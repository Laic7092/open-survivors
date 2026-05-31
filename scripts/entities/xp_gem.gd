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


# Called by ObjectPoolManager when borrowing from pool
func _pool_borrow(config: Dictionary = {}):
	collision_layer = CollisionLayers.XP_GEM
	collision_mask = CollisionLayers.MASK_PLAYER
	add_to_group("gems")
	visible = true
	process_mode = PROCESS_MODE_INHERIT
	collected = false
	attracted = false
	player = config.get("player", null)
	value = config.get("value", 2)
	tier = config.get("tier", Tier.BLUE)


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
		var val = collect()
		if val > 0:
			player.add_xp(val)


func _return_to_pool():
	ObjectPoolManager.return_obj(self)


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
