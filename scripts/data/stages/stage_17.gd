extends RefCounted
# Stage 17 — Astral Stair

static func get_data() -> Dictionary:
	return {
		"id": 17,
		"name": "Astral Stair",
		"wiki_id": "ASTRALSTAIR",
		"type": "Challenge",
		"desc": "An endless staircase through the cosmos.\n+25% Move Speed. Enemies empowered.",
		"time_limit": 1200.0,
		"bg_color": Color(0.02, 0.06, 0.18),
		"map_width": 6400,
		"map_height": 4800,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.3,
		"gold_mod": 1.5,
		"luck_mod": 0.1,
		"enemy_hp_mod": 1.3,
		"spawn_base_interval": 0.45,
		"spawn_min_interval": 0.1,
		"spawn_ramp_time": 22.0,
		"wave_size_interval": 22.0,
		"difficulty_ramp_time": 45.0,
		"unlock_req": "reach_level_65",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.8, "gold_mult": 1.5,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.5,
		},
		"stage_items": [],
	}
