extends Node
# Internationalization system — lazy-loading i18n.
# Translation tables are stored in separate files under scripts/data/i18n/
# and loaded on first access via load().
# Usage: I18N.t("key") returns the string in the current language.

const SETTINGS_PATH := "user://opensurvivors_settings.json"

var current_lang: String = "zh"  # default: Chinese
var fullscreen: bool = true
var resolution: Vector2i = Vector2i(1280, 720)
var _tables: Dictionary = {}
var _loaded: bool = false
var _zh_script = null
var _en_script = null


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	_load_settings()


func set_language(lang: String):
	if lang != "zh" and lang != "en":
		return
	current_lang = lang
	_save_settings()


func _tr(key: String, fallback: String = "") -> String:
	_load_table(current_lang)
	if _tables.has(current_lang) and _tables[current_lang].has(key):
		return _tables[current_lang][key]
	# Fallback to English
	_load_table("en")
	if _tables.has("en") and _tables["en"].has(key):
		return _tables["en"][key]
	return fallback if fallback != "" else key


# Public alias with a safe name (avoids conflict with built-in tr())
func t(key: String, fallback: String = "") -> String:
	return _tr(key, fallback)


func _load_table(lang: String):
	if _tables.has(lang):
		return
	var script = null
	match lang:
		"zh":
			if not _zh_script:
				_zh_script = load("res://scripts/data/i18n/zh.gd")
			script = _zh_script
		"en":
			if not _en_script:
				_en_script = load("res://scripts/data/i18n/en.gd")
			script = _en_script
	if script and script.has_method("get_data"):
		_tables[lang] = script.get_data()


# ── Settings persistence ──

func _load_settings():
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not file:
		_apply_display_settings()
		return
	var text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(text) != OK:
		_apply_display_settings()
		return
	var data = json.data
	if data.has("language"):
		current_lang = data["language"]
	if data.has("fullscreen"):
		fullscreen = data["fullscreen"]
	if data.has("resolution_w") and data.has("resolution_h"):
		resolution = Vector2i(data["resolution_w"], data["resolution_h"])
	_apply_display_settings()


func _apply_display_settings():
	if DisplayServer.get_name() == "web":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	if resolution.x > 0 and resolution.y > 0:
		DisplayServer.window_set_size(resolution)
		get_tree().root.set_size(resolution)


func toggle_fullscreen():
	fullscreen = not fullscreen
	_save_settings()


func set_resolution(w: int, h: int):
	resolution = Vector2i(w, h)
	_save_settings()


func _save_settings():
	var data = {
		"language": current_lang,
		"fullscreen": fullscreen,
		"resolution_w": resolution.x,
		"resolution_h": resolution.y,
	}
	_apply_display_settings()
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if not file:
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
