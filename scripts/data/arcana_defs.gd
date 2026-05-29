extends RefCounted
# Arcana definitions — 22 base Arcanas from Vampire Survivors.
# Each Arcana is represented by a Roman numeral (0, I–XXI).
#
# Effects field uses string identifiers checked at runtime:
#   Stat modifiers: "might+N%", "cooldown-N%", "area+N%", "speed+N%", "duration+N%"
#   Special flags:  "no_xp", "healing_double", "revival_plus_3", "gold_fever", "crits_enabled"
#   Cycling:        "cycle_stats", "cycle_speed", "cycle_area", "cycle_duration"
#   Timer:          "attract_items_120s"
#   Weapon:         "listed_explode_expire", "listed_bounce", "listed_freeze", "listed_explode_impact"
#   Other:          "armor_scales_damage", "magnet_aura_damage", "empty_slot_stats"

const ARCANAS := [
	# ── 0 — Game Killer ──
	{
		"id": 0,
		"roman": "0",
		"name": "Game Killer",
		"desc": "Halts XP gain. Experience Gems turn into exploding projectiles. All Treasure Chests contain at least 3 items.",
		"unlock": "Defeat the final boss in the last stage.",
		"color": Color(0.9, 0.15, 0.15),
		"icon_shape": "skull",
		"effects": ["no_xp", "xp_gem_explode", "chest_min_3"],
		"listed_weapons": [],
		"stage_milestone": -1,
		"character_lv50": -1,
		"minute_31_stage": -1,
	},

	# ── I — Gemini ──
	{
		"id": 1,
		"roman": "I",
		"name": "Gemini",
		"desc": "Listed weapons come with a counterpart.",
		"unlock": "Reach level 30 with Pugnala-equivalent.",
		"color": Color(0.6, 0.2, 0.8),
		"icon_shape": "twins",
		"effects": ["listed_counterpart"],
		"listed_weapons": [0, 1, 10, 12, 16, 20],  # Whip, Wand, Knife, FireWand, Cross, Lightning
		"stage_milestone": -1,
		"character_lv50": 6,
		"minute_31_stage": -1,
	},

	# ── II — Twilight Requiem ──
	{
		"id": 2,
		"roman": "II",
		"name": "Twilight Requiem",
		"desc": "Listed weapon projectiles generate explosions when they expire. Explosion damage is affected by Curse.",
		"unlock": "Reach level 30 with Dommario.",
		"color": Color(0.4, 0.1, 0.6),
		"icon_shape": "burst",
		"effects": ["listed_explode_expire"],
		"listed_weapons": [0, 2, 11, 17, 18, 19],  # Whip, Garlic, Axe, Bible, SantaWater, Runetracer
		"stage_milestone": -1,
		"character_lv50": 9,
		"minute_31_stage": -1,
	},

	# ── III — Tragic Princess ──
	{
		"id": 3,
		"roman": "III",
		"name": "Tragic Princess",
		"desc": "The cooldown of the listed weapons reduces when moving.",
		"unlock": "Reach level 30 with Porta.",
		"color": Color(0.8, 0.2, 0.6),
		"icon_shape": "crown",
		"effects": ["listed_move_cd"],
		"listed_weapons": [0, 1, 10, 11, 12, 16, 17, 18, 19, 20],  # All weapons
		"stage_milestone": -1,
		"character_lv50": 5,
		"minute_31_stage": -1,
	},

	# ── IV — Awake ──
	{
		"id": 4,
		"roman": "IV",
		"name": "Awake",
		"desc": "Gives +3 Revivals. Consuming a Revival gives +10% Max Health, +1 Armor, and +5% Might, Area, Duration, and Speed.",
		"unlock": "Reach level 30 with Krochi.",
		"color": Color(0.9, 0.7, 0.1),
		"icon_shape": "phoenix",
		"effects": ["revival_plus_3", "revival_buff"],
		"listed_weapons": [],
		"stage_milestone": -1,
		"character_lv50": 10,
		"minute_31_stage": -1,
	},

	# ── V — Chaos in the Dark Night ──
	{
		"id": 5,
		"roman": "V",
		"name": "Chaos in the Dark Night",
		"desc": "Overall projectile Speed continuously changes between -50% and +50% over 10 seconds. Start gaining +1% projectile Speed every level.",
		"unlock": "Reach level 30 with Giovanna.",
		"color": Color(0.3, 0.3, 0.9),
		"icon_shape": "vortex",
		"effects": ["cycle_speed", "level_speed_pct"],
		"listed_weapons": [],
		"stage_milestone": -1,
		"character_lv50": 1,
		"minute_31_stage": -1,
	},

	# ── VI — Sarabande of Healing ──
	{
		"id": 6,
		"roman": "VI",
		"name": "Sarabande of Healing",
		"desc": "Healing is doubled. Recovering HP damages nearby enemies for the same amount.",
		"unlock": "Find the Randomazzo.",
		"color": Color(0.2, 0.9, 0.4),
		"icon_shape": "heart",
		"effects": ["healing_double", "healing_damages_enemies"],
		"listed_weapons": [],
		"stage_milestone": -1,
		"character_lv50": -1,
		"minute_31_stage": -1,
	},

	# ── VII — Iron Blue Will ──
	{
		"id": 7,
		"roman": "VII",
		"name": "Iron Blue Will",
		"desc": "Listed weapon projectiles gain up to 3 bounces and might pass through enemies and walls.",
		"unlock": "Reach level 30 with Gennaro.",
		"color": Color(0.3, 0.5, 0.9),
		"icon_shape": "shield",
		"effects": ["listed_bounce"],
		"listed_weapons": [1, 10, 11, 12, 16, 18, 19, 20],  # Projectile weapons
		"stage_milestone": -1,
		"character_lv50": 3,
		"minute_31_stage": -1,
	},

	# ── VIII — Mad Groove ──
	{
		"id": 8,
		"roman": "VIII",
		"name": "Mad Groove",
		"desc": "Every 2 minutes attracts all standard stage items, pickups, and light sources towards the character.",
		"unlock": "Reach minute 31 in the Mad Forest.",
		"color": Color(0.8, 0.3, 0.8),
		"icon_shape": "magnet",
		"effects": ["attract_items_120s"],
		"listed_weapons": [],
		"stage_milestone": -1,
		"character_lv50": -1,
		"minute_31_stage": 0,
	},

	# ── IX — Divine Bloodline ──
	{
		"id": 9,
		"roman": "IX",
		"name": "Divine Bloodline",
		"desc": "Armor also affects listed weapons' damage and reflects enemy damage. Bonus damage depending on missing Health. Defeating enemies with retaliatory damage gives +0.5 Max Health.",
		"unlock": "Reach level 30 with Clerici.",
		"color": Color(0.7, 0.2, 0.2),
		"icon_shape": "blood",
		"effects": ["armor_scales_damage", "missing_hp_damage", "retaliate_maxhp"],
		"listed_weapons": [0, 2, 11, 17],  # Melee-adjacent weapons
		"stage_milestone": -1,
		"character_lv50": 8,
		"minute_31_stage": -1,
	},

	# ── X — Beginning ──
	{
		"id": 10,
		"roman": "X",
		"name": "Beginning",
		"desc": "Listed weapons get +1 Amount. The character's main weapon gains +3 Amount instead.",
		"unlock": "Reach level 30 with Antonio.",
		"color": Color(0.9, 0.8, 0.2),
		"icon_shape": "star",
		"effects": ["listed_amount_plus_1", "main_weapon_amount_plus_3"],
		"listed_weapons": [0, 1, 2, 10, 11, 12, 16, 17, 18, 19, 20],  # All weapons
		"stage_milestone": -1,
		"character_lv50": 0,
		"minute_31_stage": -1,
	},

	# ── XI — Waltz of Pearls ──
	{
		"id": 11,
		"roman": "XI",
		"name": "Waltz of Pearls",
		"desc": "Listed weapon projectiles gain up to 3 bounces.",
		"unlock": "Reach level 30 with Imelda.",
		"color": Color(0.4, 0.7, 0.9),
		"icon_shape": "pearl",
		"effects": ["listed_bounce"],
		"listed_weapons": [1, 10, 12, 16, 19, 20],  # Ranged projectiles
		"stage_milestone": -1,
		"character_lv50": 1,
		"minute_31_stage": -1,
	},

	# ── XII — Out of Bounds ──
	{
		"id": 12,
		"roman": "XII",
		"name": "Out of Bounds",
		"desc": "Freezing enemies generates explosions. Orologions are easier to find.",
		"unlock": "Reach minute 31 in Gallo Tower.",
		"color": Color(0.3, 0.8, 0.9),
		"icon_shape": "snowflake",
		"effects": ["freeze_explodes", "clock_boost"],
		"listed_weapons": [],
		"stage_milestone": -1,
		"character_lv50": -1,
		"minute_31_stage": 1,
	},

	# ── XIII — Wicked Season ──
	{
		"id": 13,
		"roman": "XIII",
		"name": "Wicked Season",
		"desc": "Overall Growth, Luck, Greed, and Curse are doubled at fixed intervals. Start gaining +1% Growth, Luck, Greed, and Curse every 2 levels.",
		"unlock": "Reach level 30 with Christine.",
		"color": Color(0.2, 0.8, 0.3),
		"icon_shape": "leaf",
		"effects": ["cycle_stats", "level_stat_pct"],
		"listed_weapons": [],
		"stage_milestone": -1,
		"character_lv50": 11,
		"minute_31_stage": -1,
	},

	# ── XIV — Jail of Crystal ──
	{
		"id": 14,
		"roman": "XIV",
		"name": "Jail of Crystal",
		"desc": "Listed weapon projectiles have a chance to freeze enemies.",
		"unlock": "Reach level 30 with Pasqualina.",
		"color": Color(0.3, 0.6, 1.0),
		"icon_shape": "crystal",
		"effects": ["listed_freeze"],
		"listed_weapons": [1, 10, 12, 16, 19, 20],  # Ranged projectiles
		"stage_milestone": -1,
		"character_lv50": 2,
		"minute_31_stage": -1,
	},

	# ── XV — Disco of Gold ──
	{
		"id": 15,
		"roman": "XV",
		"name": "Disco of Gold",
		"desc": "Picking up coins from the floor triggers Gold Fever. Obtaining gold restores HP.",
		"unlock": "Reach minute 31 in the Inlaid Library.",
		"color": Color(0.9, 0.8, 0.1),
		"icon_shape": "coin",
		"effects": ["gold_fever", "gold_heals"],
		"listed_weapons": [],
		"stage_milestone": -1,
		"character_lv50": -1,
		"minute_31_stage": 1,
	},

	# ── XVI — Slash ──
	{
		"id": 16,
		"roman": "XVI",
		"name": "Slash",
		"desc": "Enables critical hits for listed weapons. Doubles overall critical damage.",
		"unlock": "Reach level 30 with Lama.",
		"color": Color(0.8, 0.1, 0.1),
		"icon_shape": "slash",
		"effects": ["crits_enabled", "crit_damage_double"],
		"listed_weapons": [0, 2, 10, 11, 16, 17],  # Melee/close-range
		"stage_milestone": -1,
		"character_lv50": 6,
		"minute_31_stage": -1,
	},

	# ── XVII — Lost & Found Painting ──
	{
		"id": 17,
		"roman": "XVII",
		"name": "Lost & Found Painting",
		"desc": "Overall Duration continuously changes between -50% and +50% over 10 seconds. Start gaining +1% Duration every level.",
		"unlock": "Reach level 30 with Poppea.",
		"color": Color(0.9, 0.6, 0.3),
		"icon_shape": "palette",
		"effects": ["cycle_duration", "level_duration_pct"],
		"listed_weapons": [],
		"stage_milestone": -1,
		"character_lv50": 7,  # Poe — closest Poppea equivalent
		"minute_31_stage": -1,
	},

	# ── XVIII — Boogaloo of Illusions ──
	{
		"id": 18,
		"roman": "XVIII",
		"name": "Boogaloo of Illusions",
		"desc": "Overall Area continuously changes between -25% and +25% over 10 seconds. Start gaining +1% Area every level.",
		"unlock": "Reach level 30 with Concetta.",
		"color": Color(0.7, 0.3, 0.7),
		"icon_shape": "moon",
		"effects": ["cycle_area", "level_area_pct"],
		"listed_weapons": [],
		"stage_milestone": -1,
		"character_lv50": 4,  # Arca — closest Concetta equivalent
		"minute_31_stage": -1,
	},

	# ── XIX — Heart of Fire ──
	{
		"id": 19,
		"roman": "XIX",
		"name": "Heart of Fire",
		"desc": "Listed weapon projectiles explode on impact. Light sources explode. Character explodes when damaged.",
		"unlock": "Reach level 30 with Arca.",
		"color": Color(0.9, 0.3, 0.1),
		"icon_shape": "fire",
		"effects": ["listed_explode_impact", "light_sources_explode", "hit_explode"],
		"listed_weapons": [1, 10, 12, 16, 19, 20],  # Ranged projectiles
		"stage_milestone": -1,
		"character_lv50": 4,
		"minute_31_stage": -1,
	},

	# ── XX — Silent Old Sanctuary ──
	{
		"id": 20,
		"roman": "XX",
		"name": "Silent Old Sanctuary",
		"desc": "Gives +3 Reroll, Skip, and Banish. Gives +20% Might and -8% Cooldown for each active weapon slot left empty.",
		"unlock": "Reach minute 31 in the Dairy Plant.",
		"color": Color(0.3, 0.3, 0.5),
		"icon_shape": "temple",
		"effects": ["reroll_skip_banish_plus_3", "empty_slot_stats"],
		"listed_weapons": [],
		"stage_milestone": -1,
		"character_lv50": -1,
		"minute_31_stage": 2,
	},

	# ── XXI — Blood Astronomia ──
	{
		"id": 21,
		"roman": "XXI",
		"name": "Blood Astronomia",
		"desc": "Listed weapons also emit special damaging zones affected by Amount and Magnet. Enemies within Magnet range take damage based on Amount.",
		"unlock": "Reach level 30 with Poe.",
		"color": Color(0.8, 0.1, 0.3),
		"icon_shape": "blood_moon",
		"effects": ["magnet_aura_damage"],
		"listed_weapons": [0, 2, 11, 17, 18],  # Melee/close-range + zone weapons
		"stage_milestone": -1,
		"character_lv50": 7,
		"minute_31_stage": -1,
	},
]


