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
	MAGNET = 15
}

class WeaponState:
	var type: int
	var level: int
	var max_level: int
	var cooldown: float
	var cooldown_timer: float
	var damage: float
	var area: float
	var speed: float
	var evolved: bool = false

	static var _BASE = {
		UpgradeType.WHIP: {"cd": 1.0, "dmg": 75.0, "area": 60.0, "speed": 0.0},
		UpgradeType.MAGIC_WAND: {"cd": 0.05, "dmg": 12.0, "area": 12.0, "speed": 400.0},
		UpgradeType.GARLIC: {"cd": 0.3, "dmg": 6.0, "area": 80.0, "speed": 0.0},
		UpgradeType.KNIFE: {"cd": 0.3, "dmg": 30.0, "area": 10.0, "speed": 600.0},
		UpgradeType.AXE: {"cd": 1.2, "dmg": 100.0, "area": 40.0, "speed": 0.0},
		UpgradeType.FIRE_WAND: {"cd": 0.8, "dmg": 50.0, "area": 20.0, "speed": 300.0},
	}

	func _init(t: int):
		type = t; level = 1; max_level = 8
		var b = _BASE[t]
		cooldown = b["cd"]; damage = b["dmg"]
		area = b["area"]; speed = b["speed"]
		cooldown_timer = 0.0

	func upgrade():
		level += 1
		cooldown = max(cooldown * 0.88, 0.1)
		damage *= 1.15; area *= 1.1; speed *= 1.1

	func evolve():
		evolved = true
		match type:
			UpgradeType.WHIP:
				damage *= 2.0
				area *= 1.5
			UpgradeType.MAGIC_WAND:
				cooldown = 0.02
				damage *= 1.5
			UpgradeType.GARLIC:
				area *= 1.5
				damage *= 2.0
			UpgradeType.KNIFE:
				damage *= 1.5
				speed *= 1.3
			UpgradeType.AXE:
				damage *= 1.8
				area *= 1.4

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
var projectile_bonus: int = 0   # from Duplicator passive
var greed_mult: float = 0.0     # from Stone Mask passive

const EVOLUTION_RECIPES = {
	UpgradeType.WHIP: {
		"passive": UpgradeType.SPINACH,
		"passive_level": 1,
		"name": "Bloody Tear",
		"desc": "Whip evolves into Bloody Tear\nHeals 20% of damage dealt"
	},
	UpgradeType.MAGIC_WAND: {
		"passive": UpgradeType.WINGS,
		"passive_level": 1,
		"name": "Holy Wand",
		"desc": "Magic Wand evolves into Holy Wand\nFires at super speed"
	},
	UpgradeType.GARLIC: {
		"passive": UpgradeType.TOME,
		"passive_level": 1,
		"name": "Soul Eater",
		"desc": "Garlic evolves into Soul Eater\nHeals 1 HP per kill"
	},
	UpgradeType.KNIFE: {
		"passive": UpgradeType.CANDELABRADOR,
		"passive_level": 1,
		"name": "Thousand Edge",
		"desc": "Knife evolves into Thousand Edge\nFires a spread of 3 blades"
	},
	UpgradeType.AXE: {
		"passive": UpgradeType.HOLLOW_HEART,
		"passive_level": 1,
		"name": "Death Spiral",
		"desc": "Axe evolves into Death Spiral\nAxes orbit and return to you"
	}
}

var xp: int = 0
var level: int = 1
var xp_to_next: int = 10

var weapons: Array[WeaponState] = []
var passives: Dictionary = {}
var invincible: float = 0.0
var direction: Vector2 = Vector2.DOWN

var hurtbox: Area2D
var collect_area: Area2D

var _proj_vis_script = preload("res://scripts/entities/proj_vis.gd")
var whip_vis_time: float = 0.0

var whip_vis_area: float = 60.0
var _whip_hit_this_swing: Dictionary = {}
var _wand_sfx_cooldown: float = 0.0
var _knife_sfx_cooldown: float = 0.0
var _collect_shape_ref: CollisionShape2D


