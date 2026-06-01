extends Node
# SaveManager — autoload singleton.
# 3 save slots, each stores FULL profile (gold, powerups, relics, unlocks, arcanas, etc.)
# Slot 1 is auto-created on first launch.
#
# File structure (single JSON):
# {
#   "current_slot": "1",
#   "slots": {
#     "1": { gold, levels, relics, ... },
#     "2": { gold, levels, relics, ... } | null,
#     "3": { gold, levels, relics, ... } | null
#   }
# }

const SAVE_PATH := "user://opensurvivors_save.json"
const SLOT_COUNT := 3
const SAVE_VERSION := "2.0"

var _cache: Dictionary = {}
var current_slot: String = "1"  # currently active slot


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	_load()


# ═══════════════════════════════════════════════════════════
#  Internal I/O
# ═══════════════════════════════════════════════════════════

func _load():
	if not FileAccess.file_exists(SAVE_PATH):
		# First launch: create slot 1 with default data
		_cache = {
			"current_slot": "1",
			"slots": {
				"1": _default_slot_data(),
				"2": null,
				"3": null,
			}
		}
		_save()
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		_cache = _fresh_cache()
		return
	var text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(text) != OK:
		_cache = _fresh_cache()
		return
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		_cache = _fresh_cache()
		return
	
	_cache = data
	_ensure_structure()
	current_slot = _cache.get("current_slot", "1")
	
	# Migrate from v1 (profile+slots) or flat format to v2 (slots only)
	_migrate_if_needed()


func _save():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("SaveManager: cannot write save file")
		return
	file.store_string(JSON.stringify(_cache, "\t"))
	file.close()


func _fresh_cache() -> Dictionary:
	return {
		"current_slot": "1",
		"slots": {
			"1": _default_slot_data(),
			"2": null,
			"3": null,
		}
	}


func _ensure_structure():
	if not _cache.has("current_slot"):
		_cache["current_slot"] = "1"
	if not _cache.has("slots"):
		_cache["slots"] = {}
	for i in range(1, SLOT_COUNT + 1):
		if not _cache["slots"].has(str(i)):
			_cache["slots"][str(i)] = null
	# Ensure slot 1 always has data
	if _cache["slots"]["1"] == null:
		_cache["slots"]["1"] = _default_slot_data()


func _migrate_if_needed():
	# If the only data is in old flat/profile format, migrate to slot 1
	var slots = _cache.get("slots", {})
	if slots.get("1") == null or slots.get("1", {}).get("version") == SAVE_VERSION:
		return
	
	# Check for old-style data (flat keys like "gold", "levels" at root)
	var old_profile = {}
	for key in ["gold", "levels", "unlocked_stages", "unlocked_hyper", "unlocked_chars", "relics", "completed_unlocks", "seen_unlocks", "unlocked_arcanas"]:
		if _cache.has(key):
			old_profile[key] = _cache[key]
	
	if not old_profile.is_empty():
		# Merge into slot 1
		var slot1 = slots.get("1", {})
		for k in old_profile:
			slot1[k] = old_profile[k]
		slot1["version"] = SAVE_VERSION
		_cache["slots"]["1"] = slot1
		# Remove old flat keys
		for k in old_profile:
			_cache.erase(k)
		_cache.erase("profile")
		_save()


func _default_slot_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"name": "存档1",
		"timestamp": Time.get_unix_time_from_system(),
		"play_time": 0.0,
		"gold": 0,
		"levels": {},
		"unlocked_stages": 1,
		"unlocked_hyper": 0,
		"unlocked_chars": 1,
		"relics": [],
		"completed_unlocks": [],
		"seen_unlocks": [],
		"unlocked_arcanas": [],
	}


# ═══════════════════════════════════════════════════════════
#  Public API
# ═══════════════════════════════════════════════════════════

# Get info about all slots for UI display
func get_slots_info() -> Dictionary:
	_ensure_structure()
	var result = {}
	for i in range(1, SLOT_COUNT + 1):
		var key = str(i)
		var slot = _cache["slots"].get(key)
		if slot == null:
			result[key] = {"occupied": false}
		else:
			var ts = slot.get("timestamp", 0)
			var time_str = ""
			if ts > 0:
				var dt = Time.get_datetime_dict_from_unix_time(ts)
				time_str = "%04d-%02d-%02d %02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute]
			
			result[key] = {
				"occupied": true,
				"name": slot.get("name", "Slot " + key),
				"timestamp": ts,
				"time_str": time_str,
				"gold": slot.get("gold", 0),
				"play_time": slot.get("play_time", 0.0),
			}
	return result


