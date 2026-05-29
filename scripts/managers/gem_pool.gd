extends Node

const GEM_SCENE = preload("res://scenes/xp_gem.tscn")
const CollisionLayers = preload("res://scripts/data/collision_layers.gd")
const POOL_SIZE := 64

var _available: Array = []


func _ready():
	for i in range(POOL_SIZE):
		var gem = GEM_SCENE.instantiate()
		gem.visible = false
		gem.process_mode = PROCESS_MODE_DISABLED
		gem.collision_layer = 0
		gem.collision_mask = 0
		gem.remove_from_group("gems")
		_available.append(gem)
		add_child(gem)


func borrow() -> Node:
	var gem
	if _available.is_empty():
		gem = GEM_SCENE.instantiate()
	else:
		gem = _available.pop_back()
		remove_child(gem)

	gem.collected = false
	gem.collision_layer = CollisionLayers.XP_GEM
	gem.collision_mask = CollisionLayers.MASK_PLAYER
	gem.visible = true
	gem.process_mode = PROCESS_MODE_INHERIT
	gem.add_to_group("gems")
	return gem


func return_gem(gem: Node):
	_reset_gem(gem)
	_available.append(gem)
	add_child(gem)


func _reset_gem(gem: Node):
	gem.get_parent().remove_child(gem)
	gem.visible = false
	gem.process_mode = PROCESS_MODE_DISABLED
	gem.collision_layer = 0
	gem.collision_mask = 0
	gem.attracted = false
	gem.player = null
	gem.value = 2
	gem.tier = 0
	gem.remove_from_group("gems")
