extends Node
# DebugManager — autoload for development shortcuts.
#
# F8: 跳过选人/选关，直接 Antonio + Mad Forest 开始游戏
#
# CLI 测试请运行:
#   ./check_gdscript.sh
#   或: godot --headless --script res://scripts/test/run_tests_headless.gd --path .

var quick_start: bool = false


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	quick_start = Engine.has_meta("debug_quick_start") and Engine.get_meta("debug_quick_start")


func _input(event):
	if event is InputEventKey:
		if event.keycode == KEY_F8 and event.pressed and not event.echo:
			AudioManager.play_sfx("menu_confirm")
			Engine.set_meta("debug_quick_start", true)
			quick_start = true
			_start_quick_game()
			get_viewport().set_input_as_handled()


func _start_quick_game():
	var CharacterDefs = preload("res://scripts/data/character_defs.gd")
	var default_char = CharacterDefs.get_character(0)
	Engine.set_meta("selected_character", default_char)
	
	var StageDefs = preload("res://scripts/data/stage_defs.gd")
	var default_stage = StageDefs.get_stage(0)
	Engine.set_meta("selected_stage", default_stage)
	
	get_tree().change_scene_to_file("res://scenes/main.tscn")
