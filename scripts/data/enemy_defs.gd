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
			14.0, 45.0, 10.0, 1.0, 2,
			Color(0.3, 0.4, 0.9), Color(0.5, 0.6, 1.0), 1.5,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.0, false,
			1.0, 0.0, 0.0
		),
		# 1 — Viper (fast swarm)
		EnemyTypeData.new(
			1, "Viper",
			6.0, 75.0, 8.0, 0.7, 1,
			Color(0.2, 0.7, 0.2), Color(0.4, 0.9, 0.3), 1.5,
			"triangle", "chase",
			false, 0.0, 0.0, 0.0,
			0.0, false,
			0.8, 0.0, 0.0
		),
		# 2 — Golem (slow tank)
		EnemyTypeData.new(
			2, "Golem",
			50.0, 24.0, 18.0, 1.6, 5,
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
			12.0, 55.0, 12.0, 0.9, 3,
			Color(0.85, 0.5, 0.1), Color(1.0, 0.65, 0.15), 1.5,
			"hexagon", "wavy",
			false, 0.0, 0.0, 0.0,
			0.1, false,
			1.2, 0.0, 0.0
		),
		# 5 — Nightmare (boss)
		EnemyTypeData.new(
			5, "Nightmare",
			200.0, 32.0, 25.0, 2.5, 50,
			Color(0.5, 0.05, 0.05), Color(0.7, 0.1, 0.1), 3.0,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.9, true,
			5.0, 0.3, 0.1
		),
		# 6 — Giant Crab (Dairy Plant boss, high armor, spawns adds)
		EnemyTypeData.new(
			6, "Giant Crab",
			300.0, 28.0, 20.0, 3.0, 80,
			Color(0.3, 0.6, 0.8), Color(0.5, 0.8, 1.0), 3.0,
			"hexagon", "chase",
			false, 0.0, 0.0, 0.0,
			0.95, true,
			8.0, 0.5, 0.15
		),
		# 7 — Trinacria (Gallo Tower boss, triple-form, spread projectiles)
		EnemyTypeData.new(
			7, "Trinacria",
			500.0, 24.0, 30.0, 3.5, 120,
			Color(0.8, 0.3, 0.1), Color(1.0, 0.5, 0.2), 3.5,
			"triangle", "chase",
			true, 1.5, 300.0, 1.2,
			0.9, true,
			10.0, 0.6, 0.2
		),
		# 8 — Zombie (Mad Forest early enemy)
		EnemyTypeData.new(
			8, "Zombie",
			18.0, 30.0, 10.0, 1.1, 3,
			Color(0.35, 0.3, 0.25), Color(0.45, 0.4, 0.3), 1.5,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.3, false,
			1.0, 0.0, 0.0
		),
		# 9 — Skeleton (Mad Forest mid enemy)
		EnemyTypeData.new(
			9, "Skeleton",
			22.0, 40.0, 12.0, 1.0, 4,
			Color(0.5, 0.45, 0.35), Color(0.6, 0.55, 0.4), 1.5,
			"diamond", "chase",
			false, 0.0, 0.0, 0.0,
			0.2, false,
			1.5, 0.01, 0.0
		),
		# 10 — Ghost (Mad Forest mid enemy)
		EnemyTypeData.new(
			10, "Ghost",
			15.0, 60.0, 8.0, 0.9, 5,
			Color(0.5, 0.5, 0.7, 0.6), Color(0.6, 0.6, 0.9), 1.5,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.0, false,
			1.2, 0.0, 0.0
		),
		# 11 — Bat (basic swarm, fast fragile)
		EnemyTypeData.new(
			11, "Bat",
			8.0, 80.0, 6.0, 0.6, 1,
			Color(0.25, 0.15, 0.35), Color(0.35, 0.25, 0.45), 1.0,
			"triangle", "chase",
			false, 0.0, 0.0, 0.0,
			0.0, false,
			0.5, 0.0, 0.0
		),
		# 12 — Red-Eyed Bat (stronger bat)
		EnemyTypeData.new(
			12, "Red-Eyed Bat",
			12.0, 75.0, 8.0, 0.7, 2,
			Color(0.5, 0.1, 0.1), Color(0.6, 0.15, 0.15), 1.0,
			"triangle", "chase",
			false, 0.0, 0.0, 0.0,
			0.0, false,
			0.8, 0.0, 0.0
		),
		# 13 — Giant Bat (large slow bat)
		EnemyTypeData.new(
			13, "Giant Bat",
			45.0, 35.0, 15.0, 1.8, 8,
			Color(0.3, 0.15, 0.25), Color(0.4, 0.2, 0.3), 2.0,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.2, false,
			2.0, 0.02, 0.0
		),
		# 14 — Glowing Bat (special mini-boss, drops chests)
		EnemyTypeData.new(
			14, "Glowing Bat",
			60.0, 60.0, 12.0, 1.2, 15,
			Color(0.9, 0.8, 0.2), Color(1.0, 0.9, 0.3), 2.0,
			"triangle", "chase",
			false, 0.0, 0.0, 0.0,
			0.5, false,
			3.0, 0.1, 0.3
		),
		# 15 — Mudman (slow tank)
		EnemyTypeData.new(
			15, "Mudman",
			50.0, 25.0, 18.0, 1.5, 6,
			Color(0.3, 0.25, 0.15), Color(0.4, 0.35, 0.2), 2.0,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.4, false,
			2.0, 0.05, 0.0
		),
		# 16 — Green Mudman (poison variant)
		EnemyTypeData.new(
			16, "Green Mudman",
			40.0, 30.0, 14.0, 1.3, 5,
			Color(0.2, 0.4, 0.2), Color(0.3, 0.5, 0.3), 2.0,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.3, false,
			1.5, 0.02, 0.0
		),
		# 17 — Mantichana (lion-scorpion, mid-boss)
		EnemyTypeData.new(
			17, "Mantichana",
			120.0, 50.0, 20.0, 1.8, 25,
			Color(0.8, 0.4, 0.1), Color(0.9, 0.5, 0.15), 2.5,
			"hexagon", "chase",
			true, 3.0, 200.0, 0.7,
			0.6, true,
			4.0, 0.15, 0.05
		),
		# 18 — Werewolf (fast aggressive)
		EnemyTypeData.new(
			18, "Werewolf",
			60.0, 65.0, 18.0, 1.4, 10,
			Color(0.4, 0.3, 0.2), Color(0.5, 0.4, 0.25), 2.0,
			"triangle", "chase",
			false, 0.0, 0.0, 0.0,
			0.2, false,
			2.5, 0.03, 0.0
		),
		# 19 — Big Mummy (large slow)
		EnemyTypeData.new(
			19, "Big Mummy",
			100.0, 18.0, 22.0, 2.0, 12,
			Color(0.4, 0.35, 0.2), Color(0.5, 0.45, 0.25), 2.5,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.7, false,
			3.0, 0.05, 0.0
		),
		# 20 — Venus (plant boss)
		EnemyTypeData.new(
			20, "Venus",
			150.0, 20.0, 25.0, 2.2, 30,
			Color(0.6, 0.1, 0.3), Color(0.7, 0.15, 0.35), 2.5,
			"circle", "stationary",
			true, 2.5, 220.0, 1.0,
			0.8, true,
			5.0, 0.2, 0.1
		),
		# 21 — Giant Blue Venus (stage boss)
		EnemyTypeData.new(
			21, "Giant Blue Venus",
			500.0, 15.0, 35.0, 3.5, 100,
			Color(0.1, 0.3, 0.8), Color(0.2, 0.4, 0.9), 3.0,
			"circle", "stationary",
			true, 1.5, 280.0, 1.2,
			0.9, true,
			10.0, 0.4, 0.15
		),
		# 22 — The Reaper (death, 30min+)
		EnemyTypeData.new(
			22, "The Reaper",
			999999.0, 120.0, 999.0, 3.0, 999,
			Color(0.1, 0.1, 0.1), Color(0.5, 0.0, 0.0), 3.0,
			"diamond", "chase",
			false, 0.0, 0.0, 0.0,
			1.0, true,
			0.0, 0.0, 0.0
		),
	]

	# Spawn weight overrides (lower = much rarer)
	for t in _types:
		match t.id:
			3:  t.spawn_weight = 0.03   # Cursed Eye — greatly reduced
			13: t.spawn_weight = 0.08   # Giant Bat — rarer
			14: t.spawn_weight = 0.02   # Glowing Bat — very rare mini-boss
			17: t.spawn_weight = 0.04   # Mantichana — rare mid-boss
			18: t.spawn_weight = 0.15   # Werewolf — uncommon
			19: t.spawn_weight = 0.10   # Big Mummy — uncommon
			20: t.spawn_weight = 0.01   # Venus — very rare
			21: t.spawn_weight = 0.005  # Giant Blue Venus — stage boss only
			22: t.spawn_weight = 0.0    # The Reaper — never random spawn


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

	var early := game_time < 180.0
	var mid := game_time >= 180.0 and game_time < 480.0
	var late := game_time >= 480.0

	match stage_id:
		0:  # Mad Forest — VS timeline
			if game_time < 60.0:
				pool = [11, 12]                # Bats only (0:00-1:00)
			elif game_time < 120.0:
				pool = [8, 11, 12]             # +Zombie (1:00-2:00)
			elif game_time < 180.0:
				pool = [9, 11, 12]             # +Skeleton (2:00-3:00)
			elif game_time < 240.0:
				pool = [8, 9, 10]              # Skeletons + Ghosts
			elif game_time < 300.0:
				pool = [15, 16]                # Mudmen (5:00)
			elif game_time < 480.0:
				pool = [8, 9, 10, 15, 16]      # Mid: all basic
			elif game_time < 720.0:
				pool = [9, 10, 15, 16, 18]     # +Werewolf (12:00)
			elif game_time < 1020.0:
				pool = [10, 13, 15, 16, 18, 19]  # +Giant Bat, Big Mummy (17:00)
			elif game_time < 1260.0:
				pool = [13, 15, 16, 18, 19, 20]  # +Venus (21:00)
			else:
				pool = [8, 13, 15, 16, 18, 19, 20]  # late (25:00+)
		1:  # Inlaid Library — ranged focus
			if early:
				pool = [0, 3]           # Wraith + Cursed Eye
			elif mid:
				pool = [0, 1, 3]        # +Viper
			elif late:
				pool = [0, 1, 2, 3, 4]  # full
		2:  # Il Molise — swarm + tanks
			if early:
				pool = [0, 1]
			elif mid:
				pool = [0, 1, 2, 4]
			elif late:
				pool = [0, 1, 2, 4]
		3:  # Dairy Plant — mixed
			if early:
				pool = [0, 1, 4]
			elif mid:
				pool = [0, 1, 2, 4]
			elif late:
				pool = [0, 1, 2, 3, 4]
		4:  # Gallo Tower — magic-heavy
			if early:
				pool = [1, 3]           # Viper + Cursed Eye
			elif mid:
				pool = [0, 1, 3, 4]
			elif late:
				pool = [0, 1, 2, 3, 4]
		5:  # Cappella Magna — full bestiary
			if early:
				pool = [1, 2, 3, 4]
			elif mid:
				pool = [0, 1, 2, 3, 4]
			elif late:
				pool = [1, 2, 3, 4]     # drop easy Wraiths
		6:  # Moongolow — aggressive
			if early:
				pool = [1, 2, 4]
			elif mid:
				pool = [0, 1, 2, 3, 4]
			elif late:
				pool = [1, 2, 3, 4]
		7:  # Green Acres — all mix
			if early:
				pool = [0, 1, 2, 3]
			elif mid:
				pool = [0, 1, 2, 3, 4]
			elif late:
				pool = [0, 2, 3, 4]
		8:  # The Bone Zone — fast/aggressive
			if early:
				pool = [1, 4]
			elif mid:
				pool = [0, 1, 2, 4]
			elif late:
				pool = [1, 2, 4]
		9:  # Boss Rash
			pool = [5, 6, 7]
		10: # Whiteout
			if early:
				pool = [0, 1, 4]
			elif mid:
				pool = [0, 1, 2, 4]
			elif late:
				pool = [0, 1, 2, 3, 4]
		11: # The Lycaeum
			if early:
				pool = [0, 3, 4]
			elif mid:
				pool = [0, 1, 3, 4]
			elif late:
				pool = [0, 1, 2, 3, 4]
		12: # The Coop — melee swarms
			if early:
				pool = [0, 1]
			elif mid:
				pool = [0, 1, 4]
			elif late:
				pool = [0, 1, 2, 4]
		13: # Space 54 — chaotic
			pool = [0, 1, 2, 3, 4]
		14: # Bat Country — extreme
			if early:
				pool = [1, 4]
			elif mid:
				pool = [0, 1, 2, 4]
			elif late:
				pool = [0, 1, 2, 3, 4]
		15: # Eudaimonia Machine — endgame
			if early:
				pool = [1, 2, 3, 4]
			elif mid:
				pool = [1, 2, 3, 4, 5]
			elif late:
				pool = [1, 2, 3, 4, 5]
		_:
			pool = [0, 1, 2, 3, 4]

	return pool


# Picks a weighted random type from the pool. Rarer types appear less often.
static func pick_weighted(pool: Array[int]) -> int:
	_ensure_loaded()
	if pool.is_empty():
		return 0
	if pool.size() == 1:
		return pool[0]
	
	var total_weight := 0.0
	for id in pool:
		var t = get_type(id)
		total_weight += t.spawn_weight
	
	var roll = randf() * total_weight
	var accum := 0.0
	for id in pool:
		var t = get_type(id)
		accum += t.spawn_weight
		if roll < accum:
			return id
	return pool[-1]


# Returns the boss type ID for a given stage, or -1 if no boss.
static func get_boss_type(stage_id: int, game_time: float) -> int:
	_ensure_loaded()
	match stage_id:
		0:  # Mad Forest — VS boss timeline
			if game_time >= 1800.0:
				return 22   # The Reaper at 30:00
			if game_time >= 1500.0:
				return 21   # Giant Blue Venus at 25:00
			if game_time >= 900.0:
				return 20   # Venus at 15:00
			if game_time >= 600.0:
				return 17   # Mantichana at 10:00
			if game_time >= 300.0:
				return 14   # Glowing Bat at 5:00
			return -1
		1:  # Inlaid Library — Nightmare at 15:00
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
