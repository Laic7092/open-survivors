static func fire(w, weapon_manager, player, get_enemies):
	var in_range = get_enemies.call()
	if in_range.is_empty():
		return
	var ppos = player.global_position
	var target = in_range[randi() % in_range.size()]
	if not is_instance_valid(target):
		return
	var base_dir = (target.global_position - ppos).normalized()
	var perp = Vector2(-base_dir.y, base_dir.x)
	var count = weapon_manager.get_projectile_count(w.type)
	var explosion_radius = w.area * player.area_mult * 1.5
	var dmg = weapon_manager._calc_damage(w)

	for i in range(count):
		var angle_offset = (i - (count - 1) / 2.0) * 0.15
		var dir = base_dir.rotated(angle_offset)
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = max(w.area * player.area_mult * 0.5, 4.0)
		s.shape = c
		p.add_child(s)
		var vis = weapon_manager._make_emoji_node("🔥", max(w.area * player.area_mult, 12.0))
		p.add_child(vis)
		p.global_position = ppos + dir * 25
		player.get_parent().add_child(p)

		var mover = weapon_manager._proj_mover_script.new()
		var travel_time = ppos.distance_to(target.global_position) / max(w.speed, 1.0)
		mover.set_movement(dir * w.speed, travel_time)
		var _em = weapon_manager.get_enemy_manager()
		# 命中时触发爆炸；使用较大搜索半径避免穿透
		mover.set_hit_config(_em, dmg, explosion_radius * 0.8, 0, func(eid, proj, dmg_val):
			weapon_manager._explode_at(proj.global_position, explosion_radius, dmg_val, w)
			return true
		)
		p.add_child(mover)

		# Explode on timeout (misses target)
		var tw = player.create_tween()
		tw.tween_interval(travel_time)
		tw.finished.connect(_on_firewand_explode.bind(p, explosion_radius, dmg, w, weapon_manager))


static func _on_firewand_explode(proj, explosion_radius: float, dmg: float, w, weapon_manager):
	if not is_instance_valid(proj):
		return
	weapon_manager._explode_at(proj.global_position, explosion_radius, dmg, w)
