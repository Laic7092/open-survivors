const ItemDefs = preload("res://scripts/data/item_defs.gd")

var _player
var weapons: Array[WeaponState] = []

var whip_vis_time: float = 0.0
var whip_hit_window: float = 0.0
var whip_vis_area: float = 60.0

var _whip_hit_this_swing: Dictionary = {}
var _wand_sfx_cooldown: float = 0.0
var _knife_sfx_cooldown: float = 0.0

var _bible_projectiles: Array[Node2D] = []
var _bible_angle: float = 0.0

# Cache the EnemyRegistry reference for hot path access
var _enemy_registry_cache = null


func _get_enemies() -> Array:
	# Lazily cache the EnemyRegistry autoload reference
	if _enemy_registry_cache == null:
		_enemy_registry_cache = EnemyRegistry
	if _enemy_registry_cache != null and _enemy_registry_cache.get_count() > 0:
		return _enemy_registry_cache.get_all_ref()
	return []


# Calculate damage with crit support (Clover passive)
func _calc_damage(w: WeaponState) -> float:
	var dmg = w.damage * _player.damage_mult
	if _player._crit_chance > 0 and randf() < _player._crit_chance:
		dmg *= _player._crit_mult
	return dmg


var _proj_vis_script = preload("res://scripts/entities/proj_vis.gd")
var _proj_mover_script = preload("res://scripts/entities/projectile_mover.gd")
var _explosion_fx_script = preload("res://scripts/entities/explosion_fx.gd")
var _emoji_node_script = preload("res://scripts/entities/emoji_node.gd")
var _fireball_node_script = preload("res://scripts/entities/fireball_node.gd")


const EVOLUTION_RECIPES = {
	# ── Evolution now requires the passive at MAX level ──
	# This forces players to invest heavily in passives before evolving,
	# stretching out the upgrade pipeline and creating meaningful tradeoffs.
	Player.UpgradeType.WHIP: {
		"passive": Player.UpgradeType.SPINACH,
		"passive_level": 5,
		"name": "Bloody Tear",
		"desc": "Whip evolves into Bloody Tear\nHeals 20% of damage dealt"
	},
	Player.UpgradeType.MAGIC_WAND: {
		"passive": Player.UpgradeType.WINGS,
		"passive_level": 5,
		"name": "Holy Wand",
		"desc": "Magic Wand evolves into Holy Wand\nFires at super speed"
	},
	Player.UpgradeType.GARLIC: {
		"passive": Player.UpgradeType.TOME,
		"passive_level": 5,
		"name": "Soul Eater",
		"desc": "Garlic evolves into Soul Eater\nHeals 1 HP per kill"
	},
	Player.UpgradeType.KNIFE: {
		"passive": Player.UpgradeType.CANDELABRADOR,
		"passive_level": 5,
		"name": "Thousand Edge",
		"desc": "Knife evolves into Thousand Edge\nFires a spread of 3 blades"
	},
	Player.UpgradeType.AXE: {
		"passive": Player.UpgradeType.HOLLOW_HEART,
		"passive_level": 5,
		"name": "Death Spiral",
		"desc": "Axe evolves into Death Spiral\nAxes orbit and return to you"
	},
	Player.UpgradeType.FIRE_WAND: {
		"passive": Player.UpgradeType.SPINACH,
		"passive_level": 5,
		"name": "Hellfire",
		"desc": "Fire Wand evolves into Hellfire\nDouble explosions"
	},
	Player.UpgradeType.CROSS: {
		"passive": Player.UpgradeType.CLOVER,
		"passive_level": 5,
		"name": "Heaven Sword",
		"desc": "Cross evolves into Heaven Sword\nSword rains from above"
	},
	Player.UpgradeType.KING_BIBLE: {
		"passive": Player.UpgradeType.SPELLBINDER,
		"passive_level": 5,
		"name": "Unholy Vespers",
		"desc": "King Bible evolves into Unholy Vespers\nDual orbiting shields"
	},
	Player.UpgradeType.SANTA_WATER: {
		"passive": Player.UpgradeType.MAGNET,
		"passive_level": 5,
		"name": "La Borra",
		"desc": "Santa Water evolves into La Borra\nTracking damaging puddles"
	},
	Player.UpgradeType.RUNETRACER: {
		"passive": Player.UpgradeType.ARMOR,
		"passive_level": 5,
		"name": "NO FUTURE",
		"desc": "Runetracer evolves into NO FUTURE\nWalls of piercing lasers"
	},
	Player.UpgradeType.LIGHTNING_RING: {
		"passive": Player.UpgradeType.SPINACH,
		"passive_level": 5,
		"name": "Thunder Loop",
		"desc": "Lightning Ring evolves into Thunder Loop\nChain lightning"
	},
	# ── New Weapon Evolutions ──
	Player.UpgradeType.PENTAGRAM: {
		"passive": Player.UpgradeType.CROWN,
		"passive_level": 5,
		"name": "Gorgeous Moon",
		"desc": "Pentagram evolves into Gorgeous Moon\nLarger range, lower cooldown"
	},
	Player.UpgradeType.SONG_OF_MANA: {
		"passive": Player.UpgradeType.SKULL,
		"passive_level": 5,
		"name": "Mannajja",
		"desc": "Song of Mana evolves into Mannajja\nTracking vines, full screen attack"
	},
	Player.UpgradeType.GATTI_AMARI: {
		"passive": Player.UpgradeType.STONE_MASK,
		"passive_level": 5,
		"name": "Vicious Hunger",
		"desc": "Gatti Amari evolves into Vicious Hunger\nCats pick up gold and items"
	},
	Player.UpgradeType.PHIERA_DER_TUPHELLO: {
		"passive": Player.UpgradeType.TIRAGISU,
		"passive_level": 2,
		"name": "Phieraggi",
		"desc": "Phiera + Eight evolve into Phieraggi\nUltra piercing attack"
	},
	Player.UpgradeType.EIGHT_THE_SPARROW: {
		"passive": Player.UpgradeType.TIRAGISU,
		"passive_level": 2,
		"name": "Phieraggi",
		"desc": "Phiera + Eight evolve into Phieraggi\nUltra piercing attack"
	},
	Player.UpgradeType.VICTORY_SWORD: {
		"passive": Player.UpgradeType.TORRONA,
		"passive_level": 9,
		"name": "Sole Solution",
		"desc": "Victory Sword evolves into Sole Solution\nCharges up then unleashes a massive slash"
	},
}


