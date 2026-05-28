extends Node2D

const StageDefs = preload("res://scripts/data/stage_defs.gd")
const Prop = preload("res://scripts/entities/prop.gd")
const EnemyDefs = preload("res://scripts/data/enemy_defs.gd")

var player
var hud: Control
var minimap: Control
var level_up_screen: Control
var pause_overlay: Control
var game_time: float = 0.0
var game_over: bool = false
var stage_complete: bool = false
var total_kills: int = 0
var difficulty: float = 1.0
var spawn_timer: Timer

# Stage data
var stage_data: Dictionary = {}
var stage_time_limit: float = 1800.0
var stage_enemy_speed_mod: float = 1.0
var map_width: float = 3200.0
var map_height: float = 2400.0

# Obstacle positions for minimap
var _obstacle_positions: Array[Vector2] = []

# Camera
var _camera: Camera2D

# Boss state
var _boss_spawned: bool = false

# Camera shake
var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0

var _player_scene = preload("res://scenes/player.tscn")
var _enemy_scene = preload("res://scenes/enemy.tscn")
var _gem_scene = preload("res://scenes/xp_gem.tscn")
var _pickup_scene = preload("res://scenes/pickup.tscn")


func _ready():
	# Read stage data from Engine metadata (set by stage_select)
	if Engine.has_meta("selected_stage"):
		stage_data = Engine.get_meta("selected_stage")
	else:
		stage_data = StageDefs.get_stage(0)
	
	stage_time_limit = stage_data.get("time_limit", 1800.0)
	stage_enemy_speed_mod = stage_data.get("enemy_speed_mod", 1.0)
	map_width = stage_data.get("map_width", 3200.0)
	map_height = stage_data.get("map_height", 2400.0)
	
	# Apply stage modifiers so enemies can read them
	Engine.set_meta("stage_enemy_speed_mod", stage_enemy_speed_mod)

	# Build the large scrolling map (background + props)
	_setup_map()

	# ── UI layer (stays on-screen regardless of camera) ──
	var ui_layer = CanvasLayer.new()
	ui_layer.layer = 1
	add_child(ui_layer)

	hud = Control.new()
	hud.name = "HUD"
	hud.set_script(preload("res://scripts/ui/hud.gd"))
	ui_layer.add_child(hud)
	hud.set_time_limit(stage_time_limit)

	minimap = Control.new()
	minimap.name = "Minimap"
	minimap.set_script(preload("res://scripts/ui/minimap.gd"))
	ui_layer.add_child(minimap)
	minimap.set_map_size(map_width, map_height)
	minimap.set_obstacles(_obstacle_positions)

	level_up_screen = Control.new()
	level_up_screen.name = "LevelUpScreen"
	level_up_screen.set_script(preload("res://scripts/ui/level_up_screen.gd"))
	ui_layer.add_child(level_up_screen)

	pause_overlay = preload("res://scenes/pause_overlay.tscn").instantiate()
	ui_layer.add_child(pause_overlay)
	pause_overlay.toggle_pause.connect(_toggle_pause)
	pause_overlay.quit_to_menu.connect(_on_quit_to_menu)

	# ── Player ──
	player = _player_scene.instantiate()
	player.leveled_up.connect(_on_player_leveled_up)
	player.died.connect(_on_player_died)
	player.hurt.connect(_on_player_hurt)
	add_child(player)

	# ── Camera (sibling of player, follows in _process) ──
	_camera = Camera2D.new()
	_camera.name = "PlayerCamera"
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	_camera.limit_left = -map_width / 2.0
	_camera.limit_right = map_width / 2.0
	_camera.limit_top = -map_height / 2.0
	_camera.limit_bottom = map_height / 2.0
	add_child(_camera)

	# ── Connections ──
	level_up_screen.upgrade_selected.connect(_on_upgrade_selected)
	level_up_screen.evolution_selected.connect(_on_evolution_selected)

	# ── Timers ──
	spawn_timer = Timer.new()
	spawn_timer.wait_time = stage_data.get("spawn_base_interval", 2.0)
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_spawn_wave)
	add_child(spawn_timer)

	var pickup_timer = Timer.new()
	pickup_timer.wait_time = 18.0
	pickup_timer.autostart = true
	pickup_timer.timeout.connect(_spawn_pickup)
	add_child(pickup_timer)

	# Reset run gold & start music
	PowerUpManager.reset_run_gold()
	call_deferred("start_game_music")


