extends Node2D

const StageDefs = preload("res://scripts/data/stage_defs.gd")
const Prop = preload("res://scripts/entities/prop.gd")
const EnemyDefs = preload("res://scripts/data/enemy_defs.gd")
const RelicDefs = preload("res://scripts/data/relic_defs.gd")
const ArcanaDefs = preload("res://scripts/data/arcana_defs.gd")

# Map interactivity
const PropManager = preload("res://scripts/map/prop_manager.gd")
const BreakableWall = preload("res://scripts/map/breakable_wall.gd")
const TreasureChest = preload("res://scripts/map/treasure_chest.gd")
const HealingFountain = preload("res://scripts/map/healing_fountain.gd")
const HazardZone = preload("res://scripts/map/hazard_zone.gd")
const BoostZone = preload("res://scripts/map/boost_zone.gd")

var player
var hud
var level_up_screen
var pause_overlay
var game_time: float = 0.0
var game_over: bool = false
var stage_complete: bool = false
var total_kills: int = 0
var difficulty: float = 1.0
var _spawn_timer: float = 0.0

# Wave system
var wave_number: int = 0
var _wave_active: bool = false
var _wave_spawning: bool = false
var _wave_total: int = 0
var _wave_spawned: int = 0
var _wave_alive: int = 0
var _wave_spawn_timer: float = 0.0
var _wave_break_timer: float = 0.0

# Stage data
var stage_data: Dictionary = {}
var stage_time_limit: float = 1800.0
var stage_enemy_speed_mod: float = 1.0
var map_width: float = 3200.0
var map_height: float = 2400.0

# Cached stage data lookups (avoid .get() every frame)
var _stage_id: int = 0
var _diff_ramp_time: float = 60.0
var _spawn_base_interval: float = 1.0
var _spawn_min_interval: float = 0.15

# Obstacle positions for minimap
var _obstacle_positions: Array[Vector2] = []

# Camera
var _camera: Camera2D
var _camera_offset: Vector2 = Vector2.ZERO

# Boss state
var _boss_spawned: bool = false

# Relic state
var _stage_relics: Array = []  # relic pickups on this stage
var _relic_arrow_target: Vector2 = Vector2.ZERO
var _has_relic_arrow: bool = false

# Camera shake
var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0

# HUD data cache — avoid rebuilding every frame when nothing changed
var _hud_weapon_cache: Array = []
var _hud_passive_cache: Array = []
var _hud_last_level: int = -1
var _hud_last_kills: int = -1
var _hud_last_gold: int = -1
var _hud_last_wave: int = -1
var _hud_last_xp: int = -1
var _hud_last_xp_to_next: int = -1
var _frame_count: int = 0

# Cached values for per-frame hot paths
var _last_speed_mult: float = -1.0
var _cached_vp_size: Vector2 = Vector2.ZERO

var _player_scene = preload("res://scenes/player.tscn")
var _enemy_scene = preload("res://scenes/enemy.tscn")
# _gem_scene removed — using GemPool.borrow()
var _pickup_scene = preload("res://scenes/pickup.tscn")
var _relic_scene = preload("res://scenes/relic_pickup.tscn")
var _arcana_choice_screen_scene = preload("res://scripts/ui/arcana_choice_screen.gd")
var _arcana_choice_screen: Control
var _arcana_boss_spawned_11: bool = false
var _arcana_boss_spawned_21: bool = false
var _arcana_active_count: int = 0
var _map_ready: bool = false

# Map interactivity
var prop_manager: Node = null
var _interact_prompt: Label = null


