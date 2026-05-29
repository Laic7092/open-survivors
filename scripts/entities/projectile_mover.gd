extends Node2D
# Lightweight projectile movement — replaces Tween for simple linear projectiles.
# Attach to any Area2D as a child or set as its script.
# Call set_movement() after adding to scene.

var _velocity: Vector2 = Vector2.ZERO
var _lifetime: float = 0.0
var _max_lifetime: float = 1.0
var _hit_registered: bool = false


func set_movement(vel: Vector2, max_life: float = 1.0):
	_velocity = vel
	_max_lifetime = max_life


func _physics_process(delta):
	if _hit_registered:
		return
	_lifetime += delta
	if _lifetime >= _max_lifetime:
		if is_inside_tree():
			get_parent().queue_free()
		return
	# Manual position update
	get_parent().global_position += _velocity * delta


func mark_hit():
	_hit_registered = true
