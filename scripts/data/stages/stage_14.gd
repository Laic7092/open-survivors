extends RefCounted
# Stage 14 — Bat Country (challenge)

static func get_data() -> Dictionary:
	return {
		"id": 14,
		"name": "Bat Country",
		"desc": "We can't stop here.\n-75% XP. Enemies hyper-scale over time.",
		"time_limit": 1200.0,
		"bg_color": Color(0.04, 0.02, 0.06),
		"map_width": 3200,
		"map_height": 2400,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.5,
		"gold_mod": 1.3,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 0.35,
		"spawn_min_interval": 0.07,
		"spawn_ramp_time": 12.0,
		"wave_size_interval": 12.0,
		"difficulty_ramp_time": 25.0,
		"unlock_req": "reach_level_65",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.9, "gold_mult": 1.8,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.0,
		},
		"stage_items": [],
	}
