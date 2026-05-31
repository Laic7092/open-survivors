static func fire(w, weapon_manager, player, get_enemies):
	if not weapon_manager.has_meta("pako_connected"):
		weapon_manager.set_meta("pako_connected", true)
		if not player.hurt.is_connected(_on_player_hurt):
			player.hurt.connect(_on_player_hurt.bind(w, weapon_manager, player))

static func _on_player_hurt(w, weapon_manager, player):
	if not is_instance_valid(player):
		return
	if randf() < 0.3 + w.level * 0.05:
		var dmg = weapon_manager._calc_damage(w)
		var area = w.area * player.area_mult
		var all = weapon_manager._get_enemies()
		var ppos = player.global_position
		for e in all:
			if is_instance_valid(e) and ppos.distance_to(e.global_position) < area * 1.5:
				if e.has_method("take_damage"):
					e.take_damage(dmg, Vector2.ZERO)
		var flash = ColorRect.new()
		flash.color = Color(0.4, 0.2, 0.4, 0.5)
		var sz = area * 3
		flash.size = Vector2(sz, sz)
		flash.position = Vector2(-sz / 2, -sz / 2)
		flash.global_position = player.global_position
		player.get_parent().add_child(flash)
		var tw = player.create_tween()
		tw.tween_property(flash, "modulate:a", 0.0, 0.3)
		tw.finished.connect(flash.queue_free)

static func _reset(weapon_manager):
	if weapon_manager:
		weapon_manager.set_meta("pako_countering", false)
