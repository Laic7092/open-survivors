extends Node2D
# Pre-defined emoji drawing node — replaces dynamic draw.connect closures.
# Use EmojiNode.new() and set properties before adding to scene.

var emoji: String = ""
var emoji_size: float = 16.0
var _font_size: int = 16


func setup(e: String, sz: float):
	emoji = e
	emoji_size = sz
	_font_size = maxi(12, int(sz * 1.5))


func _draw():
	if emoji.is_empty():
		return
	var f = ThemeDB.get_project_theme().default_font if ThemeDB.get_project_theme() else ThemeDB.get_default_theme().default_font
	if f:
		var ts = f.get_string_size(emoji, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size)
		var pos = Vector2(-ts.x * 0.5, ts.y * 0.35)
		draw_string(f, pos, emoji, HORIZONTAL_ALIGNMENT_CENTER, ts.x, _font_size, Color(1, 1, 1, 0.95))
