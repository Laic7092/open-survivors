extends RefCounted
# UI 工具函数 — 统一按钮样式、配色方案

const RADIUS := 6
const BORDER_W := 2


# 统一样式按钮
# btn: Button 实例
# bg: 默认背景色
# accent: 边框色 + hover 背景基调
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


# 卡片面板样式（用在角色/关卡/密术选择卡）
static func style_card_panel(panel: Panel, bg_color: Color, border_color: Color, radius: int = 12):
	var s = StyleBoxFlat.new()
	s.bg_color = bg_color
	s.border_width_left = BORDER_W + 1; s.border_width_right = BORDER_W + 1
	s.border_width_top = BORDER_W + 1; s.border_width_bottom = BORDER_W + 1
	s.border_color = border_color
	s.corner_radius_top_left = radius; s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius; s.corner_radius_bottom_right = radius
	panel.add_theme_stylebox_override("panel", s)


# 响应式：计算视口中可容纳的列数
# item_w: 单个卡片宽度, gap: 间距, margin: 两侧边距, max_cols: 最大列数
static func calc_columns(viewport_w: float, item_w: float, gap: float = 16.0, margin: float = 40.0, max_cols: int = 6) -> int:
	var available = viewport_w - margin * 2
	var cols = max(1, int(available / (item_w + gap)))
	return mini(cols, max_cols)


# 响应式：居中计算起始 x
static func calc_start_x(viewport_w: float, cols: int, item_w: float, gap: float) -> float:
	var total_w = cols * item_w + (cols - 1) * gap
	return (viewport_w - total_w) / 2.0
