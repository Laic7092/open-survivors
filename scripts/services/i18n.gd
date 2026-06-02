class_name I18N extends Node
# Internationalization system — lazy-loading i18n.
# Translation tables are stored in separate files under scripts/data/i18n/
# and loaded on first access via load().
# Usage: I18N.t("key") returns the string in the current language.

const SETTINGS_PATH := "user://opensurvivors_settings.json"

static var current_lang: String = "zh"
static var fullscreen: bool = true
static var resolution: Vector2i = Vector2i(1280, 720)

static var _tables: Dictionary = {}
static var _loaded: bool = false
static var _zh_script = null
static var _en_script = null


static func _ensure_initialized():
	if _loaded:
		return
	_loaded = true
	_load_settings()


static func set_language(lang: String):
	_ensure_initialized()
	if lang != "zh" and lang != "en":
		return
	current_lang = lang
	_save_settings()


static func _tr(key: String, fallback: String = "") -> String:
	_ensure_initialized()
	_load_table(current_lang)
	if _tables.has(current_lang) and _tables[current_lang].has(key):
		return _tables[current_lang][key]
	_load_table("en")
	if _tables.has("en") and _tables["en"].has(key):
		return _tables["en"][key]
	return fallback if fallback != "" else key


static func t(key: String, fallback: String = "") -> String:
	return _tr(key, fallback)


static func _load_table(lang: String):
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


static func _load_settings():
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


static func _apply_display_settings():
	if DisplayServer.get_name() == "web":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	if resolution.x > 0 and resolution.y > 0:
		DisplayServer.window_set_size(resolution)


static func toggle_fullscreen():
	_ensure_initialized()
	fullscreen = not fullscreen
	_save_settings()


static func set_resolution(w: int, h: int):
	_ensure_initialized()
	resolution = Vector2i(w, h)
	_save_settings()


static func _save_settings():
	_ensure_initialized()
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
