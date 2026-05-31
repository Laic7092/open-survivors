extends Node
# UnlockManager — autoload singleton
# Central condition engine for all unlocks.
# Persistence delegated to SaveManager.

signal unlock_occurred(unlock_id: String, unlock_type: int)
signal unlocks_cleared
signal run_stat_updated(key: String, value)
signal persistent_stat_updated(key: String, value)

const UnlockTypes = preload("res://scripts/data/unlock_types.gd")
# Unlock data loaded lazily via DataRegistry

var _completed: Dictionary = {}
var _newly_unlocked: Array = []
var _run_level: int = 0
var _cleared_stages: Dictionary = {}

# Per-run tracking (resets each run)
var _run_data: Dictionary = {
	"survive_time": 0.0,
	"run_kills": 0,
	"evolved_weapons": [],
	"found_items": [],
	"destroyed_light_sources": 0,
	"start_char_id": -1,
}

# Persistent cross-run tracking
var _persistent_stats: Dictionary = {
	"total_kills": 0,
	"total_light_destroyed": 0,
	"max_survive_time": 0.0,
	"weapon_levels_reached": {},  # weapon_type -> max_level
	"found_items_permanent": [],
}


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	_load_data()


# ── Event handlers ──

func on_stage_cleared(stage_id: int):
	_cleared_stages[stage_id] = true
	_run_check(UnlockTypes.ConditionType.STAGE_CLEARED)


func on_relic_collected(relic_id: String):
	_run_check(UnlockTypes.ConditionType.RELIC_OWNED)


func on_boss_defeated(stage_id: int):
	if PowerUpManager and not PowerUpManager.has_hyper(stage_id):
		PowerUpManager.unlock_hyper(stage_id)


func on_player_leveled_up(new_level: int):
	if new_level > _run_level:
		_run_level = new_level
		_run_check(UnlockTypes.ConditionType.PLAYER_LEVEL)
		_run_check(UnlockTypes.ConditionType.CHAR_LEVEL)


func on_run_ended(level: int):
	if level > _run_level:
		_run_level = level
		_run_check(UnlockTypes.ConditionType.PLAYER_LEVEL)
	_harden_run_stats()


func purchase_unlock(unlock_id: String) -> bool:
	if _completed.has(unlock_id):
		return false
	var def = DataRegistry.unlocks().get_def(unlock_id)
	if def == null:
		return false
	return _execute_unlock(def)


func reset_run_state():
	_run_level = 0
	_cleared_stages.clear()
	_run_data = {
		"survive_time": 0.0,
		"run_kills": 0,
		"evolved_weapons": [],
		"found_items": [],
		"destroyed_light_sources": 0,
		"start_char_id": -1,
	}


# ── New event handlers ──

func on_kill(enemy_type: int = -1):
	_run_data["run_kills"] += 1
	_persistent_stats["total_kills"] += 1
	run_stat_updated.emit("run_kills", _run_data["run_kills"])
	persistent_stat_updated.emit("total_kills", _persistent_stats["total_kills"])
	_run_check(UnlockTypes.ConditionType.RUN_KILLS)
	_run_check(UnlockTypes.ConditionType.TOTAL_KILLS)


func on_weapon_upgraded(weapon_type: int, new_level: int):
	var prev = _persistent_stats["weapon_levels_reached"].get(weapon_type, 0)
	if new_level > prev:
		_persistent_stats["weapon_levels_reached"][weapon_type] = new_level
	_run_check(UnlockTypes.ConditionType.WEAPON_AT_LEVEL)


func on_item_found(item_type: int):
	if not _run_data["found_items"].has(item_type):
		_run_data["found_items"].append(item_type)
	if not _persistent_stats["found_items_permanent"].has(item_type):
		_persistent_stats["found_items_permanent"].append(item_type)
	_run_check(UnlockTypes.ConditionType.ITEM_FOUND)


