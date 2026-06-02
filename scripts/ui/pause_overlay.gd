extends Control

signal toggle_pause
signal quit_to_menu

const WeaponManager = preload("res://scripts/entities/player/weapon_manager.gd")
# Character data loaded lazily via DataRegistry
const Player = preload("res://scripts/entities/player/player.gd")
const MinimapScript = preload("res://scripts/ui/minimap.gd")

# Scene nodes (Outer is the root container — defined in .tscn)
@onready var _outer: VBoxContainer = $Outer

# Dynamically built children
var _title: Label
var _sep: ColorRect
var _hbox: HBoxContainer
var _col1: VBoxContainer
var _col2: VBoxContainer
var _col3: VBoxContainer
var _minimap: Control
var _map_text: Label
var _grimoire_header: Label
var _grimoire_container: VBoxContainer
var _god_btn: Button
var _resume_btn: Button
var _quit_btn: Button
var _stat_labels: Array[Label] = []
var _minimap_initialized := false

# Cached map data
var _map_data_ready: bool = false
var _cached_map_w: float = 3200.0
var _cached_map_h: float = 2400.0
var _cached_obstacles: Array[Vector2] = []
var _cached_chests: Array[Vector2] = []
var _cached_fountains: Array[Vector2] = []
var _cached_hazards: Array[Vector2] = []
var _cached_boosts: Array[Vector2] = []


func _ready():
	_resize_outer()
	get_viewport().size_changed.connect(_resize_outer)
	_build_ui()
	# Signal connections
	_resume_btn.pressed.connect(_on_resume_pressed)
	_quit_btn.pressed.connect(_on_quit_pressed)
	# Initial i18n text
	_title.text = I18N.t("pause.title")
	_god_btn.text = "无敌"
	_resume_btn.text = I18N.t("pause.resume")
	_quit_btn.text = I18N.t("pause.quit")


func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		_on_resume_pressed()
		get_viewport().set_input_as_handled()


func _resize_outer():
	var vp_w = get_viewport().get_visible_rect().size.x
	var target_w = mini(vp_w * 0.75, 1000.0)
	_outer.offset_left = -target_w * 0.5
	_outer.offset_right = target_w * 0.5


func _build_ui():
	# Title
	_title = Label.new()
	_title.theme_type_variation = &"TitleLabel"
	_title.text = ""
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 32)
	_outer.add_child(_title)

	# Separator
	_sep = ColorRect.new()
	_sep.color = Color(0.9, 0.8, 0.2, 0.3)
	_sep.custom_minimum_size = Vector2(200, 2)
	_sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_outer.add_child(_sep)

	# Top spacer
	var ts = Control.new()
	ts.custom_minimum_size = Vector2(0, 4)
	_outer.add_child(ts)

	# HBox: stats | minimap | grimoire
	_hbox = HBoxContainer.new()
	_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hbox.add_theme_constant_override("separation", 16)
	_outer.add_child(_hbox)

	# Column 1: stats
	_col1 = VBoxContainer.new()
	_col1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_col1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_col1.add_theme_constant_override("separation", 3)
	_hbox.add_child(_col1)
	_build_stat_labels()

	# Column 2: minimap area
	_col2 = VBoxContainer.new()
	_col2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_col2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_col2.add_theme_constant_override("separation", 4)
	_hbox.add_child(_col2)
	_build_minimap_area()

	# Column 3: Grim Grimoire
	_col3 = VBoxContainer.new()
	_col3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_col3.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_col3.add_theme_constant_override("separation", 4)
	_hbox.add_child(_col3)

	_grimoire_header = Label.new()
	_grimoire_header.text = I18N.t("relic.grim_grimoire")
	_grimoire_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_grimoire_header.add_theme_color_override("font_color", Color(0.9, 0.7, 0.1))
	_grimoire_header.add_theme_font_size_override("font_size", 15)
	_grimoire_header.visible = false
	_col3.add_child(_grimoire_header)

	_grimoire_container = VBoxContainer.new()
	_grimoire_container.add_theme_constant_override("separation", 1)
	_grimoire_container.visible = false
	_col3.add_child(_grimoire_container)

	# Bottom spacer
	var bs = Control.new()
	bs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_outer.add_child(bs)

	# Buttons: God Mode | Resume | Quit
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	_outer.add_child(btn_row)

	_god_btn = Button.new()
	_god_btn.text = ""
	_god_btn.toggle_mode = true
	_god_btn.custom_minimum_size = Vector2(120, 40)
	_god_btn.add_theme_font_size_override("font_size", 16)
	_god_btn.toggled.connect(func(v):
		EventBus.set_config("god_mode", v)
		_god_btn.text = "无敌 ON" if v else "无敌")
	btn_row.add_child(_god_btn)
	
	_resume_btn = Button.new()
	_resume_btn.text = ""
	_resume_btn.theme_type_variation = &"PrimaryButton"
	_resume_btn.custom_minimum_size = Vector2(120, 40)
	_resume_btn.add_theme_font_size_override("font_size", 16)
	btn_row.add_child(_resume_btn)

	_quit_btn = Button.new()
	_quit_btn.text = ""
	_quit_btn.theme_type_variation = &"DangerButton"
	_quit_btn.custom_minimum_size = Vector2(120, 40)
	_quit_btn.add_theme_font_size_override("font_size", 16)
	btn_row.add_child(_quit_btn)


