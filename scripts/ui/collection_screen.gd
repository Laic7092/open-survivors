extends Control

const IconGenerator = preload("res://scripts/ui/icon_generator.gd")

@onready var _title: Label = %Title
@onready var _counter: Label = %Counter
@onready var _tabs: HBoxContainer = %Tabs
@onready var _scroll: ScrollContainer = %Scroll
@onready var _grid: GridContainer = %Grid
@onready var _back_btn: Button = %BackBtn

# Tab data: { label_key, entries_array }
var _tabs_data: Array[Dictionary] = []
var _current_tab: int = 0


func _ready():
	_title.text = I18N.t("collection.title")
	_back_btn.text = I18N.t("collection.back")
	_back_btn.pressed.connect(_on_back)
	
	_build_tabs()
	_rebuild()
	get_viewport().size_changed.connect(_rebuild)


func _build_tabs():
	_tabs_data = [
		{"label": I18N.t("collection.tab_weapons"), "entries": _build_weapon_entries()},
		{"label": I18N.t("collection.tab_passives"), "entries": _build_pas_entries()},
		{"label": I18N.t("collection.tab_enemies"), "entries": _build_enemy_entries()},
	]
	
	# 清空并重建标签按钮
	for c in _tabs.get_children():
		c.queue_free()
	
	for i in range(_tabs_data.size()):
		var btn = Button.new()
		btn.text = _tabs_data[i]["label"]
		btn.custom_minimum_size = Vector2(0, 34)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.theme_type_variation = &"NeutralButton"
		btn.toggle_mode = true
		btn.button_pressed = (i == 0)
		btn.pressed.connect(_on_tab.bind(i))
		_tabs.add_child(btn)


func _build_weapon_entries() -> Array:
	var entries: Array[Dictionary] = []
	for t in DataRegistry.items().WEAPON_TYPES:
		entries.append(_make_item_entry(t))
	# 也检查其他 is_weapon 的条目
	for t in DataRegistry.items().DATA:
		if DataRegistry.items().DATA[t].get("is_weapon", false):
			if not entries.any(func(e): return e["type"] == t):
				entries.append(_make_item_entry(t))
	entries.sort_custom(func(a, b): return a["type"] < b["type"])
	return entries


func _build_pas_entries() -> Array:
	var entries: Array[Dictionary] = []
	for t in DataRegistry.items().DATA:
		var data = DataRegistry.items().DATA[t]
		if not data.get("is_weapon", true):
			entries.append(_make_item_entry(t))
	entries.sort_custom(func(a, b): return a["type"] < b["type"])
	return entries


func _build_enemy_entries() -> Array:
	var entries: Array[Dictionary] = []
	for i in range(DataRegistry.enemies().get_type_count()):
		var et = DataRegistry.enemies().get_type(i)
		if et == null:
			continue
		entries.append({
			"type": et.id,
			"name": et.name,
			"color": et.color,
			"shape": et.shape,
			"is_boss": et.is_boss,
			"seen": true,  # 所有敌人类型默认可见
		})
	return entries


func _make_item_entry(t: int) -> Dictionary:
	var data = DataRegistry.items().DATA.get(t, {})
	var unlocked = UnlockManager.is_item_unlocked(t)
	var found = _is_item_found(t)
	var max_lv = data.get("max_level", 1)
	var weapon_lv = _persistent_weapon_level(t)
	return {
		"type": t,
		"name": I18N.t(data.get("name_key", ""), data.get("name", "???")),
		"color": data.get("color", Color.GRAY),
		"is_weapon": data.get("is_weapon", true),
		"unlocked": unlocked,
		"found": found,
		"max_level": max_lv,
		"weapon_level": weapon_lv,
	}


func _is_item_found(t: int) -> bool:
	if not UnlockManager:
		return false
	# 检查 UnlockManager 的 _persistent_stats 中 found_items_permanent
	# 或通过 is_item_unlocked 判断默认解锁的也算已发现
	var unlocked = UnlockManager.is_item_unlocked(t)
	if unlocked:
		# 检查是否有解锁条件——无条件则默认解锁即算发现
		var key = DataRegistry.unlocks().get_unlock_id_for_item(t)
		if key == "":
			return true
		var defn = DataRegistry.unlocks().get_def(key)
		if defn and defn.conditions.is_empty():
			return true
	# 在运行中找到过才算 found
	# 从 SaveManager 读
	var found_list = SaveManager.get_section("unlock_persistent_stats", {}).get("found_items_permanent", [])
	return found_list.has(t)


func _persistent_weapon_level(t: int) -> int:
	var stats = SaveManager.get_section("unlock_persistent_stats", {})
	var levels = stats.get("weapon_levels_reached", {})
	return levels.get(t, 0)


func _on_tab(idx: int):
	_current_tab = idx
	# 更新按钮状态
	for i in range(_tabs.get_child_count()):
		var btn = _tabs.get_child(i) as Button
		if btn:
			btn.button_pressed = (i == idx)
	_rebuild()


func _rebuild():
	_clear_grid()
	
	if _current_tab < 0 or _current_tab >= _tabs_data.size():
		return
	
	var entries = _tabs_data[_current_tab]["entries"]
	var total = entries.size()
	var found = 0
	for e in entries:
		if e.get("unlocked", false) or e.get("found", false) or e.get("seen", false):
			found += 1
	
	_counter.text = I18N.t("collection.progress") % [found, total]
	
	# 动态列数
	var vp = get_viewport().get_visible_rect().size
	var avail_w = vp.x - 60.0
	var h_gap = 16.0
	var card_min_w = 220.0
	var cols = max(2, int((avail_w + h_gap) / (card_min_w + h_gap)))
	cols = mini(cols, 6)
	_grid.columns = cols
	var card_w = (avail_w - (cols - 1) * h_gap) / cols
	
	for entry in entries:
		_add_entry_card(entry, card_w)


