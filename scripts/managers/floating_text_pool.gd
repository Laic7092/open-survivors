extends Node
# FloatingTextPool — autoload singleton
# Object pool for floating text nodes to avoid allocation churn.

const POOL_SIZE: int = 32
const FT_SCENE = preload("res://scenes/floating_text.tscn")

var _available: Array = []


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	_prefill_pool()


func _prefill_pool():
	for i in range(POOL_SIZE):
		var ft = FT_SCENE.instantiate()
		ft.visible = false
		ft.set_process(false)
		ft.set_physics_process(false)
		_available.append(ft)
		add_child(ft)


func spawn(parent: Node, world_pos: Vector2, text: String, color: Color = Color.WHITE, size: int = 18) -> Node2D:
	var ft: Node2D = _borrow()
	ft.display_text = text
	ft.text_color = color
	ft.font_size = size
	ft.global_position = world_pos
	ft.velocity = Vector2(randf_range(-15, 15), -50)
	ft.lifetime = 0.9
	ft.age = 0.0
	ft.visible = true
	ft.set_process(true)
	ft.modulate = Color(1, 1, 1, 1)
	
	# Remove from pool container (if it's our child) and add to target parent
	if ft.get_parent() == self:
		remove_child(ft)
	parent.add_child(ft)
	return ft


func _borrow() -> Node2D:
	while _available.size() > 0:
		var ft = _available.pop_back()
		if is_instance_valid(ft):
			return ft
	# Fallback: create new one
	var new_ft = FT_SCENE.instantiate()
	new_ft.visible = false
	new_ft.set_process(false)
	return new_ft


func return_ft(ft: Node2D):
	if not is_instance_valid(ft):
		return
	if ft.get_parent():
		ft.get_parent().remove_child(ft)
	ft.visible = false
	ft.set_process(false)
	ft.set_physics_process(false)
	if _available.size() < POOL_SIZE:
		_available.append(ft)
		add_child(ft)
	else:
		ft.queue_free()
