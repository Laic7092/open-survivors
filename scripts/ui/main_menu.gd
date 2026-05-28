extends Control


func _ready():
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var vp = get_viewport().get_visible_rect().size

	# Title
	var title = Label.new()
	title.text = I18N.t("menu.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	title.position = Vector2(vp.x / 2 - 200, vp.y / 3 - 30)
	title.size = Vector2(400, 60)
	add_child(title)

	# Subtitle
	var sub = Label.new()
	sub.text = I18N.t("menu.subtitle")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	sub.position = Vector2(vp.x / 2 - 150, vp.y / 3 + 25)
	sub.size = Vector2(300, 30)
	add_child(sub)

	# Separator line
	var line = ColorRect.new()
	line.color = Color(0.9, 0.8, 0.2, 0.4)
	line.position = Vector2(vp.x / 2 - 120, vp.y / 3 + 66)
	line.size = Vector2(240, 2)
	add_child(line)

	var btn_w = 240
	var btn_h = 50
	var btn_x = vp.x / 2 - btn_w / 2
	var y_off = vp.y / 2  # accumulator for rows

	# Start Game button
	var start_btn = Button.new()
	start_btn.text = I18N.t("menu.start_game")
	start_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	start_btn.position = Vector2(btn_x, y_off)
	add_child(start_btn)
	_style_button(start_btn, Color(0.15, 0.5, 0.2), Color(0.25, 0.7, 0.3))
	start_btn.pressed.connect(_on_start_pressed)
	y_off += btn_h + 8

	# Language toggle
	var lang_btn = Button.new()
	lang_btn.text = I18N.t("menu.language")
	lang_btn.custom_minimum_size = Vector2(btn_w, 30)
	lang_btn.position = Vector2(btn_x, y_off)
	add_child(lang_btn)
	_style_button(lang_btn, Color(0.3, 0.2, 0.4), Color(0.4, 0.3, 0.5))
	lang_btn.pressed.connect(_on_language_pressed)
	y_off += 30 + 8

	# Fullscreen toggle
	var fs_btn = Button.new()
	fs_btn.text = _fullscreen_text()
	fs_btn.custom_minimum_size = Vector2(btn_w, 30)
	fs_btn.position = Vector2(btn_x, y_off)
	add_child(fs_btn)
	_style_button(fs_btn, Color(0.3, 0.3, 0.3), Color(0.4, 0.4, 0.4))
	fs_btn.pressed.connect(_on_fullscreen_pressed.bind(fs_btn))
	y_off += 30 + 8

	# Resolution toggle
	var res_btn = Button.new()
	res_btn.text = _resolution_text()
	res_btn.custom_minimum_size = Vector2(btn_w, 30)
	res_btn.position = Vector2(btn_x, y_off)
	add_child(res_btn)
	_style_button(res_btn, Color(0.3, 0.3, 0.3), Color(0.4, 0.4, 0.4))
	res_btn.pressed.connect(_on_resolution_pressed.bind(res_btn))
	y_off += 30 + 8

	# PowerUps button
	var pu_btn = Button.new()
	pu_btn.text = I18N.t("menu.power_ups")
	pu_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	pu_btn.position = Vector2(btn_x, y_off)
	add_child(pu_btn)
	_style_button(pu_btn, Color(0.2, 0.2, 0.5), Color(0.3, 0.3, 0.7))
	pu_btn.pressed.connect(_on_powerups_pressed)
	y_off += btn_h + 8

	# Gold display
	var gold_lbl = Label.new()
	gold_lbl.text = I18N.t("menu.gold") + str(PowerUpManager.gold)
	gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_lbl.add_theme_font_size_override("font_size", 16)
	gold_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.1))
	gold_lbl.position = Vector2(vp.x / 2 - 80, y_off)
	gold_lbl.size = Vector2(160, 24)
	add_child(gold_lbl)
	y_off += 24 + 8

	# Quit button
	var quit_btn = Button.new()
	quit_btn.text = I18N.t("menu.quit")
	quit_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	quit_btn.position = Vector2(btn_x, y_off)
	add_child(quit_btn)
	_style_button(quit_btn, Color(0.5, 0.1, 0.1), Color(0.7, 0.2, 0.2))
	quit_btn.pressed.connect(_on_quit_pressed)

	# Version / footer
	var foot = Label.new()
	foot.text = I18N.t("menu.footer")
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_font_size_override("font_size", 12)
	foot.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	foot.position = Vector2(vp.x / 2 - 100, vp.y - 40)
	foot.size = Vector2(200, 20)
	add_child(foot)

	# Start menu BGM
	call_deferred("play_menu_music")


func _style_button(btn: Button, bg_color: Color, hover_color: Color):
	var normal = StyleBoxFlat.new()
	normal.bg_color = bg_color
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.border_color = bg_color * 1.5
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", normal)

	var hover = StyleBoxFlat.new()
	hover.bg_color = hover_color
	hover.border_width_left = 2
	hover.border_width_right = 2
	hover.border_width_top = 2
	hover.border_width_bottom = 2
	hover.border_color = hover_color * 1.5
	hover.corner_radius_top_left = 6
	hover.corner_radius_top_right = 6
	hover.corner_radius_bottom_left = 6
	hover.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("hover", hover)

	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 20)


func _on_powerups_pressed():
	AudioManager.play_sfx("menu_confirm")
	get_tree().change_scene_to_file("res://scenes/powerup_screen.tscn")


func play_menu_music():
	if AudioManager and AudioManager.has_method("play_bgm"):
		AudioManager.play_bgm(AudioManager.sounds.get("bgm_menu"))


func _on_language_pressed():
	AudioManager.play_sfx("menu_select")
	if I18N.current_lang == "zh":
		I18N.set_language("en")
	else:
		I18N.set_language("zh")
	# Refresh the whole scene so all text updates
	get_tree().reload_current_scene()


func _fullscreen_text() -> String:
	if I18N.current_lang == "zh":
		return "[ ] 全屏" if not I18N.fullscreen else "[✓] 全屏"
	return "[ ] Fullscreen" if not I18N.fullscreen else "[✓] Fullscreen"


func _resolution_text() -> String:
	var w = I18N.resolution.x
	var h = I18N.resolution.y
	return "%dx%d" % [w, h]


func _on_fullscreen_pressed(btn: Button):
	AudioManager.play_sfx("menu_select")
	I18N.toggle_fullscreen()
	btn.text = _fullscreen_text()


func _on_resolution_pressed(btn: Button):
	AudioManager.play_sfx("menu_select")
	# Cycle: 720p → 1080p → 1440p → 720p
	var cur = I18N.resolution
	match cur:
		Vector2i(1280, 720):
			I18N.set_resolution(1920, 1080)
		Vector2i(1920, 1080):
			I18N.set_resolution(2560, 1440)
		_:
			I18N.set_resolution(1280, 720)
	btn.text = _resolution_text()


func _on_start_pressed():
	AudioManager.play_sfx("menu_confirm")
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")


func _input(event):
	if event.is_action_pressed("fullscreen"):
		I18N.toggle_fullscreen()
		# Refresh button text if on main menu
		for c in get_children():
			if c is Button and (c.text.contains("全屏") or c.text.contains("Fullscreen")):
				c.text = _fullscreen_text()
				break
		get_viewport().set_input_as_handled()


func _on_quit_pressed():
	AudioManager.play_sfx("menu_select")
	# Small delay then quit
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()
