extends Node
# SpawnManager — 统一生成管理
# 从 main.gd 拆分：所有敌人/拾取物/遗物/Boss 生成 + 敌人死亡掉落
# main.gd 持有引用并驱动
const CollisionLayers = preload("res://scripts/data/collision_layers.gd")

# Enemy data loaded lazily via DataRegistry
# Relic data loaded lazily via DataRegistry
# Item data loaded lazily via DataRegistry

signal enemy_spawned(enemy: Node2D)
signal boss_spawned(boss_type: int)
signal arcana_boss_defeated

var player: Node2D
var game_state: Node  # GameState
var camera_ctrl: Node  # CameraController
var main_node: Node2D  # 父节点（main.gd）

var _overflow_xp: int = 0
const MAX_GEMS: int = 500

var _enemy_scene = preload("res://scenes/enemy.tscn")
var _pickup_scene = preload("res://scenes/pickup.tscn")
var _relic_scene = preload("res://scenes/relic_pickup.tscn")

# 死亡敌人池：原地禁用后回收复用，避免 remove_child/add_child 场景树开销
var _dead_enemies: Array[Node2D] = []

# 遗物跟踪
var stage_relics: Array = []
var has_relic_arrow: bool = false
var relic_arrow_target: Vector2 = Vector2.ZERO

# 延时刷出的遗物队列
var _queued_time_relics: Array = []

# 掉落圣物队列 (boss_drop) — 当 BOSS 死亡时刷出
var _queued_boss_relics: Array = []

# 条件圣物队列 (conditional) — 满足条件时刷出
var _queued_conditional_relics: Array = []

# 商人圣物 (merchant) — 在商人处出售
var _queued_merchant_relics: Array = []

# 探索圣物 (collection) — 隐藏于关卡中
var _queued_collection_relics: Array = []


func setup(p: Node2D, gs: Node, cam: Node, parent: Node2D):
	player = p
	game_state = gs
	camera_ctrl = cam
	main_node = parent


# ── 敌人生成 ──

func spawn_enemy(type_id: int = 0) -> Node2D:
	var enemy: Node2D
	if _dead_enemies.size() > 0:
		# 从死亡池回收，原地复活
		enemy = _dead_enemies.pop_back()
		_revive_enemy(enemy, type_id)
	else:
		enemy = _enemy_scene.instantiate()
		enemy.player = player
		enemy.game_state = game_state
		var curse_mod = 1.0 + (player.get_curse() if is_instance_valid(player) else 0.0)
		var bounds = camera_ctrl.get_camera_bounds()
		var margin = 60.0
		var pos: Vector2
		match randi() % 4:
			0: pos = Vector2(randf_range(bounds.left + margin, bounds.right - margin), bounds.top - margin)
			1: pos = Vector2(randf_range(bounds.left + margin, bounds.right - margin), bounds.bottom + margin)
			2: pos = Vector2(bounds.left - margin, randf_range(bounds.top + margin, bounds.bottom - margin))
			3: pos = Vector2(bounds.right + margin, randf_range(bounds.top + margin, bounds.bottom - margin))
		enemy.global_position = _clamp_to_map(pos, 10.0)
		var wave_bonus = 1.0 + game_state.wave_number * 0.08
		enemy.set_enemy_type(type_id, game_state.difficulty * curse_mod * wave_bonus)
		main_node.add_child(enemy)
	enemy_spawned.emit(enemy)
	return enemy


