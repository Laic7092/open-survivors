extends Control

const CharacterDefs = preload("res://scripts/data/character_defs.gd")
const UiUtils = preload("res://scripts/ui/ui_utils.gd")


func _ready():
	anchor_right = 1.0
	anchor_bottom = 1.0
	_show()
	get_viewport().size_changed.connect(_show)


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
	title.text = I18N.t("char_select.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	title.position = Vector2(vp.x / 2 - 160, 20)
	title.size = Vector2(320, 50)
	add_child(title)

	# Gold display
	var gold_lbl = Label.new()
	gold_lbl.text = I18N.t("char_select.gold") + str(PowerUpManager.gold)
	gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_lbl.add_theme_font_size_override("font_size", 16)
	gold_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.1))
	gold_lbl.position = Vector2(vp.x / 2 - 80, 70)
	gold_lbl.size = Vector2(160, 24)
	add_child(gold_lbl)

	# Character grid — 自适应列数
	var chars = CharacterDefs.CHARACTERS
	var cols = UiUtils.calc_columns(vp.x, 180, 16, 40, 6)
	cols = mini(cols, chars.size())
	var card_w = mini(180, max(140, int((vp.x - 80) / cols - 16)))
	var card_h = mini(220, max(180, int((vp.y - 150) / 2)))
	var gap_x = 12
	var gap_y = 12
	var grid_w = cols * card_w + (cols - 1) * gap_x
	var start_x = max(10, (vp.x - grid_w) / 2)
	var rows = ceil(float(chars.size()) / cols)
	var grid_h = rows * card_h + (rows - 1) * gap_y
	var start_y = max(10, (vp.y - grid_h) / 2)

	for i in range(chars.size()):
		var c = chars[i]
		var row = i / cols
		var col = i % cols
		var pos = Vector2(start_x + col * (card_w + gap_x), start_y + row * (card_h + gap_y))
		_add_character_card(c, pos, card_w, card_h)

	# Back button
	var back_btn = Button.new()
	back_btn.text = I18N.t("char_select.back")
	back_btn.custom_minimum_size = Vector2(140, 40)
	back_btn.position = Vector2(vp.x / 2 - 70, vp.y - 60)
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


func _add_character_card(char_data: Dictionary, pos: Vector2, w: int, h: int):
	var char_id = char_data["id"]
	var unlocked = PowerUpManager.has_unlocked_character(char_id)
	var cost = char_data.get("cost", 0)
	
	var card = VBoxContainer.new()
	card.position = pos
	card.size = Vector2(w, h)
	card.add_theme_constant_override("separation", 4)
	add_child(card)

	var col = char_data["color"]

	# Color accent bar
	var bar = ColorRect.new()
	bar.color = col
	bar.size = Vector2(w, 4)
	card.add_child(bar)

	# Character icon placeholder (colored circle)
	var icon_box = Control.new()
	icon_box.custom_minimum_size = Vector2(0, 70)
	card.add_child(icon_box)
	# Draw character icon
	var icon_draw = func():
		icon_box.draw_circle(Vector2(icon_box.size.x / 2, 35), 24, col if unlocked else col * 0.3)
		icon_box.draw_circle(Vector2(icon_box.size.x / 2, 35), 24, Color(1, 1, 1, 0.2 if unlocked else 0.05), false, 2)
		if not unlocked:
			icon_box.draw_string(ThemeDB.fallback_font, Vector2(icon_box.size.x / 2 - 10, 39), "🔒", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.5, 0.5, 0.5))
	icon_box.draw.connect(icon_draw)

	# Character name
	var nm = Label.new()
	nm.text = I18N.t("char." + str(char_id) + "_name")
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 22)
	nm.add_theme_color_override("font_color", Color.WHITE if unlocked else Color(0.4, 0.4, 0.4))
	card.add_child(nm)

	# Starting weapon
	var wep_key = _wep_name_key(char_data["weapon"])
	var wep_lbl = Label.new()
	wep_lbl.text = I18N.t(wep_key)
	wep_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wep_lbl.add_theme_font_size_override("font_size", 14)
	wep_lbl.add_theme_color_override("font_color", col if unlocked else col * 0.3)
	card.add_child(wep_lbl)

	# Bonus description
	var desc = Label.new()
	desc.text = I18N.t("char." + str(char_id) + "_desc")
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7) if unlocked else Color(0.35, 0.35, 0.35))
	card.add_child(desc)

	card.add_spacer(true)

	if unlocked:
		# Select button
		var btn = Button.new()
		btn.text = I18N.t("char_select.select")
		btn.custom_minimum_size = Vector2(0, 36)
		UiUtils.style_button(btn, col * 0.3, col)
		card.add_child(btn)
		btn.pressed.connect(_on_select.bind(char_data))
	else:
		# Cost label
		var cost_lbl = Label.new()
		cost_lbl.text = I18N.t("char_select.cost") % [cost]
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_lbl.add_theme_font_size_override("font_size", 13)
		cost_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.1))
		card.add_child(cost_lbl)
		
		# Buy button
		var buy_btn = Button.new()
		buy_btn.text = I18N.t("char_select.buy")
		buy_btn.disabled = PowerUpManager.gold < cost
		buy_btn.custom_minimum_size = Vector2(0, 36)
		if PowerUpManager.gold >= cost:
			UiUtils.style_button(buy_btn, Color(0.15, 0.5, 0.15), Color(0.3, 0.7, 0.3))
		else:
			UiUtils.style_button(buy_btn, Color(0.1, 0.1, 0.1), Color(0.2, 0.2, 0.2))
		buy_btn.add_theme_color_override("font_color", Color.WHITE if PowerUpManager.gold >= cost else Color(0.4, 0.4, 0.4))
		buy_btn.add_theme_font_size_override("font_size", 16)
		card.add_child(buy_btn)
		buy_btn.pressed.connect(_on_buy_character.bind(char_id))


func _on_select(char_data: Dictionary):
	if not PowerUpManager.has_unlocked_character(char_data["id"]):
		return  # shouldn't happen with disabled button, but safety check
	AudioManager.play_sfx("menu_confirm")
	# Store character data in Engine metadata
	Engine.set_meta("selected_character", char_data)
	SceneManager.change_scene("res://scenes/stage_select.tscn")


func _on_buy_character(char_id: int):
	# Find character data to get cost
	var char_data = null
	for c in CharacterDefs.CHARACTERS:
		if c["id"] == char_id:
			char_data = c
			break
	if not char_data:
		return
	var cost = char_data.get("cost", 0)
	if PowerUpManager.buy_character(char_id, cost):
		AudioManager.play_sfx("menu_confirm")
		_show()  # refresh screen
	else:
		AudioManager.play_sfx("menu_select")


func _on_back():
	AudioManager.play_sfx("menu_select")
	SceneManager.change_scene("res://scenes/main_menu.tscn")


static func _wep_name_key(type: int) -> String:
	match type:
		0: return "item.whip_name"
		1: return "item.wand_name"
		2: return "item.garlic_name"
		10: return "item.knife_name"
		11: return "item.axe_name"
		12: return "item.firewand_name"
		16: return "item.cross_name"
		17: return "item.bible_name"
		18: return "item.santa_water_name"
		19: return "item.runetracer_name"
		20: return "item.lightning_name"
	return "item.whip_name"


func _clear():
	for c in get_children():
		c.queue_free()
