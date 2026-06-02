extends Node
# StageGenerator — 关卡地图生成
# 从 main.gd 中拆分出的地图/装饰/交互元素生成逻辑

const GameState = preload("res://scripts/core/game_state.gd")
const Prop = preload("res://scripts/map/prop.gd")
const PropManager = preload("res://scripts/core/prop_manager.gd")
const BreakableWall = preload("res://scripts/map/breakable_wall.gd")
const TreasureChest = preload("res://scripts/map/treasure_chest.gd")
const HealingFountain = preload("res://scripts/map/healing_fountain.gd")
const HazardZone = preload("res://scripts/map/hazard_zone.gd")
const BoostZone = preload("res://scripts/map/boost_zone.gd")

var game_state: GameState
var main_node: Node2D  # 父节点（通常是 main.gd 所在场景）
var player: Node2D

# 障碍物位置（用于生成时碰撞检测）
var obstacle_positions: Array[Vector2] = []

signal map_ready
signal obstacle_added(pos: Vector2)
signal obstacle_removed(pos: Vector2)


func setup(gs: GameState, parent: Node2D, p: Node2D):
	game_state = gs
	main_node = parent
	player = p


func generate():
	obstacle_positions.clear()
	
	var stage_data = game_state.stage_data
	var hw = game_state.map_width / 2.0
	var hh = game_state.map_height / 2.0
	var stage_id = game_state._stage_id
	
	var map_scene_path = stage_data.get("map_scene", "")
	if map_scene_path:
		_load_map_scene(map_scene_path, hw, hh)
	else:
		_add_background(stage_data.get("bg_color", Color(0.04, 0.04, 0.10)), hw, hh)
		_add_stage_decor(stage_id, hw, hh)
	
	_generate_props(stage_id, hw, hh)
	_add_boundary_walls(hw, hh)
	_add_interactive_elements(stage_data.get("interactables", {}), hw, hh)
	var count = randi_range(3, 6)
	_scatter_initial_pickups(count, hw, hh)
	
	map_ready.emit()


func _load_map_scene(path: String, hw: float, hh: float):
	var scene = load(path)
	if not scene:
		push_error("StageGenerator: failed to load map scene: " + path)
		return
	var instance = scene.instantiate()
	instance.position = Vector2(-hw, -hh)
	main_node.add_child(instance)


func _add_background(bg_color: Color, hw: float, hh: float):
	var bg = ColorRect.new()
	bg.color = bg_color
	bg.position = Vector2(-hw, -hh)
	bg.size = Vector2(game_state.map_width, game_state.map_height)
	bg.z_index = -100
	main_node.add_child(bg)


func _add_stage_decor(stage_id: int, hw: float, hh: float):
	# 优先读取数据驱动的 decor_config
	var dc = game_state.stage_data.get("decor_config", {})
	if not dc.is_empty():
		_apply_decor_config(dc, hw, hh)
		return
	# 回退到硬编码装饰函数
	match stage_id:
		0:  pass  # Mad Forest — props only
		1:  _setup_library_decor(hw, hh)
		2:  _setup_meadow_flowers(hw, hh)
		3:  _setup_factory_decor(hw, hh)
		4:  _setup_tower_decor(hw, hh)
		5:  _setup_chapel_decor(hw, hh)
		6:  _setup_moongolow_decor(hw, hh)
		7:  pass  # Green Acres — props only
		8:  _setup_bone_decor(hw, hh)
		9:  _setup_arena_decor(hw, hh)
		10: _setup_whiteout_decor(hw, hh)
		11: _setup_lycaeum_decor(hw, hh)
		12: _setup_coop_decor(hw, hh)
		13: _setup_space_decor(hw, hh)
		14: _setup_bat_decor(hw, hh)
		15: _setup_eudaimonia_decor(hw, hh)


# ── 数据驱动装饰系统（从 decor_config 读取）──

