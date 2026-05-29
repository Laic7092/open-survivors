extends Control

const StageDefs = preload("res://scripts/data/stage_defs.gd")
const UiUtils = preload("res://scripts/ui/ui_utils.gd")

# Responsive refs
var _scroll: ScrollContainer
var _card_container: VBoxContainer
var _toggle_bar: HBoxContainer
var _back_btn: Button
var _title: Label
var _hurry_btn: Button
var _endless_btn: Button
var _music_btn: Button
var _arcana_btn: Button

var _scale: float = 1.0
var _card_rows: Array = []  # HBoxContainer rows


func _ready():
	anchor_right = 1.0
	anchor_bottom = 1.0
	_build_ui()
	_apply_responsive()


func _notification(what):
	if what == NOTIFICATION_RESIZED and _card_container != null:
		_apply_responsive()


func _build_ui():
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# Title
	_title = Label.new()
	_title.text = I18N.t("stage_select.title")
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	add_child(_title)

	# Scroll area for stage cards
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(_scroll)

	_card_container = VBoxContainer.new()
	_card_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_card_container.add_theme_constant_override("separation", 12)
	_scroll.add_child(_card_container)

	# Cards are built in _apply_responsive (row wrapping)
	# Toggle bar (mode switches) — below cards
	_toggle_bar = HBoxContainer.new()
	_toggle_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_toggle_bar)

	_hurry_btn = _build_toggle_button(I18N.t("stage_select.hurry"), Color(0.9, 0.5, 0.3))
	_toggle_bar.add_child(_hurry_btn)

	_endless_btn = _build_toggle_button(I18N.t("stage_select.endless"), Color(0.9, 0.3, 0.3))
	_toggle_bar.add_child(_endless_btn)

	_music_btn = _build_toggle_button(I18N.t("stage_select.music"), Color(0.6, 0.4, 0.9))
	_toggle_bar.add_child(_music_btn)

	_arcana_btn = _build_toggle_button(I18N.t("stage_select.arcana"), Color(0.3, 0.9, 0.5))
	_toggle_bar.add_child(_arcana_btn)

	# Back button
	_back_btn = Button.new()
	_back_btn.text = I18N.t("stage_select.back")
	_back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back_btn.pressed.connect(_on_back)
	_back_btn.add_theme_color_override("font_color", Color.WHITE)
	add_child(_back_btn)

	# Connections
	_hurry_btn.toggled.connect(_on_hurry_toggled)
	_endless_btn.toggled.connect(_on_endless_toggled)
	_music_btn.toggled.connect(_on_music_toggled)
	_arcana_btn.toggled.connect(_on_arcana_toggled)


func _apply_responsive():
	var vp = get_viewport().get_visible_rect().size
	if vp.x <= 0 or vp.y <= 0:
		return

	_scale = clamp(vp.y / 720.0, 0.5, 2.5)

	# Title
	var title_size = max(16, int(32 * _scale))
	_title.add_theme_font_size_override("font_size", title_size)
	_title.position = Vector2(vp.x / 2 - 140 * _scale, max(4, 12 * _scale))
	_title.size = Vector2(280 * _scale, max(30, 44 * _scale))

	# Margins and spacing
	var toggle_margin = max(8, 16 * _scale)
	var toggle_h = clamp(28 * _scale, 22, 48)
	var toggle_bar_area = toggle_h + max(40, 56 * _scale)
	var back_btn_area = clamp(40 * _scale, 30, 64) + toggle_margin * 0.5
	var title_h = max(30, 44 * _scale)
	var title_margin = max(4, 12 * _scale)

	# Scroll container: fill between title and toggle bar
	var scroll_top = title_margin + title_h + 8
	_scroll.anchor_left = 0.0
	_scroll.anchor_top = 0.0
	_scroll.anchor_right = 1.0
	_scroll.anchor_bottom = 1.0
	_scroll.offset_left = toggle_margin
	_scroll.offset_top = scroll_top
	_scroll.offset_right = -toggle_margin
	_scroll.offset_bottom = -(toggle_bar_area + back_btn_area + toggle_margin * 0.5)

	# Cards — rebuild rows based on current width
	_rebuild_cards(vp)

	# Toggle bar
	var toggle_fs = max(10, int(14 * _scale))
	_toggle_bar.anchor_left = toggle_margin / vp.x
	_toggle_bar.anchor_top = 1.0
	_toggle_bar.anchor_right = 1.0 - toggle_margin / vp.x
	_toggle_bar.anchor_bottom = 1.0
	_toggle_bar.offset_top = -(toggle_h + max(40, 56 * _scale))
	_toggle_bar.offset_bottom = -(max(40, 56 * _scale))

	for btn in [_hurry_btn, _endless_btn, _music_btn, _arcana_btn]:
		btn.custom_minimum_size = Vector2(0, toggle_h)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", toggle_fs)

	# Enable/disable toggles based on relics
	_hurry_btn.disabled = not RelicManager.has_relic("sorceress_tears")
	_endless_btn.disabled = not RelicManager.has_relic("seventh_trumpet")
	_music_btn.disabled = not RelicManager.has_relic("magic_banger")
	var has_randomazzo = RelicManager.has_relic("randomazzo")
	_arcana_btn.disabled = not has_randomazzo
	if has_randomazzo:
		_arcana_btn.button_pressed = Engine.get_meta("arcanas_enabled", true)
		Engine.set_meta("arcanas_enabled", _arcana_btn.button_pressed)

	# Back button (anchored below toggle bar)
	var btn_w = clamp(140 * _scale, 100, 240)
	var btn_h = clamp(40 * _scale, 30, 64)
	_back_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	_back_btn.add_theme_font_size_override("font_size", max(12, int(16 * _scale)))
	_back_btn.anchor_left = 0.5
	_back_btn.anchor_top = 1.0
	_back_btn.anchor_right = 0.5
	_back_btn.anchor_bottom = 1.0
	_back_btn.offset_left = -btn_w / 2
	_back_btn.offset_right = btn_w / 2
	_back_btn.offset_top = -(back_btn_area + toggle_margin * 0.2)
	_back_btn.offset_bottom = -(back_btn_area - btn_h - toggle_margin * 0.2)
	# Style back button
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.2, 0.2, 0.3)
	s.border_width_left = 2; s.border_width_right = 2
	s.border_width_top = 2; s.border_width_bottom = 2
	s.border_color = Color(0.4, 0.4, 0.6)
	s.corner_radius_top_left = 6; s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6; s.corner_radius_bottom_right = 6
	_back_btn.add_theme_stylebox_override("normal", s)
	_back_btn.add_theme_stylebox_override("hover", s)


