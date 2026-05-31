static func fire(w, weapon_manager, player, get_enemies):
	AudioManager.play_sfx("wpn_knife")
	var dmg = weapon_manager._calc_damage(w)
	var area = w.area * player.area_mult
	var count = weapon_manager.get_projectile_count(w.type)
	var base_dir = player.direction if player.direction.length() > 0 else Vector2.DOWN
	var speed = player.velocity.length()
	var move_dmg_mult = 1.0 + min(speed / 300.0, 1.0)
	for i in range(count):
		var offset = (i - (count - 1) / 2.0) * 0.2
		var dir = base_dir.rotated(offset)
		var p = Area2D.new()
		p.collision_mask = 4
		var s = CollisionShape2D.new()
		var c = CircleShape2D.new()
		c.radius = area
		s.shape = c
		p.add_child(s)
		var vis = weapon_manager._make_emoji_node("❄️", max(area * 1.2, 12.0))
		p.add_child(vis)
		p.global_position = player.global_position + dir * 20
		p.set_meta("move_mult", move_dmg_mult)
		player.get_parent().add_child(p)
		p.body_entered.connect(_on_glass_hit.bind(p, dmg, move_dmg_mult, player))
		var mover = Node2D.new()
		mover.set_script(weapon_manager._proj_mover_script)
		var spd = w.speed * player.speed_mult
		mover.set_movement(dir * spd, 400.0 / max(spd, 1.0))
		p.add_child(mover)

static func _on_glass_hit(body, proj, dmg, move_mult, player):
	if not is_instance_valid(body) or not is_instance_valid(proj):
		return
	var effective_dmg = dmg * move_mult
	if body.has_method("is_frozen") and body.is_frozen():
		effective_dmg *= 2.0
	if body.has_method("take_damage"):
		body.take_damage(effective_dmg, Vector2.ZERO)
	proj.queue_free()
