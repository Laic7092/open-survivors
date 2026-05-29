extends Control

signal toggle_pause
signal quit_to_menu

const CharacterDefs = preload("res://scripts/data/character_defs.gd")
const Player = preload("res://scripts/entities/player.gd")
const Minimap = preload("res://scripts/ui/minimap.gd")

# ── Responsive constants ──
const BASE_HEIGHT = 720.0
const FONT_TITLE = 32
const FONT_SECTION = 15
const FONT_STAT_VAL = 17
const FONT_STAT = 13
const FONT_BTN = 17
const FONT_HINT = 12

# Stat labels
var _stat_labels: Array[Label] = []

# Minimap node
var _minimap: Control

# Grim Grimoire
var _grimoire_header: Label
var _grimoire_container: VBoxContainer

# Responsive refs
var _outer: VBoxContainer
var _title: Label
var _sep: ColorRect
var _hbox: HBoxContainer
var _col1: VBoxContainer
var _col2: VBoxContainer
var _map_text: Label
var _resume_btn: Button
var _quit_btn: Button
var _section_labels: Array[Label] = []

var _scale: float = 1.0

# Cached map data (filled from main node each frame)
var _map_data_ready: bool = false
var _cached_map_w: float = 3200.0
var _cached_map_h: float = 2400.0
var _cached_obstacles: Array[Vector2] = []


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	mouse_filter = MOUSE_FILTER_STOP
	anchor_right = 1.0
	anchor_bottom = 1.0
	visible = false

	# Dark overlay
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.82)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# ── Outer container ──
	_outer = VBoxContainer.new()
	_outer.anchor_left = 0.5
	_outer.anchor_top = 0.0
	_outer.anchor_right = 0.5
	_outer.anchor_bottom = 1.0
	add_child(_outer)

	# Title
	_title = Label.new()
	_title.text = I18N.t("pause.title")
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_color_override("font_color", Color.WHITE)
	_outer.add_child(_title)

	# Separator
	_sep = ColorRect.new()
	_sep.color = Color(0.9, 0.8, 0.2, 0.3)
	_sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_outer.add_child(_sep)

	_outer.add_spacer(false)

	# ── HBox: stats | minimap ──
	_hbox = HBoxContainer.new()
	_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_outer.add_child(_hbox)

	# ── Column 1: Stats ──
	_col1 = VBoxContainer.new()
	_col1.add_theme_constant_override("separation", 3)
	_col1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_col1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hbox.add_child(_col1)

	_add_section_label(_col1, I18N.t("pause.character"))
	var char_name_lbl = _stat_label(_col1, "", Color.WHITE)
	var char_lv_lbl = _stat_label(_col1, "", Color.WHITE)
	_col1.add_spacer(true)
	_add_section_label(_col1, I18N.t("pause.run_stats"))
	var kills_lbl = _stat_label(_col1, "", Color.WHITE)
	var time_lbl = _stat_label(_col1, "", Color.WHITE)
	var gold_lbl = _stat_label(_col1, "", Color(0.9, 0.8, 0.1))
	_col1.add_spacer(true)
	_add_section_label(_col1, I18N.t("pause.combat_stats"))
	var hp_lbl = _stat_label(_col1, "", Color.WHITE)
	var dmg_lbl = _stat_label(_col1, "", Color.WHITE)
	var spd_lbl = _stat_label(_col1, "", Color.WHITE)
	var area_lbl = _stat_label(_col1, "", Color.WHITE)
	var cd_lbl = _stat_label(_col1, "", Color.WHITE)
	var armor_lbl = _stat_label(_col1, "", Color.WHITE)

	_stat_labels = [char_name_lbl, char_lv_lbl, kills_lbl, time_lbl, gold_lbl,
					hp_lbl, dmg_lbl, spd_lbl, area_lbl, cd_lbl, armor_lbl]

	# ── Column 2: Minimap ──
	_col2 = VBoxContainer.new()
	_col2.add_theme_constant_override("separation", 4)
	_col2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_col2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hbox.add_child(_col2)

	# Minimap node (always created, visibility toggled by relic check)
	_minimap = Control.new()
	_minimap.set_script(Minimap)
	_minimap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_minimap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_minimap.visible = false
	_col2.add_child(_minimap)

	# "Map locked" hint (shown when relic not owned)
	_map_text = Label.new()
	_map_text.text = I18N.t("pause.map_available")
	_map_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_map_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_map_text.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	_map_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_map_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_text.visible = false
	_col2.add_child(_map_text)

	# ── Grim Grimoire ──
	_grimoire_header = _build_section_header(I18N.t("pause.grimoire"), Color(0.9, 0.7, 0.1))
	_grimoire_header.visible = false
	_outer.add_child(_grimoire_header)
	_grimoire_container = VBoxContainer.new()
	_grimoire_container.add_theme_constant_override("separation", 1)
	_grimoire_container.visible = false
	_outer.add_child(_grimoire_container)

	# ── Bottom spacer + buttons ──
	_outer.add_spacer(true)

	_resume_btn = Button.new()
	_resume_btn.text = I18N.t("pause.resume")
	_resume_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_outer.add_child(_resume_btn)
	_resume_btn.pressed.connect(_on_resume_pressed)

	_quit_btn = Button.new()
	_quit_btn.text = I18N.t("pause.quit")
	_quit_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_outer.add_child(_quit_btn)
	_quit_btn.pressed.connect(_on_quit_pressed)

	# ── Apply responsive + styles ──
	_apply_responsive()
	_style_button(_resume_btn, Color(0.15, 0.45, 0.15), Color(0.25, 0.65, 0.25))
	_style_button(_quit_btn, Color(0.45, 0.15, 0.15), Color(0.65, 0.25, 0.25))


