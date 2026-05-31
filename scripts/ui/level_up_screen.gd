extends Control
# level_up_screen.gd — 纯 UI 渲染层
# 所有选择逻辑委托给 LevelUpService（scripts/core/level_up_service.gd）
# 不再包含选择生成逻辑

signal upgrade_selected(upgrade_type: int)
signal evolution_selected(weapon_type: int)
signal gold_selected(amount: int)
signal chicken_selected(amount: int)
signal limit_break_selected(weapon_type: int, option: Dictionary)

const LevelUpService = preload("res://scripts/core/level_up_service.gd")
const IconGenerator = preload("res://scripts/ui/icon_generator.gd")
const UiUtils = preload("res://scripts/ui/ui_utils.gd")
const WeaponManagerScript = preload("res://scripts/entities/weapon_manager.gd")

const MAX_WEAPONS = 6
const MAX_PASSIVES = 6

# 当前展示的 Choices 缓存（用于 Skip / Reroll / Banish）
var _current_choices: Array = []
var _player_ref: Node = null
var _panel: Panel
var _title: Label
var _container: HBoxContainer
var _reroll_btn: Button
var _skip_btn: Button
var _banish_btn: Button
var _button_bar: HBoxContainer

# PowerUp 剩余次数
var _rerolls_left: int = 0
var _skips_left: int = 0
var _banishes_left: int = 0

# 魔法常量
const GOLD_FALLBACK_CODE = -9999
const CHICKEN_FALLBACK_CODE = -8888


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	mouse_filter = MOUSE_FILTER_STOP
	anchor_right = 1.0
	anchor_bottom = 1.0
	visible = false


func show_choices(p):
	_player_ref = p
	var has_gospel = RelicManager and RelicManager.has_relic("great_gospel")
	var is_random = EventBus.get_config("random_level_up", false)
	var always_chicken = EventBus.get_config("always_chicken_unlocked", false)
	var luck = p.luck

	# 查询 PowerUp 剩余次数（Reroll / Skip / Banish）
	_rerolls_left = PowerUpManager.get_rerolls_remaining() if PowerUpManager else 0
	_skips_left = PowerUpManager.get_skips_remaining() if PowerUpManager else 0
	_banishes_left = PowerUpManager.get_banishes_remaining() if PowerUpManager else 0

	_current_choices = LevelUpService.generate_choices(
		p,
		p.weapon_manager,
		p.passive_inventory,
		luck,
		has_gospel,
		is_random,
		always_chicken,
		p.level,
	)

	visible = true
	_clear()
	_create_ui()

	if is_random:
		# Random LevelUp: 自动选择第一个，不显示 UI
		var picked = _current_choices[0] if not _current_choices.is_empty() else null
		if picked:
			_emit_choice(picked)
		return

	_render_choices()


func _create_ui():
	_panel = Panel.new()
	_panel.anchor_left = 0.0
	_panel.anchor_top = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.theme_type_variation = &"OverlayPanel"
	add_child(_panel)

	var vp = get_viewport().get_visible_rect().size
	var panel_w = mini(800, vp.x - 40)
	var panel_h = mini(480, vp.y - 40)
	var vb = VBoxContainer.new()
	vb.anchor_left = 0.5
	vb.anchor_top = 0.5
	vb.anchor_right = 0.5
	vb.anchor_bottom = 0.5
	vb.offset_left = -panel_w / 2
	vb.offset_top = -panel_h / 2
	vb.offset_right = panel_w / 2
	vb.offset_bottom = panel_h / 2
	_panel.add_child(vb)

	_title = Label.new()
	_title.text = I18N.t("levelup.title")
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 36)
	_title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	_title.custom_minimum_size = Vector2(0, 50)
	vb.add_child(_title)

	var sp = Control.new()
	sp.custom_minimum_size = Vector2(0, 16)
	vb.add_child(sp)

	_container = HBoxContainer.new()
	_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_container.add_theme_constant_override("separation", 20)
	_container.size = Vector2(panel_w, 280)
	vb.add_child(_container)

	# ── Skip / Reroll / Banish 按钮栏 ──
	_button_bar = HBoxContainer.new()
	_button_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_button_bar.add_theme_constant_override("separation", 12)
	var has_any_action = _rerolls_left > 0 or _skips_left > 0 or _banishes_left > 0
	_button_bar.visible = has_any_action
	vb.add_child(_button_bar)

	if _rerolls_left > 0:
		_reroll_btn = Button.new()
		_reroll_btn.text = I18N.t("levelup.reroll") % _rerolls_left
		_reroll_btn.theme_type_variation = &"NeutralButton"
		_reroll_btn.custom_minimum_size = Vector2(120, 36)
		_reroll_btn.pressed.connect(_on_reroll)
		_button_bar.add_child(_reroll_btn)

	if _skips_left > 0:
		_skip_btn = Button.new()
		_skip_btn.text = I18N.t("levelup.skip") % _skips_left
		_skip_btn.theme_type_variation = &"NeutralButton"
		_skip_btn.custom_minimum_size = Vector2(120, 36)
		_skip_btn.pressed.connect(_on_skip)
		_button_bar.add_child(_skip_btn)

	if _banishes_left > 0:
		_banish_btn = Button.new()
		_banish_btn.text = I18N.t("levelup.banish") % _banishes_left
		_banish_btn.theme_type_variation = &"NeutralButton"
		_banish_btn.custom_minimum_size = Vector2(120, 36)
		_banish_btn.pressed.connect(_on_banish)
		_button_bar.add_child(_banish_btn)


