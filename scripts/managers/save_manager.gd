extends Node
# SaveManager — autoload singleton. Single source of truth for persistence.
# All managers delegate read/write through this node so the save file is
# never read-modify-written concurrently by different systems.

const SAVE_PATH := "user://desire_survivors_save.json"

var _cache: Dictionary = {}


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	_load()


func _load():
	if not FileAccess.file_exists(SAVE_PATH):
		_cache = {}
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		_cache = {}
		return
	var text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(text) != OK:
		_cache = {}
		return
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		_cache = {}
		return
	_cache = data


func _save():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("SaveManager: cannot write save file")
		return
	file.store_string(JSON.stringify(_cache, "\t"))
	file.close()


func get_raw() -> Dictionary:
	return _cache


func get_section(key: String, default = null):
	return _cache.get(key, default)


func set_section(key: String, value):
	_cache[key] = value
	_save()


func has_section(key: String) -> bool:
	return _cache.has(key)


func reset_section(key: String):
	_cache.erase(key)
	_save()
