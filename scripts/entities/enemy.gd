extends CharacterBody2D

signal died

const EnemyDefs = preload("res://scripts/data/enemy_defs.gd")

# ── Type data (copied from EnemyDefs on init) ──
var enemy_type_id: int = 0
var _type_name: String = "Wraith"
var _color: Color = Color(0.3, 0.4, 0.9)
var _outline_color: Color = Color(0.5, 0.6, 1.0)
var _outline_width: float = 1.5
var _shape: String = "circle"
var _behavior: String = "chase"
var _has_ranged: bool = false
var _ranged_cooldown: float = 0.0
var _ranged_speed: float = 0.0
var _ranged_dmg_mult: float = 0.0
var _knockback_resist: float = 0.0
var _is_boss: bool = false
var _drop_xp_mult: float = 1.0
var _drop_gold_chance: float = 0.0
var _drop_chest_chance: float = 0.0
var is_wave_enemy: bool = false

# ── Runtime stats (scaled from base) ──
var player: Node2D
var game_state: Node = null
var move_speed: float = 60.0
var health: float = 20.0
var max_health: float = 20.0
var contact_damage: float = 10.0
var xp_value: int = 2
var hit_flash_time: float = 0.0

# ── Knockback ──
var knockback_velocity: Vector2 = Vector2.ZERO
const KNOCKBACK_DECAY: float = 6.0   # how fast knockback fades
const KNOCKBACK_STRENGTH: float = 300.0  # base push pixels

# ── Ranged attack state ──
var _ranged_timer: float = 0.0

# ── Wavy movement state ──
var _wavy_time: float = 0.0

# Visibility culling — skip AI processing for distant enemies
const CULL_DIST_SQ: float = 1000.0 * 1000.0  # ~1000px max processing range
var _culled: bool = false

# ── Freeze state (Orologion pickup) ──
var _frozen: bool = false
var _freeze_timer: float = 0.0


# ── Helper: read current stage mods from GameState (single source of truth) ──
func _get_speed_mod() -> float:
	return game_state.stage_enemy_speed_mod if game_state else 1.0


func _get_curse_level() -> int:
	return game_state.curse_level if game_state else 0

# ── Scene references ──
var _proj_scene = preload("res://scenes/enemy_projectile.tscn")

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


const CollisionLayers = preload("res://scripts/data/collision_layers.gd")


func _ready():
	collision_layer = CollisionLayers.ENEMY
	collision_mask = 0
	add_to_group("enemies")
	if EnemyRegistry:
		EnemyRegistry.register(self)


# Call BEFORE add_child. Loads type data and applies difficulty scaling.
func set_enemy_type(type_id: int, diff: float):
	enemy_type_id = type_id
	_copy_type_data()
	_scale_difficulty(diff)


func _copy_type_data():
	var t = EnemyDefs.get_type(enemy_type_id)
	_type_name = t.name
	_color = t.color
	_outline_color = t.outline_color
	_outline_width = t.outline_width
	_shape = t.shape
	_behavior = t.behavior
	_has_ranged = t.has_ranged
	_ranged_cooldown = t.ranged_cooldown
	_ranged_speed = t.ranged_speed
	_ranged_dmg_mult = t.ranged_dmg_mult
	_knockback_resist = t.knockback_resist
	_is_boss = t.is_boss
	_drop_xp_mult = t.drop_xp_mult
	_drop_gold_chance = t.drop_gold_chance
	_drop_chest_chance = t.drop_chest_chance


func _scale_difficulty(diff: float):
	var t = EnemyDefs.get_type(enemy_type_id)
	# Base stats from type
	# Quadratic scaling: steeper curve to challenge maxed-out players
	# At 7min (diff=8):  HP = base * (1 + 7*0.2 + 49*0.015) = base * (1 + 1.4 + 0.74) ≈ 3.1x
	# At 15min (diff=16): HP = base * (1 + 15*0.2 + 225*0.015) = base * (1 + 3.0 + 3.38) ≈ 7.4x
	# At 30min (diff=31): HP = base * (1 + 30*0.2 + 900*0.015) = base * (1 + 6.0 + 13.5) ≈ 20.5x
	var diff_factor = (diff - 1.0)
	var diff_sq = diff_factor * diff_factor
	health = t.base_health * (1.0 + diff_factor * 0.2 + diff_sq * 0.015)
	max_health = health
	contact_damage = t.base_damage * (1.0 + diff_factor * 0.08)
	move_speed = t.base_speed * (1.0 + diff_factor * 0.08)
	# Size scaling — fixed to base size, no difficulty growth
	var s = t.base_size
	scale = Vector2(s, s)
	# Reduced XP per kill to slow leveling
	xp_value = t.base_xp + int((diff - 1.0) * 3 * t.drop_xp_mult)
	
	# ── Cursed Time: additional stacking penalty ──
	var curse_level = _get_curse_level()
	if curse_level > 0:
		var curse_factor = curse_level * 0.15  # 15% per curse level
		health *= (1.0 + curse_factor)
		contact_damage *= (1.0 + curse_factor * 0.75)
		move_speed *= (1.0 + curse_factor * 0.5)
	
	# Bosses get extra HP multiplier
	if _is_boss:
		health *= 3.0
		max_health = health