func on_destroy_light_source():
	_run_data["destroyed_light_sources"] += 1
	_persistent_stats["total_light_destroyed"] += 1
	_run_check(UnlockTypes.ConditionType.DESTROY_LIGHT_SOURCES)


func on_evolution(weapon_type: int):
	if not _run_data["evolved_weapons"].has(weapon_type):
		_run_data["evolved_weapons"].append(weapon_type)
	_run_check(UnlockTypes.ConditionType.ALL_EVOLUTIONS)


func on_run_started(char_id: int):
	reset_run_state()
	_run_data["start_char_id"] = char_id
	_run_check(UnlockTypes.ConditionType.START_WITH_CHAR)


func on_game_time_updated(time_seconds: float):
	if time_seconds > _run_data["survive_time"]:
		_run_data["survive_time"] = time_seconds
		if time_seconds > _persistent_stats["max_survive_time"]:
			_persistent_stats["max_survive_time"] = time_seconds
		_run_check(UnlockTypes.ConditionType.SURVIVE_CHAR_TIME)


# ── Condition checking ──

func _run_check(cond_type: int):
	var changed = false
	for def in DataRegistry.unlocks().get_defs():
		if _completed.has(def.id):
			continue
		if _conditions_met(def):
			if _execute_unlock(def):
				changed = true
	if changed:
		_save_data()


func _conditions_met(def) -> bool:
	if def.unlock_type == UnlockTypes.UnlockableType.ITEM and def.conditions.is_empty():
		return true
	if def.conditions.is_empty():
		return false
	for cond in def.conditions:
		if not _condition_met(cond):
			return false
	return true


func _condition_met(cond) -> bool:
	match cond.type:
		UnlockTypes.ConditionType.STAGE_CLEARED:
			var sid = cond.params.get("stage_id", -1)
			if _cleared_stages.has(sid):
				return true
			var next_stage_id = sid + 1
			var next_key = DataRegistry.unlocks().get_unlock_id_for_stage(next_stage_id)
			if next_key != "" and _completed.has(next_key):
				return true
			return false
		UnlockTypes.ConditionType.PLAYER_LEVEL:
			return _run_level >= cond.params.get("min_level", 30)
		UnlockTypes.ConditionType.CHAR_LEVEL:
			return _run_level >= cond.params.get("min_level", 30)
		UnlockTypes.ConditionType.RELIC_OWNED:
			var rid = cond.params.get("relic_id", "")
			return rid != "" and RelicManager.has_relic(rid)
		UnlockTypes.ConditionType.SURVIVE_CHAR_TIME:
			var min_time = cond.params.get("min_time", 0)
			var char_id = cond.params.get("char_id", -1)
			if char_id >= 0 and _run_data["start_char_id"] != char_id:
				return false
			return _run_data["survive_time"] >= min_time
		UnlockTypes.ConditionType.TOTAL_KILLS:
			return _persistent_stats["total_kills"] >= cond.params.get("min_kills", 0)
		UnlockTypes.ConditionType.RUN_KILLS:
			return _run_data["run_kills"] >= cond.params.get("min_kills", 0)
		UnlockTypes.ConditionType.WEAPON_AT_LEVEL:
			var wt = cond.params.get("weapon_type", 0)
			var ml = cond.params.get("min_level", 0)
			return _persistent_stats["weapon_levels_reached"].get(wt, 0) >= ml
		UnlockTypes.ConditionType.ITEM_FOUND:
			var it = cond.params.get("item_type", 0)
			return _persistent_stats["found_items_permanent"].has(it)
		UnlockTypes.ConditionType.DESTROY_LIGHT_SOURCES:
			return _persistent_stats["total_light_destroyed"] >= cond.params.get("count", 0)
		UnlockTypes.ConditionType.START_WITH_CHAR:
			return _run_data["start_char_id"] == cond.params.get("char_id", -1)
		UnlockTypes.ConditionType.ALL_EVOLUTIONS:
			return _run_data["evolved_weapons"].size() >= 6
	return false


