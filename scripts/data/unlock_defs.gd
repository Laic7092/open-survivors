extends RefCounted
# Unlock definitions — centralized condition table for every unlockable.
# Each entry defines WHAT unlocks, WHAT TYPE it is, and WHAT CONDITIONS must be met.
# Conditions are AND logic: ALL conditions must be satisfied.
#
# Types:
#   STAGE     — a playable stage (target_id matches stage_defs.gd id)
#   ARCANA    — an Arcana card (target_id matches arcana_defs.gd id)
#   CHARACTER — a playable character (target_id matches character_defs.gd id)
#
# Condition types:
#   STAGE_CLEARED  → params: {stage_id}
#   PLAYER_LEVEL   → params: {min_level}
#   RELIC_OWNED    → params: {relic_id}

# Enums imported from shared tiny file so match patterns work everywhere
const UnlockTypes = preload("res://scripts/data/unlock_types.gd")
const UnlockableType = UnlockTypes.UnlockableType
const ConditionType = UnlockTypes.ConditionType

class UnlockCondition:
	var type: ConditionType
	var params: Dictionary  # varies by type
	
	func _init(t: ConditionType, p: Dictionary):
		type = t
		params = p
	
	func description() -> String:
		match type:
			ConditionType.STAGE_CLEARED:
				var stage_id = params.get("stage_id", -1)
				return "Clear stage %d" % stage_id
			ConditionType.PLAYER_LEVEL:
				return "Reach level %d in a run" % params.get("min_level", 0)
			ConditionType.RELIC_OWNED:
				return "Collect relic: %s" % params.get("relic_id", "?")
			ConditionType.SURVIVE_CHAR_TIME:
				var t = params.get("min_time", 0) / 60
				var char_id = params.get("char_id", -1)
				if char_id >= 0:
					return "Survive %d min with char %d" % [t, char_id]
				return "Survive %d min" % t
			ConditionType.TOTAL_KILLS:
				return "Accumulate %d total kills" % params.get("min_kills", 0)
			ConditionType.WEAPON_AT_LEVEL:
				return "Upgrade weapon %d to level %d" % [params.get("weapon_type", 0), params.get("min_level", 0)]
			ConditionType.ITEM_FOUND:
				return "Find item %d" % params.get("item_type", 0)
			ConditionType.DESTROY_LIGHT_SOURCES:
				return "Destroy %d light sources" % params.get("count", 0)
			ConditionType.START_WITH_CHAR:
				return "Start a run with character %d" % params.get("char_id", 0)
			ConditionType.ALL_EVOLUTIONS:
				return "Evolve all weapons in a run"
			ConditionType.RUN_KILLS:
				return "Kill %d enemies in one run" % params.get("min_kills", 0)
			ConditionType.CHAR_LEVEL:
				return "Reach character level %d" % params.get("min_level", 0)
			ConditionType.HAVE_WEAPONS_COUNT:
				return "Have %d different weapons in one run" % params.get("min_count", 6)
			ConditionType.PICKUP_COLLECTED:
				return "Collect pickup: %s" % params.get("pickup_type", "?")
			_:
				return "Unknown condition"


class UnlockDef:
	var id: String           # unique string key, e.g. "stage_1", "arcana_6"
	var unlock_type: UnlockableType
	var target_id: int       # the actual numeric ID in the target system
	var conditions: Array    # Array[UnlockCondition] — all must pass
	var name_key: String     # i18n key for display name
	var desc_key: String     # i18n key for description
	var icon_hint: String    # optional: for UI badge
	
	func _init(p_id: String, ut: UnlockableType, tid: int, conds: Array, nk: String = "", dk: String = "", ic: String = ""):
		id = p_id
		unlock_type = ut
		target_id = tid
		conditions = conds
		name_key = nk
		desc_key = dk
		icon_hint = ic


# ── Master table ──────────────────────────────────────────

static func get_defs() -> Array:
	return _ALL_DEFS


static func get_def(id: String) -> UnlockDef:
	for d in _ALL_DEFS:
		if d.id == id:
			return d
	return null


static func get_defs_for_type(ut: UnlockableType) -> Array:
	var result: Array = []
	for d in _ALL_DEFS:
		if d.unlock_type == ut:
			result.append(d)
	return result