func _notification(what):
	if what == NOTIFICATION_RESIZED and _outer != null:
		_apply_responsive()


# ═══════════════════════════════════════════
# Responsive layout
# ═══════════════════════════════════════════

func _apply_responsive():
	var vp = get_viewport().get_visible_rect().size
	if vp.x <= 0 or vp.y <= 0:
		return

	_scale = clamp(vp.y / BASE_HEIGHT, 0.45, 3.0)

	# Panel
	var panel_w = clamp(vp.x * 0.56, 420.0, 900.0 * _scale)
	var half = panel_w / 2.0
	_outer.offset_left = -half
	_outer.offset_right = half
	_outer.offset_top = max(6, 18 * _scale)
	_outer.offset_bottom = -max(4, 10 * _scale)

	# Spacing
	var sep = max(1, int(3 * _scale))
	_outer.add_theme_constant_override("separation", sep)
	_hbox.add_theme_constant_override("separation", max(6, int(16 * _scale)))
	_col1.add_theme_constant_override("separation", max(1, int(3 * _scale)))
	_col2.add_theme_constant_override("separation", max(1, int(4 * _scale)))

	# Fonts
	_title.add_theme_font_size_override("font_size", max(14, int(FONT_TITLE * _scale)))
	for lbl in _section_labels:
		if is_instance_valid(lbl):
			lbl.add_theme_font_size_override("font_size", max(9, int(FONT_SECTION * _scale)))

	if _stat_labels.size() >= 1:
		_stat_labels[0].add_theme_font_size_override("font_size", max(10, int(FONT_STAT_VAL * _scale)))
	for i in range(1, _stat_labels.size()):
		if is_instance_valid(_stat_labels[i]):
			_stat_labels[i].add_theme_font_size_override("font_size", max(8, int(FONT_STAT * _scale)))

	# Separator
	_sep.custom_minimum_size = Vector2(clamp(panel_w * 0.5, 80.0, 400.0), max(1, 2 * _scale))

	# Buttons
	var btn_w = clamp(panel_w * 0.28, 120.0, 220.0)
	var btn_h = clamp(34 * _scale, 26, 64)
	for btn in [_resume_btn, _quit_btn]:
		if is_instance_valid(btn):
			btn.custom_minimum_size = Vector2(btn_w, btn_h)
			btn.add_theme_font_size_override("font_size", max(10, int(FONT_BTN * _scale)))

	# Map hint font
	if is_instance_valid(_map_text):
		_map_text.add_theme_font_size_override("font_size", max(9, int(FONT_HINT * _scale)))

	# Update minimap draw rect (match its allocated area in column 2)
	_update_minimap_rect()


