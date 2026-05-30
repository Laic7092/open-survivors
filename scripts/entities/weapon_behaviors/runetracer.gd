static func fire(w, weapon_manager, player, get_enemies):
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult

	if w.evolved:
		AudioManager.play_sfx("wpn_nofuture")
		var wall_len = 300.0 + 60.0 * w.level
		var wall_dur = 1.5 + player.duration_bonus
		var dir = player.direction if player.direction.length() > 0 else Vector2.DOWN
		var perp = Vector2(-dir.y, dir.x)
		for side in [-1, 1]:
			var wall = Area2D.new()
			wall.collision_mask = 4
			var ws = CollisionShape2D.new()
			var wc = RectangleShape2D.new()
			wc.size = Vector2(wall_len, 12.0)
			ws.shape = wc
			wall.add_child(ws)
			var beam = ColorRect.new()
			beam.color = Color(0.9, 0.3, 0.8, 0.7)
			beam.size = Vector2(wall_len, 10)
			beam.position = Vector2(-wall_len / 2, -5)
			wall.add_child(beam)
			var glow = ColorRect.new()
			glow.color = Color(1.0, 0.6, 0.9, 0.3)
			glow.size = Vector2(wall_len + 20, 16)
			glow.position = Vector2(-wall_len / 2 - 10, -8)
			wall.add_child(glow)
			wall.global_position = player.global_position + perp * side * 30
			player.get_parent().add_child(wall)
			wall.body_entered.connect(weapon_manager._on_proj_hit.bind(wall, dmg * 0.3))
			player.get_tree().create_timer(wall_dur).timeout.connect(wall.queue_free)
		return

	AudioManager.play_sfx("wpn_runetracer")
	var speed = w.speed * player.speed_mult * 1.2
	var p = Area2D.new()
	p.collision_mask = 4
	var s = CollisionShape2D.new()
	var c = CircleShape2D.new()
	c.radius = max(area, 4.0)
	s.shape = c
	p.add_child(s)
	var sz = max(area * 1.5, 8.0)
	var vis = ColorRect.new()
	vis.color = Color(0.8, 0.3, 0.7, 0.9)
	vis.size = Vector2(sz, sz)
	vis.position = Vector2(-sz / 2, -sz / 2)
	p.add_child(vis)
	var inner = ColorRect.new()
	inner.color = Color(1.0, 0.6, 0.9, 0.6)
	inner.size = Vector2(sz * 0.5, sz * 0.5)
	inner.position = Vector2(-sz * 0.25, -sz * 0.25)
	p.add_child(inner)

	var dir = player.direction if player.direction.length() > 0 else Vector2.DOWN
	p.global_position = player.global_position + dir * 15
	p.set_meta("rune_dir", dir)
	p.set_meta("rune_speed", speed)
	p.set_meta("rune_bounces", 0)
	p.set_meta("rune_dmg", dmg)
	player.get_parent().add_child(p)
	p.body_entered.connect(weapon_manager._on_proj_hit.bind(p, dmg))

	var updater = Node2D.new()
	updater.name = "RuneTracerUpdater"
	updater.set_script(preload("res://scripts/entities/runetracer_updater.gd"))
	updater.set_meta("rune_proj", p)
	player.add_child(updater)