func _rebuild_cards(vp: Vector2):
	# Clear old cards
	for c in _card_container.get_children():
		c.queue_free()
	_card_rows.clear()

	var stages = StageDefs.STAGES
	var margin = max(8, 16 * _scale)
	var avail_w = vp.x - margin * 2
	var card_min_w = max(180, 220 * _scale)
	var gap = max(8, 14 * _scale)

	# Determine how many cards per row
	var cols = max(1, int(avail_w / (card_min_w + gap)))
	var card_w = (avail_w - (cols - 1) * gap) / cols
	var card_h = clamp(320 * _scale, 260, 400)

	# Layout cards in rows
	var row: HBoxContainer = null
	for i in range(stages.size()):
		if i % cols == 0:
			row = HBoxContainer.new()
			row.add_theme_constant_override("separation", gap)
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_card_container.add_child(row)
			_card_rows.append(row)

		var stage = stages[i]
		_add_card(stage, card_w, card_h, row)



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
	nm.add_theme_font_size_override("font_size", max(12, int(18 * _scale)))
	nm.add_theme_color_override("font_color", Color.WHITE if unlocked else Color(0.4, 0.4, 0.4))
	card.add_child(nm)

	# Modifier icons row
	var mod_row = HBoxContainer.new()
	mod_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mod_row.add_theme_constant_override("separation", 6)
	card.add_child(mod_row)

	# Move speed
	var ms_mod = stage.get("move_speed_mod", 1.0)
	if ms_mod != 1.0:
		var ms_lbl = Label.new()
		ms_lbl.text = "🏃+" + str(int((ms_mod - 1.0) * 100)) + "%"
		ms_lbl.add_theme_font_size_override("font_size", max(8, int(11 * _scale)))
		ms_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
		mod_row.add_child(ms_lbl)

	# Gold
	var g_mod = stage.get("gold_mod", 1.0)
	if g_mod != 1.0:
		var g_lbl = Label.new()
		g_lbl.text = "💰+" + str(int((g_mod - 1.0) * 100)) + "%"
		g_lbl.add_theme_font_size_override("font_size", max(8, int(11 * _scale)))
		g_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.1))
		mod_row.add_child(g_lbl)

	# Time
	var time_min = int(stage["time_limit"] / 60)
	var time_lbl = Label.new()
	time_lbl.text = "⏱" + str(time_min) + "min"
	time_lbl.add_theme_font_size_override("font_size", max(8, int(11 * _scale)))
	time_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.9))
	mod_row.add_child(time_lbl)

	# Description
	var desc = Label.new()
	desc.text = I18N.t("stage." + str(stage_id) + "_desc")
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", max(8, int(11 * _scale)))
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7) if unlocked else Color(0.35, 0.35, 0.35))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(desc)

	card.add_spacer(true)

	# Unlock condition for locked stages
	if not unlocked:
		var req_txt = _get_unlock_text(stage.get("unlock_req", ""))
		var req_lbl = Label.new()
		req_lbl.text = req_txt
		req_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		req_lbl.add_theme_font_size_override("font_size", max(8, int(11 * _scale)))
		req_lbl.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))
		req_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(req_lbl)
	else:
		# Item count hint
		var items = stage.get("stage_items", [])
		if not items.is_empty():
			var item_lbl = Label.new()
			item_lbl.text = "📦 " + str(items.size()) + (" items" if I18N.current_lang == "en" else " 个物品")
			item_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			item_lbl.add_theme_font_size_override("font_size", max(7, int(10 * _scale)))
			item_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			card.add_child(item_lbl)

	# Buttons row: Select + Hyper toggle
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	btn_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.add_child(btn_row)

	# Select / Locked button
	var select_btn = Button.new()
	select_btn.text = I18N.t("stage_select.select") if unlocked else I18N.t("stage_select.locked")
	select_btn.disabled = not unlocked
	var btn_w = w * 0.5
	var btn_h = clamp(30 * _scale, 24, 48)
	select_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	select_btn.add_theme_font_size_override("font_size", max(10, int(14 * _scale)))
	select_btn.add_theme_color_override("font_color", Color.WHITE if unlocked else Color(0.4, 0.4, 0.4))
	UiUtils.style_button(select_btn, bg_col * 0.3 if unlocked else Color(0.15, 0.15, 0.15), bg_col if unlocked else Color(0.3, 0.3, 0.3))
	btn_row.add_child(select_btn)
	if unlocked:
		select_btn.pressed.connect(_on_select.bind(stage))

	# Hyper toggle (only if unlocked)
	if unlocked and has_hyper:
		var hyper_btn = Button.new()
		hyper_btn.text = "⚡HYPER"
		hyper_btn.toggle_mode = true
		hyper_btn.custom_minimum_size = Vector2(btn_w * 0.6, btn_h)
		hyper_btn.add_theme_font_size_override("font_size", max(9, int(12 * _scale)))
		var h_normal = StyleBoxFlat.new()
		h_normal.bg_color = Color(0.3, 0.15, 0.05)
		h_normal.border_width_left = 2; h_normal.border_width_right = 2
		h_normal.border_width_top = 2; h_normal.border_width_bottom = 2
		h_normal.border_color = Color(0.9, 0.5, 0.2)
		h_normal.corner_radius_top_left = 4; h_normal.corner_radius_top_right = 4
		h_normal.corner_radius_bottom_left = 4; h_normal.corner_radius_bottom_right = 4
		hyper_btn.add_theme_stylebox_override("normal", h_normal)
		var h_pressed = StyleBoxFlat.new()
		h_pressed.bg_color = Color(0.9, 0.5, 0.2, 0.3)
		h_pressed.border_width_left = 2; h_pressed.border_width_right = 2
		h_pressed.border_width_top = 2; h_pressed.border_width_bottom = 2
		h_pressed.border_color = Color(0.9, 0.5, 0.2)
		h_pressed.corner_radius_top_left = 4; h_pressed.corner_radius_top_right = 4
		h_pressed.corner_radius_bottom_left = 4; h_pressed.corner_radius_bottom_right = 4
		hyper_btn.add_theme_stylebox_override("pressed", h_pressed)
		hyper_btn.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
		hyper_btn.toggled.connect(_on_hyper_toggled.bind(stage_id))
		btn_row.add_child(hyper_btn)


