extends CharacterBody2D
class_name Player

signal leveled_up
signal died
signal hurt

enum UpgradeType {
	WHIP, MAGIC_WAND, GARLIC,
	WINGS, SPINACH, TOME,
	HOLLOW_HEART, CANDELABRADOR, CROWN, PUMMAROLA,
	KNIFE = 10, AXE = 11, FIRE_WAND = 12,
	DUPLICATOR = 13, STONE_MASK = 14,
	MAGNET = 15,
	CROSS = 16, KING_BIBLE = 17, SANTA_WATER = 18,
	RUNETRACER = 19, LIGHTNING_RING = 20,
	CLOVER = 21, SPELLBINDER = 22, ARMOR = 23,
	BRACER = 24, SKULL = 25, TIRAGISU = 26,
	TORRONA = 27, SILVER_RING = 28, GOLD_RING = 29,
	METAGLIO_LEFT = 30, METAGLIO_RIGHT = 31
}

var move_speed: float = 200.0
var max_health: float = 100.0
var health: float = 100.0
var damage_mult: float = 1.0
var base_max_health: float = 100.0
var pickup_range: float = 60.0
var armor: float = 0.0
var cooldown_reduction: float = 0.0
var area_mult: float = 1.0
var growth_mult: float = 1.0
var recovery: float = 0.0
var projectile_bonus: int = 0
var greed_mult: float = 0.0
var magnet_level: int = 0
var luck: float = 0.0
var duration_bonus: float = 0.0
var speed_mult: float = 1.0
var curse: float = 0.0
var revivals: int = 0

var _arcana_speed_override: float = 1.0
var _arcana_area_override: float = 1.0
var _arcana_duration_override: float = 0.0
var _crit_chance: float = 0.0
var _crit_mult: float = 2.0

var xp: int = 0
var level: int = 1
var xp_to_next: int = 10

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
var collect_area: Area2D
var _collect_shape_ref: CollisionShape2D

var _ft_scene = preload("res://scenes/floating_text.tscn")

const CollisionLayers = preload("res://scripts/data/collision_layers.gd")
const ItemDefs = preload("res://scripts/data/item_defs.gd")


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
	hc.radius = 18
	hs.shape = hc
	hurtbox.add_child(hs)
	add_child(hurtbox)
	hurtbox.body_entered.connect(_on_hurt)
	hurtbox.area_entered.connect(_on_hurt_area)

	collect_area = Area2D.new()
	collect_area.name = "CollectArea"
	collect_area.collision_mask = CollisionLayers.XP_GEM
	var cs = CollisionShape2D.new()
	var cc = CircleShape2D.new()
	cc.radius = pickup_range
	cs.shape = cc
	collect_area.add_child(cs)
	add_child(collect_area)
	_collect_shape_ref = cs
	collect_area.area_entered.connect(_on_collect_area)

	health = max_health
	var start_weapon_type = UpgradeType.WHIP
	if Engine.has_meta("selected_character"):
		var char_data = Engine.get_meta("selected_character")
		start_weapon_type = char_data.get("weapon", UpgradeType.WHIP)
	var starter = WeaponState.new(start_weapon_type)
	weapon_manager.add_weapon(starter)
	update_xp_requirements()
	if Engine.has_meta("selected_character"):
		var char_data = Engine.get_meta("selected_character")
		var bonus_type = char_data.get("bonus_type", "")
		var bonus_val = char_data.get("bonus_value", 0.0)
		match bonus_type:
			"might": damage_mult += bonus_val
			"growth": growth_mult += bonus_val
			"movespeed": move_speed += 200.0 * bonus_val
			"area": area_mult += bonus_val
	_apply_powerup_bonuses()


