class_name WeaponState

const ItemTypes = preload("res://scripts/data/item_types.gd")

var type: int
var level: int
var max_level: int
var cooldown: float
var cooldown_timer: float
var damage: float
var area: float
var speed: float
var evolved: bool = false

static var _BASE = {
	ItemTypes.Type.WHIP: {"cd": 1.0, "dmg": 50.0, "area": 60.0, "speed": 0.0},
	ItemTypes.Type.MAGIC_WAND: {"cd": 0.35, "dmg": 20.0, "area": 12.0, "speed": 400.0},
	ItemTypes.Type.GARLIC: {"cd": 0.8, "dmg": 10.0, "area": 70.0, "speed": 0.0},
	ItemTypes.Type.KNIFE: {"cd": 0.3, "dmg": 30.0, "area": 10.0, "speed": 600.0},
	ItemTypes.Type.AXE: {"cd": 1.2, "dmg": 100.0, "area": 40.0, "speed": 0.0},
	ItemTypes.Type.FIRE_WAND: {"cd": 0.8, "dmg": 50.0, "area": 20.0, "speed": 300.0},
	ItemTypes.Type.CROSS: {"cd": 1.2, "dmg": 60.0, "area": 40.0, "speed": 400.0},
	ItemTypes.Type.KING_BIBLE: {"cd": 2.0, "dmg": 15.0, "area": 50.0, "speed": 200.0},
	ItemTypes.Type.SANTA_WATER: {"cd": 2.0, "dmg": 20.0, "area": 60.0, "speed": 0.0},
	ItemTypes.Type.RUNETRACER: {"cd": 0.8, "dmg": 25.0, "area": 16.0, "speed": 500.0},
	ItemTypes.Type.LIGHTNING_RING: {"cd": 1.5, "dmg": 40.0, "area": 40.0, "speed": 0.0},
	ItemTypes.Type.PENTAGRAM: {"cd": 10.0, "dmg": 0.0, "area": 400.0, "speed": 0.0},
	ItemTypes.Type.PEACHONE: {"cd": 1.5, "dmg": 10.0, "area": 30.0, "speed": 200.0},
	ItemTypes.Type.EBONY_WINGS: {"cd": 1.5, "dmg": 10.0, "area": 30.0, "speed": 200.0},
	ItemTypes.Type.PHIERA_DER_TUPHELLO: {"cd": 0.25, "dmg": 5.0, "area": 8.0, "speed": 500.0},
	ItemTypes.Type.EIGHT_THE_SPARROW: {"cd": 0.25, "dmg": 5.0, "area": 8.0, "speed": 500.0},
	ItemTypes.Type.GATTI_AMARI: {"cd": 2.0, "dmg": 10.0, "area": 20.0, "speed": 150.0},
	ItemTypes.Type.SONG_OF_MANA: {"cd": 1.2, "dmg": 10.0, "area": 30.0, "speed": 0.0},
	ItemTypes.Type.SHADOW_PINION: {"cd": 0.8, "dmg": 10.0, "area": 25.0, "speed": 0.0},
	ItemTypes.Type.CLOCK_LANCET: {"cd": 3.0, "dmg": 0.0, "area": 20.0, "speed": 300.0},
	ItemTypes.Type.LAUREL: {"cd": 8.0, "dmg": 0.0, "area": 30.0, "speed": 0.0},
	ItemTypes.Type.VENTO_SACRO: {"cd": 0.4, "dmg": 2.0, "area": 15.0, "speed": 300.0},
	ItemTypes.Type.BONE: {"cd": 0.5, "dmg": 5.0, "area": 10.0, "speed": 400.0},
	ItemTypes.Type.CHERRY_BOMB: {"cd": 0.8, "dmg": 10.0, "area": 15.0, "speed": 350.0},
	ItemTypes.Type.CARRELLO: {"cd": 0.6, "dmg": 10.0, "area": 12.0, "speed": 400.0},
	ItemTypes.Type.CELESTIAL_DUSTING: {"cd": 0.7, "dmg": 5.0, "area": 12.0, "speed": 400.0},
	ItemTypes.Type.LA_ROBBA: {"cd": 0.8, "dmg": 10.0, "area": 15.0, "speed": 350.0},
	ItemTypes.Type.GREATEST_JUBILEE: {"cd": 1.5, "dmg": 10.0, "area": 30.0, "speed": 0.0},
	ItemTypes.Type.BRACELET: {"cd": 1.2, "dmg": 10.0, "area": 12.0, "speed": 450.0},
	ItemTypes.Type.CANDYBOX: {"cd": 999.0, "dmg": 0.0, "area": 0.0, "speed": 0.0},
	ItemTypes.Type.VICTORY_SWORD: {"cd": 0.6, "dmg": 5.0, "area": 25.0, "speed": 0.0},
	ItemTypes.Type.FLAMES_OF_MISSPELL: {"cd": 0.5, "dmg": 10.0, "area": 25.0, "speed": 250.0},
	ItemTypes.Type.PAKO_BATTILIAR: {"cd": 3.0, "dmg": 20.0, "area": 40.0, "speed": 0.0},
	ItemTypes.Type.AMMO_APPALATE: {"cd": 0.3, "dmg": 5.0, "area": 10.0, "speed": 500.0},
	ItemTypes.Type.CHAOS_RUNE: {"cd": 0.8, "dmg": 10.0, "area": 20.0, "speed": 300.0},
	ItemTypes.Type.GLASS_FANDANGO: {"cd": 0.6, "dmg": 10.0, "area": 20.0, "speed": 0.0},
	ItemTypes.Type.SANTA_JAVELIN: {"cd": 1.0, "dmg": 20.0, "area": 15.0, "speed": 0.0},
	ItemTypes.Type.GAZE_OF_GAEA: {"cd": 1.0, "dmg": 5.0, "area": 30.0, "speed": 0.0},
	ItemTypes.Type.MAGI_STONE: {"cd": 0.8, "dmg": 10.0, "area": 20.0, "speed": 300.0},
	ItemTypes.Type.PHAS3R: {"cd": 1.0, "dmg": 5.0, "area": 12.0, "speed": 0.0},
	ItemTypes.Type.ARMA_DIO: {"cd": 999.0, "dmg": 0.0, "area": 0.0, "speed": 0.0},
}

