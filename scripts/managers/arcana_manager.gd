extends Node
# ArcanaManager — autoload singleton
# Manages Arcana unlock state + run-time active Arcanas.
# Persisted alongside PowerUpManager save data.

const ArcanaDefs = preload("res://scripts/data/arcana_defs.gd")

# ── Runtime state ──
var _unlocked: Dictionary = {}      # arcana_id -> true
var _active: Array = []              # arcana_ids active in this run (max 3 normally)
var _last_attract_time: float = 0.0  # Mad Groove cooldown tracker
var _cycle_time: float = 0.0
var _level_stat_accum: Dictionary = {} # per-level stat accumulation
var _last_processed_level: int = 0

# Signals
signal arcana_unlocked(arcana_id: int)
signal arcana_activated(arcana_id: int)
signal arcana_cleared


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	load_unlock_data()


# ── Unlock tracking ──

func has_unlocked(id: int) -> bool:
	return _unlocked.has(id) and _unlocked[id] == true


func unlock(id: int) -> bool:
	if has_unlocked(id):
		return false
	if _arcana_exists(id):
		_unlocked[id] = true
		_save_unlock_data()
		arcana_unlocked.emit(id)
		return true
	return false


func get_unlocked() -> Array:
	var result: Array = []
	for id in _unlocked:
		if _unlocked[id]:
			result.append(id)
	return result


func get_unlocked_count() -> int:
	var count = 0
	for id in _unlocked:
		if _unlocked[id]:
			count += 1
	return count


# ── Active Arcanas (run-time) ──

func is_active(id: int) -> bool:
	return _active.has(id)


func get_active() -> Array:
	return _active.duplicate()


func get_active_count() -> int:
	return _active.size()


func activate(id: int) -> bool:
	if not has_unlocked(id):
		return false
	if _active.has(id):
		return false
	# Max 3 active Arcanas (no limit enforcement here — game loop gates it)
	_active.append(id)
	arcana_activated.emit(id)
	return true


func deactivate(id: int):
	_active.erase(id)


func deactivate_all():
	_active.clear()
	_last_attract_time = 0.0
	_cycle_time = 0.0
	_level_stat_accum = {}
	_last_processed_level = 0
	arcana_cleared.emit()


# ── Effect query helpers ──

func has_effect(effect_id: String) -> bool:
	for id in _active:
		if ArcanaDefs.arcana_has_effect(id, effect_id):
			return true
	return false


func has_any_effect(effects: Array) -> bool:
	for id in _active:
		var a = ArcanaDefs.get_arcana(id)
		for eff in effects:
			if eff in a["effects"]:
				return true
	return false


# Check if an active Arcana lists a specific weapon
func active_arcana_lists_weapon(weapon_type: int) -> Array:
	var result: Array = []
	for id in _active:
		if ArcanaDefs.arcana_lists_weapon(id, weapon_type):
			result.append(id)
	return result


# Check if any active Arcana that lists a weapon has a specific effect
func active_arcanas_have_weapon_effect(weapon_type: int, effect_id: String) -> bool:
	for id in _active:
		if ArcanaDefs.arcana_lists_weapon(id, weapon_type) and ArcanaDefs.arcana_has_effect(id, effect_id):
			return true
	return false


# ── Arcana system is available (Randomazzo collected) ──
func is_system_enabled() -> bool:
	return RelicManager.has_relic("randomazzo")


# ── Apply Arcana stat modifiers to a player stat dictionary ──
# Called by player.gd every frame / on stat recalculation
# stats is a Dictionary with: damage_mult, cooldown_reduction, area_mult, speed_mult,
#   duration_bonus, move_speed, max_health, armor, growth_mult, greed_mult, luck, curse,
#   revivals, projectile_bonus, pickup_range, crit_chance, crit_mult
func apply_stat_modifiers(stats: Dictionary, player) -> Dictionary:
	var result = stats.duplicate()
	
	for id in _active:
		var a = ArcanaDefs.get_arcana(id)
		for effect in a["effects"]:
			match effect:
				"revival_plus_3":
					result["revivals"] = stats.get("revivals", 0) + 3
				
				"armor_scales_damage":
					var armor_val = stats.get("armor", 0)
					result["damage_mult"] = stats.get("damage_mult", 1.0) + armor_val * 0.1
				
				"empty_slot_stats":
					# +20% Might and -8% CD per empty weapon slot
					var total_slots = 6
					var filled = 0
					if player and player.has_method("get_weapon_count"):
						filled = player.get_weapon_count()
					var empty = max(total_slots - filled, 0)
					result["damage_mult"] = stats.get("damage_mult", 1.0) + 0.20 * empty
					result["cooldown_reduction"] = stats.get("cooldown_reduction", 0.0) + 0.08 * empty
				
				"crits_enabled":
					result["crit_chance"] = max(stats.get("crit_chance", 0.0), 0.15)
				
				"crit_damage_double":
					result["crit_mult"] = stats.get("crit_mult", 2.0) * 2.0
				
				"cycle_speed":
					# -50% to +50% over 10 seconds — applied in _process via setter
					pass  # handled in player._process()
				
				"cycle_area":
					pass  # handled in player._process()
				
				"cycle_duration":
					pass  # handled in player._process()
				
				"cycle_stats":
					pass  # handled in player._process()
	
	return result


