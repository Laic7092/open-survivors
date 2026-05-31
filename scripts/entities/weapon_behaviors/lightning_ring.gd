static func fire(w, weapon_manager, player, get_enemies):
	var enemies = get_enemies.call()
	if enemies.is_empty():
		return
	var max_range_lsq: float = (350.0 + w.area * player.area_mult * 3.0) * (350.0 + w.area * player.area_mult * 3.0)
	var ppos = player.global_position
	var in_range: Array = []
	for e in enemies:
		if is_instance_valid(e) and ppos.distance_squared_to(e.global_position) <= max_range_lsq:
			in_range.append(e)
	if in_range.is_empty():
		return
	AudioManager.play_sfx("wpn_lightning")
	var target = in_range[randi() % in_range.size()]
	if not is_instance_valid(target):
		return
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var strike_radius = area * 1.2

	var flash = ColorRect.new()
	flash.color = Color(1.0, 1.0, 0.3, 0.7)
	var flash_sz = strike_radius * 2
	flash.size = Vector2(flash_sz, flash_sz)
	flash.position = Vector2(-flash_sz / 2, -flash_sz / 2)
	flash.global_position = target.global_position
	player.get_parent().add_child(flash)

	# 复用 enemies 变量，不二次 get_enemies()
	var target_pos = target.global_position
	var strike_r_sq = strike_radius * strike_radius
	for e in enemies:
		if not is_instance_valid(e):
			continue
		if e.global_position.distance_squared_to(target_pos) <= strike_r_sq:
			if e.has_method("take_damage"):
				e.take_damage(dmg, target_pos)

	var tw = player.create_tween()
	tw.tween_property(flash, "modulate", Color(1, 1, 0.3, 0), 0.15)
	tw.finished.connect(flash.queue_free)

	if w.evolved:
		var chained: Array[Node2D] = [target]
		# Dictionary 替代 Array.has() O(n) → O(1)
		var chained_set: Dictionary = {target.get_instance_id(): true}
		var chain_dmg = dmg * 0.6
		var chain_radius = strike_radius * 0.8
		var chain_r_sq = chain_radius * chain_radius
		for _c in range(5):
			var last = chained[-1]
			if not is_instance_valid(last):
				break
			var next_target: Node2D = null
			var min_d_sq = INF
			var last_pos = last.global_position
			for e in enemies:
				if not is_instance_valid(e):
					continue
				if chained_set.has(e.get_instance_id()):
					continue
				var d_sq = e.global_position.distance_squared_to(last_pos)
				if d_sq < min_d_sq and d_sq <= chain_r_sq:
					min_d_sq = d_sq
					next_target = e
			if next_target:
				var ch_flash = ColorRect.new()
				ch_flash.color = Color(0.6, 0.8, 1.0, 0.5)
				ch_flash.size = Vector2(flash_sz * 0.6, flash_sz * 0.6)
				ch_flash.position = Vector2(-flash_sz * 0.3, -flash_sz * 0.3)
				ch_flash.global_position = next_target.global_position
				player.get_parent().add_child(ch_flash)
				var tw2 = player.create_tween()
				tw2.tween_property(ch_flash, "modulate", Color(0.6, 0.8, 1.0, 0), 0.1)
				tw2.finished.connect(ch_flash.queue_free)
				if next_target.has_method("take_damage"):
					next_target.take_damage(chain_dmg, next_target.global_position)
				chained.append(next_target)
				chained_set[next_target.get_instance_id()] = true
