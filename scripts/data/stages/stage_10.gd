extends RefCounted
# Stage 10 — Whiteout (bonus)
# Wiki: https://vampire.survivors.wiki/w/Whiteout
# Wave data sourced from wiki wave table.

static func get_data() -> Dictionary:
	return {
		"id": 10,
		"wiki_id": "WHITEOUT",
		"name": "Whiteout",
		"type": "Bonus",
		"desc": "Arctic mirages and a slow, constant snowstorm make this great glacier a hostile environment.\nFire weapons deal extra damage.",
		"time_limit": 1200.0,
		"bg_color": Color(0.1, 0.12, 0.18),
		"map_width": 5400,
		"map_height": 4400,
		"move_speed_mod": 1.35,
		"enemy_speed_mod": 1.0,
		"gold_mod": 1.0,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 0.7,
		"spawn_min_interval": 0.1,
		"spawn_ramp_time": 22.0,
		"wave_size_interval": 22.0,
		"difficulty_ramp_time": 40.0,
		"unlock_req": "collect_20_orologions",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.65,
			"gold_mult": 1.25,
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.0,
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
		"wave_defs": [
			{"time": 0,  "enemies": [{"id": "miragellos", "count": 15}], "enemy_minimum": 15, "interval": 1.0},
			{"time": 1,  "enemies": [{"id": "miragellos", "count": 30}], "enemy_minimum": 30, "interval": 1.0},
			{"time": 2,  "enemies": [{"id": "miragellos", "count": 50}], "enemy_minimum": 50, "interval": 0.5},
			{"time": 3,  "enemies": [{"id": "miragellos", "count": 40}], "enemy_minimum": 40, "interval": 0.25, "boss": "bat_g", "chest": true},
			{"time": 4,  "enemies": [{"id": "ghost", "count": 15}, {"id": "miragellos", "count": 15}], "enemy_minimum": 30, "interval": 0.5},
			{"time": 5,  "enemies": [{"id": "madd_onna", "count": 10}], "enemy_minimum": 10, "interval": 1.0},
			{"time": 6,  "enemies": [{"id": "madd_onna", "count": 10}, {"id": "miragellos", "count": 10}], "enemy_minimum": 20, "interval": 0.5, "boss": "bat_g", "chest": true},
			{"time": 7,  "enemies": [{"id": "madd_onna", "count": 40}, {"id": "miragellos", "count": 40}], "enemy_minimum": 80, "interval": 0.5, "boss": "bat_g", "chest": true, "arcana": true},
			{"time": 8,  "enemies": [{"id": "miragellos", "count": 100}], "enemy_minimum": 100, "interval": 1.5},
			{"time": 9,  "enemies": [{"id": "menta_elemental", "count": 15}, {"id": "miragellos", "count": 15}], "enemy_minimum": 30, "interval": 0.5, "boss": "bat_g", "chest": true},
			{"time": 10, "enemies": [{"id": "madd_onna", "count": 20}], "enemy_minimum": 20, "interval": 1.0},
			{"time": 11, "enemies": [{"id": "miragellos", "count": 300}], "enemy_minimum": 300, "interval": 0.5},
			{"time": 12, "enemies": [{"id": "menta_elemental", "count": 7}, {"id": "ghost", "count": 7}, {"id": "miragellos", "count": 6}], "enemy_minimum": 20, "interval": 0.5, "boss": "bat_g", "chest": true},
			{"time": 13, "enemies": [{"id": "menta_elemental", "count": 150}], "enemy_minimum": 150, "interval": 0.5},
			{"time": 14, "enemies": [{"id": "menta_elemental", "count": 20}], "enemy_minimum": 20, "interval": 0.5, "boss": "bat_g", "chest": true, "arcana": true},
			{"time": 15, "enemies": [{"id": "miragellos", "count": 60}], "enemy_minimum": 60, "interval": 0.5, "boss": "kizzune", "chest": true},
			{"time": 16, "enemies": [{"id": "miragellos", "count": 60}], "enemy_minimum": 60, "interval": 0.5, "boss": "kizzune", "chest": true},
			{"time": 17, "enemies": [{"id": "bambaman", "count": 20}], "enemy_minimum": 20, "interval": 0.5},
			{"time": 18, "enemies": [{"id": "bambaman", "count": 60}], "enemy_minimum": 60, "interval": 0.5, "boss": "bat_g", "chest": true},
			{"time": 19, "enemies": [{"id": "bambaman", "count": 100}], "enemy_minimum": 100, "interval": 0.5},
			{"time": 20, "enemies": [], "enemy_minimum": 1, "interval": 10.0, "boss": "reaper"},
		],
		"map_events": [
			{"time": 2,  "type": "diamond_maze"},
			{"time": 5,  "type": "diamond_maze"},
			{"time": 8,  "type": "diamond_maze"},
			{"time": 11, "type": "diamond_maze"},
			{"time": 14, "type": "diamond_maze"},
			{"time": 17, "type": "diamond_maze"},
			{"time": 19, "type": "diamond_maze"},
		],
		"decor_config": {
			"background_pattern": "solid",
			"decor_elements": [
				{"type": "dot", "count": 50, "size_min": 2, "size_max": 5,
				 "color": Color(0.12, 0.14, 0.20), "alpha_min": 0.15, "alpha_max": 0.35, "z": -49},
				{"type": "dot", "count": 15, "size_min": 1, "size_max": 3,
				 "color": Color(0.6, 0.7, 0.9), "alpha_min": 0.2, "alpha_max": 0.4, "z": -45},
			],
			"props": {
				"colors": [
					Color(0.15, 0.18, 0.25),
					Color(0.20, 0.22, 0.30),
					Color(0.10, 0.12, 0.18),
				],
			},
		},
	}
