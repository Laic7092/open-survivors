extends Node
# UnlockManager — autoload singleton
# Central condition engine for all unlocks.
# Persistence delegated to SaveManager.

signal unlock_occurred(unlock_id: String, unlock_type: int)
signal unlocks_cleared

const UnlockTypes = preload("res://scripts/data/unlock_types.gd")
# Unlock data loaded lazily via DataRegistry

var _completed: Dictionary = {}
var _newly_unlocked: Array = []
var _run_level: int = 0
var _cleared_stages: Dictionary = {}


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


func on_run_ended(level: int):
	if level > _run_level:
		_run_level = level
		_run_check(UnlockTypes.ConditionType.PLAYER_LEVEL)


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
		UnlockTypes.ConditionType.RELIC_OWNED:
			var rid = cond.params.get("relic_id", "")
			return rid != "" and RelicManager.has_relic(rid)
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
	if not _newly_unlocked.has(uid):
		_newly_unlocked.append(uid)
	unlock_occurred.emit(uid, defn.unlock_type)
	return true


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
