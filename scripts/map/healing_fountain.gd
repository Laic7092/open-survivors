extends StaticBody2D
# Healing fountain — player presses E to restore HP.

class_name HealingFountain
#
# - Blocks player movement
# - Shows "Press [E] to heal" when player is near  
# - Heals a percentage of max HP
# - Has cooldown between uses
#
# Add via setup() before adding to tree.

# ── Visual ──
var pool_color: Color = Color(0.1, 0.5, 0.8, 0.4)
var rim_color: Color = Color(0.4, 0.4, 0.4)
var pool_radius: float = 24.0

# ── Interaction ──
var interaction_prompt: String = ""
var interaction_range: float = 70.0
var can_interact: bool = true

# ── Healing config ──
var heal_percent: float = 0.50      # heal 50% of max HP
var cooldown_time: float = 30.0     # seconds between uses

var _player_ref: Node2D = null

# Cooldown timer (replaces _process accumulator)
var _cooldown_timer: Timer


func _ready():
	interaction_prompt = I18N.t("interact.heal")

	# Physical collision basin
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = pool_radius
	shape.shape = circle
	add_child(shape)
	
	# Cooldown timer (node-based, no _process overhead)
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	_cooldown_timer.timeout.connect(_on_cooldown_end)
	add_child(_cooldown_timer)
	
	add_to_group("interactables")


func _draw():
	# Stone rim (static — redrawn only on state change, not every frame)
	var r = pool_radius
	draw_circle(Vector2.ZERO, r, rim_color)
	draw_circle(Vector2.ZERO, r, Color(0.25, 0.25, 0.25), false, 2.0)
	
	# Water pool — dim when on cooldown
	var water_r = r * 0.7
	var water_col = pool_color if can_interact else Color(0.15, 0.15, 0.15, 0.3)
	draw_circle(Vector2.ZERO, water_r, water_col)
	
	# Healing cross (static, no shimmer)
	if can_interact:
		var cross_sz = water_r * 0.35
		var white = Color(1.0, 1.0, 1.0, 0.3)
		draw_rect(Rect2(-cross_sz * 0.25, -cross_sz, cross_sz * 0.5, cross_sz * 2), white)
		draw_rect(Rect2(-cross_sz, -cross_sz * 0.25, cross_sz * 2, cross_sz * 0.5), white)


func interact(player: Node2D) -> bool:
	if not can_interact or not is_instance_valid(player):
		return false
	
	var heal_amt = ceil(player.max_health * heal_percent)
	player.heal(heal_amt)
	
	# Start cooldown
	can_interact = false
	_cooldown_timer.start(cooldown_time)
	queue_redraw()
	
	return true


func _on_cooldown_end():
	can_interact = true
	queue_redraw()


func setup(radius: float, heal_pct: float, cd: float, player_ref: Node2D):
	pool_radius = radius
	heal_percent = heal_pct
	cooldown_time = cd
	_player_ref = player_ref
