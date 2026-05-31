extends RefCounted
# Stage 6 — Moongolow (bonus)

static func get_data() -> Dictionary:
	return {
		"id": 6,
		"name": "Moongolow",
		"wiki_id": "SINKING",
		"type": "Bonus",
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
		"spawn_base_interval": 0.65,
		"spawn_min_interval": 0.1,
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

		# ── 波次定义（分钟级 — 15分钟限定） ──
		"wave_defs": [
			# 0:00 — Mixed start
			{"time": 0,  "enemies": [{"id": "wraith", "count": 15}, {"id": "bat_s", "count": 15}], "enemy_minimum": 30, "interval": 0.8},
			# 1:00 — +Zombie
			{"time": 1,  "enemies": [{"id": "wraith", "count": 15}, {"id": "zombie", "count": 15}], "enemy_minimum": 30, "interval": 0.7},
			# 2:00 — +Viper
			{"time": 2,  "enemies": [{"id": "wraith", "count": 10}, {"id": "viper", "count": 20}, {"id": "zombie", "count": 15}], "enemy_minimum": 45, "interval": 0.6},
			# 3:00 — +Skeleton + Mantichana
			{"time": 3,  "enemies": [{"id": "viper", "count": 20}, {"id": "skeleton", "count": 15}], "enemy_minimum": 35, "interval": 0.6, "boss": "mantichana", "chest": true},
			# 4:00 — +Golem
			{"time": 4,  "enemies": [{"id": "viper", "count": 20}, {"id": "golem", "count": 10}, {"id": "skeleton", "count": 15}], "enemy_minimum": 45, "interval": 0.5},
			# 5:00 — +Mantis + Glowing Bat
			{"time": 5,  "enemies": [{"id": "golem", "count": 10}, {"id": "mantis", "count": 20}, {"id": "viper", "count": 15}], "enemy_minimum": 45, "interval": 0.5, "boss": "bat_g", "chest": true},
			# 6:00 — Werewolf introduction
			{"time": 6,  "enemies": [{"id": "golem", "count": 15}, {"id": "mantis", "count": 20}, {"id": "werewolf", "count": 5}], "enemy_minimum": 40, "interval": 0.3},
			# 7:00 — Pre-Nightmare build-up + Arcana
			{"time": 7,  "enemies": [{"id": "werewolf", "count": 15}, {"id": "golem", "count": 15}, {"id": "mantis", "count": 20}], "enemy_minimum": 50, "interval": 0.3, "boss": "bat_g", "chest": true, "arcana": true},
			# 8:00 — Nightmare boss (~7:30)
			{"time": 8,  "enemies": [{"id": "werewolf", "count": 10}], "enemy_minimum": 10, "interval": 0.5, "boss": "nightmare", "chest": true},
			# 9:00 — Post-boss wave
			{"time": 9,  "enemies": [{"id": "werewolf", "count": 20}, {"id": "golem", "count": 15}], "enemy_minimum": 35, "interval": 0.2},
			# 10:00 — Elite push + Glowing Bat
			{"time": 10, "enemies": [{"id": "werewolf", "count": 25}, {"id": "mantis", "count": 20}, {"id": "golem", "count": 15}], "enemy_minimum": 60, "interval": 0.2, "boss": "bat_g", "chest": true},
			# 11:00 — Big Mummy appears
			{"time": 11, "enemies": [{"id": "werewolf", "count": 20}, {"id": "mummy_big", "count": 15}], "enemy_minimum": 35, "interval": 0.1},
			# 12:00 — Second Nightmare
			{"time": 12, "enemies": [{"id": "werewolf", "count": 30}, {"id": "mummy_big", "count": 15}], "enemy_minimum": 45, "interval": 0.1, "boss": "nightmare", "chest": true},
			# 13:00 — Final build-up
			{"time": 13, "enemies": [{"id": "werewolf", "count": 30}, {"id": "mummy_big", "count": 20}, {"id": "golem", "count": 20}], "enemy_minimum": 70, "interval": 0.1},
			# 14:00 — Last wave
			{"time": 14, "enemies": [{"id": "werewolf", "count": 40}, {"id": "mummy_big", "count": 20}], "enemy_minimum": 60, "interval": 0.05, "boss": "bat_g", "chest": true},
			# 15:00 — The Reaper
			{"time": 15, "enemies": [], "enemy_minimum": 1, "interval": 60.0, "boss": "reaper"},
		],

		# ── 地图事件 ──
		"map_events": [
			{"time": 2,  "type": "bat_swarm", "delay": 0.0, "chance": 1.0},
			{"time": 5,  "type": "bat_swarm", "delay": 5.0, "chance": 0.7},
			{"time": 7,  "type": "bat_swarm", "delay": 0.0, "chance": 1.0},
			{"time": 10, "type": "bat_swarm", "delay": 0.0, "chance": 1.0},
			{"time": 14, "type": "bat_swarm", "delay": 0.0, "chance": 1.0},
		],
		"decor_config": {
			"background_pattern": "solid",
			"decor_elements": [
				{"type": "dot", "count": 40, "size_min": 2, "size_max": 5,
				 "color": Color(0.02, 0.04, 0.18), "alpha_min": 0.15, "alpha_max": 0.35, "z": -49},
				{"type": "dot", "count": 10, "size_min": 1, "size_max": 3,
				 "color": Color(0.2, 0.5, 0.9), "alpha_min": 0.2, "alpha_max": 0.4, "z": -45},
			],
			"props": {
				"colors": [
					Color(0.04, 0.06, 0.20),
					Color(0.06, 0.08, 0.22),
					Color(0.08, 0.04, 0.12),
				],
			},
		},
	}
