extends Node2D

# ── 使用拆分后的核心组件 ──
const GameState = preload("res://scripts/core/game_state.gd")
const WaveSystem = preload("res://scripts/core/wave_system.gd")
const CurseSystem = preload("res://scripts/core/curse_system.gd")
const CameraController = preload("res://scripts/core/camera_controller.gd")
const StageGenerator = preload("res://scripts/core/stage_generator.gd")

# ── 外部依赖 ──
const StageDefs = preload("res://scripts/data/stage_defs.gd")
const EnemyDefs = preload("res://scripts/data/enemy_defs.gd")
const RelicDefs = preload("res://scripts/data/relic_defs.gd")
const ArcanaDefs = preload("res://scripts/data/arcana_defs.gd")
const ItemDefs = preload("res://scripts/data/item_defs.gd")

# ── 场景预加载 ──
var _player_scene = preload("res://scenes/player.tscn")
var _enemy_scene = preload("res://scenes/enemy.tscn")
var _pickup_scene = preload("res://scenes/pickup.tscn")
var _relic_scene = preload("res://scenes/relic_pickup.tscn")

# ── 核心组件 ──
var game_state
var wave_system
var curse_system
var camera_ctrl
var stage_gen

# ── 节点引用 ──
var player: Node2D
var hud: Node
var level_up_screen: Node
var pause_overlay: Node
var _interact_prompt: Label
var _arcana_choice_screen: Node
var prop_manager: Node = null

# ── 状态 ──
var _arcana_boss_spawned_11: bool = false
var _arcana_boss_spawned_21: bool = false
var _frame_count: int = 0
var _map_ready: bool = false

var _cached_vp_size: Vector2 = Vector2.ZERO
var _stage_relics: Array = []
var _has_relic_arrow: bool = false
var _relic_arrow_target: Vector2 = Vector2.ZERO


func _ready():
	# ── 初始化游戏状态 ──
	Engine.time_scale = 1.0
	game_state = GameState.new()
	add_child(game_state)
	
	# 读取关卡数据
	var stage_data = EventBus.get_config("selected_stage", null)
	if stage_data != null:
		game_state.set_stage_data(stage_data)
	else:
		game_state.set_stage_data(StageDefs.get_stage(0))
	
	# 无尽模式
	if EventBus.get_config("endless_mode", false):
		game_state.stage_time_limit = INF
	
	# 各种模式修正
	_apply_stage_mods()
	
	# ── UI 层 ──
	var ui_layer = CanvasLayer.new()
	ui_layer.layer = 1
	add_child(ui_layer)
	
	hud = preload("res://scenes/hud.tscn").instantiate()
	hud.name = "HUD"
	ui_layer.add_child(hud)
	hud.set_time_limit(game_state.stage_time_limit)
	
	level_up_screen = Control.new()
	level_up_screen.name = "LevelUpScreen"
	level_up_screen.set_script(preload("res://scripts/ui/level_up_screen.gd"))
	ui_layer.add_child(level_up_screen)
	
	_arcana_choice_screen = Control.new()
	_arcana_choice_screen.name = "ArcanaChoiceScreen"
	_arcana_choice_screen.set_script(preload("res://scripts/ui/arcana_choice_screen.gd"))
	ui_layer.add_child(_arcana_choice_screen)
	_arcana_choice_screen.arcana_selected.connect(_on_arcana_selected)
	
	pause_overlay = preload("res://scenes/pause_overlay.tscn").instantiate()
	ui_layer.add_child(pause_overlay)
	pause_overlay.toggle_pause.connect(_toggle_pause)
	pause_overlay.quit_to_menu.connect(_on_quit_to_menu)
	
	_interact_prompt = Label.new()
	_interact_prompt.name = "InteractPrompt"
	_interact_prompt.visible = false
	_interact_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interact_prompt.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	_interact_prompt.add_theme_font_size_override("font_size", 16)
	_interact_prompt.add_theme_constant_override("outline_size", 4)
	_interact_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	ui_layer.add_child(_interact_prompt)
	
	# ── 玩家 ──
	player = _player_scene.instantiate()
	player.leveled_up.connect(_on_player_leveled_up)
	player.died.connect(_on_player_died)
	player.hurt.connect(_on_player_hurt)
	add_child(player)
	
	# ── 相机 ──
	camera_ctrl = CameraController.new()
	add_child(camera_ctrl)
	camera_ctrl.setup(self, player, game_state.map_width, game_state.map_height)
	
	# ── Core 系统 ──
	wave_system = WaveSystem.new()
	add_child(wave_system)
	wave_system.setup(game_state, player, _spawn_enemy)
	
	curse_system = CurseSystem.new()
	add_child(curse_system)
	curse_system.setup(game_state, player)
	curse_system.set_hud(hud)
	
	# ── 关卡生成 ──
	stage_gen = StageGenerator.new()
	add_child(stage_gen)
	stage_gen.setup(game_state, self, player)
	stage_gen.map_ready.connect(_on_map_ready)
	
	# ── 遗物生成 ──
	_spawn_stage_relics()
	_spawn_stage_items()
	
	# ── 连接 ──
	level_up_screen.upgrade_selected.connect(_on_upgrade_selected)
	level_up_screen.evolution_selected.connect(_on_evolution_selected)
	level_up_screen.gold_selected.connect(_on_gold_selected)
	
	# ── 重置运行时状态 ──
	PowerUpManager.reset_run_gold()
	_lazy_unlock_manager().reset_run_state()
	ArcanaManager.deactivate_all()
	
	# ── HUD 信号连接 + 初始同步 ──
	_connect_hud_signals()
	_sync_hud_initial()
	
	call_deferred("start_game_music")
	
	if RelicManager.has_relic("randomazzo"):
		_lazy_unlock_manager().on_relic_collected("randomazzo")
	
	# 延迟生成地图
	call_deferred("_deferred_setup")
	
	# 首次奥秘选择
	if EventBus.get_config("arcanas_enabled", false) and ArcanaManager.is_system_enabled() and ArcanaManager.get_unlocked_count() > 0:
		call_deferred("_show_arcana_first_pick")


