extends Node
# WaveSystem — 波次生成系统
#
# 模式 1 — 数据驱动（主线关卡）
#   解析 stage_data.wave_defs，按游戏时间精确触发波次
#   每波从定义中读取敌人组合、间隔、Boss、事件
#   波间休息阶段维持 enemy_minimum
#
# 模式 2 — 程序化生成（无 wave_defs 的关卡回退）
#   波次规模随时间增长，敌人类型按阶段加权随机

const EnemyDefs = preload("res://scripts/data/enemy_defs.gd")
const GameState = preload("res://scripts/core/game_state.gd")

# 外部依赖：由 main.gd 注入
var game_state: GameState
var player: Node2D
var spawn_enemy_func: Callable  # func(type_id: int) -> Node2D

# ── 敌人名称 → 类型 ID 映射 ──
# wave_defs 中使用 Vampire Survivors 风格字符串 ID
# 映射到 enemy_defs.gd 中的数值 ID
const ENEMY_NAME_MAP := {
	"bat_r": 12,           # Red-Eyed Bat
	"bat_s": 11,           # Bat
	"bat_g": 14,           # Glowing Bat
	"bat_silver": 14,      # Glowing Bat（变体）
	"bat_giant": 13,       # Giant Bat
	"zombie": 8,           # Zombie
	"zombie_b": 8,         # Zombie（强）
	"skeleton": 9,         # Skeleton
	"skeleton_b": 9,       # Skeleton（强）
	"skeleton_r": 9,       # Skeleton（远程变体）
	"ghost": 10,           # Ghost
	"mudman": 15,          # Mudman
	"mudman_g": 16,        # Green Mudman
	"werewolf": 18,        # Werewolf
	"werewolf_giant": 18,  # Werewolf（巨型变体）
	"mantichana": 17,      # Mantichana
	"mantichana_giant": 17,# Mantichana（巨型）
	"mummy_big": 19,       # Big Mummy
	"mummy_giant": 19,     # Big Mummy（巨型）
	"flower_wall": 0,      # → Wraith（占位）
	"venus": 20,           # Venus
	"venus_blue_giant": 21,# Giant Blue Venus
	"reaper": 22,          # The Reaper
}

# ── 内部状态 ──
var _map_ready: bool = false
var _use_data_driven: bool = false

# 数据驱动状态
var _wave_defs: Array = []
var _next_wave_index: int = 0        # 下一个待触发的波次索引
var _spawn_queue: Array = []         # [{type_id, remaining}]
var _spawn_queue_pos: int = 0        # 当前消费位置
var _wave_spawn_interval: float = 0.0
var _wave_spawn_timer: float = 0.0
var _wave_boss_id: int = -1          # 当前波次 Boss 类型 ID
var _rest_timer: float = 0.5         # 波间休息计时
var _rest_spawn_cooldown: float = 0.0 # 维持最小敌人的冷却计时

# 程序化生成状态（fallback）
var _proc_wave_spawn_timer: float = 0.0
var _proc_rest_spawn_timer: float = 0.0

# ── 信号 ──
signal wave_started(wave_number: int)
signal wave_ended(wave_number: int)
signal elite_spawned
signal wave_event_triggered(event_type: String, event_data: Dictionary)


func setup(gs: GameState, p: Node2D, spawn_func: Callable):
	game_state = gs
	player = p
	spawn_enemy_func = spawn_func

	# 检测关卡是否定义了 wave_defs
	var stage_data = gs.stage_data
	if stage_data.has("wave_defs") and not stage_data["wave_defs"].is_empty():
		_use_data_driven = true
		_wave_defs = stage_data["wave_defs"].duplicate()
		# 按 time（分钟）升序排列，确保可靠顺序
		_wave_defs.sort_custom(_sort_by_time)


static func _sort_by_time(a: Dictionary, b: Dictionary) -> bool:
	return a.get("time", 0) < b.get("time", 0)


func set_map_ready(val: bool):
	_map_ready = val
	if val:
		_rest_timer = 0.5
		_proc_rest_spawn_timer = -1.0


func process(delta: float):
	if not _map_ready or game_state.game_over or game_state.stage_complete:
		return

	if _use_data_driven:
		_process_data_driven(delta)
	else:
		_process_procedural(delta)


# ═══════════════════════════════════════════════════════════
#  数据驱动模式
# ═══════════════════════════════════════════════════════════

func _process_data_driven(delta: float):
	var gs = game_state

	if gs.wave_active:
		# ── 波次进行中 ──
		# 波次系统自己不断生成敌人，不需要额外维持最小值
		if gs.wave_spawning:
			_wave_spawn_timer -= delta
			if _wave_spawn_timer <= 0.0:
				_spawn_queue_next()

		# 波次结束条件：全部生成完毕 + 全部击杀
		if not gs.wave_spawning and gs.wave_alive <= 0:
			_end_data_wave()
	else:
		# ── 休息阶段 ──
		_rest_timer -= delta

		# 每 0.3 秒检查一次最低敌人数量，避免每帧查 EnemyRegistry
		_rest_spawn_cooldown -= delta
		if _rest_spawn_cooldown <= 0.0:
			_rest_spawn_cooldown = 0.3
			_maintain_minimum_enemies()

		if _rest_timer <= 0.0:
			_try_trigger_next_wave()


