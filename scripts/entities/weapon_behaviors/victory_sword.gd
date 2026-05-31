static func fire(w, weapon_manager, player, get_enemies):
	AudioManager.play_sfx("wpn_whip")
	var enemies = get_enemies.call()
	if enemies.is_empty():
		return
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var swing_count = 1 + int(w.level / 3)
	var max_range_sq = (200.0 + w.area * player.area_mult * 2.0) * (200.0 + w.area * player.area_mult * 2.0)
	var ppos = player.global_position
	var dir = player.direction if player.direction.length() > 0 else Vector2.DOWN
	for s_i in range(swing_count):
		var swing_angle = -PI / 4 + (PI / 2) * (s_i / float(swing_count))
		var swing_dir = dir.rotated(swing_angle)
		var slash = ColorRect.new()
		slash.color = Color(0.9, 0.8, 0.6, 0.4)
		var sw = area * 2.0
		var sh = area * 0.3
		slash.size = Vector2(sw, sh)
		slash.position = Vector2(-sw / 2, -sh / 2)
		slash.global_position = ppos + swing_dir * area
		slash.rotation = swing_dir.angle()
		player.get_parent().add_child(slash)
		var tw = player.create_tween()
		tw.tween_property(slash, "modulate:a", 0.0, 0.2)
		tw.finished.connect(slash.queue_free)
		for e in enemies:
			if not is_instance_valid(e):
				continue
			var offset = e.global_position - (ppos + swing_dir * area)
			if offset.length() < area:
				if e.has_method("take_damage"):
					e.take_damage(dmg, Vector2.ZERO)
