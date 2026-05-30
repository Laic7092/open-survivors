extends Node
# WaveSystem — 波次生成系统
# 负责：波次计时、规模计算、精英生成、rest 阶段刷怪

const EnemyDefs = preload("res://scripts/data/enemy_defs.gd")
const GameState = preload("res://scripts/core/game_state.gd")

# 外部依赖：由 main.gd 注入
var game_state: GameState
var player: Node2D
var spawn_enemy_func: Callable  # func(type_id: int) -> Node2D

# 内部计时
var _wave_spawn_timer: float = 0.0
var _wave_break_timer: float = 0.0
var _rest_spawn_timer: float = -1.0
var _map_ready: bool = false

signal wave_started(wave_number: int)
signal wave_ended(wave_number: int)
signal elite_spawned


func setup(gs: GameState, p: Node2D, spawn_func: Callable):
	game_state = gs
	player = p
	spawn_enemy_func = spawn_func


func set_map_ready(val: bool):
	_map_ready = val
	if val:
		_wave_break_timer = 0.5  # 首次波次延迟
		_rest_spawn_timer = -1.0


func process(delta: float):
	if not _map_ready or game_state.game_over or game_state.stage_complete:
		return
	
	var gs = game_state
	
	if gs.wave_active:
		if gs.wave_spawning:
			gs.wave_spawn_timer -= delta
			if gs.wave_spawn_timer <= 0.0:
				_spawn_wave_enemy()
		# 波次中持续有零星刷怪
		if _rest_spawn_timer > 0:
			_rest_spawn_timer -= delta
			if _rest_spawn_timer <= 0.0:
				_spawn_rest_enemy()
		# 波次结束条件
		if not gs.wave_spawning and gs.wave_alive <= 0:
			_end_wave()
	else:
		# 休息阶段
		_wave_break_timer -= delta
		if _wave_break_timer <= 0.0:
			_start_wave()
		elif _rest_spawn_timer > 0:
			_rest_spawn_timer -= delta
			if _rest_spawn_timer <= 0.0:
				_spawn_rest_enemy()


func _start_wave():
	var gs = game_state
	gs.wave_number += 1
	gs.wave_active = true
	gs.wave_spawning = true
	# 波次规模：基数来自关卡 starting_spawns，随难度快速增长
	var base = gs.starting_spawns
	gs.wave_total = base + int(gs.game_time / 10.0 + gs.game_time * gs.game_time / 5000.0)
	gs.wave_spawned = 0
	gs.wave_alive = gs.wave_total
	gs.wave_spawn_timer = 0.1
	wave_started.emit(gs.wave_number)


func _spawn_wave_enemy():
	var gs = game_state
	var pool = EnemyDefs.get_types_for_stage(gs._stage_id, gs.game_time)
	if pool.is_empty():
		pool = [0]
	var type_idx = EnemyDefs.pick_weighted(pool)
	var enemy = spawn_enemy_func.call(type_idx)
	if is_instance_valid(enemy):
		enemy.is_wave_enemy = true
	gs.wave_spawned += 1
	gs.wave_spawn_timer = 0.04  # 快速爆发间隔
	if gs.wave_spawned >= gs.wave_total:
		gs.wave_spawning = false


func _end_wave():
	var gs = game_state
	gs.wave_active = false
	_wave_break_timer = 0.1 + randf_range(0.0, 0.3)
	_rest_spawn_timer = 0.05
	_spawn_elite_if_due()
	wave_ended.emit(gs.wave_number)


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


func _spawn_rest_enemy():
	var gs = game_state
	# 确保场上至少有 enemy_minimum 个敌人
	var alive_count = EnemyRegistry.get_count() if EnemyRegistry else 0
	var needed = gs.enemy_minimum
	if alive_count < needed:
		for i in range(needed - alive_count):
			var pool = EnemyDefs.get_types_for_stage(gs._stage_id, gs.game_time)
			if pool.is_empty():
				pool = [0]
			var type_idx = EnemyDefs.pick_weighted(pool)
			spawn_enemy_func.call(type_idx)
	
	var pool = EnemyDefs.get_types_for_stage(gs._stage_id, gs.game_time)
	if pool.is_empty():
		pool = [0]
	var type_idx = EnemyDefs.pick_weighted(pool)
	spawn_enemy_func.call(type_idx)
	
	# Rest 频率随时间加快
	var rest_elapsed = 1.0 - _wave_break_timer / max(_wave_break_timer + _rest_spawn_timer, 0.001)
	var base_interval = 0.1 - min(gs.game_time * 0.00002, 0.05)
	_rest_spawn_timer = base_interval - rest_elapsed * 0.07
