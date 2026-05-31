static func fire(w, weapon_manager, player, get_enemies):
	AudioManager.play_sfx("wpn_bible")
	var base_dmg = w.damage * player.might
	var level_scaled = base_dmg * (1.0 + w.level * 0.5)
	var area = w.area * player.area_mult
	var count = weapon_manager.get_projectile_count(w.type)
	var dir = player.direction if player.direction.length() > 0 else Vector2.DOWN
	for i in range(count):
		var angle = (TAU / count) * i
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = area * 0.6
		s.shape = c
		p.add_child(s)
		var vis = weapon_manager._make_emoji_node("💎", max(area * 1.0, 12.0))
		p.add_child(vis)
		p.global_position = player.global_position + dir.rotated(angle) * 25
		player.get_parent().add_child(p)
		p.body_entered.connect(weapon_manager._on_proj_hit_and_free.bind(p, level_scaled))
		var mover = Node2D.new()
		mover.set_script(weapon_manager._proj_mover_script)
		var spd = w.speed * player.speed_mult
		mover.set_movement(dir.rotated(angle) * spd, 400.0 / max(spd, 1.0))
		p.add_child(mover)
