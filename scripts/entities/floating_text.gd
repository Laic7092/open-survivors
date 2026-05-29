extends Node2D
# Floating text with pooled lifecycle.
# No Timer child created anymore — uses _process-based lifetime.
# Returns itself to FloatingTextPool when expired.

var display_text: String = ""
var text_color: Color = Color.WHITE
var font_size: int = 18
var lifetime: float = 0.9
var age: float = 0.0
var velocity: Vector2 = Vector2(0, -50)


func _process(delta):
	age += delta
	position += velocity * delta
	if age >= lifetime:
		if is_inside_tree():
			if FloatingTextPool:
				FloatingTextPool.return_ft(self)
			else:
				queue_free()


func _draw():
	var alpha = 1.0 - (age / lifetime)
	if alpha <= 0:
		return
	var y_offset = -age * 20
	var pos = Vector2.ZERO + Vector2(0, y_offset)
	var font = ThemeDB.fallback_font
	if not font:
		return
	var text_width = font.get_string_size(display_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	pos.x -= text_width / 2
	draw_string(font, pos, display_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(text_color.r, text_color.g, text_color.b, alpha))
