extends RefCounted
# Relic 系统测试套件
# 在 headless 模式下，autoload (RelicManager, PowerUpManager) 由引擎自动加载。
# 场景 (Node, Area2D) 也可以正常实例化。

const RelicDefs = preload("res://scripts/data/relic_defs.gd")
const StageDefs = preload("res://scripts/data/stage_defs.gd")
const Player = preload("res://scripts/entities/player.gd")

var results: Dictionary = {}

func run_all() -> Dictionary:
	results = {}
	
	# ── 纯数据测试 ──
	_test("data_integrity", _test_data_integrity)
	_test("ids_unique", _test_ids_unique)
	_test("stage_ids_valid", _test_stage_ids_valid)
	_test("spawn_in_bounds", _test_spawn_in_bounds)
	_test("stage_query", _test_stage_query)
	
	# ── RelicManager 逻辑测试 ──
	if RelicManager != null:
		_test("collect_roundtrip", _test_collect_roundtrip)
		_test("duplicate_collect", _test_duplicate_collect)
		_test("invalid_relic", _test_invalid_relic)
		_test("save_persistence", _test_save_persistence)
	else:
		results["collect_roundtrip"] = {"passed": false, "message": "SKIP: RelicManager not available"}
		results["duplicate_collect"] = {"passed": false, "message": "SKIP: RelicManager not available"}
		results["invalid_relic"] = {"passed": false, "message": "SKIP: RelicManager not available"}
		results["save_persistence"] = {"passed": false, "message": "SKIP: RelicManager not available"}
	
	# ── 场景集成测试 ──
	_test("relic_pickup_entity", _test_relic_pickup_entity)
	_test("player_limit_break", _test_player_limit_break)
	_test("hud_relic_arrow", _test_hud_relic_arrow)
	
	return results


func _test(name: String, fn: Callable):
	results[name] = fn.call()


# ═══════════════════════════════════════════════════════════
#  数据层测试
# ═══════════════════════════════════════════════════════════

func _test_data_integrity() -> Dictionary:
	var required = ["id", "name", "desc", "effect", "stage_id", "spawn_pos", "color", "icon_shape"]
	for r in RelicDefs.RELICS:
		for f in required:
			if not r.has(f):
				return {"passed": false, "message": "'%s' missing: %s" % [r.get("id","?"), f]}
	return {"passed": true, "message": "%d relics OK" % RelicDefs.RELICS.size()}


func _test_ids_unique() -> Dictionary:
	var ids = []
	for r in RelicDefs.RELICS:
		if ids.has(r["id"]):
			return {"passed": false, "message": "duplicate: " + r["id"]}
		ids.append(r["id"])
	return {"passed": true, "message": "%d unique IDs" % ids.size()}


func _test_stage_ids_valid() -> Dictionary:
	var sids = []
	for s in StageDefs.STAGES:
		sids.append(s["id"])
	for r in RelicDefs.RELICS:
		if not sids.has(r["stage_id"]):
			return {"passed": false, "message": "'%s' stage %d not found" % [r["id"], r["stage_id"]]}
	return {"passed": true, "message": "all stage IDs valid"}


func _test_spawn_in_bounds() -> Dictionary:
	for r in RelicDefs.RELICS:
		var stage = StageDefs.get_stage(r["stage_id"])
		var hw = stage.get("map_width", 3200) / 2.0
		var hh = stage.get("map_height", 2400) / 2.0
		var p = r["spawn_pos"]
		if abs(p.x) > hw or abs(p.y) > hh:
			return {"passed": false, "message": "'%s' pos (%.0f,%.0f) outside stage %d" % [r["id"], p.x, p.y, r["stage_id"]]}
	return {"passed": true, "message": "all positions in bounds"}


func _test_stage_query() -> Dictionary:
	var counts = {}
	for r in RelicDefs.RELICS:
		counts[r["stage_id"]] = counts.get(r["stage_id"], 0) + 1
	for sid in counts:
		var list = RelicDefs.get_relics_for_stage(sid)
		if list.size() != counts[sid]:
			return {"passed": false, "message": "stage %d expected %d got %d" % [sid, counts[sid], list.size()]}
	return {"passed": true, "message": "stage query OK"}


# ═══════════════════════════════════════════════════════════
#  RelicManager 逻辑测试
# ═══════════════════════════════════════════════════════════

