static func fire(w, weapon_manager, player, get_enemies):
	var em = weapon_manager.get_enemy_manager()
	if not em or not em.has_method("query_circle"):
		return
	var effective_area = w.area * player.area_mult
	var ppos = player.global_position
	var dmg = weapon_manager._calc_damage(w)
	# query_circle 直接查询 _pos 数组，返回 entity ID 列表，无需创建代理
	var ids = em.query_circle(ppos, effective_area + 14.0)
	for eid in ids:
		var enemy_r = em.get_radius(eid)
		var thr = effective_area + enemy_r
		if ppos.distance_squared_to(em.get_pos(eid)) <= thr * thr:
			em.damage(eid, dmg, Vector2.ZERO)
			if w.evolved:
				player.health = min(player.health + 1.0, player.max_health)