# 检查并触发下一波
func _try_trigger_next_wave():
	var gs = game_state
	var game_sec = gs.game_time

	# 所有波次已触发 → 自由刷怪模式
	if _next_wave_index >= _wave_defs.size():
		_rest_timer = 0.5
		_spawn_free_mode_enemy()
		return

	var wd = _wave_defs[_next_wave_index]
	var wave_time_sec = wd.get("time", 0) * 60.0

	# 还没到时间
	if game_sec < wave_time_sec:
		_rest_timer = wave_time_sec - game_sec
		_rest_timer = clamp(_rest_timer, 0.05, 5.0)
		return

	# ── 触发波次 ──
	_next_wave_index += 1
	gs.wave_number += 1
	gs.wave_active = true
	gs.wave_spawning = true

	# 构建生成队列
	_spawn_queue.clear()
	_spawn_queue_pos = 0
	var total_count := 0
	var enemies = wd.get("enemies", [])
	for entry in enemies:
		var type_id = _resolve_enemy_id(entry.get("id", ""))
		if type_id < 0:
			continue
		var cnt = entry.get("count", 1)
		if cnt > 0:
			_spawn_queue.append({"type_id": type_id, "remaining": cnt})
			total_count += cnt

	gs.wave_total = total_count
	gs.wave_spawned = 0
	gs.wave_alive = total_count

	# 生成参数
	_wave_spawn_interval = wd.get("interval", 0.5)
	_wave_spawn_timer = 0.1  # 首帧快速启动

	# 波次元数据
	var boss_name = wd.get("boss", null)
	_wave_boss_id = _resolve_enemy_id(boss_name) if boss_name != null and boss_name != "" else -1

	wave_started.emit(gs.wave_number)


# 从队列生成下一批敌人
func _spawn_queue_next():
	var gs = game_state

	# 队列已空
	if _spawn_queue_pos >= _spawn_queue.size():
		gs.wave_spawning = false
		_spawn_boss_if_needed()
		return

	var entry = _spawn_queue[_spawn_queue_pos]
	var type_id = entry["type_id"]
	var batch = mini(entry["remaining"], 5)  # 每帧最多 5 只，防卡顿

	for _i in range(batch):
		var enemy = spawn_enemy_func.call(type_id)
		if is_instance_valid(enemy):
			enemy.is_wave_enemy = true
		gs.wave_spawned += 1

	entry["remaining"] -= batch
	if entry["remaining"] <= 0:
		_spawn_queue_pos += 1

	# 随机抖动间隔，产生不均匀的爆发感
	_wave_spawn_timer = _wave_spawn_interval * (0.7 + randf() * 0.6)

	# 如果已经生成完毕，立即停止
	if gs.wave_spawned >= gs.wave_total:
		gs.wave_spawning = false
		_spawn_boss_if_needed()


# 生成 Boss（如果当前波次有定义）
func _spawn_boss_if_needed():
	if _wave_boss_id < 0:
		return

	var enemy = spawn_enemy_func.call(_wave_boss_id)
	if is_instance_valid(enemy):
		enemy.is_wave_enemy = true
	_wave_boss_id = -1


# 结束当前数据波次
func _end_data_wave():
	var gs = game_state
	gs.wave_active = false
	_rest_timer = 0.3 + randf_range(0.0, 0.3)

	_spawn_elite_if_due()
	wave_ended.emit(gs.wave_number)


# 自由刷怪模式（所有波次已耗尽）
func _spawn_free_mode_enemy():
	var gs = game_state
	var pool = EnemyDefs.get_types_for_stage(gs._stage_id, gs.game_time)
	if pool.is_empty():
		pool = [0]
	var type_idx = EnemyDefs.pick_weighted(pool)
	var enemy = spawn_enemy_func.call(type_idx)
	if is_instance_valid(enemy):
		enemy.is_wave_enemy = true


# ═══════════════════════════════════════════════════════════
#  程序化生成模式（回退）
# ═══════════════════════════════════════════════════════════

