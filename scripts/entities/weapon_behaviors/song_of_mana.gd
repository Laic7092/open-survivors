static func fire(w, weapon_manager, player, get_enemies):
	AudioManager.play_sfx("wpn_bible")
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var screen_h = player.get_viewport_rect().size.y
	var height = screen_h * 1.5
	var dur = 0.5 * player.duration_mult

	var zone = Area2D.new()
	zone.collision_mask = 4
	var s = CollisionShape2D.new()
	var c = RectangleShape2D.new()
	c.size = Vector2(area * 2, height)
	s.shape = c
	zone.add_child(s)

	# ── 视觉：用矩形条代替 emoji 音符 ──
	var note_count = 5 + w.level
	var note_w = max(area * 1.5, 12.0)
	var note_h = 4.0
	var base_color = Color(0.2, 0.7, 1.0, 0.8)  # 浅蓝
	var glow_alpha = 0.6
	for i in range(note_count):
		var y_off = -height / 2 + (height / (note_count + 1)) * (i + 1)

		# 光晕矩形（比主体大一圈）
		var glow = ColorRect.new()
		glow.color = Color(base_color.r, base_color.g, base_color.b, glow_alpha * 0.3)
		glow.size = Vector2(note_w * 2.5, note_h * 3)
		glow.position = Vector2(-area - glow.size.x / 2, y_off - glow.size.y / 2)
		zone.add_child(glow)

		# 主体矩形
		var rect = ColorRect.new()
		rect.color = base_color
		rect.size = Vector2(note_w, note_h)
		rect.position = Vector2(-area - rect.size.x / 2, y_off - rect.size.y / 2)
		zone.add_child(rect)

	zone.global_position = player.global_position + Vector2(0, 0)
	player.get_parent().add_child(zone)
	zone.body_entered.connect(_on_vine_hit.bind(zone, dmg))
	var tw = player.create_tween()
	for child in zone.get_children():
		if child is ColorRect:
			tw.parallel().tween_property(child, "modulate:a", 0.0, dur)
	var zone_id = zone.get_instance_id()
	tw.finished.connect(func():
		var _x = instance_from_id(zone_id)
		if _x:
			_x.queue_free()
	)

static func _on_vine_hit(body, zone, dmg):
	if not is_instance_valid(body) or not is_instance_valid(zone):
		return
	if body.has_method("take_damage"):
		body.take_damage(dmg, Vector2.ZERO)