func _apply_decor_config(dc: Dictionary, hw: float, hh: float):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var ref_area = 3200.0 * 2400.0
	var area_ratio = (game_state.map_width * game_state.map_height) / ref_area
	var area_scale = sqrt(area_ratio)
	var margin = clampf(40.0 * area_scale, 40.0, 120.0)

	for el in dc.get("decor_elements", []):
		var el_type = el.get("type", "dot")
		var count = int(el.get("count", 10) * area_ratio)
		var size_min = el.get("size_min", 2.0)
		var size_max = el.get("size_max", 4.0)
		var base_color: Color = el.get("color", Color.WHITE)
		var alpha_min = el.get("alpha_min", 0.2)
		var alpha_max = el.get("alpha_max", 0.5)
		var z = el.get("z", -50)

		for i in range(count):
			var pos = Vector2(
				rng.randf_range(-hw + margin, hw - margin),
				rng.randf_range(-hh + margin, hh - margin)
			)
			var sz = rng.randf_range(size_min, size_max)
			var alpha = rng.randf_range(alpha_min, alpha_max)
			var col = Color(base_color.r, base_color.g, base_color.b, alpha)

			var rect = ColorRect.new()
			rect.position = pos
			rect.size = Vector2(sz, sz)
			rect.color = col
			rect.z_index = z
			main_node.add_child(rect)

	# Props 颜色配置（覆盖硬编码 prop 生成中的颜色）
	var props_cfg = dc.get("props", {})
	if not props_cfg.is_empty():
		var prop_colors = props_cfg.get("colors", [])
		if not prop_colors.is_empty():
			game_state.set_meta("prop_colors", prop_colors)


# ── 各关卡装饰 ──

func _setup_library_decor(hw: float, hh: float):
	var wall_color = Color(0.12, 0.03, 0.18)
	var strip_w = 40.0
	_add_wall_strip(Vector2(-hw, -hh), Vector2(strip_w, game_state.map_height), wall_color)
	_add_wall_strip(Vector2(hw - strip_w, -hh), Vector2(strip_w, game_state.map_height), wall_color)
	for y in range(-int(hh) + 80, int(hh), 120):
		_add_decor_rect(Vector2(-hw + strip_w, y), Vector2(game_state.map_width - strip_w * 2, 2), Color(0.1, 0.02, 0.15, 0.3))


func _setup_meadow_flowers(hw: float, hh: float):
	for i in range(40):
		_add_decor_rect(
			Vector2(randf_range(-hw + 30, hw - 30), randf_range(-hh + 30, hh - 30)),
			Vector2(4, 4),
			Color(randf_range(0.6, 1.0), randf_range(0.3, 0.9), randf_range(0.1, 0.5), 0.7)
		)


func _setup_factory_decor(hw: float, hh: float):
	var wall_color = Color(0.12, 0.08, 0.18)
	var strip_w = 30.0
	_add_wall_strip(Vector2(-hw, -hh), Vector2(strip_w, game_state.map_height), wall_color)
	_add_wall_strip(Vector2(hw - strip_w, -hh), Vector2(strip_w, game_state.map_height), wall_color)
	for y in range(-int(hh) + 60, int(hh), 80):
		_add_decor_rect(Vector2(-hw + strip_w, y), Vector2(game_state.map_width - strip_w * 2, 3), Color(0.15, 0.1, 0.22, 0.3))
	for i in range(6):
		_add_decor_rect(
			Vector2(randf_range(-hw + 80, hw - 80), randf_range(-hh + 80, hh - 80)),
			Vector2(24, 24), Color(0.2, 0.15, 0.3, 0.25)
		)


func _setup_tower_decor(hw: float, hh: float):
	var wall_color = Color(0.15, 0.03, 0.2)
	var strip_w = 35.0
	_add_wall_strip(Vector2(-hw, -hh), Vector2(strip_w, game_state.map_height), wall_color)
	_add_wall_strip(Vector2(hw - strip_w, -hh), Vector2(strip_w, game_state.map_height), wall_color)
	for y in range(-int(hh) + 50, int(hh), 100):
		_add_decor_rect(Vector2(-hw + strip_w, y), Vector2(game_state.map_width - strip_w * 2, 2), Color(0.2, 0.05, 0.25, 0.3))
	for i in range(4):
		_add_decor_rect(
			Vector2(randf_range(-hw + 60, hw - 60), randf_range(-hh + 60, hh - 60)),
			Vector2(16, 16), Color(0.5, 0.1, 0.6, 0.15)
		)


