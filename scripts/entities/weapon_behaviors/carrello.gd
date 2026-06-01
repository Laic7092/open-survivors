static func fire(w, weapon_manager, player, get_enemies):
	AudioManager.play_sfx("wpn_knife")
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var count = weapon_manager.get_projectile_count(w.type) + int(w.level / 2)
	var base_dir = player.direction if player.direction.length() > 0 else Vector2.DOWN
	for i in range(count):
		var offset = (i - (count - 1) / 2.0) * 0.15
		var dir = base_dir.rotated(offset)
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = area
		s.shape = c
		p.add_child(s)
		var vis = weapon_manager._make_emoji_node("🚗", max(area * 1.0, 10.0))
		p.add_child(vis)
		p.global_position = player.global_position + dir * 15
		player.get_parent().add_child(p)
		var bounces = 1 + count
		_bounce_move(p, dir, w, dmg, bounces, player, weapon_manager)

static func _bounce_move(proj, dir, w, dmg, bounces, player, weapon_manager):
	if not is_instance_valid(proj):
		return
	var spd = w.speed * player.speed_mult
	var dist = 70.0
	var target = proj.global_position + dir * dist
	var tw = player.create_tween()
	tw.tween_property(proj, "global_position", target, dist / max(spd, 1.0))
	if bounces > 0:
		tw.finished.connect(_bounce.bind(proj, dir.rotated(PI * 0.25 * (1 if randi() % 2 == 0 else -1)), w, dmg, bounces - 1, player, weapon_manager))
	else:
		tw.finished.connect(weapon_manager._on_tween_done.bind(proj))

static func _bounce(proj, new_dir, w, dmg, bounces, player, weapon_manager):
	if is_instance_valid(proj):
		_bounce_move(proj, new_dir, w, dmg, bounces, player, weapon_manager)
