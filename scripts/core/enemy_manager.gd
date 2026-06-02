extends Node2D
# EnemyManager — data-driven enemy system.
# Replaces all individual enemy CharacterBody2D nodes with array-based state,
# batch processing, and batch rendering.

signal enemy_killed(id: int, type_id: int, pos: Vector2, is_boss: bool, xp_value: int)
signal boss_count_changed(count: int)

const CollisionLayers = preload("res://scripts/data/collision_layers.gd")
const EnemyProxy = preload("res://scripts/entities/enemy/enemy_proxy.gd")

const KNOCKBACK_DECAY: float = 6.0
const KNOCKBACK_STRENGTH: float = 300.0
const CULL_DIST: float = 1000.0
const MID_DIST: float = 500.0
const BASE_RADIUS: float = 14.0

var player: Node2D
var game_state: Node
var camera_ctrl: Node

# ── Entity state arrays (indexed by entity id) ──
var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _cached_vel := PackedVector2Array()
var _kb_vel := PackedVector2Array()
var _fixed_dir := PackedVector2Array()
var _health := PackedFloat32Array()
var _max_health := PackedFloat32Array()
var _scale_arr := PackedFloat32Array()
var _move_speed := PackedFloat32Array()
var _contact_damage := PackedFloat32Array()
var _xp_value := PackedInt32Array()
var _type_id := PackedInt32Array()
var _lives_remaining := PackedInt32Array()
var _wavy_time := PackedFloat32Array()
var _hit_flash := PackedFloat32Array()
var _freeze_timer := PackedFloat32Array()
var _debuff_slow := PackedFloat32Array()
var _debuff_timer := PackedFloat32Array()
var _kb_resist_reduce := PackedFloat32Array()
var _kb_resist_reduce_timer := PackedFloat32Array()
var _knockback_resist := PackedFloat32Array()
var _freeze_resist := PackedFloat32Array()
var _drop_xp_mult := PackedFloat32Array()
var _outline_width := PackedFloat32Array()
var _color := PackedColorArray()
var _outline_color := PackedColorArray()

# Byte-per-entity for compacter flags
var _shape := PackedByteArray()      # 0=circle 1=triangle 2=diamond 3=hexagon
var _behavior := PackedByteArray()   # 0=chase 1=wavy 2=stationary
var _alive := PackedByteArray()
var _dmg_txt_skip := PackedByteArray()

# Bit flags per entity byte: is_boss, instant_kill_resist, debuff_resist,
# has_hp_x_level, has_three_lives, is_fixed_dir, is_self_destruct, frozen, harmless
var _flags := PackedByteArray()
enum Flag { BOSS, IK_RESIST, DEBUFF_RESIST, HP_X_LEVEL, THREE_LIVES, FIXED_DIR, SELF_DESTRUCT, FROZEN, HARMLESS }

# Meta flags byte: is_wave_enemy, is_arcana_boss, culled, has_fixed_dir
var _meta := PackedByteArray()
enum Meta { WAVE_ENEMY, ARCANA_BOSS, CULLED, HAS_FIXED_DIR }

var _free_ids: Array[int] = []
var _alive_count: int = 0
var _boss_count: int = 0

var _proxy_pool: Array[EnemyProxy] = []
var _proxy_pool_idx: int = 0
var _cached_proxies: Array = []
var _proxy_frame: int = -1
var _frame_n: int = 0

# Spatial grid for proximity queries
const GRID_CELL: float = 64.0
var _grid: Dictionary = {}  # Vector2i -> Array[int]
var _grid_frame: int = -1

# MultiMesh rendering — 固定槽位（每个敌人对应固定 mm 实例索引，支持跳帧更新）
const MULTIMESH_CAPACITY = 500
var _mm_slot: PackedInt32Array = []
var _mm_shape: PackedByteArray = []
var _mm_free_slots: Array = [[], [], [], []]
var _mm_next_slot: PackedInt32Array = [0, 0, 0, 0]


func setup(p: Node2D, gs: Node, cam: Node):
	player = p
	game_state = gs
	camera_ctrl = cam
	_init_multimesh()


# ═══════════════════════════════════════════════════════════════════
#  Entity lifecycle
# ═══════════════════════════════════════════════════════════════════

func _alloc() -> int:
	var id: int
	if _free_ids.size() > 0:
		id = _free_ids.pop_back()
	else:
		id = _pos.size()
		_resize(id + 1)
	_alive[id] = 1
	_alive_count += 1
	return id


func _free(id: int):
	if id < 0 or id >= _alive.size() or _alive[id] == 0:
		return
	_alive[id] = 0
	_alive_count -= 1
	_free_ids.append(id)


