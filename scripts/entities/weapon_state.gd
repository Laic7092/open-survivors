class_name WeaponState

const ItemTypes = preload("res://scripts/data/item_types.gd")
const _ItemDefs = preload("res://scripts/data/item_defs.gd")

var type: int
var level: int
var max_level: int
var cooldown: float
var cooldown_timer: float
var damage: float
var area: float
var speed: float
var amount: int = 1
var pierce: int = 1
var evolved: bool = false

# ── Limit Break ──
var limit_break_level: int = 0        # how many limit break upgrades applied
var limit_break_bonuses: Dictionary = {}  # {stat_key: total_accumulated_value}

# ── Per-weapon state (for behaviors that need to persist between fires) ──
var custom_state: Dictionary = {}  # e.g. {"whip_swing_dir": 1}


# ════════════════════════════════════════════════════════════════
#  DATA — Base stats
# ════════════════════════════════════════════════════════════════
# "cd" = cooldown in seconds
# "dmg" = base damage (game-tuned)
# "area" = base area in pixel-units (100% on wiki ≈ this value)
# "speed" = projectile speed in px/sec (or 0 for static)
# "amt" = base projectile amount
static var _BASE = {
	ItemTypes.Type.WHIP: {"cd": 1.35, "dmg": 50.0, "area": 60.0, "speed": 0.0, "amt": 1},
	ItemTypes.Type.MAGIC_WAND: {"cd": 1.2, "dmg": 20.0, "area": 12.0, "speed": 400.0, "amt": 1, "pierce": 1},
	ItemTypes.Type.GARLIC: {"cd": 1.3, "dmg": 10.0, "area": 70.0, "speed": 0.0, "amt": 1},
	ItemTypes.Type.KNIFE: {"cd": 1.0, "dmg": 30.0, "area": 10.0, "speed": 600.0, "amt": 1, "pierce": 1},
	ItemTypes.Type.AXE: {"cd": 4.0, "dmg": 100.0, "area": 40.0, "speed": 0.0, "amt": 1, "pierce": 3},
	ItemTypes.Type.FIRE_WAND: {"cd": 3.0, "dmg": 50.0, "area": 20.0, "speed": 300.0, "amt": 3, "pierce": 1},
	ItemTypes.Type.CROSS: {"cd": 2.0, "dmg": 60.0, "area": 40.0, "speed": 400.0, "amt": 1},
	ItemTypes.Type.KING_BIBLE: {"cd": 3.0, "dmg": 15.0, "area": 50.0, "speed": 200.0, "amt": 1},
	ItemTypes.Type.SANTA_WATER: {"cd": 4.5, "dmg": 20.0, "area": 60.0, "speed": 0.0, "amt": 1},
	ItemTypes.Type.RUNETRACER: {"cd": 0.8, "dmg": 25.0, "area": 16.0, "speed": 500.0, "amt": 1, "pierce": 999},  # infinite pierce
	ItemTypes.Type.LIGHTNING_RING: {"cd": 1.5, "dmg": 40.0, "area": 40.0, "speed": 0.0, "amt": 2},
	ItemTypes.Type.PENTAGRAM: {"cd": 90.0, "dmg": 0.0, "area": 400.0, "speed": 0.0, "amt": 1},
	ItemTypes.Type.PEACHONE: {"cd": 1.0, "dmg": 10.0, "area": 30.0, "speed": 200.0, "amt": 4},
	ItemTypes.Type.EBONY_WINGS: {"cd": 1.0, "dmg": 10.0, "area": 30.0, "speed": 200.0, "amt": 4},
	ItemTypes.Type.PHIERA_DER_TUPHELLO: {"cd": 1.4, "dmg": 5.0, "area": 8.0, "speed": 500.0, "amt": 1, "pierce": 3},
	ItemTypes.Type.EIGHT_THE_SPARROW: {"cd": 1.4, "dmg": 5.0, "area": 8.0, "speed": 500.0, "amt": 1},
	ItemTypes.Type.GATTI_AMARI: {"cd": 5.0, "dmg": 10.0, "area": 20.0, "speed": 150.0, "amt": 1},
	ItemTypes.Type.SONG_OF_MANA: {"cd": 2.0, "dmg": 10.0, "area": 30.0, "speed": 0.0, "amt": 1},
	ItemTypes.Type.SHADOW_PINION: {"cd": 6.0, "dmg": 10.0, "area": 25.0, "speed": 0.0, "amt": 1},
	ItemTypes.Type.CLOCK_LANCET: {"cd": 2.0, "dmg": 0.0, "area": 20.0, "speed": 300.0, "amt": 1},
	ItemTypes.Type.LAUREL: {"cd": 10.0, "dmg": 0.0, "area": 30.0, "speed": 0.0, "amt": 1},
	ItemTypes.Type.VENTO_SACRO: {"cd": 2.0, "dmg": 2.0, "area": 15.0, "speed": 300.0, "amt": 4},
	ItemTypes.Type.BONE: {"cd": 3.0, "dmg": 5.0, "area": 10.0, "speed": 400.0, "amt": 1},
	ItemTypes.Type.CHERRY_BOMB: {"cd": 3.0, "dmg": 10.0, "area": 15.0, "speed": 350.0, "amt": 1},
	ItemTypes.Type.CARRELLO: {"cd": 0.6, "dmg": 10.0, "area": 12.0, "speed": 400.0, "amt": 1},
	ItemTypes.Type.CELESTIAL_DUSTING: {"cd": 6.0, "dmg": 5.0, "area": 12.0, "speed": 400.0, "amt": 1},
	ItemTypes.Type.LA_ROBBA: {"cd": 4.5, "dmg": 10.0, "area": 15.0, "speed": 350.0, "amt": 3},
	ItemTypes.Type.GREATEST_JUBILEE: {"cd": 3.0, "dmg": 10.0, "area": 30.0, "speed": 0.0, "amt": 1},
	ItemTypes.Type.BRACELET: {"cd": 1.4, "dmg": 10.0, "area": 12.0, "speed": 450.0, "amt": 3},
	ItemTypes.Type.CANDYBOX: {"cd": 999.0, "dmg": 0.0, "area": 0.0, "speed": 0.0, "amt": 1},
	ItemTypes.Type.VICTORY_SWORD: {"cd": 1.85, "dmg": 5.0, "area": 25.0, "speed": 0.0, "amt": 2},
	ItemTypes.Type.FLAMES_OF_MISSPELL: {"cd": 4.0, "dmg": 10.0, "area": 25.0, "speed": 250.0, "amt": 12},
	ItemTypes.Type.PAKO_BATTILIAR: {"cd": 8.0, "dmg": 20.0, "area": 40.0, "speed": 0.0, "amt": 10},
	ItemTypes.Type.AMMO_APPALATE: {"cd": 2.0, "dmg": 5.0, "area": 10.0, "speed": 500.0, "amt": 3},
	ItemTypes.Type.CHAOS_RUNE: {"cd": 3.0, "dmg": 10.0, "area": 20.0, "speed": 300.0, "amt": 1},
	ItemTypes.Type.GLASS_FANDANGO: {"cd": 1.4, "dmg": 10.0, "area": 20.0, "speed": 0.0, "amt": 1},
	ItemTypes.Type.SANTA_JAVELIN: {"cd": 6.5, "dmg": 20.0, "area": 15.0, "speed": 0.0, "amt": 1},
	ItemTypes.Type.GAZE_OF_GAEA: {"cd": 2.0, "dmg": 5.0, "area": 30.0, "speed": 0.0, "amt": 1},
	ItemTypes.Type.MAGI_STONE: {"cd": 3.5, "dmg": 10.0, "area": 20.0, "speed": 300.0, "amt": 1},
	ItemTypes.Type.PHAS3R: {"cd": 5.0, "dmg": 5.0, "area": 12.0, "speed": 0.0, "amt": 1},
	ItemTypes.Type.ARMA_DIO: {"cd": 999.0, "dmg": 0.0, "area": 0.0, "speed": 0.0, "amt": 1},
}