func _ready():
	# Read stage data from Engine metadata (set by stage_select)
	if Engine.has_meta("selected_stage"):
		stage_data = Engine.get_meta("selected_stage")
	else:
		stage_data = StageDefs.get_stage(0)
	
	_stage_id = stage_data.get("id", 0)
	_diff_ramp_time = stage_data.get("difficulty_ramp_time", 60.0)
	_spawn_base_interval = stage_data.get("spawn_base_interval", 1.0)
	_spawn_min_interval = stage_data.get("spawn_min_interval", 0.15)
	
	stage_time_limit = stage_data.get("time_limit", 1800.0)
	# Endless mode removes time limit
	if Engine.has_meta("endless_mode") and Engine.get_meta("endless_mode"):
		stage_time_limit = INF
	
	stage_enemy_speed_mod = stage_data.get("enemy_speed_mod", 1.0)
	# Hurry mode multiplies enemy speed by 1.5
	var hurry = Engine.has_meta("hurry_mode") and Engine.get_meta("hurry_mode")
	if hurry:
		stage_enemy_speed_mod *= 1.5
	
	# Hyper mode: boost modifiers if unlocked and selected
	var hyper = Engine.has_meta("hyper_mode") and Engine.get_meta("hyper_mode")
	var hyper_mods = stage_data.get("hyper_mods", {})
	if hyper:
		stage_enemy_speed_mod += hyper_mods.get("enemy_speed_bonus", 0.0)
	
	# Player move speed modifier (combined base + hyper)
	var move_speed_base = stage_data.get("move_speed_mod", 1.0)
	if hyper:
		move_speed_base += hyper_mods.get("move_speed_bonus", 0.0)
	Engine.set_meta("stage_move_speed_mod", move_speed_base)
	
	# Gold modifier
	var gold_mod = stage_data.get("gold_mod", 1.0)
	if hyper:
		gold_mod *= hyper_mods.get("gold_mult", 1.0)
	Engine.set_meta("stage_gold_mod", gold_mod)
	
	# Enemy HP modifier
	var enemy_hp_mod = stage_data.get("enemy_hp_mod", 1.0)
	if hyper:
		enemy_hp_mod += hyper_mods.get("enemy_hp_bonus", 0.0)
	Engine.set_meta("stage_enemy_hp_mod", enemy_hp_mod)
	
	map_width = stage_data.get("map_width", 3200.0)
	map_height = stage_data.get("map_height", 2400.0)
	
	# Apply stage modifiers so enemies can read them
	Engine.set_meta("stage_enemy_speed_mod", stage_enemy_speed_mod)
	Engine.set_meta("stage_speed_mult", 1.5 if hurry else 1.0)

	# ── UI layer (stays on-screen regardless of camera) ──
	var ui_layer = CanvasLayer.new()
	ui_layer.layer = 1
	add_child(ui_layer)

	hud = preload("res://scenes/hud.tscn").instantiate()
	hud.name = "HUD"
	ui_layer.add_child(hud)
	hud.set_time_limit(stage_time_limit)

	# Minimap is now shown inside the pause overlay (requires Milky Way Map relic)

	level_up_screen = Control.new()
	level_up_screen.name = "LevelUpScreen"
	level_up_screen.set_script(preload("res://scripts/ui/level_up_screen.gd"))
	ui_layer.add_child(level_up_screen)

	# ── Arcana Choice Screen (hidden until needed) ──
	_arcana_choice_screen = Control.new()
	_arcana_choice_screen.name = "ArcanaChoiceScreen"
	_arcana_choice_screen.set_script(_arcana_choice_screen_scene)
	ui_layer.add_child(_arcana_choice_screen)
	_arcana_choice_screen.arcana_selected.connect(_on_arcana_selected)

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

	# Camera offset to show more above the player
	_camera_offset = Vector2(0, -80)

	# ── Spawn uncollected relics for this stage (player must exist) ──
	_spawn_stage_relics()

	# ── Spawn pre-placed stage items (passives/weapons on the map) ──
	_spawn_stage_items()

	# ── Connections ──
	level_up_screen.upgrade_selected.connect(_on_upgrade_selected)
	level_up_screen.evolution_selected.connect(_on_evolution_selected)
	level_up_screen.gold_selected.connect(_on_gold_selected)

	# ── Continuous spawning starts after map is ready ──
	_spawn_timer = 1.0
	
	# ── Wave system init ──
	_wave_break_timer = 15.0  # first wave at 15s

	# pickup_timer removed — floor chicken spawn was too generous

	# Reset run gold & start music
	PowerUpManager.reset_run_gold()
	UnlockManager.reset_run_state()
	ArcanaManager.deactivate_all()
	call_deferred("start_game_music")

	# Auto-check relic-based unlocks at game start
	if RelicManager.has_relic("randomazzo"):
		UnlockManager.on_relic_collected("randomazzo")

	# ── Interaction prompt label (below center of screen) ──
	_interact_prompt = Label.new()
	_interact_prompt.name = "InteractPrompt"
	_interact_prompt.visible = false
	_interact_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interact_prompt.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	_interact_prompt.add_theme_font_size_override("font_size", 16)
	_interact_prompt.add_theme_constant_override("outline_size", 4)
	_interact_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	ui_layer.add_child(_interact_prompt)

	# Defer heavy map generation — _setup_map builds bg + decorations + props + walls
	call_deferred("_setup_map")

	# Show Arcana first pick if enabled
	var arcanas_enabled = Engine.has_meta("arcanas_enabled") and Engine.get_meta("arcanas_enabled")
	if arcanas_enabled and ArcanaManager.is_system_enabled() and ArcanaManager.get_unlocked_count() > 0:
		call_deferred("_show_arcana_first_pick")

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
		3:  # Dairy Plant — conveyor belts, vats, crates, pipes
			_setup_factory_decor(hw, hh)
			_generate_props(0.0018, stage_id, hw, hh)
		4:  # Gallo Tower — floor strips, spiral stairs, arcane circles
			_setup_tower_decor(hw, hh)
			_generate_props(0.0012, stage_id, hw, hh)
		5:  # Cappella Magna — stained glass, pillars, altar platforms
			_setup_chapel_decor(hw, hh)
			_generate_props(0.0015, stage_id, hw, hh)
		6:  # Moongolow — flooded ruins
			_setup_moongolow_decor(hw, hh)
			_generate_props(0.0015, stage_id, hw, hh)
		7:  # Green Acres — open meadow, random
			_generate_props(0.0020, stage_id, hw, hh)
		8:  # The Bone Zone — skeletal remains
			_setup_bone_decor(hw, hh)
			_generate_props(0.0018, stage_id, hw, hh)
		9:  # Boss Rash — arena
			_setup_arena_decor(hw, hh)
		10: # Whiteout — snow, ice
			_setup_whiteout_decor(hw, hh)
			_generate_props(0.0015, stage_id, hw, hh)
		11: # The Lycaeum — underwater school
			_setup_lycaeum_decor(hw, hh)
			_generate_props(0.0015, stage_id, hw, hh)
		12: # The Coop — farm
			_setup_coop_decor(hw, hh)
			_generate_props(0.0020, stage_id, hw, hh)
		13: # Space 54 — cosmic void
			_setup_space_decor(hw, hh)
			_generate_props(0.0012, stage_id, hw, hh)
		14: # Bat Country — dark caves
			_setup_bat_decor(hw, hh)
			_generate_props(0.0018, stage_id, hw, hh)
		15: # Eudaimonia Machine — white void
			_setup_eudaimonia_decor(hw, hh)

	# Boundary collision walls
	var wall_thick = 60.0
	_add_boundary_wall(Vector2(0, -hh - wall_thick / 2.0), Vector2(map_width + wall_thick * 2, wall_thick))
	_add_boundary_wall(Vector2(0, hh + wall_thick / 2.0), Vector2(map_width + wall_thick * 2, wall_thick))
	_add_boundary_wall(Vector2(-hw - wall_thick / 2.0, 0), Vector2(wall_thick, map_height))
	_add_boundary_wall(Vector2(hw + wall_thick / 2.0, 0), Vector2(wall_thick, map_height))

	# ── Interactive map elements ──
	prop_manager = PropManager.new()
	prop_manager.name = "PropManager"
	prop_manager.setup(self)
	add_child(prop_manager)

	var interactables = stage_data.get("interactables", {})
	_spawn_interactive_elements(interactables, hw, hh)

	# Scatter initial pickups around the map
	_spawn_initial_pickups(hw, hh)

	_map_ready = true


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


# ═══════════════════════════════════════════════════════════
#  Stage 3 — Dairy Plant décor
# ═══════════════════════════════════════════════════════════

func _setup_factory_decor(hw: float, hh: float):
	var wall_color = Color(0.12, 0.08, 0.18)
	var strip_w = 30.0
	# Left wall
	var l = ColorRect.new()
	l.color = wall_color
	l.position = Vector2(-hw, -hh)
	l.size = Vector2(strip_w, map_height)
	l.z_index = -50
	add_child(l)
	# Right wall
	var r = ColorRect.new()
	r.color = wall_color
	r.position = Vector2(hw - strip_w, -hh)
	r.size = Vector2(strip_w, map_height)
	r.z_index = -50
	add_child(r)
	# Conveyor belt lines (horizontal stripes at regular intervals)
	for y in range(-int(hh) + 60, int(hh), 80):
		var belt = ColorRect.new()
		belt.color = Color(0.15, 0.1, 0.22, 0.3)
		belt.position = Vector2(-hw + strip_w, y)
		belt.size = Vector2(map_width - strip_w * 2, 3)
		belt.z_index = -50
		add_child(belt)
	# Vat circles (decorative, no collision)
	for i in range(6):
		var vx = randf_range(-hw + 80, hw - 80)
		var vy = randf_range(-hh + 80, hh - 80)
		var vat = ColorRect.new()
		vat.position = Vector2(vx, vy)
		vat.size = Vector2(24, 24)
		vat.color = Color(0.2, 0.15, 0.3, 0.25)
		vat.z_index = -50
		add_child(vat)


# ═══════════════════════════════════════════════════════════
#  Stage 4 — Gallo Tower décor
# ═══════════════════════════════════════════════════════════

