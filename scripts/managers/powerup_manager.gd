extends Node

# PowerUpManager — autoload singleton
# Manages permanent meta-progression: gold + purchasable stat upgrades.

const SAVE_PATH := "user://desire_survivors_save.json"

# PowerUp definitions
# id: { name, desc, per_level (effect string), max_lv, base_cost }
const POWERUPS := {
	"might":     {"name": "Might",     "desc": "+5% damage",              "max_lv": 5, "base_cost": 200},
	"max_hp":    {"name": "Max HP",    "desc": "+10% max health",         "max_lv": 3, "base_cost": 200},
	"recovery":  {"name": "Recovery",  "desc": "+0.1 HP/s regen",        "max_lv": 5, "base_cost": 200},
	"cooldown":  {"name": "Cooldown",  "desc": "-2.5% weapon cooldown",  "max_lv": 2, "base_cost": 900},
	"area":      {"name": "Area",      "desc": "+5% attack area",         "max_lv": 2, "base_cost": 300},
	"movespeed": {"name": "Move Spd",  "desc": "+5% move speed",         "max_lv": 2, "base_cost": 600},
	"growth":    {"name": "Growth",    "desc": "+3% XP gain",             "max_lv": 5, "base_cost": 900},
	"greed":     {"name": "Greed",     "desc": "+10% gold earned",       "max_lv": 5, "base_cost": 200},
	"armor":     {"name": "Armor",     "desc": "+1 armor (dmg reduction)","max_lv": 3, "base_cost": 600},
}

# Runtime state
var gold: int = 0
var levels: Dictionary = {}  # powerup_id -> current level (0 = not bought)

# Unlock state — bitmasks
var unlocked_stages: int = 1      # bit 0 = stage 0 (Mad Forest) always unlocked
var unlocked_hyper: int = 0       # bit N = hyper mode for stage N
var unlocked_chars: int = 1       # bit 0 = char 0 (Antonio) always unlocked

# Run-local gold accumulator (not saved until game over)
var run_gold: int = 0


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	_load_data()


# ── Persistence ────────────────────────────────────────────

func _save_data():
	# Read existing save data to preserve relic state written by RelicManager
	var data = _read_raw_save()
	data["gold"] = gold
	data["levels"] = levels.duplicate()
	data["unlocked_stages"] = unlocked_stages
	data["unlocked_hyper"] = unlocked_hyper
	data["unlocked_chars"] = unlocked_chars
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


# Read raw save data preserving all fields (used by RelicManager too)
func _read_raw_save() -> Dictionary:
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


func _load_data():
	if not FileAccess.file_exists(SAVE_PATH):
		# First launch — initialise defaults
		gold = 0
		levels = {}
		for id in POWERUPS:
			levels[id] = 0
		_save_data()
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		return
	var data = json.data
	gold = data.get("gold", 0)
	levels = data.get("levels", {})
	unlocked_stages = data.get("unlocked_stages", 1)
	unlocked_hyper = data.get("unlocked_hyper", 0)
	unlocked_chars = data.get("unlocked_chars", 1)
	# Ensure every powerup exists in levels dict
	for id in POWERUPS:
		if not levels.has(id):
			levels[id] = 0


# ── Public API ─────────────────────────────────────────────

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
		return false  # already maxed
	
	var cost = get_cost(id)
	if gold < cost:
		return false  # not enough gold
	
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
		return -1  # maxed
	# Base cost increases per level
	return info["base_cost"] * (1 + cur_lv)


func get_total_bought() -> int:
	var total = 0
	for id in POWERUPS:
		total += levels.get(id, 0)
	return total


# ── Unlock system ──────────────────────────────────────────

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


# Unlock the next stage after current_id (stage id = current_id + 1)
func unlock_next_stage(current_id: int):
	var next_id = current_id + 1
	unlock_stage(next_id)


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
	# Notify UnlockManager for notification tracking
	if UnlockManager:
		UnlockManager.purchase_unlock("char_" + str(char_id))
	return true


# ── Run gold management ────────────────────────────────────

func add_run_gold(amount: int):
	run_gold += amount


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


# ── Stats applied to Player ────────────────────────────────
# Returns a dictionary of bonus stats keys
func get_stat_bonuses() -> Dictionary:
	var bonuses = {
		"damage_mult": 0.0,
		"max_hp_pct": 0.0,
		"recovery": 0.0,
		"cooldown_reduction": 0.0,
		"area_mult": 0.0,
		"move_speed_pct": 0.0,
		"growth_pct": 0.0,
		"greed_pct": 0.0,
		"armor": 0,
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
			"movespeed":
				bonuses["move_speed_pct"] = 0.05 * lv
			"growth":
				bonuses["growth_pct"] = 0.03 * lv
			"greed":
				bonuses["greed_pct"] = 0.10 * lv
			"armor":
				bonuses["armor"] = 1 * lv
	return bonuses