func _add_entry_card(entry: Dictionary, card_w: float):
	var is_weapon_tab = (_current_tab == 0)
	var is_enemy_tab = (_current_tab == 2)
	
	var card = VBoxContainer.new()
	card.custom_minimum_size = Vector2(card_w, 130)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_constant_override("separation", 2)
	_grid.add_child(card)
	
	var unlocked = entry.get("unlocked", false)
	var found = entry.get("found", false)
	var seen = entry.get("seen", false)
	var visible = unlocked or found or seen
	var col = entry.get("color", Color.GRAY)
	
	# 背景色
	var bg = ColorRect.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = col * 0.08 if visible else Color(0.03, 0.03, 0.06)
	card.add_child(bg)
	card.move_child(bg, 0)
	
	# 圆角边框
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color.TRANSPARENT
	sb.border_color = col * 0.4 if visible else Color(0.15, 0.15, 0.2)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.border_blend = true
	var sb_ref = sb
	card.draw.connect(func():
		card.draw_style_box(sb_ref, Rect2(Vector2.ZERO, card.size))
	)
	
	if is_enemy_tab:
		# 敌人
		var shape = entry.get("shape", "circle")
		var is_boss = entry.get("is_boss", false)
		
		# 顶栏 Spacer
		card.add_spacer(false)
		
		# 形状绘制
		var icon_box = Control.new()
		icon_box.custom_minimum_size = Vector2(0, 50)
		card.add_child(icon_box)
		icon_box.draw.connect(_draw_enemy_icon.bind(icon_box, col, shape, is_boss, visible))
		
		# 名称
		var nm = Label.new()
		nm.text = entry.get("name", "???")
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.add_theme_font_size_override("font_size", 14)
		nm.add_theme_color_override("font_color", col if visible else Color(0.25, 0.25, 0.25))
		card.add_child(nm)
		
		# Boss tag
		if is_boss:
			var boss_tag = Label.new()
			boss_tag.text = I18N.t("collection.boss", "BOSS")
			boss_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			boss_tag.add_theme_font_size_override("font_size", 10)
			boss_tag.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
			card.add_child(boss_tag)
		
		card.add_spacer(false)
	else:
		# 武器/道具
		var icon = IconGenerator.make_icon_node(entry["type"], 28)
		icon.custom_minimum_size = Vector2(0, 44)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.modulate = Color.WHITE if visible else Color(0.2, 0.2, 0.2)
		card.add_child(icon)
		
		# 名称
		var nm = Label.new()
		nm.text = entry.get("name", "???")
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.add_theme_font_size_override("font_size", 13)
		nm.add_theme_color_override("font_color", col if visible else Color(0.25, 0.25, 0.25))
		card.add_child(nm)
		
		# 状态行
		var status = Label.new()
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.add_theme_font_size_override("font_size", 11)
		if not unlocked:
			status.text = "🔒"
			status.add_theme_color_override("font_color", Color(0.5, 0.4, 0.2))
		elif not found:
			status.text = I18N.t("collection.unlocked", "Unlocked")
			status.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
		else:
			var lv = entry.get("weapon_level", 0)
			var max_lv = entry.get("max_level", 1)
			status.text = I18N.t("collection.level") % [lv, max_lv]
			status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3) if lv >= max_lv else Color(0.8, 0.8, 0.8))
		card.add_child(status)


func _draw_enemy_icon(icon_box: Control, col: Color, shape: String, is_boss: bool, visible: bool):
	var cx = icon_box.size.x / 2
	var cy = 25.0
	var r = 16.0
	var c = col if visible else Color(0.2, 0.2, 0.2)
	if is_boss:
		r = 20.0
	
	match shape:
		"circle":
			icon_box.draw_circle(Vector2(cx, cy), r, c * 0.3)
			icon_box.draw_circle(Vector2(cx, cy), r, c, false, 2.0)
		"triangle":
			var pts = PackedVector2Array([
				Vector2(cx, cy - r),
				Vector2(cx + r * 0.866, cy + r * 0.5),
				Vector2(cx - r * 0.866, cy + r * 0.5),
			])
			icon_box.draw_polygon(pts, [c * 0.3])
			icon_box.draw_polyline(pts, c, 2.0, true)
		"diamond":
			var pts = PackedVector2Array([
				Vector2(cx, cy - r),
				Vector2(cx + r, cy),
				Vector2(cx, cy + r),
				Vector2(cx - r, cy),
			])
			icon_box.draw_polygon(pts, [c * 0.3])
			icon_box.draw_polyline(pts, c, 2.0, true)
		"hexagon":
			var pts = PackedVector2Array()
			for i in range(6):
				var a = i * PI / 3 - PI / 2
				pts.append(Vector2(cx + r * cos(a), cy + r * sin(a)))
			icon_box.draw_polygon(pts, [c * 0.3])
			icon_box.draw_polyline(pts, c, 2.0, true)
		_:
			icon_box.draw_circle(Vector2(cx, cy), r, c * 0.3)
			icon_box.draw_circle(Vector2(cx, cy), r, c, false, 2.0)
	
	if not visible:
		icon_box.draw_string(ThemeDB.fallback_font, Vector2(cx - 8, cy + 5), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.3, 0.3, 0.3))


func _on_back():
	SceneManager.change_scene("res://scenes/main_menu.tscn")


func _clear_grid():
	for c in _grid.get_children():
		c.queue_free()
