static func fire(w, weapon_manager, player, get_enemies):
	AudioManager.play_sfx("wpn_whip" if not w.evolved else "wpn_evo")
	weapon_manager.whip_vis_time = 0.12
	weapon_manager.whip_vis_area = w.area * player.area_mult
	# Whip swings twice: immediate + delayed follow-up
	_hit_swing(w, player, get_enemies)
	player.get_tree().create_timer(0.075).timeout.connect(
		func(): _hit_swing(w, player, get_enemies)
	)


static func _hit_swing(w, player, get_enemies):
	var enemies = get_enemies.call()
	var effective_area = w.area * player.area_mult
	# Arc-shaped hitbox extending in the player's facing direction
	# Wiki: "Attacks horizontally, passes through enemies"
	var arc_r = effective_area * 2.0  # reach radius
	var arc_width = effective_area * 0.6  # arc width perpendicular to facing
	var arc_angle = PI * 0.6  # ~108° arc coverage
	var facing_dir = player.direction.normalized() if player.direction.length() > 0 else Vector2.DOWN
	
	var dmg = w.damage * player.might
	if player._crit_chance > 0 and randf() < player._crit_chance:
		dmg *= player._crit_mult
	var knockback_force = 120.0 * DataRegistry.items().wiki_knockback(w.type)
	var heal = dmg * 0.2 if w.evolved else 0.0
	
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var offset = e.global_position - player.global_position
		var dist = offset.length()
		if dist > arc_r:
			continue
		# Check if enemy is within the facing arc
		var angle_diff = abs(offset.angle_to(facing_dir))
		if angle_diff > arc_angle * 0.5:
			continue
		# Check perpendicular offset (for the "wide arc" feel)
		var perp = offset.dot(facing_dir.orthogonal())
		if abs(perp) > arc_width:
			continue
		# Passes through enemies (no pierce limit, hits all in arc)
		if e.has_method("take_damage"):
			e.take_damage(dmg, facing_dir * knockback_force)
			if heal > 0:
				player.health = min(player.health + heal, player.max_health)
