extends Node
# EnemyRegistry — autoload singleton
# Tracks all alive enemies via register/unregister.
# Replaces get_tree().get_nodes_in_group("enemies") hot path.

var _enemies: Array[Node] = []


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED


func register(e: Node):
	_enemies.append(e)


func unregister(e: Node):
	# Fast path: most removals are from the tail (recently added dies first)
	var idx = _enemies.find(e)
	if idx >= 0:
		_enemies.remove_at(idx)


func get_all() -> Array[Node]:
	return _enemies.duplicate()


# Fast path: returns reference, caller must NOT modify the array
func get_all_ref() -> Array[Node]:
	return _enemies


func is_empty() -> bool:
	return _enemies.is_empty()


func get_count() -> int:
	return _enemies.size()