# 复活一个死亡池中的敌人
func _revive_enemy(enemy: Node2D, type_id: int):
	# 清理旧信号
	for c in enemy.died.get_connections():
		enemy.died.disconnect(c.callable)

	enemy.player = player
	enemy.game_state = game_state
	enemy.visible = true
	enemy.modulate = Color(1, 1, 1, 1)
	enemy.scale = Vector2(1, 1)
	enemy.collision_layer = CollisionLayers.ENEMY
	enemy.collision_mask = 0
	enemy.set_physics_process(true)
	enemy.set_process(true)
	enemy.add_to_group("enemies")

	var curse_mod = 1.0 + (player.get_curse() if is_instance_valid(player) else 0.0)
	var bounds = camera_ctrl.get_camera_bounds()
	var margin = 60.0
	var pos: Vector2
	match randi() % 4:
		0: pos = Vector2(randf_range(bounds.left + margin, bounds.right - margin), bounds.top - margin)
		1: pos = Vector2(randf_range(bounds.left + margin, bounds.right - margin), bounds.bottom + margin)
		2: pos = Vector2(bounds.left - margin, randf_range(bounds.top + margin, bounds.bottom - margin))
		3: pos = Vector2(bounds.right + margin, randf_range(bounds.top + margin, bounds.bottom - margin))
	enemy.global_position = _clamp_to_map(pos, 10.0)
	var wave_bonus = 1.0 + game_state.wave_number * 0.08
	enemy.set_enemy_type(type_id, game_state.difficulty * curse_mod * wave_bonus)
	EnemyRegistry.register(enemy)


# 回收死亡敌人：原地禁用，不复位父节点，不经过 OPM
func recycle_enemy(enemy: Node2D):
	if not is_instance_valid(enemy):
		return
	enemy.visible = false
	enemy.set_process(false)
	enemy.set_physics_process(false)
	enemy.collision_layer = 0
	enemy.collision_mask = 0
	enemy.remove_from_group("enemies")
	# 保留在 main_node 中，只禁用
	_dead_enemies.append(enemy)


func spawn_boss():
	if game_state.boss_spawned:
		return
	game_state.boss_spawned = true
	game_state.boss_spawned_event.emit()

	var boss_type = DataRegistry.enemies().get_boss_type(game_state._stage_id, game_state.game_time)
	if boss_type < 0:
		return

	var enemy: Node2D
	if _dead_enemies.size() > 0:
		enemy = _dead_enemies.pop_back()
		_revive_enemy(enemy, boss_type)
	else:
		enemy = _enemy_scene.instantiate()
		enemy.player = player
		enemy.game_state = game_state
		var curse_mod = 1.0 + (player.get_curse() if is_instance_valid(player) else 0.0)
		enemy.set_enemy_type(boss_type, game_state.difficulty * curse_mod)
		enemy.set_as_boss()

		var bounds = camera_ctrl.get_camera_bounds()
		var margin = 80.0
		var pos: Vector2
		match randi() % 4:
			0: pos = Vector2(0, bounds.top - margin)
			1: pos = Vector2(0, bounds.bottom + margin)
			2: pos = Vector2(bounds.left - margin, 0)
			3: pos = Vector2(bounds.right + margin, 0)
		enemy.global_position = _clamp_to_map(pos, 20.0)
		main_node.add_child(enemy)
	boss_spawned.emit(boss_type)
	enemy_spawned.emit(enemy)


func spawn_arcana_boss():
	if ArcanaManager.get_active_count() >= 3:
		return
	var boss_type = DataRegistry.enemies().get_boss_type(game_state._stage_id, game_state.game_time)
	if boss_type < 0:
		boss_type = 0

	var enemy: Node2D
	if _dead_enemies.size() > 0:
		enemy = _dead_enemies.pop_back()
		_revive_enemy(enemy, boss_type)
		enemy.set_as_boss()
		enemy.set_meta("arcana_boss", true)
	else:
		enemy = _enemy_scene.instantiate()
		enemy.player = player
		enemy.game_state = game_state
		var curse_mod = 1.0 + (player.get_curse() if is_instance_valid(player) else 0.0)
		enemy.set_enemy_type(boss_type, game_state.difficulty * curse_mod * 1.5)
		enemy.set_as_boss()
		enemy.set_meta("arcana_boss", true)

		var bounds = camera_ctrl.get_camera_bounds()
		var margin = 80.0
		var pos: Vector2
		match randi() % 4:
			0: pos = Vector2(0, bounds.top - margin)
			1: pos = Vector2(0, bounds.bottom + margin)
			2: pos = Vector2(bounds.left - margin, 0)
			3: pos = Vector2(bounds.right + margin, 0)
		enemy.global_position = _clamp_to_map(pos, 20.0)
		main_node.add_child(enemy)
	enemy_spawned.emit(enemy)