# Helper: creates an EmojiNode for projectile visuals (pooled approach)
func _make_emoji_node(emoji: String, sz: float) -> Node2D:
	var n = _emoji_node_script.new()
	n.setup(emoji, sz)
	return n


func _init(player: Player):
	_player = player


func add_weapon(ws: WeaponState):
	weapons.append(ws)


func add_or_upgrade(t: int):
	var w = _find_weapon(t)
	if w:
		w.upgrade()
	else:
		weapons.append(WeaponState.new(t))


# Returns true if at least one enemy is within this weapon's effective range.
func _can_fire(w: WeaponState) -> bool:
	var enemies = _get_enemies()
	if enemies.is_empty():
		return false

	var ppos = _player.global_position

	# Aura weapons (Garlic, Soul Eater) are always active — no range check needed
	if w.type == Player.UpgradeType.GARLIC:
		return true

	var range_limit: float
	match w.type:
		Player.UpgradeType.KING_BIBLE:
			range_limit = 80.0 + w.area * _player.area_mult
		Player.UpgradeType.WHIP:
			range_limit = w.area * _player.area_mult * 3.0
		Player.UpgradeType.SANTA_WATER:
			range_limit = w.area * _player.area_mult * 2.5
		_:
			range_limit = 350.0 + w.area * _player.area_mult * 3.0

	var range_sq = range_limit * range_limit
	for e in enemies:
		if is_instance_valid(e) and ppos.distance_squared_to(e.global_position) <= range_sq:
			return true
	return false


func process(delta: float):
	if _wand_sfx_cooldown > 0:
		_wand_sfx_cooldown -= delta
	if _knife_sfx_cooldown > 0:
		_knife_sfx_cooldown -= delta
	if whip_vis_time > 0:
		whip_vis_time -= delta
	if whip_hit_window > 0:
		whip_hit_window -= delta
		for w in weapons:
			if w.type == Player.UpgradeType.WHIP:
				_check_whip_hits(w)
	for w in weapons:
		w.cooldown_timer -= delta
		if w.cooldown_timer <= 0 and _can_fire(w):
			w.cooldown_timer = w.cooldown * (1.0 - _player.cooldown_reduction)
			fire_weapon(w)
	# King Bible orbit update — avoid filter() allocation every frame
	if not _bible_projectiles.is_empty():
		_bible_angle += delta * 3.0
		var i = _bible_projectiles.size() - 1
		while i >= 0:
			var p = _bible_projectiles[i]
			if not is_instance_valid(p):
				_bible_projectiles.remove_at(i)
			else:
				var angle = p.get_meta("orbit_angle", 0.0) + _bible_angle
				var radius = p.get_meta("orbit_radius", 60.0)
				p.global_position = _player.global_position + Vector2(cos(angle), sin(angle)) * radius
			i -= 1


func _find_weapon(t: int) -> WeaponState:
	for w in weapons:
		if w.type == t: return w
	return null


func get_level(t: int) -> int:
	var w = _find_weapon(t)
	return w.level if w else 0


func get_max_level(t: int) -> int:
	var w = _find_weapon(t)
	return w.max_level if w else ItemDefs.item_max_level(t)


func get_count() -> int:
	return weapons.size()