# Switch to a different slot (load its data into global managers)
func switch_to_slot(slot_id: String) -> bool:
	_ensure_structure()
	if not _cache["slots"].has(slot_id) or _cache["slots"][slot_id] == null:
		return false
	
	current_slot = slot_id
	_cache["current_slot"] = slot_id
	_apply_slot_to_managers(slot_id)
	_save()
	return true


# Apply a slot's data to all global managers
# Each manager reads its own data via SaveManager.get_section()
func _apply_slot_to_managers(_slot_id: String):
	# Tell each manager to reload from the current slot
	if PowerUpManager and PowerUpManager.has_method("_load_data"):
		PowerUpManager._load_data()
	if RelicManager and RelicManager.has_method("_load_data"):
		RelicManager._load_data()
	if ArcanaManager and ArcanaManager.has_method("load_unlock_data"):
		ArcanaManager.load_unlock_data()
	if UnlockManager:
		UnlockManager._load_data()


# Save current manager state into the current slot
func save_current_slot():
	var slot_id = current_slot
	var slot = _cache["slots"].get(slot_id)
	if slot == null:
		slot = _default_slot_data()
		_cache["slots"][slot_id] = slot
	
	slot["version"] = SAVE_VERSION
	slot["timestamp"] = Time.get_unix_time_from_system()
	
	if PowerUpManager:
		slot["gold"] = PowerUpManager.gold
		slot["levels"] = PowerUpManager.levels.duplicate()
		slot["unlocked_stages"] = PowerUpManager.unlocked_stages
		slot["unlocked_hyper"] = PowerUpManager.unlocked_hyper
		slot["unlocked_chars"] = PowerUpManager.unlocked_chars
	
	if RelicManager:
		slot["relics"] = RelicManager.get_collected()
	
	if ArcanaManager:
		slot["unlocked_arcanas"] = ArcanaManager.get_unlocked()
	
	if UnlockManager:
		slot["completed_unlocks"] = UnlockManager.get_completed()
		slot["seen_unlocks"] = UnlockManager.get_seen()
	
	_save()


# Create a new slot with default data
func create_slot(slot_id: String) -> bool:
	_ensure_structure()
	if not _cache["slots"].has(slot_id):
		return false
	
	_cache["slots"][slot_id] = _default_slot_data()
	_cache["slots"][slot_id]["name"] = "存档" + slot_id
	_save()
	return true


# Delete a slot
func delete_slot(slot_id: String):
	_ensure_structure()
	_cache["slots"][slot_id] = null
	# Cannot delete slot 1
	if slot_id == "1":
		_cache["slots"]["1"] = _default_slot_data()
	_save()


# Check if slot is occupied
func is_slot_occupied(slot_id: String) -> bool:
	_ensure_structure()
	return _cache["slots"].get(slot_id) != null


# ═══════════════════════════════════════════════════════════
#  Compatibility API — operates on the CURRENT slot
#  These are used by PowerUpManager, RelicManager, etc.
# ═══════════════════════════════════════════════════════════

# Returns the raw dict of the current slot (or empty dict if none)
func get_raw() -> Dictionary:
	return _cache.get("slots", {}).get(current_slot, {})


# Get a value from the current slot
func get_section(key: String, default = null):
	var slot = _cache.get("slots", {}).get(current_slot)
	if slot == null:
		return default
	return slot.get(key, default)


# Set a value in the current slot and persist
func set_section(key: String, value):
	var slot_id = current_slot
	var slot = _cache.get("slots", {}).get(slot_id)
	if slot == null:
		slot = _default_slot_data()
		_cache["slots"][slot_id] = slot
	slot[key] = value
	_save()


# Check if current slot has a key
func has_section(key: String) -> bool:
	var slot = _cache.get("slots", {}).get(current_slot)
	if slot == null:
		return false
	return slot.has(key)


# Remove a key from the current slot
func reset_section(key: String):
	var slot = _cache.get("slots", {}).get(current_slot)
	if slot != null:
		slot.erase(key)
		_save()
