extends Area2D
# Stage item pickup — pre-placed weapon/passive on the map.
# Walk near it to auto-collect (adds weapon or passive to player inventory).

const CollisionLayers = preload("res://scripts/data/collision_layers.gd")
# Item data loaded lazily via DataRegistry (autoload)
const _ICON_GEN = preload("res://scripts/ui/icon_generator.gd")

var item_type: int = -1
var is_weapon: bool = true
var player: Node2D
var collected: bool = false

var _name_label: Label
var _cached_icon_tex: ImageTexture

# Cached emoji font — created once, shared across all pickup instances.
static var _emoji_font: SystemFont


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
	
	# Label float animation via Tween — no per-frame _process needed
	var tw = create_tween().set_loops()
	tw.tween_property(_name_label, "position:y", -27.0, 1.0)
	tw.tween_property(_name_label, "position:y", -21.0, 1.0)

	# Initialize static emoji font once
	if _emoji_font == null:
		_emoji_font = SystemFont.new()
		_emoji_font.font_names = [
			"Noto Color Emoji",
			"Segoe UI Emoji",
			"Apple Color Emoji",
			"Twitter Color Emoji",
		]


func setup(wpn_type: int, wpn_is_weapon: bool, name_text: String):
	item_type = wpn_type
	is_weapon = wpn_is_weapon
	if _name_label:
		_name_label.text = name_text
	# Cache icon texture once (IconGenerator.generate has a static cache,
	# but caching the reference here avoids even the method-call overhead).
	_cached_icon_tex = _ICON_GEN.generate(item_type, 16)


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





func _draw():
	var color = Color(0.8, 0.7, 0.3) if is_weapon else Color(0.3, 0.8, 0.5)
	# Glow circle
	draw_circle(Vector2.ZERO, 14, Color(color.r, color.g, color.b, 0.2))
	draw_circle(Vector2.ZERO, 12, color * 0.6)
	draw_circle(Vector2.ZERO, 12, Color.WHITE * 0.3, false, 1.5)
	# Icon (cached in setup)
	if _cached_icon_tex:
		draw_texture(_cached_icon_tex, Vector2(-8, -8))
	
	# Emoji overlay (cached font, no per-frame allocation)
	var emoji_str = _ICON_GEN.get_emoji(item_type)
	if emoji_str and _emoji_font:
		draw_string(_emoji_font, Vector2(-6, 5), emoji_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
