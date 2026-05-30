extends Node

# PowerUpManager — autoload singleton
# Manages permanent meta-progression: gold + purchasable stat upgrades.
# Persistence delegated to SaveManager autoload.

# PowerUp definitions — 28 total (base game, no DLC)
# Values match https://vampire.survivors.wiki/w/PowerUps
const POWERUPS := {
	# ── Core stats ──
	"might":     {"name": "Might",     "desc": "+5% damage",              "max_lv": 5, "base_cost": 200},
	"max_hp":    {"name": "Max HP",    "desc": "+10% max health",         "max_lv": 3, "base_cost": 200},
	"recovery":  {"name": "Recovery",  "desc": "+0.1 HP/s regen",        "max_lv": 5, "base_cost": 200},
	"cooldown":  {"name": "Cooldown",  "desc": "-2.5% weapon cooldown",  "max_lv": 2, "base_cost": 900},
	"area":      {"name": "Area",      "desc": "+5% attack area",         "max_lv": 2, "base_cost": 300},
	"speed":     {"name": "Speed",     "desc": "+10% projectile speed",  "max_lv": 2, "base_cost": 300},
	"duration":  {"name": "Duration",  "desc": "+15% effect duration",    "max_lv": 2, "base_cost": 300},
	"amount":    {"name": "Amount",    "desc": "+1 projectile (all weapons)", "max_lv": 1, "base_cost": 5000},
	"movespeed": {"name": "Move Spd",  "desc": "+5% move speed",         "max_lv": 2, "base_cost": 600},
	"magnet":    {"name": "Magnet",    "desc": "+25% pickup range",       "max_lv": 2, "base_cost": 300},
	"luck":      {"name": "Luck",      "desc": "+10% luck",               "max_lv": 3, "base_cost": 600},
	"growth":    {"name": "Growth",    "desc": "+3% XP gain",             "max_lv": 5, "base_cost": 900},
	"greed":     {"name": "Greed",     "desc": "+10% gold earned",       "max_lv": 5, "base_cost": 200},
	"armor":     {"name": "Armor",     "desc": "+1 damage reduction",     "max_lv": 3, "base_cost": 600},
	"curse":     {"name": "Curse",     "desc": "+10% enemy difficulty",   "max_lv": 5, "base_cost": 1666},
	"revival":   {"name": "Revival",   "desc": "+1 revive (50% HP)",     "max_lv": 1, "base_cost": 10000},
	# ── Special stat boosts ──
	"omni":      {"name": "Omni",      "desc": "+2% Might/Speed/Dur/Area", "max_lv": 5, "base_cost": 1000},
	"charm":     {"name": "Charm",     "desc": "+20 enemy spawn count",   "max_lv": 5, "base_cost": 10000},
	"defang":    {"name": "Defang",    "desc": "+3% harmless enemies",    "max_lv": 5, "base_cost": 10},
	# ── Utility ──
	"reroll":    {"name": "Reroll",    "desc": "+2 reroll uses",          "max_lv": 5, "base_cost": 1000},
	"skip":      {"name": "Skip",      "desc": "+2 skip uses",            "max_lv": 5, "base_cost": 100},
	"banish":    {"name": "Banish",    "desc": "+2 banish uses",          "max_lv": 5, "base_cost": 100},
	"preserve":  {"name": "Preserve",  "desc": "+10% preserve chance",    "max_lv": 5, "base_cost": 500},
	# ── Seal ──
	"seal_i":    {"name": "Seal I",    "desc": "+1 seal slot",            "max_lv": 10, "base_cost": 10000},
	"seal_ii":   {"name": "Seal II",   "desc": "+2 seal slots",           "max_lv": 10, "base_cost": 10000},
	"seal_iii":  {"name": "Seal III",  "desc": "+3 seal slots",           "max_lv": 10, "base_cost": 10000},
	"seal_all":  {"name": "Seal All",  "desc": "+4 seal slots",           "max_lv": 10, "base_cost": 10000},
}

var gold: int = 0
var levels: Dictionary = {}
var unlocked_stages: int = 1
var unlocked_hyper: int = 0
var unlocked_chars: int = 1
var run_gold: int = 0
var run_rerolls: int = 0


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	_load_data()


# ── Persistence (delegated to SaveManager) ──

func _save_data():
	SaveManager.set_section("gold", gold)
	SaveManager.set_section("levels", levels.duplicate())
	SaveManager.set_section("unlocked_stages", unlocked_stages)
	SaveManager.set_section("unlocked_hyper", unlocked_hyper)
	SaveManager.set_section("unlocked_chars", unlocked_chars)


func _load_data():
	if not SaveManager.has_section("gold"):
		gold = 0
		levels = {}
		for id in POWERUPS:
			levels[id] = 0
		_save_data()
		return

	gold = SaveManager.get_section("gold", 0)
	levels = SaveManager.get_section("levels", {})
	unlocked_stages = SaveManager.get_section("unlocked_stages", 1)
	unlocked_hyper = SaveManager.get_section("unlocked_hyper", 0)
	unlocked_chars = SaveManager.get_section("unlocked_chars", 1)
	for id in POWERUPS:
		if not levels.has(id):
			levels[id] = 0


# ── Public API ──

func get_level(id: String) -> int:
	return levels.get(id, 0)


func get_gold() -> int:
	return gold


func add_gold(amount: int):
	gold += amount
	_save_data()


