static func fire(w, weapon_manager, player, get_enemies):
	var enemies = get_enemies.call()
	if enemies.is_empty():
		return
	var target = _find_nearest(player, enemies)
	if target == null:
		return

	AudioManager.play_sfx("wpn_water")
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var dur = 3.0 * player.duration_mult
	var start_pos = player.global_position
	var target_pos = target.global_position

	# 创建投掷物（瓶子）
	var proj = Area2D.new()
	proj.collision_mask = 4
	var s = CollisionShape2D.new()
	var c = CircleShape2D.new()
	c.radius = max(area * 0.25, 4.0)
	s.shape = c
	proj.add_child(s)

	var bsz = max(area * 0.35, 8.0)

	var body = ColorRect.new()
	body.color = Color(0.2, 0.55, 1.0, 0.85)
	body.size = Vector2(bsz * 1.6, bsz * 2.0)
	body.position = Vector2(-bsz * 0.8, -bsz * 1.0)
	proj.add_child(body)

	var cork = ColorRect.new()
	cork.color = Color(0.55, 0.27, 0.07, 0.9)
	cork.size = Vector2(bsz * 1.2, bsz * 0.25)
	cork.position = Vector2(-bsz * 0.6, -bsz * 1.0 - bsz * 0.25)
	proj.add_child(cork)

	var hl = ColorRect.new()
	hl.color = Color(1.0, 1.0, 1.0, 0.35)
	hl.size = Vector2(bsz * 0.3, bsz * 1.2)
	hl.position = Vector2(-bsz * 0.5, -bsz * 0.5)
	proj.add_child(hl)

	proj.global_position = start_pos
	player.get_parent().add_child(proj)

	# 存档落地参数
	proj.set_meta("area", area)
	proj.set_meta("dmg", dmg)
	proj.set_meta("dur", dur)
	proj.set_meta("evolved", w.evolved)
	proj.set_meta("player", player)
	proj.set_meta("wp", weapon_manager)

	# 抛物线弹道（tween_method 模拟重力）
	var travel_dist = start_pos.distance_to(target_pos)
	var arc_height = travel_dist * 0.55
	var travel_time = travel_dist / max(w.speed, 200.0) * 0.55
	travel_time = max(travel_time, 0.15)

	var tw = player.create_tween()
	tw.tween_method(
		func(t):
			var x = lerpf(start_pos.x, target_pos.x, t)
			var y = lerpf(start_pos.y, target_pos.y, t) - arc_height * 4.0 * t * (1.0 - t)
			proj.global_position = Vector2(x, y),
		0.0, 1.0, travel_time
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tw.finished.connect(_on_water_bottle_land.bind(proj))


static func _find_nearest(player, enemies: Array) -> Node2D:
	var best: Node2D = null
	var min_d_sq = INF
	var ppos = player.global_position
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var d_sq = ppos.distance_squared_to(e.global_position)
		if d_sq < min_d_sq:
			min_d_sq = d_sq
			best = e
	return best


static func _on_water_bottle_land(proj):
	"""瓶子落地 → 爆开成水洼"""
	if not is_instance_valid(proj):
		return
	var pos = proj.global_position
	var area = proj.get_meta("area")
	var dmg = proj.get_meta("dmg")
	var dur = proj.get_meta("dur")
	var evolved = proj.get_meta("evolved")
	var player = proj.get_meta("player")
	var wp = proj.get_meta("wp")
	proj.queue_free()
	create_water_zone(pos, area, dmg, dur, evolved, player, wp)


static func _pulse_alpha(node, a: float, dur: float, player):
	if not is_instance_valid(node):
		return
	var tw = player.create_tween()
	tw.tween_property(node, "modulate:a", a, dur)
	tw.finished.connect(_pulse_alpha.bind(node, 0.5 if a < 0.35 else 0.35, dur, player))


static func _pulse_rings(rings: Array, tw: float, player):
	for r in rings:
		if is_instance_valid(r):
			var t = player.create_tween()
			t.tween_property(r, "modulate:a", 0.7, tw)
			t.finished.connect(_decay_rings.bind(r, tw, player))
	var dt = player.create_tween()
	dt.tween_interval(tw * 2)
	dt.finished.connect(_pulse_rings.bind(rings, tw, player))


static func _decay_rings(r, tw: float, player):
	if not is_instance_valid(r):
		return
	var t = player.create_tween()
	t.tween_property(r, "modulate:a", 0.3, tw)


static func _pulse_gold_rings(rings: Array, gt: float, player):
	for r in rings:
		if is_instance_valid(r):
			var t = player.create_tween()
			t.tween_property(r, "modulate:a", 0.55, gt)
			t.finished.connect(_decay_gold_rings.bind(r, gt, player))
	var dt = player.create_tween()
	dt.tween_interval(gt * 2)
	dt.finished.connect(_pulse_gold_rings.bind(rings, gt, player))


static func _decay_gold_rings(r, gt: float, player):
	if not is_instance_valid(r):
		return
	var t = player.create_tween()
	t.tween_property(r, "modulate:a", 0.15, gt)


static func create_water_zone(pos: Vector2, area: float, dmg: float, dur: float, evolved: bool, player, weapon_manager):
	# ===== 落地爆开水洼 =====
	var zone = Area2D.new()
	zone.collision_mask = 4
	var sz = CollisionShape2D.new()
	var sc = CircleShape2D.new()
	sc.radius = area
	sz.shape = sc
	zone.add_child(sz)

	# 1) 落地爆开 — 水花扩散
	var burst = ColorRect.new()
	burst.color = Color(0.3, 0.7, 1.0, 0.8)
	burst.size = Vector2(area * 0.1, area * 0.1)
	burst.position = Vector2(-area * 0.05, -area * 0.05)
	zone.add_child(burst)
	var btw = player.create_tween()
	btw.tween_property(burst, "scale", Vector2(8.0, 8.0), 0.2).from(Vector2(0.3, 0.3))
	btw.parallel().tween_property(burst, "modulate:a", 0.0, 0.2).from(0.8)
	btw.finished.connect(burst.queue_free)

	# 2) 水洼主体 — 呼吸动画（链式递归，不用 set_loops）
	var puddle = ColorRect.new()
	puddle.color = Color(0.1, 0.4, 0.8, 0.35)
	puddle.size = Vector2(area * 2, area * 2)
	puddle.position = Vector2(-area, -area)
	zone.add_child(puddle)
	zone.set_meta("puddle", puddle)
	_pulse_alpha(puddle, 0.5, 1.0, player)

	# 3) 边界辉光环 — 4 条边（独立 tween 链）
	var ring_color = Color(0.4, 0.85, 1.0, 0.45)
	var bw = 3
	var tw = 0.7
	var rt = ColorRect.new(); rt.color = ring_color; rt.size = Vector2(area * 2, bw); rt.position = Vector2(-area, -area); zone.add_child(rt)
	var rb = ColorRect.new(); rb.color = ring_color; rb.size = Vector2(area * 2, bw); rb.position = Vector2(-area, area - bw); zone.add_child(rb)
	var rl = ColorRect.new(); rl.color = ring_color; rl.size = Vector2(bw, area * 2); rl.position = Vector2(-area, -area); zone.add_child(rl)
	var rr = ColorRect.new(); rr.color = ring_color; rr.size = Vector2(bw, area * 2); rr.position = Vector2(area - bw, -area); zone.add_child(rr)
	zone.set_meta("rings", [rt, rb, rl, rr])
	for r in [rt, rb, rl, rr]:
		r.modulate.a = 0.3
	_pulse_rings([rt, rb, rl, rr], tw, player)

	# 4) 进化 — 金色内边框
	if evolved:
		var gc = Color(1.0, 0.7, 0.1, 0.25)
		var gap = 6
		var grt = ColorRect.new(); grt.color = gc; grt.size = Vector2(area * 2 - gap * 2, bw)
		grt.position = Vector2(-area + gap, -area + gap); zone.add_child(grt)
		var grb = ColorRect.new(); grb.color = gc; grb.size = Vector2(area * 2 - gap * 2, bw)
		grb.position = Vector2(-area + gap, area - gap - bw); zone.add_child(grb)
		var grl = ColorRect.new(); grl.color = gc; grl.size = Vector2(bw, area * 2 - gap * 2)
		grl.position = Vector2(-area + gap, -area + gap); zone.add_child(grl)
		var grr = ColorRect.new(); grr.color = gc; grr.size = Vector2(bw, area * 2 - gap * 2)
		grr.position = Vector2(area - gap - bw, -area + gap); zone.add_child(grr)
		zone.set_meta("gold_rings", [grt, grb, grl, grr])
		for r in [grt, grb, grl, grr]:
			r.modulate.a = 0.15
		_pulse_gold_rings([grt, grb, grl, grr], 0.8, player)

	zone.global_position = pos
	player.get_parent().add_child(zone)

	# Tick 定时器
	var tick_count = int(dur / 0.5)
	for i in range(1, tick_count + 1):
		player.get_tree().create_timer(0.5 * i).timeout.connect(weapon_manager._on_water_tick.bind(zone, area, dmg, evolved))
	player.get_tree().create_timer(dur).timeout.connect(weapon_manager._on_water_cleanup.bind(zone))
