static func fire(w, weapon_manager, player, get_enemies):
	var enemies = get_enemies.call()
	if enemies.is_empty():
		return
	var dir = player.direction if player.direction.length() > 0 else Vector2.DOWN
	var p = Area2D.new()
	p.collision_mask = 4
	var s = CollisionShape2D.new()
	var c = CircleShape2D.new()
	c.radius = max(w.area * player.area_mult * 0.6, 6.0)
	s.shape = c
	p.add_child(s)
	var vis = weapon_manager._make_emoji_node("⏰", max(w.area * player.area_mult, 12.0))
	p.add_child(vis)
	p.global_position = player.global_position + dir * 20
	player.get_parent().add_child(p)
	var mover = Node2D.new()
	mover.set_script(weapon_manager._proj_mover_script)
	var spd = w.speed * player.speed_mult
	mover.set_movement(dir * spd, 300.0 / max(spd, 1.0))
	var _em = weapon_manager.get_enemy_manager()
	mover.set_hit_config(_em, 0.0, 10.0, 0, func(eid, _p, _d):
		_em.freeze(eid, 2.0)
		return true
	)
	p.add_child(mover)
