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
		UpgradeType.MAGIC_WAND: {"cd": 0.5, "dmg": 12.0, "area": 12.0, "speed": 400.0},
		UpgradeType.GARLIC: {"cd": 0.3, "dmg": 6.0, "area": 50.0, "speed": 0.0},
		UpgradeType.KNIFE: {"cd": 0.3, "dmg": 30.0, "area": 10.0, "speed": 600.0},
		UpgradeType.AXE: {"cd": 1.2, "dmg": 100.0, "area": 40.0, "speed": 0.0},
		UpgradeType.FIRE_WAND: {"cd": 0.8, "dmg": 50.0, "area": 20.0, "speed": 300.0},
		UpgradeType.CROSS: {"cd": 1.2, "dmg": 30.0, "area": 40.0, "speed": 400.0},
		UpgradeType.KING_BIBLE: {"cd": 2.0, "dmg": 15.0, "area": 50.0, "speed": 200.0},
		UpgradeType.SANTA_WATER: {"cd": 2.5, "dmg": 20.0, "area": 60.0, "speed": 0.0},
		UpgradeType.RUNETRACER: {"cd": 0.8, "dmg": 15.0, "area": 16.0, "speed": 500.0},
		UpgradeType.LIGHTNING_RING: {"cd": 2.0, "dmg": 25.0, "area": 40.0, "speed": 0.0},
	}

	func _init(t: int):
		type = t; level = 1; max_level = 8
		# Limit Break: Great Gospel relic extends weapon max level to 20
		if RelicManager.has_relic("great_gospel"):
			max_level = 20
		var b = _BASE[t]
		cooldown = b["cd"]; damage = b["dmg"]
		area = b["area"]; speed = b["speed"]
		cooldown_timer = 0.0

	func upgrade():
		level += 1
		# Diminishing returns for limit break (levels 9+)
		if level <= 8:
			cooldown = max(cooldown * 0.90, 0.1)
			damage *= 1.12
			if type == UpgradeType.GARLIC:
				area = min(area * 1.05, 100.0)
			else:
				area *= 1.08
			speed *= 1.08
		else:
			# Limit break: smaller gains past level 8
			cooldown = max(cooldown * 0.97, 0.05)
			damage *= 1.05
			if type == UpgradeType.GARLIC:
				area = min(area * 1.02, 120.0)
			else:
				area *= 1.03
			speed *= 1.03

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
var magnet_level: int = 0       # from Magnet passive
var luck: float = 0.0           # from Clover passive
var duration_bonus: float = 0.0 # from Spellbinder passive
var speed_mult: float = 1.0     # from Bracer passive
var curse: float = 0.0          # from Skull O'Maniac passive
var revivals: int = 0           # from Tiragisú passive

