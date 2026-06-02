extends Node2D
# Generic bounce component for projectiles.
# Attach as a child of any projectile that bounces off screen edges.
# Configure meta keys, max bounces, and optional bounce callback.

# Meta keys
var direction_meta: String = "bounce_dir"
var speed_meta: String = "bounce_speed"
var bounce_count_meta: String = "bounce_count"

var max_bounces: int = 6
var visuals_node: String = "Visuals"
# callback(pos: Vector2, projectile_parent: Node) — called on each bounce
var on_bounce: Callable

var _bounce_left: float = 0.0
var _bounce_right: float = 0.0
var _bounce_top: float = 0.0
var _bounce_bottom: float = 0.0

var _bounds_timer: float = 0.0
var _bounds_interval: float = 0.5

var _player: Node2D = null


func _ready():
	var proj = get_parent()
	_player = _find_player(proj)
	_refresh_bounds()


func _find_player(proj: Node2D) -> Node2D:
	var p = proj.get_parent().get_node_or_null("Player")
	if p:
		return p
	return proj.get_parent().get_node_or_null("../Player")


func _process(delta):
	var proj = get_parent()
	if not is_instance_valid(proj):
		_cleanup()
		return

	_tick(proj, delta)


func _refresh_bounds():
	var vp = get_viewport()
	var cam = vp.get_camera_2d() if vp else null
	if not cam:
		return

	var vp_size = vp.get_visible_rect().size
	var cam_pos = cam.global_position

	var speed_bonus = 0.0
	if is_instance_valid(_player) and _player.has_method(&"get_speed_mult"):
		speed_bonus = _player.speed_mult

	_bounce_left = cam_pos.x - vp_size.x / 2
	_bounce_right = cam_pos.x + vp_size.x / 2
	_bounce_top = cam_pos.y - vp_size.y / 2
	_bounce_bottom = cam_pos.y + vp_size.y / 2


func _tick(proj: Node2D, delta: float):
	var dir: Vector2 = proj.get_meta(direction_meta, Vector2.DOWN)
	var speed: float = proj.get_meta(speed_meta, 400.0)
	var bounces: int = proj.get_meta(bounce_count_meta, 0)

	proj.global_position += dir * speed * delta

	var vis = proj.get_node_or_null(visuals_node)
	if vis:
		vis.rotation = dir.angle()

	_bounds_timer += delta
	if _bounds_timer >= _bounds_interval:
		_bounds_timer = 0.0
		_refresh_bounds()

	var bounced = false

	if proj.global_position.x < _bounce_left:
		proj.global_position.x = _bounce_left
		dir.x = abs(dir.x)
		bounced = true
	elif proj.global_position.x > _bounce_right:
		proj.global_position.x = _bounce_right
		dir.x = -abs(dir.x)
		bounced = true

	if proj.global_position.y < _bounce_top:
		proj.global_position.y = _bounce_top
		dir.y = abs(dir.y)
		bounced = true
	elif proj.global_position.y > _bounce_bottom:
		proj.global_position.y = _bounce_bottom
		dir.y = -abs(dir.y)
		bounced = true

	if bounced:
		bounces += 1
		proj.set_meta(direction_meta, dir)
		proj.set_meta(bounce_count_meta, bounces)
		if on_bounce.is_valid():
			on_bounce.call(proj.global_position, proj.get_parent())

	if bounces >= max_bounces:
		_cleanup()


func _cleanup():
	var proj = get_parent()
	if is_instance_valid(proj):
		proj.queue_free()
	queue_free()
