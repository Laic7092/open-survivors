extends Node
# PropManager — manages all interactive map elements.
#
# Responsibilities:
#   - Registers interactive elements (chests, fountains, breakables)
#   - Finds the nearest interactable element for HUD prompt
#   - Tracks hazard zones and boost zones
#   - Provides element positions to minimap
#
# Attach as a child of main.gd; call setup() after map creation.

class_name PropManager

# Preload scripts for type checking at runtime (avoids class_name compile deps)
const _BreakableWallScript = preload("res://scripts/map/breakable_wall.gd")
const _TreasureChestScript = preload("res://scripts/map/treasure_chest.gd")
const _HealingFountainScript = preload("res://scripts/map/healing_fountain.gd")
const _HazardZoneScript = preload("res://scripts/map/hazard_zone.gd")
const _BoostZoneScript = preload("res://scripts/map/boost_zone.gd")

# ── References ──
var map_width: float = 3200.0
var map_height: float = 2400.0

# ── Interactive element lists ──
var interactables: Array[Node2D] = []      # things with interact()
var breakable_walls: Array[Node2D] = []    # breakable walls
var treasure_chests: Array[Node2D] = []     # chests
var healing_fountains: Array[Node2D] = []   # fountains
var hazard_zones: Array[Node2D] = []        # damage zones
var boost_zones: Array[Node2D] = []         # buff zones

# ── Interaction state ──
var nearest_interactable: Node2D = null
var nearest_interactable_dist: float = INF
var highlight_prompt: String = ""

# ── Signals ──
signal nearest_interactable_changed(element: Node2D, prompt: String)


func setup(main_node: Node):
	map_width = main_node.map_width if "map_width" in main_node else 3200.0
	map_height = main_node.map_height if "map_height" in main_node else 2400.0


## Register an interactive element. Called during map generation.
func register_interactable(element: Node2D):
	if not element or not is_instance_valid(element):
		return
	interactables.append(element)
	
	var scr = element.get_script()
	if scr == _BreakableWallScript:
		breakable_walls.append(element)
	elif "interaction_prompt" in element:
		if scr == _TreasureChestScript:
			treasure_chests.append(element)
		elif scr == _HealingFountainScript:
			healing_fountains.append(element)


## Register a hazard zone.
func register_hazard(zone: Node2D):
	if zone and is_instance_valid(zone) and zone.get_script() == _HazardZoneScript:
		hazard_zones.append(zone)


## Register a boost zone.
func register_boost(zone: Node2D):
	if zone and is_instance_valid(zone) and zone.get_script() == _BoostZoneScript:
		boost_zones.append(zone)


## Called each frame from main.gd's _process.
## Finds the closest interactable within range and updates the prompt.
func update_nearest(player_pos: Vector2, max_range: float = 80.0):
	var closest: Node2D = null
	var closest_dist: float = max_range * max_range  # squared distance
	
	for e in interactables:
		if not is_instance_valid(e):
			continue
		if not ("can_interact" in e) or not e.can_interact:
			continue
		
		var dist = player_pos.distance_squared_to(e.global_position)
		if dist < closest_dist:
			# Use element's own interaction_range if available
			var range_sq = max_range * max_range
			if "interaction_range" in e:
				range_sq = e.interaction_range * e.interaction_range
			
			if dist < range_sq:
				closest = e
				closest_dist = dist
	
	# Update state
	var changed = false
	if closest != nearest_interactable:
		changed = true
		nearest_interactable = closest
	
	if closest:
		var prompt = ""
		if "interaction_prompt" in closest:
			prompt = closest.interaction_prompt
		if prompt != highlight_prompt:
			changed = true
			highlight_prompt = prompt
		nearest_interactable_dist = sqrt(closest_dist)
	else:
		if highlight_prompt != "":
			changed = true
			highlight_prompt = ""
		nearest_interactable_dist = INF
	
	if changed:
		nearest_interactable_changed.emit(nearest_interactable, highlight_prompt)


## Call when player presses E. Returns true if interaction happened.
func try_interact(player: Node2D) -> bool:
	if nearest_interactable and is_instance_valid(nearest_interactable):
		if nearest_interactable.has_method("interact"):
			return nearest_interactable.interact(player)
	return false


## Collect positions for minimap display.
func get_chest_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for c in treasure_chests:
		if is_instance_valid(c):
			positions.append(c.global_position)
	return positions


func get_fountain_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for f in healing_fountains:
		if is_instance_valid(f):
			positions.append(f.global_position)
	return positions


func get_hazard_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for h in hazard_zones:
		if is_instance_valid(h):
			positions.append(h.global_position)
	return positions


func get_boost_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for b in boost_zones:
		if is_instance_valid(b):
			positions.append(b.global_position)
	return positions


## Clean up destroyed elements from our lists.
func clean_dead():
	interactables = _filter_alive(interactables)
	breakable_walls = _filter_alive(breakable_walls)
	treasure_chests = _filter_alive(treasure_chests)
	healing_fountains = _filter_alive(healing_fountains)
	hazard_zones = _filter_alive(hazard_zones)
	boost_zones = _filter_alive(boost_zones)


static func _filter_alive(arr: Array) -> Array:
	return arr.filter(func(n): return is_instance_valid(n))
