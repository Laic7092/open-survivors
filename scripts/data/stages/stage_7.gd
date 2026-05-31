extends RefCounted
# Stage 7 — Green Acres (challenge)
# Vampire Survivors reference: https://vampire-survivors.fandom.com/wiki/Green_Acres

static func get_data() -> Dictionary:
	return {
		"id": 7,
		"name": "Green Acres",
		"wiki_id": "GREENACRES",
		"type": "Challenge",
		"desc": "A land of changing fate.\nRandom enemy waves. +50% Enemy HP.",
		"time_limit": 1800.0,
		"bg_color": Color(0.06, 0.18, 0.06),
		"map_width": 6000,
		"map_height": 4500,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.3,
		"gold_mod": 1.0,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.5,
		"spawn_base_interval": 0.5,
		"spawn_min_interval": 0.1,
		"spawn_ramp_time": 20.0,
		"wave_size_interval": 20.0,
		"difficulty_ramp_time": 40.0,
		"unlock_req": "reach_level_40",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.9, "gold_mult": 1.5,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.5,
		},
		"stage_items": [],
		"interactables": {
			"chests": [
				{"pos": Vector2(-2500, -1000)},
				{"pos": Vector2(2000, 1500)},
				{"pos": Vector2(-1000, 2000)},
			],
			"fountains": [
				{"pos": Vector2(0, 0), "heal_pct": 0.50},
			],
			"breakable_density": 0.00015,
			"breakable_hp": 25.0,
			"hazards": [
				{"pos": Vector2(-1000, -2000), "size": Vector2(200, 100), "dps": 15.0},
			],
			"boosts": [
				{"pos": Vector2(1000, 500), "type": "magnet", "amount": 1.0, "size": Vector2(100, 100)},
			],
		},
	}
