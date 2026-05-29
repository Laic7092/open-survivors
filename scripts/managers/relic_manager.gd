extends Node
# RelicManager — autoload singleton
# Manages permanent relic collection state. Saved alongside PowerUpManager data.
# API: has_relic(id), collect_relic(id), get_collected(), get_unlocked_count()

const RelicDefs = preload("res://scripts/data/relic_defs.gd")

# Runtime state: set of collected relic IDs
var _collected: Dictionary = {}  # relic_id -> true


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	_load_data()


# ── Public API ─────────────────────────────────────────────

func has_relic(id: String) -> bool:
	return _collected.has(id) and _collected[id] == true


func collect_relic(id: String) -> bool:
	if has_relic(id):
		return false  # already collected
	if not _relic_exists(id):
		return false
	_collected[id] = true
	_save_data()
	# Notify UnlockManager for relic-based unlocks
	if UnlockManager:
		UnlockManager.on_relic_collected(id)
	return true


func get_collected() -> Array:
	var result: Array = []
	for id in _collected:
		if _collected[id]:
			result.append(id)
	return result


func get_unlocked_count() -> int:
	var count = 0
	for id in _collected:
		if _collected[id]:
			count += 1
	return count


func get_total_count() -> int:
	return RelicDefs.get_relic_count()


# ── Persistence (same save file as PowerUpManager) ─────────

const SAVE_PATH := "user://desire_survivors_save.json"


func _save_data():
	# Read existing data, merge relics field, write back
	var data = _read_save_data()
	data["relics"] = []
	for id in _collected:
		if _collected[id]:
			data["relics"].append(id)
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _load_data():
	var data = _read_save_data()
	_collected = {}
	if data.has("relics"):
		for id in data["relics"]:
			_collected[id] = true


func _read_save_data() -> Dictionary:
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


func _relic_exists(id: String) -> bool:
	for r in RelicDefs.RELICS:
		if r["id"] == id:
			return true
	return false
