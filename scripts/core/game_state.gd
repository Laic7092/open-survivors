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
signal kills_changed(total_kills: int)

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
var stage_projectile_speed_mod: float = 1.0
var stage_xp_mod: float = 1.0
var stage_gold_mod: float = 1.0
var stage_luck_mod: float = 0.0
var stage_enemy_hp_mod: float = 1.0
var starting_spawns: int = 10
var enemy_minimum: int = 1
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
	starting_spawns = 10
	enemy_minimum = 1


func set_stage_data(data: Dictionary):
	stage_data = data
	_stage_id = data.get("id", 0)
	_diff_ramp_time = data.get("difficulty_ramp_time", 60.0)
	stage_time_limit = data.get("time_limit", 1800.0)
	stage_enemy_speed_mod = data.get("enemy_speed_mod", 1.0)
	stage_projectile_speed_mod = data.get("projectile_speed_mod", 1.0)
	stage_xp_mod = data.get("xp_mod", 1.0)
	stage_gold_mod = data.get("gold_mod", 1.0)
	stage_luck_mod = data.get("luck_mod", 0.0)
	stage_enemy_hp_mod = data.get("enemy_hp_mod", 1.0)
	starting_spawns = data.get("starting_spawns", 10)
	enemy_minimum = data.get("enemy_minimum", 1)
	map_width = data.get("map_width", 3200.0)
	map_height = data.get("map_height", 2400.0)


func update_difficulty(delta: float):
	difficulty = 1.0 + game_time / _diff_ramp_time
	difficulty_changed.emit(difficulty)


# ═══════════════════════════════════════════════
#  统一难度计算（集中敌人属性缩放公式）
# ═══════════════════════════════════════════════

# 给定基础值和 diff factor，计算缩放后的敌人属性
# diff_factor = difficulty - 1.0（由 spawn 侧传入，已包含 curse_mod + wave_bonus）
# curse_level 由 Cursed Time 系统提供

static func calc_enemy_hp(base_hp: float, diff_factor: float, curse_level: int) -> float:
	var diff_sq = diff_factor * diff_factor
	var hp = base_hp * (1.0 + diff_factor * 0.2 + diff_sq * 0.015)
	if curse_level > 0:
		hp *= (1.0 + curse_level * 0.15)
	return hp


static func calc_enemy_damage(base_dmg: float, diff_factor: float, curse_level: int) -> float:
	var dmg = base_dmg * (1.0 + diff_factor * 0.08)
	if curse_level > 0:
		dmg *= (1.0 + curse_level * 0.15 * 0.75)
	return dmg


static func calc_enemy_speed(base_speed: float, diff_factor: float, curse_level: int) -> float:
	var speed = base_speed * (1.0 + diff_factor * 0.08)
	if curse_level > 0:
		speed *= (1.0 + curse_level * 0.5 * 0.5)
	return speed


func add_kill(count: int = 1):
	total_kills += count
	kills_changed.emit(total_kills)


func set_game_over():
	game_over = true
	game_over_final.emit()


func set_stage_complete():
	stage_complete = true
	stage_complete_final.emit()


func shake_camera(intensity: float, duration: float):
	shake_intensity = intensity
	shake_duration = duration