func _resize(n: int):
	_pos.resize(n); _vel.resize(n); _cached_vel.resize(n); _kb_vel.resize(n)
	_fixed_dir.resize(n); _health.resize(n); _max_health.resize(n)
	_scale_arr.resize(n); _move_speed.resize(n); _contact_damage.resize(n)
	_xp_value.resize(n); _type_id.resize(n); _lives_remaining.resize(n)
	_wavy_time.resize(n); _hit_flash.resize(n); _freeze_timer.resize(n)
	_debuff_slow.resize(n); _debuff_timer.resize(n)
	_kb_resist_reduce.resize(n); _kb_resist_reduce_timer.resize(n)
	var prev = _mm_slot.size()
	_mm_slot.resize(n); _mm_shape.resize(n)
	for i in range(prev, n):
		_mm_slot[i] = -1
	_knockback_resist.resize(n); _freeze_resist.resize(n); _drop_xp_mult.resize(n)
	_outline_width.resize(n); _color.resize(n); _outline_color.resize(n)
	_shape.resize(n); _behavior.resize(n); _alive.resize(n)
	_dmg_txt_skip.resize(n); _flags.resize(n); _meta.resize(n)


# Spawn an enemy by type_id. Returns entity id. If force_boss is true,
# the entity gets the boss flag and x3 HP regardless of type data.
func spawn(type_id: int, pos: Vector2,
		p: Node2D, gs: Node, cam: Node,
		diff: float, force_boss: bool = false) -> int:
	if not game_state:
		setup(p, gs, cam)

	var t = DataRegistry.enemies().get_type(type_id)
	if t == null:
		return -1

	var id = _alloc()
	_pos[id] = pos
	_vel[id] = Vector2.ZERO
	_cached_vel[id] = Vector2.ZERO
	_kb_vel[id] = Vector2.ZERO
	_fixed_dir[id] = Vector2.ZERO
	_type_id[id] = type_id
	_hit_flash[id] = 0.0
	_wavy_time[id] = 0.0
	_freeze_timer[id] = 0.0
	_debuff_slow[id] = 0.0
	_debuff_timer[id] = 0.0
	_kb_resist_reduce[id] = 0.0
	_kb_resist_reduce_timer[id] = 0.0
	_dmg_txt_skip[id] = 0
	_scale_arr[id] = t.base_size

	# Copy type data
	_color[id] = t.color
	_outline_color[id] = t.outline_color
	_outline_width[id] = t.outline_width
	_shape[id] = _shape_to_byte(t.shape)
	_behavior[id] = _behavior_to_byte(t.behavior)
	_knockback_resist[id] = t.knockback_resist
	_drop_xp_mult[id] = t.drop_xp_mult
	_freeze_resist[id] = t.freeze_resist

	# Allocate MultiMesh slot
	_mm_shape[id] = _shape[id]
	_mm_slot[id] = _alloc_mm_slot(_shape[id])

	# Scale difficulty
	var diff_factor = diff - 1.0
	var curse_level = _get_curse_level()
	_health[id] = GameState.calc_enemy_hp(t.base_health, diff_factor, curse_level)
	_max_health[id] = _health[id]
	_contact_damage[id] = GameState.calc_enemy_damage(t.base_damage, diff_factor, curse_level)
	_move_speed[id] = GameState.calc_enemy_speed(t.base_speed, diff_factor, curse_level) * randf_range(0.975, 1.025)
	_xp_value[id] = t.base_xp

	# Flags
	var fl: int = 0
	if force_boss: fl |= 1 << Flag.BOSS
	if t.instant_kill_resistant: fl |= 1 << Flag.IK_RESIST
	if t.debuff_resistant: fl |= 1 << Flag.DEBUFF_RESIST
	if t.has_hp_x_level: fl |= 1 << Flag.HP_X_LEVEL
	if t.has_three_lives: fl |= 1 << Flag.THREE_LIVES
	if t.is_fixed_direction: fl |= 1 << Flag.FIXED_DIR
	if t.is_self_destruct: fl |= 1 << Flag.SELF_DESTRUCT
	if PowerUpManager and randf() < PowerUpManager.get_stat_bonuses()["defang_pct"]:
		_contact_damage[id] = 0.0
		fl |= 1 << Flag.HARMLESS
	_flags[id] = fl

	# Meta flags
	_meta[id] = 0

	_lives_remaining[id] = 3 if t.has_three_lives else 1

	# Boss bonus HP & count（仅 force_boss 才算真 Boss）
	if force_boss:
		_health[id] *= 3.0
		_max_health[id] = _health[id]
		_boss_count += 1
		boss_count_changed.emit(_boss_count)

	# HP x Level
	if t.has_hp_x_level and is_instance_valid(player):
		var lv = maxi(player.level, 1)
		_health[id] *= lv
		_max_health[id] = _health[id]

	return id


