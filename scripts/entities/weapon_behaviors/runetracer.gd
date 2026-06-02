static func fire(w, weapon_manager, player, get_enemies):
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult

	# ── 进化形态：两面激光墙 ──
	if w.evolved:
		AudioManager.play_sfx("wpn_nofuture")
		var wall_len = 300.0 + 60.0 * w.level
		var wall_dur = (w.duration if w.duration > 0.0 else 1.5) * player.duration_mult
		var dir = player.direction if player.direction.length() > 0 else Vector2.DOWN
		var perp = Vector2(-dir.y, dir.x)
		for side in [-1, 1]:
			var wall = Area2D.new()
			wall.collision_mask = 4
			var ws = CollisionShape2D.new()
			var wc = RectangleShape2D.new()
			wc.size = Vector2(wall_len, 12.0)
			ws.shape = wc
			wall.add_child(ws)
			var beam = ColorRect.new()
			beam.color = Color(0.9, 0.3, 0.8, 0.7)
			beam.size = Vector2(wall_len, 10)
			beam.position = Vector2(-wall_len / 2, -5)
			wall.add_child(beam)
			var glow = ColorRect.new()
			glow.color = Color(1.0, 0.6, 0.9, 0.3)
			glow.size = Vector2(wall_len + 20, 16)
			glow.position = Vector2(-wall_len / 2 - 10, -8)
			wall.add_child(glow)
			wall.global_position = player.global_position + perp * side * 30
			player.get_parent().add_child(wall)
			var _hit = Node2D.new()
			_hit.set_script(weapon_manager._proj_mover_script)
			_hit.set_hit_config(weapon_manager.get_enemy_manager(), dmg * 0.3, 10.0, -1, Callable(), w.knockback, w.hitbox_delay)
			wall.add_child(_hit)
			var wall_id = wall.get_instance_id()
			player.get_tree().create_timer(wall_dur).timeout.connect(func():
				var _x = instance_from_id(wall_id)
				if _x:
					_x.queue_free()
			)
		return

	# ── 普通形态：弹射投射物 ──
	AudioManager.play_sfx("wpn_runetracer")
	var count = weapon_manager.get_projectile_count(w.type)
	var base_speed = w.speed * player.speed_mult * 3
	var base_dir = player.direction if player.direction.length() > 0 else Vector2.DOWN

	for i in range(count):
		var speed = base_speed
		var dir = base_dir.rotated((i - (count - 1) * 0.5) * 0.2)

		# 碰撞
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = max(area, 4.0)
		s.shape = c
		p.add_child(s)

		# ── 视觉容器（整体旋转） ──
		var vis = Node2D.new()
		vis.name = "Visuals"
		p.add_child(vis)

		var sz = max(area * 1.0, 6.0)

		# 外光晕 —— 蓝紫色大光圈
		var aura = ColorRect.new()
		aura.color = Color(0.35, 0.15, 0.85, 0.18)
		aura.size = Vector2(sz * 3.5, sz * 3.5)
		aura.position = -aura.size / 2
		vis.add_child(aura)

		# 主体 —— 细长菱形，紫粉色
		var body = ColorRect.new()
		body.color = Color(0.8, 0.25, 0.95, 0.9)
		body.size = Vector2(sz * 2.8, sz * 0.4)
		body.position = Vector2(-body.size.x / 2, -body.size.y / 2)
		vis.add_child(body)

		# 内发光 —— 粉紫色方形光晕
		var inner = ColorRect.new()
		inner.color = Color(0.95, 0.4, 0.9, 0.5)
		inner.size = Vector2(sz * 1.6, sz * 1.6)
		inner.position = -inner.size / 2
		vis.add_child(inner)

		# 中心亮核 —— 白色
		var core = ColorRect.new()
		core.color = Color(1.0, 0.9, 0.95, 1.0)
		core.size = Vector2(sz * 0.6, sz * 0.6)
		core.position = -core.size / 2
		vis.add_child(core)

		# ── 初始方向 ──
		p.global_position = player.global_position + dir * 15
		vis.rotation = dir.angle()

		# ── 元数据 ──
		p.set_meta("rune_dir", dir)
		p.set_meta("rune_speed", speed)
		p.set_meta("rune_bounces", 0)
		p.set_meta("rune_dmg", dmg)

		player.get_parent().add_child(p)
		var _hit2 = Node2D.new()
		_hit2.set_script(weapon_manager._proj_mover_script)
		_hit2.set_movement(Vector2.ZERO, (w.duration if w.duration > 0.0 else 9999.0) * player.duration_mult)
		_hit2.set_hit_config(weapon_manager.get_enemy_manager(), dmg, max(area * 0.8, 12.0), -1, Callable(), w.knockback, w.hitbox_delay)
		p.add_child(_hit2)

		# ── 开火闪光 ──
		var spark = ColorRect.new()
		spark.color = Color(1.0, 0.85, 0.6, 0.6)
		spark.size = Vector2.ONE * max(area * 0.8, 5.0)
		spark.global_position = p.global_position - spark.size / 2
		player.get_parent().add_child(spark)
		var tw = player.create_tween()
		tw.tween_property(spark, "scale", Vector2.ONE * 1.5, 0.15)
		tw.parallel().tween_property(spark, "modulate:a", 0.0, 0.3)
		var spark_id = spark.get_instance_id()
		tw.finished.connect(func():
			var _x = instance_from_id(spark_id)
			if _x:
				_x.queue_free()
		)

		# ── Bounce component（作为投射物的子节点） ──
		var bouncer = Node2D.new()
		bouncer.name = "BounceComponent"
		bouncer.set_script(preload("res://scripts/entities/projectile/bounce_component.gd"))
		bouncer.direction_meta = "rune_dir"
		bouncer.speed_meta = "rune_speed"
		bouncer.bounce_count_meta = "rune_bounces"
		bouncer.max_bounces = 999999  # 仅由 duration 控制销毁，弹跳次数不限
		bouncer.visuals_node = "Visuals"
		bouncer.on_bounce = func(pos: Vector2, parent: Node):
			AudioManager.play_sfx("wpn_bounce")
			var ring = ColorRect.new()
			ring.color = Color(0.95, 0.85, 1.0, 0.8)
			var rs = 16.0
			ring.size = Vector2.ONE * rs
			ring.global_position = pos - ring.size / 2
			ring.rotation = deg_to_rad(45.0)
			parent.add_child(ring)
			var tween = parent.create_tween()
			tween.tween_property(ring, "scale", Vector2.ONE * 0.2, 0.1)
			tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.15)
			var ring_id = ring.get_instance_id()
			tween.finished.connect(func():
				var _x = instance_from_id(ring_id)
				if _x:
					_x.queue_free()
			)
			ring.get_tree().create_timer(0.3).timeout.connect(func():
				var _x = instance_from_id(ring_id)
				if _x:
					_x.queue_free()
			)
		p.add_child(bouncer)
