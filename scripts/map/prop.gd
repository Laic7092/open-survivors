extends StaticBody2D
# Simple map prop: tree, rock, pillar, bush, etc.
# Set properties before adding to scene.

var prop_color: Color = Color(0.2, 0.5, 0.1)
var shape_type: String = "circle"   # "circle" or "rect"
var shape_radius: float = 14.0      # for circles
var rect_size: Vector2 = Vector2(20, 20)  # for rects
var outline_width: float = 2.0


func _draw():
	match shape_type:
		"circle":
			draw_circle(Vector2.ZERO, shape_radius, prop_color)
			if outline_width > 0:
				draw_circle(Vector2.ZERO, shape_radius, prop_color * 0.7, false, outline_width)
		"rect":
			var half = rect_size / 2.0
			draw_rect(Rect2(-half, rect_size), prop_color)
			if outline_width > 0:
				draw_rect(Rect2(-half, rect_size), prop_color * 0.7, false, outline_width)
