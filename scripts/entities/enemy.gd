extends CharacterBody2D

signal died

# Enemy data loaded lazily via DataRegistry

# ── Type data (copied from EnemyDefs on init) ──
var enemy_type_id: int = 0
var _type_name: String = "Wraith"
var _color: Color = Color(0.3, 0.4, 0.9)
var _outline_color: Color = Color(0.5, 0.6, 1.0)
var _outline_width: float = 1.5
var _shape: String = "circle"
var _behavior: String = "chase"
var _knockback_resist: float = 0.0
var _is_boss: bool = false
var _drop_xp_mult: float = 1.0
var _drop_gold_chance: float = 0.0
var _drop_chest_chance: float = 0.0
var is_wave_enemy: bool = false

# ── Resistances (从 EnemyDefs 复制) ──
var _freeze_resist: float = 0.0
var _instant_kill_resistant: bool = false
var _debuff_resistant: bool = false

# ── Special flags (从 EnemyDefs 复制) ──
var _has_hp_x_level: bool = false
var _has_three_lives: bool = false
var _is_fixed_direction: bool = false
var _ignores_collision: bool = false
var _is_self_destruct: bool = false

# Knockback resist reduction (replaces meta for perf)
var _kb_resist_reduce: float = 0.0
var _kb_resist_reduce_timer: float = 0.0
var _dmg_text_skip: int = 0
var _cached_velocity: Vector2 = Vector2.ZERO
# Fixed direction for bat_swarm / flower_wall
var _fixed_dir: Vector2 = Vector2.ZERO
var _has_fixed_dir: bool = false
# Enemy collision flag
var _has_enemy_collision: bool = false
var _cached_camera: Camera2D = null
var _init_collision_mask: int = 0

# ── Three-lives state ──
var _lives_remaining: int = 1

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

# ── Wavy movement state ──
var _wavy_time: float = 0.0

# Visibility culling — skip AI processing for distant enemies
var CULL_DIST_SQ: float = 1000.0 * 1000.0  # ~1000px max processing range
var MID_DIST_SQ: float = 500.0 * 500.0        # ~500px: skip physics, direct position move
var _culled: bool = false

# ── Freeze state ──
var _frozen: bool = false
var _freeze_timer: float = 0.0

# ── Debuff state (Mannajja slow / Garlic debuff) ──
var _debuff_slow: float = 0.0      # slow multiplier (0.0 = no slow, 0.5 = half speed)
var _debuff_timer: float = 0.0


# ── Helper: read current stage mods from GameState (single source of truth) ──
func _get_speed_mod() -> float:
	return game_state.stage_enemy_speed_mod if game_state else 1.0


func _get_curse_level() -> int:
	return game_state.curse_level if game_state else 0


# 获取相机视野矩形（用于 Boss 传送回屏幕）
func _get_camera_bounds() -> Rect2:
	if _cached_camera == null:
		_cached_camera = get_viewport().get_camera_2d() if is_inside_tree() else null
	var cam = _cached_camera
	if not cam:
		return Rect2()
	var vp = get_viewport().get_visible_rect().size
	var cam_pos = cam.global_position
	var half_w = vp.x * 0.5 / cam.zoom.x
	var half_h = vp.y * 0.5 / cam.zoom.y
	return Rect2(cam_pos.x - half_w, cam_pos.y - half_h, half_w * 2, half_h * 2)

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
	var t = DataRegistry.enemies().get_type(type_id)
	_copy_type_data(t)
	_scale_difficulty(diff, t)
	_init_collision_mask = CollisionLayers.ENEMY if (_has_enemy_collision and not _ignores_collision) else 0
	collision_mask = _init_collision_mask
	if game_state:
		var scale = game_state.map_scale
		CULL_DIST_SQ = (1000.0 * scale) ** 2
		MID_DIST_SQ = (500.0 * scale) ** 2


func _copy_type_data(t):
	_type_name = t.name
	_color = t.color
	_outline_color = t.outline_color
	_outline_width = t.outline_width
	_shape = t.shape
	_behavior = t.behavior
	_knockback_resist = t.knockback_resist
	_drop_xp_mult = t.drop_xp_mult
	_drop_gold_chance = t.drop_gold_chance
	_drop_chest_chance = t.drop_chest_chance

	# Resistances
	_freeze_resist = t.freeze_resist
	_instant_kill_resistant = t.instant_kill_resistant
	_debuff_resistant = t.debuff_resistant

	# Special flags
	_has_hp_x_level = t.has_hp_x_level
	_has_three_lives = t.has_three_lives
	_is_fixed_direction = t.is_fixed_direction
	_ignores_collision = t.ignores_collision
	_is_self_destruct = t.is_self_destruct
	_lives_remaining = 3 if t.has_three_lives else 1