func _init(t: int):
	type = t; level = 1; max_level = DataRegistry.items().item_max_level(t)
	var b = _BASE[t]
	cooldown = b["cd"]; damage = b["dmg"]
	area = b["area"]; speed = b["speed"]
	cooldown_timer = 0.0

func upgrade():
	level += 1
	# ── Diminishing returns at high levels ──
	# Levels 2-5: strong gains (12% dmg, 8% area, 0.90x cd)
	# Levels 6-7: moderate gains (8% dmg, 5% area, 0.93x cd)
	# Levels 8-9: small gains (4% dmg, 3% area, 0.96x cd)
	# This makes investing levels past 5 less impactful per level,
	# so players feel diminishing returns and must rely on evolutions
	if level <= 5:
		cooldown = max(cooldown * 0.90, 0.1)
		damage *= 1.12
		area *= 1.08
		speed *= 1.08
	elif level <= 7:
		cooldown = max(cooldown * 0.93, 0.08)
		damage *= 1.08
		area *= 1.05
		speed *= 1.05
	else:
		cooldown = max(cooldown * 0.96, 0.06)
		damage *= 1.04
		area *= 1.03
		speed *= 1.03

func evolve():
	evolved = true
	match type:
		ItemTypes.Type.WHIP:
			damage *= 1.8
			area *= 1.4
		ItemTypes.Type.MAGIC_WAND:
			cooldown = 0.10
			damage *= 1.5
		ItemTypes.Type.GARLIC:
			area *= 1.3
			damage *= 1.8
			cooldown *= 0.7
		ItemTypes.Type.KNIFE:
			damage *= 1.5
			speed *= 1.3
		ItemTypes.Type.AXE:
			damage *= 1.8
			area *= 1.4
		ItemTypes.Type.FIRE_WAND:
			damage *= 1.5
			area *= 1.3
		ItemTypes.Type.CROSS:
			damage *= 1.6
			cooldown *= 0.7
		ItemTypes.Type.KING_BIBLE:
			damage *= 1.5
			area *= 1.3
		ItemTypes.Type.SANTA_WATER:
			damage *= 1.6
			area *= 1.3
		ItemTypes.Type.RUNETRACER:
			damage *= 1.5
			speed *= 1.4
		ItemTypes.Type.LIGHTNING_RING:
			damage *= 1.6
			area *= 1.3
		ItemTypes.Type.PENTAGRAM:
			cooldown *= 0.5
			area *= 1.5
		ItemTypes.Type.PEACHONE:
			damage *= 1.6
			area *= 1.3
		ItemTypes.Type.EBONY_WINGS:
			damage *= 1.6
			area *= 1.3
		ItemTypes.Type.PHIERA_DER_TUPHELLO:
			damage *= 1.8
			speed *= 1.2
		ItemTypes.Type.EIGHT_THE_SPARROW:
			damage *= 1.8
			speed *= 1.2
		ItemTypes.Type.GATTI_AMARI:
			damage *= 1.6
			area *= 1.3
		ItemTypes.Type.SONG_OF_MANA:
			damage *= 1.5
			area *= 1.5
		ItemTypes.Type.SHADOW_PINION:
			damage *= 1.8
			area *= 1.3
		ItemTypes.Type.CLOCK_LANCET:
			cooldown *= 0.5
		ItemTypes.Type.LAUREL:
			cooldown *= 0.4
		ItemTypes.Type.VENTO_SACRO:
			damage *= 1.5
			speed *= 1.3
		ItemTypes.Type.BONE:
			damage *= 1.6
			speed *= 1.2
		ItemTypes.Type.CHERRY_BOMB:
			damage *= 1.5
			area *= 1.3
		ItemTypes.Type.CARRELLO:
			damage *= 1.6
			speed *= 1.2
		ItemTypes.Type.CELESTIAL_DUSTING:
			damage *= 1.5
			cooldown *= 0.7
		ItemTypes.Type.LA_ROBBA:
			damage *= 1.5
			area *= 1.3
		ItemTypes.Type.GREATEST_JUBILEE:
			area *= 1.4
			cooldown *= 0.7
		ItemTypes.Type.BRACELET:
			damage *= 1.6
			speed *= 1.2
		ItemTypes.Type.VICTORY_SWORD:
			damage *= 1.8
			area *= 1.4
		ItemTypes.Type.FLAMES_OF_MISSPELL:
			damage *= 1.6
			area *= 1.4
		ItemTypes.Type.PAKO_BATTILIAR:
			damage *= 1.8
			area *= 1.3
		ItemTypes.Type.AMMO_APPALATE:
			damage *= 1.5
			speed *= 1.3
		ItemTypes.Type.CHAOS_RUNE:
			damage *= 1.5
			area *= 1.3
		ItemTypes.Type.GLASS_FANDANGO:
			damage *= 1.8
			area *= 1.3
		ItemTypes.Type.SANTA_JAVELIN:
			damage *= 1.6
			area *= 1.3
		ItemTypes.Type.GAZE_OF_GAEA:
			damage *= 1.5
			area *= 1.4
		ItemTypes.Type.MAGI_STONE:
			damage *= 1.6
			area *= 1.3
		ItemTypes.Type.PHAS3R:
			damage *= 1.5
			area *= 1.5
