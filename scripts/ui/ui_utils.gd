extends RefCounted
# UI 工具函数 — 动态按钮样式（用于颜色随物品变化的按钮）

const RADIUS := 6
const BORDER_W := 2


# 统一样式按钮（颜色可动态指定，用于升级选择/密术选择等场景）
static func style_button(btn: Button, bg: Color, accent: Color):
	var normal = StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_width_left = BORDER_W; normal.border_width_right = BORDER_W
	normal.border_width_top = BORDER_W; normal.border_width_bottom = BORDER_W
	normal.border_color = accent
	normal.corner_radius_top_left = RADIUS; normal.corner_radius_top_right = RADIUS
	normal.corner_radius_bottom_left = RADIUS; normal.corner_radius_bottom_right = RADIUS
	btn.add_theme_stylebox_override("normal", normal)
	
	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(
		min(bg.r + 0.15, 1.0),
		min(bg.g + 0.15, 1.0),
		min(bg.b + 0.15, 1.0),
		min(bg.a + 0.1, 1.0)
	)
	hover.border_width_left = BORDER_W; hover.border_width_right = BORDER_W
	hover.border_width_top = BORDER_W; hover.border_width_bottom = BORDER_W
	hover.border_color = Color(
		min(accent.r + 0.3, 1.0),
		min(accent.g + 0.3, 1.0),
		min(accent.b + 0.3, 1.0)
	)
	hover.corner_radius_top_left = RADIUS; hover.corner_radius_top_right = RADIUS
	hover.corner_radius_bottom_left = RADIUS; hover.corner_radius_bottom_right = RADIUS
	btn.add_theme_stylebox_override("hover", hover)
	
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 16)


# 响应式：计算视口中可容纳的列数
static func calc_columns(viewport_w: float, item_w: float, gap: float = 16.0, margin: float = 40.0, max_cols: int = 6) -> int:
	var available = viewport_w - margin * 2
	var cols = max(1, int(available / (item_w + gap)))
	return mini(cols, max_cols)


# 创建升级选择按钮（包含内容容器，统一样式）
# content: VBoxContainer 作为按钮内容子节点
# accent: 可选，边框强调色（默认淡金色）
static func make_choice_button(content: Control, accent: Color = Color(0.7, 0.6, 0.1)) -> Button:
	var btn = Button.new()
	var content_h = max(content.custom_minimum_size.y, 80)
	btn.custom_minimum_size = Vector2(0, content_h)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# 带内边距的卡片样式
	var bg = accent * 0.15
	var border = accent
	border.a = 0.5
	var normal = StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = border
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", normal)
	# hover: 亮一点
	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(
		min(bg.r + 0.08, 1.0),
		min(bg.g + 0.08, 1.0),
		min(bg.b + 0.08, 1.0),
		min(bg.a + 0.05, 1.0)
	)
	hover.border_color = accent
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(8)
	hover.content_margin_left = 10
	hover.content_margin_right = 10
	hover.content_margin_top = 6
	hover.content_margin_bottom = 6
	btn.add_theme_stylebox_override("hover", hover)
	# pressed: 更亮
	var pressed = StyleBoxFlat.new()
	pressed.bg_color = Color(
		min(bg.r + 0.15, 1.0),
		min(bg.g + 0.15, 1.0),
		min(bg.b + 0.15, 1.0),
		min(bg.a + 0.1, 1.0)
	)
	pressed.border_color = accent
	pressed.border_color.a = 0.8
	pressed.set_border_width_all(2)
	pressed.set_corner_radius_all(8)
	pressed.content_margin_left = 10
	pressed.content_margin_right = 10
	pressed.content_margin_top = 6
	pressed.content_margin_bottom = 6
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", normal)
	# 内容填满按钮
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(content)
	return btn
