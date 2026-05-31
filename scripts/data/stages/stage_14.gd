extends RefCounted
# Stage 14 — Bat Country (challenge)
# Wiki: https://vampire.survivors.wiki/w/Bat_Country
# Wave data sourced from wiki wave table.

static func get_data() -> Dictionary:
	return {
		"id": 14,
		"name": "Bat Country",
		"wiki_id": "BATCOUNTRY",
		"type": "Challenge",
		"desc": "We can't stop here.\nAll bats. Enemies grow stronger over time. -75% XP.",
		"time_limit": 1200.0,
		"bg_color": Color(0.04, 0.02, 0.06),
		"map_width": 3200,
		"map_height": 2400,
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 1.25,
		"enemy_speed_per_min": 0.25,
		"projectile_speed_mod": 1.0,
		"gold_mod": 1.3,
		"luck_mod": 0.0,
		"xp_mod": 0.25,
		"enemy_hp_mod": 1.0,
		"enemy_hp_per_min": 0.2,
		"starting_spawns": 0,
		"spawn_base_interval": 0.35,
		"spawn_min_interval": 0.07,
		"spawn_ramp_time": 12.0,
		"wave_size_interval": 12.0,
		"difficulty_ramp_time": 25.0,
		"unlock_req": "reach_level_80_inverse_mad_forest",
		"hyper_unlock": "default",
		"hyper_mods": {
			"move_speed_bonus": 0.65,
			"gold_mult": 1.8,
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.0,
		},
		"stage_items": [],
		"interactables": {
			"chests": [
				{"pos": Vector2(-1000, -800)},
				{"pos": Vector2(1000, 800)},
			],
			"fountains": [
				{"pos": Vector2(0, 0), "heal_pct": 0.50},
			],
			"breakable_density": 0.0003,
			"breakable_hp": 15.0,
			"hazards": [
				{"pos": Vector2(-500, 500), "size": Vector2(100, 100), "dps": 12.0},
			],
			"boosts": [
				{"pos": Vector2(500, -500), "type": "speed", "amount": 0.5, "size": Vector2(80, 80)},
			],
		},
		"wave_defs": [
			# Bat Country: all bats, very high enemy minimum (300), intervals decrease over time
			# Bosses are Glowing Bat / Golden Bat variants
			{"time": 0,  "enemies": [{"id": "bat_s", "count": 200}], "enemy_minimum": 200, "interval": 9.0},
			{"time": 1,  "enemies": [{"id": "bat_s", "count": 150}, {"id": "bat_r", "count": 150}], "enemy_minimum": 300, "interval": 9.0, "boss": "bat_g", "chest": true},
			{"time": 2,  "enemies": [{"id": "bat_s", "count": 100}, {"id": "bat_r", "count": 100}, {"id": "bat_giant", "count": 100}], "enemy_minimum": 300, "interval": 8.0, "boss": "bat_g", "chest": true},
			{"time": 3,  "enemies": [{"id": "bat_r", "count": 300}], "enemy_minimum": 300, "interval": 7.0, "boss": "bat_g", "chest": true},
			{"time": 4,  "enemies": [{"id": "bat_r", "count": 300}], "enemy_minimum": 300, "interval": 6.0},
			{"time": 5,  "enemies": [{"id": "bat_r", "count": 300}], "enemy_minimum": 300, "interval": 5.0, "boss": "bat_g", "chest": true, "arcana": true},
			{"time": 6,  "enemies": [{"id": "bat_r", "count": 300}], "enemy_minimum": 300, "interval": 4.0, "boss": "bat_g", "chest": true},
			{"time": 7,  "enemies": [{"id": "bat_r", "count": 300}], "enemy_minimum": 300, "interval": 3.0, "boss": "bat_g", "chest": true},
			{"time": 8,  "enemies": [{"id": "bat_s", "count": 150}, {"id": "bat_r", "count": 150}], "enemy_minimum": 300, "interval": 2.0},
			{"time": 9,  "enemies": [{"id": "bat_r", "count": 300}], "enemy_minimum": 300, "interval": 1.0, "boss": "bat_g", "chest": true},
			{"time": 10, "enemies": [{"id": "bat_s", "count": 150}, {"id": "bat_r", "count": 150}], "enemy_minimum": 300, "interval": 0.5, "boss": "bat_g", "chest": true, "arcana": true},
			{"time": 11, "enemies": [{"id": "bat_r", "count": 300}], "enemy_minimum": 300, "interval": 0.4},
			{"time": 12, "enemies": [{"id": "bat_s", "count": 150}, {"id": "bat_r", "count": 150}], "enemy_minimum": 300, "interval": 0.3, "boss": "bat_g", "chest": true},
			{"time": 13, "enemies": [{"id": "bat_r", "count": 300}], "enemy_minimum": 300, "interval": 0.2, "boss": "bat_g", "chest": true},
			{"time": 14, "enemies": [{"id": "bat_giant", "count": 150}, {"id": "bat_r", "count": 150}], "enemy_minimum": 300, "interval": 0.1},
			{"time": 15, "enemies": [{"id": "bat_giant", "count": 100}, {"id": "bat_s", "count": 100}, {"id": "bat_r", "count": 100}], "enemy_minimum": 300, "interval": 0.1, "boss": "bat_g", "chest": true},
			{"time": 16, "enemies": [{"id": "bat_giant", "count": 150}, {"id": "bat_r", "count": 150}], "enemy_minimum": 300, "interval": 0.1},
			{"time": 17, "enemies": [{"id": "bat_giant", "count": 300}], "enemy_minimum": 300, "interval": 0.1},
			{"time": 18, "enemies": [{"id": "bat_giant", "count": 150}, {"id": "bat_r", "count": 150}], "enemy_minimum": 300, "interval": 0.1, "boss": "bat_g", "chest": true},
			{"time": 19, "enemies": [{"id": "bat_giant", "count": 300}], "enemy_minimum": 300, "interval": 0.1},
			{"time": 20, "enemies": [], "enemy_minimum": 300, "interval": 0.1, "boss": "reaper"},
		],
		# Map events are Diamond-related (visual effects) — omitted for simplicity
		"map_events": [],
		"decor_config": {
			"background_pattern": "solid",
			"decor_elements": [
				{"type": "dot", "count": 40, "size_min": 2, "size_max": 4,
				 "color": Color(0.04, 0.02, 0.08), "alpha_min": 0.15, "alpha_max": 0.35, "z": -49},
				{"type": "dot", "count": 15, "size_min": 1, "size_max": 2,
				 "color": Color(0.6, 0.1, 0.1), "alpha_min": 0.3, "alpha_max": 0.6, "z": -45},
			],
			"props": {
				"colors": [
					Color(0.08, 0.02, 0.12),
					Color(0.12, 0.04, 0.15),
					Color(0.20, 0.05, 0.05),
				],
			},
		},
	}
