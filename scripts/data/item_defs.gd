extends RefCounted
# Centralized item definitions — single source of truth for weapon/passive metadata.
# Eliminates duplication across player.gd, main.gd, level_up_screen.gd, character_select.gd.

enum Type {
	WHIP = 0, MAGIC_WAND = 1, GARLIC = 2,
	WINGS = 3, SPINACH = 4, TOME = 5,
	HOLLOW_HEART = 6, CANDELABRADOR = 7, CROWN = 8, PUMMAROLA = 9,
	KNIFE = 10, AXE = 11, FIRE_WAND = 12,
	DUPLICATOR = 13, STONE_MASK = 14,
	MAGNET = 15,  # Internal enum; display name is "Attractorb"
	CROSS = 16, KING_BIBLE = 17, SANTA_WATER = 18,
	RUNETRACER = 19, LIGHTNING_RING = 20,
	CLOVER = 21, SPELLBINDER = 22, ARMOR = 23,
	BRACER = 24, SKULL = 25, TIRAGISU = 26,
	TORRONA = 27, SILVER_RING = 28, GOLD_RING = 29,
	METAGLIO_LEFT = 30, METAGLIO_RIGHT = 31,
	PENTAGRAM = 32, PEACHONE = 33, EBONY_WINGS = 34,
	PHIERA_DER_TUPHELLO = 35, EIGHT_THE_SPARROW = 36,
	GATTI_AMARI = 37, SONG_OF_MANA = 38, SHADOW_PINION = 39,
	CLOCK_LANCET = 40, LAUREL = 41, VENTO_SACRO = 42,
	BONE = 43, CHERRY_BOMB = 44, CARRELLO = 45,
	CELESTIAL_DUSTING = 46, LA_ROBBA = 47,
	GREATEST_JUBILEE = 48, BRACELET = 49, CANDYBOX = 50,
	VICTORY_SWORD = 51, FLAMES_OF_MISSPELL = 52,
	PAKO_BATTILIAR = 53, AMMO_APPALATE = 54,
	CHAOS_RUNE = 55, GLASS_FANDANGO = 56, SANTA_JAVELIN = 57,
	GAZE_OF_GAEA = 58, MAGI_STONE = 59, PHAS3R = 60,
	ARMA_DIO = 61,
}

const WEAPON_TYPES: Array[int] = [
	0, 1, 2, 10, 11, 12, 16, 17, 18, 19, 20,
	32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42,
	43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53,
	54, 55, 56, 57, 58, 59, 60, 61,
]

