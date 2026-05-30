static func fire(w, weapon_manager, player, get_enemies):
	var enemies = get_enemies.call()
	if enemies.is_empty():
		return
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var count = weapon_manager.get_projectile_count(w.type)

	var max_range_wsq: float = (350.0 + w.area * player.area_mult * 3.0)
	max_range_wsq *= max_range_wsq
	var ppos = player.global_position

	var best: Array = []
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var dsq = ppos.distance_squared_to(e.global_position)
		if dsq > max_range_wsq:
			continue
		var inserted = false
		for i in range(best.size()):
			if dsq < best[i][0]:
				best.insert(i, [dsq, e])
				inserted = true
				break
		if not inserted and best.size() < count:
			best.append([dsq, e])
		if best.size() > count:
			best.pop_back()
	if best.is_empty():
		return

	if weapon_manager._wand_sfx_cooldown <= 0:
		AudioManager.play_sfx("wpn_wand" if not w.evolved else "wpn_evo")
		weapon_manager._wand_sfx_cooldown = 0.3

	for pair in best:
		var target = pair[1]
		if not is_instance_valid(target):
			continue
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = area
		s.shape = c
		p.add_child(s)
		p.global_position = ppos
		var vis = Node2D.new()
		vis.set_script(weapon_manager._proj_vis_script)
		p.add_child(vis)
		player.get_parent().add_child(p)
		p.body_entered.connect(weapon_manager._on_proj_hit.bind(p, dmg))
		var dir = (target.global_position - ppos).normalized()
		var mover = Node2D.new()
		mover.set_script(weapon_manager._proj_mover_script)
		mover.set_movement(dir * w.speed, ppos.distance_to(target.global_position) / max(w.speed, 1.0))
		p.add_child(mover)
