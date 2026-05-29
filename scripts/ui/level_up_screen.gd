extends Control

signal upgrade_selected(upgrade_type: int)
signal evolution_selected(weapon_type: int)

const IconGenerator = preload("res://scripts/ui/icon_generator.gd")
const UiUtils = preload("res://scripts/ui/ui_utils.gd")

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
	# Full-screen dark backdrop
	panel = Panel.new()
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 0
	panel.offset_top = 0
	panel.offset_right = 0
	panel.offset_bottom = 0
	add_child(panel)

	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.85)
	panel.add_theme_stylebox_override("panel", bg)

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
	var possible = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
	possible.shuffle()

	# Gather evolution candidates from owned weapons
	var evolutions: Array[int] = []
	for w in player_ref.weapons:
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
		var max_lv = player_ref.get_weapon_max_level(p) if _is_weapon(p) else 8
		if lv < max_lv:
			chosen.append(p)

	if chosen.is_empty():
		chosen.append(0)

	for c in chosen:
		if c < 0:
			_add_evolution_choice(-1 - c)
		else:
			_add_choice_button(c)


func _add_choice_button(t: int):
	var vb2 = VBoxContainer.new()
	vb2.custom_minimum_size = Vector2(190, 200)
	vb2.alignment = BoxContainer.ALIGNMENT_CENTER
	var nm = I18N.t(_item_name_key(t), _name(t))
	var lv = player_ref.get_weapon_level(t) if _is_weapon(t) else player_ref.get_passive_level(t)
	var lv_txt = I18N.t("levelup.new") if lv == 0 else I18N.t("levelup.level") % [lv, lv + 1]
	var desc = I18N.t(_item_desc_key(t), _desc(t))
	var col = _color(t)

	# Icon at top
	var icon = TextureRect.new()
	icon.texture = IconGenerator.generate(t, 40)
	icon.custom_minimum_size = Vector2(40, 40)
	icon.stretch_mode = TextureRect.STRETCH_KEEP
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb2.add_child(icon)

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

	var recipe = Player.EVOLUTION_RECIPES[weapon_type]
	var evo_name = recipe["name"]
	var evo_desc = recipe["desc"]

	# Golden icon at top
	var icon = TextureRect.new()
	icon.texture = IconGenerator.generate(weapon_type, 44)
	icon.custom_minimum_size = Vector2(44, 44)
	icon.stretch_mode = TextureRect.STRETCH_KEEP
	icon.modulate = Color(0.9, 0.7, 0.1)  # golden tint
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb2.add_child(icon)

	# Golden border button
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 140)
	UiUtils.style_button(btn, Color(0.3, 0.2, 0.0), Color(0.9, 0.7, 0.1))

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
	var src_i18n = I18N.t(_item_name_key(weapon_type), _name(weapon_type))
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


func _on_evolution_choice(weapon_type: int):
	evolution_selected.emit(weapon_type)


func hide_screen():
	visible = false
	_clear()


func _clear():
	for c in get_children():
		c.queue_free()
	panel = null; title = null; container = null


static func _is_weapon(t: int) -> bool:
	return t in [0, 1, 2, 10, 11, 12, 16, 17, 18, 19, 20]


static func _is_passive(t: int) -> bool:
	return t in [3, 4, 5, 6, 7, 8, 9, 13, 14, 15, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31]


static func _name(t: int) -> String:
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
	return ""


static func _desc(t: int) -> String:
	match t:
		0: return "Strike enemies in a wide arc"
		1: return "Fire homing bolts at enemies"
		2: return "Damage enemies around you"
		10: return "Throw daggers in faced direction"
		11: return "Hurl a heavy axe in an arc"
		12: return "Shoot explosive fire at enemies"
		16: return "Boomerang that seeks enemies"
		17: return "Orbiting projectiles"
		18: return "Create damaging puddles"
		19: return "Bouncing tracer projectiles"
		20: return "Strike enemies with lightning"
		3: return "Increase movement speed"
		4: return "Increase all damage"
		5: return "Reduce all weapon cooldowns"
		6: return "Increase max health"
		7: return "Increase attack area"
		8: return "Gain more XP"
		9: return "Regenerate HP over time"
		13: return "+1 Projectile per level"
		14: return "+20% Gold per level"
		15: return "Increase pickup range"
		21: return "Increase luck"
		22: return "Increase effect duration"
		23: return "Reduce damage taken"
		24: return "Increase projectile speed"
		25: return "Increase enemy difficulty"
		26: return "Revive on death"
		27: return "Boost all stats slightly"
		28: return "+Duration, +Area"
		29: return "Curse enemies"
		30: return "+Recovery, +Max HP"
		31: return "Curse enemies"
	return ""


