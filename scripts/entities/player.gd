extends CharacterBody2D
class_name Player

signal leveled_up
signal died
signal hurt
signal xp_changed(xp: int, xp_to_next: int)
signal health_changed(health: float, max_health: float)
signal weapons_changed
signal passives_changed

# ═══════════════════════════════════════════════════════════════
#  21 Player Stats — 对齐 VS Wiki
#  https://vampire.survivors.wiki/w/Player_stats
#  百分比 stat 基数为 1.0 (= 100%)，加成后相乘
#  绝对值 stat 为具体数值
# ═══════════════════════════════════════════════════════════════

# ── 绝对值 stats ──
var health: float = 100.0           # 当前 HP
var max_health: float = 100.0       # 最大 HP (Wiki: 100 HP)
var base_max_health: float = 100.0  # PowerUp/角色调整后的基础最大 HP
var recovery: float = 0.0           # HP/s 回复 (Wiki: 0 HP/s)
var armor: float = 0.0             # 减伤 (Wiki: 0)
var move_speed: float = 200.0      # 移动速度 px/s (Wiki: 100% = 200px/s)
var revivals: int = 0              # 复活次数 (Wiki: 0)
var invincible_duration: float = 0.3  # 受伤无敌时间 (Parm Aegis)
var charm: int = 0                 # 敌人生成数增加

# ── 百分比乘算 stats (1.0 = 100%) ──
var might: float = 1.0             # 伤害倍率 (Wiki: Might 100%)
var area_mult: float = 1.0         # 范围倍率 (Wiki: Area 100%)
var speed_mult: float = 1.0        # 弹速倍率 (Wiki: Speed 100%)
var duration_mult: float = 1.0     # 持续时间倍率 (Wiki: Duration 100%)
var cooldown_mult: float = 1.0     # 冷却倍率 (Wiki: Cooldown 100%, 越低越快)
var growth_mult: float = 1.0       # XP 倍率 (Wiki: Growth 100%)

# ── 加算偏置 stats (0 = 基线加成) ──
var luck: float = 0.0             # 幸运加成 (Wiki: Luck 100% = 1.0 + luck)
var greed_mult: float = 0.0       # 金币加成 (Wiki: Greed 100% = 1.0 + greed)
var curse: float = 0.0            # 诅咒 (Wiki: 0%)

# ── 弹数 ──
var projectile_bonus: int = 0     # 额外弹数 (Wiki: Amount 0)

# ── 拾取范围 ──
var pickup_range: float = 80.0    # 吸引范围 px (Wiki: Magnet)
var magnet_level: int = 0          # Magnet 被动等级

# ── 其他 ──
var gold_fever_duration_bonus: float = 0.0  # Gold Fever 延长时间
var _crit_chance: float = 0.0     # 暴击率
var _crit_mult: float = 2.0       # 暴击倍率

# ── Arcana 加成层（在 recalculate 最后乘算） ──
var _arcana_speed_mult: float = 1.0
var _arcana_area_mult: float = 1.0
var _arcana_duration_mult: float = 1.0

var xp: int = 0
var level: int = 1
var xp_to_next: int = 5
var _accumulated_xp: int = 0

var invincible: float = 0.0
var direction: Vector2 = Vector2.DOWN

# Dirty flag for _draw — avoids queue_redraw every frame
var _visual_dirty: bool = false
var _last_health: float = -1.0
var _last_max_health: float = -1.0
var _last_invincible: float = -1.0
var _last_whip_vis: float = -1.0
var _last_whip_evolved: bool = false
var _last_garlic_evolved: bool = false
var _last_garlic_area: float = 0.0
var _last_direction: Vector2 = Vector2.DOWN

var weapon_manager
var passive_inventory

var hurtbox: Area2D

var _ft_scene = preload("res://scenes/floating_text.tscn")

const CollisionLayers = preload("res://scripts/data/collision_layers.gd")
const ItemTypes = preload("res://scripts/data/item_types.gd")
const UpgradeType = ItemTypes.Type