# ═══════════════════════════════════════════
# Minimap helpers
# ═══════════════════════════════════════════

func _update_minimap_rect():
	if not is_instance_valid(_minimap) or not _minimap.visible:
		return
	# Schedule a deferred update so the container layout is resolved
	call_deferred("_do_update_minimap_rect")


func _do_update_minimap_rect():
	if not is_instance_valid(_minimap) or not _minimap.visible:
		return
	var mm_size = _minimap.size
	if mm_size.x <= 0 or mm_size.y <= 0:
		return
	# The minimap draws relative to its parent (col2), so pass a rect
	# with local position (0,0) and the minimap's allocated size
	_minimap.set_draw_rect(Rect2(Vector2.ZERO, mm_size))


func _cache_map_data():
	# Read map data from main Node2D (parent's parent in scene tree)
	var main = get_parent().get_parent()
	if not is_instance_valid(main):
		return
	_cached_map_w = main.map_width
	_cached_map_h = main.map_height
	_cached_obstacles = main._obstacle_positions.duplicate()
	_map_data_ready = true


# ═══════════════════════════════════════════
# Helpers
# ═══════════════════════════════════════════

func _build_section_header(text: String, color: Color) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_section_labels.append(lbl)
	return lbl


func _add_section_label(parent: Node, text: String):
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	_section_labels.append(lbl)
	parent.add_child(lbl)


func _stat_label(parent: Node, text: String, color: Color) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl


# ═══════════════════════════════════════════
# Per-frame stats + minimap update
# ═══════════════════════════════════════════

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

	_stat_labels[0].text = char_i18n + " — " + char_weapon
	_stat_labels[1].text = I18N.t("pause.level") % [player.level, player.xp, player.xp_to_next]

	var main = get_parent().get_parent()
	var kills = main.total_kills if is_instance_valid(main) else 0
	var run_time = main.game_time if is_instance_valid(main) else 0.0
	var m = int(run_time) / 60
	var s = int(run_time) % 60
	var gold_amt = PowerUpManager.run_gold if PowerUpManager else 0

	_stat_labels[2].text = I18N.t("pause.kills") % kills
	_stat_labels[3].text = I18N.t("pause.time") % [m, s]
	_stat_labels[4].text = I18N.t("pause.gold") % gold_amt

	var hp = player.health
	var max_hp = player.max_health
	_stat_labels[5].text = I18N.t("pause.hp") % [hp, max_hp]
	_stat_labels[6].text = I18N.t("pause.dmg") % player.damage_mult
	_stat_labels[7].text = I18N.t("pause.spd") % player.move_speed
	_stat_labels[8].text = I18N.t("pause.area") % player.area_mult
	_stat_labels[9].text = I18N.t("pause.cd") % int(player.cooldown_reduction * 100)
	_stat_labels[10].text = I18N.t("pause.armor") % player.armor

	# ── Minimap ──
	_update_minimap_state(player, main)