# Map item type to i18n key for name
static func _item_name_key(t: int) -> String:
	match t:
		0: return "item.whip_name"
		1: return "item.wand_name"
		2: return "item.garlic_name"
		10: return "item.knife_name"
		11: return "item.axe_name"
		12: return "item.firewand_name"
		16: return "item.cross_name"
		17: return "item.bible_name"
		18: return "item.santa_water_name"
		19: return "item.runetracer_name"
		20: return "item.lightning_name"
		3: return "item.wings_name"
		4: return "item.spinach_name"
		5: return "item.tome_name"
		6: return "item.hollow_name"
		7: return "item.candel_name"
		8: return "item.crown_name"
		9: return "item.pummarola_name"
		13: return "item.duplicator_name"
		14: return "item.stonemask_name"
		15: return "item.magnet_name"
		21: return "item.clover_name"
		22: return "item.spellbinder_name"
		23: return "item.armor_name"
		24: return "item.bracer_name"
		25: return "item.skull_name"
		26: return "item.tiragisu_name"
		27: return "item.torrona_name"
		28: return "item.silver_ring_name"
		29: return "item.gold_ring_name"
		30: return "item.metaglio_left_name"
		31: return "item.metaglio_right_name"
	return ""


# Map item type to i18n key for description
static func _item_desc_key(t: int) -> String:
	match t:
		0: return "item.whip_desc"
		1: return "item.wand_desc"
		2: return "item.garlic_desc"
		10: return "item.knife_desc"
		11: return "item.axe_desc"
		12: return "item.firewand_desc"
		16: return "item.cross_desc"
		17: return "item.bible_desc"
		18: return "item.santa_water_desc"
		19: return "item.runetracer_desc"
		20: return "item.lightning_desc"
		3: return "item.wings_desc"
		4: return "item.spinach_desc"
		5: return "item.tome_desc"
		6: return "item.hollow_desc"
		7: return "item.candel_desc"
		8: return "item.crown_desc"
		9: return "item.pummarola_desc"
		13: return "item.duplicator_desc"
		14: return "item.stonemask_desc"
		15: return "item.magnet_desc"
		21: return "item.clover_desc"
		22: return "item.spellbinder_desc"
		23: return "item.armor_desc"
		24: return "item.bracer_desc"
		25: return "item.skull_desc"
		26: return "item.tiragisu_desc"
		27: return "item.torrona_desc"
		28: return "item.silver_ring_desc"
		29: return "item.gold_ring_desc"
		30: return "item.metaglio_left_desc"
		31: return "item.metaglio_right_desc"
	return ""


# Map weapon type to evo i18n key prefix
static func _evo_i18n_key(weapon_type: int) -> String:
	match weapon_type:
		0: return "whip"
		1: return "wand"
		2: return "garlic"
		10: return "knife"
		11: return "axe"
		12: return "firewand"
		16: return "cross"
		17: return "king_bible"
		18: return "santa_water"
		19: return "runetracer"
		20: return "lightning_ring"
	return "whip"


static func _color(t: int) -> Color:
	match t:
		0: return Color(0.8, 0.6, 0.3)
		1: return Color(0.3, 0.5, 1.0)
		2: return Color(0.6, 0.2, 0.8)
		10: return Color(0.7, 0.7, 0.7)
		11: return Color(0.6, 0.3, 0.1)
		12: return Color(0.9, 0.4, 0.1)
		16: return Color(0.9, 0.6, 0.2)    # Cross
		17: return Color(0.2, 0.6, 0.9)    # King Bible
		18: return Color(0.1, 0.5, 0.8)    # Santa Water
		19: return Color(0.8, 0.3, 0.7)    # Runetracer
		20: return Color(0.9, 0.9, 0.2)    # Lightning Ring
		3: return Color(0.2, 0.8, 0.4)
		4: return Color(0.9, 0.3, 0.3)
		5: return Color(0.2, 0.5, 0.8)
		6: return Color(0.9, 0.2, 0.2)
		7: return Color(0.9, 0.7, 0.2)
		8: return Color(0.9, 0.8, 0.0)
		9: return Color(0.2, 0.9, 0.2)
		13: return Color(0.2, 0.7, 0.9)
		14: return Color(0.7, 0.7, 0.8)
		15: return Color(0.1, 0.7, 0.8)
		21: return Color(0.2, 0.9, 0.3)    # Clover
		22: return Color(0.5, 0.3, 0.9)    # Spellbinder
		23: return Color(0.6, 0.6, 0.6)    # Armor
		24: return Color(0.3, 0.9, 0.6)    # Bracer
		25: return Color(0.6, 0.2, 0.2)    # Skull O'Maniac
		26: return Color(0.9, 0.7, 0.9)    # Tiragisú
		27: return Color(0.4, 0.2, 0.6)    # Torrona's Box
		28: return Color(0.6, 0.7, 0.9)    # Silver Ring
		29: return Color(0.9, 0.8, 0.2)    # Gold Ring
		30: return Color(0.5, 0.3, 0.8)    # Metaglio Left
		31: return Color(0.8, 0.3, 0.5)    # Metaglio Right
	return Color.WHITE
