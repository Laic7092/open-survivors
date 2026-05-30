extends RefCounted
# Stage 11 — The Lycaeum (bonus)

static func get_data() -> Dictionary:
	return {
		"id": 11,
		"name": "The Lycaeum",
		"desc": "School submerged beneath a sunlit lake.\n+20% Gold. Strange fish.",
		"time_limit": 1200.0,
		"bg_color": Color(0.04, 0.1, 0.16),
		"map_width": 5200,
		"map_height": 3800,
		"move_speed_mod": 1.0,
		"enemy_speed_mod": 1.2,
		"gold_mod": 1.2,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 0.8,
		"spawn_min_interval": 0.12,
		"spawn_ramp_time": 25.0,
		"wave_size_interval": 25.0,
		"difficulty_ramp_time": 45.0,
		"unlock_req": "clear_stage_4",
		"hyper_unlock": "boss_stage_11",
		"hyper_mods": {
			"move_speed_bonus": 1.0, "gold_mult": 1.7,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.0,
		},
		"stage_items": [
			{"type": 15, "is_weapon": false, "pos": Vector2(-1200, 800)},
			{"type": 3, "is_weapon": false, "pos": Vector2(1000, -600)},
			{"type": 22, "is_weapon": false, "pos": Vector2(-800, -1200)},
		],
		"interactables": {
			"chests": [
				{"pos": Vector2(-2000, 1200)},
				{"pos": Vector2(2000, -1000)},
			],
			"fountains": [
				{"pos": Vector2(0, 0), "heal_pct": 0.50},
			],
			"breakable_density": 0.0002,
			"breakable_hp": 20.0,
			"hazards": [
				{"pos": Vector2(-1500, -500), "size": Vector2(200, 100), "dps": 10.0},
				{"pos": Vector2(1500, 800), "size": Vector2(150, 100), "dps": 8.0},
			],
			"boosts": [
				{"pos": Vector2(0, -1500), "type": "might", "amount": 0.3, "size": Vector2(80, 80)},
			],
		},
	}