func _setup_chapel_decor(hw: float, hh: float):
	var wall_color = Color(0.2, 0.05, 0.08)
	var strip_w = 40.0
	_add_wall_strip(Vector2(-hw, -hh), Vector2(strip_w, game_state.map_height), wall_color)
	_add_wall_strip(Vector2(hw - strip_w, -hh), Vector2(strip_w, game_state.map_height), wall_color)
	var glass_colors = [Color(0.8, 0.2, 0.2, 0.2), Color(0.2, 0.4, 0.8, 0.2), Color(0.8, 0.8, 0.2, 0.2)]
	for i in range(6):
		_add_decor_rect(
			Vector2(randf_range(-hw + 60, hw - 60), randf_range(-hh + 60, hh - 60)),
			Vector2(30, 40), glass_colors[i % glass_colors.size()]
		)
	_add_decor_rect(Vector2(-40, -40), Vector2(80, 80), Color(0.4, 0.15, 0.1, 0.3))


func _setup_moongolow_decor(hw: float, hh: float):
	for i in range(12):
		_add_decor_rect(
			Vector2(randf_range(-hw + 40, hw - 40), randf_range(-hh + 40, hh - 40)),
			Vector2(randf_range(10, 25), randf_range(8, 16)),
			Color(0.15, 0.12, 0.2, randf_range(0.3, 0.6))
		)


func _setup_bone_decor(hw: float, hh: float):
	for i in range(15):
		_add_decor_rect(
			Vector2(randf_range(-hw + 40, hw - 40), randf_range(-hh + 40, hh - 40)),
			Vector2(randf_range(6, 14), randf_range(2, 4)),
			Color(0.3, 0.25, 0.2, 0.5)
		)


func _setup_arena_decor(hw: float, hh: float):
	_add_decor_rect(Vector2(-hw + 20, -hh + 20), Vector2(game_state.map_width - 40, game_state.map_height - 40), Color(0.5, 0.05, 0.05, 0.15))


func _setup_whiteout_decor(hw: float, hh: float):
	for i in range(20):
		_add_decor_rect(
			Vector2(randf_range(-hw + 40, hw - 40), randf_range(-hh + 40, hh - 40)),
			Vector2(randf_range(8, 20), randf_range(8, 20)),
			Color(0.5, 0.5, 0.6, randf_range(0.1, 0.25))
		)


func _setup_lycaeum_decor(hw: float, hh: float):
	for i in range(10):
		_add_decor_rect(
			Vector2(randf_range(-hw + 40, hw - 40), randf_range(-hh + 40, hh - 40)),
			Vector2(4, randf_range(10, 20)),
			Color(0.1, 0.4, 0.3, 0.3)
		)


func _setup_coop_decor(hw: float, hh: float):
	for i in range(16):
		_add_decor_rect(
			Vector2(randf_range(-hw + 40, hw - 40), randf_range(-hh + 40, hh - 40)),
			Vector2(6, randf_range(12, 20)),
			Color(0.3, 0.2, 0.1, 0.4)
		)


func _setup_space_decor(hw: float, hh: float):
	for i in range(25):
		_add_decor_rect(
			Vector2(randf_range(-hw + 40, hw - 40), randf_range(-hh + 40, hh - 40)),
			Vector2(2, 2),
			Color(0.8, 0.8, 1.0, randf_range(0.2, 0.6))
		)


func _setup_bat_decor(hw: float, hh: float):
	for i in range(12):
		_add_decor_rect(
			Vector2(randf_range(-hw + 40, hw - 40), randf_range(-hh + 40, hh - 40)),
			Vector2(randf_range(4, 10), randf_range(6, 14)),
			Color(0.3, 0.1, 0.4, 0.3)
		)


func _setup_eudaimonia_decor(hw: float, hh: float):
	var grid_color = Color(0.3, 0.3, 0.35, 0.15)
	for x in range(-int(hw), int(hw), 80):
		_add_decor_rect(Vector2(x, -hh), Vector2(1, game_state.map_height), grid_color)
	for y in range(-int(hh), int(hh), 80):
		_add_decor_rect(Vector2(-hw, y), Vector2(game_state.map_width, 1), grid_color)


# ── 辅助 ──

func _add_decor_rect(pos: Vector2, size: Vector2, color: Color):
	var r = ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.z_index = -50
	main_node.add_child(r)


func _add_wall_strip(pos: Vector2, size: Vector2, color: Color):
	var r = ColorRect.new()
	r.color = color
	r.position = pos
	r.size = size
	r.z_index = -50
	main_node.add_child(r)


# ── Props（带碰撞的装饰物）──