func _test_collect_roundtrip() -> Dictionary:
	# 尝试找一个未收集的 relic
	var target = ""
	for r in RelicDefs.RELICS:
		if not RelicManager.has_relic(r["id"]):
			target = r["id"]
			break
	if target.is_empty():
		# 全都收集过了 — 验证 has_relic 对已有的返回 true
		var ok = true
		for r in RelicDefs.RELICS:
			if not RelicManager.has_relic(r["id"]):
				ok = false
		return {"passed": ok, "message": "all relics collected, has_relic verified"}
	if not RelicManager.collect_relic(target):
		return {"passed": false, "message": "collect_relic failed"}
	if not RelicManager.has_relic(target):
		return {"passed": false, "message": "has_relic false after collect"}
	return {"passed": true, "message": "'%s' roundtrip OK" % target}


func _test_duplicate_collect() -> Dictionary:
	var collected = ""
	for r in RelicDefs.RELICS:
		if RelicManager.has_relic(r["id"]):
			collected = r["id"]
			break
	if collected.is_empty():
		for r in RelicDefs.RELICS:
			RelicManager.collect_relic(r["id"])
			collected = r["id"]
			break
	if RelicManager.collect_relic(collected) != false:
		return {"passed": false, "message": "duplicate collect should return false"}
	return {"passed": true, "message": "duplicate blocked OK"}


func _test_invalid_relic() -> Dictionary:
	if RelicManager.collect_relic("does_not_exist") != false:
		return {"passed": false, "message": "invalid collect should return false"}
	return {"passed": true, "message": "invalid blocked OK"}


func _test_save_persistence() -> Dictionary:
	RelicManager.call("_save_data")
	var path = "user://desire_survivors_save.json"
	if not FileAccess.file_exists(path):
		return {"passed": false, "message": "save file not found"}
	var f = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	json.parse(f.get_as_text())
	f.close()
	var data = json.data
	if not data.has("relics"):
		return {"passed": false, "message": "save missing relics field"}
	return {"passed": true, "message": "relics field OK in save file"}


# ═══════════════════════════════════════════════════════════
#  场景集成测试 — 需要场景树 / Node 实例化
# ═══════════════════════════════════════════════════════════

func _test_relic_pickup_entity() -> Dictionary:
	# 实例化 relic pickup 场景（不添加到树，只验证脚本能加载）
	var scene = load("res://scenes/relic_pickup.tscn")
	if not scene:
		return {"passed": false, "message": "relic_pickup.tscn failed to load"}
	var instance = scene.instantiate()
	if not instance:
		return {"passed": false, "message": "relic_pickup instantiate failed"}
	if not instance.has_method("initialize"):
		return {"passed": false, "message": "relic_entity missing initialize()"}
	# 验证 collision shape
	var shapes = []
	for c in instance.get_children():
		if c is CollisionShape2D:
			shapes.append(c)
	if shapes.is_empty():
		return {"passed": false, "message": "relic_entity has no collision shape"}
	instance.queue_free()
	return {"passed": true, "message": "relic_pickup.tscn loads + instantiates OK"}


func _test_player_limit_break() -> Dictionary:
	# 验证 WeaponState 的 max_level 受 Great Gospel 影响
	# 注意: 这个测试有副作用（会 collect relic）
	var had_gospel = RelicManager.has_relic("great_gospel")
	if not had_gospel:
		RelicManager.collect_relic("great_gospel")
	
	# 创建 WeaponState（不依赖 player 实例）
	var ws = Player.WeaponState.new(Player.UpgradeType.WHIP)
	if ws.max_level != 20:
		# 还原状态
		return {"passed": false, "message": "with Gospel, max_level should be 20, got %d" % ws.max_level}
	
	# 升级验证
	ws.level = 8
	ws.upgrade()
	if ws.level != 9:
		return {"passed": false, "message": "upgrade past 8 failed, level=%d" % ws.level}
	if ws.damage <= 0:
		return {"passed": false, "message": "damage not set after upgrade"}
	
	# 还原
	if not had_gospel:
		# 没办法 uncollect — 这是测试副作用，接受
		pass
	
	return {"passed": true, "message": "limit break max_level=%d, upgrade past 8 works" % ws.max_level}


func _test_hud_relic_arrow() -> Dictionary:
	# 创建 HUD 实例（需要场景树才能正常绘制，但至少验证脚本加载）
	var hud_script = load("res://scripts/ui/hud.gd")
	if not hud_script:
		return {"passed": false, "message": "hud.gd failed to load"}
	
	# 验证 set_relic_arrow 方法存在
	var test_hud = hud_script.new()
	if not test_hud:
		return {"passed": false, "message": "hud instance failed"}
	if not test_hud.has_method("set_relic_arrow"):
		return {"passed": false, "message": "hud missing set_relic_arrow"}
	
	test_hud.set_relic_arrow(1.5, 200.0)
	# 无法断言绘制结果，但至少方法可以调用
	test_hud.queue_free()
	return {"passed": true, "message": "hud.gd loads, set_relic_arrow callable"}
