extends RefCounted
# Stage 18 — Mazerella (challenge)
# Wiki: https://vampire.survivors.wiki/w/Mazerella
# Wave data sourced from wiki wave table.

static func get_data() -> Dictionary:
	return {
		"id": 18,
		"name": "Mazerella",
		"desc": "A lactose labyrinth lies buried in the buttery basement of the Dairy Plant.\nEnemies grow stronger over time. Charging enemies.",
		"wiki_id": "EX_MAZERELLA",
		"type": "Challenge",
		"time_limit": 1200.0,
		"bg_color": Color(0.16, 0.08, 0.02),
		"map_width": 4800,
		"map_height": 4800,
		"map_scale": 2.5,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.0,
		"gold_mod": 1.3,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 0.4,
		"spawn_min_interval": 0.09,
		"spawn_ramp_time": 20.0,
		"wave_size_interval": 20.0,
		"difficulty_ramp_time": 40.0,
		"unlock_req": "reach_level_80_inverse_dairy_plant",
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
				{"pos": Vector2(-1800, -1500)},
				{"pos": Vector2(1800, 1500)},
			],
			"fountains": [
				{"pos": Vector2(0, 0), "heal_pct": 0.45},
			],
			"breakable_density": 0.0002,
			"breakable_hp": 25.0,
			"hazards": [
				{"pos": Vector2(-1000, 1000), "size": Vector2(150, 80), "dps": 15.0},
				{"pos": Vector2(1500, -500), "size": Vector2(120, 120), "dps": 12.0},
			],
			"boosts": [
				{"pos": Vector2(500, -1000), "type": "speed", "amount": 0.4, "size": Vector2(80, 80)},
			],
		},
		"wave_defs": [
			# Torino → wraith, Milk Elemental → milk_elemental, EX HARPY2 → harzia
			# Joyatauro → minotaur, Sneaky Head → merdusa, AccumulaTori → big_golem
			# Minotaur Boss → minotaur, Lionhead → lionhead, Archon Disco → archon_disco
			# Manticore → manticore
			{"time": 0,  "enemies": [{"id": "wraith", "count": 25}], "enemy_minimum": 25, "interval": 0.3},
			{"time": 1,  "enemies": [{"id": "wraith", "count": 30}], "enemy_minimum": 30, "interval": 0.5, "boss": "minotaur", "chest": true},
			{"time": 2,  "enemies": [{"id": "milk_elemental", "count": 40}], "enemy_minimum": 40, "interval": 0.4, "boss": "minotaur", "chest": true},
			{"time": 3,  "enemies": [{"id": "harzia", "count": 45}], "enemy_minimum": 45, "interval": 0.5, "boss": "minotaur", "chest": true},
			{"time": 4,  "enemies": [{"id": "wraith", "count": 55}], "enemy_minimum": 55, "interval": 0.6},
			{"time": 5,  "enemies": [{"id": "milk_elemental", "count": 50}], "enemy_minimum": 50, "interval": 0.3, "boss": "minotaur", "chest": true, "arcana": true},
			{"time": 6,  "enemies": [{"id": "minotaur", "count": 25}, {"id": "harzia", "count": 20}], "enemy_minimum": 45, "interval": 0.5, "boss": "minotaur", "chest": true},
			{"time": 7,  "enemies": [{"id": "minotaur", "count": 20}, {"id": "merdusa", "count": 20}], "enemy_minimum": 40, "interval": 0.4, "boss": "minotaur", "chest": true},
			{"time": 8,  "enemies": [{"id": "milk_elemental", "count": 80}], "enemy_minimum": 80, "interval": 0.8},
			{"time": 9,  "enemies": [{"id": "merdusa", "count": 20}, {"id": "harzia", "count": 20}], "enemy_minimum": 40, "interval": 0.4, "boss": "minotaur", "chest": true},
			{"time": 10, "enemies": [{"id": "minotaur", "count": 40}], "enemy_minimum": 40, "interval": 0.4, "boss": "lionhead", "chest": true, "arcana": true},
			{"time": 11, "enemies": [{"id": "harzia", "count": 30}, {"id": "milk_elemental", "count": 30}], "enemy_minimum": 60, "interval": 0.4},
			{"time": 12, "enemies": [{"id": "minotaur", "count": 15}, {"id": "merdusa", "count": 15}], "enemy_minimum": 30, "interval": 0.3, "boss": "archon_disco", "chest": true},
			{"time": 13, "enemies": [{"id": "harzia", "count": 30}, {"id": "milk_elemental", "count": 30}], "enemy_minimum": 60, "interval": 0.3, "boss": "minotaur", "chest": true},
			{"time": 14, "enemies": [{"id": "harzia", "count": 20}, {"id": "minotaur", "count": 20}], "enemy_minimum": 40, "interval": 0.3},
			{"time": 15, "enemies": [{"id": "big_golem", "count": 30}], "enemy_minimum": 30, "interval": 0.6, "boss": "manticore", "chest": true},
			{"time": 16, "enemies": [{"id": "big_golem", "count": 20}, {"id": "harzia", "count": 20}, {"id": "merdusa", "count": 10}], "enemy_minimum": 50, "interval": 0.3, "boss": "archon_disco", "chest": true},
			{"time": 17, "enemies": [{"id": "minotaur", "count": 50}, {"id": "milk_elemental", "count": 50}], "enemy_minimum": 100, "interval": 0.3},
			{"time": 18, "enemies": [{"id": "minotaur", "count": 25}, {"id": "big_golem", "count": 25}], "enemy_minimum": 50, "interval": 0.3, "boss": "manticore", "chest": true},
			{"time": 19, "enemies": [{"id": "manticore", "count": 25}, {"id": "archon_disco", "count": 25}], "enemy_minimum": 50, "interval": 1.0},
			{"time": 20, "enemies": [], "enemy_minimum": 1, "interval": 10.0, "boss": "reaper"},
		],
		"map_events": [
			{"time": 1,  "type": "milk_event", "repeats": 3},
			{"time": 2,  "type": "medusa_wall"},
			{"time": 4,  "type": "milk_event", "repeats": 5},
			{"time": 5,  "type": "medusa_wall"},
			{"time": 8,  "type": "migno_swarm", "repeats": 4},
			{"time": 10, "type": "migno_swarm", "repeats": 4},
			{"time": 12, "type": "migno_swarm", "repeats": 6},
			{"time": 14, "type": "medusa_wall"},
			{"time": 17, "type": "milk_event", "repeats": 3},
		],
		"decor_config": {
			"background_pattern": "solid",
			"decor_elements": [
				{"type": "dot", "count": 45, "size_min": 2, "size_max": 5,
				 "color": Color(0.18, 0.10, 0.02), "alpha_min": 0.15, "alpha_max": 0.35, "z": -49},
				{"type": "dot", "count": 12, "size_min": 1, "size_max": 3,
				 "color": Color(0.8, 0.6, 0.1), "alpha_min": 0.3, "alpha_max": 0.5, "z": -45},
			],
			"props": {
				"colors": [
					Color(0.22, 0.12, 0.04),
					Color(0.25, 0.15, 0.05),
					Color(0.30, 0.08, 0.02),
				],
			},
		},
	}
