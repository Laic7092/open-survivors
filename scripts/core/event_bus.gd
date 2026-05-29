extends Node
# EventBus — 全局事件总线 + 运行时配置
# 替代 Engine.set_meta/get_meta 的跨模块通信方式
# 用法:
#   EventBus.stage_started.connect(...)
#   EventBus.set_config("stage_curse_level", 3)
#   var v = EventBus.get_config("stage_curse_level", 0)

# ═══════════════════════════════════════════════
#  游戏事件信号
# ═══════════════════════════════════════════════

signal stage_started(stage_data: Dictionary)
signal stage_completed(stage_id: int, time: float)
signal game_over(kills: int, level: int, time: float)
signal player_leveled_up(level: int)
signal enemy_killed(enemy_type: int, position: Vector2, is_boss: bool)
signal boss_spawned(boss_type: int)
signal curse_level_changed(level: int)
signal relic_collected(relic_id: String)
signal arcana_activated(arcana_id: int)
signal config_changed(key: String, value)

# ═══════════════════════════════════════════════
#  运行时配置存储（替代 Engine.set_meta/get_meta）
# ═══════════════════════════════════════════════

var _config: Dictionary = {}

func set_config(key: String, value):
	_config[key] = value
	config_changed.emit(key, value)

func get_config(key: String, default = null):
	return _config.get(key, default)

func has_config(key: String) -> bool:
	return _config.has(key)

func clear_config():
	_config.clear()

# ═══════════════════════════════════════════════
#  便利方法：关卡/模式配置
# ═══════════════════════════════════════════════

func set_stage_config(stage_data: Dictionary):
	set_config("selected_stage", stage_data)
	stage_started.emit(stage_data)

func set_character_config(char_data: Dictionary):
	set_config("selected_character", char_data)

func set_mode_flags(hurry: bool, hyper: bool, endless: bool, alt_music: bool, arcanas: bool):
	set_config("hurry_mode", hurry)
	set_config("hyper_mode", hyper)
	set_config("endless_mode", endless)
	set_config("alt_music", alt_music)
	set_config("arcanas_enabled", arcanas)

func get_stage_move_speed_mod() -> float:
	return get_config("stage_move_speed_mod", 1.0)

func get_stage_enemy_speed_mod() -> float:
	return get_config("stage_enemy_speed_mod", 1.0)

func get_stage_gold_mod() -> float:
	return get_config("stage_gold_mod", 1.0)

func get_stage_enemy_hp_mod() -> float:
	return get_config("stage_enemy_hp_mod", 1.0)

func get_curse_level() -> int:
	return get_config("stage_curse_level", 0)

func get_speed_mult() -> float:
	return get_config("stage_speed_mult", 1.0)


# ═══════════════════════════════════════════════════════════
#  延迟加载管理器注册表
# ═══════════════════════════════════════════════════════════

var _unlock_manager_ref: Node = null

func register_unlock_manager(node: Node):
	_unlock_manager_ref = node

func get_unlock_manager() -> Node:
	return _unlock_manager_ref
