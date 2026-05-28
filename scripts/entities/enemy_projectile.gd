extends Area2D
# Projectile fired by ranged enemies. Moves toward the player.
# Collision layer 8 — player hurtbox must mask layer 8 to take damage.

var target: Node2D          # player reference
var speed: float = 250.0
var damage: float = 10.0
var lifetime: float = 4.0   # auto-despawn after this long

var _age: float = 0.0
var _direction: Vector2 = Vector2.ZERO


func _ready():
	collision_layer = 8
	collision_mask = 2       # hit player body (hurtbox checks body_entered)
	body_entered.connect(_on_body_entered)
	
	# Auto-despawn timeout
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
	
	# Lock direction on first frame, then fly straight (no homing)
	if _direction == Vector2.ZERO:
		_direction = (target.global_position - global_position).normalized()
	
	global_position += _direction * speed * delta
	
	# Face movement direction for rotation-based visuals
	rotation = _direction.angle()


func _draw():
	# Glowing purple bolt visual
	var r = 5.0
	draw_circle(Vector2.ZERO, r, Color(0.7, 0.2, 0.8, 0.9))
	draw_circle(Vector2.ZERO, r, Color(0.9, 0.3, 1.0, 0.6), false, 1.5)
	# Inner bright core
	draw_circle(Vector2.ZERO, r * 0.4, Color(1.0, 0.8, 1.0, 0.8))
	# Motion trail lines
	var trail_col = Color(0.7, 0.2, 0.8, 0.3)
	var dir_vec = Vector2(cos(rotation), sin(rotation))
	draw_line(-dir_vec * r * 1.5, -dir_vec * r * 3.5, trail_col, 2.0)


# Called by player hurtbox when collision_mask matches (layer 8 → mask 8)
func get_projectile_damage() -> float:
	return damage


func _on_body_entered(body: Node):
	if not is_instance_valid(body):
		return
	# Damage the player via their hurt pathway
	if body.has_method("_on_hurt"):
		body._on_hurt(self)
	queue_free()
