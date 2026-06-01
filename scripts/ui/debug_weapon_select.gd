extends Control
# 调试模式 — 自行选择初始武器

const ItemTypes = preload("res://scripts/data/item_types.gd")

@onready var _title: Label = %Title
@onready var _grid: GridContainer = %Grid
@onready var _count_lbl: Label = %CountLabel
@onready var _start_btn: Button = %StartBtn
@onready var _back_btn: Button = %BackBtn

# 武器 → emoji 映射（简单直观）
const WEP_EMOJI: Dictionary = {
	0: "🔪",   # Whip
	1: "🪄",   # Magic Wand
	2: "🧄",   # Garlic
	10: "🗡️",  # Knife
	11: "🪓",  # Axe
	12: "🔥",  # Fire Wand
	16: "✝️",  # Cross
	17: "📖",  # King Bible
	18: "💧",  # Santa Water
	19: "🔶",  # Runetracer
	20: "⚡",  # Lightning Ring
	32: "⭐",  # Pentagram
	33: "🐦",  # Peachone
	34: "🐦‍⬛", # Ebony Wings
	35: "🔫",  # Phiera Der Tuphello
	36: "🐤",  # Eight The Sparrow
	37: "🐱",  # Gatti Amari
	38: "🎵",  # Song of Mana
	39: "🦇",  # Shadow Pinion
	40: "⏰",  # Clock Lancet
	41: "🌿",  # Laurel
	42: "💨",  # Vento Sacro
	43: "🦴",  # Bone
	44: "🍒",  # Cherry Bomb
	45: "🚗",  # Carrello
	46: "✨",  # Celestial Dusting
	47: "🌀",  # La Robba
	48: "🎉",  # Greatest Jubilee
	49: "📿",  # Bracelet
	50: "🍬",  # Candybox
	51: "⚔️",  # Victory Sword
	52: "📜",  # Flames of Misspell
	53: "🔨",  # Pako Battiliar
	54: "🎯",  # Ammo Appalate
	55: "🔮",  # Chaos Rune
	56: "❄️",  # Glass Fandango
	57: "🔱",  # Santa Javelin
	58: "👁️",  # Gaze of Gaea
	59: "💎",  # Magi Stone
	60: "💿",  # Phas3r
	61: "🛡️",  # Arma Dio
}

var _selected: Dictionary = {}  # type → true
var _btns: Dictionary = {}  # type → Button


func _ready():
	_title.text = "🧪 " + I18N.t("menu.debug_weapon_select")
	_start_btn.text = I18N.t("stage_select.select")
	_back_btn.text = I18N.t("char_select.back")
	_start_btn.pressed.connect(_on_start)
	_back_btn.pressed.connect(_on_back)
	_rebuild_grid()


func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()


func _rebuild_grid():
	for c in _grid.get_children():
		c.queue_free()

	var weapons = ItemTypes.WEAPON_TYPES
	_grid.columns = max(1, _calc_cols())

	for w_type in weapons:
		var btn = _make_weapon_card(w_type)
		_grid.add_child(btn)
		_btns[w_type] = btn

	_update_count()


func _calc_cols() -> int:
	var vp = get_viewport().get_visible_rect().size
	return max(1, int(vp.x / 160))


func _make_weapon_card(type: int) -> Button:
	var btn = Button.new()
	btn.toggle_mode = true
	btn.custom_minimum_size = Vector2(140, 100)
	btn.size = Vector2(140, 100)

	var emoji = WEP_EMOJI.get(type, "❓")
	var name_key = _wep_name_key(type)
	var name_text = I18N.t(name_key)

	# Vertical layout inside button (icon on top, name below)
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn.add_child(vbox)

	var icon = Label.new()
	icon.text = emoji
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 28)
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(icon)

	var nm = Label.new()
	nm.text = name_text
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 12)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(nm)

	btn.toggled.connect(_on_toggled.bind(type))
	return btn


func _on_toggled(toggled_on: bool, type: int):
	if toggled_on:
		_selected[type] = true
	else:
		_selected.erase(type)
	_update_count()


func _update_count():
	var count = _selected.size()
	if count == 0:
		_count_lbl.text = I18N.t("debug.select_weapons")
		_start_btn.disabled = true
	else:
		_count_lbl.text = I18N.t("debug.selected_count") % count
		_start_btn.disabled = false


func _on_start():
	if _selected.is_empty():
		return
	var weapon_list = _selected.keys()
	weapon_list.sort()
	EventBus.set_config("debug_starting_weapons", weapon_list)
	# Use default character for stats (character 0 = Antonio)
	var default_char = _get_default_character()
	EventBus.set_config("selected_character", default_char)
	SceneManager.change_scene("res://scenes/stage_select.tscn")


func _on_back():
	AudioManager.play_sfx("menu_select")
	SceneManager.change_scene("res://scenes/main_menu.tscn")


func _get_default_character() -> Dictionary:
	var chars = DataRegistry.characters().CHARACTERS
	if chars.is_empty():
		return {"id": 0, "weapon": 0, "bonus_type": "", "bonus_value": 0.0, "stats": {}}
	return chars[0].duplicate()


static func _wep_name_key(type: int) -> String:
	match type:
		0: return "item.whip_name"
		1: return "item.wand_name"
		2: return "item.garlic_name"
		10: return "item.knife_name"
		11: return "item.axe_name"
		12: return "item.firewand_name"
		16: return "item.cross_name"
		17: return "item.bible_name"
		18: return "item.santa_water_name"
		19: return "item.runetracer_name"
		20: return "item.lightning_name"
		32: return "item.pentagram_name"
		33: return "item.peachone_name"
		34: return "item.ebony_wings_name"
		35: return "item.phiera_name"
		36: return "item.eight_name"
		37: return "item.gatti_amari_name"
		38: return "item.song_of_mana_name"
		39: return "item.shadow_pinion_name"
		40: return "item.clock_lancet_name"
		41: return "item.laurel_name"
		42: return "item.vento_sacro_name"
		43: return "item.bone_name"
		44: return "item.cherry_bomb_name"
		45: return "item.carrello_name"
		46: return "item.celestial_dusting_name"
		47: return "item.la_robba_name"
		48: return "item.greatest_jubilee_name"
		49: return "item.bracelet_name"
		51: return "item.victory_sword_name"
		52: return "item.flames_of_misspell_name"
		53: return "item.pako_battiliar_name"
		54: return "item.ammo_appalate_name"
		55: return "item.chaos_rune_name"
		56: return "item.glass_fandango_name"
		57: return "item.santa_javelin_name"
		58: return "item.gaze_of_gaea_name"
		59: return "item.magi_stone_name"
		60: return "item.phas3r_name"
		61: return "item.arma_dio_name"
	return "item.whip_name"