# ════════════════════════════════════════════════════════════════
#  DATA — Per-level upgrade table
# ════════════════════════════════════════════════════════════════
# Array of dictionaries. Index 0 = Level 2 bonus, 1 = Level 3, etc.
# Supported keys:
#   "dmg"       — flat damage increase
#   "area_pct"  — +X% of base area (pixels = base_area * area_pct / 100)
#   "amt"       — +X amount (projectile count)
#   "speed"     — flat speed increase (px/sec)
#   "cd_pct"    — cooldown multiplied by (1 - cd_pct/100)
static var _UPGRADES = {
	ItemTypes.Type.WHIP: [
		# Lv2      Lv3       Lv4              Lv5       Lv6              Lv7       Lv8
		{"amt": 1}, {"dmg": 5}, {"dmg": 5, "area_pct": 10}, {"dmg": 5}, {"dmg": 5, "area_pct": 10}, {"dmg": 5}, {"dmg": 5},
	],
	ItemTypes.Type.MAGIC_WAND: [
		# Lv2        Lv3          Lv4        Lv5         Lv6        Lv7          Lv8
		{"amt": 1}, {"cd": 0.2}, {"amt": 1}, {"dmg": 10}, {"amt": 1}, {"pierce": 1}, {"dmg": 10},
	],
	ItemTypes.Type.GARLIC: [
		# Lv2                   Lv3                         Lv4                   Lv5                         Lv6                   Lv7                         Lv8
		{"area_pct": 40, "dmg": 2}, {"cd": 0.1, "dmg": 1}, {"area_pct": 20, "dmg": 1}, {"cd": 0.1, "dmg": 2}, {"area_pct": 20, "dmg": 1}, {"cd": 0.1, "dmg": 1}, {"area_pct": 20, "dmg": 2},
	],
	ItemTypes.Type.KNIFE: [
		# Lv2        Lv3               Lv4        Lv5           Lv6        Lv7               Lv8
		{"amt": 1}, {"amt": 1, "dmg": 5}, {"amt": 1}, {"pierce": 1}, {"amt": 1}, {"amt": 1, "dmg": 5}, {"pierce": 1},
	],
	ItemTypes.Type.AXE: [
		# Lv2        Lv3         Lv4           Lv5        Lv6         Lv7           Lv8
		{"amt": 1}, {"dmg": 20}, {"pierce": 2}, {"amt": 1}, {"dmg": 20}, {"pierce": 2}, {"dmg": 20},
	],
	ItemTypes.Type.FIRE_WAND: [
		# Lv2        Lv3                    Lv4        Lv5                    Lv6        Lv7                    Lv8
		{"dmg": 10}, {"dmg": 10, "speed_pct": 20}, {"dmg": 10}, {"dmg": 10, "speed_pct": 20}, {"dmg": 10}, {"dmg": 10, "speed_pct": 20}, {"dmg": 10},
	],
	ItemTypes.Type.CROSS: [
		# Lv2         Lv3                       Lv4        Lv5         Lv6                       Lv7        Lv8
		{"dmg": 10}, {"area_pct": 10, "speed_pct": 25}, {"amt": 1}, {"dmg": 10}, {"area_pct": 10, "speed_pct": 25}, {"amt": 1}, {"dmg": 10},
	],
	ItemTypes.Type.KING_BIBLE: [
		# Lv2        Lv3                       Lv4                         Lv5        Lv6                       Lv7                         Lv8
		{"amt": 1}, {"area_pct": 25, "speed_pct": 30}, {"dmg": 10, "duration_pct": 50}, {"amt": 1}, {"area_pct": 25, "speed_pct": 30}, {"dmg": 10, "duration_pct": 50}, {"amt": 1},
	],
	ItemTypes.Type.SANTA_WATER: [
		# Lv2                Lv3                         Lv4                Lv5                         Lv6                Lv7                        Lv8
		{"amt": 1, "area_pct": 20}, {"dmg": 10, "duration_pct": 50}, {"amt": 1, "area_pct": 20}, {"dmg": 10, "duration_pct": 25}, {"amt": 1, "area_pct": 20}, {"dmg": 5, "duration_pct": 25}, {"dmg": 5, "area_pct": 20},
	],
	ItemTypes.Type.RUNETRACER: [
		# Lv2                 Lv3                        Lv4        Lv5                 Lv6                        Lv7        Lv8
		{"dmg": 5, "speed_pct": 20}, {"dmg": 5, "duration_pct": 25}, {"amt": 1}, {"dmg": 5, "speed_pct": 20}, {"dmg": 5, "duration_pct": 25}, {"amt": 1}, {"duration_pct": 50},
	],
	ItemTypes.Type.LIGHTNING_RING: [
		{"dmg": 6}, {"amt": 1}, {"dmg": 6}, {"amt": 1}, {"dmg": 6}, {"amt": 1}, {"dmg": 6},
	],
	ItemTypes.Type.PENTAGRAM: [
		{"area_pct": 10}, {"cooldown_pct": 5}, {"area_pct": 10}, {"cooldown_pct": 5}, {"area_pct": 10}, {"cooldown_pct": 5}, {"area_pct": 10},
	],
	ItemTypes.Type.PEACHONE: [
		{"amt": 1}, {"dmg": 2}, {"amt": 1}, {"dmg": 2}, {"amt": 1}, {"area_pct": 10}, {"amt": 1},
	],
	ItemTypes.Type.EBONY_WINGS: [
		{"amt": 1}, {"dmg": 2}, {"amt": 1}, {"dmg": 2}, {"amt": 1}, {"area_pct": 10}, {"amt": 1},
	],
	ItemTypes.Type.PHIERA_DER_TUPHELLO: [
		{"dmg": 1}, {"dmg": 1}, {"amt": 1}, {"dmg": 1}, {"dmg": 1}, {"amt": 1}, {"dmg": 1},
	],
	ItemTypes.Type.EIGHT_THE_SPARROW: [
		{"dmg": 1}, {"amt": 1}, {"dmg": 1}, {"dmg": 1}, {"amt": 1}, {"dmg": 1}, {"dmg": 1},
	],
	ItemTypes.Type.GATTI_AMARI: [
		{"dmg": 2}, {"area_pct": 8}, {"dmg": 2}, {"amt": 1}, {"area_pct": 8}, {"dmg": 2}, {"amt": 1},
	],
	ItemTypes.Type.SONG_OF_MANA: [
		{"area_pct": 15}, {"dmg": 3}, {"area_pct": 15}, {"dmg": 3}, {"area_pct": 15}, {"dmg": 3}, {"area_pct": 15},
	],
	ItemTypes.Type.SHADOW_PINION: [
		{"dmg": 2}, {"area_pct": 8}, {"dmg": 2}, {"area_pct": 8}, {"dmg": 2}, {"area_pct": 8}, {"amt": 1},
	],
	ItemTypes.Type.CLOCK_LANCET: [
		{}, {}, {}, {}, {}, {},  # 7 levels total at max_level=7
	],
	ItemTypes.Type.LAUREL: [
		{}, {}, {}, {}, {}, {},
	],
	ItemTypes.Type.VENTO_SACRO: [
		{"dmg": 1}, {"amt": 1}, {"dmg": 1}, {"area_pct": 8}, {"amt": 1}, {"dmg": 1}, {"amt": 1},
	],
	ItemTypes.Type.BONE: [
		{"dmg": 2}, {"dmg": 2}, {"area_pct": 5}, {"dmg": 2}, {"amt": 1}, {"dmg": 2}, {"amt": 1},
	],
	ItemTypes.Type.CHERRY_BOMB: [
		{"area_pct": 10}, {"dmg": 2}, {"area_pct": 10}, {"dmg": 2}, {"area_pct": 10}, {"dmg": 2}, {"amt": 1},
	],
	ItemTypes.Type.CARRELLO: [
		{"dmg": 2}, {"area_pct": 5}, {"dmg": 2}, {"amt": 1}, {"dmg": 2}, {"area_pct": 5}, {"amt": 1},
	],
	ItemTypes.Type.CELESTIAL_DUSTING: [
		{"dmg": 1}, {"area_pct": 5}, {"dmg": 1}, {"dmg": 1}, {"area_pct": 5}, {"dmg": 1}, {"amt": 1},
	],
	ItemTypes.Type.LA_ROBBA: [
		{"amt": 1}, {"dmg": 3}, {"amt": 1}, {"dmg": 3}, {"area_pct": 5}, {"dmg": 3}, {"amt": 1},
	],
	ItemTypes.Type.GREATEST_JUBILEE: [
		{"dmg": 2}, {"amt": 1}, {"area_pct": 5}, {"dmg": 2}, {"amt": 1}, {"dmg": 2}, {"area_pct": 5}, {"amt": 1},
	],
	ItemTypes.Type.BRACELET: [
		{"dmg": 3}, {"dmg": 3}, {"area_pct": 5}, {"dmg": 3}, {"amt": 1},
	],
	ItemTypes.Type.CANDYBOX: [
		{"amt": 1},
	],
	ItemTypes.Type.VICTORY_SWORD: [
		{"dmg": 2}, {"amt": 1}, {"dmg": 2}, {"amt": 1}, {"dmg": 2},
		{"amt": 1}, {"dmg": 2}, {"amt": 1}, {"dmg": 2}, {"amt": 1}, {"dmg": 2},
	],
	ItemTypes.Type.FLAMES_OF_MISSPELL: [
		{"dmg": 3}, {"area_pct": 5}, {"dmg": 3}, {"area_pct": 5}, {"dmg": 3}, {"area_pct": 5}, {"dmg": 3},
	],
	ItemTypes.Type.PAKO_BATTILIAR: [
		{"dmg": 3}, {"amt": 1}, {"dmg": 3}, {"area_pct": 5}, {"amt": 1}, {"dmg": 3}, {"amt": 1},
	],
	ItemTypes.Type.AMMO_APPALATE: [
		{"dmg": 1}, {"amt": 1}, {"dmg": 1}, {"amt": 1}, {"dmg": 1}, {"area_pct": 5}, {"amt": 1},
	],
	ItemTypes.Type.CHAOS_RUNE: [
		{"dmg": 2}, {"area_pct": 5}, {"dmg": 2}, {"amt": 1}, {"dmg": 2}, {"area_pct": 5}, {"amt": 1},
	],
	ItemTypes.Type.GLASS_FANDANGO: [
		{"dmg": 2}, {"area_pct": 5}, {"dmg": 2}, {"amt": 1}, {"area_pct": 5}, {"dmg": 2}, {"amt": 1},
	],
	ItemTypes.Type.SANTA_JAVELIN: [
		{"dmg": 5}, {"area_pct": 8}, {"dmg": 5}, {"area_pct": 8}, {"dmg": 5}, {"amt": 1}, {"dmg": 5},
	],
	ItemTypes.Type.GAZE_OF_GAEA: [
		{"area_pct": 5}, {"dmg": 1}, {"area_pct": 5}, {"amt": 1}, {"dmg": 1}, {"area_pct": 5}, {"amt": 1},
	],
	ItemTypes.Type.MAGI_STONE: [
		{"dmg": 2}, {"area_pct": 5}, {"dmg": 2}, {"amt": 1}, {"area_pct": 5}, {"dmg": 2}, {"amt": 1},
	],
	ItemTypes.Type.PHAS3R: [
		{"area_pct": 10}, {"dmg": 1}, {"area_pct": 10}, {"amt": 1}, {"area_pct": 10}, {"dmg": 1}, {"amt": 1},
	],
	ItemTypes.Type.ARMA_DIO: [
		{"amt": 1},
	],
}


