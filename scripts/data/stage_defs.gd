extends RefCounted
# Stage definitions — 按需加载的关卡数据注册器
# 各关卡数据存储于独立文件 scripts/data/stages/stage_{id}.gd
# 通过 load() 运行时加载，实现按需导入

const STAGE_COUNT := 16

# 缓存已加载的关卡数据
static var _cache: Dictionary = {}

static var _all_ids: Array[int] = []


static func _init_ids():
	if _all_ids.is_empty():
		for i in range(STAGE_COUNT):
			_all_ids.append(i)


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
