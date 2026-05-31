static func fire(w, weapon_manager, player, get_enemies):
	AudioManager.play_sfx("wpn_whip" if not w.evolved else "wpn_evo")
	weapon_manager.whip_vis_time = 0.1
	weapon_manager.whip_vis_area = w.area * player.area_mult
	# 立即扫一次 + 延迟再扫一次（替代原先 per-frame 全量扫描）
	_hit_swing(w, player, get_enemies)
	player.get_tree().create_timer(0.075).timeout.connect(
		func(): _hit_swing(w, player, get_enemies)
	)


static func _hit_swing(w, player, get_enemies):
	var enemies = get_enemies.call()
	var effective_area = w.area * player.area_mult
	var arc_r = effective_area * 2.0
	var half_w = arc_r * 0.50
	var half_h = arc_r * 0.30
	var dmg = w.damage * player.damage_mult
	if player._crit_chance > 0 and randf() < player._crit_chance:
		dmg *= player._crit_mult
	var heal = dmg * 0.2 if w.evolved else 0.0
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var offset = e.global_position - player.global_position
		var enemy_r = 14.0
		if is_instance_valid(e.collision_shape) and e.collision_shape.shape is CircleShape2D:
			enemy_r = e.collision_shape.shape.radius * max(e.scale.x, e.scale.y)
		if abs(offset.x) > half_w + enemy_r or abs(offset.y) > half_h + enemy_r:
			continue
		if e.has_method("take_damage"):
			e.take_damage(dmg, Vector2.ZERO)
			if heal > 0:
				player.health = min(player.health + heal, player.max_health)
