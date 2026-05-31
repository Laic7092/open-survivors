extends RefCounted
# Stage 20 — Westwoods

static func get_data() -> Dictionary:
	return {
		"id": 20,
		"name": "Westwoods",
		"desc": "Ancient forest where secrets roam.\n+20% Luck. Random events.",
		"time_limit": 1800.0,
		"bg_color": Color(0.1, 0.16, 0.04),
		"map_width": 4800,
		"map_height": 3600,
		"move_speed_mod": 1.3,
		"enemy_speed_mod": 1.35,
		"gold_mod": 1.5,
		"luck_mod": 0.2,
		"enemy_hp_mod": 1.6,
		"spawn_base_interval": 0.3,
		"spawn_min_interval": 0.07,
		"spawn_ramp_time": 15.0,
		"wave_size_interval": 15.0,
		"difficulty_ramp_time": 30.0,
		"unlock_req": "reach_level_80",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.8, "gold_mult": 1.8,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.8,
		},
		"stage_items": [],
	}
