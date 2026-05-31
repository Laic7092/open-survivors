extends RefCounted
# Stage 19 — Tiny Bridge (challenge)
# Wiki: https://vampire.survivors.wiki/w/Tiny_Bridge
# wiki_id: TOWERBRIDGE, Type: Challenge

static func get_data() -> Dictionary:
	return {
		"id": 19,
		"name": "Tiny Bridge",
		"desc": "A narrow crossing over a bottomless chasm.\nTwo opposing factions abruptly stopped fighting here.",
		"time_limit": 1200.0,
		"bg_color": Color(0.06, 0.14, 0.06),
		"map_width": 2400,
		"map_height": 4800,
		"move_speed_mod": 1.0,
		"enemy_speed_mod": 1.5,
		"gold_mod": 1.3,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.5,
		"spawn_base_interval": 0.35,
		"spawn_min_interval": 0.08,
		"spawn_ramp_time": 18.0,
		"wave_size_interval": 18.0,
		"difficulty_ramp_time": 35.0,
		"unlock_req": "reach_level_75",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.0, "gold_mult": 1.8,
			"enemy_speed_bonus": 0.0, "enemy_hp_bonus": 0.5,
		},
		"stage_items": [],
	}