func _ready():
	collision_layer = 2
	collision_mask = 0
	add_to_group("player")

	hurtbox = Area2D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_mask = 4 | 8  # enemy bodies (4) + enemy projectiles (8)
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
	collect_area.collision_mask = 16
	var cs = CollisionShape2D.new()
	var cc = CircleShape2D.new()
	cc.radius = pickup_range
	cs.shape = cc
	collect_area.add_child(cs)
	add_child(collect_area)
	_collect_shape_ref = cs
	collect_area.area_entered.connect(_on_collect_area)

	health = max_health
	# Starting weapon set by CharacterSelect (default Whip)
	var start_weapon_type = UpgradeType.WHIP
	if Engine.has_meta("selected_character"):
		var char_data = Engine.get_meta("selected_character")
		start_weapon_type = char_data.get("weapon", UpgradeType.WHIP)
	var starter = WeaponState.new(start_weapon_type)
	weapons.append(starter)
	update_xp_requirements()
	# Apply character bonus
	if Engine.has_meta("selected_character"):
		var char_data = Engine.get_meta("selected_character")
		var bonus_type = char_data.get("bonus_type", "")
		var bonus_val = char_data.get("bonus_value", 0.0)
		match bonus_type:
			"might": damage_mult += bonus_val
			"growth": growth_mult += bonus_val
			"movespeed": move_speed = 200.0 * (1.0 + bonus_val)
			"area": area_mult += bonus_val
	# Apply permanent PowerUp bonuses
	_apply_powerup_bonuses()


func _process(delta):
	if health <= 0:
		return
	if invincible > 0:
		invincible -= delta
	# Passive recovery (Pummarola)
	if recovery > 0.0 and health < max_health:
		health = min(health + recovery * delta, max_health)
	if _wand_sfx_cooldown > 0:
		_wand_sfx_cooldown -= delta
	if _knife_sfx_cooldown > 0:
		_knife_sfx_cooldown -= delta
	if whip_vis_time > 0:
		whip_vis_time -= delta
		for w in weapons:
			if w.type == UpgradeType.WHIP:
				_check_whip_hits(w)
	for w in weapons:
		w.cooldown_timer -= delta
		if w.cooldown_timer <= 0:
			w.cooldown_timer = w.cooldown * (1.0 - cooldown_reduction)
			if not get_tree().get_nodes_in_group("enemies").is_empty():
				fire_weapon(w)
	update_visual()


func _physics_process(delta):
	var input = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()
	if input.length() > 0:
		direction = input
	velocity = input * move_speed
	move_and_slide()


func fire_weapon(w: WeaponState):
	match w.type:
		UpgradeType.WHIP: _fire_whip(w)
		UpgradeType.MAGIC_WAND: _fire_wand(w)
		UpgradeType.GARLIC: _fire_garlic(w)
		UpgradeType.KNIFE: _fire_knife(w)
		UpgradeType.AXE: _fire_axe(w)
		UpgradeType.FIRE_WAND: _fire_fire_wand(w)


func _fire_whip(w: WeaponState):
	AudioManager.play_sfx("wpn_whip" if not w.evolved else "wpn_evo")
	whip_vis_time = 0.1
	whip_vis_area = w.area * area_mult
	_whip_hit_this_swing.clear()
	_check_whip_hits(w)


func _check_whip_hits(w: WeaponState):
	var enemies = get_tree().get_nodes_in_group("enemies")
	var effective_area = w.area * area_mult
	var half_w = effective_area * 1.5
	var half_h = effective_area * 0.5
	var src_pos = global_position
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var id = e.get_instance_id()
		if _whip_hit_this_swing.has(id):
			continue
		var offset = e.global_position - global_position
		if abs(offset.x) < half_w and abs(offset.y) < half_h:
			var dmg = w.damage * damage_mult
			e.take_damage(dmg, src_pos)
			if w.evolved:
				health = min(health + dmg * 0.2, max_health)
			_whip_hit_this_swing[id] = true


