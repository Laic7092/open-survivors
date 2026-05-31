static func fire(w, weapon_manager, player, get_enemies):
	if not weapon_manager.has_meta("ebony_birds"):
		weapon_manager.set_meta("ebony_birds", [])
	var birds: Array = weapon_manager.get_meta("ebony_birds")
	for b in birds:
		if is_instance_valid(b):
			return
	birds.clear()
	var count = 1 + (w.level - 1) / 2
	if w.evolved:
		count += 2
	var dmg = weapon_manager._calc_damage(w)
	var radius = 70.0 + w.area * player.area_mult * 0.4
	for i in range(count):
		var angle = (TAU / count) * i
		var bird = Area2D.new()
		bird.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = max(w.area * player.area_mult * 0.5, 8.0)
		s.shape = c
		bird.add_child(s)
		var vis = weapon_manager._make_emoji_node("🐦‍⬛", max(w.area * player.area_mult, 12.0))
		bird.add_child(vis)
		bird.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * radius
		bird.set_meta("orbit_angle", angle)
		bird.set_meta("orbit_radius", radius)
		bird.set_meta("orbit_speed", 2.0)
		bird.set_meta("bird_dmg", dmg)
		bird.set_meta("clockwise", false)
		player.get_parent().add_child(bird)
		bird.body_entered.connect(weapon_manager._on_proj_hit.bind(bird, dmg))
		birds.append(bird)
	var dur = 4.0 * player.duration_mult
	player.get_tree().create_timer(dur).timeout.connect(_cleanup.bind(birds))

static func _cleanup(birds):
	for b in birds:
		if is_instance_valid(b):
			b.queue_free()