func _apply_stage_mods():
	var sd = game_state.stage_data
	
	var hurry = EventBus.get_config("hurry_mode", false)
	var hyper = EventBus.get_config("hyper_mode", false)
	var hyper_mods = sd.get("hyper_mods", {})
	
	var enemy_speed = sd.get("enemy_speed_mod", 1.0)
	if hurry:
		enemy_speed *= 1.5
	if hyper:
		enemy_speed += hyper_mods.get("enemy_speed_bonus", 0.0)
	game_state.stage_enemy_speed_mod = enemy_speed
	
	var gold_mod = sd.get("gold_mod", 1.0)
	if hyper:
		gold_mod *= hyper_mods.get("gold_mult", 1.0)
	game_state.stage_gold_mod = gold_mod
	
	var enemy_hp_mod = sd.get("enemy_hp_mod", 1.0)
	if hyper:
		enemy_hp_mod += hyper_mods.get("enemy_hp_bonus", 0.0)
	game_state.stage_enemy_hp_mod = enemy_hp_mod
	
	var proj_speed = sd.get("projectile_speed_mod", 1.0)
	if hyper:
		proj_speed += hyper_mods.get("projectile_speed_bonus", 0.0)
	game_state.stage_projectile_speed_mod = proj_speed
	
	game_state.stage_xp_mod = sd.get("xp_mod", 1.0)
	game_state.stage_luck_mod = sd.get("luck_mod", 0.0)


func _deferred_setup():
	stage_gen.generate()


func _on_map_ready():
	_map_ready = true
	wave_system.set_map_ready(true)
	
	# 初始拾取物散布
	var hw = game_state.map_width / 2.0
	var hh = game_state.map_height / 2.0
	_spawn_initial_pickups(hw, hh)
	
	# 初始敌人（starting_spawns）
	var starting = game_state.starting_spawns
	var pool = EnemyDefs.get_types_for_stage(game_state._stage_id, 0.0)
	for i in range(starting):
		var t = EnemyDefs.pick_weighted(pool) if not pool.is_empty() else 11
		var e = _spawn_enemy(t)
		if e:
			e.is_wave_enemy = false


# ═══════════════════════════════════════════════════════════
#  PROCESS
# ═══════════════════════════════════════════════════════════

