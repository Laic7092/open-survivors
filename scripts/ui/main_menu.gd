extends Control

const UnlockDefs = preload("res://scripts/data/unlock_defs.gd")
const ArcanaDefs = preload("res://scripts/data/arcana_defs.gd")

# ── Responsive constants ──
const BASE_HEIGHT = 720.0
const FONT_TITLE = 48
const FONT_SUBTITLE = 18
const FONT_BTN = 20
const FONT_SMALL_BTN = 13
const FONT_GOLD = 16
const FONT_FOOTER = 12
const FONT_DEBUG = 10

var _unlock_notif: Control

# Top bar — gold (left) / settings (right)
var _top_bar: HBoxContainer
var _gold_lbl: Label
var _lang_btn: Button
var _fs_btn: Button
var _res_btn: Button

# Center column — title → subtitle → sep → start → btn_row
var _center: VBoxContainer
var _title: Label
var _subtitle: Label
var _sep: ColorRect
var _start_btn: Button
var _pu_btn: Button
var _relic_btn: Button

# Bottom bar — version (left) / quit (right)
var _bottom_bar: HBoxContainer
var _version_lbl: Label
var _quit_btn: Button
var _debug_hint: Label

# Badge tracking
var _badge_entries: Array[Dictionary] = []

var _scale: float = 1.0


func _ready():
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)
	
	# Unlock notification overlay (永久保留)
	_unlock_notif = Control.new()
	_unlock_notif.name = "UnlockNotification"
	_unlock_notif.set_script(preload("res://scripts/ui/unlock_notification.gd"))
	add_child(_unlock_notif)
	
	_build_ui()
	_apply_responsive()
	call_deferred("play_menu_music")
	call_deferred("_check_new_unlocks")


func _notification(what):
	if what == NOTIFICATION_RESIZED and _center != null:
		_apply_responsive()


# ═══════════════════════════════════════════════════════════
# UI Construction (called once)
# ═══════════════════════════════════════════════════════════

