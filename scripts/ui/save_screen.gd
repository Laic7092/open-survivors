extends Control

signal slot_selected(slot_id: String)
signal slot_created(slot_id: String)
signal closed

@onready var _title: Label = %Title
@onready var _back_btn: Button = %BackBtn

@onready var _slot_buttons: Array[Button] = [%SlotBtn1, %SlotBtn2, %SlotBtn3]
@onready var _slot_delete_btns: Array[Button] = [%SlotDel1, %SlotDel2, %SlotDel3]
@onready var _slot_info_labels: Array[Label] = [%SlotInfo1, %SlotInfo2, %SlotInfo3]
@onready var _slot_detail_labels: Array[Label] = [%SlotDetail1, %SlotDetail2, %SlotDetail3]


func _ready():
	visible = false
	_title.text = I18N.t("save_slot.select_title")
	_title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2, 1))
	_back_btn.text = I18N.t("save_slot.back", "BACK")
	_back_btn.pressed.connect(_on_back)
	for i in range(3):
		var slot_id = str(i + 1)
		_slot_buttons[i].pressed.connect(_on_slot_action.bind(slot_id))
		_slot_delete_btns[i].pressed.connect(_on_delete_slot.bind(slot_id))
		_slot_detail_labels[i].add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))


func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		closed.emit()
		get_viewport().set_input_as_handled()


func show_screen():
	visible = true
	_refresh_slots()


func hide_screen():
	visible = false


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
			del.visible = not is_current
		else:
			info_lbl.text = I18N.t("save_slot.empty")
			info_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			detail_lbl.text = ""
			btn.text = I18N.t("save_slot.create")
			del.visible = false


func _on_slot_action(slot_id: String):
	if SaveManager.is_slot_occupied(slot_id):
		slot_selected.emit(slot_id)
	else:
		slot_created.emit(slot_id)


func _on_delete_slot(slot_id: String):
	SaveManager.delete_slot(slot_id)
	_refresh_slots()


func _on_back():
	closed.emit()
