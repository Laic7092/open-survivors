extends Control

# Relic data loaded lazily via DataRegistry

@onready var _title: Label = %Title
@onready var _progress_lbl: Label = %ProgressLabel
@onready var _card_area: ScrollContainer = %CardArea
@onready var _relic_grid: GridContainer = %RelicGrid
@onready var _back_btn: Button = %BackBtn


func _ready():
	_title.text = I18N.t("relic_screen.title")
	_back_btn.text = I18N.t("relic_screen.back")
	_back_btn.pressed.connect(_on_back)
	# 等一帧确保布局完成后再计算
	_rebuild.call_deferred()
	get_viewport().size_changed.connect(_rebuild)


func _rebuild():
	_clear_cards()

	var collected = RelicManager.get_unlocked_count()
	var total = RelicManager.get_total_count()

	_progress_lbl.text = I18N.t("relic_screen.progress") % [collected, total]

	# 动态计算列数 + 卡片宽度
	var h_gap = 20.0
	var avail_w = _card_area.size.x
	if avail_w <= 0:
		avail_w = get_viewport().get_visible_rect().size.x - 60.0
	var card_min_w = 280.0
	var cols = max(1, int((avail_w + h_gap) / (card_min_w + h_gap)))
	cols = mini(cols, 5)
	_relic_grid.columns = cols
	var card_w = (avail_w - (cols - 1) * h_gap) / cols
	# 取整避免亚像素间隙
	card_w = floor(card_w)
	# 确保卡片最小宽度
	if card_w < 200:
		card_w = 200.0

	for r in DataRegistry.relics().RELICS:
		_add_relic_card(r, card_w)


func _add_relic_card(r: Dictionary, card_w: float):
	var rid = r["id"]
	var collected = RelicManager.has_relic(rid)
	var color = r.get("color", Color(0.5, 0.5, 0.5))

	var card = VBoxContainer.new()
	card.custom_minimum_size = Vector2(card_w, 190)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_constant_override("separation", 2)
	_relic_grid.add_child(card)

	# 背景色
	var card_bg = ColorRect.new()
	card_bg.color = color * 0.12 if collected else Color(0.05, 0.05, 0.08)
	card_bg.anchor_right = 1.0
	card_bg.anchor_bottom = 1.0
	card_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(card_bg)
	card.move_child(card_bg, 0)

	# 顶栏色条
	var bar = ColorRect.new()
	bar.color = color if collected else Color(0.2, 0.2, 0.2)
	bar.custom_minimum_size = Vector2(0, 3)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(bar)

	# 图标区
	var icon_box = Control.new()
	icon_box.custom_minimum_size = Vector2(0, 44)
	card.add_child(icon_box)
	var ic = func():
		var cx = icon_box.size.x / 2
		var cy = 22.0
		if collected:
			icon_box.draw_circle(Vector2(cx, cy), 16, color * 0.3)
			icon_box.draw_circle(Vector2(cx, cy), 14, color, false, 2.0)
			icon_box.draw_circle(Vector2(cx, cy), 4, Color.WHITE)
		else:
			icon_box.draw_circle(Vector2(cx, cy), 14, Color(0.15, 0.15, 0.15))
			icon_box.draw_circle(Vector2(cx, cy), 14, Color(0.3, 0.3, 0.3), false, 1.5)
			icon_box.draw_string(ThemeDB.fallback_font, Vector2(cx - 8, cy + 5), "🔒", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	icon_box.draw.connect(ic)

	# 名称
	var nm = Label.new()
	nm.text = I18N.t("relic." + rid, r.get("name", "???"))
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 17)
	nm.add_theme_color_override("font_color", color if collected else Color(0.4, 0.4, 0.4))
	card.add_child(nm)

	# 描述
	var desc = Label.new()
	desc.text = I18N.t("relic." + rid + "_desc", r.get("desc", "")) if collected else "???"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7) if collected else Color(0.3, 0.3, 0.3))
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(desc)

	# 效果（仅已收集）
	if collected:
		var eff = Label.new()
		eff.text = I18N.t("relic." + rid + "_effect", r.get("effect", ""))
		eff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		eff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		eff.add_theme_font_size_override("font_size", 10)
		eff.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3))
		card.add_child(eff)


func _on_back():
	AudioManager.play_sfx("menu_select")
	SceneManager.change_scene("res://scenes/main_menu.tscn")


func _clear_cards():
	for c in _relic_grid.get_children():
		c.queue_free()
