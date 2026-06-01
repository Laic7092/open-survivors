extends Node
# EnemyRegistry — autoload singleton (shim delegating to EnemyManager)
# All tracking is now in EnemyManager. This file provides backward compat.

signal boss_count_changed(count: int)

var is_crowded: bool = false
const CROWDED_THRESHOLD: int = 150

var _enemy_manager: Node = null


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED


func _get_mgr() -> Node:
	if _enemy_manager == null:
		_enemy_manager = _find_enemy_manager()
	return _enemy_manager


func _find_enemy_manager() -> Node:
	var tree = Engine.get_main_loop()
	if tree and tree.has_method("get_current_scene"):
		var scene = tree.get_current_scene()
		if scene:
			return scene.find_child("EnemyManager", true, false)
	return null


func register(_e: Node):
	pass  # managed by EnemyManager internally


func unregister(_e: Node):
	pass


func get_all() -> Array:
	var mgr = _get_mgr()
	if mgr and mgr.has_method("get_proxies"):
		return mgr.get_proxies()
	return []


func get_all_ref() -> Array:
	return get_all()


func is_empty() -> bool:
	var mgr = _get_mgr()
	return mgr.get_count() <= 0 if mgr else true


func get_count() -> int:
	var mgr = _get_mgr()
	return mgr.get_count() if mgr else 0


func get_boss_count() -> int:
	var mgr = _get_mgr()
	return mgr.get_boss_count() if mgr else 0
