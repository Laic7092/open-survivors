extends Area2D
# Relic pickup entity — appears on a stage at a fixed position.
# Once touched, permanently unlocks the relic. Never reappears.

var relic_id: String = ""
var _collected: bool = false
var _pulse: float = 0.0

# Reference to player for arrow direction
var player_ref: Node2D

# _ft_scene removed — using FloatingTextPool


const CollisionLayers = preload("res://scripts/data/collision_layers.gd")


func _ready():
	collision_layer = 0
	collision_mask = CollisionLayers.MASK_PLAYER
	body_entered.connect(_on_body_entered)
	add_to_group("relics")
	
	# Auto-despawn timer (just in case)
	var timer = Timer.new()
	timer.wait_time = 600.0
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()
	
	# Floating bob + pulse animation via Tween — no _process needed
	var tw = create_tween().set_loops()
	tw.tween_property(self, "position:y", position.y - 6.0, 2.0)
	tw.tween_property(self, "position:y", position.y + 6.0, 2.0)
	
	var tw2 = create_tween().set_loops()
	tw2.tween_method(func(v): _pulse = v; queue_redraw(), 0.0, TAU, 2.0)
	tw2.tween_method(func(v): _pulse = v; queue_redraw(), TAU, TAU * 2.0, 2.0)


func initialize(id: String, player: Node2D):
	relic_id = id
	player_ref = player
	# Set up collision shape (circle area)
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 24.0
	shape.shape = circle
	add_child(shape)


func _on_body_entered(body: Node):
	if _collected:
		return
	if body == player_ref or body.is_in_group("player"):
		_collect()


func _collect():
	if _collected:
		return
	_collected = true
	
	# Mark as permanently collected
	if RelicManager.collect_relic(relic_id):
		# Show collection text
		var defs = preload("res://scripts/data/relic_defs.gd")
		var r = defs.get_relic(relic_id)
		var relic_name = r.get("name", "Relic")
		
		if is_inside_tree() and ObjectPoolManager:
			ObjectPoolManager.spawn_ft(get_parent(), global_position, "🔮 " + relic_name + " collected!", r.get("color", Color(0.9, 0.8, 0.2)), 22)
		
		# SFX
		AudioManager.play_sfx("evolution")
		
		# Visual effect: brief flash
		var flash = ColorRect.new()
		flash.color = Color(1, 1, 1, 0.8)
		flash.anchor_right = 1.0
		flash.anchor_bottom = 1.0
		flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if is_inside_tree():
			# Add to viewport for full-screen flash
			var ui_layer = _find_ui_layer()
			if ui_layer:
				ui_layer.add_child(flash)
				var tw = create_tween()
				tw.tween_property(flash, "modulate", Color(1, 1, 1, 0), 0.5)
				tw.finished.connect(flash.queue_free)
		
		# Remove from world — play a brief shrinking animation
		var tw2 = create_tween()
		tw2.set_parallel(true)
		tw2.tween_property(self, "scale", Vector2(2.0, 2.0), 0.2)
		tw2.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3)
		tw2.finished.connect(queue_free)


func _find_ui_layer() -> CanvasLayer:
	var parent = get_parent()
	while parent:
		if parent is CanvasLayer:
			return parent
		parent = parent.get_parent()
	return null


func _draw():
	if _collected:
		return
	
	var color = Color(0.4, 0.8, 0.3)  # relic green glow
	var pulse_alpha = 0.3 + sin(_pulse) * 0.15
	
	# Outer glow circle
	draw_circle(Vector2.ZERO, 28 + sin(_pulse) * 3, Color(color.r, color.g, color.b, 0.3 + sin(_pulse * 0.5) * 0.1))
	
	# Inner halo
	draw_circle(Vector2.ZERO, 20, Color(color.r, color.g, color.b, pulse_alpha * 0.3), false, 2.0)
	
	# Star/sparkle shape
	var s = 10.0
	var white = Color(1, 1, 1, 0.7 + sin(_pulse * 0.7) * 0.3)
	# Four-point star
	var star = PackedVector2Array([
		Vector2(0, -16),
		Vector2(4, -4),
		Vector2(16, 0),
		Vector2(4, 4),
		Vector2(0, 16),
		Vector2(-4, 4),
		Vector2(-16, 0),
		Vector2(-4, -4),
	])
	draw_polygon(star, [Color(color.r * 0.6, color.g * 1.0, color.b * 0.6, 0.8)])
	
	# Center diamond
	var dim = PackedVector2Array([
		Vector2(0, -6),
		Vector2(4, 0),
		Vector2(0, 6),
		Vector2(-4, 0),
	])
	draw_polygon(dim, [white])
	
	# Green arrow indicator (drawn toward bottom of screen pointing toward relic)
	# This is drawn in the HUD instead — see main.gd for the directional indicator