# Public — kept for backward compat; delegates to set_enemy_type(0, diff)
func scale_difficulty(diff: float):
	set_enemy_type(0, diff)


func _physics_process(delta):
	if health <= 0 or not is_instance_valid(player):
		return
	if _frozen:
		_freeze_timer -= delta
		if _freeze_timer <= 0:
			_frozen = false
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta * 60.0)
		velocity = knockback_velocity
		move_and_slide()
		return

	# Visibility culling: skip full AI for distant enemies
	var dist_sq = global_position.distance_squared_to(player.global_position)
	if dist_sq > CULL_DIST_SQ:
		if not _culled:
			_culled = true
			collision_layer = 0
			collision_mask = 0
		# Throttle culled enemies to every 4th frame — they're far offscreen
		if Engine.get_frames_drawn() % 4 != 0:
			return
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * move_speed * 0.3
		move_and_slide()
		return
	elif _culled:
		_culled = false
		collision_layer = CollisionLayers.ENEMY
		collision_mask = 0

	# Hit flash — use modulate which is GPU-side
	if hit_flash_time > 0:
		hit_flash_time -= delta
		if hit_flash_time <= 0:
			modulate = Color(1.0, 1.0, 1.0, 1.0)

	# Knockback decay
	if knockback_velocity.length_squared() > 0.0:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta * 60.0)
		if knockback_velocity.length_squared() < 1.0:
			knockback_velocity = Vector2.ZERO

	# Stationary enemies (Il Molise override)
	var speed_mod = _get_speed_mod()
	if speed_mod <= 0.0:
		velocity = Vector2.ZERO + knockback_velocity
		move_and_slide()
		_update_ranged(delta)
		return

	# Behavior dispatch
	match _behavior:
		"wavy":
			_behavior_wavy(delta, speed_mod)
		"stationary":
			_behavior_stationary(delta)
		_:
			_behavior_chase(delta, speed_mod)

	# Apply knockback on top
	velocity += knockback_velocity
	move_and_slide()

	# Ranged attack update
	_update_ranged(delta)


func _behavior_chase(_delta: float, speed_mod: float = 1.0):
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * move_speed * speed_mod


func _behavior_wavy(delta: float, speed_mod: float = 1.0):
	var dir = (player.global_position - global_position).normalized()
	var perp = dir.rotated(PI / 2.0)
	_wavy_time += delta
	var wave_amp = 60.0 * speed_mod
	var wave = perp * sin(_wavy_time * 4.0) * wave_amp
	velocity = dir * move_speed * speed_mod + wave


func _behavior_stationary(_delta: float):
	# Don't move; ranged attack handled by _update_ranged
	velocity = Vector2.ZERO


func _update_ranged(delta: float):
	if not _has_ranged or not is_instance_valid(player):
		return
	_ranged_timer -= delta
	if _ranged_timer <= 0.0:
		_ranged_timer = _ranged_cooldown
		_fire_projectile()


func _fire_projectile():
	if not is_instance_valid(player) or not is_inside_tree():
		return
	# Cursed Time: extra projectiles per volley
	var extra_shots = _get_curse_level() / 5  # +1 projectile every 5 curse levels
	
	var shot_count = 1 + extra_shots
	for s in range(shot_count):
		if ObjectPoolManager:
			var proj = ObjectPoolManager.borrow_enemy_proj(player, _ranged_speed, contact_damage * _ranged_dmg_mult, 4.0)
			proj.global_position = global_position
			if s > 0:
				# Spread extra projectiles slightly
				proj.global_position += Vector2(randf_range(-20, 20), randf_range(-20, 20))
			get_parent().add_child(proj)
		else:
			var proj = _proj_scene.instantiate()
			proj.global_position = global_position
			if s > 0:
				proj.global_position += Vector2(randf_range(-20, 20), randf_range(-20, 20))
			proj.target = player
			proj.speed = _ranged_speed
			proj.damage = contact_damage * _ranged_dmg_mult
			get_parent().add_child(proj)
	AudioManager.play_sfx("enemy_shoot")


func take_damage(amount: float, source_pos: Vector2 = Vector2.ZERO):
	health -= amount
	hit_flash_time = 0.08
	# Use modulate for hit flash — cheaper than queue_redraw every frame
	modulate = Color(3.0, 3.0, 3.0, 1.0)
	
	# Knockback
	if source_pos != Vector2.ZERO and _knockback_resist < 1.0:
		var kb_dir = (global_position - source_pos).normalized()
		knockback_velocity = kb_dir * KNOCKBACK_STRENGTH * (1.0 - _knockback_resist)
	
	# Floating damage number (via pooled system)
	if is_inside_tree() and ObjectPoolManager:
		ObjectPoolManager.spawn_ft(get_parent(), global_position + Vector2(randf_range(-8, 8), -10), str(int(amount)), Color(1, 0.9, 0.6), 16 + mini(int(amount) / 10, 14))
	
	if health <= 0:
		die()