# ── Toggle button builder ──

func _build_toggle_button(text: String, accent: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.toggle_mode = true
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.08, 0.12)
	normal.border_width_left = 2; normal.border_width_right = 2
	normal.border_width_top = 2; normal.border_width_bottom = 2
	normal.border_color = accent
	normal.corner_radius_top_left = 4; normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4; normal.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", normal)

	var pressed = StyleBoxFlat.new()
	pressed.bg_color = accent * 0.25
	pressed.border_width_left = 2; pressed.border_width_right = 2
	pressed.border_width_top = 2; pressed.border_width_bottom = 2
	pressed.border_color = accent
	pressed.corner_radius_top_left = 4; pressed.corner_radius_top_right = 4
	pressed.corner_radius_bottom_left = 4; pressed.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("pressed", pressed)

	var hover = StyleBoxFlat.new()
	hover.bg_color = accent * 0.15
	hover.border_width_left = 2; hover.border_width_right = 2
	hover.border_width_top = 2; hover.border_width_bottom = 2
	hover.border_color = accent * 1.5
	hover.corner_radius_top_left = 4; hover.corner_radius_top_right = 4
	hover.corner_radius_bottom_left = 4; hover.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("hover", hover)

	btn.add_theme_color_override("font_color", Color.WHITE)
	return btn


# ═══════════════════════════════════════════════════════════
#  Handlers
# ═══════════════════════════════════════════════════════════

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
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_back():
	AudioManager.play_sfx("menu_select")
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")


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
