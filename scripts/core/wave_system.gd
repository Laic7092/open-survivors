extends Node
# WaveSystem — 波次生成系统
#
# wave_defs 驱动的关卡：每波定义"维持最低 N 个敌人，每 interval 秒补一次"
# 波次按分钟精确触发，到时间自动切换参数。所有敌人来源只有 wave_defs。
#
# 如关卡未定义 wave_defs，走传统最低敌人维持模式。
# 如有关卡使用 wave_defs 但格式不同，需另设兼容。

const GameState = preload("res://scripts/core/game_state.gd")

# 外部依赖：由 main.gd 注入
var game_state: GameState
var player: Node2D
var camera_ctrl: Node
var spawn_enemy_func: Callable  # func(type_id: int) -> Node2D

# ── 敌人名称 → 类型 ID 映射 ──
const ENEMY_NAME_MAP := {
	"bat_r": 12, "bat_s": 11, "bat_g": 14, "bat_silver": 14, "bat_giant": 13,
	"zombie": 8, "zombie_b": 8, "skeleton": 9, "skeleton_b": 9, "skeleton_r": 9,
	"ghost": 10, "mudman": 15, "mudman_g": 16, "werewolf": 18, "werewolf_giant": 18,
	"mantichana": 17, "mantichana_giant": 17, "mummy_big": 19, "mummy_giant": 19,
	"flower_wall": 0, "venus": 20, "venus_blue_giant": 21, "reaper": 22,

	# Inlaid Library
	"dust_elemental": 23, "musc_musc": 24, "big_musc_musc": 24,
	"testa_di_mano": 28, "mummy": 26, "medusa_head": 25,
	"big_sneaky_head": 25, "aggressive_sneaky_head": 25, "lionhead": 27,
	"dullahan": 28, "silver_bat": 14, "apprentice_witch": 29,
	"elite_dullahan": 30, "undead_witch": 30, "glowing_skull": 31, "giant_medusa": 32,

	# Inlaid Library bosses
	"colossal_musc_musc": 5, "colossal_lionhead": 17, "colossal_sneaky_head": 20,
	"colossal_dust_elemental": 2, "queen_medusa": 20, "master_witch": 5,
	"nesuferit": 21, "hag": 21,
}

# ── 事件类型 → 敌人名称映射 ──
const EVENT_ENEMY_MAP := {
	"shade_bomb": "dust_elemental", "medusa_wall": "medusa_head",
	"medusa_swarm": "medusa_head", "skull_swarm": "glowing_skull",
	"bat_swarm": "bat_s", "flower_wall": "flower_wall", "ghost_swarm": "ghost",
}

# ── 内部状态 ──
var _map_ready: bool = false

# 波次定义（从 stage_data 加载）
var _wave_defs: Array = []
var _next_wave_index: int = 0

# 当前波次参数（持续补怪模型）
var _wave_timer: float = 0.0           # 距下次补怪倒计时
var _wave_enemy_types: Array[int] = [] # 当前波次可用敌人类型 ID 列表
var _wave_minimum: int = 1             # 当前波次最低存活数
var _wave_interval: float = 1.0        # 当前波次补怪间隔（秒）
var _wave_boss_id: int = -1            # 当前波次 Boss 类型（-1=无）
var _wave_boss_spawned: bool = false   # Boss 是否已生成

# 地图事件
var _map_events: Array = []
var _map_event_index: int = 0

# 波次内事件
var _wave_events: Array = []
var _wave_event_index: int = 0
var _wave_elapsed: float = 0.0

# ── 信号 ──
signal wave_started(wave_number: int)
signal wave_event_triggered(event_type: String, event_data: Dictionary)


func setup(gs: GameState, p: Node2D, spawn_func: Callable, cam: Node = null):
	game_state = gs
	player = p
	camera_ctrl = cam
	spawn_enemy_func = spawn_func

	var stage_data = gs.stage_data
	if stage_data.has("wave_defs") and not stage_data["wave_defs"].is_empty():
		_wave_defs = stage_data["wave_defs"].duplicate()
		_wave_defs.sort_custom(_sort_by_time)

	if stage_data.has("map_events") and not stage_data["map_events"].is_empty():
		_map_events = stage_data["map_events"].duplicate()
		_map_events.sort_custom(_sort_by_map_event_time)


static func _sort_by_map_event_time(a: Dictionary, b: Dictionary) -> bool:
	var a_t = a.get("time", 0) * 60.0 + a.get("delay", 0.0)
	var b_t = b.get("time", 0) * 60.0 + b.get("delay", 0.0)
	return a_t < b_t