func _generate_props(stage_id: int, hw: float, hh: float):
	# 优先从 decor_config 读取密度
	var dc = game_state.stage_data.get("decor_config", {})
	var props_cfg = dc.get("props", {})
	var cfg_density = props_cfg.get("density", -1.0)
	
	var density_map = {
		0: 0.0020, 1: 0.0015, 2: 0.0010, 3: 0.0018,
		4: 0.0012, 5: 0.0015, 6: 0.0015, 7: 0.0020,
		8: 0.0018, 9: 0.0,    10: 0.0015, 11: 0.0015,
		12: 0.0020, 13: 0.0012, 14: 0.0018, 15: 0.0
	}
	var density = density_map.get(stage_id, 0.0015)
	if cfg_density >= 0.0:
		density = cfg_density
	if density <= 0.0:
		return
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var target_count = int(game_state.map_width * game_state.map_height * density)
	var ref_area = 3200.0 * 2400.0
	var area_ratio = (game_state.map_width * game_state.map_height) / ref_area
	var area_scale = sqrt(area_ratio)
	var margin = clampf(80.0 * area_scale, 80.0, 200.0)
	var clear_radius = clampf(180.0 * area_scale, 180.0, 400.0)
	var min_dist = clampf(60.0 * area_scale, 60.0, 150.0)
	var max_props = clampi(int(60 * area_scale), 15, 500)
	target_count = clampi(target_count, 15, max_props)
	var attempts = target_count * 5
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
		for ep in obstacle_positions:
			if pos.distance_to(ep) < min_dist:
				too_close = true
				break
		if too_close:
			continue
		obstacle_positions.append(pos)
		placed += 1
		_make_stage_prop(stage_id, pos, rng)


func _make_stage_prop(stage_id: int, pos: Vector2, rng: RandomNumberGenerator):
	match stage_id:
		0:  _make_forest_prop(pos, rng)
		1:  _make_library_prop(pos, rng)
		2, 7: _make_meadow_prop(pos, rng)
		3, 12: _make_factory_prop(pos, rng)
		4:  _make_tower_prop(pos, rng)
		5:  _make_chapel_prop(pos, rng)
		6, 11: _make_ruins_prop(pos, rng)
		8, 14: _make_bone_prop(pos, rng)
		10: _make_ice_prop(pos, rng)
		13: _make_crystal_prop(pos, rng)


func _make_forest_prop(pos: Vector2, rng: RandomNumberGenerator):
	var prop_colors = game_state.get_meta("prop_colors", []) if game_state.has_meta("prop_colors") else []
	var green = prop_colors[0] if prop_colors.size() > 0 else Color(0.15, 0.35, 0.05)
	var dark_green = prop_colors[1] if prop_colors.size() > 1 else Color(0.25, 0.40, 0.10)
	var brown = prop_colors[2] if prop_colors.size() > 2 else Color(0.30, 0.20, 0.10)
	var roll = rng.randf()
	if roll < 0.45:
		var shade = rng.randf_range(0.15, 0.35)
		_make_collision_prop(pos, rng.randf_range(12.0, 20.0), Color(shade, shade + 0.35, shade + 0.05))
	elif roll < 0.70:
		var shade = rng.randf_range(0.25, 0.40)
		_make_collision_prop(pos, rng.randf_range(8.0, 14.0), Color(shade + 0.1, shade, shade))
	elif roll < 0.85:
		_make_rect_prop(pos, Vector2(rng.randf_range(8.0, 14.0), rng.randf_range(14.0, 20.0)), Color(0.3, 0.2, 0.1))
	else:
		_make_decoration(pos, rng.randf_range(6.0, 10.0), Color(0.15, 0.5, 0.1))


func _make_library_prop(pos: Vector2, rng: RandomNumberGenerator):
	var roll = rng.randf()
	if roll < 0.50:
		_make_rect_prop(pos, Vector2(rng.randf_range(24.0, 40.0), rng.randf_range(10.0, 16.0)), Color(0.25, 0.15, 0.05))
	elif roll < 0.75:
		_make_rect_prop(pos, Vector2(rng.randf_range(14.0, 18.0), rng.randf_range(14.0, 18.0)), Color(0.1, 0.05, 0.12))
	elif roll < 0.90:
		_make_rect_prop(pos, Vector2(rng.randf_range(30.0, 50.0), rng.randf_range(8.0, 12.0)), Color(0.2, 0.12, 0.06))
	else:
		_make_decoration(pos, rng.randf_range(3.0, 5.0), Color(0.9, 0.6, 0.1))