func _build_ui():
	# ── Top bar: ⭐ Gold (left) | Settings pills (right) ──
	_top_bar = HBoxContainer.new()
	_top_bar.anchor_left = 0.0
	_top_bar.anchor_top = 0.0
	_top_bar.anchor_right = 1.0
	add_child(_top_bar)
	
	_gold_lbl = Label.new()
	_gold_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.1))
	_top_bar.add_child(_gold_lbl)
	
	var top_spacer = Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_spacer.mouse_filter = Control.MOUSE_FILTER_PASS
	_top_bar.add_child(top_spacer)
	
	var settings_hbox = HBoxContainer.new()
	settings_hbox.add_theme_constant_override("separation", 4)
	_top_bar.add_child(settings_hbox)
	
	_lang_btn = Button.new()
	_lang_btn.pressed.connect(_on_language_pressed)
	settings_hbox.add_child(_lang_btn)
	_style_small_button(_lang_btn)
	
	_fs_btn = Button.new()
	_fs_btn.pressed.connect(_on_fs_pressed)
	settings_hbox.add_child(_fs_btn)
	_style_small_button(_fs_btn)
	
	_res_btn = Button.new()
	_res_btn.pressed.connect(_on_res_pressed)
	settings_hbox.add_child(_res_btn)
	_style_small_button(_res_btn)
	
	# ── Center column: title → subtitle → sep → start → btn_row ──
	_center = VBoxContainer.new()
	_center.anchor_left = 0.5
	_center.anchor_top = 0.0
	_center.anchor_right = 0.5
	_center.anchor_bottom = 1.0
	_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_center)
	
	# Top elastic spacer (pushes content block to vertical center)
	var top_fill = Control.new()
	top_fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_fill.mouse_filter = Control.MOUSE_FILTER_PASS
	_center.add_child(top_fill)
	
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	_center.add_child(_title)
	
	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_center.add_child(_subtitle)
	
	_sep = ColorRect.new()
	_sep.color = Color(0.9, 0.8, 0.2, 0.4)
	_sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_center.add_child(_sep)
	
	_center.add_spacer(false)
	
	_start_btn = Button.new()
	_start_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_start_btn.pressed.connect(_on_start_pressed)
	_center.add_child(_start_btn)
	_style_button(_start_btn, Color(0.15, 0.5, 0.2), Color(0.25, 0.7, 0.3))
	
	_center.add_spacer(false)
	
	# PowerUps + Relics side-by-side
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 16)
	btn_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_center.add_child(btn_row)
	
	_pu_btn = Button.new()
	_pu_btn.pressed.connect(_on_powerups_pressed)
	btn_row.add_child(_pu_btn)
	_style_button(_pu_btn, Color(0.2, 0.2, 0.5), Color(0.3, 0.3, 0.7))
	
	_relic_btn = Button.new()
	_relic_btn.pressed.connect(_on_relics_pressed)
	btn_row.add_child(_relic_btn)
	_style_button(_relic_btn, Color(0.3, 0.6, 0.2), Color(0.4, 0.8, 0.3))
	
	# Bottom elastic spacer
	var bot_fill = Control.new()
	bot_fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bot_fill.mouse_filter = Control.MOUSE_FILTER_PASS
	_center.add_child(bot_fill)
	
	# Debug hint
	_debug_hint = Label.new()
	_debug_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_debug_hint.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	_center.add_child(_debug_hint)
	
	# ── Bottom bar: version (left) / quit (right) ──
	_bottom_bar = HBoxContainer.new()
	_bottom_bar.anchor_left = 0.0
	_bottom_bar.anchor_top = 1.0
	_bottom_bar.anchor_right = 1.0
	_bottom_bar.anchor_bottom = 1.0
	add_child(_bottom_bar)
	
	_version_lbl = Label.new()
	_version_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	_bottom_bar.add_child(_version_lbl)
	
	var bot_spacer = Control.new()
	bot_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot_spacer.mouse_filter = Control.MOUSE_FILTER_PASS
	_bottom_bar.add_child(bot_spacer)
	
	_quit_btn = Button.new()
	_quit_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	_quit_btn.pressed.connect(_on_quit_pressed)
	_bottom_bar.add_child(_quit_btn)
	_style_button(_quit_btn, Color(0.5, 0.1, 0.1), Color(0.7, 0.2, 0.2))


# ═══════════════════════════════════════════════════════════
# Responsive Layout (called on init AND on window resize)
# ═══════════════════════════════════════════════════════════