func fire_weapon(w: WeaponState):
	match w.type:
		Player.UpgradeType.WHIP: _fire_whip(w)
		Player.UpgradeType.MAGIC_WAND: _fire_wand(w)
		Player.UpgradeType.GARLIC: _fire_garlic(w)
		Player.UpgradeType.KNIFE: _fire_knife(w)
		Player.UpgradeType.AXE: _fire_axe(w)
		Player.UpgradeType.FIRE_WAND: _fire_fire_wand(w)
		Player.UpgradeType.CROSS: _fire_cross(w)
		Player.UpgradeType.KING_BIBLE: _fire_king_bible(w)
		Player.UpgradeType.SANTA_WATER: _fire_santa_water(w)
		Player.UpgradeType.RUNETRACER: _fire_runetracer(w)
		Player.UpgradeType.LIGHTNING_RING: _fire_lightning_ring(w)
		# New weapons — fire logic not yet implemented; silently skip
		Player.UpgradeType.PENTAGRAM, Player.UpgradeType.SONG_OF_MANA, \
		Player.UpgradeType.GATTI_AMARI, Player.UpgradeType.PHIERA_DER_TUPHELLO, \
		Player.UpgradeType.EIGHT_THE_SPARROW, Player.UpgradeType.VICTORY_SWORD:
			push_warning("Weapon %d fire logic not yet implemented" % w.type)


func get_projectile_count(weapon_type: int) -> int:
	var count = 1 + _player.projectile_bonus
	if ArcanaManager and ArcanaManager.active_arcanas_have_weapon_effect(weapon_type, "listed_amount_plus_1"):
		count += 1
	if ArcanaManager and ArcanaManager.has_effect("main_weapon_amount_plus_3"):
		if weapons.size() > 0 and weapons[0].type == weapon_type:
			count += 3
	if weapon_type == Player.UpgradeType.KNIFE:
		var w = _find_weapon(Player.UpgradeType.KNIFE)
		if w and w.evolved:
			count += 2
	elif weapon_type == Player.UpgradeType.MAGIC_WAND:
		var w = _find_weapon(Player.UpgradeType.MAGIC_WAND)
		if w and w.evolved:
			count += 1
	return max(count, 1)


func can_evolve(weapon_type: int) -> bool:
	if not EVOLUTION_RECIPES.has(weapon_type):
		return false
	var w = _find_weapon(weapon_type)
	if not w or w.level < w.max_level or w.evolved:
		return false
	var recipe = EVOLUTION_RECIPES[weapon_type]
	var passive_lv = _player.passive_inventory.get_level(recipe["passive"])
	return passive_lv >= recipe["passive_level"]


func evolve_weapon(weapon_type: int):
	var w = _find_weapon(weapon_type)
	if not w:
		return
	w.evolve()
	var recipe = EVOLUTION_RECIPES[weapon_type]
	_player.passive_inventory.remove(recipe["passive"])
	_player.recalculate_stats()
	var evo_name = I18N.t("evo." + _evo_name_key(weapon_type) + "_name")
	_player.show_floating_text("⚡ " + evo_name + " ⚡", Color(0.9, 0.7, 0.1), 22)
	AudioManager.play_sfx("evolution")


static func _evo_name_key(weapon_type: int) -> String:
	match weapon_type:
		Player.UpgradeType.WHIP: return "whip"
		Player.UpgradeType.MAGIC_WAND: return "wand"
		Player.UpgradeType.GARLIC: return "garlic"
		Player.UpgradeType.KNIFE: return "knife"
		Player.UpgradeType.AXE: return "axe"
		Player.UpgradeType.FIRE_WAND: return "firewand"
		Player.UpgradeType.CROSS: return "cross"
		Player.UpgradeType.KING_BIBLE: return "king_bible"
		Player.UpgradeType.SANTA_WATER: return "santa_water"
		Player.UpgradeType.RUNETRACER: return "runetracer"
		Player.UpgradeType.LIGHTNING_RING: return "lightning_ring"
	return "whip"


# ── WHIP ─────────────────────────────────────────────────────────────

func _fire_whip(w: WeaponState):
	AudioManager.play_sfx("wpn_whip" if not w.evolved else "wpn_evo")
	whip_vis_time = 0.1
	whip_hit_window = 0.15
	whip_vis_area = w.area * _player.area_mult
	_whip_hit_this_swing.clear()
	_check_whip_hits(w)


func _check_whip_hits(w: WeaponState):
	var enemies = _get_enemies()
	var effective_area = w.area * _player.area_mult
	var arc_r = effective_area * 2.0
	var half_w = arc_r * 0.50
	var half_h = arc_r * 0.30
	var src_pos = _player.global_position
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var id = e.get_instance_id()
		if _whip_hit_this_swing.has(id):
			continue
		var offset = e.global_position - _player.global_position
		var enemy_r = 14.0
		if is_instance_valid(e.collision_shape) and e.collision_shape.shape is CircleShape2D:
			enemy_r = e.collision_shape.shape.radius * max(e.scale.x, e.scale.y)
		if abs(offset.x) > half_w + enemy_r or abs(offset.y) > half_h + enemy_r:
			continue
		var dmg = _calc_damage(w)
		e.take_damage(dmg, Vector2.ZERO)
		if w.evolved:
			_player.health = min(_player.health + dmg * 0.2, _player.max_health)
		_whip_hit_this_swing[id] = true


