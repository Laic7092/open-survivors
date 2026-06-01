static func fire(w, weapon_manager, player, get_enemies):
	var enemies = get_enemies.call()
	if enemies.is_empty():
		return
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var count = weapon_manager.get_projectile_count(w.type)
	var max_range_sq = (300.0 + w.area * player.area_mult * 3.0) * (300.0 + w.area * player.area_mult * 3.0)
	var ppos = player.global_position
	var in_range = []
	for e in enemies:
		if is_instance_valid(e) and ppos.distance_squared_to(e.global_position) <= max_range_sq:
			in_range.append(e)
	if in_range.is_empty():
		return
	for i in range(min(count, in_range.size())):
		var target = in_range[randi() % in_range.size()]
		if not is_instance_valid(target):
			continue
		var dir = (target.global_position - ppos).normalized()
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = area
		s.shape = c
		p.add_child(s)
		var vis = weapon_manager._make_emoji_node("📿", max(area * 1.2, 10.0))
		p.add_child(vis)
		p.global_position = ppos
		player.get_parent().add_child(p)
		p.body_entered.connect(weapon_manager._on_proj_hit_and_free.bind(p, dmg))
		var mover = Node2D.new()
		mover.set_script(weapon_manager._proj_mover_script)
		var spd = w.speed * player.speed_mult
		mover.set_movement(dir * spd, 500.0 / max(spd, 1.0))
		mover.set_hit_config(weapon_manager.get_enemy_manager(), dmg, 6.0, 0)
		p.add_child(mover)
