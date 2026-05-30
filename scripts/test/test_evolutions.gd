# Test: Evolution recipes completeness
# Verifies that every defined weapon has an evolution recipe in weapon_manager.gd
# and that the required passive items exist in item_defs.gd.

static func run() -> Dictionary:
	var passed := 0
	var failed := 0
	var errors: Array[String] = []

	var ItemDefs = preload("res://scripts/data/item_defs.gd")
	var WM = preload("res://scripts/entities/weapon_manager.gd")

	# ── 1. Every weapon in WEAPON_TYPES should have an evolution recipe ──
	for t in ItemDefs.WEAPON_TYPES:
		if WM.EVOLUTION_RECIPES.has(t):
			passed += 1
		else:
			failed += 1
			errors.append("Weapon type %d (%s) has no evolution recipe" % [t, ItemDefs.item_name(t)])

	# ── 2. Every evolution recipe references a valid passive that exists ──
	for weapon_type in WM.EVOLUTION_RECIPES:
		var recipe = WM.EVOLUTION_RECIPES[weapon_type]
		var passive_id = recipe["passive"]
		var passive_name = ItemDefs.item_name(passive_id)
		# Verify passive exists in DATA
		if ItemDefs.DATA.has(passive_id):
			passed += 1
		else:
			failed += 1
			errors.append("Evolution for %d references non-existent passive %d" % [weapon_type, passive_id])

		# Verify passive_level is valid
		var max_lv = ItemDefs.item_max_level(passive_id)
		var req_lv = recipe["passive_level"]
		if req_lv <= max_lv and req_lv > 0:
			passed += 1
		else:
			failed += 1
			errors.append("Evolution for %d requires passive %d at level %d, but max is %d" % [weapon_type, passive_id, req_lv, max_lv])

	# ── 3. Recipes have name and desc ──
	for weapon_type in WM.EVOLUTION_RECIPES:
		var recipe = WM.EVOLUTION_RECIPES[weapon_type]
		if recipe.has("name") and recipe.has("desc"):
			passed += 1
		else:
			failed += 1
			errors.append("Evolution recipe for %d missing name or desc" % weapon_type)

	return {"passed": passed, "failed": failed, "errors": errors}
