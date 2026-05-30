extends RefCounted
# Stage 6 — Moongolow (bonus)

static func get_data() -> Dictionary:
	return {
		"id": 6,
		"name": "Moongolow",
		"desc": "City swallowed by the sea.\n15 min limit. All passives available.",
		"time_limit": 900.0,
		"bg_color": Color(0.02, 0.04, 0.15),
		"map_width": 5400,
		"map_height": 4000,
		"move_speed_mod": 1.35,
		"enemy_speed_mod": 1.3,
		"gold_mod": 1.0,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 0.65,
		"spawn_min_interval": 0.1,
		"spawn_ramp_time": 20.0,
		"wave_size_interval": 20.0,
		"difficulty_ramp_time": 35.0,
		"unlock_req": "clear_stage_5",
		"hyper_unlock": "boss_stage_6",
		"hyper_mods": {
			"move_speed_bonus": 1.0, "gold_mult": 1.5,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.0,
		},
		"stage_items": [
			{"type": 4, "is_weapon": false, "pos": Vector2(-1600, -600)},
			{"type": 6, "is_weapon": false, "pos": Vector2(1200, 400)},
			{"type": 9, "is_weapon": false, "pos": Vector2(-800, 1400)},
			{"type": 5, "is_weapon": false, "pos": Vector2(1000, -1000)},
		],
		"interactables": {
			"chests": [
				{"pos": Vector2(-2000, 1000)},
				{"pos": Vector2(2000, -1500)},
			],
			"fountains": [
				{"pos": Vector2(0, 0), "heal_pct": 0.45},
			],
			"breakable_density": 0.0002,
			"breakable_hp": 20.0,
			"hazards": [
				{"pos": Vector2(-1000, 500), "size": Vector2(150, 80), "dps": 10.0},
				{"pos": Vector2(1500, -800), "size": Vector2(120, 120), "dps": 12.0},
			],
		},
	}
