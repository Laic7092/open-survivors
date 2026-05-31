extends RefCounted
# Stage 4 — Gallo Tower

static func get_data() -> Dictionary:
	return {
		"id": 4,
		"name": "Gallo Tower",
		"wiki_id": "TOWER",
		"type": "Normal",
		"desc": "An edifice of science and sorcery.\n+25% Move Speed. +30% Gold. Vertical ascent.",
		"time_limit": 1800.0,
		"bg_color": Color(0.12, 0.02, 0.18),
		"map_width": 3200,
		"map_height": 7800,
		"map_scale": 3.0,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.3,
		"gold_mod": 1.3,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 0.7,
		"spawn_min_interval": 0.1,
		"spawn_ramp_time": 20.0,
		"wave_size_interval": 20.0,
		"difficulty_ramp_time": 40.0,
		"unlock_req": "clear_stage_3",
		"hyper_unlock": "boss_stage_4",
		"hyper_mods": {
			"move_speed_bonus": 0.9,
			"gold_mult": 1.8,
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.0,
		},
		"stage_items": [
			{"type": 24, "is_weapon": false, "pos": Vector2(0, -2400)},
			{"type": 22, "is_weapon": false, "pos": Vector2(0, 2400)},
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

		# ── 波次定义（分钟级） ──
		"wave_defs": [
			# 0:00 — Wraith start
			{"time": 0,  "enemies": [{"id": "wraith", "count": 20}], "enemy_minimum": 20, "interval": 1.0},
			# 1:00 — +Bat
			{"time": 1,  "enemies": [{"id": "wraith", "count": 15}, {"id": "bat_s", "count": 15}], "enemy_minimum": 30, "interval": 0.8},
			# 2:00 — +Mantis
			{"time": 2,  "enemies": [{"id": "wraith", "count": 15}, {"id": "bat_s", "count": 20}, {"id": "mantis", "count": 10}], "enemy_minimum": 45, "interval": 0.7},
			# 3:00 — +Golem + Mantichana boss
			{"time": 3,  "enemies": [{"id": "wraith", "count": 15}, {"id": "mantis", "count": 15}, {"id": "golem", "count": 5}], "enemy_minimum": 35, "interval": 0.6, "boss": "mantichana", "chest": true},
			# 4:00 — +Mudman
			{"time": 4,  "enemies": [{"id": "mantis", "count": 15}, {"id": "golem", "count": 10}, {"id": "mudman", "count": 10}], "enemy_minimum": 35, "interval": 0.6},
			# 5:00 — Heavy infantry wave
			{"time": 5,  "enemies": [{"id": "golem", "count": 15}, {"id": "mudman", "count": 15}], "enemy_minimum": 30, "interval": 0.5},
			# 6:00 — +Werewolf
			{"time": 6,  "enemies": [{"id": "golem", "count": 10}, {"id": "mudman", "count": 15}, {"id": "werewolf", "count": 5}], "enemy_minimum": 30, "interval": 0.5, "boss": "bat_g", "chest": true},
			# 7:00 — Werewolf surge
			{"time": 7,  "enemies": [{"id": "werewolf", "count": 15}, {"id": "mudman", "count": 15}], "enemy_minimum": 30, "interval": 0.5},
			# 8:00 — +Big Mummy
			{"time": 8,  "enemies": [{"id": "werewolf", "count": 10}, {"id": "mudman", "count": 15}, {"id": "mummy_big", "count": 5}], "enemy_minimum": 30, "interval": 0.4, "boss": "bat_g", "chest": true},
			# 9:00 — Golem + Mummy
			{"time": 9,  "enemies": [{"id": "golem", "count": 15}, {"id": "mummy_big", "count": 10}], "enemy_minimum": 25, "interval": 0.4},
			# 10:00 — +Green Mudman + Arcana
			{"time": 10, "enemies": [{"id": "werewolf", "count": 20}, {"id": "mummy_big", "count": 10}, {"id": "mudman_g", "count": 10}], "enemy_minimum": 40, "interval": 0.3, "boss": "bat_g", "chest": true, "arcana": true},
			# 11:00 — Full mix
			{"time": 11, "enemies": [{"id": "werewolf", "count": 20}, {"id": "mudman_g", "count": 15}, {"id": "mummy_big", "count": 10}], "enemy_minimum": 45, "interval": 0.3},
			# 12:00 — Elite wave
			{"time": 12, "enemies": [{"id": "mummy_big", "count": 20}, {"id": "golem", "count": 15}], "enemy_minimum": 35, "interval": 0.3, "boss": "bat_g", "chest": true},
			# 13:00 — Pre-boss pressure
			{"time": 13, "enemies": [{"id": "werewolf", "count": 20}, {"id": "mudman_g", "count": 20}], "enemy_minimum": 40, "interval": 0.2},
			# 14:00 — Final build-up
			{"time": 14, "enemies": [{"id": "werewolf", "count": 30}, {"id": "mummy_big", "count": 20}, {"id": "golem", "count": 15}], "enemy_minimum": 65, "interval": 0.2},
			# 15:00 — Trinacria boss
			{"time": 15, "enemies": [{"id": "werewolf", "count": 10}], "enemy_minimum": 10, "interval": 0.5, "boss": "trinacria", "chest": true},
			# 16:00 — Post-boss wave
			{"time": 16, "enemies": [{"id": "werewolf", "count": 20}, {"id": "mudman_g", "count": 20}], "enemy_minimum": 40, "interval": 0.2, "boss": "bat_g", "chest": true},
			# 17:00 — Elite wave
			{"time": 17, "enemies": [{"id": "mummy_big", "count": 25}, {"id": "golem", "count": 15}], "enemy_minimum": 40, "interval": 0.2},
			# 18:00 — Arcana wave
			{"time": 18, "enemies": [{"id": "werewolf", "count": 25}, {"id": "mudman_g", "count": 25}], "enemy_minimum": 50, "interval": 0.1, "boss": "bat_g", "chest": true, "arcana": true},
			# 19:00 — Heavy mix
			{"time": 19, "enemies": [{"id": "mummy_big", "count": 20}, {"id": "werewolf", "count": 30}], "enemy_minimum": 50, "interval": 0.1},
			# 20:00 — Second Trinacria
			{"time": 20, "enemies": [{"id": "golem", "count": 30}, {"id": "mudman_g", "count": 30}], "enemy_minimum": 60, "interval": 0.1, "boss": "trinacria", "chest": true},
			# 21:00 — Intense
			{"time": 21, "enemies": [{"id": "werewolf", "count": 40}, {"id": "mummy_big", "count": 20}], "enemy_minimum": 60, "interval": 0.1},
			# 22:00 — All elites
			{"time": 22, "enemies": [{"id": "mummy_big", "count": 30}, {"id": "golem", "count": 20}, {"id": "werewolf", "count": 20}], "enemy_minimum": 70, "interval": 0.1},
			# 23:00 — Bat swarm + boss
			{"time": 23, "enemies": [{"id": "werewolf", "count": 30}, {"id": "golem", "count": 30}], "enemy_minimum": 60, "interval": 0.1, "boss": "bat_g", "chest": true},
			# 24:00 — Trinacria encore
			{"time": 24, "enemies": [{"id": "mummy_big", "count": 30}, {"id": "mudman_g", "count": 30}], "enemy_minimum": 60, "interval": 0.1, "boss": "trinacria", "chest": true},
			# 25:00 — Final stretch
			{"time": 25, "enemies": [{"id": "werewolf", "count": 50}, {"id": "mummy_big", "count": 30}], "enemy_minimum": 80, "interval": 0.1},
			# 26:00 — Elite wave
			{"time": 26, "enemies": [{"id": "golem", "count": 40}, {"id": "werewolf", "count": 40}], "enemy_minimum": 80, "interval": 0.1, "boss": "bat_g", "chest": true},
			# 27:00 — Ultimate
			{"time": 27, "enemies": [{"id": "mummy_big", "count": 40}, {"id": "mudman_g", "count": 40}], "enemy_minimum": 80, "interval": 0.1},
			# 28:00 — Trinacria
			{"time": 28, "enemies": [{"id": "werewolf", "count": 50}, {"id": "golem", "count": 30}], "enemy_minimum": 80, "interval": 0.1, "boss": "trinacria", "chest": true},
			# 29:00 — Last stand
			{"time": 29, "enemies": [{"id": "werewolf", "count": 60}, {"id": "mummy_big", "count": 40}], "enemy_minimum": 100, "interval": 0.05, "boss": "bat_g", "chest": true},
			# 30:00 — The Reaper
			{"time": 30, "enemies": [], "enemy_minimum": 1, "interval": 60.0, "boss": "reaper"},
		],

		# ── 地图事件 ──
		"map_events": [
			{"time": 3,  "type": "bat_swarm", "delay": 0.0, "chance": 1.0},
			{"time": 6,  "type": "bat_swarm", "delay": 5.0, "chance": 0.7},
			{"time": 10, "type": "bat_swarm", "delay": 0.0, "chance": 1.0},
			{"time": 15, "type": "bat_swarm", "delay": 3.0, "chance": 1.0},
			{"time": 18, "type": "bat_swarm", "delay": 0.0, "chance": 1.0},
			{"time": 20, "type": "bat_swarm", "delay": 0.0, "chance": 1.0},
			{"time": 25, "type": "bat_swarm", "delay": 0.0, "chance": 1.0},
			{"time": 29, "type": "bat_swarm", "delay": 0.0, "chance": 1.0},
			{"time": 29, "type": "bat_swarm", "delay": 15.0, "chance": 1.0},
		],
		"decor_config": {
			"background_pattern": "solid",
			"decor_elements": [
				{"type": "dot", "count": 40, "size_min": 2, "size_max": 5,
				 "color": Color(0.14, 0.02, 0.20), "alpha_min": 0.15, "alpha_max": 0.35, "z": -49},
				{"type": "dot", "count": 12, "size_min": 1, "size_max": 3,
				 "color": Color(0.6, 0.1, 0.8), "alpha_min": 0.2, "alpha_max": 0.5, "z": -45},
			],
			"props": {
				"colors": [
					Color(0.18, 0.04, 0.22),
					Color(0.22, 0.06, 0.28),
					Color(0.12, 0.02, 0.16),
				],
			},
		},
	}
