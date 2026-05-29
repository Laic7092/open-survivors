extends Control

const ArcanaDefs = preload("res://scripts/data/arcana_defs.gd")
const HudCell = preload("res://scripts/ui/hud_cell.gd")

# ── Scene node references ──
@onready var _xp_bar_bg: ColorRect = $XpBarBg
@onready var _xp_bar_fill: ColorRect = $XpBarFill
@onready var _level_label: Label = $LevelLabel
@onready var _timer_label: Label = $TimerLabel
@onready var _kills_label: Label = $KillsLabel
@onready var _gold_label: Label = $GoldLabel
@onready var _arcana_container: HBoxContainer = $ArcanaContainer
@onready var _weapon_grid: GridContainer = $WeaponGrid
@onready var _relic_arrow: Control = $RelicArrow
@onready var _overlay_panel: Panel = $OverlayPanel
@onready var _overlay_title: Label = $OverlayPanel/OverlayTitle
@onready var _overlay_stats: Label = $OverlayPanel/OverlayStats
@onready var _restart_btn: Button = $OverlayPanel/RestartBtn
@onready var _menu_btn: Button = $OverlayPanel/MenuBtn

# ── State ──
var time_limit_str: String = ""
var game_over_data: Dictionary = {}
var victory_data: Dictionary = {}

# Relic arrow
var _relic_arrow_angle: float = 0.0
var _relic_arrow_dist: float = 0.0
var _show_relic_arrow: bool = false

# XP bar
var _xp_pct: float = 0.0

# 预创建的 12 个格子：前 6 = 武器，后 6 = 被动
var _cells: Array = []


func _ready():
	# 覆盖层按钮事件
	_restart_btn.pressed.connect(_on_restart)
	_menu_btn.pressed.connect(_on_menu)

	# 按钮文字 (i18n)
	_restart_btn.text = I18N.t("hud.restart")
	_menu_btn.text = I18N.t("hud.main_menu")

	# 初始文字
	_level_label.text = I18N.t("hud.lv") + "1"
	_timer_label.text = I18N.t("hud.timer_format") % [0, 0]
	_kills_label.text = I18N.t("hud.kills") + "0"
	_gold_label.text = I18N.t("hud.gold") + "0"

	# 在网格中预创建 12 个武器/被动格子
	for i in range(12):
		var cell = Control.new()
		cell.set_script(HudCell)
		cell.name = "Cell" + str(i)
		cell.custom_minimum_size = Vector2(36, 36)
		_weapon_grid.add_child(cell)
		_cells.append(cell)

	# 遗物箭头通过 draw 信号绘制
	_relic_arrow.draw.connect(_draw_relic_arrow_signal)


# ═══════════════════════════════════════════════════════════════════════
#  Public Setters
# ═══════════════════════════════════════════════════════════════════════

func set_health(_cur: float, _max_hp: float):
	pass


func set_xp(cur: int, need: int):
	_xp_pct = float(cur) / float(need) if need > 0 else 0
	var bar_w = _xp_bar_bg.size.x
	if bar_w > 0:
		_xp_bar_fill.offset_right = 12.0 + bar_w * _xp_pct


func set_level(lv: int):
	_level_label.text = I18N.t("hud.lv") + str(lv)


func set_timer(t: float):
	var m = int(t) / 60
	var s = int(t) % 60
	var display = I18N.t("hud.timer_format") % [m, s]
	if time_limit_str != "":
		display += " / " + time_limit_str
	_timer_label.text = display


func set_time_limit(limit: float):
	var m = int(limit) / 60
	var s = int(limit) % 60
	time_limit_str = I18N.t("hud.timer_format") % [m, s]


func set_kills(c: int):
	_kills_label.text = I18N.t("hud.kills") + str(c)


func set_gold(g: int):
	_gold_label.text = I18N.t("hud.gold") + str(g)


func set_relic_arrow(angle, dist: float):
	if angle == null:
		_show_relic_arrow = false
	else:
		_show_relic_arrow = true
		_relic_arrow_angle = angle
		_relic_arrow_dist = dist
	if _relic_arrow:
		_relic_arrow.queue_redraw()


func set_weapons(weapons: Array):
	for i in range(min(weapons.size(), 6)):
		var w = weapons[i]
		var cell = _cells[i]
		var max_lv = 8
		if RelicManager.has_relic("great_gospel"):
			max_lv = 20
		cell.set_data(
			w.get("type", -1),
			w.get("level", 1),
			max_lv,
			w.get("evolved", false),
			w.get("color", Color(0.5, 0.5, 0.5))
		)
	for i in range(weapons.size(), 6):
		_cells[i].clear()


