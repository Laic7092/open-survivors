extends Node2D
# Optimized explosion visual effect.
# Replaces dynamic draw function creation with a proper script.
# Properties must be set before adding to scene.

var _radius: float = 0.0
var _color: Color = Color(1.0, 0.4, 0.1)


func _draw():
	var a = modulate.a
	draw_circle(Vector2.ZERO, _radius, Color(_color.r, _color.g, _color.b, a * 0.25))
	draw_arc(Vector2.ZERO, _radius, 0, TAU, 32, Color(_color.r, _color.g, _color.b, a * 0.8), max(2.0, _radius * 0.08))
	draw_circle(Vector2.ZERO, _radius * 0.35, Color(1.0, 0.8, 0.4, a * 0.6))