# ════════════════════════════════════════════════════════════════
#  DATA — Limit Break options per weapon
# ════════════════════════════════════════════════════════════════
# Each entry:
#   "options" → array of {stat, value, rarity(weight), max_total(cap)}
#   stat: might_pct, area_pct, speed_pct, amt, base_dmg, cd_pct
#   rarity: selection weight (higher = more common). -1 = always in pool.
#   max_total: max accumulable value. -1 = unlimited.
static var _LIMIT_BREAKS := {
	ItemTypes.Type.WHIP: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.MAGIC_WAND: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "speed_pct", "value": 5.0, "rarity": 10, "max_total": 300.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "pierce", "value": 1, "rarity": 5, "max_total": 10},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.GARLIC: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.KNIFE: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "speed_pct", "value": 5.0, "rarity": 10, "max_total": 300.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "pierce", "value": 1, "rarity": 5, "max_total": -1},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.AXE: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "speed_pct", "value": 5.0, "rarity": 10, "max_total": 300.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "pierce", "value": 1, "rarity": 5, "max_total": 10},
		],
	},
	ItemTypes.Type.FIRE_WAND: {
		"options": [
			{"stat": "might_pct", "value": 1.0, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "speed_pct", "value": 5.0, "rarity": 10, "max_total": 300.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 1.0, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.CROSS: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "speed_pct", "value": 5.0, "rarity": 10, "max_total": 300.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
		],
	},
	ItemTypes.Type.KING_BIBLE: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "speed_pct", "value": 5.0, "rarity": 10, "max_total": 300.0},
			{"stat": "duration_pct", "value": 100.0, "rarity": 1, "max_total": 9.0},
		],
	},
	ItemTypes.Type.SANTA_WATER: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "duration_pct", "value": 100.0, "rarity": 1, "max_total": 9.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
		],
	},
	ItemTypes.Type.RUNETRACER: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "speed_pct", "value": 5.0, "rarity": 10, "max_total": 300.0},
			{"stat": "duration_pct", "value": 100.0, "rarity": 1, "max_total": 6.0},
		],
	},
	ItemTypes.Type.LIGHTNING_RING: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.PENTAGRAM: {
		"options": [
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "cd_pct", "value": 1.0, "rarity": 8, "max_total": 80.0},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.PEACHONE: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.EBONY_WINGS: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.PHIERA_DER_TUPHELLO: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "speed_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.EIGHT_THE_SPARROW: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "speed_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.GATTI_AMARI: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.SONG_OF_MANA: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "cd_pct", "value": 1.0, "rarity": 8, "max_total": 80.0},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.SHADOW_PINION: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "speed_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.CLOCK_LANCET: {
		"options": [
			{"stat": "cd_pct", "value": 1.0, "rarity": 10, "max_total": 80.0},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.LAUREL: {
		"options": [
			{"stat": "cd_pct", "value": 1.0, "rarity": 10, "max_total": 80.0},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
		],
	},
	ItemTypes.Type.VENTO_SACRO: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.BONE: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "speed_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.CHERRY_BOMB: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.CARRELLO: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "speed_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.CELESTIAL_DUSTING: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "speed_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "cd_pct", "value": 1.0, "rarity": 8, "max_total": 80.0},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.LA_ROBBA: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.GREATEST_JUBILEE: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.BRACELET: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "speed_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.CANDYBOX: {
		"options": [
			{"stat": "amt", "value": 1, "rarity": -1, "max_total": 10},
		],
	},
	ItemTypes.Type.VICTORY_SWORD: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.FLAMES_OF_MISSPELL: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.PAKO_BATTILIAR: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.AMMO_APPALATE: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "speed_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.CHAOS_RUNE: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "speed_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.GLASS_FANDANGO: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.SANTA_JAVELIN: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.GAZE_OF_GAEA: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.MAGI_STONE: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.PHAS3R: {
		"options": [
			{"stat": "might_pct", "value": 0.5, "rarity": 10, "max_total": -1},
			{"stat": "area_pct", "value": 2.5, "rarity": 10, "max_total": 1000.0},
			{"stat": "amt", "value": 1, "rarity": 1, "max_total": 20},
			{"stat": "base_dmg", "value": 0.5, "rarity": -1, "max_total": -1},
		],
	},
	ItemTypes.Type.ARMA_DIO: {
		"options": [
			{"stat": "amt", "value": 1, "rarity": -1, "max_total": 5},
		],
	},
}


