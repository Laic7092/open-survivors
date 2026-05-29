extends Control

const StageDefs = preload("res://scripts/data/stage_defs.gd")
const UiUtils = preload("res://scripts/ui/ui_utils.gd")

@onready var _title: Label = %Title
@onready var _scroll: ScrollContainer = %Scroll
@onready var _card_container: VBoxContainer = %CardContainer
@onready var _toggle_bar: HBoxContainer = %ToggleBar
@onready var _back_btn: Button = %BackBtn
@onready var _hurry_btn: Button = %HurryBtn
@onready var _endless_btn: Button = %EndlessBtn
@onready var _music_btn: Button = %MusicBtn
@onready var _arcana_btn: Button = %ArcanaBtn


func _ready():
	_title.text = I18N.t("stage_select.title")
	_back_btn.text = I18N.t("stage_select.back")
	_hurry_btn.text = I18N.t("stage_select.hurry")
	_endless_btn.text = I18N.t("stage_select.endless")
	_music_btn.text = I18N.t("stage_select.music")
	_arcana_btn.text = I18N.t("stage_select.arcana")

	_back_btn.pressed.connect(_on_back)
	_hurry_btn.toggled.connect(_on_hurry_toggled)
	_endless_btn.toggled.connect(_on_endless_toggled)
	_music_btn.toggled.connect(_on_music_toggled)
	_arcana_btn.toggled.connect(_on_arcana_toggled)

	_rebuild_cards()
	_update_toggle_states()


func _notification(what):
	if what == NOTIFICATION_RESIZED and _card_container:
		_rebuild_cards()


func _update_toggle_states():
	_hurry_btn.disabled = not RelicManager.has_relic("sorceress_tears")
	_endless_btn.disabled = not RelicManager.has_relic("seventh_trumpet")
	_music_btn.disabled = not RelicManager.has_relic("magic_banger")
	var has_randomazzo = RelicManager.has_relic("randomazzo")
	_arcana_btn.disabled = not has_randomazzo
	if has_randomazzo:
		_arcana_btn.button_pressed = Engine.get_meta("arcanas_enabled", true)
		Engine.set_meta("arcanas_enabled", _arcana_btn.button_pressed)


func _rebuild_cards():
	for c in _card_container.get_children():
		c.queue_free()

	var vp = get_viewport().get_visible_rect().size
	var stages = StageDefs.STAGES
	var avail_w = vp.x - 32.0  # scroll margins
	var card_min_w = 200.0
	var gap = 14.0

	var cols = max(1, int(avail_w / (card_min_w + gap)))
	var card_w = (avail_w - (cols - 1) * gap) / cols
	var card_h = clamp(300.0, 260, 400)

	var row: HBoxContainer = null
	for i in range(stages.size()):
		if i % cols == 0:
			row = HBoxContainer.new()
			row.add_theme_constant_override("separation", gap)
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_card_container.add_child(row)

		var stage = stages[i]
		_add_card(stage, card_w, card_h, row)

	_update_toggle_states()


