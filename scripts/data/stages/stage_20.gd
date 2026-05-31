extends RefCounted
# Stage 20 — Westwoods (challenge)
# Wiki: https://vampire.survivors.wiki/w/Westwoods
# Wave data sourced from wiki wave table.
# Note: Unique casino-themed enemies mapped to closest project equivalents.

static func get_data() -> Dictionary:
	return {
		"id": 20,
		"name": "Westwoods",
		"wiki_id": "EX_WESTWOODS",
		"type": "Challenge",
		"desc": "Greed's gone green. Arcane avarice is transforming these once serene woods into a ghoulish gambling den.\n+20% Luck. Random events.",
		"time_limit": 1200.0,
		"bg_color": Color(0.1, 0.16, 0.04),
		"map_width": 4800,
		"map_height": 3600,
		"map_scale": 2.5,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.0,
		"gold_mod": 1.2,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 0.3,
		"spawn_min_interval": 0.07,
		"spawn_ramp_time": 15.0,
		"wave_size_interval": 15.0,
		"difficulty_ramp_time": 30.0,
		"unlock_req": "find_23_little_clovers",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.65,
			"gold_mult": 1.8,
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.0,
		},
		"stage_items": [],
		"interactables": {
			"chests": [
				{"pos": Vector2(-1500, -1000)},
				{"pos": Vector2(1500, 1000)},
			],
			"fountains": [
				{"pos": Vector2(0, 0), "heal_pct": 0.50},
			],
			"breakable_density": 0.00015,
			"breakable_hp": 25.0,
			"hazards": [
				{"pos": Vector2(-1200, 800), "size": Vector2(150, 80), "dps": 18.0},
				{"pos": Vector2(1500, -500), "size": Vector2(120, 100), "dps": 15.0},
			],
			"boosts": [
				{"pos": Vector2(800, -800), "type": "magnet", "amount": 1.0, "size": Vector2(80, 80)},
			],
		},
		"wave_defs": [
			# Barm → wraith, Squillers → bat_s, Goldie → viper, Gamblin → mantis
			# Ghoulette → ghost, Dandybrine (boss) → bat_g, Daimon (boss) → bat_g
			# Gambergar → golem, Harzia → harzia, Card Sharp → skeleton_ninja
			# Toll → big_golem, Mushroulette (boss) → bat_g, Knight of Spades → archon_spada
			# Valentine → nightmare (boss), Ghiavolo → ghiavolo
			{"time": 0,  "enemies": [{"id": "wraith", "count": 15}, {"id": "bat_s", "count": 15}], "enemy_minimum": 30, "interval": 2.5},
			{"time": 1,  "enemies": [{"id": "wraith", "count": 10}, {"id": "viper", "count": 10}, {"id": "bat_s", "count": 5}], "enemy_minimum": 25, "interval": 0.8, "boss": "bat_g", "chest": true},
			{"time": 2,  "enemies": [{"id": "viper", "count": 10}, {"id": "harzia", "count": 10}], "enemy_minimum": 20, "interval": 1.1},
			{"time": 3,  "enemies": [{"id": "wraith", "count": 50}], "enemy_minimum": 50, "interval": 0.4, "boss": "bat_g", "chest": true},
			{"time": 4,  "enemies": [{"id": "harzia", "count": 15}, {"id": "viper", "count": 10}], "enemy_minimum": 25, "interval": 0.25},
			{"time": 5,  "enemies": [{"id": "wraith", "count": 15}, {"id": "mantis", "count": 15}], "enemy_minimum": 30, "interval": 0.8, "boss": "bat_g", "chest": true},
			{"time": 6,  "enemies": [{"id": "viper", "count": 25}, {"id": "mantis", "count": 25}, {"id": "bat_s", "count": 20}], "enemy_minimum": 70, "interval": 1.0},
			{"time": 7,  "enemies": [{"id": "ghiavolo", "count": 30}, {"id": "ghost", "count": 30}], "enemy_minimum": 60, "interval": 0.5, "boss": "bat_g", "chest": true},
			{"time": 8,  "enemies": [{"id": "mantis", "count": 45}, {"id": "harzia", "count": 45}], "enemy_minimum": 90, "interval": 0.9},
			{"time": 9,  "enemies": [{"id": "golem", "count": 20}, {"id": "mantis", "count": 20}], "enemy_minimum": 40, "interval": 0.7, "boss": "bat_g", "chest": true},
			{"time": 10, "enemies": [{"id": "big_golem", "count": 15}, {"id": "wraith", "count": 15}, {"id": "skeleton_ninja", "count": 10}], "enemy_minimum": 40, "interval": 0.5, "boss": "bat_g", "chest": true, "arcana": true},
			{"time": 11, "enemies": [{"id": "mantis", "count": 35}, {"id": "golem", "count": 35}, {"id": "harzia", "count": 30}], "enemy_minimum": 100, "interval": 0.5, "boss": "bat_g", "chest": true},
			{"time": 12, "enemies": [{"id": "ghost", "count": 20}, {"id": "big_golem", "count": 20}], "enemy_minimum": 40, "interval": 0.8, "boss": "bat_g", "chest": true},
			{"time": 13, "enemies": [{"id": "mantis", "count": 40}, {"id": "golem", "count": 40}, {"id": "skeleton_ninja", "count": 40}], "enemy_minimum": 120, "interval": 0.3},
			{"time": 14, "enemies": [{"id": "big_golem", "count": 150}], "enemy_minimum": 150, "interval": 0.5},
			{"time": 15, "enemies": [{"id": "golem", "count": 30}, {"id": "mantis", "count": 30}, {"id": "ghost", "count": 20}], "enemy_minimum": 80, "interval": 0.3},
			{"time": 16, "enemies": [{"id": "ghost", "count": 40}, {"id": "ghiavolo", "count": 40}], "enemy_minimum": 80, "interval": 0.6, "boss": "archon_spada", "chest": true},
			{"time": 17, "enemies": [{"id": "bat_g", "count": 15}, {"id": "golem", "count": 15}], "enemy_minimum": 30, "interval": 0.2},
			{"time": 18, "enemies": [{"id": "bat_g", "count": 20}, {"id": "bat_g", "count": 20}], "enemy_minimum": 40, "interval": 0.8, "boss": "nightmare", "chest": true},
			{"time": 19, "enemies": [{"id": "nightmare", "count": 30}, {"id": "ghiavolo", "count": 30}, {"id": "bat_s", "count": 30}], "enemy_minimum": 90, "interval": 0.5},
			{"time": 20, "enemies": [], "enemy_minimum": 1, "interval": 10.0, "boss": "reaper"},
		],
		"map_events": [
			{"time": 0,  "type": "squiller_swarm", "repeats": 7},
			{"time": 1,  "type": "squiller_swarm", "repeats": 10},
			{"time": 2,  "type": "squiller_swarm_2", "repeats": 7},
			{"time": 3,  "type": "squiller_swarm", "repeats": 5},
			{"time": 4,  "type": "pile_assault"},
			{"time": 6,  "type": "squiller_combo"},
			{"time": 8,  "type": "squiller_swarm", "repeats": 10},
			{"time": 9,  "type": "squiller_combo", "repeats": 2},
			{"time": 10, "type": "squiller_swarm", "chance": 0.5, "repeats": 5},
			{"time": 11, "type": "squiller_combo", "repeats": 4},
			{"time": 12, "type": "squiller_swarm_2", "repeats": 10},
			{"time": 15, "type": "squiller_combo"},
		],
		"decor_config": {
			"background_pattern": "solid",
			"decor_elements": [
				{"type": "dot", "count": 50, "size_min": 2, "size_max": 5,
				 "color": Color(0.12, 0.18, 0.04), "alpha_min": 0.15, "alpha_max": 0.35, "z": -49},
				{"type": "dot", "count": 15, "size_min": 1, "size_max": 3,
				 "color": Color(0.5, 0.8, 0.2), "alpha_min": 0.3, "alpha_max": 0.6, "z": -45},
			],
			"props": {
				"colors": [
					Color(0.15, 0.22, 0.06),
					Color(0.20, 0.28, 0.08),
					Color(0.08, 0.12, 0.04),
				],
			},
		},
	}