func freeze(duration: float):
	_frozen = true
	_freeze_timer = duration


func die():
	died.emit()
	if EnemyRegistry:
		EnemyRegistry.unregister(self)
	queue_free()


func _spawn_death_burst():
	if not is_inside_tree():
		return
	# Create a burst of colored particles flying outward
	var count = 8
	var burst = Node2D.new()
	burst.global_position = global_position
	get_parent().add_child(burst)
	
	for i in range(count):
		var angle = (TAU / count) * i + randf_range(-0.2, 0.2)
		var dist = randf_range(20, 40)
		var sz = randf_range(4, 8)
		var p = ColorRect.new()
		p.color = _color * randf_range(0.8, 1.2)
		p.size = Vector2(sz, sz)
		p.position = Vector2(-sz/2, -sz/2)
		burst.add_child(p)
		
		# Tween outward and fade
		var tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "position", Vector2(cos(angle), sin(angle)) * dist, 0.3)
		tw.tween_property(p, "modulate", Color(1, 1, 1, 0), 0.3)
	
	# Clean up burst node
	var clean = create_tween()
	clean.tween_interval(0.4)
	clean.finished.connect(burst.queue_free)


func get_contact_damage() -> float:
	return contact_damage


func get_is_boss() -> bool:
	return _is_boss


# ── Drawing ──

func _draw():
	var r = 14.0  # base radius; scale transform handles per-type sizing
	
	match _shape:
		"triangle":
			_draw_triangle(r)
		"diamond":
			_draw_diamond(r)
		"hexagon":
			_draw_hexagon(r)
		_:
			_draw_circle_style(r)
	
	# Hit flash removed — handled via modulate in _physics_process
	
	# Health bar removed for performance
	
	# Boss: extra health bar + aura
	if _is_boss:
		_draw_boss_flair(r)


func _draw_circle_style(r: float):
	draw_circle(Vector2.ZERO, r, _color)
	draw_circle(Vector2.ZERO, r, _outline_color, false, _outline_width)


func _draw_triangle(r: float):
	# Point toward player direction if valid, else point up
	var angle = -PI / 2.0
	if is_instance_valid(player):
		angle = (player.global_position - global_position).angle()
	var pts = PackedVector2Array()
	for i in range(3):
		var a = angle + float(i) * TAU / 3.0 - PI / 2.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	draw_polygon(pts, [_color])
	# Outline
	for i in range(3):
		var n = (i + 1) % 3
		draw_line(pts[i], pts[n], _outline_color, _outline_width)


func _draw_diamond(r: float):
	var pts = PackedVector2Array([
		Vector2(0, -r), Vector2(r * 0.7, 0),
		Vector2(0, r), Vector2(-r * 0.7, 0)
	])
	draw_polygon(pts, [_color])
	draw_line(pts[0], pts[1], _outline_color, _outline_width)
	draw_line(pts[1], pts[2], _outline_color, _outline_width)
	draw_line(pts[2], pts[3], _outline_color, _outline_width)
	draw_line(pts[3], pts[0], _outline_color, _outline_width)


func _draw_hexagon(r: float):
	var pts = PackedVector2Array()
	for i in range(6):
		var a = float(i) * TAU / 6.0 - PI / 2.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	draw_polygon(pts, [_color])
	for i in range(6):
		var n = (i + 1) % 6
		draw_line(pts[i], pts[n], _outline_color, _outline_width)


func _draw_boss_flair(r: float):
	# Aura ring — pulsing
	var pulse = 0.5 + sin(Time.get_ticks_msec() * 0.003) * 0.15
	var aura_r = r + 8.0 + pulse * 4.0
	var aura_col = Color(0.6, 0.05, 0.05, 0.25 + pulse * 0.15)
	draw_circle(Vector2.ZERO, aura_r, aura_col)
	draw_circle(Vector2.ZERO, aura_r, Color(0.8, 0.1, 0.1, 0.4), false, 2.0)
	
	# Crown-like spikes
	var spike_count = 8
	var spike_len = r * 0.35
	for i in range(spike_count):
		var a = float(i) * TAU / spike_count + Time.get_ticks_msec() * 0.001
		var inner = Vector2(cos(a), sin(a)) * (r + 2)
		var outer = Vector2(cos(a), sin(a)) * (r + 2 + spike_len)
		draw_line(inner, outer, Color(0.8, 0.15, 0.15, 0.7), 2.0)
	
	# Boss health bar removed for performance
	# Name (i18n)
	var name_col = Color(1, 0.9, 0.9, 0.6)
	_draw_string_centered(Vector2(0, -r - 16), I18N.t("enemy." + str(enemy_type_id) + "_name", _type_name), name_col, 10)


func _draw_string_centered(pos: Vector2, text: String, col: Color, sz: int):
	var font = ThemeDB.fallback_font
	if not font:
		return
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, sz)
	var draw_pos = Vector2(pos.x - text_size.x / 2.0, pos.y + sz * 0.35)
	draw_string(font, draw_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
