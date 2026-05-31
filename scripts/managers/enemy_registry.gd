extends Node
# EnemyRegistry — autoload singleton
# Tracks all alive enemies via register/unregister.
# Replaces get_tree().get_nodes_in_group("enemies") hot path.

signal boss_count_changed(count: int)

var is_crowded: bool = false
const CROWDED_THRESHOLD: int = 150

var _enemies: Array[Node] = []
var _boss_count: int = 0


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED


func register(e: Node):
	_enemies.append(e)
	if not is_crowded and _enemies.size() > CROWDED_THRESHOLD:
		is_crowded = true
	if e.has_method("get_is_boss") and e.get_is_boss():
		_boss_count += 1
		boss_count_changed.emit(_boss_count)


func unregister(e: Node):
	var idx = _enemies.rfind(e)
	if idx >= 0:
		_enemies.remove_at(idx)
	if is_crowded and _enemies.size() <= CROWDED_THRESHOLD:
		is_crowded = false
	if e.has_method("get_is_boss") and e.get_is_boss():
		_boss_count = max(0, _boss_count - 1)
		boss_count_changed.emit(_boss_count)


func get_all() -> Array[Node]:
	return _enemies.duplicate()


# Fast path: returns reference, caller must NOT modify the array
func get_all_ref() -> Array[Node]:
	return _enemies


func is_empty() -> bool:
	return _enemies.is_empty()


func get_count() -> int:
	return _enemies.size()


func get_boss_count() -> int:
	return _boss_count
