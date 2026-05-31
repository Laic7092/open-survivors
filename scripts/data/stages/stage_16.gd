extends RefCounted
# Stage 16 — Holy Forbidden

static func get_data() -> Dictionary:
	return {
		"id": 16,
		"name": "Holy Forbidden",
		"desc": "Sacred grounds defiled by evil.\nHidden secrets await discovery.",
		"time_limit": 1800.0,
		"bg_color": Color(0.08, 0.02, 0.16),
		"map_width": 4800,
		"map_height": 3600,
		"move_speed_mod": 1.3,
		"enemy_speed_mod": 1.3,
		"gold_mod": 1.5,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.2,
		"spawn_base_interval": 0.5,
		"spawn_min_interval": 0.12,
		"spawn_ramp_time": 25.0,
		"wave_size_interval": 25.0,
		"difficulty_ramp_time": 50.0,
		"unlock_req": "clear_stage_5",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.8, "gold_mult": 1.5,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.5,
		},
		"stage_items": [],
	}
