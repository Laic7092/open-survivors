extends Control

const UiUtils = preload("res://scripts/ui/ui_utils.gd")

# 对应 passive item 的 powerup → item_type 映射
# 当对应 item 未解锁时，powerup 不可购买
const POWERUP_ITEM_MAP := {
	"might": 4,      # Spinach
	"max_hp": 6,     # Hollow Heart
	"recovery": 9,   # Pummarola
	"cooldown": 5,   # Empty Tome
	"area": 7,       # Candelabrador
	"speed": 24,     # Bracer
	"duration": 22,  # Spellbinder
	"amount": 13,    # Duplicator
	"movespeed": 3,  # Wings
	"magnet": 15,    # Attractorb
	"luck": 21,      # Clover
	"growth": 8,     # Crown
	"armor": 23,     # Armor
	"curse": 25,     # Skull O'Maniac
	"revival": 26,   # Tiragisú
	"omni": 27,      # Torrona's Box
}

@onready var _title: Label = %Title
@onready var _gold_lbl: Label = %GoldLabel
@onready var _grid: GridContainer = %Grid
@onready var _back_btn: Button = %BackBtn


func _ready():
	_title.text = I18N.t("powerup.title")
	_back_btn.text = I18N.t("powerup.back")

	_back_btn.pressed.connect(_on_back)
	_rebuild.call_deferred()
	get_viewport().size_changed.connect(_rebuild)


func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()


const FEATURE_GATE := {
	"charm": "powerup_charm",
	"defang": "powerup_defang",
	"preserve": "powerup_preserve",
}


func _rebuild():
	_clear_grid()

	_gold_lbl.text = I18N.t("menu.gold") + str(PowerUpManager.gold)

	# 根据可用宽度动态计算列数 + 卡片宽度
	var vp = get_viewport().get_visible_rect().size
	var margin_total = 60.0  # scroll container 左右 margin
	var h_gap = 20.0
	var avail_w = vp.x - margin_total
	var card_min_w = 280.0
	var cols = max(2, int((avail_w + h_gap) / (card_min_w + h_gap)))
	cols = mini(cols, 5)
	_grid.columns = cols
	# 精确计算每张卡片宽度以填满 GridContainer
	var card_w = (avail_w - (cols - 1) * h_gap) / cols

	var ids = PowerUpManager.POWERUPS.keys()
	ids.sort()
	for id in ids:
		_add_powerup_card(id, card_w)


func _is_powerup_locked(id: String) -> bool:
	# 遗物门控（如 charm/defang/preserve）
	if FEATURE_GATE.has(id):
		if not RelicManager.is_feature_unlocked(FEATURE_GATE[id]):
			return true
	# 对应 passive item 未解锁
	if POWERUP_ITEM_MAP.has(id):
		var item_type = POWERUP_ITEM_MAP[id]
		if not UnlockManager.is_item_unlocked(item_type):
			return true
	return false


func _add_powerup_card(id: String, card_w: float = 0.0):
	var info = PowerUpManager.POWERUPS[id]
	var lv = PowerUpManager.get_level(id)
	var max_lv = info["max_lv"]
	var cost = PowerUpManager.get_cost(id)
	var locked = _is_powerup_locked(id)

	# ── 卡片：VBoxContainer + 背景边框 ──
	var card = VBoxContainer.new()
	card.custom_minimum_size = Vector2(card_w, 150)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_constant_override("separation", 4)
	_grid.add_child(card)
	
	# 背景色
	var bg = ColorRect.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.06, 0.06, 0.14)
	card.add_child(bg)
	card.move_child(bg, 0)
	
	# 圆角边框 (用 draw_style_box，StyleBoxFlat 在闭包外创建，只一次)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color.TRANSPARENT
	sb.border_color = Color(0.3, 0.3, 0.5, 0.4)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.border_blend = true
	card.draw.connect(func():
		card.draw_style_box(sb, Rect2(Vector2.ZERO, card.size))
	)

	# ── 顶栏：名称 + 等级 ──
	var header = HBoxContainer.new()
	card.add_child(header)

	var nm = Label.new()
	nm.text = I18N.t("pu." + id, info["name"])
	nm.add_theme_font_size_override("font_size", 20)
	nm.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5) if locked else Color.WHITE)
	header.add_child(nm)

	var lv_color: Color
	var lv_text: String
	if locked:
		lv_text = "🔒"
		lv_color = Color(0.8, 0.6, 0.2)
	elif lv >= max_lv:
		lv_text = "MAX"
		lv_color = Color(0.3, 1.0, 0.3)
	else:
		lv_text = str(lv) + "/" + str(max_lv)
		lv_color = Color(0.8, 0.8, 0.8)
	header.add_spacer(true)
	var lv_lbl = Label.new()
	lv_lbl.text = lv_text
	lv_lbl.add_theme_font_size_override("font_size", 16)
	lv_lbl.add_theme_color_override("font_color", lv_color)
	header.add_child(lv_lbl)

	# ── 分隔线 1 ──
	var sep1 = ColorRect.new()
	sep1.color = Color(0.9, 0.8, 0.2, 0.15)
	sep1.custom_minimum_size = Vector2(0, 1)
	sep1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(sep1)

	# ── 描述 ──
	var desc = Label.new()
	if locked:
		# 判断是遗物锁定还是 item 锁定
		if FEATURE_GATE.has(id) and not RelicManager.is_feature_unlocked(FEATURE_GATE[id]):
			var feature_id = FEATURE_GATE[id]
			var rid = DataRegistry.relics().get_relic_for_feature(feature_id)
			var relic_name = I18N.t("relic." + rid, rid)
			desc.text = "🔒 " + I18N.t("powerup.need_relic") % relic_name
		else:
			var item_type = POWERUP_ITEM_MAP.get(id, -1)
			var item_name = ""
			if item_type >= 0:
				item_name = I18N.t(DataRegistry.items().item_name_key(item_type), DataRegistry.items().item_name(item_type))
			desc.text = "🔒 " + I18N.t("powerup.need_item") % item_name
	else:
		desc.text = I18N.t("pu." + id + "_desc", info["desc"])
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(desc)

	# ── 分隔线 2 ──
	var sep2 = ColorRect.new()
	sep2.color = Color(0.9, 0.8, 0.2, 0.15)
	sep2.custom_minimum_size = Vector2(0, 1)
	sep2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(sep2)

	# ── 底栏：费用 + 购买按钮 ──
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
