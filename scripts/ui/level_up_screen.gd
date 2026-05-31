extends Control

signal upgrade_selected(upgrade_type: int)
signal evolution_selected(weapon_type: int)
signal gold_selected(amount: int)

const WeaponManager = preload("res://scripts/entities/weapon_manager.gd")
const IconGenerator = preload("res://scripts/ui/icon_generator.gd")
const UiUtils = preload("res://scripts/ui/ui_utils.gd")
# Bulk item data loaded lazily via DataRegistry (autoload)

const MAX_WEAPONS = 6
const MAX_PASSIVES = 6
const GOLD_REWARD = 9999

var player_ref
var panel: Panel
var title: Label
var container: HBoxContainer


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	mouse_filter = MOUSE_FILTER_STOP
	anchor_right = 1.0
	anchor_bottom = 1.0
	visible = false


func show_choices(p):
	player_ref = p
	visible = true
	_clear()
	_create_ui()
	_generate_and_show()


func _create_ui():
	panel = Panel.new()
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.theme_type_variation = &"OverlayPanel"
	add_child(panel)

	# Center the choice panel using anchors
	var vp = get_viewport().get_visible_rect().size
	var panel_w = mini(700, vp.x - 40)
	var panel_h = mini(400, vp.y - 40)
	var vb = VBoxContainer.new()
	vb.anchor_left = 0.5; vb.anchor_top = 0.5
	vb.anchor_right = 0.5; vb.anchor_bottom = 0.5
	vb.offset_left = -panel_w / 2; vb.offset_top = -panel_h / 2
	vb.offset_right = panel_w / 2; vb.offset_bottom = panel_h / 2
	panel.add_child(vb)

	title = Label.new()
	title.text = I18N.t("levelup.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	title.custom_minimum_size = Vector2(700, 50)
	vb.add_child(title)

	var sp = Control.new()
	sp.custom_minimum_size = Vector2(0, 20)
	vb.add_child(sp)

	container = HBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 20)
	container.size = Vector2(700, 260)
	vb.add_child(container)


func _generate_and_show():
	var possible = DataRegistry.items().DATA.keys()
	possible.shuffle()

	# Filter out locked weapons (only if UnlockManager exists)
	var um = EventBus.get_unlock_manager() if EventBus else null
	if um:
		possible = possible.filter(func(t: int):
			if not DataRegistry.items().is_weapon(t):
				return true
			return um.is_weapon_unlocked(t)
		)

	# Gather evolution candidates from owned weapons
	var evolutions: Array[int] = []
	for w in player_ref.weapon_manager.weapons:
		if player_ref.can_evolve(w.type):
			evolutions.append(w.type)

	var chosen: Array[int] = []

	# Add evolutions first (encoded as negative)
	for ev in evolutions:
		if chosen.size() < 3:
			chosen.append(-1 - ev)  # -1=whip, -2=wand, -3=garlic

	# Fill remaining slots with normal upgrades
	for p in possible:
		if chosen.size() >= 3:
			break
		# Skip weapons already being offered as evolution
		if _is_weapon(p) and evolutions.has(p):
			continue
		var lv = player_ref.get_weapon_level(p) if _is_weapon(p) else player_ref.get_passive_level(p)
		var max_lv = player_ref.get_weapon_max_level(p) if _is_weapon(p) else DataRegistry.items().item_max_level(p)
		# Skip new items beyond the slot limit
		if lv == 0:
			if _is_weapon(p) and player_ref.weapon_manager.weapons.size() >= MAX_WEAPONS:
				continue
			if _is_passive(p) and player_ref.passive_inventory.size() >= MAX_PASSIVES:
				continue
		if lv < max_lv:
			chosen.append(p)

	if chosen.is_empty():
		# If no valid choices from filtering, try including locked weapons as fallback
		if um:
			possible = DataRegistry.items().DATA.keys()
			possible.shuffle()
			for p in possible:
				if chosen.size() >= 3:
					break
				if _is_weapon(p) and evolutions.has(p):
					continue
				var lv = player_ref.get_weapon_level(p) if _is_weapon(p) else player_ref.get_passive_level(p)
				var max_lv = player_ref.get_weapon_max_level(p) if _is_weapon(p) else DataRegistry.items().item_max_level(p)
				if lv == 0:
					if _is_weapon(p) and player_ref.weapon_manager.weapons.size() >= MAX_WEAPONS:
						continue
					if _is_passive(p) and player_ref.passive_inventory.size() >= MAX_PASSIVES:
						continue
				if lv < max_lv:
					chosen.append(p)

	if chosen.is_empty():
		# If all slots maxed, offer an owned weapon upgrade anyway
		for w in player_ref.weapon_manager.weapons:
			if w.level < w.max_level:
				chosen.append(w.type)
				break
		if chosen.is_empty():
			var p = player_ref.passive_inventory.get_all()
			for t in p:
				if player_ref.get_passive_level(t) < DataRegistry.items().item_max_level(t):
					chosen.append(t)
					break
	if chosen.is_empty():
		chosen.append(GOLD_REWARD)

	for c in chosen:
		if c < 0:
			_add_evolution_choice(-1 - c)
		else:
			_add_choice_button(c)


