extends Node2D
# Floating text with pooled lifecycle.
# No Timer child created anymore — uses _process-based lifetime.
# Returns itself to FloatingTextPool when expired.

var display_text: String = "":
	set(v):
		display_text = v
		_text_width = -1.0  # invalidate cache
var text_color: Color = Color.WHITE
var font_size: int = 18
var lifetime: float = 0.5
var age: float = 0.0
var velocity: Vector2 = Vector2(0, -50)
var _text_width: float = -1.0


func _pool_borrow(config: Dictionary = {}):
	display_text = config.get("text", "")
	text_color = config.get("color", Color.WHITE)
	font_size = config.get("size", 18)
	global_position = config.get("position", Vector2.ZERO)
	velocity = config.get("velocity", Vector2(randf_range(-15, 15), -50))
	lifetime = config.get("lifetime", 0.5)
	age = 0.0
	visible = true
	set_process(true)
	modulate = Color(1, 1, 1, 1)


func _process(delta):
	age += delta
	position += velocity * delta
	if age >= lifetime:
		if is_inside_tree() and ObjectPoolManager:
			ObjectPoolManager.return_obj(self)


func _draw():
	var alpha = 1.0 - (age / lifetime)
	if alpha <= 0:
		return
	var y_offset = -age * 20
	var pos = Vector2(0, y_offset)
	var font = ThemeDB.fallback_font
	if not font:
		return
	if _text_width < 0 and font:
		_text_width = font.get_string_size(display_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	pos.x -= _text_width / 2
	draw_string(font, pos, display_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(text_color.r, text_color.g, text_color.b, alpha))
