extends Node
class_name GameState
# GameState — 游戏运行时状态管理
# 从 main.gd 中拆分出的数据层，通过信号通知状态变化
# main.gd 持有此组件的引用并驱动其更新

signal game_over_final
signal stage_complete_final
signal boss_spawned_event
signal curse_level_changed(level: int)
signal difficulty_changed(value: float)

# ── 时间 & 进度 ──
var game_time: float = 0.0
var game_over: bool = false
var stage_complete: bool = false
var total_kills: int = 0
var difficulty: float = 1.0

# ── 关卡 ──
var stage_data: Dictionary = {}
var stage_time_limit: float = 1800.0
var stage_enemy_speed_mod: float = 1.0
var map_width: float = 3200.0
var map_height: float = 2400.0
var _stage_id: int = 0
var _diff_ramp_time: float = 60.0

# ── 波次 ──
var wave_number: int = 0
var wave_active: bool = false
var wave_spawning: bool = false
var wave_total: int = 0
var wave_spawned: int = 0
var wave_alive: int = 0
var wave_spawn_timer: float = 0.0
var wave_break_timer: float = 0.0
var rest_spawn_timer: float = 0.5

# ── Boss ──
var boss_spawned: bool = false

# ── 诅咒时刻 ──
var cursed_time_active: bool = false
var curse_level: int = 0
var curse_timer: float = 60.0

# ── 速度控制 ──
var speed_level: int = 0
const SPEED_VALUES: Array[float] = [1.0, 2.0, 3.0, 4.0]

# ── 相机抖动 ──
var shake_intensity: float = 0.0
var shake_duration: float = 0.0


func _init():
	pass


func reset():
	game_time = 0.0
	game_over = false
	stage_complete = false
	total_kills = 0
	difficulty = 1.0
	wave_number = 0
	wave_active = false
	wave_spawning = false
	wave_total = 0
	wave_spawned = 0
	wave_alive = 0
	wave_spawn_timer = 0.0
	wave_break_timer = 0.0
	rest_spawn_timer = -1.0
	boss_spawned = false
	cursed_time_active = false
	curse_level = 0
	curse_timer = 60.0
	speed_level = 0
	shake_intensity = 0.0
	shake_duration = 0.0


func set_stage_data(data: Dictionary):
	stage_data = data
	_stage_id = data.get("id", 0)
	_diff_ramp_time = data.get("difficulty_ramp_time", 60.0)
	stage_time_limit = data.get("time_limit", 1800.0)
	stage_enemy_speed_mod = data.get("enemy_speed_mod", 1.0)
	map_width = data.get("map_width", 3200.0)
	map_height = data.get("map_height", 2400.0)


func update_difficulty(delta: float):
	difficulty = 1.0 + game_time / _diff_ramp_time
	difficulty_changed.emit(difficulty)


func add_kill(count: int = 1):
	total_kills += count


func set_game_over():
	game_over = true
	game_over_final.emit()


func set_stage_complete():
	stage_complete = true
	stage_complete_final.emit()


func shake_camera(intensity: float, duration: float):
	shake_intensity = intensity
	shake_duration = duration
