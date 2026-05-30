extends Area2D
# Hazard zone — deals damage per second to anything inside.
# Affects both player AND enemies (can be used tactically).
#
# - Area2D that detects bodies on ENEMY and PLAYER layers
# - Configurable DPS, color, size
# - Visual: semi-transparent colored rectangle (node-based, no _draw)
#
# Add via setup() before adding to tree.

class_name HazardZone

const CollisionLayers = preload("res://scripts/data/collision_layers.gd")

# ── Config ──
var dps: float = 15.0
var zone_size: Vector2 = Vector2(100, 100)
var zone_color: Color = Color(0.8, 0.1, 0.05, 0.25)
var edge_color: Color = Color(0.9, 0.3, 0.1, 0.5)

# ── Active bodies ──
var _bodies: Array[Node2D] = []

# Whether this zone damages enemies too (makes it tactical)
var hurts_enemies: bool = true

# ── Visual nodes ──
var _bg_rect: ColorRect
var _border_rect: ColorRect
var _glow_rect: ColorRect


func _ready():
	collision_layer = 0
	# Detect both player (layer 2) and enemies (layer 4)
	collision_mask = CollisionLayers.PLAYER | CollisionLayers.ENEMY
	
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = zone_size
	shape.shape = rect
	add_child(shape)
	
	# Background fill (node-based, no _draw overhead)
	_bg_rect = ColorRect.new()
	_bg_rect.color = zone_color
	_bg_rect.size = zone_size
	_bg_rect.position = -zone_size / 2.0
	_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_rect)
	
	# Border edge
	_border_rect = ColorRect.new()
	_border_rect.color = edge_color
	_border_rect.size = zone_size
	_border_rect.position = -zone_size / 2.0
	_border_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_border_rect)
	
	# Damage tick timer (replaces _process accumulator)
	var tick_timer = Timer.new()
	tick_timer.wait_time = 0.5
	tick_timer.autostart = true
	tick_timer.timeout.connect(_tick_damage)
	add_child(tick_timer)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	add_to_group("hazard_zones")


func _tick_damage():
	# Manual cleanup — no array allocation (replaces _bodies.filter())
	var i = 0
	while i < _bodies.size():
		var body = _bodies[i]
		if not is_instance_valid(body) or not body.is_inside_tree():
			_bodies.remove_at(i)
			continue
		i += 1
	
	for body in _bodies:
		# Damage player
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(dps * 0.5, global_position)
		# Damage enemies (tactical use)
		if hurts_enemies and body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(dps * 0.5, global_position)


func _on_body_entered(body: Node2D):
	if not body or not is_instance_valid(body):
		return
	if body.has_method("take_damage") and not _bodies.has(body):
		_bodies.append(body)


func _on_body_exited(body: Node2D):
	_bodies.erase(body)


func setup(size: Vector2, damage_per_sec: float, color: Color, hurt_enemies: bool = true):
	zone_size = size
	dps = damage_per_sec
	zone_color = Color(color.r, color.g, color.b, 0.25)
	edge_color = Color(color.r * 1.2, color.g * 1.2, color.b * 1.2, 0.5)
	hurts_enemies = hurt_enemies
	
	# Recreate collision shape with new size
	for c in get_children():
		if c is CollisionShape2D:
			var rs = RectangleShape2D.new()
			rs.size = zone_size
			c.shape = rs
			break
	
	# Update visuals
	if _bg_rect:
		_bg_rect.size = zone_size
		_bg_rect.color = zone_color
		_bg_rect.position = -zone_size / 2.0
	if _border_rect:
		_border_rect.size = zone_size
		_border_rect.color = edge_color
		_border_rect.position = -zone_size / 2.0
