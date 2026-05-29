extends Control
# Test Runner — 作为主场景运行，自动执行所有测试。
# 
# 用法: godot --headless res://scenes/test_runner.tscn --path .
# 不需要 --script，会正常加载 autoload、场景、资源。
#
# 如果检测到是 headless 模式，自动跑测试并退出。
# 如果在编辑器里打开，显示一个简单的 GUI 和 Run 按钮。

const TEST_DIR := "res://scripts/test/"
const DIVIDER := "============================================================"

var _suites: Array = []
var _total_passed := 0
var _total_failed := 0
var _total_tests := 0


func _ready():
	# 自动检测 headless 模式
	if DisplayServer.get_name() == "headless":
		_run_headless()
	else:
		_build_gui()
		_discover_tests()


# ═══════════════════════════════════════════════════════════
#  GUI 模式（编辑器里按 F9 打开时）
# ═══════════════════════════════════════════════════════════

func _build_gui():
	anchor_right = 1.0
	anchor_bottom = 1.0
	var vp = get_viewport().get_visible_rect().size
	
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.06)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)
	
	var title = Label.new()
	title.text = "Test Runner"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	title.position = Vector2(vp.x / 2 - 100, 25)
	title.size = Vector2(200, 40)
	add_child(title)
	
	var run_btn = Button.new()
	run_btn.text = "▶ Run All Tests"
	run_btn.custom_minimum_size = Vector2(200, 44)
	run_btn.position = Vector2(vp.x / 2 - 100, 80)
	run_btn.pressed.connect(_run_gui)
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.15, 0.45, 0.15)
	s.border_width_left = 2; s.border_width_right = 2
	s.border_width_top = 2; s.border_width_bottom = 2
	s.border_color = Color(0.25, 0.65, 0.25)
	s.corner_radius_top_left = 6; s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6; s.corner_radius_bottom_right = 6
	run_btn.add_theme_stylebox_override("normal", s)
	run_btn.add_theme_color_override("font_color", Color.WHITE)
	run_btn.add_theme_font_size_override("font_size", 16)
	add_child(run_btn)
	
	_discover_tests()


func _run_gui():
	_run_all()
	var msg = "%d passed, %d failed, %d total" % [_total_passed, _total_failed, _total_tests]
	print(msg)


# ═══════════════════════════════════════════════════════════
#  测试发现 + 执行（GUI 和 headless 共用）
# ═══════════════════════════════════════════════════════════

func _discover_tests():
	_suites.clear()
	var dir = DirAccess.open(TEST_DIR)
	if not dir:
		push_error("无法打开测试目录: ", TEST_DIR)
		return
	dir.list_dir_begin()
	var fname = dir.get_next()
	while fname != "":
		if fname.ends_with(".gd") and fname.begins_with("suite_") and fname != "test_runner.gd":
			var path = TEST_DIR + fname
			var script = load(path)
			if script:
				var instance = script.new()
				if instance and instance.has_method("run_all"):
					_suites.append({"name": fname.trim_suffix(".gd"), "instance": instance})
		fname = dir.get_next()
	dir.list_dir_end()


func _run_headless():
	print(DIVIDER)
	print("  Test Runner (headless)")
	print("  Autoloads: loaded automatically by engine")
	print(DIVIDER)
	print("")
	
	_discover_tests()
	if _suites.is_empty():
		print("❌ 没有找到测试套件 (scripts/test/suite_*.gd)")
		get_tree().quit(1)
		return
	
	_run_all()
	
	print(DIVIDER)
	if _total_failed == 0:
		print("  ✅ ALL PASSED  (%d test(s))" % _total_tests)
	else:
		print("  ❌ %d passed, %d failed (%d total)" % [_total_passed, _total_failed, _total_tests])
	print(DIVIDER)
	
	get_tree().quit(0 if _total_failed == 0 else 1)


func _run_all():
	_total_passed = 0
	_total_failed = 0
	_total_tests = 0
	
	for suite in _suites:
		var results = suite["instance"].run_all()
		print("── ", suite["name"], " ──")
		var names = results.keys()
		names.sort()
		for tname in names:
			var r = results[tname]
			_total_tests += 1
			if r.get("passed", false):
				_total_passed += 1
				print("  ✅ ", tname)
			elif r.get("message", "").begins_with("SKIP"):
				print("  ⏭️  ", tname)
			else:
				_total_failed += 1
				print("  ❌ ", tname)
			print("     ", r.get("message", ""))
		print("")
