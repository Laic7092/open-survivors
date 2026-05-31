extends RefCounted
# Stage 2 — Il Molise (bonus)

static func get_data() -> Dictionary:
	return {
		"id": 2,
		"name": "Il Molise",
		"wiki_id": "MOLISE",
		"type": "Bonus",
		"desc": "Peaceful meadow hiding a secret.\n15 min limit. Enemies stay still.",
		"time_limit": 900.0,
		"bg_color": Color(0.06, 0.16, 0.04),
		"map_width": 6000,
		"map_height": 6000,
		"move_speed_mod": 1.0,
		"enemy_speed_mod": 0.0,
		"gold_mod": 1.0,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 0.5,
		"spawn_min_interval": 0.08,
		"spawn_ramp_time": 18.0,
		"wave_size_interval": 20.0,
		"difficulty_ramp_time": 40.0,
		"unlock_req": "clear_stage_1",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 1.0,
			"gold_mult": 1.5,
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.6,
		},
		"stage_items": [],
		"interactables": {
			"chests": [
				{"pos": Vector2(-2000, -1500)},
				{"pos": Vector2(2500, -1000)},
				{"pos": Vector2(-1800, 2000)},
				{"pos": Vector2(2000, 2500)},
			],
			"fountains": [
				{"pos": Vector2(-500, 500), "heal_pct": 0.50},
				{"pos": Vector2(800, -300), "heal_pct": 0.50},
			],
			"breakable_density": 0.0,
			"boosts": [
				{"pos": Vector2(-1500, 1500), "type": "speed", "amount": 0.4, "size": Vector2(100, 100)},
				{"pos": Vector2(1500, -1500), "type": "might", "amount": 0.3, "size": Vector2(100, 100)},
			],
		},
	}
