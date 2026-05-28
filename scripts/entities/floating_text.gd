extends Node2D

var display_text: String = ""
var text_color: Color = Color.WHITE
var font_size: int = 18
var lifetime: float = 0.9
var age: float = 0.0
var velocity: Vector2 = Vector2(0, -50)


func _ready():
	# Random horizontal drift
	velocity.x = randf_range(-15, 15)
	# Auto-remove after lifetime via Timer
	var t = Timer.new()
	t.wait_time = lifetime
	t.one_shot = true
	t.timeout.connect(func():
		if is_inside_tree():
			queue_free()
	)
	add_child(t)
	t.start()


func _process(delta):
	age += delta
	position += velocity * delta


func _draw():
	var alpha = 1.0 - (age / lifetime)
	if alpha <= 0:
		return
	# Offset upward slightly as it ages
	var y_offset = -age * 20
	var pos = Vector2.ZERO + Vector2(0, y_offset)
	var font = ThemeDB.fallback_font
	# Center the text horizontally
	var text_width = font.get_string_size(display_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	pos.x -= text_width / 2
	draw_string(font, pos, display_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(text_color.r, text_color.g, text_color.b, alpha))
