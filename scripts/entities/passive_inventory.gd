const ItemTypes = preload("res://scripts/data/item_types.gd")
var _passives: Dictionary = {}


func add_or_upgrade(t: int):
	var lv = _passives.get(t, 0) + 1
	_passives[t] = lv


func remove(t: int):
	_passives.erase(t)


func get_level(t: int) -> int:
	return _passives.get(t, 0)


func has(t: int) -> bool:
	return _passives.has(t)


func size() -> int:
	return _passives.size()


func get_all() -> Dictionary:
	return _passives.duplicate()


func recalculate(player):
	var old_max = player.max_health
	player.move_speed = 200.0
	player.damage_mult = 1.0
	player.cooldown_reduction = 0.0
	player.area_mult = 1.0
	player.growth_mult = 1.0
	player.recovery = 0.0
	player.projectile_bonus = 0
	player.greed_mult = 0.0
	player.magnet_level = 0
	player.luck = 0.0
	player.duration_bonus = 0.0
	player.speed_mult = 1.0
	player.curse = 0.0
	player.revivals = 0
	player.armor = 0.0
	player.pickup_range = 60.0
	player.max_health = player.base_max_health

	for t in _passives:
		var lv = _passives[t]
		match t:
			ItemTypes.Type.WINGS:
				player.move_speed = 200.0 * (1.0 + 0.1 * lv)
			ItemTypes.Type.SPINACH:
				player.damage_mult += 0.1 * lv
			ItemTypes.Type.TOME:
				player.cooldown_reduction = 0.08 * lv
			ItemTypes.Type.HOLLOW_HEART:
				player.max_health = player.base_max_health * (1.0 + 0.2 * lv)
			ItemTypes.Type.CANDELABRADOR:
				player.area_mult += 0.1 * lv
			ItemTypes.Type.CROWN:
				player.growth_mult = 1.0 + 0.08 * lv
			ItemTypes.Type.PUMMAROLA:
				player.recovery += 0.5 * lv
			ItemTypes.Type.DUPLICATOR:
				player.projectile_bonus = lv
			ItemTypes.Type.STONE_MASK:
				player.greed_mult = 0.20 * lv
			ItemTypes.Type.MAGNET:
				player.magnet_level = lv
				player.pickup_range = 60.0 + 20.0 * lv
			ItemTypes.Type.CLOVER:
				player.luck = 0.08 * lv
				player._crit_chance = player.luck * 0.5  # Lv5 = 20% crit
			ItemTypes.Type.SPELLBINDER:
				player.duration_bonus += 0.3 * lv
			ItemTypes.Type.ARMOR:
				player.armor = 0.08 * lv  # 8% damage reduction per level
			ItemTypes.Type.BRACER:
				player.speed_mult += 0.10 * lv
			ItemTypes.Type.SKULL:
				player.curse = 0.10 * lv
			ItemTypes.Type.TIRAGISU:
				player.revivals = lv
			ItemTypes.Type.TORRONA:
				player.damage_mult += 0.04 * lv
				player.area_mult += 0.04 * lv
				player.speed_mult += 0.04 * lv
				player.duration_bonus += 0.04 * lv
			ItemTypes.Type.SILVER_RING:
				player.duration_bonus += 0.05 * lv
				player.area_mult += 0.05 * lv
			ItemTypes.Type.GOLD_RING:
				player.curse += 0.05 * lv
			ItemTypes.Type.METAGLIO_LEFT:
				player.recovery += 0.1 * lv
				player.max_health += player.base_max_health * 0.05 * lv
			ItemTypes.Type.METAGLIO_RIGHT:
				player.curse += 0.05 * lv

	# Scale health proportionally with max HP changes
	if player.max_health != old_max and old_max > 0:
		player.health = player.health * (player.max_health / old_max)
	# Safety clamp: health must never exceed max_health
	player.health = min(player.health, player.max_health)
