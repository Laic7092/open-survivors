extends Control

# Unlock data loaded lazily via DataRegistry
# Arcana data loaded lazily via DataRegistry

# ── Scene node references ──
@onready var _gold_lbl: Label = %GoldLabel
@onready var _lang_btn: Button = %LangBtn
@onready var _fs_btn: Button = %FsBtn
@onready var _res_btn: Button = %ResBtn
@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _sep: ColorRect = %Sep
@onready var _start_btn: Button = %StartBtn
@onready var _pu_btn: Button = %PuBtn
@onready var _relic_btn: Button = %RelicBtn
@onready var _load_btn: Button = %LoadBtn
@onready var _version_lbl: Label = %VersionLabel
@onready var _quit_btn: Button = %QuitBtn
@onready var _center: VBoxContainer = %Center

var _save_screen: Control
var _unlock_notif: Control
var _badge_entries: Array[Dictionary] = []


func _ready():
	# Signal connections
	_start_btn.pressed.connect(_on_start_pressed)
	_pu_btn.pressed.connect(_on_powerups_pressed)
	_relic_btn.pressed.connect(_on_relics_pressed)
	_load_btn.pressed.connect(_on_load_pressed)
	_lang_btn.pressed.connect(_on_language_pressed)
	_fs_btn.pressed.connect(_on_fs_pressed)
	_res_btn.pressed.connect(_on_res_pressed)
	_quit_btn.pressed.connect(_on_quit_pressed)

	# Set i18n text
	_refresh_text()

	# Unlock notification overlay
	_unlock_notif = Control.new()
	_unlock_notif.name = "UnlockNotification"
	_unlock_notif.set_script(preload("res://scripts/ui/unlock_notification.gd"))
	add_child(_unlock_notif)

	# ── Save Screen (profile slot selection) ──
	_save_screen = preload("res://scenes/save_screen.tscn").instantiate()
	add_child(_save_screen)
	_save_screen.slot_selected.connect(_on_slot_selected)
	_save_screen.slot_created.connect(_on_slot_created)
	_save_screen.closed.connect(_on_save_screen_closed)

	call_deferred("play_menu_music")
	call_deferred("_check_new_unlocks")


func _refresh_text():
	_gold_lbl.text = I18N.t("menu.gold") + str(PowerUpManager.gold)
	_title.text = I18N.t("menu.title")
	_subtitle.text = I18N.t("menu.subtitle")
	_start_btn.text = I18N.t("menu.start_game")
	_pu_btn.text = I18N.t("menu.power_ups")
	_relic_btn.text = I18N.t("menu.relics")
	_load_btn.text = I18N.t("menu.load_game")
	_lang_btn.text = I18N.t("menu.language")
	_fs_btn.text = _fullscreen_text()
	_res_btn.text = _resolution_text()
	_version_lbl.text = I18N.t("menu.footer")
	_quit_btn.text = I18N.t("menu.quit")


# ═══════════════════════════════════════════════════════════
# Unlock Badges
# ═══════════════════════════════════════════════════════════

func _check_new_unlocks():
	var um = _lazy_unlock_manager()
	if _unlock_notif and _unlock_notif.has_method("check_and_show"):
		_unlock_notif.check_and_show()
	call_deferred("_add_unlock_badges")


func _add_unlock_badges():
	if not _lazy_unlock_manager().has_new_unlocks():
		return
	_clear_badges()
	_add_badge_to_button(_start_btn, Color(0.9, 0.2, 0.2))
	_add_badge_to_button(_relic_btn, Color(0.9, 0.7, 0.2))


func _add_badge_to_button(btn: Button, color: Color):
	var badge_bg = ColorRect.new()
	badge_bg.color = color
	badge_bg.size = Vector2(28, 16)
	btn.add_child(badge_bg)
	var badge = Label.new()
	badge.text = I18N.t("unlock.new_badge")
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", Color.WHITE)
	badge.size = Vector2(24, 14)
	btn.add_child(badge)
	_badge_entries.append({"bg": badge_bg, "label": badge, "btn": btn})
	_reposition_badges()