# ── MAGIC WAND ───────────────────────────────────────────────────────

func _fire_wand(w: WeaponState):
	var enemies = _get_enemies()
	if enemies.is_empty():
		return
	var dmg = _calc_damage(w)
	var area = w.area * _player.area_mult
	var count = get_projectile_count(Player.UpgradeType.MAGIC_WAND)

	# Sort a copy to avoid modifying the registry's internal array
	var sorted = enemies.duplicate()
	sorted.sort_custom(func(a, b): 
		if not is_instance_valid(a) or not is_instance_valid(b):
			return false
		return _player.global_position.distance_squared_to(a.global_position) < _player.global_position.distance_squared_to(b.global_position))
	# Limit to max targeting range (scales with area so Candelabrador extends reach)
	var max_range_wsq: float = (350.0 + w.area * _player.area_mult * 3.0)
	max_range_wsq *= max_range_wsq
	sorted = sorted.filter(func(e): return is_instance_valid(e) and _player.global_position.distance_squared_to(e.global_position) <= max_range_wsq)
	var targets = sorted.slice(0, min(count, sorted.size()))
	if targets.is_empty():
		return

	if _wand_sfx_cooldown <= 0:
		AudioManager.play_sfx("wpn_wand" if not w.evolved else "wpn_evo")
		_wand_sfx_cooldown = 0.3

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
		p.global_position = _player.global_position
		var vis = Node2D.new()
		vis.set_script(_proj_vis_script)
		p.add_child(vis)
		_player.get_parent().add_child(p)
		p.body_entered.connect(_on_proj_hit.bind(p, dmg))
		# Use projectile_mover instead of Tween for linear movement
		var dir = (target.global_position - _player.global_position).normalized()
		var mover = Node2D.new()
		mover.set_script(_proj_mover_script)
		mover.set_movement(dir * w.speed, _player.global_position.distance_to(target.global_position) / max(w.speed, 1.0))
		p.add_child(mover)


# ── GARLIC ───────────────────────────────────────────────────────────

func _fire_garlic(w: WeaponState):
	var enemies = _get_enemies()
	var effective_area = w.area * _player.area_mult
	var ppos = _player.global_position
	for e in enemies:
		if not is_instance_valid(e):
			continue
		# Account for enemy collision radius — partial overlap counts
		var enemy_r = 14.0
		if is_instance_valid(e.collision_shape) and e.collision_shape.shape is CircleShape2D:
			enemy_r = e.collision_shape.shape.radius * max(e.scale.x, e.scale.y)
		if ppos.distance_to(e.global_position) - enemy_r < effective_area:
			if e.has_method("take_damage"):
				e.take_damage(_calc_damage(w), Vector2.ZERO)
				if w.evolved:
					_player.health = min(_player.health + 1.0, _player.max_health)


# ── KNIFE ────────────────────────────────────────────────────────────

func _fire_knife(w: WeaponState):
	if _knife_sfx_cooldown <= 0:
		AudioManager.play_sfx("wpn_knife" if not w.evolved else "wpn_evo")
		_knife_sfx_cooldown = 0.3
	var dmg = _calc_damage(w)
	var area = w.area * _player.area_mult
	var count = get_projectile_count(Player.UpgradeType.KNIFE)
	var base_dir = _player.direction if _player.direction.length() > 0 else Vector2.DOWN
	var perp = Vector2(-base_dir.y, base_dir.x)

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
		var knife_emoji = _make_emoji_node("🗡️", max(area * 1.2, 16.0))
		p.add_child(knife_emoji)
		p.global_position = _player.global_position + dir * 20 + side_offset
		p.rotation = dir.angle()
		_player.get_parent().add_child(p)
		p.body_entered.connect(_on_proj_hit_and_free.bind(p, dmg))
		# Use projectile_mover instead of Tween for linear movement
		var mover = Node2D.new()
		mover.set_script(_proj_mover_script)
		mover.set_movement(dir * w.speed, 500.0 / max(w.speed, 1.0))
		p.add_child(mover)


# ── AXE ──────────────────────────────────────────────────────────────

func _fire_axe(w: WeaponState):
	AudioManager.play_sfx("wpn_axe" if not w.evolved else "wpn_evo")
	var dmg = _calc_damage(w)
	var area = w.area * _player.area_mult * 0.5

	if w.evolved:
		_fire_death_spiral(w, dmg, area)
	else:
		_fire_axe_normal(w, dmg, area)


