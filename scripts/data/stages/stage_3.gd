extends RefCounted
# Stage 3 — Dairy Plant

static func get_data() -> Dictionary:
	return {
		"id": 3,
		"name": "Dairy Plant",
		"desc": "Abandoned factory overrun by experiments.\n+25% Move Speed. +20% Gold.",
		"time_limit": 1800.0,
		"bg_color": Color(0.08, 0.06, 0.16),
		"map_width": 5400,
		"map_height": 4400,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.2,
		"gold_mod": 1.2,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 0.8,
		"spawn_min_interval": 0.12,
		"spawn_ramp_time": 22.0,
		"wave_size_interval": 22.0,
		"difficulty_ramp_time": 45.0,
		"unlock_req": "clear_stage_2",
		"hyper_unlock": "boss_stage_3",
		"hyper_mods": {
			"move_speed_bonus": 0.9,
			"gold_mult": 1.7,
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.0,
		},
		"stage_items": [
			{"type": 15, "is_weapon": false, "pos": Vector2(-1200, 1200)},
			{"type": 7,  "is_weapon": false, "pos": Vector2(1800, -800)},
			{"type": 3,  "is_weapon": false, "pos": Vector2(-600, -1400)},
			{"type": 23, "is_weapon": false, "pos": Vector2(800, 1000)},
		],
		"interactables": {
			"chests": [
				{"pos": Vector2(-2000, 1500)},
				{"pos": Vector2(2000, -1200)},
			],
			"fountains": [
				{"pos": Vector2(0, 0), "heal_pct": 0.40},
			],
			"breakable_density": 0.0003,
			"breakable_hp": 30.0,
			"hazards": [
				{"pos": Vector2(1500, 800), "size": Vector2(150, 80), "dps": 18.0},
				{"pos": Vector2(-1800, -500), "size": Vector2(120, 120), "dps": 15.0},
			],
			"boosts": [
				{"pos": Vector2(-500, 1500), "type": "might", "amount": 0.25, "size": Vector2(80, 80)},
			],
		},
	}