func _build_stat_labels():
	var add_section = func(text: String):
		var lbl = Label.new()
		lbl.text = text
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.theme_type_variation = &"TitleLabel"
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
		_col1.add_child(lbl)
		return lbl

	var add_val = func() -> Label:
		var lbl = Label.new()
		_col1.add_child(lbl)
		return lbl

	add_section.call(I18N.t("pause.character"))
	_stat_labels.append(add_val.call())
	_stat_labels.append(add_val.call())

	# Spacer between sections
	var sp001 = Control.new()
	sp001.custom_minimum_size = Vector2(0, 8)
	_col1.add_child(sp001)

	add_section.call(I18N.t("pause.combat_stats"))
	for i in 16:
		_stat_labels.append(add_val.call())


func _build_minimap_area():
	_minimap = Control.new()
	_minimap.set_script(MinimapScript)
	_minimap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_minimap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_minimap.visible = false
	_col2.add_child(_minimap)

	_map_text = Label.new()
	_map_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_map_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_map_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_map_text.theme_type_variation = &"DimLabel"
	_map_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_text.visible = false
	_col2.add_child(_map_text)


# ═══════════════════════════════════════════
# Minimap helpers
# ═══════════════════════════════════════════

func _update_minimap_rect():
	if not is_instance_valid(_minimap) or not _minimap.visible:
		return
	call_deferred("_do_update_minimap_rect")


func _do_update_minimap_rect():
	if not is_instance_valid(_minimap) or not _minimap.visible:
		return
	var mm_size = _minimap.size
	if mm_size.x <= 0 or mm_size.y <= 0:
		return
	_minimap.set_draw_rect(Rect2(Vector2.ZERO, mm_size))


func _cache_map_data():
	var main = get_parent().get_parent()
	if not is_instance_valid(main):
		return
	
	# 通过访问器获取数据（向后兼容）
	if main.has_method("get_game_state"):
		var gs = main.get_game_state()
		_cached_map_w = gs.map_width if gs else 3200.0
		_cached_map_h = gs.map_height if gs else 2400.0
	else:
		_cached_map_w = main.map_width if "map_width" in main else 3200.0
		_cached_map_h = main.map_height if "map_height" in main else 2400.0
	
	_cached_obstacles = main.get_obstacle_positions() if main.has_method("get_obstacle_positions") else []

	var pm = main.get_prop_manager() if main.has_method("get_prop_manager") else null
	if pm:
		_cached_chests = pm.get_chest_positions() if pm.has_method("get_chest_positions") else []
		_cached_fountains = pm.get_fountain_positions() if pm.has_method("get_fountain_positions") else []
		_cached_hazards = pm.get_hazard_positions() if pm.has_method("get_hazard_positions") else []
		_cached_boosts = pm.get_boost_positions() if pm.has_method("get_boost_positions") else []
	else:
		_cached_chests = []
		_cached_fountains = []
		_cached_hazards = []
		_cached_boosts = []

	_map_data_ready = true


# ═══════════════════════════════════════════
# Per-frame stats + minimap update
# ═══════════════════════════════════════════

func _process(_delta):
	if not visible:
		_minimap_initialized = false
		return
	# 首次可见时一次性初始化 minimap（此时布局已计算，_minimap.size 有效）
	if not _minimap_initialized:
		_minimap_initialized = true
		_setup_minimap()
	_update_stats()


func _update_stats():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var char_data = EventBus.get_config("selected_character", {})
	var char_name = char_data.get("name", "?")
	var char_weapon = DataRegistry.characters().get_weapon_name(char_data.get("weapon", 0)) if char_data else "?"
	var char_id = char_data.get("id", 0) if char_data else 0
	var char_i18n = I18N.t("char." + str(char_id) + "_name", char_name)

	_stat_labels[0].text = char_i18n + " — " + char_weapon
	_stat_labels[1].text = I18N.t("pause.level") % [player.level, player.xp, player.xp_to_next]

	_stat_labels[2].text = I18N.t("pause.hp") % [player.health, player.max_health]
	_stat_labels[3].text = I18N.t("pause.regen") % player.recovery
	_stat_labels[4].text = I18N.t("pause.dmg") % player.might
	_stat_labels[5].text = I18N.t("pause.spd") % player.move_speed
	_stat_labels[6].text = I18N.t("pause.area") % player.area_mult
	_stat_labels[7].text = I18N.t("pause.proj_spd") % player.speed_mult
	_stat_labels[8].text = I18N.t("pause.duration") % player.duration_mult
	_stat_labels[9].text = I18N.t("pause.cd") % int((1.0 - player.cooldown_mult) * 100)
	_stat_labels[10].text = I18N.t("pause.amount") % player.projectile_bonus
	_stat_labels[11].text = I18N.t("pause.armor") % player.armor
	_stat_labels[12].text = I18N.t("pause.growth") % player.growth_mult
	_stat_labels[13].text = I18N.t("pause.luck") % (player.luck * 100)
	_stat_labels[14].text = I18N.t("pause.greed") % (player.greed_mult * 100)
	_stat_labels[15].text = I18N.t("pause.magnet") % player.pickup_range
	_stat_labels[16].text = I18N.t("pause.curse") % (player.curse * 100)
	_stat_labels[17].text = I18N.t("pause.revivals") % player.revivals