func _fire_axe_normal(w: WeaponState, dmg: float, area: float):
	var count = get_projectile_count(Player.UpgradeType.AXE)
	var spawn_dir = _player.direction if _player.direction.length() > 0 else Vector2.DOWN
	var h_dir = Vector2(spawn_dir.x, 0.0)
	if h_dir.length_squared() < 0.01:
		h_dir = Vector2.RIGHT if spawn_dir.y >= 0 else Vector2.LEFT
	else:
		h_dir = h_dir.normalized()
	var perp = Vector2(-h_dir.y, h_dir.x)

	for i in range(count):
		var side = perp * (i - (count - 1) / 2.0) * 25.0

		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = area
		s.shape = c
		p.add_child(s)
		var axe_emoji = _make_emoji_node("🪓", max(area * 1.3, 16.0))
		p.add_child(axe_emoji)
		p.global_position = _player.global_position + spawn_dir * 20 + side
		p.rotation = h_dir.angle()
		_player.get_parent().add_child(p)
		p.body_entered.connect(_on_proj_hit.bind(p, dmg))
		var mid = _player.global_position + h_dir * 120 + Vector2(0, -160) + side
		var end = _player.global_position + h_dir * 320 + side
		var tw = _player.create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "global_position", mid, 0.6)
		tw.tween_property(p, "rotation", p.rotation - TAU * 1.5, 0.6)
		tw.finished.connect(_on_axe_arc_done.bind(p, end))


func _fire_death_spiral(w: WeaponState, dmg: float, area: float):
	var count = 6 + _player.projectile_bonus * 2
	var dir = _player.direction if _player.direction.length() > 0 else Vector2.DOWN

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
		var axe_sz = max(area * 2.5, 16.0)
		var death_emoji = _make_emoji_node("🪓", axe_sz)
		p.add_child(death_emoji)

		p.global_position = _player.global_position + spawn_dir * 10
		p.rotation = angle
		_player.get_parent().add_child(p)
		p.body_entered.connect(_on_proj_hit.bind(p, dmg))

		var mid = _player.global_position + spawn_dir * 140
		var end = _player.global_position + spawn_dir * 80
		var tw = _player.create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "global_position", mid, 0.3)
		tw.tween_property(p, "scale", Vector2(1.5, 1.5), 0.3)
		tw.finished.connect(_on_axe_return.bind(p, end))


# ── FIRE WAND ────────────────────────────────────────────────────────

func _fire_fire_wand(w: WeaponState):
	var enemies = _get_enemies()
	if enemies.is_empty():
		return
	var dmg = _calc_damage(w)
	var area = w.area * _player.area_mult
	var explosion_radius = area * 1.5
	var count = get_projectile_count(Player.UpgradeType.FIRE_WAND)
	# Limit to max targeting range
	var max_range_fsq: float = (350.0 + w.area * _player.area_mult * 3.0)
	max_range_fsq *= max_range_fsq
	var targets: Array = enemies.duplicate()
	targets = targets.filter(func(e): return is_instance_valid(e) and _player.global_position.distance_squared_to(e.global_position) <= max_range_fsq)
	if targets.is_empty():
		return
	AudioManager.play_sfx("wpn_fire")
	targets.shuffle()
	var n = mini(count, targets.size())
	for i in range(n):
		var target = targets[i]
		if not is_instance_valid(target):
			continue
		_fire_one_fireball(target, dmg, area, explosion_radius, w)


func _fire_one_fireball(target: Node2D, dmg: float, area: float, explosion_radius: float, w: WeaponState):
	var p = Area2D.new()
	p.collision_mask = 4
	var s = CollisionShape2D.new()
	var c = CircleShape2D.new()
	c.radius = area * 0.8
	s.shape = c
	p.add_child(s)
	# Use pre-defined FireballNode instead of dynamic draw closure
	var fire_gfx = _fireball_node_script.new()
	fire_gfx.fb_size = max(area * 0.4, 6.0)
	fire_gfx.seed_offset = randi() % 1000
	p.add_child(fire_gfx)
	p.global_position = _player.global_position
	_player.get_parent().add_child(p)
	p.body_entered.connect(_on_firewand_hit.bind(p, explosion_radius, dmg, w))
	# Use projectile_mover instead of Tween for linear movement
	var dir = (target.global_position - _player.global_position).normalized()
	var mover = _proj_mover_script.new()
	var travel_time = _player.global_position.distance_to(target.global_position) / max(w.speed, 1.0)
	mover.set_movement(dir * w.speed, travel_time)
	p.add_child(mover)
	var tw = _player.create_tween()
	tw.tween_interval(travel_time)
	tw.finished.connect(_on_firewand_explode.bind(p, explosion_radius, dmg, w))


# ── CROSS ────────────────────────────────────────────────────────────

