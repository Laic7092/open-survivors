extends RefCounted
# Test suite for Unlock Manager + Arcana systems.
# These tests verify data integrity and core logic of the new unlock infrastructure.

const UnlockDefs = preload("res://scripts/data/unlock_defs.gd")
const ArcanaDefs = preload("res://scripts/data/arcana_defs.gd")
const RelicDefs = preload("res://scripts/data/relic_defs.gd")
const StageDefs = preload("res://scripts/data/stage_defs.gd")

var results: Dictionary = {}

func run_all() -> Dictionary:
	results = {}
	
	# ── UnlockDefs data tests ──
	_test("unlock_defs_count", _test_unlock_defs_count)
	_test("unlock_ids_unique", _test_unlock_ids_unique)
	_test("unlock_targets_valid", _test_unlock_targets_valid)
	_test("unlock_types_match", _test_unlock_types_match)
	_test("unlock_lookup", _test_unlock_lookup)
	
	# ── ArcanaDefs data tests ──
	_test("arcana_count", _test_arcana_count)
	_test("arcana_ids_unique", _test_arcana_ids_unique)
	_test("arcana_roman_unique", _test_arcana_roman_unique)
	_test("arcana_effects_format", _test_arcana_effects_format)
	
	# ── UnlockManager logic tests ──
	if UnlockManager != null:
		_test("unlock_mgr_state", _test_unlock_mgr_state)
		_test("event_tracking", _test_event_tracking)
		_test("notification_tracking", _test_notification_tracking)
	else:
		results["unlock_mgr_state"] = {"passed": false, "message": "SKIP: UnlockManager not available"}
		results["event_tracking"] = {"passed": false, "message": "SKIP: UnlockManager not available"}
		results["notification_tracking"] = {"passed": false, "message": "SKIP: UnlockManager not available"}
	
	# ── ArcanaManager logic tests ──
	if ArcanaManager != null:
		_test("arcana_mgr_api", _test_arcana_mgr_api)
		_test("arcana_effect_query", _test_arcana_effect_query)
	else:
		results["arcana_mgr_api"] = {"passed": false, "message": "SKIP: ArcanaManager not available"}
		results["arcana_effect_query"] = {"passed": false, "message": "SKIP: ArcanaManager not available"}
	
	return results


func _test(name: String, fn: Callable):
	results[name] = fn.call()


# ═══════════════════════════════════════════════════════════
#  UNLOCK DEFS TESTS
# ═══════════════════════════════════════════════════════════

func _test_unlock_defs_count() -> Dictionary:
	var defs = UnlockDefs.get_defs()
	if defs.size() < 35:
		return {"passed": false, "message": "expected 35+ unlocks, got %d" % defs.size()}
	return {"passed": true, "message": "%d unlock definitions" % defs.size()}


func _test_unlock_ids_unique() -> Dictionary:
	var ids = []
	for d in UnlockDefs.get_defs():
		if ids.has(d.id):
			return {"passed": false, "message": "duplicate id: " + d.id}
		ids.append(d.id)
	return {"passed": true, "message": "%d unique IDs" % ids.size()}


func _test_unlock_targets_valid() -> Dictionary:
	for d in UnlockDefs.get_defs():
		match d.unlock_type:
			UnlockDefs.UnlockableType.STAGE:
				var s = StageDefs.get_stage(d.target_id)
				if s["id"] != d.target_id:
					return {"passed": false, "message": "stage %d not found" % d.target_id}
			UnlockDefs.UnlockableType.ARCANA:
				var a = ArcanaDefs.get_arcana(d.target_id)
				if a["id"] != d.target_id:
					return {"passed": false, "message": "arcana %d not found" % d.target_id}
			UnlockDefs.UnlockableType.CHARACTER:
				# Characters not loaded here, just verify id range
				if d.target_id < 1 or d.target_id > 11:
					return {"passed": false, "message": "character %d out of range (1-11)" % d.target_id}
	return {"passed": true, "message": "all targets valid"}


func _test_unlock_types_match() -> Dictionary:
	# Verify that stage unlocks point to stages, arcana to arcanas, etc.
	for d in UnlockDefs.get_defs():
		if d.id.begins_with("stage_") and d.unlock_type != UnlockDefs.UnlockableType.STAGE:
			return {"passed": false, "message": "%s should be STAGE type" % d.id}
		if d.id.begins_with("arcana_") and d.unlock_type != UnlockDefs.UnlockableType.ARCANA:
			return {"passed": false, "message": "%s should be ARCANA type" % d.id}
		if d.id.begins_with("char_") and d.unlock_type != UnlockDefs.UnlockableType.CHARACTER:
			return {"passed": false, "message": "%s should be CHARACTER type" % d.id}
	return {"passed": true, "message": "all type hints match"}