# Maximum number of limit break choices to offer per level-up
const _LIMIT_BREAK_CHOICE_COUNT: int = 3


# Weighted random selection helper
static func _weighted_pick(options: Array, count: int) -> Array:
	# Separate guaranteed options (rarity = -1) from weighted pool
	var guaranteed: Array = []
	var weighted: Array = []
	var total_weight: float = 0.0
	for opt in options:
		var r = opt.get("rarity", 1)
		if r < 0:
			guaranteed.append(opt)
		else:
			weighted.append(opt)
			total_weight += r
	# Always include guaranteed options first
	var result: Array = guaranteed.duplicate()
	# Pick from weighted pool until we have enough or run out
	var picked_indices: Array = []
	while result.size() < count and weighted.size() > picked_indices.size():
		# Recalculate remaining weight
		var remaining_weight: float = 0.0
		for i in range(weighted.size()):
			if i in picked_indices:
				continue
			remaining_weight += weighted[i].get("rarity", 1)
		if remaining_weight <= 0:
			break
		# Pick random
		var roll = randf() * remaining_weight
		var cumulative: float = 0.0
		var picked = -1
		for i in range(weighted.size()):
			if i in picked_indices:
				continue
			cumulative += weighted[i].get("rarity", 1)
			if roll <= cumulative:
				picked = i
				break
		if picked < 0:
			break
		picked_indices.append(picked)
		result.append(weighted[picked])
	return result