# ── Time-based Arcana effects (called from main.gd _process) ──
func process_time_effects(delta: float, player, game_time: float):
	_cycle_time += delta
	
	for id in _active:
		var a = ArcanaDefs.get_arcana(id)
		for effect in a["effects"]:
			match effect:
				"attract_items_120s":
					if game_time - _last_attract_time >= 120.0:
						_last_attract_time = game_time
						_attract_items(player)
				
				"cycle_speed":
					if player and player.has_method("set_speed_mult"):
						var cycle = sin(_cycle_time * TAU / 10.0)  # 10s period
						var bonus = 1.0 + cycle * 0.5  # -50% to +50%
						player.set_speed_mult(bonus)
				
				"cycle_area":
					if player and player.has_method("set_area_mult_override"):
						var cycle = sin(_cycle_time * TAU / 10.0)
						var bonus = 1.0 + cycle * 0.25  # -25% to +25%
						player.set_area_mult_override(bonus)
				
				"cycle_duration":
					if player and player.has_method("set_duration_bonus_override"):
						var cycle = sin(_cycle_time * TAU / 10.0)
						var bonus = cycle * 0.5  # -50% to +50%
						player.set_duration_bonus_override(bonus)
				
				"cycle_stats":
					# Cycle Growth/Luck/Greed/Curse — 2x one at a time
					var phase = fmod(_cycle_time, 20.0) / 20.0  # 20s cycle
					if phase < 0.25:
						_set_player_stat(player, "growth_mult", 2.0)
						_set_player_stat(player, "luck", 0.0)
						_set_player_stat(player, "greed_mult", 0.0)
						_set_player_stat(player, "curse", 0.0)
					elif phase < 0.5:
						_set_player_stat(player, "growth_mult", 1.0)
						_set_player_stat(player, "luck", 1.0)
						_set_player_stat(player, "greed_mult", 0.0)
						_set_player_stat(player, "curse", 0.0)
					elif phase < 0.75:
						_set_player_stat(player, "growth_mult", 1.0)
						_set_player_stat(player, "luck", 0.0)
						_set_player_stat(player, "greed_mult", 1.0)
						_set_player_stat(player, "curse", 0.0)
					else:
						_set_player_stat(player, "growth_mult", 1.0)
						_set_player_stat(player, "luck", 0.0)
						_set_player_stat(player, "greed_mult", 0.0)
						_set_player_stat(player, "curse", 1.0)


func _set_player_stat(player, stat: String, value):
	if player and player.has_method("set_" + stat):
		player.call("set_" + stat, value)


# ── Mad Groove: attract all items ──
func _attract_items(player):
	if not is_instance_valid(player):
		return
	# Find all pickups, XP gems, light sources in the scene and pull them toward player
	var scene = player.get_tree().current_scene
	if not scene:
		return
	var pull_targets = []
	# Collect all groups
	for group in ["pickups", "xp_gems", "light_sources"]:
		pull_targets += scene.get_tree().get_nodes_in_group(group)
	for target in pull_targets:
		if not is_instance_valid(target):
			continue
		var tw = scene.create_tween()
		tw.tween_property(target, "global_position", player.global_position, 0.5)
		tw.set_ease(Tween.EASE_IN)


# ── Healing multipliers (for Sarabande of Healing) ──
func get_healing_multiplier() -> float:
	if has_effect("healing_double"):
		return 2.0
	return 1.0


# ── Player level-up Arcana bonuses ──
func on_player_level_up(player, new_level: int):
	# Skip if we've already processed this level (prevents double-apply)
	if new_level <= _last_processed_level:
		return
	_last_processed_level = new_level
	
	for id in _active:
		var a = ArcanaDefs.get_arcana(id)
		for effect in a["effects"]:
			match effect:
				"level_speed_pct":
					# +1% projectile speed per level
					var bonus = 0.01 * new_level
					if player and player.has_method("add_speed_mult_pct"):
						player.add_speed_mult_pct(bonus)
				
				"level_stat_pct":
					# +1% Growth, Luck, Greed, Curse every 2 levels
					if new_level % 2 == 0:
						var pct = 0.01
						if player:
							if player.has_method("add_growth_pct"):
								player.add_growth_pct(pct)
							if player.has_method("add_luck"):
								player.add_luck(pct)
							if player.has_method("add_greed_pct"):
								player.add_greed_pct(pct)
							if player.has_method("add_curse"):
								player.add_curse(pct)
				
				"level_area_pct":
					# +1% Area per level
					var bonus = 0.01 * new_level
					if player and player.has_method("add_area_pct"):
						player.add_area_pct(bonus)
				
				"level_duration_pct":
					# +1% Duration per level
					var bonus = 0.01 * new_level
					if player and player.has_method("add_duration_pct"):
						player.add_duration_pct(bonus)


# ── Load/Save (delegated to PowerUpManager save file) ──

func _save_unlock_data():
	# Read existing save, merge, write back
	var file = FileAccess.open("user://desire_survivors_save.json", FileAccess.READ)
	var data = {}
	if file:
		var text = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(text) == OK:
			data = json.data
	
	data["unlocked_arcanas"] = []
	for id in _unlocked:
		if _unlocked[id]:
			data["unlocked_arcanas"].append(id)
	
	file = FileAccess.open("user://desire_survivors_save.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func load_unlock_data():
	var file = FileAccess.open("user://desire_survivors_save.json", FileAccess.READ)
	if not file:
		_unlocked = {}
		return
	var text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(text) != OK:
		_unlocked = {}
		return
	var data = json.data
	_unlocked = {}
	if data.has("unlocked_arcanas"):
		for id in data["unlocked_arcanas"]:
			_unlocked[int(id)] = true


func _arcana_exists(id: int) -> bool:
	return id >= 0 and id < ArcanaDefs.get_arcana_count()