func _setup_minimap():
	var player = get_tree().get_first_node_in_group("player")
	var main = get_parent().get_parent()
	if not player or not is_instance_valid(main):
		return

	var has_map_relic = RelicManager and RelicManager.is_feature_unlocked("map_pause")

	if not _map_data_ready and has_map_relic:
		_cache_map_data()

	if has_map_relic and is_instance_valid(_minimap):
		_minimap.visible = true
		_map_text.visible = false

		if _map_data_ready:
			_minimap.set_map_size(_cached_map_w, _cached_map_h)
			_minimap.set_obstacles(_cached_obstacles)
			_minimap.set_chest_positions(_cached_chests)
			_minimap.set_fountain_positions(_cached_fountains)
			_minimap.set_hazard_positions(_cached_hazards)
			_minimap.set_boost_positions(_cached_boosts)

		_minimap.set_player_pos(player.global_position)
		var vs = get_viewport().get_visible_rect().size
		var cam = main.get_camera() if main.has_method("get_camera") else null
		var cam_pos = cam.global_position if cam else Vector2.ZERO
		_minimap.set_camera_view(cam_pos, vs)
		var poses: Array[Vector2] = []
		for r in (main._stage_relics if "_stage_relics" in main else []):
			if is_instance_valid(r):
				poses.append(r.global_position)
		_minimap.set_relic_positions(poses)

		_update_minimap_rect()
	else:
		_minimap.visible = false
		_map_text.visible = true
		if has_map_relic:
			_map_text.text = I18N.t("pause.map_available")
		else:
			_map_text.text = I18N.t("pause.map_available") + "\n🔒 " + I18N.t("pause.find_milky_way")

	# Grim Grimoire
	if RelicManager and RelicManager.is_feature_unlocked("grimoire_pause"):
		_grimoire_header.visible = true
		_grimoire_container.visible = true
		for c in _grimoire_container.get_children():
			c.queue_free()
		var evo = WeaponManager.EVOLUTION_RECIPES
		for wpn_type in evo:
			var recipe = evo[wpn_type]
			var wpn_nm = I18N.t(_wpn_i18n_key(wpn_type), _weapon_name(wpn_type))
			var pass_nm = I18N.t(_pass_i18n_key(recipe["passive"]), _passive_name(recipe["passive"]))
			var evo_name = I18N.t(_evo_i18n_key(wpn_type) + "_name", recipe.get("name", "?"))
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 4)
			row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			var lbl = Label.new()
			lbl.text = wpn_nm + " + " + pass_nm + " (Lv." + str(recipe["passive_level"]) + ") → " + evo_name
			lbl.add_theme_font_size_override("font_size", 12)
			lbl.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3))
			row.add_child(lbl)
			_grimoire_container.add_child(row)
	else:
		_grimoire_header.visible = false
		_grimoire_container.visible = false



# ═══════════════════════════════════════════
# Static helpers
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
		32: return "Pentagram"
		33: return "Song of Mana"
		34: return "Gatti Amari"
		35: return "Phiera Der Tuphello"
		36: return "Eight The Sparrow"
		37: return "Victory Sword"
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
		15: return "Attractorb"
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
		32: return "wpn.pentagram"
		33: return "wpn.song_of_mana"
		34: return "wpn.gatti_amari"
		35: return "wpn.phiera"
		36: return "wpn.eight"
		37: return "wpn.victory_sword"
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


static func _evo_i18n_key(weapon_type: int) -> String:
	match weapon_type:
		0: return "evo.whip"
		1: return "evo.wand"
		2: return "evo.garlic"
		10: return "evo.knife"
		11: return "evo.axe"
		12: return "evo.firewand"
		16: return "evo.cross"
		17: return "evo.king_bible"
		18: return "evo.santa_water"
		19: return "evo.runetracer"
		20: return "evo.lightning_ring"
		32: return "evo.pentagram"
		33: return "evo.song_of_mana"
		34: return "evo.gatti_amari"
		35: return "evo.phiera"
		36: return "evo.eight"
		37: return "evo.victory_sword"
	return "evo.whip"


func show_pause():
	visible = true


func hide_pause():
	visible = false


func _on_resume_pressed():
	toggle_pause.emit()


func _on_quit_pressed():
	quit_to_menu.emit()
