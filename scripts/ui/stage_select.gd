extends Control

const UiUtils = preload("res://scripts/ui/ui_utils.gd")

@onready var _title: Label = %Title
@onready var _scroll: ScrollContainer = %Scroll
@onready var _card_container: VBoxContainer = %CardContainer
@onready var _left_panel: VBoxContainer = %LeftPanel
@onready var _toggle_bar: VBoxContainer = %ToggleBar
@onready var _back_btn: Button = %BackBtn
@onready var _hurry_btn: Button = %HurryBtn
@onready var _endless_btn: Button = %EndlessBtn
@onready var _music_btn: Button = %MusicBtn
@onready var _arcana_btn: Button = %ArcanaBtn

@onready var _stage_name: Label = %StageName
@onready var _stage_mods: Label = %StageMods
@onready var _stage_time: Label = %StageTime
@onready var _stage_desc: Label = %StageDesc
@onready var _stage_items: Label = %StageItems
@onready var _start_btn: Button = %StartBtn

var _inverse_btn: Button
var _random_events_btn: Button
var _random_upgrade_btn: Button
var _hyper_btn: Button

var _selected_stage: Dictionary = {}


func _ready():
	_title.text = I18N.t("stage_select.title")
	_back_btn.text = I18N.t("stage_select.back")
	_start_btn.text = I18N.t("stage_select.start")
	_hurry_btn.text = I18N.t("stage_select.hurry")
	_endless_btn.text = I18N.t("stage_select.endless")
	_music_btn.text = I18N.t("stage_select.music")
	_arcana_btn.text = I18N.t("stage_select.arcana")

	_back_btn.pressed.connect(_on_back)
	_hurry_btn.toggled.connect(_on_hurry_toggled)
	_endless_btn.toggled.connect(_on_endless_toggled)
	_music_btn.toggled.connect(_on_music_toggled)
	_arcana_btn.toggled.connect(_on_arcana_toggled)
	_start_btn.pressed.connect(_on_start)

	_add_extra_toggles()
	_clear_info_panel()
	_rebuild_cards()
	_update_toggle_states()


func _clear_info_panel():
	_stage_name.text = ""
	_stage_mods.text = ""
	_stage_time.text = ""
	_stage_desc.text = I18N.t("stage_select.select_hint")
	_stage_items.text = ""
	_start_btn.disabled = true
	_selected_stage = {}


func _add_extra_toggles():
	_hyper_btn = Button.new()
	_hyper_btn.text = I18N.t("stage_select.hyper")
	_hyper_btn.toggle_mode = true
	_hyper_btn.toggled.connect(_on_hyper_toggled)
	_toggle_bar.add_child(_hyper_btn)

	var toggles := [
		{"name": I18N.t("stage_select.inverse"),    "feature": "inverse_mode",   "config": "inverse_mode"},
		{"name": I18N.t("stage_select.random_events"), "feature": "random_events", "config": "random_events"},
		{"name": I18N.t("stage_select.random_upgrade"), "feature": "random_upgrade", "config": "random_upgrade"},
	]
	for t in toggles:
		var btn = Button.new()
		btn.text = t["name"]
		btn.toggle_mode = true
		btn.disabled = not RelicManager.is_feature_unlocked(t["feature"])
		if not btn.disabled:
			btn.button_pressed = EventBus.get_config(t["config"], false)
		btn.toggled.connect(func(v): EventBus.set_config(t["config"], v))
		_toggle_bar.add_child(btn)
		match t["config"]:
			"inverse_mode": _inverse_btn = btn
			"random_events": _random_events_btn = btn
			"random_upgrade": _random_upgrade_btn = btn


func _update_toggle_states():
	_hurry_btn.disabled = not RelicManager.is_feature_unlocked("hurry_mode")
	_endless_btn.disabled = not RelicManager.is_feature_unlocked("endless_mode")
	_music_btn.disabled = not RelicManager.is_feature_unlocked("alt_music")
	var has_arcana = RelicManager.is_feature_unlocked("arcana_system")
	_arcana_btn.disabled = not has_arcana
	if has_arcana:
		_arcana_btn.button_pressed = EventBus.get_config("arcanas_enabled", true)

	if _inverse_btn:
		_inverse_btn.disabled = not RelicManager.is_feature_unlocked("inverse_mode")
	if _random_events_btn:
		_random_events_btn.disabled = not RelicManager.is_feature_unlocked("random_events")
	if _random_upgrade_btn:
		_random_upgrade_btn.disabled = not RelicManager.is_feature_unlocked("random_upgrade")

	var any_hyper = false
	for s in DataRegistry.stages().get_all_stage_meta():
		if PowerUpManager.has_hyper(s["id"]):
			any_hyper = true
			break
	_hyper_btn.disabled = not any_hyper
	if any_hyper:
		_hyper_btn.button_pressed = EventBus.get_config("hyper_mode", false)


func _rebuild_cards():
	for c in _card_container.get_children():
		c.queue_free()

	var stages = DataRegistry.stages().get_all_stage_meta()
	for stage in stages:
		_add_card(stage, _card_container)

	_update_toggle_states()

	if not stages.is_empty():
		_on_card_selected(stages[0], false)