func kill(id: int):
	if not _is_valid(id):
		return
	var fl = _flags[id]
	var meta = _meta[id]

	# Three-lives check
	if fl & (1 << Flag.THREE_LIVES) and _lives_remaining[id] > 1:
		_lives_remaining[id] -= 1
		_health[id] = _max_health[id]
		_flags[id] = fl & ~(1 << Flag.FROZEN)  # clear frozen
		_freeze_timer[id] = 0.0
		_debuff_slow[id] = 0.0
		_debuff_timer[id] = 0.0
		_hit_flash[id] = 0.0
		# Revive FX
		if ObjectPoolManager:
			ObjectPoolManager.spawn_ft(get_parent(),
				_pos[id] + Vector2(randf_range(-10, 10), -20),
				"✧ REVIVE ✧", Color(0.5, 0.8, 1.0), 18)
		AudioManager.play_sfx("enemy_revive")
		return

	# Self-destruct
	if fl & (1 << Flag.SELF_DESTRUCT):
		_explode(id)

	# Emit death signal
	var is_boss = bool(fl & (1 << Flag.BOSS))
	var is_arcana = bool(meta & (1 << Meta.ARCANA_BOSS))
	enemy_killed.emit(id, _type_id[id], _pos[id], is_boss, _xp_value[id])

	if is_boss:
		_boss_count = maxi(0, _boss_count - 1)
		boss_count_changed.emit(_boss_count)

	# Free MultiMesh slot
	_free_mm_slot(id)
	# Free entity slot
	_free(id)


func _is_valid(id: int) -> bool:
	return id >= 0 and id < _alive.size() and _alive[id] > 0


# ═══════════════════════════════════════════════════════════════════
#  PROCESSING
# ═══════════════════════════════════════════════════════════════════

func _process(delta):
	if not is_instance_valid(player) or not game_state:
		return
	_frame_n += 1
	var player_pos = player.global_position
	var map_scale = game_state.map_scale
	var speed_mod = game_state.stage_enemy_speed_mod if game_state else 1.0
	var cull_dist_sq = (CULL_DIST * map_scale) ** 2
	var mid_dist_sq = (MID_DIST * map_scale) ** 2

	var n = _pos.size()
	for i in n:
		if _alive[i] == 0:
			continue

		# ── Death check (merged, catches all states including frozen) ──
		if _health[i] <= 0:
			kill(i)
			continue

		# ── Frozen ──
		if _flags[i] & (1 << Flag.FROZEN):
			_freeze_timer[i] -= delta
			if _freeze_timer[i] <= 0.0:
				_flags[i] &= ~(1 << Flag.FROZEN)
			if _kb_vel[i].length_squared() > 0.0:
				_kb_vel[i] = _kb_vel[i].move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta * 60.0)
			continue

		# ── Timer decays ──
		if _debuff_timer[i] > 0.0:
			_debuff_timer[i] -= delta
			if _debuff_timer[i] <= 0.0:
				_debuff_slow[i] = 0.0
		if _kb_resist_reduce_timer[i] > 0.0:
			_kb_resist_reduce_timer[i] -= delta
			if _kb_resist_reduce_timer[i] <= 0.0:
				_knockback_resist[i] = minf(1.0, _knockback_resist[i] + _kb_resist_reduce[i])
				_kb_resist_reduce[i] = 0.0

		# ── Distance culling ──
		var dist_sq = _pos[i].distance_squared_to(player_pos)
		var is_culled = bool(_meta[i] & (1 << Meta.CULLED))
		var is_boss = bool(_flags[i] & (1 << Flag.BOSS))

		if dist_sq > cull_dist_sq:
			if not is_culled:
				_meta[i] |= 1 << Meta.CULLED
			if is_boss:
				_meta[i] &= ~(1 << Meta.CULLED)
				_teleport_boss(i)
				continue
			# Throttle culled non-boss: every 4th frame
			if (i + _frame_n) % 4 != 0:
				continue
			var dir = (player_pos - _pos[i]).normalized()
			_pos[i] += dir * _move_speed[i] * 0.3 * delta
			continue
		elif is_culled:
			_meta[i] &= ~(1 << Meta.CULLED)

		# ── Skip physics optimization ──
		var skip_physics = dist_sq > mid_dist_sq

		# ── Hit flash ──
		if _hit_flash[i] > 0.0:
			_hit_flash[i] -= delta

		# ── Knockback decay ──
		if _kb_vel[i].length_squared() > 0.0:
			_kb_vel[i] = _kb_vel[i].move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta * 60.0)
			if _kb_vel[i].length_squared() < 1.0:
				_kb_vel[i] = Vector2.ZERO

		# ── Frame staggering: 1/3 per frame ──
		var my_turn = (i + _frame_n) % 3 == 0
		var effective_speed = speed_mod

		# Stationary or off-turn
		if speed_mod <= 0.0 or not my_turn:
			if speed_mod <= 0.0:
				_vel[i] = Vector2.ZERO
			else:
				_vel[i] = _cached_vel[i]
			_pos[i] += (_vel[i] + _kb_vel[i]) * delta
			continue

		# Debuff slow
		if _debuff_slow[i] > 0.0:
			effective_speed *= (1.0 - _debuff_slow[i])

		# Behavior dispatch
		_dispatch_behavior(i, delta, effective_speed, player_pos)

		_cached_vel[i] = _vel[i]
		_pos[i] += (_vel[i] + _kb_vel[i]) * delta

	_update_multimesh()


