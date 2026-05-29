extends Area2D
# Boost zone — grants temporary buffs while the player stands in it.
# Effects linger for a few seconds after leaving.
#
# Buff types:
#   "speed"  — +50% move speed
#   "might"  — +30% damage
#   "magnet" — +100% pickup range
#
# Add via setup() before adding to tree.

class_name BoostZone

const CollisionLayers = preload("res://scripts/data/collision_layers.gd")

# ── Config ──
var buff_type: String = "speed"
var buff_amount: float = 0.5       # 0.5 = +50%
var linger_duration: float = 3.0   # seconds buff persists after leaving
var zone_size: Vector2 = Vector2(80, 80)
var zone_color: Color = Color(0.1, 0.8, 0.3, 0.2)

# ── State ──
var _player_inside: bool = false
var _linger_timer: float = 0.0
var _active: bool = false
var _player_ref: Node2D = null
var _original_value: float = 0.0      # original stat value to restore


func _ready():
	collision_layer = 0
	collision_mask = CollisionLayers.PLAYER
	
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = zone_size
	shape.shape = rect
	add_child(shape)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	add_to_group("boost_zones")


func _draw():
	var half = zone_size / 2.0
	
	# Zone background
	draw_rect(Rect2(-half, zone_size), zone_color)
	
	# Animated glow when active
	var pulse = sin(Time.get_ticks_msec() * 0.004) * 0.2 + 0.8
	var glow_col = Color(zone_color.r * 1.5, zone_color.g * 1.5, zone_color.b * 1.5, 0.3 * pulse)
	draw_rect(Rect2(-half, zone_size), glow_col, false, 2.0)
	
	# Buff symbol
	var icon = ""
	var icon_color = Color.WHITE
	match buff_type:
		"speed": icon = "▶"; icon_color = Color(0.3, 0.8, 1.0)
		"might": icon = "⚔"; icon_color = Color(1.0, 0.3, 0.3)
		"magnet": icon = "◆"; icon_color = Color(1.0, 0.8, 0.2)
	
	# Simple colored icon shape instead of text (text requires font)
	var icon_r = min(zone_size.x, zone_size.y) * 0.12
	match buff_type:
		"speed":
			draw_circle(Vector2.ZERO, icon_r, Color(0.3, 0.8, 1.0, 0.4 * pulse))
			# Arrow-like triangle
			var tri = PackedVector2Array([
				Vector2(icon_r * 1.5, 0),
				Vector2(-icon_r * 0.8, -icon_r),
				Vector2(-icon_r * 0.8, icon_r)
			])
			draw_colored_polygon(tri, Color(0.3, 0.8, 1.0, 0.3 * pulse))
		"might":
			draw_circle(Vector2.ZERO, icon_r, Color(1.0, 0.3, 0.3, 0.4 * pulse))
			# Cross shape
			var cs = icon_r * 0.6
			draw_rect(Rect2(-cs * 0.25, -cs, cs * 0.5, cs * 2), Color(1.0, 0.3, 0.3, 0.3 * pulse))
			draw_rect(Rect2(-cs, -cs * 0.25, cs * 2, cs * 0.5), Color(1.0, 0.3, 0.3, 0.3 * pulse))
		"magnet":
			draw_circle(Vector2.ZERO, icon_r, Color(1.0, 0.8, 0.2, 0.4 * pulse))
			# Ring
			draw_circle(Vector2.ZERO, icon_r * 1.5, Color(1.0, 0.8, 0.2, 0.15 * pulse), false, 1.5)


func _process(delta):
	# Redraw for animation
	queue_redraw()
	
	if _player_inside:
		# Apply buff
		if not _active and _player_ref and is_instance_valid(_player_ref):
			_apply_buff(_player_ref)
			_active = true
		_linger_timer = linger_duration
	elif _active:
		# Linger timer
		if _linger_timer > 0.0:
			_linger_timer -= delta
		if _linger_timer <= 0.0:
			_remove_buff()
	elif _linger_timer > 0.0:
		_linger_timer -= delta
		if _linger_timer <= 0.0:
			_remove_buff()


func _apply_buff(player: Node2D):
	match buff_type:
		"speed":
			_original_value = player.move_speed
			player.move_speed = player.move_speed * (1.0 + buff_amount)
		"might":
			_original_value = player.damage_mult
			player.damage_mult = player.damage_mult * (1.0 + buff_amount)
		"magnet":
			_original_value = player.pickup_range
			player.pickup_range = player.pickup_range * (1.0 + buff_amount)


func _remove_buff():
	if not _active:
		return
	_active = false
	
	if _player_ref and is_instance_valid(_player_ref):
		match buff_type:
			"speed":
				_player_ref.move_speed = _original_value
			"might":
				_player_ref.damage_mult = _original_value
			"magnet":
				_player_ref.pickup_range = _original_value


func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		_player_inside = true
		_player_ref = body
		_linger_timer = linger_duration


func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		_player_inside = false
		# _linger_timer already set, buff stays until timer expires


func setup(b_type: String, amount: float, size: Vector2, color: Color):
	buff_type = b_type
	buff_amount = amount
	zone_size = size
	if color != Color.BLACK:
		zone_color = Color(color.r, color.g, color.b, 0.2)
	
	# Recreate collision shape with new size
	for c in get_children():
		if c is CollisionShape2D:
			var rect = RectangleShape2D.new()
			rect.size = zone_size
			c.shape = rect
			break