func _scale_difficulty(diff: float, t):
	var diff_factor = (diff - 1.0)
	var curse_level = _get_curse_level()
	
	# 使用 GameState 的集中公式计算
	health = GameState.calc_enemy_hp(t.base_health, diff_factor, curse_level)
	max_health = health
	contact_damage = GameState.calc_enemy_damage(t.base_damage, diff_factor, curse_level)
	move_speed = GameState.calc_enemy_speed(t.base_speed, diff_factor, curse_level)
	
	# Size scaling — fixed to base size, no difficulty growth
	scale = Vector2(t.base_size, t.base_size)
	# Reduced XP per kill to slow leveling
	xp_value = t.base_xp + int(diff_factor * 3 * t.drop_xp_mult)
	
	

	if _is_boss:
		health *= 3.0
		max_health = health
	# ═══ HP x Level: 生成时按玩家等级乘算血量（对齐 VS Wiki）═══
	if _has_hp_x_level and is_instance_valid(player):
		var lv_factor = max(player.level, 1)
		health *= lv_factor
		max_health = health


# Public — kept for backward compat; delegates to set_enemy_type(0, diff)
func scale_difficulty(diff: float):
	set_enemy_type(0, diff)


# ═══════════════════════════════════════════════════════════════════
#  Instant Kill / Debuff API
# ═══════════════════════════════════════════════════════════════════

# 即死攻击（Pentagram / Gorgeous Moon / Rosary）
func instant_kill() -> bool:
	if _instant_kill_resistant:
		return false  # 抵抗即死
	# 直接扣血量到 0
	take_damage(max_health * 10, Vector2.ZERO)
	return true


# 施加 debuff（Garlic 抗性降低 / Mannajja 减速）
# 如果敌人 debuff_resistant，则免疫
func apply_debuff(type: String, value: float, duration: float) -> bool:
	if _debuff_resistant:
		return false
	match type:
		"slow":
			_debuff_slow = max(_debuff_slow, value)
			_debuff_timer = max(_debuff_timer, duration)
		"knockback_resist_reduce":
			# 暂时降低击退抗性
			_knockback_resist = max(0.0, _knockback_resist - value)
			_kb_resist_reduce = value
			_kb_resist_reduce_timer = duration
		_:
			return false
	return true


