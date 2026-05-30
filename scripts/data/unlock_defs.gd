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
]
