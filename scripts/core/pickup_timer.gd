extends Node
# PickupTimer — 拾取计时器管理
# 从 main.gd 拆分：Gold Finger / Nduja Fritta / Gold Fever 计时逻辑

signal gold_finger_ended(kills: int)
signal spawned_pickup(pos: Vector2, pickup_type: int)

var player: Node2D
var main_node: Node2D


func setup(p: Node2D, parent: Node2D):
	player = p
	main_node = parent


func process(delta: float):
	_process_gold_finger(delta)
	_process_nduja(delta)
	_process_gold_fever(delta)


func _process_gold_finger(delta: float):
	var gf = EventBus.get_config("gold_finger_timer", 0.0)
	if gf > 0.0:
		gf -= delta
		if gf <= 0.0:
			EventBus.set_config("gold_finger_timer", 0.0)
			_on_gold_finger_end()
		else:
			EventBus.set_config("gold_finger_timer", gf)
			if is_instance_valid(player):
				player.invincible = max(player.invincible, 0.1)


func _process_nduja(delta: float):
	var nd = EventBus.get_config("nduja_timer", 0.0)
	if nd > 0.0:
		nd -= delta
		if nd <= 0.0:
			EventBus.set_config("nduja_timer", 0.0)
		else:
			EventBus.set_config("nduja_timer", nd)
			_emit_nduja_fire()


func _process_gold_fever(delta: float):
	var gft = EventBus.get_config("gold_fever_timer", 0.0)
	if gft > 0.0:
		gft -= delta
		if gft <= 0.0:
			EventBus.set_config("gold_fever_timer", 0.0)
		else:
			EventBus.set_config("gold_fever_timer", gft)


func _on_gold_finger_end():
	var kills = EventBus.get_config("gold_finger_kills", 0)
	var tier = "bronze"
	if kills >= 10: tier = "silver"
	if kills >= 30: tier = "gold"
	if kills >= 60: tier = "demon"
	if kills >= 100: tier = "cosmic"

	match tier:
		"bronze":
			spawned_pickup.emit(player.global_position, 2)
		"silver":
			spawned_pickup.emit(player.global_position, 3)
			spawned_pickup.emit(player.global_position, 7)
		"gold":
			spawned_pickup.emit(player.global_position, 3)
			spawned_pickup.emit(player.global_position, 8)
		"demon":
			for i in range(3):
				spawned_pickup.emit(player.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20)), 3)
			spawned_pickup.emit(player.global_position, 4)
		"cosmic":
			for i in range(5):
				spawned_pickup.emit(player.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20)), 3)
			spawned_pickup.emit(player.global_position, 8)
			spawned_pickup.emit(player.global_position, 4)

	var txt = "Gold Finger: " + str(kills) + " kills - " + tier.capitalize() + " prize!"
	if is_instance_valid(player) and player.has_method("show_floating_text"):
		player.show_floating_text(txt, Color(0.9, 0.7, 0.0), 22)


func _emit_nduja_fire():
	if not is_instance_valid(player) or not is_inside_tree():
		return
	if Engine.get_frames_drawn() % 5 != 0:
		return
	var dir = player.direction if player.direction.length() > 0 else Vector2.DOWN
	var offset = dir * 24.0
	var area = Area2D.new()
	area.global_position = player.global_position + offset
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 20.0
	shape.shape = circle
	area.add_child(shape)
	add_child(area)
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and area.global_position.distance_to(e.global_position) < 24.0:
			if e.has_method("take_damage"):
				var dmg = 10.0 * (player.might if player.has_method("get_curse") else 1.0)
				e.take_damage(dmg, player.global_position)
	var fb = preload("res://scripts/entities/fireball_node.gd").new()
	fb.fb_size = 8.0
	fb.seed_offset = randi()
	fb.global_position = area.global_position
	add_child(fb)
	var tw = create_tween()
	tw.tween_interval(0.3)
	var area_id = area.get_instance_id()
	tw.finished.connect(func():
		var _x = instance_from_id(area_id)
		if _x:
			_x.queue_free()
	)
	var fb_id = fb.get_instance_id()
	tw.finished.connect(func():
		var _x = instance_from_id(fb_id)
		if _x:
			_x.queue_free()
	)
