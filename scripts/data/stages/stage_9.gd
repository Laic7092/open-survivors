extends RefCounted
# Stage 9 — Boss Rash (challenge)
# Vampire Survivors reference: https://vampire.survivors.wiki/w/Boss_Rash

static func get_data() -> Dictionary:
	return {
		"id": 9,
		"name": "Boss Rash",
		"desc": "The monsters want entertainment.\n15 minutes. All bosses. All the time.",
		"wiki_id": "RASH",
		"type": "Challenge",
		"time_limit": 900.0,
		"bg_color": Color(0.15, 0.02, 0.02),
		"map_width": 5000,
		"map_height": 3600,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.5,
		"gold_mod": 1.5,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.5,
		"spawn_base_interval": 1.5,
		"spawn_min_interval": 0.25,
		"spawn_ramp_time": 10.0,
		"wave_size_interval": 10.0,
		"difficulty_ramp_time": 20.0,
		"unlock_req": "reach_level_60",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.9, "gold_mult": 1.5,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.6,
		},
		"stage_items": [
			{"type": 4, "is_weapon": false, "pos": Vector2(-1000, 0)},
			{"type": 6, "is_weapon": false, "pos": Vector2(1000, 0)},
			{"type": 7, "is_weapon": false, "pos": Vector2(0, -800)},
			{"type": 13, "is_weapon": false, "pos": Vector2(0, 800)},
		],
		"interactables": {
			"fountains": [
				{"pos": Vector2(0, 0), "heal_pct": 0.50},
				{"pos": Vector2(-2000, -1000), "heal_pct": 0.30},
				{"pos": Vector2(2000, 1000), "heal_pct": 0.30},
			],
			"breakable_density": 0.0,
			"hazards": [
				{"pos": Vector2(-1000, -800), "size": Vector2(120, 80), "dps": 15.0},
				{"pos": Vector2(1000, 800), "size": Vector2(120, 80), "dps": 15.0},
			],
			"boosts": [
				{"pos": Vector2(-1500, 0), "type": "might", "amount": 0.5, "size": Vector2(100, 100)},
				{"pos": Vector2(1500, 0), "type": "speed", "amount": 0.5, "size": Vector2(100, 100)},
			],
		},
	}
