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

# ── Runtime stats (scaled from base) ──
var player: Node2D
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

# ── Scene references ──
var _proj_scene = preload("res://scenes/enemy_projectile.tscn")
var _ft_scene = preload("res://scenes/floating_text.tscn")

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
	# Quadratic scaling: late game gets noticeably harder
	var diff_factor = (diff - 1.0)
	var diff_sq = diff_factor * diff_factor
	health = t.base_health * (1.0 + diff_factor * 0.3 + diff_sq * 0.015)
	max_health = health
	contact_damage = t.base_damage * (1.0 + diff_factor * 0.2 + diff_sq * 0.01)
	move_speed = t.base_speed * (1.0 + diff_factor * 0.05)
	# Size scaling
	var s = t.base_size * (1.0 + (diff - 1.0) * 0.08)
	scale = Vector2(s, s)
	xp_value = t.base_xp + int((diff - 1.0) * 4 * t.drop_xp_mult)
	
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
	
	# Hit flash timer
	if hit_flash_time > 0:
		hit_flash_time -= delta
		queue_redraw()
	
	# Knockback decay
	if knockback_velocity.length_squared() > 0.0:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta * 60.0)
		if knockback_velocity.length_squared() < 1.0:
			knockback_velocity = Vector2.ZERO
	
	# Stationary enemies (Il Molise override)
	var spd_mod = Engine.get_meta("stage_enemy_speed_mod", 1.0)
	if spd_mod <= 0.0:
		velocity = Vector2.ZERO + knockback_velocity
		move_and_slide()
		# Still do ranged attack
		_update_ranged(delta)
		return
	
	# Behavior dispatch
	match _behavior:
		"wavy":
			_behavior_wavy(delta)
		"stationary":
			_behavior_stationary(delta)
		_:
			_behavior_chase(delta)
	
	# Apply knockback on top
	velocity += knockback_velocity
	move_and_slide()
	
	# Ranged attack update
	_update_ranged(delta)


func _behavior_chase(_delta: float):
	var spd_mod = Engine.get_meta("stage_enemy_speed_mod", 1.0)
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * move_speed * spd_mod


func _behavior_wavy(delta: float):
	var spd_mod = Engine.get_meta("stage_enemy_speed_mod", 1.0)
	var dir = (player.global_position - global_position).normalized()
	var perp = dir.rotated(PI / 2.0)
	_wavy_time += delta
	var wave_amp = 60.0 * spd_mod
	var wave = perp * sin(_wavy_time * 4.0) * wave_amp
	velocity = dir * move_speed * spd_mod + wave


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
	var proj = _proj_scene.instantiate()
	proj.global_position = global_position
	proj.target = player
	proj.speed = _ranged_speed
	proj.damage = contact_damage * _ranged_dmg_mult
	get_parent().add_child(proj)
	AudioManager.play_sfx("enemy_shoot")


func take_damage(amount: float, source_pos: Vector2 = Vector2.ZERO):
	health -= amount
	hit_flash_time = 0.08
	queue_redraw()
	
	# Knockback
	if source_pos != Vector2.ZERO and _knockback_resist < 1.0:
		var kb_dir = (global_position - source_pos).normalized()
		knockback_velocity = kb_dir * KNOCKBACK_STRENGTH * (1.0 - _knockback_resist)
	
	# Floating damage number
	var ft = _ft_scene.instantiate()
	ft.display_text = str(int(amount))
	ft.text_color = Color(1, 0.9, 0.6)
	ft.font_size = 16 + mini(int(amount) / 10, 14)
	ft.global_position = global_position + Vector2(randf_range(-8, 8), -10)
	if is_inside_tree():
		get_parent().add_child(ft)
	
	if health <= 0:
		die()


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
	
	# Hit flash overlay
	if hit_flash_time > 0:
		var alpha = min(hit_flash_time * 12, 0.9)
		if _shape == "circle":
			draw_circle(Vector2.ZERO, r, Color(1, 1, 1, alpha))
		else:
			draw_circle(Vector2.ZERO, r * 0.6, Color(1, 1, 1, alpha * 0.6))
	
	# Health arc (only show when damaged)
	if health < max_health and not _is_boss:
		var pct = max(health / max_health, 0.0)
		var arc_color = Color(0.1, 0.8, 0.1)
		if pct < 0.3:
			arc_color = Color(0.9, 0.2, 0.1)
		elif pct < 0.6:
			arc_color = Color(0.9, 0.7, 0.1)
		draw_arc(Vector2.ZERO, r + 3, -PI / 2, -PI / 2 + PI * 2 * pct, 12, arc_color, 2.0)
	
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
	
	# Boss health bar (always visible)
	var bar_w = r * 2.0 + 20.0
	var bar_h = 4.0
	var bar_y = -r - 18.0
	var pct = max(health / max_health, 0.0)
	# Background
	draw_rect(Rect2(-bar_w / 2.0, bar_y, bar_w, bar_h), Color(0.2, 0.05, 0.05, 0.8))
	# Fill
	var fill_col = Color(0.1, 0.8, 0.1)
	if pct < 0.3:
		fill_col = Color(0.9, 0.15, 0.05)
	elif pct < 0.6:
		fill_col = Color(0.9, 0.7, 0.1)
	draw_rect(Rect2(-bar_w / 2.0, bar_y, bar_w * pct, bar_h), fill_col)
	# Name (i18n)
	var name_col = Color(1, 0.9, 0.9, 0.6)
	_draw_string_centered(Vector2(0, bar_y - 2), I18N.t("enemy." + str(enemy_type_id) + "_name", _type_name), name_col, 10)


func _draw_string_centered(pos: Vector2, text: String, col: Color, sz: int):
	var font = ThemeDB.fallback_font
	if not font:
		return
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, sz)
	var draw_pos = Vector2(pos.x - text_size.x / 2.0, pos.y + sz * 0.35)
	draw_string(font, draw_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
