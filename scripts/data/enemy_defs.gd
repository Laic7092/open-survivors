extends RefCounted
# Enemy type definitions — data-driven stats, visuals, behaviors, drops.
# All values are base; difficulty scaling is applied in enemy.gd
#
# Base game coverage: bestiary entries 001–163 from Vampire Survivors wiki.
# DLC enemies (Moonspell, Foscari, Emergency Meeting, etc.) are NOT included.

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

	# Special flags
	var has_hp_x_level: bool = false   # HP multiplied by player level
	var has_three_lives: bool = false  # revives twice after death
	var is_fixed_direction: bool = false # moves in straight line only
	var ignores_collision: bool = false  # passes through other enemies
	var is_self_destruct: bool = false   # explodes on death/contact

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
		# ═══════════════════════════════════════════════════════════════
		#  MAD FOREST (stages 0, 7)
		# ═══════════════════════════════════════════════════════════════
		# 0 — Pipeestrello / Wraith (basic chaser, bestiary 001)
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
		# 6 — Giant Enemy Crab (Dairy Plant / Gallo Tower boss, bestiary 058)
		EnemyTypeData.new(
			6, "Giant Enemy Crab",
			300.0, 28.0, 20.0, 3.0, 80,
			Color(0.3, 0.6, 0.8), Color(0.5, 0.8, 1.0), 3.0,
			"hexagon", "chase",
			false, 0.0, 0.0, 0.0,
			0.95, true,
			8.0, 0.5, 0.15
		),
		# 7 — Trinacria (Gallo Tower / Cappella Magna boss, bestiary 117)
		EnemyTypeData.new(
			7, "Trinacria",
			500.0, 24.0, 30.0, 3.5, 120,
			Color(0.8, 0.3, 0.1), Color(1.0, 0.5, 0.2), 3.5,
			"triangle", "chase",
			true, 1.5, 300.0, 1.2,
			0.9, true,
			10.0, 0.6, 0.2
		),
		# 8 — Zombie (Mad Forest early enemy, bestiary 007)
		EnemyTypeData.new(
			8, "Zombie",
			18.0, 30.0, 10.0, 1.1, 3,
			Color(0.35, 0.3, 0.25), Color(0.45, 0.4, 0.3), 1.5,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.3, false,
			1.0, 0.0, 0.0
		),
		# 9 — Skeleton (Mad Forest / Dairy Plant, bestiary 006)
		EnemyTypeData.new(
			9, "Skeleton",
			22.0, 40.0, 12.0, 1.0, 4,
			Color(0.5, 0.45, 0.35), Color(0.6, 0.55, 0.4), 1.5,
			"diamond", "chase",
			false, 0.0, 0.0, 0.0,
			0.2, false,
			1.5, 0.01, 0.0
		),
		# 10 — Ghost (Mad Forest / Inlaid Library, bestiary 011)
		EnemyTypeData.new(
			10, "Ghost",
			15.0, 60.0, 8.0, 0.9, 5,
			Color(0.5, 0.5, 0.7, 0.6), Color(0.6, 0.6, 0.9), 1.5,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.0, false,
			1.2, 0.0, 0.0
		),
		# 11 — Bat (basic swarm, fast fragile, bestiary variant)
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
		# 13 — Giant Bat (large slow bat, bestiary 034)
		EnemyTypeData.new(
			13, "Giant Bat",
			45.0, 35.0, 15.0, 1.8, 8,
			Color(0.3, 0.15, 0.25), Color(0.4, 0.2, 0.3), 2.0,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.2, false,
			2.0, 0.02, 0.0
		),
		# 14 — Glowing Bat / LV128 Golden Bat (mini-boss, drops chests, bestiary 130)
		EnemyTypeData.new(
			14, "Glowing Bat",
			60.0, 60.0, 12.0, 1.2, 15,
			Color(0.9, 0.8, 0.2), Color(1.0, 0.9, 0.3), 2.0,
			"triangle", "chase",
			false, 0.0, 0.0, 0.0,
			0.5, false,
			3.0, 0.1, 0.3
		),
		# 15 — Mudman (slow tank, Mad Forest, bestiary 008)
		EnemyTypeData.new(
			15, "Mudman",
			50.0, 25.0, 18.0, 1.5, 6,
			Color(0.3, 0.25, 0.15), Color(0.4, 0.35, 0.2), 2.0,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.4, false,
			2.0, 0.05, 0.0
		),
		# 16 — Green Mudman (poison variant, Mad Forest)
		EnemyTypeData.new(
			16, "Green Mudman",
			40.0, 30.0, 14.0, 1.3, 5,
			Color(0.2, 0.4, 0.2), Color(0.3, 0.5, 0.3), 2.0,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.3, false,
			1.5, 0.02, 0.0
		),
		# 17 — Mantichana (lion-scorpion, mid-boss, Mad Forest, bestiary 035)
		EnemyTypeData.new(
			17, "Mantichana",
			120.0, 50.0, 20.0, 1.8, 25,
			Color(0.8, 0.4, 0.1), Color(0.9, 0.5, 0.15), 2.5,
			"hexagon", "chase",
			true, 3.0, 200.0, 0.7,
			0.6, true,
			4.0, 0.15, 0.05
		),
		# 18 — Werewolf (fast aggressive, Mad Forest, bestiary 012)
		EnemyTypeData.new(
			18, "Werewolf",
			60.0, 65.0, 18.0, 1.4, 10,
			Color(0.4, 0.3, 0.2), Color(0.5, 0.4, 0.25), 2.0,
			"triangle", "chase",
			false, 0.0, 0.0, 0.0,
			0.2, false,
			2.5, 0.03, 0.0
		),
		# 19 — Big Mummy (large slow, Mad Forest, bestiary 036)
		EnemyTypeData.new(
			19, "Big Mummy",
			100.0, 18.0, 22.0, 2.0, 12,
			Color(0.4, 0.35, 0.2), Color(0.5, 0.45, 0.25), 2.5,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.7, false,
			3.0, 0.05, 0.0
		),
		# 20 — Venus (plant boss, Mad Forest, bestiary 037)
		EnemyTypeData.new(
			20, "Venus",
			150.0, 20.0, 25.0, 2.2, 30,
			Color(0.6, 0.1, 0.3), Color(0.7, 0.15, 0.35), 2.5,
			"circle", "stationary",
			true, 2.5, 220.0, 1.0,
			0.8, true,
			5.0, 0.2, 0.1
		),
		# 21 — Giant Blue Venus (Mad Forest stage boss, bestiary 037 boss)
		EnemyTypeData.new(
			21, "Giant Blue Venus",
			500.0, 15.0, 35.0, 3.5, 100,
			Color(0.1, 0.3, 0.8), Color(0.2, 0.4, 0.9), 3.0,
			"circle", "stationary",
			true, 1.5, 280.0, 1.2,
			0.9, true,
			10.0, 0.4, 0.15
		),
		# 22 — The Reaper (death, 30min+, bestiary 119)
		EnemyTypeData.new(
			22, "The Reaper",
			999999.0, 120.0, 999.0, 3.0, 999,
			Color(0.1, 0.1, 0.1), Color(0.5, 0.0, 0.0), 3.0,
			"diamond", "chase",
			false, 0.0, 0.0, 0.0,
			1.0, true,
			0.0, 0.0, 0.0
		),

		# ═══════════════════════════════════════════════════════════════
		#  INLAID LIBRARY (stage 1)
		# ═══════════════════════════════════════════════════════════════
		# 23 — Dust Elemental (Inlaid Library ground, bestiary 013)
		EnemyTypeData.new(
			23, "Dust Elemental",
			30.0, 30.0, 12.0, 1.3, 4,
			Color(0.55, 0.4, 0.25), Color(0.7, 0.55, 0.35), 2.0,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.2, false,
			1.5, 0.02, 0.0
		),
		# 24 — Musc Musc (floating ghost, Inlaid Library, bestiary 024)
		EnemyTypeData.new(
			24, "Musc Musc",
			12.0, 50.0, 8.0, 0.9, 3,
			Color(0.5, 0.1, 0.5), Color(0.7, 0.2, 0.7), 1.5,
			"circle", "chase",
			true, 3.0, 200.0, 0.6,
			0.0, false,
			1.0, 0.0, 0.0
		),
		# 25 — Medusa Head / Sneaky Head (stationary ranged, Inlaid Library, bestiary 022)
		EnemyTypeData.new(
			25, "Sneaky Head",
			20.0, 0.0, 15.0, 1.0, 5,
			Color(0.2, 0.6, 0.2), Color(0.3, 0.8, 0.3), 2.0,
			"diamond", "stationary",
			true, 2.5, 250.0, 0.8,
			0.4, false,
			1.5, 0.02, 0.0
		),
		# 26 — Mummy (slow melee, Inlaid Library, bestiary 021)
		EnemyTypeData.new(
			26, "Mummy",
			25.0, 35.0, 12.0, 1.2, 4,
			Color(0.6, 0.5, 0.3), Color(0.7, 0.6, 0.4), 2.0,
			"hexagon", "chase",
			false, 0.0, 0.0, 0.0,
			0.3, false,
			1.2, 0.01, 0.0
		),
		# 27 — Lionhead (fast aggressive, Inlaid Library, bestiary 014)
		EnemyTypeData.new(
			27, "Lionhead",
			40.0, 45.0, 18.0, 1.4, 8,
			Color(0.8, 0.4, 0.1), Color(0.9, 0.55, 0.15), 2.5,
			"triangle", "chase",
			false, 0.0, 0.0, 0.0,
			0.2, false,
			2.0, 0.03, 0.0
		),
		# 28 — Dullahan / Testa di Mano (erratic floating, Inlaid Library, bestiary 026)
		EnemyTypeData.new(
			28, "Dullahan",
			15.0, 60.0, 10.0, 0.8, 3,
			Color(0.5, 0.5, 0.5), Color(0.65, 0.65, 0.65), 1.5,
			"triangle", "wavy",
			false, 0.0, 0.0, 0.0,
			0.0, false,
			0.8, 0.0, 0.0
		),
		# 29 — Apprentice Witch (ranged caster, Inlaid Library, bestiary variant)
		EnemyTypeData.new(
			29, "Apprentice Witch",
			18.0, 40.0, 14.0, 1.0, 5,
			Color(0.5, 0.2, 0.6), Color(0.7, 0.3, 0.8), 2.0,
			"diamond", "chase",
			true, 2.0, 220.0, 0.7,
			0.1, false,
			1.5, 0.01, 0.0
		),
		# 30 — Elite Dullahan (fast tough hand, Inlaid Library, bestiary 026 boss)
		EnemyTypeData.new(
			30, "Elite Dullahan",
			30.0, 70.0, 16.0, 1.1, 6,
			Color(0.3, 0.3, 0.3), Color(0.5, 0.5, 0.5), 2.0,
			"triangle", "wavy",
			false, 0.0, 0.0, 0.0,
			0.2, false,
			2.0, 0.03, 0.0
		),
		# 31 — Glowing Skull (fast fragile, Inlaid Library, bestiary 088)
		EnemyTypeData.new(
			31, "Glowing Skull",
			12.0, 55.0, 8.0, 0.7, 3,
			Color(0.8, 0.8, 0.6), Color(1.0, 1.0, 0.8), 1.5,
			"diamond", "chase",
			false, 0.0, 0.0, 0.0,
			0.0, false,
			0.8, 0.0, 0.0
		),
		# 32 — Giant Medusa (large stationary ranged, Inlaid Library semi-boss)
		EnemyTypeData.new(
			32, "Giant Medusa",
			60.0, 0.0, 20.0, 2.0, 15,
			Color(0.1, 0.5, 0.1), Color(0.2, 0.7, 0.2), 2.5,
			"hexagon", "stationary",
			true, 2.0, 280.0, 1.0,
			0.6, false,
			3.0, 0.05, 0.0
		),

		# ═══════════════════════════════════════════════════════════════
		#  GENERIC / BONUS STAGE ENEMIES
		# ═══════════════════════════════════════════════════════════════
		# 33 — Scylla (many-headed hydra, mid-boss)
		EnemyTypeData.new(
			33, "Scylla",
			150.0, 30.0, 22.0, 2.0, 20,
			Color(0.2, 0.6, 0.3), Color(0.3, 0.8, 0.4), 2.5,
			"hexagon", "chase",
			false, 0.0, 0.0, 0.0,
			0.5, true,
			4.0, 0.1, 0.05
		),
		# 34 — Slasher (fast melee skirmisher)
		EnemyTypeData.new(
			34, "Slasher",
			18.0, 70.0, 14.0, 0.9, 4,
			Color(0.7, 0.2, 0.2), Color(0.9, 0.3, 0.3), 1.5,
			"triangle", "chase",
			false, 0.0, 0.0, 0.0,
			0.1, false,
			1.0, 0.01, 0.0
		),
		# 35 — Trickster (erratic teleporting / wavy, boss, bestiary 120)
		EnemyTypeData.new(
			35, "Trickster",
			22.0, 50.0, 12.0, 1.0, 5,
			Color(0.5, 0.1, 0.5), Color(0.7, 0.2, 0.6), 2.0,
			"diamond", "wavy",
			false, 0.0, 0.0, 0.0,
			0.2, false,
			1.2, 0.02, 0.0
		),

		# ═══════════════════════════════════════════════════════════════
		#  INLAID LIBRARY — additional enemies (bestiary 017–020, 029–033)
		# ═══════════════════════════════════════════════════════════════
		# 36 — Sig.ra Rossi (self-destruct shade bomb, Inlaid Library, bestiary 017)
		EnemyTypeData.new(
			36, "Sig.ra Rossi",
			8.0, 0.0, 25.0, 1.0, 6,
			Color(0.3, 0.1, 0.5), Color(0.5, 0.2, 0.7), 2.0,
			"diamond", "stationary",
			false, 0.0, 0.0, 0.0,
			0.0, false,
			2.0, 0.02, 0.0
		),
		# 37 — Hag (resistant, HPxLevel, Inlaid Library, bestiary 019)
		EnemyTypeData.new(
			37, "Hag",
			100.0, 28.0, 20.0, 1.6, 15,
			Color(0.1, 0.4, 0.3), Color(0.2, 0.6, 0.4), 2.5,
			"hexagon", "chase",
			true, 3.0, 180.0, 0.8,
			0.7, true,
			4.0, 0.15, 0.08
		),
		# 38 — Nesufritto (freeze resistant, HPxLevel, Inlaid Library, bestiary 020)
		EnemyTypeData.new(
			38, "Nesufritto",
			80.0, 35.0, 18.0, 1.5, 12,
			Color(0.5, 0.3, 0.1), Color(0.6, 0.4, 0.15), 2.0,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.5, false,
			3.0, 0.08, 0.0
		),
		# 39 — Merdusa (Inlaid Library, bestiary 033)
		EnemyTypeData.new(
			39, "Merdusa",
			14.0, 0.0, 10.0, 0.9, 4,
			Color(0.3, 0.7, 0.3), Color(0.4, 0.9, 0.4), 1.5,
			"diamond", "stationary",
			true, 2.0, 220.0, 0.7,
			0.2, false,
			1.2, 0.01, 0.0
		),
		# 40 — Undead Witch (Inlaid Library, bestiary 029)
		EnemyTypeData.new(
			40, "Undead Witch",
			20.0, 45.0, 12.0, 1.0, 5,
			Color(0.3, 0.2, 0.5), Color(0.4, 0.3, 0.6), 1.5,
			"diamond", "chase",
			true, 2.5, 200.0, 0.6,
			0.15, false,
			1.5, 0.01, 0.0
		),
		# 41 — Undead Sassy Witch (Inlaid Library, bestiary 030)
		EnemyTypeData.new(
			41, "Undead Sassy Witch",
			25.0, 50.0, 14.0, 1.1, 6,
			Color(0.5, 0.2, 0.4), Color(0.7, 0.3, 0.5), 2.0,
			"diamond", "chase",
			true, 2.0, 230.0, 0.7,
			0.2, false,
			1.8, 0.02, 0.0
		),

		# ═══════════════════════════════════════════════════════════════
		#  DAIRY PLANT (stage 3)
		# ═══════════════════════════════════════════════════════════════
		# 42 — Milk Elemental (Dairy Plant, bestiary 015)
		EnemyTypeData.new(
			42, "Milk Elemental",
			35.0, 35.0, 14.0, 1.2, 5,
			Color(0.8, 0.8, 0.7), Color(0.9, 0.9, 0.85), 1.5,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.1, false,
			1.5, 0.02, 0.0
		),
		# 43 — Merman (Dairy Plant / Moongolow, bestiary 038)
		EnemyTypeData.new(
			43, "Merman",
			30.0, 40.0, 14.0, 1.2, 5,
			Color(0.2, 0.5, 0.3), Color(0.3, 0.6, 0.4), 2.0,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.2, false,
			1.5, 0.02, 0.0
		),
		# 44 — Lizard Pawn (Dairy Plant, bestiary 039)
		EnemyTypeData.new(
			44, "Lizard Pawn",
			16.0, 55.0, 10.0, 0.8, 3,
			Color(0.3, 0.5, 0.2), Color(0.4, 0.6, 0.3), 1.5,
			"triangle", "chase",
			false, 0.0, 0.0, 0.0,
			0.0, false,
			1.0, 0.0, 0.0
		),
		# 45 — Twin Snakes (stationary, shoots, Dairy Plant, bestiary 040)
		EnemyTypeData.new(
			45, "Twin Snakes",
			12.0, 0.0, 10.0, 0.8, 4,
			Color(0.2, 0.6, 0.2), Color(0.3, 0.8, 0.3), 1.5,
			"diamond", "stationary",
			true, 2.0, 200.0, 0.7,
			0.3, false,
			1.5, 0.01, 0.0
		),
		# 46 — Lizard Rook (Dairy Plant, bestiary 041)
		EnemyTypeData.new(
			46, "Lizard Rook",
			45.0, 30.0, 16.0, 1.4, 6,
			Color(0.3, 0.4, 0.15), Color(0.4, 0.55, 0.2), 2.0,
			"hexagon", "chase",
			false, 0.0, 0.0, 0.0,
			0.3, false,
			2.0, 0.03, 0.0
		),
		# 47 — Twin Demons (stationary rapid-fire, Dairy Plant, bestiary 042)
		EnemyTypeData.new(
			47, "Twin Demons",
			18.0, 0.0, 14.0, 1.0, 6,
			Color(0.6, 0.1, 0.1), Color(0.8, 0.2, 0.2), 2.0,
			"diamond", "stationary",
			true, 1.5, 250.0, 0.8,
			0.4, false,
			2.0, 0.02, 0.0
		),
		# 48 — Jellyfish (Dairy Plant / Moongolow, bestiary 043)
		EnemyTypeData.new(
			48, "Jellyfish",
			10.0, 45.0, 8.0, 0.7, 2,
			Color(0.4, 0.7, 0.8), Color(0.5, 0.8, 0.9), 1.5,
			"circle", "wavy",
			false, 0.0, 0.0, 0.0,
			0.0, false,
			0.8, 0.0, 0.0
		),
		# 49 — Skeleton Ninja (Dairy Plant / Bone Zone, bestiary 044)
		EnemyTypeData.new(
			49, "Skeleton Ninja",
			20.0, 55.0, 12.0, 0.9, 4,
			Color(0.5, 0.5, 0.4), Color(0.6, 0.6, 0.5), 1.5,
			"triangle", "chase",
			false, 0.0, 0.0, 0.0,
			0.1, false,
			1.2, 0.01, 0.0
		),
		# 50 — Lost Twin (stationary rapid-fire, Dairy Plant / Bone Zone, bestiary 045)
		EnemyTypeData.new(
			50, "Lost Twin",
			14.0, 0.0, 12.0, 0.9, 5,
			Color(0.5, 0.4, 0.3), Color(0.6, 0.5, 0.4), 1.5,
			"diamond", "stationary",
			true, 1.0, 260.0, 0.8,
			0.3, false,
			1.8, 0.01, 0.0
		),
		# 51 — Melone (Dairy Plant, bestiary 046)
		EnemyTypeData.new(
			51, "Melone",
			30.0, 20.0, 16.0, 1.3, 5,
			Color(0.4, 0.6, 0.2), Color(0.5, 0.7, 0.3), 2.0,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.4, false,
			1.5, 0.02, 0.0
		),
		# 52 — Minotaur (Dairy Plant, bestiary 047)
		EnemyTypeData.new(
			52, "Minotaur",
			60.0, 50.0, 20.0, 1.6, 10,
			Color(0.5, 0.25, 0.1), Color(0.6, 0.35, 0.15), 2.5,
			"hexagon", "chase",
			false, 0.0, 0.0, 0.0,
			0.3, false,
			2.5, 0.05, 0.0
		),
		# 53 — Mignotaur (fixed direction, Dairy Plant, bestiary 048)
		EnemyTypeData.new(
			53, "Mignotaur",
			40.0, 60.0, 16.0, 1.3, 8,
			Color(0.4, 0.3, 0.15), Color(0.5, 0.4, 0.2), 2.0,
			"triangle", "chase",
			false, 0.0, 0.0, 0.0,
			0.2, false,
			2.0, 0.03, 0.0
		),
		# 54 — Archon Lancia (Dairy Plant, bestiary 049)
		EnemyTypeData.new(
			54, "Archon Lancia",
			20.0, 35.0, 12.0, 1.0, 4,
			Color(0.6, 0.5, 0.2), Color(0.7, 0.6, 0.3), 1.5,
			"diamond", "chase",
			false, 0.0, 0.0, 0.0,
			0.15, false,
			1.2, 0.01, 0.0
		),
		# 55 — Archon Ascia (Dairy Plant, bestiary 050)
		EnemyTypeData.new(
			55, "Archon Ascia",
			22.0, 40.0, 14.0, 1.1, 5,
			Color(0.5, 0.3, 0.2), Color(0.6, 0.4, 0.25), 2.0,
			"diamond", "chase",
			false, 0.0, 0.0, 0.0,
			0.2, false,
			1.5, 0.01, 0.0
		),
		# 56 — Skelewing (Dairy Plant, bestiary 051)
		EnemyTypeData.new(
			56, "Skelewing",
			18.0, 60.0, 10.0, 0.9, 3,
			Color(0.45, 0.4, 0.3), Color(0.55, 0.5, 0.4), 1.5,
			"triangle", "chase",
			false, 0.0, 0.0, 0.0,
			0.0, false,
			1.0, 0.0, 0.0
		),
		# 57 — Tritont (Dairy Plant, bestiary 052)
		EnemyTypeData.new(
			57, "Tritont",
			25.0, 30.0, 14.0, 1.1, 5,
			Color(0.2, 0.5, 0.5), Color(0.3, 0.6, 0.6), 2.0,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.25, false,
			1.5, 0.02, 0.0
		),
		# 58 — Gallotrice (Dairy Plant / Gallo Tower, bestiary 054)
		EnemyTypeData.new(
			58, "Gallotrice",
			35.0, 40.0, 16.0, 1.3, 7,
			Color(0.6, 0.4, 0.2), Color(0.7, 0.5, 0.3), 2.0,
			"hexagon", "chase",
			true, 3.0, 200.0, 0.6,
			0.3, false,
			2.0, 0.03, 0.0
		),
		# 59 — Big Golem (Dairy Plant / Boss Rash, bestiary 055)
		EnemyTypeData.new(
			59, "Big Golem",
			120.0, 20.0, 22.0, 2.0, 15,
			Color(0.35, 0.3, 0.2), Color(0.45, 0.4, 0.25), 2.5,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.6, false,
			3.0, 0.08, 0.0
		),
		# 60 — Sword Guardian (Dairy Plant, bestiary 057)
		EnemyTypeData.new(
			60, "Sword Guardian",
			80.0, 30.0, 20.0, 1.5, 12,
			Color(0.5, 0.4, 0.3), Color(0.6, 0.5, 0.35), 2.5,
			"hexagon", "chase",
			false, 0.0, 0.0, 0.0,
			0.5, true,
			3.0, 0.1, 0.05
		),

		# ═══════════════════════════════════════════════════════════════
		#  GALLO TOWER (stage 4)
		# ═══════════════════════════════════════════════════════════════
		# 61 — Bloodbath (Gallo Tower, bestiary 002)
		EnemyTypeData.new(
			61, "Bloodbath",
			18.0, 50.0, 12.0, 1.0, 4,
			Color(0.6, 0.05, 0.05), Color(0.8, 0.1, 0.1), 1.5,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.1, false,
			1.2, 0.01, 0.0
		),
		# 62 — Skullino (Gallo Tower / Bone Zone, bestiary 003)
		EnemyTypeData.new(
			62, "Skullino",
			14.0, 45.0, 10.0, 0.8, 3,
			Color(0.5, 0.4, 0.3), Color(0.6, 0.5, 0.4), 1.5,
			"diamond", "chase",
			false, 0.0, 0.0, 0.0,
			0.0, false,
			1.0, 0.0, 0.0
		),
		# 63 — Skulorosso (Gallo Tower / Bone Zone, bestiary 004)
		EnemyTypeData.new(
			63, "Skulorosso",
			18.0, 50.0, 12.0, 0.9, 4,
			Color(0.6, 0.15, 0.15), Color(0.7, 0.2, 0.2), 1.5,
			"diamond", "chase",
			false, 0.0, 0.0, 0.0,
			0.1, false,
			1.2, 0.01, 0.0
		),
		# 64 — Scarleton (3 lives, Gallo Tower / Bone Zone, bestiary 005)
		EnemyTypeData.new(
			64, "Scarleton",
			20.0, 55.0, 14.0, 1.0, 5,
			Color(0.7, 0.1, 0.1), Color(0.85, 0.15, 0.15), 2.0,
			"diamond", "chase",
			false, 0.0, 0.0, 0.0,
			0.15, false,
			1.5, 0.02, 0.0
		),
		# 65 — Dragon Shrimp (HPxLevel, Gallo Tower, bestiary 016)
		EnemyTypeData.new(
			65, "Dragon Shrimp",
			30.0, 40.0, 14.0, 1.1, 6,
			Color(0.7, 0.3, 0.1), Color(0.85, 0.4, 0.15), 2.0,
			"triangle", "chase",
			false, 0.0, 0.0, 0.0,
			0.2, false,
			1.8, 0.02, 0.0
		),
		# 66 — Poltergeist (self-destruct, Gallo Tower / Cappella Magna, bestiary 018)
		EnemyTypeData.new(
			66, "Poltergeist",
			10.0, 0.0, 22.0, 1.0, 5,
			Color(0.4, 0.2, 0.6), Color(0.5, 0.3, 0.7), 2.0,
			"diamond", "stationary",
			false, 0.0, 0.0, 0.0,
			0.0, false,
			2.0, 0.02, 0.0
		),
		# 67 — Impefinger (Gallo Tower, bestiary 025)
		EnemyTypeData.new(
			67, "Impefinger",
			16.0, 60.0, 10.0, 0.8, 3,
			Color(0.4, 0.3, 0.1), Color(0.5, 0.4, 0.15), 1.5,
			"triangle", "chase",
			false, 0.0, 0.0, 0.0,
			0.0, false,
			1.0, 0.0, 0.0
		),
		# 68 — Ghiavolo (Gallo Tower, bestiary 027)
		EnemyTypeData.new(
			68, "Ghiavolo",
			22.0, 50.0, 14.0, 1.0, 4,
			Color(0.5, 0.1, 0.3), Color(0.6, 0.15, 0.4), 1.5,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.15, false,
			1.2, 0.01, 0.0
		),
		# 69 — Undead Mage (ranged, Gallo Tower, bestiary 028)
		EnemyTypeData.new(
			69, "Undead Mage",
			20.0, 40.0, 14.0, 1.0, 5,
			Color(0.3, 0.3, 0.5), Color(0.4, 0.4, 0.6), 2.0,
			"diamond", "chase",
			true, 2.0, 240.0, 0.7,
			0.2, false,
			1.5, 0.01, 0.0
		),
		# 70 — Archon Spada (Gallo Tower, bestiary 031)
		EnemyTypeData.new(
			70, "Archon Spada",
			25.0, 35.0, 14.0, 1.1, 5,
			Color(0.4, 0.3, 0.2), Color(0.5, 0.4, 0.25), 2.0,
			"diamond", "chase",
			false, 0.0, 0.0, 0.0,
			0.2, false,
			1.5, 0.02, 0.0
		),
		# 71 — Archon Disco (Gallo Tower, bestiary 032)
		EnemyTypeData.new(
			71, "Archon Disco",
			28.0, 45.0, 16.0, 1.2, 6,
			Color(0.5, 0.2, 0.5), Color(0.6, 0.3, 0.6), 2.0,
			"hexagon", "chase",
			false, 0.0, 0.0, 0.0,
			0.2, false,
			1.8, 0.02, 0.0
		),
		# 72 — Manticore (Gallo Tower, bestiary 053)
		EnemyTypeData.new(
			72, "Manticore",
			60.0, 35.0, 20.0, 1.6, 12,
			Color(0.7, 0.3, 0.1), Color(0.8, 0.4, 0.15), 2.5,
			"hexagon", "chase",
			true, 3.0, 220.0, 0.8,
			0.4, false,
			3.0, 0.05, 0.0
		),
		# 73 — Meat Golem (Gallo Tower, bestiary 056)
		EnemyTypeData.new(
			73, "Meat Golem",
			80.0, 22.0, 22.0, 1.8, 14,
			Color(0.5, 0.2, 0.15), Color(0.6, 0.25, 0.2), 2.5,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.5, false,
			3.0, 0.05, 0.0
		),

		# ═══════════════════════════════════════════════════════════════
		#  MOONGOLOW (stage 6)
		# ═══════════════════════════════════════════════════════════════
		# 74 — Serpentvine (Moongolow, bestiary 099)
		EnemyTypeData.new(
			74, "Serpentvine",
			25.0, 30.0, 12.0, 1.1, 4,
			Color(0.2, 0.5, 0.2), Color(0.3, 0.6, 0.3), 1.5,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.2, false,
			1.2, 0.01, 0.0
		),
		# 75 — Garlic (Moongolow plant, bestiary 100)
		EnemyTypeData.new(
			75, "Garlic",
			18.0, 25.0, 10.0, 1.0, 3,
			Color(0.5, 0.5, 0.2), Color(0.6, 0.6, 0.25), 1.5,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.3, false,
			1.0, 0.01, 0.0
		),
		# 76 — Nightshade (Moongolow, bestiary 101)
		EnemyTypeData.new(
			76, "Nightshade",
			20.0, 35.0, 12.0, 1.0, 4,
			Color(0.2, 0.2, 0.4), Color(0.3, 0.3, 0.5), 1.5,
			"diamond", "chase",
			false, 0.0, 0.0, 0.0,
			0.15, false,
			1.2, 0.01, 0.0
		),
		# 77 — Sig.ra Blu (ignores collision, Moongolow, bestiary 102)
		EnemyTypeData.new(
			77, "Sig.ra Blu",
			15.0, 55.0, 10.0, 0.9, 4,
			Color(0.2, 0.3, 0.7), Color(0.3, 0.4, 0.8), 1.5,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.0, false,
			1.2, 0.01, 0.0
		),
		# 78 — Non-Giant Enemy Crab (fixed direction HPxLevel, Moongolow, bestiary 103)
		EnemyTypeData.new(
			78, "Non-Giant Enemy Crab",
			60.0, 45.0, 18.0, 1.5, 10,
			Color(0.3, 0.5, 0.6), Color(0.4, 0.6, 0.7), 2.0,
			"hexagon", "chase",
			false, 0.0, 0.0, 0.0,
			0.3, false,
			2.5, 0.05, 0.0
		),

		# ═══════════════════════════════════════════════════════════════
		#  CAPPELLA MAGNA (stage 5)
		# ═══════════════════════════════════════════════════════════════
		# 79 — Tetrabrachia (Cappella Magna, bestiary 106)
		EnemyTypeData.new(
			79, "Tetrabrachia",
			30.0, 40.0, 16.0, 1.2, 6,
			Color(0.4, 0.2, 0.1), Color(0.5, 0.3, 0.15), 2.0,
			"hexagon", "chase",
			false, 0.0, 0.0, 0.0,
			0.2, false,
			1.8, 0.02, 0.0
		),
		# 80 — Archon Fiamma (Cappella Magna, bestiary 107)
		EnemyTypeData.new(
			80, "Archon Fiamma",
			35.0, 38.0, 16.0, 1.2, 7,
			Color(0.7, 0.2, 0.05), Color(0.85, 0.3, 0.1), 2.0,
			"diamond", "chase",
			false, 0.0, 0.0, 0.0,
			0.25, false,
			2.0, 0.03, 0.0
		),
		# 81 — Succubus (Cappella Magna, bestiary 108)
		EnemyTypeData.new(
			81, "Succubus",
			25.0, 55.0, 14.0, 1.0, 5,
			Color(0.6, 0.1, 0.3), Color(0.7, 0.15, 0.35), 2.0,
			"diamond", "wavy",
			false, 0.0, 0.0, 0.0,
			0.1, false,
			1.5, 0.02, 0.0
		),
		# 82 — Archon Rame (Cappella Magna, bestiary 109)
		EnemyTypeData.new(
			82, "Archon Rame",
			30.0, 35.0, 15.0, 1.1, 6,
			Color(0.3, 0.4, 0.3), Color(0.4, 0.5, 0.4), 2.0,
			"diamond", "chase",
			false, 0.0, 0.0, 0.0,
			0.25, false,
			1.8, 0.02, 0.0
		),
		# 83 — Demon Priest (Cappella Magna, bestiary 110)
		EnemyTypeData.new(
			83, "Demon Priest",
			40.0, 38.0, 18.0, 1.3, 8,
			Color(0.5, 0.1, 0.1), Color(0.6, 0.15, 0.15), 2.5,
			"hexagon", "chase",
			true, 3.0, 220.0, 0.7,
			0.35, false,
			2.5, 0.03, 0.0
		),
		# 84 — Fallen Cherub (Cappella Magna, bestiary 111)
		EnemyTypeData.new(
			84, "Fallen Cherub",
			20.0, 50.0, 12.0, 0.9, 4,
			Color(0.5, 0.3, 0.3), Color(0.6, 0.4, 0.4), 1.5,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.1, false,
			1.2, 0.01, 0.0
		),
		# 85 — Fallen Cherubbello (Cappella Magna, bestiary 112)
		EnemyTypeData.new(
			85, "Fallen Cherubbello",
			28.0, 55.0, 14.0, 1.1, 5,
			Color(0.6, 0.2, 0.2), Color(0.7, 0.3, 0.3), 2.0,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.15, false,
			1.5, 0.02, 0.0
		),
		# 86 — Fallen Throne (Cappella Magna, bestiary 113)
		EnemyTypeData.new(
			86, "Fallen Throne",
			50.0, 25.0, 20.0, 1.6, 10,
			Color(0.4, 0.2, 0.1), Color(0.5, 0.3, 0.15), 2.5,
			"hexagon", "chase",
			false, 0.0, 0.0, 0.0,
			0.4, false,
			2.5, 0.05, 0.0
		),
		# 87 — Archon Oro (Cappella Magna, bestiary 114)
		EnemyTypeData.new(
			87, "Archon Oro",
			32.0, 40.0, 16.0, 1.2, 7,
			Color(0.6, 0.5, 0.1), Color(0.7, 0.6, 0.15), 2.0,
			"diamond", "chase",
			false, 0.0, 0.0, 0.0,
			0.25, false,
			2.0, 0.03, 0.0
		),
		# 88 — Demon Beast (Cappella Magna, bestiary 115)
		EnemyTypeData.new(
			88, "Demon Beast",
			45.0, 45.0, 18.0, 1.4, 9,
			Color(0.3, 0.1, 0.05), Color(0.4, 0.15, 0.1), 2.0,
			"triangle", "chase",
			false, 0.0, 0.0, 0.0,
			0.3, false,
			2.5, 0.04, 0.0
		),
		# 89 — Archdemon (Cappella Magna, bestiary 116)
		EnemyTypeData.new(
			89, "Archdemon",
			80.0, 30.0, 24.0, 1.8, 18,
			Color(0.6, 0.05, 0.05), Color(0.7, 0.1, 0.1), 3.0,
			"hexagon", "chase",
			true, 3.5, 250.0, 0.9,
			0.5, false,
			4.0, 0.08, 0.0
		),
		# 90 — Stage Killer (HPxLevel, Cappella Magna, bestiary 118)
		EnemyTypeData.new(
			90, "Stage Killer",
			60.0, 35.0, 20.0, 1.5, 12,
			Color(0.1, 0.1, 0.1), Color(0.3, 0.0, 0.0), 2.5,
			"diamond", "chase",
			false, 0.0, 0.0, 0.0,
			0.4, false,
			3.0, 0.05, 0.0
		),
		# 91 — Reaper Trainee (Cappella Magna, bestiary 105)
		EnemyTypeData.new(
			91, "Reaper Trainee",
			30.0, 55.0, 16.0, 1.1, 8,
			Color(0.15, 0.15, 0.15), Color(0.4, 0.0, 0.0), 2.0,
			"diamond", "chase",
			false, 0.0, 0.0, 0.0,
			0.3, false,
			2.0, 0.03, 0.0
		),
		# 92 — Unknown (Cappella Magna boss during lunar eclipse, bestiary 104)
		EnemyTypeData.new(
			92, "Unknown",
			300.0, 25.0, 30.0, 2.5, 60,
			Color(0.2, 0.0, 0.3), Color(0.3, 0.0, 0.4), 3.0,
			"hexagon", "chase",
			true, 2.0, 280.0, 1.1,
			0.8, true,
			8.0, 0.3, 0.15
		),

		# ═══════════════════════════════════════════════════════════════
		#  IL MOLISE (stage 2) — stationary Molisano family
		#  Wiki: Base / Secco / Bello / Grosso / Giallo / Rosso / Fagiolo
		#  Boss: Vecchio, special: Anfora (coin drops), Big Molisano
		# ═══════════════════════════════════════════════════════════════
		# 93 — Molisano Base (basic, most common)
		EnemyTypeData.new(
			93, "Molisano Base",
			20.0, 0.0, 10.0, 1.0, 3,
			Color(0.35, 0.25, 0.2), Color(0.45, 0.35, 0.3), 1.5,
			"circle", "stationary",
			false, 0.0, 0.0, 0.0,
			1.0, false,
			1.0, 0.0, 0.0
		),
		# 94 — Molisano Secco (thin/dry)
		EnemyTypeData.new(
			94, "Molisano Secco",
			15.0, 0.0, 12.0, 0.8, 4,
			Color(0.5, 0.4, 0.25), Color(0.6, 0.5, 0.35), 1.5,
			"diamond", "stationary",
			false, 0.0, 0.0, 0.0,
			1.0, false,
			1.2, 0.01, 0.0
		),
		# 95 — Molisano Bello (beautiful)
		EnemyTypeData.new(
			95, "Molisano Bello",
			25.0, 0.0, 14.0, 1.1, 5,
			Color(0.6, 0.3, 0.4), Color(0.7, 0.4, 0.5), 2.0,
			"hexagon", "stationary",
			false, 0.0, 0.0, 0.0,
			1.0, false,
			1.5, 0.02, 0.0
		),
		# 96 — Molisano Grosso (big)
		EnemyTypeData.new(
			96, "Molisano Grosso",
			40.0, 0.0, 18.0, 1.5, 8,
			Color(0.4, 0.3, 0.15), Color(0.5, 0.4, 0.2), 2.5,
			"circle", "stationary",
			false, 0.0, 0.0, 0.0,
			1.0, false,
			2.0, 0.03, 0.0
		),
		# 97 — Molisano Giallo (yellow)
		EnemyTypeData.new(
			97, "Molisano Giallo",
			30.0, 0.0, 14.0, 1.2, 6,
			Color(0.7, 0.6, 0.15), Color(0.8, 0.7, 0.2), 2.0,
			"diamond", "stationary",
			false, 0.0, 0.0, 0.0,
			1.0, false,
			1.8, 0.02, 0.0
		),
		# 98 — Molisano Rosso (red, aggressive)
		EnemyTypeData.new(
			98, "Molisano Rosso",
			35.0, 0.0, 16.0, 1.3, 7,
			Color(0.65, 0.1, 0.1), Color(0.75, 0.15, 0.15), 2.0,
			"triangle", "stationary",
			false, 0.0, 0.0, 0.0,
			1.0, false,
			2.0, 0.03, 0.0
		),
		# 99 — Molisano Fagiolo (bean, small)
		EnemyTypeData.new(
			99, "Molisano Fagiolo",
			10.0, 0.0, 8.0, 0.7, 2,
			Color(0.4, 0.5, 0.2), Color(0.5, 0.6, 0.3), 1.5,
			"circle", "stationary",
			false, 0.0, 0.0, 0.0,
			1.0, false,
			0.8, 0.0, 0.0
		),
		# 100 — Molisano Vecchio (old, boss, spawns 9:00+)
		EnemyTypeData.new(
			100, "Molisano Vecchio",
			80.0, 0.0, 22.0, 1.8, 15,
			Color(0.3, 0.2, 0.1), Color(0.4, 0.3, 0.15), 3.0,
			"hexagon", "stationary",
			false, 0.0, 0.0, 0.0,
			1.0, false,
			3.0, 0.1, 0.05
		),
		# 101 — Molisano Anfora (coin dropper, spawns every wave)
		EnemyTypeData.new(
			101, "Molisano Anfora",
			15.0, 0.0, 8.0, 0.9, 0,
			Color(0.6, 0.5, 0.3), Color(0.7, 0.6, 0.35), 1.5,
			"diamond", "stationary",
			false, 0.0, 0.0, 0.0,
			0.5, false,
			0.0, 0.0, 0.0
		),
		# 102 — Big Molisano (colossal boss)
		EnemyTypeData.new(
			102, "Big Molisano",
			200.0, 0.0, 30.0, 3.0, 50,
			Color(0.25, 0.15, 0.1), Color(0.35, 0.25, 0.15), 3.5,
			"circle", "stationary",
			false, 0.0, 0.0, 0.0,
			1.0, false,
			5.0, 0.3, 0.1
		),

		# ═══════════════════════════════════════════════════════════════
		#  THE BONE ZONE (stage 8)  — bestiary 088-093
		# ═══════════════════════════════════════════════════════════════
		# 103 — Twin Skulls (stationary rapid-fire, Bone Zone, bestiary 088)
		EnemyTypeData.new(
			103, "Twin Skulls",
			14.0, 0.0, 12.0, 0.9, 5,
			Color(0.5, 0.4, 0.3), Color(0.6, 0.5, 0.4), 1.5,
			"diamond", "stationary",
			true, 1.0, 260.0, 0.8,
			0.3, false,
			1.8, 0.01, 0.0
		),
		# 104 — Skullone (multiple stages, bestiary 089)
		EnemyTypeData.new(
			104, "Skullone",
			25.0, 40.0, 14.0, 1.1, 5,
			Color(0.5, 0.4, 0.3), Color(0.6, 0.5, 0.4), 2.0,
			"diamond", "chase",
			false, 0.0, 0.0, 0.0,
			0.2, false,
			1.5, 0.02, 0.0
		),
		# 105 — Skeleton Panther (Bone Zone, bestiary 090)
		EnemyTypeData.new(
			105, "Skeleton Panther",
			35.0, 55.0, 16.0, 1.3, 6,
			Color(0.4, 0.35, 0.25), Color(0.5, 0.45, 0.35), 2.0,
			"triangle", "chase",
			false, 0.0, 0.0, 0.0,
			0.15, false,
			1.8, 0.02, 0.0
		),
		# 106 — Giant Skeleton (Bone Zone, bestiary 091)
		EnemyTypeData.new(
			106, "Giant Skeleton",
			80.0, 20.0, 22.0, 2.0, 15,
			Color(0.4, 0.3, 0.2), Color(0.5, 0.4, 0.25), 2.5,
			"diamond", "chase",
			false, 0.0, 0.0, 0.0,
			0.5, false,
			3.0, 0.05, 0.0
		),
		# 107 — Skeletone (HPxLevel, Bone Zone, bestiary 092)
		EnemyTypeData.new(
			107, "Skeletone",
			40.0, 35.0, 16.0, 1.3, 8,
			Color(0.5, 0.4, 0.3), Color(0.6, 0.5, 0.4), 2.0,
			"diamond", "chase",
			false, 0.0, 0.0, 0.0,
			0.25, false,
			2.0, 0.03, 0.0
		),
		# 108 — Sketamari (Bone Zone boss, absorbs enemies, bestiary 093)
		EnemyTypeData.new(
			108, "Sketamari",
			500.0, 20.0, 35.0, 3.5, 100,
			Color(0.3, 0.3, 0.3), Color(0.5, 0.0, 0.0), 3.5,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.95, true,
			10.0, 0.4, 0.2
		),

		# ═══════════════════════════════════════════════════════════════
		#  WHITEOUT (stage 10) — bestiary 064-068
		# ═══════════════════════════════════════════════════════════════
		# 109 — Bambaman (Whiteout, bestiary 064)
		EnemyTypeData.new(
			109, "Bambaman",
			20.0, 45.0, 12.0, 1.0, 4,
			Color(0.5, 0.5, 0.4), Color(0.6, 0.6, 0.5), 1.5,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.1, false,
			1.2, 0.01, 0.0
		),
		# 110 — Miragellos (Whiteout, bestiary 065)
		EnemyTypeData.new(
			110, "Miragellos",
			16.0, 50.0, 10.0, 0.9, 3,
			Color(0.3, 0.5, 0.6), Color(0.4, 0.6, 0.7), 1.5,
			"circle", "wavy",
			false, 0.0, 0.0, 0.0,
			0.0, false,
			1.0, 0.0, 0.0
		),
		# 111 — Menta Elemental (Whiteout, bestiary 066)
		EnemyTypeData.new(
			111, "Menta Elemental",
			30.0, 30.0, 14.0, 1.2, 5,
			Color(0.4, 0.7, 0.6), Color(0.5, 0.8, 0.7), 2.0,
			"circle", "chase",
			false, 0.0, 0.0, 0.0,
			0.2, false,
			1.5, 0.02, 0.0
		),
		# 112 — Madd-Onna (Whiteout, bestiary 067)
		EnemyTypeData.new(
			112, "Madd-Onna",
			15.0, 55.0, 10.0, 0.9, 4,
			Color(0.7, 0.2, 0.3), Color(0.8, 0.3, 0.4), 1.5,
			"triangle", "chase",
			false, 0.0, 0.0, 0.0,
			0.0, false,
			1.2, 0.01, 0.0
		),
		# 113 — Kizzune (resistant, HPxLevel, Whiteout, bestiary 068)
		EnemyTypeData.new(
			113, "Kizzune",
			60.0, 35.0, 18.0, 1.5, 12,
			Color(0.5, 0.3, 0.6), Color(0.6, 0.4, 0.7), 2.5,
			"hexagon", "chase",
			false, 0.0, 0.0, 0.0,
			0.6, false,
			3.0, 0.08, 0.0
		),

		# ═══════════════════════════════════════════════════════════════
		#  SPECIAL / BOSS enemies
		# ═══════════════════════════════════════════════════════════════
		# 114 — The Stalker (unique boss, bestiary 121)
		EnemyTypeData.new(
			114, "The Stalker",
			400.0, 35.0, 28.0, 2.5, 80,
			Color(0.05, 0.05, 0.2), Color(0.1, 0.1, 0.3), 3.0,
			"diamond", "chase",
			false, 0.0, 0.0, 0.0,
			0.9, true,
			8.0, 0.4, 0.15
		),
		# 115 — The Drowner (unique boss, bestiary 122)
		EnemyTypeData.new(
			115, "The Drowner",
			450.0, 30.0, 30.0, 2.8, 90,
			Color(0.05, 0.2, 0.3), Color(0.1, 0.3, 0.4), 3.0,
			"hexagon", "chase",
			false, 0.0, 0.0, 0.0,
			0.9, true,
			9.0, 0.4, 0.15
		),
		# 116 — The Maddener (unique boss, bestiary 123)
		EnemyTypeData.new(
			116, "The Maddener",
			600.0, 28.0, 32.0, 3.0, 120,
			Color(0.3, 0.0, 0.0), Color(0.5, 0.0, 0.0), 3.5,
			"hexagon", "chase",
			true, 2.0, 300.0, 1.2,
			0.95, true,
			10.0, 0.5, 0.2
		),
		# 117 — The Ender (unique boss, bestiary 125)
		EnemyTypeData.new(
			117, "The Ender",
			800.0, 24.0, 35.0, 3.5, 150,
			Color(0.1, 0.0, 0.2), Color(0.2, 0.0, 0.3), 3.5,
			"diamond", "chase",
			true, 1.5, 320.0, 1.3,
			0.95, true,
			12.0, 0.5, 0.2
		),
		# 118 — The Directer (Eudaimonia Machine, bestiary 131)
		EnemyTypeData.new(
			118, "The Directer",
			2000.0, 20.0, 40.0, 4.0, 999,
			Color(0.8, 0.8, 0.1), Color(1.0, 1.0, 0.2), 4.0,
			"diamond", "chase",
			true, 1.5, 350.0, 1.5,
			1.0, true,
			15.0, 0.8, 0.5
		),
		# 119 — Moongolow Atlantean (egg drop, bestiary 098)
		EnemyTypeData.new(
			119, "Moongolow Atlantean",
			100.0, 50.0, 22.0, 1.8, 50,
			Color(0.2, 0.5, 0.7), Color(0.3, 0.6, 0.8), 2.5,
			"hexagon", "chase",
			false, 0.0, 0.0, 0.0,
			0.7, true,
			6.0, 0.3, 0.1
		),
		# 120 — Harzia (fixed direction wavy, Gallo Tower, bestiary 023)
		EnemyTypeData.new(
			120, "Harzia",
			22.0, 50.0, 14.0, 1.0, 5,
			Color(0.3, 0.5, 0.4), Color(0.4, 0.6, 0.5), 2.0,
			"diamond", "wavy",
			false, 0.0, 0.0, 0.0,
			0.15, false,
			1.5, 0.02, 0.0
		),
		# 121 — Flower Wall (Mad Forest event, bestiary 009)
		EnemyTypeData.new(
			121, "Flower Wall",
			30.0, 0.0, 14.0, 1.2, 5,
			Color(0.3, 0.6, 0.1), Color(0.4, 0.7, 0.15), 2.0,
			"hexagon", "stationary",
			false, 0.0, 0.0, 0.0,
			0.5, false,
			1.5, 0.02, 0.0
		),
	]

	# ── Post-init adjustments ──
	for t in _types:
		match t.id:
			# Spawn weight overrides (lower = much rarer)
			0:   t.spawn_weight = 1.0
			3:   t.spawn_weight = 0.03   # Cursed Eye — greatly reduced
			13:  t.spawn_weight = 0.08   # Giant Bat — rarer
			14:  t.spawn_weight = 0.02   # Glowing Bat — very rare mini-boss
			17:  t.spawn_weight = 0.04   # Mantichana — rare mid-boss
			18:  t.spawn_weight = 0.15   # Werewolf — uncommon
			19:  t.spawn_weight = 0.10   # Big Mummy — uncommon
			20:  t.spawn_weight = 0.01   # Venus — very rare
			21:  t.spawn_weight = 0.005  # Giant Blue Venus — stage boss only
			22:  t.spawn_weight = 0.0    # The Reaper — never random spawn

			# Inlaid Library spawn weights
			25:  t.spawn_weight = 0.03   # Sneaky Head — rare (stationary ranged)
			27:  t.spawn_weight = 0.10   # Lionhead — uncommon
			28:  t.spawn_weight = 0.15   # Dullahan — uncommon
			30:  t.spawn_weight = 0.08   # Elite Dullahan — rarer
			31:  t.spawn_weight = 0.15   # Glowing Skull — uncommon
			32:  t.spawn_weight = 0.01   # Giant Medusa — rare semi-boss
			36:  t.spawn_weight = 0.01   # Sig.ra Rossi — only in map events
			37:  t.spawn_weight = 0.02   # Hag — rare boss
			38:  t.spawn_weight = 0.04   # Nesufritto — uncommon
			39:  t.spawn_weight = 0.05   # Merdusa — uncommon
			40:  t.spawn_weight = 0.08   # Undead Witch
			41:  t.spawn_weight = 0.06   # Undead Sassy Witch

			# Dairy Plant
			45:  t.spawn_weight = 0.03   # Twin Snakes — stationary ranged
			47:  t.spawn_weight = 0.03   # Twin Demons — stationary ranged
			50:  t.spawn_weight = 0.03   # Lost Twin — stationary rapid-fire
			52:  t.spawn_weight = 0.08   # Minotaur — mid-tier
			53:  t.spawn_weight = 0.06   # Mignotaur
			58:  t.spawn_weight = 0.04   # Gallotrice — uncommon
			59:  t.spawn_weight = 0.03   # Big Golem — rare
			60:  t.spawn_weight = 0.02   # Sword Guardian — rare

			# Gallo Tower
			61:  t.spawn_weight = 0.15   # Bloodbath
			65:  t.spawn_weight = 0.08   # Dragon Shrimp
			66:  t.spawn_weight = 0.02   # Poltergeist — event only
			69:  t.spawn_weight = 0.08   # Undead Mage — uncommon
			72:  t.spawn_weight = 0.04   # Manticore — uncommon
			73:  t.spawn_weight = 0.04   # Meat Golem

			# Moongolow
			74:  t.spawn_weight = 0.12   # Serpentvine
			77:  t.spawn_weight = 0.06   # Sig.ra Blu
			78:  t.spawn_weight = 0.03   # Non-Giant Enemy Crab

			# Cappella Magna
			81:  t.spawn_weight = 0.10   # Succubus
			83:  t.spawn_weight = 0.06   # Demon Priest
			89:  t.spawn_weight = 0.02   # Archdemon — rare
			90:  t.spawn_weight = 0.04   # Stage Killer
			91:  t.spawn_weight = 0.06   # Reaper Trainee
			92:  t.spawn_weight = 0.01   # Unknown — rare boss

			# Il Molise
			93:  t.spawn_weight = 0.12   # Molisano Base
			94:  t.spawn_weight = 0.10   # Molisano Secco
			95:  t.spawn_weight = 0.08   # Molisano Bello
			96:  t.spawn_weight = 0.06   # Molisano Grosso
			97:  t.spawn_weight = 0.08   # Molisano Giallo
			98:  t.spawn_weight = 0.06   # Molisano Rosso
			99:  t.spawn_weight = 0.10   # Molisano Fagiolo
			100: t.spawn_weight = 0.02   # Molisano Vecchio — boss
			101: t.spawn_weight = 0.01   # Molisano Anfora — coin dropper
			102: t.spawn_weight = 0.005  # Big Molisano — colossal boss

			# Bone Zone
			103: t.spawn_weight = 0.04   # Twin Skulls — stationary
			104: t.spawn_weight = 0.10   # Skullone
			105: t.spawn_weight = 0.08   # Skeleton Panther
			106: t.spawn_weight = 0.03   # Giant Skeleton
			107: t.spawn_weight = 0.06   # Skeletone
			108: t.spawn_weight = 0.005  # Sketamari — ultra rare boss

			# Whiteout
			109: t.spawn_weight = 0.12   # Bambaman
			110: t.spawn_weight = 0.10   # Miragellos
			111: t.spawn_weight = 0.08   # Menta Elemental
			112: t.spawn_weight = 0.10   # Madd-Onna
			113: t.spawn_weight = 0.02   # Kizzune — rare

			# Special bosses
			114: t.spawn_weight = 0.002  # The Stalker — ultra rare
			115: t.spawn_weight = 0.002  # The Drowner — ultra rare
			116: t.spawn_weight = 0.001  # The Maddener — ultra rare
			117: t.spawn_weight = 0.001  # The Ender — ultra rare
			118: t.spawn_weight = 0.0    # The Directer — never random
			119: t.spawn_weight = 0.002  # Moongolow Atlantean — ultra rare

			# Special flags
			# Has three lives
			64: t.has_three_lives = true  # Scarleton

			# Ignores collision
			36: t.ignores_collision = true  # Sig.ra Rossi (shade bomb)
			66: t.ignores_collision = true  # Poltergeist
			77: t.ignores_collision = true  # Sig.ra Blu

			# Self-destruct
			36: t.is_self_destruct = true   # Sig.ra Rossi
			66: t.is_self_destruct = true   # Poltergeist

			# HPxLevel flag
			37: t.has_hp_x_level = true   # Hag
			38: t.has_hp_x_level = true   # Nesufritto
			65: t.has_hp_x_level = true   # Dragon Shrimp
			90: t.has_hp_x_level = true   # Stage Killer
			107: t.has_hp_x_level = true  # Skeletone
			113: t.has_hp_x_level = true  # Kizzune

			# Fixed direction
			53: t.is_fixed_direction = true   # Mignotaur
			78: t.is_fixed_direction = true   # Non-Giant Enemy Crab
			120: t.is_fixed_direction = true  # Harzia