# ═══════════════════════════════════════════════════════════
#  MAP SETUP
# ═══════════════════════════════════════════════════════════

func _setup_map():
	var bg_color = stage_data.get("bg_color", Color(0.04, 0.04, 0.10))
	var hw = map_width / 2.0
	var hh = map_height / 2.0
	var stage_id = stage_data.get("id", 0)

	# Background
	var bg = ColorRect.new()
	bg.color = bg_color
	bg.position = Vector2(-hw, -hh)
	bg.size = Vector2(map_width, map_height)
	bg.z_index = -100
	add_child(bg)

	# Stage-specific decorations + props
	match stage_id:
		0:  # Mad Forest — trees, rocks, graves, bushes
			_generate_props(0.0020, stage_id, hw, hh)
		1:  # Inlaid Library — wall strips, floor lines, bookshelves, pillars
			_setup_library_decor(hw, hh)
			_generate_props(0.0015, stage_id, hw, hh)
		2:  # Il Molise — meadow with trees, flowers, fences
			_setup_meadow_flowers(hw, hh)
			_generate_props(0.0010, stage_id, hw, hh)

	# Boundary collision walls
	var wall_thick = 60.0
	_add_boundary_wall(Vector2(0, -hh - wall_thick / 2.0), Vector2(map_width + wall_thick * 2, wall_thick))
	_add_boundary_wall(Vector2(0, hh + wall_thick / 2.0), Vector2(map_width + wall_thick * 2, wall_thick))
	_add_boundary_wall(Vector2(-hw - wall_thick / 2.0, 0), Vector2(wall_thick, map_height))
	_add_boundary_wall(Vector2(hw + wall_thick / 2.0, 0), Vector2(wall_thick, map_height))


func _setup_library_decor(hw: float, hh: float):
	var wall_color = Color(0.12, 0.03, 0.18)
	var strip_w = 40.0
	# Left wall strip
	var l = ColorRect.new()
	l.color = wall_color
	l.position = Vector2(-hw, -hh)
	l.size = Vector2(strip_w, map_height)
	l.z_index = -50
	add_child(l)
	# Right wall strip
	var r = ColorRect.new()
	r.color = wall_color
	r.position = Vector2(hw - strip_w, -hh)
	r.size = Vector2(strip_w, map_height)
	r.z_index = -50
	add_child(r)
	# Floor lines
	for y in range(-int(hh) + 80, int(hh), 120):
		var line = ColorRect.new()
		line.color = Color(0.1, 0.02, 0.15, 0.3)
		line.position = Vector2(-hw + strip_w, y)
		line.size = Vector2(map_width - strip_w * 2, 2)
		line.z_index = -50
		add_child(line)


func _setup_meadow_flowers(hw: float, hh: float):
	for i in range(40):
		var flower = ColorRect.new()
		flower.position = Vector2(randf_range(-hw + 30, hw - 30), randf_range(-hh + 30, hh - 30))
		flower.size = Vector2(4, 4)
		flower.color = Color(
			randf_range(0.6, 1.0), randf_range(0.3, 0.9), randf_range(0.1, 0.5), 0.7
		)
		flower.z_index = -50
		add_child(flower)


func _generate_props(density: float, stage_id: int, hw: float, hh: float):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var margin = 80.0
	var clear_radius = 180.0  # keep area around player start clear
	var min_dist = 60.0       # minimum distance between props
	var target_count = int(map_width * map_height * density)
	target_count = clampi(target_count, 15, 80)
	var attempts = target_count * 5
	var placed = 0

	for _a in range(attempts):
		if placed >= target_count:
			break
		var x = rng.randf_range(-hw + margin, hw - margin)
		var y = rng.randf_range(-hh + margin, hh - margin)
		var pos = Vector2(x, y)

		# Keep player start area clear
		if pos.length() < clear_radius:
			continue
		# Keep distance from other props
		var too_close = false
		for ep in _obstacle_positions:
			if pos.distance_to(ep) < min_dist:
				too_close = true
				break
		if too_close:
			continue

		_obstacle_positions.append(pos)
		placed += 1

		# Pick a prop type based on stage
		match stage_id:
			0:  # Mad Forest
				_make_forest_prop(pos, rng)
			1:  # Inlaid Library
				_make_library_prop(pos, rng)
			2:  # Il Molise
				_make_meadow_prop(pos, rng)