# ── 拾取物生成 ──

func spawn_pickup_at(pos: Vector2, pickup_type: int = -1):
	var pickup = _pickup_scene.instantiate()
	pickup.player = player
	if pickup_type >= 0:
		pickup.type = pickup_type
	else:
		var r = randf()
		if r < 0.35:
			pickup.type = 0   # CHICKEN
		elif r < 0.65:
			pickup.type = 2   # COIN_BAG
		elif r < 0.85:
			pickup.type = 1   # GOLD_COIN
		elif r < 0.90:
			pickup.type = 3   # RICH_COIN_BAG
		elif r < 0.95:
			pickup.type = 4   # ROSARY
		else:
			pickup.type = 6   # VACUUM
	pickup.global_position = _clamp_to_map(pos, 20.0)
	main_node.call_deferred("add_child", pickup)


func spawn_initial_pickups(hw: float, hh: float):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var clear_radius = 200.0
	var count = rng.randi_range(3, 6)
	for i in range(count):
		var x = rng.randf_range(-hw * 0.7, hw * 0.7)
		var y = rng.randf_range(-hh * 0.7, hh * 0.7)
		var pos = Vector2(x, y)
		if pos.length() < clear_radius:
			continue
		var pt = rng.randi_range(0, 2)
		if pt == 1:
			pt = 2
		var roll = rng.randf()
		if roll < 0.01:
			pt = 7
		elif roll < 0.02:
			pt = 4
		spawn_pickup_at(pos, pt)


func spawn_enemy_drops(enemy: Node2D):
	if not is_instance_valid(enemy):
		return

	var is_arcana_boss = enemy.has_meta("arcana_boss") and enemy.get_meta("arcana_boss")
	if is_arcana_boss:
		for i in range(5):
			var gem = ObjectPoolManager.borrow_gem()
			gem.value = max(enemy.xp_value / 3, 5)
			gem.player = player
			gem.global_position = enemy.global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
			main_node.call_deferred("add_child", gem)
		for i in range(2):
			spawn_pickup_at(enemy.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20)), 2)
		arcana_boss_defeated.emit()
		return

	var is_boss = enemy.has_method("get_is_boss") and enemy.get_is_boss()
	if is_boss:
		for i in range(3):
			var gem = ObjectPoolManager.borrow_gem()
			gem.value = max(enemy.xp_value / 3, 5)
			gem.player = player
			gem.global_position = enemy.global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
			main_node.call_deferred("add_child", gem)
		spawn_pickup_at(enemy.global_position, 0)
		_try_spawn_boss_drop_relic(enemy.global_position)
	else:
		# XP 宝石掉落：固定值（对齐 VS Wiki），不随难度缩放
		var base_xp = _get_enemy_base_xp(enemy)
		if base_xp <= 0:
			base_xp = 1
		if randf() < 0.60:
			_try_spawn_gem(base_xp, enemy.global_position)
		if randf() < 0.001:
			var pt = 4 + randi() % 3
			spawn_pickup_at(enemy.global_position, pt)


func _try_spawn_gem(value: int, pos: Vector2):
	var gem_count = main_node.get_tree().get_nodes_in_group("gems").size()
	if gem_count >= MAX_GEMS:
		_overflow_xp += value
		if _overflow_xp >= 100:
			_overflow_xp -= 100
			_spawn_single_gem(100, pos)
		return
	_spawn_single_gem(value, pos)
	if _overflow_xp >= 50 and gem_count < MAX_GEMS - 1:
		var n = mini(_overflow_xp / 50, 5)
		for i in range(n):
			_overflow_xp -= 50
			_spawn_single_gem(50, pos + Vector2(randf_range(-20, 20), randf_range(-20, 20)))


