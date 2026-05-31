extends Node2D
# main.gd — 游戏主循环编排（缩减版）
# 初始化子系统 → 驱动 _process → 处理游戏流程事件
# 生成逻辑委托给 SpawnManager，拾取计时器委托给 PickupTimer

# ── 核心组件 ──
const GameState = preload("res://scripts/core/game_state.gd")
const WaveSystem = preload("res://scripts/core/wave_system.gd")
const CurseSystem = preload("res://scripts/core/curse_system.gd")
const CameraController = preload("res://scripts/core/camera_controller.gd")
const StageGenerator = preload("res://scripts/core/stage_generator.gd")
const SpawnManager = preload("res://scripts/core/spawn_manager.gd")
const PickupTimer = preload("res://scripts/core/pickup_timer.gd")

# ── 外部依赖 ──
# Data defs loaded lazily via DataRegistry (autoload)

# ── 核心组件 ──
var game_state
var wave_system
var curse_system
var camera_ctrl
var stage_gen
var spawn_manager
var pickup_timer

# ── 节点引用 ──
var player: Node2D
var hud: Node
var _ui_layer: CanvasLayer
# 延迟创建：首次使用时实例化
var _level_up_screen: Node = null
var _pause_overlay: Node = null
var _arcana_choice_screen: Node = null
var _interact_prompt: Label
var prop_manager: Node = null

# ── 状态 ──
var _arcana_boss_spawned_11: bool = false
var _arcana_boss_spawned_21: bool = false
var _frame_count: int = 0
var _map_ready: bool = false
var _cached_vp_size: Vector2 = Vector2.ZERO


func _ready():
	# ── 初始化游戏状态 ──
	Engine.time_scale = 1.0
	game_state = GameState.new()
	add_child(game_state)

	# Notify unlock manager that run started
	var char_data = EventBus.get_config("selected_character", null)
	var char_id = char_data.get("id", 0) if char_data else 0
	UnlockManager.on_run_started(char_id)
	
	var stage_data = EventBus.get_config("selected_stage", null)
	if stage_data != null:
		game_state.set_stage_data(stage_data)
	else:
		game_state.set_stage_data(DataRegistry.stages().get_stage(0))
	
	if EventBus.get_config("endless_mode", false):
		game_state.stage_time_limit = INF
	
	_apply_stage_mods()
	
	# ── UI 层 ──
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 1
	add_child(_ui_layer)
	
	hud = preload("res://scenes/hud.tscn").instantiate()
	hud.name = "HUD"
	_ui_layer.add_child(hud)
	hud.set_time_limit(game_state.stage_time_limit)
	
	_interact_prompt = Label.new()
	_interact_prompt.name = "InteractPrompt"
	_interact_prompt.visible = false
	_interact_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interact_prompt.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	_interact_prompt.add_theme_font_size_override("font_size", 16)
	_interact_prompt.add_theme_constant_override("outline_size", 4)
	_interact_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_ui_layer.add_child(_interact_prompt)
	
	_level_up_screen = Control.new()
	_level_up_screen.name = "LevelUpScreen"
	_level_up_screen.set_script(preload("res://scripts/ui/level_up_screen.gd"))
	_ui_layer.add_child(_level_up_screen)
	_level_up_screen.upgrade_selected.connect(_on_upgrade_selected)
	_level_up_screen.evolution_selected.connect(_on_evolution_selected)
	_level_up_screen.gold_selected.connect(_on_gold_selected)
	# _arcana_choice_screen、pause_overlay 延迟创建
	
	# ── 玩家 ──
	player = preload("res://scenes/player.tscn").instantiate()
	player.leveled_up.connect(_on_player_leveled_up)
	player.died.connect(_on_player_died)
	player.hurt.connect(_on_player_hurt)
	add_child(player)
	
	# ── 相机 ──
	camera_ctrl = CameraController.new()
	add_child(camera_ctrl)
	camera_ctrl.setup(self, player, game_state.map_width, game_state.map_height)
	
	# ── SpawnManager ──
	spawn_manager = SpawnManager.new()
	add_child(spawn_manager)
	spawn_manager.setup(player, game_state, camera_ctrl, self)
	spawn_manager.enemy_spawned.connect(_on_enemy_spawned)
	spawn_manager.boss_spawned.connect(_on_boss_spawned)
	
	# ── Core 系统 ──
	wave_system = WaveSystem.new()
	add_child(wave_system)
	wave_system.setup(game_state, player, spawn_manager.spawn_enemy)
	
	curse_system = CurseSystem.new()
	add_child(curse_system)
	curse_system.setup(game_state, player)
	curse_system.set_hud(hud)
	
	# ── 关卡生成 ──
	stage_gen = StageGenerator.new()
	add_child(stage_gen)
	stage_gen.setup(game_state, self, player)
	stage_gen.map_ready.connect(_on_map_ready)
	
	# ── PickupTimer ──
	pickup_timer = PickupTimer.new()
	add_child(pickup_timer)
	pickup_timer.setup(player, self)
	pickup_timer.spawned_pickup.connect(_on_pickup_timer_spawn)
	
	# ── 遗物 / 道具生成 ──
	spawn_manager.spawn_stage_relics()
	spawn_manager.spawn_stage_items()
	
	# ── 重置运行时状态 ──
	PowerUpManager.reset_run_gold()
	ArcanaManager.deactivate_all()
	
	# ── HUD 信号连接 + 初始同步 ──
	_connect_hud_signals()
	_sync_hud_initial()
	
	call_deferred("start_game_music")
	
	if RelicManager.has_relic("randomazzo"):
		UnlockManager.on_relic_collected("randomazzo")
	
	call_deferred("_deferred_setup")
	
	if EventBus.get_config("arcanas_enabled", false) and ArcanaManager.is_system_enabled() and ArcanaManager.get_unlocked_count() > 0:
		call_deferred("_show_arcana_first_pick")


