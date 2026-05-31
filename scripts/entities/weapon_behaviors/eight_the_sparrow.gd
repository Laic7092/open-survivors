static func fire(w, weapon_manager, player, get_enemies):
	AudioManager.play_sfx("wpn_knife")
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var count = weapon_manager.get_projectile_count(w.type)
	var base_dir = player.direction if player.direction.length() > 0 else Vector2.DOWN
	var spread = 0.3
	var angles = [-spread, 0.0, spread]
	for i in range(count):
		for a in angles:
			var dir = base_dir.rotated(a)
			var p = Area2D.new()
			p.collision_mask = 4
			var s = CollisionShape2D.new()
			var c = CircleShape2D.new()
			c.radius = area
			s.shape = c
			p.add_child(s)
			var vis = weapon_manager._make_emoji_node("🐤", max(area * 1.2, 12.0))
			p.add_child(vis)
			p.global_position = player.global_position
			p.rotation = dir.angle()
			p.set_meta("piercing", true)
			player.get_parent().add_child(p)
			p.body_entered.connect(_on_piercing_hit.bind(p, w, weapon_manager, dmg))
			var mover = Node2D.new()
			mover.set_script(weapon_manager._proj_mover_script)
			var spd = w.speed * player.speed_mult
			mover.set_movement(dir * spd, 600.0 / max(spd, 1.0))
			p.add_child(mover)

static func _on_piercing_hit(body, proj, w, weapon_manager, dmg: float):
	if not is_instance_valid(body) or not is_instance_valid(proj):
		return
	if body.has_method("take_damage"):
		body.take_damage(dmg, Vector2.ZERO)
