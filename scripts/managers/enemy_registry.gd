extends Node
# EnemyRegistry — autoload singleton
# Tracks all alive enemies via register/unregister.
# Dictionary-based for O(1) register/unregister performance.

signal boss_count_changed(count: int)

var is_crowded: bool = false
const CROWDED_THRESHOLD: int = 150

var _enemies: Dictionary = {}  # instance_id -> Node
var _boss_count: int = 0


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED


func register(e: Node):
	var id = e.get_instance_id()
	_enemies[id] = e
	if not is_crowded and _enemies.size() > CROWDED_THRESHOLD:
		is_crowded = true
	if e.has_method("get_is_boss") and e.get_is_boss():
		_boss_count += 1
		boss_count_changed.emit(_boss_count)


func unregister(e: Node):
	var id = e.get_instance_id()
	if _enemies.erase(id):
		if is_crowded and _enemies.size() <= CROWDED_THRESHOLD:
			is_crowded = false
		if e.has_method("get_is_boss") and e.get_is_boss():
			_boss_count = max(0, _boss_count - 1)
			boss_count_changed.emit(_boss_count)


func get_all() -> Array[Node]:
	return _enemies.values().duplicate()


# Fast path: returns values array (new allocation but no copy of references)
func get_all_ref() -> Array:
	return _enemies.values()


func is_empty() -> bool:
	return _enemies.is_empty()


func get_count() -> int:
	return _enemies.size()


func get_boss_count() -> int:
	return _boss_count
