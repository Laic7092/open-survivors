static func fire(w, weapon_manager, player, get_enemies):
	var enemies = get_enemies.call()
	var effective_area = w.area * player.area_mult
	var ppos = player.global_position
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var enemy_r = 14.0
		if is_instance_valid(e.collision_shape) and e.collision_shape.shape is CircleShape2D:
			enemy_r = e.collision_shape.shape.radius * max(e.scale.x, e.scale.y)
		if ppos.distance_to(e.global_position) - enemy_r < effective_area:
			if e.has_method("take_damage"):
				e.take_damage(weapon_manager._calc_damage(w), Vector2.ZERO)
				if w.evolved:
					player.health = min(player.health + 1.0, player.max_health)
