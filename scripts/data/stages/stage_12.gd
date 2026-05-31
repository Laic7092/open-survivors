extends RefCounted
# Stage 12 — The Coop (bonus)
# Wiki: https://vampire.survivors.wiki/w/The_Coop
# Wave data sourced from wiki wave table.
# Note: Unique chicken enemies (Chickenfantry, Cockreliutennant, etc.) mapped to
# closest project equivalents.

static func get_data() -> Dictionary:
	return {
		"id": 12,
		"name": "The Coop",
		"wiki_id": "COOP",
		"type": "Bonus",
		"desc": "A farm for fear itself, the beasts reared here have turned from tasty morsels to terrifying monsters after realising the deadly power of cooperation.",
		"time_limit": 1200.0,
		"bg_color": Color(0.08, 0.12, 0.04),
		"map_width": 4000,
		"map_height": 4000,
		"move_speed_mod": 1.35,
		"enemy_speed_mod": 1.0,
		"gold_mod": 1.0,
		"luck_mod": 0.0,
		"xp_mod": 0.35,
		"enemy_hp_mod": 1.0,
		"starting_spawns": 50,
		"spawn_base_interval": 0.5,
		"spawn_min_interval": 0.1,
		"spawn_ramp_time": 18.0,
		"wave_size_interval": 18.0,
		"difficulty_ramp_time": 35.0,
		"unlock_req": "collect_500_floor_chicken",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.65,
			"gold_mult": 1.25,
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 2.0,
		},
		"stage_items": [
			# Parm Aegis — available after 1:00 (1 fence east)
			{"type": 12, "is_weapon": true, "pos": Vector2(400, 0)},
			# Fire Wand — available after 5:00 (5 fences east)
			{"type": 12, "is_weapon": true, "pos": Vector2(2000, 0)},
		],
		"interactables": {
			"chests": [
				{"pos": Vector2(-1200, 1200)},
				{"pos": Vector2(1200, -1200)},
			],
			"fountains": [
				{"pos": Vector2(0, 0), "heal_pct": 0.40},
			],
			"breakable_density": 0.0002,
			"breakable_hp": 20.0,
			"hazards": [
				{"pos": Vector2(-800, 800), "size": Vector2(120, 80), "dps": 10.0},
				{"pos": Vector2(1000, 500), "size": Vector2(100, 100), "dps": 12.0},
			],
			"boosts": [
				{"pos": Vector2(-500, -1000), "type": "speed", "amount": 0.4, "size": Vector2(80, 80)},
			],
		},
		"wave_defs": [
			# Chickenfantry → wraith, Cockreliutennant → mantis, Chik → bat_s, Egge → viper
			# Pol.lo Rosso → bat_r, Abraxas → bat_g (mini-boss)
			{"time": 0,  "enemies": [{"id": "wraith", "count": 100}], "enemy_minimum": 100, "interval": 0.1, "boss": "wraith", "chest": true},
			{"time": 1,  "enemies": [{"id": "wraith", "count": 20}, {"id": "mantis", "count": 20}, {"id": "bat_s", "count": 15}, {"id": "viper", "count": 15}], "enemy_minimum": 70, "interval": 0.5},
			{"time": 2,  "enemies": [{"id": "wraith", "count": 100}, {"id": "bat_s", "count": 100}], "enemy_minimum": 200, "interval": 0.05},
			{"time": 3,  "enemies": [{"id": "wraith", "count": 35}, {"id": "bat_s", "count": 35}], "enemy_minimum": 70, "interval": 0.4, "boss": "bat_g", "chest": true},
			{"time": 4,  "enemies": [{"id": "bat_s", "count": 70}, {"id": "viper", "count": 70}, {"id": "mantis", "count": 60}], "enemy_minimum": 200, "interval": 0.05},
			{"time": 5,  "enemies": [{"id": "bat_s", "count": 20}, {"id": "viper", "count": 20}, {"id": "mantis", "count": 20}], "enemy_minimum": 60, "interval": 0.25, "boss": "bat_g", "chest": true},
			{"time": 6,  "enemies": [{"id": "viper", "count": 25}, {"id": "mantis", "count": 25}, {"id": "wraith", "count": 20}], "enemy_minimum": 70, "interval": 0.2, "boss": "bat_g", "chest": true},
			{"time": 7,  "enemies": [{"id": "bat_r", "count": 25}, {"id": "wraith", "count": 25}, {"id": "mantis", "count": 20}], "enemy_minimum": 70, "interval": 0.1, "boss": "mantis", "chest": true},
			{"time": 8,  "enemies": [{"id": "bat_r", "count": 30}, {"id": "mantis", "count": 30}, {"id": "bat_s", "count": 30}], "enemy_minimum": 90, "interval": 0.05, "boss": "bat_g", "chest": true},
			{"time": 9,  "enemies": [{"id": "wraith", "count": 100}], "enemy_minimum": 100, "interval": 0.05},
			{"time": 10, "enemies": [{"id": "viper", "count": 20}, {"id": "bat_s", "count": 15}, {"id": "bat_g", "count": 15}], "enemy_minimum": 50, "interval": 1.0, "boss": "bat_g", "chest": true},
			{"time": 11, "enemies": [{"id": "bat_g", "count": 30}, {"id": "wraith", "count": 30}, {"id": "bat_s", "count": 20}], "enemy_minimum": 80, "interval": 0.5},
			{"time": 12, "enemies": [{"id": "mantis", "count": 50}, {"id": "bat_r", "count": 50}], "enemy_minimum": 100, "interval": 1.0, "boss": "bat_g", "chest": true},
			{"time": 13, "enemies": [{"id": "bat_g", "count": 45}, {"id": "wraith", "count": 45}], "enemy_minimum": 90, "interval": 0.8, "boss": "bat_g", "chest": true},
			{"time": 14, "enemies": [{"id": "bat_g", "count": 65}, {"id": "mantis", "count": 65}], "enemy_minimum": 130, "interval": 0.5, "boss": "mantis", "chest": true},
			{"time": 15, "enemies": [{"id": "wraith", "count": 75}, {"id": "mantis", "count": 75}], "enemy_minimum": 150, "interval": 0.8, "boss": "bat_g", "chest": true},
			{"time": 16, "enemies": [{"id": "bat_g", "count": 60}, {"id": "mantis", "count": 60}, {"id": "wraith", "count": 40}], "enemy_minimum": 160, "interval": 1.0, "boss": "bat_g", "chest": true},
			{"time": 17, "enemies": [{"id": "bat_g", "count": 30}, {"id": "mantis", "count": 30}, {"id": "bat_g", "count": 30}], "enemy_minimum": 90, "interval": 1.0, "boss": "bat_g", "chest": true},
			{"time": 18, "enemies": [{"id": "bat_g", "count": 35}, {"id": "mantis", "count": 35}, {"id": "bat_s", "count": 30}], "enemy_minimum": 100, "interval": 0.6, "boss": "bat_g", "chest": true},
			{"time": 19, "enemies": [{"id": "bat_g", "count": 50}, {"id": "bat_g", "count": 50}, {"id": "bat_g", "count": 50}], "enemy_minimum": 150, "interval": 1.0},
			{"time": 20, "enemies": [], "enemy_minimum": 1, "interval": 10.0, "boss": "reaper"},
		],
		"map_events": [
			{"time": 2,  "type": "coop_egg_swarm"},
			{"time": 3,  "type": "coop_egg_swarm"},
			{"time": 4,  "type": "coop_chicken_swarm", "repeats": 4},
			{"time": 5,  "type": "coop_chicken_swarm", "repeats": 3},
			{"time": 6,  "type": "coop_chik_swarm", "repeats": 3},
			{"time": 8,  "type": "coop_chicken_swarm", "repeats": 3},
			{"time": 9,  "type": "coop_egg_swarm", "repeats": 3},
			{"time": 10, "type": "coop_chicken_swarm", "repeats": 2},
			{"time": 12, "type": "coop_chicken_swarm", "repeats": 3},
			{"time": 14, "type": "coop_chicken_swarm", "repeats": 3},
			{"time": 15, "type": "coop_roast_chicken_swarm", "repeats": 3},
			{"time": 17, "type": "coop_roast_chicken_swarm", "repeats": 3},
			{"time": 18, "type": "coop_roast_chicken_swarm", "repeats": 3},
			{"time": 19, "type": "coop_chicken_swarm", "repeats": 3},
		],
		"decor_config": {
			"background_pattern": "solid",
			"decor_elements": [
				{"type": "dot", "count": 40, "size_min": 2, "size_max": 5,
				 "color": Color(0.08, 0.14, 0.04), "alpha_min": 0.15, "alpha_max": 0.35, "z": -49},
				{"type": "dot", "count": 10, "size_min": 1, "size_max": 3,
				 "color": Color(0.5, 0.7, 0.2), "alpha_min": 0.3, "alpha_max": 0.5, "z": -45},
			],
			"props": {
				"colors": [
					Color(0.12, 0.20, 0.06),
					Color(0.18, 0.25, 0.08),
					Color(0.20, 0.10, 0.04),
				],
			},
		},
	}
