extends Control

const UiUtils = preload("res://scripts/ui/ui_utils.gd")

@onready var _title: Label = %Title
@onready var _gold_lbl: Label = %GoldLabel
@onready var _grid: GridContainer = %Grid
@onready var _back_btn: Button = %BackBtn


func _ready():
	_title.text = I18N.t("powerup.title")
	_back_btn.text = I18N.t("powerup.back")

	_back_btn.pressed.connect(_on_back)
	_rebuild()
	get_viewport().size_changed.connect(_rebuild)


const FEATURE_GATE := {
	"charm": "powerup_charm",
	"defang": "powerup_defang",
	"preserve": "powerup_preserve",
}


func _rebuild():
	_clear_grid()

	_gold_lbl.text = I18N.t("menu.gold") + str(PowerUpManager.gold)

	var ids = PowerUpManager.POWERUPS.keys()
	ids.sort()
	for id in ids:
		_add_powerup_card(id)


func _is_powerup_locked(id: String) -> bool:
	if FEATURE_GATE.has(id):
		return not RelicManager.is_feature_unlocked(FEATURE_GATE[id])
	return false


func _add_powerup_card(id: String):
	var info = PowerUpManager.POWERUPS[id]
	var lv = PowerUpManager.get_level(id)
	var max_lv = info["max_lv"]
	var cost = PowerUpManager.get_cost(id)
	var locked = _is_powerup_locked(id)

	var card = VBoxContainer.new()
	card.custom_minimum_size = Vector2(360, 130)
	_grid.add_child(card)

	var header = HBoxContainer.new()
	card.add_child(header)

	var nm = Label.new()
	nm.text = I18N.t("pu." + id, info["name"])
	nm.add_theme_font_size_override("font_size", 20)
	nm.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5) if locked else Color.WHITE)
	header.add_child(nm)

	if locked:
		var lock_lbl = Label.new()
		lock_lbl.text = " 🔒"
		lock_lbl.add_theme_font_size_override("font_size", 16)
		lock_lbl.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))
		header.add_child(lock_lbl)
	else:
		var lv_str = " [" + str(lv) + "/" + str(max_lv) + "]"
		var lv_lbl = Label.new()
		lv_lbl.text = lv_str
		lv_lbl.add_theme_font_size_override("font_size", 16)
		var lv_color = Color(0.3, 1.0, 0.3) if lv >= max_lv else Color(0.8, 0.8, 0.8)
		lv_lbl.add_theme_color_override("font_color", lv_color)
		header.add_child(lv_lbl)

	header.add_spacer(true)

	var desc = Label.new()
	if locked:
		var feature_id = FEATURE_GATE[id]
		var rid = DataRegistry.relics().get_relic_for_feature(feature_id)
		var relic_name = I18N.t("relic." + rid, rid)
		desc.text = "🔒 " + I18N.t("powerup.need_relic") % relic_name
	else:
		desc.text = I18N.t("pu." + id + "_desc", info["desc"])
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	card.add_child(desc)

	var buy_row = HBoxContainer.new()
	card.add_child(buy_row)

	if locked:
		var need_lbl = Label.new()
		need_lbl.text = I18N.t("powerup.locked")
		need_lbl.add_theme_font_size_override("font_size", 14)
		need_lbl.add_theme_color_override("font_color", Color(0.6, 0.4, 0.2))
		buy_row.add_child(need_lbl)
	elif lv >= max_lv:
		var maxed = Label.new()
		maxed.text = I18N.t("powerup.maxed")
		maxed.add_theme_font_size_override("font_size", 16)
		maxed.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		buy_row.add_child(maxed)
	else:
		var cost_lbl = Label.new()
		cost_lbl.text = I18N.t("powerup.cost") % cost
		cost_lbl.add_theme_font_size_override("font_size", 14)
		cost_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.1))
		buy_row.add_child(cost_lbl)

		buy_row.add_spacer(true)

		var buy_btn = Button.new()
		buy_btn.text = I18N.t("powerup.buy")
		buy_btn.custom_minimum_size = Vector2(80, 32)
		var can_afford = PowerUpManager.gold >= cost
		buy_btn.theme_type_variation = &"PrimaryButton" if can_afford else &"DangerButton"
		buy_btn.disabled = not can_afford
		buy_btn.pressed.connect(_on_buy.bind(id))
		buy_row.add_child(buy_btn)


func _on_buy(id: String):
	if PowerUpManager.buy_powerup(id):
		_rebuild()


func _on_back():
	SceneManager.change_scene("res://scenes/main_menu.tscn")


func _clear_grid():
	for c in _grid.get_children():
		c.queue_free()
