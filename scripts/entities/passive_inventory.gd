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
	# 注意：recalculate 不重置 stat 到基线（已在 player.recalculate_stats 中完成）
	# 只做被动叠加
	var old_max = player.max_health
	player.max_health = player.base_max_health

	for t in _passives:
		var lv = _passives[t]
		match t:
			ItemTypes.Type.WINGS:
				player.move_speed = 200.0 * (1.0 + 0.1 * lv)
			ItemTypes.Type.SPINACH:
				player.might += 0.1 * lv
			ItemTypes.Type.TOME:
				# Wiki: Cooldown 100% base, -8%/lv → multiplier = 1.0 - 0.08*lv
				player.cooldown_mult -= 0.08 * lv
			ItemTypes.Type.HOLLOW_HEART:
				# Wiki: Max HP +40%/lv
				player.max_health = player.base_max_health * (1.0 + 0.4 * lv)
			ItemTypes.Type.CANDELABRADOR:
				# Wiki: Area +10%/lv
				player.area_mult += 0.1 * lv
			ItemTypes.Type.CROWN:
				# Wiki: Growth +8%/lv
				player.growth_mult = 1.0 + 0.08 * lv
			ItemTypes.Type.PUMMAROLA:
				# Wiki: Recovery +0.2 HP/s/lv
				player.recovery += 0.2 * lv
			ItemTypes.Type.DUPLICATOR:
				# Wiki: Amount +1/lv
				player.projectile_bonus = lv
			ItemTypes.Type.STONE_MASK:
				# Wiki: Greed +10%/lv
				player.greed_mult = 0.10 * lv
			ItemTypes.Type.MAGNET:
				player.magnet_level = lv
				player.pickup_range = 80.0 + 20.0 * lv
			ItemTypes.Type.CLOVER:
				# Wiki: Luck +10%/lv
				player.luck = 0.10 * lv
				player._crit_chance = player.luck * 0.5  # Lv5 = 25% crit
			ItemTypes.Type.SPELLBINDER:
				player.duration_mult += 0.10 * lv
			ItemTypes.Type.ARMOR:
				player.armor = lv  # 平坦减伤 -1/lv (最大-5)
			ItemTypes.Type.BRACER:
				player.speed_mult += 0.10 * lv
			ItemTypes.Type.SKULL:
				player.curse = 0.10 * lv
			ItemTypes.Type.TIRAGISU:
				player.revivals = lv
			ItemTypes.Type.TORRONA:
				player.might += 0.04 * lv
				player.area_mult += 0.04 * lv
				player.speed_mult += 0.04 * lv
				player.duration_mult += 0.04 * lv
			ItemTypes.Type.SILVER_RING:
				player.duration_mult += 0.05 * lv
				player.area_mult += 0.05 * lv
			ItemTypes.Type.GOLD_RING:
				player.curse += 0.05 * lv
			ItemTypes.Type.METAGLIO_LEFT:
				player.recovery += 0.1 * lv
				player.max_health += player.base_max_health * 0.05 * lv
			ItemTypes.Type.METAGLIO_RIGHT:
				player.curse += 0.05 * lv
			ItemTypes.Type.PARM_AEGIS:
				player.invincible_duration = 0.3 + 0.05 * lv
			ItemTypes.Type.KAROMAS_MANA:
				player.charm = lv * 10
				player.gold_fever_duration_bonus = 0.10 * lv

	# Scale health proportionally with max HP changes
	if player.max_health != old_max and old_max > 0:
		player.health = player.health * (player.max_health / old_max)
	# Safety clamp: health must never exceed max_health
	player.health = min(player.health, player.max_health)
