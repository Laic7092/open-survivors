extends RefCounted
# Stage 10 — Whiteout (bonus)

static func get_data() -> Dictionary:
	return {
		"id": 10,
		"name": "Whiteout",
		"desc": "Arctic glacier.\n20 min limit. Fire weapons deal extra damage.",
		"time_limit": 1200.0,
		"bg_color": Color(0.1, 0.12, 0.18),
		"map_width": 5400,
		"map_height": 4400,
		"move_speed_mod": 1.35,
		"enemy_speed_mod": 1.3,
		"gold_mod": 1.0,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 0.7,
		"spawn_min_interval": 0.1,
		"spawn_ramp_time": 22.0,
		"wave_size_interval": 22.0,
		"difficulty_ramp_time": 40.0,
		"unlock_req": "clear_stage_3",
		"hyper_unlock": "boss_stage_10",
		"hyper_mods": {
			"move_speed_bonus": 1.0, "gold_mult": 1.25,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.0,
		},
		"stage_items": [
			{"type": 25, "is_weapon": false, "pos": Vector2(-1600, -1000)},
			{"type": 3, "is_weapon": false, "pos": Vector2(1400, 1000)},
			{"type": 4, "is_weapon": false, "pos": Vector2(0, -1500)},
		],
		"interactables": {
			"chests": [
				{"pos": Vector2(-2000, 1500)},
				{"pos": Vector2(2000, -1500)},
			],
			"fountains": [
				{"pos": Vector2(500, 500), "heal_pct": 0.45},
			],
			"breakable_density": 0.0002,
			"breakable_hp": 30.0,
			"hazards": [
				{"pos": Vector2(-1500, -500), "size": Vector2(160, 100), "dps": 10.0},
				{"pos": Vector2(1500, 800), "size": Vector2(140, 100), "dps": 12.0},
			],
			"boosts": [
				{"pos": Vector2(-500, -2000), "type": "speed", "amount": 0.4, "size": Vector2(100, 100)},
			],
		},
	}
