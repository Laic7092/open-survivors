extends Node
# CameraController — 相机跟随 + 抖动
# 从 main.gd 中拆分出的相机逻辑

var _camera: Camera2D
var _target: Node2D
var _offset: Vector2 = Vector2(0, -80)

# 抖动状态
var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0

# 相机边界缓存
var cam_left: float = 0.0
var cam_right: float = 0.0
var cam_top: float = 0.0
var cam_bottom: float = 0.0
var _bounds_dirty: bool = true

# 地图边界
var _map_width: float = 3200.0
var _map_height: float = 2400.0


func setup(parent: Node, target: Node2D, mw: float, mh: float):
	_target = target
	_map_width = mw
	_map_height = mh
	
	_camera = Camera2D.new()
	_camera.name = "PlayerCamera"
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	_camera.limit_left = -mw / 2.0
	_camera.limit_right = mw / 2.0
	_camera.limit_top = -mh / 2.0
	_camera.limit_bottom = mh / 2.0
	parent.add_child(_camera)


func shake(intensity: float, duration: float):
	_shake_intensity = intensity
	_shake_duration = duration


func get_camera_bounds() -> Dictionary:
	_update_bounds()
	return {"left": cam_left, "right": cam_right, "top": cam_top, "bottom": cam_bottom}


func process(delta: float):
	if not _camera or not is_instance_valid(_target):
		return
	
	var shake_off = Vector2.ZERO
	if _shake_duration > 0.0:
		_shake_duration -= delta
		shake_off = Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
	
	_camera.global_position = _target.global_position + _offset + shake_off
	_bounds_dirty = true


func _update_bounds():
	if not _bounds_dirty:
		return
	var viewport = get_viewport()
	if not viewport:
		return
	var camera = viewport.get_camera_2d()
	if not camera:
		var vs = viewport.get_visible_rect().size
		cam_left = -vs.x / 2.0
		cam_right = vs.x / 2.0
		cam_top = -vs.y / 2.0
		cam_bottom = vs.y / 2.0
	else:
		var cam_pos = camera.global_position
		var vs = viewport.get_visible_rect().size
		cam_left = cam_pos.x - vs.x / 2.0
		cam_right = cam_pos.x + vs.x / 2.0
		cam_top = cam_pos.y - vs.y / 2.0
		cam_bottom = cam_pos.y + vs.y / 2.0
	_bounds_dirty = false