static func get_unlock_id_for_arcana(arcana_id: int) -> String:
	for d in _ALL_DEFS:
		if d.unlock_type == UnlockableType.ARCANA and d.target_id == arcana_id:
			return d.id
	return ""


static func get_unlock_id_for_stage(stage_id: int) -> String:
	for d in _ALL_DEFS:
		if d.unlock_type == UnlockableType.STAGE and d.target_id == stage_id:
			return d.id
	return ""

static func get_unlock_id_for_item(item_id: int) -> String:
	for d in _ALL_DEFS:
		if d.unlock_type == UnlockableType.ITEM and d.target_id == item_id:
			return d.id
	return ""


# ── All unlock definitions ──

static var _ALL_DEFS: Array = [
	# ═══════════════════════════════════════════════════════
	#  STAGES
	# ═══════════════════════════════════════════════════════
	UnlockDef.new(
		"stage_1", UnlockableType.STAGE, 1,
		[UnlockCondition.new(ConditionType.STAGE_CLEARED, {"stage_id": 0})],
		"stage.1_name", "stage.1_desc", "stage"
	),
	UnlockDef.new(
		"stage_2", UnlockableType.STAGE, 2,
		[UnlockCondition.new(ConditionType.STAGE_CLEARED, {"stage_id": 1})],
		"stage.2_name", "stage.2_desc", "stage"
	),
	UnlockDef.new(
		"stage_3", UnlockableType.STAGE, 3,
		[UnlockCondition.new(ConditionType.STAGE_CLEARED, {"stage_id": 2})],
		"stage.3_name", "stage.3_desc", "stage"
	),
	UnlockDef.new(
		"stage_4", UnlockableType.STAGE, 4,
		[UnlockCondition.new(ConditionType.STAGE_CLEARED, {"stage_id": 3})],
		"stage.4_name", "stage.4_desc", "stage"
	),
	UnlockDef.new(
		"stage_5", UnlockableType.STAGE, 5,
		[UnlockCondition.new(ConditionType.STAGE_CLEARED, {"stage_id": 4})],
		"stage.5_name", "stage.5_desc", "stage"
	),
	UnlockDef.new(
		"stage_6", UnlockableType.STAGE, 6,
		[UnlockCondition.new(ConditionType.STAGE_CLEARED, {"stage_id": 5})],
		"stage.6_name", "stage.6_desc", "stage"
	),
	UnlockDef.new(
		"stage_7", UnlockableType.STAGE, 7,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 40})],
		"stage.7_name", "stage.7_desc", "stage"
	),
	UnlockDef.new(
		"stage_8", UnlockableType.STAGE, 8,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 50})],
		"stage.8_name", "stage.8_desc", "stage"
	),
	UnlockDef.new(
		"stage_9", UnlockableType.STAGE, 9,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 60})],
		"stage.9_name", "stage.9_desc", "stage"
	),
	UnlockDef.new(
		"stage_10", UnlockableType.STAGE, 10,
		[UnlockCondition.new(ConditionType.STAGE_CLEARED, {"stage_id": 3})],
		"stage.10_name", "stage.10_desc", "stage"
	),
	UnlockDef.new(
		"stage_11", UnlockableType.STAGE, 11,
		[UnlockCondition.new(ConditionType.STAGE_CLEARED, {"stage_id": 4})],
		"stage.11_name", "stage.11_desc", "stage"
	),
	UnlockDef.new(
		"stage_12", UnlockableType.STAGE, 12,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 30})],
		"stage.12_name", "stage.12_desc", "stage"
	),
	UnlockDef.new(
		"stage_13", UnlockableType.STAGE, 13,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 55})],
		"stage.13_name", "stage.13_desc", "stage"
	),
	UnlockDef.new(
		"stage_14", UnlockableType.STAGE, 14,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 65})],
		"stage.14_name", "stage.14_desc", "stage"
	),
	UnlockDef.new(
		"stage_15", UnlockableType.STAGE, 15,
		[UnlockCondition.new(ConditionType.RELIC_OWNED, {"relic_id": "yellow_sign"})],
		"stage.15_name", "stage.15_desc", "stage"
	),

	# ═══════════════════════════════════════════════════════
	#  ARCANAS
	# ═══════════════════════════════════════════════════════

	# Arcana 0 — Game Killer: Clear final stage
	UnlockDef.new(
		"arcana_0", UnlockableType.ARCANA, 0,
		[UnlockCondition.new(ConditionType.STAGE_CLEARED, {"stage_id": 2})],
		"arcana.0_name", "arcana.0_desc", "arcana"
	),

	# Arcana I-V: Character level unlocks (level 30)
	UnlockDef.new(
		"arcana_1", UnlockableType.ARCANA, 1,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 30})],
		"arcana.1_name", "arcana.1_desc", "arcana"
	),
	UnlockDef.new(
		"arcana_2", UnlockableType.ARCANA, 2,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 30})],
		"arcana.2_name", "arcana.2_desc", "arcana"
	),
	UnlockDef.new(
		"arcana_3", UnlockableType.ARCANA, 3,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 30})],
		"arcana.3_name", "arcana.3_desc", "arcana"
	),
	UnlockDef.new(
		"arcana_4", UnlockableType.ARCANA, 4,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 30})],
		"arcana.4_name", "arcana.4_desc", "arcana"
	),
	UnlockDef.new(
		"arcana_5", UnlockableType.ARCANA, 5,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 30})],
		"arcana.5_name", "arcana.5_desc", "arcana"
	),

	# Arcana VI — Sarabande of Healing: Randomazzo relic
	UnlockDef.new(
		"arcana_6", UnlockableType.ARCANA, 6,
		[UnlockCondition.new(ConditionType.RELIC_OWNED, {"relic_id": "randomazzo"})],
		"arcana.6_name", "arcana.6_desc", "arcana"
	),

	# Arcana VII-XI: Character level unlocks
	UnlockDef.new(
		"arcana_7", UnlockableType.ARCANA, 7,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 30})],
		"arcana.7_name", "arcana.7_desc", "arcana"
	),

	# Arcana VIII — Mad Groove: Clear stage 0
	UnlockDef.new(
		"arcana_8", UnlockableType.ARCANA, 8,
		[UnlockCondition.new(ConditionType.STAGE_CLEARED, {"stage_id": 0})],
		"arcana.8_name", "arcana.8_desc", "arcana"
	),

	UnlockDef.new(
		"arcana_9", UnlockableType.ARCANA, 9,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 30})],
		"arcana.9_name", "arcana.9_desc", "arcana"
	),
	UnlockDef.new(
		"arcana_10", UnlockableType.ARCANA, 10,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 30})],
		"arcana.10_name", "arcana.10_desc", "arcana"
	),
	UnlockDef.new(
		"arcana_11", UnlockableType.ARCANA, 11,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 30})],
		"arcana.11_name", "arcana.11_desc", "arcana"
	),

	# Arcana XII — Out of Bounds: Clear stage 1
	UnlockDef.new(
		"arcana_12", UnlockableType.ARCANA, 12,
		[UnlockCondition.new(ConditionType.STAGE_CLEARED, {"stage_id": 1})],
		"arcana.12_name", "arcana.12_desc", "arcana"
	),

	UnlockDef.new(
		"arcana_13", UnlockableType.ARCANA, 13,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 30})],
		"arcana.13_name", "arcana.13_desc", "arcana"
	),
	UnlockDef.new(
		"arcana_14", UnlockableType.ARCANA, 14,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 30})],
		"arcana.14_name", "arcana.14_desc", "arcana"
	),

	# Arcana XV — Disco of Gold: Clear stage 1
	UnlockDef.new(
		"arcana_15", UnlockableType.ARCANA, 15,
		[UnlockCondition.new(ConditionType.STAGE_CLEARED, {"stage_id": 1})],
		"arcana.15_name", "arcana.15_desc", "arcana"
	),

	UnlockDef.new(
		"arcana_16", UnlockableType.ARCANA, 16,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 30})],
		"arcana.16_name", "arcana.16_desc", "arcana"
	),
	UnlockDef.new(
		"arcana_17", UnlockableType.ARCANA, 17,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 30})],
		"arcana.17_name", "arcana.17_desc", "arcana"
	),
	UnlockDef.new(
		"arcana_18", UnlockableType.ARCANA, 18,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 30})],
		"arcana.18_name", "arcana.18_desc", "arcana"
	),
	UnlockDef.new(
		"arcana_19", UnlockableType.ARCANA, 19,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 30})],
		"arcana.19_name", "arcana.19_desc", "arcana"
	),

	# Arcana XX — Silent Old Sanctuary: Clear stage 2
	UnlockDef.new(
		"arcana_20", UnlockableType.ARCANA, 20,
		[UnlockCondition.new(ConditionType.STAGE_CLEARED, {"stage_id": 2})],
		"arcana.20_name", "arcana.20_desc", "arcana"
	),

	UnlockDef.new(
		"arcana_21", UnlockableType.ARCANA, 21,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 30})],
		"arcana.21_name", "arcana.21_desc", "arcana"
	),

	# ═══════════════════════════════════════════════════════
	#  CHARACTERS (gold-purchase tracked as unlocks for notification)
	# ═══════════════════════════════════════════════════════
	# Characters 1-11 are purchased with gold.
	# They appear here so the notification system knows about them.
	# The purchase logic stays in PowerUpManager.
	UnlockDef.new(
		"char_1", UnlockableType.CHARACTER, 1,
		[],  # no auto-condition — purchased via gold
		"char.1_name", "char.1_desc", "character"
	),
	UnlockDef.new(
		"char_2", UnlockableType.CHARACTER, 2,
		[],
		"char.2_name", "char.2_desc", "character"
	),
	UnlockDef.new(
		"char_3", UnlockableType.CHARACTER, 3,
		[],
		"char.3_name", "char.3_desc", "character"
	),
	UnlockDef.new(
		"char_4", UnlockableType.CHARACTER, 4,
		[],
		"char.4_name", "char.4_desc", "character"
	),
	UnlockDef.new(
		"char_5", UnlockableType.CHARACTER, 5,
		[],
		"char.5_name", "char.5_desc", "character"
	),
	UnlockDef.new(
		"char_6", UnlockableType.CHARACTER, 6,
		[],
		"char.6_name", "char.6_desc", "character"
	),
	UnlockDef.new(
		"char_7", UnlockableType.CHARACTER, 7,
		[],
		"char.7_name", "char.7_desc", "character"
	),
	UnlockDef.new(
		"char_8", UnlockableType.CHARACTER, 8,
		[],
		"char.8_name", "char.8_desc", "character"
	),
	UnlockDef.new(
		"char_9", UnlockableType.CHARACTER, 9,
		[],
		"char.9_name", "char.9_desc", "character"
	),
	UnlockDef.new(
		"char_10", UnlockableType.CHARACTER, 10,
		[],
		"char.10_name", "char.10_desc", "character"
	),
	UnlockDef.new(
		"char_11", UnlockableType.CHARACTER, 11,
		[],
		"char.11_name", "char.11_desc", "character"
	),

	# ═══════════════════════════════════════════════════════
	#  ITEMS (weapons)
	# ═══════════════════════════════════════════════════════
	# Default-unlocked weapons have empty conditions array.
	# Conditioned weapons require ALL conditions to be met.

	# Pentagram — default unlocked
	UnlockDef.new(
		"item_32", UnlockableType.ITEM, 32,
		[],
		"item.pentagram_name", "item.pentagram_desc"
	),
	# Peachone — default unlocked
	UnlockDef.new(
		"item_33", UnlockableType.ITEM, 33,
		[],
		"item.peachone_name", "item.peachone_desc"
	),
	# Ebony Wings — default unlocked
	UnlockDef.new(
		"item_34", UnlockableType.ITEM, 34,
		[],
		"item.ebony_wings_name", "item.ebony_wings_desc"
	),
	# Phiera Der Tuphello — default unlocked
	UnlockDef.new(
		"item_35", UnlockableType.ITEM, 35,
		[],
		"item.phiera_name", "item.phiera_desc"
	),
	# Eight The Sparrow — default unlocked
	UnlockDef.new(
		"item_36", UnlockableType.ITEM, 36,
		[],
		"item.eight_name", "item.eight_desc"
	),
	# Gatti Amari — default unlocked
	UnlockDef.new(
		"item_37", UnlockableType.ITEM, 37,
		[],
		"item.gatti_amari_name", "item.gatti_amari_desc"
	),
	# Song of Mana — default unlocked
	UnlockDef.new(
		"item_38", UnlockableType.ITEM, 38,
		[],
		"item.song_of_mana_name", "item.song_of_mana_desc"
	),
	# Shadow Pinion — default unlocked
	UnlockDef.new(
		"item_39", UnlockableType.ITEM, 39,
		[],
		"item.shadow_pinion_name", "item.shadow_pinion_desc"
	),
	# Bracelet — default unlocked
	UnlockDef.new(
		"item_49", UnlockableType.ITEM, 49,
		[],
		"item.bracelet_name", "item.bracelet_desc"
	),
	# Clock Lancet — survive 30 min
	UnlockDef.new(
		"item_40", UnlockableType.ITEM, 40,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 1800})],
		"item.clock_lancet_name", "item.clock_lancet_desc"
	),
	# Laurel — survive 30 min
	UnlockDef.new(
		"item_41", UnlockableType.ITEM, 41,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 1800})],
		"item.laurel_name", "item.laurel_desc"
	),
	# Vento Sacro — survive 30 min
	UnlockDef.new(
		"item_42", UnlockableType.ITEM, 42,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 1800})],
		"item.vento_sacro_name", "item.vento_sacro_desc"
	),
	# Bone — survive 30 min
	UnlockDef.new(
		"item_43", UnlockableType.ITEM, 43,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 1800})],
		"item.bone_name", "item.bone_desc"
	),
	# Greatest Jubilee — survive 30 min
	UnlockDef.new(
		"item_48", UnlockableType.ITEM, 48,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 1800})],
		"item.greatest_jubilee_name", "item.greatest_jubilee_desc"
	),
	# Victory Sword — survive 30 min
	UnlockDef.new(
		"item_51", UnlockableType.ITEM, 51,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 1800})],
		"item.victory_sword_name", "item.victory_sword_desc"
	),
	# Glass Fandango — survive 30 min
	UnlockDef.new(
		"item_56", UnlockableType.ITEM, 56,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 1800})],
		"item.glass_fandango_name", "item.glass_fandango_desc"
	),
	# Santa Javelin — survive 30 min
	UnlockDef.new(
		"item_57", UnlockableType.ITEM, 57,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 1800})],
		"item.santa_javelin_name", "item.santa_javelin_desc"
	),
	# Gaze of Gaea — survive 30 min
	UnlockDef.new(
		"item_58", UnlockableType.ITEM, 58,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 1800})],
		"item.gaze_of_gaea_name", "item.gaze_of_gaea_desc"
	),
	# Magi Stone — survive 30 min
	UnlockDef.new(
		"item_59", UnlockableType.ITEM, 59,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 1800})],
		"item.magi_stone_name", "item.magi_stone_desc"
	),
	# Phas3r — survive 15 min with She-Mush (char 6)
	UnlockDef.new(
		"item_60", UnlockableType.ITEM, 60,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 900, "char_id": 6})],
		"item.phas3r_name", "item.phas3r_desc"
	),
	# Cherry Bomb — survive 15 min with Lama (char 2)
	UnlockDef.new(
		"item_44", UnlockableType.ITEM, 44,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 900, "char_id": 2})],
		"item.cherry_bomb_name", "item.cherry_bomb_desc"
	),
	# Carrello — survive 15 min with Pugnala (char 3)
	UnlockDef.new(
		"item_45", UnlockableType.ITEM, 45,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 900, "char_id": 3})],
		"item.carrello_name", "item.carrello_desc"
	),
	# Celestial Dusting — survive 15 min with Poppea (char 4)
	UnlockDef.new(
		"item_46", UnlockableType.ITEM, 46,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 900, "char_id": 4})],
		"item.celestial_dusting_name", "item.celestial_dusting_desc"
	),
	# La Robba — survive 15 min with Concetta (char 5)
	UnlockDef.new(
		"item_47", UnlockableType.ITEM, 47,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 900, "char_id": 5})],
		"item.la_robba_name", "item.la_robba_desc"
	),
	# Flames of Misspell — survive 15 min with Avatar (char 7)
	UnlockDef.new(
		"item_52", UnlockableType.ITEM, 52,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 900, "char_id": 7})],
		"item.flames_of_misspell_name", "item.flames_of_misspell_desc"
	),
	# Pako Battiliar — survive 15 min with O'Soul (char 8)
	UnlockDef.new(
		"item_53", UnlockableType.ITEM, 53,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 900, "char_id": 8})],
		"item.pako_battiliar_name", "item.pako_battiliar_desc"
	),
	# Ammo Appalate — survive 15 min with Zi'Assunta (char 9)
	UnlockDef.new(
		"item_54", UnlockableType.ITEM, 54,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 900, "char_id": 9})],
		"item.ammo_appalate_name", "item.ammo_appalate_desc"
	),
	# Chaos Rune — survive 15 min with Sigma (char 10)
	UnlockDef.new(
		"item_55", UnlockableType.ITEM, 55,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 900, "char_id": 10})],
		"item.chaos_rune_name", "item.chaos_rune_desc"
	),
	# Arma Dio — total kills 10000
	UnlockDef.new(
		"item_61", UnlockableType.ITEM, 61,
		[UnlockCondition.new(ConditionType.TOTAL_KILLS, {"min_kills": 10000})],
		"item.arma_dio_name", "item.arma_dio_desc"
	),
	# Candybox — all evolutions collected in a run
	UnlockDef.new(
		"item_50", UnlockableType.ITEM, 50,
		[UnlockCondition.new(ConditionType.ALL_EVOLUTIONS, {})],
		"item.candybox_name", "item.candybox_desc"
	),

	# ═══════════════════════════════════════════════════════
	#  PASSIVE ITEMS
	# ═══════════════════════════════════════════════════════

	# Wings (3) — reach level 5
	UnlockDef.new(
		"item_3", UnlockableType.ITEM, 3,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 5})],
		"item.wings_name", "item.wings_desc"
	),
	# Spinach (4) — default unlocked
	UnlockDef.new(
		"item_4", UnlockableType.ITEM, 4,
		[],
		"item.spinach_name", "item.spinach_desc"
	),
	# Empty Tome — have 6 weapons in a run
	UnlockDef.new(
		"item_5", UnlockableType.ITEM, 5,
		[UnlockCondition.new(ConditionType.HAVE_WEAPONS_COUNT, {"min_count": 6})],
		"item.tome_name", "item.tome_desc"
	),
	# Hollow Heart — survive 1 min
	UnlockDef.new(
		"item_6", UnlockableType.ITEM, 6,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 60})],
		"item.hollow_name", "item.hollow_desc"
	),
	# Candelabrador — Santa Water to level 4
	UnlockDef.new(
		"item_7", UnlockableType.ITEM, 7,
		[UnlockCondition.new(ConditionType.WEAPON_AT_LEVEL, {"weapon_type": 18, "min_level": 4})],
		"item.candel_name", "item.candel_desc"
	),
	# Crown — reach level 10
	UnlockDef.new(
		"item_8", UnlockableType.ITEM, 8,
		[UnlockCondition.new(ConditionType.PLAYER_LEVEL, {"min_level": 10})],
		"item.crown_name", "item.crown_desc"
	),
	# Pummarola — survive 5 min with Gennaro (char 3)
	UnlockDef.new(
		"item_9", UnlockableType.ITEM, 9,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 300, "char_id": 3})],
		"item.pummarola_name", "item.pummarola_desc"
	),
	# Duplicator — Magic Wand to level 7
	UnlockDef.new(
		"item_13", UnlockableType.ITEM, 13,
		[UnlockCondition.new(ConditionType.WEAPON_AT_LEVEL, {"weapon_type": 1, "min_level": 7})],
		"item.duplicator_name", "item.duplicator_desc"
	),
	# Stone Mask — find and pick up
	UnlockDef.new(
		"item_14", UnlockableType.ITEM, 14,
		[UnlockCondition.new(ConditionType.ITEM_FOUND, {"item_type": 14})],
		"item.stonemask_name", "item.stonemask_desc"
	),
	# Attractorb — pick up a Vacuum
	UnlockDef.new(
		"item_15", UnlockableType.ITEM, 15,
		[UnlockCondition.new(ConditionType.PICKUP_COLLECTED, {"pickup_type": "vacuum"})],
		"item.attractorb_name", "item.attractorb_desc"
	),
	# Clover — pick up a Little Clover
	UnlockDef.new(
		"item_21", UnlockableType.ITEM, 21,
		[UnlockCondition.new(ConditionType.PICKUP_COLLECTED, {"pickup_type": "little_clover"})],
		"item.clover_name", "item.clover_desc"
	),
	# Spellbinder — Runetracer to level 7
	UnlockDef.new(
		"item_22", UnlockableType.ITEM, 22,
		[UnlockCondition.new(ConditionType.WEAPON_AT_LEVEL, {"weapon_type": 19, "min_level": 7})],
		"item.spellbinder_name", "item.spellbinder_desc"
	),
	# Armor — default unlocked
	UnlockDef.new(
		"item_23", UnlockableType.ITEM, 23,
		[],
		"item.armor_name", "item.armor_desc"
	),
	# Bracer — King Bible to level 4
	UnlockDef.new(
		"item_24", UnlockableType.ITEM, 24,
		[UnlockCondition.new(ConditionType.WEAPON_AT_LEVEL, {"weapon_type": 17, "min_level": 4})],
		"item.bracer_name", "item.bracer_desc"
	),
	# Skull O'Maniac — survive 30 min with Lama (char 6)
	UnlockDef.new(
		"item_25", UnlockableType.ITEM, 25,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 1800, "char_id": 6})],
		"item.skull_name", "item.skull_desc"
	),
	# Tiragisú — survive 20 min with Krochi (char 10)
	UnlockDef.new(
		"item_26", UnlockableType.ITEM, 26,
		[UnlockCondition.new(ConditionType.SURVIVE_CHAR_TIME, {"min_time": 1200, "char_id": 10})],
		"item.tiragisu_name", "item.tiragisu_desc"
	),
	# Torrona's Box — 6 different evolutions in a run
	UnlockDef.new(
		"item_27", UnlockableType.ITEM, 27,
		[UnlockCondition.new(ConditionType.ALL_EVOLUTIONS, {})],
		"item.torrona_name", "item.torrona_desc"
	),
	# Silver Ring — Yellow Sign relic
	UnlockDef.new(
		"item_28", UnlockableType.ITEM, 28,
		[UnlockCondition.new(ConditionType.RELIC_OWNED, {"relic_id": "yellow_sign"})],
		"item.silver_ring_name", "item.silver_ring_desc"
	),
	# Gold Ring — Yellow Sign relic
	UnlockDef.new(
		"item_29", UnlockableType.ITEM, 29,
		[UnlockCondition.new(ConditionType.RELIC_OWNED, {"relic_id": "yellow_sign"})],
		"item.gold_ring_name", "item.gold_ring_desc"
	),
	# Metaglio Left — Yellow Sign relic
	UnlockDef.new(
		"item_30", UnlockableType.ITEM, 30,
		[UnlockCondition.new(ConditionType.RELIC_OWNED, {"relic_id": "yellow_sign"})],
		"item.metaglio_left_name", "item.metaglio_left_desc"
	),
	# Metaglio Right — Yellow Sign relic
	UnlockDef.new(
		"item_31", UnlockableType.ITEM, 31,
		[UnlockCondition.new(ConditionType.RELIC_OWNED, {"relic_id": "yellow_sign"})],
		"item.metaglio_right_name", "item.metaglio_right_desc"
	),
	# Parm Aegis — found in The Coop
	UnlockDef.new(
		"item_62", UnlockableType.ITEM, 62,
		[UnlockCondition.new(ConditionType.ITEM_FOUND, {"item_type": 62})],
		"item.parm_aegis_name", "item.parm_aegis_desc"
	),
	# Karoma's Mana — found in Westwoods
	UnlockDef.new(
		"item_63", UnlockableType.ITEM, 63,
		[UnlockCondition.new(ConditionType.ITEM_FOUND, {"item_type": 63})],
		"item.karomas_mana_name", "item.karomas_mana_desc"
	),
]
