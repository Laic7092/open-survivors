extends RefCounted
# Stage 13 — Space 54 (bonus)
# Wiki: https://vampire.survivors.wiki/w/Space_54
# Wave data sourced from wiki wave table.
# Note: Unique space-themed enemies mapped to closest project equivalents.

static func get_data() -> Dictionary:
	return {
		"id": 13,
		"name": "Space 54",
		"wiki_id": "SPAZIE",
		"type": "Bonus",
		"desc": "The 54th ritual is complete, and space itself has folded under the weight of an otherworldly will.\n+30% Gold. Dimensional chaos.",
		"time_limit": 1200.0,
		"bg_color": Color(0.02, 0.02, 0.14),
		"map_width": 4000,
		"map_height": 3000,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.0,
		"gold_mod": 1.3,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 0.5,
		"spawn_min_interval": 0.08,
		"spawn_ramp_time": 18.0,
		"wave_size_interval": 18.0,
		"difficulty_ramp_time": 30.0,
		"unlock_req": "collect_5_gold_fingers",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.65,
			"gold_mult": 1.8,
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.0,
		},
		"stage_items": [
			{"type": 15, "is_weapon": false, "pos": Vector2(-1200, 800)},
			{"type": 3, "is_weapon": false, "pos": Vector2(1000, -600)},
			{"type": 22, "is_weapon": false, "pos": Vector2(-800, -1200)},
		],
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
		"wave_defs": [
			# Musc Musc → musc_musc, Moon Duck → bat_s, Space Pickle → golem
			# Moon Rabbit → bat_r, Space Ant Onion → mudman, ECMASlime → ghost
			# Sinistronz → werewolf, Gala Invader → wraith, EX Phalien XL Boss → bat_g
			{"time": 0,  "enemies": [{"id": "musc_musc", "count": 50}], "enemy_minimum": 50, "interval": 3.0},
			{"time": 1,  "enemies": [{"id": "bat_s", "count": 40}], "enemy_minimum": 40, "interval": 3.0},
			{"time": 2,  "enemies": [{"id": "musc_musc", "count": 20}, {"id": "golem", "count": 30}], "enemy_minimum": 50, "interval": 4.0, "boss": "bat_g", "chest": true},
			{"time": 3,  "enemies": [{"id": "musc_musc", "count": 30}, {"id": "golem", "count": 30}], "enemy_minimum": 60, "interval": 4.0},
			{"time": 4,  "enemies": [{"id": "bat_s", "count": 55}, {"id": "bat_r", "count": 55}], "enemy_minimum": 110, "interval": 4.0},
			{"time": 5,  "enemies": [{"id": "musc_musc", "count": 50}, {"id": "golem", "count": 50}], "enemy_minimum": 100, "interval": 4.0, "boss": "bat_g", "chest": true},
			{"time": 6,  "enemies": [{"id": "musc_musc", "count": 10}, {"id": "mudman", "count": 20}], "enemy_minimum": 30, "interval": 2.0, "boss": "bat_g", "chest": true},
			{"time": 7,  "enemies": [{"id": "musc_musc", "count": 40}, {"id": "mudman", "count": 40}], "enemy_minimum": 80, "interval": 2.0},
			{"time": 8,  "enemies": [{"id": "mudman", "count": 80}], "enemy_minimum": 80, "interval": 1.0, "boss": "bat_g", "chest": true},
			{"time": 9,  "enemies": [{"id": "mudman", "count": 140}, {"id": "musc_musc", "count": 60}], "enemy_minimum": 200, "interval": 0.5},
			{"time": 10, "enemies": [{"id": "ghost", "count": 200}], "enemy_minimum": 200, "interval": 0.5},
			{"time": 11, "enemies": [{"id": "ghost", "count": 50}], "enemy_minimum": 50, "interval": 3.0, "boss": "bat_g", "chest": true},
			{"time": 12, "enemies": [{"id": "ghost", "count": 40}], "enemy_minimum": 40, "interval": 2.0, "boss": "bat_g", "chest": true},
			{"time": 13, "enemies": [{"id": "mudman", "count": 40}, {"id": "golem", "count": 40}, {"id": "musc_musc", "count": 40}], "enemy_minimum": 120, "interval": 1.0},
			{"time": 14, "enemies": [{"id": "mudman", "count": 40}, {"id": "golem", "count": 40}], "enemy_minimum": 110, "interval": 0.1, "boss": "bat_g", "chest": true},
			{"time": 15, "enemies": [{"id": "wraith", "count": 300}], "enemy_minimum": 300, "interval": 4.0},
			{"time": 16, "enemies": [{"id": "ghost", "count": 100}], "enemy_minimum": 100, "interval": 0.5},
			{"time": 17, "enemies": [{"id": "ghost", "count": 100}], "enemy_minimum": 100, "interval": 0.5, "boss": "bat_g", "chest": true},
			{"time": 18, "enemies": [{"id": "werewolf", "count": 100}], "enemy_minimum": 100, "interval": 0.5},
			{"time": 19, "enemies": [{"id": "werewolf", "count": 100}], "enemy_minimum": 100, "interval": 0.5},
			{"time": 20, "enemies": [{"id": "werewolf", "count": 300}], "enemy_minimum": 300, "interval": 0.1, "boss": "reaper"},
		],
		"map_events": [
			{"time": 0,  "type": "invaders"},
			{"time": 1,  "type": "ex_duck_swarm", "repeats": 3},
			{"time": 2,  "type": "ex_batspace_swarm", "chance": 0.8, "repeats": 3},
			{"time": 3,  "type": "ex_batspace_swarm", "chance": 0.8, "repeats": 3},
			{"time": 4,  "type": "ex_rabbit_swarm"},
			{"time": 5,  "type": "medusa_swarm", "chance": 0.8, "repeats": 1},
			{"time": 6,  "type": "medusa_swarm", "chance": 0.8, "repeats": 2},
			{"time": 7,  "type": "medusa_swarm", "chance": 0.8, "repeats": 3},
			{"time": 8,  "type": "monster_dance"},
			{"time": 9,  "type": "monster_dance"},
			{"time": 10, "type": "invaders"},
			{"time": 11, "type": "diamond_maze"},
			{"time": 15, "type": "invaders"},
		],
		"decor_config": {
			"background_pattern": "solid",
			"decor_elements": [
				{"type": "dot", "count": 50, "size_min": 2, "size_max": 6,
				 "color": Color(0.02, 0.02, 0.16), "alpha_min": 0.15, "alpha_max": 0.35, "z": -49},
				{"type": "dot", "count": 20, "size_min": 1, "size_max": 3,
				 "color": Color(0.4, 0.3, 0.9), "alpha_min": 0.3, "alpha_max": 0.6, "z": -45},
			],
			"props": {
				"colors": [
					Color(0.04, 0.04, 0.20),
					Color(0.06, 0.06, 0.25),
					Color(0.15, 0.05, 0.10),
				],
			},
		},
	}
