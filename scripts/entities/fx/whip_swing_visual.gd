extends Node2D
# Temporary visual for a single whip swing (used for staggered swings beyond the first).
# Each instance draws one rectangle at its position and fades out.

var visual_area: float = 60.0
var facing_dir: Vector2 = Vector2.DOWN
var evolved: bool = false


func _draw():
	var rect_len = visual_area * 2.0
	var rect_half_w = visual_area * 0.6
	var perp_dir = facing_dir.orthogonal()

	var far_r = facing_dir * rect_len + perp_dir * rect_half_w
	var far_l = facing_dir * rect_len - perp_dir * rect_half_w
	var near_l = -perp_dir * rect_half_w
	var near_r = perp_dir * rect_half_w
	var corners = PackedVector2Array([far_r, far_l, near_l, near_r])

	var base_color = Color(1.0, 0.6, 0.6) if evolved else Color(1, 1, 1)
	var alpha = modulate.a

	# 半透明填充
	draw_polygon(corners, [Color(base_color.r, base_color.g, base_color.b, alpha * 0.2)])
	# 四条边
	draw_line(far_r, far_l, Color(base_color.r, base_color.g, base_color.b, alpha * 0.6), 2.0, true)
	draw_line(far_l, near_l, Color(base_color.r, base_color.g, base_color.b, alpha * 0.4), 1.5, true)
	draw_line(near_l, near_r, Color(base_color.r, base_color.g, base_color.b, alpha * 0.2), 1.0, true)
	draw_line(near_r, far_r, Color(base_color.r, base_color.g, base_color.b, alpha * 0.4), 1.5, true)
	# 远端端点
	draw_circle(facing_dir * rect_len, 3.0, Color(base_color.r, base_color.g, base_color.b, alpha))