func _reposition_badges():
	for entry in _badge_entries:
		if not is_instance_valid(entry["bg"]):
			continue
		var btn = entry["btn"]
		var bw = max(btn.custom_minimum_size.x, btn.size.x)
		entry["bg"].position = Vector2(max(0, bw - 30), -8)
		entry["label"].position = Vector2(max(0, bw - 28), -6)


func _clear_badges():
	for entry in _badge_entries:
		if is_instance_valid(entry["bg"]):
			entry["bg"].queue_free()
		if is_instance_valid(entry["label"]):
			entry["label"].queue_free()
	_badge_entries.clear()


# ═══════════════════════════════════════════════════════════
# Signal Handlers
# ═══════════════════════════════════════════════════════════

func _on_start_pressed():
	AudioManager.play_sfx("menu_confirm")
	SceneManager.change_scene("res://scenes/character_select.tscn")


func _on_load_pressed():
	AudioManager.play_sfx("menu_confirm")
	_save_screen.show_screen()


func _on_save_screen_closed():
	_save_screen.hide_screen()


# Load an existing save → restore game state
func _on_slot_selected(slot_id: String):
	AudioManager.play_sfx("menu_confirm")
	_save_screen.hide_screen()
	# Switch to this slot — loads its profile into all managers
	SaveManager.switch_to_slot(slot_id)
	# Refresh gold display
	_gold_lbl.text = I18N.t("menu.gold") + str(PowerUpManager.gold)


func _on_slot_created(slot_id: String):
	AudioManager.play_sfx("menu_confirm")
	_save_screen.hide_screen()
	# Create new slot and switch to it
	SaveManager.create_slot(slot_id)
	SaveManager.switch_to_slot(slot_id)
	# Refresh gold display
	_gold_lbl.text = I18N.t("menu.gold") + str(PowerUpManager.gold)


func _on_powerups_pressed():
	AudioManager.play_sfx("menu_confirm")
	SceneManager.change_scene("res://scenes/powerup_screen.tscn")


func _on_relics_pressed():
	AudioManager.play_sfx("menu_confirm")
	SceneManager.change_scene("res://scenes/relic_screen.tscn")


func _on_language_pressed():
	AudioManager.play_sfx("menu_select")
	if I18N.current_lang == "zh":
		I18N.set_language("en")
	else:
		I18N.set_language("zh")
	get_tree().reload_current_scene()


func _on_fs_pressed():
	AudioManager.play_sfx("menu_select")
	I18N.toggle_fullscreen()
	_fs_btn.text = _fullscreen_text()


func _on_res_pressed():
	AudioManager.play_sfx("menu_select")
	var cur = I18N.resolution
	match cur:
		Vector2i(1280, 720):
			I18N.set_resolution(1920, 1080)
		Vector2i(1920, 1080):
			I18N.set_resolution(2560, 1440)
		_:
			I18N.set_resolution(1280, 720)
	_res_btn.text = _resolution_text()


func _on_quit_pressed():
	AudioManager.play_sfx("menu_select")
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()


func _input(event):
	if event.is_action_pressed("fullscreen"):
		I18N.toggle_fullscreen()
		_fs_btn.text = _fullscreen_text()
		get_viewport().set_input_as_handled()


# ═══════════════════════════════════════════════════════════
# Helpers
# ═══════════════════════════════════════════════════════════

func _fullscreen_text() -> String:
	return I18N.t("menu.fullscreen_off") if not I18N.fullscreen else I18N.t("menu.fullscreen_on")


func _resolution_text() -> String:
	var w = I18N.resolution.x
	var h = I18N.resolution.y
	return "%dx%d" % [w, h]


# UnlockManager 延迟加载
var _unlock_manager: Node = null

func _lazy_unlock_manager() -> Node:
	if _unlock_manager == null:
		_unlock_manager = load("res://scripts/managers/unlock_manager.gd").new()
		add_child(_unlock_manager)
		EventBus.register_unlock_manager(_unlock_manager)
	return _unlock_manager


func play_menu_music():
	if AudioManager and AudioManager.has_method("play_bgm"):
		AudioManager.play_bgm(AudioManager.sounds.get("bgm_menu"))
