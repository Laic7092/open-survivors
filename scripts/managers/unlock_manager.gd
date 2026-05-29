extends Node
# UnlockManager — autoload singleton
# Central condition engine for all unlocks.
# Game code reports events (stage cleared, level up, relic collected).
# Manager checks conditions, executes unlocks, and notifies UI.

signal unlock_occurred(unlock_id: String, unlock_type: int)
signal unlocks_cleared

const UnlockDefs = preload("res://scripts/data/unlock_defs.gd")

# ── Runtime state ──
var _completed: Dictionary = {}    # unlock_id -> true
var _newly_unlocked: Array = []    # unlock_ids not yet seen by player (for badges)
var _run_level: int = 0            # current run's highest level
var _cleared_stages: Dictionary = {} # stage_id -> true (this session)


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	_load_data()


# ═══════════════════════════════════════════════════════════
#  EVENT HANDLERS — called by game code
# ═══════════════════════════════════════════════════════════

# ── A stage was cleared ──
func on_stage_cleared(stage_id: int):
	_cleared_stages[stage_id] = true
	_run_check(UnlockDefs.ConditionType.STAGE_CLEARED)


# ── A relic was collected ──
func on_relic_collected(relic_id: String):
	_run_check(UnlockDefs.ConditionType.RELIC_OWNED)


# ── A boss was defeated — unlock hyper mode for that stage ──
func on_boss_defeated(stage_id: int):
	if PowerUpManager and not PowerUpManager.has_hyper(stage_id):
		PowerUpManager.unlock_hyper(stage_id)


# ── Player reached a new level in this run ──
func on_player_leveled_up(new_level: int):
	if new_level > _run_level:
		_run_level = new_level
		_run_check(UnlockDefs.ConditionType.PLAYER_LEVEL)


# ── Run ended (death or completion) ──
func on_run_ended(level: int):
	if level > _run_level:
		_run_level = level
		_run_check(UnlockDefs.ConditionType.PLAYER_LEVEL)


# ── Direct unlock (for purchases or manual triggers) ──
func purchase_unlock(unlock_id: String) -> bool:
	if _completed.has(unlock_id):
		return false
	var def = UnlockDefs.get_def(unlock_id)
	if def == null:
		return false
	return _execute_unlock(def)


# ── Reset per-run state ──
func reset_run_state():
	_run_level = 0
	_cleared_stages.clear()


# ═══════════════════════════════════════════════════════════
#  CHECKS ALL PENDING UNLOCKS FOR A CONDITION TYPE
# ═══════════════════════════════════════════════════════════

func _run_check(cond_type: int):
	var changed = false
	for def in UnlockDefs.get_defs():
		if _completed.has(def.id):
			continue
		if _conditions_met(def):
			if _execute_unlock(def):
				changed = true
	if changed:
		_save_data()


func _conditions_met(def) -> bool:
	if def.conditions.is_empty():
		return false  # purchase-only unlocks checked via purchase_unlock
	
	for cond in def.conditions:
		if not _condition_met(cond):
			return false
	return true


func _condition_met(cond) -> bool:
	match cond.type:
		UnlockDefs.ConditionType.STAGE_CLEARED:
			var sid = cond.params.get("stage_id", -1)
			# Check session cache first, then persistent state
			if _cleared_stages.has(sid):
				return true
			# Also check saved state: if stage N+1 is unlocked, stage N was cleared
			var next_stage_id = sid + 1
			var next_key = UnlockDefs.get_unlock_id_for_stage(next_stage_id)
			if next_key != "" and _completed.has(next_key):
				return true
			return false
		
		UnlockDefs.ConditionType.PLAYER_LEVEL:
			var min_lv = cond.params.get("min_level", 30)
			return _run_level >= min_lv
		
		UnlockDefs.ConditionType.RELIC_OWNED:
			var rid = cond.params.get("relic_id", "")
			return rid != "" and RelicManager.has_relic(rid)
	
	return false


func _execute_unlock(defn) -> bool:
	var uid = defn.id
	if _completed.has(uid):
		return false
	
	_completed[uid] = true
	
	# Apply the unlock to the target system
	match defn.unlock_type:
		UnlockDefs.UnlockableType.STAGE:
			_on_stage_unlocked(defn.target_id)
		UnlockDefs.UnlockableType.ARCANA:
			_on_arcana_unlocked(defn.target_id)
		UnlockDefs.UnlockableType.CHARACTER:
			_on_character_unlocked(defn.target_id)
	
	# Track for notification
	if not _newly_unlocked.has(uid):
		_newly_unlocked.append(uid)
	
	unlock_occurred.emit(uid, defn.unlock_type)
	return true


func _on_stage_unlocked(stage_id: int):
	PowerUpManager.unlock_stage(stage_id)


func _on_arcana_unlocked(arcana_id: int):
	ArcanaManager.unlock(arcana_id)


func _on_character_unlocked(char_id: int):
	# Characters are purchased — this is just for notification tracking
	pass


# ═══════════════════════════════════════════════════════════
#  QUERY API
# ═══════════════════════════════════════════════════════════

func is_unlocked(unlock_id: String) -> bool:
	return _completed.has(unlock_id)


func is_stage_unlocked(stage_id: int) -> bool:
	var key = UnlockDefs.get_unlock_id_for_stage(stage_id)
	return key != "" and _completed.has(key)


func is_arcana_unlocked(arcana_id: int) -> bool:
	return ArcanaManager.has_unlocked(arcana_id)


func is_character_unlocked(char_id: int) -> bool:
	return PowerUpManager.has_unlocked_character(char_id)


# ═══════════════════════════════════════════════════════════
#  NOTIFICATION TRACKING
# ═══════════════════════════════════════════════════════════

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


# ═══════════════════════════════════════════════════════════
#  PERSISTENCE
# ═══════════════════════════════════════════════════════════

const SAVE_PATH := "user://desire_survivors_save.json"


func _save_data():
	var data = _read_save()
	data["completed_unlocks"] = []
	for uid in _completed:
		if _completed[uid]:
			data["completed_unlocks"].append(uid)
	data["seen_unlocks"] = []
	for uid in _newly_unlocked:
		# Invert: save what's NOT yet seen (newly_unlocked hasn't been seen)
		pass
	# Simpler: save the seen list separately
	var all_ids = []
	for d in UnlockDefs.get_defs():
		all_ids.append(d.id)
	var seen = []
	for uid in all_ids:
		if _completed.has(uid) and not _newly_unlocked.has(uid):
			seen.append(uid)
	data["seen_unlocks"] = seen
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func _load_data():
	var data = _read_save()
	_completed = {}
	if data.has("completed_unlocks"):
		for uid in data["completed_unlocks"]:
			_completed[uid] = true
	
	# Rebuild _newly_unlocked: completed but not seen
	_newly_unlocked.clear()
	var seen = []
	if data.has("seen_unlocks"):
		seen = data["seen_unlocks"]
	for uid in _completed:
		if not seen.has(uid):
			_newly_unlocked.append(uid)


func _read_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return {}
	var text = file.get_as_text()
	file.close()
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		return {}
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data
