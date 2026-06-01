static func fire(w, weapon_manager, player, get_enemies):
	AudioManager.play_sfx("wpn_whip" if not w.evolved else "wpn_evo")
	weapon_manager.whip_vis_time = 0.12
	weapon_manager.whip_vis_area = w.area * player.area_mult
	# Whip swings twice: immediate + delayed follow-up
	_hit_swing(w, player, get_enemies, weapon_manager)
	player.get_tree().create_timer(0.075).timeout.connect(
		func(): _hit_swing(w, player, get_enemies, weapon_manager)
	)


static func _hit_swing(w, player, get_enemies, weapon_manager):
	var enemies = get_enemies.call()
	var effective_area = w.area * player.area_mult
	# Rectangle hitbox extending in the player's facing direction
	var rect_length = effective_area * 2.0  # forward reach
	var rect_half_width = effective_area * 0.6  # half-width perpendicular to facing
	var facing_dir = player.direction.normalized() if player.direction.length() > 0 else Vector2.DOWN
	var perp_dir = facing_dir.orthogonal()
	
	var dmg = w.damage * player.might
	if player._crit_chance > 0 and randf() < player._crit_chance:
		dmg *= player._crit_mult
	var knockback_force = 120.0 * DataRegistry.items().wiki_knockback(w.type)
	var heal = dmg * 0.2 if w.evolved else 0.0
	
	var em = weapon_manager.get_enemy_manager()
	
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var offset = e.global_position - player.global_position
		var forward = offset.dot(facing_dir)  # distance forward (negative = behind)
		var perp = offset.dot(perp_dir)  # distance to the side
		
		# 矩形-圆碰撞：把敌人中心夹到矩形边界，检查距离是否 ≤ 敌人半径
		var enemy_r = em.get_radius(e.id) if em else 0.0
		var clamped_f = clamp(forward, 0.0, rect_length)
		var clamped_p = clamp(perp, -rect_half_width, rect_half_width)
		var ddx = forward - clamped_f
		var ddy = perp - clamped_p
		if ddx * ddx + ddy * ddy > enemy_r * enemy_r:
			continue
		
		# Passes through enemies (no pierce limit, hits all in rectangle)
		if e.has_method("take_damage"):
			e.take_damage(dmg, facing_dir * knockback_force)
			if heal > 0:
				player.health = min(player.health + heal, player.max_health)
