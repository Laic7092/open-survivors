extends RefCounted
# Relic definitions — permanent collectibles that unlock game mechanics.
# Each relic has fixed placement on a specific stage.
# Once collected, the relic never spawns again and its effect is permanently active.

const RELICS := [
	# ── Mad Forest (stage 0) ──
	{
		"id": "grim_grimoire",
		"name": "Grim Grimoire",
		"desc": "Permanently allows to peek at discovered weapon evolutions\nfrom the pause menu.",
		"effect": "Unlocks the Evolution Recipes tab in the pause menu.",
		"stage_id": 0,
		"spawn_pos": Vector2(-600, -400),
		"color": Color(0.6, 0.2, 0.9),
		"icon_shape": "book",
	},
	{
		"id": "milky_way_map",
		"name": "Milky Way Map",
		"desc": "Permanently enables the map in the pause menu.",
		"effect": "Unlocks the minimap overlay in the pause screen.",
		"stage_id": 0,
		"spawn_pos": Vector2(700, 300),
		"color": Color(0.2, 0.6, 0.9),
		"icon_shape": "map",
	},

	# ── Inlaid Library (stage 1) ──
	{
		"id": "sorceress_tears",
		"name": "Sorceress' Tears",
		"desc": "Permanently allows to speed up time in Stage Selection.",
		"effect": "Unlocks Hurry Mode (1.5x game speed) in stage select.",
		"stage_id": 1,
		"spawn_pos": Vector2(0, -1800),
		"color": Color(0.9, 0.3, 0.6),
		"icon_shape": "tear",
	},
	{
		"id": "magic_banger",
		"name": "Magic Banger",
		"desc": "Permanently allows to change music in Stage Selection.",
		"effect": "Unlocks alternate music tracks in stage select.",
		"stage_id": 1,
		"spawn_pos": Vector2(0, 1800),
		"color": Color(0.9, 0.6, 0.2),
		"icon_shape": "music",
	},

	# ── Il Molise (stage 2) ──
	{
		"id": "randomazzo",
		"name": "Randomazzo",
		"desc": "Enables the unlocking and activation of Arcanas.",
		"effect": "Unlocks Arcana Cards — special modifiers selectable before a run.",
		"stage_id": 2,
		"spawn_pos": Vector2(0, 1200),
		"color": Color(0.3, 0.9, 0.5),
		"icon_shape": "card",
	},

	# ── Dairy Plant (stage 3) ──
	{
		"id": "great_gospel",
		"name": "Great Gospel",
		"desc": "Permanently allows to level up weapons beyond their limit.",
		"effect": "Unlocks Limit Break — weapons can reach level 20.",
		"stage_id": 3,
		"spawn_pos": Vector2(800, -600),
		"color": Color(0.9, 0.8, 0.2),
		"icon_shape": "gospel",
	},
	{
		"id": "ars_gouda",
		"name": "Ars Gouda",
		"desc": "Permanently increases gold gain by 20%.",
		"effect": "+20% Gold from all sources.",
		"stage_id": 3,
		"spawn_pos": Vector2(-900, 400),
		"color": Color(0.9, 0.7, 0.1),
		"icon_shape": "gold",
	},

	# ── Gallo Tower (stage 4) ──
	{
		"id": "seventh_trumpet",
		"name": "Seventh Trumpet",
		"desc": "Permanently allows to disable the time limit and fight endlessly.",
		"effect": "Unlocks Endless Mode (no time limit) in stage select.",
		"stage_id": 4,
		"spawn_pos": Vector2(0, -2000),
		"color": Color(0.9, 0.2, 0.2),
		"icon_shape": "trumpet",
	},
	{
		"id": "antidote",
		"name": "Antidote",
		"desc": "Permanently reduces damage taken by 10%.",
		"effect": "-10% Damage Taken across all runs.",
		"stage_id": 4,
		"spawn_pos": Vector2(0, 1500),
		"color": Color(0.3, 0.9, 0.4),
		"icon_shape": "potion",
	},

	# ── Cappella Magna (stage 5) ──
	{
		"id": "glass_vizard",
		"name": "Glass Vizard",
		"desc": "Permanently reveals hidden stage items on the map.",
		"effect": "Hidden items appear on the minimap and can be collected.",
		"stage_id": 5,
		"spawn_pos": Vector2(-1200, -800),
		"color": Color(0.4, 0.8, 0.9),
		"icon_shape": "mask",
	},
	{
		"id": "yellow_sign",
		"name": "Yellow Sign",
		"desc": "Permanently reveals all secrets hidden in stages.",
		"effect": "Unlocks hidden characters and items across stages.",
		"stage_id": 5,
		"spawn_pos": Vector2(1400, 1000),
		"color": Color(0.9, 0.8, 0.1),
		"icon_shape": "sign",
	},
]


static func get_relic(id: String) -> Dictionary:
	for r in RELICS:
		if r["id"] == id:
			return r
	return RELICS[0]


static func get_relics_for_stage(stage_id: int) -> Array:
	var result: Array = []
	for r in RELICS:
		if r["stage_id"] == stage_id:
			result.append(r)
	return result


static func get_relic_count() -> int:
	return RELICS.size()


static func get_relic_ids() -> Array:
	var ids: Array = []
	for r in RELICS:
		ids.append(r["id"])
	return ids