func _process(delta):
	if health <= 0:
		return
	if invincible > 0:
		invincible -= delta
	if recovery > 0.0 and health < max_health:
		health = min(health + recovery * delta, max_health)
	weapon_manager.process(delta)
	if magnet_level > 0:
		_magnet_pull(delta)
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
		draw_circle(Vector2.ZERO, 18, Color(0.2, 0.4, 0.9))
		draw_circle(Vector2.ZERO, 18, Color(0.3, 0.5, 1.0), false, 2.0)
		var hp_pct = health / max_health if max_health > 0 else 0
		var bar_w = 32.0
		var bar_h = 4.0
		var bar_y = 22.0
		draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.3, 0.05, 0.05))
		var hp_color = Color(0.9, 0.7, 0.1) if hp_pct > 0.5 else Color(0.9, 0.15, 0.15)
		draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_pct, bar_h), hp_color)

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
		var outer_r = w_area * 2.0
		var half_w = outer_r * 0.65
		var half_h = outer_r * 0.35
		var rect = Rect2(-half_w, -half_h, half_w * 2, half_h * 2)
		draw_rect(rect, Color(base_color.r, base_color.g, base_color.b, alpha * 0.12), true)
		draw_rect(rect, base_color, false, 2.5)
		var pulse_inset = progress * 8.0
		var pulse_rect = Rect2(
			-half_w + pulse_inset, -half_h + pulse_inset,
			(half_w - pulse_inset) * 2, (half_h - pulse_inset) * 2
		)
		draw_rect(pulse_rect, Color(base_color.r, base_color.g, base_color.b, alpha * 0.5), false, 1.5)
	for w in weapon_manager.weapons:
		if w.type == UpgradeType.GARLIC:
			var pulse = 0.4 + sin(Time.get_ticks_msec() * 0.004) * 0.15
			var garlic_alpha = pulse * (0.4 if w.evolved else 0.25)
			var garlic_color = Color(0.8, 0.2, 1.0, garlic_alpha) if w.evolved else Color(0.5, 0.2, 0.8, garlic_alpha)
			draw_circle(Vector2.ZERO, w.area * area_mult, garlic_color)
			break

	var tip = direction * 22.0
	var perp = direction.rotated(PI / 2.0) * 7.0
	var base = direction * 12.0
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
	passive_inventory.recalculate(self)
	if Engine.has_meta("selected_character"):
		var char_data = Engine.get_meta("selected_character")
		var stats = char_data.get("stats", {})
		if not stats.is_empty():
			damage_mult += stats.get("damage_mult", 0.0)
			cooldown_reduction += stats.get("cooldown_reduction", 0.0)
			area_mult += stats.get("area_mult", 0.0)
			move_speed += 200.0 * stats.get("move_speed_pct", 0.0)
			growth_mult += stats.get("growth_pct", 0.0)
			recovery += stats.get("recovery", 0.0)
			armor += stats.get("armor", 0)
			greed_mult += stats.get("greed_pct", 0.0)
			max_health = base_max_health * (1.0 + stats.get("max_hp_pct", 0.0))
		else:
			var bonus_type = char_data.get("bonus_type", "")
			var bonus_val = char_data.get("bonus_value", 0.0)
			match bonus_type:
				"might": damage_mult += bonus_val
				"growth": growth_mult += bonus_val
				"movespeed": move_speed += 200.0 * bonus_val
				"area": area_mult += bonus_val
	_apply_powerup_stats()
	if _collect_shape_ref and _collect_shape_ref.shape:
		var circle = _collect_shape_ref.shape as CircleShape2D
		if circle:
			circle.radius = pickup_range


func apply_upgrade(t: int):
	match t:
		UpgradeType.WHIP, UpgradeType.MAGIC_WAND, UpgradeType.GARLIC, \
		UpgradeType.KNIFE, UpgradeType.AXE, UpgradeType.FIRE_WAND, \
		UpgradeType.CROSS, UpgradeType.KING_BIBLE, UpgradeType.SANTA_WATER, \
		UpgradeType.RUNETRACER, UpgradeType.LIGHTNING_RING:
			weapon_manager.add_or_upgrade(t)
		UpgradeType.WINGS, UpgradeType.SPINACH, UpgradeType.TOME, \
		UpgradeType.HOLLOW_HEART, UpgradeType.CANDELABRADOR, \
		UpgradeType.CROWN, UpgradeType.PUMMAROLA, \
		UpgradeType.DUPLICATOR, UpgradeType.STONE_MASK, \
		UpgradeType.MAGNET, UpgradeType.CLOVER, UpgradeType.SPELLBINDER, \
		UpgradeType.ARMOR, UpgradeType.BRACER, UpgradeType.SKULL, \
		UpgradeType.TIRAGISU, UpgradeType.TORRONA, \
		UpgradeType.SILVER_RING, UpgradeType.GOLD_RING, \
		UpgradeType.METAGLIO_LEFT, UpgradeType.METAGLIO_RIGHT:
			passive_inventory.add_or_upgrade(t)
	recalculate_stats()


func get_weapon_level(t: int) -> int:
	return weapon_manager.get_level(t)


func get_weapon_max_level(t: int) -> int:
	return weapon_manager.get_max_level(t)


func get_passive_level(t: int) -> int:
	return passive_inventory.get_level(t)


func get_passive_max_level(t: int) -> int:
	return ItemDefs.get_max_level(t)


func can_evolve(weapon_type: int) -> bool:
	return weapon_manager.can_evolve(weapon_type)


func evolve_weapon(weapon_type: int):
	weapon_manager.evolve_weapon(weapon_type)


