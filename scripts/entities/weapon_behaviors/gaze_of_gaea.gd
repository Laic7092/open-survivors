static func fire(w, weapon_manager, player, get_enemies):
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var dur = 2.0 * player.duration_mult
	var zone = Area2D.new()
	zone.collision_mask = 4
	var s = CollisionShape2D.new()
	var c = CircleShape2D.new()
	c.radius = area
	s.shape = c
	zone.add_child(s)
	var vis = ColorRect.new()
	vis.color = Color(0.3, 0.7, 0.3, 0.4)
	vis.size = Vector2(area * 2, area * 2)
	vis.position = Vector2(-area, -area)
	zone.add_child(vis)
	zone.global_position = player.global_position + player.direction * 40
	player.get_parent().add_child(zone)
	zone.body_entered.connect(_on_gaea_hit.bind(zone, dmg))
	var tw = player.create_tween()
	tw.tween_property(vis, "modulate:a", 0.0, dur)
	tw.finished.connect(zone.queue_free)

static func _on_gaea_hit(body, zone, dmg):
	if not is_instance_valid(body) or not is_instance_valid(zone):
		return
	if body.has_method("take_damage"):
		body.take_damage(dmg, Vector2.ZERO)
	if body.has_method("disarm") and randf() < 0.15:
		body.disarm(1.5)
