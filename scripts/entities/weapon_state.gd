class_name WeaponState

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
	Player.UpgradeType.WHIP: {"cd": 1.0, "dmg": 75.0, "area": 60.0, "speed": 0.0},
	Player.UpgradeType.MAGIC_WAND: {"cd": 0.4, "dmg": 12.0, "area": 12.0, "speed": 400.0},
	Player.UpgradeType.GARLIC: {"cd": 0.3, "dmg": 6.0, "area": 70.0, "speed": 0.0},
	Player.UpgradeType.KNIFE: {"cd": 0.3, "dmg": 30.0, "area": 10.0, "speed": 600.0},
	Player.UpgradeType.AXE: {"cd": 1.2, "dmg": 100.0, "area": 40.0, "speed": 0.0},
	Player.UpgradeType.FIRE_WAND: {"cd": 0.8, "dmg": 50.0, "area": 20.0, "speed": 300.0},
	Player.UpgradeType.CROSS: {"cd": 1.2, "dmg": 30.0, "area": 40.0, "speed": 400.0},
	Player.UpgradeType.KING_BIBLE: {"cd": 2.0, "dmg": 15.0, "area": 50.0, "speed": 200.0},
	Player.UpgradeType.SANTA_WATER: {"cd": 2.5, "dmg": 20.0, "area": 60.0, "speed": 0.0},
	Player.UpgradeType.RUNETRACER: {"cd": 0.8, "dmg": 15.0, "area": 16.0, "speed": 500.0},
	Player.UpgradeType.LIGHTNING_RING: {"cd": 2.0, "dmg": 25.0, "area": 40.0, "speed": 0.0},
}

func _init(t: int):
	type = t; level = 1; max_level = ItemDefs.get_max_level(t)
	var b = _BASE[t]
	cooldown = b["cd"]; damage = b["dmg"]
	area = b["area"]; speed = b["speed"]
	cooldown_timer = 0.0

func upgrade():
	level += 1
	if level <= 8:
		cooldown = max(cooldown * 0.90, 0.1)
		damage *= 1.12
		if type == Player.UpgradeType.GARLIC:
			area = min(area * 1.05, 100.0)
		else:
			area *= 1.08
		speed *= 1.08
	else:
		cooldown = max(cooldown * 0.97, 0.05)
		damage *= 1.05
		if type == Player.UpgradeType.GARLIC:
			area = min(area * 1.02, 120.0)
		else:
			area *= 1.03
		speed *= 1.03

func evolve():
	evolved = true
	match type:
		Player.UpgradeType.WHIP:
			damage *= 2.0
			area *= 1.5
		Player.UpgradeType.MAGIC_WAND:
			cooldown = 0.02
			damage *= 1.5
		Player.UpgradeType.GARLIC:
			area *= 1.5
			damage *= 2.0
		Player.UpgradeType.KNIFE:
			damage *= 1.5
			speed *= 1.3
		Player.UpgradeType.AXE:
			damage *= 1.8
			area *= 1.4
