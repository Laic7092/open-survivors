extends Control

signal toggle_pause
signal quit_to_menu

const CharacterDefs = preload("res://scripts/data/character_defs.gd")

# Stat labels (updated in _process when visible)
var _stat_labels: Array[Label] = []


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	mouse_filter = MOUSE_FILTER_STOP
	anchor_right = 1.0
	anchor_bottom = 1.0
	visible = false

	# Dark overlay
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	var vp = get_viewport().get_visible_rect().size

	# ── Outer container (centered) ──
	var outer = VBoxContainer.new()
	outer.position = Vector2(vp.x / 2 - 220, 40)
	outer.size = Vector2(440, 0)
	outer.add_theme_constant_override("separation", 6)
	add_child(outer)

	# Title
	var title = Label.new()
	title.text = I18N.t("pause.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.custom_minimum_size = Vector2(440, 50)
	outer.add_child(title)

	# Separator (VBoxContainer centered via size_flags)
	var sep = ColorRect.new()
	sep.color = Color(0.9, 0.8, 0.2, 0.4)
	sep.custom_minimum_size = Vector2(300, 2)
	sep.size = Vector2(300, 2)
	sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	outer.add_child(sep)

	outer.add_spacer(false)

	# ── Two-column stats area ──
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	outer.add_child(hbox)

	# Left column — character info
	var left_col = VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 4)
	hbox.add_child(left_col)

	_left_label(left_col, I18N.t("pause.character"), Color(0.9, 0.8, 0.2), 16)
	var char_name_lbl = _stat_label(left_col, "", Color.WHITE, 18)
	var char_lv_lbl = _stat_label(left_col, "", Color.WHITE, 14)
	left_col.add_spacer(true)
	_left_label(left_col, I18N.t("pause.run_stats"), Color(0.9, 0.8, 0.2), 16)
	var kills_lbl = _stat_label(left_col, "", Color.WHITE, 14)
	var time_lbl = _stat_label(left_col, "", Color.WHITE, 14)
	var gold_lbl = _stat_label(left_col, "", Color(0.9, 0.8, 0.1), 14)

	# Right column — combat stats
	var right_col = VBoxContainer.new()
	right_col.add_theme_constant_override("separation", 4)
	hbox.add_child(right_col)

	_left_label(right_col, I18N.t("pause.combat_stats"), Color(0.9, 0.8, 0.2), 16)
	var hp_lbl = _stat_label(right_col, "", Color.WHITE, 14)
	var dmg_lbl = _stat_label(right_col, "", Color.WHITE, 14)
	var spd_lbl = _stat_label(right_col, "", Color.WHITE, 14)
	var area_lbl = _stat_label(right_col, "", Color.WHITE, 14)
	var cd_lbl = _stat_label(right_col, "", Color.WHITE, 14)
	var armor_lbl = _stat_label(right_col, "", Color.WHITE, 14)

	# ── Weapons & passives section ──
	outer.add_spacer(false)
	var wpn_header = Label.new()
	wpn_header.text = I18N.t("pause.weapons")
	wpn_header.add_theme_font_size_override("font_size", 14)
	wpn_header.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	wpn_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(wpn_header)
	var wpn_lbl = _stat_label(outer, "", Color(0.7, 0.7, 0.9), 13)

	var pass_header = Label.new()
	pass_header.text = I18N.t("pause.passives")
	pass_header.add_theme_font_size_override("font_size", 14)
	pass_header.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	pass_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(pass_header)
	var pass_lbl = _stat_label(outer, "", Color(0.7, 0.9, 0.7), 13)

	# ── Buttons ──
	outer.add_spacer(true)

	var resume_btn = Button.new()
	resume_btn.text = I18N.t("pause.resume")
	resume_btn.custom_minimum_size = Vector2(200, 44)
	resume_btn.size = Vector2(200, 44)
	resume_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	outer.add_child(resume_btn)
	_style_button(resume_btn, Color(0.15, 0.45, 0.15), Color(0.25, 0.65, 0.25))
	resume_btn.pressed.connect(_on_resume_pressed)

	var quit_btn = Button.new()
	quit_btn.text = I18N.t("pause.quit")
	quit_btn.custom_minimum_size = Vector2(200, 44)
	quit_btn.size = Vector2(200, 44)
	quit_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	outer.add_child(quit_btn)
	_style_button(quit_btn, Color(0.45, 0.15, 0.15), Color(0.65, 0.25, 0.25))
	quit_btn.pressed.connect(_on_quit_pressed)

	# Store references for _process updates: [char_name, char_lv, kills, time, gold, hp, dmg, spd, area, cd, armor, wpn, pass]
	_stat_labels = [char_name_lbl, char_lv_lbl, kills_lbl, time_lbl, gold_lbl,
					hp_lbl, dmg_lbl, spd_lbl, area_lbl, cd_lbl, armor_lbl,
					wpn_lbl, pass_lbl]


func _left_label(parent: Node, text: String, color: Color, size: int):
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)


func _stat_label(parent: Node, text: String, color: Color, size: int) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl


