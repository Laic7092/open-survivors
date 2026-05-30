extends Node
# RelicManager — autoload singleton
# Manages permanent relic collection state. Persistence delegated to SaveManager.

# Relic data loaded lazily via DataRegistry

var _collected: Dictionary = {}


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	_load_data()


# ── Public API ──

func has_relic(id: String) -> bool:
	return _collected.has(id) and _collected[id] == true


func collect_relic(id: String) -> bool:
	if has_relic(id):
		return false
	if not _relic_exists(id):
		return false
	_collected[id] = true
	_save_data()
	var um = EventBus.get_unlock_manager() if EventBus else null
	if um:
		um.on_relic_collected(id)
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
	return DataRegistry.relics().get_relic_count()


# ── Persistence (delegated to SaveManager) ──

func _save_data():
	var ids: Array = []
	for id in _collected:
		if _collected[id]:
			ids.append(id)
	SaveManager.set_section("relics", ids)


func _load_data():
	_collected = {}
	var ids = SaveManager.get_section("relics", [])
	for id in ids:
		_collected[id] = true


func _relic_exists(id: String) -> bool:
	for r in DataRegistry.relics().RELICS:
		if r["id"] == id:
			return true
	return false