func _fire_wand(w: WeaponState):
	if _wand_sfx_cooldown <= 0:
		AudioManager.play_sfx("wpn_wand" if not w.evolved else "wpn_evo")
		_wand_sfx_cooldown = 0.3
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	var dmg = w.damage * damage_mult
	var area = w.area * area_mult
	var count = get_projectile_count(UpgradeType.MAGIC_WAND)
	
	# Sort enemies by distance and pick the closest 'count' enemies
	enemies.sort_custom(func(a, b): return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position))
	var targets = enemies.slice(0, min(count, enemies.size()))
	
	for target in targets:
		if not is_instance_valid(target):
			continue
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = area
		s.shape = c
		p.add_child(s)
		p.global_position = global_position
		var vis = Node2D.new()
		vis.set_script(_proj_vis_script)
		p.add_child(vis)
		get_parent().add_child(p)
		p.body_entered.connect(_on_proj_hit.bind(p, dmg))
		var tw = create_tween()
		tw.tween_property(p, "global_position", target.global_position, 0.4)
		tw.finished.connect(_on_tween_done.bind(p))


func _fire_garlic(w: WeaponState):
	var enemies = get_tree().get_nodes_in_group("enemies")
	var effective_area = w.area * area_mult
	var src_pos = global_position
	for e in enemies:
		if not is_instance_valid(e): continue
		if global_position.distance_to(e.global_position) < effective_area:
			if e.has_method("take_damage"):
				e.take_damage(w.damage * damage_mult, src_pos)
				if w.evolved:
					health = min(health + 1.0, max_health)


func _fire_knife(w: WeaponState):
	if _knife_sfx_cooldown <= 0:
		AudioManager.play_sfx("wpn_knife" if not w.evolved else "wpn_evo")
		_knife_sfx_cooldown = 0.3
	var dmg = w.damage * damage_mult
	var area = w.area * area_mult
	var count = get_projectile_count(UpgradeType.KNIFE)
	var base_dir = direction if direction.length() > 0 else Vector2.DOWN
	var spread_angle = deg_to_rad(10.0)  # 10° between each blade
	var start_angle = -spread_angle * (count - 1) / 2.0
	
	for i in range(count):
		var angle = start_angle + spread_angle * i
		var dir = base_dir.rotated(angle)
		
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = area
		s.shape = c
		p.add_child(s)
		# Visual — small blade
		var vis = ColorRect.new()
		vis.color = Color(0.75, 0.75, 0.75)
		vis.size = Vector2(5, 20)
		vis.position = Vector2(-2.5, -10)
		p.add_child(vis)
		var handle = ColorRect.new()
		handle.color = Color(0.4, 0.25, 0.1)
		handle.size = Vector2(3, 5)
		handle.position = Vector2(-1.5, 10)
		p.add_child(handle)
		# Position & rotation
		p.global_position = global_position + dir * 20
		p.rotation = dir.angle()
		get_parent().add_child(p)
		# Single-use: first hit kills the projectile
		p.body_entered.connect(_on_proj_hit_and_free.bind(p, dmg))
		var target = global_position + dir * 400.0
		var tw = create_tween()
		tw.tween_property(p, "global_position", target, 0.25)
		tw.finished.connect(_on_tween_done.bind(p))


func _fire_axe(w: WeaponState):
	AudioManager.play_sfx("wpn_axe" if not w.evolved else "wpn_evo")
	var dmg = w.damage * damage_mult
	var area = w.area * area_mult * 0.5
	
	if w.evolved:
		_fire_death_spiral(w, dmg, area)
	else:
		_fire_axe_normal(w, dmg, area)


func _fire_axe_normal(w: WeaponState, dmg: float, area: float):
	var count = get_projectile_count(UpgradeType.AXE)
	var spawn_dir = direction if direction.length() > 0 else Vector2.DOWN
	var spread_angle = deg_to_rad(8.0)
	var start_angle = -spread_angle * (count - 1) / 2.0
	
	for i in range(count):
		var angle = start_angle + spread_angle * i
		var dir = spawn_dir.rotated(angle)
		
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = area
		s.shape = c
		p.add_child(s)
		# Visual — dark axe head
		var vis = ColorRect.new()
		vis.color = Color(0.35, 0.25, 0.15)
		vis.size = Vector2(area * 2.0, area * 1.2)
		vis.position = Vector2(-area, -area * 0.6)
		p.add_child(vis)
		var edge = ColorRect.new()
		edge.color = Color(0.5, 0.35, 0.2)
		edge.size = Vector2(area * 2.2, 4)
		edge.position = Vector2(-area * 1.1, -2)
		p.add_child(edge)
		# Spawn in front of player
		p.global_position = global_position + dir * 30
		get_parent().add_child(p)
		p.body_entered.connect(_on_proj_hit.bind(p, dmg))
		# Arc trajectory
		var mid = global_position + dir * 120 + Vector2(0, -80)
		var end = global_position + dir * 250
		var tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "global_position", mid, 0.3)
		tw.tween_property(p, "scale", Vector2(1.5, 1.5), 0.3)
		tw.finished.connect(_on_axe_arc_done.bind(p, end))