# { type: { name, name_key, desc, desc_key, color, evo_key } }
const DATA := {
	# ── Weapons ──
	0: {
		"name": "Whip", "name_key": "item.whip_name",
		"desc": "Strike enemies in a wide arc", "desc_key": "item.whip_desc",
		"color": Color(0.8, 0.6, 0.3), "evo_key": "whip", "is_weapon": true, "max_level": 9,
	},
	1: {
		"name": "Magic Wand", "name_key": "item.wand_name",
		"desc": "Fire homing bolts at enemies", "desc_key": "item.wand_desc",
		"color": Color(0.3, 0.5, 1.0), "evo_key": "wand", "is_weapon": true, "max_level": 9,
	},
	2: {
		"name": "Garlic", "name_key": "item.garlic_name",
		"desc": "Damage enemies around you", "desc_key": "item.garlic_desc",
		"color": Color(0.6, 0.2, 0.8), "evo_key": "garlic", "is_weapon": true, "max_level": 9,
	},
	10: {
		"name": "Knife", "name_key": "item.knife_name",
		"desc": "Throw daggers in faced direction", "desc_key": "item.knife_desc",
		"color": Color(0.7, 0.7, 0.7), "evo_key": "knife", "is_weapon": true, "max_level": 9,
	},
	11: {
		"name": "Axe", "name_key": "item.axe_name",
		"desc": "Hurl a heavy axe in an arc", "desc_key": "item.axe_desc",
		"color": Color(0.6, 0.3, 0.1), "evo_key": "axe", "is_weapon": true, "max_level": 9,
	},
	12: {
		"name": "Fire Wand", "name_key": "item.firewand_name",
		"desc": "Shoot explosive fire at enemies", "desc_key": "item.firewand_desc",
		"color": Color(0.9, 0.4, 0.1), "evo_key": "firewand", "is_weapon": true, "max_level": 9,
	},
	16: {
		"name": "Cross", "name_key": "item.cross_name",
		"desc": "Boomerang that seeks enemies", "desc_key": "item.cross_desc",
		"color": Color(0.9, 0.6, 0.2), "evo_key": "cross", "is_weapon": true, "max_level": 9,
	},
	17: {
		"name": "King Bible", "name_key": "item.bible_name",
		"desc": "Orbiting projectiles", "desc_key": "item.bible_desc",
		"color": Color(0.2, 0.6, 0.9), "evo_key": "king_bible", "is_weapon": true, "max_level": 9,
	},
	18: {
		"name": "Santa Water", "name_key": "item.santa_water_name",
		"desc": "Create damaging puddles", "desc_key": "item.santa_water_desc",
		"color": Color(0.1, 0.5, 0.8), "evo_key": "santa_water", "is_weapon": true, "max_level": 9,
	},
	19: {
		"name": "Runetracer", "name_key": "item.runetracer_name",
		"desc": "Bouncing tracer projectiles", "desc_key": "item.runetracer_desc",
		"color": Color(0.8, 0.3, 0.7), "evo_key": "runetracer", "is_weapon": true, "max_level": 9,
	},
	20: {
		"name": "Lightning Ring", "name_key": "item.lightning_name",
		"desc": "Strike enemies with lightning", "desc_key": "item.lightning_desc",
		"color": Color(0.9, 0.9, 0.2), "evo_key": "lightning_ring", "is_weapon": true, "max_level": 9,
	},
	# ── Passives ──
	3: {
		"name": "Wings", "name_key": "item.wings_name",
		"desc": "Increase movement speed", "desc_key": "item.wings_desc",
		"color": Color(0.2, 0.8, 0.4), "is_weapon": false, "max_level": 5,
	},
	4: {
		"name": "Spinach", "name_key": "item.spinach_name",
		"desc": "Increase all damage", "desc_key": "item.spinach_desc",
		"color": Color(0.9, 0.3, 0.3), "is_weapon": false, "max_level": 5,
	},
	5: {
		"name": "Empty Tome", "name_key": "item.tome_name",
		"desc": "Reduce all weapon cooldowns", "desc_key": "item.tome_desc",
		"color": Color(0.2, 0.5, 0.8), "is_weapon": false, "max_level": 5,
	},
	6: {
		"name": "Hollow Heart", "name_key": "item.hollow_name",
		"desc": "Increase max health", "desc_key": "item.hollow_desc",
		"color": Color(0.9, 0.2, 0.2), "is_weapon": false, "max_level": 5,
	},
	7: {
		"name": "Candelabrador", "name_key": "item.candel_name",
		"desc": "Increase attack area", "desc_key": "item.candel_desc",
		"color": Color(0.9, 0.7, 0.2), "is_weapon": false, "max_level": 5,
	},
	8: {
		"name": "Crown", "name_key": "item.crown_name",
		"desc": "Gain more XP", "desc_key": "item.crown_desc",
		"color": Color(0.9, 0.8, 0.0), "is_weapon": false, "max_level": 5,
	},
	9: {
		"name": "Pummarola", "name_key": "item.pummarola_name",
		"desc": "Regenerate HP over time", "desc_key": "item.pummarola_desc",
		"color": Color(0.2, 0.9, 0.2), "is_weapon": false, "max_level": 5,
	},
	13: {
		"name": "Duplicator", "name_key": "item.duplicator_name",
		"desc": "+1 Projectile per level", "desc_key": "item.duplicator_desc",
		"color": Color(0.2, 0.7, 0.9), "is_weapon": false, "max_level": 3,
	},
	14: {
		"name": "Stone Mask", "name_key": "item.stonemask_name",
		"desc": "+20% Gold per level", "desc_key": "item.stonemask_desc",
		"color": Color(0.7, 0.7, 0.8), "is_weapon": false, "max_level": 5,
	},
	15: {
		"name": "Attractorb", "name_key": "item.attractorb_name",
		"desc": "Character picks up items from further away", "desc_key": "item.attractorb_desc",
		"color": Color(0.1, 0.7, 0.8), "is_weapon": false, "max_level": 5,
	},
	21: {
		"name": "Clover", "name_key": "item.clover_name",
		"desc": "Increase luck", "desc_key": "item.clover_desc",
		"color": Color(0.2, 0.9, 0.3), "is_weapon": false, "max_level": 5,
	},
	22: {
		"name": "Spellbinder", "name_key": "item.spellbinder_name",
		"desc": "Increase effect duration", "desc_key": "item.spellbinder_desc",
		"color": Color(0.5, 0.3, 0.9), "is_weapon": false, "max_level": 5,
	},
	23: {
		"name": "Armor", "name_key": "item.armor_name",
		"desc": "Reduce damage taken", "desc_key": "item.armor_desc",
		"color": Color(0.6, 0.6, 0.6), "is_weapon": false, "max_level": 5,
	},
	24: {
		"name": "Bracer", "name_key": "item.bracer_name",
		"desc": "Increase projectile speed", "desc_key": "item.bracer_desc",
		"color": Color(0.3, 0.9, 0.6), "is_weapon": false, "max_level": 5,
	},
	25: {
		"name": "Skull O'Maniac", "name_key": "item.skull_name",
		"desc": "Increase enemy difficulty", "desc_key": "item.skull_desc",
		"color": Color(0.6, 0.2, 0.2), "is_weapon": false, "max_level": 5,
	},
	26: {
		"name": "Tiragisú", "name_key": "item.tiragisu_name",
		"desc": "Revive on death", "desc_key": "item.tiragisu_desc",
		"color": Color(0.9, 0.7, 0.9), "is_weapon": false, "max_level": 2,
	},
	27: {
		"name": "Torrona's Box", "name_key": "item.torrona_name",
		"desc": "Boost all stats slightly", "desc_key": "item.torrona_desc",
		"color": Color(0.4, 0.2, 0.6), "is_weapon": false, "max_level": 9,
	},
	28: {
		"name": "Silver Ring", "name_key": "item.silver_ring_name",
		"desc": "+Duration, +Area", "desc_key": "item.silver_ring_desc",
		"color": Color(0.6, 0.7, 0.9), "is_weapon": false, "max_level": 5,
	},
	29: {
		"name": "Gold Ring", "name_key": "item.gold_ring_name",
		"desc": "Curse enemies", "desc_key": "item.gold_ring_desc",
		"color": Color(0.9, 0.8, 0.2), "is_weapon": false, "max_level": 5,
	},
	30: {
		"name": "Metaglio Left", "name_key": "item.metaglio_left_name",
		"desc": "+Recovery, +Max HP", "desc_key": "item.metaglio_left_desc",
		"color": Color(0.5, 0.3, 0.8), "is_weapon": false, "max_level": 5,
	},
	31: {
		"name": "Metaglio Right", "name_key": "item.metaglio_right_name",
		"desc": "Curse enemies", "desc_key": "item.metaglio_right_desc",
		"color": Color(0.8, 0.3, 0.5), "is_weapon": false, "max_level": 5,
	},
	# ── New Weapons ──
	32: {
		"name": "Pentagram", "name_key": "item.pentagram_name",
		"desc": "Removes all enemies and items from the screen at a fixed interval", "desc_key": "item.pentagram_desc",
		"color": Color(0.6, 0.1, 0.9), "evo_key": "pentagram", "is_weapon": true, "max_level": 9,
	},
	33: {
		"name": "Peachone", "name_key": "item.peachone_name",
		"desc": "Flying ally circles clockwise around you", "desc_key": "item.peachone_desc",
		"color": Color(0.9, 0.5, 0.3), "evo_key": "peachone", "is_weapon": true, "max_level": 9,
	},
	34: {
		"name": "Ebony Wings", "name_key": "item.ebony_wings_name",
		"desc": "Flying ally circles counter-clockwise around you", "desc_key": "item.ebony_wings_desc",
		"color": Color(0.3, 0.3, 0.7), "evo_key": "ebony_wings", "is_weapon": true, "max_level": 9,
	},
	35: {
		"name": "Phiera Der Tuphello", "name_key": "item.phiera_name",
		"desc": "Fires piercing projectiles in facing direction", "desc_key": "item.phiera_desc",
		"color": Color(0.3, 0.3, 0.7), "evo_key": "phiera", "is_weapon": true, "max_level": 9,
	},
	36: {
		"name": "Eight The Sparrow", "name_key": "item.eight_name",
		"desc": "Fires three-way spread shots", "desc_key": "item.eight_desc",
		"color": Color(0.7, 0.3, 0.4), "evo_key": "eight", "is_weapon": true, "max_level": 9,
	},
	37: {
		"name": "Gatti Amari", "name_key": "item.gatti_amari_name",
		"desc": "Cats scurry around, attacking and collecting", "desc_key": "item.gatti_amari_desc",
		"color": Color(0.9, 0.5, 0.2), "evo_key": "gatti_amari", "is_weapon": true, "max_level": 9,
	},
	38: {
		"name": "Song of Mana", "name_key": "item.song_of_mana_name",
		"desc": "Summon damaging vines along the vertical axis", "desc_key": "item.song_of_mana_desc",
		"color": Color(0.2, 0.8, 0.3), "evo_key": "song_of_mana", "is_weapon": true, "max_level": 9,
	},
	39: {
		"name": "Shadow Pinion", "name_key": "item.shadow_pinion_name",
		"desc": "Leave damaging shadows while moving, strike when stopping", "desc_key": "item.shadow_pinion_desc",
		"color": Color(0.4, 0.2, 0.6), "evo_key": "shadow_pinion", "is_weapon": true, "max_level": 9,
	},
	40: {
		"name": "Clock Lancet", "name_key": "item.clock_lancet_name",
		"desc": "Chance to freeze enemies in time", "desc_key": "item.clock_lancet_desc",
		"color": Color(0.6, 0.8, 1.0), "evo_key": "clock_lancet", "is_weapon": true, "max_level": 8,
	},
	41: {
		"name": "Laurel", "name_key": "item.laurel_name",
		"desc": "Temporary invincibility shield", "desc_key": "item.laurel_desc",
		"color": Color(0.2, 0.9, 0.4), "evo_key": "laurel", "is_weapon": true, "max_level": 8,
	},
	42: {
		"name": "Vento Sacro", "name_key": "item.vento_sacro_name",
		"desc": "Stronger while moving, can crit", "desc_key": "item.vento_sacro_desc",
		"color": Color(0.3, 0.8, 0.8), "evo_key": "vento_sacro", "is_weapon": true, "max_level": 9,
	},
	43: {
		"name": "Bone", "name_key": "item.bone_name",
		"desc": "Throw bouncing projectiles", "desc_key": "item.bone_desc",
		"color": Color(0.8, 0.8, 0.7), "evo_key": "bone", "is_weapon": true, "max_level": 9,
	},
	44: {
		"name": "Cherry Bomb", "name_key": "item.cherry_bomb_name",
		"desc": "Throw bouncing bombs that may explode", "desc_key": "item.cherry_bomb_desc",
		"color": Color(0.9, 0.2, 0.2), "evo_key": "cherry_bomb", "is_weapon": true, "max_level": 9,
	},
	45: {
		"name": "Carréllo", "name_key": "item.carrello_name",
		"desc": "Throw bouncing projectiles that scale with amount", "desc_key": "item.carrello_desc",
		"color": Color(0.2, 0.6, 0.9), "evo_key": "carrello", "is_weapon": true, "max_level": 9,
	},
	46: {
		"name": "Celestial Dusting", "name_key": "item.celestial_dusting_name",
		"desc": "Throws projectiles, movespeed reduces cooldown", "desc_key": "item.celestial_dusting_desc",
		"color": Color(0.7, 0.5, 0.9), "evo_key": "celestial_dusting", "is_weapon": true, "max_level": 9,
	},
	47: {
		"name": "La Robba", "name_key": "item.la_robba_name",
		"desc": "Generates bouncing projectiles", "desc_key": "item.la_robba_desc",
		"color": Color(0.6, 0.2, 0.8), "evo_key": "la_robba", "is_weapon": true, "max_level": 9,
	},
	48: {
		"name": "Greatest Jubilee", "name_key": "item.greatest_jubilee_name",
		"desc": "Chance to spawn light sources", "desc_key": "item.greatest_jubilee_desc",
		"color": Color(0.9, 0.8, 0.1), "evo_key": "greatest_jubilee", "is_weapon": true, "max_level": 10,
	},
	49: {
		"name": "Bracelet", "name_key": "item.bracelet_name",
		"desc": "Fires projectiles at random enemies", "desc_key": "item.bracelet_desc",
		"color": Color(0.7, 0.3, 0.6), "evo_key": "bracelet", "is_weapon": true, "max_level": 7,
	},
	50: {
		"name": "Candybox", "name_key": "item.candybox_name",
		"desc": "Choose any unlocked base weapon", "desc_key": "item.candybox_desc",
		"color": Color(0.9, 0.3, 0.7), "evo_key": "candybox", "is_weapon": true, "max_level": 2,
	},
	51: {
		"name": "Victory Sword", "name_key": "item.victory_sword_name",
		"desc": "Swings a mighty sword that grows with each swing", "desc_key": "item.victory_sword_desc",
		"color": Color(0.9, 0.8, 0.6), "evo_key": "victory_sword", "is_weapon": true, "max_level": 13,
	},
	52: {
		"name": "Flames of Misspell", "name_key": "item.flames_of_misspell_name",
		"desc": "Emit a cone of flames", "desc_key": "item.flames_of_misspell_desc",
		"color": Color(0.9, 0.3, 0.1), "evo_key": "flames_of_misspell", "is_weapon": true, "max_level": 9,
	},
	53: {
		"name": "Pako Battiliar", "name_key": "item.pako_battiliar_name",
		"desc": "May counterattack when taking damage", "desc_key": "item.pako_battiliar_desc",
		"color": Color(0.4, 0.2, 0.4), "evo_key": "pako_battiliar", "is_weapon": true, "max_level": 9,
	},
	54: {
		"name": "Ammo Appalate", "name_key": "item.ammo_appalate_name",
		"desc": "Aims at enemies in faced direction, stores shots", "desc_key": "item.ammo_appalate_desc",
		"color": Color(0.5, 0.7, 0.3), "evo_key": "ammo_appalate", "is_weapon": true, "max_level": 9,
	},
	55: {
		"name": "Chaos Rune", "name_key": "item.chaos_rune_name",
		"desc": "Speed and duration affect hit count", "desc_key": "item.chaos_rune_desc",
		"color": Color(0.7, 0.1, 0.7), "evo_key": "chaos_rune", "is_weapon": true, "max_level": 9,
	},
	56: {
		"name": "Glass Fandango", "name_key": "item.glass_fandango_name",
		"desc": "Stronger while moving and against frozen enemies", "desc_key": "item.glass_fandango_desc",
		"color": Color(0.5, 0.8, 0.9), "evo_key": "glass_fandango", "is_weapon": true, "max_level": 9,
	},
	57: {
		"name": "Santa Javelin", "name_key": "item.santa_javelin_name",
		"desc": "Duration affects amount, can crit", "desc_key": "item.santa_javelin_desc",
		"color": Color(0.8, 0.6, 0.1), "evo_key": "santa_javelin", "is_weapon": true, "max_level": 9,
	},
	58: {
		"name": "Gaze of Gaea", "name_key": "item.gaze_of_gaea_name",
		"desc": "May disarm enemies", "desc_key": "item.gaze_of_gaea_desc",
		"color": Color(0.3, 0.7, 0.3), "evo_key": "gaze_of_gaea", "is_weapon": true, "max_level": 9,
	},
	59: {
		"name": "Magi-Stone", "name_key": "item.magi_stone_name",
		"desc": "Deals damage based on weapon level", "desc_key": "item.magi_stone_desc",
		"color": Color(0.6, 0.4, 0.8), "evo_key": "magi_stone", "is_weapon": true, "max_level": 9,
	},
	60: {
		"name": "Phas3r", "name_key": "item.phas3r_name",
		"desc": "Creates thin damaging zones, high amount scaling", "desc_key": "item.phas3r_desc",
		"color": Color(0.2, 0.9, 0.6), "evo_key": "phas3r", "is_weapon": true, "max_level": 9,
	},
	61: {
		"name": "Arma Dio", "name_key": "item.arma_dio_name",
		"desc": "Select an additional passive item", "desc_key": "item.arma_dio_desc",
		"color": Color(0.8, 0.2, 0.2), "evo_key": "arma_dio", "is_weapon": true, "max_level": 2,
	},
}


static func is_weapon(t: int) -> bool:
	return t in WEAPON_TYPES


static func item_data(t: int) -> Dictionary:
	return DATA.get(t, DATA[0])


static func item_name(t: int) -> String:
	return DATA.get(t, {}).get("name", "?")


static func item_name_key(t: int) -> String:
	return DATA.get(t, {}).get("name_key", "item.whip_name")


static func item_desc(t: int) -> String:
	return DATA.get(t, {}).get("desc", "")


static func item_desc_key(t: int) -> String:
	return DATA.get(t, {}).get("desc_key", "item.whip_desc")


static func item_color(t: int) -> Color:
	return DATA.get(t, {}).get("color", Color.WHITE)


static func item_evo_key(t: int) -> String:
	return DATA.get(t, {}).get("evo_key", "whip")


static func item_max_level(t: int) -> int:
	return DATA.get(t, {}).get("max_level", 8)