func _test_unlock_lookup() -> Dictionary:
	# Verify lookup helpers
	var s1 = UnlockDefs.get_unlock_id_for_stage(1)
	if s1 != "stage_1":
		return {"passed": false, "message": "stage_1 lookup returned: " + s1}
	var a6 = UnlockDefs.get_unlock_id_for_arcana(6)
	if a6 != "arcana_6":
		return {"passed": false, "message": "arcana_6 lookup returned: " + a6}
	var def = UnlockDefs.get_def("arcana_8")
	if def == null:
		return {"passed": false, "message": "get_def returned null"}
	if def.target_id != 8:
		return {"passed": false, "message": "arcana_8 target_id should be 8"}
	return {"passed": true, "message": "lookup helpers OK"}


# ═══════════════════════════════════════════════════════════
#  ARCANA DEFS TESTS
# ═══════════════════════════════════════════════════════════

func _test_arcana_count() -> Dictionary:
	if ArcanaDefs.get_arcana_count() != 22:
		return {"passed": false, "message": "expected 22 arcanas, got %d" % ArcanaDefs.get_arcana_count()}
	return {"passed": true, "message": "22 arcanas"}


func _test_arcana_ids_unique() -> Dictionary:
	var ids = []
	for a in ArcanaDefs.ARCANAS:
		if ids.has(a["id"]):
			return {"passed": false, "message": "duplicate arcana id: " + str(a["id"])}
		ids.append(a["id"])
	return {"passed": true, "message": "%d unique arcana IDs" % ids.size()}


func _test_arcana_roman_unique() -> Dictionary:
	var romans = []
	for a in ArcanaDefs.ARCANAS:
		if romans.has(a["roman"]):
			return {"passed": false, "message": "duplicate roman: " + a["roman"]}
		romans.append(a["roman"])
	return {"passed": true, "message": "all roman numerals unique"}


func _test_arcana_effects_format() -> Dictionary:
	for a in ArcanaDefs.ARCANAS:
		if not a.has("effects") or a["effects"].is_empty():
			return {"passed": false, "message": "arcana %d has no effects" % a["id"]}
		if not a.has("listed_weapons"):
			return {"passed": false, "message": "arcana %d missing listed_weapons" % a["id"]}
	return {"passed": true, "message": "all arcanas have effects + listed_weapons"}


# ═══════════════════════════════════════════════════════════
#  UNLOCK MANAGER TESTS
# ═══════════════════════════════════════════════════════════

func _test_unlock_mgr_state() -> Dictionary:
	if UnlockManager == null:
		return {"passed": false, "message": "UnlockManager not initialized"}
	if UnlockManager.get_newly_unlocked() == null:
		return {"passed": false, "message": "get_newly_unlocked returns null"}
	return {"passed": true, "message": "UnlockManager responds to API"}


func _test_event_tracking() -> Dictionary:
	# Verify the manager can process events without crashing
	var prev_level = 0
	# Simulate a level-up event (should not crash even if no unlocks trigger)
	UnlockManager.on_player_leveled_up(5)
	UnlockManager.on_player_leveled_up(10)
	UnlockManager.on_stage_cleared(0)
	return {"passed": true, "message": "events processed without error"}


func _test_notification_tracking() -> Dictionary:
	# Verify mark_seen works
	var before = UnlockManager.get_newly_unlocked().duplicate()
	UnlockManager.mark_all_seen()
	var after = UnlockManager.get_newly_unlocked().size()
	if after != 0:
		# Restore
		for uid in before:
			pass
		return {"passed": false, "message": "mark_all_seen should clear, got %d items" % after}
	return {"passed": true, "message": "mark_all_seen clears notification queue"}


# ═══════════════════════════════════════════════════════════
#  ARCANA MANAGER TESTS
# ═══════════════════════════════════════════════════════════

func _test_arcana_mgr_api() -> Dictionary:
	if ArcanaManager == null:
		return {"passed": false, "message": "ArcanaManager not initialized"}
	if not ArcanaManager.is_system_enabled():
		# May be false if Randomazzo not collected — that's OK, API should still work
		pass
	if ArcanaManager.get_active_count() < 0:
		return {"passed": false, "message": "get_active_count returns negative"}
	return {"passed": true, "message": "ArcanaManager API responsive"}


func _test_arcana_effect_query() -> Dictionary:
	# Verify has_effect doesn't crash with empty active list
	var result = ArcanaManager.has_effect("healing_double")
	if result != false:
		return {"passed": false, "message": "has_effect should be false with no active arcanas"}
	result = ArcanaManager.has_any_effect(["healing_double", "revival_plus_3"])
	if result != false:
		return {"passed": false, "message": "has_any_effect should be false with no active arcanas"}
	return {"passed": true, "message": "effect queries safe with empty state"}
