extends RefCounted
# Character definitions — static data for the character select system.
# Each entry: id, name, weapon (UpgradeType), bonus_type, bonus_value, desc
# Bonus types: "might", "growth", "movespeed", "area"

const CHARACTERS = [
	{
		"id": 0,
		"name": "Antonio",
		"weapon": 0,  # WHIP
		"bonus_type": "might",
		"bonus_value": 0.10,
		"desc": "Starts with Whip\n+10% Might",
		"color": Color(0.8, 0.6, 0.3),
		"cost": 0,  # free starter
	},
	{
		"id": 1,
		"name": "Imelda",
		"weapon": 1,  # MAGIC_WAND
		"bonus_type": "growth",
		"bonus_value": 0.10,
		"desc": "Starts with Magic Wand\n+10% Growth",
		"color": Color(0.3, 0.5, 1.0),
		"cost": 500,
	},
	{
		"id": 2,
		"name": "Pasqualina",
		"weapon": 10,  # KNIFE
		"bonus_type": "movespeed",
		"bonus_value": 0.10,
		"desc": "Starts with Knife\n+10% Move Speed",
		"color": Color(0.2, 0.8, 0.4),
		"cost": 1000,
	},
	{
		"id": 3,
		"name": "Gennaro",
		"weapon": 11,  # AXE
		"bonus_type": "area",
		"bonus_value": 0.10,
		"desc": "Starts with Axe\n+10% Area",
		"color": Color(0.9, 0.3, 0.3),
		"cost": 1500,
	},
]


static func get_character(id: int) -> Dictionary:
	for c in CHARACTERS:
		if c["id"] == id:
			return c
	return CHARACTERS[0]


static func get_weapon_name(t: int) -> String:
	return I18N.t(get_weapon_name_key(t))


static func get_weapon_name_key(t: int) -> String:
	match t:
		0: return "wpn.whip"
		1: return "wpn.wand"
		2: return "wpn.garlic"
		10: return "wpn.knife"
		11: return "wpn.axe"
		12: return "wpn.firewand"
	return "wpn.whip"
