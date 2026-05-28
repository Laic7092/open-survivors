extends Area2D

var value: int = 2
var player: Node2D
var attracted: bool = false
var collected: bool = false
var float_offset: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready():
	collision_layer = 16
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	add_to_group("gems")


func _process(delta):
	if is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < player.pickup_range:
			attracted = true
	if attracted and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		global_position += dir * 300.0 * delta
	float_offset += delta * 2.0
	queue_redraw()


func collect() -> int:
	if collected:
		return 0
	collected = true
	var v = value
	queue_free()
	return v


func _on_body_entered(body: Node):
	if body == player:
		player.add_xp(collect())


func _draw():
	var sz = 5
	var c = Color(0.9, 0.85, 0.1)
	var off = Vector2(0, sin(float_offset) * 4)
	draw_circle(off, sz, c)
