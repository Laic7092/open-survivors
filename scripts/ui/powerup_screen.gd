extends Control

const UiUtils = preload("res://scripts/ui/ui_utils.gd")


func _ready():
	anchor_right = 1.0
	anchor_bottom = 1.0
	_show()
	get_viewport().size_changed.connect(_show)


func _show():
	_clear()

	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var vp = get_viewport().get_visible_rect().size

	# Title
	var title = Label.new()
	title.text = I18N.t("powerup.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	title.position = Vector2(vp.x / 2 - 120, 20)
	title.size = Vector2(240, 50)
	add_child(title)

	# Gold display
	var gold_lbl = Label.new()
	gold_lbl.text = I18N.t("menu.gold") + str(PowerUpManager.gold)
	gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_lbl.add_theme_font_size_override("font_size", 22)
	gold_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.1))
	gold_lbl.position = Vector2(vp.x / 2 - 100, 70)
	gold_lbl.size = Vector2(200, 30)
	add_child(gold_lbl)

	# PowerUp grid
	var grid = GridContainer.new()
	grid.columns = 3
	grid.position = Vector2(40, 110)
	grid.size = Vector2(vp.x - 80, vp.y - 180)
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 12)
	add_child(grid)

	var ids = PowerUpManager.POWERUPS.keys()
	ids.sort()
	for id in ids:
		_add_powerup_card(grid, id)

	# Back button
	var back_btn = Button.new()
	back_btn.text = I18N.t("powerup.back")
	back_btn.custom_minimum_size = Vector2(160, 44)
	back_btn.position = Vector2(vp.x / 2 - 80, vp.y - 60)
	back_btn.pressed.connect(_on_back)
	# Style the back button
	UiUtils.style_button(back_btn, Color(0.2, 0.2, 0.3), Color(0.4, 0.4, 0.6))
	add_child(back_btn)


func _add_powerup_card(grid: GridContainer, id: String):
	var info = PowerUpManager.POWERUPS[id]
	var lv = PowerUpManager.get_level(id)
	var max_lv = info["max_lv"]
	var cost = PowerUpManager.get_cost(id)

	var card = VBoxContainer.new()
	card.custom_minimum_size = Vector2(360, 130)
	grid.add_child(card)

	# Name + level
	var header = HBoxContainer.new()
	card.add_child(header)

	var nm = Label.new()
	nm.text = I18N.t("pu." + id, info["name"])
	nm.add_theme_font_size_override("font_size", 20)
	nm.add_theme_color_override("font_color", Color.WHITE)
	header.add_child(nm)

	var lv_str = " [" + str(lv) + "/" + str(max_lv) + "]"
	var lv_lbl = Label.new()
	lv_lbl.text = lv_str
	lv_lbl.add_theme_font_size_override("font_size", 16)
	var lv_color = Color(0.3, 1.0, 0.3) if lv >= max_lv else Color(0.8, 0.8, 0.8)
	lv_lbl.add_theme_color_override("font_color", lv_color)
	header.add_child(lv_lbl)

	header.add_spacer(true)

	# Description
	var desc = Label.new()
	desc.text = I18N.t("pu." + id + "_desc", info["desc"])
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	card.add_child(desc)

	# Buy area
	var buy_row = HBoxContainer.new()
	card.add_child(buy_row)

	if lv >= max_lv:
		var maxed = Label.new()
		maxed.text = I18N.t("powerup.maxed")
		maxed.add_theme_font_size_override("font_size", 16)
		maxed.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		buy_row.add_child(maxed)
	else:
		var cost_lbl = Label.new()
		cost_lbl.text = I18N.t("powerup.cost") % cost
		cost_lbl.add_theme_font_size_override("font_size", 14)
		cost_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.1))
		buy_row.add_child(cost_lbl)

		buy_row.add_spacer(true)

		var buy_btn = Button.new()
		buy_btn.text = I18N.t("powerup.buy")
		buy_btn.custom_minimum_size = Vector2(80, 32)
		var can_afford = PowerUpManager.gold >= cost
		if can_afford:
			UiUtils.style_button(buy_btn, Color(0.15, 0.5, 0.15), Color(0.3, 0.8, 0.3))
		else:
			UiUtils.style_button(buy_btn, Color(0.3, 0.15, 0.15), Color(0.5, 0.2, 0.2))
		buy_btn.disabled = not can_afford
		buy_btn.pressed.connect(_on_buy.bind(id))
		buy_row.add_child(buy_btn)


func _on_buy(id: String):
	if PowerUpManager.buy_powerup(id):
		_show()  # refresh


func _on_back():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _clear():
	for c in get_children():
		c.queue_free()
