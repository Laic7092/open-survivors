extends Control
# 单个武器/被动格子，在 HUD 底部网格中显示
# 通过 set_data() 传入数据，_draw() 绘制背景/等级条/文字

var item_type: int = -1      # 道具类型 ID
var item_level: int = 0      # 当前等级
var item_max_lv: int = 8     # 最大等级
var is_evolved: bool = false # 是否已进化
var cell_color: Color = Color(0.5, 0.5, 0.5)
var _has_data: bool = false

# 图标节点（由 IconGenerator.make_icon_node() 创建，含纹理 + emoji）
var _icon_node: Control = null


func set_data(type: int, level: int, max_lv: int, evolved: bool, color: Color):
	item_type = type
	item_level = level
	item_max_lv = max_lv if max_lv > 0 else 8
	is_evolved = evolved
	cell_color = color
	_has_data = true
	custom_minimum_size = Vector2(36, 36)

	# 替换图标节点（工厂方法返回含纹理 + emoji 的 Control）
	if _icon_node != null:
		_icon_node.queue_free()
	_icon_node = IconGenerator.make_icon_node(type, 28)
	_icon_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_node.size = Vector2(28, 28)
	_icon_node.position = Vector2((36 - 28) / 2.0, (36 - 28) / 2.0)
	add_child(_icon_node)
	queue_redraw()


func clear():
	_has_data = false
	if _icon_node != null:
		_icon_node.queue_free()
		_icon_node = null
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

	# 背景色块
	var bg = Color(cell_color.r * 0.25, cell_color.g * 0.25, cell_color.b * 0.25, 0.7)
	draw_rect(Rect2(Vector2.ZERO, Vector2(sz, sz)), bg)

	# 等级填充条（左边竖条）
	var fill_h = (sz - 2) * min(item_level / float(item_max_lv), 1.0)
	draw_rect(Rect2(1, sz - 1 - fill_h, 3, fill_h), cell_color)

	# 等级数字（左下）
	var font = ThemeDB.fallback_font
	var lv_str = str(item_level)
	var lv_x = max(2.0, 6.0)
	var lv_y = sz - 4.0
	draw_string(font, Vector2(lv_x, lv_y), lv_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)

	# 进化星号（右上）
	if is_evolved:
		draw_string(font, Vector2(sz - 14, 12), "*", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.8, 0.2))