func _apply_stage_mods():
	var sd = game_state.stage_data
	var hurry = EventBus.get_config("hurry_mode", false)
	var hyper = EventBus.get_config("hyper_mode", false)
	var inverse = EventBus.get_config("inverse_mode", false) and RelicManager.has_relic("gracia_mirror")
	var hyper_mods = sd.get("hyper_mods", {})
	var inverse_mods = sd.get("inverse_mods", {})
	
	var enemy_speed = sd.get("enemy_speed_mod", 1.0)
	if hurry: enemy_speed *= 1.5
	if hyper: enemy_speed += hyper_mods.get("enemy_speed_bonus", 0.0)
	game_state.stage_enemy_speed_mod = enemy_speed
	
	var gold_mod = sd.get("gold_mod", 1.0)
	if hyper: gold_mod *= hyper_mods.get("gold_mult", 1.0)
	if inverse: gold_mod *= inverse_mods.get("gold_mult", 3.0)
	game_state.stage_gold_mod = gold_mod
	
	var enemy_hp_mod = sd.get("enemy_hp_mod", 1.0)
	if hyper: enemy_hp_mod += hyper_mods.get("enemy_hp_bonus", 0.0)
	if inverse: enemy_hp_mod = inverse_mods.get("enemy_hp", 3.0)
	game_state.stage_enemy_hp_mod = enemy_hp_mod
	
	var proj_speed = sd.get("projectile_speed_mod", 1.0)
	if hyper: proj_speed += hyper_mods.get("projectile_speed_bonus", 0.0)
	if inverse: proj_speed = inverse_mods.get("projectile_speed", 1.25)
	game_state.stage_projectile_speed_mod = proj_speed
	
	game_state.stage_xp_mod = sd.get("xp_mod", 1.0)
	game_state.stage_luck_mod = sd.get("luck_mod", 0.0)
	if inverse: game_state.stage_luck_mod += inverse_mods.get("luck", 0.2)
	
	if inverse:
		game_state.starting_spawns = inverse_mods.get("starting_spawns", game_state.starting_spawns)
	
	# Handle random events
	if EventBus.get_config("random_events", false) and RelicManager.has_relic("trisection"):
		game_state.stage_data["random_events"] = true


func _deferred_setup():
	stage_gen.generate()


func _on_map_ready():
	_map_ready = true
	wave_system.set_map_ready(true)
	
	var hw = game_state.map_width / 2.0
	var hh = game_state.map_height / 2.0
	spawn_manager.spawn_initial_pickups(hw, hh)
	
	var starting = game_state.starting_spawns
	var pool = DataRegistry.enemies().get_types_for_stage(game_state._stage_id, 0.0)
	for i in range(starting):
		var t = DataRegistry.enemies().pick_weighted(pool) if not pool.is_empty() else 11
		var e = spawn_manager.spawn_enemy(t)
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
	
	# Unlock manager: game time tracking — update every ~1s for survivable checks
	if _frame_count % 60 == 0:
		UnlockManager.on_game_time_updated(game_state.game_time)
	
	if not EventBus.get_config("endless_mode", false) and game_state.game_time >= game_state.stage_time_limit:
		_on_stage_complete()
		return
	
	# ── 子系统更新 ──
	wave_system.process(delta)
	curse_system.process(delta)
	camera_ctrl.process(delta)
	pickup_timer.process(delta)
	
	# ── Boss 检测 ──
	# 数据驱动关卡（wave_defs）由波次系统管理 Boss，跳过此处
	var _has_wave_defs = game_state.stage_data.has("wave_defs") and not game_state.stage_data["wave_defs"].is_empty()
	if not _has_wave_defs and not game_state.boss_spawned and game_state.game_time >= 900.0:
		var boss_t = DataRegistry.enemies().get_boss_type(game_state._stage_id, game_state.game_time)
		if boss_t >= 0:
			spawn_manager.spawn_boss()
	
	# ── HUD 计时器 ──
	hud.set_timer(game_state.game_time)
	
	# ── 奥秘系统 ──
	_update_arcana(delta)
	
	# ── 遗物箭头 ──
	_update_relic_arrow(every_n)
	
	# ── 交互提示 ──
	_update_interaction_prompt(every_n)