func _setup_tower_decor(hw: float, hh: float):
	var wall_color = Color(0.15, 0.03, 0.2)
	var strip_w = 35.0
	# Left wall
	var l = ColorRect.new()
	l.color = wall_color
	l.position = Vector2(-hw, -hh)
	l.size = Vector2(strip_w, map_height)
	l.z_index = -50
	add_child(l)
	# Right wall
	var r = ColorRect.new()
	r.color = wall_color
	r.position = Vector2(hw - strip_w, -hh)
	r.size = Vector2(strip_w, map_height)
	r.z_index = -50
	add_child(r)
	# Floor lines (horizontal every 100px)
	for y in range(-int(hh) + 50, int(hh), 100):
		var line = ColorRect.new()
		line.color = Color(0.2, 0.05, 0.25, 0.3)
		line.position = Vector2(-hw + strip_w, y)
		line.size = Vector2(map_width - strip_w * 2, 2)
		line.z_index = -50
		add_child(line)
	# Arcane circles (decorative)
	for i in range(4):
		var ax = randf_range(-hw + 60, hw - 60)
		var ay = randf_range(-hh + 60, hh - 60)
		var circle = ColorRect.new()
		circle.position = Vector2(ax, ay)
		circle.size = Vector2(16, 16)
		circle.color = Color(0.5, 0.1, 0.6, 0.15)
		circle.z_index = -50
		add_child(circle)


# ═══════════════════════════════════════════════════════════
#  Stage 5 — Cappella Magna décor
# ═══════════════════════════════════════════════════════════

func _setup_chapel_decor(hw: float, hh: float):
	var wall_color = Color(0.2, 0.05, 0.08)
	var strip_w = 40.0
	# Left wall
	var l = ColorRect.new()
	l.color = wall_color
	l.position = Vector2(-hw, -hh)
	l.size = Vector2(strip_w, map_height)
	l.z_index = -50
	add_child(l)
	# Right wall
	var r = ColorRect.new()
	r.color = wall_color
	r.position = Vector2(hw - strip_w, -hh)
	r.size = Vector2(strip_w, map_height)
	r.z_index = -50
	add_child(r)
	# Stained glass patches (colored rectangles)
	var glass_colors = [Color(0.8, 0.2, 0.2, 0.2), Color(0.2, 0.4, 0.8, 0.2), Color(0.8, 0.8, 0.2, 0.2)]
	for i in range(6):
		var gx = randf_range(-hw + 60, hw - 60)
		var gy = randf_range(-hh + 60, hh - 60)
		var glass = ColorRect.new()
		glass.position = Vector2(gx, gy)
		glass.size = Vector2(30, 40)
		glass.color = glass_colors[i % glass_colors.size()]
		glass.z_index = -50
		add_child(glass)
	# Altar platform (center)
	var altar = ColorRect.new()
	altar.color = Color(0.4, 0.15, 0.1, 0.3)
	altar.position = Vector2(-40, -40)
	altar.size = Vector2(80, 80)
	altar.z_index = -50
	add_child(altar)


# ═══════════════════════════════════════════════════════════
#  Stage 6 — Moongolow décor (flooded ruins)
# ═══════════════════════════════════════════════════════════

func _setup_moongolow_decor(hw: float, hh: float):
	for i in range(12):
		var rx = randf_range(-hw + 40, hw - 40)
		var ry = randf_range(-hh + 40, hh - 40)
		var rubble = ColorRect.new()
		rubble.position = Vector2(rx, ry)
		rubble.size = Vector2(randf_range(10, 25), randf_range(8, 16))
		rubble.color = Color(0.15, 0.12, 0.2, randf_range(0.3, 0.6))
		rubble.z_index = -50
		add_child(rubble)


# ═══════════════════════════════════════════════════════════
#  Stage 8 — The Bone Zone décor
# ═══════════════════════════════════════════════════════════

func _setup_bone_decor(hw: float, hh: float):
	for i in range(15):
		var bx = randf_range(-hw + 40, hw - 40)
		var by = randf_range(-hh + 40, hh - 40)
		var bone = ColorRect.new()
		bone.position = Vector2(bx, by)
		bone.size = Vector2(randf_range(6, 14), randf_range(2, 4))
		bone.color = Color(0.3, 0.25, 0.2, 0.5)
		bone.z_index = -50
		add_child(bone)


# ═══════════════════════════════════════════════════════════
#  Stage 9 — Boss Rash arena
# ═══════════════════════════════════════════════════════════

func _setup_arena_decor(hw: float, hh: float):
	# Arena border glow
	var border = ColorRect.new()
	border.color = Color(0.5, 0.05, 0.05, 0.15)
	border.position = Vector2(-hw + 20, -hh + 20)
	border.size = Vector2(map_width - 40, map_height - 40)
	border.z_index = -50
	add_child(border)


# ═══════════════════════════════════════════════════════════
#  Stage 10 — Whiteout décor (snow/ice)
# ═══════════════════════════════════════════════════════════

func _setup_whiteout_decor(hw: float, hh: float):
	for i in range(20):
		var sx = randf_range(-hw + 40, hw - 40)
		var sy = randf_range(-hh + 40, hh - 40)
		var snow = ColorRect.new()
		snow.position = Vector2(sx, sy)
		snow.size = Vector2(randf_range(8, 20), randf_range(8, 20))
		snow.color = Color(0.5, 0.5, 0.6, randf_range(0.1, 0.25))
		snow.z_index = -50
		add_child(snow)


# ═══════════════════════════════════════════════════════════
#  Stage 11 — The Lycaeum décor (underwater)
# ═══════════════════════════════════════════════════════════

func _setup_lycaeum_decor(hw: float, hh: float):
	for i in range(10):
		var wx = randf_range(-hw + 40, hw - 40)
		var wy = randf_range(-hh + 40, hh - 40)
		var weed = ColorRect.new()
		weed.position = Vector2(wx, wy)
		weed.size = Vector2(4, randf_range(10, 20))
		weed.color = Color(0.1, 0.4, 0.3, 0.3)
		weed.z_index = -50
		add_child(weed)


# ═══════════════════════════════════════════════════════════
#  Stage 12 — The Coop décor (farm fences)
# ═══════════════════════════════════════════════════════════

func _setup_coop_decor(hw: float, hh: float):
	for i in range(16):
		var fx = randf_range(-hw + 40, hw - 40)
		var fy = randf_range(-hh + 40, hh - 40)
		var fence = ColorRect.new()
		fence.position = Vector2(fx, fy)
		fence.size = Vector2(6, randf_range(12, 20))
		fence.color = Color(0.3, 0.2, 0.1, 0.4)
		fence.z_index = -50
		add_child(fence)


# ═══════════════════════════════════════════════════════════
#  Stage 13 — Space 54 décor (stars + cosmic)
# ═══════════════════════════════════════════════════════════

func _setup_space_decor(hw: float, hh: float):
	for i in range(25):
		var sx = randf_range(-hw + 40, hw - 40)
		var sy = randf_range(-hh + 40, hh - 40)
		var star = ColorRect.new()
		star.position = Vector2(sx, sy)
		star.size = Vector2(2, 2)
		star.color = Color(0.8, 0.8, 1.0, randf_range(0.2, 0.6))
		star.z_index = -50
		add_child(star)


# ═══════════════════════════════════════════════════════════
#  Stage 14 — Bat Country décor (cave)
# ═══════════════════════════════════════════════════════════

func _setup_bat_decor(hw: float, hh: float):
	for i in range(12):
		var cx = randf_range(-hw + 40, hw - 40)
		var cy = randf_range(-hh + 40, hh - 40)
		var crystal = ColorRect.new()
		crystal.position = Vector2(cx, cy)
		crystal.size = Vector2(randf_range(4, 10), randf_range(6, 14))
		crystal.color = Color(0.3, 0.1, 0.4, 0.3)
		crystal.z_index = -50
		add_child(crystal)