func _process(delta):
	if game_state.game_over or game_state.stage_complete or not _map_ready:
		return
	
	_frame_count += 1
	var every_n = func(n: int): return _frame_count % n == 0
	
	# ── 倍速控制 ──
	var speed_mult = GameState.SPEED_VALUES[game_state.speed_level]
	var hurry = EventBus.get_config("hurry_mode", false)
	if hurry and game_state.speed_level == 0:
		speed_mult = 1.5
	if speed_mult != Engine.time_scale:
		Engine.time_scale = speed_mult
	
	game_state.game_time += delta
	game_state.update_difficulty(delta)
	
	# ── 胜利条件 ──
	var endless = EventBus.get_config("endless_mode", false)
	if not endless and game_state.game_time >= game_state.stage_time_limit:
		_on_stage_complete()
		return
	
	# ── 子系统更新 ──
	wave_system.process(delta)
	curse_system.process(delta)
	camera_ctrl.process(delta)
	_process_pickup_timers(delta)
	
	# ── Boss 检测 ──
	if not game_state.boss_spawned and game_state.game_time >= 900.0:
		var boss_t = EnemyDefs.get_boss_type(game_state._stage_id, game_state.game_time)
		if boss_t >= 0:
			_spawn_boss()
	
	# ── HUD 计时器 ──
	hud.set_timer(game_state.game_time)
	
	# ── 奥秘系统 ──
	_update_arcana(delta)
	
	# ── 遗物箭头 ──
	_update_relic_arrow(every_n)
	
	# ── 交互提示 ──
	_update_interaction_prompt(every_n)


# ════════════════════════════════════════════════════════════════════
#  PICKUP TIMERS (Gold Finger, Nduja, Gold Fever, Freeze)
# ════════════════════════════════════════════════════════════════════

func _process_pickup_timers(delta: float):
	# Gold Finger countdown
	var gf = EventBus.get_config("gold_finger_timer", 0.0)
	if gf > 0.0:
		gf -= delta
		if gf <= 0.0:
			EventBus.set_config("gold_finger_timer", 0.0)
			_on_gold_finger_end()
		else:
			EventBus.set_config("gold_finger_timer", gf)
			if is_instance_valid(player):
				player.invincible = max(player.invincible, 0.1)

	# Nduja Fritta countdown
	var nd = EventBus.get_config("nduja_timer", 0.0)
	if nd > 0.0:
		nd -= delta
		if nd <= 0.0:
			EventBus.set_config("nduja_timer", 0.0)
		else:
			EventBus.set_config("nduja_timer", nd)
			_emit_nduja_fire()

	# Gold Fever countdown
	var gft = EventBus.get_config("gold_fever_timer", 0.0)
	if gft > 0.0:
		gft -= delta
		if gft <= 0.0:
			EventBus.set_config("gold_fever_timer", 0.0)
		else:
			EventBus.set_config("gold_fever_timer", gft)


func _on_gold_finger_end():
	var kills = EventBus.get_config("gold_finger_kills", 0)
	var tier = "bronze"
	if kills >= 10: tier = "silver"
	if kills >= 30: tier = "gold"
	if kills >= 60: tier = "demon"
	if kills >= 100: tier = "cosmic"

	match tier:
		"bronze":
			_spawn_pickup_at(player.global_position, 2)  # COIN_BAG
		"silver":
			_spawn_pickup_at(player.global_position, 3)  # RICH_COIN_BAG
			_spawn_pickup_at(player.global_position, 7)  # LITTLE_CLOVER
		"gold":
			_spawn_pickup_at(player.global_position, 3)  # RICH_COIN_BAG
			_spawn_pickup_at(player.global_position, 8)  # GILDED_CLOVER
		"demon":
			for i in range(3):
				_spawn_pickup_at(player.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20)), 3)
			_spawn_pickup_at(player.global_position, 4)  # ROSARY
		"cosmic":
			for i in range(5):
				_spawn_pickup_at(player.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20)), 3)
			_spawn_pickup_at(player.global_position, 8)  # GILDED_CLOVER
			_spawn_pickup_at(player.global_position, 4)  # ROSARY

	var txt = "Gold Finger: " + str(kills) + " kills - " + tier.capitalize() + " prize!"
	if is_instance_valid(player) and player.has_method("show_floating_text"):
		player.show_floating_text(txt, Color(0.9, 0.7, 0.0), 22)