func set_passives(passives: Array):
	for i in range(min(passives.size(), 6)):
		var p = passives[i]
		var cell = _cells[6 + i]
		cell.set_data(
			p.get("type", -1),
			p.get("level", 1),
			8,
			false,
			p.get("color", Color(0.5, 0.5, 0.5))
		)
	for i in range(passives.size(), 6):
		_cells[6 + i].clear()


func set_arcanas(arcana_ids: Array):
	for c in _arcana_container.get_children():
		c.queue_free()

	for id in arcana_ids:
		var a = ArcanaDefs.get_arcana(id)
		var col = a.get("color", Color(0.5, 0.5, 0.5))
		var roman = a.get("roman", "?")

		var badge = Panel.new()
		badge.custom_minimum_size = Vector2(36, 36)
		var s = StyleBoxFlat.new()
		s.bg_color = col * 0.25
		s.set_border_width_all(2)
		s.border_color = col
		s.corner_radius_top_left = 4
		s.corner_radius_top_right = 4
		s.corner_radius_bottom_left = 4
		s.corner_radius_bottom_right = 4
		badge.add_theme_stylebox_override("panel", s)
		_arcana_container.add_child(badge)

		var roman_label = Label.new()
		roman_label.text = roman
		roman_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		roman_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		roman_label.size = Vector2(36, 36)
		roman_label.position = Vector2(0, 0)
		var fs = 12 if roman.length() <= 2 else 9
		roman_label.add_theme_font_size_override("font_size", fs)
		roman_label.add_theme_color_override("font_color", col)
		badge.add_child(roman_label)


func set_relic_arrow_visible(visible: bool):
	_show_relic_arrow = visible
	if _relic_arrow:
		_relic_arrow.queue_redraw()


# ═══════════════════════════════════════════════════════════════════════
#  Relic Arrow
# ═══════════════════════════════════════════════════════════════════════

func _draw_relic_arrow_signal():
	if not _show_relic_arrow:
		return

	var font = ThemeDB.fallback_font
	var vp = get_viewport().get_visible_rect().size
	var center = vp / 2.0

	var arrow_len = 40.0
	var arrow_size = 12.0
	var tip = center + Vector2(cos(_relic_arrow_angle), sin(_relic_arrow_angle)) * arrow_len
	var perp = Vector2(-sin(_relic_arrow_angle), cos(_relic_arrow_angle))
	var base_left = center + perp * arrow_size
	var base_right = center - perp * arrow_size
	var arrow_tri = PackedVector2Array([tip, base_left, base_right])
	_relic_arrow.draw_polygon(arrow_tri, [Color(0.3, 0.8, 0.3, 0.85)])
	_relic_arrow.draw_polyline(PackedVector2Array([base_left, tip, base_right]), Color(0.5, 1.0, 0.5, 0.6), 2.0)

	var dist_str = str(int(_relic_arrow_dist)) + I18N.t("hud.distance_unit")
	var dist_pos = center + Vector2(cos(_relic_arrow_angle), sin(_relic_arrow_angle)) * (arrow_len + 18)
	_relic_arrow.draw_string(font, dist_pos - Vector2(10, 5), dist_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.3, 0.8, 0.3))


# ═══════════════════════════════════════════════════════════════════════
#  Game Over / Victory Overlay
# ═══════════════════════════════════════════════════════════════════════

func show_game_over(t: float, kills: int, lv: int):
	var m = int(t) / 60
	var s = int(t) % 60
	game_over_data["text"] = I18N.t("hud.game_over_stats") % [m, s, kills, lv, PowerUpManager.run_gold]
	_show_overlay(I18N.t("hud.game_over"), Color(0.9, 0.2, 0.2), game_over_data)


func show_stage_complete(t: float, kills: int, lv: int, stage_name: String):
	var m = int(t) / 60
	var s = int(t) % 60
	victory_data["text"] = I18N.t("hud.victory_stats") % [stage_name, m, s, kills, lv, PowerUpManager.run_gold]
	_show_overlay(I18N.t("hud.stage_complete"), Color(0.2, 0.9, 0.3), victory_data)


func _show_overlay(title: String, title_color: Color, data: Dictionary):
	_overlay_title.text = title
	_overlay_title.add_theme_color_override("font_color", title_color)
	_overlay_stats.text = data.get("text", "")
	_overlay_panel.visible = true


func hide_overlay():
	_overlay_panel.visible = false


func _on_restart():
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu():
	get_tree().paused = false
	SceneManager.change_scene("res://scenes/main_menu.tscn")
