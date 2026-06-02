static func fire(w, weapon_manager, player, get_enemies):
	# 每发独立取当前方向、区域、伤害，不共用前一发的固定值
	var stagger_idx = w.custom_state.get("stagger_index", 0)
	var effective_area = w.area * player.area_mult
	var facing_dir = player.direction if player.direction.length() > 0 else Vector2.DOWN
	var perp_dir = facing_dir.normalized().orthogonal()
	# 偏移倍数：每发矩形沿朝向平移 2×area，使相邻挥击首尾相接，最大化覆盖范围
	var rect_offset = facing_dir.normalized() * stagger_idx * effective_area * 2.0
	
	AudioManager.play_sfx("wpn_whip" if not w.evolved else "wpn_evo")
	if stagger_idx == 0:
		# 第一发沿用 player.gd 的 _draw 渲染
		weapon_manager.whip_vis_time = 0.12
		weapon_manager.whip_vis_area = effective_area
	else:
		# 后续发自己生成偏移后的临时视觉节点
		_spawn_swing_visual(player, effective_area, facing_dir.normalized(), rect_offset, w.evolved)
	
	_hit_swing(w, player, get_enemies, weapon_manager, stagger_idx)


static func _spawn_swing_visual(player: Node2D, area: float, facing_dir: Vector2, offset: Vector2, evolved: bool):
	# 创建一个临时节点绘制挥击矩形，位置对准判定区，渐隐后自动销毁
	var rect_node = Node2D.new()
	rect_node.name = "WhipSwingVisual"
	rect_node.position = player.global_position + offset
	
	# 直接用 _draw 画矩形
	rect_node.set_script(preload("res://scripts/entities/fx/whip_swing_visual.gd"))
	rect_node.visual_area = area
	rect_node.facing_dir = facing_dir
	rect_node.evolved = evolved
	
	player.get_parent().add_child(rect_node)
	
	# 渐隐动画
	var tw = player.create_tween()
	tw.tween_method(func(a): rect_node.modulate.a = a, 0.6, 0.0, 0.12)
	tw.finished.connect(rect_node.queue_free)


static func _hit_swing(w, player, get_enemies, weapon_manager, stagger_idx: int = 0):
	var enemies = get_enemies.call()
	var effective_area = w.area * player.area_mult
	# Rectangle hitbox extending in the player's facing direction
	var rect_length = effective_area * 2.0  # forward reach
	var rect_half_width = effective_area * 0.6  # half-width perpendicular to facing
	var facing_dir = player.direction.normalized() if player.direction.length() > 0 else Vector2.DOWN
	var perp_dir = facing_dir.orthogonal()
	
	# 分开发射时，后一发矩形向朝向方向偏移，首尾相接，最大化覆盖
	var rect_offset = facing_dir * stagger_idx * effective_area * 2.0
	var rect_origin = player.global_position + rect_offset
	
	var dmg = weapon_manager._calc_damage(w)
	var heal = dmg * 0.2 if w.evolved else 0.0
	
	var em = weapon_manager.get_enemy_manager()
	
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var offset = e.global_position - rect_origin
		var forward = offset.dot(facing_dir)  # distance forward from rect_origin
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
			e.take_damage(dmg, player.global_position, w.knockback)
			if heal > 0:
				player.health = min(player.health + heal, player.max_health)