func _process(_delta):
	if not visible:
		return
	_update_stats()


func _update_stats():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var char_data = Engine.get_meta("selected_character", {})
	var char_name = char_data.get("name", "?")
	var char_weapon = CharacterDefs.get_weapon_name(char_data.get("weapon", 0)) if char_data else "?"
	var char_id = char_data.get("id", 0) if char_data else 0
	var char_i18n = I18N.t("char." + str(char_id) + "_name", char_name)

	# Character info
	_stat_labels[0].text = char_i18n + " — " + char_weapon
	_stat_labels[1].text = I18N.t("pause.level") % [player.level, player.xp, player.xp_to_next]

	# Run stats: read from the main Node2D (parent of our CanvasLayer)
	var main = get_parent().get_parent()
	var kills = main.total_kills if is_instance_valid(main) else 0
	var run_time = main.game_time if is_instance_valid(main) else 0.0
	var m = int(run_time) / 60
	var s = int(run_time) % 60
	var gold_amt = PowerUpManager.run_gold if PowerUpManager else 0

	_stat_labels[2].text = I18N.t("pause.kills") % kills
	_stat_labels[3].text = I18N.t("pause.time") % [m, s]
	_stat_labels[4].text = I18N.t("pause.gold") % gold_amt

	# Combat stats
	var hp = player.health
	var max_hp = player.max_health
	_stat_labels[5].text = I18N.t("pause.hp") % [hp, max_hp]
	_stat_labels[6].text = I18N.t("pause.dmg") % player.damage_mult
	_stat_labels[7].text = I18N.t("pause.spd") % player.move_speed
	_stat_labels[8].text = I18N.t("pause.area") % player.area_mult
	_stat_labels[9].text = I18N.t("pause.cd") % int(player.cooldown_reduction * 100)
	_stat_labels[10].text = I18N.t("pause.armor") % player.armor

	# Weapons
	var wpn_text = ""
	if player.weapons and player.weapons.size() > 0:
		var parts = []
		for w in player.weapons:
			var nm = I18N.t(_wpn_i18n_key(w.type), _weapon_name(w.type))
			var evo = I18N.t("wpn.evolved") if w.evolved else ""
			parts.append(nm + " Lv." + str(w.level) + evo)
		wpn_text = "  ".join(parts)
	_stat_labels[11].text = wpn_text if wpn_text != "" else I18N.t("pause.none")

	# Passives
	var pass_text = ""
	if player.passives and player.passives.size() > 0:
		var parts = []
		for t in player.passives:
			var nm = I18N.t(_pass_i18n_key(t), _passive_name(t))
			parts.append(nm + " Lv." + str(player.passives[t]))
		pass_text = "  ".join(parts)
	_stat_labels[12].text = pass_text if pass_text != "" else I18N.t("pause.none")


static func _weapon_name(t: int) -> String:
	match t:
		0: return "Whip"
		1: return "Magic Wand"
		2: return "Garlic"
		10: return "Knife"
		11: return "Axe"
		12: return "Fire Wand"
	return "?"


static func _passive_name(t: int) -> String:
	match t:
		3: return "Wings"
		4: return "Spinach"
		5: return "Empty Tome"
		6: return "Hollow Heart"
		7: return "Candelabrador"
		8: return "Crown"
		9: return "Pummarola"
		13: return "Duplicator"
		14: return "Stone Mask"
		15: return "Magnet"
	return "?"


static func _wpn_i18n_key(t: int) -> String:
	match t:
		0: return "wpn.whip"
		1: return "wpn.wand"
		2: return "wpn.garlic"
		10: return "wpn.knife"
		11: return "wpn.axe"
		12: return "wpn.firewand"
	return "wpn.whip"


static func _pass_i18n_key(t: int) -> String:
	match t:
		3: return "pas.wings"
		4: return "pas.spinach"
		5: return "pas.tome"
		6: return "pas.hollow"
		7: return "pas.candel"
		8: return "pas.crown"
		9: return "pas.pummarola"
		13: return "pas.duplicator"
		14: return "pas.stonemask"
		15: return "pas.magnet"
	return "pas.wings"


func _style_button(btn: Button, bg_color: Color, hover_color: Color):
	var normal = StyleBoxFlat.new()
	normal.bg_color = bg_color
	normal.border_width_left = 2; normal.border_width_right = 2
	normal.border_width_top = 2; normal.border_width_bottom = 2
	normal.border_color = bg_color * 1.5
	normal.corner_radius_top_left = 6; normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6; normal.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", normal)
	var hover = StyleBoxFlat.new()
	hover.bg_color = hover_color
	hover.border_width_left = 2; hover.border_width_right = 2
	hover.border_width_top = 2; hover.border_width_bottom = 2
	hover.border_color = hover_color * 1.5
	hover.corner_radius_top_left = 6; hover.corner_radius_top_right = 6
	hover.corner_radius_bottom_left = 6; hover.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 18)


func show_pause():
	visible = true


func hide_pause():
	visible = false


func _on_resume_pressed():
	toggle_pause.emit()


func _on_quit_pressed():
	quit_to_menu.emit()
