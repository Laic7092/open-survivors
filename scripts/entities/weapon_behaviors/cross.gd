static func fire(w, weapon_manager, player, get_enemies):
	var enemies = get_enemies.call()
	if enemies.is_empty():
		return
	var dmg = weapon_manager._calc_damage(w)

	if w.evolved:
		var count = 2 + weapon_manager.get_projectile_count(w.type)
		var max_range_hsq: float = (500.0 + w.area * player.area_mult * 5.0) * (500.0 + w.area * player.area_mult * 5.0)
		var ppos = player.global_position
		var in_range: Array = []
		for e in enemies:
			if is_instance_valid(e) and ppos.distance_squared_to(e.global_position) <= max_range_hsq:
				in_range.append(e)
		if in_range.is_empty():
			return
		AudioManager.play_sfx("wpn_heaven")
		for i in range(min(count, in_range.size())):
			var e = in_range[randi() % in_range.size()]
			if not is_instance_valid(e):
				continue
			var sword = Area2D.new()
			sword.collision_mask = 4
			var ss = CollisionShape2D.new()
			var sc = CircleShape2D.new()
			sc.radius = max(w.area * player.area_mult * 0.5, 5.0)
			ss.shape = sc
			sword.add_child(ss)
			var sz = max(w.area * player.area_mult * 0.7, 8.0)
			var blade = ColorRect.new()
			blade.color = Color(0.9, 0.8, 0.4, 0.9)
			blade.size = Vector2(sz * 0.4, sz * 2.0)
			blade.position = Vector2(-sz * 0.2, -sz * 1.0)
			sword.add_child(blade)
			var tip = ColorRect.new()
			tip.color = Color(1.0, 0.9, 0.5)
			tip.size = Vector2(sz * 0.6, sz * 0.3)
			tip.position = Vector2(-sz * 0.3, -sz * 1.0)
			sword.add_child(tip)
			sword.global_position = e.global_position + Vector2(randf_range(-30, 30), -200)
			player.get_parent().add_child(sword)
			var _hit = Node2D.new()
			_hit.set_script(weapon_manager._proj_mover_script)
			_hit.set_movement(Vector2.ZERO, 2.0)
			_hit.set_hit_config(weapon_manager.get_enemy_manager(), dmg, 10.0, -1)
			sword.add_child(_hit)
			var tw = player.create_tween()
			tw.tween_property(sword, "global_position", e.global_position, 0.25)
			tw.parallel().tween_property(sword, "rotation", deg_to_rad(360), 0.25).as_relative()
			tw.finished.connect(weapon_manager._on_tween_done.bind(sword))
		return

	var max_range_csq: float = (450.0 + w.area * player.area_mult * 5.0) * (450.0 + w.area * player.area_mult * 5.0)
	var nearest = null
	var min_dist = max_range_csq
	var ppos = player.global_position
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var d = ppos.distance_squared_to(e.global_position)
		if d < min_dist:
			min_dist = d
			nearest = e
	if not nearest:
		return
	AudioManager.play_sfx("wpn_cross")
	var count = weapon_manager.get_projectile_count(w.type)
	# 非进化形态：飞向最近敌人方向，穿透所有敌人，不弹回
	var fire_dir = (nearest.global_position - player.global_position).normalized()
	var travel_range = 450.0 + w.area * player.area_mult * 5.0
	var travel_speed = max(w.speed * 1.5, 100.0)
	var travel_time = travel_range / travel_speed

	for i in range(count):
		var angle_off = (i - (count - 1) * 0.5) * 0.15
		var dir = fire_dir.rotated(angle_off)

		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = max(w.area * player.area_mult * 0.5, 5.0)
		s.shape = c
		p.add_child(s)
		var sz = max(w.area * player.area_mult * 0.7, 8.0)
		var bar_h = ColorRect.new()
		bar_h.color = Color(0.9, 0.6, 0.2)
		bar_h.size = Vector2(sz * 1.6, sz * 0.3)
		bar_h.position = Vector2(-sz * 0.8, -sz * 0.15)
		p.add_child(bar_h)
		var bar_v = ColorRect.new()
		bar_v.color = Color(0.9, 0.6, 0.2)
		bar_v.size = Vector2(sz * 0.3, sz * 1.6)
		bar_v.position = Vector2(-sz * 0.15, -sz * 0.8)
		p.add_child(bar_v)
		p.global_position = player.global_position
		player.get_parent().add_child(p)
		var _hit2 = Node2D.new()
		_hit2.set_script(weapon_manager._proj_mover_script)
		_hit2.set_movement(Vector2.ZERO, travel_time + 1.5)
		_hit2.set_hit_config(weapon_manager.get_enemy_manager(), dmg, 10.0, -1)
		p.add_child(_hit2)

		var end_pos = p.global_position + dir * travel_range
		var tw = player.create_tween()
		tw.tween_property(p, "global_position", end_pos, travel_time)
		tw.parallel().tween_property(p, "rotation", deg_to_rad(720), travel_time).as_relative()
		var p_id = p.get_instance_id()
		tw.finished.connect(func():
			var _x = instance_from_id(p_id)
			if not _x:
				return
			var p_node = _x as Node2D
			var ret_tw = player.create_tween()
			ret_tw.tween_property(p_node, "global_position", player.global_position, 0.4)
			ret_tw.parallel().tween_property(p_node, "rotation", deg_to_rad(360), 0.4).as_relative()
			ret_tw.finished.connect(func():
				if is_instance_valid(p_node):
					p_node.queue_free()
			)
		)