func _emit_nduja_fire():
	if not is_instance_valid(player) or not is_inside_tree():
		return
	if Engine.get_frames_drawn() % 5 != 0:
		return
	var dir = player.direction if player.direction.length() > 0 else Vector2.DOWN
	var offset = dir * 24.0
	var area = Area2D.new()
	area.global_position = player.global_position + offset
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 20.0
	shape.shape = circle
	area.add_child(shape)
	add_child(area)
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and area.global_position.distance_to(e.global_position) < 24.0:
			if e.has_method("take_damage"):
				var dmg = 10.0 * (player.damage_mult if player.has_method("get_curse") else 1.0)
				e.take_damage(dmg, player.global_position)
	var fb = preload("res://scripts/entities/fireball_node.gd").new()
	fb.fb_size = 8.0
	fb.seed_offset = randi()
	fb.global_position = area.global_position
	add_child(fb)
	var tw = create_tween()
	tw.tween_interval(0.3)
	tw.finished.connect(area.queue_free)
	tw.finished.connect(fb.queue_free)

# ════════════════════════════════════════════════════════════════════# ════════════════════════════════════════════════════════════════════


# ════════════════════════════════════════════════════════════════════
#  HUD — 信号驱动（替代逐帧轮询）
# ════════════════════════════════════════════════════════════════════

func _connect_hud_signals():
	# 玩家属性
	player.leveled_up.connect(_on_player_level_changed)
	player.xp_changed.connect(_on_xp_changed)
	player.health_changed.connect(_on_health_changed)
	player.weapons_changed.connect(_on_weapons_changed)
	player.passives_changed.connect(_on_passives_changed)
	
	# 游戏状态
	game_state.kills_changed.connect(_on_kills_changed)
	wave_system.wave_started.connect(_on_wave_changed)
	
	# 运行金币
	PowerUpManager.run_gold_changed.connect(_on_run_gold_changed)


func _sync_hud_initial():
	hud.set_level(player.level)
	hud.set_kills(game_state.total_kills)
	hud.set_gold(PowerUpManager.run_gold)
	hud.set_wave(game_state.wave_number)
	hud.set_xp(player.xp, player.xp_to_next)
	hud.set_health(player.health, player.max_health)
	hud.set_timer(game_state.game_time)
	_on_weapons_changed()
	_on_passives_changed()


func _on_player_level_changed():
	hud.set_level(player.level)


func _on_xp_changed(_xp: int, _need: int):
	hud.set_xp(player.xp, player.xp_to_next)


func _on_health_changed(_hp: float, _max_hp: float):
	hud.set_health(player.health, player.max_health)


func _on_kills_changed(total: int):
	hud.set_kills(total)


func _on_run_gold_changed(amount: int):
	hud.set_gold(amount)


func _on_wave_changed(wave: int):
	hud.set_wave(wave)


func _on_weapons_changed():
	var wep_data: Array = []
	for w in player.weapon_manager.weapons:
		wep_data.append({
			"name": ItemDefs.item_name(w.type),
			"name_key": ItemDefs.item_name_key(w.type),
			"type": w.type,
			"level": w.level,
			"evolved": w.evolved,
			"color": ItemDefs.item_color(w.type),
		})
	hud.set_weapons(wep_data)


func _on_passives_changed():
	var pas_data: Array = []
	for t in player.passive_inventory.get_all():
		var lv = player.passive_inventory.get_level(t)
		pas_data.append({"type": t, "level": lv, "color": ItemDefs.item_color(t)})
	hud.set_passives(pas_data)


func _update_arcana(delta: float):
	if ArcanaManager.get_active_count() > 0:
		ArcanaManager.process_time_effects(delta, player, game_state.game_time)
		hud.set_arcanas(ArcanaManager.get_active())
	
	var arcanas_enabled = EventBus.get_config("arcanas_enabled", false)
	if arcanas_enabled and ArcanaManager.is_system_enabled():
		if not _arcana_boss_spawned_11 and game_state.game_time >= 660.0:
			_arcana_boss_spawned_11 = true
			_spawn_arcana_boss()
		if not _arcana_boss_spawned_21 and game_state.game_time >= 1260.0:
			_arcana_boss_spawned_21 = true
			_spawn_arcana_boss()


