extends RefCounted

const RELICS := [
	# ── Base Game: Randomazzo — Gallo Tower (stage 4) ──
	{
		"id": "randomazzo",
		"name": "Randomazzo",
		"desc": "Enables the unlocking and activation of Arcanas.",
		"effect": "Unlocks Arcana Cards — special modifiers selectable before a run.\nAwards Sarabande of Healing (VI).",
		"stage_id": 4,
		"spawn_pos": Vector2(0, 1200),
		"color": Color(0.3, 0.9, 0.5),
		"icon_shape": "card",
	},

	# ── #397 Grim Grimoire — Inlaid Library (stage 1) ──
	{
		"id": "grim_grimoire",
		"name": "Grim Grimoire",
		"desc": "Permanently allows to peek at discovered weapon evolutions and unions from the pause menu.",
		"effect": "Unlocks the 'Open Grimoire' menu in the pause screen.",
		"stage_id": 1,
		"spawn_pos": Vector2(-1800, 0),
		"color": Color(0.6, 0.2, 0.9),
		"icon_shape": "book",
	},

	# ── #398 Ars Gouda — Dairy Plant (stage 3) ──
	{
		"id": "ars_gouda",
		"name": "Ars Gouda",
		"desc": "Permanently allows access to the bestiary of defeated enemies from the main menu.",
		"effect": "Unlocks the Bestiary — view all defeated enemies and their stats.",
		"stage_id": 3,
		"spawn_pos": Vector2(0, 1500),
		"color": Color(0.9, 0.7, 0.1),
		"icon_shape": "gold",
	},

	# ── #399 Milky Way Map — Dairy Plant (stage 3) ──
	{
		"id": "milky_way_map",
		"name": "Milky Way Map",
		"desc": "Permanently enables the map in the pause menu.",
		"effect": "Unlocks the map overlay in the pause screen.",
		"stage_id": 3,
		"spawn_pos": Vector2(0, -1500),
		"color": Color(0.2, 0.6, 0.9),
		"icon_shape": "map",
	},

	# ── #400 Magic Banger — Green Acres (stage 7) ──
	{
		"id": "magic_banger",
		"name": "Magic Banger",
		"desc": "Permanently allows to change music in Stage Selection.",
		"effect": "Unlocks alternate music tracks in stage select.",
		"stage_id": 7,
		"spawn_pos": Vector2(1200, -800),
		"color": Color(0.9, 0.6, 0.2),
		"icon_shape": "music",
	},

	# ── #401 Sorceress' Tears — Gallo Tower (stage 4) ──
	{
		"id": "sorceress_tears",
		"name": "Sorceress' Tears",
		"desc": "Permanently allows to speed up time in Stage Selection.",
		"effect": "Unlocks Hurry Mode (1.5x game speed) in stage select.",
		"stage_id": 4,
		"spawn_pos": Vector2(0, -2000),
		"color": Color(0.9, 0.3, 0.6),
		"icon_shape": "tear",
	},

	# ── #402 Glass Vizard — Moongolow (stage 6), purchased from merchant ──
	{
		"id": "glass_vizard",
		"name": "Glass Vizard",
		"desc": "Summons the merchant in all stages.",
		"effect": "The merchant now appears in every stage.",
		"stage_id": 6,
		"spawn_pos": Vector2(0, 0),
		"color": Color(0.4, 0.8, 0.9),
		"icon_shape": "mask",
	},

	# ── #404 Mindbender — Collection 50 entries ──
	{
		"id": "mindbender",
		"name": "Mindbender",
		"desc": "Permanently allows changing character appearance and max weapon configuration.",
		"effect": "Unlocks cosmetic options for certain characters and allows setting max weapon count.",
		"stage_id": 0,
		"spawn_pos": Vector2(0, 0),
		"color": Color(0.8, 0.3, 0.8),
		"icon_shape": "mind",
	},

	# ── #405 Yellow Sign — Holy Forbidden (stage 16) ──
	{
		"id": "yellow_sign",
		"name": "Yellow Sign",
		"desc": "Permanently reveals hidden stage items across all stages.",
		"effect": "Unlocks Silver Ring, Gold Ring, Metaglio Left, Metaglio Right.\nEnables certain hidden relics and events.",
		"stage_id": 16,
		"spawn_pos": Vector2(2000, 0),
		"color": Color(0.9, 0.8, 0.1),
		"icon_shape": "sign",
	},

	# ── #406 Forbidden Scrolls of Morbane — The Bone Zone (stage 8), dropped by Sketamari ──
	{
		"id": "forbidden_scrolls",
		"name": "Forbidden Scrolls of Morbane",
		"desc": "Permanently allows casting spells and accessing the secrets list from the main menu.",
		"effect": "Unlocks the Secrets menu, provides instructions for unlocking hidden characters,\nand allows spell input to unlock most features.",
		"stage_id": 8,
		"spawn_pos": Vector2(0, 2000),
		"color": Color(0.7, 0.2, 0.3),
		"icon_shape": "scroll",
	},

	# ── #407 Great Gospel — Cappella Magna (stage 5), dropped by final enemy (needs Yellow Sign) ──
	{
		"id": "great_gospel",
		"name": "Great Gospel",
		"desc": "Permanently allows leveling weapons beyond their limit.",
		"effect": "Unlocks Limit Break — weapons can be upgraded past Lv.8.",
		"stage_id": 5,
		"spawn_pos": Vector2(0, 0),
		"color": Color(0.9, 0.8, 0.2),
		"icon_shape": "gospel",
	},

	# ── #408 Gracia's Mirror — Eudaimonia Machine (stage 15) ──
	{
		"id": "gracia_mirror",
		"name": "Gracia's Mirror",
		"desc": "Permanently allows accessing the difficult version of any stage.",
		"effect": "Unlocks Inverse Mode — harder stages with increased rewards.",
		"stage_id": 15,
		"spawn_pos": Vector2(1000, -1000),
		"color": Color(0.6, 0.3, 0.9),
		"icon_shape": "mirror",
	},

	# ── #409 Seventh Trumpet — Eudaimonia Machine (stage 15) ──
	{
		"id": "seventh_trumpet",
		"name": "Seventh Trumpet",
		"desc": "Permanently allows disabling all reapers and fighting endlessly.",
		"effect": "Unlocks Endless Mode — no time limit, fight forever.",
		"stage_id": 15,
		"spawn_pos": Vector2(-1000, 1000),
		"color": Color(0.9, 0.2, 0.2),
		"icon_shape": "trumpet",
	},

	# ── #410 Atlas Gate — Boss Rash (stage 9), appears 7 min into battle (needs Yellow Sign) ──
	{
		"id": "atlas_gate",
		"name": "Atlas Gate",
		"desc": "Enables base game adventures.",
		"effect": "Unlocks Adventure Mode.",
		"stage_id": 9,
		"spawn_pos": Vector2(0, 0),
		"color": Color(0.2, 0.5, 0.8),
		"icon_shape": "gate",
	},

	# ── #411 Chaos Malachite — Bat Country (stage 14), appears at 18:00 ──
	{
		"id": "chaos_malachite",
		"name": "Chaos Malachite",
		"desc": "Allows Mortaccio to transform at level 80.",
		"effect": "Mortaccio transforms into a stronger form at Lv.80, evolving their main weapon.",
		"stage_id": 14,
		"spawn_pos": Vector2(0, -1000),
		"color": Color(0.2, 0.8, 0.4),
		"icon_shape": "chaos",
	},

	# ── #412 Chaos Rosalia — Astral Stair (stage 17) ──
	{
		"id": "chaos_rosalia",
		"name": "Chaos Rosalia",
		"desc": "Allows Yatta Cavallo to transform at level 80.",
		"effect": "Yatta Cavallo transforms into a stronger form at Lv.80, evolving their main weapon.",
		"stage_id": 17,
		"spawn_pos": Vector2(-800, 600),
		"color": Color(0.9, 0.3, 0.5),
		"icon_shape": "chaos",
	},

	# ── #413 Chaos Lazulia — Mazerella (stage 18) ──
	{
		"id": "chaos_lazulia",
		"name": "Chaos Lazulia",
		"desc": "Allows Bianca Ramba to transform at level 80.",
		"effect": "Bianca Ramba transforms into a stronger form at Lv.80, evolving their main weapon.",
		"stage_id": 18,
		"spawn_pos": Vector2(-1000, 0),
		"color": Color(0.3, 0.5, 0.9),
		"icon_shape": "chaos",
	},

	# ── #414 Chaos Altemanna — Tiny Bridge (stage 19) ──
	{
		"id": "chaos_altemanna",
		"name": "Chaos Altemanna",
		"desc": "Allows O'Sole Meeo to transform at level 80.",
		"effect": "O'Sole Meeo transforms into a stronger form at Lv.80, evolving their main weapon.",
		"stage_id": 19,
		"spawn_pos": Vector2(0, 1000),
		"color": Color(0.9, 0.6, 0.2),
		"icon_shape": "chaos",
	},

	# ── #415 Trisection — Astral Stair (stage 17) ──
	{
		"id": "trisection",
		"name": "Trisection",
		"desc": "Enables random events in all stages.",
		"effect": "Adds a Random Events option in the stage select menu.",
		"stage_id": 17,
		"spawn_pos": Vector2(800, -600),
		"color": Color(0.5, 0.2, 0.8),
		"icon_shape": "triangle",
	},

	# ── #416 Brave Story — Space 54 (stage 13), appears after 18 min ──
	{
		"id": "brave_story",
		"name": "Brave Story",
		"desc": "Enables random upgrade selection on level up.",
		"effect": "Adds a Random Upgrade option in the stage select menu.",
		"stage_id": 13,
		"spawn_pos": Vector2(0, 1500),
		"color": Color(0.8, 0.4, 0.2),
		"icon_shape": "star",
	},

	# ── #417 Masquerade — Westwoods (stage 20) ──
	{
		"id": "masquerade",
		"name": "Masquerade",
		"desc": "Unlocks Party Mode.",
		"effect": "Allows access to Party Mode.",
		"stage_id": 20,
		"spawn_pos": Vector2(-1500, 0),
		"color": Color(0.9, 0.2, 0.7),
		"icon_shape": "mask2",
	},

	# ── #418 Apoplexy — Bat Country (stage 14), appears at 9:00 ──
	{
		"id": "apoplexy",
		"name": "Apoplexy",
		"desc": "Allows purchasing the Charm power-up.",
		"effect": "Unlocks the Charm upgrade.",
		"stage_id": 14,
		"spawn_pos": Vector2(0, 1000),
		"color": Color(0.9, 0.1, 0.1),
		"icon_shape": "charm",
	},

	# ── #419 Antidote — Whiteout (stage 10) ──
	{
		"id": "antidote",
		"name": "Antidote",
		"desc": "Allows purchasing the Defang power-up.",
		"effect": "Unlocks the Defang upgrade — some enemies become harmless.",
		"stage_id": 10,
		"spawn_pos": Vector2(0, -2000),
		"color": Color(0.3, 0.9, 0.4),
		"icon_shape": "potion",
	},

	# ── #420 Wax Fetish — Mazerella (stage 18) ──
	{
		"id": "wax_fetish",
		"name": "Wax Fetish",
		"desc": "Allows purchasing the Preserve power-up.",
		"effect": "Unlocks the Preserve upgrade — chance to keep items on level up.",
		"stage_id": 18,
		"spawn_pos": Vector2(1000, 0),
		"color": Color(0.8, 0.7, 0.2),
		"icon_shape": "wax",
	},

	# ── #421 Roast Chicken with a Clock in the Middle — The Coop (stage 12) ──
	{
		"id": "roast_chicken",
		"name": "Roast Chicken with a Clock in the Middle",
		"desc": "Permanently allows speeding up game progression.",
		"effect": "Unlocks the Speed Up button.",
		"stage_id": 12,
		"spawn_pos": Vector2(1500, 0),
		"color": Color(0.9, 0.5, 0.2),
		"icon_shape": "chicken",
	},

	# ── #423 Astral Stair Map — Astral Stair (stage 17) ──
	{
		"id": "astral_stair_map",
		"name": "Astral Stair Map",
		"desc": "Shows a detailed map of Astral Stair.",
		"effect": "Displays the Astral Stair map in the pause menu.",
		"stage_id": 17,
		"spawn_pos": Vector2(-800, -600),
		"color": Color(0.3, 0.7, 0.9),
		"icon_shape": "map2",
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