func _physics_process(delta):
	if health <= 0 or not is_instance_valid(player):
		return
	var player_pos = player.global_position
	if _frozen:
		_freeze_timer -= delta
		if _freeze_timer <= 0:
			_frozen = false
		if knockback_velocity.length_squared() > 0.0:
			knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta * 60.0)
			velocity = knockback_velocity
			move_and_slide()
		return

	# Debuff timer decay
	if _debuff_timer > 0:
		_debuff_timer -= delta
		if _debuff_timer <= 0:
			_debuff_slow = 0.0
	# Knockback resist reduction timer
	if _kb_resist_reduce_timer > 0.0:
		_kb_resist_reduce_timer -= delta
		if _kb_resist_reduce_timer <= 0.0:
			_knockback_resist = min(1.0, _knockback_resist + _kb_resist_reduce)
			_kb_resist_reduce = 0.0

	# Visibility culling: skip full AI for distant enemies
	var dist_sq = global_position.distance_squared_to(player_pos)
	if dist_sq > CULL_DIST_SQ:
		if not _culled:
			_culled = true
			collision_layer = 0
			collision_mask = 0
		# ═══ Boss: 不因远离消失，传回屏幕（对齐 VS Wiki）═══
		if _is_boss:
			_culled = false
			collision_layer = CollisionLayers.ENEMY
			collision_mask = 0
			# 传回玩家附近
			var bounds = _get_camera_bounds()
			if bounds != Rect2():
				var margin = 60.0
				var side = randi() % 4
				match side:
					0: global_position = Vector2(randf_range(bounds.position.x + margin, bounds.position.x + bounds.size.x - margin), bounds.position.y - margin)
					1: global_position = Vector2(randf_range(bounds.position.x + margin, bounds.position.x + bounds.size.x - margin), bounds.position.y + bounds.size.y + margin)
					2: global_position = Vector2(bounds.position.x - margin, randf_range(bounds.position.y + margin, bounds.position.y + bounds.size.y - margin))
					3: global_position = Vector2(bounds.position.x + bounds.size.x + margin, randf_range(bounds.position.y + margin, bounds.position.y + bounds.size.y - margin))
				velocity = Vector2.ZERO
				move_and_slide()
				return
		# Throttle culled enemies to every 4th frame — they're far offscreen
		if (get_instance_id() + Engine.get_physics_frames()) % 4 != 0:
			return
		var dir = (player_pos - global_position).normalized()
		global_position += dir * move_speed * 0.3 * delta
		return
	elif _culled:
		_culled = false
		collision_layer = CollisionLayers.ENEMY
		collision_mask = _init_collision_mask

	# 跳过物理引擎：中距敌人 或 全场拥挤时非Boss敌人
	var _skip_physics = dist_sq > MID_DIST_SQ or (EnemyRegistry and EnemyRegistry.is_crowded and not _is_boss)

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

	# ── Frame staggering: 每敌人每 3 帧才跑完整 AI ──
	var phys_frame = Engine.get_physics_frames()
	var my_turn = (get_instance_id() + phys_frame) % 3 == 0

	# Stationary enemies (Il Molise override)
	var speed_mod = _get_speed_mod()
	if speed_mod <= 0.0:
		velocity = knockback_velocity
		if _skip_physics:
			global_position += velocity * delta
		else:
			move_and_slide()
		return

	if not my_turn:
		velocity = _cached_velocity + knockback_velocity
		if _skip_physics:
			global_position += velocity * delta
		else:
			move_and_slide()
		return

	# 应用 debuff 减速
	var effective_speed_mod = speed_mod
	if _debuff_slow > 0.0:
		effective_speed_mod = speed_mod * (1.0 - _debuff_slow)

	# Behavior dispatch
	match _behavior:
		"wavy":
			if _is_fixed_direction:
				_behavior_fixed_wavy(delta, effective_speed_mod)
			else:
				_behavior_wavy(delta, effective_speed_mod, player_pos)
		"stationary":
			_behavior_stationary(delta)
		_:
			if _is_fixed_direction:
				_behavior_fixed_chase(delta, effective_speed_mod, player_pos)
			else:
				_behavior_chase(delta, effective_speed_mod, player_pos)

	_cached_velocity = velocity
	velocity += knockback_velocity
	if _skip_physics:
		global_position += velocity * delta
	else:
		move_and_slide()


func _behavior_chase(_delta: float, speed_mod: float = 1.0, player_pos: Vector2 = Vector2.ZERO):
	var dir = (player_pos - global_position).normalized()
	velocity = dir * move_speed * speed_mod


# Fixed Direction: 直线移动（初始方向固定）
func _behavior_fixed_chase(_delta: float, speed_mod: float = 1.0, player_pos: Vector2 = Vector2.ZERO):
	# 首次运行时记录初始方向
	if not _has_fixed_dir:
		_fixed_dir = (player_pos - global_position).normalized()
		_has_fixed_dir = true
	velocity = _fixed_dir * move_speed * speed_mod


func _behavior_wavy(delta: float, speed_mod: float = 1.0, player_pos: Vector2 = Vector2.ZERO):
	var dir = (player_pos - global_position).normalized()
	var perp = dir.rotated(PI / 2.0)
	_wavy_time += delta
	var wave_amp = 60.0 * speed_mod
	var wave = perp * sin(_wavy_time * 4.0) * wave_amp
	velocity = dir * move_speed * speed_mod + wave


# Fixed Direction + Wavy: 直线移动 + 波形偏移
func _behavior_fixed_wavy(delta: float, speed_mod: float = 1.0):
	if not _has_fixed_dir:
		_fixed_dir = Vector2.DOWN
		_has_fixed_dir = true
	var dir = _fixed_dir
	var perp = dir.rotated(PI / 2.0)
	_wavy_time += delta
	var wave_amp = 60.0 * speed_mod
	var wave = perp * sin(_wavy_time * 4.0) * wave_amp
	velocity = dir * move_speed * speed_mod + wave


func _behavior_stationary(_delta: float):
	velocity = Vector2.ZERO


func take_damage(amount: float, source_pos: Vector2 = Vector2.ZERO):
	health -= amount
	hit_flash_time = 0.08
	# Use modulate for hit flash — cheaper than queue_redraw every frame
	modulate = Color(3.0, 3.0, 3.0, 1.0)
	
	# Knockback
	if source_pos != Vector2.ZERO and _knockback_resist < 1.0:
		var kb_dir = (global_position - source_pos).normalized()
		knockback_velocity = kb_dir * KNOCKBACK_STRENGTH * (1.0 - _knockback_resist)
	
	# Floating damage number — throttle to every 3rd hit for perf
	_dmg_text_skip += 1
	if _dmg_text_skip % 3 == 0 and is_inside_tree() and ObjectPoolManager:
		ObjectPoolManager.spawn_ft(get_parent(), global_position + Vector2(randf_range(-8, 8), -10), str(int(amount)), Color(1, 0.9, 0.6), 16 + mini(int(amount) / 10, 14))
	
	if health <= 0:
		die()


