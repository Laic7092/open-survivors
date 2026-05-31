static func fire(w, weapon_manager, player, get_enemies):
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var count = 1 + int(w.level / 3)
	var luck_bonus = 1.0 + player.luck
	for i in range(count):
		if randf() < 0.15 * luck_bonus:
			var angle = randf() * TAU
			var dist = randf_range(30.0, 80.0)
			var pos = player.global_position + Vector2(cos(angle), sin(angle)) * dist
			var light = ColorRect.new()
			light.color = Color(0.9, 0.8, 0.1, 0.6)
			var sz = area * 0.5
			light.size = Vector2(sz, sz)
			light.position = Vector2(-sz / 2, -sz / 2)
			light.global_position = pos
			player.get_parent().add_child(light)
			var zone = Area2D.new()
			zone.collision_mask = 4
			var s = CollisionShape2D.new()
			var c = CircleShape2D.new()
			c.radius = area * 0.4
			s.shape = c
			zone.add_child(s)
			zone.global_position = pos
			player.get_parent().add_child(zone)
			zone.body_entered.connect(_on_light_hit.bind(zone, dmg))
			var tw = player.create_tween()
			tw.tween_property(light, "modulate:a", 0.0, 1.0)
			var zone_id = zone.get_instance_id()
			tw.finished.connect(func():
				var _x = instance_from_id(zone_id)
				if _x:
					_x.queue_free()
			)
			var light_id = light.get_instance_id()
			player.get_tree().create_timer(1.0).timeout.connect(func():
				var _x = instance_from_id(light_id)
				if _x:
					_x.queue_free()
			)

static func _on_light_hit(body, zone, dmg):
	if not is_instance_valid(body) or not is_instance_valid(zone):
		return
	if body.has_method("take_damage"):
		body.take_damage(dmg, Vector2.ZERO)