func _ready():
	weapon_manager = preload("res://scripts/entities/weapon_manager.gd").new(self)
	passive_inventory = preload("res://scripts/entities/passive_inventory.gd").new()

	collision_layer = CollisionLayers.PLAYER
	collision_mask = 0
	add_to_group("player")

	hurtbox = Area2D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_mask = CollisionLayers.MASK_ENEMIES
	var hs = CollisionShape2D.new()
	var hc = CircleShape2D.new()
	hc.radius = 12
	hs.shape = hc
	hurtbox.add_child(hs)
	add_child(hurtbox)
	hurtbox.body_entered.connect(_on_hurt)
	hurtbox.area_entered.connect(_on_hurt_area)



	health = max_health
	var debug_weapons = EventBus.get_config("debug_starting_weapons", [])
	if not debug_weapons.is_empty():
		for w_type in debug_weapons:
			var starter = WeaponState.new(w_type)
			weapon_manager.add_weapon(starter)
	else:
		var start_weapon_type = UpgradeType.WHIP
		var char_data = EventBus.get_config("selected_character", {})
		if not char_data.is_empty():
			start_weapon_type = char_data.get("weapon", UpgradeType.WHIP)
		var starter = WeaponState.new(start_weapon_type)
		weapon_manager.add_weapon(starter)
	xp_to_next = LevelUpService.xp_for_level(level)
	if debug_weapons.is_empty():
		var char_data = EventBus.get_config("selected_character", {})
		if not char_data.is_empty():
			var bonus_type = char_data.get("bonus_type", "")
			var bonus_val = char_data.get("bonus_value", 0.0)
			match bonus_type:
				"might": might += bonus_val
				"growth": growth_mult += bonus_val
				"movespeed": move_speed += 200.0 * bonus_val
				"area": area_mult += bonus_val
	_apply_powerup_bonuses()
	health_changed.emit(health, max_health)


func _process(delta):
	if health <= 0:
		return
	_flush_xp()
	if invincible > 0:
		invincible -= delta
		# 升级无敌期间闪烁
		update_visual()
	if recovery > 0.0 and health < max_health:
		var old = health
		health = min(health + recovery * delta, max_health)
		if health != old:
			health_changed.emit(health, max_health)
	weapon_manager.process(delta)
	_attract_gems(delta)
	_mark_visual_dirty_if_needed()


func _physics_process(delta):
	var input = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()
	if input.length() > 0:
		direction = input
	velocity = input * move_speed
	move_and_slide()