func _make_meadow_prop(pos: Vector2, rng: RandomNumberGenerator):
	var roll = rng.randf()
	if roll < 0.40:
		var shade = rng.randf_range(0.15, 0.35)
		_make_collision_prop(pos, rng.randf_range(10.0, 18.0), Color(shade, shade + 0.4, shade + 0.05))
	elif roll < 0.60:
		_make_rect_prop(pos, Vector2(6.0, 16.0), Color(0.3, 0.18, 0.08))
	elif roll < 0.80:
		_make_collision_prop(pos, rng.randf_range(8.0, 14.0), Color(0.55, 0.50, 0.15))
	else:
		_make_decoration(pos, rng.randf_range(4.0, 7.0), Color(0.7, 0.3, 0.5))


func _make_factory_prop(pos: Vector2, rng: RandomNumberGenerator):
	var roll = rng.randf()
	if roll < 0.35:
		_make_rect_prop(pos, Vector2(rng.randf_range(16.0, 24.0), rng.randf_range(12.0, 18.0)), Color(0.3, 0.2, 0.08))
	elif roll < 0.55:
		_make_collision_prop(pos, rng.randf_range(6.0, 12.0), Color(0.15, 0.15, 0.2))
	elif roll < 0.75:
		_make_collision_prop(pos, rng.randf_range(10.0, 16.0), Color(0.15, 0.2, 0.35))
	elif roll < 0.90:
		_make_rect_prop(pos, Vector2(rng.randf_range(20.0, 30.0), rng.randf_range(14.0, 20.0)), Color(0.5, 0.45, 0.2))
	else:
		_make_decoration(pos, rng.randf_range(5.0, 10.0), Color(0.3, 0.4, 0.5, 0.4))


func _make_tower_prop(pos: Vector2, rng: RandomNumberGenerator):
	var roll = rng.randf()
	if roll < 0.40:
		_make_rect_prop(pos, Vector2(rng.randf_range(20.0, 35.0), rng.randf_range(12.0, 18.0)), Color(0.2, 0.1, 0.06))
	elif roll < 0.60:
		_make_rect_prop(pos, Vector2(rng.randf_range(12.0, 18.0), rng.randf_range(18.0, 24.0)), Color(0.15, 0.12, 0.2))
	elif roll < 0.80:
		_make_decoration(pos, rng.randf_range(4.0, 8.0), Color(0.6, 0.2, 0.9, 0.6))
	else:
		_make_decoration(pos, rng.randf_range(3.0, 5.0), Color(0.9, 0.5, 0.1))


func _make_chapel_prop(pos: Vector2, rng: RandomNumberGenerator):
	var roll = rng.randf()
	if roll < 0.35:
		_make_collision_prop(pos, rng.randf_range(10.0, 16.0), Color(0.35, 0.3, 0.25))
	elif roll < 0.55:
		_make_rect_prop(pos, Vector2(rng.randf_range(30.0, 40.0), rng.randf_range(8.0, 12.0)), Color(0.3, 0.18, 0.08))
	elif roll < 0.75:
		_make_decoration(pos, rng.randf_range(4.0, 7.0), Color(0.9, 0.7, 0.2))
	elif roll < 0.90:
		_make_collision_prop(pos, rng.randf_range(6.0, 12.0), Color(0.25, 0.2, 0.18))
	else:
		_make_decoration(pos, rng.randf_range(6.0, 10.0), Color(0.9, 0.8, 0.3, 0.3))


func _make_ruins_prop(pos: Vector2, rng: RandomNumberGenerator):
	var roll = rng.randf()
	if roll < 0.40:
		_make_rect_prop(pos, Vector2(rng.randf_range(10, 18), rng.randf_range(6, 12)), Color(0.2, 0.18, 0.25))
	elif roll < 0.70:
		_make_collision_prop(pos, rng.randf_range(6, 12), Color(0.15, 0.12, 0.18))
	else:
		_make_decoration(pos, rng.randf_range(3, 6), Color(0.3, 0.5, 0.8, 0.5))


func _make_bone_prop(pos: Vector2, rng: RandomNumberGenerator):
	var roll = rng.randf()
	if roll < 0.50:
		_make_rect_prop(pos, Vector2(rng.randf_range(8, 16), rng.randf_range(4, 8)), Color(0.35, 0.3, 0.22))
	elif roll < 0.80:
		_make_collision_prop(pos, rng.randf_range(6, 10), Color(0.3, 0.25, 0.2))
	else:
		_make_decoration(pos, rng.randf_range(3, 5), Color(0.4, 0.35, 0.28))


