extends Area2D

const CollisionLayers = preload("res://scripts/data/collision_layers.gd")

var value: int = 2
var player: Node2D
var attracted: bool = false
var collected: bool = false
var float_offset: float = 0.0
var attract_speed: float = 300.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready():
	collision_layer = CollisionLayers.XP_GEM
	collision_mask = CollisionLayers.MASK_PLAYER
	body_entered.connect(_on_body_entered)
	add_to_group("gems")


func _process(delta):
	if is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < player.pickup_range:
			attracted = true
	if attracted and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		global_position += dir * attract_speed * delta
	float_offset += delta * 2.0
	queue_redraw()


func collect() -> int:
	if collected:
		return 0
	collected = true
	AudioManager.play_sfx("pickup_xp")
	var v = value
	queue_free()
	return v


func _on_body_entered(body: Node):
	if body == player:
		player.add_xp(collect())


func _draw():
	var off = Vector2(0, sin(float_offset) * 4)
	if value <= 4:
		# Blue — small
		draw_circle(off, 5, Color(0.3, 0.6, 1.0))
	elif value <= 10:
		# Green — medium
		draw_circle(off, 8, Color(0.2, 0.85, 0.3))
		draw_circle(off, 10, Color(0.2, 0.85, 0.3, 0.25))
	else:
		# Red — large, with glow
		draw_circle(off, 12, Color(0.95, 0.25, 0.2))
		draw_circle(off, 14, Color(0.95, 0.25, 0.2, 0.3))
		draw_circle(off, 18, Color(0.95, 0.3, 0.25, 0.12))
