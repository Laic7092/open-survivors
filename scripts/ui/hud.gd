extends Control

const ArcanaDefs = preload("res://scripts/data/arcana_defs.gd")

var health_pct: float = 1.0
var xp_pct: float = 0.0
var level_str: String = "LV 1"
var timer_str: String = "00:00"
var time_limit_str: String = ""
var kills_str: String = "Kills: 0"
var gold_str: String = "Gold: 0"
var game_over_data: Dictionary = {}
var show_go: bool = false
var show_victory: bool = false
var victory_data: Dictionary = {}
var restart_btn: Button
var menu_btn: Button

var _weapon_list: Array = []  # [{name, level, evolved, color}]
var _passive_list: Array = []  # [{name, level, color}]

# Relic arrow indicator
var _relic_arrow_angle: float = 0.0
var _relic_arrow_dist: float = 0.0
var _show_relic_arrow: bool = false

# Active Arcana display
var _active_arcanas: Array = []  # arcana data dicts


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	mouse_filter = MOUSE_FILTER_STOP
	anchor_right = 1.0
	anchor_bottom = 1.0


func _draw():
	var vp = get_viewport().get_visible_rect().size
	var m = 12.0
	var font = ThemeDB.fallback_font
	var bar_w = vp.x - m * 2

	# XP bar (full width)
	draw_rect(Rect2(m, m, bar_w, 8), Color(0.05, 0.05, 0.3))
	draw_rect(Rect2(m, m, bar_w * xp_pct, 8), Color(0.2, 0.3, 0.9))
	# Level on top of XP bar
	draw_string(font, Vector2(m + 4, m + 7), I18N.t("hud.lv") + level_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.7, 0.9, 0.8))
	# Timer (centered, large)
	var timer_display = timer_str
	if time_limit_str != "":
		timer_display = timer_str + " / " + time_limit_str
	var timer_fs = 28
	var timer_w = font.get_string_size(timer_display, HORIZONTAL_ALIGNMENT_LEFT, -1, timer_fs).x
	draw_string(font, Vector2((vp.x - timer_w) / 2, m + 32), timer_display, HORIZONTAL_ALIGNMENT_LEFT, -1, timer_fs, Color.WHITE)
	# Stats
	draw_string(font, Vector2(m, m + 46), kills_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	draw_string(font, Vector2(m + 120, m + 46), gold_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.8, 0.1))

	# ── Active Arcana badges (top-right) ──
	if not _active_arcanas.is_empty():
		var badge_size = 36.0
		var badge_gap = 4.0
		var badge_x = vp.x - (badge_size + badge_gap) * _active_arcanas.size() - m
		var badge_y = m + 10.0
		for i in range(_active_arcanas.size()):
			var a = _active_arcanas[i]
			var col = a.get("color", Color(0.5, 0.5, 0.5))
			var roman = a.get("roman", "?")
			var bx = badge_x + i * (badge_size + badge_gap)
			# Badge background
			draw_rect(Rect2(bx, badge_y, badge_size, badge_size), col * 0.25)
			draw_rect(Rect2(bx, badge_y, badge_size, badge_size), col, false, 2.0)
			# Roman numeral text
			var text_sz = 12 if roman.length() <= 2 else 9
			var tw = font.get_string_size(roman, HORIZONTAL_ALIGNMENT_LEFT, -1, text_sz).x
			draw_string(font, Vector2(bx + (badge_size - tw) / 2, badge_y + badge_size - 8), roman, HORIZONTAL_ALIGNMENT_LEFT, -1, text_sz, col)

	# ── Relic arrow indicator (green pointer toward uncollected relics) ──
	if _show_relic_arrow:
		var arrow_center = Vector2(vp.x / 2, vp.y / 2)
		var arrow_len = 40.0
		var arrow_size = 12.0
		var tip = arrow_center + Vector2(cos(_relic_arrow_angle), sin(_relic_arrow_angle)) * arrow_len
		var perp = Vector2(-sin(_relic_arrow_angle), cos(_relic_arrow_angle))
		var base_left = arrow_center + perp * arrow_size
		var base_right = arrow_center - perp * arrow_size
		var arrow_tri = PackedVector2Array([tip, base_left, base_right])
		draw_polygon(arrow_tri, [Color(0.3, 0.8, 0.3, 0.85)])
		# Outline via polyline
		draw_polyline(PackedVector2Array([base_left, tip, base_right]), Color(0.5, 1.0, 0.5, 0.6), 2.0)
		# Distance text
		var dist_str = str(int(_relic_arrow_dist)) + "m"
		var dist_pos = arrow_center + Vector2(cos(_relic_arrow_angle), sin(_relic_arrow_angle)) * (arrow_len + 18)
		draw_string(font, dist_pos - Vector2(10, 5), dist_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.3, 0.8, 0.3))

	# ── Weapon & passive cells (bottom-right) ──
	var cell_sz = 36.0
	var gap = 4.0
	var cells_start_x = vp.x - (cell_sz + gap) * 6 - 10
	var cells_y = vp.y - (cell_sz + gap) * 2 - 10
	_draw_cell_row(cells_start_x, cells_y, cell_sz, gap, _weapon_list, false)
	_draw_cell_row(cells_start_x, cells_y + cell_sz + gap, cell_sz, gap, _passive_list, true)

	if show_go:
		_draw_overlay(vp, font, I18N.t("hud.game_over"), Color(0.9, 0.2, 0.2))
	
	if show_victory:
		_draw_overlay(vp, font, I18N.t("hud.stage_complete"), Color(0.2, 0.9, 0.3))