# Arcana overrides (set by ArcanaManager for cycling effects)
var _arcana_speed_override: float = 1.0
var _arcana_area_override: float = 1.0
var _arcana_duration_override: float = 0.0
var _crit_chance: float = 0.0
var _crit_mult: float = 2.0

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
	},
	UpgradeType.FIRE_WAND: {
		"passive": UpgradeType.SPINACH,
		"passive_level": 1,
		"name": "Hellfire",
		"desc": "Fire Wand evolves into Hellfire\nDouble explosions"
	},
	UpgradeType.CROSS: {
		"passive": UpgradeType.CLOVER,
		"passive_level": 1,
		"name": "Heaven Sword",
		"desc": "Cross evolves into Heaven Sword\nSword rains from above"
	},
	UpgradeType.KING_BIBLE: {
		"passive": UpgradeType.SPELLBINDER,
		"passive_level": 1,
		"name": "Unholy Vespers",
		"desc": "King Bible evolves into Unholy Vespers\nDual orbiting shields"
	},
	UpgradeType.SANTA_WATER: {
		"passive": UpgradeType.MAGNET,
		"passive_level": 1,
		"name": "La Borra",
		"desc": "Santa Water evolves into La Borra\nTracking damaging puddles"
	},
	UpgradeType.RUNETRACER: {
		"passive": UpgradeType.ARMOR,
		"passive_level": 1,
		"name": "NO FUTURE",
		"desc": "Runetracer evolves into NO FUTURE\nWalls of piercing lasers"
	},
	UpgradeType.LIGHTNING_RING: {
		"passive": UpgradeType.SPINACH,
		"passive_level": 3,
		"name": "Thunder Loop",
		"desc": "Lightning Ring evolves into Thunder Loop\nChain lightning"
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
var whip_hit_window: float = 0.0

var whip_vis_area: float = 60.0
var _whip_hit_this_swing: Dictionary = {}
var _wand_sfx_cooldown: float = 0.0
var _knife_sfx_cooldown: float = 0.0
var _collect_shape_ref: CollisionShape2D

# King Bible orbiting state
var _bible_projectiles: Array[Node2D] = []
var _bible_angle: float = 0.0


const CollisionLayers = preload("res://scripts/data/collision_layers.gd")


func _ready():
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
			"movespeed": move_speed += 200.0 * bonus_val
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
	if whip_hit_window > 0:
		whip_hit_window -= delta
		for w in weapons:
			if w.type == UpgradeType.WHIP:
				_check_whip_hits(w)
	for w in weapons:
		w.cooldown_timer -= delta
		if w.cooldown_timer <= 0:
			w.cooldown_timer = w.cooldown * (1.0 - cooldown_reduction)
			if not get_tree().get_nodes_in_group("enemies").is_empty():
				fire_weapon(w)
	if magnet_level > 0:
		_magnet_pull(delta)
	# King Bible orbit update
	if not _bible_projectiles.is_empty():
		_bible_projectiles = _bible_projectiles.filter(func(x): return is_instance_valid(x))
		_bible_angle += delta * 3.0  # rotation speed
		for p in _bible_projectiles:
			if not is_instance_valid(p):
				continue
			var angle = p.get_meta("orbit_angle", 0.0) + _bible_angle
			var radius = p.get_meta("orbit_radius", 60.0)
			p.global_position = global_position + Vector2(cos(angle), sin(angle)) * radius
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
		UpgradeType.CROSS: _fire_cross(w)
		UpgradeType.KING_BIBLE: _fire_king_bible(w)
		UpgradeType.SANTA_WATER: _fire_santa_water(w)
		UpgradeType.RUNETRACER: _fire_runetracer(w)
		UpgradeType.LIGHTNING_RING: _fire_lightning_ring(w)


func _fire_whip(w: WeaponState):
	AudioManager.play_sfx("wpn_whip" if not w.evolved else "wpn_evo")
	whip_vis_time = 0.1
	whip_hit_window = 0.15
	whip_vis_area = w.area * area_mult
	_whip_hit_this_swing.clear()
	_check_whip_hits(w)


func _check_whip_hits(w: WeaponState):
	var enemies = get_tree().get_nodes_in_group("enemies")
	var effective_area = w.area * area_mult
	var arc_r = effective_area * 2.0  # matches visual
	var half_w = arc_r * 0.65
	var half_h = arc_r * 0.35
	var src_pos = global_position
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var id = e.get_instance_id()
		if _whip_hit_this_swing.has(id):
			continue
		var offset = e.global_position - global_position
		# Account for enemy collision radius so partial overlap counts
		var enemy_r = 14.0
		if is_instance_valid(e.collision_shape) and e.collision_shape.shape is CircleShape2D:
			enemy_r = e.collision_shape.shape.radius * max(e.scale.x, e.scale.y)
		# Rectangle check expanded by enemy radius
		if abs(offset.x) > half_w + enemy_r or abs(offset.y) > half_h + enemy_r:
			continue
		var dmg = w.damage * damage_mult
		e.take_damage(dmg, Vector2.ZERO)
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
				e.take_damage(w.damage * damage_mult, Vector2.ZERO)
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
	var perp = Vector2(-base_dir.y, base_dir.x)  # perpendicular for offset
	
	for i in range(count):
		var dir = base_dir
		var side_offset = perp * (i - (count - 1) / 2.0) * 10.0
		
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
		# Position & rotation (with side offset)
		p.global_position = global_position + dir * 20 + side_offset
		p.rotation = dir.angle()
		get_parent().add_child(p)
		# Single-use: first hit kills the projectile
		p.body_entered.connect(_on_proj_hit_and_free.bind(p, dmg))
		var target = global_position + dir * 500.0 + side_offset
		var tw = create_tween()
		tw.tween_property(p, "global_position", target, 0.12)
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
	# Horizontal direction only (parabola always arcs upward regardless of vertical facing)
	var h_dir = Vector2(spawn_dir.x, 0.0)
	if h_dir.length_squared() < 0.01:
		h_dir = Vector2.RIGHT if spawn_dir.y >= 0 else Vector2.LEFT
	else:
		h_dir = h_dir.normalized()
	var perp = Vector2(-h_dir.y, h_dir.x)  # = Vector2(0, h_dir.x) since h_dir.y is 0
	
	for i in range(count):
		var side = perp * (i - (count - 1) / 2.0) * 25.0
		
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = area
		s.shape = c
		p.add_child(s)
		# Visual — proper axe shape
		var axe_gfx = Node2D.new()
		var axe_sz = max(area * 0.7, 14.0)
		var draw_axe = func():
			# Handle (brown wood) — longer
			axe_gfx.draw_rect(Rect2(-4, -axe_sz * 0.6, 8, axe_sz * 4.2), Color(0.4, 0.25, 0.1))
			# Blade (silver trapezoid)
			var blade = PackedVector2Array([
				Vector2(-3, -axe_sz * 1.4),
				Vector2(axe_sz * 1.4, -axe_sz * 0.8),
				Vector2(axe_sz * 1.4, axe_sz * 0.6),
				Vector2(-3, axe_sz * 1.0),
			])
			axe_gfx.draw_polygon(blade, [Color(0.6, 0.6, 0.65)])
			# Cutting edge (brighter)
			var edge_poly = PackedVector2Array([
				Vector2(axe_sz * 1.4, -axe_sz * 0.8),
				Vector2(axe_sz * 1.8, 0),
				Vector2(axe_sz * 1.4, axe_sz * 0.6),
			])
			axe_gfx.draw_polygon(edge_poly, [Color(0.8, 0.8, 0.85)])
			# Outline
			axe_gfx.draw_polyline(blade, Color(0.3, 0.3, 0.35), 2.0, true)
		axe_gfx.draw.connect(draw_axe)
		p.add_child(axe_gfx)
		# Spawn in front of player (use full direction for spawn position)
		p.global_position = global_position + spawn_dir * 20 + side
		p.rotation = h_dir.angle()
		get_parent().add_child(p)
		p.body_entered.connect(_on_proj_hit.bind(p, dmg))
		# Parabolic arc: always arcs upward, horizontal follows player facing
		var mid = global_position + h_dir * 120 + Vector2(0, -160) + side
		var end = global_position + h_dir * 320 + side
		var tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "global_position", mid, 0.6)
		tw.tween_property(p, "rotation", p.rotation - TAU * 1.5, 0.6)
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
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	var dmg = w.damage * damage_mult
	var area = w.area * area_mult
	var explosion_radius = area * 3.0
	var count = get_projectile_count(UpgradeType.FIRE_WAND)
	# Pick unique targets (or fewer if not enough enemies)
	var targets: Array = enemies.duplicate()
	targets.shuffle()
	var n = mini(count, targets.size())
	for i in range(n):
		var target = targets[i]
		if not is_instance_valid(target):
			continue
		_fire_one_fireball(target, dmg, area, explosion_radius, w)


