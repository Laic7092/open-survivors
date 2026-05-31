static func fire(w, weapon_manager, player, get_enemies):
	if weapon_manager._knife_sfx_cooldown <= 0:
		AudioManager.play_sfx("wpn_knife" if not w.evolved else "wpn_evo")
		weapon_manager._knife_sfx_cooldown = 0.3

	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var count = weapon_manager.get_projectile_count(w.type)

	# Wiki: "throws projectiles in the direction the player is moving or last moved"
	var base_dir = player.direction if player.direction.length() > 0 else Vector2.DOWN
	var perp = Vector2(-base_dir.y, base_dir.x)

	# Wiki: "The firing Interval is decreased on levels 4, 6 and 8"
	# Each level reduces stagger between knives, grouping the volley tighter
	var stagger = 0.05
	if w.level >= 4: stagger -= 0.02
	if w.level >= 6: stagger -= 0.02
	if w.level >= 8: stagger -= 0.02
	stagger = max(stagger, 0.01)

	# Wiki: "Multiple knives from Amount are fired in short volleys in parallel"
	# Sequential stagger per knife
	for i in range(count):
		var dir = base_dir
		var side_offset = perp * (i - (count - 1) / 2.0) * 10.0
		
		if stagger > 0 and i > 0:
			player.get_tree().create_timer(stagger * i).timeout.connect(
				func(): _fire_knife(w, weapon_manager, player, dmg, area, dir, side_offset)
			)
		else:
			_fire_knife(w, weapon_manager, player, dmg, area, dir, side_offset)


static func _fire_knife(w, weapon_manager, player, dmg: float, area: float, dir: Vector2, side_offset: Vector2):
	var p = Area2D.new()
	p.collision_mask = 4
	var s = CollisionShape2D.new()
	var c = CircleShape2D.new()
	c.radius = area
	s.shape = c
	p.add_child(s)
	
	# Wiki: "Each knife can initially hit one enemy before dissipating"
	# Uses pierce count from WeaponState
	p.set_meta("pierce_remaining", w.pierce)
	
	var knife_emoji = weapon_manager._make_emoji_node("🗡️", max(area * 1.2, 16.0))
	p.add_child(knife_emoji)
	p.global_position = player.global_position + dir * 20 + side_offset
	p.rotation = dir.angle()
	player.get_parent().add_child(p)
	
	# Custom hit callback for pierce tracking
	p.body_entered.connect(_on_knife_hit.bind(p, dmg))
	
	# Wiki: "They cannot pass through walls" — linear travel
	var mover = Node2D.new()
	mover.set_script(weapon_manager._proj_mover_script)
	mover.set_movement(dir * w.speed, 500.0 / max(w.speed, 1.0))
	p.add_child(mover)


static func _on_knife_hit(body, proj, dmg: float):
	if not is_instance_valid(body) or not is_instance_valid(proj):
		return
	if body.has_method("take_damage"):
		body.take_damage(dmg, Vector2.ZERO)
	var remaining = proj.get_meta("pierce_remaining", 1) - 1
	if remaining <= 0:
		if is_instance_valid(proj):
			proj.queue_free()
	else:
		proj.set_meta("pierce_remaining", remaining)
