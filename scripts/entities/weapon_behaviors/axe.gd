static func fire(w, weapon_manager, player, get_enemies):
	AudioManager.play_sfx("wpn_axe" if not w.evolved else "wpn_evo")
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult * 0.5

	if w.evolved:
		_fire_death_spiral(w, dmg, area, weapon_manager, player, get_enemies)
	else:
		_fire_axe_normal(w, dmg, area, weapon_manager, player, get_enemies)


static func _fire_axe_normal(w, dmg: float, area: float, weapon_manager, player, get_enemies):
	var count = weapon_manager.get_projectile_count(w.type)
	# Wiki: "subsequent axes from Amount are thrown in quick succession towards the direction the player is facing in progressively wider arcs"
	var spawn_dir = player.direction if player.direction.length() > 0 else Vector2.DOWN
	var h_dir = Vector2(spawn_dir.x, 0.0)
	if h_dir.length_squared() < 0.01:
		h_dir = Vector2.RIGHT if spawn_dir.y >= 0 else Vector2.LEFT
	else:
		h_dir = h_dir.normalized()
	var perp = Vector2(-h_dir.y, h_dir.x)

	for i in range(count):
		var side = perp * (i - (count - 1) / 2.0) * 25.0
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = area
		s.shape = c
		p.add_child(s)
		var axe_emoji = weapon_manager._make_emoji_node("🪓", max(area * 1.3, 16.0))
		p.add_child(axe_emoji)
		p.global_position = player.global_position + spawn_dir * 20 + side
		p.rotation = h_dir.angle()
		player.get_parent().add_child(p)
		# Wiki: "Each axe can initially hit up to three enemies"
		p.set_meta("pierce_remaining", w.pierce)
		p.body_entered.connect(_on_axe_hit.bind(p, dmg))
		var apex = player.global_position + h_dir * 130 + Vector2(0, -180) + side
		var tw = player.create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "global_position", apex, 0.5)
		tw.tween_property(p, "rotation", p.rotation - TAU * 1.5, 0.5)
		tw.finished.connect(_on_axe_arc_done.bind(p, area))


static func _fire_death_spiral(w, dmg: float, area: float, weapon_manager, player, get_enemies):
	var count = 6 + player.projectile_bonus * 2
	var dir = player.direction if player.direction.length() > 0 else Vector2.DOWN

	for i in range(count):
		var angle = (TAU / count) * i
		var spawn_dir = Vector2(cos(angle), sin(angle))
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = max(area * 1.2, 8.0)
		s.shape = c
		p.add_child(s)
		var axe_sz = max(area * 2.5, 16.0)
		var death_emoji = weapon_manager._make_emoji_node("🪓", axe_sz)
		p.add_child(death_emoji)
		p.global_position = player.global_position + spawn_dir * 10
		p.rotation = angle
		player.get_parent().add_child(p)
		# Wiki: "Each axe can initially hit up to three enemies"
		p.set_meta("pierce_remaining", w.pierce)
		p.body_entered.connect(_on_axe_hit.bind(p, dmg))
		var mid = player.global_position + spawn_dir * 160 + Vector2(0, -120)
		var tw = player.create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "global_position", mid, 0.35)
		tw.tween_property(p, "scale", Vector2(1.5, 1.5), 0.35)
		tw.finished.connect(_on_axe_return.bind(p, area))


# ── Custom pierce-aware hit callback ──
static func _on_axe_hit(body, proj, dmg: float):
	if not is_instance_valid(body) or not is_instance_valid(proj):
		return
	if body.has_method("take_damage"):
		body.take_damage(dmg, Vector2.ZERO)
	var remaining = proj.get_meta("pierce_remaining", 3) - 1
	if remaining <= 0:
		if is_instance_valid(proj):
			proj.queue_free()
	else:
		proj.set_meta("pierce_remaining", remaining)


# ── Arc-done callback (replace weapon_manager._on_axe_arc_done) ──
static func _on_axe_arc_done(proj, area: float):
	if not is_instance_valid(proj):
		return
	var fall_dist = 500.0 + area * 3.0
	var target = proj.global_position + Vector2(0, fall_dist)
	var tw = (proj.get_tree().get_first_node_in_group("player") as Node).create_tween() if Engine.has_singleton("Player") else null
	if not tw:
		tw = (proj.get_tree().get_nodes_in_group("player")[0] as Node).create_tween() if proj.get_tree().get_nodes_in_group("player").size() > 0 else null
	if not tw:
		proj.queue_free()
		return
	tw.set_parallel(true)
	tw.tween_property(proj, "global_position", target, 0.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(proj, "rotation", proj.rotation - TAU * 2.0, 0.8)
	tw.finished.connect(_on_tween_done.bind(proj))


# ── Return callback (replace weapon_manager._on_axe_return) ──
static func _on_axe_return(proj, area: float):
	if not is_instance_valid(proj):
		return
	var fall_dist = 400.0 + area * 3.0
	var target = proj.global_position + Vector2(0, fall_dist)
	var player_node = proj.get_tree().get_nodes_in_group("player")[0] if proj.get_tree().get_nodes_in_group("player").size() > 0 else null
	if not player_node:
		proj.queue_free()
		return
	var tw = player_node.create_tween()
	tw.set_parallel(true)
	tw.tween_property(proj, "global_position", target, 0.7).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(proj, "rotation", proj.rotation - TAU * 2.0, 0.7)
	tw.finished.connect(_on_tween_done.bind(proj))


# ── Generic cleanup ──
static func _on_tween_done(proj):
	if is_instance_valid(proj):
		proj.queue_free()
