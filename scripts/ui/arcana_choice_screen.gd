extends Control
# Arcana choice screen — shown at run start and when Arcana chests are collected.
# Displays 4 random uncollected Arcanas (or all unlocked if first pick).

const ArcanaDefs = preload("res://scripts/data/arcana_defs.gd")
const UiUtils = preload("res://scripts/ui/ui_utils.gd")

signal arcana_selected(arcana_id: int)

var _available_pool: Array = []  # arcana_ids available for this pick
var _is_first_pick: bool = false
var _caller_ref = null
var _scene_tree: SceneTree


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	mouse_filter = MOUSE_FILTER_STOP
	anchor_right = 1.0
	anchor_bottom = 1.0
	visible = false


# Show the choice screen. first_pick=true => first Arcana of the run (show ALL unlocked)
# first_pick=false => Arcana chest (show 4 random from uncollected/available)
func show_choices(first_pick: bool = false, available_pool: Array = []):
	_is_first_pick = first_pick
	visible = true
	_clear()
	
	if first_pick:
		# Show ALL unlocked Arcanas for the first pick
		_available_pool = ArcanaManager.get_unlocked()
	else:
		# Filter out already active Arcanas from the pool
		var active = ArcanaManager.get_active()
		_available_pool = []
		for id in available_pool:
			if not active.has(id):
				_available_pool.append(id)
	
	if _available_pool.is_empty():
		# Fallback: shouldn't happen, but just hide
		visible = false
		return
	
	# Pick up to 4 random choices
	var choices = _available_pool.duplicate()
	choices.shuffle()
	var display_count = min(choices.size(), 4)
	if display_count <= 0:
		visible = false
		return
	choices = choices.slice(0, display_count)
	
	# If only 1 choice, show it directly
	if display_count == 1:
		_emit_choice(choices[0])
		return
	
	_create_ui(choices)


func _create_ui(choices: Array):
	var vp = get_viewport().get_visible_rect().size
	
	# Dark backdrop
	var panel = Panel.new()
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	add_child(panel)
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.88)
	panel.add_theme_stylebox_override("panel", bg)
	
	# Title
	var title = Label.new()
	title.text = I18N.t("arcana.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	title.position = Vector2(vp.x / 2 - 160, 30)
	title.size = Vector2(320, 50)
	panel.add_child(title)
	
	# Subtitle (first pick vs. chest pick)
	var subtitle = Label.new()
	subtitle.text = I18N.t("arcana.first_pick" if _is_first_pick else "arcana.chest_pick")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	subtitle.position = Vector2(vp.x / 2 - 180, 70)
	subtitle.size = Vector2(360, 30)
	panel.add_child(subtitle)
	
	# Card container — 自适应
	var cols = choices.size()
	var card_w = mini(260, max(160, int((vp.x - 80) / cols - 16)))
	var card_h = mini(340, max(280, vp.y - 160))
	var gap = 16
	var total_w = cols * card_w + (cols - 1) * gap
	var start_x = max(10, (vp.x - total_w) / 2)
	var start_y = max(10, vp.y / 2 - card_h / 2 + 10)
	
	for i in range(choices.size()):
		var arc_id = choices[i]
		var a = ArcanaDefs.get_arcana(arc_id)
		_add_card(panel, a, Vector2(start_x + i * (card_w + gap), start_y), card_w, card_h)
	
	# Random button (bottom center)
	var random_btn = Button.new()
	random_btn.text = I18N.t("arcana.random")
	random_btn.custom_minimum_size = Vector2(200, 44)
	random_btn.position = Vector2(vp.x / 2 - 100, start_y + card_h + 20)
	UiUtils.style_button(random_btn, Color(0.2, 0.2, 0.3), Color(0.5, 0.5, 0.7))
	random_btn.pressed.connect(_on_random.bind(choices))
	panel.add_child(random_btn)


func _add_card(parent: Control, arcana_data: Dictionary, pos: Vector2, w: int, h: int):
	var card = Panel.new()
	card.position = pos
	card.size = Vector2(w, h)
	
	var s = StyleBoxFlat.new()
	s.bg_color = arcana_data["color"] * 0.12
	s.border_width_left = 3; s.border_width_right = 3
	s.border_width_top = 3; s.border_width_bottom = 3
	s.border_color = arcana_data["color"]
	s.corner_radius_top_left = 12
	s.corner_radius_top_right = 12
	s.corner_radius_bottom_left = 12
	s.corner_radius_bottom_right = 12
	card.add_theme_stylebox_override("panel", s)
	parent.add_child(card)
	
	# Roman numeral at top
	var roman_label = Label.new()
	roman_label.text = arcana_data["roman"]
	roman_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	roman_label.add_theme_font_size_override("font_size", 42)
	roman_label.add_theme_color_override("font_color", arcana_data["color"])
	roman_label.position = Vector2(0, 10)
	roman_label.size = Vector2(w, 50)
	card.add_child(roman_label)
	
	# Name
	var name_label = Label.new()
	name_label.text = I18N.t("arcana." + str(arcana_data["id"]) + "_name", arcana_data["name"])
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.position = Vector2(8, 60)
	name_label.size = Vector2(w - 16, 50)
	card.add_child(name_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = I18N.t("arcana." + str(arcana_data["id"]) + "_desc", arcana_data["desc"])
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_label.position = Vector2(8, 115)
	desc_label.size = Vector2(w - 16, 140)
	card.add_child(desc_label)
	
	# Unlock info (small at bottom)
	var unlock_label = Label.new()
	unlock_label.text = I18N.t("arcana." + str(arcana_data["id"]) + "_unlock", arcana_data["unlock"])
	unlock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unlock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	unlock_label.add_theme_font_size_override("font_size", 9)
	unlock_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	unlock_label.position = Vector2(4, 260)
	unlock_label.size = Vector2(w - 8, 50)
	card.add_child(unlock_label)
	
	# Select button
	var select_btn = Button.new()
	select_btn.text = I18N.t("arcana.select")
	select_btn.custom_minimum_size = Vector2(w - 20, 32)
	select_btn.position = Vector2(10, h - 42)
	UiUtils.style_button(select_btn, arcana_data["color"] * 0.3, arcana_data["color"])
	select_btn.add_theme_font_size_override("font_size", 14)
	select_btn.pressed.connect(_emit_choice.bind(arcana_data["id"]))
	card.add_child(select_btn)


func _on_random(choices: Array):
	var picked = choices[randi() % choices.size()]
	_emit_choice(picked)


func _emit_choice(arcana_id: int):
	ArcanaManager.activate(arcana_id)
	arcana_selected.emit(arcana_id)
	visible = false
	_clear()


func hide_screen():
	visible = false
	_clear()


func _clear():
	for c in get_children():
		c.queue_free()
