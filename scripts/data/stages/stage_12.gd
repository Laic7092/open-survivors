extends RefCounted
# Stage 12 — The Coop (bonus)

static func get_data() -> Dictionary:
	return {
		"id": 12,
		"name": "The Coop",
		"desc": "Farm where beasts learned cooperation.\n-65% XP. Stage grows over time.",
		"time_limit": 1200.0,
		"bg_color": Color(0.08, 0.12, 0.04),
		"map_width": 4000,
		"map_height": 4000,
		"move_speed_mod": 1.35,
		"enemy_speed_mod": 1.2,
		"gold_mod": 1.0,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 0.5,
		"spawn_min_interval": 0.1,
		"spawn_ramp_time": 18.0,
		"wave_size_interval": 18.0,
		"difficulty_ramp_time": 35.0,
		"unlock_req": "reach_level_30",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 1.0, "gold_mult": 1.25,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 1.0,
		},
		"stage_items": [
			{"type": 12, "is_weapon": false, "pos": Vector2(0, 0)},
		],
	}