func _draw():
	if not (invincible > 0 and int(invincible * 20) % 2 == 0):
		draw_circle(Vector2.ZERO, 12, Color(0.2, 0.4, 0.9))
		draw_circle(Vector2.ZERO, 12, Color(0.3, 0.5, 1.0), false, 2.0)
		var hp_pct = health / max_health if max_health > 0 else 0
		var bar_w = 22.0
		var bar_h = 3.0
		var bar_y = 15.0
		draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.3, 0.05, 0.05))
		var hp_color = Color(0.9, 0.7, 0.1) if hp_pct > 0.5 else Color(0.9, 0.15, 0.15)
		draw_rect(Rect2(-bar_w / 2, bar_y, min(bar_w, bar_w * hp_pct), bar_h), hp_color)

	if weapon_manager.whip_vis_time > 0:
		var progress = 1.0 - (weapon_manager.whip_vis_time / 0.1)
		var alpha = min(weapon_manager.whip_vis_time * 10, 0.6)
		var w_area = weapon_manager.whip_vis_area
		var whip_evolved = false
		for w in weapon_manager.weapons:
			if w.type == UpgradeType.WHIP and w.evolved:
				whip_evolved = true
				break
		var base_color = Color(1.0, 0.2, 0.2) if whip_evolved else Color(1, 1, 1)
		
		# Arc-shaped whip visual matching hitbox in whip.gd
		var arc_r = w_area * 2.0
		var arc_angle = PI * 0.6  # ~108°
		var facing = direction.normalized() if direction.length() > 0 else Vector2.DOWN
		var angle0 = facing.angle() - arc_angle * 0.5
		var angle1 = facing.angle() + arc_angle * 0.5
		var segs = 12
		
		# Filled arc (triangle fan)
		var pts: PackedVector2Array = [Vector2.ZERO]
		for i in range(segs + 1):
			var a = angle0 + (angle1 - angle0) * (float(i) / segs)
			pts.push_back(Vector2(cos(a), sin(a)) * arc_r)
		draw_polygon(pts, PackedColorArray([Color(base_color.r, base_color.g, base_color.b, alpha * 0.15)]))
		
		# Arc outline
		draw_arc(Vector2.ZERO, arc_r, angle0, angle1, segs, base_color, 2.5, true)
		
		# Pulse effect (shrinking arc)
		var pulse_inset = progress * arc_r * 0.15
		var pulse_r = max(arc_r - pulse_inset, 4.0)
		draw_arc(Vector2.ZERO, pulse_r, angle0, angle1, segs, Color(base_color.r, base_color.g, base_color.b, alpha * 0.4), 1.5, true)
	for w in weapon_manager.weapons:
		if w.type == UpgradeType.GARLIC:
			var pulse = 0.4 + sin(Time.get_ticks_msec() * 0.004) * 0.15
			var garlic_alpha = pulse * (0.4 if w.evolved else 0.25)
			var garlic_color = Color(0.8, 0.2, 1.0, garlic_alpha) if w.evolved else Color(0.5, 0.2, 0.8, garlic_alpha)
			draw_circle(Vector2.ZERO, w.area * area_mult, garlic_color)
			break

	var tip = direction * 16.0
	var perp = direction.rotated(PI / 2.0) * 5.0
	var base = direction * 9.0
	var tri = PackedVector2Array([tip, base + perp, base - perp])
	draw_polygon(tri, [Color(0.5, 0.8, 1.0, 0.8)])


func update_visual():
	_visual_dirty = true
	queue_redraw()


func _mark_visual_dirty_if_needed():
	# Only mark dirty when something visible actually changed
	var dirty = false
	if health != _last_health or max_health != _last_max_health:
		_last_health = health
		_last_max_health = max_health
		dirty = true
	if invincible != _last_invincible:
		_last_invincible = invincible
		dirty = true
	
	# Direction change (player arrow indicator)
	if direction != _last_direction:
		_last_direction = direction
		dirty = true
	
	# Check whip visibility
	var wv = weapon_manager.whip_vis_time
	if wv != _last_whip_vis:
		_last_whip_vis = wv
		dirty = true
	if wv > 0:
		# Check evolved state during whip swing
		var we = false
		for w in weapon_manager.weapons:
			if w.type == UpgradeType.WHIP and w.evolved:
				we = true
				break
		if we != _last_whip_evolved:
			_last_whip_evolved = we
			dirty = true
	
	# Check garlic presence
	var ga = 0.0
	var ge = false
	for w in weapon_manager.weapons:
		if w.type == UpgradeType.GARLIC:
			ga = w.area * area_mult
			ge = w.evolved
			break
	if ga != _last_garlic_area:
		_last_garlic_area = ga
		dirty = true
	if ge != _last_garlic_evolved:
		_last_garlic_evolved = ge
		dirty = true
	
	if dirty:
		_visual_dirty = true
		queue_redraw()


func get_weapon_count() -> int:
	return weapon_manager.get_count()