func _make_forest_prop(pos: Vector2, rng: RandomNumberGenerator):
	var roll = rng.randf()
	if roll < 0.45:
		# Tree (large green circle)
		var r = rng.randf_range(12.0, 20.0)
		var shade = rng.randf_range(0.15, 0.35)
		_make_collision_prop(pos, r, Color(shade, shade + 0.35, shade + 0.05))
	elif roll < 0.70:
		# Rock (gray circle)
		var r = rng.randf_range(8.0, 14.0)
		var shade = rng.randf_range(0.25, 0.40)
		_make_collision_prop(pos, r, Color(shade + 0.1, shade, shade))
	elif roll < 0.85:
		# Grave (small brown rectangle)
		var w = rng.randf_range(8.0, 14.0)
		var h = rng.randf_range(14.0, 20.0)
		_make_rect_prop(pos, Vector2(w, h), Color(0.3, 0.2, 0.1))
	else:
		# Bush (small green circle, no collision)
		_make_decoration(pos, rng.randf_range(6.0, 10.0), Color(0.15, 0.5, 0.1))


func _make_library_prop(pos: Vector2, rng: RandomNumberGenerator):
	var roll = rng.randf()
	if roll < 0.50:
		# Bookshelf (brown rectangle)
		var w = rng.randf_range(24.0, 40.0)
		var h = rng.randf_range(10.0, 16.0)
		_make_rect_prop(pos, Vector2(w, h), Color(0.25, 0.15, 0.05))
	elif roll < 0.75:
		# Pillar (dark rectangle)
		var w = rng.randf_range(14.0, 18.0)
		var h = rng.randf_range(14.0, 18.0)
		_make_rect_prop(pos, Vector2(w, h), Color(0.1, 0.05, 0.12))
	elif roll < 0.90:
		# Table (brown rectangle, wider)
		var w = rng.randf_range(30.0, 50.0)
		var h = rng.randf_range(8.0, 12.0)
		_make_rect_prop(pos, Vector2(w, h), Color(0.2, 0.12, 0.06))
	else:
		# Candle (tiny orange circle, no collision)
		_make_decoration(pos, rng.randf_range(3.0, 5.0), Color(0.9, 0.6, 0.1))


func _make_meadow_prop(pos: Vector2, rng: RandomNumberGenerator):
	var roll = rng.randf()
	if roll < 0.40:
		# Tree (green circle)
		var r = rng.randf_range(10.0, 18.0)
		var shade = rng.randf_range(0.15, 0.35)
		_make_collision_prop(pos, r, Color(shade, shade + 0.4, shade + 0.05))
	elif roll < 0.60:
		# Fence post (brown thin rect)
		_make_rect_prop(pos, Vector2(6.0, 16.0), Color(0.3, 0.18, 0.08))
	elif roll < 0.80:
		# Hay bale (yellowish circle)
		var r = rng.randf_range(8.0, 14.0)
		_make_collision_prop(pos, r, Color(0.55, 0.50, 0.15))
	else:
		# Flower cluster (no collision)
		_make_decoration(pos, rng.randf_range(4.0, 7.0), Color(0.7, 0.3, 0.5))


func _make_collision_prop(pos: Vector2, radius: float, color: Color):
	var p = Prop.new()
	p.position = pos
	p.prop_color = color
	p.shape_type = "circle"
	p.shape_radius = radius
	p.outline_width = 2.0
	# Collision
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	p.add_child(shape)
	add_child(p)


func _make_rect_prop(pos: Vector2, size: Vector2, color: Color):
	var p = Prop.new()
	p.position = pos
	p.prop_color = color
	p.shape_type = "rect"
	p.rect_size = size
	p.outline_width = 2.0
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	p.add_child(shape)
	add_child(p)