func _init(t: int):
	type = t; level = 1; max_level = _ItemDefs.item_max_level(t)
	var b = _BASE[t]
	cooldown = b["cd"]; damage = b["dmg"]
	area = b["area"]; speed = b["speed"]; amount = b.get("amt", 1)
	pierce = b.get("pierce", 1)
	cooldown_timer = 0.0


# ════════════════════════════════════════════════════════════════
#  UPGRADE SYSTEM — per-level additive
# ════════════════════════════════════════════════════════════════

func upgrade():
	level += 1
	var levels = _UPGRADES.get(type, [])
	var idx = level - 2  # index 0 = level 2
	if idx >= 0 and idx < levels.size():
		_apply_level_data(levels[idx])


# Apply a per-level data dictionary (handles all stat keys generically)
func _apply_level_data(d: Dictionary):
	for key in d:
		match key:
			"dmg":
				damage += d[key]
			"area_pct":
				# +X% of base area
				area += _BASE[type]["area"] * d[key] / 100.0
			"amt":
				amount += d[key]
			"pierce":
				pierce += d[key]
			"speed":
				speed += d[key]
			"speed_pct":
				# +X% of base speed
				speed += _BASE[type]["speed"] * d[key] / 100.0
			"duration_pct":
				# Per-weapon duration TBD — currently global via player.duration_bonus
				pass
			"cd":
				# Flat cooldown reduction (seconds)
				cooldown = max(cooldown - d[key], 0.1)
			"cd_pct", "cooldown_pct":
				cooldown *= (1.0 - d[key] / 100.0)
			_:
				push_warning("WeaponState: unknown upgrade key '%s' for type %d" % [key, type])


