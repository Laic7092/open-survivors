extends Node2D

var color := Color(0.3, 0.6, 1.0, 0.9)

func _draw():
	draw_circle(Vector2.ZERO, 6, color)
	draw_circle(Vector2.ZERO, 6, Color(0.5, 0.8, 1.0, 0.5), false, 1.5)