# Fire a single fireball toward a target
func _fire_one_fireball(target: Node2D, dmg: float, area: float, explosion_radius: float, w: WeaponState):
	var p = Area2D.new()
	p.collision_mask = 4
	var s = CollisionShape2D.new()
	var c = CircleShape2D.new()
	c.radius = area * 0.8
	s.shape = c
	p.add_child(s)
	# Visual — fireball
	var fire_gfx = Node2D.new()
	var fb_sz = max(area * 0.4, 6.0)
	var seed_offset = randi() % 1000
	var draw_fire = func():
		var flicker = 0.85 + sin(Time.get_ticks_msec() * 0.015 + seed_offset) * 0.15
		var r = fb_sz * flicker
		# Outer glow (red-orange, faint)
		fire_gfx.draw_circle(Vector2.ZERO, r * 2.2, Color(0.9, 0.3, 0.05, 0.12))
		# Mid glow (orange)
		fire_gfx.draw_circle(Vector2.ZERO, r * 1.5, Color(0.95, 0.5, 0.1, 0.25))
		# Inner fire (bright orange-yellow)
		fire_gfx.draw_circle(Vector2.ZERO, r * 0.9, Color(0.95, 0.7, 0.15, 0.8))
		# Core (white-yellow)
		fire_gfx.draw_circle(Vector2.ZERO, r * 0.4, Color(1.0, 0.9, 0.5, 1.0))
	fire_gfx.draw.connect(draw_fire)
	p.add_child(fire_gfx)
	p.global_position = global_position
	get_parent().add_child(p)
	p.body_entered.connect(_on_firewand_hit.bind(p, explosion_radius, dmg, w))
	var tw = create_tween()
	tw.tween_property(p, "global_position", target.global_position, 0.5)
	p.set_meta("_wand_tween", tw)
	tw.finished.connect(_on_firewand_explode.bind(p, explosion_radius, dmg, w))


# ═══════════════════════════════════════════════════════════════
#  New Weapon Fire Methods — added in weapon-system expansion
# ═══════════════════════════════════════════════════════════════

func _fire_cross(w: WeaponState):
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	var dmg = w.damage * damage_mult
	
	if w.evolved:
		# Heaven Sword: rain swords down on random enemies
		AudioManager.play_sfx("wpn_heaven")
		var count = 3 + projectile_bonus
		for i in range(min(count, enemies.size())):
			var e = enemies[randi() % enemies.size()]
			if not is_instance_valid(e):
				continue
			# Sword falls from above
			var sword = Area2D.new()
			sword.collision_mask = 4
			var ss = CollisionShape2D.new()
			var sc = CircleShape2D.new()
			sc.radius = max(w.area * area_mult * 0.6, 6.0)
			ss.shape = sc
			sword.add_child(ss)
			var sz = max(w.area * area_mult, 12.0)
			var blade = ColorRect.new()
			blade.color = Color(0.9, 0.8, 0.4, 0.9)
			blade.size = Vector2(sz * 0.4, sz * 2.0)
			blade.position = Vector2(-sz * 0.2, -sz * 1.0)
			sword.add_child(blade)
			var tip = ColorRect.new()
			tip.color = Color(1.0, 0.9, 0.5)
			tip.size = Vector2(sz * 0.6, sz * 0.3)
			tip.position = Vector2(-sz * 0.3, -sz * 1.0)
			sword.add_child(tip)
			sword.global_position = e.global_position + Vector2(randf_range(-30, 30), -200)
			get_parent().add_child(sword)
			sword.body_entered.connect(_on_proj_hit.bind(sword, dmg))
			var tw = create_tween()
			tw.tween_property(sword, "global_position", e.global_position, 0.3)
			tw.finished.connect(_on_tween_done.bind(sword))
		return
	
	# Normal Cross: boomerang
	AudioManager.play_sfx("wpn_cross")
	var nearest: Node2D = null
	var min_dist = INF
	var ppos = global_position
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var d = ppos.distance_squared_to(e.global_position)
		if d < min_dist:
			min_dist = d
			nearest = e
	if not nearest:
		return
	var p = Area2D.new()
	p.collision_mask = 4
	var s = CollisionShape2D.new()
	var c = CircleShape2D.new()
	c.radius = max(w.area * area_mult * 0.8, 8.0)
	s.shape = c
	p.add_child(s)
	var sz = max(w.area * area_mult * 1.2, 14.0)
	var bar_h = ColorRect.new()
	bar_h.color = Color(0.9, 0.6, 0.2)
	bar_h.size = Vector2(sz * 1.6, sz * 0.3)
	bar_h.position = Vector2(-sz * 0.8, -sz * 0.15)
	p.add_child(bar_h)
	var bar_v = ColorRect.new()
	bar_v.color = Color(0.9, 0.6, 0.2)
	bar_v.size = Vector2(sz * 0.3, sz * 1.6)
	bar_v.position = Vector2(-sz * 0.15, -sz * 0.8)
	p.add_child(bar_v)
	p.global_position = global_position
	get_parent().add_child(p)
	p.body_entered.connect(_on_proj_hit.bind(p, dmg))
	var fly_time = 0.35
	var target_pos = nearest.global_position
	var tw = create_tween()
	tw.tween_property(p, "global_position", target_pos, fly_time)
	tw.tween_property(p, "global_position", global_position, fly_time * 1.2)
	tw.finished.connect(_on_boomerang_return.bind(p, dmg))


func _fire_king_bible(w: WeaponState):
	# King Bible: orbiting projectiles around the player.
	# Removes old bible projectiles on each fire (they time out naturally).
	# Each level adds +1 orbiting projectile.
	AudioManager.play_sfx("wpn_bible")
	var count = 2 + (w.level - 1)
	if w.evolved:
		count += 2  # Unholy Vespers: extra shields
	var orbit_radius = 60.0 + w.area * area_mult * 0.5
	var dmg = w.damage * damage_mult
	var dur = 2.5 + duration_bonus  # base orbit duration
	
	# Clean up old bibles that may have expired
	_bible_projectiles = _bible_projectiles.filter(func(x): return is_instance_valid(x))
	
	for i in range(count):
		# Use a dedicated timer to manage this bible's lifetime
		var angle = (TAU / count) * i + _bible_angle
		var offset = Vector2(cos(angle), sin(angle)) * orbit_radius
		
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = max(w.area * area_mult * 0.5, 6.0)
		s.shape = c
		p.add_child(s)
		# Visual — glowing orb
		var color = Color(0.3, 0.7, 1.0, 0.85) if not w.evolved else Color(0.5, 0.9, 1.0, 0.9)
		var vis = ColorRect.new()
		vis.color = color
		var orb_sz = max(w.area * area_mult * 0.8, 10.0)
		vis.size = Vector2(orb_sz, orb_sz)
		vis.position = Vector2(-orb_sz / 2, -orb_sz / 2)
		p.add_child(vis)
		# Glow ring for evolved
		if w.evolved:
			var glow = ColorRect.new()
			glow.color = Color(0.8, 0.9, 1.0, 0.3)
			glow.size = Vector2(orb_sz * 1.8, orb_sz * 1.8)
			glow.position = Vector2(-orb_sz * 0.9, -orb_sz * 0.9)
			p.add_child(glow)
		
		p.global_position = global_position + offset
		p.set_meta("orbit_angle", angle)
		p.set_meta("orbit_radius", orbit_radius)
		p.set_meta("orbit_dmg", dmg)
		get_parent().add_child(p)
		p.body_entered.connect(_on_proj_hit.bind(p, dmg))
		_bible_projectiles.append(p)
		
		# Self-destruct after duration
		var timer = Timer.new()
		timer.wait_time = dur
		timer.one_shot = true
		timer.timeout.connect(_on_bible_expire.bind(p))
		add_child(timer)
		timer.start()


