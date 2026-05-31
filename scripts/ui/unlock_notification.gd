extends Control
# Unlock notification popup — modal overlay on main menu when new content is unlocked.

const UnlockTypes = preload("res://scripts/data/unlock_types.gd")
# Unlock data loaded lazily via DataRegistry

signal dismissed

var _pending_data: Array = []


func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	mouse_filter = MOUSE_FILTER_STOP
	anchor_right = 1.0
	anchor_bottom = 1.0
	visible = false


func check_and_show():
	var new_unlocks = UnlockManager.get_newly_unlocked()
	if new_unlocks.is_empty():
		return

	_pending_data = []
	for uid in new_unlocks:
		var defn = DataRegistry.unlocks().get_def(uid)
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
	card.offset_top = -280.0
	card.offset_right = card_w / 2.0
	card.offset_bottom = 90.0  # taller to leave room for scrolling
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

	# 可滚动区域（解锁条目较多时不溢出）
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)

	var entry_vb = VBoxContainer.new()
	entry_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry_vb.add_theme_constant_override("separation", 6)
	scroll.add_child(entry_vb)

	# 解锁条目
	for item in _pending_data:
		var defn = item["def"]

		# ── 每个条目用纵向容器：条件 + 解锁项 ──
		var entry_vbox = VBoxContainer.new()
		entry_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry_vbox.add_theme_constant_override("separation", 2)
		entry_vb.add_child(entry_vbox)

		# 顶部留空
		var top_pad = Control.new()
		top_pad.custom_minimum_size = Vector2(0, 2)
		entry_vbox.add_child(top_pad)

		# 条件描述行
		var cond_hb = HBoxContainer.new()
		cond_hb.add_theme_constant_override("separation", 6)
		entry_vbox.add_child(cond_hb)

		var cond_icon = Label.new()
		cond_icon.text = "⚡"
		cond_icon.add_theme_font_size_override("font_size", 14)
		cond_icon.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2, 0.7))
		cond_hb.add_child(cond_icon)

		var cond_label = Label.new()
		var cond_texts = []
		for c in defn.conditions:
			cond_texts.append(c.description())
		cond_label.text = "  ".join(cond_texts)
		cond_label.add_theme_font_size_override("font_size", 13)
		cond_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.75))
		cond_hb.add_child(cond_label)

		# 解锁项行
		var item_hb = HBoxContainer.new()
		item_hb.alignment = BoxContainer.ALIGNMENT_CENTER
		item_hb.add_theme_constant_override("separation", 10)
		item_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry_vbox.add_child(item_hb)

		var indicator = ColorRect.new()
		indicator.custom_minimum_size = Vector2(8, 28)
		indicator.color = _type_color(defn.unlock_type)
		item_hb.add_child(indicator)

		var arrow_label = Label.new()
		arrow_label.text = "▶"
		arrow_label.add_theme_font_size_override("font_size", 16)
		arrow_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.6))
		item_hb.add_child(arrow_label)

		var name_label = Label.new()
		var name = I18N.t(defn.name_key, str(defn.target_id))
		var type_name = _type_name(defn.unlock_type)
		name_label.text = type_name + I18N.t("unlock.separator") + name
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", _type_color(defn.unlock_type))
		item_hb.add_child(name_label)

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
	UnlockManager.mark_all_seen()
	visible = false
	_clear()
	dismissed.emit()


func _type_color(ut: int) -> Color:
	match ut:
		UnlockTypes.UnlockableType.STAGE:
			return Color(0.3, 0.8, 0.4)
		UnlockTypes.UnlockableType.ARCANA:
			return Color(0.9, 0.7, 0.2)
		UnlockTypes.UnlockableType.CHARACTER:
			return Color(0.3, 0.5, 0.9)
		UnlockTypes.UnlockableType.ITEM:
			return Color(0.8, 0.3, 0.6)
	return Color.WHITE


func _type_name(ut: int) -> String:
	match ut:
		UnlockTypes.UnlockableType.STAGE:
			return I18N.t("unlock.type_stage")
		UnlockTypes.UnlockableType.ARCANA:
			return I18N.t("unlock.type_arcana")
		UnlockTypes.UnlockableType.CHARACTER:
			return I18N.t("unlock.type_character")
		UnlockTypes.UnlockableType.ITEM:
			return I18N.t("unlock.type_item")
	return ""


func _clear():
	for c in get_children():
		c.queue_free()