# ═══════════════════════════════════════════════════════════
#  Stage 15 — Eudaimonia Machine décor (clean void)
# ═══════════════════════════════════════════════════════════

func _setup_eudaimonia_decor(hw: float, hh: float):
	# White grid lines
	var grid_color = Color(0.3, 0.3, 0.35, 0.15)
	for x in range(-int(hw), int(hw), 80):
		var line = ColorRect.new()
		line.color = grid_color
		line.position = Vector2(x, -hh)
		line.size = Vector2(1, map_height)
		line.z_index = -50
		add_child(line)
	for y in range(-int(hh), int(hh), 80):
		var line = ColorRect.new()
		line.color = grid_color
		line.position = Vector2(-hw, y)
		line.size = Vector2(map_width, 1)
		line.z_index = -50
		add_child(line)


func _generate_props(density: float, stage_id: int, hw: float, hh: float):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var margin = 80.0
	var clear_radius = 180.0  # keep area around player start clear
	var min_dist = 60.0       # minimum distance between props
	var target_count = int(map_width * map_height * density)
	# Scale max props with map area — larger maps get more props
	var ref_area = 3200.0 * 2400.0
	var area_ratio = (map_width * map_height) / ref_area
	var max_props = clampi(int(60 * sqrt(area_ratio)), 15, 200)
	target_count = clampi(target_count, 15, max_props)
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
			3:  # Dairy Plant
				_make_factory_prop(pos, rng)
			4:  # Gallo Tower
				_make_tower_prop(pos, rng)
			5:  # Cappella Magna
				_make_chapel_prop(pos, rng)
			6:  # Moongolow
				_make_ruins_prop(pos, rng)
			7:  # Green Acres
				_make_meadow_prop(pos, rng)  # reuse meadow props
			8:  # The Bone Zone
				_make_bone_prop(pos, rng)
			9:  # Boss Rash (no props)
				pass
			10: # Whiteout
				_make_ice_prop(pos, rng)
			11: # The Lycaeum
				_make_ruins_prop(pos, rng)
			12: # The Coop
				_make_factory_prop(pos, rng)  # reuse factory crates
			13: # Space 54
				_make_crystal_prop(pos, rng)
			14: # Bat Country
				_make_bone_prop(pos, rng)
			15: # Eudaimonia Machine (no props)
				pass
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


func _make_factory_prop(pos: Vector2, rng: RandomNumberGenerator):
	var roll = rng.randf()
	if roll < 0.35:
		# Crate (brown rectangle)
		var w = rng.randf_range(16.0, 24.0)
		var h = rng.randf_range(12.0, 18.0)
		_make_rect_prop(pos, Vector2(w, h), Color(0.3, 0.2, 0.08))
	elif roll < 0.55:
		# Pipe (dark gray circle)
		var r = rng.randf_range(6.0, 12.0)
		_make_collision_prop(pos, r, Color(0.15, 0.15, 0.2))
	elif roll < 0.75:
		# Barrel (blueish circle)
		var r = rng.randf_range(10.0, 16.0)
		_make_collision_prop(pos, r, Color(0.15, 0.2, 0.35))
	elif roll < 0.90:
		# Dairy Cart (special, larger)
		var w = rng.randf_range(20.0, 30.0)
		var h = rng.randf_range(14.0, 20.0)
		_make_rect_prop(pos, Vector2(w, h), Color(0.5, 0.45, 0.2))
	else:
		# Spill / puddle (no collision)
		_make_decoration(pos, rng.randf_range(5.0, 10.0), Color(0.3, 0.4, 0.5, 0.4))


func _make_tower_prop(pos: Vector2, rng: RandomNumberGenerator):
	var roll = rng.randf()
	if roll < 0.40:
		# Bookshelf (dark rectangle)
		var w = rng.randf_range(20.0, 35.0)
		var h = rng.randf_range(12.0, 18.0)
		_make_rect_prop(pos, Vector2(w, h), Color(0.2, 0.1, 0.06))
	elif roll < 0.60:
		# Pedestal (gray rectangle)
		var w = rng.randf_range(12.0, 18.0)
		var h = rng.randf_range(18.0, 24.0)
		_make_rect_prop(pos, Vector2(w, h), Color(0.15, 0.12, 0.2))
	elif roll < 0.80:
		# Crystal (colored circle, no collision)
		_make_decoration(pos, rng.randf_range(4.0, 8.0), Color(0.6, 0.2, 0.9, 0.6))
	else:
		# Brazier (tiny orange circle)
		_make_decoration(pos, rng.randf_range(3.0, 5.0), Color(0.9, 0.5, 0.1))


func _make_chapel_prop(pos: Vector2, rng: RandomNumberGenerator):
	var roll = rng.randf()
	if roll < 0.35:
		# Pillar (stone circle)
		var r = rng.randf_range(10.0, 16.0)
		_make_collision_prop(pos, r, Color(0.35, 0.3, 0.25))
	elif roll < 0.55:
		# Pew (brown rectangle)
		var w = rng.randf_range(30.0, 40.0)
		var h = rng.randf_range(8.0, 12.0)
		_make_rect_prop(pos, Vector2(w, h), Color(0.3, 0.18, 0.08))
	elif roll < 0.75:
		# Candelabra (gold circle, no collision)
		_make_decoration(pos, rng.randf_range(4.0, 7.0), Color(0.9, 0.7, 0.2))
	elif roll < 0.90:
		# Debris (gray circle)
		var r = rng.randf_range(6.0, 12.0)
		_make_collision_prop(pos, r, Color(0.25, 0.2, 0.18))
	else:
		# Holy spot (gold glow, no collision)
		_make_decoration(pos, rng.randf_range(6.0, 10.0), Color(0.9, 0.8, 0.3, 0.3))


func _make_ruins_prop(pos: Vector2, rng: RandomNumberGenerator):
	var roll = rng.randf()
	if roll < 0.40:
		# Fallen pillar (gray rect)
		var w = rng.randf_range(10, 18)
		var h = rng.randf_range(6, 12)
		_make_rect_prop(pos, Vector2(w, h), Color(0.2, 0.18, 0.25))
	elif roll < 0.70:
		# Debris pile (small circle)
		var r = rng.randf_range(6, 12)
		_make_collision_prop(pos, r, Color(0.15, 0.12, 0.18))
	else:
		# Glowing crystal (decoration)
		_make_decoration(pos, rng.randf_range(3, 6), Color(0.3, 0.5, 0.8, 0.5))


func _make_bone_prop(pos: Vector2, rng: RandomNumberGenerator):
	var roll = rng.randf()
	if roll < 0.50:
		# Bone pile (pale rect)
		var w = rng.randf_range(8, 16)
		var h = rng.randf_range(4, 8)
		_make_rect_prop(pos, Vector2(w, h), Color(0.35, 0.3, 0.22))
	elif roll < 0.80:
		# Skull (small circle)
		var r = rng.randf_range(6, 10)
		_make_collision_prop(pos, r, Color(0.3, 0.25, 0.2))
	else:
		# Bone fragment (decoration)
		_make_decoration(pos, rng.randf_range(3, 5), Color(0.4, 0.35, 0.28))