func _fire_santa_water(w: WeaponState):
	AudioManager.play_sfx("wpn_water")
	var dmg = w.damage * damage_mult
	var area = w.area * area_mult
	var dur = 3.0 + duration_bonus
	
	# Drop at a random position in front of the player
	var drop_dist = 30.0 + randf_range(0, 40.0)
	var ppos = global_position + direction * drop_dist
	
	# Clamp to stage bounds
	var half_w = 1600.0
	var half_h = 1200.0
	if Engine.has_meta("selected_stage"):
		var sd = Engine.get_meta("selected_stage")
		half_w = sd.get("map_width", 3200.0) * 0.5
		half_h = sd.get("map_height", 2400.0) * 0.5
	ppos.x = clamp(ppos.x, -half_w + 30, half_w - 30)
	ppos.y = clamp(ppos.y, -half_h + 30, half_h - 30)
	
	var zone = Area2D.new()
	zone.collision_mask = 4
	var s = CollisionShape2D.new()
	var c = CircleShape2D.new()
	c.radius = area
	s.shape = c
	zone.add_child(s)
	# Visual — blue puddle
	var puddle = ColorRect.new()
	puddle.color = Color(0.1, 0.4, 0.8, 0.5)
	puddle.size = Vector2(area * 2, area * 2)
	puddle.position = Vector2(-area, -area)
	zone.add_child(puddle)
	# Border ring
	var ring = ColorRect.new()
	ring.color = Color(0.3, 0.7, 1.0, 0.6)
	ring.size = Vector2(area * 2, 4)
	ring.position = Vector2(-area, -area)
	zone.add_child(ring)
	
	zone.global_position = ppos
	get_parent().add_child(zone)
	
	# Tick damage every 0.5s for duration
	var tick_count = int(dur / 0.5)
	for i in range(tick_count):
		var timer = Timer.new()
		timer.wait_time = 0.5
		timer.one_shot = true
		timer.timeout.connect(_on_water_tick.bind(zone, area, dmg, w.evolved))
		add_child(timer)
		timer.start()
	# Cleanup
	var cleanup = Timer.new()
	cleanup.wait_time = dur
	cleanup.one_shot = true
	cleanup.timeout.connect(_on_water_cleanup.bind(zone))
	add_child(cleanup)
	cleanup.start()


func _fire_runetracer(w: WeaponState):
	var dmg = w.damage * damage_mult
	var area = w.area * area_mult
	
	if w.evolved:
		# NO FUTURE: piercing laser walls perpendicular to facing direction
		AudioManager.play_sfx("wpn_nofuture")
		var wall_len = 300.0 + 60.0 * w.level
		var wall_dur = 1.5 + duration_bonus
		var dir = direction if direction.length() > 0 else Vector2.DOWN
		var perp = Vector2(-dir.y, dir.x)  # perpendicular to facing direction
		
		for side in [-1, 1]:
			var wall = Area2D.new()
			wall.collision_mask = 4
			var ws = CollisionShape2D.new()
			var wc = RectangleShape2D.new()
			wc.size = Vector2(wall_len, 12.0)
			ws.shape = wc
			wall.add_child(ws)
			# Visual — laser beam
			var beam = ColorRect.new()
			beam.color = Color(0.9, 0.3, 0.8, 0.7)
			beam.size = Vector2(wall_len, 10)
			beam.position = Vector2(-wall_len / 2, -5)
			wall.add_child(beam)
			var glow = ColorRect.new()
			glow.color = Color(1.0, 0.6, 0.9, 0.3)
			glow.size = Vector2(wall_len + 20, 16)
			glow.position = Vector2(-wall_len / 2 - 10, -8)
			wall.add_child(glow)
			wall.global_position = global_position + perp * side * 30
			get_parent().add_child(wall)
			wall.body_entered.connect(_on_proj_hit.bind(wall, dmg * 0.3))
			var cleanup = Timer.new()
			cleanup.wait_time = wall_dur
			cleanup.one_shot = true
			cleanup.timeout.connect(wall.queue_free)
			add_child(cleanup)
			cleanup.start()
		return
	
	# Normal Runetracer
	AudioManager.play_sfx("wpn_runetracer")
	var speed = w.speed * speed_mult * 1.2
	
	var p = Area2D.new()
	p.collision_mask = 4
	var s = CollisionShape2D.new()
	var c = CircleShape2D.new()
	c.radius = max(area, 4.0)
	s.shape = c
	p.add_child(s)
	var sz = max(area * 1.5, 8.0)
	var vis = ColorRect.new()
	vis.color = Color(0.8, 0.3, 0.7, 0.9)
	vis.size = Vector2(sz, sz)
	vis.position = Vector2(-sz / 2, -sz / 2)
	p.add_child(vis)
	var inner = ColorRect.new()
	inner.color = Color(1.0, 0.6, 0.9, 0.6)
	inner.size = Vector2(sz * 0.5, sz * 0.5)
	inner.position = Vector2(-sz * 0.25, -sz * 0.25)
	p.add_child(inner)
	
	var dir = direction if direction.length() > 0 else Vector2.DOWN
	p.global_position = global_position + dir * 15
	p.set_meta("rune_dir", dir)
	p.set_meta("rune_speed", speed)
	p.set_meta("rune_bounces", 0)
	p.set_meta("rune_dmg", dmg)
	get_parent().add_child(p)
	p.body_entered.connect(_on_proj_hit.bind(p, dmg))
	
	var rune_update = Timer.new()
	rune_update.wait_time = 0.016
	rune_update.timeout.connect(_on_runetracer_tick.bind(p))
	add_child(rune_update)
	rune_update.start()
	
	var cleanup = Timer.new()
	cleanup.wait_time = 4.0
	cleanup.one_shot = true
	cleanup.timeout.connect(_on_runetracer_cleanup.bind(p, rune_update))
	add_child(cleanup)
	cleanup.start()