func _make_decoration(pos: Vector2, radius: float, color: Color):
	# Decoration with circle, no collision — just visual
	var p = Prop.new()
	p.position = pos
	p.prop_color = color
	p.shape_type = "circle"
	p.shape_radius = radius
	p.outline_width = 0.0  # no outline for small decorations
	add_child(p)


func _add_boundary_wall(pos: Vector2, size: Vector2):
	var wall = StaticBody2D.new()
	wall.position = pos
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	wall.add_child(shape)
	add_child(wall)


# ═══════════════════════════════════════════════════════════
#  SPAWNING
# ═══════════════════════════════════════════════════════════

func _get_camera_bounds() -> Dictionary:
	var camera = get_viewport().get_camera_2d()
	if not camera:
		var vs = get_viewport_rect().size
		return {"left": -vs.x/2, "right": vs.x/2, "top": -vs.y/2, "bottom": vs.y/2}
	var cam_pos = camera.global_position
	var vs = get_viewport_rect().size
	return {
		"left": cam_pos.x - vs.x / 2.0,
		"right": cam_pos.x + vs.x / 2.0,
		"top": cam_pos.y - vs.y / 2.0,
		"bottom": cam_pos.y + vs.y / 2.0,
	}


func _clamp_to_map(pos: Vector2, margin: float = 40.0) -> Vector2:
	var hw = map_width / 2.0 - margin
	var hh = map_height / 2.0 - margin
	return Vector2(clamp(pos.x, -hw, hw), clamp(pos.y, -hh, hh))


func _process(delta):
	if game_over or stage_complete:
		return
	game_time += delta
	
	# Win condition
	if game_time >= stage_time_limit:
		_on_stage_complete()
		return
	
	# Difficulty ramping
	var ramp_time = stage_data.get("difficulty_ramp_time", 60.0)
	difficulty = 1.0 + game_time / ramp_time
	
	# Spawn interval
	var base_interval = stage_data.get("spawn_base_interval", 2.0)
	var min_interval = stage_data.get("spawn_min_interval", 0.3)
	var ramp_interval = stage_data.get("spawn_ramp_time", 30.0)
	spawn_timer.wait_time = max(min_interval, base_interval - game_time / ramp_interval)
	
	# Boss spawn check (at 15:00 for eligible stages)
	if not _boss_spawned and game_time >= 900.0:
		var boss_t = EnemyDefs.get_boss_type(stage_data.get("id", 0), game_time)
		if boss_t >= 0:
			_spawn_boss()
	
	# HUD
	hud.set_health(player.health, player.max_health)
	hud.set_xp(player.xp, player.xp_to_next)
	hud.set_level(player.level)
	hud.set_timer(game_time)
	hud.set_kills(total_kills)
	hud.set_gold(PowerUpManager.run_gold)
	
	# Weapon display data for HUD
	var wep_data: Array = []
	for w in player.weapons:
		wep_data.append({
			"name": _get_wep_name(w.type),
			"name_key": _get_wep_name_key(w.type),
			"level": w.level,
			"evolved": w.evolved,
			"color": _get_wep_color(w.type),
		})
	hud.set_weapons(wep_data)
	
	# Camera follows player with shake offset
	if _camera:
		var shake_off = Vector2.ZERO
		if _shake_duration > 0.0:
			_shake_duration -= delta
			shake_off = Vector2(randf_range(-_shake_intensity, _shake_intensity), randf_range(-_shake_intensity, _shake_intensity))
		_camera.global_position = player.global_position + shake_off
	
	# Minimap
	var vs = get_viewport_rect().size
	minimap.set_player_pos(player.global_position)
	minimap.set_camera_view(_camera.global_position if _camera else Vector2.ZERO, vs)


func _spawn_wave():
	if game_over or stage_complete:
		return
	var wave_interval = stage_data.get("wave_size_interval", 30.0)
	var count = 1 + int(game_time / wave_interval)
	if stage_data.get("id", 0) == 2:
		count = count * 2 + 1
	
	# Get available enemy types for this stage + game time
	var type_pool = EnemyDefs.get_types_for_stage(stage_data.get("id", 0), game_time)
	if type_pool.is_empty():
		type_pool = [0]
	
	# Spawn a mix of types — bias toward more dangerous types as time goes on
	var time_bias = min(game_time / 600.0, 1.0)  # 0→1 over 10 min
	for i in count:
		var type_idx: int
		if type_pool.size() == 1:
			type_idx = type_pool[0]
		else:
			# Weighted: sometimes pick hardest available, sometimes random
			if randf() < time_bias * 0.4 and type_pool.size() > 1:
				type_idx = type_pool[randi() % max(type_pool.size() - 1, 1) + 1]
			else:
				type_idx = type_pool[randi() % type_pool.size()]
		_spawn_enemy(type_idx)