func _apply_responsive():
	var vp = get_viewport().get_visible_rect().size
	if vp.x <= 0 or vp.y <= 0:
		return
	
	_scale = clamp(vp.y / BASE_HEIGHT, 0.5, 3.0)
	
	# ── Top bar ──
	var margin = max(6, 12 * _scale)
	_top_bar.offset_left = margin
	_top_bar.offset_right = -margin
	_top_bar.offset_top = margin
	
	_gold_lbl.text = I18N.t("menu.gold") + str(PowerUpManager.gold)
	_gold_lbl.add_theme_font_size_override("font_size", max(10, int(FONT_GOLD * _scale)))
	
	var small_h = clamp(24 * _scale, 18, 48)
	var small_fs = max(9, int(FONT_SMALL_BTN * _scale))
	
	_lang_btn.text = I18N.t("menu.language")
	_lang_btn.custom_minimum_size = Vector2(0, small_h)
	_lang_btn.add_theme_font_size_override("font_size", small_fs)
	
	_fs_btn.text = _fullscreen_text()
	_fs_btn.custom_minimum_size = Vector2(0, small_h)
	_fs_btn.add_theme_font_size_override("font_size", small_fs)
	
	_res_btn.text = _resolution_text()
	_res_btn.custom_minimum_size = Vector2(0, small_h)
	_res_btn.add_theme_font_size_override("font_size", small_fs)
	
	# ── Center column ──
	var panel_w = clamp(vp.x * 0.44, 280.0, 600.0 * _scale)
	var half = panel_w / 2.0
	_center.offset_left = -half
	_center.offset_right = half
	_center.offset_top = margin + small_h + margin * 0.5
	_center.offset_bottom = -margin * 3
	
	var sep_s = max(2, 4 * _scale)
	_center.add_theme_constant_override("separation", int(sep_s))
	
	# Title
	_title.text = I18N.t("menu.title")
	_title.add_theme_font_size_override("font_size", max(18, int(FONT_TITLE * _scale)))
	
	# Subtitle
	_subtitle.text = I18N.t("menu.subtitle")
	_subtitle.add_theme_font_size_override("font_size", max(10, int(FONT_SUBTITLE * _scale)))
	
	# Separator
	_sep.custom_minimum_size = Vector2(clamp(panel_w * 0.55, 80.0, 400.0), max(1, 2 * _scale))
	
	# Start Game button
	var btn_w = clamp(panel_w * 0.6, 140.0, 340.0)
	var btn_h = clamp(40 * _scale, 28, 80)
	_start_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	_start_btn.text = I18N.t("menu.start_game")
	_start_btn.add_theme_font_size_override("font_size", max(12, int(FONT_BTN * _scale)))
	
	# PowerUps / Relics
	var side_w = clamp(panel_w * 0.38, 100.0, 220.0)
	var side_h = clamp(32 * _scale, 24, 64)
	var side_fs = max(10, int(FONT_BTN * 0.8 * _scale))
	
	_pu_btn.custom_minimum_size = Vector2(side_w, side_h)
	_pu_btn.text = I18N.t("menu.power_ups")
	_pu_btn.add_theme_font_size_override("font_size", side_fs)
	
	_relic_btn.custom_minimum_size = Vector2(side_w, side_h)
	_relic_btn.text = I18N.t("menu.relics")
	_relic_btn.add_theme_font_size_override("font_size", side_fs)
	
	# ── Bottom bar ──
	var bb_h = clamp(36 * _scale, 24, 60)
	_bottom_bar.offset_left = margin
	_bottom_bar.offset_right = -margin
	_bottom_bar.offset_top = -bb_h - margin * 0.5
	_bottom_bar.offset_bottom = -margin
	
	_version_lbl.text = I18N.t("menu.footer")
	_version_lbl.add_theme_font_size_override("font_size", max(8, int(FONT_FOOTER * _scale)))
	
	_quit_btn.custom_minimum_size = Vector2(clamp(btn_w * 0.55, 80.0, 160.0), bb_h)
	_quit_btn.text = I18N.t("menu.quit")
	_quit_btn.add_theme_font_size_override("font_size", max(11, int(FONT_BTN * _scale)))
	
	# Debug hint
	_debug_hint.text = "[F8] Quick Start"
	_debug_hint.add_theme_font_size_override("font_size", max(7, int(FONT_DEBUG * _scale)))
	_debug_hint.custom_minimum_size = Vector2(0, max(12, 16 * _scale))
	
	# Reposition unlock badges
	_reposition_badges()


# ═══════════════════════════════════════════════════════════
# Button Styles (permanent — only called from _build_ui)
# ═══════════════════════════════════════════════════════════

func _style_small_button(btn: Button):
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.2, 0.2, 0.25)
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_width_top = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(0.4, 0.4, 0.5)
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", normal)
	
	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.35, 0.35, 0.4)
	hover.border_width_left = 1
	hover.border_width_right = 1
	hover.border_width_top = 1
	hover.border_width_bottom = 1
	hover.border_color = Color(0.6, 0.6, 0.7)
	hover.corner_radius_top_left = 4
	hover.corner_radius_top_right = 4
	hover.corner_radius_bottom_left = 4
	hover.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("hover", hover)
	
	btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))


func _style_button(btn: Button, bg_color: Color, hover_color: Color):
	var normal = StyleBoxFlat.new()
	normal.bg_color = bg_color
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.border_color = bg_color * 1.5
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", normal)
	
	var hover = StyleBoxFlat.new()
	hover.bg_color = hover_color
	hover.border_width_left = 2
	hover.border_width_right = 2
	hover.border_width_top = 2
	hover.border_width_bottom = 2
	hover.border_color = hover_color * 1.5
	hover.corner_radius_top_left = 6
	hover.corner_radius_top_right = 6
	hover.corner_radius_bottom_left = 6
	hover.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("hover", hover)
	
	btn.add_theme_color_override("font_color", Color.WHITE)
	# Font size set dynamically in _apply_responsive()