# ═══════════════════════════════════════════════════════════
#  ENEMY DEATH (signal bridge: enemy → SpawnManager → main.gd)
# ═══════════════════════════════════════════════════════════

func _on_boss_spawned(_boss_type: int):
	_show_boss_announcement(I18N.t("boss.announce"))
	camera_ctrl.shake(8.0, 1.0)


func _on_enemy_spawned(enemy: Node2D):
	enemy.died.connect(_on_enemy_died.bind(enemy))


func _on_enemy_died(enemy: Node2D):
	if not is_instance_valid(enemy):
		return
	game_state.add_kill()
	var is_boss = enemy.has_method("get_is_boss") and enemy.get_is_boss()
	var enemy_type = enemy.enemy_type_id if "enemy_type_id" in enemy else -1
	EventBus.enemy_killed.emit(enemy_type, enemy.global_position, is_boss)
	
	if game_state.wave_active and enemy.is_wave_enemy:
		game_state.wave_alive -= 1
	
	var is_arcana_boss = enemy.has_meta("arcana_boss") and enemy.get_meta("arcana_boss")
	
	# 掉落物（委托给 SpawnManager）
	spawn_manager.spawn_enemy_drops(enemy)
	
	# 进度/UI（main.gd 保留）
	if is_arcana_boss:
		call_deferred("_show_arcana_chest_pick")
	if is_boss:
		UnlockManager.on_boss_defeated(game_state._stage_id)


# ═══════════════════════════════════════════════════════════
#  HUD — 信号驱动
# ═══════════════════════════════════════════════════════════

func _connect_hud_signals():
	player.leveled_up.connect(_on_player_level_changed)
	player.xp_changed.connect(_on_xp_changed)
	player.health_changed.connect(_on_health_changed)
	player.weapons_changed.connect(_on_weapons_changed)
	player.passives_changed.connect(_on_passives_changed)
	game_state.kills_changed.connect(_on_kills_changed)
	wave_system.wave_started.connect(_on_wave_changed)
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
			"name": DataRegistry.items().item_name(w.type),
			"name_key": DataRegistry.items().item_name_key(w.type),
			"type": w.type,
			"level": w.level,
			"evolved": w.evolved,
			"color": DataRegistry.items().item_color(w.type),
		})
	hud.set_weapons(wep_data)


func _on_passives_changed():
	var pas_data: Array = []
	for t in player.passive_inventory.get_all():
		var lv = player.passive_inventory.get_level(t)
		pas_data.append({"type": t, "level": lv, "color": DataRegistry.items().item_color(t)})
	hud.set_passives(pas_data)


func _on_pickup_timer_spawn(pos: Vector2, pickup_type: int):
	spawn_manager.spawn_pickup_at(pos, pickup_type)


# ═══════════════════════════════════════════════════════════
#  ARCANA / RELIC ARROW / INTERACTION
# ═══════════════════════════════════════════════════════════

func _update_arcana(delta: float):
	if ArcanaManager.get_active_count() > 0:
		ArcanaManager.process_time_effects(delta, player, game_state.game_time)
		hud.set_arcanas(ArcanaManager.get_active())
	
	var arcanas_enabled = EventBus.get_config("arcanas_enabled", false)
	if arcanas_enabled and ArcanaManager.is_system_enabled():
		if not _arcana_boss_spawned_11 and game_state.game_time >= 660.0:
			_arcana_boss_spawned_11 = true
			spawn_manager.spawn_arcana_boss()
			_show_boss_announcement(I18N.t("arcana.boss_announce"))
		if not _arcana_boss_spawned_21 and game_state.game_time >= 1260.0:
			_arcana_boss_spawned_21 = true
			spawn_manager.spawn_arcana_boss()
			_show_boss_announcement(I18N.t("arcana.boss_announce"))


