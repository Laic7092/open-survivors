extends RefCounted
# Stage 1 — Inlaid Library
# Vampire Survivors reference: https://vampire.survivors.wiki/w/Inlaid_Library
#
# 持续补怪模型：每波定义"维持最低 N 个敌人，每 interval 秒补一次"
# enemies 列表仅指定当前波次可用的敌人类型（无需 count）
# Boss 在波次开始时立即生成。

static func get_data() -> Dictionary:
	return {
		"id": 1,
		"wiki_id": "LIBRARY",
		"name": "Inlaid Library",
		"type": "Normal",
		"desc": "Halls of forbidden knowledge.\n+25% Move Speed. Narrow corridor.",

		"time_limit": 1800.0,
		"bg_color": Color(0.08, 0.02, 0.12),
		"map_width": 2800,
		"map_height": 7200,
		"theme": "Inlaid Library",

		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.15,
		"projectile_speed_mod": 1.0,
		"gold_mod": 1.0,
		"luck_mod": 0.0,
		"xp_mod": 1.0,
		"enemy_hp_mod": 1.0,

		"starting_spawns": 8,
		"enemy_minimum": 1,
		"spawn_base_interval": 1.0,
		"spawn_min_interval": 0.1,
		"spawn_ramp_time": 25.0,
		"wave_size_interval": 25.0,
		"difficulty_ramp_time": 50.0,

		"unlock_req": "clear_stage_0",
		"hyper_unlock": "boss_stage_1",

		"hyper_mods": {
			"move_speed_bonus": 0.9,
			"gold_mult": 1.5,
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.0,
		},

		"stage_items": [
			{"type": 14, "is_weapon": false, "pos": Vector2(0, -2400)},
			{"type": 5,  "is_weapon": false, "pos": Vector2(0, 2400)},
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

		# ── 波次定义 ──
		# Enemy minimum = 场上始终保持至少 N 个敌人
		# Interval = 每 N 秒检查一次，低于 minimum 则补怪
		# enemies = 该波次可用的敌人类型列表（随机选）
		# boss = 波次开始时立即生成的首领
		"wave_defs": [
			# 0:00-1:00 — Dust Elemental 主导
			{"time": 0, "enemies": [{"id": "dust_elemental"}], "enemy_minimum": 50, "interval": 3.0},
			{"time": 1, "enemies": [{"id": "dust_elemental"}], "enemy_minimum": 80, "interval": 3.0},

			# 2:00 — +Musc Musc
			{"time": 2, "enemies": [{"id": "dust_elemental"}, {"id": "musc_musc"}], "enemy_minimum": 100, "interval": 4.0},

			# 3:00 — Mummy + Boss Giant Mummy
			{"time": 3, "enemies": [{"id": "mummy"}], "enemy_minimum": 60, "interval": 4.0, "boss": "mummy_giant"},

			# 4:00 — Dust Elemental + Mummy
			{"time": 4, "enemies": [{"id": "dust_elemental"}, {"id": "mummy"}], "enemy_minimum": 110, "interval": 4.0},

			# 5:00 — Mummy + Boss Giant Mummy
			{"time": 5, "enemies": [{"id": "mummy"}], "enemy_minimum": 100, "interval": 4.0, "boss": "mummy_giant"},

			# 6:00-7:00 — Testa di Mano + Musc Musc
			{"time": 6, "enemies": [{"id": "testa_di_mano"}, {"id": "musc_musc"}], "enemy_minimum": 30, "interval": 2.0},
			{"time": 7, "enemies": [{"id": "testa_di_mano"}, {"id": "musc_musc"}, {"id": "big_musc_musc"}], "enemy_minimum": 80, "interval": 2.0},

			# 8:00 — Boss Colossal Musc Musc
			{"time": 8, "enemies": [{"id": "big_musc_musc"}, {"id": "ghost"}], "enemy_minimum": 80, "interval": 1.0, "boss": "colossal_musc_musc"},

			# 9:00 — Mummy + Ghost swarm
			{"time": 9, "enemies": [{"id": "mummy"}, {"id": "ghost"}], "enemy_minimum": 200, "interval": 0.5},

			# 10:00 — Boss Colossal Lionhead (chest)
			{"time": 10, "enemies": [{"id": "big_musc_musc"}], "enemy_minimum": 100, "interval": 0.5, "boss": "colossal_lionhead", "chest": true},

			# 11:00 — Medusa + Lionhead + Boss Colossal Sneaky Head + Arcana Glowing Bat
			{"time": 11, "enemies": [{"id": "big_sneaky_head"}, {"id": "lionhead"}], "enemy_minimum": 120, "interval": 2.0, "boss": "colossal_sneaky_head", "chest": true, "arcana": true},

			# 12:00 — Big Sneaky Head + Dullahan + Arcana Boss
			{"time": 12, "enemies": [{"id": "big_sneaky_head"}, {"id": "dullahan"}], "enemy_minimum": 80, "interval": 1.0, "boss": "bat_g", "chest": true},

			# 13:00 — Mummy + Dullahan + Boss Colossal Dust Elemental
			{"time": 13, "enemies": [{"id": "mummy"}, {"id": "dullahan"}], "enemy_minimum": 120, "interval": 0.5, "boss": "colossal_dust_elemental", "chest": true},

			# 14:00 — Mummy + Medusa + Big Musc Musc + Boss Silver Bat
			{"time": 14, "enemies": [{"id": "mummy"}, {"id": "medusa_head"}, {"id": "big_musc_musc"}], "enemy_minimum": 300, "interval": 0.1, "boss": "silver_bat", "chest": true},

			# 15:00 — Boss Queen Medusa
			{"time": 15, "enemies": [{"id": "aggressive_sneaky_head"}], "enemy_minimum": 100, "interval": 0.1, "boss": "queen_medusa", "chest": true},

			# 16:00 — Apprentice Witch + Dullahan variants
			{"time": 16, "enemies": [{"id": "apprentice_witch"}, {"id": "dullahan"}, {"id": "elite_dullahan"}], "enemy_minimum": 100, "interval": 1.0, "boss": "bat_g", "chest": true},

			# 17:00 — Witch + Musc Musc wave
			{"time": 17, "enemies": [{"id": "apprentice_witch"}, {"id": "big_musc_musc"}, {"id": "musc_musc"}], "enemy_minimum": 200, "interval": 1.0},

			# 18:00 — Boss Master Witch
			{"time": 18, "enemies": [{"id": "apprentice_witch"}, {"id": "lionhead"}], "enemy_minimum": 60, "interval": 0.5, "boss": "master_witch", "chest": true},

			# 19:00 — Witch + Elite Dullahan
			{"time": 19, "enemies": [{"id": "apprentice_witch"}, {"id": "elite_dullahan"}], "enemy_minimum": 120, "interval": 0.5},

			# 20:00 — Boss Nesuferit (3-weapon chest)
			{"time": 20, "enemies": [{"id": "lionhead"}, {"id": "elite_dullahan"}], "enemy_minimum": 100, "interval": 0.1, "boss": "nesuferit", "chest": true},

			# 21:00 — Arcana Glowing Bat
			{"time": 21, "enemies": [{"id": "lionhead"}], "enemy_minimum": 100, "interval": 0.1, "boss": "bat_g", "arcana": true},

			# 22:00 — Undead Witch + Lionhead + Arcana Boss
			{"time": 22, "enemies": [{"id": "undead_witch"}, {"id": "lionhead"}], "enemy_minimum": 80, "interval": 1.0, "boss": "bat_g", "chest": true},

			# 23:00 — Dullahan + Undead Witch + Boss Colossal Lionhead
			{"time": 23, "enemies": [{"id": "dullahan"}, {"id": "elite_dullahan"}, {"id": "undead_witch"}], "enemy_minimum": 120, "interval": 0.1, "boss": "colossal_lionhead", "chest": true},

			# 24:00 — Pure Undead Witch swarm
			{"time": 24, "enemies": [{"id": "undead_witch"}], "enemy_minimum": 300, "interval": 0.1},

			# 25:00 — Boss Hag (defeat = unlock hyper)
			{"time": 25, "enemies": [{"id": "glowing_skull"}, {"id": "undead_witch"}, {"id": "bat_giant"}], "enemy_minimum": 300, "interval": 0.1, "boss": "hag", "chest": true},

			# 26:00 — Giant Medusa + Boss Queen Medusa
			{"time": 26, "enemies": [{"id": "giant_medusa"}], "enemy_minimum": 100, "interval": 0.1, "boss": "queen_medusa", "chest": true},

			# 27:00 — Medusa swarm + Boss Queen Medusa
			{"time": 27, "enemies": [{"id": "big_sneaky_head"}, {"id": "giant_medusa"}], "enemy_minimum": 300, "interval": 0.1, "boss": "queen_medusa", "chest": true},

			# 28:00 — Witch + Colossal Sneaky Heads + Boss Queen Medusa
			{"time": 28, "enemies": [{"id": "apprentice_witch"}, {"id": "colossal_sneaky_head"}], "enemy_minimum": 250, "interval": 0.1, "boss": "queen_medusa", "chest": true},

			# 29:00 — All colossi wave
			{"time": 29, "enemies": [
				{"id": "colossal_dust_elemental"},
				{"id": "colossal_musc_musc"},
				{"id": "colossal_lionhead"},
				{"id": "colossal_sneaky_head"}
			], "enemy_minimum": 250, "interval": 0.1},

			# 30:00 — The Reaper
			{"time": 30, "enemies": [], "enemy_minimum": 1, "interval": 60.0, "boss": "reaper"},
		],

		# ── 地图事件（数据预留） ──
		"map_events": [
			{"time": 0, "type": "shade_bomb", "delay": 0.0, "chance": 1.0},
			{"time": 2, "type": "medusa_wall", "delay": 0.0, "chance": 1.0},
			{"time": 2, "type": "medusa_swarm", "delay": 5.0, "chance": 0.7, "count": 5},
			{"time": 5, "type": "medusa_wall", "delay": 0.0, "chance": 1.0},
			{"time": 5, "type": "medusa_swarm", "delay": 5.0, "chance": 0.7, "count": 6},
			{"time": 6, "type": "shade_bomb", "delay": 10.0, "chance": 0.5, "count": 5},
			{"time": 7, "type": "shade_bomb", "delay": 5.0, "chance": 0.8, "count": 9},
			{"time": 9, "type": "shade_bomb", "delay": 20.0, "chance": 0.5, "count": 3},
			{"time": 10, "type": "shade_bomb", "delay": 0.0, "chance": 1.0},
			{"time": 10, "type": "shade_bomb", "delay": 10.0, "chance": 0.8, "count": 4},
			{"time": 12, "type": "medusa_swarm", "delay": 0.0, "chance": 1.0},
			{"time": 12, "type": "medusa_wall", "delay": 5.0, "chance": 0.7, "count": 6},
			{"time": 15, "type": "medusa_wall", "delay": 0.0, "chance": 1.0},
			{"time": 15, "type": "medusa_swarm", "delay": 2.0, "chance": 0.9, "count": 26},
			{"time": 15, "type": "medusa_wall", "delay": 13.0, "chance": 1.0},
			{"time": 17, "type": "shade_bomb", "delay": 5.0, "chance": 0.5, "count": 5},
			{"time": 20, "type": "shade_bomb", "delay": 4.0, "chance": 0.5, "count": 26},
			{"time": 20, "type": "skull_swarm", "delay": 0.0, "chance": 1.0},
			{"time": 20, "type": "skull_swarm", "delay": 5.0, "chance": 1.0},
			{"time": 20, "type": "skull_swarm", "delay": 15.0, "chance": 1.0},
			{"time": 20, "type": "skull_swarm", "delay": 25.0, "chance": 1.0},
			{"time": 20, "type": "skull_swarm", "delay": 35.0, "chance": 1.0},
			{"time": 20, "type": "skull_swarm", "delay": 45.0, "chance": 1.0},
			{"time": 20, "type": "skull_swarm", "delay": 55.0, "chance": 1.0},
			{"time": 22, "type": "shade_bomb", "delay": 2.0, "chance": 0.5, "count": 26},
			{"time": 25, "type": "bat_swarm", "delay": 0.0, "chance": 1.0},
			{"time": 25, "type": "skull_swarm", "delay": 0.0, "chance": 1.0},
			{"time": 25, "type": "skull_swarm", "delay": 5.0, "chance": 1.0},
			{"time": 25, "type": "skull_swarm", "delay": 15.0, "chance": 1.0},
			{"time": 25, "type": "skull_swarm", "delay": 25.0, "chance": 1.0},
			{"time": 25, "type": "skull_swarm", "delay": 35.0, "chance": 1.0},
			{"time": 25, "type": "skull_swarm", "delay": 45.0, "chance": 1.0},
			{"time": 25, "type": "skull_swarm", "delay": 55.0, "chance": 1.0},
			{"time": 27, "type": "medusa_swarm", "delay": 0.0, "chance": 1.0},
			{"time": 27, "type": "medusa_wall", "delay": 2.0, "chance": 0.9, "count": 26},
			{"time": 29, "type": "shade_bomb", "delay": 1.0, "chance": 0.6, "count": 51},
		],

		"decor_config": {
			"background_pattern": "solid",
			"decor_elements": [
				{"type": "dot", "count": 40, "size_min": 2, "size_max": 4,
				 "color": Color(0.12, 0.04, 0.18), "alpha_min": 0.15, "alpha_max": 0.35, "z": -49},
				{"type": "dot", "count": 12, "size_min": 1, "size_max": 3,
				 "color": Color(0.5, 0.2, 0.7), "alpha_min": 0.2, "alpha_max": 0.5, "z": -45},
				{"type": "line", "count": 8, "length_min": 40, "length_max": 120,
				 "color": Color(0.3, 0.05, 0.4), "alpha_min": 0.1, "alpha_max": 0.25, "z": -48},
			],
			"props": {
				"colors": [
					Color(0.25, 0.08, 0.30),
					Color(0.30, 0.05, 0.20),
					Color(0.15, 0.05, 0.25),
				],
			},
		},
	}
