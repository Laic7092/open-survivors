static func fire(w, weapon_manager, player, get_enemies):
	AudioManager.play_sfx("wpn_knife")
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var count = weapon_manager.get_projectile_count(w.type)
	var base_dir = player.direction if player.direction.length() > 0 else Vector2.DOWN
	var speed = player.velocity.length()
	var cd_reduce = 1.0 - min(speed / 800.0, 0.5)
	w.cooldown *= cd_reduce
	for i in range(count):
		var offset = (i - (count - 1) / 2.0) * 0.2
		var dir = base_dir.rotated(offset)
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = area
		s.shape = c
		p.add_child(s)
		var vis = weapon_manager._make_emoji_node("✨", max(area * 1.2, 10.0))
		p.add_child(vis)
		p.global_position = player.global_position + dir * 20
		player.get_parent().add_child(p)
		p.body_entered.connect(weapon_manager._on_proj_hit_and_free.bind(p, dmg))
		var mover = Node2D.new()
		mover.set_script(weapon_manager._proj_mover_script)
		var spd = w.speed * player.speed_mult
		mover.set_movement(dir * spd, 400.0 / max(spd, 1.0))
		mover.set_hit_config(weapon_manager.get_enemy_manager(), dmg, 6.0, 0)
		p.add_child(mover)