static func get_type(id: int) -> EnemyTypeData:
	_ensure_loaded()
	for t in _types:
		if t.id == id:
			return t
	return _types[0]


static func get_type_count() -> int:
	_ensure_loaded()
	return _types.size()


# ── Helper: load stage data via StageDefs (no circular dependency since both are data scripts)
const _StageDefs := preload("res://scripts/data/stage_defs.gd")

# ── Helper: extract unique enemy IDs used across all wave_defs entries
static func _extract_enemy_ids_from_wave_defs(wave_defs: Array) -> Array[int]:
	var ids: Array[int] = []
	var seen: Dictionary = {}
	for wd in wave_defs:
		var enemies = wd.get("enemies", [])
		for entry in enemies:
			var id_str = entry.get("id", "")
			# Resolve string name via the same mapping used by wave_system
			var resolved = _resolve_enemy_id_for_pool(id_str)
			if resolved >= 0 and not seen.has(resolved):
				seen[resolved] = true
				ids.append(resolved)
		# Also include boss if present
		var boss_name = wd.get("boss", "")
		if boss_name != null and boss_name != "":
			var boss_id = _resolve_enemy_id_for_pool(boss_name)
			if boss_id >= 0 and not seen.has(boss_id):
				seen[boss_id] = true
				ids.append(boss_id)
	return ids


