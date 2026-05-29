extends Node2D
# Base class for map elements the player can interact with (press E).
# Subclasses must override _on_interact(player) -> bool.
#
# Each interactable has:
#   - interaction_prompt: text shown in HUD when player is near
#   - interaction_range: how close the player must be to interact
#   - can_interact: set false while on cooldown / already used

signal interaction_occurred(which: Node2D)

var interaction_prompt: String = ""
var interaction_range: float = 80.0
var can_interact: bool = true


## Called by main.gd when the player presses E nearby.
## Returns true if interaction happened.
func interact(player: Node2D) -> bool:
	if not can_interact or not is_instance_valid(player):
		return false
	var ok = _on_interact(player)
	if ok:
		interaction_occurred.emit(self)
	return ok


## Override in subclass. Return true if interaction succeeded.
func _on_interact(player: Node2D) -> bool:
	return false
