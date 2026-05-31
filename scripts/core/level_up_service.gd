extends RefCounted
# LevelUpService — 等级提升核心逻辑（纯数据，无节点依赖）
# 集中管理：XP 需求公式、升级选项生成、稀有度权重、Skip/Reroll/Banish
# 对齐 Vampire Survivors Wiki: https://vampire.survivors.wiki/w/Level_up

const ItemTypes = preload("res://scripts/data/item_types.gd")
const _WeaponManager = preload("res://scripts/entities/weapon_manager.gd")

# ── Choice 类型 ──
enum ChoiceType {
	ITEM,        # 普通武器/被动升级
	EVOLUTION,   # 进化
	LIMIT_BREAK, # 限界突破
	GOLD,        # 金币
	CHICKEN,     # Floor Chicken 回血
	REROLL,      # 重掷（PowerUp）
	SKIP,        # 跳过（PowerUp）
	BANISH,      # 禁止（PowerUp）
}

class Choice:
	var type: int = ChoiceType.ITEM
	var item_type: int = -1          # 对于 ITEM/EVOLUTION/LIMIT_BREAK
	var limit_break_option: Dictionary = {}
	var gold_amount: int = 0
	var chicken_amount: int = 0
	var label: String = ""
	var description: String = ""
	var color: Color = Color.WHITE
	var level_before: int = 0        # 当前等级
	var level_after: int = 1         # 升级后等级
	var is_new: bool = false         # 是否为新物品
	var is_evolved: bool = false
	var is_limit_break: bool = false

	func _to_string() -> String:
		return "Choice(%s, type=%d, item=%d)" % [label, type, item_type]


# ═══════════════════════════════════════════════════════════════════
#  1. XP 需求公式（对齐 VS Wiki）
# ═══════════════════════════════════════════════════════════════════
# 分段线性增长：
#   Level 1→20: 每级 +10 XP
#   Level 21→40: 每级 +13 XP
#   Level 41+: 每级 +16 XP
#   额外门槛：Level 20→21 加 600，Level 40→41 加 2400
# 参考数据点：
#   Lv1→2: 5, Lv10→11: 405, Lv20→21: 2600, Lv40→41: 12800, Lv60→61: 27848

static func xp_for_level(level: int) -> int:
	## 返回从 level 升到 level+1 所需 XP
	if level < 1:
		return 0
	var current_req = 5  # Level 1→2
	var increment: int
	var lv = level
	if lv < 20:
		increment = 10
	elif lv < 40:
		increment = 13
	else:
		increment = 16
	# 累加 (level-1) 次增量到 current_req
	for _i in range(1, lv):
		if _i < 20:
			current_req += 10
		elif _i < 40:
			current_req += 13
		else:
			current_req += 16
	# 额外门槛
	if lv == 20:
		current_req += 600
	elif lv == 40:
		current_req += 2400
	return current_req


# 累计 XP 到指定等级（用于 UI 显示）
static func cumulative_xp(level: int) -> int:
	if level <= 1:
		return 0
	var total = 0
	for lv in range(1, level):
		total += xp_for_level(lv)
	return total


# ═══════════════════════════════════════════════════════════════════
#  2. Growth 有效性计算（带衰减，防止指数膨胀）
# ═══════════════════════════════════════════════════════════════════

static func effective_growth(growth_mult: float, level: int) -> float:
	# growth_mult > 1.3 时超额部分 50% 衰减
	var g = growth_mult
	if g > 1.3:
		g = 1.3 + (g - 1.3) * 0.5
	# 20/40 级时获得 +100% Growth 直到升级
	if level in [20, 40]:
		g *= 2.0
	return g


# ═══════════════════════════════════════════════════════════════════
#  3. 稀有度权重选择
# ═══════════════════════════════════════════════════════════════════
# 每个物品在 item_defs.gd WIKI_DATA 中有 rarity 值
# P(item) = itemRarity / totalPoolWeight

