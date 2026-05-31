extends Node
# CurseSystem — 诅咒时刻系统
# Boss 战后每60s叠加一层诅咒，使游戏持续变难

const GameState = preload("res://scripts/core/game_state.gd")

var game_state: GameState
var player: Node2D
var hud: Node  # HUD 引用，用于显示诅咒层数

signal curse_announced(level: int)


func setup(gs: GameState, p: Node2D):
	game_state = gs
	player = p


func set_hud(h: Node):
	hud = h


func process(delta: float):
	if game_state.game_over or game_state.stage_complete:
		return
	
	# Boss 战死后激活诅咒时刻
	if game_state.boss_spawned and not game_state.cursed_time_active:
		game_state.cursed_time_active = true
		game_state.curse_timer = 60.0
		game_state.curse_level = 0
		_on_cursed_time_start()
	
	if game_state.cursed_time_active:
		game_state.curse_timer -= delta
		while game_state.curse_timer <= 0.0:
			game_state.curse_level += 1
			game_state.curse_timer += 60.0 * (0.9 / max(1.0, game_state.curse_level * 0.05))
			_on_curse_level_up()
			game_state.curse_level_changed.emit(game_state.curse_level)


func _on_cursed_time_start():
	_show_announcement("💀 " + _t("cursed_time.start"))
	if is_instance_valid(player):
		player.show_floating_text(_t("cursed_time.start"), Color(0.9, 0.1, 0.1), 24)
	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("cursed_time")
	curse_announced.emit(-1)


func _on_curse_level_up():
	if is_instance_valid(player):
		player.show_floating_text("💀 " + _t("cursed_time.level") % game_state.curse_level, Color(0.9, 0.1, 0.1), 20)
		if AudioManager:
			AudioManager.play_sfx("cursed_time")
	if hud and hud.has_method("set_curse_level"):
		hud.set_curse_level(game_state.curse_level)
	curse_announced.emit(game_state.curse_level)


func _show_announcement(text: String):
	# 查找场景中的 CanvasLayer UI 层来显示公告
	var scene = get_tree().current_scene
	if not scene:
		return
	for c in scene.get_children():
		if c is CanvasLayer:
			var label = Label.new()
			label.text = text
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_color_override("font_color", Color(0.9, 0.15, 0.1))
			label.add_theme_font_size_override("font_size", 30)
			var vp_size = get_viewport().get_visible_rect().size
			label.position = Vector2(
				vp_size.x / 2.0 - 150,
				vp_size.y * 0.15
			)
			c.add_child(label)
			var tw = create_tween()
			tw.tween_interval(1.5)
			tw.tween_property(label, "modulate", Color(1, 1, 1, 0), 1.0)
			var label_id = label.get_instance_id()
			tw.finished.connect(func():
				var _x = instance_from_id(label_id)
				if _x:
					_x.queue_free()
			)
			break


func _t(key: String) -> String:
	if I18N and I18N.has_method("t"):
		return I18N.t(key)
	return key
