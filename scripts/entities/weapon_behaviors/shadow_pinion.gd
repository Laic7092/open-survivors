static func fire(w, weapon_manager, player, get_enemies):
	AudioManager.play_sfx("wpn_whip")
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var speed = player.velocity.length()
	if speed < 10.0:
		var zone = Area2D.new()
		zone.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = area
		s.shape = c
		zone.add_child(s)
		var vis = ColorRect.new()
		vis.color = Color(0.4, 0.2, 0.6, 0.5)
		vis.size = Vector2(area * 2, area * 2)
		vis.position = Vector2(-area, -area)
		zone.add_child(vis)
		zone.global_position = player.global_position
		player.get_parent().add_child(zone)
		zone.body_entered.connect(_on_shadow_hit.bind(zone, dmg))
		var tw = player.create_tween()
		tw.tween_property(vis, "modulate:a", 0.0, 0.5)
		var zone_id = zone.get_instance_id()
		tw.finished.connect(func():
			var _x = instance_from_id(zone_id)
			if _x:
				_x.queue_free()
		)
	else:
		var trail_pos = player.global_position - player.velocity.normalized() * 20.0
		var zone = Area2D.new()
		zone.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = area * 0.6
		s.shape = c
		zone.add_child(s)
		var vis = ColorRect.new()
		vis.color = Color(0.3, 0.1, 0.5, 0.3)
		vis.size = Vector2(area * 1.2, area * 1.2)
		vis.position = Vector2(-area * 0.6, -area * 0.6)
		zone.add_child(vis)
		zone.global_position = trail_pos
		player.get_parent().add_child(zone)
		zone.body_entered.connect(_on_shadow_hit.bind(zone, dmg * 0.5))
		var tw = player.create_tween()
		tw.tween_property(vis, "modulate:a", 0.0, 0.3)
		var zone_id = zone.get_instance_id()
		tw.finished.connect(func():
			var _x = instance_from_id(zone_id)
			if _x:
				_x.queue_free()
		)

static func _on_shadow_hit(body, zone, dmg):
	if not is_instance_valid(body) or not is_instance_valid(zone):
		return
	if body.has_method("take_damage"):
		body.take_damage(dmg, Vector2.ZERO)
