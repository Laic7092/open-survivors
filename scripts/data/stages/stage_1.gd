extends RefCounted
# Stage 1 — Inlaid Library

static func get_data() -> Dictionary:
	return {
		"id": 1,
		"name": "Inlaid Library",
		"desc": "Halls of forbidden knowledge.\n+25% Move Speed. Narrow corridor.",
		"time_limit": 1800.0,
		"bg_color": Color(0.08, 0.02, 0.12),
		"map_width": 2800,
		"map_height": 7200,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.15,
		"gold_mod": 1.0,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 0.9,
		"spawn_min_interval": 0.12,
		"spawn_ramp_time": 25.0,
		"wave_size_interval": 25.0,
		"difficulty_ramp_time": 50.0,
		"unlock_req": "clear_stage_0",
		"hyper_unlock": "boss_stage_1",
		"hyper_mods": {
			"move_speed_bonus": 0.9,
			"gold_mult": 1.5,
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.0,
		},
		"stage_items": [
			{"type": 14, "is_weapon": false, "pos": Vector2(0, -2400)},    # Stone Mask
			{"type": 5,  "is_weapon": false, "pos": Vector2(0, 2400)},    # Empty Tome
		],
		"interactables": {
			"chests": [
				{"pos": Vector2(-800, -3000)},
				{"pos": Vector2(800, 0)},
				{"pos": Vector2(-600, 3200)},
			],
			"fountains": [
				{"pos": Vector2(0, -1500), "heal_pct": 0.40},
			],
			"breakable_density": 0.0003,
			"breakable_hp": 25.0,
			"boosts": [
				{"pos": Vector2(0, 500), "type": "speed", "amount": 0.6, "size": Vector2(100, 60)},
				{"pos": Vector2(0, -500), "type": "speed", "amount": 0.6, "size": Vector2(100, 60)},
			],
		},
	}
