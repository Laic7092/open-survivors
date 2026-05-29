extends RefCounted
# Stage definitions — static data for the stage selection system.
# Each entry: id, name, desc, time_limit, bg_color,
# base modifiers, hyper modifiers, spawn curve params, unlock condition.

const STAGES = [
	# ═══════════════════════════════════════════════════════
	#  Stage 0 — Mad Forest (default)
	# ═══════════════════════════════════════════════════════
	{
		"id": 0,
		"name": "Mad Forest",
		"desc": "A dark forest overrun by evil.\nSurvive until dawn.",
		"time_limit": 1800.0,  # 30 minutes
		"bg_color": Color(0.04, 0.04, 0.10),
		"map_width": 6400,
		"map_height": 4800,
		"move_speed_mod": 1.0,
		"enemy_speed_mod": 1.0,
		"gold_mod": 1.0,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 2.0,
		"spawn_min_interval": 0.3,
		"spawn_ramp_time": 30.0,
		"wave_size_interval": 30.0,
		"difficulty_ramp_time": 60.0,
		"unlock_req": "",
		"hyper_unlock": "boss_stage_0",  # defeat boss on this stage
		"hyper_mods": {
			"move_speed_bonus": 1.0,   # +100% move speed (total 2.0)
			"gold_mult": 1.5,          # +50% gold
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.0,
		},
		"stage_items": [
			{"type": 4,  "is_weapon": false, "pos": Vector2(-1600, -800)},   # Spinach
			{"type": 21, "is_weapon": false, "pos": Vector2(1200, 600)},    # Clover
			{"type": 6,  "is_weapon": false, "pos": Vector2(-400, 1400)},   # Hollow Heart
			{"type": 9,  "is_weapon": false, "pos": Vector2(1000, -1200)},  # Pummarola
		],
		"interactables": {
			"chests": [
				{"pos": Vector2(-2500, -1500)},
				{"pos": Vector2(2000, 1800)},
				{"pos": Vector2(-1500, 2000)},
			],
			"fountains": [
				{"pos": Vector2(-1200, -600), "heal_pct": 0.50},
				{"pos": Vector2(1500, -1000), "heal_pct": 0.50},
			],
			"breakable_density": 0.00025,
			"breakable_hp": 20.0,
			"hazards": [
				{"pos": Vector2(-800, 2000), "size": Vector2(120, 120), "dps": 12.0},
				{"pos": Vector2(2800, -500), "size": Vector2(100, 100), "dps": 15.0},
			],
			"boosts": [
				{"pos": Vector2(0, 0), "type": "speed", "amount": 0.5, "size": Vector2(80, 80)},
			],
		},
	},
	# ═══════════════════════════════════════════════════════
	#  Stage 1 — Inlaid Library
	# ═══════════════════════════════════════════════════════
	{
		"id": 1,
		"name": "Inlaid Library",
		"desc": "Halls of forbidden knowledge.\n+25% Move Speed. Narrow corridor.",
		"time_limit": 1800.0,
		"bg_color": Color(0.08, 0.02, 0.12),
		"map_width": 2800,
		"map_height": 7200,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.15,
		"gold_mod": 1.0,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 1.8,
		"spawn_min_interval": 0.25,
		"spawn_ramp_time": 25.0,
		"wave_size_interval": 25.0,
		"difficulty_ramp_time": 50.0,
		"unlock_req": "clear_stage_0",
		"hyper_unlock": "boss_stage_1",
		"hyper_mods": {
			"move_speed_bonus": 0.9,   # +90% (total 2.15)
			"gold_mult": 1.5,          # +50%
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.0,
		},
		"stage_items": [
			{"type": 14, "is_weapon": false, "pos": Vector2(0, -2400)},    # Stone Mask
			{"type": 5,  "is_weapon": false, "pos": Vector2(0, 2400)},    # Empty Tome
		],
		"interactables": {
			"chests": [
				{"pos": Vector2(-800, -3000)},
				{"pos": Vector2(800, 0)},
				{"pos": Vector2(-600, 3200)},
			],
			"fountains": [
				{"pos": Vector2(0, -1500), "heal_pct": 0.40},
			],
			"breakable_density": 0.0003,
			"breakable_hp": 25.0,
			"boosts": [
				{"pos": Vector2(0, 500), "type": "speed", "amount": 0.6, "size": Vector2(100, 60)},
				{"pos": Vector2(0, -500), "type": "speed", "amount": 0.6, "size": Vector2(100, 60)},
			],
		},
	},
	# ═══════════════════════════════════════════════════════
	#  Stage 2 — Il Molise (bonus)
	# ═══════════════════════════════════════════════════════
	{
		"id": 2,
		"name": "Il Molise",
		"desc": "Peaceful meadow hiding a secret.\n15 min limit. Enemies stay still.",
		"time_limit": 900.0,
		"bg_color": Color(0.06, 0.16, 0.04),
		"map_width": 6000,
		"map_height": 6000,
		"move_speed_mod": 1.0,
		"enemy_speed_mod": 0.0,  # stationary enemies
		"gold_mod": 1.0,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 1.0,
		"spawn_min_interval": 0.12,
		"spawn_ramp_time": 18.0,
		"wave_size_interval": 20.0,
		"difficulty_ramp_time": 40.0,
		"unlock_req": "clear_stage_1",
		"hyper_unlock": "default",     # unlocked by default with stage
		"hyper_mods": {
			"move_speed_bonus": 1.0,   # +100%
			"gold_mult": 1.5,          # +50%
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.6,     # +60% enemy HP
		},
		"stage_items": [],
		"interactables": {
			"chests": [
				{"pos": Vector2(-2000, -1500)},
				{"pos": Vector2(2500, -1000)},
				{"pos": Vector2(-1800, 2000)},
				{"pos": Vector2(2000, 2500)},
			],
			"fountains": [
				{"pos": Vector2(-500, 500), "heal_pct": 0.50},
				{"pos": Vector2(800, -300), "heal_pct": 0.50},
			],
			"breakable_density": 0.0,
			"boosts": [
				{"pos": Vector2(-1500, 1500), "type": "speed", "amount": 0.4, "size": Vector2(100, 100)},
				{"pos": Vector2(1500, -1500), "type": "might", "amount": 0.3, "size": Vector2(100, 100)},
			],
		},
	},
	# ═══════════════════════════════════════════════════════
	#  Stage 3 — Dairy Plant
	# ═══════════════════════════════════════════════════════
	{
		"id": 3,
		"name": "Dairy Plant",
		"desc": "Abandoned factory overrun by experiments.\n+25% Move Speed. +20% Gold. Carts block paths.",
		"time_limit": 1800.0,
		"bg_color": Color(0.08, 0.06, 0.16),
		"map_width": 5400,
		"map_height": 4400,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.2,
		"gold_mod": 1.2,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 1.5,
		"spawn_min_interval": 0.2,
		"spawn_ramp_time": 22.0,
		"wave_size_interval": 22.0,
		"difficulty_ramp_time": 45.0,
		"unlock_req": "clear_stage_2",
		"hyper_unlock": "boss_stage_3",
		"hyper_mods": {
			"move_speed_bonus": 0.9,   # +90% (total 2.15)
			"gold_mult": 1.7,          # +70%
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.0,
		},
		"stage_items": [
			{"type": 15, "is_weapon": false, "pos": Vector2(-1200, 1200)},  # Magnet (Attractorb)
			{"type": 7,  "is_weapon": false, "pos": Vector2(1800, -800)},  # Candelabrador
			{"type": 3,  "is_weapon": false, "pos": Vector2(-600, -1400)}, # Wings
			{"type": 23, "is_weapon": false, "pos": Vector2(800, 1000)},   # Armor
		],
		"interactables": {
			"chests": [
				{"pos": Vector2(-2000, 1500)},
				{"pos": Vector2(2000, -1200)},
			],
			"fountains": [
				{"pos": Vector2(0, 0), "heal_pct": 0.40},
			],
			"breakable_density": 0.0003,
			"breakable_hp": 30.0,
			"hazards": [
				{"pos": Vector2(1500, 800), "size": Vector2(150, 80), "dps": 18.0},
				{"pos": Vector2(-1800, -500), "size": Vector2(120, 120), "dps": 15.0},
			],
			"boosts": [
				{"pos": Vector2(-500, 1500), "type": "might", "amount": 0.25, "size": Vector2(80, 80)},
			],
		},
	},
	# ═══════════════════════════════════════════════════════
	#  Stage 4 — Gallo Tower
	# ═══════════════════════════════════════════════════════
	{
		"id": 4,
		"name": "Gallo Tower",
		"desc": "An edifice of science and sorcery.\n+25% Move Speed. +30% Gold. Vertical ascent.",
		"time_limit": 1800.0,
		"bg_color": Color(0.12, 0.02, 0.18),
		"map_width": 3200,
		"map_height": 7800,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.3,
		"gold_mod": 1.3,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 1.3,
		"spawn_min_interval": 0.18,
		"spawn_ramp_time": 20.0,
		"wave_size_interval": 20.0,
		"difficulty_ramp_time": 40.0,
		"unlock_req": "clear_stage_3",
		"hyper_unlock": "boss_stage_4",
		"hyper_mods": {
			"move_speed_bonus": 0.9,   # +90% (total 2.15)
			"gold_mult": 1.8,          # +80%
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.0,
		},
		"stage_items": [
			{"type": 24, "is_weapon": false, "pos": Vector2(0, -2400)},   # Bracer
			{"type": 22, "is_weapon": false, "pos": Vector2(0, 2400)},   # Spellbinder
		],
		"interactables": {
			"chests": [
				{"pos": Vector2(-800, -3000)},
				{"pos": Vector2(800, 3000)},
			],
			"fountains": [
				{"pos": Vector2(0, 0), "heal_pct": 0.35},
			],
			"breakable_density": 0.00025,
			"breakable_hp": 20.0,
			"hazards": [
				{"pos": Vector2(-1000, -1500), "size": Vector2(100, 100), "dps": 12.0},
				{"pos": Vector2(1000, 1500), "size": Vector2(100, 100), "dps": 12.0},
			],
			"boosts": [
				{"pos": Vector2(0, -1000), "type": "speed", "amount": 0.4, "size": Vector2(80, 80)},
			],
		},
	},
	# ═══════════════════════════════════════════════════════
	#  Stage 5 — Cappella Magna
	# ═══════════════════════════════════════════════════════
	{
		"id": 5,
		"name": "Cappella Magna",
		"desc": "Nexus of debased purity.\n+40% Move Speed. +40% Gold. Grand chapel.",
		"time_limit": 1800.0,
		"bg_color": Color(0.18, 0.04, 0.06),
		"map_width": 6600,
		"map_height": 5000,
		"move_speed_mod": 1.4,
		"enemy_speed_mod": 1.5,
		"gold_mod": 1.4,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 1.0,
		"spawn_min_interval": 0.15,
		"spawn_ramp_time": 18.0,
		"wave_size_interval": 18.0,
		"difficulty_ramp_time": 35.0,
		"unlock_req": "clear_stage_4",
		"hyper_unlock": "boss_stage_5",
		"hyper_mods": {
			"move_speed_bonus": 1.0,   # +100% (total 2.4)
			"gold_mult": 1.9,          # +90%
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.0,
		},
		"stage_items": [
			{"type": 8,  "is_weapon": false, "pos": Vector2(-2400, -1200)}, # Crown
			{"type": 26, "is_weapon": false, "pos": Vector2(2800, 1000)},  # Tiragisú
			{"type": 13, "is_weapon": false, "pos": Vector2(0, 2000)},    # Duplicator
		],
		"interactables": {
			"chests": [
				{"pos": Vector2(-2000, 1500)},
				{"pos": Vector2(2500, -1000)},
				{"pos": Vector2(0, -2000)},
			],
			"fountains": [
				{"pos": Vector2(-1500, 0), "heal_pct": 0.50},
				{"pos": Vector2(2000, 500), "heal_pct": 0.50},
			],
			"breakable_density": 0.0002,
			"breakable_hp": 35.0,
			"hazards": [
				{"pos": Vector2(0, 0), "size": Vector2(180, 120), "dps": 20.0},
			],
		},
	},
	# ═══════════════════════════════════════════════════════
	#  Stage 6 — Moongolow (bonus)
	# ═══════════════════════════════════════════════════════
	{
		"id": 6,
		"name": "Moongolow",
		"desc": "City swallowed by the sea.\n15 min limit. All passives available.",
		"time_limit": 900.0,
		"bg_color": Color(0.02, 0.04, 0.15),
		"map_width": 5400,
		"map_height": 4000,
		"move_speed_mod": 1.35,
		"enemy_speed_mod": 1.3,
		"gold_mod": 1.0,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 1.2,
		"spawn_min_interval": 0.15,
		"spawn_ramp_time": 20.0,
		"wave_size_interval": 20.0,
		"difficulty_ramp_time": 35.0,
		"unlock_req": "clear_stage_5",
		"hyper_unlock": "boss_stage_6",
		"hyper_mods": {
			"move_speed_bonus": 1.0, "gold_mult": 1.5,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.0,
		},
		"stage_items": [
			{"type": 4, "is_weapon": false, "pos": Vector2(-1600, -600)},
			{"type": 6, "is_weapon": false, "pos": Vector2(1200, 400)},
			{"type": 9, "is_weapon": false, "pos": Vector2(-800, 1400)},
			{"type": 5, "is_weapon": false, "pos": Vector2(1000, -1000)},
		],
		"interactables": {
			"chests": [
				{"pos": Vector2(-2000, 1000)},
				{"pos": Vector2(2000, -1500)},
			],
			"fountains": [
				{"pos": Vector2(0, 0), "heal_pct": 0.45},
			],
			"breakable_density": 0.0002,
			"breakable_hp": 20.0,
			"hazards": [
				{"pos": Vector2(-1000, 500), "size": Vector2(150, 80), "dps": 10.0},
				{"pos": Vector2(1500, -800), "size": Vector2(120, 120), "dps": 12.0},
			],
		},
	},
	# ═══════════════════════════════════════════════════════
	#  Stage 7 — Green Acres (challenge)
	# ═══════════════════════════════════════════════════════
	{
		"id": 7,
		"name": "Green Acres",
		"desc": "Realm of changing fate.\nRandom enemy waves. +50% Enemy HP.",
		"time_limit": 1800.0,
		"bg_color": Color(0.06, 0.18, 0.06),
		"map_width": 6000,
		"map_height": 4500,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.3,
		"gold_mod": 1.0,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.5,
		"spawn_base_interval": 1.0,
		"spawn_min_interval": 0.15,
		"spawn_ramp_time": 20.0,
		"wave_size_interval": 20.0,
		"difficulty_ramp_time": 40.0,
		"unlock_req": "reach_level_40",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.9, "gold_mult": 1.5,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.5,
		},
		"stage_items": [],
		"interactables": {
			"chests": [
				{"pos": Vector2(-2500, -1000)},
				{"pos": Vector2(2000, 1500)},
				{"pos": Vector2(-1000, 2000)},
			],
			"fountains": [
				{"pos": Vector2(0, 0), "heal_pct": 0.50},
			],
			"breakable_density": 0.00015,
			"breakable_hp": 25.0,
			"hazards": [
				{"pos": Vector2(-1000, -2000), "size": Vector2(200, 100), "dps": 15.0},
			],
			"boosts": [
				{"pos": Vector2(1000, 500), "type": "magnet", "amount": 1.0, "size": Vector2(100, 100)},
			],
		},
	},
	# ═══════════════════════════════════════════════════════
	#  Stage 8 — The Bone Zone (challenge)
	# ═══════════════════════════════════════════════════════
	{
		"id": 8,
		"name": "The Bone Zone",
		"desc": "Where the dead go to live.\nNo item drops. Enemies grow stronger.",
		"time_limit": 1800.0,
		"bg_color": Color(0.06, 0.04, 0.08),
		"map_width": 5400,
		"map_height": 4400,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.4,
		"gold_mod": 1.5,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 0.8,
		"spawn_min_interval": 0.12,
		"spawn_ramp_time": 15.0,
		"wave_size_interval": 15.0,
		"difficulty_ramp_time": 30.0,
		"unlock_req": "reach_level_50",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.9, "gold_mult": 2.0,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.0,
		},
		"stage_items": [],
		"interactables": {
			"chests": [
				{"pos": Vector2(-2000, -1500)},
				{"pos": Vector2(2000, 1500)},
			],
			"fountains": [
				{"pos": Vector2(500, -500), "heal_pct": 0.40},
			],
			"breakable_density": 0.00035,
			"breakable_hp": 25.0,
			"hazards": [
				{"pos": Vector2(-1500, 500), "size": Vector2(150, 100), "dps": 18.0},
				{"pos": Vector2(1500, -1000), "size": Vector2(120, 120), "dps": 15.0},
				{"pos": Vector2(-500, 2000), "size": Vector2(100, 200), "dps": 20.0},
			],
		},
	},
	# ═══════════════════════════════════════════════════════
	#  Stage 9 — Boss Rash (challenge)
	# ═══════════════════════════════════════════════════════
	{
		"id": 9,
		"name": "Boss Rash",
		"desc": "The monsters want entertainment.\n15 min limit. All bosses, all the time.",
		"time_limit": 900.0,
		"bg_color": Color(0.15, 0.02, 0.02),
		"map_width": 5000,
		"map_height": 3600,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.5,
		"gold_mod": 1.5,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.5,
		"spawn_base_interval": 3.0,
		"spawn_min_interval": 0.5,
		"spawn_ramp_time": 10.0,
		"wave_size_interval": 10.0,
		"difficulty_ramp_time": 20.0,
		"unlock_req": "reach_level_60",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.9, "gold_mult": 1.5,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.6,
		},
		"stage_items": [
			{"type": 4, "is_weapon": false, "pos": Vector2(-1000, 0)},
			{"type": 6, "is_weapon": false, "pos": Vector2(1000, 0)},
			{"type": 7, "is_weapon": false, "pos": Vector2(0, -800)},
			{"type": 13, "is_weapon": false, "pos": Vector2(0, 800)},
		],
		"interactables": {
			"fountains": [
				{"pos": Vector2(0, 0), "heal_pct": 0.50},
				{"pos": Vector2(-2000, -1000), "heal_pct": 0.30},
				{"pos": Vector2(2000, 1000), "heal_pct": 0.30},
			],
			"breakable_density": 0.0,
			"hazards": [
				{"pos": Vector2(-1000, -800), "size": Vector2(120, 80), "dps": 15.0},
				{"pos": Vector2(1000, 800), "size": Vector2(120, 80), "dps": 15.0},
			],
			"boosts": [
				{"pos": Vector2(-1500, 0), "type": "might", "amount": 0.5, "size": Vector2(100, 100)},
				{"pos": Vector2(1500, 0), "type": "speed", "amount": 0.5, "size": Vector2(100, 100)},
			],
		},
	},
	# ═══════════════════════════════════════════════════════
	#  Stage 10 — Whiteout (bonus)
	# ═══════════════════════════════════════════════════════
	{
		"id": 10,
		"name": "Whiteout",
		"desc": "Arctic glacier.\n20 min limit. Fire weapons deal extra damage.",
		"time_limit": 1200.0,
		"bg_color": Color(0.1, 0.12, 0.18),
		"map_width": 5400,
		"map_height": 4400,
		"move_speed_mod": 1.35,
		"enemy_speed_mod": 1.3,
		"gold_mod": 1.0,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 1.3,
		"spawn_min_interval": 0.18,
		"spawn_ramp_time": 22.0,
		"wave_size_interval": 22.0,
		"difficulty_ramp_time": 40.0,
		"unlock_req": "clear_stage_3",
		"hyper_unlock": "boss_stage_10",
		"hyper_mods": {
			"move_speed_bonus": 1.0, "gold_mult": 1.25,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.0,
		},
		"stage_items": [
			{"type": 25, "is_weapon": false, "pos": Vector2(-1600, -1000)},
			{"type": 3, "is_weapon": false, "pos": Vector2(1400, 1000)},
			{"type": 4, "is_weapon": false, "pos": Vector2(0, -1500)},
		],
		"interactables": {
			"chests": [
				{"pos": Vector2(-2000, 1500)},
				{"pos": Vector2(2000, -1500)},
			],
			"fountains": [
				{"pos": Vector2(500, 500), "heal_pct": 0.45},
			],
			"breakable_density": 0.0002,
			"breakable_hp": 30.0,
			"hazards": [
				{"pos": Vector2(-1500, -500), "size": Vector2(160, 100), "dps": 10.0},
				{"pos": Vector2(1500, 800), "size": Vector2(140, 100), "dps": 12.0},
			],
			"boosts": [
				{"pos": Vector2(-500, -2000), "type": "speed", "amount": 0.4, "size": Vector2(100, 100)},
			],
		},
	},
	# ═══════════════════════════════════════════════════════
	#  Stage 11 — The Lycaeum (bonus)
	# ═══════════════════════════════════════════════════════
	{
		"id": 11,
		"name": "The Lycaeum",
		"desc": "School submerged beneath a sunlit lake.\n+20% Gold. Strange fish.",
		"time_limit": 1200.0,
		"bg_color": Color(0.04, 0.1, 0.16),
		"map_width": 5200,
		"map_height": 3800,
		"move_speed_mod": 1.0,
		"enemy_speed_mod": 1.2,
		"gold_mod": 1.2,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 1.5,
		"spawn_min_interval": 0.2,
		"spawn_ramp_time": 25.0,
		"wave_size_interval": 25.0,
		"difficulty_ramp_time": 45.0,
		"unlock_req": "clear_stage_4",
		"hyper_unlock": "boss_stage_11",
		"hyper_mods": {
			"move_speed_bonus": 1.0, "gold_mult": 1.7,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.0,
		},
		"stage_items": [
			{"type": 15, "is_weapon": false, "pos": Vector2(-1200, 800)},
			{"type": 3, "is_weapon": false, "pos": Vector2(1000, -600)},
			{"type": 22, "is_weapon": false, "pos": Vector2(-800, -1200)},
		],
		"interactables": {
			"chests": [
				{"pos": Vector2(-2000, 1200)},
				{"pos": Vector2(2000, -1000)},
			],
			"fountains": [
				{"pos": Vector2(0, 0), "heal_pct": 0.50},
			],
			"breakable_density": 0.0002,
			"breakable_hp": 20.0,
			"hazards": [
				{"pos": Vector2(-1500, -500), "size": Vector2(200, 100), "dps": 10.0},
				{"pos": Vector2(1500, 800), "size": Vector2(150, 100), "dps": 8.0},
			],
			"boosts": [
				{"pos": Vector2(0, -1500), "type": "might", "amount": 0.3, "size": Vector2(80, 80)},
			],
		},
	},
	# ═══════════════════════════════════════════════════════
	#  Stage 12 — The Coop (bonus)
	# ═══════════════════════════════════════════════════════
	{
		"id": 12,
		"name": "The Coop",
		"desc": "Farm where beasts learned cooperation.\n-65% XP. Stage grows over time.",
		"time_limit": 1200.0,
		"bg_color": Color(0.08, 0.12, 0.04),
		"map_width": 4000,
		"map_height": 4000,
		"move_speed_mod": 1.35,
		"enemy_speed_mod": 1.2,
		"gold_mod": 1.0,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 1.0,
		"spawn_min_interval": 0.15,
		"spawn_ramp_time": 18.0,
		"wave_size_interval": 18.0,
		"difficulty_ramp_time": 35.0,
		"unlock_req": "reach_level_30",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 1.0, "gold_mult": 1.25,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 1.0,
		},
		"stage_items": [
			{"type": 12, "is_weapon": false, "pos": Vector2(0, 0)},
		],
	},
	# ═══════════════════════════════════════════════════════
	#  Stage 13 — Space 54 (bonus)
	# ═══════════════════════════════════════════════════════
	{
		"id": 13,
		"name": "Space 54",
		"desc": "Cosmic plane where space folds.\n+30% Gold. Dimensional chaos.",
		"time_limit": 1200.0,
		"bg_color": Color(0.02, 0.02, 0.14),
		"map_width": 4000,
		"map_height": 3000,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.4,
		"gold_mod": 1.3,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.2,
		"spawn_base_interval": 1.0,
		"spawn_min_interval": 0.12,
		"spawn_ramp_time": 18.0,
		"wave_size_interval": 18.0,
		"difficulty_ramp_time": 30.0,
		"unlock_req": "reach_level_55",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.9, "gold_mult": 1.8,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.0,
		},
		"stage_items": [],
		"interactables": {
			"chests": [
				{"pos": Vector2(-2500, -1000)},
				{"pos": Vector2(2000, 1500)},
			],
			"fountains": [
				{"pos": Vector2(0, 0), "heal_pct": 0.40},
			],
			"breakable_density": 0.00015,
			"breakable_hp": 25.0,
			"hazards": [
				{"pos": Vector2(-1000, 2000), "size": Vector2(180, 100), "dps": 15.0},
				{"pos": Vector2(2500, -500), "size": Vector2(120, 120), "dps": 18.0},
			],
			"boosts": [
				{"pos": Vector2(-1500, 500), "type": "speed", "amount": 0.6, "size": Vector2(100, 100)},
				{"pos": Vector2(1500, -1000), "type": "might", "amount": 0.5, "size": Vector2(100, 100)},
			],
		},
	},
	# ═══════════════════════════════════════════════════════
	#  Stage 14 — Bat Country (challenge)
	# ═══════════════════════════════════════════════════════
	{
		"id": 14,
		"name": "Bat Country",
		"desc": "We can't stop here.\n-75% XP. Enemies hyper-scale over time.",
		"time_limit": 1200.0,
		"bg_color": Color(0.04, 0.02, 0.06),
		"map_width": 3200,
		"map_height": 2400,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.5,
		"gold_mod": 1.3,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 0.6,
		"spawn_min_interval": 0.1,
		"spawn_ramp_time": 12.0,
		"wave_size_interval": 12.0,
		"difficulty_ramp_time": 25.0,
		"unlock_req": "reach_level_65",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.9, "gold_mult": 1.8,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.0,
		},
		"stage_items": [],
	},
	# ═══════════════════════════════════════════════════════
	#  Stage 15 — Eudaimonia Machine (special)
	# ═══════════════════════════════════════════════════════
	{
		"id": 15,
		"name": "Eudaimonia Machine",
		"desc": "A space between spaces.\n99 min limit. The culmination.",
		"time_limit": 5940.0,  # 99 minutes
		"bg_color": Color(0.14, 0.08, 0.02),
		"map_width": 3000,
		"map_height": 3000,
		"move_speed_mod": 1.0,
		"enemy_speed_mod": 1.0,
		"gold_mod": 2.0,
		"luck_mod": 0.2,
		"enemy_hp_mod": 2.0,
		"spawn_base_interval": 0.8,
		"spawn_min_interval": 0.1,
		"spawn_ramp_time": 30.0,
		"wave_size_interval": 30.0,
		"difficulty_ramp_time": 60.0,
		"unlock_req": "relic_yellow_sign",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.0, "gold_mult": 1.0,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.0,
		},
		"stage_items": [
			{"type": 14, "is_weapon": false, "pos": Vector2(-800, 0)},
			{"type": 13, "is_weapon": false, "pos": Vector2(800, 0)},
			{"type": 8, "is_weapon": false, "pos": Vector2(0, -800)},
		],
		"interactables": {
			"chests": [
				{"pos": Vector2(-1000, -800)},
				{"pos": Vector2(1000, 800)},
				{"pos": Vector2(0, 1000)},
			],
			"fountains": [
				{"pos": Vector2(-500, 500), "heal_pct": 0.50},
				{"pos": Vector2(500, -500), "heal_pct": 0.50},
			],
			"breakable_density": 0.0,
			"boosts": [
				{"pos": Vector2(0, 0), "type": "might", "amount": 0.5, "size": Vector2(100, 100)},
				{"pos": Vector2(-500, -500), "type": "speed", "amount": 0.5, "size": Vector2(100, 100)},
				{"pos": Vector2(500, 500), "type": "magnet", "amount": 1.0, "size": Vector2(100, 100)},
			],
		},
	}
]


static func get_stage(id: int) -> Dictionary:
	for s in STAGES:
		if s["id"] == id:
			return s
	return STAGES[0]


static func get_stage_count() -> int:
	return STAGES.size()


# Returns the stage ID whose boss unlocks a given hyper unlock key
static func get_stage_id_for_hyper(unlock_key: String) -> int:
	for s in STAGES:
		if s.get("hyper_unlock", "") == unlock_key:
			return s["id"]
	return -1
