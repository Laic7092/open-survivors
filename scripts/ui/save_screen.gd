extends Control
# Save/Load screen — 3 profile save slots.
# Each slot stores full player progress (gold, powerups, relics, etc.)
# Slot 1 is created by default on first launch.

signal slot_selected(slot_id: String)   # user picked a slot
signal slot_created(slot_id: String)    # user created a new slot
signal closed

var _slot_buttons: Array[Button] = []
var _slot_delete_btns: Array[Button] = []
var _slot_info_labels: Array[Label] = []
var _slot_detail_labels: Array[Label] = []
var _built := false


func _ready():
	pass


func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		closed.emit()
		get_viewport().set_input_as_handled()


func show_screen():
	visible = true
	if not _built:
		_build_ui()
		_built = true
	_refresh_slots()


func hide_screen():
	visible = false


func _build_ui():
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# Background dim
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	
	# Panel
	var panel = Panel.new()
	panel.anchor_left = 0.25
	panel.anchor_top = 0.15
	panel.anchor_right = 0.75
	panel.anchor_bottom = 0.85
	add_child(panel)
	
	# Title
	var title = Label.new()
	title.anchor_left = 0.0
	title.anchor_top = 0.0
	title.anchor_right = 1.0
	title.anchor_bottom = 0.0
	title.offset_top = 16
	title.offset_bottom = 60
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2, 1))
	title.text = I18N.t("save_slot.select_title")
	panel.add_child(title)
	
	# Slot list
	var sc = VBoxContainer.new()
	sc.anchor_left = 0.05
	sc.anchor_top = 0.15
	sc.anchor_right = 0.95
	sc.anchor_bottom = 0.85
	sc.add_theme_constant_override("separation", 10)
	panel.add_child(sc)
	
	for i in range(1, 4):
		_build_slot_card(i, sc)
	
	# Back
	var back = Button.new()
	back.anchor_left = 0.5
	back.anchor_top = 1.0
	back.anchor_right = 0.5
	back.anchor_bottom = 1.0
	back.offset_left = -70
	back.offset_top = -60
	back.offset_right = 70
	back.offset_bottom = -16
	back.add_theme_font_size_override("font_size", 15)
	back.text = I18N.t("save_slot.back", "BACK")
	back.pressed.connect(_on_back)
	panel.add_child(back)


func _build_slot_card(idx: int, container: VBoxContainer):
	var slot_id = str(idx)
	
	var card = Panel.new()
	card.custom_minimum_size = Vector2(0, 72)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.name = "SlotCard" + slot_id
	
	var hb = HBoxContainer.new()
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hb.add_theme_constant_override("separation", 10)
	
	# Number
	var num = Label.new()
	num.text = str(idx)
	num.add_theme_font_size_override("font_size", 24)
	num.custom_minimum_size = Vector2(36, 0)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(num)
	
	# Info
	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vb.add_theme_constant_override("separation", 2)
	
	var info = Label.new()
	info.text = ""
	info.add_theme_font_size_override("font_size", 13)
	vb.add_child(info)
	_slot_info_labels.append(info)
	
	var detail = Label.new()
	detail.text = ""
	detail.add_theme_font_size_override("font_size", 10)
	detail.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vb.add_child(detail)
	_slot_detail_labels.append(detail)
	
	hb.add_child(vb)
	
	# Action button
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(90, 36)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 13)
	btn.name = "SlotBtn" + slot_id
	hb.add_child(btn)
	_slot_buttons.append(btn)
	
	# Delete
	var del = Button.new()
	del.custom_minimum_size = Vector2(28, 28)
	del.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	del.add_theme_font_size_override("font_size", 11)
	del.text = "✕"
	del.name = "SlotDel" + slot_id
	hb.add_child(del)
	_slot_delete_btns.append(del)
	
	btn.pressed.connect(_on_slot_action.bind(slot_id))
	del.pressed.connect(_on_delete_slot.bind(slot_id))
	
	card.add_child(hb)
	container.add_child(card)


func _refresh_slots():
	var current = SaveManager.current_slot
	var slots_info = SaveManager.get_slots_info()
	
	for i in range(3):
		var key = str(i + 1)
		var info = slots_info.get(key, {})
		var occupied = info.get("occupied", false)
		var btn = _slot_buttons[i]
		var del = _slot_delete_btns[i]
		var info_lbl = _slot_info_labels[i]
		var detail_lbl = _slot_detail_labels[i]
		
		var is_current = (key == current)
		
		if occupied:
			var gold = info.get("gold", 0)
			var time_str = info.get("time_str", "")
			
			if is_current:
				info_lbl.text = "▶ " + I18N.t("save_slot.current") + " | " + I18N.t("menu.gold") + str(gold)
				info_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
			else:
				info_lbl.text = I18N.t("menu.gold") + str(gold)
				info_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.7))
			
			detail_lbl.text = time_str
			btn.text = I18N.t("save_slot.select")
			del.visible = (not is_current) and (key != "1")  # can't delete current or slot 1
		else:
			info_lbl.text = I18N.t("save_slot.empty")
			info_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			detail_lbl.text = ""
			btn.text = I18N.t("save_slot.create")
			del.visible = false


func _on_slot_action(slot_id: String):
	if SaveManager.is_slot_occupied(slot_id):
		# Switch to this slot
		slot_selected.emit(slot_id)
	else:
		# Create and switch to this slot
		slot_created.emit(slot_id)


func _on_delete_slot(slot_id: String):
	SaveManager.delete_slot(slot_id)
	_refresh_slots()


func _on_back():
	closed.emit()
