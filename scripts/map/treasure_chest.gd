extends StaticBody2D
# Treasure chest — player presses E to open and receive loot.

class_name TreasureChest
#
# - Blocks player movement until opened
# - Shows "Press [E] to open" when player is near
# - Drops random loot: XP gems, gold, chance of weapon/passive upgrade
# - One-time use (can_interact = false after opening)
#
# Add to scene via setup() before adding to tree.

# _gem_scene removed — using GemPool.borrow()

# ── Visual ──
var chest_color: Color = Color(0.45, 0.3, 0.1)
var lid_color: Color = Color(0.6, 0.4, 0.12)
var chest_size: Vector2 = Vector2(28, 20)
var _open: bool = false

# ── Interaction ──
var interaction_prompt: String = "Press [E] to open"
var interaction_range: float = 70.0
var can_interact: bool = true

# ── Loot config ──
var min_xp: int = 5
var max_xp: int = 15
var gold_chance: float = 0.5
var item_chance: float = 0.15  # chance to spawn a stage item pickup

var _player_ref: Node2D = null


func _ready():
	# Physical collision
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = chest_size
	shape.shape = rect
	add_child(shape)
	
	add_to_group("interactables")


func _draw():
	var half = chest_size / 2.0
	
	if _open:
		# Opened chest — dark interior with gold glint
		draw_rect(Rect2(-half, chest_size), Color(0.15, 0.1, 0.05))
		draw_rect(Rect2(-half, chest_size), Color(0.3, 0.2, 0.1), false, 1.5)
		# Gold glint
		draw_circle(Vector2(0, 0), 4.0, Color(0.9, 0.7, 0.1, 0.6))
	else:
		# Closed chest — brown body
		draw_rect(Rect2(-half, chest_size), chest_color)
		# Lid (top rectangle)
		var lid_h = chest_size.y * 0.35
		draw_rect(Rect2(-half.x, -half.y - lid_h, chest_size.x, lid_h), lid_color)
		# Outline
		draw_rect(Rect2(-half, chest_size), Color(0.2, 0.12, 0.04), false, 1.5)
		# Lock / clasp
		draw_rect(Rect2(-3, -2, 6, 4), Color(0.8, 0.7, 0.2))


func interact(player: Node2D) -> bool:
	if _open or not can_interact:
		return false
	_open = true
	can_interact = false
	queue_redraw()
	
	# Spawn loot
	_spawn_loot(player)
	return true


func _spawn_loot(player: Node2D):
	# XP gems
	var gem_count = 2 + randi() % 3
	for i in range(gem_count):
		var gem = GemPool.borrow()
		gem.value = randi_range(min_xp, max_xp)
		gem.player = player
		gem.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))
		get_parent().add_child(gem)
	
	# Gold
	if randf() < gold_chance:
		var main = get_parent()
		if main and main.has_method("_spawn_pickup_at"):
			main._spawn_pickup_at(global_position, 1)  # GOLD
	
	# Chance for extra gold instead of stage item
	if randf() < item_chance:
		var main = get_parent()
		if main and main.has_method("_spawn_pickup_at"):
			main._spawn_pickup_at(global_position, 1)


func setup(size: Vector2, color: Color, player_ref: Node2D):
	chest_size = size
	chest_color = color
	lid_color = Color(color.r * 1.3, color.g * 1.3, color.b * 1.3)
	_player_ref = player_ref
