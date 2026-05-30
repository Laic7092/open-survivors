extends Area2D

const CollisionLayers = preload("res://scripts/data/collision_layers.gd")

enum Tier { BLUE, GREEN, RED }

var tier: int = Tier.BLUE:
	set(v):
		if tier != v:
			tier = v
			if is_inside_tree():
				queue_redraw()
var value: int = 2:
	set(v):
		if value != v:
			value = v
			if is_inside_tree():
				queue_redraw()
var player: Node2D
var attracted: bool = false
var collected: bool = false
var attract_speed: float = 300.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready():
	collision_layer = CollisionLayers.XP_GEM
	collision_mask = CollisionLayers.MASK_PLAYER
	body_entered.connect(_on_body_entered)
	add_to_group("gems")
	queue_redraw()


var _throttle_offset: int = 0

func _process(delta):
	if is_instance_valid(player):
		# Distribute throttled checks across frames — each gem checks on a different frame
		if attracted or (Engine.get_frames_drawn() + _throttle_offset) % 4 == 0 or not _far_from_player():
			var dist = global_position.distance_to(player.global_position)
			if dist < player.pickup_range:
				attracted = true
	if attracted and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		global_position += dir * attract_speed * delta


var _player_last_check_pos: Vector2 = Vector2.ZERO
func _far_from_player() -> bool:
	if not is_instance_valid(player):
		return true
	var ppos = player.global_position
	var dx = global_position.x - ppos.x
	var dy = global_position.y - ppos.y
	return (dx * dx + dy * dy) > 40000.0  # 200px^2


func collect() -> int:
	if collected:
		return 0
	collected = true
	AudioManager.play_sfx("pickup_xp")
	var v = value
	call_deferred("_return_to_pool")
	return v


func _on_body_entered(body: Node):
	if body == player:
		collect()


func _return_to_pool():
	ObjectPoolManager.return_gem(self)


func _draw():
	match tier:
		Tier.BLUE:
			draw_circle(Vector2.ZERO, 5, Color(0.3, 0.6, 1.0))
		Tier.GREEN:
			draw_circle(Vector2.ZERO, 8, Color(0.2, 0.85, 0.3))
			draw_circle(Vector2.ZERO, 10, Color(0.2, 0.85, 0.3, 0.25))
		Tier.RED:
			draw_circle(Vector2.ZERO, 12, Color(0.95, 0.25, 0.2))
			draw_circle(Vector2.ZERO, 14, Color(0.95, 0.25, 0.2, 0.3))
			draw_circle(Vector2.ZERO, 18, Color(0.95, 0.3, 0.25, 0.12))