func _update_relic_arrow(every_n: Callable):
	if _has_relic_arrow and is_instance_valid(player) and every_n.call(6):
		var target = _get_nearest_relic_pos()
		if target != Vector2.ZERO:
			var offset = target - player.global_position
			var dist = offset.length()
			if dist > 80.0:
				hud.set_relic_arrow(offset.angle(), dist)
			else:
				hud.set_relic_arrow(null, 0.0)
		else:
			hud.set_relic_arrow(null, 0.0)


func _update_interaction_prompt(every_n: Callable):
	var pm = get_prop_manager()
	if pm and is_instance_valid(player) and every_n.call(6):
		pm.update_nearest(player.global_position, 80.0)
		if pm.highlight_prompt != "":
			_interact_prompt.text = "[E] " + pm.highlight_prompt
			if _cached_vp_size == Vector2.ZERO:
				_cached_vp_size = get_viewport().get_visible_rect().size
			_interact_prompt.position = Vector2(_cached_vp_size.x / 2.0 - 100, _cached_vp_size.y - 50)
			_interact_prompt.visible = true
		else:
			_interact_prompt.visible = false


# ═══════════════════════════════════════════════════════════
#  SPAWNING
# ═══════════════════════════════════════════════════════════

func _spawn_enemy(type_id: int = 0) -> Node2D:
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
	enemy.died.connect(_on_enemy_died.bind(enemy))
	add_child(enemy)
	return enemy


func _spawn_boss():
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
	enemy.died.connect(_on_enemy_died.bind(enemy))
	add_child(enemy)
	_show_boss_announcement(I18N.t("boss.announce"))
	camera_ctrl.shake(8.0, 1.0)


func _spawn_arcana_boss():
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
	enemy.died.connect(_on_enemy_died.bind(enemy))
	add_child(enemy)
	_show_boss_announcement(I18N.t("arcana.boss_announce"))


func _spawn_pickup_at(pos: Vector2, pickup_type: int = -1):
	var pickup = _pickup_scene.instantiate()
	pickup.player = player
	if pickup_type >= 0:
		pickup.type = pickup_type
	else:
		# Weighted random: chicken, coin, coin_bag, or rare rosary/vacuum
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
	call_deferred("add_child", pickup)


func _spawn_initial_pickups(hw: float, hh: float):
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
		# CHICKEN (0), COIN_BAG (2), or rarely LITTLE_CLOVER (7) / ROSARY (4)
		var pt = rng.randi_range(0, 2)
		if pt == 1:
			pt = 2  # map GOLD_COIN(1) to COIN_BAG(2) for map spawns
		var roll = rng.randf()
		if roll < 0.01:
			pt = 7  # Little Clover
		elif roll < 0.02:
			pt = 4  # Rosary
		_spawn_pickup_at(pos, pt)


# ── 遗物 ──

func _spawn_stage_relics():
	var stage_id = game_state._stage_id
	var relics = RelicDefs.get_relics_for_stage(stage_id)
	for r in relics:
		var rid = r["id"]
		if RelicManager.has_relic(rid):
			continue
		var relic = _relic_scene.instantiate()
		relic.initialize(rid, player)
		relic.global_position = _clamp_to_map(r["spawn_pos"], 30.0)
		add_child(relic)
		_stage_relics.append(relic)
		if not _has_relic_arrow:
			_has_relic_arrow = true
			_relic_arrow_target = relic.global_position


func _spawn_stage_items():
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
			add_child(pickup)


func _get_nearest_relic_pos() -> Vector2:
	if _stage_relics.is_empty():
		return Vector2.ZERO
	var nearest = _stage_relics[0]
	var min_dist = INF
	var ppos = player.global_position if is_instance_valid(player) else Vector2.ZERO
	for r in _stage_relics:
		if not is_instance_valid(r):
			continue
		var d = ppos.distance_squared_to(r.global_position)
		if d < min_dist:
			min_dist = d
			nearest = r
	return nearest.global_position if is_instance_valid(nearest) else Vector2.ZERO