# ════════════════════════════════════════════════════════════════
#  LIMIT BREAK SYSTEM
# ════════════════════════════════════════════════════════════════

# Check if limit break is available (requires Great Gospel relic)
func can_limit_break() -> bool:
	if not Engine.has_singleton("RelicManager"):
		return false
	return Engine.get_singleton("RelicManager").has_relic("great_gospel")


# Get weighted random limit break options (respects caps, returns up to N choices)
func get_limit_break_options() -> Array:
	var lb_data = _LIMIT_BREAKS.get(type, {})
	var all_options = lb_data.get("options", [])
	# Filter out capped options
	var available: Array = []
	for opt in all_options:
		var stat = opt["stat"]
		var max_total = opt.get("max_total", -1)
		if max_total > 0:
			var current = limit_break_bonuses.get(stat, 0.0)
			if current >= max_total:
				continue
		available.append(opt)
	if available.is_empty():
		return []
	# Weighted random selection
	return _weighted_pick(available, _LIMIT_BREAK_CHOICE_COUNT)


# Apply a limit break option chosen from get_limit_break_options()
func apply_limit_break(opt: Dictionary) -> bool:
	var stat = opt.get("stat", "")
	var value = opt.get("value", 0.0)
	if stat == "":
		return false
	# Track accumulated bonus
	limit_break_bonuses[stat] = limit_break_bonuses.get(stat, 0.0) + value
	limit_break_level += 1
	# Apply stat changes based on key
	match stat:
		"might_pct":
			damage *= (1.0 + value / 100.0)
		"area_pct":
			area *= (1.0 + value / 100.0)
		"speed_pct":
			speed *= (1.0 + value / 100.0)
		"amt":
			amount += value
		"base_dmg":
			damage += value
		"cd_pct":
			cooldown *= (1.0 - value / 100.0)
		_:
			push_warning("WeaponState: unknown limit break stat '%s'" % stat)
	return true