func _fire_lightning_ring(w: WeaponState):
	AudioManager.play_sfx("wpn_lightning")
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	# Strike random enemy
	var target = enemies[randi() % enemies.size()]
	if not is_instance_valid(target):
		return
	var dmg = w.damage * damage_mult
	var area = w.area * area_mult
	var strike_radius = area * 1.2
	
	# Lightning flash visual (brief, then fade)
	var flash = ColorRect.new()
	flash.color = Color(1.0, 1.0, 0.3, 0.7)
	var flash_sz = strike_radius * 2
	flash.size = Vector2(flash_sz, flash_sz)
	flash.position = Vector2(-flash_sz / 2, -flash_sz / 2)
	flash.global_position = target.global_position
	get_parent().add_child(flash)
	
	# Damage all enemies in radius
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	for e in all_enemies:
		if not is_instance_valid(e):
			continue
		var dist = e.global_position.distance_to(target.global_position)
		if dist <= strike_radius:
			if e.has_method("take_damage"):
				e.take_damage(dmg, target.global_position)
	
	# Flash fade
	var tw = create_tween()
	tw.tween_property(flash, "modulate", Color(1, 1, 0.3, 0), 0.15)
	tw.finished.connect(flash.queue_free)
	
	# Evolved (Thunder Loop): chain to nearby enemies
	if w.evolved:
		var chained = [target]
		var chain_dmg = dmg * 0.6
		var chain_radius = strike_radius * 0.8
		for _c in range(3):  # chain up to 3 extra hits
			var last = chained[-1]
			if not is_instance_valid(last):
				break
			var next_target: Node2D = null
			var min_d = chain_radius * chain_radius
			for e in all_enemies:
				if not is_instance_valid(e) or e == last or chained.has(e):
					continue
				var d = e.global_position.distance_squared_to(last.global_position)
				if d < min_d:
					min_d = d
					next_target = e
			if next_target:
				# Chain lightning visual
				var ch_flash = ColorRect.new()
				ch_flash.color = Color(0.6, 0.8, 1.0, 0.5)
				ch_flash.size = Vector2(flash_sz * 0.6, flash_sz * 0.6)
				ch_flash.position = Vector2(-flash_sz * 0.3, -flash_sz * 0.3)
				ch_flash.global_position = next_target.global_position
				get_parent().add_child(ch_flash)
				var tw2 = create_tween()
				tw2.tween_property(ch_flash, "modulate", Color(0.6, 0.8, 1.0, 0), 0.1)
				tw2.finished.connect(ch_flash.queue_free)
				
				if next_target.has_method("take_damage"):
					next_target.take_damage(chain_dmg, next_target.global_position)
				chained.append(next_target)


# ── Projectile callback helpers (no lambdas ⇒ no freed-capture errors) ──
# Signal args come first, then bound args: handler(signal..., bound...)

func _on_proj_hit(body, proj, dmg: float):
	if not is_instance_valid(body) or not is_instance_valid(proj):
		return
	if body.has_method("take_damage"):
		body.take_damage(dmg, Vector2.ZERO)


func _on_proj_hit_and_free(body, proj, dmg: float):
	if not is_instance_valid(body) or not is_instance_valid(proj):
		return
	if body.has_method("take_damage"):
		body.take_damage(dmg, Vector2.ZERO)
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
	tw2.tween_property(proj, "global_position", end_pos, 1.2)
	tw2.tween_property(proj, "rotation", proj.rotation - TAU * 3, 1.2)
	tw2.finished.connect(_on_tween_done.bind(proj))


func _on_axe_return(proj, return_pos: Vector2):
	if not is_instance_valid(proj):
		return
	# Return toward the player (updated to player's current position)
	var tw2 = create_tween()
	tw2.tween_property(proj, "global_position", return_pos, 0.5)
	tw2.tween_property(proj, "scale", Vector2(0.3, 0.3), 0.5)
	tw2.finished.connect(_on_tween_done.bind(proj))


func _on_firewand_hit(body, proj, explosion_radius: float, dmg: float, w: WeaponState):
	if not is_instance_valid(body) or not is_instance_valid(proj):
		return
	var pos = proj.global_position
	# Full direct damage to the hit enemy
	if body.has_method("take_damage"):
		body.take_damage(dmg, Vector2.ZERO)
	# Explode at impact point
	_explode_at(pos, explosion_radius, dmg, w)
	# Clean up projectile
	var tw = proj.get_meta("_wand_tween", null)
	if tw and is_instance_valid(tw):
		tw.kill()
	if is_instance_valid(proj):
		proj.queue_free()


func _on_firewand_explode(proj, explosion_radius: float, dmg: float, w: WeaponState = null):
	# Fallback: fireball reached destination without hitting anything — explode there
	if not is_instance_valid(proj):
		return
	_explode_at(proj.global_position, explosion_radius, dmg, w)
	if is_instance_valid(proj):
		proj.queue_free()


func _explode_at(pos: Vector2, explosion_radius: float, dmg: float, w: WeaponState):
	# Visual
	_spawn_explosion_fx(pos, explosion_radius, Color(0.9, 0.4, 0.1))
	# First explosion — full damage
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and pos.distance_to(e.global_position) < explosion_radius:
			if e.has_method("take_damage"):
				e.take_damage(dmg, Vector2.ZERO)
	# Evolved (Hellfire): second bigger explosion
	var evolved = w and w.evolved
	if evolved:
		var dbl_radius = explosion_radius * 1.6
		_spawn_explosion_fx(pos, dbl_radius, Color(1.0, 0.3, 0.0))
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e) and pos.distance_to(e.global_position) < dbl_radius:
				if e.has_method("take_damage"):
					e.take_damage(dmg, Vector2.ZERO)


