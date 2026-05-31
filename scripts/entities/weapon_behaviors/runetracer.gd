static func fire(w, weapon_manager, player, get_enemies):
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult

	# ── 进化形态：两面激光墙 ──
	if w.evolved:
		AudioManager.play_sfx("wpn_nofuture")
		var wall_len = 300.0 + 60.0 * w.level
		var wall_dur = 1.5 * player.duration_mult
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
			wall.body_entered.connect(weapon_manager._on_proj_hit.bind(wall, dmg * 0.3))
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
	var base_speed = w.speed * player.speed_mult * 1.2
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

		# ── 命中连接 ──
		p.body_entered.connect(weapon_manager._on_proj_hit.bind(p, dmg))

		# ── Updater（作为投射物的子节点） ──
		var updater = Node2D.new()
		updater.name = "RuneTracerUpdater"
		updater.set_script(preload("res://scripts/entities/runetracer_updater.gd"))
		p.add_child(updater)
