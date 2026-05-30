extends RefCounted
# Item type enums — tiny file, safe to preload anywhere.
# The bulk data dictionary lives in item_defs.gd (loaded lazily via DataRegistry).

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
	METAGLIO_LEFT = 30, METAGLIO_RIGHT = 31,
}

const WEAPON_TYPES: Array[int] = [
	0, 1, 2, 10, 11, 12, 16, 17, 18, 19, 20,
]
