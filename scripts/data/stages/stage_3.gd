extends RefCounted
# Stage 3 — Dairy Plant

static func get_data() -> Dictionary:
	return {
		"id": 3,
		"wiki_id": "WAREHOUSE",
		"name": "Dairy Plant",
		"type": "Normal",
		"desc": "An abandoned factory overrun by failed experiments.\n+25% Move Speed. +20% Gold.",
		"time_limit": 1800.0,
		"bg_color": Color(0.08, 0.06, 0.16),
		"map_width": 5400,
		"map_height": 4400,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.2,
		"gold_mod": 1.2,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 0.8,
		"spawn_min_interval": 0.12,
		"spawn_ramp_time": 22.0,
		"wave_size_interval": 22.0,
		"difficulty_ramp_time": 45.0,
		"unlock_req": "clear_stage_2",
		"hyper_unlock": "boss_stage_3",
		"hyper_mods": {
			"move_speed_bonus": 0.9,
			"gold_mult": 1.7,
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.0,
		},
		"stage_items": [
			{"type": 15, "is_weapon": false, "pos": Vector2(-1200, 1200)},
			{"type": 7,  "is_weapon": false, "pos": Vector2(1800, -800)},
			{"type": 3,  "is_weapon": false, "pos": Vector2(-600, -1400)},
			{"type": 23, "is_weapon": false, "pos": Vector2(800, 1000)},
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

		# ── 波次定义（分钟级） ──
		"wave_defs": [
			# 0:00 — Viper swarm start
			{"time": 0,  "enemies": [{"id": "viper", "count": 20}], "enemy_minimum": 20, "interval": 1.0},
			# 1:00 — +Skeleton
			{"time": 1,  "enemies": [{"id": "viper", "count": 15}, {"id": "skeleton", "count": 15}], "enemy_minimum": 30, "interval": 0.8},
			# 2:00 — +Zombie
			{"time": 2,  "enemies": [{"id": "viper", "count": 15}, {"id": "skeleton", "count": 15}, {"id": "zombie", "count": 10}], "enemy_minimum": 40, "interval": 0.7},
			# 3:00 — +Mudman
			{"time": 3,  "enemies": [{"id": "skeleton", "count": 20}, {"id": "zombie", "count": 15}, {"id": "mudman", "count": 5}], "enemy_minimum": 40, "interval": 0.7},
			# 4:00 — Mantichana boss
			{"time": 4,  "enemies": [{"id": "zombie", "count": 20}, {"id": "mudman", "count": 10}], "enemy_minimum": 30, "interval": 0.6, "boss": "mantichana", "chest": true},
			# 5:00 — +Werewolf
			{"time": 5,  "enemies": [{"id": "mudman", "count": 10}, {"id": "werewolf", "count": 5}], "enemy_minimum": 15, "interval": 0.6},
			# 6:00 — Heavy wave
			{"time": 6,  "enemies": [{"id": "skeleton", "count": 30}, {"id": "mudman", "count": 15}, {"id": "werewolf", "count": 5}], "enemy_minimum": 50, "interval": 0.5},
			# 7:00 — Mudman + Werewolf
			{"time": 7,  "enemies": [{"id": "mudman", "count": 15}, {"id": "werewolf", "count": 10}], "enemy_minimum": 25, "interval": 0.5},
			# 8:00 — +Big Mummy + Glowing Bat boss
			{"time": 8,  "enemies": [{"id": "mudman", "count": 10}, {"id": "werewolf", "count": 10}, {"id": "mummy_big", "count": 5}], "enemy_minimum": 25, "interval": 0.5, "boss": "bat_g", "chest": true},
			# 9:00 — +Green Mudman
			{"time": 9,  "enemies": [{"id": "werewolf", "count": 10}, {"id": "mummy_big", "count": 10}, {"id": "mudman_g", "count": 10}], "enemy_minimum": 30, "interval": 0.4, "boss": "bat_g", "chest": true},
			# 10:00 — Mix wave
			{"time": 10, "enemies": [{"id": "werewolf", "count": 15}, {"id": "mummy_big", "count": 10}, {"id": "mudman", "count": 20}], "enemy_minimum": 45, "interval": 0.4},
			# 11:00 — Arcana wave
			{"time": 11, "enemies": [{"id": "mudman_g", "count": 15}, {"id": "golem", "count": 5}], "enemy_minimum": 20, "interval": 0.3, "boss": "bat_g", "chest": true, "arcana": true},
			# 12:00 — Dense mummy wave
			{"time": 12, "enemies": [{"id": "mummy_big", "count": 20}, {"id": "golem", "count": 10}], "enemy_minimum": 30, "interval": 0.3},
			# 13:00 — Full mix
			{"time": 13, "enemies": [{"id": "werewolf", "count": 20}, {"id": "mudman_g", "count": 20}, {"id": "mummy_big", "count": 10}], "enemy_minimum": 50, "interval": 0.2, "boss": "bat_g", "chest": true},
			# 14:00 — Pre-boss build-up
			{"time": 14, "enemies": [{"id": "werewolf", "count": 25}, {"id": "mummy_big", "count": 15}, {"id": "golem", "count": 15}], "enemy_minimum": 55, "interval": 0.2},
			# 15:00 — Giant Crab boss
			{"time": 15, "enemies": [{"id": "werewolf", "count": 10}], "enemy_minimum": 10, "interval": 0.5, "boss": "giant_crab", "chest": true},
			# 16:00 — Post-boss
			{"time": 16, "enemies": [{"id": "werewolf", "count": 20}, {"id": "mudman_g", "count": 20}], "enemy_minimum": 40, "interval": 0.3, "boss": "bat_g", "chest": true},
			# 17:00 — Big Mummy surge
			{"time": 17, "enemies": [{"id": "mummy_big", "count": 30}, {"id": "golem", "count": 10}], "enemy_minimum": 40, "interval": 0.3},
			# 18:00 — Green Mudman wave
			{"time": 18, "enemies": [{"id": "mudman_g", "count": 30}, {"id": "werewolf", "count": 15}], "enemy_minimum": 45, "interval": 0.2, "boss": "bat_g", "chest": true},
			# 19:00 — Heavy elite wave
			{"time": 19, "enemies": [{"id": "mummy_big", "count": 20}, {"id": "golem", "count": 20}, {"id": "werewolf", "count": 20}], "enemy_minimum": 60, "interval": 0.2},
			# 20:00 — Arcana wave
			{"time": 20, "enemies": [{"id": "mudman_g", "count": 40}, {"id": "mummy_big", "count": 20}], "enemy_minimum": 60, "interval": 0.1, "boss": "bat_g", "chest": true, "arcana": true},
			# 21:00 — Second Giant Crab
			{"time": 21, "enemies": [{"id": "golem", "count": 25}, {"id": "werewolf", "count": 25}], "enemy_minimum": 50, "interval": 0.1, "boss": "giant_crab", "chest": true},
			# 22:00 — Last stretch
			{"time": 22, "enemies": [{"id": "mummy_big", "count": 30}, {"id": "mudman_g", "count": 30}], "enemy_minimum": 60, "interval": 0.1},
			# 23:00 — Mix
			{"time": 23, "enemies": [{"id": "werewolf", "count": 30}, {"id": "golem", "count": 20}, {"id": "mummy_big", "count": 20}], "enemy_minimum": 70, "interval": 0.1},
			# 24:00 — Giant Crab
			{"time": 24, "enemies": [{"id": "mudman_g", "count": 30}, {"id": "werewolf", "count": 30}], "enemy_minimum": 60, "interval": 0.1, "boss": "giant_crab", "chest": true},
			# 25:00 — Final wave start
			{"time": 25, "enemies": [{"id": "werewolf", "count": 50}, {"id": "mummy_big", "count": 30}, {"id": "golem", "count": 20}], "enemy_minimum": 100, "interval": 0.1},
			# 26:00 — All elite
			{"time": 26, "enemies": [{"id": "mummy_big", "count": 40}, {"id": "mudman_g", "count": 40}], "enemy_minimum": 80, "interval": 0.1, "boss": "bat_g", "chest": true},
			# 27:00 — Giant Crab
			{"time": 27, "enemies": [{"id": "golem", "count": 40}, {"id": "werewolf", "count": 40}], "enemy_minimum": 80, "interval": 0.1, "boss": "giant_crab", "chest": true},
			# 28:00 — Full aggression
			{"time": 28, "enemies": [{"id": "werewolf", "count": 60}, {"id": "mudman_g", "count": 40}], "enemy_minimum": 100, "interval": 0.1, "boss": "bat_g", "chest": true},
			# 29:00 — Ultimate wave
			{"time": 29, "enemies": [{"id": "mummy_big", "count": 50}, {"id": "golem", "count": 50}], "enemy_minimum": 100, "interval": 0.05, "boss": "giant_crab", "chest": true},
			# 30:00 — The Reaper
			{"time": 30, "enemies": [], "enemy_minimum": 1, "interval": 60.0, "boss": "reaper"},
		],

		# ── 地图事件 ──
		"map_events": [
			{"time": 4,  "type": "bat_swarm", "delay": 0.0, "chance": 1.0},
			{"time": 8,  "type": "bat_swarm", "delay": 5.0, "chance": 0.7},
			{"time": 11, "type": "bat_swarm", "delay": 0.0, "chance": 1.0},
			{"time": 15, "type": "bat_swarm", "delay": 3.0, "chance": 1.0},
			{"time": 20, "type": "bat_swarm", "delay": 0.0, "chance": 1.0},
			{"time": 25, "type": "bat_swarm", "delay": 0.0, "chance": 1.0},
			{"time": 25, "type": "bat_swarm", "delay": 10.0, "chance": 1.0},
			{"time": 29, "type": "bat_swarm", "delay": 0.0, "chance": 1.0},
			{"time": 29, "type": "bat_swarm", "delay": 15.0, "chance": 1.0},
		],
		"decor_config": {
			"background_pattern": "solid",
			"decor_elements": [
				{"type": "dot", "count": 45, "size_min": 2, "size_max": 5,
				 "color": Color(0.10, 0.08, 0.18), "alpha_min": 0.15, "alpha_max": 0.35, "z": -49},
				{"type": "dot", "count": 12, "size_min": 1, "size_max": 3,
				 "color": Color(0.4, 0.3, 0.7), "alpha_min": 0.2, "alpha_max": 0.4, "z": -45},
			],
			"props": {
				"colors": [
					Color(0.12, 0.08, 0.20),
					Color(0.18, 0.10, 0.25),
					Color(0.15, 0.06, 0.12),
				],
			},
		},
	}