func _make_ice_prop(pos: Vector2, rng: RandomNumberGenerator):
	var roll = rng.randf()
	if roll < 0.40:
		# Ice block (pale blue circle)
		var r = rng.randf_range(8, 14)
		_make_collision_prop(pos, r, Color(0.5, 0.55, 0.65, 0.6))
	elif roll < 0.70:
		# Snow mound (white circle)
		var r = rng.randf_range(10, 18)
		_make_collision_prop(pos, r, Color(0.6, 0.6, 0.65, 0.4))
	else:
		# Ice shard (decoration)
		_make_decoration(pos, rng.randf_range(3, 5), Color(0.7, 0.75, 0.85, 0.6))


func _make_crystal_prop(pos: Vector2, rng: RandomNumberGenerator):
	var roll = rng.randf()
	if roll < 0.35:
		# Large crystal (colored rect)
		var w = rng.randf_range(8, 14)
		var h = rng.randf_range(12, 20)
		var hue = rng.randf_range(0.5, 0.9)
		_make_rect_prop(pos, Vector2(w, h), Color.from_hsv(hue, 0.6, 0.5))
	elif roll < 0.65:
		# Rock (gray circle)
		var r = rng.randf_range(8, 14)
		_make_collision_prop(pos, r, Color(0.15, 0.12, 0.2))
	else:
		# Sparkle (tiny decoration)
		_make_decoration(pos, rng.randf_range(2, 4), Color(0.9, 0.8, 1.0, 0.7))


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
#  INTERACTIVE MAP ELEMENTS
# ═══════════════════════════════════════════════════════════

func _spawn_interactive_elements(data: Dictionary, hw: float, hh: float):
	if data.is_empty() or not prop_manager:
		return

	# ── Treasure chests ──
	for c in data.get("chests", []):
		var pos = c.get("pos", Vector2.ZERO)
		var size_f = c.get("size_f", 1.0)
		var chest = TreasureChest.new()
		var sz = Vector2(28, 20) * size_f
		var col = Color(0.45, 0.3, 0.1)
		if c.has("color"):
			col = c["color"]
		chest.setup(sz, col, player)
		chest.global_position = _clamp_to_map(pos, 30.0)
		add_child(chest)
		prop_manager.register_interactable(chest)

	# ── Healing fountains ──
	for f in data.get("fountains", []):
		var pos = f.get("pos", Vector2.ZERO)
		var heal_pct = f.get("heal_pct", 0.5)
		var cd = f.get("cooldown", 30.0)
		var radius = f.get("radius", 24.0)
		var fountain = HealingFountain.new()
		fountain.setup(radius, heal_pct, cd, player)
		fountain.global_position = _clamp_to_map(pos, 30.0)
		add_child(fountain)
		prop_manager.register_interactable(fountain)

	# ── Breakable walls ──
	var bd = data.get("breakable_density", 0.0)
	var bh = data.get("breakable_hp", 25.0)
	if bd > 0.0:
		_spawn_breakable_walls(bd, bh, hw, hh)

	# ── Hazard zones ──
	for h in data.get("hazards", []):
		var pos = h.get("pos", Vector2.ZERO)
		var size = h.get("size", Vector2(100, 100))
		var dps = h.get("dps", 15.0)
		var color = h.get("color", Color(0.8, 0.1, 0.05))
		var hurt_enemies = h.get("hurt_enemies", true)
		var zone = HazardZone.new()
		zone.setup(size, dps, color, hurt_enemies)
		zone.global_position = _clamp_to_map(pos, 20.0)
		add_child(zone)
		prop_manager.register_hazard(zone)

	# ── Boost zones ──
	for b in data.get("boosts", []):
		var pos = b.get("pos", Vector2.ZERO)
		var btype = b.get("type", "speed")
		var amount = b.get("amount", 0.5)
		var size = b.get("size", Vector2(80, 80))
		var color = b.get("color", Color.BLACK)
		var zone = BoostZone.new()
		zone.setup(btype, amount, size, color)
		zone.global_position = _clamp_to_map(pos, 20.0)
		add_child(zone)
		prop_manager.register_boost(zone)


func _spawn_breakable_walls(density: float, hp: float, hw: float, hh: float):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var margin = 80.0
	var clear_radius = 180.0
	var min_dist = 80.0
	
	var target_count = int(map_width * map_height * density)
	target_count = clampi(target_count, 5, 120)
	var attempts = target_count * 6
	var placed = 0
	
	for _a in range(attempts):
		if placed >= target_count:
			break
		var x = rng.randf_range(-hw + margin, hw - margin)
		var y = rng.randf_range(-hh + margin, hh - margin)
		var pos = Vector2(x, y)
		
		if pos.length() < clear_radius:
			continue
		
		var too_close = false
		for ep in _obstacle_positions:
			if pos.distance_to(ep) < min_dist:
				too_close = true
				break
		if too_close:
			continue
		
		var wall_sz = Vector2(rng.randf_range(20, 40), rng.randf_range(20, 40))
		var shade = rng.randf_range(0.2, 0.35)
		var col = Color(shade, shade * 0.8, shade * 0.6)
		
		var bw = BreakableWall.new()
		bw.setup(wall_sz, col, hp + rng.randf_range(-5, 5), player)
		bw.global_position = pos
		bw.wall_destroyed.connect(_on_breakable_destroyed)
		add_child(bw)
		prop_manager.register_interactable(bw)
		_obstacle_positions.append(pos)
		placed += 1


