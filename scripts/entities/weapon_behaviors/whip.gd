static func fire(w, weapon_manager, player, get_enemies):
	AudioManager.play_sfx("wpn_whip" if not w.evolved else "wpn_evo")
	weapon_manager.whip_vis_time = 0.1
	weapon_manager.whip_hit_window = 0.15
	weapon_manager.whip_vis_area = w.area * player.area_mult
	weapon_manager._whip_hit_this_swing.clear()
	_check_hits(w, weapon_manager, player, get_enemies)


static func _check_hits(w, weapon_manager, player, get_enemies):
	var enemies = get_enemies.call()
	var effective_area = w.area * player.area_mult
	var arc_r = effective_area * 2.0
	var half_w = arc_r * 0.50
	var half_h = arc_r * 0.30
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var id = e.get_instance_id()
		if weapon_manager._whip_hit_this_swing.has(id):
			continue
		var offset = e.global_position - player.global_position
		var enemy_r = 14.0
		if is_instance_valid(e.collision_shape) and e.collision_shape.shape is CircleShape2D:
			enemy_r = e.collision_shape.shape.radius * max(e.scale.x, e.scale.y)
		if abs(offset.x) > half_w + enemy_r or abs(offset.y) > half_h + enemy_r:
			continue
		var dmg = w.damage * player.damage_mult
		if player._crit_chance > 0 and randf() < player._crit_chance:
			dmg *= player._crit_mult
		e.take_damage(dmg, Vector2.ZERO)
		if w.evolved:
			player.health = min(player.health + dmg * 0.2, player.max_health)
		weapon_manager._whip_hit_this_swing[id] = true
