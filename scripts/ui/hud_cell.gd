extends Control
# 单个武器/被动格子，在 HUD 底部网格中显示
# 通过 set_data() 传入数据，_draw() 绘制所有内容

var item_type: int = -1      # 道具类型 ID
var item_level: int = 0      # 当前等级
var item_max_lv: int = 8     # 最大等级
var is_evolved: bool = false # 是否已进化
var cell_color: Color = Color(0.5, 0.5, 0.5)
var _has_data: bool = false

# 图标纹理 — from IconGenerator
var _icon: ImageTexture


func set_data(type: int, level: int, max_lv: int, evolved: bool, color: Color):
	item_type = type
	item_level = level
	item_max_lv = max_lv if max_lv > 0 else 8
	is_evolved = evolved
	cell_color = color
	_has_data = true
	custom_minimum_size = Vector2(36, 36)
	_icon = IconGenerator.generate(type, 28)
	queue_redraw()


func clear():
	_has_data = false
	_icon = null
	item_type = -1
	item_level = 0
	queue_redraw()


func _draw():
	var sz = size.x
	if sz <= 0:
		sz = 36

	if not _has_data:
		# 空格子 — 灰色虚线框
		draw_rect(Rect2(Vector2.ZERO, Vector2(sz, sz)), Color(0.2, 0.2, 0.2, 0.3), false, 1.0)
		return

	var hs = sz / 2.0

	# 背景色块
	var bg = Color(cell_color.r * 0.25, cell_color.g * 0.25, cell_color.b * 0.25, 0.7)
	draw_rect(Rect2(Vector2.ZERO, Vector2(sz, sz)), bg)

	# 等级填充条（左边竖条）
	var fill_h = (sz - 2) * min(item_level / float(item_max_lv), 1.0)
	draw_rect(Rect2(1, sz - 1 - fill_h, 3, fill_h), cell_color)

	# 图标（IconGenerator 生成的圆形彩色纹理）
	if _icon:
		var ix = (sz - 28) / 2.0
		var iy = (sz - 28) / 2.0
		draw_texture(_icon, Vector2(ix, iy))

	# 武器符号（白色，覆盖在图标上）
	if item_type >= 0:
		_draw_symbol(hs, hs, hs * 0.55, item_type)

	# 等级数字（左下）
	var font = ThemeDB.fallback_font
	var lv_str = str(item_level)
	var lv_x = max(2.0, 6.0)
	var lv_y = sz - 4.0
	draw_string(font, Vector2(lv_x, lv_y), lv_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)

	# 进化星号（右上）
	if is_evolved:
		draw_string(font, Vector2(sz - 14, 12), "*", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.8, 0.2))