# ── Minimal name→ID resolver for pool extraction (mirrors wave_system.gd mapping)
static func _resolve_enemy_id_for_pool(name: String) -> int:
	if name.is_empty():
		return -1
	if name.is_valid_int():
		return name.to_int()
	var map := {
		"wraith": 0, "viper": 1, "golem": 2, "mantis": 4, "nightmare": 5,
		"giant_crab": 6, "trinacria": 7,
		"zombie": 8, "skeleton": 9, "ghost": 10,
		"bat_s": 11, "bat_r": 12, "bat_giant": 13, "bat_g": 14, "bat_silver": 14,
		"mudman": 15, "mudman_g": 16,
		"mantichana": 17, "mantichana_giant": 17, "werewolf": 18,
		"mummy_big": 19, "mummy_giant": 19,
		"venus": 20, "venus_blue_giant": 21, "reaper": 22,
		"dust_elemental": 23, "musc_musc": 24, "big_musc_musc": 24,
		"sneaky_head": 25, "medusa_head": 25, "big_sneaky_head": 39,
		"aggressive_sneaky_head": 39, "mummy": 26, "lionhead": 27,
		"dullahan": 28, "testa_di_mano": 28,
		"apprentice_witch": 29, "elite_dullahan": 30,
		"glowing_skull": 31, "giant_medusa": 32,
		"sigra_rossi": 36, "hag": 37, "nesufritto": 38, "nesuferit": 38,
		"merdusa": 39, "undead_witch": 40, "undead_sassy_witch": 41,
		"milk_elemental": 42, "merman": 43, "lizard_pawn": 44,
		"twin_snakes": 45, "lizard_rook": 46, "twin_demons": 47,
		"jellyfish": 48, "skeleton_ninja": 49, "lost_twin": 50,
		"melone": 51, "minotaur": 52, "mignotaur": 53,
		"archon_lancia": 54, "archon_ascia": 55, "skelewing": 56,
		"tritont": 57, "gallotrice": 58, "big_golem": 59, "sword_guardian": 60,
		"bloodbath": 61, "skullino": 62, "skulorosso": 63, "scarleton": 64,
		"dragon_shrimp": 65, "poltergeist": 66, "impefinger": 67,
		"ghiavolo": 68, "undead_mage": 69, "archon_spada": 70,
		"archon_disco": 71, "manticore": 72, "meat_golem": 73,
		"serpentvine": 74, "garlic": 75, "nightshade": 76,
		"sigra_blu": 77, "non_giant_crab": 78,
		"tetrabrachia": 79, "archon_fiamma": 80, "succubus": 81,
		"archon_rame": 82, "demon_priest": 83, "fallen_cherub": 84,
		"fallen_cherubbello": 85, "fallen_throne": 86, "archon_oro": 87,
		"demon_beast": 88, "archdemon": 89, "stage_killer": 90,
		"reaper_trainee": 91, "unknown": 92,
		"molisano_base": 93, "molisano_secco": 94,
		"molisano_bello": 95, "molisano_grosso": 96,
		"molisano_giallo": 97, "molisano_rosso": 98,
		"molisano_fagiolo": 99, "molisano_vecchio": 100,
		"molisano_anfora": 101, "big_molisano": 102,
		"sad_molisano": 93, "happy_molisano": 94, "cute_molisano": 95,
		"old_molisano": 100, "dead_molisano": 97,
		"twin_skulls": 103, "skullone": 104, "skeleton_panther": 105,
		"giant_skeleton": 106, "skeletone": 107, "sketamari": 108,
		"bambaman": 109, "miragellos": 110, "menta_elemental": 111,
		"madd_onna": 112, "kizzune": 113,
		"stalker": 114, "drowner": 115, "maddener": 116, "ender": 117,
		"directer": 118, "moongolow_atlantean": 119, "harzia": 120,
		"flower_wall": 121,
		# Legacy aliases for stage boss references
		"colossal_musc_musc": 24, "colossal_lionhead": 27,
		"colossal_sneaky_head": 39, "colossal_dust_elemental": 23,
		"queen_medusa": 39, "master_witch": 40,
		"silver_bat": 14, "werewolf_giant": 18,
		"zombie_b": 8, "skeleton_b": 9, "skeleton_r": 9,
	}
	return map.get(name, -1)


