extends RefCounted
# Stage 18 — Mazerella

static func get_data() -> Dictionary:
	return {
		"id": 18,
		"name": "Mazerella",
		"desc": "A labyrinth of cheese and moonlight.\nDancers carry hidden treasures.",
		"time_limit": 1800.0,
		"bg_color": Color(0.16, 0.08, 0.02),
		"map_width": 4800,
		"map_height": 4800,
		"move_speed_mod": 1.2,
		"enemy_speed_mod": 1.4,
		"gold_mod": 1.6,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.4,
		"spawn_base_interval": 0.4,
		"spawn_min_interval": 0.09,
		"spawn_ramp_time": 20.0,
		"wave_size_interval": 20.0,
		"difficulty_ramp_time": 40.0,
		"unlock_req": "reach_level_70",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.7, "gold_mult": 1.6,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.6,
		},
		"stage_items": [],
	}
