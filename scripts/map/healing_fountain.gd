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
var _cooldown_progress: float = 0.0  # 0.0 = ready, 1.0 = full cooldown

# ── Interaction ──
var interaction_prompt: String = "Press [E] to heal"
var interaction_range: float = 70.0
var can_interact: bool = true

# ── Healing config ──
var heal_percent: float = 0.50      # heal 50% of max HP
var cooldown_time: float = 30.0     # seconds between uses
var _cooldown_timer: float = 0.0

var _player_ref: Node2D = null


func _ready():
	# Physical collision basin
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = pool_radius
	shape.shape = circle
	add_child(shape)
	
	add_to_group("interactables")


func _draw():
	# Stone rim
	draw_circle(Vector2.ZERO, pool_radius, rim_color)
	draw_circle(Vector2.ZERO, pool_radius, Color(0.25, 0.25, 0.25), false, 2.0)
	
	# Water pool (slightly smaller inside the rim)
	var water_r = pool_radius * 0.7
	var water_col = pool_color
	if not can_interact:
		water_col = Color(0.15, 0.15, 0.15, 0.3)
	draw_circle(Vector2.ZERO, water_r, water_col)
	
	# Water shimmer (animated)
	if can_interact:
		var shimmer = sin(Time.get_ticks_msec() * 0.003) * 0.15 + 0.85
		draw_circle(Vector2(1, -1), water_r * 0.5, Color(0.6, 0.8, 1.0, 0.15 * shimmer))
		# Healing cross symbol
		var cross_sz = water_r * 0.35
		draw_rect(Rect2(-cross_sz * 0.25, -cross_sz, cross_sz * 0.5, cross_sz * 2), Color(1.0, 1.0, 1.0, 0.3 * shimmer))
		draw_rect(Rect2(-cross_sz, -cross_sz * 0.25, cross_sz * 2, cross_sz * 0.5), Color(1.0, 1.0, 1.0, 0.3 * shimmer))


func _process(delta):
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0:
			_cooldown_timer = 0.0
			can_interact = true
			queue_redraw()
		_cooldown_progress = _cooldown_timer / cooldown_time
	
	if can_interact:
		queue_redraw()  # keep shimmer animating


func interact(player: Node2D) -> bool:
	if not can_interact or not is_instance_valid(player):
		return false
	
	var heal_amt = ceil(player.max_health * heal_percent)
	player.heal(heal_amt)
	
	# Start cooldown
	can_interact = false
	_cooldown_timer = cooldown_time
	_cooldown_progress = 1.0
	queue_redraw()
	
	return true


func setup(radius: float, heal_pct: float, cd: float, player_ref: Node2D):
	pool_radius = radius
	heal_percent = heal_pct
	cooldown_time = cd
	_player_ref = player_ref
