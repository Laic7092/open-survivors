class_name WeaponState

const ItemDefs = preload("res://scripts/data/item_defs.gd")

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
	ItemDefs.Type.WHIP: {"cd": 1.0, "dmg": 50.0, "area": 60.0, "speed": 0.0},
	ItemDefs.Type.MAGIC_WAND: {"cd": 0.35, "dmg": 20.0, "area": 12.0, "speed": 400.0},
	ItemDefs.Type.GARLIC: {"cd": 0.8, "dmg": 10.0, "area": 70.0, "speed": 0.0},
	ItemDefs.Type.KNIFE: {"cd": 0.3, "dmg": 30.0, "area": 10.0, "speed": 600.0},
	ItemDefs.Type.AXE: {"cd": 1.2, "dmg": 100.0, "area": 40.0, "speed": 0.0},
	ItemDefs.Type.FIRE_WAND: {"cd": 0.8, "dmg": 50.0, "area": 20.0, "speed": 300.0},
	ItemDefs.Type.CROSS: {"cd": 1.2, "dmg": 60.0, "area": 40.0, "speed": 400.0},
	ItemDefs.Type.KING_BIBLE: {"cd": 2.0, "dmg": 15.0, "area": 50.0, "speed": 200.0},
	ItemDefs.Type.SANTA_WATER: {"cd": 2.0, "dmg": 20.0, "area": 60.0, "speed": 0.0},
	ItemDefs.Type.RUNETRACER: {"cd": 0.8, "dmg": 25.0, "area": 16.0, "speed": 500.0},
	ItemDefs.Type.LIGHTNING_RING: {"cd": 1.5, "dmg": 40.0, "area": 40.0, "speed": 0.0},
}

func _init(t: int):
	type = t; level = 1; max_level = ItemDefs.item_max_level(t)
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
		ItemDefs.Type.WHIP:
			damage *= 1.8
			area *= 1.4
		ItemDefs.Type.MAGIC_WAND:
			cooldown = 0.10
			damage *= 1.5
		ItemDefs.Type.GARLIC:
			area *= 1.3
			damage *= 1.8
			cooldown *= 0.7
		ItemDefs.Type.KNIFE:
			damage *= 1.5
			speed *= 1.3
		ItemDefs.Type.AXE:
			damage *= 1.8
			area *= 1.4
		ItemDefs.Type.FIRE_WAND:
			damage *= 1.5
			area *= 1.3
		ItemDefs.Type.CROSS:
			damage *= 1.6
			cooldown *= 0.7
		ItemDefs.Type.KING_BIBLE:
			damage *= 1.5
			area *= 1.3
		ItemDefs.Type.SANTA_WATER:
			damage *= 1.6
			area *= 1.3
		ItemDefs.Type.RUNETRACER:
			damage *= 1.5
			speed *= 1.4
		ItemDefs.Type.LIGHTNING_RING:
			damage *= 1.6
			area *= 1.3
