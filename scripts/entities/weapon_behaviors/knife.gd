static func fire(w, weapon_manager, player, get_enemies):
	if weapon_manager._knife_sfx_cooldown <= 0:
		AudioManager.play_sfx("wpn_knife" if not w.evolved else "wpn_evo")
		weapon_manager._knife_sfx_cooldown = 0.3
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var count = weapon_manager.get_projectile_count(w.type)
	var base_dir = player.direction if player.direction.length() > 0 else Vector2.DOWN
	var perp = Vector2(-base_dir.y, base_dir.x)

	for i in range(count):
		var dir = base_dir
		var side_offset = perp * (i - (count - 1) / 2.0) * 10.0
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = area
		s.shape = c
		p.add_child(s)
		var knife_emoji = weapon_manager._make_emoji_node("🗡️", max(area * 1.2, 16.0))
		p.add_child(knife_emoji)
		p.global_position = player.global_position + dir * 20 + side_offset
		p.rotation = dir.angle()
		player.get_parent().add_child(p)
		p.body_entered.connect(weapon_manager._on_proj_hit_and_free.bind(p, dmg))
		var mover = Node2D.new()
		mover.set_script(weapon_manager._proj_mover_script)
		mover.set_movement(dir * w.speed, 500.0 / max(w.speed, 1.0))
		p.add_child(mover)
