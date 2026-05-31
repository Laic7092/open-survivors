extends RefCounted
# Stage 0 — Mad Forest
# Vampire Survivors reference: https://vampire.survivors.wiki/w/Mad_Forest

const TS := 48.0  # tileset unit

static func get_data() -> Dictionary:
	return {
		"id": 0,
		"name": "Mad Forest",
		"wiki_id": "FOREST",
		"type": "Normal",
		"tags": ["forest", "normal", "main_stage"],
		"desc": "Once a thriving haven, now a dumping ground for evil. A vampire is said to be the root of this evil, but we can find only mayhem and roast chicken.",
		"time_limit": 1800.0,
		"bg_color": Color(0.04, 0.04, 0.10),
		"map_width": 6400,
		"map_height": 4800,
		"theme": "Forest Night Fever",

		# ── 基础倍率 ──
		"move_speed_mod": 1.1,
		"enemy_speed_mod": 1.1,
		"projectile_speed_mod": 1.0,
		"gold_mod": 1.0,
		"luck_mod": 0.0,
		"xp_mod": 1.0,
		"enemy_hp_mod": 1.0,

		# ── 生成参数 ──
		"starting_spawns": 10,
		"enemy_minimum": 1,
		"spawn_base_interval": 1.0,
		"spawn_min_interval": 0.15,
		"spawn_ramp_time": 30.0,
		"wave_size_interval": 30.0,
		"difficulty_ramp_time": 60.0,

		# ── 可破坏物（灯柱） ──
		"breakable_chance": 0.1,
		"breakable_chance_max": 0.5,
		"max_breakable": 10,

		# ── 解锁 ──
		"unlock_req": "",
		"hyper_unlock": "boss_stage_0",

		# ── Hyper ──
		"hyper_mods": {
			"move_speed_bonus": 0.9,   # total 2.0 (x1.1 + 0.9)
			"enemy_speed_bonus": 0.9,  # total 2.0
			"gold_mult": 1.5,
			"enemy_hp_bonus": 0.0,
			"projectile_speed_bonus": 0.25,  # x1.25
		},

		# ── Inverse ──
		"inverse_mods": {
			"player_speed": 2.0,
			"enemy_speed": 1.1,
			"enemy_speed_per_min": 0.005,
			"enemy_hp": 3.0,
			"enemy_hp_per_min": 0.05,
			"gold_mult": 3.0,
			"projectile_speed": 1.25,
			"luck": 0.2,
			"xp": 1.0,
			"starting_spawns": 15,
			"enemy_minimum": 1.25,
		},

		# ── 场景道具 ──
		"stage_items": [
			# Skull O'Maniac — 6 tilesets NW
			{"type": 25, "is_weapon": false, "positions": [Vector2(-6 * TS, -6 * TS)]},
			# Hollow Heart — 4~5 tilesets N
			{"type": 6,  "is_weapon": false, "positions": [Vector2(0, -4.5 * TS)]},
			# Spinach — up to 4 copies
			{"type": 4,  "is_weapon": false, "positions": [
				{"pos": Vector2(3 * TS, -2 * TS), "chance": 1.0},
				{"pos": Vector2(5 * TS, -2 * TS), "chance": 0.3},
				{"pos": Vector2(4 * TS,  2 * TS), "chance": 0.2},
				{"pos": Vector2(6 * TS,  2 * TS), "chance": 0.1},
			]},
			# Pummarola — 5 tilesets S
			{"type": 9,  "is_weapon": false, "positions": [Vector2(0, 5 * TS)]},
			# Clover — up to 4 copies
			{"type": 21, "is_weapon": false, "positions": [
				{"pos": Vector2(-4 * TS,  3 * TS), "chance": 1.0},
				{"pos": Vector2(-2 * TS,  4 * TS), "chance": 0.3},
				{"pos": Vector2(-4 * TS,  4 * TS), "chance": 0.2},
				{"pos": Vector2(-5 * TS,  3 * TS), "chance": 0.1},
			]},
		],

		# ── 棺材（解锁角色） ──
		"coffin": {
			"pos": Vector2(6 * TS, -6 * TS),
			"character": "pugnala",
		},

		# ── 隐藏遗物（需 Yellow Sign） ──
		"hidden_relics": [
			{"id": "silver_ring",    "pos": Vector2(0,       -7 * TS)},
			{"id": "metaglio_right", "pos": Vector2(7 * TS,  0)},
			{"id": "gold_ring",      "pos": Vector2(0,        7 * TS)},
			{"id": "metaglio_left",  "pos": Vector2(-7 * TS, 0)},
		],

		# ── 交互元素 ──
		"interactables": {
			"chests": [
				{"pos": Vector2(-2500, -1500)},
				{"pos": Vector2(2000, 1800)},
				{"pos": Vector2(-1500, 2000)},
			],
			"fountains": [
				{"pos": Vector2(-1200, -600), "heal_pct": 0.50},
				{"pos": Vector2(1500, -1000), "heal_pct": 0.50},
			],
			"breakable_density": 0.00025,
			"breakable_hp": 20.0,
			"hazards": [
				{"pos": Vector2(-800, 2000), "size": Vector2(120, 120), "dps": 12.0},
				{"pos": Vector2(2800, -500), "size": Vector2(100, 100), "dps": 15.0},
			],
			"boosts": [
				{"pos": Vector2(0, 0), "type": "speed", "amount": 0.5, "size": Vector2(80, 80)},
			],
		},

		# ── 波次定义（分钟级） ──
		"wave_defs": [
			{"time": 0,  "enemies": [{"id": "bat_r", "count": 15}], "enemy_minimum": 15, "interval": 1.0, "boss": null},
			{"time": 1,  "enemies": [{"id": "zombie", "count": 10}, {"id": "bat_s", "count": 20}], "enemy_minimum": 30, "interval": 0.8, "boss": "bat_g", "chest": true},
			{"time": 2,  "enemies": [{"id": "bat_s", "count": 20}, {"id": "bat_r", "count": 30}], "enemy_minimum": 50, "interval": 0.5, "events": [{"type": "bat_swarm", "delay": 5, "repeats": 2}]},
			{"time": 3,  "enemies": [{"id": "skeleton", "count": 40}], "enemy_minimum": 40, "interval": 0.25, "boss": "bat_g"},
			{"time": 4,  "enemies": [{"id": "skeleton", "count": 20}, {"id": "ghost", "count": 10}], "enemy_minimum": 30, "interval": 1.0},
			{"time": 5,  "enemies": [{"id": "mudman_g", "count": 10}], "enemy_minimum": 10, "interval": 1.0, "boss": "mantichana", "events": [{"type": "flower_wall", "duration": 30}]},
			{"time": 6,  "enemies": [{"id": "zombie", "count": 10}, {"id": "mudman_g", "count": 10}], "enemy_minimum": 20, "interval": 0.5},
			{"time": 7,  "enemies": [{"id": "bat_r", "count": 40}, {"id": "mudman", "count": 40}], "enemy_minimum": 80, "interval": 0.5, "boss": "bat_g"},
			{"time": 8,  "enemies": [{"id": "zombie_b", "count": 100}], "enemy_minimum": 100, "interval": 1.5, "boss": "bat_giant"},
			{"time": 9,  "enemies": [{"id": "bat_giant", "count": 10}, {"id": "zombie", "count": 20}], "enemy_minimum": 30, "interval": 0.5, "boss": "bat_silver"},
			{"time": 10, "enemies": [{"id": "mudman", "count": 5}, {"id": "mudman_g", "count": 5}], "enemy_minimum": 10, "interval": 0.5, "boss": "mantichana_giant", "events": [{"type": "flower_wall", "duration": 60}]},
			{"time": 11, "enemies": [{"id": "skeleton_b", "count": 300}], "enemy_minimum": 300, "interval": 0.1, "boss": "bat_g", "arcana": true},
			{"time": 12, "enemies": [{"id": "werewolf", "count": 10}, {"id": "ghost", "count": 10}], "enemy_minimum": 20, "interval": 0.25, "boss": "bat_g"},
			{"time": 13, "enemies": [{"id": "werewolf", "count": 50}, {"id": "ghost", "count": 100}], "enemy_minimum": 150, "interval": 0.5, "events": [{"type": "ghost_swarm"}]},
			{"time": 14, "enemies": [{"id": "bat_giant", "count": 10}, {"id": "werewolf", "count": 10}], "enemy_minimum": 20, "interval": 0.1, "boss": "bat_silver"},
			{"time": 15, "enemies": [{"id": "werewolf", "count": 30}, {"id": "bat_giant", "count": 30}, {"id": "mudman_g", "count": 40}], "enemy_minimum": 100, "interval": 0.1, "boss": "werewolf_giant", "events": [{"type": "flower_wall", "duration": 60}]},
			{"time": 16, "enemies": [{"id": "mantichana", "count": 20}, {"id": "mudman", "count": 40}, {"id": "mudman_g", "count": 40}], "enemy_minimum": 100, "interval": 0.1, "boss": "bat_g"},
			{"time": 17, "enemies": [{"id": "mummy_big", "count": 20}], "enemy_minimum": 20, "interval": 1.0},
			{"time": 18, "enemies": [{"id": "mummy_big", "count": 30}, {"id": "mudman", "count": 30}], "enemy_minimum": 60, "interval": 0.5, "boss": "bat_silver"},
			{"time": 19, "enemies": [{"id": "mummy_big", "count": 50}, {"id": "mudman", "count": 50}], "enemy_minimum": 100, "interval": 0.5},
			{"time": 20, "enemies": [{"id": "mummy_big", "count": 40}, {"id": "mudman_g", "count": 30}, {"id": "bat_giant", "count": 30}], "enemy_minimum": 100, "interval": 0.1, "boss": "mummy_giant"},
			{"time": 21, "enemies": [{"id": "flower_wall", "count": 300}], "enemy_minimum": 300, "interval": 0.1, "boss": "venus", "arcana": true},
			{"time": 22, "enemies": [{"id": "flower_wall", "count": 100}, {"id": "mummy_big", "count": 100}], "enemy_minimum": 200, "interval": 0.1, "boss": "bat_g"},
			{"time": 23, "enemies": [{"id": "flower_wall", "count": 150}, {"id": "mummy_big", "count": 150}], "enemy_minimum": 300, "interval": 0.1, "boss": "bat_silver"},
			{"time": 24, "enemies": [{"id": "flower_wall", "count": 150}, {"id": "mummy_big", "count": 150}], "enemy_minimum": 300, "interval": 0.1, "boss": "venus"},
			{"time": 25, "enemies": [{"id": "venus", "count": 100}], "enemy_minimum": 100, "interval": 0.1, "boss": "venus_blue_giant", "events": [{"type": "flower_wall", "delay": 10, "repeats": 6, "duration": 10}]},
			{"time": 26, "enemies": [{"id": "venus", "count": 50}, {"id": "flower_wall", "count": 100}], "enemy_minimum": 150, "interval": 0.1},
			{"time": 27, "enemies": [{"id": "mummy_big", "count": 100}, {"id": "mudman", "count": 100}, {"id": "mudman_g", "count": 100}], "enemy_minimum": 300, "interval": 0.1, "boss": "bat_g"},
			{"time": 28, "enemies": [{"id": "bat_giant", "count": 150}, {"id": "bat_g", "count": 150}], "enemy_minimum": 300, "interval": 0.1},
			{"time": 29, "enemies": [{"id": "bat_g", "count": 150}, {"id": "bat_silver", "count": 150}], "enemy_minimum": 300, "interval": 0.1, "boss": "bat_g"},
			{"time": 30, "enemies": [], "enemy_minimum": 1, "interval": 60.0, "boss": "reaper"},
		],

		# ── 地图事件 ──
		"map_events": [
			{"time": 2,  "type": "bat_swarm",   "unit": "bat",   "delay": 5.0,  "repeats": 2, "direction": "straight"},
			{"time": 5,  "type": "flower_wall",  "duration": 30.0, "chance": 1.0},
			{"time": 13, "type": "ghost_swarm",  "unit": "ghost", "delay": 1.2, "repeats": 20},
		],

		# ── 数据驱动装饰配置 ──
		"decor_config": {
			"background_pattern": "solid",
			"decor_elements": [
				{"type": "dot", "count": 60, "size_min": 2, "size_max": 5,
				 "color": Color(0.08, 0.12, 0.04), "alpha_min": 0.15, "alpha_max": 0.35, "z": -49},
				{"type": "dot", "count": 15, "size_min": 1, "size_max": 3,
				 "color": Color(0.6, 0.9, 0.3), "alpha_min": 0.3, "alpha_max": 0.7, "z": -45},
			],
			"props": {
				"colors": [
					Color(0.15, 0.35, 0.05),
					Color(0.25, 0.40, 0.10),
					Color(0.30, 0.20, 0.10),
				],
			},
		},
	}
