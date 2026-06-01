extends Area2D
# Projectile fired by ranged enemies. Moves toward the player.
# Uses EnemyProjectilePool for reuse — no Timer child, process-based lifetime.

const CollisionLayers = preload("res://scripts/data/collision_layers.gd")

var target: Node2D:
	set(v):
		_target_ref = weakref(v) if v else null
var speed: float = 250.0
var damage: float = 10.0
var lifetime: float = 4.0

var _age: float = 0.0
var _direction: Vector2 = Vector2.ZERO
var _in_use: bool = false
var _target_ref: WeakRef = null


func _ready():
	collision_layer = CollisionLayers.ENEMY_PROJECTILE
	collision_mask = 0
	area_entered.connect(_on_area_entered)


func _physics_process(delta):
	if not _in_use:
		return
	var t = _target_ref.get_ref() if _target_ref else null
	if not t:
		_recycle()
		return

	_age += delta
	if _age >= lifetime:
		_recycle()
		return

	if _direction == Vector2.ZERO:
		_direction = (t.global_position - global_position).normalized()
		rotation = _direction.angle()

	global_position += _direction * speed * delta


func _draw():
	if not _in_use:
		return
	var r = 5.0
	draw_circle(Vector2.ZERO, r, Color(0.7, 0.2, 0.8, 0.9))
	draw_circle(Vector2.ZERO, r, Color(0.9, 0.3, 1.0, 0.6), false, 1.5)
	draw_circle(Vector2.ZERO, r * 0.4, Color(1.0, 0.8, 1.0, 0.8))
	var trail_col = Color(0.7, 0.2, 0.8, 0.3)
	var dir_vec = Vector2(cos(rotation), sin(rotation))
	draw_line(-dir_vec * r * 1.5, -dir_vec * r * 3.5, trail_col, 2.0)


func get_projectile_damage() -> float:
	return damage


func _on_area_entered(area: Area2D):
	if _in_use:
		_recycle()


# Called by ObjectPoolManager when borrowing from pool
func _pool_borrow(config: Dictionary = {}):
	target = config.get("target", null)
	speed = config.get("speed", 250.0)
	damage = config.get("damage", 10.0)
	lifetime = config.get("lifetime", 4.0)
	_age = 0.0
	_direction = Vector2.ZERO
	_in_use = true
	visible = true
	set_process(true)
	set_physics_process(true)
	collision_layer = CollisionLayers.ENEMY_PROJECTILE
	collision_mask = 0


func _recycle():
	_in_use = false
	visible = false
	set_process(false)
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	_target_ref = null
	if ObjectPoolManager:
		ObjectPoolManager.return_obj(self)
	else:
		queue_free()
