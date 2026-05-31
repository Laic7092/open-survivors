extends RefCounted
# Stage 16 — Holy Forbidden (Hidden Ground)
# Wiki: https://vampire.survivors.wiki/w/Holy_Forbidden
# wiki_id: STAGEX, Type: Hidden Ground, Time: 05:00

static func get_data() -> Dictionary:
	return {
		"id": 16,
		"name": "Holy Forbidden",
		"wiki_id": "STAGEX",
		"type": "Hidden Ground",
		"desc": "Wait, you can see this too? This isn't right...",
		"time_limit": 300.0,
		"bg_color": Color(0.08, 0.02, 0.16),
		"map_width": 4800,
		"map_height": 3600,
		"move_speed_mod": 1.0,
		"enemy_speed_mod": 1.3,
		"projectile_speed_mod": 1.0,
		"gold_mod": 3.0,
		"luck_mod": 0.0,
		"xp_mod": 1.0,
		"enemy_hp_mod": 1.2,
		"starting_spawns": 10,
		"enemy_minimum": 1,
		"spawn_base_interval": 0.5,
		"spawn_min_interval": 0.12,
		"spawn_ramp_time": 25.0,
		"wave_size_interval": 25.0,
		"difficulty_ramp_time": 50.0,
		"unlock_req": "relic_yellow_sign",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.8, "gold_mult": 1.5,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.5,
		},
		"inverse_mods": {
			"player_speed": 1.5,
			"enemy_speed": 1.1,
			"enemy_hp": 2.0,
			"gold_mult": 2.0,
		},
		"stage_items": [],
		"interactables": {
			"breakable_density": 0.0001,
			"breakable_hp": 20.0,
		},
	}