func _spawn_single_gem(value: int, pos: Vector2):
	var gem = ObjectPoolManager.borrow_gem()
	gem.player = player
	gem.global_position = pos
	gem.value = value
	if value <= 2:
		gem.tier = gem.Tier.BLUE
	elif value <= 9:
		gem.tier = gem.Tier.GREEN
	else:
		gem.tier = gem.Tier.RED
	main_node.call_deferred("add_child", gem)


# ── 遗物 ──

func spawn_stage_relics():
	stage_relics.clear()
	_queued_time_relics.clear()
	_queued_boss_relics.clear()
	_queued_conditional_relics.clear()
	_queued_merchant_relics.clear()
	_queued_collection_relics.clear()
	has_relic_arrow = false
	relic_arrow_target = Vector2.ZERO

	var stage_id = game_state._stage_id
	var imm_relics = DataRegistry.relics().get_relics_for_stage_by_type(stage_id, "immediate")
	for r in imm_relics:
		_place_relic(r)

	_register_relics_by_type(stage_id, "time_based", _queued_time_relics)
	_register_relics_by_type(stage_id, "boss_drop", _queued_boss_relics)
	_register_relics_by_type(stage_id, "conditional", _queued_conditional_relics)
	_register_relics_by_type(stage_id, "merchant", _queued_merchant_relics)
	_register_relics_by_type(stage_id, "collection", _queued_collection_relics)


func _register_relics_by_type(stage_id: int, spawn_type: String, queue: Array):
	var relics = DataRegistry.relics().get_relics_for_stage_by_type(stage_id, spawn_type)
	for r in relics:
		if RelicManager.has_relic(r["id"]):
			continue
		queue.append({"def": r})


func process_delayed_spawns(game_time: float):
	if _queued_time_relics.is_empty():
		return
	var i = 0
	while i < _queued_time_relics.size():
		var entry = _queued_time_relics[i]
		var r = entry["def"]
		var spawn_time = r.get("spawn_time", 0.0)
		if game_time >= spawn_time:
			if not RelicManager.has_relic(r["id"]):
				_place_relic(r)
			_queued_time_relics.remove_at(i)
		else:
			i += 1


func _try_spawn_boss_drop_relic(boss_pos: Vector2):
	if _queued_boss_relics.is_empty():
		return
	var entry = _queued_boss_relics[0]
	var r = entry["def"]
	if not RelicManager.has_relic(r["id"]):
		r["spawn_pos"] = boss_pos
		_place_relic(r)
	_queued_boss_relics.remove_at(0)


func process_conditional_relics():
	if _queued_conditional_relics.is_empty():
		return
	var i = 0
	while i < _queued_conditional_relics.size():
		var entry = _queued_conditional_relics[i]
		var r = entry["def"]
		if _evaluate_condition(r.get("condition", {})):
			if not RelicManager.has_relic(r["id"]):
				_place_relic(r)
			_queued_conditional_relics.remove_at(i)
		else:
			i += 1


func _evaluate_condition(cond: Dictionary) -> bool:
	var ctype = cond.get("type", "")
	var val = cond.get("value", 0)
	match ctype:
		"player_level":
			return is_instance_valid(player) and player.level >= val
		"total_kills":
			return game_state and game_state.total_kills >= val
		"wave_number":
			return game_state and game_state.wave_number >= val
		"weapon_evolved":
			var wpn_type = cond.get("weapon_type", -1)
			if wpn_type >= 0 and is_instance_valid(player) and player.weapon_manager:
				return player.weapon_manager.is_evolved(wpn_type)
			return false
	return false


func get_merchant_relics() -> Array:
	var result: Array = []
	for entry in _queued_merchant_relics:
		result.append(entry["def"])
	return result


func on_merchant_relic_bought(relic_id: String):
	var i = 0
	while i < _queued_merchant_relics.size():
		var entry = _queued_merchant_relics[i]
		if entry["def"]["id"] == relic_id:
			_queued_merchant_relics.remove_at(i)
			return
		i += 1


