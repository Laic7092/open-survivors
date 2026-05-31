extends RefCounted
# Stage 9 — Boss Rash (challenge)
# Wiki: https://vampire.survivors.wiki/w/Boss_Rash
# Wave data sourced from wiki wave table.

static func get_data() -> Dictionary:
	return {
		"id": 9,
		"name": "Boss Rash",
		"desc": "The monsters want entertainment.\n15 minutes. All bosses. All the time.",
		"wiki_id": "RASH",
		"type": "Challenge",
		"time_limit": 900.0,
		"bg_color": Color(0.15, 0.02, 0.02),
		"map_width": 5000,
		"map_height": 3600,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.25,
		"gold_mod": 1.0,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.5,
		"enemy_hp_per_min": 0.1,
		"starting_spawns": 30,
		"spawn_base_interval": 1.5,
		"spawn_min_interval": 0.25,
		"spawn_ramp_time": 10.0,
		"wave_size_interval": 10.0,
		"difficulty_ramp_time": 20.0,
		"unlock_req": "unlock_5_hyper_modes",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.0,
			"gold_mult": 1.5,
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.5,
			"starting_spawns": 60,
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
		"wave_defs": [
			# Boss Rash: boss-rush format, minimal regular enemies, multiple bosses per wave
			{"time": 0,  "enemies": [{"id": "bat_r", "count": 1}], "enemy_minimum": 1, "interval": 1.0, "boss": "bat_g", "chest": true},
			{"time": 1,  "enemies": [{"id": "bat_r", "count": 1}], "enemy_minimum": 1, "interval": 1.0, "boss": "mantichana", "chest": true},
			{"time": 2,  "enemies": [{"id": "dust_elemental", "count": 1}], "enemy_minimum": 1, "interval": 1.0, "boss": "musc_musc", "chest": true},
			{"time": 3,  "enemies": [{"id": "medusa_head", "count": 1}], "enemy_minimum": 1, "interval": 1.0, "boss": "queen_medusa", "chest": true},
			{"time": 4,  "enemies": [{"id": "medusa_head", "count": 1}], "enemy_minimum": 1, "interval": 1.0, "boss": "hag", "chest": true},
			{"time": 5,  "enemies": [{"id": "skeleton", "count": 1}], "enemy_minimum": 1, "interval": 1.0, "boss": "giant_skeleton", "chest": true},
			{"time": 6,  "enemies": [{"id": "harzia", "count": 1}], "enemy_minimum": 1, "interval": 1.0, "boss": "manticore", "chest": true},
			{"time": 7,  "enemies": [{"id": "milk_elemental", "count": 1}], "enemy_minimum": 1, "interval": 1.0, "boss": "giant_crab", "chest": true},
			{"time": 8,  "enemies": [{"id": "sword_guardian", "count": 1}], "enemy_minimum": 1, "interval": 1.0, "boss": "archdemon", "chest": true},
			{"time": 9,  "enemies": [{"id": "unknown", "count": 1}], "enemy_minimum": 1, "interval": 1.0, "boss": "trinacria", "chest": true},
			{"time": 10, "enemies": [], "enemy_minimum": 1, "interval": 1.0, "boss": "ender", "chest": true},
			{"time": 11, "enemies": [{"id": "bat_r", "count": 1}], "enemy_minimum": 1, "interval": 1.0, "boss": "stalker", "chest": true},
			{"time": 12, "enemies": [{"id": "golem", "count": 20}], "enemy_minimum": 20, "interval": 1.0, "boss": "big_golem", "chest": true},
			{"time": 13, "enemies": [{"id": "bat_r", "count": 20}], "enemy_minimum": 20, "interval": 1.0, "boss": "giant_crab", "chest": true},
			{"time": 14, "enemies": [{"id": "dragon_shrimp", "count": 20}], "enemy_minimum": 20, "interval": 1.0, "boss": "trinacria", "chest": true},
			{"time": 15, "enemies": [], "enemy_minimum": 1, "interval": 10.0, "boss": "reaper"},
		],
		"map_events": [
			{"time": 1,  "type": "bat_swarm", "delay": 15.0, "chance": 0.7, "repeats": 2},
			{"time": 5,  "type": "ghost_swarm", "delay": 1.2, "chance": 0.7, "repeats": 2},
			{"time": 7,  "type": "jellyfish_swarm", "amount": 80, "duration": 10},
			{"time": 8,  "type": "dragon_swarm", "amount": 12, "duration": 20},
		],
		"decor_config": {
			"background_pattern": "solid",
			"decor_elements": [
				{"type": "dot", "count": 40, "size_min": 2, "size_max": 5,
				 "color": Color(0.18, 0.02, 0.02), "alpha_min": 0.15, "alpha_max": 0.35, "z": -49},
				{"type": "dot", "count": 10, "size_min": 1, "size_max": 3,
				 "color": Color(0.8, 0.1, 0.1), "alpha_min": 0.3, "alpha_max": 0.5, "z": -45},
			],
			"props": {
				"colors": [
					Color(0.20, 0.03, 0.03),
					Color(0.30, 0.05, 0.05),
					Color(0.15, 0.02, 0.08),
				],
			},
		},
	}
