static func fire(w, weapon_manager, player, get_enemies):
	AudioManager.play_sfx("wpn_bible")
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var count = 1 + (w.level - 1) / 2
	if w.evolved:
		count += 2
	for i in range(count):
		var angle = randf() * TAU
		var dist = 30.0 + randf() * 40.0
		var cat = Area2D.new()
		cat.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = max(area * 0.4, 6.0)
		s.shape = c
		cat.add_child(s)
		var vis = weapon_manager._make_emoji_node("🐱", max(area * 0.8, 10.0))
		cat.add_child(vis)
		cat.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * dist
		player.get_parent().add_child(cat)
		var target = _pick_random_enemy(player, get_enemies)
		if target:
			var tw = player.create_tween()
			var time = cat.global_position.distance_to(target.global_position) / 200.0
			tw.tween_property(cat, "global_position", target.global_position, time)
			tw.finished.connect(_cat_bite.bind(cat, target, dmg))
		player.get_tree().create_timer(2.0).timeout.connect(_cleanup.bind(cat))

static func _pick_random_enemy(player, get_enemies):
	var enemies = get_enemies.call()
	if enemies.is_empty():
		return null
	var in_range = []
	for e in enemies:
		if is_instance_valid(e) and player.global_position.distance_squared_to(e.global_position) < 40000:
			in_range.append(e)
	if in_range.is_empty():
		return null
	return in_range[randi() % in_range.size()]

static func _cat_bite(cat, target, dmg):
	if not is_instance_valid(cat) or not is_instance_valid(target):
		return
	if target.has_method("take_damage"):
		target.take_damage(dmg, Vector2.ZERO)

static func _cleanup(cat):
	if is_instance_valid(cat):
		cat.queue_free()