static func _sort_by_time(a: Dictionary, b: Dictionary) -> bool:
	return a.get("time", 0) < b.get("time", 0)


func set_map_ready(val: bool):
	_map_ready = val
	if val and not _wave_defs.is_empty():
		_wave_timer = 0.1  # 首帧快速启动第一波


func process(delta: float):
	if not _map_ready or game_state.game_over or game_state.stage_complete:
		return

	# 地图事件（时间触发）
	_process_map_events()

	if _wave_defs.is_empty():
		return  # 无 wave_defs 的关卡不做任何事

	_process_wave_defs(delta)


# ═══════════════════════════════════════════════════════════
#  持续补怪模式
# ═══════════════════════════════════════════════════════════

func _process_wave_defs(delta: float):
	# 检查是否该触发下一波（按 game_time 推进）
	_try_trigger_next_wave()

	# 1) 持续生成：每 interval 秒出一小波
	_wave_timer -= delta
	if _wave_timer <= 0.0:
		_wave_timer = _wave_interval
		_spawn_continuous_batch()

	# 2) 硬下限检测：场上少于 minimum 时立刻补满
	_check_minimum_enforcement()

	# 波次内事件
	_process_wave_events(delta)


func _try_trigger_next_wave():
	var gs = game_state
	var game_sec = gs.game_time

	# 所有波次已触发 → 用最后一波的参数继续补怪
	if _next_wave_index >= _wave_defs.size():
		return

	var wd = _wave_defs[_next_wave_index]
	var wave_time_sec = wd.get("time", 0) * 60.0
	if game_sec < wave_time_sec:
		return

	# ── 触发波次 ──
	_next_wave_index += 1
	gs.wave_number += 1

	# 更新参数
	_wave_minimum = wd.get("enemy_minimum", 1)
	_wave_interval = wd.get("interval", 0.5)

	# 解析敌人类型列表
	_wave_enemy_types.clear()
	var enemies = wd.get("enemies", [])
	for entry in enemies:
		var type_id = _resolve_enemy_id(entry.get("id", ""))
		if type_id >= 0:
			_wave_enemy_types.append(type_id)

	# Boss
	var boss_name = wd.get("boss", null)
	_wave_boss_id = _resolve_enemy_id(boss_name) if boss_name != null and boss_name != "" else -1
	_wave_boss_spawned = false

	# 波次内事件
	_wave_events.clear()
	_wave_event_index = 0
	_wave_elapsed = 0.0
	if wd.has("events"):
		_wave_events = wd["events"].duplicate()
		_wave_events.sort_custom(_sort_by_wave_event_delay)

	# 重置计时器，让下一轮补怪尽快开始
	_wave_timer = 0.1

	# 立即生成 Boss
	_spawn_boss_if_needed()

	gs.wave_active = true
	wave_started.emit(gs.wave_number)


# 持续生成：每 interval 秒出一小波（正常刷怪节奏）
func _spawn_continuous_batch():
	if _wave_enemy_types.is_empty():
		return

	# 批次大小随 minimum 增长，保证节奏感
	var batch_size = maxi(1, floori(_wave_minimum / 20.0))
	for _i in range(batch_size):
		var type_id = _wave_enemy_types[randi() % _wave_enemy_types.size()]
		var enemy = spawn_enemy_func.call(type_id)
		if is_instance_valid(enemy):
			enemy.is_wave_enemy = true


# 硬下限检测：场上少于 minimum 时立刻补满
func _check_minimum_enforcement():
	if _wave_enemy_types.is_empty() or _wave_minimum <= 0:
		return

	var alive = EnemyRegistry.get_count() if EnemyRegistry else 0
	var needed = _wave_minimum - alive
	if needed <= 0:
		return

	for _i in range(needed):
		var type_id = _wave_enemy_types[randi() % _wave_enemy_types.size()]
		var enemy = spawn_enemy_func.call(type_id)
		if is_instance_valid(enemy):
			enemy.is_wave_enemy = true


func _spawn_boss_if_needed():
	if _wave_boss_id < 0 or _wave_boss_spawned:
		return
	_wave_boss_spawned = true

	var enemy = spawn_enemy_func.call(_wave_boss_id)
	if is_instance_valid(enemy):
		enemy.is_wave_enemy = true


# ═══════════════════════════════════════════════════════════
#  地图事件（时间触发）
# ═══════════════════════════════════════════════════════════