func _process_procedural(delta: float):
	var gs = game_state

	if gs.wave_active:
		if gs.wave_spawning:
			_proc_wave_spawn_timer -= delta
			if _proc_wave_spawn_timer <= 0.0:
				_proc_spawn_wave_enemy()

		if _proc_rest_spawn_timer > 0:
			_proc_rest_spawn_timer -= delta
			if _proc_rest_spawn_timer <= 0.0:
				_proc_spawn_rest_enemy()

		if not gs.wave_spawning and gs.wave_alive <= 0:
			_proc_end_wave()
	else:
		gs.wave_break_timer -= delta
		if gs.wave_break_timer <= 0.0:
			_proc_start_wave()
		elif _proc_rest_spawn_timer > 0:
			_proc_rest_spawn_timer -= delta
			if _proc_rest_spawn_timer <= 0.0:
				_proc_spawn_rest_enemy()


func _proc_start_wave():
	var gs = game_state
	gs.wave_number += 1
	gs.wave_active = true
	gs.wave_spawning = true
	var base = gs.starting_spawns
	gs.wave_total = base + int(gs.game_time / 10.0 + gs.game_time * gs.game_time / 5000.0)
	gs.wave_spawned = 0
	gs.wave_alive = gs.wave_total
	_proc_wave_spawn_timer = 0.1
	wave_started.emit(gs.wave_number)


func _proc_spawn_wave_enemy():
	var gs = game_state
	var pool = EnemyDefs.get_types_for_stage(gs._stage_id, gs.game_time)
	if pool.is_empty():
		pool = [0]
	var type_idx = EnemyDefs.pick_weighted(pool)
	var enemy = spawn_enemy_func.call(type_idx)
	if is_instance_valid(enemy):
		enemy.is_wave_enemy = true
	gs.wave_spawned += 1
	_proc_wave_spawn_timer = 0.04
	if gs.wave_spawned >= gs.wave_total:
		gs.wave_spawning = false


func _proc_end_wave():
	var gs = game_state
	gs.wave_active = false
	gs.wave_break_timer = 0.1 + randf_range(0.0, 0.3)
	_proc_rest_spawn_timer = 0.05
	_spawn_elite_if_due()
	wave_ended.emit(gs.wave_number)


func _proc_spawn_rest_enemy():
	var gs = game_state
	_maintain_minimum_enemies()

	var pool = EnemyDefs.get_types_for_stage(gs._stage_id, gs.game_time)
	if pool.is_empty():
		pool = [0]
	var type_idx = EnemyDefs.pick_weighted(pool)
	spawn_enemy_func.call(type_idx)

	var rest_elapsed = 1.0 - gs.wave_break_timer / max(gs.wave_break_timer + _proc_rest_spawn_timer, 0.001)
	var base_interval = 0.1 - min(gs.game_time * 0.00002, 0.05)
	_proc_rest_spawn_timer = base_interval - rest_elapsed * 0.07


# ═══════════════════════════════════════════════════════════
#  通用逻辑
# ═══════════════════════════════════════════════════════════

# 维持场上最低敌人数量
func _maintain_minimum_enemies():
	var gs = game_state
	var alive = EnemyRegistry.get_count() if EnemyRegistry else 0
	var needed = gs.enemy_minimum
	if alive < needed:
		var pool = EnemyDefs.get_types_for_stage(gs._stage_id, gs.game_time)
		if pool.is_empty():
			pool = [0]
		for _i in range(needed - alive):
			var type_idx = EnemyDefs.pick_weighted(pool)
			spawn_enemy_func.call(type_idx)


# 精英生成判定
func _spawn_elite_if_due():
	var gs = game_state
	if gs.wave_number <= 0:
		return
	if gs.wave_number <= 12:
		if gs.wave_number % 3 == 0:
			_spawn_elite_enemy()
	else:
		_spawn_elite_enemy()


func _spawn_elite_enemy():
	var gs = game_state
	var pool = EnemyDefs.get_types_for_stage(gs._stage_id, gs.game_time)
	if pool.is_empty():
		pool = [0]
	var type_idx = EnemyDefs.pick_weighted(pool)
	var curse_bonus = 1.0 + gs.curse_level * 0.15
	var curse_mod = 1.0 + (player.get_curse() if is_instance_valid(player) else 0.0)
	var elite_bonus = 1.0 + gs.wave_number * 0.15 * curse_bonus

	var enemy = spawn_enemy_func.call(type_idx)
	if is_instance_valid(enemy):
		enemy.set_enemy_type(type_idx, gs.difficulty * curse_mod * elite_bonus)
		enemy.modulate = Color(2.0, 1.8, 0.6, 1.0)
		var tw = enemy.create_tween()
		tw.tween_property(enemy, "modulate", Color(1, 1, 1, 1), 0.4)
	elite_spawned.emit()


# 将 wave_defs 中的字符串 ID 解析为 enemy_defs.gd 的数值 ID
func _resolve_enemy_id(name: String) -> int:
	if name.is_empty():
		return -1
	if ENEMY_NAME_MAP.has(name):
		return ENEMY_NAME_MAP[name]
	if name.is_valid_int():
		return name.to_int()
	push_warning("WaveSystem: unknown enemy name '%s', defaulting to type 0 (Wraith)" % name)
	return 0