func _spawn_enemy(type_id: int = 0):
	var enemy = _enemy_scene.instantiate()
	enemy.player = player
	enemy.set_enemy_type(type_id, difficulty)
	
	var cam = _get_camera_bounds()
	var margin = 60.0
	var pos: Vector2
	match randi() % 4:
		0:  pos = Vector2(randf_range(cam.left + margin, cam.right - margin), cam.top - margin)
		1:  pos = Vector2(randf_range(cam.left + margin, cam.right - margin), cam.bottom + margin)
		2:  pos = Vector2(cam.left - margin, randf_range(cam.top + margin, cam.bottom - margin))
		3:  pos = Vector2(cam.right + margin, randf_range(cam.top + margin, cam.bottom - margin))
	
	enemy.global_position = _clamp_to_map(pos, 10.0)
	enemy.died.connect(_on_enemy_died.bind(enemy))
	add_child(enemy)


func _spawn_boss():
	if _boss_spawned:
		return
	_boss_spawned = true
	var boss_type = EnemyDefs.get_boss_type(stage_data.get("id", 0), game_time)
	if boss_type < 0:
		return
	
	var enemy = _enemy_scene.instantiate()
	enemy.player = player
	enemy.set_enemy_type(boss_type, difficulty)
	
	# Boss spawns closer — just off-screen
	var cam = _get_camera_bounds()
	var margin = 80.0
	var pos: Vector2
	match randi() % 4:
		0:  pos = Vector2(0, cam.top - margin)
		1:  pos = Vector2(0, cam.bottom + margin)
		2:  pos = Vector2(cam.left - margin, 0)
		3:  pos = Vector2(cam.right + margin, 0)
	enemy.global_position = _clamp_to_map(pos, 20.0)
	enemy.died.connect(_on_enemy_died.bind(enemy))
	add_child(enemy)
	
	# Announce boss
	_show_boss_announcement(I18N.t("boss.announce"))


# Creates a simple text Label that fades out — no HUD dependency
func _shake_camera(intensity: float, duration: float):
	_shake_intensity = intensity
	_shake_duration = duration


func _show_boss_announcement(text: String):
	# Also trigger camera shake
	_shake_camera(8.0, 1.0)
	
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.9, 0.15, 0.1))
	label.add_theme_font_size_override("font_size", 30)
	label.position = Vector2(
		get_viewport_rect().size.x / 2.0 - 150,
		get_viewport_rect().size.y * 0.15
	)
	# Add to the UI layer (first CanvasLayer child)
	for c in get_children():
		if c is CanvasLayer:
			c.add_child(label)
			break
	
	# Animate: stay 1.5s, then fade out over 1.0s
	var tw = create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(label, "modulate", Color(1, 1, 1, 0), 1.0)
	tw.finished.connect(label.queue_free)


func _spawn_pickup_at(pos: Vector2, pickup_type: int = -1):
	var pickup = _pickup_scene.instantiate()
	pickup.player = player
	pickup.type = pickup_type if pickup_type >= 0 else randi() % 4
	pickup.global_position = _clamp_to_map(pos, 20.0)
	call_deferred("add_child", pickup)


func _spawn_pickup():
	var cam = _get_camera_bounds()
	var margin = 60.0
	var pos = Vector2(
		randf_range(cam.left + margin, cam.right - margin),
		randf_range(cam.top + margin, cam.bottom - margin)
	)
	_spawn_pickup_at(pos)