func _add_card(stage: Dictionary, w: float, h: float, parent: Container):
	var stage_id = stage["id"]
	var unlocked = PowerUpManager.has_unlocked_stage(stage_id)
	var has_hyper = PowerUpManager.has_hyper(stage_id)
	var bg_col = stage["bg_color"]

	var card = VBoxContainer.new()
	card.custom_minimum_size = Vector2(w, h)
	card.size = Vector2(w, h)
	card.add_theme_constant_override("separation", 2)
	parent.add_child(card)

	# Decorative bar
	var bar = ColorRect.new()
	bar.color = bg_col
	bar.custom_minimum_size = Vector2(0, 3)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(bar)

	# Name
	var nm = Label.new()
	nm.text = I18N.t("stage." + str(stage_id) + "_name")
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 18)
	nm.add_theme_color_override("font_color", Color.WHITE if unlocked else Color(0.4, 0.4, 0.4))
	card.add_child(nm)

	# Modifier icons row
	var mod_row = HBoxContainer.new()
	mod_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mod_row.add_theme_constant_override("separation", 6)
	card.add_child(mod_row)

	var ms_mod = stage.get("move_speed_mod", 1.0)
	if ms_mod != 1.0:
		var ms_lbl = Label.new()
		ms_lbl.text = "🏃+" + str(int((ms_mod - 1.0) * 100)) + "%"
		ms_lbl.add_theme_font_size_override("font_size", 11)
		ms_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
		mod_row.add_child(ms_lbl)

	var g_mod = stage.get("gold_mod", 1.0)
	if g_mod != 1.0:
		var g_lbl = Label.new()
		g_lbl.text = "💰+" + str(int((g_mod - 1.0) * 100)) + "%"
		g_lbl.add_theme_font_size_override("font_size", 11)
		g_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.1))
		mod_row.add_child(g_lbl)

	var time_min = int(stage["time_limit"] / 60)
	var time_lbl = Label.new()
	time_lbl.text = "⏱" + str(time_min) + "min"
	time_lbl.add_theme_font_size_override("font_size", 11)
	time_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.9))
	mod_row.add_child(time_lbl)

	# Description
	var desc = Label.new()
	desc.text = I18N.t("stage." + str(stage_id) + "_desc")
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7) if unlocked else Color(0.35, 0.35, 0.35))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(desc)

	card.add_spacer(true)

	if not unlocked:
		var req_txt = _get_unlock_text(stage.get("unlock_req", ""))
		var req_lbl = Label.new()
		req_lbl.text = req_txt
		req_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		req_lbl.add_theme_font_size_override("font_size", 11)
		req_lbl.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))
		req_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(req_lbl)
	else:
		var items = stage.get("stage_items", [])
		if not items.is_empty():
			var item_lbl = Label.new()
			item_lbl.text = I18N.t("stage_select.items") % items.size()
			item_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			item_lbl.add_theme_font_size_override("font_size", 10)
			item_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			card.add_child(item_lbl)

	# Buttons row: Select + Hyper toggle
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	btn_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.add_child(btn_row)

	var select_btn = Button.new()
	select_btn.text = I18N.t("stage_select.select") if unlocked else I18N.t("stage_select.locked")
	select_btn.disabled = not unlocked
	var btn_w = w * 0.5
	var btn_h = 30.0
	select_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	select_btn.add_theme_font_size_override("font_size", 14)
	select_btn.add_theme_color_override("font_color", Color.WHITE if unlocked else Color(0.4, 0.4, 0.4))
	select_btn.theme_type_variation = &"PrimaryButton"
	btn_row.add_child(select_btn)
	if unlocked:
		select_btn.pressed.connect(_on_select.bind(stage))

	if unlocked and has_hyper:
		var hyper_btn = Button.new()
		hyper_btn.text = I18N.t("stage_select.hyper")
		hyper_btn.toggle_mode = true
		hyper_btn.custom_minimum_size = Vector2(btn_w * 0.6, btn_h)
		hyper_btn.add_theme_font_size_override("font_size", 12)
		hyper_btn.theme_type_variation = &"ToggleButton"
		hyper_btn.toggled.connect(_on_hyper_toggled.bind(stage_id))
		btn_row.add_child(hyper_btn)


func _get_unlock_text(req: String) -> String:
	match req:
		"clear_stage_0": return I18N.t("stage_select.unlock_0")
		"clear_stage_1": return I18N.t("stage_select.unlock_1")
		"clear_stage_2": return I18N.t("stage_select.unlock_2")
		"clear_stage_3": return I18N.t("stage_select.unlock_3")
		"clear_stage_4": return I18N.t("stage_select.unlock_4")
		"clear_stage_5": return I18N.t("stage_select.unlock_5")
		"reach_level_30": return I18N.t("stage_select.reach_30")
		"reach_level_40": return I18N.t("stage_select.reach_40")
		"reach_level_50": return I18N.t("stage_select.reach_50")
		"reach_level_55": return I18N.t("stage_select.reach_55")
		"reach_level_60": return I18N.t("stage_select.reach_60")
		"reach_level_65": return I18N.t("stage_select.reach_65")
		"relic_yellow_sign": return I18N.t("stage_select.relic_yellow")
		_: return ""


func _on_select(stage_data: Dictionary):
	AudioManager.play_sfx("menu_confirm")
	Engine.set_meta("selected_stage", stage_data)
	SceneManager.change_scene("res://scenes/main.tscn")


func _on_back():
	AudioManager.play_sfx("menu_select")
	SceneManager.change_scene("res://scenes/character_select.tscn")


func _on_hyper_toggled(toggled_on: bool, _stage_id: int):
	AudioManager.play_sfx("menu_select")
	Engine.set_meta("hyper_mode", toggled_on)


func _on_hurry_toggled(toggled_on: bool):
	AudioManager.play_sfx("menu_select")
	Engine.set_meta("hurry_mode", toggled_on)


func _on_endless_toggled(toggled_on: bool):
	AudioManager.play_sfx("menu_select")
	Engine.set_meta("endless_mode", toggled_on)


func _on_music_toggled(toggled_on: bool):
	AudioManager.play_sfx("menu_select")
	Engine.set_meta("alt_music", toggled_on)


func _on_arcana_toggled(toggled_on: bool):
	AudioManager.play_sfx("menu_select")
	Engine.set_meta("arcanas_enabled", toggled_on)
