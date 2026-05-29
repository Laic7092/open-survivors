extends RefCounted
# Centralized item definitions — single source of truth for weapon/passive metadata.
# Eliminates duplication across player.gd, main.gd, level_up_screen.gd, character_select.gd.

enum Type {
	WHIP = 0, MAGIC_WAND = 1, GARLIC = 2,
	WINGS = 3, SPINACH = 4, TOME = 5,
	HOLLOW_HEART = 6, CANDELABRADOR = 7, CROWN = 8, PUMMAROLA = 9,
	KNIFE = 10, AXE = 11, FIRE_WAND = 12,
	DUPLICATOR = 13, STONE_MASK = 14,
	MAGNET = 15,
	CROSS = 16, KING_BIBLE = 17, SANTA_WATER = 18,
	RUNETRACER = 19, LIGHTNING_RING = 20,
	CLOVER = 21, SPELLBINDER = 22, ARMOR = 23,
	BRACER = 24, SKULL = 25, TIRAGISU = 26,
	TORRONA = 27, SILVER_RING = 28, GOLD_RING = 29,
	METAGLIO_LEFT = 30, METAGLIO_RIGHT = 31
}

const WEAPON_TYPES: Array[int] = [0, 1, 2, 10, 11, 12, 16, 17, 18, 19, 20]

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
		"name": "Magnet", "name_key": "item.magnet_name",
		"desc": "Increase pickup range", "desc_key": "item.magnet_desc",
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
		"color": Color(0.9, 0.7, 0.9), "is_weapon": false, "max_level": 1,
	},
	27: {
		"name": "Torrona's Box", "name_key": "item.torrona_name",
		"desc": "Boost all stats slightly", "desc_key": "item.torrona_desc",
		"color": Color(0.4, 0.2, 0.6), "is_weapon": false, "max_level": 5,
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
}


static func is_weapon(t: int) -> bool:
	return t in WEAPON_TYPES


static func get_data(t: int) -> Dictionary:
	return DATA.get(t, DATA[0])


static func get_name(t: int) -> String:
	return DATA.get(t, {}).get("name", "?")


static func get_name_key(t: int) -> String:
	return DATA.get(t, {}).get("name_key", "item.whip_name")


static func get_desc(t: int) -> String:
	return DATA.get(t, {}).get("desc", "")


static func get_desc_key(t: int) -> String:
	return DATA.get(t, {}).get("desc_key", "item.whip_desc")


static func get_color(t: int) -> Color:
	return DATA.get(t, {}).get("color", Color.WHITE)


static func get_evo_key(t: int) -> String:
	return DATA.get(t, {}).get("evo_key", "whip")


static func get_max_level(t: int) -> int:
	return DATA.get(t, {}).get("max_level", 8)