# ── Lookup helpers ──

static func get_arcana(id: int) -> Dictionary:
	for a in ARCANAS:
		if a["id"] == id:
			return a
	return ARCANAS[0]


static func get_arcana_by_roman(roman: String) -> Dictionary:
	for a in ARCANAS:
		if a["roman"] == roman:
			return a
	return ARCANAS[0]


static func get_arcana_count() -> int:
	return ARCANAS.size()


static func get_all_ids() -> Array:
	var ids: Array = []
	for a in ARCANAS:
		ids.append(a["id"])
	return ids


# Returns Arcanas that have a specific effect ID
static func get_arcanas_with_effect(effect_id: String) -> Array:
	var result: Array = []
	for a in ARCANAS:
		if effect_id in a["effects"]:
			result.append(a)
	return result


# Returns Arcanas that list a specific weapon type
static func get_arcanas_listing_weapon(weapon_type: int) -> Array:
	var result: Array = []
	for a in ARCANAS:
		if a["listed_weapons"].has(weapon_type):
			result.append(a)
	return result


# Returns whether an Arcana lists a specific weapon
static func arcana_lists_weapon(arcana_id: int, weapon_type: int) -> bool:
	var a = get_arcana(arcana_id)
	return a["listed_weapons"].has(weapon_type)


# Returns whether an Arcana has a specific effect
static func arcana_has_effect(arcana_id: int, effect_id: String) -> bool:
	var a = get_arcana(arcana_id)
	return effect_id in a["effects"]
