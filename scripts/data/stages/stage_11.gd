extends RefCounted
# Stage 11 — The Lycaeum (bonus)
# Wiki: https://vampire.survivors.wiki/w/The_Lycaeum
# Wave data sourced from wiki wave table.
# Note: Unique underwater enemies mapped to closest project equivalents.

static func get_data() -> Dictionary:
	return {
		"id": 11,
		"wiki_id": "EX_LYCAEUM",
		"name": "The Lycaeum",
		"type": "Bonus",
		"desc": "Myths are murmured of a school submerged beneath a sunlit lake. In silent depths strange fish survive, while at its peak vile evil thrives.",
		"time_limit": 1200.0,
		"bg_color": Color(0.04, 0.1, 0.16),
		"map_width": 5200,
		"map_height": 3800,
		"map_scale": 2.0,
		"move_speed_mod": 1.0,
		"enemy_speed_mod": 1.0,
		"gold_mod": 1.2,
		"luck_mod": 0.0,
		"enemy_hp_mod": 1.0,
		"spawn_base_interval": 0.8,
		"spawn_min_interval": 0.12,
		"spawn_ramp_time": 25.0,
		"wave_size_interval": 25.0,
		"difficulty_ramp_time": 45.0,
		"unlock_req": "collect_50_vacuum",
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
		"wave_defs": [
			# Deep Angellette → wraith, Sea Ham → merman, Deep Sluge → jellyfish
			# Sea Spinach → serpentvine, Itchiocentaur → mantis, Awizotl → nightshade
			# Buklavaca → garlic, Tritont → tritont, Olmo → ghost
			# Enypnastys/Deep Sphynx (boss) → bat_g, Arcana Salmon → bat_g (arcana boss)
			{"time": 0,  "enemies": [{"id": "wraith", "count": 20}], "enemy_minimum": 20, "interval": 1.0},
			{"time": 1,  "enemies": [{"id": "wraith", "count": 15}, {"id": "merman", "count": 15}], "enemy_minimum": 30, "interval": 1.0},
			{"time": 2,  "enemies": [{"id": "merman", "count": 25}, {"id": "jellyfish", "count": 25}], "enemy_minimum": 50, "interval": 0.5},
			{"time": 3,  "enemies": [{"id": "serpentvine", "count": 20}, {"id": "jellyfish", "count": 20}], "enemy_minimum": 40, "interval": 0.25, "boss": "bat_g", "chest": true},
			{"time": 4,  "enemies": [{"id": "serpentvine", "count": 15}, {"id": "mantis", "count": 15}], "enemy_minimum": 30, "interval": 0.5},
			{"time": 5,  "enemies": [{"id": "mantis", "count": 40}], "enemy_minimum": 40, "interval": 0.75, "boss": "bat_g", "chest": true},
			{"time": 6,  "enemies": [{"id": "mantis", "count": 20}, {"id": "merman", "count": 20}], "enemy_minimum": 40, "interval": 0.5, "boss": "bat_g", "chest": true, "arcana": true},
			{"time": 7,  "enemies": [{"id": "mantis", "count": 40}, {"id": "wraith", "count": 40}], "enemy_minimum": 80, "interval": 0.5},
			{"time": 8,  "enemies": [{"id": "mantis", "count": 50}, {"id": "jellyfish", "count": 50}], "enemy_minimum": 100, "interval": 1.5, "boss": "bat_g", "chest": true},
			{"time": 9,  "enemies": [{"id": "mantis", "count": 15}, {"id": "serpentvine", "count": 15}, {"id": "wraith", "count": 10}], "enemy_minimum": 40, "interval": 0.5},
			{"time": 10, "enemies": [{"id": "mantis", "count": 10}, {"id": "nightshade", "count": 10}, {"id": "merman", "count": 10}], "enemy_minimum": 30, "interval": 0.5, "boss": "bat_g", "chest": true},
			{"time": 11, "enemies": [{"id": "nightshade", "count": 35}, {"id": "garlic", "count": 35}, {"id": "jellyfish", "count": 30}], "enemy_minimum": 100, "interval": 0.5},
			{"time": 12, "enemies": [{"id": "tritont", "count": 10}, {"id": "garlic", "count": 10}], "enemy_minimum": 20, "interval": 1.0, "boss": "bat_g", "chest": true},
			{"time": 13, "enemies": [{"id": "tritont", "count": 120}], "enemy_minimum": 120, "interval": 0.2, "boss": "bat_g", "chest": true, "arcana": true},
			{"time": 14, "enemies": [{"id": "mantis", "count": 75}, {"id": "serpentvine", "count": 75}], "enemy_minimum": 150, "interval": 0.5},
			{"time": 15, "enemies": [{"id": "serpentvine", "count": 50}], "enemy_minimum": 50, "interval": 0.5, "boss": "bat_g", "chest": true},
			{"time": 16, "enemies": [{"id": "ghost", "count": 40}, {"id": "mantis", "count": 40}], "enemy_minimum": 80, "interval": 0.5},
			{"time": 17, "enemies": [{"id": "ghost", "count": 20}, {"id": "serpentvine", "count": 20}], "enemy_minimum": 40, "interval": 0.1, "boss": "bat_g", "chest": true},
			{"time": 18, "enemies": [{"id": "ghost", "count": 45}, {"id": "bat_g", "count": 45}], "enemy_minimum": 90, "interval": 0.5},
			{"time": 19, "enemies": [{"id": "mantis", "count": 20}], "enemy_minimum": 20, "interval": 0.5},
			{"time": 20, "enemies": [], "enemy_minimum": 1, "interval": 10.0, "boss": "reaper"},
		],
		"map_events": [
			{"time": 0,  "type": "ex_seaangel_medusa", "repeats": 4},
			{"time": 1,  "type": "ex_crabbino_medusa", "repeats": 4},
			{"time": 2,  "type": "ex_salmon_red_medusa", "repeats": 4},
			{"time": 3,  "type": "ex_salmon_blue_medusa", "repeats": 4},
			{"time": 4,  "type": "ex_salmon_pink_medusa", "repeats": 4},
			{"time": 5,  "type": "ex_jelly_medusa", "repeats": 4},
			{"time": 6,  "type": "ex_salmon_red_medusa", "repeats": 4},
			{"time": 7,  "type": "ex_seaangel_medusa", "repeats": 4},
			{"time": 8,  "type": "ex_seahorse_medusa", "repeats": 4},
			{"time": 9,  "type": "ex_salmon_blue_medusa", "repeats": 4},
			{"time": 10, "type": "ex_salmon_pink_medusa", "repeats": 4},
			{"time": 11, "type": "ex_seaangel_medusa", "repeats": 4},
			{"time": 12, "type": "ex_jelly_medusa", "repeats": 4},
			{"time": 13, "type": "ex_salmon_red_medusa", "repeats": 4},
		],
		"decor_config": {
			"background_pattern": "solid",
			"decor_elements": [
				{"type": "dot", "count": 45, "size_min": 2, "size_max": 5,
				 "color": Color(0.04, 0.12, 0.18), "alpha_min": 0.15, "alpha_max": 0.35, "z": -49},
				{"type": "dot", "count": 12, "size_min": 1, "size_max": 3,
				 "color": Color(0.3, 0.6, 0.8), "alpha_min": 0.2, "alpha_max": 0.5, "z": -45},
			],
			"props": {
				"colors": [
					Color(0.06, 0.15, 0.22),
					Color(0.08, 0.18, 0.25),
					Color(0.10, 0.05, 0.15),
				],
			},
		},
	}