func buy_powerup(id: String) -> bool:
	if not POWERUPS.has(id):
		return false
	var info = POWERUPS[id]
	var cur_lv = levels.get(id, 0)
	if cur_lv >= info["max_lv"]:
		return false
	var cost = get_cost(id)
	if gold < cost:
		return false
	levels[id] = cur_lv + 1
	gold -= cost
	_save_data()
	return true


func get_cost(id: String) -> int:
	if not POWERUPS.has(id):
		return 999999
	var info = POWERUPS[id]
	var cur_lv = levels.get(id, 0)
	if cur_lv >= info["max_lv"]:
		return -1
	return info["base_cost"] * (1 + cur_lv)


func get_total_bought() -> int:
	var total = 0
	for id in POWERUPS:
		total += levels.get(id, 0)
	return total


# ── Unlock system ──

func unlock_stage(stage_id: int):
	unlocked_stages |= (1 << stage_id)
	_save_data()


func has_unlocked_stage(stage_id: int) -> bool:
	return (unlocked_stages & (1 << stage_id)) != 0


func unlock_hyper(stage_id: int):
	unlocked_hyper |= (1 << stage_id)
	_save_data()


func has_hyper(stage_id: int) -> bool:
	return (unlocked_hyper & (1 << stage_id)) != 0


func unlock_next_stage(current_id: int):
	unlock_stage(current_id + 1)


func unlock_character(char_id: int):
	unlocked_chars |= (1 << char_id)
	_save_data()


func has_unlocked_character(char_id: int) -> bool:
	return (unlocked_chars & (1 << char_id)) != 0


func buy_character(char_id: int, cost: int) -> bool:
	if has_unlocked_character(char_id):
		return false
	if gold < cost:
		return false
	gold -= cost
	unlock_character(char_id)
	_save_data()
	var um = EventBus.get_unlock_manager() if EventBus else null
	if um:
		um.purchase_unlock("char_" + str(char_id))
	return true


# ── Run gold management ──

func add_run_gold(amount: int):
	run_gold += amount


func add_reroll(amount: int):
	run_rerolls += amount


func end_run(save_run: bool = true):
	if save_run and run_gold > 0:
		var bonuses = get_stat_bonuses()
		var greed_mult = 1.0 + bonuses["greed_pct"]
		var final_gold = int(run_gold * greed_mult)
		if final_gold < 0:
			final_gold = 0
		add_gold(final_gold)
	reset_run_gold()


func reset_run_gold():
	run_gold = 0
	run_rerolls = 0


func get_stat_bonuses() -> Dictionary:
	var bonuses = {
		"damage_mult": 0.0,
		"max_hp_pct": 0.0,
		"recovery": 0.0,
		"cooldown_reduction": 0.0,
		"area_mult": 0.0,
		"projectile_speed_pct": 0.0,
		"duration_pct": 0.0,
		"amount": 0,
		"move_speed_pct": 0.0,
		"magnet_pct": 0.0,
		"luck_pct": 0.0,
		"growth_pct": 0.0,
		"greed_pct": 0.0,
		"armor": 0,
		"curse_pct": 0.0,
		"revivals": 0,
		"charm": 0,
		"defang_pct": 0.0,
		"reroll_uses": 0,
		"skip_uses": 0,
		"banish_uses": 0,
		"preserve_pct": 0.0,
		"seal_slots": 0,
	}
	for id in POWERUPS:
		var lv = levels.get(id, 0)
		if lv == 0:
			continue
		match id:
			"might":
				bonuses["damage_mult"] = 0.05 * lv
			"max_hp":
				bonuses["max_hp_pct"] = 0.10 * lv
			"recovery":
				bonuses["recovery"] = 0.1 * lv
			"cooldown":
				bonuses["cooldown_reduction"] = 0.025 * lv
			"area":
				bonuses["area_mult"] = 0.05 * lv
			"speed":
				bonuses["projectile_speed_pct"] = 0.10 * lv
			"duration":
				bonuses["duration_pct"] = 0.15 * lv
			"amount":
				bonuses["amount"] = 1 * lv
			"movespeed":
				bonuses["move_speed_pct"] = 0.05 * lv
			"magnet":
				bonuses["magnet_pct"] = 0.25 * lv
			"luck":
				bonuses["luck_pct"] = 0.10 * lv
			"growth":
				bonuses["growth_pct"] = 0.03 * lv
			"greed":
				bonuses["greed_pct"] = 0.10 * lv
			"armor":
				bonuses["armor"] = 1 * lv
			"curse":
				bonuses["curse_pct"] = 0.10 * lv
			"revival":
				bonuses["revivals"] = 1 * lv
			"omni":
				bonuses["damage_mult"] += 0.02 * lv
				bonuses["projectile_speed_pct"] += 0.02 * lv
				bonuses["duration_pct"] += 0.02 * lv
				bonuses["area_mult"] += 0.02 * lv
			"charm":
				bonuses["charm"] = 20 * lv
			"defang":
				bonuses["defang_pct"] = 0.03 * lv
			"reroll":
				bonuses["reroll_uses"] = 2 * lv
			"skip":
				bonuses["skip_uses"] = 2 * lv
			"banish":
				bonuses["banish_uses"] = 2 * lv
			"preserve":
				bonuses["preserve_pct"] = 0.10 * lv
			"seal_i":
				bonuses["seal_slots"] += 1 * lv
			"seal_ii":
				bonuses["seal_slots"] += 2 * lv
			"seal_iii":
				bonuses["seal_slots"] += 3 * lv
			"seal_all":
				bonuses["seal_slots"] += 4 * lv
	return bonuses
