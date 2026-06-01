static func fire(w, weapon_manager, player, get_enemies):
	AudioManager.play_sfx("wpn_firewand")
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var count = weapon_manager.get_projectile_count(w.type)
	var base_dir = player.direction if player.direction.length() > 0 else Vector2.DOWN
	var cone = PI / 4
	for i in range(count):
		var angle = -cone + (cone * 2) * (i / float(max(count - 1, 1)))
		var dir = base_dir.rotated(angle)
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = area * 0.6
		s.shape = c
		p.add_child(s)
		var vis = ColorRect.new()
		vis.color = Color(0.9, 0.3, 0.1, 0.7)
		var sz = area * 0.8
		vis.size = Vector2(sz, sz)
		vis.position = Vector2(-sz / 2, -sz / 2)
		p.add_child(vis)
		p.global_position = player.global_position + dir * 20
		p.rotation = dir.angle()
		player.get_parent().add_child(p)
		p.body_entered.connect(weapon_manager._on_proj_hit_and_free.bind(p, dmg))
		var mover = Node2D.new()
		mover.set_script(weapon_manager._proj_mover_script)
		var spd = w.speed * player.speed_mult
		mover.set_movement(dir * spd, 300.0 / max(spd, 1.0))
		mover.set_hit_config(weapon_manager.get_enemy_manager(), dmg, 6.0, 0)
		p.add_child(mover)