func _fire_death_spiral(w: WeaponState, dmg: float, area: float):
	# Death Spiral: axes circle out from the player in all directions (boomerang ring)
	var count = 6 + projectile_bonus * 2
	var dir = direction if direction.length() > 0 else Vector2.DOWN
	
	for i in range(count):
		var angle = (TAU / count) * i
		var spawn_dir = Vector2(cos(angle), sin(angle))
		
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = max(area * 1.2, 8.0)
		s.shape = c
		p.add_child(s)
		# Visual — glowing purple axe
		var axe_sz = max(area * 2.5, 16.0)
		var vis = ColorRect.new()
		vis.color = Color(0.5, 0.3, 0.8)
		vis.size = Vector2(axe_sz, axe_sz * 0.6)
		vis.position = Vector2(-axe_sz / 2, -axe_sz * 0.3)
		p.add_child(vis)
		var edge = ColorRect.new()
		edge.color = Color(0.8, 0.4, 0.9)
		edge.size = Vector2(axe_sz * 1.1, 3)
		edge.position = Vector2(-axe_sz * 0.55, -1.5)
		p.add_child(edge)
		
		p.global_position = global_position + spawn_dir * 10
		p.rotation = angle
		get_parent().add_child(p)
		p.body_entered.connect(_on_proj_hit.bind(p, dmg))
		
		# Fly outward, then curve back toward player
		var mid = global_position + spawn_dir * 140
		var end = global_position + spawn_dir * 80 + Vector2(0, 0)  # end near player but offset
		var tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "global_position", mid, 0.3)
		tw.tween_property(p, "scale", Vector2(1.5, 1.5), 0.3)
		tw.finished.connect(_on_axe_return.bind(p, end))


func _fire_fire_wand(w: WeaponState):
	AudioManager.play_sfx("wpn_fire")
	# Explosive projectile at a random enemy
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	var target = enemies[randi() % enemies.size()]
	if not is_instance_valid(target):
		return
	var dmg = w.damage * damage_mult
	var area = w.area * area_mult
	var explosion_radius = area * 1.5
	var p = Area2D.new()
	p.collision_mask = 4
	var s = CollisionShape2D.new()
	var c = CircleShape2D.new()
	c.radius = area
	s.shape = c
	p.add_child(s)
	# Visual — fire orb
	var vis = ColorRect.new()
	vis.color = Color(0.9, 0.4, 0.1, 0.9)
	vis.size = Vector2(area * 1.8, area * 1.8)
	vis.position = Vector2(-area * 0.9, -area * 0.9)
	p.add_child(vis)
	var glow = ColorRect.new()
	glow.color = Color(1.0, 0.7, 0.2, 0.4)
	glow.size = Vector2(area * 2.6, area * 2.6)
	glow.position = Vector2(-area * 1.3, -area * 1.3)
	p.add_child(glow)
	p.global_position = global_position
	get_parent().add_child(p)
	p.body_entered.connect(_on_proj_hit.bind(p, dmg))
	var tw = create_tween()
	tw.tween_property(p, "global_position", target.global_position, 0.5)
	tw.finished.connect(_on_firewand_explode.bind(p, explosion_radius, dmg))


# ── Projectile callback helpers (no lambdas ⇒ no freed-capture errors) ──
# Signal args come first, then bound args: handler(signal..., bound...)

func _on_proj_hit(body, proj, dmg: float):
	if not is_instance_valid(body) or not is_instance_valid(proj):
		return
	if body.has_method("take_damage"):
		body.take_damage(dmg, proj.global_position)