# ── 武器符号绘制（从原 _draw_item_symbol 移植） ──
func _draw_symbol(cx: float, cy: float, s: float, t: int):
	var white = Color(1, 1, 1, 0.85)

	match t:
		0:  # Whip — 对角斜线
			draw_line(Vector2(cx - s, cy + s), Vector2(cx + s, cy - s), white, 2.0)
		1:  # Magic Wand — 竖线 + 圆点
			draw_line(Vector2(cx, cy - s * 0.8), Vector2(cx, cy + s * 0.8), white, 2.0)
			draw_circle(Vector2(cx, cy - s * 1.0), 1.5, white)
		2:  # Garlic — 实心圆
			draw_circle(Vector2(cx, cy), s * 0.5, white)
		10: # Knife — 三角形（指向右）
			var tri = PackedVector2Array([
				Vector2(cx + s * 0.8, cy),
				Vector2(cx - s * 0.6, cy - s * 0.7),
				Vector2(cx - s * 0.6, cy + s * 0.7),
			])
			draw_polygon(tri, [white])
		11: # Axe — 横线
			draw_line(Vector2(cx - s, cy), Vector2(cx + s, cy), white, 2.5)
		12: # Fire Wand — 菱形
			var diamond = PackedVector2Array([
				Vector2(cx, cy - s * 0.9),
				Vector2(cx + s * 0.7, cy),
				Vector2(cx, cy + s * 0.9),
				Vector2(cx - s * 0.7, cy),
			])
			draw_polygon(diamond, [white])
		3:  # Wings — V 形
			draw_line(Vector2(cx - s, cy + s * 0.3), Vector2(cx, cy - s * 0.6), white, 2.0)
			draw_line(Vector2(cx, cy - s * 0.6), Vector2(cx + s, cy + s * 0.3), white, 2.0)
		4:  # Spinach — 十字 +
			draw_line(Vector2(cx - s * 0.7, cy), Vector2(cx + s * 0.7, cy), white, 2.0)
			draw_line(Vector2(cx, cy - s * 0.7), Vector2(cx, cy + s * 0.7), white, 2.0)
		5:  # Empty Tome — 方形外框
			var r = s * 0.7
			draw_rect(Rect2(cx - r, cy - r, r * 2, r * 2), white, false, 1.5)
		6:  # Hollow Heart — 心形
			var hr = s * 0.4
			draw_circle(Vector2(cx - hr, cy - hr * 0.3), hr * 0.6, white)
			draw_circle(Vector2(cx + hr, cy - hr * 0.3), hr * 0.6, white)
			draw_line(Vector2(cx - hr * 1.0, cy - hr * 0.1), Vector2(cx, cy + hr * 0.9), white, 1.5)
			draw_line(Vector2(cx + hr * 1.0, cy - hr * 0.1), Vector2(cx, cy + hr * 0.9), white, 1.5)
		7:  # Candelabrador — 圆圈外框
			draw_circle(Vector2(cx, cy), s * 0.55, white, false, 1.5)
		8:  # Crown — 皇冠
			var cw = s * 0.8
			var ch = s * 0.6
			var crown = PackedVector2Array([
				Vector2(cx - cw, cy + ch * 0.5),
				Vector2(cx - cw * 0.6, cy - ch),
				Vector2(cx - cw * 0.2, cy - ch * 0.2),
				Vector2(cx + cw * 0.2, cy - ch * 0.2),
				Vector2(cx + cw * 0.6, cy - ch),
				Vector2(cx + cw, cy + ch * 0.5),
			])
			draw_polygon(crown, [white])
		9:  # Pummarola — 实心小圆
			draw_circle(Vector2(cx, cy), s * 0.4, white)
		13: # Duplicator — II 两竖线
			draw_line(Vector2(cx - s * 0.35, cy - s * 0.6), Vector2(cx - s * 0.35, cy + s * 0.6), white, 2.0)
			draw_line(Vector2(cx + s * 0.35, cy - s * 0.6), Vector2(cx + s * 0.35, cy + s * 0.6), white, 2.0)
		14: # Stone Mask — 两点（眼睛）
			draw_circle(Vector2(cx - s * 0.4, cy), s * 0.15, white)
			draw_circle(Vector2(cx + s * 0.4, cy), s * 0.15, white)
		15: # Magnet — U 形
			var ms = s * 0.6
			draw_line(Vector2(cx - ms, cy - ms), Vector2(cx - ms, cy + ms * 0.5), white, 2.0)
			draw_line(Vector2(cx + ms, cy - ms), Vector2(cx + ms, cy + ms * 0.5), white, 2.0)
			draw_line(Vector2(cx - ms, cy + ms * 0.5), Vector2(cx + ms, cy + ms * 0.5), white, 2.0)
		16: # Cross — 十字架
			draw_line(Vector2(cx - s * 0.7, cy), Vector2(cx + s * 0.7, cy), white, 2.5)
			draw_line(Vector2(cx, cy - s * 0.7), Vector2(cx, cy + s * 0.7), white, 2.5)
		17: # King Bible — 圆圈 + 十字
			draw_circle(Vector2(cx, cy), s * 0.55, white, false, 2.0)
			draw_line(Vector2(cx - s * 0.4, cy), Vector2(cx + s * 0.4, cy), white, 2.0)
			draw_line(Vector2(cx, cy - s * 0.4), Vector2(cx, cy + s * 0.4), white, 2.0)
		18: # Santa Water — 水滴（三角形）
			var drop = PackedVector2Array([
				Vector2(cx, cy - s * 0.7),
				Vector2(cx - s * 0.6, cy + s * 0.4),
				Vector2(cx + s * 0.6, cy + s * 0.4),
			])
			draw_polygon(drop, [white])
		19: # Runetracer — 斜线符文
			draw_line(Vector2(cx - s * 0.8, cy - s * 0.5), Vector2(cx + s * 0.8, cy + s * 0.5), white, 2.0)
			draw_line(Vector2(cx - s * 0.5, cy - s * 0.8), Vector2(cx + s * 0.5, cy + s * 0.8), white, 1.5)
		20: # Lightning Ring — 锯齿闪电
			draw_line(Vector2(cx - s * 0.3, cy - s * 0.7), Vector2(cx + s * 0.2, cy - s * 0.2), white, 2.0)
			draw_line(Vector2(cx + s * 0.2, cy - s * 0.2), Vector2(cx - s * 0.2, cy + s * 0.2), white, 2.0)
			draw_line(Vector2(cx - s * 0.2, cy + s * 0.2), Vector2(cx + s * 0.3, cy + s * 0.7), white, 2.0)
