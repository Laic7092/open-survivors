extends Node
# ArcanaManager — autoload singleton
# Manages Arcana unlock state + run-time active Arcanas.
# Persistence delegated to SaveManager.

# Arcana data loaded lazily via DataRegistry

var _unlocked: Dictionary = {}
var _active: Array = []
var _last_attract_time: float = 0.0
var _cycle_time: float = 0.0
var _level_stat_accum: Dictionary = {}
var _last_processed_level: int = 0

signal arcana_unlocked(arcana_id: int)
signal arcana_activated(arcana_id: int)
signal arcana_cleared


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	load_unlock_data()


# ── Unlock tracking ──

func has_unlocked(id: int) -> bool:
	return _unlocked.has(id) and _unlocked[id] == true


func unlock(id: int) -> bool:
	if has_unlocked(id):
		return false
	if _arcana_exists(id):
		_unlocked[id] = true
		_save_unlock_data()
		arcana_unlocked.emit(id)
		return true
	return false


func get_unlocked() -> Array:
	var result: Array = []
	for id in _unlocked:
		if _unlocked[id]:
			result.append(id)
	return result


func get_unlocked_count() -> int:
	var count = 0
	for id in _unlocked:
		if _unlocked[id]:
			count += 1
	return count


# ── Active Arcanas (run-time) ──

func is_active(id: int) -> bool:
	return _active.has(id)


func get_active() -> Array:
	return _active.duplicate()


func get_active_count() -> int:
	return _active.size()


func activate(id: int) -> bool:
	if not has_unlocked(id):
		return false
	if _active.has(id):
		return false
	_active.append(id)
	arcana_activated.emit(id)
	return true


func deactivate(id: int):
	_active.erase(id)


func deactivate_all():
	_active.clear()
	_last_attract_time = 0.0
	_cycle_time = 0.0
	_level_stat_accum = {}
	_last_processed_level = 0
	arcana_cleared.emit()


# ── Effect query helpers ──

func has_effect(effect_id: String) -> bool:
	for id in _active:
		if DataRegistry.arcanas().arcana_has_effect(id, effect_id):
			return true
	return false


func has_any_effect(effects: Array) -> bool:
	for id in _active:
		var a = DataRegistry.arcanas().get_arcana(id)
		for eff in effects:
			if eff in a["effects"]:
				return true
	return false


func active_arcana_lists_weapon(weapon_type: int) -> Array:
	var result: Array = []
	for id in _active:
		if DataRegistry.arcanas().arcana_lists_weapon(id, weapon_type):
			result.append(id)
	return result


func active_arcanas_have_weapon_effect(weapon_type: int, effect_id: String) -> bool:
	for id in _active:
		if DataRegistry.arcanas().arcana_lists_weapon(id, weapon_type) and DataRegistry.arcanas().arcana_has_effect(id, effect_id):
			return true
	return false


func is_system_enabled() -> bool:
	return RelicManager.has_relic("randomazzo")


# ── Apply Arcana stat modifiers ──

func apply_stat_modifiers(stats: Dictionary, player) -> Dictionary:
	var result = stats.duplicate()
	for id in _active:
		var a = DataRegistry.arcanas().get_arcana(id)
		for effect in a["effects"]:
			match effect:
				"revival_plus_3":
					result["revivals"] = stats.get("revivals", 0) + 3
				"armor_scales_damage":
					var armor_val = stats.get("armor", 0)
					result["damage_mult"] = stats.get("damage_mult", 1.0) + armor_val * 0.1
				"empty_slot_stats":
					var total_slots = 6
					var filled = 0
					if player and player.has_method("get_weapon_count"):
						filled = player.get_weapon_count()
					var empty = max(total_slots - filled, 0)
					result["damage_mult"] = stats.get("damage_mult", 1.0) + 0.20 * empty
					result["cooldown_reduction"] = stats.get("cooldown_reduction", 0.0) + 0.08 * empty
				"crits_enabled":
					result["crit_chance"] = max(stats.get("crit_chance", 0.0), 0.15)
				"crit_damage_double":
					result["crit_mult"] = stats.get("crit_mult", 2.0) * 2.0
	return result


# ── Time-based Arcana effects ──

