extends RefCounted
# Stage 7 — Green Acres (challenge)
# Vampire Survivors reference: https://vampire-survivors.fandom.com/wiki/Green_Acres
# Wiki: https://vampire.survivors.wiki/w/Green_Acres
# Note: Waves are randomly selected from unlocked base stages — no fixed wave_defs.

static func get_data() -> Dictionary:
	return {
		"id": 7,
		"name": "Green Acres",
		"wiki_id": "GREENACRES",
		"type": "Challenge",
		"desc": "Fate changes by the minute in a realm where mortals can only trespass.\nRandom enemy waves from normal stages. +50% Enemy HP.",
		"time_limit": 1800.0,
		"bg_color": Color(0.06, 0.18, 0.06),
		"map_width": 6000,
		"map_height": 4500,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.25,
		"gold_mod": 1.0,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.5,
		"starting_spawns": 30,
		"spawn_base_interval": 0.5,
		"spawn_min_interval": 0.1,
		"spawn_ramp_time": 20.0,
		"wave_size_interval": 20.0,
		"difficulty_ramp_time": 40.0,
		"unlock_req": "unlock_2_hyper_modes",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.65,
			"gold_mult": 1.5,
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.5,
			"starting_spawns": 60,
		},
		"stage_items": [],
		"interactables": {
			"chests": [
				{"pos": Vector2(-2500, -1000)},
				{"pos": Vector2(2000, 1500)},
				{"pos": Vector2(-1000, 2000)},
			],
			"fountains": [
				{"pos": Vector2(0, 0), "heal_pct": 0.50},
			],
			"breakable_density": 0.00015,
			"breakable_hp": 25.0,
			"hazards": [
				{"pos": Vector2(-1000, -2000), "size": Vector2(200, 100), "dps": 15.0},
			],
			"boosts": [
				{"pos": Vector2(1000, 500), "type": "magnet", "amount": 1.0, "size": Vector2(100, 100)},
			],
		},
		# No wave_defs — waves are randomly selected from unlocked base stages
		"map_events": [],
		"decor_config": {
			"background_pattern": "solid",
			"decor_elements": [
				{"type": "dot", "count": 50, "size_min": 2, "size_max": 5,
				 "color": Color(0.06, 0.18, 0.06), "alpha_min": 0.15, "alpha_max": 0.35, "z": -49},
				{"type": "dot", "count": 15, "size_min": 1, "size_max": 3,
				 "color": Color(0.4, 0.9, 0.3), "alpha_min": 0.3, "alpha_max": 0.6, "z": -45},
			],
			"props": {
				"colors": [
					Color(0.10, 0.30, 0.08),
					Color(0.15, 0.35, 0.12),
					Color(0.20, 0.10, 0.05),
				],
			},
		},
	}
