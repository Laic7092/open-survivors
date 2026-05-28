extends Control
# Minimap — draws a small overview of the map in the corner.
# main.gd calls setter methods each frame to update positions.

var map_w: float = 3200.0
var map_h: float = 2400.0
var player_pos: Vector2 = Vector2.ZERO
var camera_pos: Vector2 = Vector2.ZERO
var camera_size: Vector2 = Vector2(1280, 720)
var obstacle_positions: Array[Vector2] = []


func set_map_size(w: float, h: float):
	map_w = w
	map_h = h
	queue_redraw()


func set_player_pos(pos: Vector2):
	player_pos = pos
	queue_redraw()


func set_camera_view(pos: Vector2, size: Vector2):
	camera_pos = pos
	camera_size = size
	queue_redraw()


func set_obstacles(positions: Array[Vector2]):
	obstacle_positions = positions
	queue_redraw()


func _draw():
	var vp = get_viewport().get_visible_rect().size
	var mm_size = Vector2(150, 150)
	var mm_origin = Vector2(vp.x - mm_size.x - 10, 10)
	
	# Semi-transparent background
	draw_rect(Rect2(mm_origin, mm_size), Color(0, 0, 0, 0.75))
	draw_rect(Rect2(mm_origin, mm_size), Color(0.4, 0.4, 0.4, 0.5), false, 1.5)
	
	# Scale: map coordinates → minimap pixels (fit within mm_size)
	var sx = (mm_size.x - 12.0) / map_w
	var sy = (mm_size.y - 12.0) / map_h
	var scale = min(sx, sy)
	
	# Center of minimap area
	var center = mm_origin + Vector2(mm_size.x / 2.0, mm_size.y / 2.0)
	
	# Map boundary
	var map_rect = Rect2(
		center + Vector2(-map_w / 2.0 * scale, -map_h / 2.0 * scale),
		Vector2(map_w * scale, map_h * scale)
	)
	draw_rect(map_rect, Color(0.25, 0.25, 0.25), false, 1.0)
	
	# Obstacles as small dark dots
	for p in obstacle_positions:
		var dot = center + p * scale
		draw_circle(dot, 1.5, Color(0.35, 0.35, 0.35))
	
	# Camera visible area
	if camera_size.x > 0 and camera_size.y > 0:
		var cam_rect = Rect2(
			center + (camera_pos - camera_size / 2.0) * scale,
			camera_size * scale
		)
		draw_rect(cam_rect, Color(1, 1, 1, 0.1), true)
		draw_rect(cam_rect, Color(1, 1, 1, 0.4), false, 1.0)
	
	# Player dot (on top of everything)
	var pp = center + player_pos * scale
	draw_circle(pp, 4.0, Color(0.9, 0.9, 0.2))
	draw_circle(pp, 4.0, Color(1, 1, 1), false, 1.5)
