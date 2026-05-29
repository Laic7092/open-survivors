extends RefCounted
# Character definitions — expanded for multiple stat bonuses.
# Each entry: id, name, weapon (UpgradeType), stats dict, desc, color, cost
# Stats keys match PowerUpManager.get_stat_bonuses() output.

const CHARACTERS = [
	# ── Starter ──
	{
		"id": 0,
		"name": "Antonio",
		"weapon": 0,  # WHIP
		"stats": {"damage_mult": 0.10},
		"desc": "Starts with Whip\n+10% Might",
		"color": Color(0.8, 0.6, 0.3),
		"cost": 0,
	},
	# ── Purchasable ──
	{
		"id": 1,
		"name": "Imelda",
		"weapon": 1,  # MAGIC_WAND
		"stats": {"growth_pct": 0.10},
		"desc": "Starts with Magic Wand\n+10% Growth",
		"color": Color(0.3, 0.5, 1.0),
		"cost": 500,
	},
	{
		"id": 2,
		"name": "Pasqualina",
		"weapon": 10,  # KNIFE
		"stats": {"move_speed_pct": 0.10},
		"desc": "Starts with Knife\n+10% Move Speed",
		"color": Color(0.2, 0.8, 0.4),
		"cost": 1000,
	},
	{
		"id": 3,
		"name": "Gennaro",
		"weapon": 11,  # AXE
		"stats": {"area_mult": 0.10},
		"desc": "Starts with Axe\n+10% Area",
		"color": Color(0.9, 0.3, 0.3),
		"cost": 1500,
	},
	{
		"id": 4,
		"name": "Arca",
		"weapon": 12,  # FIRE_WAND
		"stats": {"cooldown_reduction": 0.10},
		"desc": "Starts with Fire Wand\n-10% Cooldown",
		"color": Color(0.9, 0.4, 0.1),
		"cost": 2000,
	},
	{
		"id": 5,
		"name": "Porta",
		"weapon": 20,  # LIGHTNING_RING
		"stats": {"cooldown_reduction": 0.15},
		"desc": "Starts with Lightning Ring\n-15% Cooldown",
		"color": Color(0.9, 0.9, 0.2),
		"cost": 3000,
	},
	{
		"id": 6,
		"name": "Lama",
		"weapon": 11,  # AXE (shared weapon, different bonus)
		"stats": {"damage_mult": 0.20, "armor": 1},
		"desc": "Starts with Axe\n+20% Might, +1 Armor",
		"color": Color(0.6, 0.3, 0.1),
		"cost": 4000,
	},
	{
		"id": 7,
		"name": "Poe",
		"weapon": 2,  # GARLIC
		"stats": {"max_hp_pct": 0.30},
		"desc": "Starts with Garlic\n+30% Max HP",
		"color": Color(0.6, 0.2, 0.8),
		"cost": 5000,
	},
	{
		"id": 8,
		"name": "Clerici",
		"weapon": 18,  # SANTA_WATER
		"stats": {"recovery": 0.5},
		"desc": "Starts with Santa Water\n+0.5 HP/s Regen",
		"color": Color(0.1, 0.5, 0.8),
		"cost": 6000,
	},
	{
		"id": 9,
		"name": "Dommario",
		"weapon": 17,  # KING_BIBLE
		"stats": {"greed_pct": 0.10, "growth_pct": 0.10},
		"desc": "Starts with King Bible\n+10% Greed, +10% Growth",
		"color": Color(0.2, 0.6, 0.9),
		"cost": 8000,
	},
	{
		"id": 10,
		"name": "Krochi",
		"weapon": 16,  # CROSS
		"stats": {"move_speed_pct": 0.10, "max_hp_pct": 0.10},
		"desc": "Starts with Cross\n+10% Move Speed, +10% HP",
		"color": Color(0.9, 0.6, 0.2),
		"cost": 10000,
	},
	{
		"id": 11,
		"name": "Christine",
		"weapon": 1,  # MAGIC_WAND
		"stats": {"cooldown_reduction": 0.20, "area_mult": 0.10},
		"desc": "Starts with Magic Wand\n-20% CD, +10% Area",
		"color": Color(0.3, 0.5, 1.0),
		"cost": 12000,
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