func recalculate_stats():
	# ── 对齐 Wiki：所有 stat 从基线重算，分层叠加 ──
	#    Layer 0: 基础值
	#    Layer 1: 角色加成
	#    Layer 2: PowerUp 加成
	#    Layer 3: 被动物品加成（passive_inventory.recalculate）
	#    Layer 4: Arcana 加成（在 _recalculate_* 中处理）

	# ── L0 + L1: 基础值 + 角色加成 ──
	var char_data = EventBus.get_config("selected_character", {})
	
	# Max Health: baseline
	var hp_mult := 1.0
	var char_stats = char_data.get("stats", {}) if not char_data.is_empty() else {}
	if not char_stats.is_empty():
		hp_mult = 1.0 + char_stats.get("max_hp_pct", 0.0)
	if PowerUpManager:
		var b = PowerUpManager.get_stat_bonuses()
		base_max_health = 100.0 * (1.0 + b["max_hp_pct"]) * hp_mult
	else:
		base_max_health = 100.0 * hp_mult
	
	# 重置所有 stat 到基线
	might = 1.0
	cooldown_mult = 1.0
	area_mult = 1.0
	speed_mult = 1.0
	duration_mult = 1.0
	growth_mult = 1.0
	luck = 0.0
	greed_mult = 0.0
	curse = 0.0
	recovery = 0.0
	armor = 0.0
	move_speed = 200.0
	projectile_bonus = 0
	revivals = 0
	magnet_level = 0
	pickup_range = 80.0
	charm = 0
	invincible_duration = 0.3
	gold_fever_duration_bonus = 0.0
	_crit_chance = 0.0
	
	var old_max = max_health
	
	# L1: Character non-HP 加成
	if not char_stats.is_empty():
		might += char_stats.get("damage_mult", 0.0)
		cooldown_mult -= char_stats.get("cooldown_reduction", 0.0)
		area_mult += char_stats.get("area_mult", 0.0)
		move_speed += 200.0 * char_stats.get("move_speed_pct", 0.0)
		growth_mult += char_stats.get("growth_pct", 0.0)
		recovery += char_stats.get("recovery", 0.0)
		armor += char_stats.get("armor", 0)
		greed_mult += char_stats.get("greed_pct", 0.0)
	else:
		var bonus_type = char_data.get("bonus_type", "")
		var bonus_val = char_data.get("bonus_value", 0.0)
		match bonus_type:
			"might": might += bonus_val
			"growth": growth_mult += bonus_val
			"movespeed": move_speed += 200.0 * bonus_val
			"area": area_mult += bonus_val
	
	# L2: PowerUp 加成
	if PowerUpManager:
		var b = PowerUpManager.get_stat_bonuses()
		might += b["damage_mult"]
		recovery += b["recovery"]
		cooldown_mult -= b["cooldown_reduction"]
		area_mult += b["area_mult"]
		move_speed += 200.0 * b["move_speed_pct"]
		growth_mult += b["growth_pct"]
		armor += b["armor"]
	
	# L3: Passive items（passive_inventory 从基线重算所有 stat）
	passive_inventory.recalculate(self)
	
	# L4: Arcana 加成（乘算在最后）
	area_mult *= _arcana_area_mult
	speed_mult *= _arcana_speed_mult
	duration_mult *= _arcana_duration_mult
	
	# 血量变更通知
	if max_health != old_max or health > max_health:
		health = min(health, max_health)
		health_changed.emit(health, max_health)


func apply_upgrade(t: int):
	var is_weapon = DataRegistry.items().is_weapon(t)
	if is_weapon:
		weapon_manager.add_or_upgrade(t)
	else:
		passive_inventory.add_or_upgrade(t)
	recalculate_stats()
	if is_weapon:
		weapons_changed.emit()
	else:
		passives_changed.emit()


func get_weapon_level(t: int) -> int:
	return weapon_manager.get_level(t)


func get_weapon_max_level(t: int) -> int:
	return weapon_manager.get_max_level(t)


func get_passive_level(t: int) -> int:
	return passive_inventory.get_level(t)


func get_passive_max_level(t: int) -> int:
	return DataRegistry.items().item_max_level(t)


func can_evolve(weapon_type: int) -> bool:
	return weapon_manager.can_evolve(weapon_type)


func evolve_weapon(weapon_type: int):
	weapon_manager.evolve_weapon(weapon_type)
	weapons_changed.emit()


func set_speed_mult(val: float):
	_arcana_speed_mult = val
	var bracer_lv = passive_inventory.get_level(UpgradeType.BRACER)
	speed_mult = (1.0 + 0.10 * bracer_lv) * _arcana_speed_mult