func _teleport_boss(id: int):
	var bounds = _get_camera_bounds()
	if bounds == Rect2():
		return
	var margin = 60.0
	var side = randi() % 4
	match side:
		0: _pos[id] = Vector2(randf_range(bounds.position.x + margin, bounds.position.x + bounds.size.x - margin), bounds.position.y - margin)
		1: _pos[id] = Vector2(randf_range(bounds.position.x + margin, bounds.position.x + bounds.size.x - margin), bounds.position.y + bounds.size.y + margin)
		2: _pos[id] = Vector2(bounds.position.x - margin, randf_range(bounds.position.y + margin, bounds.position.y + bounds.size.y - margin))
		3: _pos[id] = Vector2(bounds.position.x + bounds.size.x + margin, randf_range(bounds.position.y + margin, bounds.position.y + bounds.size.y - margin))


func _get_camera_bounds() -> Rect2:
	if not camera_ctrl or not camera_ctrl.has_method("get_camera_bounds"):
		return Rect2()
	return camera_ctrl.get_camera_bounds()


func _dispatch_behavior(i: int, delta: float, speed_mod: float, player_pos: Vector2):
	match _behavior[i]:
		1:  # wavy
			var dir = (player_pos - _pos[i]).normalized()
			var perp = dir.rotated(PI / 2.0)
			_wavy_time[i] += delta
			var wave = perp * sin(_wavy_time[i] * 4.0) * (60.0 * speed_mod)
			if _flags[i] & (1 << Flag.FIXED_DIR):
				if not (_meta[i] & (1 << Meta.HAS_FIXED_DIR)):
					_fixed_dir[i] = Vector2.DOWN
					_meta[i] |= 1 << Meta.HAS_FIXED_DIR
				_vel[i] = _fixed_dir[i] * _move_speed[i] * speed_mod + wave
			else:
				_vel[i] = dir * _move_speed[i] * speed_mod + wave
		2:  # stationary
			_vel[i] = Vector2.ZERO
		_:  # chase (0)
			if _flags[i] & (1 << Flag.FIXED_DIR):
				if not (_meta[i] & (1 << Meta.HAS_FIXED_DIR)):
					_fixed_dir[i] = (player_pos - _pos[i]).normalized()
					_meta[i] |= 1 << Meta.HAS_FIXED_DIR
				_vel[i] = _fixed_dir[i] * _move_speed[i] * speed_mod
			else:
				var dir = (player_pos - _pos[i]).normalized()
				_vel[i] = dir * _move_speed[i] * speed_mod


func _get_curse_level() -> int:
	return game_state.curse_level if game_state else 0


# ═══════════════════════════════════════════════════════════════════
#  Self-destruct explosion
# ═══════════════════════════════════════════════════════════════════

func _explode(id: int):
	var radius = 60.0 * _scale_arr[id]
	var dmg = _contact_damage[id] * 2.0
	var pos = _pos[id]
	var n = _pos.size()
	for i in n:
		if _alive[i] == 0 or i == id:
			continue
		if pos.distance_to(_pos[i]) < radius:
			_damage(i, dmg, Vector2.ZERO)
	# Player damage
	if is_instance_valid(player):
		var dist = pos.distance_to(player.global_position)
		if dist < radius:
			if player.has_method("take_damage_direct"):
				player.take_damage_direct(dmg)
			elif player.has_method("_on_hurt"):
				player._on_hurt(null)
	# Visual
	_spawn_explosion_fx(pos, radius, Color(0.9, 0.4, 0.05))
	AudioManager.play_sfx("explosion")


func _spawn_explosion_fx(world_pos: Vector2, radius: float, color: Color):
	var explosion = Node2D.new()
	explosion.global_position = world_pos
	add_child(explosion)
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
		if exp: exp.queue_free()
	)


