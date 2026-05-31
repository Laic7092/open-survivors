extends RefCounted
# Stage 13 — Space 54 (bonus)
# Wiki: https://vampire.survivors.wiki/w/Space_54
# wiki_id: SPAZIE, Type: Bonus

static func get_data() -> Dictionary:
	return {
		"id": 13,
		"name": "Space 54",
		"desc": "The 54th ritual is complete, and space itself has folded under the weight of an otherworldly will.\n+30% Gold. Dimensional chaos.",
		"time_limit": 1200.0,
		"bg_color": Color(0.02, 0.02, 0.14),
		"map_width": 4000,
		"map_height": 3000,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.4,
		"gold_mod": 1.3,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.2,
		"spawn_base_interval": 0.5,
		"spawn_min_interval": 0.08,
		"spawn_ramp_time": 18.0,
		"wave_size_interval": 18.0,
		"difficulty_ramp_time": 30.0,
		"unlock_req": "reach_level_55",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.9, "gold_mult": 1.8,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.0,
		},
		"stage_items": [],
		"interactables": {
			"chests": [
				{"pos": Vector2(-2500, -1000)},
				{"pos": Vector2(2000, 1500)},
			],
			"fountains": [
				{"pos": Vector2(0, 0), "heal_pct": 0.40},
			],
			"breakable_density": 0.00015,
			"breakable_hp": 25.0,
			"hazards": [
				{"pos": Vector2(-1000, 2000), "size": Vector2(180, 100), "dps": 15.0},
				{"pos": Vector2(2500, -500), "size": Vector2(120, 120), "dps": 18.0},
			],
			"boosts": [
				{"pos": Vector2(-1500, 500), "type": "speed", "amount": 0.6, "size": Vector2(100, 100)},
				{"pos": Vector2(1500, -1000), "type": "might", "amount": 0.5, "size": Vector2(100, 100)},
			],
		},
	}
