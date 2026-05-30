static func fire(w, weapon_manager, player, get_enemies):
	AudioManager.play_sfx("wpn_water")
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var dur = 3.0 + player.duration_bonus

	var drop_dist = 30.0 + randf_range(0, 40.0)
	var ppos = player.global_position + player.direction * drop_dist

	var sd = EventBus.get_config("selected_stage", null)
	if sd != null:
		ppos.x = clamp(ppos.x, -sd.get("map_width", 3200.0) * 0.5 + 30, sd.get("map_width", 3200.0) * 0.5 - 30)
		ppos.y = clamp(ppos.y, -sd.get("map_height", 2400.0) * 0.5 + 30, sd.get("map_height", 2400.0) * 0.5 - 30)
	else:
		ppos.x = clamp(ppos.x, -1570, 1570)
		ppos.y = clamp(ppos.y, -1170, 1170)

	var zone = Area2D.new()
	zone.collision_mask = 4
	var s = CollisionShape2D.new()
	var c = CircleShape2D.new()
	c.radius = area
	s.shape = c
	zone.add_child(s)
	var puddle = ColorRect.new()
	puddle.color = Color(0.1, 0.4, 0.8, 0.5)
	puddle.size = Vector2(area * 2, area * 2)
	puddle.position = Vector2(-area, -area)
	zone.add_child(puddle)
	var ring = ColorRect.new()
	ring.color = Color(0.3, 0.7, 1.0, 0.6)
	ring.size = Vector2(area * 2, 4)
	ring.position = Vector2(-area, -area)
	zone.add_child(ring)
	zone.global_position = ppos
	player.get_parent().add_child(zone)

	var tick_count = int(dur / 0.5)
	for i in range(1, tick_count + 1):
		player.get_tree().create_timer(0.5 * i).timeout.connect(weapon_manager._on_water_tick.bind(zone, area, dmg, w.evolved))
	player.get_tree().create_timer(dur).timeout.connect(weapon_manager._on_water_cleanup.bind(zone))
