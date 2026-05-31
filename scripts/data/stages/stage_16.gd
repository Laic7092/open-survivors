extends RefCounted
# Stage 16 — Holy Forbidden (Hidden Ground)
# Wiki: https://vampire.survivors.wiki/w/Holy_Forbidden
# Note: This stage uses event-based enemy spawning, not wave_defs.

static func get_data() -> Dictionary:
	return {
		"id": 16,
		"name": "Holy Forbidden",
		"wiki_id": "STAGEX",
		"type": "Hidden Ground",
		"desc": "Wait, you can see this too? This isn't right...",
		"time_limit": 300.0,
		"bg_color": Color(0.08, 0.02, 0.16),
		"map_width": 4800,
		"map_height": 3600,
		"map_scale": 1.0,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.25,
		"projectile_speed_mod": 1.0,
		"gold_mod": 1.0,
		"luck_mod": 1.0,
		"xp_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"starting_spawns": 50,
		"enemy_minimum": 1,
		"spawn_base_interval": 0.5,
		"spawn_min_interval": 0.12,
		"spawn_ramp_time": 25.0,
		"wave_size_interval": 25.0,
		"difficulty_ramp_time": 50.0,
		"unlock_req": "relic_yellow_sign",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.0,
			"gold_mult": 1.0,
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.0,
		},
		"inverse_mods": {
			"player_speed": 1.5,
			"enemy_speed": 1.1,
			"enemy_hp": 2.0,
			"gold_mult": 2.0,
		},
		"stage_items": [],
		"interactables": {
			"breakable_density": 0.0001,
			"breakable_hp": 20.0,
		},
		# No wave_defs — Holy Forbidden uses a special event-driven enemy sequence
		# (bats spawning vertically, The Maddener appearance at 0:15, angel transformation)
		"map_events": [
			{"time": 0,  "type": "holy_forbidden_bats", "count": 50, "interval": 3.0},
			{"time": 15, "type": "holy_forbidden_maddener"},
		],
		"decor_config": {
			"background_pattern": "solid",
			"decor_elements": [
				{"type": "dot", "count": 50, "size_min": 2, "size_max": 6,
				 "color": Color(0.10, 0.02, 0.20), "alpha_min": 0.15, "alpha_max": 0.35, "z": -49},
				{"type": "dot", "count": 20, "size_min": 1, "size_max": 4,
				 "color": Color(0.6, 0.1, 0.8), "alpha_min": 0.3, "alpha_max": 0.6, "z": -45},
			],
			"props": {
				"colors": [
					Color(0.15, 0.04, 0.25),
					Color(0.20, 0.06, 0.30),
					Color(0.10, 0.02, 0.18),
				],
			},
		},
	}