func set_speed_mult(val: float):
	_arcana_speed_override = val
	var bracer_lv = passive_inventory.get_level(UpgradeType.BRACER)
	speed_mult = (1.0 + 0.10 * bracer_lv) * _arcana_speed_override


func set_area_mult_override(val: float):
	_arcana_area_override = val
	_recalculate_area()


func set_duration_bonus_override(val: float):
	_arcana_duration_override = val
	_recalculate_duration()


func add_speed_mult_pct(pct: float):
	var bracer_lv = passive_inventory.get_level(UpgradeType.BRACER)
	speed_mult = (1.0 + 0.10 * bracer_lv + pct) * _arcana_speed_override


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
	duration_bonus += pct
	_recalculate_duration()


func _recalculate_area():
	var candel_lv = passive_inventory.get_level(UpgradeType.CANDELABRADOR)
	area_mult = 1.0 + 0.08 * candel_lv
	area_mult *= _arcana_area_override


func _recalculate_duration():
	var spell_lv = passive_inventory.get_level(UpgradeType.SPELLBINDER)
	duration_bonus = 0.1 * spell_lv + _arcana_duration_override


func get_curse() -> float:
	return curse


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
	if ArcanaManager and ArcanaManager.has_effect("healing_damages_enemies"):
		_damage_nearby_enemies(effective)


# ── XP ───────────────────────────────────────────────────────────────

func _on_collect_area(area: Area2D):
	if area.has_method("collect"):
		add_xp(area.collect())


func add_xp(value: int):
	if ArcanaManager and ArcanaManager.has_effect("no_xp"):
		return
	xp += int(value * growth_mult)
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		update_xp_requirements()
		show_floating_text(I18N.t("player.level_up"), Color(0.9, 0.8, 0.2), 22)
		AudioManager.play_sfx("level_up")
		leveled_up.emit()


func update_xp_requirements():
	xp_to_next = 10 + level * 15 + int(level * level * 0.35)


# ── Magnet ───────────────────────────────────────────────────────────

func _magnet_pull(delta: float):
	var magnet_range = 80.0 + 50.0 * magnet_level
	var pull_speed = 300.0 + 80.0 * magnet_level
	var gems = get_tree().get_nodes_in_group("gems")
	var player_pos = global_position
	for g in gems:
		if not is_instance_valid(g) or g.collected:
			continue
		var dist = player_pos.distance_squared_to(g.global_position)
		if dist < magnet_range * magnet_range:
			if not g.attracted:
				g.attracted = true
			g.attract_speed = max(g.attract_speed, pull_speed)


# ── Hurt / Health ────────────────────────────────────────────────────

func _on_hurt(body: Node):
	if health <= 0 or invincible > 0:
		return
	if body.has_method("get_contact_damage"):
		health -= max(body.get_contact_damage() - armor, 1.0)
		invincible = 0.3
		hurt.emit()
		if health <= 0:
			if revivals > 0:
				_revive()
				return
			health = 0
			died.emit()
		else:
			AudioManager.play_sfx("player_hurt")


func _on_hurt_area(area: Area2D):
	if health <= 0 or invincible > 0:
		return
	if area.has_method("get_projectile_damage"):
		var dmg = area.get_projectile_damage()
		health -= max(dmg - armor * 0.5, 1.0)
		invincible = 0.3
		hurt.emit()
		if health <= 0:
			if revivals > 0:
				_revive()
				return
			health = 0
			died.emit()
		else:
			AudioManager.play_sfx("player_hurt")


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
	if is_inside_tree() and FloatingTextPool:
		FloatingTextPool.spawn(get_parent(), global_position + Vector2(randf_range(-10, 10), -30), txt, col, sz)


func _revive():
	revivals -= 1
	if ArcanaManager and ArcanaManager.has_effect("revival_buff"):
		max_health *= 1.10
		armor += 1
		damage_mult *= 1.05
		area_mult *= 1.05
		duration_bonus += 0.05
		speed_mult *= 1.05
		if ArcanaManager and ArcanaManager.has_effect("armor_scales_damage"):
			damage_mult += 0.1 * armor
	health = max_health * 0.5
	invincible = 2.0
	show_floating_text(I18N.t("player.revive"), Color(0.9, 0.8, 0.2), 24)
	AudioManager.play_sfx("player_revive")


# ── PowerUp ──────────────────────────────────────────────────────────

func _apply_powerup_stats():
	if not PowerUpManager:
		return
	var b = PowerUpManager.get_stat_bonuses()
	damage_mult += b["damage_mult"]
	base_max_health = 100.0 * (1.0 + b["max_hp_pct"])
	recovery += b["recovery"]
	cooldown_reduction += b["cooldown_reduction"]
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
