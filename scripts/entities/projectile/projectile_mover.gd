extends Node2D
# Lightweight projectile movement — replaces Tween for simple linear projectiles.
# Attach to any Area2D as a child or set as its script.
# Call set_movement() after adding to scene.
# For EnemyManager hit polling, call set_hit_config().

var _velocity: Vector2 = Vector2.ZERO
var _lifetime: float = 0.0
var _max_lifetime: float = 1.0
var _hit_registered: bool = false

# Hit detection via EnemyManager
var _enemy_manager: Node = null
var _damage: float = 0.0
var _hit_radius: float = 6.0
var _pierce: int = 0
var _hit_mask: PackedByteArray = []
var _hit_callable: Callable = Callable()

var _parent: Node2D = null

# Wall blocking (read from parent metadata if not set explicitly)
var _block_by_walls: bool = false
var _wall_collision_mask: int = 0

# Per-weapon stats
var _knockback_mult: float = 1.0
var _hitbox_delay: float = 0.0
var _hit_timers: Dictionary = {}  # eid → hit_time for timed re-hit


func set_movement(vel: Vector2, max_life: float = 1.0):
	_velocity = vel
	_max_lifetime = max_life


func set_wall_blocking(enabled: bool, wall_mask: int = 0):
	_block_by_walls = enabled
	_wall_collision_mask = wall_mask


func _read_block_by_walls_meta():
	# Check parent for block_by_walls metadata set by weapon behaviors
	if _parent and _parent.has_meta("block_by_walls"):
		_block_by_walls = _parent.get_meta("block_by_walls")
		if _parent.has_meta("wall_collision_mask"):
			_wall_collision_mask = _parent.get_meta("wall_collision_mask")


# callback(eid: int, proj_parent: Node2D, dmg: float) — return true to consume hit
func set_hit_config(mgr: Node, dmg: float, radius: float = 6.0, pierce: int = 0, callback: Callable = Callable(), knockback_mult: float = 1.0, hitbox_delay: float = 0.0):
	_enemy_manager = mgr
	_damage = dmg
	_hit_radius = radius
	_pierce = pierce
	_hit_callable = callback
	_knockback_mult = knockback_mult
	_hitbox_delay = hitbox_delay
	_hit_timers.clear()
	_hit_mask.resize(0)
	var cap = mgr.get_capacity() if mgr and mgr.has_method("get_capacity") else 0
	if cap > 0:
		_hit_mask.resize(cap)


func _physics_process(delta):
	if _hit_registered:
		return

	if not _parent:
		_parent = get_parent()
		if not _parent:
			return
		_read_block_by_walls_meta()

	_lifetime += delta
	if _lifetime >= _max_lifetime:
		_parent.queue_free()
		return

	# Manual position update
	if _velocity != Vector2.ZERO:
		_parent.global_position += _velocity * delta

	# Wall blocking check
	if _block_by_walls:
		var space_state = _parent.get_world_2d().direct_space_state
		if space_state:
			var query = PhysicsPointQueryParameters2D.new()
			query.position = _parent.global_position
			if _wall_collision_mask > 0:
				query.collision_mask = _wall_collision_mask
			var hits = space_state.intersect_point(query)
			for hit in hits:
				if hit.collider is StaticBody2D:
					_parent.queue_free()
					_hit_registered = true
					return

	# Enemy hit polling (replaces body_entered)
	if _enemy_manager and _damage > 0:
		var pos = _parent.global_position

		# 快速空单元格跳过：附近格子无敌人则省去完整查询
		if _enemy_manager.has_method("cell_has_enemies") and not _enemy_manager.cell_has_enemies(pos, _hit_radius):
			return

		# Hitbox delay: 清除超时的命中标记，允许重复命中
		if _hitbox_delay > 0 and not _hit_timers.is_empty():
			var now = _lifetime
			for eid in _hit_timers.keys():
				if now - _hit_timers[eid] >= _hitbox_delay:
					_hit_timers.erase(eid)
					if eid < _hit_mask.size():
						_hit_mask[eid] = 0

		var eid = _enemy_manager.get_nearest_with_mask(pos, _hit_radius, _hit_mask)
		if eid >= 0:
			if _hit_callable.is_valid():
				var consumed = _hit_callable.call(eid, _parent, _damage)
				if consumed:
					if _pierce == 0:
						_hit_registered = true
						_parent.queue_free()
					else:
						if _pierce > 0:
							_pierce -= 1
						if eid < _hit_mask.size():
							_hit_mask[eid] = 1
						if _hitbox_delay > 0:
							_hit_timers[eid] = _lifetime
			else:
				_enemy_manager.damage(eid, _damage, pos, _knockback_mult)
				if _pierce == 0:
					_hit_registered = true
					_parent.queue_free()
				else:
					if _pierce > 0:
						_pierce -= 1
					if eid < _hit_mask.size():
						_hit_mask[eid] = 1
					if _hitbox_delay > 0:
						_hit_timers[eid] = _lifetime


func mark_hit():
	_hit_registered = true
