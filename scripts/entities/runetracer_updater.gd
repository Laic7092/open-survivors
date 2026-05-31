extends Node2D
# RuneTracer 更新器（极简版）
# 弹跳边界跟随玩家位置滞后更新（每 0.5s），不走场景树

# 弹跳边界（世界坐标，定时刷新）
var _bounce_left: float = 0.0
var _bounce_right: float = 0.0
var _bounce_top: float = 0.0
var _bounce_bottom: float = 0.0

# 边界刷新计时
var _bounds_timer: float = 0.0
var _bounds_interval: float = 0.5

# 缓存的玩家引用
var _player: Node2D = null


func _ready():
	var proj = get_parent()
	# 缓存玩家引用
	_player = _find_player(proj)
	# 初始边界
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

	_on_runetracer_tick(proj, delta)


func _refresh_bounds():
	var vp = get_viewport()
	var cam = vp.get_camera_2d() if vp else null
	if not cam:
		return

	var vp_size = vp.get_visible_rect().size
	var cam_pos = cam.global_position

	# 移速加成：有缓存 player 则取 speed_mult
	var speed_bonus = 0.0
	if is_instance_valid(_player) and _player.has_method(&"get_speed_mult"):
		speed_bonus = _player.speed_mult

	var margin = 60.0 + speed_bonus * 40.0

	_bounce_left = cam_pos.x - vp_size.x / 2.0 - margin
	_bounce_right = cam_pos.x + vp_size.x / 2.0 + margin
	_bounce_top = cam_pos.y - vp_size.y / 2.0 - margin
	_bounce_bottom = cam_pos.y + vp_size.y / 2.0 + margin


func _bounce_effect(pos: Vector2, parent: Node):
	var ring = ColorRect.new()
	ring.color = Color(0.95, 0.85, 1.0, 0.8)
	var rs = 16.0
	ring.size = Vector2.ONE * rs
	ring.global_position = pos - ring.size / 2
	ring.rotation = deg_to_rad(45.0)
	parent.add_child(ring)
	var tw = create_tween()
	tw.tween_property(ring, "scale", Vector2.ONE * 0.2, 0.1)
	tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.15)
	tw.finished.connect(ring.queue_free)
	# 兜底：tween 被 kill（updater 被清理）时 finished 不触发，
	# 定时器确保残留菱形最终被清理
	ring.get_tree().create_timer(0.3).timeout.connect(ring.queue_free)


func _on_runetracer_tick(proj: Node2D, delta: float):
	var dir: Vector2 = proj.get_meta("rune_dir", Vector2.DOWN)
	var speed: float = proj.get_meta("rune_speed", 400.0)
	var bounces: int = proj.get_meta("rune_bounces", 0)

	proj.global_position += dir * speed * delta

	# 视觉旋转
	var vis = proj.get_node_or_null("Visuals")
	if vis:
		vis.rotation = dir.angle()

	# ── 定时刷新边界（不每帧走）──
	_bounds_timer += delta
	if _bounds_timer >= _bounds_interval:
		_bounds_timer = 0.0
		_refresh_bounds()

	# ── 边界反弹 ──
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
		proj.set_meta("rune_dir", dir)
		proj.set_meta("rune_bounces", bounces)
		AudioManager.play_sfx("wpn_bounce")
		_bounce_effect(proj.global_position, proj.get_parent())

	if bounces >= 6:
		_cleanup()


func _cleanup():
	var proj = get_parent()
	if is_instance_valid(proj):
		proj.queue_free()
	queue_free()