func _add_choice_button(t: int):
	var vb2 = VBoxContainer.new()
	vb2.custom_minimum_size = Vector2(190, 200)
	vb2.alignment = BoxContainer.ALIGNMENT_CENTER

	if t == GOLD_REWARD:
		var gold_amt = 50 + player_ref.level * 30
		# Gold icon (coin circle)
		var icon = TextureRect.new()
		icon.texture = IconGenerator.generate(14, 40)  # STONE_MASK icon = coin
		icon.custom_minimum_size = Vector2(40, 40)
		icon.stretch_mode = TextureRect.STRETCH_KEEP
		icon.modulate = Color(0.9, 0.8, 0.1)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vb2.add_child(icon)

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 120)
		UiUtils.style_button(btn, Color(0.6, 0.5, 0.1) * 0.25, Color(0.9, 0.8, 0.1))

		var l1 = Label.new()
		l1.text = I18N.t("pickup.gold_name", "+%d Gold" % gold_amt)
		l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l1.add_theme_font_size_override("font_size", 22)
		l1.add_theme_color_override("font_color", Color(0.9, 0.8, 0.1))
		vb2.add_child(l1)

		var l2 = Label.new()
		l2.text = I18N.t("levelup.gold_desc", "All slots full!")
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l2.add_theme_font_size_override("font_size", 14)
		l2.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
		vb2.add_child(l2)

		var l3 = Label.new()
		l3.text = ""
		l3.custom_minimum_size = Vector2(0, 30)
		vb2.add_child(l3)

		vb2.add_child(btn)
		btn.pressed.connect(_on_gold.bind(gold_amt))
		container.add_child(vb2)
		return

	var nm = I18N.t(DataRegistry.items().item_name_key(t), DataRegistry.items().item_name(t))
	var lv = player_ref.get_weapon_level(t) if DataRegistry.items().is_weapon(t) else player_ref.get_passive_level(t)
	var lv_txt = I18N.t("levelup.new") if lv == 0 else I18N.t("levelup.level") % [lv, lv + 1]
	var desc = I18N.t(DataRegistry.items().item_desc_key(t), DataRegistry.items().item_desc(t))
	var col = DataRegistry.items().item_color(t)

	# Icon at top (colored circle + emoji, single node from factory)
	var icon_node = IconGenerator.make_icon_node(t, 40)
	icon_node.custom_minimum_size = Vector2(40, 40)
	icon_node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb2.add_child(icon_node)

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 120)
	UiUtils.style_button(btn, col * 0.25, col)

	var l1 = Label.new()
	l1.text = nm
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l1.add_theme_font_size_override("font_size", 22)
	l1.add_theme_color_override("font_color", col)
	vb2.add_child(l1)

	var l2 = Label.new()
	l2.text = lv_txt
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l2.add_theme_font_size_override("font_size", 14)
	l2.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vb2.add_child(l2)

	var l3 = Label.new()
	l3.text = desc
	l3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l3.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l3.add_theme_font_size_override("font_size", 12)
	l3.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vb2.add_child(l3)

	vb2.add_child(btn)

	var id = t
	btn.pressed.connect(_on_choice.bind(id))
	container.add_child(vb2)


