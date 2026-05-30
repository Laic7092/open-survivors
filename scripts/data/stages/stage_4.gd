extends RefCounted
# Stage 4 — Gallo Tower

static func get_data() -> Dictionary:
	return {
		"id": 4,
		"name": "Gallo Tower",
		"desc": "An edifice of science and sorcery.\n+25% Move Speed. +30% Gold. Vertical ascent.",
		"time_limit": 1800.0,
		"bg_color": Color(0.12, 0.02, 0.18),
		"map_width": 3200,
		"map_height": 7800,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.3,
		"gold_mod": 1.3,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 0.7,
		"spawn_min_interval": 0.1,
		"spawn_ramp_time": 20.0,
		"wave_size_interval": 20.0,
		"difficulty_ramp_time": 40.0,
		"unlock_req": "clear_stage_3",
		"hyper_unlock": "boss_stage_4",
		"hyper_mods": {
			"move_speed_bonus": 0.9,
			"gold_mult": 1.8,
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.0,
		},
		"stage_items": [
			{"type": 24, "is_weapon": false, "pos": Vector2(0, -2400)},
			{"type": 22, "is_weapon": false, "pos": Vector2(0, 2400)},
		],
		"interactables": {
			"chests": [
				{"pos": Vector2(-800, -3000)},
				{"pos": Vector2(800, 3000)},
			],
			"fountains": [
				{"pos": Vector2(0, 0), "heal_pct": 0.35},
			],
			"breakable_density": 0.00025,
			"breakable_hp": 20.0,
			"hazards": [
				{"pos": Vector2(-1000, -1500), "size": Vector2(100, 100), "dps": 12.0},
				{"pos": Vector2(1000, 1500), "size": Vector2(100, 100), "dps": 12.0},
			],
			"boosts": [
				{"pos": Vector2(0, -1000), "type": "speed", "amount": 0.4, "size": Vector2(80, 80)},
			],
		},
	}