static func select_weighted(items: Array, rarity_map: Dictionary, count: int) -> Array:
	# items: int[] 物品类型
	# rarity_map: {type: rarity_value}
	# 不放回加权抽取 count 个
	if items.is_empty() or count <= 0:
		return []

	var result = []
	var available = items.duplicate()
	var weights = []  # 与 available 对齐

	# 初始化权重
	for t in available:
		weights.append(float(rarity_map.get(t, 50)))

	while result.size() < count and not available.is_empty():
		var total_weight = 0.0
		for w in weights:
			total_weight += w
		if total_weight <= 0:
			break

		var roll = randf() * total_weight
		var cumulative = 0.0
		var picked_idx = -1

		for i in range(available.size()):
			cumulative += weights[i]
			if roll <= cumulative:
				picked_idx = i
				break

		if picked_idx < 0:
			break

		result.append(available[picked_idx])
		available.remove_at(picked_idx)
		weights.remove_at(picked_idx)

	return result


# ═══════════════════════════════════════════════════════════════════
#  4. 拥有物品优先概率（基于 Luck）
# ═══════════════════════════════════════════════════════════════════
# ownedChance = 1 + 0.3^(x-1) / totalLuck
# x = 2 if level is even, x = 1 if level is odd

static func owned_item_chance(luck: float, level: int) -> float:
	# Wiki: totalLuck 以 100% 为基线 (1.0)，luck 是加成（0.1 = +10%）
	var total_luck = max(1.0 + luck, 0.01)
	var x = 2 if level % 2 == 0 else 1
	return 1.0 + pow(0.3, x - 1) / total_luck


# ═══════════════════════════════════════════════════════════════════
#  5. 第四选项概率
# ═══════════════════════════════════════════════════════════════════
# chanceFourth = 1 - (1 / totalLuck)

static func fourth_option_chance(luck: float) -> float:
	# Wiki: chanceFourth = 1 - (1 / totalLuck), totalLuck 基线 100%
	var total_luck = max(1.0 + luck, 0.01)
	return 1.0 - (1.0 / total_luck)


# ═══════════════════════════════════════════════════════════════════
#  6. 核心：生成升级选项
# ═══════════════════════════════════════════════════════════════════

