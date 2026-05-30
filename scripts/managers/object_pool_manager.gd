extends Node
# ObjectPoolManager - 统一对象池管理器
# 合并 GemPool + FloatingTextPool + EnemyProjectilePool
# 支持任意场景类型,按资源路径索引
#
# 用法:
#   ObjectPoolManager.borrow("res://scenes/xp_gem.tscn")
#   ObjectPoolManager.return_obj(obj)

const POOL_SIZE_PER_TYPE := 32

# { scene_path: [pooled_nodes] }
var _pools: Dictionary = {}

# 场景缓存
var _scenes: Dictionary = {}

# 预设池大小(可针对不同类型覆盖)
var _pool_sizes: Dictionary = {}

# 场景路径常量(用于 preload)
const _SCENE_GEM := "res://scenes/xp_gem.tscn"
const _SCENE_FT := "res://scenes/floating_text.tscn"
const _SCENE_PROJ := "res://scenes/enemy_projectile.tscn"

# 已借出节点跟踪(用于调试/泄漏检测)
var _borrowed_count: Dictionary = {}


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	# 池不再预填充 —— 改为懒填充，首次 borrow() 时创建
	_pool_sizes[_SCENE_GEM] = POOL_SIZE_PER_TYPE
	_pool_sizes[_SCENE_FT] = POOL_SIZE_PER_TYPE
	_pool_sizes[_SCENE_PROJ] = POOL_SIZE_PER_TYPE


func _prefill_pool(scene_path: String, count: int):
	if not _scenes.has(scene_path):
		_scenes[scene_path] = load(scene_path)
	var scene = _scenes[scene_path]

	if not _pools.has(scene_path):
		_pools[scene_path] = []
	
	for i in range(count):
		var obj = scene.instantiate()
		obj.set_meta("_pool_scene_path", scene_path)  # 标记场景路径，_get_scene_path 用
		_reset_for_pool(obj)
		_pools[scene_path].append(obj)
		add_child(obj)
	
	_borrowed_count[scene_path] = 0


# 从池中借出一个节点
func borrow(scene_path: String) -> Node:
	var pool = _pools.get(scene_path)
	if pool == null:
		# 懒填充：首次访问时创建池
		_prefill_pool(scene_path, _pool_sizes.get(scene_path, 8))
		pool = _pools[scene_path]

	var obj: Node = null
	while pool.size() > 0:
		obj = pool.pop_back()
		if is_instance_valid(obj):
			break
		obj = null

	if obj == null:
		# 池为空，创建新实例
		if not _scenes.has(scene_path):
			_scenes[scene_path] = load(scene_path)
		obj = _scenes[scene_path].instantiate()
		# 新实例也需要标记
		obj.set_meta("_pool_scene_path", scene_path)
	
	# 从池容器中移除（如果父节点是池管理器）
	if obj.get_parent() == self:
		remove_child(obj)
	
	# 恢复处理模式（_reset_for_pool 设置了 DISABLED）
	obj.process_mode = PROCESS_MODE_INHERIT

	_borrowed_count[scene_path] = _borrowed_count.get(scene_path, 0) + 1
	return obj


# 归还节点到池
func return_obj(obj: Node):
	if not is_instance_valid(obj):
		return

	var scene_path = _get_scene_path(obj)
	if scene_path == "":
		obj.queue_free()
		return

	if obj.get_parent():
		obj.get_parent().remove_child(obj)

	_reset_for_pool(obj)

	var pool = _pools.get(scene_path)
	if pool == null:
		_pools[scene_path] = []
		pool = _pools[scene_path]

	if pool.size() < _pool_sizes.get(scene_path, POOL_SIZE_PER_TYPE):
		pool.append(obj)
		add_child(obj)
	else:
		obj.queue_free()

	_borrowed_count[scene_path] = max(_borrowed_count.get(scene_path, 0) - 1, 0)


func _reset_for_pool(obj: Node):
	obj.visible = false
	obj.set_process(false)
	obj.set_physics_process(false)
	obj.process_mode = PROCESS_MODE_DISABLED

	# 清理碰撞
	if obj is Area2D or obj is CharacterBody2D or obj is StaticBody2D:
		obj.collision_layer = 0
		obj.collision_mask = 0

	# 移除分组
	for group in obj.get_groups():
		if group != "":  # 保留默认组
			obj.remove_from_group(group)

	# 调用自定义重置方法(如果存在)
	if obj.has_method("_pool_reset"):
		obj._pool_reset()


# 通过 metadata 获取节点场景路径
func _get_scene_path(obj: Node) -> String:
	if obj.has_meta("_pool_scene_path"):
		return obj.get_meta("_pool_scene_path")
	# 兜底：检查场景文件路径
	if obj.has_method("get_scene_file_path"):
		return obj.get_scene_file_path()
	return ""


# ── 向后兼容方法（委托给 _pool_borrow） ──

var _gem_throttle_counter: int = 0

func borrow_gem() -> Node:
	var gem = borrow(_SCENE_GEM)
	if gem.has_method("_pool_borrow"):
		gem._pool_borrow()
	gem._throttle_offset = _gem_throttle_counter
	_gem_throttle_counter = (_gem_throttle_counter + 1) % 4
	return gem


func return_gem(gem: Node):
	if gem.get_parent():
		gem.get_parent().remove_child(gem)
	gem.attracted = false
	gem.player = null
	gem.value = 2
	gem.tier = 0
	gem.remove_from_group("gems")
	return_obj(gem)


func spawn_ft(parent: Node, world_pos: Vector2, text: String, color: Color = Color.WHITE, size: int = 18) -> Node2D:
	var ft = borrow(_SCENE_FT)
	if ft.has_method("_pool_borrow"):
		ft._pool_borrow({"text": text, "color": color, "size": size, "position": world_pos})
	else:
		ft.display_text = text
		ft.text_color = color
		ft.font_size = size
		ft.global_position = world_pos
		ft.velocity = Vector2(randf_range(-15, 15), -50)
		ft.lifetime = 0.5
		ft.age = 0.0
		ft.visible = true
		ft.set_process(true)
		ft.modulate = Color(1, 1, 1, 1)
	parent.add_child(ft)
	return ft


func return_ft(ft: Node2D):
	if ft.get_parent():
		ft.get_parent().remove_child(ft)
	return_obj(ft)


func borrow_enemy_proj(target: Node2D, speed: float, damage: float, lifetime: float) -> Node2D:
	var proj = borrow(_SCENE_PROJ)
	if proj.has_method("_pool_borrow"):
		proj._pool_borrow({"target": target, "speed": speed, "damage": damage, "lifetime": lifetime})
	else:
		proj.reset(target, speed, damage, lifetime)
	return proj


func return_enemy_proj(proj: Node2D):
	return_obj(proj)