func _update_minimap_state(player, main):
	var has_map_relic = RelicManager and RelicManager.has_relic("milky_way_map")

	# Cache map geometry on first show
	if not _map_data_ready and has_map_relic and is_instance_valid(main):
		_cache_map_data()

	if has_map_relic and is_instance_valid(_minimap):
		_minimap.visible = true
		_map_text.visible = false

		# One-time setup
		if _map_data_ready:
			_minimap.set_map_size(_cached_map_w, _cached_map_h)
			_minimap.set_obstacles(_cached_obstacles)

		# Per-frame position data (main node keeps state even while paused)
		_minimap.set_player_pos(player.global_position)
		var vs = get_viewport().get_visible_rect().size
		if is_instance_valid(main):
			_minimap.set_camera_view(main._camera.global_position if main._camera else Vector2.ZERO, vs)
			var poses: Array[Vector2] = []
			for r in main._stage_relics:
				if is_instance_valid(r):
					poses.append(r.global_position)
			_minimap.set_relic_positions(poses)

		# Keep draw rect in sync (in case of resize)
		_update_minimap_rect()

	else:
		_minimap.visible = false
		_map_text.visible = true
		if has_map_relic:
			_map_text.text = I18N.t("pause.map_available")
		else:
			_map_text.text = I18N.t("pause.map_available") + "\n🔒 " + (I18N.t("menu.relics") if I18N.current_lang == "zh" else "Find Milky Way Map")

	# ── Grim Grimoire ──
	if RelicManager and RelicManager.has_relic("grim_grimoire"):
		_grimoire_header.visible = true
		_grimoire_container.visible = true
		for c in _grimoire_container.get_children():
			c.queue_free()
		var evo = Player.EVOLUTION_RECIPES
		for wpn_type in evo:
			var recipe = evo[wpn_type]
			var wpn_nm = I18N.t(_wpn_i18n_key(wpn_type), _weapon_name(wpn_type))
			var pass_nm = I18N.t(_pass_i18n_key(recipe["passive"]), _passive_name(recipe["passive"]))
			var evo_name = recipe.get("name", "?")
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 4)
			row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			var lbl = Label.new()
			lbl.text = wpn_nm + " + " + pass_nm + " (Lv." + str(recipe["passive_level"]) + ") → " + evo_name
			lbl.add_theme_font_size_override("font_size", max(8, int(11 * _scale)))
			lbl.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3))
			row.add_child(lbl)
			_grimoire_container.add_child(row)
	else:
		_grimoire_header.visible = false
		_grimoire_container.visible = false


# ═══════════════════════════════════════════
# Static helpers (weapon / passive names for Grimoire)
# ═══════════════════════════════════════════

static func _weapon_name(t: int) -> String:
	match t:
		0: return "Whip"
		1: return "Magic Wand"
		2: return "Garlic"
		10: return "Knife"
		11: return "Axe"
		12: return "Fire Wand"
		16: return "Cross"
		17: return "King Bible"
		18: return "Santa Water"
		19: return "Runetracer"
		20: return "Lightning Ring"
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
		21: return "Clover"
		22: return "Spellbinder"
		23: return "Armor"
		24: return "Bracer"
		25: return "Skull O'Maniac"
		26: return "Tiragisú"
		27: return "Torrona's Box"
		28: return "Silver Ring"
		29: return "Gold Ring"
		30: return "Metaglio Left"
		31: return "Metaglio Right"
	return "?"


static func _wpn_i18n_key(t: int) -> String:
	match t:
		0: return "wpn.whip"
		1: return "wpn.wand"
		2: return "wpn.garlic"
		10: return "wpn.knife"
		11: return "wpn.axe"
		12: return "wpn.firewand"
		16: return "wpn.cross"
		17: return "wpn.bible"
		18: return "wpn.santa_water"
		19: return "wpn.runetracer"
		20: return "wpn.lightning"
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
		21: return "pas.clover"
		22: return "pas.spellbinder"
		23: return "pas.armor"
		24: return "pas.bracer"
		25: return "pas.skull"
		26: return "pas.tiragisu"
		27: return "pas.torrona"
		28: return "pas.silver_ring"
		29: return "pas.gold_ring"
		30: return "pas.metaglio_left"
		31: return "pas.metaglio_right"
	return "pas.wings"


# ═══════════════════════════════════════════
# Button style
# ═══════════════════════════════════════════

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