static func generate_choices(
	player,
	weapon_manager,
	passive_inventory,
	luck: float,
	has_great_gospel: bool,
	is_random_level_up: bool,
	always_chicken_unlocked: bool,
	current_level: int,  # player.level
) -> Array:
	## 返回 3~4 个 Choice（基于 Luck 决定 4th）
	## 如果 is_random_level_up，自动选择并返回单一 Choice

	var choices: Array[Choice] = []

	# ── Step 1: 收集进化候选 ──
	var evolution_candidates: Array[int] = []
	for w in weapon_manager.weapons:
		var recipe = _WeaponManager.EVOLUTION_RECIPES.get(w.type)
		if not recipe:
			continue
		if w.level >= w.max_level and not w.evolved:
			# 检查是否需要另一个武器
			var need_weapon = recipe.get("need_weapon", -1)
			if need_weapon >= 0:
				var need_w = weapon_manager.find_weapon(need_weapon)
				var need_lv = recipe.get("need_weapon_level", 7)
				if not need_w or need_w.level < need_lv or need_w.evolved:
					continue
			# 检查被动需求
			var passive_type = recipe["passive"]
			var passive_lv = passive_inventory.get_level(passive_type)
			var other_w = weapon_manager.find_weapon(passive_type)
			var has_reagent = (passive_lv > 0 and passive_lv >= recipe["passive_level"]) or \
				(other_w != null and other_w.level >= recipe["passive_level"])
			if has_reagent:
				evolution_candidates.append(w.type)

	# ── Step 2: 收集可升级物品（已有物品优先池 + 新物品池） ──
	var owned_upgradable: Array[int] = []  # 已有且可升级
	var new_possible: Array[int] = []      # 可获得的新物品

	var all_items = DataRegistry.items().DATA.keys()
	var max_weapons = 6
	var max_passives = 6
	var current_weapons = weapon_manager.weapons.size()
	var current_passives = passive_inventory.size()

	for t in all_items:
		if not UnlockManager.is_item_unlocked(t):
			continue
		# 跳过已在进化候选中的武器（进化自己独占一个槽位）
		if DataRegistry.items().is_weapon(t) and evolution_candidates.has(t):
			# 但如果没有被进化占用（比如同时可普通升级），允许
			var w = weapon_manager.find_weapon(t)
			if w and w.level < w.max_level and not w.evolved:
				owned_upgradable.append(t)
			continue

		var lv = 0
		var max_lv = 0
		var is_weapon = DataRegistry.items().is_weapon(t)
		if is_weapon:
			lv = weapon_manager.get_level(t)
			max_lv = weapon_manager.get_max_level(t)
		else:
			lv = passive_inventory.get_level(t)
			max_lv = DataRegistry.items().item_max_level(t)

		if lv > 0 and lv < max_lv:
			owned_upgradable.append(t)
		elif lv == 0:
			if is_weapon and current_weapons >= max_weapons:
				continue
			if not is_weapon and current_passives >= max_passives:
				continue
			new_possible.append(t)

	# ── Step 3: 构建候选池 ──
	var target_count = 3
	if fourth_option_chance(luck) > randf():
		target_count = 4

	var rarity_map = {}
	for t in all_items:
		rarity_map[t] = DataRegistry.items().wiki_rarity(t)

	choices.clear()

	# --- 3a: 进化优先（直接加入，不占权重池） ---
	for ev in evolution_candidates:
		if choices.size() >= target_count:
			break
		var c = Choice.new()
		c.type = ChoiceType.EVOLUTION
		c.item_type = ev
		c.is_evolved = true
		c.label = DataRegistry.items().item_name(ev)
		c.color = DataRegistry.items().item_color(ev)
		c.level_before = weapon_manager.get_level(ev)
		c.level_after = c.level_before  # 进化不改变数字等级
		choices.append(c)

	# --- 3b: 拥有物品优先检查（基于 Luck） ---
	var owned_slots_needed = target_count - choices.size()
	if owned_slots_needed > 0 and not owned_upgradable.is_empty():
		var owned_check_count = 0
		# 做两次独立检查
		for _attempt in range(2):
			if choices.size() >= target_count:
				break
			if owned_upgradable.is_empty():
				break
			var chance = owned_item_chance(luck, current_level)
			if randf() < chance:
				# 从 owned_upgradable 中随机选一个（不加权）
				var picked = owned_upgradable[randi() % owned_upgradable.size()]
				# 避免重复
				var already = false
				for c in choices:
					if c.item_type == picked:
						already = true
						break
				if already:
					# 二次检查抽出重复 → 从全池抽新物品
					if not new_possible.is_empty():
						var fallback = select_weighted(new_possible, rarity_map, 1)
						if not fallback.is_empty():
							var fb_type = fallback[0]
							var c = Choice.new()
							c.type = ChoiceType.ITEM
							c.item_type = fb_type
							c.is_new = true
							c.level_before = 0
							c.level_after = 1
							c.label = DataRegistry.items().item_name(fb_type)
							c.description = DataRegistry.items().item_desc(fb_type)
							c.color = DataRegistry.items().item_color(fb_type)
							# 从 new_possible 移除
							new_possible.erase(fb_type)
							choices.append(c)
				else:
					var c = Choice.new()
					c.type = ChoiceType.ITEM
					c.item_type = picked
					c.is_new = false
					var lv = weapon_manager.get_level(picked) if DataRegistry.items().is_weapon(picked) else passive_inventory.get_level(picked)
					c.level_before = lv
					c.level_after = lv + 1
					c.label = DataRegistry.items().item_name(picked)
					c.description = DataRegistry.items().item_desc(picked)
					c.color = DataRegistry.items().item_color(picked)
					owned_upgradable.erase(picked)
					choices.append(c)

	# --- 3c: 从权重池填充剩余 ---
	var remaining_needed = target_count - choices.size()
	if remaining_needed > 0:
		# 合并可用的候选：owned_upgradable + new_possible
		var pool = []
		for t in owned_upgradable:
			# 排除已在 choices 中的
			var skip = false
			for c in choices:
				if c.item_type == t:
					skip = true
					break
			if not skip:
				pool.append(t)
		for t in new_possible:
			var skip = false
			for c in choices:
				if c.item_type == t:
					skip = true
					break
			if not skip:
				pool.append(t)

		var picked_items = select_weighted(pool, rarity_map, remaining_needed)
		for t in picked_items:
			var c = Choice.new()
			c.type = ChoiceType.ITEM
			c.item_type = t
			var lv = 0
			var is_weapon = DataRegistry.items().is_weapon(t)
			if is_weapon:
				lv = weapon_manager.get_level(t)
			else:
				lv = passive_inventory.get_level(t)
			c.is_new = (lv == 0)
			c.level_before = lv
			c.level_after = lv + 1
			c.label = DataRegistry.items().item_name(t)
			c.description = DataRegistry.items().item_desc(t)
			c.color = DataRegistry.items().item_color(t)
			choices.append(c)

	# ── Step 4: 降级处理（无可用物品时） ──
	if choices.is_empty():
		# 4a: Limit Break（有 Great Gospel）
		if has_great_gospel:
			for w in weapon_manager.weapons:
				if choices.size() >= target_count:
					break
				if w.can_limit_break():
					var lb_options = w.get_limit_break_options()
					if lb_options.is_empty():
						continue
					var opt = lb_options[0]  # 展示第一个
					var c = Choice.new()
					c.type = ChoiceType.LIMIT_BREAK
					c.item_type = w.type
					c.is_limit_break = true
					c.limit_break_option = opt
					c.label = DataRegistry.items().item_name(w.type)
					c.color = DataRegistry.items().item_color(w.type)
					choices.append(c)
				else:
					# 还未满级或没有 Great Gospel
					pass

		# 4b: 金币 / 鸡肉
		if choices.is_empty():
			var gold_amt = 50 + current_level * 30
			# "Always Floor Chicken" 模式
			if always_chicken_unlocked:
				if player and player.health < player.max_health:
					var c = Choice.new()
					c.type = ChoiceType.CHICKEN
					c.chicken_amount = 30  # 回血量
					c.label = "Floor Chicken"
					c.color = Color(0.3, 1.0, 0.3)
					choices.append(c)
				else:
					var c = Choice.new()
					c.type = ChoiceType.GOLD
					c.gold_amount = gold_amt
					c.label = "+%d Gold" % gold_amt
					c.color = Color(0.9, 0.8, 0.1)
					choices.append(c)
			else:
				# 混合选项：金币 + 鸡肉
				var c1 = Choice.new()
				c1.type = ChoiceType.GOLD
				c1.gold_amount = gold_amt
				c1.label = "+%d Gold" % gold_amt
				c1.color = Color(0.9, 0.8, 0.1)
				choices.append(c1)
				if choices.size() < target_count:
					var c2 = Choice.new()
					c2.type = ChoiceType.CHICKEN
					c2.chicken_amount = 30
					c2.label = "Floor Chicken"
					c2.color = Color(0.3, 1.0, 0.3)
					choices.append(c2)

	# ── Step 5: 如果还是不够，用金币填充 ──
	while choices.size() < 3:
		var gold_amt = 50 + current_level * 30
		var c = Choice.new()
		c.type = ChoiceType.GOLD
		c.gold_amount = gold_amt
		c.label = "+%d Gold" % gold_amt
		c.color = Color(0.9, 0.8, 0.1)
		choices.append(c)

	# ── Random LevelUp: 自动选择 ---
	if is_random_level_up and not choices.is_empty():
		var picked = choices[randi() % choices.size()]
		return [picked]

	return choices


# ═══════════════════════════════════════════════════════════════════
#  7. 应用升级
# ═══════════════════════════════════════════════════════════════════

static func apply_choice(player, choice: Choice, weapon_manager, passive_inventory) -> bool:
	match choice.type:
		ChoiceType.ITEM:
			player.apply_upgrade(choice.item_type)
			return true
		ChoiceType.EVOLUTION:
			player.evolve_weapon(choice.item_type)
			return true
		ChoiceType.LIMIT_BREAK:
			var ok = weapon_manager.apply_limit_break(choice.item_type, choice.limit_break_option)
			return ok
		ChoiceType.GOLD:
			if PowerUpManager:
				PowerUpManager.add_run_gold(choice.gold_amount)
			return true
		ChoiceType.CHICKEN:
			if player:
				player.heal(choice.chicken_amount)
			return true
	return false