# ═══════════════════════════════════════════════════════════════════
#  RENDERING — MultiMesh (批量渲染)
# ═══════════════════════════════════════════════════════════════════

# 每种形状独立 Mesh + MultiMeshInstance2D（outline + fill）
var _mm_outline = []  # [shape]->MultiMesh
var _mm_fill = []
var _mmi_outline = []
var _mmi_fill = []


func _build_shape_mesh(shape: int) -> Mesh:
	var mesh = ArrayMesh.new()
	var verts = PackedVector3Array()
	var idx = PackedInt32Array()
	match shape:
		1:  # triangle — 指向 -Y，由 transform.rotation 转向玩家
			for j in range(3):
				var a = -PI / 2.0 + float(j) * TAU / 3.0
				verts.append(Vector3(cos(a), sin(a), 0))
			idx.append(0); idx.append(1); idx.append(2)
		2:  # diamond
			for d in [Vector2(0, -1), Vector2(0.7, 0), Vector2(0, 1), Vector2(-0.7, 0)]:
				verts.append(Vector3(d.x, d.y, 0))
			for i in [0, 1, 2, 0, 2, 3]:
				idx.append(i)
		3:  # hexagon
			for j in range(6):
				var a = float(j) * TAU / 6.0 - PI / 2.0
				verts.append(Vector3(cos(a), sin(a), 0))
			for i in [0, 1, 2, 0, 2, 3, 0, 3, 4, 0, 4, 5]:
				idx.append(i)
		_:  # 0 circle — 16 段三角扇
			verts.append(Vector3(0, 0, 0))
			for i in range(17):
				var a = float(i) / 16.0 * TAU
				verts.append(Vector3(cos(a), sin(a), 0))
			for i in range(16):
				idx.append(0); idx.append(i + 1); idx.append(i + 2)
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _alloc_mm_slot(shape: int) -> int:
	if _mm_free_slots[shape].size() > 0:
		return _mm_free_slots[shape].pop_back()
	var slot = _mm_next_slot[shape]
	_mm_next_slot[shape] = slot + 1
	# 如果超出当前容量，扩展 MultiMesh
	var cap = _mm_fill[shape].instance_count
	if slot >= cap:
		var new_cap = cap + 64
		_mm_fill[shape].instance_count = new_cap
		_mm_outline[shape].instance_count = new_cap
	# 更新可见计数
	_mm_fill[shape].visible_instance_count = slot + 1
	_mm_outline[shape].visible_instance_count = slot + 1
	return slot


func _free_mm_slot(id: int):
	var slot = _mm_slot[id]
	if slot < 0:
		return
	var s = _mm_shape[id]
	if s < 0 or s > 3:
		return
	var off = Transform2D(0, Vector2(0, 0), 0, Vector2(-9999, -9999))
	_mm_fill[s].set_instance_transform_2d(slot, off)
	_mm_fill[s].set_instance_color(slot, Color(0, 0, 0, 0))
	_mm_outline[s].set_instance_transform_2d(slot, off)
	_mm_outline[s].set_instance_color(slot, Color(0, 0, 0, 0))
	_mm_free_slots[s].append(slot)
	_mm_slot[id] = -1


func _init_multimesh():
	for shape in range(4):
		var mesh = _build_shape_mesh(shape)
		for layer_idx in range(2):
			var mm = MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_2D
			mm.use_colors = true
			mm.mesh = mesh
			mm.instance_count = MULTIMESH_CAPACITY

			var mmi = MultiMeshInstance2D.new()
			mmi.multimesh = mm
			mmi.name = "EnemyMM_s%d_%s" % [shape, "outline" if layer_idx == 0 else "fill"]
			add_child(mmi)

			if layer_idx == 0:
				_mm_outline.append(mm)
				_mmi_outline.append(mmi)
			else:
				_mm_fill.append(mm)
				_mmi_fill.append(mmi)

	# 初始化为不可见
	var off = Transform2D(0, Vector2(0, 0), 0, Vector2(-9999, -9999))
	var zero = Color(0, 0, 0, 0)
	for shape in range(4):
		for i in MULTIMESH_CAPACITY:
			_mm_outline[shape].set_instance_transform_2d(i, off)
			_mm_outline[shape].set_instance_color(i, zero)
			_mm_fill[shape].set_instance_transform_2d(i, off)
			_mm_fill[shape].set_instance_color(i, zero)