func _add_card(stage: Dictionary, parent: Container):
	var stage_id = stage["id"]
	var unlocked = PowerUpManager.has_unlocked_stage(stage_id)
	var bg_col = stage["bg_color"]

	var card = HBoxContainer.new()
	card.custom_minimum_size = Vector2(0, 48)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_constant_override("separation", 8)
	card.gui_input.connect(_on_card_input.bind(stage))
	card.mouse_entered.connect(func(): card.modulate = Color(0.85, 0.85, 0.85))
	card.mouse_exited.connect(func(): card.modulate = Color.WHITE)
	parent.add_child(card)

	var bar = ColorRect.new()
	bar.color = bg_col
	bar.custom_minimum_size = Vector2(4, 0)
	bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bar.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(bar)

	var nm = Label.new()
	nm.text = I18N.t("stage." + str(stage_id) + "_name")
	nm.add_theme_font_size_override("font_size", 15)
	nm.add_theme_color_override("font_color", Color.WHITE if unlocked else Color(0.4, 0.4, 0.4))
	nm.custom_minimum_size = Vector2(100, 0)
	nm.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(nm)

	var ms_mod = stage.get("move_speed_mod", 1.0)
	var g_mod = stage.get("gold_mod", 1.0)
	if ms_mod != 1.0 or g_mod != 1.0:
		var mod_lbl = Label.new()
		var parts = []
		if ms_mod != 1.0:
			parts.append("🏃+" + str(int((ms_mod - 1.0) * 100)) + "%")
		if g_mod != 1.0:
			parts.append("💰+" + str(int((g_mod - 1.0) * 100)) + "%")
		mod_lbl.text = " ".join(parts)
		mod_lbl.add_theme_font_size_override("font_size", 10)
		mod_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.4))
		mod_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
		card.add_child(mod_lbl)

	var time_min = int(stage["time_limit"] / 60)
	var time_lbl = Label.new()
	time_lbl.text = "⏱" + str(time_min) + "min"
	time_lbl.add_theme_font_size_override("font_size", 10)
	time_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.9))
	time_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(time_lbl)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(spacer)

	if not unlocked:
		var req_lbl = Label.new()
		req_lbl.text = _get_unlock_text(stage.get("unlock_req", ""))
		req_lbl.add_theme_font_size_override("font_size", 10)
		req_lbl.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))
		req_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
		card.add_child(req_lbl)
	else:
		var items = stage.get("stage_items", [])
		if not items.is_empty():
			var item_lbl = Label.new()
			item_lbl.text = I18N.t("stage_select.items") % items.size()
			item_lbl.add_theme_font_size_override("font_size", 10)
			item_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			item_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
			card.add_child(item_lbl)


func _on_card_input(event: InputEvent, stage: Dictionary):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_card_selected(stage, true)


func _on_card_selected(stage: Dictionary, play_sfx := true):
	if play_sfx:
		AudioManager.play_sfx("menu_select")
	_selected_stage = stage
	var stage_id = stage["id"]
	var unlocked = PowerUpManager.has_unlocked_stage(stage_id)

	_stage_name.text = I18N.t("stage." + str(stage_id) + "_name")

	var mods = []
	var ms_mod = stage.get("move_speed_mod", 1.0)
	if ms_mod != 1.0:
		mods.append("🏃+" + str(int((ms_mod - 1.0) * 100)) + "%")
	var g_mod = stage.get("gold_mod", 1.0)
	if g_mod != 1.0:
		mods.append("💰+" + str(int((g_mod - 1.0) * 100)) + "%")
	_stage_mods.text = "  ".join(mods) if mods else ""

	var time_min = int(stage["time_limit"] / 60)
	_stage_time.text = "⏱" + str(time_min) + "min"

	if unlocked:
		_stage_desc.text = I18N.t("stage." + str(stage_id) + "_desc")

		var items = stage.get("stage_items", [])
		_stage_items.text = I18N.t("stage_select.items") % items.size() if not items.is_empty() else ""

		_start_btn.disabled = false
	else:
		_stage_desc.text = _get_unlock_text(stage.get("unlock_req", ""))
		_stage_items.text = ""
		_start_btn.disabled = true


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
		"reach_level_70": return I18N.t("stage_select.reach_70")
		"reach_level_75": return I18N.t("stage_select.reach_75")
		"reach_level_80": return I18N.t("stage_select.reach_80")
		"relic_yellow_sign": return I18N.t("stage_select.relic_yellow")
		_: return ""


func _on_start():
	if _selected_stage.is_empty():
		return
	AudioManager.play_sfx("menu_confirm")
	var full_data = DataRegistry.stages().get_stage(_selected_stage.get("id", 0))
	EventBus.set_config("selected_stage", full_data)
	SceneManager.change_scene("res://scenes/main.tscn")


func _on_back():
	AudioManager.play_sfx("menu_select")
	SceneManager.change_scene("res://scenes/character_select.tscn")


func _on_hyper_toggled(toggled_on: bool):
	AudioManager.play_sfx("menu_select")
	EventBus.set_config("hyper_mode", toggled_on)


func _on_hurry_toggled(toggled_on: bool):
	AudioManager.play_sfx("menu_select")
	EventBus.set_config("hurry_mode", toggled_on)


func _on_endless_toggled(toggled_on: bool):
	AudioManager.play_sfx("menu_select")
	EventBus.set_config("endless_mode", toggled_on)


func _on_music_toggled(toggled_on: bool):
	AudioManager.play_sfx("menu_select")
	EventBus.set_config("alt_music", toggled_on)


func _on_arcana_toggled(toggled_on: bool):
	AudioManager.play_sfx("menu_select")
	EventBus.set_config("arcanas_enabled", toggled_on)