func place_collection_relics(parent_node: Node):
	for entry in _queued_collection_relics:
		var r = entry["def"]
		if RelicManager.has_relic(r["id"]):
			continue
		var relic = _relic_scene.instantiate()
		relic.initialize(r["id"], player)
		var pos = r.get("spawn_pos", Vector2.ZERO)
		relic.global_position = _clamp_to_map(pos, 30.0)
		relic.set_meta("collection_relic", true)
		relic.visible = false
		relic.process_mode = PROCESS_MODE_DISABLED
		parent_node.add_child(relic)
		stage_relics.append(relic)
	_queued_collection_relics.clear()


func reveal_collection_relic(relic_node: Node2D):
	if not is_instance_valid(relic_node):
		return
	if not relic_node.has_meta("collection_relic") or not relic_node.get_meta("collection_relic"):
		return
	relic_node.visible = true
	relic_node.process_mode = PROCESS_MODE_INHERIT
	if not has_relic_arrow:
		has_relic_arrow = true
		relic_arrow_target = relic_node.global_position


func _place_relic(r: Dictionary):
	var rid = r["id"]
	if RelicManager.has_relic(rid):
		return
	var relic = _relic_scene.instantiate()
	relic.initialize(rid, player)
	var pos = r.get("spawn_pos", Vector2.ZERO)
	relic.global_position = _clamp_to_map(pos, 30.0)
	main_node.add_child(relic)
	stage_relics.append(relic)
	if not has_relic_arrow:
		has_relic_arrow = true
		relic_arrow_target = relic.global_position


func spawn_stage_items():
	var items = game_state.stage_data.get("stage_items", [])
	if items.is_empty():
		return
	var item_script = preload("res://scripts/entities/stage_item_pickup.gd")
	for it in items:
		var t = it.get("type", -1)
		var is_wpn = it.get("is_weapon", true)
		if t < 0:
			continue
		var positions = it.get("positions", [])
		for entry in positions:
			var pos: Vector2
			var chance := 1.0
			if entry is Vector2:
				pos = entry
			elif entry is Dictionary:
				pos = entry.get("pos", Vector2.ZERO)
				chance = entry.get("chance", 1.0)
			else:
				continue
			if chance < 1.0 and randf() > chance:
				continue
			var pickup = Area2D.new()
			pickup.set_script(item_script)
			pickup.item_type = t
			pickup.is_weapon = is_wpn
			pickup.player = player
			pickup.global_position = _clamp_to_map(pos, 30.0)
			var shape = CollisionShape2D.new()
			var circle = CircleShape2D.new()
			circle.radius = 20.0
			shape.shape = circle
			pickup.add_child(shape)
			var nm = I18N.t(DataRegistry.items().item_name_key(t), DataRegistry.items().item_name(t))
			pickup.setup(t, is_wpn, nm)
			main_node.add_child(pickup)


func get_nearest_relic_pos() -> Vector2:
	if stage_relics.is_empty():
		return Vector2.ZERO
	var nearest = stage_relics[0]
	var min_dist = INF
	var ppos = player.global_position if is_instance_valid(player) else Vector2.ZERO
	for r in stage_relics:
		if not is_instance_valid(r):
			continue
		var d = ppos.distance_squared_to(r.global_position)
		if d < min_dist:
			min_dist = d
			nearest = r
	return nearest.global_position if is_instance_valid(nearest) else Vector2.ZERO


func _clamp_to_map(pos: Vector2, margin: float = 40.0) -> Vector2:
	var hw = game_state.map_width / 2.0 - margin
	var hh = game_state.map_height / 2.0 - margin
	return Vector2(clamp(pos.x, -hw, hw), clamp(pos.y, -hh, hh))


func _get_enemy_base_xp(enemy: Node2D) -> int:
	if not is_instance_valid(enemy):
		return 1
	var type_id = enemy.enemy_type_id if "enemy_type_id" in enemy else -1
	if type_id < 0:
		return 1
	var t = DataRegistry.enemies().get_type(type_id)
	return t.base_xp if t else 1
