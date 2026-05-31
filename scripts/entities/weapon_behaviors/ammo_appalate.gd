static func fire(w, weapon_manager, player, get_enemies):
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var count = weapon_manager.get_projectile_count(w.type)
	var base_dir = player.direction if player.direction.length() > 0 else Vector2.DOWN
	var dir = base_dir
	var ppos = player.global_position
	var nearest = _find_enemy_in_dir(player, dir, get_enemies)
	if nearest:
		dir = (nearest.global_position - ppos).normalized()
	for i in range(count):
		var offset_angle = (i - (count - 1) / 2.0) * 0.1
		var shot_dir = dir.rotated(offset_angle)
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = area
		s.shape = c
		p.add_child(s)
		var vis = weapon_manager._make_emoji_node("🎯", max(area * 1.2, 10.0))
		p.add_child(vis)
		p.global_position = ppos + shot_dir * 15
		player.get_parent().add_child(p)
		p.body_entered.connect(weapon_manager._on_proj_hit_and_free.bind(p, dmg))
		var mover = Node2D.new()
		mover.set_script(weapon_manager._proj_mover_script)
		var spd = w.speed * player.speed_mult
		mover.set_movement(shot_dir * spd, 500.0 / max(spd, 1.0))
		p.add_child(mover)

static func _find_enemy_in_dir(player, dir, get_enemies):
	var enemies = get_enemies.call()
	var best: Node2D = null
	var best_dot = -1.0
	var ppos = player.global_position
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var to_enemy = (e.global_position - ppos).normalized()
		var dot = dir.dot(to_enemy)
		if dot > 0.5 and dot > best_dot:
			best_dot = dot
			best = e
	return best