func freeze(duration: float):
	# Freeze resistance: 如果抵抗值高于 0, 只有武器 freeze_chance > resist 才生效
	# Orologion (5s freeze) 无视抗性
	if _freeze_resist > 0 and duration < 5.0:
		# 如果 duration < 5s（非 Orologion），按抗性衰减
		var effective_duration = duration * (1.0 - _freeze_resist)
		if effective_duration <= 0.1:
			return  # 完全免疫
		duration = effective_duration
	_frozen = true
	_freeze_timer = duration


func die():
	# ═══ Three Lives: 复活两次后再真正死亡 ═══
	if _has_three_lives and _lives_remaining > 1:
		_lives_remaining -= 1
		# 复活：恢复 100% HP，重置冰冻和减速
		health = max_health
		_frozen = false
		_debuff_slow = 0.0
		_debuff_timer = 0.0
		hit_flash_time = 0.0
		modulate = Color(1.0, 1.0, 1.0, 1.0)
		# 复活视觉反馈
		if is_inside_tree() and ObjectPoolManager:
			ObjectPoolManager.spawn_ft(get_parent(),
				global_position + Vector2(randf_range(-10, 10), -20),
				"✧ REVIVE ✧", Color(0.5, 0.8, 1.0), 18)
		AudioManager.play_sfx("enemy_revive")
		return

	# ═══ Self-destruct: 死亡时爆炸 ═══
	if _is_self_destruct and is_inside_tree():
		_explode()

	died.emit()
	if EnemyRegistry:
		EnemyRegistry.unregister(self)
	queue_free()


func _explode():
	# 自爆：对附近敌人和玩家造成伤害
	if not is_inside_tree():
		return
	var radius = 60.0 * scale.x
	var dmg = contact_damage * 2.0
	# 伤害范围内的敌人
	var enemies = EnemyRegistry.get_all() if EnemyRegistry else []
	for e in enemies:
		if not is_instance_valid(e) or e == self:
			continue
		if global_position.distance_to(e.global_position) < radius:
			if e.has_method("take_damage"):
				e.take_damage(dmg, Vector2.ZERO)
	# 伤害玩家
	if is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < radius:
			var dmg_to_player = dmg * 0.3  # 对玩家衰减
			if player.has_method("take_damage_direct"):
				player.take_damage_direct(dmg_to_player)
			elif player.has_method("_on_hurt"):
				player._on_hurt(self)
	# 爆炸视觉
	_spawn_explosion_fx(radius, Color(0.9, 0.4, 0.05))
	AudioManager.play_sfx("explosion")


func _spawn_explosion_fx(radius: float, color: Color):
	# 简易爆炸效果
	var explosion = Node2D.new()
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	
	var circle = ColorRect.new()
	circle.color = color
	circle.size = Vector2(radius * 2, radius * 2)
	circle.position = Vector2(-radius, -radius)
	circle.material = null
	explosion.add_child(circle)
	
	var tw = create_tween()
	tw.tween_property(circle, "modulate:a", 0.0, 0.3).from(0.6)
	tw.parallel().tween_property(circle, "scale", Vector2(0.3, 0.3), 0.3).from(Vector2(1.0, 1.0))
	var exp_id = explosion.get_instance_id()
	tw.finished.connect(func():
		var exp = instance_from_id(exp_id)
		if exp:
			exp.queue_free()
	)


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
	
	# Clean up burst node (safe via instance_from_id)
	var burst_id = burst.get_instance_id()
	var clean = create_tween()
	clean.tween_interval(0.4)
	clean.finished.connect(func():
		var b = instance_from_id(burst_id)
		if b:
			b.queue_free()
	)


func get_contact_damage() -> float:
	return contact_damage


func set_as_boss():
	if _is_boss:
		return
	_is_boss = true
	# 通知 EnemyRegistry 更新 Boss 计数（wave boss spawn 后调用）
	if EnemyRegistry and is_inside_tree():
		EnemyRegistry._boss_count += 1
		EnemyRegistry.boss_count_changed.emit(EnemyRegistry._boss_count)


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
	
	# Boss flair removed for performance


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
