static func fire(w, weapon_manager, player, get_enemies):
	var dir = player.direction if player.direction.length() > 0 else Vector2.DOWN
	var perp = Vector2(-dir.y, dir.x)
	var count = weapon_manager.get_projectile_count(w.type)
	var dmg = weapon_manager._calc_damage(w)
	var spd = w.speed * player.speed_mult

	for i in range(count):
		var angle_offset = (i - (count - 1) / 2.0) * 0.1
		var move_dir = dir.rotated(angle_offset)
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = max(w.area * player.area_mult * 0.6, 6.0)
		s.shape = c
		p.add_child(s)
		var vis = weapon_manager._make_emoji_node("🪩", max(w.area * player.area_mult, 14.0))
		p.add_child(vis)
		p.global_position = player.global_position + move_dir * 20
		player.get_parent().add_child(p)

		var mover = Node2D.new()
		mover.set_script(weapon_manager._proj_mover_script)
		mover.set_movement(move_dir * spd, 400.0 / max(spd, 1.0))
		var _em = weapon_manager.get_enemy_manager()
		var move_dmg_mult = 1.0 + (i * 0.5)
		mover.set_hit_config(_em, 0.0, 10.0, 0, func(eid, _p, _d):
			var ed = dmg * move_dmg_mult
			if _em.is_frozen(eid):
				ed *= 2.0
			_em.damage(eid, ed, Vector2.ZERO)
			return true
		)
		p.add_child(mover)