func _make_ice_prop(pos: Vector2, rng: RandomNumberGenerator):
	var roll = rng.randf()
	if roll < 0.40:
		_make_collision_prop(pos, rng.randf_range(8, 14), Color(0.5, 0.55, 0.65, 0.6))
	elif roll < 0.70:
		_make_collision_prop(pos, rng.randf_range(10, 18), Color(0.6, 0.6, 0.65, 0.4))
	else:
		_make_decoration(pos, rng.randf_range(3, 5), Color(0.7, 0.75, 0.85, 0.6))


func _make_crystal_prop(pos: Vector2, rng: RandomNumberGenerator):
	var roll = rng.randf()
	if roll < 0.35:
		var hue = rng.randf_range(0.5, 0.9)
		_make_rect_prop(pos, Vector2(rng.randf_range(8, 14), rng.randf_range(12, 20)), Color.from_hsv(hue, 0.6, 0.5))
	elif roll < 0.65:
		_make_collision_prop(pos, rng.randf_range(8, 14), Color(0.15, 0.12, 0.2))
	else:
		_make_decoration(pos, rng.randf_range(2, 4), Color(0.9, 0.8, 1.0, 0.7))


func _make_collision_prop(pos: Vector2, radius: float, color: Color):
	var p = Prop.new()
	p.position = pos
	p.prop_color = color
	p.shape_type = "circle"
	p.shape_radius = radius
	p.outline_width = 2.0
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	p.add_child(shape)
	main_node.add_child(p)


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
	main_node.add_child(p)


func _make_decoration(pos: Vector2, radius: float, color: Color):
	var p = Prop.new()
	p.position = pos
	p.prop_color = color
	p.shape_type = "circle"
	p.shape_radius = radius
	p.outline_width = 0.0
	main_node.add_child(p)


# ── 边界墙 ──

func _add_boundary_walls(hw: float, hh: float):
	var ref_area = 3200.0 * 2400.0
	var area_ratio = (game_state.map_width * game_state.map_height) / ref_area
	var wall_thick = clampf(60.0 * sqrt(area_ratio), 60.0, 150.0)
	_add_boundary_wall(Vector2(0, -hh - wall_thick / 2.0), Vector2(game_state.map_width + wall_thick * 2, wall_thick))
	_add_boundary_wall(Vector2(0, hh + wall_thick / 2.0), Vector2(game_state.map_width + wall_thick * 2, wall_thick))
	_add_boundary_wall(Vector2(-hw - wall_thick / 2.0, 0), Vector2(wall_thick, game_state.map_height))
	_add_boundary_wall(Vector2(hw + wall_thick / 2.0, 0), Vector2(wall_thick, game_state.map_height))


func _add_boundary_wall(pos: Vector2, size: Vector2):
	var wall = StaticBody2D.new()
	wall.position = pos
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	wall.add_child(shape)
	main_node.add_child(wall)


# ── 交互元素 ──

func _add_interactive_elements(data: Dictionary, hw: float, hh: float):
	if data.is_empty():
		return
	
	var prop_manager = _get_or_create_prop_manager()
	
	for c in data.get("chests", []):
		var chest = TreasureChest.new()
		var sz = Vector2(28, 20) * c.get("size_f", 1.0)
		var col = c.get("color", Color(0.45, 0.3, 0.1))
		chest.setup(sz, col, player)
		chest.global_position = _clamp_to_map(c.get("pos", Vector2.ZERO), 30.0)
		main_node.add_child(chest)
		prop_manager.register_interactable(chest)
	
	for f in data.get("fountains", []):
		var fountain = HealingFountain.new()
		fountain.setup(f.get("radius", 24.0), f.get("heal_pct", 0.5), f.get("cooldown", 30.0), player)
		fountain.global_position = _clamp_to_map(f.get("pos", Vector2.ZERO), 30.0)
		main_node.add_child(fountain)
		prop_manager.register_interactable(fountain)
	
	var bd = data.get("breakable_density", 0.0)
	if bd > 0.0:
		_spawn_breakable_walls(bd, data.get("breakable_hp", 25.0), hw, hh, prop_manager)
	
	# Light sources (braziers) — from breakable_chance
	var breakable_chance = data.get("breakable_chance", -1.0)
	var max_breakable = data.get("max_breakable", 10)
	if breakable_chance > 0.0:
		_spawn_light_sources(breakable_chance, max_breakable, hw, hh, prop_manager)
	
	for h in data.get("hazards", []):
		var zone = HazardZone.new()
		zone.setup(h.get("size", Vector2(100, 100)), h.get("dps", 15.0), h.get("color", Color(0.8, 0.1, 0.05)), h.get("hurt_enemies", true))
		zone.global_position = _clamp_to_map(h.get("pos", Vector2.ZERO), 20.0)
		main_node.add_child(zone)
		prop_manager.register_hazard(zone)
	
	for b in data.get("boosts", []):
		var zone = BoostZone.new()
		zone.setup(b.get("type", "speed"), b.get("amount", 0.5), b.get("size", Vector2(80, 80)), b.get("color", Color.BLACK))
		zone.global_position = _clamp_to_map(b.get("pos", Vector2.ZERO), 20.0)
		main_node.add_child(zone)
		prop_manager.register_boost(zone)