func _on_enemy_died(enemy: Node2D):
	if not is_instance_valid(enemy):
		return
	game_state.add_kill()
	
	# 波次追踪
	if game_state.wave_active and enemy.is_wave_enemy:
		game_state.wave_alive -= 1
	
	# Arcana Boss
	var is_arcana_boss = enemy.has_meta("arcana_boss") and enemy.get_meta("arcana_boss")
	if is_arcana_boss:
		for i in range(5):
			var gem = ObjectPoolManager.borrow_gem()
			gem.value = max(enemy.xp_value / 3, 5)
			gem.player = player
			gem.global_position = enemy.global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
			call_deferred("add_child", gem)
		for i in range(2):
			_spawn_pickup_at(enemy.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20)), 2)  # COIN_BAG
		call_deferred("_show_arcana_chest_pick")
		return
	
	var is_boss = enemy.has_method("get_is_boss") and enemy.get_is_boss()
	if is_boss:
		_lazy_unlock_manager().on_boss_defeated(game_state._stage_id)
	
	if is_boss:
		for i in range(8):
			var gem = ObjectPoolManager.borrow_gem()
			gem.value = max(enemy.xp_value / 4, 5)
			gem.player = player
			gem.global_position = enemy.global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
			call_deferred("add_child", gem)
		for i in range(3):
			_spawn_pickup_at(enemy.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20)), 3 if i == 0 else -1)  # RICH_COIN_BAG
		_spawn_pickup_at(enemy.global_position, 0)
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
			call_deferred("add_child", gem)
		if randf() < 0.001:
			# Rare: ROSARY(4), OROLOGION(5), or VACUUM(6)
			var pt = 4 + randi() % 3
			_spawn_pickup_at(enemy.global_position, pt)


# ═══════════════════════════════════════════════════════════
#  GAME FLOW
# ═══════════════════════════════════════════════════════════

func _on_player_leveled_up():
	_lazy_unlock_manager().on_player_leveled_up(player.level)
	ArcanaManager.on_player_level_up(player, player.level)
	get_tree().paused = true
	level_up_screen.show_choices(player)


func _on_player_hurt():
	camera_ctrl.shake(4.0, 0.15)


func _on_player_died():
	game_state.set_game_over()
	camera_ctrl.shake(12.0, 0.5)
	get_tree().paused = true
	if player:
		_lazy_unlock_manager().on_run_ended(player.level)
	AudioManager.stop_bgm()
	AudioManager.play_sfx("game_over")
	PowerUpManager.end_run(true)
	level_up_screen.hide_screen()
	pause_overlay.visible = false
	hud.show_game_over(game_state.game_time, game_state.total_kills, player.level)


func _on_stage_complete():
	game_state.set_stage_complete()
	AudioManager.stop_bgm()
	AudioManager.play_sfx("evolution")
	_lazy_unlock_manager().on_stage_cleared(game_state._stage_id)
	if player:
		_lazy_unlock_manager().on_run_ended(player.level)
	var gold_bonus = 500
	var total_gold = PowerUpManager.run_gold + gold_bonus
	PowerUpManager.add_run_gold(gold_bonus)
	PowerUpManager.end_run(true)
	PowerUpManager.set_run_gold(total_gold)
	get_tree().paused = true
	level_up_screen.hide_screen()
	pause_overlay.visible = false
	hud.show_stage_complete(game_state.game_time, game_state.total_kills, player.level, game_state.stage_data.get("name", "Stage"))


func _on_upgrade_selected(upgrade_type: int):
	get_tree().paused = false
	player.apply_upgrade(upgrade_type)
	level_up_screen.hide_screen()


func _on_evolution_selected(weapon_type: int):
	get_tree().paused = false
	player.evolve_weapon(weapon_type)
	level_up_screen.hide_screen()


func _on_gold_selected(amount: int):
	get_tree().paused = false
	PowerUpManager.add_run_gold(amount)
	level_up_screen.hide_screen()


# ═══════════════════════════════════════════════════════════
#  ARCANA
# ═══════════════════════════════════════════════════════════

func _show_arcana_first_pick():
	if ArcanaManager.get_unlocked_count() <= 0:
		return
	get_tree().paused = true
	_arcana_choice_screen.show_choices(true)


func _show_arcana_chest_pick():
	if get_tree().paused:
		return
	var pool = ArcanaManager.get_unlocked()
	var active = ArcanaManager.get_active()
	var available = []
	for id in pool:
		if not active.has(id):
			available.append(id)
	if available.is_empty():
		return
	get_tree().paused = true
	_arcana_choice_screen.show_choices(false, available)


func _on_arcana_selected(arcana_id: int):
	get_tree().paused = false
	_show_boss_announcement(I18N.t("arcana.equipped") % I18N.t("arcana." + str(arcana_id) + "_name", ArcanaDefs.get_arcana(arcana_id)["name"]))
	player.recalculate_stats()


