extends Node
# SpawnManager — 统一生成管理
# 从 main.gd 拆分：所有敌人/拾取物/遗物/Boss 生成 + 敌人死亡掉落
# main.gd 持有引用并驱动

const EnemyDefs = preload("res://scripts/data/enemy_defs.gd")
const RelicDefs = preload("res://scripts/data/relic_defs.gd")
const ItemDefs = preload("res://scripts/data/item_defs.gd")

signal enemy_spawned(enemy: Node2D)
signal boss_spawned(boss_type: int)
signal arcana_boss_defeated

var player: Node2D
var game_state: Node  # GameState
var camera_ctrl: Node  # CameraController
var main_node: Node2D  # 父节点（main.gd）

var _enemy_scene = preload("res://scenes/enemy.tscn")
var _pickup_scene = preload("res://scenes/pickup.tscn")
var _relic_scene = preload("res://scenes/relic_pickup.tscn")

# 遗物跟踪
var stage_relics: Array = []
var has_relic_arrow: bool = false
var relic_arrow_target: Vector2 = Vector2.ZERO


func setup(p: Node2D, gs: Node, cam: Node, parent: Node2D):
	player = p
	game_state = gs
	camera_ctrl = cam
	main_node = parent


# ── 敌人生成 ──

func spawn_enemy(type_id: int = 0) -> Node2D:
	var enemy = _enemy_scene.instantiate()
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


func spawn_boss():
	if game_state.boss_spawned:
		return
	game_state.boss_spawned = true
	game_state.boss_spawned_event.emit()
	
	var boss_type = EnemyDefs.get_boss_type(game_state._stage_id, game_state.game_time)
	if boss_type < 0:
		return
	
	var enemy = _enemy_scene.instantiate()
	enemy.player = player
	enemy.game_state = game_state
	var curse_mod = 1.0 + (player.get_curse() if is_instance_valid(player) else 0.0)
	enemy.set_enemy_type(boss_type, game_state.difficulty * curse_mod)
	
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
	var boss_type = EnemyDefs.get_boss_type(game_state._stage_id, game_state.game_time)
	if boss_type < 0:
		boss_type = 0
	
	var enemy = _enemy_scene.instantiate()
	enemy.player = player
	enemy.game_state = game_state
	var curse_mod = 1.0 + (player.get_curse() if is_instance_valid(player) else 0.0)
	enemy.set_enemy_type(boss_type, game_state.difficulty * curse_mod * 1.5)
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
	# Returns: is_arcana_boss (bool), is_boss (bool) for caller to handle progression
	
	if not is_instance_valid(enemy):
		return
	
	# Arcana Boss
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
		for i in range(8):
			var gem = ObjectPoolManager.borrow_gem()
			gem.value = max(enemy.xp_value / 4, 5)
			gem.player = player
			gem.global_position = enemy.global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
			main_node.call_deferred("add_child", gem)
		for i in range(3):
			spawn_pickup_at(enemy.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20)), 3 if i == 0 else -1)
		spawn_pickup_at(enemy.global_position, 0)
	else:
		if randf() < 0.28:
			var gem = ObjectPoolManager.borrow_gem()
			gem.player = player
			gem.global_position = enemy.global_position
			if game_state.game_time < 480.0:
				gem.tier = gem.Tier.BLUE
				gem.value = maxi(enemy.xp_value, 1)
			elif game_state.game_time < 1080.0:
				gem.tier = gem.Tier.GREEN
				gem.value = maxi(enemy.xp_value * 2, 4)
			else:
				gem.tier = gem.Tier.RED
				gem.value = maxi(enemy.xp_value * 3, 10)
			main_node.call_deferred("add_child", gem)
		if randf() < 0.001:
			var pt = 4 + randi() % 3
			spawn_pickup_at(enemy.global_position, pt)


# ── 遗物 ──

func spawn_stage_relics():
	stage_relics.clear()
	has_relic_arrow = false
	relic_arrow_target = Vector2.ZERO
	
	var stage_id = game_state._stage_id
	var relics = RelicDefs.get_relics_for_stage(stage_id)
	for r in relics:
		var rid = r["id"]
		if RelicManager.has_relic(rid):
			continue
		var relic = _relic_scene.instantiate()
		relic.initialize(rid, player)
		relic.global_position = _clamp_to_map(r["spawn_pos"], 30.0)
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
			var nm = I18N.t(ItemDefs.item_name_key(t), ItemDefs.item_name(t))
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


# ── 工具 ──

func _clamp_to_map(pos: Vector2, margin: float = 40.0) -> Vector2:
	var hw = game_state.map_width / 2.0 - margin
	var hh = game_state.map_height / 2.0 - margin
	return Vector2(clamp(pos.x, -hw, hw), clamp(pos.y, -hh, hh))
