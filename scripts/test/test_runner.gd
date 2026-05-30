#!/usr/bin/env godot
# Test runner for Desire Survivors
# Runs all test_*.gd files in the test directory.
# Usage: godot --headless --script scripts/test/test_runner.gd [--filter=xxx]

extends SceneTree

var _filter: String = ""
var _passed: int = 0
var _failed: int = 0
var _errors: Array[String] = []


func _init():
	# Parse --filter argument
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--filter="):
			_filter = arg.trim_prefix("--filter=").to_lower()

	var sep = "="
	print(sep.repeat(60))
	print("  Desire Survivors -- Test Runner")
	print(sep.repeat(60))
	print("")

	var test_dir = DirAccess.open("res://scripts/test")
	if not test_dir:
		printerr("ERROR: Cannot open test directory")
		quit(1)
		return

	test_dir.list_dir_begin()
	var file_name = test_dir.get_next()
	var test_files: Array[String] = []

	while file_name != "":
		if file_name.begins_with("test_") and file_name.ends_with(".gd") and file_name != "test_runner.gd":
			if _filter == "" or file_name.to_lower().contains(_filter):
				test_files.append(file_name)
		file_name = test_dir.get_next()

	test_files.sort()

	if test_files.is_empty():
		print("No test files found.")
		if _filter != "":
			print("  (filter: '%s' matched nothing)" % _filter)
		print("")
	else:
		print("Found %d test file(s):" % test_files.size())
		for f in test_files:
			print("  - %s" % f)
		print("")

		for f in test_files:
			_run_test_file(f)

	# Summary
	print("")
	print(sep.repeat(60))
	print("  Results: %d passed, %d failed" % [_passed, _failed])
	print(sep.repeat(60))

	if _failed > 0:
		print("")
		print("Failed tests:")
		for e in _errors:
			print("  " + e)

	quit(0 if _failed == 0 else 1)


func _run_test_file(file_name: String):
	var path = "res://scripts/test/" + file_name
	var dash = "-"
	print(dash.repeat(40))
	print("  Running: %s" % file_name)
	print(dash.repeat(40))

	var script = load(path)
	if not script:
		printerr("  FAILED TO LOAD")
		_failed += 1
		_errors.append(file_name + ": failed to load")
		return

	# Each test script should have a static func run() -> Dictionary
	if not script.has_method("run"):
		printerr("  No static run() method found")
		_failed += 1
		_errors.append(file_name + ": no run() method")
		return

	var result = script.run()
	if typeof(result) != TYPE_DICTIONARY:
		printerr("  run() must return a Dictionary {passed: int, failed: int, errors: Array[String]}")
		_failed += 1
		_errors.append(file_name + ": run() returned wrong type")
		return

	var p = result.get("passed", 0)
	var f = result.get("failed", 0)
	var errs: Array = result.get("errors", [])

	_passed += p
	_failed += f
	for e in errs:
		_errors.append(file_name + ": " + str(e))

	print("  -> %d passed, %d failed" % [p, f])
	print("")