func process_time_effects(delta: float, player, game_time: float):
	_cycle_time += delta
	for id in _active:
		var a = DataRegistry.arcanas().get_arcana(id)
		for effect in a["effects"]:
			match effect:
				"attract_items_120s":
					if game_time - _last_attract_time >= 120.0:
						_last_attract_time = game_time
						_attract_items(player)
				"cycle_speed":
					if player and player.has_method("set_speed_mult"):
						var cycle = sin(_cycle_time * TAU / 10.0)
						player.set_speed_mult(1.0 + cycle * 0.5)
				"cycle_area":
					if player and player.has_method("set_area_mult_override"):
						var cycle = sin(_cycle_time * TAU / 10.0)
						player.set_area_mult_override(1.0 + cycle * 0.25)
				"cycle_duration":
					if player and player.has_method("set_duration_bonus_override"):
						var cycle = sin(_cycle_time * TAU / 10.0)
						player.set_duration_bonus_override(cycle * 0.5)
				"cycle_stats":
					var phase = fmod(_cycle_time, 20.0) / 20.0
					if phase < 0.25:
						_set_player_stat(player, "growth_mult", 2.0)
						_set_player_stat(player, "luck", 0.0)
						_set_player_stat(player, "greed_mult", 0.0)
						_set_player_stat(player, "curse", 0.0)
					elif phase < 0.5:
						_set_player_stat(player, "growth_mult", 1.0)
						_set_player_stat(player, "luck", 1.0)
						_set_player_stat(player, "greed_mult", 0.0)
						_set_player_stat(player, "curse", 0.0)
					elif phase < 0.75:
						_set_player_stat(player, "growth_mult", 1.0)
						_set_player_stat(player, "luck", 0.0)
						_set_player_stat(player, "greed_mult", 1.0)
						_set_player_stat(player, "curse", 0.0)
					else:
						_set_player_stat(player, "growth_mult", 1.0)
						_set_player_stat(player, "luck", 0.0)
						_set_player_stat(player, "greed_mult", 0.0)
						_set_player_stat(player, "curse", 1.0)


func _set_player_stat(player, stat: String, value):
	if player and player.has_method("set_" + stat):
		player.call("set_" + stat, value)


func _attract_items(player):
	if not is_instance_valid(player):
		return
	var scene = player.get_tree().current_scene
	if not scene:
		return
	var pull_targets = []
	for group in ["pickups", "xp_gems", "light_sources"]:
		pull_targets += scene.get_tree().get_nodes_in_group(group)
	for target in pull_targets:
		if not is_instance_valid(target):
			continue
		var tw = scene.create_tween()
		tw.tween_property(target, "global_position", player.global_position, 0.5)
		tw.set_ease(Tween.EASE_IN)


func get_healing_multiplier() -> float:
	if has_effect("healing_double"):
		return 2.0
	return 1.0


func on_player_level_up(player, new_level: int):
	if new_level <= _last_processed_level:
		return
	_last_processed_level = new_level
	for id in _active:
		var a = DataRegistry.arcanas().get_arcana(id)
		for effect in a["effects"]:
			match effect:
				"level_speed_pct":
					if player and player.has_method("add_speed_mult_pct"):
						player.add_speed_mult_pct(0.01 * new_level)
				"level_stat_pct":
					if new_level % 2 == 0:
						if player:
							if player.has_method("add_growth_pct"):
								player.add_growth_pct(0.01)
							if player.has_method("add_luck"):
								player.add_luck(0.01)
							if player.has_method("add_greed_pct"):
								player.add_greed_pct(0.01)
							if player.has_method("add_curse"):
								player.add_curse(0.01)
				"level_area_pct":
					if player and player.has_method("add_area_pct"):
						player.add_area_pct(0.01 * new_level)
				"level_duration_pct":
					if player and player.has_method("add_duration_pct"):
						player.add_duration_pct(0.01 * new_level)


# ── Persistence (delegated to SaveManager) ──

func _save_unlock_data():
	var ids: Array = []
	for id in _unlocked:
		if _unlocked[id]:
			ids.append(id)
	SaveManager.set_section("unlocked_arcanas", ids)


func load_unlock_data():
	_unlocked = {}
	var ids = SaveManager.get_section("unlocked_arcanas", [])
	for id in ids:
		_unlocked[int(id)] = true


func _arcana_exists(id: int) -> bool:
	return id >= 0 and id < DataRegistry.arcanas().get_arcana_count()
