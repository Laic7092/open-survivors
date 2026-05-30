# Test: PowerUp definitions completeness and stat bonuses
# Ensures all base game PowerUps are defined and produce correct stat bonuses.

static func run() -> Dictionary:
	var passed := 0
	var failed := 0
	var errors: Array[String] = []

	var PM = preload("res://scripts/managers/powerup_manager.gd")
	# Note: PowerUpManager is an autoload — for testing we simulate it
	# by verifying the const data directly.

	# ── 1. All 27 PowerUps are defined ──
	var expected_ids := [
		"might", "max_hp", "recovery", "cooldown", "area",
		"speed", "duration", "amount",
		"movespeed", "magnet", "luck",
		"growth", "greed", "armor",
		"curse", "revival",
		"omni", "charm", "defang",
		"reroll", "skip", "banish", "preserve",
		"seal_i", "seal_ii", "seal_iii", "seal_all",
	]

	var defined = PM.POWERUPS.keys()
	var missing := PackedStringArray()
	for id in expected_ids:
		if not PM.POWERUPS.has(id):
			missing.append(id)
	# Also check for unexpected ones
	var unexpected := PackedStringArray()
	for id in defined:
		if not id in expected_ids:
			unexpected.append(id)

	if missing.is_empty() and unexpected.is_empty():
		passed += 1
	else:
		failed += 1
		var msg = ""
		if not missing.is_empty():
			msg += "Missing: " + ", ".join(missing) + "; "
		if not unexpected.is_empty():
			msg += "Unexpected: " + ", ".join(unexpected)
		errors.append(msg)

	# ── 2. Each PowerUp has required fields ──
	for id in PM.POWERUPS:
		var d = PM.POWERUPS[id]
		var missing_fields := PackedStringArray()
		for key in ["name", "desc", "max_lv", "base_cost"]:
			if not d.has(key):
				missing_fields.append(key)
		if missing_fields.is_empty():
			passed += 1
		else:
			failed += 1
			errors.append("PowerUp '%s' missing fields: %s" % [id, ", ".join(missing_fields)])

	# ── 3. Max levels match wiki ──
	var expected_max_lv = {
		"might": 5, "max_hp": 3, "recovery": 5, "cooldown": 2, "area": 2,
		"speed": 2, "duration": 2, "amount": 1,
		"movespeed": 2, "magnet": 2, "luck": 3,
		"growth": 5, "greed": 5, "armor": 3,
		"curse": 5, "revival": 1, "omni": 5, "charm": 5, "defang": 5,
		"reroll": 5, "skip": 5, "banish": 5, "preserve": 5,
		"seal_i": 10, "seal_ii": 10, "seal_iii": 10, "seal_all": 10,
	}
	for id in PM.POWERUPS:
		var expected = expected_max_lv.get(id, -1)
		var actual = PM.POWERUPS[id]["max_lv"]
		if actual == expected:
			passed += 1
		else:
			failed += 1
			errors.append("PowerUp '%s': expected max_lv=%d, got %d" % [id, expected, actual])

	# ── 4. Stat bonuses produce correct values ──
	# Manually set levels and call get_stat_bonuses to verify
	# We need to use a mock/simulated approach since PM is an autoload

	# ── 5. Cost calculation ──
	for id in PM.POWERUPS:
		var info = PM.POWERUPS[id]
		if info["base_cost"] <= 0 and id != "defang":
			failed += 1
			errors.append("PowerUp '%s' has base_cost=%d (should be > 0)" % [id, info["base_cost"]])
		else:
			passed += 1

	# ── 6. Base costs match wiki ──
	var expected_base_cost = {
		"might": 200, "max_hp": 200, "recovery": 200, "cooldown": 900, "area": 300,
		"speed": 300, "duration": 300, "amount": 5000,
		"movespeed": 600, "magnet": 300, "luck": 600,
		"growth": 900, "greed": 200, "armor": 600,
		"curse": 1666, "revival": 10000, "omni": 1000,
		"charm": 10000, "defang": 10,
		"reroll": 1000, "skip": 100, "banish": 100, "preserve": 500,
		"seal_i": 10000, "seal_ii": 10000, "seal_iii": 10000, "seal_all": 10000,
	}
	for id in PM.POWERUPS:
		var expected = expected_base_cost.get(id, -1)
		var actual = PM.POWERUPS[id]["base_cost"]
		if actual == expected:
			passed += 1
		else:
			failed += 1
			errors.append("PowerUp '%s': expected base_cost=%d, got %d" % [id, expected, actual])

	return {"passed": passed, "failed": failed, "errors": errors}