func set_area_mult_override(val: float):
	_arcana_area_mult = val
	_recalculate_area()


func set_duration_mult_override(val: float):
	_arcana_duration_mult = val
	_recalculate_duration()


func add_speed_mult_pct(pct: float):
	var bracer_lv = passive_inventory.get_level(UpgradeType.BRACER)
	speed_mult = (1.0 + 0.10 * bracer_lv + pct) * _arcana_speed_mult


func add_growth_pct(pct: float):
	growth_mult += pct


func add_luck(pct: float):
	luck += pct


func add_greed_pct(pct: float):
	greed_mult += pct


func add_curse(pct: float):
	curse += pct


func add_area_pct(pct: float):
	area_mult += pct
	_recalculate_area()


func add_duration_pct(pct: float):
	# +X% → 乘算: duration_mult 1.0 → 1.0 + pct
	duration_mult += pct
	_recalculate_duration()


func _recalculate_area():
	var candel_lv = passive_inventory.get_level(UpgradeType.CANDELABRADOR)
	area_mult = 1.0 + 0.08 * candel_lv
	area_mult *= _arcana_area_mult


func _recalculate_duration():
	# 从被动重算 duration_mult（加成全部为加算到 1.0 基线）
	var spell_lv = passive_inventory.get_level(UpgradeType.SPELLBINDER)
	var torrona_lv = passive_inventory.get_level(UpgradeType.TORRONA)
	var silver_ring_lv = passive_inventory.get_level(UpgradeType.SILVER_RING)
	duration_mult = 1.0
	duration_mult += 0.10 * spell_lv     # Spellbinder: +10%/lv
	duration_mult += 0.04 * torrona_lv   # Torrona: +4%/lv
	duration_mult += 0.05 * silver_ring_lv  # Silver Ring: +5%/lv
	duration_mult *= _arcana_duration_mult  # Arcana 层最后乘算


func get_curse() -> float:
	return curse


func get_gold_fever_duration_bonus() -> float:
	return gold_fever_duration_bonus


func get_charm() -> int:
	return charm


func get_greed_mult() -> float:
	var base = 1.0
	if PowerUpManager:
		var b = PowerUpManager.get_stat_bonuses()
		base += b["greed_pct"]
	base += greed_mult
	return base


func heal(amount: float):
	var effective = amount
	if ArcanaManager and ArcanaManager.has_effect("healing_double"):
		effective = amount * ArcanaManager.get_healing_multiplier()
	health = min(health + effective, max_health)
	show_floating_text(I18N.t("player.heal") % [int(effective)], Color(0.3, 1.0, 0.3), 16)
	health_changed.emit(health, max_health)
	if ArcanaManager and ArcanaManager.has_effect("healing_damages_enemies"):
		_damage_nearby_enemies(effective)


# ── XP ───────────────────────────────────────────────────────────────

const LevelUpService = preload("res://scripts/core/level_up_service.gd")


func add_xp(value: int):
	if ArcanaManager and ArcanaManager.has_effect("no_xp"):
		return
	_accumulated_xp += value


func _flush_xp():
	if _accumulated_xp <= 0:
		return
	var gained = _accumulated_xp
	_accumulated_xp = 0
	var effective_growth = LevelUpService.effective_growth(growth_mult, level)
	xp += int(gained * effective_growth)
	xp_to_next = LevelUpService.xp_for_level(level)
	var leveled = false
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = LevelUpService.xp_for_level(level)
		leveled = true
	if leveled:
		invincible = invincible_duration
		show_floating_text(I18N.t("player.level_up"), Color(0.9, 0.8, 0.2), 22)
		AudioManager.play_sfx("level_up")
		leveled_up.emit()
	xp_changed.emit(xp, xp_to_next)


var _attract_skip: int = 0
var _attracted_items: Array = []

