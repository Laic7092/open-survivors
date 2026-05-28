extends Control

const StageDefs = preload("res://scripts/data/stage_defs.gd")


func _ready():
	anchor_right = 1.0
	anchor_bottom = 1.0
	_show()


func _show():
	_clear()
	var vp = get_viewport().get_visible_rect().size

	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# Title
	var title = Label.new()
	title.text = I18N.t("stage_select.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	title.position = Vector2(vp.x / 2 - 140, 25)
	title.size = Vector2(280, 50)
	add_child(title)

	# Stage cards
	var stages = StageDefs.STAGES
	var card_w = 340
	var card_h = 280
	var gap = 24
	var total_w = stages.size() * card_w + (stages.size() - 1) * gap
	var start_x = (vp.x - total_w) / 2
	var start_y = vp.y / 2 - card_h / 2 - 10

	for i in range(stages.size()):
		var s = stages[i]
		_add_stage_card(s, Vector2(start_x + i * (card_w + gap), start_y), card_w, card_h)

	# Back button
	var back_btn = Button.new()
	back_btn.text = I18N.t("stage_select.back")
	back_btn.custom_minimum_size = Vector2(140, 40)
	back_btn.position = Vector2(vp.x / 2 - 70, vp.y - 55)
	back_btn.pressed.connect(_on_back)
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.2, 0.2, 0.3)
	s.border_width_left = 2; s.border_width_right = 2
	s.border_width_top = 2; s.border_width_bottom = 2
	s.border_color = Color(0.4, 0.4, 0.6)
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	back_btn.add_theme_stylebox_override("normal", s)
	back_btn.add_theme_stylebox_override("hover", s)
	back_btn.add_theme_color_override("font_color", Color.WHITE)
	back_btn.add_theme_font_size_override("font_size", 16)
	add_child(back_btn)


func _add_stage_card(stage_data: Dictionary, pos: Vector2, w: int, h: int):
	var stage_id = stage_data["id"]
	var unlocked = PowerUpManager.has_unlocked_stage(stage_id)
	
	var card = VBoxContainer.new()
	card.position = pos
	card.size = Vector2(w, h)
	card.add_theme_constant_override("separation", 4)
	add_child(card)

	var bg_col = stage_data["bg_color"]

	# Color accent bar
	var bar = ColorRect.new()
	bar.color = bg_col
	bar.size = Vector2(w, 4)
	card.add_child(bar)

	# Stage icon (colored rect with stage name initial)
	var icon_box = Control.new()
	icon_box.custom_minimum_size = Vector2(0, 80)
	card.add_child(icon_box)
	var icon_draw = func():
		var cx = icon_box.size.x / 2
		var cy = 40.0
		icon_box.draw_rect(Rect2(cx - 30, cy - 30, 60, 60), bg_col * 1.5)
		icon_box.draw_rect(Rect2(cx - 30, cy - 30, 60, 60), Color(1, 1, 1, 0.3), false, 2)
		# Lock icon overlay
		if not unlocked:
			icon_box.draw_circle(Vector2(cx, cy), 24, Color(0.1, 0.1, 0.1, 0.7))
			icon_box.draw_string(ThemeDB.fallback_font, Vector2(cx - 10, cy + 6), "🔒", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	icon_box.draw.connect(icon_draw)

	# Stage name
	var nm = Label.new()
	nm.text = I18N.t("stage." + str(stage_id) + "_name")
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 22)
	nm.add_theme_color_override("font_color", Color.WHITE if unlocked else Color(0.4, 0.4, 0.4))
	card.add_child(nm)

	# Description
	var desc = Label.new()
	desc.text = I18N.t("stage." + str(stage_id) + "_desc")
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7) if unlocked else Color(0.35, 0.35, 0.35))
	card.add_child(desc)

	# Time limit display
	var time_min = int(stage_data["time_limit"] / 60)
	var time_sec = int(stage_data["time_limit"]) % 60
	var time_lbl = Label.new()
	time_lbl.text = I18N.t("stage_select.time") % [time_min, time_sec]
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_lbl.add_theme_font_size_override("font_size", 14)
	time_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0) if unlocked else Color(0.4, 0.4, 0.5))
	card.add_child(time_lbl)

	card.add_spacer(true)

	# Unlock condition text for locked stages
	if not unlocked:
		var req_txt = _get_unlock_text(stage_data.get("unlock_req", ""))
		var req_lbl = Label.new()
		req_lbl.text = req_txt
		req_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		req_lbl.add_theme_font_size_override("font_size", 11)
		req_lbl.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))
		req_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(req_lbl)

	# Select button
	var btn = Button.new()
	btn.text = I18N.t("stage_select.select") if unlocked else I18N.t("stage_select.locked")
	btn.disabled = not unlocked
	btn.custom_minimum_size = Vector2(0, 36)
	var btn_s = StyleBoxFlat.new()
	btn_s.bg_color = bg_col * 0.3 if unlocked else Color(0.15, 0.15, 0.15)
	btn_s.border_width_left = 2; btn_s.border_width_right = 2
	btn_s.border_width_top = 2; btn_s.border_width_bottom = 2
	btn_s.border_color = bg_col * 1.5 if unlocked else Color(0.3, 0.3, 0.3)
	btn_s.corner_radius_top_left = 6
	btn_s.corner_radius_top_right = 6
	btn_s.corner_radius_bottom_left = 6
	btn_s.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", btn_s)
	btn.add_theme_stylebox_override("hover", btn_s)
	btn.add_theme_color_override("font_color", Color.WHITE if unlocked else Color(0.4, 0.4, 0.4))
	btn.add_theme_font_size_override("font_size", 16)
	card.add_child(btn)

	if unlocked:
		btn.pressed.connect(_on_select.bind(stage_data))


func _get_unlock_text(req: String) -> String:
	match req:
		"clear_stage_0": return I18N.t("stage_select.unlock_0")
		"clear_stage_1": return I18N.t("stage_select.unlock_1")
		_: return ""


func _on_select(stage_data: Dictionary):
	AudioManager.play_sfx("menu_confirm")
	Engine.set_meta("selected_stage", stage_data)
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_back():
	AudioManager.play_sfx("menu_select")
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")


func _clear():
	for c in get_children():
		c.queue_free()
