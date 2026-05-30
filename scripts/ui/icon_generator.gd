extends RefCounted
class_name IconGenerator
# Runtime icon generator — creates colored circular icon textures via Image pixel drawing.
# Also provides make_icon_node() factory to eliminate TextureRect+emoji duplication.
# No asset files needed. Textures are cached statically.

static var CACHE: Dictionary = {}
const DEFAULT_SIZE := 32

# Item type → emoji character for icon rendering
const EMOJI := {
	0: "🪢",   # Whip
	1: "🪄",   # Magic Wand
	2: "🧄",   # Garlic
	10: "🔪",  # Knife
	11: "🪓",  # Axe
	12: "🔥",  # Fire Wand
	16: "❌",  # Cross
	17: "📖",  # King Bible
	18: "💧",  # Santa Water
	19: "✨",  # Runetracer
	20: "⚡",  # Lightning Ring
	3: "👼",   # Wings
	4: "🥬",   # Spinach
	5: "📕",   # Empty Tome
	6: "❤️",  # Hollow Heart
	7: "🕯️",  # Candelabrador
	8: "👑",   # Crown
	9: "🍅",   # Pummarola
	13: "🪞",  # Duplicator
	14: "🗿",  # Stone Mask
	15: "🧲",  # Attractorb
	21: "🍀",  # Clover
	22: "📿",  # Spellbinder
	23: "🛡️", # Armor
	24: "🏹",  # Bracer
	25: "💀",  # Skull O'Maniac
	26: "🍰",  # Tiragisú
	27: "📦",  # Torrona's Box
	28: "💍",  # Silver Ring
	29: "💍",  # Gold Ring
	30: "🔮",  # Metaglio Left
	31: "⚗️", # Metaglio Right
	32: "⭐",  # Pentagram
	33: "🎵",  # Song of Mana
	34: "🐱",  # Gatti Amari
	35: "🔫",  # Phiera Der Tuphello
	36: "🔫",  # Eight The Sparrow
	37: "🗡️", # Victory Sword
}

# Item type → color (mirrors level_up_screen.gd _color())
static func get_color(t: int) -> Color:
	match t:
		0: return Color(0.8, 0.6, 0.3)    # Whip
		1: return Color(0.3, 0.5, 1.0)    # Magic Wand
		2: return Color(0.6, 0.2, 0.8)    # Garlic
		10: return Color(0.7, 0.7, 0.7)   # Knife
		11: return Color(0.6, 0.3, 0.1)   # Axe
		12: return Color(0.9, 0.4, 0.1)   # Fire Wand
		16: return Color(0.9, 0.6, 0.2)   # Cross
		17: return Color(0.2, 0.6, 0.9)   # King Bible
		18: return Color(0.1, 0.5, 0.8)   # Santa Water
		19: return Color(0.8, 0.3, 0.7)   # Runetracer
		20: return Color(0.9, 0.9, 0.2)   # Lightning Ring
		3: return Color(0.2, 0.8, 0.4)    # Wings
		4: return Color(0.9, 0.3, 0.3)    # Spinach
		5: return Color(0.2, 0.5, 0.8)    # Empty Tome
		6: return Color(0.9, 0.2, 0.2)    # Hollow Heart
		7: return Color(0.9, 0.7, 0.2)    # Candelabrador
		8: return Color(0.9, 0.8, 0.0)    # Crown
		9: return Color(0.2, 0.9, 0.2)    # Pummarola
		13: return Color(0.2, 0.7, 0.9)   # Duplicator
		14: return Color(0.7, 0.7, 0.8)   # Stone Mask
		15: return Color(0.1, 0.7, 0.8)   # Magnet
		21: return Color(0.2, 0.9, 0.3)   # Clover
		22: return Color(0.5, 0.3, 0.9)   # Spellbinder
		23: return Color(0.6, 0.6, 0.6)   # Armor
		24: return Color(0.3, 0.9, 0.6)   # Bracer
		25: return Color(0.6, 0.2, 0.2)   # Skull O'Maniac
		26: return Color(0.9, 0.7, 0.9)   # Tiragisú
		27: return Color(0.4, 0.2, 0.6)   # Torrona's Box
		28: return Color(0.6, 0.7, 0.9)   # Silver Ring
		29: return Color(0.9, 0.8, 0.2)   # Gold Ring
		30: return Color(0.5, 0.3, 0.8)   # Metaglio Left
		31: return Color(0.8, 0.3, 0.5)   # Metaglio Right
		32: return Color(0.6, 0.1, 0.9)   # Pentagram
		33: return Color(0.2, 0.8, 0.3)   # Song of Mana
		34: return Color(0.9, 0.5, 0.2)   # Gatti Amari
		35: return Color(0.3, 0.3, 0.7)   # Phiera Der Tuphello
		36: return Color(0.7, 0.3, 0.4)   # Eight The Sparrow
		37: return Color(0.9, 0.8, 0.6)   # Victory Sword
	return Color.WHITE


# Get the emoji character for a given item type
static func get_emoji(t: int) -> String:
	return EMOJI.get(t, "❓")


# Generate a colored circular icon texture. Results are cached by (type, size).
static func generate(t: int, size: int = DEFAULT_SIZE) -> ImageTexture:
	var key = str(t) + ":" + str(size)
	if CACHE.has(key):
		return CACHE[key]
	
	var color: Color = get_color(t)
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	var half: float = size / 2.0
	var outer_r: float = half - 0.5
	var inner_r: float = outer_r - 1.5  # border thickness
	
	# Border (slightly darker)
	var border_color = Color(color.r * 0.6, color.g * 0.6, color.b * 0.6)
	
	for y in range(size):
		for x in range(size):
			var dx = x + 0.5 - half
			var dy = y + 0.5 - half
			var dist = sqrt(dx*dx + dy*dy)
			
			if dist <= inner_r:
				img.set_pixel(x, y, color)
			elif dist <= outer_r:
				# Anti-aliased border
				var t_val = outer_r - dist
				var alpha = clamp(t_val, 0.0, 1.0)
				# Blend between border and background based on edge proximity
				var edge_frac = (dist - inner_r) / (outer_r - inner_r) if outer_r > inner_r else 1.0
				var c = border_color.lerp(color, 1.0 - edge_frac * 0.5)
				c.a = alpha
				img.set_pixel(x, y, c)
	
	var tex = ImageTexture.create_from_image(img)
	CACHE[key] = tex
	return tex


# Clear cached textures (call if color scheme changes at runtime)
static func clear_cache():
	CACHE.clear()


# ── Icon node factory (replaces TextureRect + emoji Label duplication) ──

# Returns a pre-assembled Control with colored circular texture + emoji overlay.
# Consumers add this single node instead of creating TextureRect + Label pairs.
static func make_icon_node(t: int, size: int, modulate: Color = Color.WHITE, emoji_scale: float = 0.55) -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(size, size)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tex_rect = TextureRect.new()
	tex_rect.texture = generate(t, size)
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	tex_rect.modulate = modulate
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(tex_rect)

	var emoji_lbl = Label.new()
	emoji_lbl.text = get_emoji(t)
	emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font_sz = max(10, int(size * emoji_scale))
	emoji_lbl.add_theme_font_size_override("font_size", font_sz)
	emoji_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	emoji_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	emoji_lbl.add_theme_constant_override("shadow_offset_x", 1)
	emoji_lbl.add_theme_constant_override("shadow_offset_y", 1)
	emoji_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emoji_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(emoji_lbl)

	return container
