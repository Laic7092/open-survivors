static func fire(w, weapon_manager, player, get_enemies):
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var count = 1 + int(w.level / 2) + weapon_manager.get_projectile_count(w.type)
	var dir = player.direction if player.direction.length() > 0 else Vector2.DOWN
	var perp = Vector2(-dir.y, dir.x)
	for i in range(count):
		var offset = perp * (i - (count - 1) / 2.0) * area * 0.8
		var zone = Area2D.new()
		zone.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = RectangleShape2D.new()
		c.size = Vector2(area * 0.3, area * 1.5)
		s.shape = c
		zone.add_child(s)
		var vis = ColorRect.new()
		vis.color = Color(0.2, 0.9, 0.6, 0.4)
		vis.size = Vector2(area * 0.3, area * 1.5)
		vis.position = Vector2(-area * 0.15, -area * 0.75)
		zone.add_child(vis)
		zone.global_position = player.global_position + dir * area + offset
		zone.rotation = dir.angle()
		player.get_parent().add_child(zone)
		zone.body_entered.connect(_on_phaser_hit.bind(zone, dmg))
		var tw = player.create_tween()
		tw.tween_property(vis, "modulate:a", 0.0, 0.8)
		tw.finished.connect(zone.queue_free)

static func _on_phaser_hit(body, zone, dmg):
	if not is_instance_valid(body) or not is_instance_valid(zone):
		return
	if body.has_method("take_damage"):
		body.take_damage(dmg, Vector2.ZERO)
