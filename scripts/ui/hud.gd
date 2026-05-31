extends Control

# Arcana/item data loaded lazily via DataRegistry (autoload)
const HudCell = preload("res://scripts/ui/hud_cell.gd")

# ── Scene node references ──
@onready var _xp_bar_bg: ColorRect = $XpBarBg
@onready var _xp_bar_fill: ColorRect = $XpBarFill
@onready var _level_label: Label = $LevelLabel
@onready var _timer_label: Label = $TimerLabel
@onready var _kills_label: Label = $KillsLabel
@onready var _gold_label: Label = $GoldLabel
@onready var _curse_label: Label = $CurseLabel
@onready var _arcana_container: HBoxContainer = $ArcanaContainer
@onready var _weapon_grid: GridContainer = $WeaponGrid
@onready var _relic_arrow: Control = $RelicArrow
@onready var _boss_count_label: Label = $BossCountLabel
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

# Timer cache
var _last_timer_text: String = ""
var _last_xp_bar_w: float = -1.0

# Speed display
var _speed_label: Label

# Pre-cached I18N strings (called every frame)
var _str_lv: String = ""
var _str_kills: String = ""
var _str_gold: String = ""
var _str_timer_fmt: String = ""

# Arcana display cache — avoid creating/destroying nodes every frame
var _last_arcana_ids: Array = []
var _arcana_badges: Array = []


func _ready():
	# Pre-cache I18N strings used every frame
	_str_lv = I18N.t("hud.lv")
	_str_kills = I18N.t("hud.kills")
	_str_gold = I18N.t("hud.gold")
	_str_timer_fmt = I18N.t("hud.timer_format")
	
	# 覆盖层按钮事件
	_restart_btn.pressed.connect(_on_restart)
	_menu_btn.pressed.connect(_on_menu)

	# 按钮文字 (i18n)
	_restart_btn.text = I18N.t("hud.restart")
	_menu_btn.text = I18N.t("hud.main_menu")

	# 初始文字
	_level_label.text = _str_lv + "1"
	_timer_label.text = _str_timer_fmt % [0, 0]
	_kills_label.text = _str_kills + "0"
	_gold_label.text = _str_gold + "0"

	# 速度倍率标签
	_speed_label = Label.new()
	_speed_label.name = "SpeedLabel"
	_speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_speed_label.add_theme_font_size_override("font_size", 14)
	_speed_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.8, 0.9))
	_speed_label.position = Vector2(12, 42)
	_speed_label.text = "x1.0"
	add_child(_speed_label)
	
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

	# Boss 计数 — 监听 EnemyRegistry 信号
	if EnemyRegistry:
		if not EnemyRegistry.boss_count_changed.is_connected(set_boss_count):
			EnemyRegistry.boss_count_changed.connect(set_boss_count)
		set_boss_count(EnemyRegistry.get_boss_count())


# ═══════════════════════════════════════════════════════════════════════
#  Public Setters
# ═══════════════════════════════════════════════════════════════════════

func set_health(_cur: float, _max_hp: float):
	pass


func set_speed(speed: float):
	_speed_label.text = "x" + str(speed)


func set_xp(cur: int, need: int):
	_xp_pct = float(cur) / float(need) if need > 0 else 0
	var bar_w = _xp_bar_bg.size.x
	if bar_w > 0 and bar_w != _last_xp_bar_w:
		_last_xp_bar_w = bar_w
		_xp_bar_fill.offset_right = 12.0 + bar_w * _xp_pct
	elif bar_w > 0 and _xp_pct < 1.0:
		_xp_bar_fill.offset_right = 12.0 + bar_w * _xp_pct


func set_level(lv: int):
	_level_label.text = _str_lv + str(lv)


func set_timer(t: float):
	var m = int(t) / 60
	var s = int(t) % 60
	# Cache string to avoid redundant updates (called every frame)
	var display = _str_timer_fmt % [m, s]
	if time_limit_str != "":
		display += " / " + time_limit_str
	if display != _last_timer_text:
		_last_timer_text = display
		_timer_label.text = display


func set_time_limit(limit: float):
	var m = int(limit) / 60
	var s = int(limit) % 60
	time_limit_str = I18N.t("hud.timer_format") % [m, s]


func set_kills(c: int):
	_kills_label.text = _str_kills + str(c)


func set_gold(g: int):
	_gold_label.text = _str_gold + str(g)


func set_wave(_n: int):
	pass


func set_boss_count(n: int):
	if n > 0:
		_boss_count_label.visible = true
		_boss_count_label.text = "BOSS x" + str(n)
	else:
		_boss_count_label.visible = false


func set_curse_level(n: int):
	if n > 0:
		_curse_label.visible = true
		_curse_label.text = I18N.t("cursed_time.level") % n
	else:
		_curse_label.visible = false
		_curse_label.text = ""


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
		var max_lv = DataRegistry.items().item_max_level(w.get("type", -1))
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
			DataRegistry.items().item_max_level(p.get("type", -1)),
			false,
			p.get("color", Color(0.5, 0.5, 0.5))
		)
	for i in range(passives.size(), 6):
		_cells[6 + i].clear()


func set_arcanas(arcana_ids: Array):
	# Skip if unchanged (called every frame)
	if arcana_ids == _last_arcana_ids:
		return
	_last_arcana_ids = arcana_ids.duplicate()

	# Reuse existing badge nodes, create new ones as needed
	while _arcana_badges.size() < arcana_ids.size():
		var badge = Panel.new()
		badge.custom_minimum_size = Vector2(36, 36)
		var roman_label = Label.new()
		roman_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		roman_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		roman_label.size = Vector2(36, 36)
		roman_label.position = Vector2(0, 0)
		badge.add_child(roman_label)
		_arcana_container.add_child(badge)
		_arcana_badges.append(badge)

	# Hide excess badges
	for i in range(arcana_ids.size(), _arcana_badges.size()):
		_arcana_badges[i].visible = false

	# Update visible badges
	for i in range(arcana_ids.size()):
		var id = arcana_ids[i]
		var a = DataRegistry.arcanas().get_arcana(id)
		var col = a.get("color", Color(0.5, 0.5, 0.5))
		var roman = a.get("roman", "?")

		var badge = _arcana_badges[i]
		badge.visible = true
		# Update stylebox
		var s = StyleBoxFlat.new()
		s.bg_color = col * 0.25
		s.set_border_width_all(2)
		s.border_color = col
		s.corner_radius_top_left = 4
		s.corner_radius_top_right = 4
		s.corner_radius_bottom_left = 4
		s.corner_radius_bottom_right = 4
		badge.add_theme_stylebox_override("panel", s)

		var roman_label = badge.get_child(0) as Label
		roman_label.text = roman
		var fs = 12 if roman.length() <= 2 else 9
		roman_label.add_theme_font_size_override("font_size", fs)
		roman_label.add_theme_color_override("font_color", col)


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
