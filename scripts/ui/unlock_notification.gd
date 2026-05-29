extends Control
# Unlock notification popup — modal overlay on main menu when new content is unlocked.

const UnlockDefs = preload("res://scripts/data/unlock_defs.gd")

signal dismissed

var _pending_data: Array = []


func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	mouse_filter = MOUSE_FILTER_STOP
	anchor_right = 1.0
	anchor_bottom = 1.0
	visible = false


func check_and_show():
	var new_unlocks = _lazy_unlock_manager().get_newly_unlocked()
	if new_unlocks.is_empty():
		return

	_pending_data = []
	for uid in new_unlocks:
		var defn = UnlockDefs.get_def(uid)
		if defn:
			_pending_data.append({"def": defn})

	if _pending_data.is_empty():
		return

	_show_notification()


func _show_notification():
	_clear()
	visible = true

	var vp = get_viewport().get_visible_rect().size

	# 全屏半透明黑色遮罩
	var overlay = ColorRect.new()
	overlay.anchor_left = 0.0
	overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.mouse_filter = MOUSE_FILTER_STOP
	add_child(overlay)

	# 内容卡片 — 居中，带深色背景和边框
	var card_w = min(560, vp.x * 0.85)
	var card = Panel.new()
	card.anchor_left = 0.5
	card.anchor_top = 0.5
	card.anchor_right = 0.5
	card.offset_left = -card_w / 2.0
	card.offset_top = -260.0
	card.offset_right = card_w / 2.0
	card.offset_bottom = 80.0
	card.theme_type_variation = &"CardPanel"
	add_child(card)

	var vb = VBoxContainer.new()
	vb.anchor_left = 0.0
	vb.anchor_top = 0.0
	vb.anchor_right = 1.0
	vb.anchor_bottom = 1.0
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)

	# 间距
	var pad = Control.new()
	pad.custom_minimum_size = Vector2(0, 12)
	vb.add_child(pad)

	# 标题
	var title = Label.new()
	title.text = I18N.t("unlock.notification_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	vb.add_child(title)

	# 副标题
	var sub = Label.new()
	sub.text = I18N.t("unlock.notification_subtitle")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vb.add_child(sub)

	# 分隔线
	var sep = ColorRect.new()
	sep.color = Color(0.9, 0.8, 0.2, 0.3)
	sep.custom_minimum_size = Vector2(0, 1)
	sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(sep)

	# 解锁条目
	for item in _pending_data:
		var defn = item["def"]
		var hb = HBoxContainer.new()
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		hb.add_theme_constant_override("separation", 10)
		var indicator = ColorRect.new()
		indicator.custom_minimum_size = Vector2(8, 28)
		indicator.color = _type_color(defn.unlock_type)
		hb.add_child(indicator)
		var name_label = Label.new()
		var name = I18N.t(defn.name_key, str(defn.target_id))
		var type_name = _type_name(defn.unlock_type)
		name_label.text = type_name + I18N.t("unlock.separator") + name
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", _type_color(defn.unlock_type))
		hb.add_child(name_label)
		vb.add_child(hb)

	# 弹性撑开
	vb.add_spacer(true)

	# 底部间距
	var pad2 = Control.new()
	pad2.custom_minimum_size = Vector2(0, 8)
	vb.add_child(pad2)

	# Continue 按钮
	var btn = Button.new()
	btn.text = I18N.t("unlock.continue")
	btn.custom_minimum_size = Vector2(200, 44)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.theme_type_variation = &"PrimaryButton"
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(_on_dismiss)
	vb.add_child(btn)


func _on_dismiss():
	_lazy_unlock_manager().mark_all_seen()
	visible = false
	_clear()
	dismissed.emit()


func _type_color(ut: int) -> Color:
	match ut:
		UnlockDefs.UnlockableType.STAGE:
			return Color(0.3, 0.8, 0.4)
		UnlockDefs.UnlockableType.ARCANA:
			return Color(0.9, 0.7, 0.2)
		UnlockDefs.UnlockableType.CHARACTER:
			return Color(0.3, 0.5, 0.9)
	return Color.WHITE


func _type_name(ut: int) -> String:
	match ut:
		UnlockDefs.UnlockableType.STAGE:
			return I18N.t("unlock.type_stage")
		UnlockDefs.UnlockableType.ARCANA:
			return I18N.t("unlock.type_arcana")
		UnlockDefs.UnlockableType.CHARACTER:
			return I18N.t("unlock.type_character")
	return ""


func _clear():
	for c in get_children():
		c.queue_free()


# UnlockManager 延迟加载
var _unlock_manager: Node = null

func _lazy_unlock_manager() -> Node:
	if _unlock_manager == null:
		_unlock_manager = load("res://scripts/managers/unlock_manager.gd").new()
		add_child(_unlock_manager)
		EventBus.register_unlock_manager(_unlock_manager)
	return _unlock_manager