func _on_proj_hit_and_free(body, proj, dmg: float):
	if not is_instance_valid(body) or not is_instance_valid(proj):
		return
	if body.has_method("take_damage"):
		body.take_damage(dmg, proj.global_position)
	if is_instance_valid(proj):
		proj.queue_free()


func _on_tween_done(proj):
	if is_instance_valid(proj):
		proj.queue_free()


func _on_axe_arc_done(proj, end_pos: Vector2):
	if not is_instance_valid(proj):
		return
	var tw2 = create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(proj, "global_position", end_pos, 0.4)
	tw2.tween_property(proj, "scale", Vector2(0.5, 0.5), 0.4)
	tw2.finished.connect(_on_tween_done.bind(proj))


func _on_axe_return(proj, return_pos: Vector2):
	if not is_instance_valid(proj):
		return
	# Return toward the player (updated to player's current position)
	var tw2 = create_tween()
	tw2.tween_property(proj, "global_position", return_pos, 0.5)
	tw2.tween_property(proj, "scale", Vector2(0.3, 0.3), 0.5)
	tw2.finished.connect(_on_tween_done.bind(proj))


func _on_firewand_explode(proj, explosion_radius: float, dmg: float):
	if not is_instance_valid(proj):
		return
	# Explosion: larger radius on arrival, damage nearby enemies
	var src_pos = proj.global_position
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and src_pos.distance_to(e.global_position) < explosion_radius:
			if e.has_method("take_damage"):
				e.take_damage(dmg * 0.5, src_pos)
	if is_instance_valid(proj):
		proj.queue_free()


func _on_hurt(body: Node):
	if health <= 0 or invincible > 0:
		return
	if body.has_method("get_contact_damage"):
		health -= max(body.get_contact_damage() - armor, 1.0)
		invincible = 0.3
		hurt.emit()
		if health <= 0:
			health = 0
			died.emit()
		else:
			AudioManager.play_sfx("player_hurt")


func _on_hurt_area(area: Area2D):
	# Handles enemy projectiles (Area2D with get_projectile_damage)
	if health <= 0 or invincible > 0:
		return
	if area.has_method("get_projectile_damage"):
		var dmg = area.get_projectile_damage()
		health -= max(dmg - armor * 0.5, 1.0)
		invincible = 0.3
		hurt.emit()
		if health <= 0:
			health = 0
			died.emit()
		else:
			AudioManager.play_sfx("player_hurt")


var _ft_scene = preload("res://scenes/floating_text.tscn")


func show_floating_text(txt: String, col: Color = Color.WHITE, sz: int = 16):
	var ft = _ft_scene.instantiate()
	ft.display_text = txt
	ft.text_color = col
	ft.font_size = sz
	ft.global_position = global_position + Vector2(randf_range(-10, 10), -30)
	if is_inside_tree():
		get_parent().add_child(ft)


func heal(amount: float):
	health = min(health + amount, max_health)
	show_floating_text(I18N.t("player.heal") % [int(amount)], Color(0.3, 1.0, 0.3), 16)


func _on_collect_area(area: Area2D):
	if area.has_method("collect"):
		add_xp(area.collect())


func add_xp(value: int):
	xp += int(value * growth_mult)
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		update_xp_requirements()
		show_floating_text(I18N.t("player.level_up"), Color(0.9, 0.8, 0.2), 22)
		AudioManager.play_sfx("level_up")
		leveled_up.emit()


func update_xp_requirements():
	xp_to_next = level * 10 + 5


func apply_upgrade(t: int):
	match t:
		UpgradeType.WHIP, UpgradeType.MAGIC_WAND, UpgradeType.GARLIC, \
		UpgradeType.KNIFE, UpgradeType.AXE, UpgradeType.FIRE_WAND:
			var w = _find_weapon(t)
			if w: w.upgrade()
			else: weapons.append(WeaponState.new(t))
		UpgradeType.WINGS, UpgradeType.SPINACH, UpgradeType.TOME, \
		UpgradeType.HOLLOW_HEART, UpgradeType.CANDELABRADOR, \
		UpgradeType.CROWN, UpgradeType.PUMMAROLA, \
		UpgradeType.DUPLICATOR, UpgradeType.STONE_MASK, \
		UpgradeType.MAGNET:
			var lv = passives.get(t, 0) + 1
			passives[t] = lv
	_recalculate_passives()


