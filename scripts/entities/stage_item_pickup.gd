extends Area2D
# Stage item pickup — pre-placed weapon/passive on the map.
# Walk near it to auto-collect (adds weapon or passive to player inventory).

const CollisionLayers = preload("res://scripts/data/collision_layers.gd")
const ItemDefs = preload("res://scripts/data/item_defs.gd")

var item_type: int = -1
var is_weapon: bool = true
var player: Node2D
var collected: bool = false

var _icon_gen = preload("res://scripts/ui/icon_generator.gd")
var _name_label: Label


func _ready():
	collision_layer = 0
	collision_mask = CollisionLayers.MASK_PLAYER
	area_entered.connect(_on_area_entered)
	add_to_group("stage_items")

	var timer = Timer.new()
	timer.wait_time = 300.0
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

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

	if is_instance_valid(player) and player.has_method("apply_upgrade"):
		player.apply_upgrade(item_type)
	else:
		push_warning("StageItemPickup: player missing apply_upgrade method — item not collected")

	AudioManager.play_sfx("pickup_chicken")

	# Pooled floating text
	if is_inside_tree() and ObjectPoolManager:
		ObjectPoolManager.spawn_ft(get_parent(), global_position, _name_label.text if _name_label else "?", Color(0.9, 0.8, 0.2), 14)

	queue_free()


func _process(_delta):
	if _name_label:
		# Float up/down — only redraw every 4 frames
		if Engine.get_frames_drawn() % 4 == 0:
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
	
	# Emoji overlay
	var emoji_str = _icon_gen.get_emoji(item_type)
	if emoji_str:
		var emoji_font = SystemFont.new()
		emoji_font.font_names = [
			"Noto Color Emoji",
			"Segoe UI Emoji",
			"Apple Color Emoji",
			"Twitter Color Emoji",
		]
		draw_string(emoji_font, Vector2(-6, 5), emoji_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
