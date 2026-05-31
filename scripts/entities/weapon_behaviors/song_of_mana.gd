static func fire(w, weapon_manager, player, get_enemies):
	AudioManager.play_sfx("wpn_bible")
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var height = 300.0 + w.area * player.area_mult * 2.0
	for side in [-1, 1]:
		var zone = Area2D.new()
		zone.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = RectangleShape2D.new()
		c.size = Vector2(area * 2, height)
		s.shape = c
		zone.add_child(s)
		var vis = ColorRect.new()
		vis.color = Color(0.2, 0.8, 0.3, 0.5)
		vis.size = Vector2(area * 2, height)
		vis.position = Vector2(-area, -height / 2)
		zone.add_child(vis)
		zone.global_position = player.global_position + Vector2(side * (30 + area), 0)
		player.get_parent().add_child(zone)
		zone.body_entered.connect(_on_vine_hit.bind(zone, dmg))
		var tw = player.create_tween()
		tw.tween_property(vis, "modulate:a", 0.0, 1.0)
		tw.finished.connect(zone.queue_free)

static func _on_vine_hit(body, zone, dmg):
	if not is_instance_valid(body) or not is_instance_valid(zone):
		return
	if body.has_method("take_damage"):
		body.take_damage(dmg, Vector2.ZERO)