func _execute_unlock(defn) -> bool:
	var uid = defn.id
	if _completed.has(uid):
		return false
	_completed[uid] = true
	match defn.unlock_type:
		UnlockTypes.UnlockableType.STAGE:
			PowerUpManager.unlock_stage(defn.target_id)
		UnlockTypes.UnlockableType.ARCANA:
			ArcanaManager.unlock(defn.target_id)
		UnlockTypes.UnlockableType.CHARACTER:
			pass
		UnlockTypes.UnlockableType.ITEM:
			if PowerUpManager:
				PowerUpManager.unlock_weapon(defn.target_id)
	if not _newly_unlocked.has(uid):
		_newly_unlocked.append(uid)
	unlock_occurred.emit(uid, defn.unlock_type)
	return true


func _harden_run_stats():
	_save_data()


# ── Query API ──

func is_unlocked(unlock_id: String) -> bool:
	return _completed.has(unlock_id)


func is_stage_unlocked(stage_id: int) -> bool:
	var key = DataRegistry.unlocks().get_unlock_id_for_stage(stage_id)
	return key != "" and _completed.has(key)


func is_arcana_unlocked(arcana_id: int) -> bool:
	return ArcanaManager.has_unlocked(arcana_id)


func is_character_unlocked(char_id: int) -> bool:
	return PowerUpManager.has_unlocked_character(char_id)


func is_weapon_unlocked(weapon_type: int) -> bool:
	if PowerUpManager and PowerUpManager.has_unlocked_weapon(weapon_type):
		return true
	var key = DataRegistry.unlocks().get_unlock_id_for_item(weapon_type)
	if key == "":
		return true
	if _completed.has(key):
		return true
	var def = DataRegistry.unlocks().get_def(key)
	if def and def.conditions.is_empty():
		return true
	return false


func get_completed() -> Array:
	var result = []
	for uid in _completed:
		if _completed[uid]:
			result.append(uid)
	return result


func get_seen() -> Array:
	var result = []
	for d in DataRegistry.unlocks().get_defs():
		if _completed.has(d.id) and not _newly_unlocked.has(d.id):
			result.append(d.id)
	return result


# ── Notification tracking ──

func get_newly_unlocked() -> Array:
	return _newly_unlocked.duplicate()


func has_new_unlocks() -> bool:
	return not _newly_unlocked.is_empty()


func mark_seen(unlock_id: String):
	_newly_unlocked.erase(unlock_id)
	_save_data()


func mark_all_seen():
	_newly_unlocked.clear()
	_save_data()
	unlocks_cleared.emit()


# ── Persistence (delegated to SaveManager) ──

func _save_data():
	var completed_ids: Array = []
	for uid in _completed:
		if _completed[uid]:
			completed_ids.append(uid)
	SaveManager.set_section("completed_unlocks", completed_ids)

	var all_ids = []
	for d in DataRegistry.unlocks().get_defs():
		all_ids.append(d.id)
	var seen = []
	for uid in all_ids:
		if _completed.has(uid) and not _newly_unlocked.has(uid):
			seen.append(uid)
	SaveManager.set_section("seen_unlocks", seen)

	# Save persistent stats
	SaveManager.set_section("unlock_persistent_stats", _persistent_stats.duplicate(true))


func _load_data():
	_completed = {}
	var completed_ids = SaveManager.get_section("completed_unlocks", [])
	for uid in completed_ids:
		_completed[uid] = true

	_newly_unlocked.clear()
	var seen = SaveManager.get_section("seen_unlocks", [])
	for uid in _completed:
		if not seen.has(uid):
			_newly_unlocked.append(uid)

	# Load persistent stats
	var saved = SaveManager.get_section("unlock_persistent_stats", {})
	if saved:
		for k in saved:
			_persistent_stats[k] = saved[k]
