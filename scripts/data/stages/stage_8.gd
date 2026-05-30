extends RefCounted
# Stage 8 — The Bone Zone (challenge)

static func get_data() -> Dictionary:
	return {
		"id": 8,
		"name": "The Bone Zone",
		"desc": "Where the dead go to live.\nNo item drops. Enemies grow stronger.",
		"time_limit": 1800.0,
		"bg_color": Color(0.06, 0.04, 0.08),
		"map_width": 5400,
		"map_height": 4400,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.4,
		"gold_mod": 1.5,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 0.45,
		"spawn_min_interval": 0.08,
		"spawn_ramp_time": 15.0,
		"wave_size_interval": 15.0,
		"difficulty_ramp_time": 30.0,
		"unlock_req": "reach_level_50",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.9, "gold_mult": 2.0,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.0,
		},
		"stage_items": [],
		"interactables": {
			"chests": [
				{"pos": Vector2(-2000, -1500)},
				{"pos": Vector2(2000, 1500)},
			],
			"fountains": [
				{"pos": Vector2(500, -500), "heal_pct": 0.40},
			],
			"breakable_density": 0.00035,
			"breakable_hp": 25.0,
			"hazards": [
				{"pos": Vector2(-1500, 500), "size": Vector2(150, 100), "dps": 18.0},
				{"pos": Vector2(1500, -1000), "size": Vector2(120, 120), "dps": 15.0},
				{"pos": Vector2(-500, 2000), "size": Vector2(100, 200), "dps": 20.0},
			],
		},
	}
