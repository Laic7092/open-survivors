extends RefCounted
# EnemyProxy — lightweight wrapper for an enemy entity ID.
# Weapons iterate get_enemies() and call methods on the returned objects.
# This proxy delegates all calls to EnemyManager.

var enemy_manager: Node = null
var id: int = -1


func setup(mgr: Node, eid: int):
	enemy_manager = mgr
	id = eid


var global_position: Vector2:
	get: return enemy_manager.get_pos(id) if enemy_manager else Vector2.ZERO

var scale: Vector2:
	get:
		var s = enemy_manager.get_enemy_scale(id) if enemy_manager else 1.0
		return Vector2(s, s)


func take_damage(amount: float, source_pos: Vector2 = Vector2.ZERO, knockback_mult: float = 1.0):
	if enemy_manager and enemy_manager.is_alive(id):
		enemy_manager.damage(id, amount, source_pos, knockback_mult)


func freeze(duration: float):
	if enemy_manager:
		enemy_manager.freeze(id, duration)


func is_frozen() -> bool:
	return enemy_manager and enemy_manager.is_frozen(id)


func get_contact_damage() -> float:
	return enemy_manager.get_contact_damage(id) if enemy_manager else 0.0


func instant_kill() -> bool:
	return enemy_manager and enemy_manager.instant_kill(id)


func die():
	if enemy_manager and enemy_manager.is_alive(id):
		enemy_manager.kill(id)


func get_is_boss() -> bool:
	return enemy_manager and enemy_manager.get_flag(id, "is_boss")


func apply_debuff(dtype: String, value: float, duration: float) -> bool:
	return enemy_manager and enemy_manager.apply_debuff(id, dtype, value, duration)


func disarm(_duration: float):
	pass  # disarm is not currently implemented in enemy.gd