func _process_map_events():
	if _map_events.is_empty() or _map_event_index >= _map_events.size():
		return

	var gs = game_state
	var game_sec = gs.game_time

	while _map_event_index < _map_events.size():
		var ev = _map_events[_map_event_index]
		var ev_time = ev.get("time", 0) * 60.0 + ev.get("delay", 0.0)
		if game_sec < ev_time:
			break
		_map_event_index += 1
		var chance = ev.get("chance", 1.0)
		if randf() > chance:
			continue
		_trigger_map_event(ev)


func _trigger_map_event(ev: Dictionary):
	var ev_type = ev.get("type", "")
	if ev_type.is_empty():
		return

	var count = ev.get("count", 1)
	var total = ev.get("total", count)
	var enemy_name = EVENT_ENEMY_MAP.get(ev_type, "")
	var type_id = _resolve_enemy_id(enemy_name)
	if type_id < 0:
		push_warning("WaveSystem: unknown event type '%s', no enemy mapped" % ev_type)
		return

	match ev_type:
		"medusa_wall", "flower_wall":
			_spawn_wall(type_id, total)
		"bat_swarm":
			_spawn_swarm(type_id, total)
		_:
			_spawn_burst(type_id, total)

	wave_event_triggered.emit(ev_type, ev)


# ═══════════════════════════════════════════════════════════
#  波次内事件
# ═══════════════════════════════════════════════════════════

func _process_wave_events(delta: float):
	if _wave_events.is_empty() or _wave_event_index >= _wave_events.size():
		return

	_wave_elapsed += delta
	while _wave_event_index < _wave_events.size():
		var ev = _wave_events[_wave_event_index]
		if _wave_elapsed < ev.get("delay", 0.0):
			break
		_wave_event_index += 1
		_trigger_map_event(ev)


static func _sort_by_wave_event_delay(a: Dictionary, b: Dictionary) -> bool:
	return a.get("delay", 0.0) < b.get("delay", 0.0)


# ═══════════════════════════════════════════════════════════
#  事件生成模式
# ═══════════════════════════════════════════════════════════

func _spawn_burst(type_id: int, count: int):
	var batch = mini(count, 8)
	for _i in range(batch):
		var e = spawn_enemy_func.call(type_id)
		if is_instance_valid(e):
			e.is_wave_enemy = false


func _spawn_wall(type_id: int, count: int):
	if not is_instance_valid(player) or not camera_ctrl or not camera_ctrl.has_method("get_camera_bounds"):
		_spawn_burst(type_id, count)
		return
	var bounds = camera_ctrl.get_camera_bounds()
	var side = randi() % 2
	var x = bounds.left - 80.0 if side == 0 else bounds.right + 80.0
	var spacing = (bounds.bottom - bounds.top) / max(count, 1)
	for i in range(count):
		var e = spawn_enemy_func.call(type_id)
		if is_instance_valid(e):
			e.is_wave_enemy = false
			e.global_position = Vector2(x, bounds.top + spacing * i + spacing * 0.5)


func _spawn_swarm(type_id: int, count: int):
	if not is_instance_valid(player) or not camera_ctrl or not camera_ctrl.has_method("get_camera_bounds"):
		_spawn_burst(type_id, count)
		return
	var bounds = camera_ctrl.get_camera_bounds()
	var side = randi() % 4
	var margin = 80.0
	var batch = mini(count, 10)
	for _i in range(batch):
		var e = spawn_enemy_func.call(type_id)
		if is_instance_valid(e):
			e.is_wave_enemy = false
			match side:
				0: e.global_position = Vector2(randf_range(bounds.left + margin, bounds.right - margin), bounds.top - margin)
				1: e.global_position = Vector2(randf_range(bounds.left + margin, bounds.right - margin), bounds.bottom + margin)
				2: e.global_position = Vector2(bounds.left - margin, randf_range(bounds.top + margin, bounds.bottom - margin))
				3: e.global_position = Vector2(bounds.right + margin, randf_range(bounds.top + margin, bounds.bottom - margin))


# ═══════════════════════════════════════════════════════════
#  通用逻辑
# ═══════════════════════════════════════════════════════════

func _resolve_enemy_id(name: String) -> int:
	if name.is_empty():
		return -1
	if ENEMY_NAME_MAP.has(name):
		return ENEMY_NAME_MAP[name]
	if name.is_valid_int():
		return name.to_int()
	push_warning("WaveSystem: unknown enemy name '%s', defaulting to type 0 (Wraith)" % name)
	return 0
