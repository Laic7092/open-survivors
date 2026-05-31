static func fire(w, weapon_manager, player, get_enemies):
	AudioManager.play_sfx("wpn_pentagram")
	var all = get_enemies.call()
	var dmg_mult = 0
	if all.is_empty():
		return
	for e in all:
		if is_instance_valid(e) and e.has_method("take_damage"):
			e.take_damage(99999.0, player.global_position)
	var area = w.area * player.area_mult
	var sz = area * 2

	# ── 外层爆炸光环 ──
	var ring = ColorRect.new()
	ring.color = Color(0.6, 0.1, 0.9, 0.4)
	ring.size = Vector2(sz * 1.3, sz * 1.3)
	ring.global_position = player.global_position - Vector2(sz * 0.65, sz * 0.65)
	player.get_parent().add_child(ring)
	var tw_ring = player.create_tween()
	tw_ring.tween_property(ring, "modulate:a", 0.0, 0.6)
	tw_ring.finished.connect(ring.queue_free)

	# ── 主闪光 ──
	var flash = ColorRect.new()
	flash.color = Color(0.7, 0.2, 0.95, 0.7)
	flash.size = Vector2(sz, sz)
	flash.global_position = player.global_position - Vector2(sz / 2, sz / 2)
	player.get_parent().add_child(flash)
	var tw = player.create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.5)
	tw.finished.connect(flash.queue_free)