# ═══════════════════════════════════════════════════════════
#  ANNOUNCEMENT / FX
# ═══════════════════════════════════════════════════════════

func _show_boss_announcement(text: String):
	camera_ctrl.shake(8.0, 1.0)
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.9, 0.15, 0.1))
	label.add_theme_font_size_override("font_size", 30)
	var vp_size = get_viewport().get_visible_rect().size
	label.position = Vector2(vp_size.x / 2.0 - 150, vp_size.y * 0.15)
	for c in get_children():
		if c is CanvasLayer:
			c.add_child(label)
			break
	var tw = create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(label, "modulate", Color(1, 1, 1, 0), 1.0)
	tw.finished.connect(label.queue_free)


func start_game_music():
	if AudioManager and AudioManager.has_method("play_bgm"):
		AudioManager.stop_bgm()
		var use_alt = EventBus.get_config("alt_music", false) and RelicManager.has_relic("magic_banger")
		var bgm_key = "bgm_alt" if use_alt else "bgm_game"
		if AudioManager.sounds.has(bgm_key):
			AudioManager.play_bgm(AudioManager.sounds.get(bgm_key))
		else:
			AudioManager.play_bgm(AudioManager.sounds.get("bgm_game"))


# ═══════════════════════════════════════════════════════════
#  INPUT
# ═══════════════════════════════════════════════════════════

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("fullscreen"):
		I18N.toggle_fullscreen()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("interact"):
		var pm = get_prop_manager()
		if pm and is_instance_valid(player):
			pm.try_interact(player)
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo and not get_tree().paused:
		match event.keycode:
			KEY_1, KEY_KP_1: _set_speed(0); get_viewport().set_input_as_handled()
			KEY_2, KEY_KP_2: _set_speed(1); get_viewport().set_input_as_handled()
			KEY_3, KEY_KP_3: _set_speed(2); get_viewport().set_input_as_handled()
			KEY_4, KEY_KP_4: _set_speed(3); get_viewport().set_input_as_handled()


func _set_speed(level: int):
	game_state.speed_level = level
	hud.set_speed(GameState.SPEED_VALUES[level])
	var txt = "Speed x" + str(GameState.SPEED_VALUES[level])
	if GameState.SPEED_VALUES[level] > 1.0:
		txt += " ⚡"
	player.show_floating_text(txt, Color(0.3, 1.0, 0.8), 18)


func _toggle_pause():
	if game_state.game_over or game_state.stage_complete or level_up_screen.visible:
		return
	var new_paused = not get_tree().paused
	get_tree().paused = new_paused
	pause_overlay.visible = new_paused


func _on_quit_to_menu():
	Engine.time_scale = 1.0
	get_tree().paused = false
	PowerUpManager.end_run(true)
	SceneManager.change_scene("res://scenes/main_menu.tscn")


# ═══════════════════════════════════════════════════════════
#  UTILITY
# ═══════════════════════════════════════════════════════════

func get_game_state():
	return game_state

func get_prop_manager():
	if prop_manager == null:
		for c in get_children():
			if c.name == "PropManager":
				prop_manager = c
				break
	return prop_manager

func get_camera():
	return camera_ctrl._camera if camera_ctrl else null

func get_obstacle_positions() -> Array:
	return stage_gen.obstacle_positions if stage_gen else []

# 向后兼容：外部脚本读取 map_width/map_height
func get_map_prop(key: String):
	match key:
		"map_width": return game_state.map_width if game_state else 3200.0
		"map_height": return game_state.map_height if game_state else 2400.0
	return null


func _clamp_to_map(pos: Vector2, margin: float = 40.0) -> Vector2:
	var hw = game_state.map_width / 2.0 - margin
	var hh = game_state.map_height / 2.0 - margin
	return Vector2(clamp(pos.x, -hw, hw), clamp(pos.y, -hh, hh))


# UnlockManager 延迟加载（非 Autoload，按需创建）
var _unlock_manager: Node = null

func _lazy_unlock_manager() -> Node:
	if _unlock_manager == null:
		_unlock_manager = load("res://scripts/managers/unlock_manager.gd").new()
		add_child(_unlock_manager)
		EventBus.register_unlock_manager(_unlock_manager)
	return _unlock_manager
