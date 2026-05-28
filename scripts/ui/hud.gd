extends Control

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

var _weapon_list: Array = []  # [{name, level, max_level}]


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	anchor_right = 1.0
	anchor_bottom = 1.0


func _draw():
	var vp = get_viewport().get_visible_rect().size
	var m = 12.0
	var bw = 220.0
	var bh = 18.0
	var y = m
	var font = ThemeDB.fallback_font
	var fs = 16

	# Health bar
	draw_rect(Rect2(m, y, bw, bh), Color(0.3, 0.05, 0.05))
	draw_rect(Rect2(m, y, bw * health_pct, bh), Color(0.9, 0.15, 0.15))
	draw_rect(Rect2(m + bw + 6, y, 2, bh), Color(0.1, 0.1, 0.1))
	y += bh + 4
	# XP bar
	draw_rect(Rect2(m, y, bw, 8), Color(0.05, 0.05, 0.3))
	draw_rect(Rect2(m, y, bw * xp_pct, 8), Color(0.2, 0.3, 0.9))
	# Level (i18n prefix)
	draw_string(font, Vector2(m + bw + 8, m + 14), I18N.t("hud.lv") + level_str, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	# Timer with time limit
	var timer_display = timer_str
	if time_limit_str != "":
		timer_display = timer_str + " / " + time_limit_str
	draw_string(font, Vector2(m, m + 50), timer_display, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	# Stats
	draw_string(font, Vector2(m, m + 72), kills_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	draw_string(font, Vector2(m, m + 90), gold_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.8, 0.1))

	# Weapon display (bottom-right)
	var wx = vp.x - 200
	var wy = vp.y - 30 * _weapon_list.size() - 10
	for w in _weapon_list:
		var wep_col = w.get("color", Color.WHITE)
		var evo_mark = I18N.t("wpn.evolved") if w.get("evolved", false) else ""
		var wpn_name = I18N.t(w.get("name_key", ""), w.get("name", "?"))
		var wep_txt = "%s%s Lv.%d" % [evo_mark, wpn_name, w.get("level", 1)]
		var wep_col_display = Color(0.8, 0.3, 0.9, 0.9) if w.get("evolved", false) else wep_col
		draw_string(font, Vector2(wx, wy), wep_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, wep_col_display)
		wy += 22

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


func set_weapons(weapons: Array):
	_weapon_list = weapons.duplicate()
	queue_redraw()


func _make_buttons():
	if restart_btn and menu_btn:
		return
	
	if not restart_btn:
		restart_btn = Button.new()
		restart_btn.text = I18N.t("hud.restart")
		restart_btn.custom_minimum_size = Vector2(160, 50)
		add_child(restart_btn)
		restart_btn.pressed.connect(_on_restart)
	
	if not menu_btn:
		menu_btn = Button.new()
		menu_btn.text = I18N.t("hud.main_menu")
		menu_btn.custom_minimum_size = Vector2(160, 50)
		add_child(menu_btn)
		menu_btn.pressed.connect(_on_menu)
	
	# Position buttons — use call_deferred to avoid await issues when paused
	call_deferred(&"_position_result_buttons")


func _position_result_buttons():
	if not is_inside_tree():
		return
	var vp = get_viewport().get_visible_rect().size
	if restart_btn:
		restart_btn.global_position = vp / 2 - Vector2(80, 90)
	if menu_btn:
		menu_btn.global_position = vp / 2 - Vector2(80, 150)


func _on_restart():
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


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
