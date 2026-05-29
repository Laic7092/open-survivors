extends RefCounted
# Enemy type definitions — data-driven stats, visuals, behaviors, drops.
# All values are base; difficulty scaling is applied in enemy.gd

class EnemyTypeData:
	var id: int
	var name: String
	var base_health: float
	var base_speed: float
	var base_damage: float
	var base_size: float        # radius multiplier (1.0 = 14px base)
	var base_xp: int
	var color: Color
	var outline_color: Color
	var outline_width: float
	var shape: String           # "circle", "triangle", "diamond", "hexagon"
	var behavior: String        # "chase", "wavy", "stationary"
	var has_ranged: bool
	var ranged_cooldown: float  # seconds between shots
	var ranged_speed: float     # projectile speed px/s
	var ranged_dmg_mult: float  # projectile damage = contact_damage * this
	var knockback_resist: float # 0.0 (full KB) to 1.0 (immune)
	var is_boss: bool
	var drop_xp_mult: float     # multiplier on base_xp
	var drop_gold_chance: float # chance to drop gold on death
	var drop_chest_chance: float # chance to drop treasure chest (boss)
	var spawn_weight: float = 1.0   # relative spawn probability; lower = rarer

	func _init(
		_id: int, _name: String,
		hp: float, spd: float, dmg: float, sz: float, xp: int,
		col: Color, ocol: Color, ow: float,
		_shape: String, _behavior: String,
		_ranged: bool, _rcooldown: float, _rspd: float, _rdmg: float,
		_kb_resist: float, _boss: bool,
		_xp_mult: float, _gold_ch: float, _chest_ch: float
	):
		id = _id; name = _name
		base_health = hp; base_speed = spd; base_damage = dmg
		base_size = sz; base_xp = xp
		color = col; outline_color = ocol; outline_width = ow
		shape = _shape; behavior = _behavior
		has_ranged = _ranged; ranged_cooldown = _rcooldown
		ranged_speed = _rspd; ranged_dmg_mult = _rdmg
		knockback_resist = _kb_resist; is_boss = _boss
		drop_xp_mult = _xp_mult; drop_gold_chance = _gold_ch
		drop_chest_chance = _chest_ch


static var _types: Array[EnemyTypeData] = []


static func _ensure_loaded():
	if _types.is_empty():
		_load_types()


static func _load_types():
	_types = [
		# 0 — Wraith (basic chaser)
		EnemyTypeData.new(
			0, "Wraith",
			14.0, 60.0, 10.0, 1.0, 2,
			Color(0.3, 0.4, 0.9), Color(0.5, 0.6, 1.0), 1.5,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.0, false,
			1.0, 0.0, 0.0
		),
		# 1 — Viper (fast swarm)
		EnemyTypeData.new(
			1, "Viper",
			6.0, 100.0, 8.0, 0.7, 1,
			Color(0.2, 0.7, 0.2), Color(0.4, 0.9, 0.3), 1.5,
			"triangle", "chase",
			false, 0.0, 0.0, 0.0,
			0.0, false,
			0.8, 0.0, 0.0
		),
		# 2 — Golem (slow tank)
		EnemyTypeData.new(
			2, "Golem",
			50.0, 30.0, 18.0, 1.6, 5,
			Color(0.4, 0.25, 0.15), Color(0.55, 0.35, 0.2), 2.5,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.3, false,
			2.0, 0.05, 0.0
		),
		# 3 — Cursed Eye (stationary ranged)
		EnemyTypeData.new(
			3, "Cursed Eye",
			18.0, 0.0, 12.0, 1.1, 4,
			Color(0.6, 0.2, 0.7), Color(0.8, 0.3, 0.9), 2.0,
			"diamond", "stationary",
			true, 2.0, 250.0, 0.8,
			0.5, false,
			1.5, 0.02, 0.0
		),
		# 4 — Mantis (erratic wavy chaser)
		EnemyTypeData.new(
			4, "Mantis",
			12.0, 70.0, 12.0, 0.9, 3,
			Color(0.85, 0.5, 0.1), Color(1.0, 0.65, 0.15), 1.5,
			"hexagon", "wavy",
			false, 0.0, 0.0, 0.0,
			0.1, false,
			1.2, 0.0, 0.0
		),
		# 5 — Nightmare (boss)
		EnemyTypeData.new(
			5, "Nightmare",
			200.0, 40.0, 25.0, 2.5, 50,
			Color(0.5, 0.05, 0.05), Color(0.7, 0.1, 0.1), 3.0,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.9, true,
			5.0, 0.3, 0.1
		),
		# 6 — Giant Crab (Dairy Plant boss, high armor, spawns adds)
		EnemyTypeData.new(
			6, "Giant Crab",
			300.0, 35.0, 20.0, 3.0, 80,
			Color(0.3, 0.6, 0.8), Color(0.5, 0.8, 1.0), 3.0,
			"hexagon", "chase",
			false, 0.0, 0.0, 0.0,
			0.95, true,
			8.0, 0.5, 0.15
		),
		# 7 — Trinacria (Gallo Tower boss, triple-form, spread projectiles)
		EnemyTypeData.new(
			7, "Trinacria",
			500.0, 30.0, 30.0, 3.5, 120,
			Color(0.8, 0.3, 0.1), Color(1.0, 0.5, 0.2), 3.5,
			"triangle", "chase",
			true, 1.5, 300.0, 1.2,
			0.9, true,
			10.0, 0.6, 0.2
		),
	]

	# Spawn weight overrides (lower = much rarer)
	for t in _types:
		match t.id:
			3: t.spawn_weight = 0.03   # Cursed Eye — greatly reduced


