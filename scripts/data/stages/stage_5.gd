extends RefCounted
# Stage 5 — Cappella Magna

static func get_data() -> Dictionary:
	return {
		"id": 5,
		"name": "Cappella Magna",
		"desc": "Nexus of debased purity.\n+40% Move Speed. +40% Gold. Grand chapel.",
		"time_limit": 1800.0,
		"bg_color": Color(0.18, 0.04, 0.06),
		"map_width": 6600,
		"map_height": 5000,
		"move_speed_mod": 1.4,
		"enemy_speed_mod": 1.5,
		"gold_mod": 1.4,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 0.5,
		"spawn_min_interval": 0.1,
		"spawn_ramp_time": 18.0,
		"wave_size_interval": 18.0,
		"difficulty_ramp_time": 35.0,
		"unlock_req": "clear_stage_4",
		"hyper_unlock": "boss_stage_5",
		"hyper_mods": {
			"move_speed_bonus": 1.0,
			"gold_mult": 1.9,
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.0,
		},
		"stage_items": [
			{"type": 8,  "is_weapon": false, "pos": Vector2(-2400, -1200)},
			{"type": 26, "is_weapon": false, "pos": Vector2(2800, 1000)},
			{"type": 13, "is_weapon": false, "pos": Vector2(0, 2000)},
		],
		"interactables": {
			"chests": [
				{"pos": Vector2(-2000, 1500)},
				{"pos": Vector2(2500, -1000)},
				{"pos": Vector2(0, -2000)},
			],
			"fountains": [
				{"pos": Vector2(-1500, 0), "heal_pct": 0.50},
				{"pos": Vector2(2000, 500), "heal_pct": 0.50},
			],
			"breakable_density": 0.0002,
			"breakable_hp": 35.0,
			"hazards": [
				{"pos": Vector2(0, 0), "size": Vector2(180, 120), "dps": 20.0},
			],
		},
	}
