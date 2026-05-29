extends StaticBody2D
# Breakable wall — blocks movement until destroyed by weapons.
#
# - Collision layer = ENEMY (bit 2) so projectile weapons detect it
# - Added to "enemies" group so aura/melee weapons also hit it
# - Has take_damage() like enemies; handles own death without emitting died signal
# - Drops XP gems + chance of gold/chicken when destroyed

class_name BreakableWall

signal wall_destroyed(pos: Vector2)

const CollisionLayers = preload("res://scripts/data/collision_layers.gd")
const _gem_scene = preload("res://scenes/xp_gem.tscn")

# ── Visual properties ──
var wall_color: Color = Color(0.25, 0.2, 0.15)
var wall_size: Vector2 = Vector2(30, 30)

# ── Combat ──
var max_hp: float = 30.0
var hp: float = 30.0
var xp_drop: int = 3
var gold_drop_chance: float = 0.15
var chicken_drop_chance: float = 0.10

# ── Knockback (like props getting pushed) ──
var knockback_velocity: Vector2 = Vector2.ZERO
const KNOCKBACK_DECAY: float = 6.0

var _player_ref: Node2D = null
var _hit_flash: float = 0.0
var _destroyed: bool = false


func _ready():
	hp = max_hp
	collision_layer = CollisionLayers.ENEMY
	collision_mask = 0
	add_to_group("breakables")
	
	# Collision shape
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = wall_size
	shape.shape = rect
	add_child(shape)


func _draw():
	var half = wall_size / 2.0
	var col = wall_color
	if _hit_flash > 0.0:
		col = Color(1.0, 1.0, 1.0, 0.8)
	
	draw_rect(Rect2(-half, wall_size), col)
	# Outline
	draw_rect(Rect2(-half, wall_size), col * 0.6, false, 2.0)
	
	# Cracks based on damage taken
	if hp < max_hp * 0.75:
		var crack_col = Color(0.1, 0.1, 0.1, 0.5)
		draw_line(Vector2(-half.x * 0.3, -half.y * 0.2), Vector2(half.x * 0.2, half.y * 0.1), crack_col, 1.5)
	if hp < max_hp * 0.40:
		var crack_col2 = Color(0.1, 0.1, 0.1, 0.6)
		draw_line(Vector2(half.x * 0.1, -half.y * 0.4), Vector2(-half.x * 0.4, half.y * 0.3), crack_col2, 1.5)
		draw_line(Vector2(-half.x * 0.5, half.y * 0.2), Vector2(half.x * 0.5, -half.y * 0.1), crack_col2, 1.0)


func _process(delta):
	if _hit_flash > 0.0:
		_hit_flash -= delta
		queue_redraw()
	
	# Apply knockback decay
	if knockback_velocity.length_squared() > 1.0:
		position += knockback_velocity * delta
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)


## Called by weapon projectiles / auras when they hit this wall.
func take_damage(dmg: float, _src_pos: Vector2 = Vector2.ZERO):
	if not is_inside_tree() or _destroyed:
		return
	
	hp -= dmg
	_hit_flash = 0.1
	queue_redraw()
	
	if hp <= 0:
		_destroy()


func _destroy():
	if _destroyed:
		return
	_destroyed = true
	wall_destroyed.emit(global_position)
	
	# Spawn XP gems
	var gem_count = 1 + randi() % 2
	for i in range(gem_count):
		var gem = _gem_scene.instantiate()
		gem.value = xp_drop
		if _player_ref and is_instance_valid(_player_ref):
			gem.player = _player_ref
		gem.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		get_parent().add_child(gem)
	
	# Chance to drop gold
	if randf() < gold_drop_chance:
		_find_main_and_spawn_pickup(1)  # 1 = GOLD
	
	# Chance to drop chicken
	if randf() < chicken_drop_chance:
		_find_main_and_spawn_pickup(0)  # 0 = CHICKEN
	
	# Tiny chance to drop rosary
	if randf() < 0.02:
		_find_main_and_spawn_pickup(2)  # 2 = ROSARY
	
	# Tiny chance to drop vacuum
	if randf() < 0.01:
		_find_main_and_spawn_pickup(3)  # 3 = VACUUM
	
	queue_free()


func _find_main_and_spawn_pickup(pickup_type: int):
	var main = get_parent()
	if main and main.has_method("_spawn_pickup_at"):
		main._spawn_pickup_at(global_position, pickup_type)


## Initialize wall properties before adding to tree.
func setup(size: Vector2, color: Color, health: float, player_ref: Node2D):
	wall_size = size
	wall_color = color
	max_hp = health
	hp = health
	_player_ref = player_ref
