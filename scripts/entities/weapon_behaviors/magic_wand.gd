static func fire(w, weapon_manager, player, get_enemies):
	var enemies = get_enemies.call()
	if enemies.is_empty():
		return
	
	# Wiki: "shoots a blue magic missile that is fired at the closest enemy"
	# "Additional projectiles from Amount will be fired in a sequence"
	var ppos = player.global_position
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var count = weapon_manager.get_projectile_count(w.type)
	var max_range_sq = (350.0 + w.area * player.area_mult * 3.0)
	max_range_sq *= max_range_sq
	
	# Sort enemies by distance (nearest first)
	var by_dist: Array = []
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var dsq = ppos.distance_squared_to(e.global_position)
		if dsq > max_range_sq:
			continue
		by_dist.append([dsq, e])
	by_dist.sort_custom(func(a, b): return a[0] < b[0])
	
	if by_dist.is_empty():
		return
	
	# Fire up to `count` missiles at the nearest enemies
	var targets = by_dist.slice(0, count)
	if targets.is_empty():
		return
	
	if weapon_manager._wand_sfx_cooldown <= 0:
		AudioManager.play_sfx("wpn_wand" if not w.evolved else "wpn_evo")
		weapon_manager._wand_sfx_cooldown = 0.3
	
	# Wiki: "missiles will be fired in a sequence" — slight stagger per projectile
	var delay = 0.0
	for pair in targets:
		var target = pair[1]
		if not is_instance_valid(target):
			continue
		if delay > 0:
			player.get_tree().create_timer(delay).timeout.connect(
				func(): _fire_missile(w, weapon_manager, player, ppos, target, dmg, area)
			)
		else:
			_fire_missile(w, weapon_manager, player, ppos, target, dmg, area)
		delay += 0.06  # Sequential stagger


static func _fire_missile(w, weapon_manager, player, from: Vector2, target, dmg: float, area: float):
	if not is_instance_valid(target):
		return
	
	var p = Area2D.new()
	p.collision_mask = 4  # enemy layer
	var s = CollisionShape2D.new()
	var c = CircleShape2D.new()
	c.radius = area
	s.shape = c
	p.add_child(s)
	p.global_position = from
	
	# Wiki: "Each missile can initially hit one enemy before dissipating"
	# Uses pierce count from WeaponState
	p.set_meta("pierce_remaining", w.pierce)
	
	# Visual
	var vis = Node2D.new()
	vis.set_script(weapon_manager._proj_vis_script)
	p.add_child(vis)
	
	player.get_parent().add_child(p)
	p.body_entered.connect(_on_wand_hit.bind(p, dmg, w))
	
	# Wiki: "The missiles cannot pass through walls"
	# Move toward target
	var dir = (target.global_position - from).normalized()
	var dist = from.distance_to(target.global_position)
	var travel_time = dist / max(w.speed, 1.0)
	var mover = Node2D.new()
	mover.set_script(weapon_manager._proj_mover_script)
	mover.set_movement(dir * w.speed, travel_time)
	p.add_child(mover)


static func _on_wand_hit(body, proj, dmg: float, w):
	if not is_instance_valid(body) or not is_instance_valid(proj):
		return
	if body.has_method("take_damage"):
		body.take_damage(dmg, Vector2.ZERO)
	# Decrement pierce; free when depleted
	var remaining = proj.get_meta("pierce_remaining", 1) - 1
	if remaining <= 0:
		if is_instance_valid(proj):
			proj.queue_free()
	else:
		proj.set_meta("pierce_remaining", remaining)