func _draw_overlay(vp: Vector2, font: Font, title: String, title_color: Color):
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.7))
	
	var data = victory_data if show_victory else game_over_data
	var txt = data.get("text", title)
	var lines = txt.split("\n")
	var ly = vp.y / 2 - 60
	# Draw title in larger font
	draw_string(font, Vector2(vp.x / 2 - 120, ly), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 36, title_color)
	ly += 44
	# Draw stats
	for line in lines:
		draw_string(font, Vector2(vp.x / 2 - 120, ly), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
		ly += 30


func set_health(cur: float, max_hp: float):
	health_pct = cur / max_hp if max_hp > 0 else 0
	queue_redraw()


func set_xp(cur: int, need: int):
	xp_pct = float(cur) / float(need) if need > 0 else 0
	queue_redraw()


func set_level(lv: int):
	level_str = str(lv)
	queue_redraw()


func set_timer(t: float):
	var m = int(t) / 60
	var s = int(t) % 60
	timer_str = "%02d:%02d" % [m, s]
	queue_redraw()


func set_time_limit(limit: float):
	var m = int(limit) / 60
	var s = int(limit) % 60
	time_limit_str = "%02d:%02d" % [m, s]


func set_kills(c: int):
	kills_str = I18N.t("hud.kills") + str(c)
	queue_redraw()


func set_gold(g: int):
	gold_str = I18N.t("hud.gold") + str(g)
	queue_redraw()


func set_relic_arrow(angle, dist: float):
	if angle == null:
		_show_relic_arrow = false
	else:
		_show_relic_arrow = true
		_relic_arrow_angle = angle
		_relic_arrow_dist = dist
	queue_redraw()


func set_weapons(weapons: Array):
	_weapon_list = weapons.duplicate()
	queue_redraw()


func set_passives(passives: Array):
	_passive_list = passives.duplicate()
	queue_redraw()


func set_arcanas(arcana_ids: Array):
	# Convert arcana IDs to data dicts with color and roman numeral
	var data: Array = []
	for id in arcana_ids:
		var a = ArcanaDefs.get_arcana(id)
		data.append({
			"id": id,
			"roman": a["roman"],
			"color": a["color"],
		})
	_active_arcanas = data
	queue_redraw()


func _draw_cell_row(start_x: float, y: float, sz: float, gap: float, items: Array, dim: bool):
	var font = ThemeDB.fallback_font
	for i in range(6):
		var x = start_x + i * (sz + gap)
		if i < items.size():
			var item = items[i]
			var col = item.get("color", Color(0.5, 0.5, 0.5))
			var lv = item.get("level", 1)
			var evolved = item.get("evolved", false)
			var t = item.get("type", -1)
			# Background
			var bg = Color(col.r * 0.25, col.g * 0.25, col.b * 0.25, 0.7)
			draw_rect(Rect2(x, y, sz, sz), bg)
			# Fill bar (level indicator on left edge)
			var max_fill_lv = 8.0
			if RelicManager.has_relic("great_gospel"):
				max_fill_lv = 20.0
			var fill_h = (sz - 2) * min(lv / max_fill_lv, 1.0)
			draw_rect(Rect2(x + 1, y + sz - 1 - fill_h, 3, fill_h), col)
			# Draw item symbol (white, centered)
			if t >= 0:
				_draw_item_symbol(x, y, sz, t)
			# Level number
			draw_string(font, Vector2(x + 8, y + sz - 4), str(lv), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
			# Evolved indicator
			if evolved:
				draw_string(font, Vector2(x + sz - 14, y + 12), "*", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.8, 0.2))
		else:
			# Empty cell (dim outline)
			draw_rect(Rect2(x, y, sz, sz), Color(0.2, 0.2, 0.2, 0.3), false, 1.0)


# Draw a simple white symbol inside a HUD cell to identify the item at a glance.
func _draw_item_symbol(cx: float, cy: float, sz: float, t: int):
	var center_x = cx + sz / 2
	var center_y = cy + sz / 2
	var s = sz * 0.2  # scale factor
	var white = Color(1, 1, 1, 0.85)
	
	match t:
		0:  # Whip — diagonal slash
			draw_line(Vector2(center_x - s, center_y + s), Vector2(center_x + s, center_y - s), white, 2.0)
		1:  # Magic Wand — vertical line + dot
			draw_line(Vector2(center_x, center_y - s * 0.8), Vector2(center_x, center_y + s * 0.8), white, 2.0)
			draw_circle(Vector2(center_x, center_y - s * 1.0), 1.5, white)
		2:  # Garlic — small filled circle
			draw_circle(Vector2(center_x, center_y), s * 0.5, white)
		10: # Knife — small triangle pointing right
			var tri = PackedVector2Array([
				Vector2(center_x + s * 0.8, center_y),
				Vector2(center_x - s * 0.6, center_y - s * 0.7),
				Vector2(center_x - s * 0.6, center_y + s * 0.7),
			])
			draw_polygon(tri, [white])
		11: # Axe — horizontal bar
			draw_line(Vector2(center_x - s, center_y), Vector2(center_x + s, center_y), white, 2.5)
		12: # Fire Wand — diamond
			var diamond = PackedVector2Array([
				Vector2(center_x, center_y - s * 0.9),
				Vector2(center_x + s * 0.7, center_y),
				Vector2(center_x, center_y + s * 0.9),
				Vector2(center_x - s * 0.7, center_y),
			])
			draw_polygon(diamond, [white])
		3:  # Wings — V shape
			draw_line(Vector2(center_x - s, center_y + s * 0.3), Vector2(center_x, center_y - s * 0.6), white, 2.0)
			draw_line(Vector2(center_x, center_y - s * 0.6), Vector2(center_x + s, center_y + s * 0.3), white, 2.0)
		4:  # Spinach — + cross
			draw_line(Vector2(center_x - s * 0.7, center_y), Vector2(center_x + s * 0.7, center_y), white, 2.0)
			draw_line(Vector2(center_x, center_y - s * 0.7), Vector2(center_x, center_y + s * 0.7), white, 2.0)
		5:  # Empty Tome — square outline
			var r = s * 0.7
			draw_rect(Rect2(center_x - r, center_y - r, r * 2, r * 2), white, false, 1.5)
		6:  # Hollow Heart — heart shape (two arcs + V)
			var hr = s * 0.4
			draw_circle(Vector2(center_x - hr, center_y - hr * 0.3), hr * 0.6, white)
			draw_circle(Vector2(center_x + hr, center_y - hr * 0.3), hr * 0.6, white)
			draw_line(Vector2(center_x - hr * 1.0, center_y - hr * 0.1), Vector2(center_x, center_y + hr * 0.9), white, 1.5)
			draw_line(Vector2(center_x + hr * 1.0, center_y - hr * 0.1), Vector2(center_x, center_y + hr * 0.9), white, 1.5)
		7:  # Candelabrador — circle outline
			draw_circle(Vector2(center_x, center_y), s * 0.55, white, false, 1.5)
		8:  # Crown — 3-point crown
			var cw = s * 0.8
			var ch = s * 0.6
			var crown_tri = PackedVector2Array([
				Vector2(center_x - cw, center_y + ch * 0.5),
				Vector2(center_x - cw * 0.6, center_y - ch),
				Vector2(center_x - cw * 0.2, center_y - ch * 0.2),
				Vector2(center_x + cw * 0.2, center_y - ch * 0.2),
				Vector2(center_x + cw * 0.6, center_y - ch),
				Vector2(center_x + cw, center_y + ch * 0.5),
			])
			draw_polygon(crown_tri, [white])
		9:  # Pummarola — small filled circle
			draw_circle(Vector2(center_x, center_y), s * 0.4, white)
		13: # Duplicator — II (two vertical lines)
			draw_line(Vector2(center_x - s * 0.35, center_y - s * 0.6), Vector2(center_x - s * 0.35, center_y + s * 0.6), white, 2.0)
			draw_line(Vector2(center_x + s * 0.35, center_y - s * 0.6), Vector2(center_x + s * 0.35, center_y + s * 0.6), white, 2.0)
		14: # Stone Mask — two dots (eyes)
			draw_circle(Vector2(center_x - s * 0.4, center_y), s * 0.15, white)
			draw_circle(Vector2(center_x + s * 0.4, center_y), s * 0.15, white)
		15: # Magnet — U shape
			var ms = s * 0.6
			draw_line(Vector2(center_x - ms, center_y - ms), Vector2(center_x - ms, center_y + ms * 0.5), white, 2.0)
			draw_line(Vector2(center_x + ms, center_y - ms), Vector2(center_x + ms, center_y + ms * 0.5), white, 2.0)
			draw_line(Vector2(center_x - ms, center_y + ms * 0.5), Vector2(center_x + ms, center_y + ms * 0.5), white, 2.0)
		16: # Cross — cross shape
			draw_line(Vector2(center_x - s * 0.7, center_y), Vector2(center_x + s * 0.7, center_y), white, 2.5)
			draw_line(Vector2(center_x, center_y - s * 0.7), Vector2(center_x, center_y + s * 0.7), white, 2.5)
		17: # King Bible — circle with cross
			draw_circle(Vector2(center_x, center_y), s * 0.55, white, false, 2.0)
			draw_line(Vector2(center_x - s * 0.4, center_y), Vector2(center_x + s * 0.4, center_y), white, 2.0)
			draw_line(Vector2(center_x, center_y - s * 0.4), Vector2(center_x, center_y + s * 0.4), white, 2.0)
		18: # Santa Water — water drop (triangle)
			var drop = PackedVector2Array([
				Vector2(center_x, center_y - s * 0.7),
				Vector2(center_x - s * 0.6, center_y + s * 0.4),
				Vector2(center_x + s * 0.6, center_y + s * 0.4),
			])
			draw_polygon(drop, [white])
		19: # Runetracer — angled lines (runes)
			draw_line(Vector2(center_x - s * 0.8, center_y - s * 0.5), Vector2(center_x + s * 0.8, center_y + s * 0.5), white, 2.0)
			draw_line(Vector2(center_x - s * 0.5, center_y - s * 0.8), Vector2(center_x + s * 0.5, center_y + s * 0.8), white, 1.5)
		20: # Lightning Ring — zigzag
			draw_line(Vector2(center_x - s * 0.3, center_y - s * 0.7), Vector2(center_x + s * 0.2, center_y - s * 0.2), white, 2.0)
			draw_line(Vector2(center_x + s * 0.2, center_y - s * 0.2), Vector2(center_x - s * 0.2, center_y + s * 0.2), white, 2.0)
			draw_line(Vector2(center_x - s * 0.2, center_y + s * 0.2), Vector2(center_x + s * 0.3, center_y + s * 0.7), white, 2.0)


func _make_buttons():
	if restart_btn and menu_btn:
		return
	var vp = get_viewport().get_visible_rect().size
	
	if not restart_btn:
		restart_btn = Button.new()
		restart_btn.text = I18N.t("hud.restart")
		restart_btn.custom_minimum_size = Vector2(160, 50)
		restart_btn.size = Vector2(160, 50)
		restart_btn.position = vp / 2 - Vector2(80, 90)
		add_child(restart_btn)
		restart_btn.pressed.connect(_on_restart)
	
	if not menu_btn:
		menu_btn = Button.new()
		menu_btn.text = I18N.t("hud.main_menu")
		menu_btn.custom_minimum_size = Vector2(160, 50)
		menu_btn.size = Vector2(160, 50)
		menu_btn.position = vp / 2 - Vector2(80, 150)
		add_child(menu_btn)
		menu_btn.pressed.connect(_on_menu)


func _on_restart():
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu():
	get_tree().paused = false
	SceneManager.change_scene("res://scenes/main_menu.tscn")


func show_game_over(t: float, kills: int, lv: int):
	var m = int(t) / 60
	var s = int(t) % 60
	game_over_data["text"] = I18N.t("hud.game_over_stats") % [m, s, kills, lv, PowerUpManager.run_gold]
	show_go = true
	queue_redraw()
	_make_buttons()


func show_stage_complete(t: float, kills: int, lv: int, stage_name: String):
	var m = int(t) / 60
	var s = int(t) % 60
	victory_data["text"] = I18N.t("hud.victory_stats") % [stage_name, m, s, kills, lv, PowerUpManager.run_gold]
	show_victory = true
	queue_redraw()
	_make_buttons()