func _update_multimesh():
	if not is_instance_valid(player):
		return
	if _mm_fill[0] == null:
		return
	var player_pos = player.global_position
	var render_dist_sq = (CULL_DIST * (game_state.map_scale if game_state else 1.0)) ** 2
	var close_sq = 350.0 * 350.0  # 350px 以内每帧更新（原 200px）

	# 负载均衡：敌人数越多，远程敌人更新频率越低
	var stride = 1
	if _alive_count > 250:
		stride = 4
	elif _alive_count > 120:
		stride = 3
	elif _alive_count > 60:
		stride = 2

	var n = _pos.size()
	for i in n:
		if _alive[i] == 0:
			continue
		var dist_sq = _pos[i].distance_squared_to(player_pos)
		if dist_sq > render_dist_sq:
			continue

		# 近战敌人（350px 内）每帧更新，远程敌人按 stride 跳帧
		if stride > 1 and dist_sq > close_sq and (i + _frame_n) % stride != 0:
			continue

		var slot = _mm_slot[i]
		if slot < 0:
			continue

		var r = BASE_RADIUS * _scale_arr[i]
		var col = _color[i]
		var ocol = _outline_color[i]
		var ow = _outline_width[i]
		var s = _shape[i]

		# Hit flash
		if _hit_flash[i] > 0.0:
			col = Color(3.0, 3.0, 3.0, 1.0)

		# Boss 高亮：金色描边 + 加粗
		if _flags[i] & (1 << Flag.BOSS):
			ocol = Color(1.0, 0.85, 0.2)
			ow = maxf(ow, 4.0)

		var pos = _pos[i]
		var rot = 0.0
		if s == 1:  # triangle 指向玩家
			rot = (player_pos - pos).angle()
		var t_fill = Transform2D(rot, Vector2(r, r), 0, Vector2(pos.x, pos.y))
		var t_out = Transform2D(rot, Vector2(r + ow, r + ow), 0, Vector2(pos.x, pos.y))

		_mm_fill[s].set_instance_transform_2d(slot, t_fill)
		_mm_fill[s].set_instance_color(slot, col)
		_mm_outline[s].set_instance_transform_2d(slot, t_out)
		_mm_outline[s].set_instance_color(slot, ocol)


func _get_camera() -> Camera2D:
	if camera_ctrl and camera_ctrl.has_method("get_camera"):
		return camera_ctrl.get_camera()
	return null


# ═══════════════════════════════════════════════════════════════════
#  PUBLIC API — Damage / Effects
# ═══════════════════════════════════════════════════════════════════

func damage(id: int, amount: float, source_pos: Vector2 = Vector2.ZERO, knockback_mult: float = 1.0):
	if not _is_valid(id):
		return
	_health[id] -= amount
	_hit_flash[id] = 0.08

	# Knockback
	if source_pos != Vector2.ZERO and _knockback_resist[id] < 1.0:
		var kb_dir = (_pos[id] - source_pos).normalized()
		_kb_vel[id] = kb_dir * KNOCKBACK_STRENGTH * (1.0 - _knockback_resist[id]) * knockback_mult

	# Damage text
	if ObjectPoolManager:
		ObjectPoolManager.spawn_ft(get_parent(),
			_pos[id] + Vector2(randf_range(-8, 8), -10),
			str(int(amount)), Color(1, 0.9, 0.6),
			16 + mini(int(amount) / 10, 14))

	# Death is handled in _process after movement
	if _health[id] <= 0:
		_health[id] = 0


func freeze(id: int, duration: float):
	if not _is_valid(id):
		return
	if _freeze_resist[id] > 0 and duration < 5.0:
		var eff = duration * (1.0 - _freeze_resist[id])
		if eff <= 0.1:
			return
		duration = eff
	_flags[id] |= 1 << Flag.FROZEN
	_freeze_timer[id] = duration


func is_frozen(id: int) -> bool:
	return _is_valid(id) and bool(_flags[id] & (1 << Flag.FROZEN))


func instant_kill(id: int) -> bool:
	if not _is_valid(id):
		return false
	if _flags[id] & (1 << Flag.IK_RESIST):
		return false
	_damage(id, _max_health[id] * 10, Vector2.ZERO)
	return true


func _damage(id: int, amount: float, source_pos: Vector2):
	# Internal damage method without death check (called during batch process)
	if not _is_valid(id):
		return
	_health[id] -= amount
	_hit_flash[id] = 0.08
	if source_pos != Vector2.ZERO and _knockback_resist[id] < 1.0:
		var kb_dir = (_pos[id] - source_pos).normalized()
		_kb_vel[id] = kb_dir * KNOCKBACK_STRENGTH * (1.0 - _knockback_resist[id])


func apply_debuff(id: int, dtype: String, value: float, duration: float) -> bool:
	if not _is_valid(id):
		return false
	if _flags[id] & (1 << Flag.DEBUFF_RESIST):
		return false
	match dtype:
		"slow":
			_debuff_slow[id] = maxf(_debuff_slow[id], value)
			_debuff_timer[id] = maxf(_debuff_timer[id], duration)
		"knockback_resist_reduce":
			_knockback_resist[id] = maxf(0.0, _knockback_resist[id] - value)
			_kb_resist_reduce[id] = value
			_kb_resist_reduce_timer[id] = duration
		_:
			return false
	return true