static func get_type(id: int) -> EnemyTypeData:
	_ensure_loaded()
	for t in _types:
		if t.id == id:
			return t
	return _types[0]


static func get_type_count() -> int:
	_ensure_loaded()
	return _types.size()


# Returns list of enemy type IDs suitable for spawning at a given stage + game time.
# Types weighted by stage affinity; later game time unlocks harder types.
static func get_types_for_stage(stage_id: int, game_time: float) -> Array[int]:
	_ensure_loaded()
	var pool: Array[int] = []

	match stage_id:
		0:  # Mad Forest — early-game types
			pool = [0, 1, 2]
			if game_time > 300.0:   # 5 min
				pool.append(3)
			if game_time > 600.0:   # 10 min
				pool.append(4)
		1:  # Inlaid Library — more ranged + magic
			pool = [0, 3]
			if game_time > 120.0:   # 2 min
				pool.append(1)
			if game_time > 360.0:   # 6 min
				pool.append(4)
			if game_time > 480.0:   # 8 min
				pool.append(2)
		2:  # Il Molise — no ranged (stationary enemies can't aim); swarm + tanks
			pool = [0, 1, 2]
			if game_time > 180.0:   # 3 min
				pool.append(4)
		3:  # Dairy Plant — factory dwellers, mixed types
			pool = [0, 1, 2, 4]
			if game_time > 180.0:   # 3 min
				pool.append(3)
			if game_time > 480.0:   # 8 min
				pool = [0, 1, 2, 3, 4]
		4:  # Gallo Tower — magic-heavy, more ranged
			pool = [1, 3, 4]
			if game_time > 120.0:
				pool.append(0)
			if game_time > 300.0:
				pool.append(2)
			if game_time > 600.0:
				pool = [0, 1, 2, 3, 4]
		5:  # Cappella Magna — full bestiary, high difficulty
			pool = [0, 1, 2, 3, 4]
			if game_time > 120.0:
				pool = [1, 2, 3, 4]
		6:  # Moongolow — aggressive, mixed types
			pool = [1, 2, 3, 4]
			if game_time > 180.0:
				pool = [0, 1, 2, 3, 4]
		7:  # Green Acres — random mix (full pool early)
			pool = [0, 1, 2, 3, 4]
		8:  # The Bone Zone — fast, aggressive
			pool = [1, 2, 4]
			if game_time > 120.0:
				pool = [0, 1, 2, 3, 4]
			if game_time > 360.0:
				pool = [1, 2, 4]  # fast types dominate
		9:  # Boss Rash — uses boss types as regular enemies
			pool = [5, 6, 7]
		10: # Whiteout — mixed with extra speed
			pool = [0, 1, 4]
			if game_time > 180.0:
				pool.append(2)
			if game_time > 360.0:
				pool.append(3)
		11: # The Lycaeum — underwater dwellers
			pool = [0, 3, 4]
			if game_time > 180.0:
				pool.append(1)
			if game_time > 360.0:
				pool.append(2)
		12: # The Coop — mostly melee swarms
			pool = [0, 1, 4]
			if game_time > 240.0:
				pool.append(2)
		13: # Space 54 — chaotic, all types
			pool = [0, 1, 2, 3, 4]
		14: # Bat Country — extreme speed + scaling
			pool = [1, 4]
			if game_time > 60.0:
				pool = [0, 1, 2, 4]
			if game_time > 180.0:
				pool = [0, 1, 2, 3, 4]
		15: # Eudaimonia Machine — endgame gauntlet
			pool = [0, 1, 2, 3, 4]
			if game_time > 180.0:
				pool = [1, 2, 3, 4, 5]
		_:
			pool = [0, 1, 2, 3, 4]

	return pool


# Returns the boss type ID for a given stage, or -1 if no boss.
static func get_boss_type(stage_id: int, game_time: float) -> int:
	_ensure_loaded()
	match stage_id:
		0, 1:  # Mad Forest, Inlaid Library — Nightmare at 15:00
			if game_time >= 900.0:
				return 5
		2:  # Il Molise — no boss (15 min stage)
			return -1
		3:  # Dairy Plant — Giant Crab at 15:00
			if game_time >= 900.0:
				return 6
		4:  # Gallo Tower — Trinacria at 15:00
			if game_time >= 900.0:
				return 7
		5:  # Cappella Magna — Nightmare (enhanced) at 15:00
			if game_time >= 900.0:
				return 5
		6:  # Moongolow — Nightmare at 7:30
			if game_time >= 450.0:
				return 5
		7, 8, 9, 10, 11, 12, 13, 14:
			# Challenge/bonus stages — no traditional boss; use scaling instead
			return -1
		15: # Eudaimonia Machine — no boss (99-min endurance)
			return -1
	return -1