func _on_breakable_destroyed(pos: Vector2):
	var idx = _obstacle_positions.find(pos)
	if idx >= 0:
		_obstacle_positions.remove_at(idx)


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
	if game_over or stage_complete or not _map_ready:
		return
	
	_frame_count += 1
	var every_n = func(n: int): return _frame_count % n == 0
	
	# Hurry mode: 1.5x game speed (cache to avoid Engine.get_meta every frame)
	var speed_mult = 1.0
	if Engine.has_meta("hurry_mode") and Engine.get_meta("hurry_mode"):
		speed_mult = 1.5
	
	game_time += delta * speed_mult
	
	# Win condition (skipped in endless mode)
	var endless = Engine.has_meta("endless_mode") and Engine.get_meta("endless_mode")
	if not endless and game_time >= stage_time_limit:
		_on_stage_complete()
		return
	
	# ── Continuous spawn system ──
	difficulty = 1.0 + game_time / _diff_ramp_time
	_spawn_timer -= delta * speed_mult
	if _spawn_timer <= 0.0:
		_spawn_continuous()
	
	# ── Wave system ──
	if not game_over and not stage_complete:
		if _wave_active:
			if _wave_spawning:
				_wave_spawn_timer -= delta * speed_mult
				if _wave_spawn_timer <= 0.0:
					_spawn_wave_enemy()
			# Wave ends when all enemies spawned & all dead
			if not _wave_spawning and _wave_alive <= 0:
				_end_wave()
		else:
			_wave_break_timer -= delta * speed_mult
			if _wave_break_timer <= 0.0:
				_start_wave()
	
	# Apply speed_mult to enemy speed via metadata (only when changed)
	if speed_mult != _last_speed_mult:
		_last_speed_mult = speed_mult
		Engine.set_meta("stage_speed_mult", speed_mult)
	
	# Boss spawn check (at 15:00 for eligible stages)
	if not _boss_spawned and game_time >= 900.0:
		var boss_t = EnemyDefs.get_boss_type(_stage_id, game_time)
		if boss_t >= 0:
			_spawn_boss()
	
	# HUD — cache simple values to avoid redundant calls
	if player.level != _hud_last_level:
		_hud_last_level = player.level
		hud.set_level(player.level)
	if total_kills != _hud_last_kills:
		_hud_last_kills = total_kills
		hud.set_kills(total_kills)
	if PowerUpManager.run_gold != _hud_last_gold:
		_hud_last_gold = PowerUpManager.run_gold
		hud.set_gold(PowerUpManager.run_gold)
	if wave_number != _hud_last_wave:
		_hud_last_wave = wave_number
		hud.set_wave(wave_number)
	if player.xp != _hud_last_xp or player.xp_to_next != _hud_last_xp_to_next:
		_hud_last_xp = player.xp
		_hud_last_xp_to_next = player.xp_to_next
		hud.set_xp(player.xp, player.xp_to_next)
	hud.set_health(player.health, player.max_health)
	hud.set_timer(game_time)
	
	# Weapon display data — only rebuild when weapons actually change
	var wep_changed = false
	var weapons = player.weapon_manager.weapons
	if weapons.size() != _hud_weapon_cache.size():
		wep_changed = true
	else:
		for i in range(weapons.size()):
			var w = weapons[i]
			var cached = _hud_weapon_cache[i]
			if w.type != cached.get("type", -1) or w.level != cached.get("level", -1) or w.evolved != cached.get("evolved", false):
				wep_changed = true
				break
	if wep_changed:
		var wep_data: Array = []
		_hud_weapon_cache.clear()
		for w in weapons:
			var entry = {
				"name": _get_wep_name(w.type),
				"name_key": _get_wep_name_key(w.type),
				"type": w.type,
				"level": w.level,
				"evolved": w.evolved,
				"color": _get_wep_color(w.type),
			}
			wep_data.append(entry)
			_hud_weapon_cache.append(entry)
		hud.set_weapons(wep_data)
	
	# Passive display data — only rebuild when passives change
	var pas_changed = false
	var pas_dict = player.passive_inventory.get_all()
	if pas_dict.size() != _hud_passive_cache.size():
		pas_changed = true
	else:
		var i = 0
		for t in pas_dict:
			var lv = pas_dict[t]
			var cached = _hud_passive_cache[i]
			if t != cached.get("type", -1) or lv != cached.get("level", -1):
				pas_changed = true
				break
			i += 1
	if pas_changed:
		var pas_data: Array = []
		_hud_passive_cache.clear()
		for t in pas_dict:
			var lv = pas_dict[t]
			var entry = {
				"type": t,
				"level": lv,
				"color": _get_wep_color(t),
			}
			pas_data.append(entry)
			_hud_passive_cache.append(entry)
		hud.set_passives(pas_data)
	
	# Camera follows player with shake offset
	if _camera:
		var shake_off = Vector2.ZERO
		if _shake_duration > 0.0:
			_shake_duration -= delta
			shake_off = Vector2(randf_range(-_shake_intensity, _shake_intensity), randf_range(-_shake_intensity, _shake_intensity))
		_camera.global_position = player.global_position + _camera_offset + shake_off
	

	
	# ── Arcana time-based effects ──
	if ArcanaManager.get_active_count() > 0:
		ArcanaManager.process_time_effects(delta * speed_mult, player, game_time)
		# Pass active Arcanas to HUD
		var active_arcanas = ArcanaManager.get_active()
		hud.set_arcanas(active_arcanas)
	
	# Arcana boss at 11:00 (throttled: only check every 30 frames after time passes)
	var arcanas_enabled = Engine.has_meta("arcanas_enabled") and Engine.get_meta("arcanas_enabled")
	if arcanas_enabled and ArcanaManager.is_system_enabled() and (_frame_count % 30 == 0 or game_time < 660.0):
		if not _arcana_boss_spawned_11 and game_time >= 660.0:  # 11:00
			_arcana_boss_spawned_11 = true
			_spawn_arcana_boss()
		if not _arcana_boss_spawned_21 and game_time >= 1260.0:  # 21:00
			_arcana_boss_spawned_21 = true
			_spawn_arcana_boss()
	
	# Relic arrow — throttle to every 6 frames
	if _has_relic_arrow and is_instance_valid(player) and every_n.call(6):
		var target = _get_nearest_relic_pos()
		if target != Vector2.ZERO:
			var offset = target - player.global_position
			var dist = offset.length()
			if dist > 80.0:
				var arrow_angle = offset.angle()
				hud.set_relic_arrow(arrow_angle, dist)
			else:
				hud.set_relic_arrow(null, 0.0)
		else:
			hud.set_relic_arrow(null, 0.0)
	
	# ── Interaction prompt (throttled to every 6 frames) —─
	if prop_manager and is_instance_valid(player) and every_n.call(6):
		prop_manager.update_nearest(player.global_position, 80.0)
		if prop_manager.highlight_prompt != "":
			_interact_prompt.text = "[E] " + prop_manager.highlight_prompt
			if _cached_vp_size == Vector2.ZERO:
				_cached_vp_size = get_viewport_rect().size
			_interact_prompt.position = Vector2(_cached_vp_size.x / 2.0 - 100, _cached_vp_size.y - 50)
			_interact_prompt.visible = true
		else:
			_interact_prompt.visible = false


func _spawn_continuous():
	if game_over or stage_complete or not _map_ready:
		return
	if not is_instance_valid(player):
		return
	
	var pool = EnemyDefs.get_types_for_stage(_stage_id, game_time)
	if pool.is_empty():
		pool = [0]
	var type_idx = EnemyDefs.pick_weighted(pool)
	_spawn_enemy(type_idx)
	
	# Ramp up spawn rate over time using per-stage config (cached values)
	var ramp = stage_data.get("spawn_ramp_time", 30.0)
	var interval = max(_spawn_base_interval - game_time / ramp * (_spawn_base_interval - _spawn_min_interval), _spawn_min_interval)
	_spawn_timer = interval


# ── Wave system ──

func _start_wave():
	wave_number += 1
	_wave_active = true
	_wave_spawning = true
	_wave_total = 1 + int(game_time / 60.0)  # grows with time: ~1 at 0s, 16 at 15min
	_wave_spawned = 0
	_wave_alive = _wave_total
	_wave_spawn_timer = 0.15  # first spawn almost immediately
	# Slow continuous spawn while wave is active (let wave be the star)
	_spawn_timer = max(_spawn_timer, 0.3)


func _spawn_wave_enemy():
	var pool = EnemyDefs.get_types_for_stage(stage_data.get("id", 0), game_time)
	if pool.is_empty():
		pool = [0]
	var type_idx = EnemyDefs.pick_weighted(pool)
	var enemy = _spawn_enemy(type_idx)
	if is_instance_valid(enemy):
		enemy.is_wave_enemy = true
	_wave_spawned += 1
	_wave_spawn_timer = 0.05  # fast burst interval
	if _wave_spawned >= _wave_total:
		_wave_spawning = false


