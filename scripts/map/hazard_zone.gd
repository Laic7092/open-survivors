extends Area2D
# Hazard zone — deals damage per second to anything inside.
# Affects both player AND enemies (can be used tactically).
#
# - Area2D that detects bodies on ENEMY and PLAYER layers
# - Configurable DPS, color, size
# - Visual: semi-transparent colored rectangle with animated edge
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
var _damage_timer: float = 0.0

# Whether this zone damages enemies too (makes it tactical)
var hurts_enemies: bool = true


func _ready():
	collision_layer = 0
	# Detect both player (layer 2) and enemies (layer 4)
	collision_mask = CollisionLayers.PLAYER | CollisionLayers.ENEMY
	
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = zone_size
	shape.shape = rect
	add_child(shape)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	add_to_group("hazard_zones")


func _draw():
	var half = zone_size / 2.0
	
	# Main hazard area
	draw_rect(Rect2(-half, zone_size), zone_color)
	
	# Animated edge pulse
	var pulse = sin(Time.get_ticks_msec() * 0.005) * 0.3 + 0.7
	var ec = Color(edge_color.r, edge_color.g, edge_color.b, edge_color.a * pulse)
	draw_rect(Rect2(-half, zone_size), ec, false, 2.0)
	
	# Hazard symbol (skull-ish mark)
	var sym_col = Color(1.0, 1.0, 1.0, 0.15 * pulse)
	draw_circle(Vector2.ZERO, min(zone_size.x, zone_size.y) * 0.15, sym_col)


func _process(delta):
	_damage_timer += delta
	
	# Tick damage every 0.5s
	if _damage_timer >= 0.5:
		_damage_timer = 0.0
		_tick_damage()
	
	# Redraw for animation
	queue_redraw()


func _tick_damage():
	# Clean up invalid bodies
	_bodies = _bodies.filter(func(b): return is_instance_valid(b) and is_inside_tree())
	
	for body in _bodies:
		if not is_instance_valid(body):
			continue
		
		# Damage player
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(dps * 0.5, global_position)  # 0.5 because tick is every 0.5s → DPS = dps
		
		# Damage enemies (tactical use)
		if hurts_enemies and body.is_in_group("enemies") and body.has_method("take_damage"):
			# Use call_deferred to avoid modifying the group mid-iteration
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
			var rect = RectangleShape2D.new()
			rect.size = zone_size
			c.shape = rect
			break