func _fire_cross(w: WeaponState):
	var enemies = _get_enemies()
	if enemies.is_empty():
		return
	var dmg = _calc_damage(w)

	if w.evolved:
		var count = 3 + _player.projectile_bonus
		# Heaven Sword also respects targeting range
		var max_range_hsq: float = (400.0 + w.area * _player.area_mult * 3.0)
		max_range_hsq *= max_range_hsq
		var in_range = enemies.filter(func(e): return is_instance_valid(e) and _player.global_position.distance_squared_to(e.global_position) <= max_range_hsq)
		if in_range.is_empty():
			return
		AudioManager.play_sfx("wpn_heaven")
		for i in range(min(count, in_range.size())):
			var e = in_range[randi() % in_range.size()]
			if not is_instance_valid(e):
				continue
			var sword = Area2D.new()
			sword.collision_mask = 4
			var ss = CollisionShape2D.new()
			var sc = CircleShape2D.new()
			sc.radius = max(w.area * _player.area_mult * 0.6, 6.0)
			ss.shape = sc
			sword.add_child(ss)
			var sz = max(w.area * _player.area_mult, 12.0)
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
			_player.get_parent().add_child(sword)
			sword.body_entered.connect(_on_proj_hit.bind(sword, dmg))
			var tw = _player.create_tween()
			tw.tween_property(sword, "global_position", e.global_position, 0.3)
			tw.finished.connect(_on_tween_done.bind(sword))
		return

	# Limit to max targeting range
	var max_range_csq: float = (350.0 + w.area * _player.area_mult * 3.0)
	max_range_csq *= max_range_csq
	var nearest: Node2D = null
	var min_dist = max_range_csq
	var ppos = _player.global_position
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var d = ppos.distance_squared_to(e.global_position)
		if d < min_dist:
			min_dist = d
			nearest = e
	if not nearest:
		return
	AudioManager.play_sfx("wpn_cross")
	var p = Area2D.new()
	p.collision_mask = 4
	var s = CollisionShape2D.new()
	var c = CircleShape2D.new()
	c.radius = max(w.area * _player.area_mult * 0.8, 8.0)
	s.shape = c
	p.add_child(s)
	var sz = max(w.area * _player.area_mult * 1.2, 14.0)
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
	p.global_position = _player.global_position
	_player.get_parent().add_child(p)
	p.body_entered.connect(_on_proj_hit.bind(p, dmg))
	var target_pos = nearest.global_position
	var fly_time = _player.global_position.distance_to(target_pos) / max(w.speed, 1.0)
	var tw = _player.create_tween()
	tw.tween_property(p, "global_position", target_pos, fly_time)
	tw.tween_property(p, "global_position", _player.global_position, fly_time * 1.2)
	tw.finished.connect(_on_boomerang_return.bind(p, dmg))


# ── KING BIBLE ───────────────────────────────────────────────────────

func _fire_king_bible(w: WeaponState):
	AudioManager.play_sfx("wpn_bible")
	var count = 2 + (w.level - 1)
	if w.evolved:
		count += 2
	var orbit_radius = 60.0 + w.area * _player.area_mult * 0.5
	var dmg = _calc_damage(w)
	var dur = 2.5 + _player.duration_bonus

	_bible_projectiles = _bible_projectiles.filter(func(x): return is_instance_valid(x))

	for i in range(count):
		var angle = (TAU / count) * i + _bible_angle
		var offset = Vector2(cos(angle), sin(angle)) * orbit_radius

		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = max(w.area * _player.area_mult * 0.5, 6.0)
		s.shape = c
		p.add_child(s)
		var color = Color(0.3, 0.7, 1.0, 0.85) if not w.evolved else Color(0.5, 0.9, 1.0, 0.9)
		var vis = ColorRect.new()
		vis.color = color
		var orb_sz = max(w.area * _player.area_mult * 0.8, 10.0)
		vis.size = Vector2(orb_sz, orb_sz)
		vis.position = Vector2(-orb_sz / 2, -orb_sz / 2)
		p.add_child(vis)
		if w.evolved:
			var glow = ColorRect.new()
			glow.color = Color(0.8, 0.9, 1.0, 0.3)
			glow.size = Vector2(orb_sz * 1.8, orb_sz * 1.8)
			glow.position = Vector2(-orb_sz * 0.9, -orb_sz * 0.9)
			p.add_child(glow)

		p.global_position = _player.global_position + offset
		p.set_meta("orbit_angle", angle)
		p.set_meta("orbit_radius", orbit_radius)
		p.set_meta("orbit_dmg", dmg)
		_player.get_parent().add_child(p)
		p.body_entered.connect(_on_proj_hit.bind(p, dmg))
		_bible_projectiles.append(p)

		# Use SceneTree.create_timer() instead of Timer.new() (no Node overhead)
		_player.get_tree().create_timer(dur).timeout.connect(_on_bible_expire.bind(p))


# ── SANTA WATER ──────────────────────────────────────────────────────