# ═══════════════════════════════════════════════════════════
# Unlock Badges
# ═══════════════════════════════════════════════════════════

func _check_new_unlocks():
	if not UnlockManager:
		return
	if _unlock_notif and _unlock_notif.has_method("check_and_show"):
		_unlock_notif.check_and_show()
	call_deferred("_add_unlock_badges")


func _add_unlock_badges():
	if not UnlockManager or not UnlockManager.has_new_unlocks():
		return
	
	_clear_badges()
	_add_badge_to_button(_start_btn, Color(0.9, 0.2, 0.2))
	_add_badge_to_button(_relic_btn, Color(0.9, 0.7, 0.2))
	
	call_deferred("_reposition_badges")


func _add_badge_to_button(btn: Button, color: Color):
	var badge_bg = ColorRect.new()
	badge_bg.color = color
	badge_bg.size = Vector2(28, 16)
	btn.add_child(badge_bg)
	
	var badge = Label.new()
	badge.text = I18N.t("unlock.new_badge")
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", Color.WHITE)
	badge.size = Vector2(24, 14)
	btn.add_child(badge)
	
	_badge_entries.append({"bg": badge_bg, "label": badge, "btn": btn})


func _reposition_badges():
	for entry in _badge_entries:
		if not is_instance_valid(entry["bg"]):
			continue
		var btn = entry["btn"]
		var bw = max(btn.custom_minimum_size.x, btn.size.x)
		entry["bg"].position = Vector2(max(0, bw - 30), -8)
		entry["label"].position = Vector2(max(0, bw - 28), -6)


func _clear_badges():
	for entry in _badge_entries:
		if is_instance_valid(entry["bg"]):
			entry["bg"].queue_free()
		if is_instance_valid(entry["label"]):
			entry["label"].queue_free()
	_badge_entries.clear()


# ═══════════════════════════════════════════════════════════
# Signal Handlers
# ═══════════════════════════════════════════════════════════

func _on_start_pressed():
	AudioManager.play_sfx("menu_confirm")
	SceneManager.change_scene("res://scenes/character_select.tscn")


func _on_powerups_pressed():
	AudioManager.play_sfx("menu_confirm")
	SceneManager.change_scene("res://scenes/powerup_screen.tscn")


func _on_relics_pressed():
	AudioManager.play_sfx("menu_confirm")
	SceneManager.change_scene("res://scenes/relic_screen.tscn")


func _on_language_pressed():
	AudioManager.play_sfx("menu_select")
	if I18N.current_lang == "zh":
		I18N.set_language("en")
	else:
		I18N.set_language("zh")
	get_tree().reload_current_scene()


func _on_fs_pressed():
	AudioManager.play_sfx("menu_select")
	I18N.toggle_fullscreen()
	_apply_responsive()


func _on_res_pressed():
	AudioManager.play_sfx("menu_select")
	var cur = I18N.resolution
	match cur:
		Vector2i(1280, 720):
			I18N.set_resolution(1920, 1080)
		Vector2i(1920, 1080):
			I18N.set_resolution(2560, 1440)
		_:
			I18N.set_resolution(1280, 720)
	_apply_responsive()


func _on_quit_pressed():
	AudioManager.play_sfx("menu_select")
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()


func _input(event):
	if event.is_action_pressed("fullscreen"):
		I18N.toggle_fullscreen()
		_apply_responsive()
		get_viewport().set_input_as_handled()


# ═══════════════════════════════════════════════════════════
# Helpers
# ═══════════════════════════════════════════════════════════

func _fullscreen_text() -> String:
	if I18N.current_lang == "zh":
		return "[ ] 全屏" if not I18N.fullscreen else "[✓] 全屏"
	return "[ ] FS" if not I18N.fullscreen else "[✓] FS"


func _resolution_text() -> String:
	var w = I18N.resolution.x
	var h = I18N.resolution.y
	return "%dx%d" % [w, h]


func play_menu_music():
	if AudioManager and AudioManager.has_method("play_bgm"):
		AudioManager.play_bgm(AudioManager.sounds.get("bgm_menu"))
