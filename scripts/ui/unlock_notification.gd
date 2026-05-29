extends Control
# Unlock notification popup — shown on main menu when new content is unlocked.
# Displays a list of newly unlocked items with icons and names.

const UnlockDefs = preload("res://scripts/data/unlock_defs.gd")

signal dismissed

var _pending_data: Array = []  # [{unlock_id, unlock_type}]


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	mouse_filter = MOUSE_FILTER_STOP
	anchor_right = 1.0
	anchor_bottom = 1.0
	visible = false


# Call this when entering the main menu to check for new unlocks
func check_and_show():
	var new_unlocks = UnlockManager.get_newly_unlocked()
	if new_unlocks.is_empty():
		return
	
	# Build display data
	_pending_data = []
	for uid in new_unlocks:
		var defn = UnlockDefs.get_def(uid)
		if defn:
			_pending_data.append({"def": defn})
	
	if _pending_data.is_empty():
		return
	
	_show_notification()


func _show_notification():
	visible = true
	_clear()
	
	var vp = get_viewport().get_visible_rect().size
	
	# Dim backdrop
	var panel = Panel.new()
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	add_child(panel)
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.85)
	panel.add_theme_stylebox_override("panel", bg)
	
	# Calculate needed height based on item count
	var item_count = _pending_data.size()
	var content_h = 40 + 12 + 20 + 12 + 8 + 12  # title + sep + subtitle + sep + spacer + sep
	content_h += item_count * (40 + 12)          # items + sep each
	content_h += 12 + 12 + 44 + 20               # spacer2 + sep + button + padding
	var panel_h = min(content_h, vp.y * 0.85)
	var panel_w = min(580, vp.x * 0.85)
	
	# Content container — use anchors, no fixed height
	var vb = VBoxContainer.new()
	vb.anchor_left = 0.5
	vb.anchor_top = 0.5
	vb.anchor_right = 0.5
	vb.anchor_bottom = 0.5
	vb.offset_left = -panel_w / 2.0
	vb.offset_top = -panel_h / 2.0
	vb.offset_right = panel_w / 2.0
	vb.offset_bottom = panel_h / 2.0
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	
	# Title
	var title = Label.new()
	title.text = I18N.t("unlock.notification_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	title.custom_minimum_size = Vector2(560, 40)
	vb.add_child(title)
	
	# Subtitle
	var sub = Label.new()
	sub.text = I18N.t("unlock.notification_subtitle")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	sub.custom_minimum_size = Vector2(560, 20)
	vb.add_child(sub)
	
	# Spacer
	var sp = Control.new()
	sp.custom_minimum_size = Vector2(0, 8)
	vb.add_child(sp)
	
	# Item list
	for item in _pending_data:
		var defn = item["def"]
		var hb = HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		hb.custom_minimum_size = Vector2(0, 40)
		
		# Color indicator
		var indicator = ColorRect.new()
		indicator.custom_minimum_size = Vector2(8, 32)
		indicator.size = Vector2(8, 32)
		indicator.color = _type_color(defn.unlock_type)
		hb.add_child(indicator)
		
		# Name
		var name_label = Label.new()
		var name = I18N.t(defn.name_key, str(defn.target_id))
		var type_name = _type_name(defn.unlock_type)
		name_label.text = type_name + ": " + name
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", _type_color(defn.unlock_type))
		hb.add_child(name_label)
		
		vb.add_child(hb)
	
	# Spacer
	var sp2 = Control.new()
	sp2.custom_minimum_size = Vector2(0, 12)
	vb.add_child(sp2)
	
	# Dismiss button
	var btn = Button.new()
	btn.text = I18N.t("unlock.continue")
	btn.custom_minimum_size = Vector2(200, 44)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var btn_s = StyleBoxFlat.new()
	btn_s.bg_color = Color(0.2, 0.3, 0.2)
	btn_s.border_width_left = 2; btn_s.border_width_right = 2
	btn_s.border_width_top = 2; btn_s.border_width_bottom = 2
	btn_s.border_color = Color(0.3, 0.9, 0.3)
	btn_s.corner_radius_top_left = 6; btn_s.corner_radius_top_right = 6
	btn_s.corner_radius_bottom_left = 6; btn_s.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", btn_s)
	btn.add_theme_stylebox_override("hover", btn_s)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(_on_dismiss)
	vb.add_child(btn)


func _on_dismiss():
	# Mark all as seen
	UnlockManager.mark_all_seen()
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
