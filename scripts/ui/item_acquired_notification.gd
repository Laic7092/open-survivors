extends Control
# Item acquired notification — brief popup when picking up a stage item.
# Uses .tscn scene for layout; script handles data + animation.

const IconGenerator = preload("res://scripts/ui/icon_generator.gd")

@onready var _panel: Panel = $Panel
@onready var _icon_container: Control = $HBox/Icon
@onready var _name_label: Label = $HBox/VBox/ItemName
@onready var _status_label: Label = $HBox/VBox/StatusLabel

var _item_type: int = -1
var _is_new: bool = false
var _timer: float = 0.0

@export var visible_duration: float = 2.5
@export var fade_duration: float = 0.5


func setup(item_type: int, is_new: bool):
	_item_type = item_type
	_is_new = is_new


func _ready():
	mouse_filter = MOUSE_FILTER_IGNORE
	
	if _item_type < 0:
		queue_free()
		return
	
	var col = DataRegistry.items().item_color(_item_type)
	var item_name = I18N.t(DataRegistry.items().item_name_key(_item_type), DataRegistry.items().item_name(_item_type))
	
	# ── Icon ──
	var icon = IconGenerator.make_icon_node(_item_type, 36)
	icon.custom_minimum_size = Vector2(36, 36)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_icon_container.add_child(icon)
	
	# ── Panel style ──
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.05, 0.12, 0.92)
	sb.set_border_width_all(2)
	sb.border_color = col * 0.7
	sb.border_blend = true
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	_panel.add_theme_stylebox_override("panel", sb)
	
	# ── Name label ──
	_name_label.text = item_name
	_name_label.add_theme_color_override("font_color", col)
	
	# ── Status label ──
	if _is_new:
		_status_label.text = I18N.t("stage_item.new", "NEW!")
		_status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	else:
		_status_label.text = I18N.t("stage_item.upgraded", "Upgraded!")
		_status_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	
	# ── Responsive width: auto-fit to text ──
	_auto_fit_width()


func _auto_fit_width():
	# Make the panel wide enough to fit the text comfortably
	var text_width = max(_name_label.get_combined_minimum_size().x, _status_label.get_combined_minimum_size().x)
	var total_w = text_width + 36 + 28  # icon + margins + icon_container
	var half_w = total_w / 2.0
	# Clamp so it doesn't exceed viewport
	var vp = get_viewport().get_visible_rect().size
	half_w = min(half_w, vp.x * 0.45)
	half_w = max(half_w, 100.0)
	
	offset_left = -half_w
	offset_right = half_w


func _process(delta):
	_timer += delta
	if _timer >= visible_duration + fade_duration:
		queue_free()
		return
	
	if _timer >= visible_duration:
		var alpha = 1.0 - ((_timer - visible_duration) / fade_duration)
		modulate = Color(1, 1, 1, clamp(alpha, 0.0, 1.0))
