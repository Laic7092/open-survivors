extends Area2D
# Projectile fired by ranged enemies. Moves toward the player.
# Collides with player hurtbox via area_entered (player hurtbox masks layer 8).

const CollisionLayers = preload("res://scripts/data/collision_layers.gd")

var target: Node2D
var speed: float = 250.0
var damage: float = 10.0
var lifetime: float = 4.0

var _age: float = 0.0
var _direction: Vector2 = Vector2.ZERO


func _ready():
	collision_layer = CollisionLayers.ENEMY_PROJECTILE
	collision_mask = 0
	# Detect the player's hurtbox (an Area2D masking layer 8) to self-destruct on hit.
	# Damage is delivered by the player's hurtbox _on_hurt_area handler.
	area_entered.connect(_on_area_entered)

	var t = Timer.new()
	t.wait_time = lifetime
	t.one_shot = true
	t.timeout.connect(queue_free)
	add_child(t)
	t.start()


func _physics_process(delta):
	if not is_instance_valid(target):
		queue_free()
		return

	if _direction == Vector2.ZERO:
		_direction = (target.global_position - global_position).normalized()

	global_position += _direction * speed * delta
	rotation = _direction.angle()


func _draw():
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
	# Hit the player's hurtbox — self-destruct. Damage is handled by player.
	queue_free()
