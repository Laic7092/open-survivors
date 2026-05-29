extends Area2D

enum PickupType { CHICKEN, GOLD, ROSARY, VACUUM }

var type: int = PickupType.CHICKEN
var player: Node2D
var collected: bool = false
var float_offset: float = 0.0

# _ft_scene removed — using FloatingTextPool


const CollisionLayers = preload("res://scripts/data/collision_layers.gd")


func _ready():
	collision_layer = CollisionLayers.PICKUP
	collision_mask = CollisionLayers.MASK_PLAYER
	body_entered.connect(_on_body_entered)
	add_to_group("pickups")

	# Auto-despawn after 25 seconds
	var timer = Timer.new()
	timer.wait_time = 25.0
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()


func _process(delta):
	float_offset += delta * 2.0
	# Only redraw every 4 frames to reduce overhead
	if Engine.get_frames_drawn() % 4 == 0:
		queue_redraw()


func _on_body_entered(body: Node):
	if body == player and not collected:
		apply_effect()


func _show_text(txt: String, col: Color, sz: int = 16):
	if is_inside_tree() and ObjectPoolManager:
		ObjectPoolManager.spawn_ft(get_parent(), global_position, txt, col, sz)


func apply_effect():
	if collected:
		return
	collected = true

	match type:
		PickupType.CHICKEN:
			_show_text(I18N.t("pickup.chicken"), Color(0.3, 1.0, 0.3))
			AudioManager.play_sfx("pickup_chicken")
			if player.has_method("heal"):
				player.heal(30.0)
		PickupType.GOLD:
			_show_text(I18N.t("pickup.gold"), Color(0.9, 0.8, 0.1))
			AudioManager.play_sfx("pickup_gold")
			# Apply greed multiplier (Stone Mask + permanent PowerUp)
			var greed_mult = 1.0
			if is_instance_valid(player) and player.has_method("get_greed_mult"):
				greed_mult = player.get_greed_mult()
			PowerUpManager.add_run_gold(int(10 * greed_mult))
		PickupType.ROSARY:
			_show_text(I18N.t("pickup.rosary"), Color(0.3, 0.5, 1.0), 20)
			AudioManager.play_sfx("pickup_rosary")
			for e in get_tree().get_nodes_in_group("enemies"):
				if is_instance_valid(e) and e.has_method("die"):
					e.die()
		PickupType.VACUUM:
			_show_text(I18N.t("pickup.vacuum"), Color(0.2, 0.8, 0.9), 20)
			AudioManager.play_sfx("pickup_vacuum")
			for g in get_tree().get_nodes_in_group("gems"):
				if is_instance_valid(g):
					g.attracted = true
	queue_free()


func _draw():
	var off = Vector2(0, sin(float_offset) * 3)
	match type:
		PickupType.CHICKEN:
			draw_circle(off, 8, Color(0.9, 0.15, 0.15))
			draw_circle(off, 8, Color(1, 0.3, 0.3), false, 1.5)
			draw_line(off + Vector2(-3, 0), off + Vector2(3, 0), Color.WHITE, 2.0)
			draw_line(off + Vector2(0, -3), off + Vector2(0, 3), Color.WHITE, 2.0)

		PickupType.GOLD:
			var d = PackedVector2Array([
				off + Vector2(0, -8), off + Vector2(6, 0),
				off + Vector2(0, 8), off + Vector2(-6, 0)
			])
			draw_polygon(d, [Color(0.9, 0.8, 0.1)])

		PickupType.ROSARY:
			draw_circle(off, 8, Color(0.2, 0.3, 0.9))
			draw_arc(off, 8, 0, TAU, 12, Color(0.5, 0.6, 1.0), 2.0)
			draw_line(off + Vector2(-3, -3), off + Vector2(3, 3), Color.WHITE, 2.0)
			draw_line(off + Vector2(3, -3), off + Vector2(-3, 3), Color.WHITE, 2.0)

		PickupType.VACUUM:
			var d2 = PackedVector2Array([
				off + Vector2(0, -8), off + Vector2(6, 0),
				off + Vector2(0, 8), off + Vector2(-6, 0)
			])
			draw_polygon(d2, [Color(0.2, 0.8, 0.9, 0.8)])
			draw_circle(off, 4, Color(0.5, 0.9, 1.0))