func _end_wave():
	_wave_active = false
	_wave_break_timer = 3.0 + randf_range(0.0, 2.0)  # 3–5s rest
	# Restore continuous spawn to normal pace
	_spawn_timer = 0.3


func _spawn_enemy(type_id: int = 0) -> Node2D:
	var enemy = _enemy_scene.instantiate()
	enemy.player = player
	var curse_mod = 1.0 + (player.get_curse() if is_instance_valid(player) else 0.0)
	enemy.set_enemy_type(type_id, difficulty * curse_mod)
	
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
	return enemy


func _spawn_boss():
	if _boss_spawned:
		return
	_boss_spawned = true
	var boss_type = EnemyDefs.get_boss_type(stage_data.get("id", 0), game_time)
	if boss_type < 0:
		return
	
	var enemy = _enemy_scene.instantiate()
	enemy.player = player
	var curse_mod = 1.0 + (player.get_curse() if is_instance_valid(player) else 0.0)
	enemy.set_enemy_type(boss_type, difficulty * curse_mod)
	
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


func _spawn_initial_pickups(hw: float, hh: float):
	# Scatter a few pickups across the map at game start
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
		var pt = rng.randi_range(0, 1)  # CHICKEN or GOLD mostly
		if rng.randf() < 0.02:
			pt = 2  # ROSARY (rare)
		_spawn_pickup_at(pos, pt)


# ── Relic spawning ──────────────────────────────────────────

func _spawn_stage_relics():
	var stage_id = stage_data.get("id", 0)
	var relics = RelicDefs.get_relics_for_stage(stage_id)
	for r in relics:
		var rid = r["id"]
		if RelicManager.has_relic(rid):
			continue  # already collected — skip
		
		var relic = _relic_scene.instantiate()
		relic.initialize(rid, player)
		relic.global_position = _clamp_to_map(r["spawn_pos"], 30.0)
		add_child(relic)
		_stage_relics.append(relic)
		
		# Track first relic for arrow indicator
		if not _has_relic_arrow:
			_has_relic_arrow = true
			_relic_arrow_target = relic.global_position


# ── Pre-placed stage items (weapons/passives on the map) ─────

func _spawn_stage_items():
	var items = stage_data.get("stage_items", [])
	if items.is_empty():
		return
	var item_script = preload("res://scripts/entities/stage_item_pickup.gd")
	for it in items:
		var t = it.get("type", -1)
		var is_wpn = it.get("is_weapon", true)
		var pos = it.get("pos", Vector2.ZERO)
		if t < 0:
			continue
		var pickup = Area2D.new()
		pickup.set_script(item_script)
		pickup.item_type = t
		pickup.is_weapon = is_wpn
		pickup.player = player
		pickup.global_position = _clamp_to_map(pos, 30.0)

		# Collision shape
		var shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 20.0
		shape.shape = circle
		pickup.add_child(shape)

		# Name label (i18n)
		var nm = ""
		if is_wpn:
			nm = I18N.t(_get_wep_name_key(t), _basic_weapon_name(t))
		else:
			nm = I18N.t(_pas_name_key(t), _basic_passive_name(t))
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
	total_kills += 1
	
	# Track wave enemy kills
	if _wave_active and enemy.is_wave_enemy:
		_wave_alive -= 1
	
	# Check if it was an Arcana boss (special chest drop)
	var is_arcana_boss = enemy.has_meta("arcana_boss") and enemy.get_meta("arcana_boss")
	if is_arcana_boss:
		# Arcana boss drops an Arcana chest = opens the choice screen
		# But first, drop some XP and gold so it's not empty
		for i in range(5):
			var gem = GemPool.borrow()
			gem.value = max(enemy.xp_value / 3, 5)
			gem.player = player
			gem.global_position = enemy.global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
			call_deferred("add_child", gem)
		for i in range(2):
			_spawn_pickup_at(enemy.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20)), 1)
		
		# Show Arcana choice screen (gated by ArcanaManager active count < some limit)
		call_deferred("_show_arcana_chest_pick")
		return
	
	# Check if it was a boss
	var is_boss = enemy.has_method("get_is_boss") and enemy.get_is_boss()
	if is_boss:
		# Unlock Hyper mode for this stage
		var sid = stage_data.get("id", 0)
		UnlockManager.on_boss_defeated(sid)
	
	# Drop XP gem(s)
	if is_boss:
		# Boss drops several large XP gems
		for i in range(8):
			var gem = GemPool.borrow()
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
		if randf() < 0.40:
			var gem = GemPool.borrow()
			gem.player = player
			gem.global_position = enemy.global_position
			if game_time < 180.0:
				gem.tier = gem.Tier.BLUE
				gem.value = maxi(enemy.xp_value, 1)
			elif game_time < 600.0:
				gem.tier = gem.Tier.GREEN
				gem.value = maxi(enemy.xp_value * 2, 4)
			else:
				gem.tier = gem.Tier.RED
				gem.value = maxi(enemy.xp_value * 3, 10)
			call_deferred("add_child", gem)
		# Very small chance for special pickups from normal enemies
		if randf() < 0.001:
			var pt = 2 if randf() < 0.5 else 3  # ROSARY or VACUUM
			_spawn_pickup_at(enemy.global_position, pt)


# ═══════════════════════════════════════════════════════════
#  GAME FLOW EVENTS
# ═══════════════════════════════════════════════════════════

func _on_player_leveled_up():
	# Check unlocks on level-up
	UnlockManager.on_player_leveled_up(player.level)
	# Notify ArcanaManager (for per-level Arcana bonuses)
	ArcanaManager.on_player_level_up(player, player.level)
	get_tree().paused = true
	level_up_screen.show_choices(player)


func _on_player_hurt():
	_shake_camera(4.0, 0.15)


func _on_player_died():
	game_over = true
	_shake_camera(12.0, 0.5)
	get_tree().paused = true
	# Check unlock conditions on death
	if player:
		UnlockManager.on_run_ended(player.level)
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
	
	# Unlock checks (stage-milestone + level-based, handled by UnlockManager)
	var stage_id = stage_data.get("id", 0)
	UnlockManager.on_stage_cleared(stage_id)
	# Also check level-based unlocks on stage completion
	if player:
		UnlockManager.on_run_ended(player.level)
	
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


func _on_gold_selected(amount: int):
	get_tree().paused = false
	PowerUpManager.add_run_gold(amount)
	hud.set_gold(PowerUpManager.run_gold)
	level_up_screen.hide_screen()


# ═══════════════════════════════════════════════════════════
#  ARCANA SYSTEM
# ═══════════════════════════════════════════════════════════

func _show_arcana_first_pick():
	# Pause and let the player pick their starting Arcana
	if ArcanaManager.get_unlocked_count() <= 0:
		return  # no Arcanas unlocked yet — skip
	get_tree().paused = true
	_arcana_choice_screen.show_choices(true)


func _show_arcana_chest_pick():
	# Arcana boss was defeated — show choice from unlocked Arcanas not yet active
	if get_tree().paused:
		return  # don't double-pause
	
	# Filter out already active Arcanas
	var pool = ArcanaManager.get_unlocked()
	var active = ArcanaManager.get_active()
	var available = []
	for id in pool:
		if not active.has(id):
			available.append(id)
	
	if available.is_empty():
		return  # all unlocked Arcanas already active — nothing to offer
	
	get_tree().paused = true
	_arcana_choice_screen.show_choices(false, available)


