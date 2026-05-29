extends Control
# Relic Gallery — shows all relics with collection status.

const RelicDefs = preload("res://scripts/data/relic_defs.gd")
const UiUtils = preload("res://scripts/ui/ui_utils.gd")


func _ready():
	anchor_right = 1.0
	anchor_bottom = 1.0
	_build_ui()
	get_viewport().size_changed.connect(_build_ui)


func _build_ui():
	_clear()
	var vp = get_viewport().get_visible_rect().size
	
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.06)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)
	
	# Title
	var title = Label.new()
	title.text = I18N.t("relic_screen.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	title.position = Vector2(vp.x / 2 - 150, 25)
	title.size = Vector2(300, 50)
	add_child(title)
	
	# Collection progress
	var collected = RelicManager.get_unlocked_count()
	var total = RelicManager.get_total_count()
	var progress_lbl = Label.new()
	progress_lbl.text = I18N.t("relic_screen.progress") % [collected, total]
	progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_lbl.add_theme_font_size_override("font_size", 16)
	progress_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	progress_lbl.position = Vector2(vp.x / 2 - 100, 70)
	progress_lbl.size = Vector2(200, 25)
	add_child(progress_lbl)
	
	# Separator
	var sep = ColorRect.new()
	sep.color = Color(0.9, 0.8, 0.2, 0.3)
	sep.position = Vector2(vp.x / 2 - 150, 100)
	sep.size = Vector2(300, 2)
	add_child(sep)
	
	# Relic cards grid — auto-layout with flow
	var card_w = 320
	var card_h = 200
	var gap_x = 20
	var gap_y = 16
	var cols = max(1, int((vp.x - 60) / (card_w + gap_x)))
	cols = min(cols, 3)  # max 3 columns
	var start_x = (vp.x - (cols * card_w + (cols - 1) * gap_x)) / 2
	var start_y = 120
	
	for i in range(RelicDefs.RELICS.size()):
		var r = RelicDefs.RELICS[i]
		var col_idx = i % cols
		var row_idx = i / cols
		var x = start_x + col_idx * (card_w + gap_x)
		var y = start_y + row_idx * (card_h + gap_y)
		_add_relic_card(r, Vector2(x, y), card_w, card_h)
	
	# Back button
	var back_btn = Button.new()
	back_btn.text = I18N.t("relic_screen.back")
	back_btn.custom_minimum_size = Vector2(140, 40)
	back_btn.position = Vector2(vp.x / 2 - 70, vp.y - 55)
	back_btn.pressed.connect(_on_back)
	UiUtils.style_button(back_btn, Color(0.2, 0.2, 0.3), Color(0.4, 0.4, 0.6))
	add_child(back_btn)


func _add_relic_card(r: Dictionary, pos: Vector2, w: int, h: int):
	var rid = r["id"]
	var collected = RelicManager.has_relic(rid)
	var color = r.get("color", Color(0.5, 0.5, 0.5))
	
	var card = VBoxContainer.new()
	card.position = pos
	card.size = Vector2(w, h)
	card.add_theme_constant_override("separation", 2)
	add_child(card)
	
	# Card background
	var card_bg = ColorRect.new()
	card_bg.color = color * 0.12 if collected else Color(0.05, 0.05, 0.08)
	card_bg.anchor_right = 1.0
	card_bg.anchor_bottom = 1.0
	card_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(card_bg)
	
	# Color accent bar at top
	var bar = ColorRect.new()
	bar.color = color if collected else Color(0.2, 0.2, 0.2)
	bar.size = Vector2(w, 3)
	card.add_child(bar)
	
	# Icon area (inner box)
	var icon_box = Control.new()
	icon_box.custom_minimum_size = Vector2(0, 50)
	card.add_child(icon_box)
	var ic = func():
		var cx = icon_box.size.x / 2
		var cy = 25.0
		if collected:
			# Glowing icon
			icon_box.draw_circle(Vector2(cx, cy), 18, color * 0.3)
			icon_box.draw_circle(Vector2(cx, cy), 16, color, false, 2.0)
			icon_box.draw_circle(Vector2(cx, cy), 5, Color.WHITE)
		else:
			# Locked — dim with lock symbol
			icon_box.draw_circle(Vector2(cx, cy), 16, Color(0.15, 0.15, 0.15))
			icon_box.draw_circle(Vector2(cx, cy), 16, Color(0.3, 0.3, 0.3), false, 1.5)
			icon_box.draw_string(ThemeDB.fallback_font, Vector2(cx - 8, cy + 6), "🔒", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	icon_box.draw.connect(ic)
	
	# Relic name (i18n)
	var nm = Label.new()
	nm.text = I18N.t("relic." + rid, r.get("name", "???"))
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 18)
	nm.add_theme_color_override("font_color", color if collected else Color(0.4, 0.4, 0.4))
	card.add_child(nm)
	
	# Description (i18n)
	var desc = Label.new()
	desc.text = I18N.t("relic." + rid + "_desc", r.get("desc", "")) if collected else "???"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7) if collected else Color(0.3, 0.3, 0.3))
	card.add_child(desc)
	
	# Effect description (shown only when collected)
	if collected:
		var eff = Label.new()
		eff.text = r.get("effect", "")
		eff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		eff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		eff.add_theme_font_size_override("font_size", 10)
		eff.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3))
		card.add_child(eff)


func _on_back():
	AudioManager.play_sfx("menu_select")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _clear():
	for c in get_children():
		c.queue_free()