func disarm(id: int, _duration: float):
	pass  # not implemented


# ═══════════════════════════════════════════════════════════════════
#  PUBLIC API — Queries
# ═══════════════════════════════════════════════════════════════════

func get_count() -> int:
	return _alive_count





func get_pos(id: int) -> Vector2:
	return _pos[id] if _is_valid(id) else Vector2.ZERO

func set_pos(id: int, pos: Vector2):
	if _is_valid(id):
		_pos[id] = pos


func get_enemy_scale(id: int) -> float:
	return _scale_arr[id] if _is_valid(id) else 1.0


func get_radius(id: int) -> float:
	return BASE_RADIUS * _scale_arr[id] if _is_valid(id) else 0.0


func get_contact_damage(id: int) -> float:
	return _contact_damage[id] if _is_valid(id) else 0.0


func get_flag(id: int, name: String) -> bool:
	if not _is_valid(id):
		return false
	match name:
		"is_boss": return bool(_flags[id] & (1 << Flag.BOSS))
		"is_arcana_boss": return bool(_meta[id] & (1 << Meta.ARCANA_BOSS))
		"is_wave_enemy": return bool(_meta[id] & (1 << Meta.WAVE_ENEMY))
		"has_three_lives": return bool(_flags[id] & (1 << Flag.THREE_LIVES))
	return false


func set_meta_flag(id: int, name: String, val: bool):
	if not _is_valid(id):
		return
	match name:
		"is_wave_enemy":
			if val: _meta[id] |= 1 << Meta.WAVE_ENEMY
			else: _meta[id] &= ~(1 << Meta.WAVE_ENEMY)
		"is_arcana_boss":
			if val: _meta[id] |= 1 << Meta.ARCANA_BOSS
			else: _meta[id] &= ~(1 << Meta.ARCANA_BOSS)


func is_alive(id: int) -> bool:
	return _is_valid(id)


func get_type_id(id: int) -> int:
	return _type_id[id] if _is_valid(id) else -1


func get_xp_value(id: int) -> int:
	return _xp_value[id] if _is_valid(id) else 0


func get_boss_count() -> int:
	return _boss_count


# ── Proximity queries for weapons ──

func get_capacity() -> int:
	return _pos.size()


const GRID_KEY_MULT := 10007  # prime, > max cells per axis

func _ensure_grid():
	if _grid_frame >= _frame_n:
		return
	# 隔帧重建：敌人 2 帧内位移 < 5px，对碰撞检测无影响
	if _grid_frame >= _frame_n - 1:
		return
	_grid_frame = _frame_n
	_grid.clear()
	var n = _pos.size()
	var px = _pos
	var al = _alive
	var mt = _meta
	for i in n:
		if al[i] == 0 or (mt[i] & (1 << Meta.CULLED)):
			continue
		var key = int(px[i].x / GRID_CELL) * GRID_KEY_MULT + int(px[i].y / GRID_CELL)
		var arr = _grid.get(key)
		if arr == null:
			arr = []
			_grid[key] = arr
		arr.append(i)



func cell_has_enemies(center: Vector2, radius: float) -> bool:
	_ensure_grid()
	var cx = int(center.x / GRID_CELL)
	var cy = int(center.y / GRID_CELL)
	var base_key = cx * GRID_KEY_MULT + cy
	var cr = ceili(radius / GRID_CELL)
	var step = GRID_KEY_MULT
	for dx in range(-cr, cr + 1):
		var row_key = base_key + dx * step
		for dy in range(-cr, cr + 1):
			if _grid.has(row_key + dy):
				return true
	return false

func get_nearest_with_mask(center: Vector2, max_radius: float, hit_mask: PackedByteArray) -> int:
	_ensure_grid()
	var best = -1
	var best_d = INF
	var cx = int(center.x / GRID_CELL)
	var cy = int(center.y / GRID_CELL)
	var base_key = cx * GRID_KEY_MULT + cy
	var cr = ceili(max_radius / GRID_CELL)
	var mask_size = hit_mask.size()
	var px = _pos
	var cxf = center.x
	var cyf = center.y
	var step = GRID_KEY_MULT
	for dx in range(-cr, cr + 1):
		var row_key = base_key + dx * step
		for dy in range(-cr, cr + 1):
			var ids = _grid.get(row_key + dy)
			if not ids:
				continue
			for eid in ids:
				if eid >= mask_size or hit_mask[eid]:
					continue
				var p = px[eid]
				var dx_v = p.x - cxf
				var dy_v = p.y - cyf
				var d = dx_v * dx_v + dy_v * dy_v
				# 圆-圆碰撞检测：投射物边界 + 敌人边界
				var combined_r = max_radius + BASE_RADIUS * _scale_arr[eid]
				if d <= combined_r * combined_r and d < best_d:
					best = eid
					best_d = d
	return best