func _fire_santa_water(w: WeaponState):
	AudioManager.play_sfx("wpn_water")
	var dmg = _calc_damage(w)
	var area = w.area * _player.area_mult
	var dur = 3.0 + _player.duration_bonus

	var drop_dist = 30.0 + randf_range(0, 40.0)
	var ppos = _player.global_position + _player.direction * drop_dist

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
	var puddle = ColorRect.new()
	puddle.color = Color(0.1, 0.4, 0.8, 0.5)
	puddle.size = Vector2(area * 2, area * 2)
	puddle.position = Vector2(-area, -area)
	zone.add_child(puddle)
	var ring = ColorRect.new()
	ring.color = Color(0.3, 0.7, 1.0, 0.6)
	ring.size = Vector2(area * 2, 4)
	ring.position = Vector2(-area, -area)
	zone.add_child(ring)

	zone.global_position = ppos
	_player.get_parent().add_child(zone)

	var tick_count = int(dur / 0.5)
	for i in range(1, tick_count + 1):
		# SceneTree.create_timer() is lighter than Timer.new()
		_player.get_tree().create_timer(0.5 * i).timeout.connect(_on_water_tick.bind(zone, area, dmg, w.evolved))
	_player.get_tree().create_timer(dur).timeout.connect(_on_water_cleanup.bind(zone))


# ── RUNETRACER ───────────────────────────────────────────────────────

func _fire_runetracer(w: WeaponState):
	var dmg = _calc_damage(w)
	var area = w.area * _player.area_mult

	if w.evolved:
		AudioManager.play_sfx("wpn_nofuture")
		var wall_len = 300.0 + 60.0 * w.level
		var wall_dur = 1.5 + _player.duration_bonus
		var dir = _player.direction if _player.direction.length() > 0 else Vector2.DOWN
		var perp = Vector2(-dir.y, dir.x)

		for side in [-1, 1]:
			var wall = Area2D.new()
			wall.collision_mask = 4
			var ws = CollisionShape2D.new()
			var wc = RectangleShape2D.new()
			wc.size = Vector2(wall_len, 12.0)
			ws.shape = wc
			wall.add_child(ws)
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
			wall.global_position = _player.global_position + perp * side * 30
			_player.get_parent().add_child(wall)
			wall.body_entered.connect(_on_proj_hit.bind(wall, dmg * 0.3))
			_player.get_tree().create_timer(wall_dur).timeout.connect(wall.queue_free)
		return

	AudioManager.play_sfx("wpn_runetracer")
	var speed = w.speed * _player.speed_mult * 1.2

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

	var dir = _player.direction if _player.direction.length() > 0 else Vector2.DOWN
	p.global_position = _player.global_position + dir * 15
	p.set_meta("rune_dir", dir)
	p.set_meta("rune_speed", speed)
	p.set_meta("rune_bounces", 0)
	p.set_meta("rune_dmg", dmg)
	_player.get_parent().add_child(p)
	p.body_entered.connect(_on_proj_hit.bind(p, dmg))

	# Use process-based update via a Node2D child on the player
	var updater = Node2D.new()
	updater.name = "RuneTracerUpdater"
	var rune_p = p
	var rune_lifetime = 4.0
	updater.set_script(preload("res://scripts/entities/runetracer_updater.gd"))
	updater.set_meta("rune_proj", rune_p)
	_player.add_child(updater)


# ── LIGHTNING RING ───────────────────────────────────────────────────

func _fire_lightning_ring(w: WeaponState):
	var enemies = _get_enemies()
	if enemies.is_empty():
		return
	# Limit to max targeting range
	var max_range_lsq: float = (350.0 + w.area * _player.area_mult * 3.0)
	max_range_lsq *= max_range_lsq
	var in_range = enemies.filter(func(e): return is_instance_valid(e) and _player.global_position.distance_squared_to(e.global_position) <= max_range_lsq)
	if in_range.is_empty():
		return
	AudioManager.play_sfx("wpn_lightning")
	var target = in_range[randi() % in_range.size()]
	if not is_instance_valid(target):
		return
	var dmg = _calc_damage(w)
	var area = w.area * _player.area_mult
	var strike_radius = area * 1.2

	var flash = ColorRect.new()
	flash.color = Color(1.0, 1.0, 0.3, 0.7)
	var flash_sz = strike_radius * 2
	flash.size = Vector2(flash_sz, flash_sz)
	flash.position = Vector2(-flash_sz / 2, -flash_sz / 2)
	flash.global_position = target.global_position
	_player.get_parent().add_child(flash)

	var all_enemies = _get_enemies()
	for e in all_enemies:
		if not is_instance_valid(e):
			continue
		var dist = e.global_position.distance_to(target.global_position)
		if dist <= strike_radius:
			if e.has_method("take_damage"):
				e.take_damage(dmg, target.global_position)

	var tw = _player.create_tween()
	tw.tween_property(flash, "modulate", Color(1, 1, 0.3, 0), 0.15)
	tw.finished.connect(flash.queue_free)

	if w.evolved:
		var chained = [target]
		var chain_dmg = dmg * 0.6
		var chain_radius = strike_radius * 0.8
		for _c in range(5):
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
				var ch_flash = ColorRect.new()
				ch_flash.color = Color(0.6, 0.8, 1.0, 0.5)
				ch_flash.size = Vector2(flash_sz * 0.6, flash_sz * 0.6)
				ch_flash.position = Vector2(-flash_sz * 0.3, -flash_sz * 0.3)
				ch_flash.global_position = next_target.global_position
				_player.get_parent().add_child(ch_flash)
				var tw2 = _player.create_tween()
				tw2.tween_property(ch_flash, "modulate", Color(0.6, 0.8, 1.0, 0), 0.1)
				tw2.finished.connect(ch_flash.queue_free)

				if next_target.has_method("take_damage"):
					next_target.take_damage(chain_dmg, next_target.global_position)
				chained.append(next_target)


