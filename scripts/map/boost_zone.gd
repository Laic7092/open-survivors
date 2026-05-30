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
var _active: bool = false
var _player_ref: Node2D = null
var _original_value: float = 0.0  # original stat value to restore

# ── Visual nodes ──
var _bg_rect: ColorRect
var _border_rect: ColorRect
var _linger_timer: Timer


func _ready():
	collision_layer = 0
	collision_mask = CollisionLayers.PLAYER
	
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
	_border_rect.color = Color(zone_color.r * 1.5, zone_color.g * 1.5, zone_color.b * 1.5, 0.3)
	_border_rect.size = zone_size
	_border_rect.position = -zone_size / 2.0
	_border_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_border_rect)
	
	# Linger timer (replaces _process hand-rolled countdown)
	_linger_timer = Timer.new()
	_linger_timer.one_shot = true
	_linger_timer.timeout.connect(_remove_buff)
	add_child(_linger_timer)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	add_to_group("boost_zones")


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
		
		# Entering resets the linger timer
		if _linger_timer.is_stopped():
			_apply_buff(body)
			_active = true
		else:
			# Still in linger window — keep buff active, cancel removal
			_linger_timer.stop()
			if not _active:
				_apply_buff(body)
				_active = true


func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		_player_inside = false
		# Start linger countdown (buff stays until timer fires)
		# Guard: during scene cleanup the timer may not be in the tree
		if _active and _linger_timer.is_inside_tree():
			_linger_timer.start(linger_duration)


func setup(b_type: String, amount: float, size: Vector2, color: Color):
	buff_type = b_type
	buff_amount = amount
	zone_size = size
	if color != Color.BLACK:
		zone_color = Color(color.r, color.g, color.b, 0.2)
	
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
		_border_rect.color = Color(zone_color.r * 1.5, zone_color.g * 1.5, zone_color.b * 1.5, 0.3)
		_border_rect.size = zone_size
		_border_rect.position = -zone_size / 2.0
