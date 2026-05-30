extends Node2D
# Replace Timer-based runetracer tick with a lightweight _process updater.
# This avoids creating a Timer per projectile (which has overhead).
# Attached as a child of player; references the projectile via metadata.

var _lifetime: float = 0.0
var _max_lifetime: float = 4.0


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED


func _process(delta):
	_lifetime += delta
	if _lifetime >= _max_lifetime:
		_cleanup()
		return
	
	var proj = get_meta("rune_proj", null)
	if not is_instance_valid(proj):
		queue_free()
		return
	
	_on_runetracer_tick(proj, delta)


func _on_runetracer_tick(proj: Node2D, delta: float):
	var dir: Vector2 = proj.get_meta("rune_dir", Vector2.DOWN)
	var speed: float = proj.get_meta("rune_speed", 400.0)
	var bounces: int = proj.get_meta("rune_bounces", 0)
	
	proj.global_position += dir * speed * delta
	
	var half_w = 1600.0
	var half_h = 1200.0
	var sd = EventBus.get_config("selected_stage", null)
	if sd != null:
		half_w = sd.get("map_width", 3200.0) * 0.5
		half_h = sd.get("map_height", 2400.0) * 0.5
	var margin = 20.0
	var bounced = false
	if proj.global_position.x < -half_w + margin:
		proj.global_position.x = -half_w + margin
		dir.x = abs(dir.x)
		bounced = true
	elif proj.global_position.x > half_w - margin:
		proj.global_position.x = half_w - margin
		dir.x = -abs(dir.x)
		bounced = true
	if proj.global_position.y < -half_h + margin:
		proj.global_position.y = -half_h + margin
		dir.y = abs(dir.y)
		bounced = true
	elif proj.global_position.y > half_h - margin:
		proj.global_position.y = half_h - margin
		dir.y = -abs(dir.y)
		bounced = true
	
	if bounced:
		bounces += 1
		proj.set_meta("rune_dir", dir)
		proj.set_meta("rune_bounces", bounces)
		AudioManager.play_sfx("wpn_bounce")
	
	if bounces >= 6:
		_cleanup()


func _cleanup():
	var proj = get_meta("rune_proj", null)
	if is_instance_valid(proj):
		proj.queue_free()
	queue_free()