func _attract_gems(delta: float):
	_attract_skip += 1
	var pos = global_position

	# 每 10 帧：扫描全组，找出新进入范围的物品
	if _attract_skip % 10 == 0:
		var range_sq = pickup_range * pickup_range
		for g in get_tree().get_nodes_in_group("gems"):
			if not is_instance_valid(g) or g.collected or g.attracted:
				continue
			if (pos - g.global_position).length_squared() < range_sq:
				g.attracted = true
				_attracted_items.append(g)
		for p in get_tree().get_nodes_in_group("pickups"):
			if not is_instance_valid(p) or p.collected or p.attracted:
				continue
			if (pos - p.global_position).length_squared() < range_sq:
				p.attracted = true
				_attracted_items.append(p)

	# 每帧：移动已吸引的物品，清理已收集/失效的
	var i = 0
	while i < _attracted_items.size():
		var item = _attracted_items[i]
		if not is_instance_valid(item) or item.collected or not item.attracted:
			_attracted_items.remove_at(i)
			continue
		item.global_position += (pos - item.global_position).normalized() * 300.0 * delta
		i += 1


# ── Hurt / Health ────────────────────────────────────────────────────

func _on_hurt(body: Node):
	if health <= 0 or invincible > 0:
		return
	if body.has_method("get_contact_damage"):
		health -= max(body.get_contact_damage() * (1.0 - armor), 1.0)
		invincible = invincible_duration
		hurt.emit()
		var dead = false
		if health <= 0:
			if revivals > 0:
				_revive()
				return
			health = 0
			dead = true
			died.emit()
		else:
			AudioManager.play_sfx("player_hurt")
		if not dead:
			health_changed.emit(health, max_health)


func _on_hurt_area(area: Area2D):
	if health <= 0 or invincible > 0:
		return
	if area.has_method("get_projectile_damage"):
		var dmg = area.get_projectile_damage()
		health -= max(dmg * (1.0 - armor * 0.5), 1.0)
		invincible = invincible_duration
		hurt.emit()
		var dead = false
		if health <= 0:
			if revivals > 0:
				_revive()
				return
			health = 0
			dead = true
			died.emit()
		else:
			AudioManager.play_sfx("player_hurt")
		if not dead:
			health_changed.emit(health, max_health)


func _damage_nearby_enemies(amount: float):
	var enemies = EnemyRegistry.get_all() if EnemyRegistry else []
	var pos = global_position
	for e in enemies:
		if not is_instance_valid(e):
			continue
		if pos.distance_to(e.global_position) < 100.0:
			if e.has_method("take_damage"):
				e.take_damage(amount, Vector2.ZERO)


func show_floating_text(txt: String, col: Color = Color.WHITE, sz: int = 16):
	if is_inside_tree() and ObjectPoolManager:
		ObjectPoolManager.spawn_ft(get_parent(), global_position + Vector2(randf_range(-10, 10), -30), txt, col, sz)


func _revive():
	revivals -= 1
	if ArcanaManager and ArcanaManager.has_effect("revival_buff"):
		max_health *= 1.10
		armor += 1
		might *= 1.05
		area_mult *= 1.05
		duration_mult += 0.05
		speed_mult *= 1.05
		if ArcanaManager and ArcanaManager.has_effect("armor_scales_damage"):
			might += 0.1 * armor
	health = max_health * 0.5
	invincible = 2.0
	show_floating_text(I18N.t("player.revive"), Color(0.9, 0.8, 0.2), 24)
	AudioManager.play_sfx("player_revive")
	health_changed.emit(health, max_health)


# ── PowerUp ──────────────────────────────────────────────────────────

func _apply_powerup_stats():
	if not PowerUpManager:
		return
	var b = PowerUpManager.get_stat_bonuses()
	might += b["damage_mult"]
	base_max_health = 100.0 * (1.0 + b["max_hp_pct"])
	recovery += b["recovery"]
	cooldown_mult -= b["cooldown_reduction"]
	area_mult += b["area_mult"]
	move_speed += 200.0 * b["move_speed_pct"]
	growth_mult += b["growth_pct"]
	armor += b["armor"]


func _apply_powerup_bonuses():
	if not PowerUpManager:
		return
	_apply_powerup_stats()
	max_health = base_max_health
	health = max_health