func _spawn_explosion_fx(pos: Vector2, radius: float, color: Color):
	var node = Node2D.new()
	node.global_position = pos
	node.name = "FireWandExplosion"
	var lifetime = 0.3
	var draw_fn = func():
		var a = node.modulate.a
		node.draw_circle(Vector2.ZERO, radius, Color(color.r, color.g, color.b, a * 0.25))
		node.draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(color.r, color.g, color.b, a * 0.8), max(2.0, radius * 0.08))
		# Inner bright core
		node.draw_circle(Vector2.ZERO, radius * 0.35, Color(1.0, 0.8, 0.4, a * 0.6))
	node.draw.connect(draw_fn)
	get_parent().add_child(node)
	var tw = create_tween()
	tw.tween_property(node, "modulate:a", 0.0, lifetime).from(1.0)
	tw.parallel().tween_property(node, "scale", Vector2(1.6, 1.6), lifetime).from(Vector2(0.4, 0.4))
	tw.finished.connect(node.queue_free)


# ═══════════════════════════════════════════════════════════════
#  New Weapon Callbacks — added in weapon-system expansion
# ═══════════════════════════════════════════════════════════════

func _on_boomerang_return(proj, dmg: float):
	# Cross return sweep — damage enemies near return path
	if not is_instance_valid(proj):
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and proj.global_position.distance_to(e.global_position) < 50:
			if e.has_method("take_damage"):
				e.take_damage(dmg * 0.5, Vector2.ZERO)
	if is_instance_valid(proj):
		proj.queue_free()


func _on_bible_expire(proj):
	_bible_projectiles = _bible_projectiles.filter(func(x): return is_instance_valid(x) and x != proj)
	if is_instance_valid(proj):
		proj.queue_free()


func _on_water_tick(zone: Area2D, area: float, dmg: float, evolved: bool):
	if not is_instance_valid(zone):
		return
	var src_pos = zone.global_position
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if src_pos.distance_to(e.global_position) <= area:
			if e.has_method("take_damage"):
				e.take_damage(dmg * 0.25, Vector2.ZERO)
	# Evolved (La Borra): move zone toward nearest enemy
	if evolved:
		var nearest: Node2D = null
		var min_d = INF
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e):
				continue
			var d = src_pos.distance_squared_to(e.global_position)
			if d < min_d:
				min_d = d
				nearest = e
		if nearest:
			var dir = (nearest.global_position - src_pos).normalized()
			zone.global_position += dir * 30.0


func _on_water_cleanup(zone):
	if is_instance_valid(zone):
		zone.queue_free()


func _on_runetracer_tick(proj):
	if not is_instance_valid(proj):
		return
	var dir: Vector2 = proj.get_meta("rune_dir", Vector2.DOWN)
	var speed: float = proj.get_meta("rune_speed", 400.0)
	var bounces: int = proj.get_meta("rune_bounces", 0)
	var dmg: float = proj.get_meta("rune_dmg", 10.0)
	
	# Move
	proj.global_position += dir * speed * 0.016
	
	# Bounce off map bounds
	var half_w = 1600.0
	var half_h = 1200.0
	if Engine.has_meta("selected_stage"):
		var sd = Engine.get_meta("selected_stage")
		half_w = sd.get("map_width", 3200.0) * 0.5
		half_h = sd.get("map_height", 2400.0) * 0.5
	var margin = 20.0
	var bounced = false
	if proj.global_position.x < -half_w + margin:
		proj.global_position.x = -half_w + margin
		dir.x = abs(dir.x)
		bounced = true
	elif proj.global_position.x > half_w - margin:
		proj.global_position.x = half_w - margin
		dir.x = -abs(dir.x)
		bounced = true
	if proj.global_position.y < -half_h + margin:
		proj.global_position.y = -half_h + margin
		dir.y = abs(dir.y)
		bounced = true
	elif proj.global_position.y > half_h - margin:
		proj.global_position.y = half_h - margin
		dir.y = -abs(dir.y)
		bounced = true
	
	if bounced:
		bounces += 1
		proj.set_meta("rune_dir", dir)
		proj.set_meta("rune_bounces", bounces)
		AudioManager.play_sfx("wpn_bounce")
	
	# Max 4 bounces then dissipate
	if bounces >= 4:
		if is_instance_valid(proj):
			proj.queue_free()


func _on_runetracer_cleanup(proj, update_timer: Timer):
	if is_instance_valid(update_timer):
		update_timer.queue_free()
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
			if revivals > 0:
				_revive()
				return
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
			if revivals > 0:
				_revive()
				return
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
	# Arcana: Sarabande of Healing (VI) doubles healing
	var effective = amount
	if ArcanaManager and ArcanaManager.has_effect("healing_double"):
		effective = amount * ArcanaManager.get_healing_multiplier()
	health = min(health + effective, max_health)
	show_floating_text(I18N.t("player.heal") % [int(effective)], Color(0.3, 1.0, 0.3), 16)
	# Sarabande: healing damages nearby enemies
	if ArcanaManager and ArcanaManager.has_effect("healing_damages_enemies"):
		_damage_nearby_enemies(effective)


func _revive():
	revivals -= 1
	# Arcana: Awake (IV) gives revival bonuses
	if ArcanaManager and ArcanaManager.has_effect("revival_buff"):
		max_health *= 1.10
		armor += 1
		damage_mult *= 1.05
		area_mult *= 1.05
		duration_bonus += 0.05
		speed_mult *= 1.05
		# Apply Arcana main stat bonus too
		if ArcanaManager and ArcanaManager.has_effect("armor_scales_damage"):
			damage_mult += 0.1 * armor
	health = max_health * 0.5
	invincible = 2.0
	show_floating_text(I18N.t("player.revive"), Color(0.9, 0.8, 0.2), 24)
	AudioManager.play_sfx("player_revive")