func _find_weapon(t: int) -> WeaponState:
	for w in weapons:
		if w.type == t: return w
	return null


func get_weapon_level(t: int) -> int:
	var w = _find_weapon(t)
	return w.level if w else 0


func get_passive_level(t: int) -> int:
	return passives.get(t, 0)


# Returns how many projectiles a weapon should fire (base + Duplicator + evolution bonus)
func get_projectile_count(weapon_type: int) -> int:
	var count = 1 + projectile_bonus
	# Weapon-specific evolution bonuses
	if weapon_type == UpgradeType.KNIFE:
		var w = _find_weapon(UpgradeType.KNIFE)
		if w and w.evolved:
			count += 2  # Thousand Edge: base 3
	elif weapon_type == UpgradeType.MAGIC_WAND:
		var w = _find_weapon(UpgradeType.MAGIC_WAND)
		if w and w.evolved:
			count += 1  # Holy Wand: double bolts
	return max(count, 1)


# Total greed multiplier from all sources (permanent powerup + in-run Stone Mask)
func get_greed_mult() -> float:
	var base = 1.0
	if PowerUpManager:
		var b = PowerUpManager.get_stat_bonuses()
		base += b["greed_pct"]
	base += greed_mult  # Stone Mask in-run bonus
	return base


func get_weapon_max_level(t: int) -> int:
	var w = _find_weapon(t)
	return w.max_level if w else 0


func can_evolve(weapon_type: int) -> bool:
	if not EVOLUTION_RECIPES.has(weapon_type):
		return false
	var w = _find_weapon(weapon_type)
	if not w or w.level < w.max_level or w.evolved:
		return false
	var recipe = EVOLUTION_RECIPES[weapon_type]
	var passive_lv = passives.get(recipe["passive"], 0)
	return passive_lv >= recipe["passive_level"]


func evolve_weapon(weapon_type: int):
	var w = _find_weapon(weapon_type)
	if not w:
		return
	w.evolve()
	var recipe = EVOLUTION_RECIPES[weapon_type]
	passives.erase(recipe["passive"])
	_recalculate_passives()
	var evo_name = I18N.t("evo." + _evo_name_key(weapon_type) + "_name")
	show_floating_text("⚡ " + evo_name + " ⚡", Color(0.9, 0.7, 0.1), 22)
	AudioManager.play_sfx("evolution")


func _apply_powerup_bonuses():
	if not PowerUpManager:
		return
	var b = PowerUpManager.get_stat_bonuses()
	damage_mult += b["damage_mult"]
	base_max_health = 100.0 * (1.0 + b["max_hp_pct"])
	max_health = base_max_health
	health = max_health
	recovery += b["recovery"]
	cooldown_reduction += b["cooldown_reduction"]
	area_mult += b["area_mult"]
	move_speed = 200.0 * (1.0 + b["move_speed_pct"])
	growth_mult += b["growth_pct"]
	armor += b["armor"]


static func _evo_name_key(weapon_type: int) -> String:
	match weapon_type:
		UpgradeType.WHIP: return "whip"
		UpgradeType.MAGIC_WAND: return "wand"
		UpgradeType.GARLIC: return "garlic"
		UpgradeType.KNIFE: return "knife"
		UpgradeType.AXE: return "axe"
	return "whip"


