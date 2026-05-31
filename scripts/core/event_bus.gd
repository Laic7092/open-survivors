extends Node
# EventBus — 全局事件总线 + 运行时配置
# 替代 Engine.set_meta/get_meta 的跨模块通信方式
# 用法:
#   EventBus.stage_started.connect(...)
#   EventBus.set_config("selected_stage", stage_data)
#   EventBus.set_config("hurry_mode", true)
#   EventBus.get_config("selected_character", {})

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

# Unlock system events
signal weapon_upgraded(weapon_type: int, level: int)
signal item_evolved(weapon_type: int)
signal light_source_destroyed()

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


# ═══════════════════════════════════════════════
#  便捷查询：模式标志
# ═══════════════════════════════════════════════

func is_mode_enabled(mode: String) -> bool:
	return get_config(mode + "_mode", false) or false
