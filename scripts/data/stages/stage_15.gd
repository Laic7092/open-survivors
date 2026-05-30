extends RefCounted
# Stage 15 — Eudaimonia Machine (special)

static func get_data() -> Dictionary:
	return {
		"id": 15,
		"name": "Eudaimonia Machine",
		"desc": "A space between spaces.\n99 min limit. The culmination.",
		"time_limit": 5940.0,
		"bg_color": Color(0.14, 0.08, 0.02),
		"map_width": 3000,
		"map_height": 3000,
		"move_speed_mod": 1.0,
		"enemy_speed_mod": 1.0,
		"gold_mod": 2.0,
		"luck_mod": 0.2,
		"enemy_hp_mod": 2.0,
		"spawn_base_interval": 0.45,
		"spawn_min_interval": 0.07,
		"spawn_ramp_time": 30.0,
		"wave_size_interval": 30.0,
		"difficulty_ramp_time": 60.0,
		"unlock_req": "relic_yellow_sign",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.0, "gold_mult": 1.0,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.0,
		},
		"stage_items": [
			{"type": 14, "is_weapon": false, "pos": Vector2(-800, 0)},
			{"type": 13, "is_weapon": false, "pos": Vector2(800, 0)},
			{"type": 8, "is_weapon": false, "pos": Vector2(0, -800)},
		],
		"interactables": {
			"chests": [
				{"pos": Vector2(-1000, -800)},
				{"pos": Vector2(1000, 800)},
				{"pos": Vector2(0, 1000)},
			],
			"fountains": [
				{"pos": Vector2(-500, 500), "heal_pct": 0.50},
				{"pos": Vector2(500, -500), "heal_pct": 0.50},
			],
			"breakable_density": 0.0,
			"boosts": [
				{"pos": Vector2(0, 0), "type": "might", "amount": 0.5, "size": Vector2(100, 100)},
				{"pos": Vector2(-500, -500), "type": "speed", "amount": 0.5, "size": Vector2(100, 100)},
				{"pos": Vector2(500, 500), "type": "magnet", "amount": 1.0, "size": Vector2(100, 100)},
			],
		},
	}