# ── Projectile callback helpers ──────────────────────────────────────

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
	var tw2 = _player.create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(proj, "global_position", end_pos, 0.5)
	tw2.tween_property(proj, "rotation", proj.rotation - TAU * 1.5, 0.5)
	tw2.finished.connect(_on_tween_done.bind(proj))


func _on_axe_return(proj, return_pos: Vector2):
	if not is_instance_valid(proj):
		return
	var tw2 = _player.create_tween()
	tw2.tween_property(proj, "global_position", return_pos, 0.5)
	tw2.tween_property(proj, "scale", Vector2(0.3, 0.3), 0.5)
	tw2.finished.connect(_on_tween_done.bind(proj))


func _on_firewand_hit(body, proj, explosion_radius: float, dmg: float, w: WeaponState):
	if not is_instance_valid(body) or not is_instance_valid(proj):
		return
	var pos = proj.global_position
	if body.has_method("take_damage"):
		body.take_damage(dmg, Vector2.ZERO)
	_explode_at(pos, explosion_radius, dmg, w)
	if is_instance_valid(proj):
		# Mark mover as hit to stop movement
		for c in proj.get_children():
			if c.has_method("mark_hit"):
				c.mark_hit()
		proj.queue_free()


func _on_firewand_explode(proj, explosion_radius: float, dmg: float, w: WeaponState = null):
	if not is_instance_valid(proj):
		return
	_explode_at(proj.global_position, explosion_radius, dmg, w)
	if is_instance_valid(proj):
		proj.queue_free()


func _explode_at(pos: Vector2, explosion_radius: float, dmg: float, w: WeaponState):
	_spawn_explosion_fx(pos, explosion_radius, Color(0.9, 0.4, 0.1))
	var enemies = _get_enemies()
	for e in enemies:
		if is_instance_valid(e) and pos.distance_to(e.global_position) < explosion_radius:
			if e.has_method("take_damage"):
				e.take_damage(dmg, Vector2.ZERO)
	var evolved = w and w.evolved
	if evolved:
		var dbl_radius = explosion_radius * 1.6
		_spawn_explosion_fx(pos, dbl_radius, Color(1.0, 0.3, 0.0))
		for e in enemies:
			if is_instance_valid(e) and pos.distance_to(e.global_position) < dbl_radius:
				if e.has_method("take_damage"):
					e.take_damage(dmg, Vector2.ZERO)


func _spawn_explosion_fx(pos: Vector2, radius: float, color: Color):
	var node = _explosion_fx_script.new()
	node._radius = radius
	node._color = color
	node.global_position = pos
	node.name = "FireWandExplosion"
	_player.get_parent().add_child(node)
	var lifetime = 0.3
	var tw = _player.create_tween()
	tw.tween_property(node, "modulate:a", 0.0, lifetime).from(1.0)
	tw.parallel().tween_property(node, "scale", Vector2(1.6, 1.6), lifetime).from(Vector2(0.4, 0.4))
	tw.finished.connect(node.queue_free)


func _on_boomerang_return(proj, dmg: float):
	if not is_instance_valid(proj):
		return
	for e in _get_enemies():
		if is_instance_valid(e) and proj.global_position.distance_to(e.global_position) < 50:
			if e.has_method("take_damage"):
				e.take_damage(dmg * 0.75, Vector2.ZERO)
	if is_instance_valid(proj):
		proj.queue_free()


func _on_bible_expire(proj):
	var idx = _bible_projectiles.find(proj)
	if idx >= 0:
		_bible_projectiles.remove_at(idx)
	if is_instance_valid(proj):
		proj.queue_free()


func _on_water_tick(zone: Area2D, area: float, dmg: float, evolved: bool):
	if not is_instance_valid(zone):
		return
	var src_pos = zone.global_position
	for e in _get_enemies():
		if not is_instance_valid(e):
			continue
		if src_pos.distance_to(e.global_position) <= area:
			if e.has_method("take_damage"):
				e.take_damage(dmg * 0.5, Vector2.ZERO)
	if evolved:
		var nearest: Node2D = null
		var min_d = INF
		for e in _get_enemies():
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

	proj.global_position += dir * speed * 0.016

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

	if bounces >= 4:
		if is_instance_valid(proj):
			proj.queue_free()


func _on_runetracer_cleanup(proj, update_timer: Timer):
	if is_instance_valid(update_timer):
		update_timer.queue_free()
	if is_instance_valid(proj):
		proj.queue_free()
