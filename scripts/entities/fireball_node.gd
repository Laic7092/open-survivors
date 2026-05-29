extends Node2D
# Pre-defined fireball drawing node — replaces dynamic draw.connect closure.
# Set fb_size and seed_offset before adding to scene.

var fb_size: float = 6.0
var seed_offset: int = 0


func _draw():
	var flicker = 0.85 + sin(Time.get_ticks_msec() * 0.015 + seed_offset) * 0.15
	var r = fb_size * flicker
	draw_circle(Vector2.ZERO, r * 2.2, Color(0.9, 0.3, 0.05, 0.12))
	draw_circle(Vector2.ZERO, r * 1.5, Color(0.95, 0.5, 0.1, 0.25))
	draw_circle(Vector2.ZERO, r * 0.9, Color(0.95, 0.7, 0.15, 0.8))
	draw_circle(Vector2.ZERO, r * 0.4, Color(1.0, 0.9, 0.5, 1.0))