# ════════════════════════════════════════════════════════════════
#  EVOLUTION SYSTEM
# ════════════════════════════════════════════════════════════════

func evolve():
	evolved = true
	# Evolution stat boosts (wiki-aligned: most get +dmg +area, +cd reduction)
	match type:
		ItemTypes.Type.WHIP:
			damage *= 1.8; area *= 1.4
			amount += 1
		ItemTypes.Type.MAGIC_WAND:
			cooldown = 0.10; damage *= 1.5
			amount += 1
		ItemTypes.Type.GARLIC:
			area *= 1.3; damage *= 1.8; cooldown *= 0.7
		ItemTypes.Type.KNIFE:
			damage *= 1.5; speed *= 1.3
			amount += 2
		ItemTypes.Type.AXE:
			damage *= 1.8; area *= 1.4
			amount += 1
		ItemTypes.Type.FIRE_WAND:
			damage *= 1.5; area *= 1.3
		ItemTypes.Type.CROSS:
			damage *= 1.6; cooldown *= 0.7
			amount += 1
		ItemTypes.Type.KING_BIBLE:
			damage *= 1.5; area *= 1.3
			amount += 1
		ItemTypes.Type.SANTA_WATER:
			damage *= 1.6; area *= 1.3
			amount += 1
		ItemTypes.Type.RUNETRACER:
			damage *= 1.5; speed *= 1.4
			amount += 1
		ItemTypes.Type.LIGHTNING_RING:
			damage *= 1.6; area *= 1.3
			amount += 2
		ItemTypes.Type.PENTAGRAM:
			cooldown *= 0.5; area *= 1.5
		ItemTypes.Type.PEACHONE:
			damage *= 1.6; area *= 1.3
			amount += 3
		ItemTypes.Type.EBONY_WINGS:
			damage *= 1.6; area *= 1.3
			amount += 3
		ItemTypes.Type.PHIERA_DER_TUPHELLO:
			damage *= 1.8; speed *= 1.2
			amount += 1
		ItemTypes.Type.EIGHT_THE_SPARROW:
			damage *= 1.8; speed *= 1.2
			amount += 1
		ItemTypes.Type.GATTI_AMARI:
			damage *= 1.6; area *= 1.3
			amount += 1
		ItemTypes.Type.SONG_OF_MANA:
			damage *= 1.5; area *= 1.5
		ItemTypes.Type.SHADOW_PINION:
			damage *= 1.8; area *= 1.3
			amount += 1
		ItemTypes.Type.CLOCK_LANCET:
			cooldown *= 0.5
		ItemTypes.Type.LAUREL:
			cooldown *= 0.4
		ItemTypes.Type.VENTO_SACRO:
			damage *= 1.5; speed *= 1.3
			amount += 2
		ItemTypes.Type.BONE:
			damage *= 1.6; speed *= 1.2
			amount += 1
		ItemTypes.Type.CHERRY_BOMB:
			damage *= 1.5; area *= 1.3
			amount += 1
		ItemTypes.Type.CARRELLO:
			damage *= 1.6; speed *= 1.2
			amount += 1
		ItemTypes.Type.CELESTIAL_DUSTING:
			damage *= 1.5; cooldown *= 0.7
			amount += 1
		ItemTypes.Type.LA_ROBBA:
			damage *= 1.5; area *= 1.3
			amount += 2
		ItemTypes.Type.GREATEST_JUBILEE:
			area *= 1.4; cooldown *= 0.7
			amount += 2
		ItemTypes.Type.BRACELET:
			damage *= 1.6; speed *= 1.2
			amount += 1
		ItemTypes.Type.VICTORY_SWORD:
			damage *= 1.8; area *= 1.4
			amount += 2
		ItemTypes.Type.FLAMES_OF_MISSPELL:
			damage *= 1.6; area *= 1.4
		ItemTypes.Type.PAKO_BATTILIAR:
			damage *= 1.8; area *= 1.3
			amount += 3
		ItemTypes.Type.AMMO_APPALATE:
			damage *= 1.5; speed *= 1.3
			amount += 2
		ItemTypes.Type.CHAOS_RUNE:
			damage *= 1.5; area *= 1.3
			amount += 1
		ItemTypes.Type.GLASS_FANDANGO:
			damage *= 1.8; area *= 1.3
			amount += 2
		ItemTypes.Type.SANTA_JAVELIN:
			damage *= 1.6; area *= 1.3
			amount += 1
		ItemTypes.Type.GAZE_OF_GAEA:
			damage *= 1.5; area *= 1.4
			amount += 1
		ItemTypes.Type.MAGI_STONE:
			damage *= 1.6; area *= 1.3
			amount += 1
		ItemTypes.Type.PHAS3R:
			damage *= 1.5; area *= 1.5
			amount += 2
