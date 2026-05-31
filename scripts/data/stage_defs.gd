extends RefCounted
# Stage definitions — 按需加载的关卡数据注册器
# 各关卡数据存储于独立文件 scripts/data/stages/stage_{id}.gd
# 通过 load() 运行时加载，实现按需导入
#
# 选关界面使用 get_stage_meta() 获取轻量元数据（不加载完整关卡文件）。
# 实际游戏启动时通过 get_stage() 加载完整数据。

const STAGE_COUNT := 21

# 缓存已加载的关卡完整数据
static var _cache: Dictionary = {}

# 选关界面元数据缓存（轻量，无需加载 .gd 文件）
static var _meta_cache: Array[Dictionary] = []

static var _all_ids: Array[int] = []


static func _init_ids():
	if _all_ids.is_empty():
		for i in range(STAGE_COUNT):
			_all_ids.append(i)


static func _init_meta():
	if not _meta_cache.is_empty():
		return
	_meta_cache = [
		{ "id": 0, "bg_color": Color(0.04, 0.04, 0.10), "time_limit": 1800.0, "move_speed_mod": 1.1, "gold_mod": 1.0, "unlock_req": "", "stage_items": [] },
		{ "id": 1, "bg_color": Color(0.08, 0.02, 0.12), "time_limit": 1800.0, "move_speed_mod": 1.25, "gold_mod": 1.0, "unlock_req": "clear_stage_0", "stage_items": [] },
		{ "id": 2, "bg_color": Color(0.06, 0.16, 0.04), "time_limit": 900.0, "move_speed_mod": 1.0, "gold_mod": 1.0, "unlock_req": "clear_stage_1", "stage_items": [] },
		{ "id": 3, "bg_color": Color(0.08, 0.06, 0.16), "time_limit": 1800.0, "move_speed_mod": 1.25, "gold_mod": 1.2, "unlock_req": "clear_stage_2", "stage_items": [] },
		{ "id": 4, "bg_color": Color(0.12, 0.02, 0.18), "time_limit": 1800.0, "move_speed_mod": 1.25, "gold_mod": 1.3, "unlock_req": "clear_stage_3", "stage_items": [] },
		{ "id": 5, "bg_color": Color(0.18, 0.04, 0.06), "time_limit": 1800.0, "move_speed_mod": 1.4, "gold_mod": 1.4, "unlock_req": "clear_stage_4", "stage_items": [] },
		{ "id": 6, "bg_color": Color(0.02, 0.04, 0.15), "time_limit": 900.0, "move_speed_mod": 1.35, "gold_mod": 1.0, "unlock_req": "clear_stage_5", "stage_items": [] },
		{ "id": 7, "bg_color": Color(0.06, 0.18, 0.06), "time_limit": 1800.0, "move_speed_mod": 1.25, "gold_mod": 1.0, "unlock_req": "reach_level_40", "stage_items": [] },
		{ "id": 8, "bg_color": Color(0.06, 0.04, 0.08), "time_limit": 1800.0, "move_speed_mod": 1.25, "gold_mod": 1.5, "unlock_req": "reach_level_50", "stage_items": [] },
		{ "id": 9, "bg_color": Color(0.15, 0.02, 0.02), "time_limit": 900.0, "move_speed_mod": 1.25, "gold_mod": 1.5, "unlock_req": "reach_level_60", "stage_items": [] },
		{ "id": 10, "bg_color": Color(0.1, 0.12, 0.18), "time_limit": 1200.0, "move_speed_mod": 1.35, "gold_mod": 1.0, "unlock_req": "clear_stage_3", "stage_items": [] },
		{ "id": 11, "bg_color": Color(0.04, 0.1, 0.16), "time_limit": 1200.0, "move_speed_mod": 1.0, "gold_mod": 1.2, "unlock_req": "clear_stage_4", "stage_items": [] },
		{ "id": 12, "bg_color": Color(0.08, 0.12, 0.04), "time_limit": 1200.0, "move_speed_mod": 1.35, "gold_mod": 1.0, "unlock_req": "reach_level_30", "stage_items": [] },
		{ "id": 13, "bg_color": Color(0.02, 0.02, 0.14), "time_limit": 1200.0, "move_speed_mod": 1.25, "gold_mod": 1.3, "unlock_req": "reach_level_55", "stage_items": [] },
		{ "id": 14, "bg_color": Color(0.04, 0.02, 0.06), "time_limit": 1200.0, "move_speed_mod": 1.25, "gold_mod": 1.3, "unlock_req": "reach_level_65", "stage_items": [] },
		{ "id": 15, "bg_color": Color(0.14, 0.08, 0.02), "time_limit": 5940.0, "move_speed_mod": 1.0, "gold_mod": 2.0, "unlock_req": "relic_yellow_sign", "stage_items": [] },
		{ "id": 16, "bg_color": Color(0.08, 0.02, 0.16), "time_limit": 1800.0, "move_speed_mod": 1.3, "gold_mod": 1.5, "unlock_req": "clear_stage_5", "stage_items": [] },
		{ "id": 17, "bg_color": Color(0.02, 0.06, 0.18), "time_limit": 1800.0, "move_speed_mod": 1.25, "gold_mod": 1.5, "unlock_req": "reach_level_65", "stage_items": [] },
		{ "id": 18, "bg_color": Color(0.16, 0.08, 0.02), "time_limit": 1800.0, "move_speed_mod": 1.2, "gold_mod": 1.6, "unlock_req": "reach_level_70", "stage_items": [] },
		{ "id": 19, "bg_color": Color(0.06, 0.14, 0.06), "time_limit": 1200.0, "move_speed_mod": 1.0, "gold_mod": 1.3, "unlock_req": "reach_level_75", "stage_items": [] },
		{ "id": 20, "bg_color": Color(0.1, 0.16, 0.04), "time_limit": 1800.0, "move_speed_mod": 1.3, "gold_mod": 1.5, "unlock_req": "reach_level_80", "stage_items": [] },
	]


static func get_stage(id: int) -> Dictionary:
	if _cache.has(id):
		return _cache[id]
	var path = "res://scripts/data/stages/stage_" + str(id) + ".gd"
	var script = load(path)
	if script and script.has_method("get_data"):
		var data: Dictionary = script.get_data()
		_cache[id] = data
		return data
	# fallback: load stage 0
	if id != 0:
		return get_stage(0)
	return {}


# 选关界面用 —— 只返回元数据，不加载完整关卡文件
static func get_stage_meta(id: int) -> Dictionary:
	_init_meta()
	for m in _meta_cache:
		if m.get("id") == id:
			return m
	return {}


static func get_all_stage_meta() -> Array[Dictionary]:
	_init_meta()
	return _meta_cache.duplicate(true)


static func get_stage_count() -> int:
	return STAGE_COUNT


static func get_all_stage_ids() -> Array[int]:
	_init_ids()
	return _all_ids.duplicate()


static func get_all_stages() -> Array[Dictionary]:
	_init_ids()
	var result: Array[Dictionary] = []
	for id in _all_ids:
		result.append(get_stage(id))
	return result


static func get_stage_id_for_hyper(unlock_key: String) -> int:
	_init_ids()
	for id in _all_ids:
		var s = get_stage(id)
		if s.get("hyper_unlock", "") == unlock_key:
			return id
	return -1


static func invalidate_cache():
	_cache.clear()
	_meta_cache.clear()