func _render_choices():
	for c in _current_choices:
		match c.type:
			LevelUpService.ChoiceType.ITEM:
				_add_item_choice(c)
			LevelUpService.ChoiceType.EVOLUTION:
				_add_evolution_choice(c)
			LevelUpService.ChoiceType.LIMIT_BREAK:
				_add_limit_break_choice(c)
			LevelUpService.ChoiceType.GOLD:
				_add_gold_choice(c)
			LevelUpService.ChoiceType.CHICKEN:
				_add_chicken_choice(c)


# ── 普通道具选项 ──
func _add_item_choice(c):
	var vb2 = VBoxContainer.new()
	vb2.custom_minimum_size = Vector2(190, 220)
	vb2.alignment = BoxContainer.ALIGNMENT_CENTER

	var icon_node = IconGenerator.make_icon_node(c.item_type, 40)
	icon_node.custom_minimum_size = Vector2(40, 40)
	icon_node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb2.add_child(icon_node)

	var lv_txt = I18N.t("levelup.new") if c.is_new else I18N.t("levelup.level") % [c.level_before, c.level_after]
	var desc = DataRegistry.items().item_desc(c.item_type)

	# 名称
	var l1 = Label.new()
	l1.text = c.label
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l1.add_theme_font_size_override("font_size", 22)
	l1.add_theme_color_override("font_color", c.color)
	vb2.add_child(l1)

	# 等级
	var l2 = Label.new()
	l2.text = lv_txt
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l2.add_theme_font_size_override("font_size", 14)
	l2.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vb2.add_child(l2)

	# 描述
	var l3 = Label.new()
	l3.text = desc
	l3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l3.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l3.add_theme_font_size_override("font_size", 12)
	l3.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vb2.add_child(l3)

	var btn = UiUtils.make_choice_button(vb2)
	var item_type = c.item_type
	btn.pressed.connect(func(): _on_item_choice(item_type))
	_container.add_child(vb2)


# ── 进化选项 ──
func _add_evolution_choice(c):
	var vb2 = VBoxContainer.new()
	vb2.custom_minimum_size = Vector2(210, 240)
	vb2.alignment = BoxContainer.ALIGNMENT_CENTER

	var recipe = WeaponManagerScript.EVOLUTION_RECIPES.get(c.item_type, {})
	var evo_name = recipe.get("name", c.label)
	var evo_desc = recipe.get("desc", "")

	# 金色图标
	var icon_node = IconGenerator.make_icon_node(c.item_type, 44, Color(0.9, 0.7, 0.1))
	icon_node.custom_minimum_size = Vector2(44, 44)
	icon_node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb2.add_child(icon_node)

	# EVOLVE 徽标
	var badge = Label.new()
	badge.text = I18N.t("levelup.evolve")
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 16)
	badge.add_theme_color_override("font_color", Color(0.9, 0.7, 0.1))
	vb2.add_child(badge)

	# 进化后名称
	var evo_i18n_name = I18N.t("evo." + _evo_i18n_key(c.item_type) + "_name", evo_name)
	var l1 = Label.new()
	l1.text = evo_i18n_name
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l1.add_theme_font_size_override("font_size", 24)
	l1.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	vb2.add_child(l1)

	# 源武器箭头
	var src_i18n = I18N.t(DataRegistry.items().item_name_key(c.item_type), DataRegistry.items().item_name(c.item_type))
	var l2 = Label.new()
	l2.text = src_i18n + I18N.t("levelup.evo_arrow") + evo_i18n_name
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l2.add_theme_font_size_override("font_size", 12)
	l2.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
	vb2.add_child(l2)

	# 描述
	var evo_i18n_desc = I18N.t("evo." + _evo_i18n_key(c.item_type) + "_desc", evo_desc)
	var l3 = Label.new()
	l3.text = evo_i18n_desc
	l3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l3.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l3.add_theme_font_size_override("font_size", 12)
	l3.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
	vb2.add_child(l3)

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 140)
	btn.theme_type_variation = &"GoldButton"
	vb2.add_child(btn)

	var wt = c.item_type
	btn.pressed.connect(func(): _on_evolution_choice(wt))
	_container.add_child(vb2)