# Returns list of enemy type IDs suitable for spawning at a given stage.
#
# For stages WITH wave_defs (0,1,3,4,5,6): auto-extracts from the stage's
# wave definition data — this is the single source of truth.
#
# For stages WITHOUT wave_defs (2,7-20): uses hardcoded fallback pools.
# This controls initial spawns in main.gd for non-wave_defs stages.
static func get_types_for_stage(stage_id: int, _game_time: float = 0.0) -> Array[int]:
	_ensure_loaded()

	# ── Auto-derive from wave_defs (most stages 0-20 have wave_defs) ──
	# Stages 7 (Green Acres, random waves), 15 (Eudaimonia Machine, boss encounter),
	# and 16 (Holy Forbidden, event sequence) intentionally skip wave_defs.
	var stage_data = _StageDefs.get_stage(stage_id)
	if not stage_data.is_empty() and stage_data.has("wave_defs") and not stage_data["wave_defs"].is_empty():
		return _extract_enemy_ids_from_wave_defs(stage_data["wave_defs"])

	# ── Fallback: safety pools for unknown/edge-case stages ──
	var pool: Array[int] = []

	match stage_id:
		2:  # Il Molise
			pool = [93, 94, 95, 96, 97, 98, 99]  # Molisano family — stationary only
			# (Vecchio/Anfora/Big are boss-level, not in random fallback)

		7:  # Green Acres — random mix with all types
			pool = [0, 1, 2, 4, 8, 9, 10, 11, 12, 15, 16, 18, 19]

		8:  # The Bone Zone — skeleton/bone themed
			pool = [0, 9, 10, 11, 12, 18, 49, 62, 63, 64, 99, 100, 101, 102]

		9:  # Boss Rash — boss rush, mixed pool
			pool = [2, 4, 5, 6, 7, 14, 17, 20, 21, 37, 38, 60, 92, 103, 109, 110, 111, 112]

		10: # Whiteout — arctic/chill theme
			pool = [104, 105, 106, 107, 108]

		11: # Bat Country
			pool = [11, 12, 13, 14]

		12: # The Lab / Laborratory
			pool = [0, 1, 2, 4, 11, 15, 18]

		13: # The Coop
			pool = [0, 1, 4, 11, 12]

		14: # Space 54
			pool = [0, 1, 4, 11, 12, 15]

		15: # Eudaimonia Machine — special; mostly boss fight
			pool = [22, 109, 110, 111, 112, 113]

		16: # Holy Forbidden
			pool = [0, 1, 2, 4, 11, 15, 18, 19]

		17: # Tiny Bridge
			pool = [0, 1, 2, 4, 9, 11, 15]

		18: # Astral Stair
			pool = [0, 1, 2, 4, 10, 11, 15, 18]

		19: # Room 1665 — DLC free update
			pool = [0, 1, 2, 4, 11, 15, 18]

		20: # Westwoods
			pool = [0, 1, 2, 4, 11, 15, 18]

		_:
			# Fallback: basic pool
			pool = [0, 1, 2, 4, 11, 15]

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