# ═══════════════════════════════════════════════════════════
#  ARCANA HELPER METHODS
# ═══════════════════════════════════════════════════════════

func get_weapon_count() -> int:
	return weapons.size()


func recalculate_stats():
	# Re-read all stats from passives and re-apply arcana effects
	# This is called when an Arcana is selected mid-run
	_recalculate_passives()
	# Arcana: Silent Old Sanctuary (XX) — handled via ArcanaManager.apply_stat_modifiers
	# The manager will call this after activating


func set_speed_mult(val: float):
	_arcana_speed_override = val
	# Effective speed for projectiles
	var bracer_bonus = 0.0
	var bracer_lv = passives.get(UpgradeType.BRACER, 0)
	if bracer_lv > 0:
		bracer_bonus = 0.10 * bracer_lv
	speed_mult = (1.0 + bracer_bonus) * _arcana_speed_override


func set_area_mult_override(val: float):
	_arcana_area_override = val
	_recalculate_area()


func set_duration_bonus_override(val: float):
	_arcana_duration_override = val
	_recalculate_duration()


func add_speed_mult_pct(pct: float):
	var bracer_bonus = 0.0
	var bracer_lv = passives.get(UpgradeType.BRACER, 0)
	if bracer_lv > 0:
		bracer_bonus = 0.10 * bracer_lv
	speed_mult = (1.0 + bracer_bonus + pct) * _arcana_speed_override


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
	# Area = base * passive bonus * arcana override
	var candel_lv = passives.get(UpgradeType.CANDELABRADOR, 0)
	area_mult = 1.0 + 0.08 * candel_lv
	area_mult *= _arcana_area_override


func _recalculate_duration():
	# Duration = base + spellbinder bonus + arcana override
	var spell_lv = passives.get(UpgradeType.SPELLBINDER, 0)
	duration_bonus = 0.1 * spell_lv + _arcana_duration_override


# Sarabande of Healing: damage nearby enemies when healing
func _damage_nearby_enemies(amount: float):
	var enemies = get_tree().get_nodes_in_group("enemies")
	var pos = global_position
	for e in enemies:
		if not is_instance_valid(e):
			continue
		if pos.distance_to(e.global_position) < 100.0:
			if e.has_method("take_damage"):
				e.take_damage(amount, Vector2.ZERO)


func _on_collect_area(area: Area2D):
	if area.has_method("collect"):
		add_xp(area.collect())


func add_xp(value: int):
	# Arcana: Game Killer (0) halts XP gain
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


# Pull nearby XP gems toward the player (magnet passive).
# Similar to VACUUM pickup effect but continuous and range-limited.
func _magnet_pull(delta: float):
	var magnet_range = 80.0 + 50.0 * magnet_level   # larger than pickup_range for vacuum feel
	var pull_speed = 300.0 + 80.0 * magnet_level     # faster pull per level
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


func apply_upgrade(t: int):
	match t:
		UpgradeType.WHIP, UpgradeType.MAGIC_WAND, UpgradeType.GARLIC, \
		UpgradeType.KNIFE, UpgradeType.AXE, UpgradeType.FIRE_WAND, \
		UpgradeType.CROSS, UpgradeType.KING_BIBLE, UpgradeType.SANTA_WATER, \
		UpgradeType.RUNETRACER, UpgradeType.LIGHTNING_RING:
			var w = _find_weapon(t)
			if w: w.upgrade()
			else: weapons.append(WeaponState.new(t))
		UpgradeType.WINGS, UpgradeType.SPINACH, UpgradeType.TOME, \
		UpgradeType.HOLLOW_HEART, UpgradeType.CANDELABRADOR, \
		UpgradeType.CROWN, UpgradeType.PUMMAROLA, \
		UpgradeType.DUPLICATOR, UpgradeType.STONE_MASK, \
		UpgradeType.MAGNET, UpgradeType.CLOVER, UpgradeType.SPELLBINDER, \
		UpgradeType.ARMOR, UpgradeType.BRACER, UpgradeType.SKULL, \
		UpgradeType.TIRAGISU, UpgradeType.TORRONA, \
		UpgradeType.SILVER_RING, UpgradeType.GOLD_RING, \
		UpgradeType.METAGLIO_LEFT, UpgradeType.METAGLIO_RIGHT:
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


func get_weapon_max_level(t: int) -> int:
	var w = _find_weapon(t)
	return w.max_level if w else 8


func get_passive_level(t: int) -> int:
	return passives.get(t, 0)


# Returns how many projectiles a weapon should fire (base + Duplicator + evolution bonus)
func get_projectile_count(weapon_type: int) -> int:
	var count = 1 + projectile_bonus
	# Arcana: Beginning (X) gives +1 Amount to listed weapons
	if ArcanaManager and ArcanaManager.active_arcanas_have_weapon_effect(weapon_type, "listed_amount_plus_1"):
		count += 1
	# Arcana: Beginning (X) gives +3 Amount to main weapon (first weapon)
	if ArcanaManager and ArcanaManager.has_effect("main_weapon_amount_plus_3"):
		if weapons.size() > 0 and weapons[0].type == weapon_type:
			count += 3
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
func get_curse() -> float:
	return curse


func get_greed_mult() -> float:
	var base = 1.0
	if PowerUpManager:
		var b = PowerUpManager.get_stat_bonuses()
		base += b["greed_pct"]
	base += greed_mult  # Stone Mask in-run bonus
	return base


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


# Apply PowerUp stat bonuses only (no health reset — safe for mid-game re-calculation)
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