func _update_relic_arrow(every_n: Callable):
	if spawn_manager.has_relic_arrow and is_instance_valid(player) and every_n.call(6):
		var target = spawn_manager.get_nearest_relic_pos()
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
#  GAME FLOW
# ═══════════════════════════════════════════════════════════

func _on_player_leveled_up():
	EventBus.player_leveled_up.emit(player.level)
	ArcanaManager.on_player_level_up(player, player.level)
	get_tree().paused = true
	_level_up_screen.show_choices(player)


func _on_player_hurt():
	camera_ctrl.shake(4.0, 0.15)


func _on_player_died():
	game_state.set_game_over()
	camera_ctrl.shake(12.0, 0.5)
	get_tree().paused = true
	UnlockManager.on_game_time_updated(game_state.game_time)
	EventBus.game_over.emit(game_state.total_kills, player.level if player else 0, game_state.game_time)
	AudioManager.stop_bgm()
	AudioManager.play_sfx("game_over")
	PowerUpManager.end_run(true)
	_level_up_screen.hide_screen()
	_get_pause_overlay().visible = false
	hud.show_game_over(game_state.game_time, game_state.total_kills, player.level)


func _on_stage_complete():
	game_state.set_stage_complete()
	AudioManager.stop_bgm()
	AudioManager.play_sfx("evolution")
	UnlockManager.on_game_time_updated(game_state.game_time)
	EventBus.stage_completed.emit(game_state._stage_id, game_state.game_time)
	if player:
		EventBus.game_over.emit(game_state.total_kills, player.level, game_state.game_time)
	var gold_bonus = 500
	var total_gold = PowerUpManager.run_gold + gold_bonus
	PowerUpManager.add_run_gold(gold_bonus)
	PowerUpManager.end_run(true)
	PowerUpManager.set_run_gold(total_gold)
	get_tree().paused = true
	_level_up_screen.hide_screen()
	_get_pause_overlay().visible = false
	hud.show_stage_complete(game_state.game_time, game_state.total_kills, player.level, game_state.stage_data.get("name", "Stage"))


func _on_upgrade_selected(upgrade_type: int):
	get_tree().paused = false
	player.apply_upgrade(upgrade_type)
	var lv = player.get_weapon_level(upgrade_type)
	EventBus.weapon_upgraded.emit(upgrade_type, lv)
	_level_up_screen.hide_screen()


func _on_evolution_selected(weapon_type: int):
	get_tree().paused = false
	player.evolve_weapon(weapon_type)
	EventBus.item_evolved.emit(weapon_type)
	_level_up_screen.hide_screen()


func _on_gold_selected(amount: int):
	get_tree().paused = false
	PowerUpManager.add_run_gold(amount)
	_level_up_screen.hide_screen()


# ═══════════════════════════════════════════════════════════
#  ARCANA UI
# ═══════════════════════════════════════════════════════════

func _show_arcana_first_pick():
	if ArcanaManager.get_unlocked_count() <= 0:
		return
	get_tree().paused = true
	_get_arcana_choice_screen().show_choices(true)


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
	_get_arcana_choice_screen().show_choices(false, available)


func _on_arcana_selected(arcana_id: int):
	get_tree().paused = false
	_show_boss_announcement(I18N.t("arcana.equipped") % I18N.t("arcana." + str(arcana_id) + "_name", DataRegistry.arcanas().get_arcana(arcana_id)["name"]))
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
	if game_state.game_over or game_state.stage_complete or _level_up_screen.visible:
		return
	var new_paused = not get_tree().paused
	get_tree().paused = new_paused
	_get_pause_overlay().visible = new_paused


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

func _get_pause_overlay():
	if not _pause_overlay:
		_pause_overlay = preload("res://scenes/pause_overlay.tscn").instantiate()
		_ui_layer.add_child(_pause_overlay)
		_pause_overlay.toggle_pause.connect(_toggle_pause)
		_pause_overlay.quit_to_menu.connect(_on_quit_to_menu)
	return _pause_overlay


func _get_arcana_choice_screen():
	if not _arcana_choice_screen:
		_arcana_choice_screen = Control.new()
		_arcana_choice_screen.name = "ArcanaChoiceScreen"
		_arcana_choice_screen.set_script(preload("res://scripts/ui/arcana_choice_screen.gd"))
		_ui_layer.add_child(_arcana_choice_screen)
		_arcana_choice_screen.arcana_selected.connect(_on_arcana_selected)
	return _arcana_choice_screen


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

func get_map_prop(key: String):
	match key:
		"map_width": return game_state.map_width if game_state else 3200.0
		"map_height": return game_state.map_height if game_state else 2400.0
	return null
