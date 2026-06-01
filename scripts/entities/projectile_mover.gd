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


func set_movement(vel: Vector2, max_life: float = 1.0):
	_velocity = vel
	_max_lifetime = max_life


# callback(eid: int, proj_parent: Node2D, dmg: float) — return true to consume hit
func set_hit_config(mgr: Node, dmg: float, radius: float = 6.0, pierce: int = 0, callback: Callable = Callable()):
	_enemy_manager = mgr
	_damage = dmg
	_hit_radius = radius
	_pierce = pierce
	_hit_callable = callback
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

	_lifetime += delta
	if _lifetime >= _max_lifetime:
		_parent.queue_free()
		return

	# Manual position update
	if _velocity != Vector2.ZERO:
		_parent.global_position += _velocity * delta

	# Enemy hit polling (replaces body_entered)
	if _enemy_manager and _damage > 0:
		var pos = _parent.global_position

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
			else:
				_enemy_manager.damage(eid, _damage, Vector2.ZERO)
				if _pierce == 0:
					_hit_registered = true
					_parent.queue_free()
				else:
					if _pierce > 0:
						_pierce -= 1
					if eid < _hit_mask.size():
						_hit_mask[eid] = 1


func mark_hit():
	_hit_registered = true