func _on_arcana_selected(arcana_id: int):
	get_tree().paused = false
	_arcana_active_count = ArcanaManager.get_active_count()
	_show_boss_announcement(I18N.t("arcana.equipped") % I18N.t("arcana." + str(arcana_id) + "_name", arcana_data_name(arcana_id)))
	# Recalculate player stats
	player.recalculate_stats()


func arcana_data_name(id: int) -> String:
	var a = ArcanaDefs.get_arcana(id)
	return a["name"]


# Unlock character-based Arcanas based on level reached
# The character-based Arcanas (1-5, 7, 9-11, 13-14, 16-19, 21) 
# unlock progressively as the player reaches higher levels
func _spawn_arcana_boss():
	# Spawn a special boss that drops an Arcana chest on death
	# If the player already has 3+ Arcanas, don't spawn (they'd have no use for more)
	if _arcana_active_count >= 3:
		return
	
	# Use the stage's boss type if available, otherwise use a generic one
	var boss_type = EnemyDefs.get_boss_type(stage_data.get("id", 0), game_time)
	if boss_type < 0:
		boss_type = 0
	
	var enemy = _enemy_scene.instantiate()
	enemy.player = player
	var curse_mod = 1.0 + (player.get_curse() if is_instance_valid(player) else 0.0)
	enemy.set_enemy_type(boss_type, difficulty * curse_mod * 1.5)  # Stronger than normal boss
	enemy.set_meta("arcana_boss", true)
	
	# Spawn just off-screen
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
	
	# Announce the Arcana boss
	_show_boss_announcement(I18N.t("arcana.boss_announce"))


# ═══════════════════════════════════════════════════════════
#  Stage item name helpers (used by _spawn_stage_items)
# ═══════════════════════════════════════════════════════════

static func _basic_weapon_name(t: int) -> String:
	match t:
		0:  return "Whip"
		1:  return "Magic Wand"
		2:  return "Garlic"
		10: return "Knife"
		11: return "Axe"
		12: return "Fire Wand"
		16: return "Cross"
		17: return "King Bible"
		18: return "Santa Water"
		19: return "Runetracer"
		20: return "Lightning Ring"
	return "?"


static func _basic_passive_name(t: int) -> String:
	match t:
		3:  return "Wings"
		4:  return "Spinach"
		5:  return "Empty Tome"
		6:  return "Hollow Heart"
		7:  return "Candelabrador"
		8:  return "Crown"
		9:  return "Pummarola"
		13: return "Duplicator"
		14: return "Stone Mask"
		15: return "Magnet"
		21: return "Clover"
		22: return "Spellbinder"
		23: return "Armor"
		24: return "Bracer"
		25: return "Skull O'Maniac"
		26: return "Tiragisú"
		27: return "Torrona's Box"
	return "?"


func start_game_music():
	if AudioManager and AudioManager.has_method("play_bgm"):
		AudioManager.stop_bgm()
		var use_alt = Engine.has_meta("alt_music") and Engine.get_meta("alt_music") and RelicManager.has_relic("magic_banger")
		var bgm_key = "bgm_alt" if use_alt else "bgm_game"
		if AudioManager.sounds.has(bgm_key):
			AudioManager.play_bgm(AudioManager.sounds.get(bgm_key))
		else:
			AudioManager.play_bgm(AudioManager.sounds.get("bgm_game"))


func _get_wep_name(type: int) -> String:
	match type:
		0: return "Whip"
		1: return "Magic Wand"
		2: return "Garlic"
		10: return "Knife"
		11: return "Axe"
		12: return "Fire Wand"
		16: return "Cross"
		17: return "King Bible"
		18: return "Santa Water"
		19: return "Runetracer"
		20: return "Lightning Ring"
	return "?" + str(type)


func _get_wep_name_key(type: int) -> String:
	match type:
		0: return "wpn.whip"
		1: return "wpn.wand"
		2: return "wpn.garlic"
		10: return "wpn.knife"
		11: return "wpn.axe"
		12: return "wpn.firewand"
		16: return "wpn.cross"
		17: return "wpn.bible"
		18: return "wpn.santa_water"
		19: return "wpn.runetracer"
		20: return "wpn.lightning"
	return "wpn.whip"


func _pas_name_key(type: int) -> String:
	match type:
		3: return "pas.wings"
		4: return "pas.spinach"
		5: return "pas.tome"
		6: return "pas.hollow"
		7: return "pas.candel"
		8: return "pas.crown"
		9: return "pas.pummarola"
		13: return "pas.duplicator"
		14: return "pas.stonemask"
		15: return "pas.magnet"
		21: return "pas.clover"
		22: return "pas.spellbinder"
		23: return "pas.armor"
		24: return "pas.bracer"
		25: return "pas.skull"
		26: return "pas.tiragisu"
		27: return "pas.torrona"
		28: return "pas.silver_ring"
		29: return "pas.gold_ring"
		30: return "pas.metaglio_left"
		31: return "pas.metaglio_right"
	return "pas.wings"


func _get_wep_color(type: int) -> Color:
	match type:
		0: return Color(0.8, 0.6, 0.3)
		1: return Color(0.3, 0.5, 1.0)
		2: return Color(0.6, 0.2, 0.8)
		10: return Color(0.7, 0.7, 0.7)
		11: return Color(0.6, 0.3, 0.1)
		12: return Color(0.9, 0.4, 0.1)
		16: return Color(0.9, 0.6, 0.2)
		17: return Color(0.2, 0.6, 0.9)
		18: return Color(0.1, 0.5, 0.8)
		19: return Color(0.8, 0.3, 0.7)
		20: return Color(0.9, 0.9, 0.2)
		# Passives (3-9, 13-15, 21-23)
		3: return Color(0.2, 0.8, 0.4)
		4: return Color(0.9, 0.3, 0.3)
		5: return Color(0.2, 0.5, 0.8)
		6: return Color(0.9, 0.2, 0.2)
		7: return Color(0.9, 0.7, 0.2)
		8: return Color(0.9, 0.8, 0.0)
		9: return Color(0.2, 0.9, 0.2)
		13: return Color(0.2, 0.7, 0.9)
		14: return Color(0.7, 0.7, 0.8)
		15: return Color(0.1, 0.7, 0.8)
		21: return Color(0.2, 0.9, 0.3)
		22: return Color(0.5, 0.3, 0.9)
		23: return Color(0.6, 0.6, 0.6)
		24: return Color(0.3, 0.9, 0.6)
		25: return Color(0.6, 0.2, 0.2)
		26: return Color(0.9, 0.7, 0.9)
		27: return Color(0.4, 0.2, 0.6)
		28: return Color(0.6, 0.7, 0.9)
		29: return Color(0.9, 0.8, 0.2)
		30: return Color(0.5, 0.3, 0.8)
		31: return Color(0.8, 0.3, 0.5)
	return Color.WHITE





func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("fullscreen"):
		I18N.toggle_fullscreen()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("interact"):
		if prop_manager and is_instance_valid(player):
			prop_manager.try_interact(player)
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
	SceneManager.change_scene("res://scenes/main_menu.tscn")
