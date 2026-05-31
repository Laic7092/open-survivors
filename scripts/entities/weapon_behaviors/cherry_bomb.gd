static func fire(w, weapon_manager, player, get_enemies):
	AudioManager.play_sfx("wpn_knife")
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var count = weapon_manager.get_projectile_count(w.type)
	var base_dir = player.direction if player.direction.length() > 0 else Vector2.DOWN
	for i in range(count):
		var offset = (i - (count - 1) / 2.0) * 0.25
		var dir = base_dir.rotated(offset)
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = area * 0.6
		s.shape = c
		p.add_child(s)
		var vis = weapon_manager._make_emoji_node("🍒", max(area * 1.0, 12.0))
		p.add_child(vis)
		p.global_position = player.global_position + dir * 15
		p.set_meta("bomb_dmg", dmg)
		p.set_meta("bomb_area", area)
		p.set_meta("bomb_evolved", w.evolved)
		player.get_parent().add_child(p)
		p.body_entered.connect(_on_bomb_hit.bind(p, weapon_manager))
		var spd = w.speed * player.speed_mult
		var dist = 80.0
		var target = p.global_position + dir * dist
		var tw = player.create_tween()
		tw.tween_property(p, "global_position", target, dist / max(spd, 1.0))
		tw.finished.connect(_maybe_explode.bind(p, weapon_manager))

static func _on_bomb_hit(body, proj, weapon_manager):
	if not is_instance_valid(body) or not is_instance_valid(proj):
		return
	if body.has_method("take_damage"):
		var dmg = proj.get_meta("bomb_dmg")
		body.take_damage(dmg, Vector2.ZERO)
	_explode_bomb(proj, weapon_manager)

static func _maybe_explode(proj, weapon_manager):
	if not is_instance_valid(proj):
		return
	if randf() < 0.3 + proj.get_meta("bomb_evolved", false) * 0.4:
		_explode_bomb(proj, weapon_manager)
	else:
		proj.queue_free()

static func _explode_bomb(proj, weapon_manager):
	if not is_instance_valid(proj):
		return
	var pos = proj.global_position
	var dmg = proj.get_meta("bomb_dmg") * 2.0
	var area = proj.get_meta("bomb_area")
	weapon_manager._spawn_explosion_fx(pos, area, Color(0.9, 0.2, 0.2))
	var enemies = weapon_manager._get_enemies()
	for e in enemies:
		if is_instance_valid(e) and pos.distance_to(e.global_position) < area:
			if e.has_method("take_damage"):
				e.take_damage(dmg, Vector2.ZERO)
	proj.queue_free()
