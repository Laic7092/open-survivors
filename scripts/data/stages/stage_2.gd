extends RefCounted
# Stage 2 — Il Molise (bonus)
# Wiki: https://vampire.survivors.wiki/w/Il_Molise
#
# Molisano family are all stationary (enemy_speed_mod = 0.0).
# Enemies spawn outside screen in tiled layout; player must move to make room.

const TS := 48.0

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
		"map_scale": 2.0,
		"theme": "Vempair Survaivors",
		"move_speed_mod": 1.25,
		"enemy_speed_mod": 0.0,
		"projectile_speed_mod": 1.0,
		"gold_mod": 1.0,
		"luck_mod": 0.0,
		"xp_mod": 1.0,
		"enemy_hp_mod": 1.0,

		"starting_spawns": 1,
		"enemy_minimum": 500,
		"spawn_base_interval": 0.1,
		"spawn_min_interval": 0.1,
		"spawn_ramp_time": 60.0,
		"wave_size_interval": 60.0,
		"difficulty_ramp_time": 60.0,

		"unlock_req": "clear_stage_1",
		"hyper_unlock": "default",

		"hyper_mods": {
			"move_speed_bonus": 1.0,
			"gold_mult": 1.5,
			"enemy_speed_bonus": 0.0,
			"enemy_hp_bonus": 0.6,
			"projectile_speed_bonus": 0.15,
			"luck": 0.2,
		},

		# Hidden relics (require Yellow Sign)
		"stage_items": [
			# Silver Ring — north
			{"type": 25, "is_weapon": false, "positions": [Vector2(0, -5 * TS)]},
			# Metaglio Right — east
			{"type": 23, "is_weapon": false, "positions": [Vector2(5 * TS, 0)]},
			# Gold Ring — south
			{"type": 26, "is_weapon": false, "positions": [Vector2(0, 5 * TS)]},
			# Metaglio Left — west
			{"type": 24, "is_weapon": false, "positions": [Vector2(-5 * TS, 0)]},
		],

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

		# ── 波次定义（参考 wiki 波次表） ──
		# 所有敌人都是静止的：只从屏幕外铺砖式生成
		# Enemy minimum = 500，每波维持高密度
		# 每波都生成 Molisano Anfora（掉金币的特殊敌人）
		"wave_defs": [
			{"time": 0,  "enemies": [{"id": "molisano_base"}],             "enemy_minimum": 500, "interval": 0.1, "boss": "molisano_anfora"},
			{"time": 1,  "enemies": [{"id": "molisano_base"}, {"id": "molisano_secco"}], "enemy_minimum": 500, "interval": 0.1, "boss": "molisano_anfora"},
			{"time": 2,  "enemies": [{"id": "molisano_secco"}],            "enemy_minimum": 500, "interval": 0.1, "boss": "molisano_anfora"},
			{"time": 3,  "enemies": [{"id": "molisano_secco"}, {"id": "molisano_bello"}, {"id": "molisano_base"}], "enemy_minimum": 500, "interval": 0.1, "boss": "molisano_anfora"},
			{"time": 4,  "enemies": [{"id": "molisano_bello"}, {"id": "molisano_grosso"}, {"id": "molisano_base"}], "enemy_minimum": 500, "interval": 0.1, "boss": "molisano_anfora"},
			{"time": 5,  "enemies": [{"id": "molisano_grosso"}, {"id": "molisano_giallo"}], "enemy_minimum": 500, "interval": 0.1, "boss": "molisano_anfora"},
			{"time": 6,  "enemies": [{"id": "molisano_grosso"}, {"id": "molisano_giallo"}, {"id": "molisano_bello"}], "enemy_minimum": 500, "interval": 0.1, "boss": "molisano_anfora"},
			{"time": 7,  "enemies": [{"id": "molisano_rosso"}, {"id": "molisano_giallo"}], "enemy_minimum": 500, "interval": 0.1, "boss": "molisano_anfora"},
			{"time": 8,  "enemies": [{"id": "molisano_rosso"}],            "enemy_minimum": 500, "interval": 0.1, "boss": "molisano_anfora"},
			{"time": 9,  "enemies": [{"id": "molisano_rosso"}, {"id": "molisano_fagiolo"}], "enemy_minimum": 500, "interval": 0.1, "boss": "molisano_vecchio", "chest": true},
			{"time": 10, "enemies": [{"id": "molisano_fagiolo"}, {"id": "molisano_base"}], "enemy_minimum": 500, "interval": 0.1, "boss": "molisano_vecchio", "chest": true},
		],

		# ── 地图事件 ──
		"map_events": [
			# Each wave also spawns an Anfora as a mini-event
			{"time": 0, "type": "burst", "unit": "molisano_anfora", "count": 1, "delay": 0.0, "chance": 1.0},
			{"time": 1, "type": "burst", "unit": "molisano_anfora", "count": 1, "delay": 0.0, "chance": 1.0},
			{"time": 2, "type": "burst", "unit": "molisano_anfora", "count": 1, "delay": 0.0, "chance": 1.0},
			{"time": 3, "type": "burst", "unit": "molisano_anfora", "count": 1, "delay": 0.0, "chance": 1.0},
			{"time": 4, "type": "burst", "unit": "molisano_anfora", "count": 1, "delay": 0.0, "chance": 1.0},
			{"time": 5, "type": "burst", "unit": "molisano_anfora", "count": 1, "delay": 0.0, "chance": 1.0},
			{"time": 6, "type": "burst", "unit": "molisano_anfora", "count": 1, "delay": 0.0, "chance": 1.0},
			{"time": 7, "type": "burst", "unit": "molisano_anfora", "count": 1, "delay": 0.0, "chance": 1.0},
			{"time": 8, "type": "burst", "unit": "molisano_anfora", "count": 1, "delay": 0.0, "chance": 1.0},
			{"time": 9, "type": "burst", "unit": "molisano_anfora", "count": 1, "delay": 0.0, "chance": 1.0},
		],

		"decor_config": {
			"background_pattern": "solid",
			"decor_elements": [
				{"type": "dot", "count": 50, "size_min": 2, "size_max": 5,
				 "color": Color(0.08, 0.18, 0.06), "alpha_min": 0.15, "alpha_max": 0.35, "z": -49},
				{"type": "dot", "count": 10, "size_min": 1, "size_max": 3,
				 "color": Color(0.4, 0.8, 0.3), "alpha_min": 0.3, "alpha_max": 0.6, "z": -45},
			],
			"props": {
				"colors": [
					Color(0.15, 0.30, 0.08),
					Color(0.20, 0.35, 0.10),
					Color(0.25, 0.15, 0.05),
				],
			},
		},
	}