# Returns the boss type ID for a given stage + game time, or -1 if no boss.
static func get_boss_type(stage_id: int, game_time: float) -> int:
	_ensure_loaded()
	match stage_id:
		0:  # Mad Forest
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

		1:  # Inlaid Library
			if game_time >= 1800.0:
				return 22   # The Reaper at 30:00
			if game_time >= 1500.0:
				return 37   # Hag at 25:00
			if game_time >= 900.0:
				return 5    # Nightmare at 15:00
			if game_time >= 600.0:
				return 38   # Nesufritto at 10:00
			if game_time >= 300.0:
				return 14   # Glowing Bat at 5:00
			return -1

		2:  # Il Molise — no boss (15 min stage)
			return -1

		3:  # Dairy Plant
			if game_time >= 1800.0:
				return 22   # The Reaper
			if game_time >= 900.0:
				return 6    # Giant Enemy Crab at 15:00
			if game_time >= 600.0:
				return 60   # Sword Guardian at 10:00
			if game_time >= 300.0:
				return 59   # Big Golem at 5:00
			return -1

		4:  # Gallo Tower
			if game_time >= 1800.0:
				return 22   # The Reaper
			if game_time >= 1500.0:
				return 6    # Giant Enemy Crab at 25:00
			if game_time >= 900.0:
				return 7    # Trinacria at 15:00
			if game_time >= 600.0:
				return 72   # Manticore at 10:00
			if game_time >= 300.0:
				return 17   # Mantichana at 5:00
			return -1

		5:  # Cappella Magna
			if game_time >= 1800.0:
				return 22   # The Reaper
			if game_time >= 1500.0:
				return 7    # Trinacria (enhanced) at 15:00
			if game_time >= 900.0:
				return 111  # The Maddener at 15:00
			if game_time >= 600.0:
				return 92   # Unknown at 10:00 (lunar eclipse phase)
			if game_time >= 300.0:
				return 112  # The Ender at 5:00
			return -1

		6:  # Moongolow
			if game_time >= 900.0:
				return 22   # The Reaper at 15:00
			if game_time >= 450.0:
				return 5    # Nightmare at 7:30
			if game_time >= 300.0:
				return 114  # Moongolow Atlantean at 5:00
			return -1

		7, 8, 9, 10, 11, 12, 13, 14:
			# Bonus/challenge stages — no traditional boss; use scaling instead
			return -1

		15: # Eudaimonia Machine
			if game_time >= 300.0:
				return 113  # The Directer at 5:00
			if game_time >= 600.0:
				return 112  # The Ender at 10:00
			return -1

	return -1
