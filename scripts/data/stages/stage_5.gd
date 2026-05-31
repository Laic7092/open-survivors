extends RefCounted
# Stage 5 — Cappella Magna
# Vampire Survivors reference: https://vampire-survivors.fandom.com/wiki/Cappella_Magna

static func get_data() -> Dictionary:
	return {
		"id": 5,
		"name": "Cappella Magna",
		"wiki_id": "CHAPEL",
		"type": "Normal",
		"desc": "Nexus of debased purity.\n+40% Move Speed. +40% Gold. Grand chapel.",
		"time_limit": 1800.0,
		"bg_color": Color(0.18, 0.04, 0.06),
		"map_width": 6600,
		"map_height": 5000,
		"map_scale": 3.0,
		"move_speed_mod": 1.4,
		"enemy_speed_mod": 1.5,
		"gold_mod": 1.4,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 0.5,
		"spawn_min_interval": 0.1,
		"spawn_ramp_time": 18.0,
		"wave_size_interval": 18.0,
		"difficulty_ramp_time": 35.0,
		"unlock_req": "clear_stage_4",
		"hyper_unlock": "boss_stage_5",
		"hyper_mods": {
			"move_speed_bonus": 1.0,
			"gold_mult": 1.9,
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.0,
		},
		"stage_items": [
			{"type": 8,  "is_weapon": false, "pos": Vector2(-2400, -1200)},
			{"type": 26, "is_weapon": false, "pos": Vector2(2800, 1000)},
			{"type": 13, "is_weapon": false, "pos": Vector2(0, 2000)},
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

		# ── 波次定义（分钟级） ──
		"wave_defs": [
			# 0:00 — Wraith start (harder baseline)
			{"time": 0,  "enemies": [{"id": "wraith", "count": 25}], "enemy_minimum": 25, "interval": 0.8},
			# 1:00 — +Mantis
			{"time": 1,  "enemies": [{"id": "wraith", "count": 20}, {"id": "mantis", "count": 15}], "enemy_minimum": 35, "interval": 0.7},
			# 2:00 — +Golem
			{"time": 2,  "enemies": [{"id": "wraith", "count": 15}, {"id": "mantis", "count": 15}, {"id": "golem", "count": 10}], "enemy_minimum": 40, "interval": 0.6},
			# 3:00 — +Mudman + Mantichana boss
			{"time": 3,  "enemies": [{"id": "mantis", "count": 20}, {"id": "golem", "count": 10}, {"id": "mudman", "count": 10}], "enemy_minimum": 40, "interval": 0.5, "boss": "mantichana", "chest": true},
			# 4:00 — Heavy infantry
			{"time": 4,  "enemies": [{"id": "golem", "count": 15}, {"id": "mudman", "count": 20}], "enemy_minimum": 35, "interval": 0.5},
			# 5:00 — +Werewolf
			{"time": 5,  "enemies": [{"id": "golem", "count": 10}, {"id": "mudman", "count": 15}, {"id": "werewolf", "count": 10}], "enemy_minimum": 35, "interval": 0.4, "boss": "bat_g", "chest": true},
			# 6:00 — Werewolf surge
			{"time": 6,  "enemies": [{"id": "werewolf", "count": 20}, {"id": "mudman", "count": 20}], "enemy_minimum": 40, "interval": 0.4},
			# 7:00 — +Big Mummy
			{"time": 7,  "enemies": [{"id": "werewolf", "count": 20}, {"id": "mudman", "count": 15}, {"id": "mummy_big", "count": 5}], "enemy_minimum": 40, "interval": 0.3},
			# 8:00 — +Green Mudman
			{"time": 8,  "enemies": [{"id": "werewolf", "count": 20}, {"id": "mummy_big", "count": 10}, {"id": "mudman_g", "count": 5}], "enemy_minimum": 35, "interval": 0.3, "boss": "bat_g", "chest": true},
			# 9:00 — Elite mix + Arcana
			{"time": 9,  "enemies": [{"id": "werewolf", "count": 25}, {"id": "mummy_big", "count": 15}], "enemy_minimum": 40, "interval": 0.3, "boss": "bat_g", "chest": true, "arcana": true},
			# 10:00 — Full mix
			{"time": 10, "enemies": [{"id": "werewolf", "count": 25}, {"id": "mummy_big", "count": 15}, {"id": "mudman_g", "count": 15}], "enemy_minimum": 55, "interval": 0.2},
			# 11:00 — Golem + Mummy
			{"time": 11, "enemies": [{"id": "golem", "count": 25}, {"id": "mummy_big", "count": 20}], "enemy_minimum": 45, "interval": 0.2},
			# 12:00 — Werewolf swarm
			{"time": 12, "enemies": [{"id": "werewolf", "count": 30}, {"id": "mudman_g", "count": 20}], "enemy_minimum": 50, "interval": 0.2, "boss": "bat_g", "chest": true},
			# 13:00 — Pre-boss pressure
			{"time": 13, "enemies": [{"id": "werewolf", "count": 30}, {"id": "mummy_big", "count": 20}, {"id": "mudman_g", "count": 20}], "enemy_minimum": 70, "interval": 0.1},
			# 14:00 — Final build-up
			{"time": 14, "enemies": [{"id": "werewolf", "count": 40}, {"id": "golem", "count": 30}], "enemy_minimum": 70, "interval": 0.1},
			# 15:00 — Nightmare boss
			{"time": 15, "enemies": [{"id": "werewolf", "count": 15}], "enemy_minimum": 15, "interval": 0.5, "boss": "nightmare", "chest": true},
			# 16:00 — Post-boss
			{"time": 16, "enemies": [{"id": "werewolf", "count": 30}, {"id": "mudman_g", "count": 20}], "enemy_minimum": 50, "interval": 0.1, "boss": "bat_g", "chest": true},
			# 17:00 — Heavy elites
			{"time": 17, "enemies": [{"id": "mummy_big", "count": 30}, {"id": "golem", "count": 20}], "enemy_minimum": 50, "interval": 0.1},
			# 18:00 — Arcana wave
			{"time": 18, "enemies": [{"id": "werewolf", "count": 35}, {"id": "mummy_big", "count": 20}], "enemy_minimum": 55, "interval": 0.1, "boss": "bat_g", "chest": true, "arcana": true},
			# 19:00 — Mudman + Werewolf
			{"time": 19, "enemies": [{"id": "mudman_g", "count": 30}, {"id": "werewolf", "count": 30}], "enemy_minimum": 60, "interval": 0.1},
			# 20:00 — Second Nightmare
			{"time": 20, "enemies": [{"id": "golem", "count": 30}, {"id": "mummy_big", "count": 30}], "enemy_minimum": 60, "interval": 0.1, "boss": "nightmare", "chest": true},
			# 21:00 — Elite wave
			{"time": 21, "enemies": [{"id": "werewolf", "count": 40}, {"id": "mudman_g", "count": 30}], "enemy_minimum": 70, "interval": 0.1},
			# 22:00 — All big enemies
			{"time": 22, "enemies": [{"id": "mummy_big", "count": 30}, {"id": "golem", "count": 30}, {"id": "werewolf", "count": 20}], "enemy_minimum": 80, "interval": 0.1},
			# 23:00 — Bat swarm
			{"time": 23, "enemies": [{"id": "werewolf", "count": 40}, {"id": "golem", "count": 30}], "enemy_minimum": 70, "interval": 0.1, "boss": "bat_g", "chest": true},
			# 24:00 — Nightmare encore
			{"time": 24, "enemies": [{"id": "mummy_big", "count": 40}, {"id": "mudman_g", "count": 30}], "enemy_minimum": 70, "interval": 0.1, "boss": "nightmare", "chest": true},
			# 25:00 — Final stretch
			{"time": 25, "enemies": [{"id": "werewolf", "count": 60}, {"id": "mummy_big", "count": 30}], "enemy_minimum": 90, "interval": 0.1},
			# 26:00 — Elite rush
			{"time": 26, "enemies": [{"id": "golem", "count": 40}, {"id": "werewolf", "count": 40}], "enemy_minimum": 80, "interval": 0.1, "boss": "bat_g", "chest": true},
			# 27:00 — All enemies
			{"time": 27, "enemies": [{"id": "mummy_big", "count": 40}, {"id": "mudman_g", "count": 40}], "enemy_minimum": 80, "interval": 0.1},
			# 28:00 — Nightmare
			{"time": 28, "enemies": [{"id": "werewolf", "count": 50}, {"id": "golem", "count": 30}], "enemy_minimum": 80, "interval": 0.1, "boss": "nightmare", "chest": true},
			# 29:00 — Ultimate wave
			{"time": 29, "enemies": [{"id": "werewolf", "count": 60}, {"id": "mummy_big", "count": 40}, {"id": "golem", "count": 30}], "enemy_minimum": 130, "interval": 0.05, "boss": "bat_g", "chest": true},
			# 30:00 — The Reaper
			{"time": 30, "enemies": [], "enemy_minimum": 1, "interval": 60.0, "boss": "reaper"},
		],

		# ── 地图事件 ──
		"map_events": [
			{"time": 3,  "type": "bat_swarm", "delay": 0.0, "chance": 1.0},
			{"time": 5,  "type": "bat_swarm", "delay": 5.0, "chance": 0.7},
			{"time": 9,  "type": "bat_swarm", "delay": 0.0, "chance": 1.0},
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
				 "color": Color(0.20, 0.04, 0.08), "alpha_min": 0.15, "alpha_max": 0.35, "z": -49},
				{"type": "dot", "count": 10, "size_min": 1, "size_max": 3,
				 "color": Color(0.9, 0.2, 0.2), "alpha_min": 0.3, "alpha_max": 0.5, "z": -45},
			],
			"props": {
				"colors": [
					Color(0.25, 0.06, 0.10),
					Color(0.30, 0.08, 0.12),
					Color(0.18, 0.04, 0.06),
				],
			},
		},
	}
