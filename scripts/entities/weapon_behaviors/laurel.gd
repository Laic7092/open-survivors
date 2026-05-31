static func fire(w, weapon_manager, player, get_enemies):
	player.invincible = 0.5 + w.level * 0.1
	if w.evolved:
		var all = get_enemies.call()
		var dmg = w.damage * player.might
		for e in all:
			if is_instance_valid(e) and player.global_position.distance_to(e.global_position) < w.area * player.area_mult:
				if e.has_method("take_damage"):
					e.take_damage(dmg, Vector2.ZERO)
	var flash = ColorRect.new()
	flash.color = Color(0.2, 0.9, 0.4, 0.4)
	var sz = w.area * player.area_mult * 2
	flash.size = Vector2(sz, sz)
	flash.position = Vector2(-sz / 2, -sz / 2)
	flash.global_position = player.global_position
	player.get_parent().add_child(flash)
	var tw = player.create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.3)
	var flash_id = flash.get_instance_id()
	tw.finished.connect(func():
		var _x = instance_from_id(flash_id)
		if _x:
			_x.queue_free()
	)
