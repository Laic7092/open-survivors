extends Node
# ProjectilePool — autoload singleton
# Pools common Area2D + CollisionShape2D pairs for player projectiles.
# Reuses nodes instead of creating/freeing them every weapon fire.

const POOL_SIZE: int = 48
const PROJ_SCENE = preload("res://scenes/enemy_projectile.tscn")

var _available: Array = []


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	for i in range(POOL_SIZE):
		var proj = _create_proj()
		_available.append(proj)
		add_child(proj)


func _create_proj() -> Area2D:
	var p = Area2D.new()
	p.collision_mask = 4  # ENEMY layer
	var s = CollisionShape2D.new()
	var c = CircleShape2D.new()
	c.radius = 10.0
	s.shape = c
	p.add_child(s)
	p.visible = false
	p.set_process(false)
	p.set_physics_process(false)
	return p


func borrow(radius: float) -> Area2D:
	var p: Area2D
	while _available.size() > 0:
		p = _available.pop_back()
		if is_instance_valid(p):
			# Update collision shape radius
			var shape_node = p.get_child(0)
			if shape_node and shape_node.shape is CircleShape2D:
				shape_node.shape.radius = radius
			# Reset state
			p.visible = true
			p.set_process(true)
			p.set_physics_process(true)
			# Remove from pool container
			remove_child(p)
			return p
	# Fallback: create new
	p = _create_proj()
	var shape_node = p.get_child(0)
	if shape_node and shape_node.shape is CircleShape2D:
		shape_node.shape.radius = radius
	p.visible = true
	p.set_process(true)
	p.set_physics_process(true)
	return p


func return_proj(p: Area2D):
	if not is_instance_valid(p):
		return
	if p.get_parent():
		p.get_parent().remove_child(p)
	# Clear signals to avoid stale connections
	p.body_entered.disconnect_all()
	# Reset
	p.visible = false
	p.set_process(false)
	p.set_physics_process(false)
	p.collision_mask = 4
	if _available.size() < POOL_SIZE:
		_available.append(p)
		add_child(p)
	else:
		p.queue_free()
