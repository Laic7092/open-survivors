extends Node
# EnemyProjectilePool — autoload singleton
# Pools enemy projectile Area2D nodes to avoid constant instantiation/freeing.

const POOL_SIZE: int = 32


var _available: Array = []


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	for i in range(POOL_SIZE):
		var proj = _create_proj()
		_available.append(proj)
		add_child(proj)


func _create_proj():
	var scene = preload("res://scenes/enemy_projectile.tscn")
	var proj = scene.instantiate()
	proj.visible = false
	proj.set_process(false)
	proj.set_physics_process(false)
	proj.collision_layer = 0
	proj.collision_mask = 0
	return proj


func borrow(target: Node2D, speed: float, damage: float, lifetime: float) -> Node2D:
	var proj = _borrow_node()
	proj.reset(target, speed, damage, lifetime)
	# Only remove if it's our child (fallback nodes have no parent)
	if proj.get_parent() == self:
		remove_child(proj)
	return proj


func _borrow_node():
	while _available.size() > 0:
		var p = _available.pop_back()
		if is_instance_valid(p):
			return p
	# Fallback: create new
	return _create_proj()


func return_proj(proj: Node2D):
	if not is_instance_valid(proj):
		return
	if proj.get_parent():
		proj.get_parent().remove_child(proj)
	if _available.size() < POOL_SIZE:
		_available.append(proj)
		add_child(proj)
	else:
		proj.queue_free()