func _add_evolution_choice(weapon_type: int):
	var vb2 = VBoxContainer.new()
	vb2.custom_minimum_size = Vector2(210, 220)
	vb2.alignment = BoxContainer.ALIGNMENT_CENTER

	var recipe = WeaponManager.EVOLUTION_RECIPES[weapon_type]
	var evo_name = recipe["name"]
	var evo_desc = recipe["desc"]

	# Golden icon at top (colored circle + emoji, single node)
	var icon_node = IconGenerator.make_icon_node(weapon_type, 44, Color(0.9, 0.7, 0.1))
	icon_node.custom_minimum_size = Vector2(44, 44)
	icon_node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb2.add_child(icon_node)

	# Golden border button
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 140)
	btn.theme_type_variation = &"GoldButton"

	# EVOLVE badge
	var badge = Label.new()
	badge.text = I18N.t("levelup.evolve")
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 16)
	badge.add_theme_color_override("font_color", Color(0.9, 0.7, 0.1))
	vb2.add_child(badge)

	# Evolved name
	var evo_i18n_name = I18N.t("evo." + _evo_i18n_key(weapon_type) + "_name", evo_name)
	var l1 = Label.new()
	l1.text = evo_i18n_name
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l1.add_theme_font_size_override("font_size", 24)
	l1.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	vb2.add_child(l1)

	# Source arrow
	var src_i18n = I18N.t(DataRegistry.items().item_name_key(weapon_type), DataRegistry.items().item_name(weapon_type))
	var l2 = Label.new()
	l2.text = src_i18n + I18N.t("levelup.evo_arrow") + evo_i18n_name
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l2.add_theme_font_size_override("font_size", 12)
	l2.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
	vb2.add_child(l2)

	# Description
	var evo_i18n_desc = I18N.t("evo." + _evo_i18n_key(weapon_type) + "_desc", evo_desc)
	var l3 = Label.new()
	l3.text = evo_i18n_desc
	l3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l3.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l3.add_theme_font_size_override("font_size", 12)
	l3.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
	vb2.add_child(l3)

	vb2.add_child(btn)

	btn.pressed.connect(_on_evolution_choice.bind(weapon_type))
	container.add_child(vb2)


func _on_choice(t: int):
	upgrade_selected.emit(t)


func _on_gold(amount: int):
	gold_selected.emit(amount)


func _on_evolution_choice(weapon_type: int):
	evolution_selected.emit(weapon_type)


func hide_screen():
	visible = false
	_clear()


func _clear():
	for c in get_children():
		c.queue_free()
	panel = null; title = null; container = null


# ── 统一委托到 ItemDefs 数据源，消除重复 ──
static func _is_weapon(t: int) -> bool:
	return DataRegistry.items().is_weapon(t)

static func _is_passive(t: int) -> bool:
	return not DataRegistry.items().is_weapon(t)

static func _name(t: int) -> String:
	return DataRegistry.items().item_name(t)

static func _desc(t: int) -> String:
	return DataRegistry.items().item_desc(t)

static func _item_name_key(t: int) -> String:
	return DataRegistry.items().item_name_key(t)

static func _item_desc_key(t: int) -> String:
	return DataRegistry.items().item_desc_key(t)

# 委托到 ItemDefs 统一数据源
static func _evo_i18n_key(weapon_type: int) -> String:
	return DataRegistry.items().item_evo_key(weapon_type)

static func _color(t: int) -> Color:
	return DataRegistry.items().item_color(t)
