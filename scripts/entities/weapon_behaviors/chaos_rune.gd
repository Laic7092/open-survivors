static func fire(w, weapon_manager, player, get_enemies):
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var speed_factor = player.speed_mult
	var duration_factor = player.duration_mult
	var hit_count = 1 + int(speed_factor * 3) + int(duration_factor * 2)
	var base_dir = player.direction if player.direction.length() > 0 else Vector2.DOWN
	for i in range(hit_count):
		var angle = (TAU / hit_count) * i
		var dir = base_dir.rotated(angle)
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = max(area * 0.4, 4.0)
		s.shape = c
		p.add_child(s)
		var vis = ColorRect.new()
		vis.color = Color(0.7, 0.1, 0.7, 0.5)
		var sz = max(area * 0.6, 8.0)
		vis.size = Vector2(sz, sz)
		vis.position = Vector2(-sz / 2, -sz / 2)
		p.add_child(vis)
		var dist = 20.0 + i * 15.0
		p.global_position = player.global_position + dir * dist
		player.get_parent().add_child(p)
		var _hit = Node2D.new()
		_hit.set_script(weapon_manager._proj_mover_script)
		_hit.set_movement(Vector2.ZERO, 0.5 * duration_factor + 0.5)
		_hit.set_hit_config(weapon_manager.get_enemy_manager(), dmg, 20.0, 0)
		p.add_child(_hit)
		var tw = player.create_tween()
		tw.tween_property(p, "modulate:a", 0.0, 0.5 * duration_factor)
		tw.finished.connect(weapon_manager._on_tween_done.bind(p))