func query_circle(center: Vector2, radius: float) -> Array[int]:
	_ensure_grid()
	var r2 = radius * radius
	var result: Array[int] = []
	var cx = int(center.x / GRID_CELL)
	var cy = int(center.y / GRID_CELL)
	var base_key = cx * GRID_KEY_MULT + cy
	var cr = ceili(radius / GRID_CELL)
	var px = _pos
	var al = _alive
	var cxf = center.x
	var cyf = center.y
	var step = GRID_KEY_MULT
	for dx in range(-cr, cr + 1):
		var row_key = base_key + dx * step
		for dy in range(-cr, cr + 1):
			var ids = _grid.get(row_key + dy)
			if not ids:
				continue
			for eid in ids:
				if al[eid] == 0:
					continue
				var p = px[eid]
				var dx_v = p.x - cxf
				var dy_v = p.y - cyf
				if dx_v * dx_v + dy_v * dy_v <= r2:
					result.append(eid)
	return result


func get_nearest(center: Vector2, max_radius: float) -> int:
	var r2 = max_radius * max_radius
	var best = -1
	var best_d = r2
	var n = _pos.size()
	for i in n:
		if _alive[i] == 0:
			continue
		var d = _pos[i].distance_squared_to(center)
		if d <= best_d:
			best = i
			best_d = d
	return best


func get_nearest_with_exclude(center: Vector2, max_radius: float, exclude: Array[int]) -> int:
	var r2 = max_radius * max_radius
	var best = -1
	var best_d = r2
	var n = _pos.size()
	for i in n:
		if _alive[i] == 0 or exclude.has(i):
			continue
		var d = _pos[i].distance_squared_to(center)
		if d <= best_d:
			best = i
			best_d = d
	return best


func contact_damage_at(center: Vector2, player_radius: float) -> float:
	_ensure_grid()
	var max_r = player_radius + BASE_RADIUS * 2
	var r2 = max_r * max_r
	var cx = int(center.x / GRID_CELL)
	var cy = int(center.y / GRID_CELL)
	var base_key = cx * GRID_KEY_MULT + cy

	# 玩家碰撞半径通常 < 64px（GRID_CELL），查中心格 + 相邻格
	var cr = ceili(max_r / GRID_CELL)
	var px = _pos
	var fl = _flags
	var cd = _contact_damage
	var cxf = center.x
	var cyf = center.y
	var step = GRID_KEY_MULT
	for dx in range(-cr, cr + 1):
		var row_key = base_key + dx * step
		for dy in range(-cr, cr + 1):
			var ids = _grid.get(row_key + dy)
			if not ids:
				continue
			for eid in ids:
				if fl[eid] & (1 << Flag.FROZEN):
					continue
				if fl[eid] & (1 << Flag.HARMLESS):
					continue
				var p = px[eid]
				var dx_v = p.x - cxf
				var dy_v = p.y - cyf
				if dx_v * dx_v + dy_v * dy_v <= r2:
					return cd[eid]
	return 0.0


# ── EnemyProxy for backward compat ──

func get_proxies() -> Array:
	if _proxy_frame == _frame_n:
		return _cached_proxies
	_proxy_frame = _frame_n
	_proxy_pool_idx = 0
	_cached_proxies.clear()
	var n = _pos.size()
	for i in n:
		if _alive[i] == 0:
			continue
		var proxy: EnemyProxy
		if _proxy_pool_idx < _proxy_pool.size():
			proxy = _proxy_pool[_proxy_pool_idx]
		else:
			proxy = EnemyProxy.new()
			_proxy_pool.append(proxy)
		_proxy_pool_idx += 1
		proxy.setup(self, i)
		_cached_proxies.append(proxy)
	return _cached_proxies


# ═══════════════════════════════════════════════════════════════════
#  Helpers
# ═══════════════════════════════════════════════════════════════════


func query_all_ids() -> Array[int]:
	var result: Array[int] = []
	var n = _pos.size()
	for i in n:
		if _alive[i]:
			result.append(i)
	return result

static func _shape_to_byte(s: String) -> int:
	match s:
		"triangle": return 1
		"diamond": return 2
		"hexagon": return 3
		_: return 0


static func _behavior_to_byte(b: String) -> int:
	match b:
		"wavy": return 1
		"stationary": return 2
		_: return 0