func _spawn_breakable_walls(density: float, hp: float, hw: float, hh: float, prop_manager):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var ref_area = 3200.0 * 2400.0
	var area_ratio = (game_state.map_width * game_state.map_height) / ref_area
	var area_scale = sqrt(area_ratio)
	var margin = clampf(80.0 * area_scale, 80.0, 200.0)
	var clear_radius = clampf(180.0 * area_scale, 180.0, 400.0)
	var min_dist = clampf(80.0 * area_scale, 80.0, 200.0)
	var target_count = clampi(int(game_state.map_width * game_state.map_height * density), 5, 300)
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
		for ep in obstacle_positions:
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
		main_node.add_child(bw)
		prop_manager.register_interactable(bw)
		obstacle_positions.append(pos)
		placed += 1


func _spawn_light_sources(chance: float, max_count: int, hw: float, hh: float, prop_manager):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var ref_area = 3200.0 * 2400.0
	var area_ratio = (game_state.map_width * game_state.map_height) / ref_area
	var area_scale = sqrt(area_ratio)
	var margin = clampf(80.0 * area_scale, 80.0, 200.0)
	var clear_radius = clampf(180.0 * area_scale, 180.0, 400.0)
	var min_dist = clampf(80.0 * area_scale, 80.0, 200.0)
	var scaled_max = int(max_count * area_ratio)
	var placed = 0
	var attempts = scaled_max * 10

	for _a in range(attempts):
		if placed >= scaled_max:
			break
		if rng.randf() > chance:
			continue
		var x = rng.randf_range(-hw + margin, hw - margin)
		var y = rng.randf_range(-hh + margin, hh - margin)
		var pos = Vector2(x, y)
		if pos.length() < clear_radius:
			continue
		var too_close = false
		for ep in obstacle_positions:
			if pos.distance_to(ep) < min_dist:
				too_close = true
				break
		if too_close:
			continue

		var sz = rng.randf_range(16, 24)
		var brazier = BreakableWall.new()
		brazier.setup(Vector2(sz, sz * 1.3), Color(0.6, 0.3, 0.05), 15.0, player)
		brazier.global_position = pos
		brazier.wall_destroyed.connect(_on_breakable_destroyed)
		main_node.add_child(brazier)
		prop_manager.register_interactable(brazier)
		obstacle_positions.append(pos)
		placed += 1


func _on_breakable_destroyed(pos: Vector2):
	var idx = obstacle_positions.find(pos)
	if idx >= 0:
		obstacle_positions.remove_at(idx)
		obstacle_removed.emit(pos)
	EventBus.light_source_destroyed.emit()


func _get_or_create_prop_manager() -> Node:
	for c in main_node.get_children():
		if c is PropManager:
			return c
	var pm = PropManager.new()
	pm.name = "PropManager"
	pm.setup(main_node)
	main_node.add_child(pm)
	return pm


func _scatter_initial_pickups(count: int, hw: float, hh: float):
	# 由 main.gd 处理实际生成（需要访问 pickup 场景和 GemPool）
	# 此处仅提供位置数组供外部使用
	pass


func _clamp_to_map(pos: Vector2, margin: float = 40.0) -> Vector2:
	var hw = game_state.map_width / 2.0 - margin
	var hh = game_state.map_height / 2.0 - margin
	return Vector2(clamp(pos.x, -hw, hw), clamp(pos.y, -hh, hh))
