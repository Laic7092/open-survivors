static func fire(w, weapon_manager, player, get_enemies):
	var enemies = get_enemies.call()
	if enemies.is_empty():
		return
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var explosion_radius = area * 1.5
	var count = weapon_manager.get_projectile_count(w.type)
	var max_range_sq: float = (350.0 + w.area * player.area_mult * 3.0)
	max_range_sq *= max_range_sq
	var ppos = player.global_position
	
	# Find a random enemy in range
	var in_range: Array = []
	for e in enemies:
		if is_instance_valid(e) and ppos.distance_squared_to(e.global_position) <= max_range_sq:
			in_range.append(e)
	if in_range.is_empty():
		return
	
	AudioManager.play_sfx("wpn_fire")
	
	# Wiki: "shoots an arc of fireballs in the direction of a random enemy"
	# "additional ones gained through Amount are added to the ends of the arc"
	var target = in_range[randi() % in_range.size()]
	if not is_instance_valid(target):
		return
	var base_dir = (target.global_position - ppos).normalized()
	var perp = Vector2(-base_dir.y, base_dir.x)
	
	# Arc spread: fireballs fanned out in an arc
	var arc_angle = PI * 0.3  # ~54° total arc
	for i in range(count):
		var t = (float(i) / max(count - 1, 1)) - 0.5 if count > 1 else 0.0
		var angle_offset = t * arc_angle
		var dir = base_dir.rotated(angle_offset)
		
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = area * 0.8
		s.shape = c
		p.add_child(s)
		
		# Wiki: "Each fireball can hit one enemy before dissipating"
		p.set_meta("pierce_remaining", w.pierce)  # base 1
		
		var fire_gfx = weapon_manager._fireball_node_script.new()
		fire_gfx.fb_size = max(area * 0.4, 6.0)
		fire_gfx.seed_offset = randi() % 1000
		p.add_child(fire_gfx)
		p.global_position = ppos
		player.get_parent().add_child(p)
		p.body_entered.connect(_on_firewand_hit.bind(p, explosion_radius, dmg, w, weapon_manager))
		
		var mover = weapon_manager._proj_mover_script.new()
		var travel_time = ppos.distance_to(target.global_position) / max(w.speed, 1.0)
		mover.set_movement(dir * w.speed, travel_time)
		p.add_child(mover)
		
		# Explode on timeout (misses target)
		var tw = player.create_tween()
		tw.tween_interval(travel_time)
		tw.finished.connect(_on_firewand_explode.bind(p, explosion_radius, dmg, w, weapon_manager))


static func _on_firewand_hit(body, proj, explosion_radius: float, dmg: float, w, weapon_manager):
	if not is_instance_valid(body) or not is_instance_valid(proj):
		return
	var pos = proj.global_position
	# Explode on contact
	weapon_manager._explode_at(pos, explosion_radius, dmg, w)
	
	# Decrement pierce; free when depleted
	var remaining = proj.get_meta("pierce_remaining", 1) - 1
	if remaining <= 0:
		if is_instance_valid(proj):
			for c in proj.get_children():
				if c.has_method("mark_hit"):
					c.mark_hit()
			proj.queue_free()
	else:
		proj.set_meta("pierce_remaining", remaining)


static func _on_firewand_explode(proj, explosion_radius: float, dmg: float, w, weapon_manager):
	if not is_instance_valid(proj):
		return
	weapon_manager._explode_at(proj.global_position, explosion_radius, dmg, w)
	if is_instance_valid(proj):
		proj.queue_free()
