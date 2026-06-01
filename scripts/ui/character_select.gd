extends Control

# Character data loaded lazily via DataRegistry
const UiUtils = preload("res://scripts/ui/ui_utils.gd")

@onready var _title: Label = %Title
@onready var _gold_lbl: Label = %GoldLabel
@onready var _card_container: Control = %CardContainer
@onready var _back_btn: Button = %BackBtn


func _ready():
	_back_btn.pressed.connect(_on_back)

	_title.text = I18N.t("char_select.title")
	_back_btn.text = I18N.t("char_select.back")

	_rebuild_cards()
	get_viewport().size_changed.connect(_rebuild_cards)


func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()


func _rebuild_cards():
	_clear_cards()

	_gold_lbl.text = I18N.t("char_select.gold") + str(PowerUpManager.gold)
	var vp = get_viewport().get_visible_rect().size

	var chars = DataRegistry.characters().CHARACTERS
	var cols = UiUtils.calc_columns(vp.x, 180, 16, 40, 6)
	cols = mini(cols, chars.size())
	var card_w = mini(180, max(140, int((vp.x - 80) / cols - 16)))
	var gap_x = 12
	var gap_y = 12
	var avail_h = _card_container.size.y
	var grid_h: int
	var rows: int
	# Estimate rows to compute card_h, then finalize
	var est_rows = max(1, ceil(float(chars.size()) / cols))
	var card_h = mini(220, max(150, int((avail_h - gap_y * (est_rows - 1) - 20) / est_rows)))
	rows = ceil(float(chars.size()) / cols)
	grid_h = rows * card_h + (rows - 1) * gap_y
	var grid_w = cols * card_w + (cols - 1) * gap_x
	var start_x = max(10, (vp.x - grid_w) / 2)
	var start_y = max(10, (avail_h - grid_h) / 2)

	for i in range(chars.size()):
		var c = chars[i]
		var row = i / cols
		var col = i % cols
		var pos = Vector2(start_x + col * (card_w + gap_x), start_y + row * (card_h + gap_y))
		_add_character_card(c, pos, card_w, card_h)


func _add_character_card(char_data: Dictionary, pos: Vector2, w: int, h: int):
	var char_id = char_data["id"]
	var unlocked = PowerUpManager.has_unlocked_character(char_id)
	var cost = char_data.get("cost", 0)

	var card = VBoxContainer.new()
	card.position = pos
	card.size = Vector2(w, h)
	card.add_theme_constant_override("separation", 4)
	_card_container.add_child(card)

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
		var btn = Button.new()
		btn.text = I18N.t("char_select.select")
		btn.custom_minimum_size = Vector2(0, 36)
		btn.theme_type_variation = &"PrimaryButton"
		card.add_child(btn)
		btn.pressed.connect(_on_select.bind(char_data))
	else:
		var cost_lbl = Label.new()
		cost_lbl.text = I18N.t("char_select.cost") % [cost]
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_lbl.add_theme_font_size_override("font_size", 13)
		cost_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.1))
		card.add_child(cost_lbl)

		var buy_btn = Button.new()
		buy_btn.text = I18N.t("char_select.buy")
		buy_btn.disabled = PowerUpManager.gold < cost
		buy_btn.custom_minimum_size = Vector2(0, 36)
		buy_btn.theme_type_variation = &"PrimaryButton" if PowerUpManager.gold >= cost else &""
		buy_btn.add_theme_color_override("font_color", Color.WHITE if PowerUpManager.gold >= cost else Color(0.4, 0.4, 0.4))
		buy_btn.add_theme_font_size_override("font_size", 16)
		card.add_child(buy_btn)
		buy_btn.pressed.connect(_on_buy_character.bind(char_id))


func _on_select(char_data: Dictionary):
	if not PowerUpManager.has_unlocked_character(char_data["id"]):
		return
	AudioManager.play_sfx("menu_confirm")
	EventBus.set_config("selected_character", char_data)
	SceneManager.change_scene("res://scenes/stage_select.tscn")


func _on_buy_character(char_id: int):
	var char_data = null
	for c in DataRegistry.characters().CHARACTERS:
		if c["id"] == char_id:
			char_data = c
			break
	if not char_data:
		return
	var cost = char_data.get("cost", 0)
	if PowerUpManager.buy_character(char_id, cost):
		AudioManager.play_sfx("menu_confirm")
		_rebuild_cards()
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


func _clear_cards():
	for c in _card_container.get_children():
		c.queue_free()
