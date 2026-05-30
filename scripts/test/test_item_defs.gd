# Test: Item definitions completeness and correctness
# Verifies all base game passive items and weapons are defined.

static func run() -> Dictionary:
	var passed := 0
	var failed := 0
	var errors: Array[String] = []

	var ItemDefs = preload("res://scripts/data/item_defs.gd")

	# ── 1. Count checks ──
	var total_entries = ItemDefs.DATA.size()
	# 11 original weapons + 6 new weapons + 17 passives + 4 special passives = 38
	var expected_count = 38
	if total_entries == expected_count:
		passed += 1
	else:
		failed += 1
		errors.append("Expected %d DATA entries, got %d" % [expected_count, total_entries])

	# ── 2. Passive item count ──
	var passives = []
	for t in ItemDefs.DATA:
		if not ItemDefs.is_weapon(t):
			passives.append(t)
	var expected_passives = 21  # 17 normal + 4 special
	if passives.size() == expected_passives:
		passed += 1
	else:
		failed += 1
		errors.append("Expected %d passives, got %d" % [expected_passives, passives.size()])

	# ── 3. Weapon count ──
	var weapons = []
	for t in ItemDefs.DATA:
		if ItemDefs.is_weapon(t):
			weapons.append(t)
	var expected_weapons = 17  # 11 original + 6 new
	if weapons.size() == expected_weapons:
		passed += 1
	else:
		failed += 1
		errors.append("Expected %d weapons, got %d" % [expected_weapons, weapons.size()])

	# ── 4. Every entry has required fields ──
	for t in ItemDefs.DATA:
		var d = ItemDefs.DATA[t]
		var missing := PackedStringArray()
		for key in ["name", "name_key", "desc", "desc_key", "color", "is_weapon", "max_level"]:
			if not d.has(key):
				missing.append(key)
		if missing.is_empty():
			passed += 1
		else:
			failed += 1
			errors.append("Type %d missing fields: %s" % [t, ", ".join(missing)])

	# ── 5. All weapons have evo_key ──
	for t in ItemDefs.WEAPON_TYPES:
		if not ItemDefs.DATA[t].has("evo_key"):
			failed += 1
			errors.append("Weapon %d missing evo_key" % t)
		else:
			passed += 1

	# ── 6. Attractorb renamed properly ──
	var magnet_data = ItemDefs.DATA[15]
	if magnet_data["name"] == "Attractorb":
		passed += 1
	else:
		failed += 1
		errors.append("Type 15 name should be 'Attractorb', got '%s'" % magnet_data["name"])

	# ── 7. New weapons exist ──
	var new_weapons = [32, 33, 34, 35, 36, 37]
	for tid in new_weapons:
		if ItemDefs.DATA.has(tid) and ItemDefs.is_weapon(tid):
			passed += 1
		else:
			failed += 1
			errors.append("Missing weapon type %d" % tid)

	return {"passed": passed, "failed": failed, "errors": errors}
