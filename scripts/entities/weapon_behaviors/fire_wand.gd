static func fire(w, weapon_manager, player, get_enemies):
	var enemies = get_enemies.call()
	if enemies.is_empty():
		return
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var explosion_radius = area * 1.5
	var count = weapon_manager.get_projectile_count(w.type)
	var max_range_fsq: float = (350.0 + w.area * player.area_mult * 3.0)
	max_range_fsq *= max_range_fsq
	var ppos = player.global_position
	var in_range: Array = []
	for e in enemies:
		if is_instance_valid(e) and ppos.distance_squared_to(e.global_position) <= max_range_fsq:
			in_range.append(e)
	if in_range.is_empty():
		return
	AudioManager.play_sfx("wpn_fire")
	in_range.shuffle()
	var n = mini(count, in_range.size())
	for i in range(n):
		var target = in_range[i]
		if not is_instance_valid(target):
			continue
		_fire_one_fireball(target, dmg, area, explosion_radius, w, weapon_manager, player)


static func _fire_one_fireball(target: Node2D, dmg: float, area: float, explosion_radius: float, w, weapon_manager, player):
	var p = Area2D.new()
	p.collision_mask = 4
	var s = CollisionShape2D.new()
	var c = CircleShape2D.new()
	c.radius = area * 0.8
	s.shape = c
	p.add_child(s)
	var fire_gfx = weapon_manager._fireball_node_script.new()
	fire_gfx.fb_size = max(area * 0.4, 6.0)
	fire_gfx.seed_offset = randi() % 1000
	p.add_child(fire_gfx)
	p.global_position = player.global_position
	player.get_parent().add_child(p)
	p.body_entered.connect(weapon_manager._on_firewand_hit.bind(p, explosion_radius, dmg, w))
	var dir = (target.global_position - player.global_position).normalized()
	var mover = weapon_manager._proj_mover_script.new()
	var travel_time = player.global_position.distance_to(target.global_position) / max(w.speed, 1.0)
	mover.set_movement(dir * w.speed, travel_time)
	p.add_child(mover)
	var tw = player.create_tween()
	tw.tween_interval(travel_time)
	tw.finished.connect(weapon_manager._on_firewand_explode.bind(p, explosion_radius, dmg, w))