# ── Limit Break 选项 ──
func _add_limit_break_choice(c):
	var vb2 = VBoxContainer.new()
	vb2.custom_minimum_size = Vector2(200, 240)
	vb2.alignment = BoxContainer.ALIGNMENT_CENTER

	var opt = c.limit_break_option

	# Limit Break 徽标
	var badge = Label.new()
	badge.text = "★ " + I18N.t("levelup.limit_break") + " ★"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_color_override("font_color", Color(0.9, 0.8, 0.1))
	badge.add_theme_font_size_override("font_size", 10)
	vb2.add_child(badge)

	# 武器图标
	var icon = TextureRect.new()
	icon.texture = IconGenerator.generate(c.item_type, 36)
	icon.custom_minimum_size = Vector2(36, 36)
	icon.stretch_mode = TextureRect.STRETCH_KEEP
	vb2.add_child(icon)

	# 属性标签
	var stat_key = opt.get("stat", "?")
	var stat_val = opt.get("value", 0)
	var stat_display = _limit_break_stat_name(stat_key)
	var stat_label = Label.new()
	var sign = "+" if stat_val >= 0 else ""
	stat_label.text = stat_display + "  " + sign + str(stat_val) + _limit_break_stat_suffix(stat_key)
	stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	stat_label.add_theme_font_size_override("font_size", 14)
	vb2.add_child(stat_label)

	# 累计进度
	var w = _player_ref.weapon_manager.find_weapon(c.item_type)
	var total_so_far = w.limit_break_bonuses.get(stat_key, 0.0) if w else 0.0
	var max_total = opt.get("max_total", -1)
	var total_text = ""
	if max_total > 0:
		total_text = "[ %d / %d ]" % [total_so_far + stat_val, max_total]
	else:
		total_text = "[ +%.1f ]" % [total_so_far + stat_val]
	var total_label = Label.new()
	total_label.text = total_text
	total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	total_label.add_theme_font_size_override("font_size", 10)
	vb2.add_child(total_label)

	var btn = UiUtils.make_choice_button(vb2)
	var wt = c.item_type
	var opt_ref = opt.duplicate()
	btn.pressed.connect(func():
		var ok = _player_ref.weapon_manager.apply_limit_break(wt, opt_ref)
		if ok:
			limit_break_selected.emit(wt, opt_ref)
			upgrade_selected.emit(wt)
	)
	_container.add_child(vb2)


# ── 金币选项 ──
func _add_gold_choice(c):
	var vb2 = VBoxContainer.new()
	vb2.custom_minimum_size = Vector2(190, 200)
	vb2.alignment = BoxContainer.ALIGNMENT_CENTER

	var icon = TextureRect.new()
	icon.texture = IconGenerator.generate(14, 40)  # STONE_MASK = coin
	icon.custom_minimum_size = Vector2(40, 40)
	icon.stretch_mode = TextureRect.STRETCH_KEEP
	icon.modulate = Color(0.9, 0.8, 0.1)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb2.add_child(icon)

	var l1 = Label.new()
	l1.text = c.label
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l1.add_theme_font_size_override("font_size", 22)
	l1.add_theme_color_override("font_color", Color(0.9, 0.8, 0.1))
	vb2.add_child(l1)

	var l2 = Label.new()
	l2.text = I18N.t("levelup.gold_desc", "All slots full!")
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l2.add_theme_font_size_override("font_size", 14)
	l2.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
	vb2.add_child(l2)

	var btn = UiUtils.make_choice_button(vb2)
	var amt = c.gold_amount
	btn.pressed.connect(func(): _on_gold_choice(amt))
	_container.add_child(vb2)


# ── Floor Chicken 选项 ──
func _add_chicken_choice(c):
	var vb2 = VBoxContainer.new()
	vb2.custom_minimum_size = Vector2(190, 200)
	vb2.alignment = BoxContainer.ALIGNMENT_CENTER

	# 鸡肉图标（用绿色圆 + 🍗）
	var icon = TextureRect.new()
	icon.texture = IconGenerator.generate(14, 40)  # 借用 coin 圆形
	icon.custom_minimum_size = Vector2(40, 40)
	icon.stretch_mode = TextureRect.STRETCH_KEEP
	icon.modulate = Color(0.3, 1.0, 0.3)
	vb2.add_child(icon)

	var l1 = Label.new()
	l1.text = I18N.t("pickup.floor_chicken")
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l1.add_theme_font_size_override("font_size", 22)
	l1.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	vb2.add_child(l1)

	var l2 = Label.new()
	l2.text = I18N.t("levelup.chicken_desc", "Restore HP")
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l2.add_theme_font_size_override("font_size", 14)
	l2.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
	vb2.add_child(l2)

	var btn = UiUtils.make_choice_button(vb2)
	var amt = c.chicken_amount
	btn.pressed.connect(func(): _on_chicken_choice(amt))
	_container.add_child(vb2)