static func _evo_name_key(weapon_type: int) -> String:
	match weapon_type:
		UpgradeType.WHIP: return "whip"
		UpgradeType.MAGIC_WAND: return "wand"
		UpgradeType.GARLIC: return "garlic"
		UpgradeType.KNIFE: return "knife"
		UpgradeType.AXE: return "axe"
		UpgradeType.FIRE_WAND: return "firewand"
		UpgradeType.CROSS: return "cross"
		UpgradeType.KING_BIBLE: return "king_bible"
		UpgradeType.SANTA_WATER: return "santa_water"
		UpgradeType.RUNETRACER: return "runetracer"
		UpgradeType.LIGHTNING_RING: return "lightning_ring"
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
	magnet_level = 0
	luck = 0.0
	duration_bonus = 0.0
	speed_mult = 1.0
	curse = 0.0
	revivals = 0
	armor = 0.0
	pickup_range = 60.0
	max_health = base_max_health
	for t in passives:
		var lv = passives[t]
		match t:
			UpgradeType.WINGS:
				move_speed = 200.0 * (1.0 + 0.1 * lv)
			UpgradeType.SPINACH:
				damage_mult += 0.1 * lv
			UpgradeType.TOME:
				cooldown_reduction = 0.08 * lv
			UpgradeType.HOLLOW_HEART:
				max_health = base_max_health * (1.0 + 0.2 * lv)
			UpgradeType.CANDELABRADOR:
				area_mult += 0.1 * lv
			UpgradeType.CROWN:
				growth_mult = 1.0 + 0.05 * lv
			UpgradeType.PUMMAROLA:
				recovery += 0.2 * lv
			UpgradeType.DUPLICATOR:
				projectile_bonus = lv  # +1 projectile per level
			UpgradeType.STONE_MASK:
				greed_mult = 0.20 * lv  # +20% gold per level
			UpgradeType.MAGNET:
				magnet_level = lv
				pickup_range = 60.0 + 20.0 * lv  # +20 pickup range per level
			UpgradeType.CLOVER:
				luck = 0.08 * lv  # +8% luck per level
			UpgradeType.SPELLBINDER:
				duration_bonus += 0.3 * lv  # +0.3s duration per level
			UpgradeType.ARMOR:
				armor = lv  # +1 armor per level
			UpgradeType.BRACER:
				speed_mult += 0.10 * lv  # +10% projectile speed per level
			UpgradeType.SKULL:
				curse = 0.10 * lv  # +10% curse per level
			UpgradeType.TIRAGISU:
				revivals = lv  # +1 revival per level
			UpgradeType.TORRONA:
				damage_mult += 0.04 * lv
				area_mult += 0.04 * lv
				speed_mult += 0.04 * lv
				duration_bonus += 0.04 * lv
			UpgradeType.SILVER_RING:
				duration_bonus += 0.05 * lv
				area_mult += 0.05 * lv
			UpgradeType.GOLD_RING:
				curse += 0.05 * lv
			UpgradeType.METAGLIO_LEFT:
				recovery += 0.1 * lv
				max_health += base_max_health * 0.05 * lv
			UpgradeType.METAGLIO_RIGHT:
				curse += 0.05 * lv
	# Update collect area collision radius
	if _collect_shape_ref and _collect_shape_ref.shape:
		var circle = _collect_shape_ref.shape as CircleShape2D
		if circle:
			circle.radius = pickup_range
	# Re-apply character starting bonus (preserved across passive recalculations)
	if Engine.has_meta("selected_character"):
		var char_data = Engine.get_meta("selected_character")
		# New format: stats dict (supports multiple bonuses)
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
			# Legacy format fallback (bonus_type / bonus_value)
			var bonus_type = char_data.get("bonus_type", "")
			var bonus_val = char_data.get("bonus_value", 0.0)
			match bonus_type:
				"might": damage_mult += bonus_val
				"growth": growth_mult += bonus_val
				"movespeed": move_speed += 200.0 * bonus_val
				"area": area_mult += bonus_val
	# Re-apply permanent PowerUp stats (additive to passives)
	_apply_powerup_stats()
	# Scale health proportionally with max HP changes (after all overrides)
	if max_health != old_max and old_max > 0:
		health = health * (max_health / old_max)


func _draw():
	# ── Player body (draw FIRST, behind weapons) ──
	if not (invincible > 0 and int(invincible * 20) % 2 == 0):
		draw_circle(Vector2.ZERO, 18, Color(0.2, 0.4, 0.9))
		draw_circle(Vector2.ZERO, 18, Color(0.3, 0.5, 1.0), false, 2.0)
		# HP bar below player
		var hp_pct = health / max_health if max_health > 0 else 0
		var bar_w = 32.0
		var bar_h = 4.0
		var bar_y = 22.0
		draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.3, 0.05, 0.05))
		var hp_color = Color(0.9, 0.7, 0.1) if hp_pct > 0.5 else Color(0.9, 0.15, 0.15)
		draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_pct, bar_h), hp_color)

	# ── Weapons (on top of player body) ──
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
		var outer_r = w_area * 2.0
		# Simple rectangle centered on player
		var half_w = outer_r * 0.65
		var half_h = outer_r * 0.35
		var rect = Rect2(-half_w, -half_h, half_w * 2, half_h * 2)
		# 1. Filled rectangle (translucent)
		draw_rect(rect, Color(base_color.r, base_color.g, base_color.b, alpha * 0.12), true)
		# 2. Bright border
		draw_rect(rect, base_color, false, 2.5)
		# 3. Pulse highlight — shrinks from edge as swing progresses
		var pulse_inset = progress * 8.0
		var pulse_rect = Rect2(
			-half_w + pulse_inset, -half_h + pulse_inset,
			(half_w - pulse_inset) * 2, (half_h - pulse_inset) * 2
		)
		draw_rect(pulse_rect, Color(base_color.r, base_color.g, base_color.b, alpha * 0.5), false, 1.5)
	for w in weapons:
		if w.type == UpgradeType.GARLIC:
			var pulse = 0.4 + sin(Time.get_ticks_msec() * 0.004) * 0.15
			var garlic_alpha = pulse * (0.4 if w.evolved else 0.25)
			var garlic_color = Color(0.8, 0.2, 1.0, garlic_alpha) if w.evolved else Color(0.5, 0.2, 0.8, garlic_alpha)
			draw_circle(Vector2.ZERO, w.area * area_mult, garlic_color)
			break

	# ── Direction indicator (on top of everything) ──
	var tip = direction * 22.0
	var perp = direction.rotated(PI / 2.0) * 7.0
	var base = direction * 12.0
	var tri = PackedVector2Array([tip, base + perp, base - perp])
	draw_polygon(tri, [Color(0.5, 0.8, 1.0, 0.8)])


func update_visual():
	queue_redraw()