func _on_enemy_died(enemy: Node2D):
	if not is_instance_valid(enemy):
		return
	total_kills += 1
	
	# Check if it was a boss
	var is_boss = enemy.has_method("get_is_boss") and enemy.get_is_boss()
	
	# Drop XP gem(s)
	if is_boss:
		# Boss drops several large XP gems
		for i in range(8):
			var gem = _gem_scene.instantiate()
			gem.value = max(enemy.xp_value / 4, 5)
			gem.player = player
			gem.global_position = enemy.global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
			call_deferred("add_child", gem)
		# Boss always drops gold (type 1 = GOLD)
		for i in range(3):
			_spawn_pickup_at(enemy.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20)),
				1 if i == 0 else -1)  # 1 = GOLD
		# Boss always drops a chicken (type 0 = CHICKEN)
		_spawn_pickup_at(enemy.global_position, 0)
	else:
		var gem = _gem_scene.instantiate()
		gem.value = enemy.xp_value
		gem.player = player
		gem.global_position = enemy.global_position
		call_deferred("add_child", gem)
		if randf() < 0.04:
			_spawn_pickup_at(enemy.global_position)


# ═══════════════════════════════════════════════════════════
#  GAME FLOW EVENTS
# ═══════════════════════════════════════════════════════════

func _on_player_leveled_up():
	get_tree().paused = true
	level_up_screen.show_choices(player)


func _on_player_hurt():
	_shake_camera(4.0, 0.15)


func _on_player_died():
	game_over = true
	_shake_camera(12.0, 0.5)
	get_tree().paused = false
	AudioManager.stop_bgm()
	AudioManager.play_sfx("game_over")
	PowerUpManager.end_run(true)
	# Hide overlays that might be intercepting input
	level_up_screen.hide_screen()
	pause_overlay.visible = false
	hud.show_game_over(game_time, total_kills, player.level)


func _on_stage_complete():
	stage_complete = true
	AudioManager.stop_bgm()
	AudioManager.play_sfx("evolution")
	
	# Unlock next stage
	var stage_id = stage_data.get("id", 0)
	PowerUpManager.unlock_next_stage(stage_id)
	
	var gold_bonus = 500
	var total_gold = PowerUpManager.run_gold + gold_bonus
	PowerUpManager.add_run_gold(gold_bonus)
	PowerUpManager.end_run(true)
	PowerUpManager.run_gold = total_gold
	get_tree().paused = true
	# Hide overlays that might be intercepting input
	level_up_screen.hide_screen()
	pause_overlay.visible = false
	hud.show_stage_complete(game_time, total_kills, player.level, stage_data.get("name", "Stage"))


func _on_upgrade_selected(upgrade_type: int):
	get_tree().paused = false
	player.apply_upgrade(upgrade_type)
	level_up_screen.hide_screen()


func _on_evolution_selected(weapon_type: int):
	get_tree().paused = false
	player.evolve_weapon(weapon_type)
	level_up_screen.hide_screen()


func start_game_music():
	if AudioManager and AudioManager.has_method("play_bgm"):
		AudioManager.stop_bgm()
		AudioManager.play_bgm(AudioManager.sounds.get("bgm_game"))


func _get_wep_name(type: int) -> String:
	match type:
		0: return "Whip"
		1: return "Magic Wand"
		2: return "Garlic"
		10: return "Knife"
		11: return "Axe"
		12: return "Fire Wand"
	return "?" + str(type)


func _get_wep_name_key(type: int) -> String:
	match type:
		0: return "wpn.whip"
		1: return "wpn.wand"
		2: return "wpn.garlic"
		10: return "wpn.knife"
		11: return "wpn.axe"
		12: return "wpn.firewand"
	return "wpn.whip"


func _get_wep_color(type: int) -> Color:
	match type:
		0: return Color(0.8, 0.6, 0.3)
		1: return Color(0.3, 0.5, 1.0)
		2: return Color(0.6, 0.2, 0.8)
		10: return Color(0.7, 0.7, 0.7)
		11: return Color(0.6, 0.3, 0.1)
		12: return Color(0.9, 0.4, 0.1)
	return Color.WHITE


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("fullscreen"):
		I18N.toggle_fullscreen()
		get_viewport().set_input_as_handled()


func _toggle_pause():
	if game_over or stage_complete or level_up_screen.visible:
		return
	var new_paused = not get_tree().paused
	get_tree().paused = new_paused
	pause_overlay.visible = new_paused


func _on_quit_to_menu():
	get_tree().paused = false
	PowerUpManager.end_run(true)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