# ═══════════════════════════════════════════════════════════════════
#  Signal Handlers
# ═══════════════════════════════════════════════════════════════════

func _on_item_choice(item_type: int):
	upgrade_selected.emit(item_type)


func _on_gold_choice(amount: int):
	gold_selected.emit(amount)


func _on_chicken_choice(amount: int):
	chicken_selected.emit(amount)


func _on_evolution_choice(weapon_type: int):
	evolution_selected.emit(weapon_type)


func _emit_choice(c):
	match c.type:
		LevelUpService.ChoiceType.ITEM:
			_on_item_choice(c.item_type)
		LevelUpService.ChoiceType.EVOLUTION:
			_on_evolution_choice(c.item_type)
		LevelUpService.ChoiceType.LIMIT_BREAK:
			pass  # 已通过按钮 emit
		LevelUpService.ChoiceType.GOLD:
			_on_gold_choice(c.gold_amount)
		LevelUpService.ChoiceType.CHICKEN:
			_on_chicken_choice(c.chicken_amount)


# ── Skip: 跳过本次升级，保留一些 XP ──
func _on_skip():
	PowerUpManager.use_skip() if PowerUpManager else null
	_skips_left -= 1
	# Skip 保留 50% 当前 XP
	var retained_xp = int(_player_ref.xp * 0.5)
	_player_ref.xp = retained_xp
	_player_ref.xp_changed.emit(_player_ref.xp, _player_ref.xp_to_next)
	hide_screen()
	get_tree().paused = false


# ── Reroll: 重新生成选项 ──
func _on_reroll():
	PowerUpManager.use_reroll() if PowerUpManager else null
	_rerolls_left -= 1
	_clear_container()
	# 重新生成（不增加进化候选，固定当前池）
	_current_choices = LevelUpService.generate_choices(
		_player_ref,
		_player_ref.weapon_manager,
		_player_ref.passive_inventory,
		_player_ref.luck,
		RelicManager.has_relic("great_gospel") if RelicManager else false,
		false,
		false,
		_player_ref.level,
	)
	_render_choices()
	# 更新按钮文字
	if _reroll_btn:
		_reroll_btn.text = I18N.t("levelup.reroll") % max(_rerolls_left, 0)
		_reroll_btn.visible = _rerolls_left > 0


# ── Banish: 移除一个选项并补充 ──
func _on_banish():
	# 简化实现：移除最后一个选项并刷新
	PowerUpManager.use_banish() if PowerUpManager else null
	_banishes_left -= 1
	if _current_choices.size() > 0:
		_current_choices.pop_back()
		# 从全局池补一个
		var extra = LevelUpService.generate_choices(
			_player_ref,
			_player_ref.weapon_manager,
			_player_ref.passive_inventory,
			_player_ref.luck,
			RelicManager.has_relic("great_gospel") if RelicManager else false,
			false,
			false,
			_player_ref.level,
		)
		if extra.size() > 0:
			_current_choices.append(extra[0])
	_clear_container()
	_render_choices()
	if _banish_btn:
		_banish_btn.text = I18N.t("levelup.banish") % max(_banishes_left, 0)
		_banish_btn.visible = _banishes_left > 0


# ═══════════════════════════════════════════════════════════════════
#  UI 辅助
# ═══════════════════════════════════════════════════════════════════

func _clear_container():
	if _container:
		for c in _container.get_children():
			c.queue_free()


func hide_screen():
	visible = false
	_clear()


func _clear():
	for c in get_children():
		c.queue_free()
	_panel = null
	_title = null
	_container = null
	_reroll_btn = null
	_skip_btn = null
	_banish_btn = null
	_button_bar = null
	_current_choices.clear()


# ── Limit Break stat 名称映射 ──
static func _limit_break_stat_name(key: String) -> String:
	match key:
		"might_pct": return "Might"
		"area_pct": return "Area"
		"speed_pct": return "Speed"
		"amt": return "Amount"
		"base_dmg": return "Base DMG"
		"cd_pct": return "Cooldown"
		_: return key.capitalize()


static func _limit_break_stat_suffix(key: String) -> String:
	match key:
		"might_pct", "area_pct", "speed_pct", "cd_pct":
			return "%"
		"amt", "base_dmg":
			return ""
		_: return ""


# ── 委托到 DataRegistry ──
static func _evo_i18n_key(weapon_type: int) -> String:
	return DataRegistry.items().item_evo_key(weapon_type)



