static func fire(w, weapon_manager, player, get_enemies):
	AudioManager.play_sfx("wpn_bible")
	var count = 2 + (w.level - 1)
	if w.evolved:
		count += 2
	var orbit_radius = 60.0 + w.area * player.area_mult * 0.5
	var dmg = weapon_manager._calc_damage(w)
	var dur = 2.5 * player.duration_mult

	weapon_manager._bible_projectiles = weapon_manager._bible_projectiles.filter(func(x): return is_instance_valid(x))

	for i in range(count):
		var angle = (TAU / count) * i + weapon_manager._bible_angle
		var offset = Vector2(cos(angle), sin(angle)) * orbit_radius
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = max(w.area * player.area_mult * 0.5, 6.0)
		s.shape = c
		p.add_child(s)
		var orb_sz = max(w.area * player.area_mult * 0.8, 10.0)
		var vis = weapon_manager._make_emoji_node("📖", orb_sz)
		p.add_child(vis)
		if w.evolved:
			var glow = ColorRect.new()
			glow.color = Color(0.8, 0.9, 1.0, 0.3)
			glow.size = Vector2(orb_sz * 1.8, orb_sz * 1.8)
			glow.position = Vector2(-orb_sz * 0.9, -orb_sz * 0.9)
			p.add_child(glow)
		p.global_position = player.global_position + offset
		p.set_meta("orbit_angle", angle)
		p.set_meta("orbit_radius", orbit_radius)
		p.set_meta("orbit_dmg", dmg)
		player.get_parent().add_child(p)

		# 轮询检测（敌人是数据驱动，body_entered 不触发）
		var poll = Node2D.new()
		poll.set_script(weapon_manager._proj_mover_script)
		poll.set_hit_config(weapon_manager.get_enemy_manager(), dmg, max(w.area * player.area_mult * 0.5, 6.0), 999)
		poll._max_lifetime = dur + 1.0
		p.add_child(poll)

		weapon_manager._bible_projectiles.append(p)
		player.get_tree().create_timer(dur).timeout.connect(weapon_manager._on_bible_expire.bind(p))
