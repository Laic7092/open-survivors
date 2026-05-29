extends CanvasLayer
# SceneManager — 带加载动画的场景切换管理器
# 用法: SceneManager.change_scene("res://scenes/xxx.tscn")
# 原理: 在 root 层显示 loading，然后触发场景切换，新场景就绪后自动隐藏

var _loading_label: Label
var _loading_bg: ColorRect
var _is_transitioning: bool = false


func _ready():
	layer = 99  # 在最上层
	visible = false
	# 创建加载动画 UI (不依赖当前场景)
	_loading_bg = ColorRect.new()
	_loading_bg.color = Color(0, 0, 0, 0.85)
	_loading_bg.anchor_right = 1.0
	_loading_bg.anchor_bottom = 1.0
	add_child(_loading_bg)
	
	_loading_label = Label.new()
	_loading_label.text = "Loading…"
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_loading_label.add_theme_font_size_override("font_size", 48)
	_loading_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	_loading_label.anchor_right = 1.0
	_loading_label.anchor_bottom = 1.0
	_loading_label.offset_bottom = -40
	add_child(_loading_label)


# 主入口: 显示 loading → 切换场景 → 隐藏 loading
func change_scene(path: String):
	if _is_transitioning:
		return
	_is_transitioning = true
	
	# 显示 loading（在当前帧渲染出来）
	show()
	await get_tree().process_frame  # 保证 loading 被绘制到屏幕上
	await get_tree().process_frame  # 额外一帧确保渲染完成
	
	# 执行场景切换（阻塞，但 loading 已显示所以用户有反馈）
	var err = get_tree().change_scene_to_file(path)
	
	# 新场景就绪，隐藏 loading
	_is_transitioning = false
	hide()
	
	if err != OK:
		push_error("SceneManager: 场景切换失败: ", path)


# 针对已缓存的 PackedScene 的重载
func change_scene_packed(packed_scene: PackedScene):
	if _is_transitioning:
		return
	_is_transitioning = true
	
	show()
	await get_tree().process_frame
	await get_tree().process_frame
	
	get_tree().change_scene_to_packed(packed_scene)
	
	_is_transitioning = false
	hide()