func _recalculate_passives():
	var old_max = max_health
	move_speed = 200.0
	damage_mult = 1.0
	cooldown_reduction = 0.0
	area_mult = 1.0
	growth_mult = 1.0
	recovery = 0.0
	projectile_bonus = 0
	greed_mult = 0.0
	pickup_range = 60.0
	max_health = base_max_health
	for t in passives:
		var lv = passives[t]
		match t:
			UpgradeType.WINGS:
				move_speed = 200.0 * (1.0 + 0.1 * lv)
			UpgradeType.SPINACH:
				damage_mult = 1.0 + 0.1 * lv
			UpgradeType.TOME:
				cooldown_reduction = 0.08 * lv
			UpgradeType.HOLLOW_HEART:
				max_health = base_max_health * (1.0 + 0.2 * lv)
			UpgradeType.CANDELABRADOR:
				area_mult = 1.0 + 0.1 * lv
			UpgradeType.CROWN:
				growth_mult = 1.0 + 0.08 * lv
			UpgradeType.PUMMAROLA:
				recovery = 0.2 * lv
			UpgradeType.DUPLICATOR:
				projectile_bonus = lv  # +1 projectile per level
			UpgradeType.STONE_MASK:
				greed_mult = 0.20 * lv  # +20% gold per level
			UpgradeType.MAGNET:
				pickup_range = 60.0 + 20.0 * lv  # +20 pickup range per level
	# Update collect area collision radius
	if _collect_shape_ref and _collect_shape_ref.shape:
		var circle = _collect_shape_ref.shape as CircleShape2D
		if circle:
			circle.radius = pickup_range
	# Scale health proportionally with max HP changes
	if max_health != old_max and old_max > 0:
		health = health * (max_health / old_max)


func _draw():
	if whip_vis_time > 0:
		var progress = 1.0 - (whip_vis_time / 0.1)  # 0→1 across the swing
		var alpha = min(whip_vis_time * 10, 0.6)
		var w_area = whip_vis_area
		# Check if the whip is evolved for red tint
		var whip_evolved = false
		for w in weapons:
			if w.type == UpgradeType.WHIP and w.evolved:
				whip_evolved = true
				break
		var base_color = Color(1.0, 0.2, 0.2) if whip_evolved else Color(1, 1, 1)
		# Direction-based sweeping arc
		var dir_angle = direction.angle()
		var arc_span = PI * 0.65  # ~117° swing arc
		var a_start = dir_angle - arc_span * 0.5
		var a_end = dir_angle + arc_span * 0.5
		var outer_r = w_area * 1.2
		# 1. Filled fan (translucent)
		var fan_pts = 16
		var fan = PackedVector2Array()
		fan.append(Vector2.ZERO)
		for i in range(fan_pts + 1):
			var a = lerp(a_start, a_end, float(i) / fan_pts)
			fan.append(Vector2(cos(a), sin(a)) * outer_r)
		draw_polygon(fan, [Color(base_color.r, base_color.g, base_color.b, alpha * 0.12)])
		# 2. Bright outer arc edge
		draw_arc(Vector2.ZERO, outer_r, a_start, a_end, 16, base_color, 3.0, true)
		# 3. Sweep highlight — moves across the arc as the whip swings
		var sweep_a = lerp(a_start + 0.05, a_end - 0.05, progress)
		draw_arc(Vector2.ZERO, outer_r * 0.85, sweep_a - 0.2, sweep_a + 0.2, 8, Color(1, 1, 1, alpha * 0.6), 4.0, true)
	for w in weapons:
		if w.type == UpgradeType.GARLIC:
			var pulse = 0.4 + sin(Time.get_ticks_msec() * 0.004) * 0.15
			var garlic_alpha = pulse * (0.4 if w.evolved else 0.25)
			var garlic_color = Color(0.8, 0.2, 1.0, garlic_alpha) if w.evolved else Color(0.5, 0.2, 0.8, garlic_alpha)
			draw_circle(Vector2.ZERO, w.area * area_mult, garlic_color)
			break
	# Direction indicator (always drawn, even during invincibility flash)
	var tip = direction * 22.0
	var perp = direction.rotated(PI / 2.0) * 7.0
	var base = direction * 12.0
	var tri = PackedVector2Array([tip, base + perp, base - perp])
	draw_polygon(tri, [Color(0.5, 0.8, 1.0, 0.8)])

	if invincible > 0 and int(invincible * 20) % 2 == 0:
		return
	# Body circle
	draw_circle(Vector2.ZERO, 18, Color(0.2, 0.4, 0.9))
	draw_circle(Vector2.ZERO, 18, Color(0.3, 0.5, 1.0), false, 2.0)


func update_visual():
	queue_redraw()
