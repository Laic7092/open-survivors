extends Area2D
# Stage item pickup — pre-placed weapon/passive on the map.
# Walk near it to auto-collect (adds weapon or passive to player inventory).

var item_type: int = -1       # UpgradeType from player.gd
var is_weapon: bool = true
var player: Node2D
var collected: bool = false
var _hover: bool = false

# Icon generator for drawing
var _icon_gen = preload("res://scripts/ui/icon_generator.gd")

# Label for floating name above the item (created after add_child)
var _name_label: Label


func _ready():
	collision_layer = 0
	collision_mask = 2  # player layer
	area_entered.connect(_on_area_entered)
	add_to_group("stage_items")

	# Auto-despawn after 5 minutes (shouldn't be needed but safety)
	var timer = Timer.new()
	timer.wait_time = 300.0
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()
	
	# Create floating name label (added as child, renders on top)
	_name_label = Label.new()
	_name_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_name_label.add_theme_constant_override("shadow_offset_y", 1)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.size = Vector2(80, 16)
	_name_label.position = Vector2(-40, -24)
	add_child(_name_label)


func setup(wpn_type: int, wpn_is_weapon: bool, name_text: String):
	item_type = wpn_type
	is_weapon = wpn_is_weapon
	if _name_label:
		_name_label.text = name_text


func _on_area_entered(area: Area2D):
	if collected:
		return
	var body = area.get_parent()
	if body == player:
		_collect()


func _collect():
	if collected:
		return
	collected = true
	
	if is_weapon:
		if player.has_method("add_weapon"):
			player.add_weapon(item_type)
	else:
		if player.has_method("add_passive"):
			player.add_passive(item_type)
	
	# Show floating text
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("pickup_chicken")
	
	var ft_scene = preload("res://scenes/floating_text.tscn")
	var ft = ft_scene.instantiate()
	ft.display_text = _name_label.text if _name_label else "?"
	ft.text_color = Color(0.9, 0.8, 0.2)
	ft.font_size = 14
	ft.global_position = global_position
	if is_inside_tree():
		get_parent().add_child(ft)
	
	queue_free()


func _process(_delta):
	if _name_label:
		# Float up/down
		var off = sin(Time.get_ticks_msec() * 0.003) * 3
		_name_label.position = Vector2(-40, -24 + off)
	queue_redraw()


func _draw():
	var color = Color(0.8, 0.7, 0.3) if is_weapon else Color(0.3, 0.8, 0.5)
	# Glow circle
	draw_circle(Vector2.ZERO, 14, Color(color.r, color.g, color.b, 0.2))
	draw_circle(Vector2.ZERO, 12, color * 0.6)
	draw_circle(Vector2.ZERO, 12, Color.WHITE * 0.3, false, 1.5)
	# Icon
	if _icon_gen:
		var tex = _icon_gen.generate(item_type, 16)
		if tex:
			draw_texture(tex, Vector2(-8, -8))
