extends Node
# Internationalization system — lightweight string-table based i18n.
# Usage: I18N.t("key") returns the string in the current language.
# Add new languages by appending entries to _tables.

const SETTINGS_PATH := "user://desire_survivors_settings.json"

var current_lang: String = "zh"  # default: Chinese
var fullscreen: bool = false
var resolution: Vector2i = Vector2i(1280, 720)
var _tables: Dictionary = {}
var _loaded: bool = false


func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	_load_settings()
	_load_tables()


func set_language(lang: String):
	if not _tables.has(lang):
		return
	current_lang = lang
	_save_settings()


func _tr(key: String, fallback: String = "") -> String:
	if not _loaded:
		_load_tables()
	if _tables.has(current_lang) and _tables[current_lang].has(key):
		return _tables[current_lang][key]
	# Fallback to English
	if _tables.has("en") and _tables["en"].has(key):
		return _tables["en"][key]
	return fallback if fallback != "" else key


# Public alias with a safe name (avoids conflict with built-in tr())
func t(key: String, fallback: String = "") -> String:
	return _tr(key, fallback)


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
	if data.has("language") and _tables.has(data["language"]):
		current_lang = data["language"]
	if data.has("fullscreen"):
		fullscreen = data["fullscreen"]
	if data.has("resolution_w") and data.has("resolution_h"):
		resolution = Vector2i(data["resolution_w"], data["resolution_h"])
	_apply_display_settings()


func _apply_display_settings():
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


# ── String tables ──

func _load_tables():
	_tables = {
		"zh": _zh(),
		"en": _en(),
	}
	_loaded = true


# ═══════════════════════════════════════════════════════════
#  CHINESE — 中文（默认）
# ═══════════════════════════════════════════════════════════

static func _zh() -> Dictionary:
	return {
		# ── Main Menu ──
		"menu.title": "欲望幸存者",
		"menu.subtitle": "吸血鬼幸存者同人游戏",
		"menu.start_game": "开始游戏",
		"menu.power_ups": "能力强化",
		"menu.quit": "退出游戏",
		"menu.gold": "金币: ",
		"menu.footer": "v1.0 — 使用 Godot 4 制作",
		"menu.language": "English",

		# ── Character Select ──
		"char_select.title": "选择角色",
		"char_select.gold": "金币: ",
		"char_select.back": "返回",
		"char_select.select": "选择",
		"char_select.buy": "购买",
		"char_select.cost": "价格: %d 金币",
		"char_select.locked": "🔒",

		# ── Character Names & Descs ──
		"char.0_name": "安东尼奥",
		"char.0_desc": "+10% 伤害",
		"char.0_full": "初始武器：鞭子\n+10% 伤害",
		"char.1_name": "伊梅尔达",
		"char.1_desc": "+10% 经验获取",
		"char.1_full": "初始武器：魔法杖\n+10% 经验获取",
		"char.2_name": "帕斯夸莉娜",
		"char.2_desc": "+10% 移动速度",
		"char.2_full": "初始武器：飞刀\n+10% 移动速度",
		"char.3_name": "詹纳罗",
		"char.3_desc": "+10% 攻击范围",
		"char.3_full": "初始武器：斧头\n+10% 攻击范围",

		# ── Stage Select ──
		"stage_select.title": "选择关卡",
		"stage_select.back": "返回",
		"stage_select.select": "选择",
		"stage_select.locked": "🔒 未解锁",
		"stage_select.time": "时间: %02d:%02d",
		"stage_select.unlock_0": "通关「疯狂森林」解锁",
		"stage_select.unlock_1": "通关「嵌花图书馆」解锁",

		# ── Stage Names & Descs ──
		"stage.0_name": "疯狂森林",
		"stage.0_desc": "被邪恶笼罩的黑暗森林。\n存活到黎明。",
		"stage.1_name": "嵌花图书馆",
		"stage.1_desc": "禁忌知识的大厅。\n+25% 移动速度。狭窄通道。",
		"stage.2_name": "莫利塞",
		"stage.2_desc": "隐藏着秘密的宁静草原。\n15分钟限时。敌人静止不动。",

		# ── HUD ──
		"hud.lv": "LV ",
		"hud.kills": "击杀: ",
		"hud.gold": "金币: ",
		"hud.game_over": "游戏结束",
		"hud.stage_complete": "关卡完成",
		"hud.restart": "重新开始",
		"hud.main_menu": "主菜单",
		"hud.game_over_stats": "时间: %02d:%02d\n击杀: %d\n等级: %d\n金币: %d",
		"hud.victory_stats": "关卡: %s\n时间: %02d:%02d\n击杀: %d\n等级: %d\n金币: %d\n\n奖励: +500 金币！",

		# ── Pause Overlay ──
		"pause.title": "暂停",
		"pause.resume": "继续",
		"pause.quit": "退出到主菜单",
		"pause.character": "角色",
		"pause.run_stats": "本轮统计",
		"pause.combat_stats": "战斗属性",
		"pause.weapons": "武器",
		"pause.passives": "被动",
		"pause.level": "等级 %d  |  经验 %d/%d",
		"pause.kills": "击杀: %d",
		"pause.time": "时间: %02d:%02d",
		"pause.gold": "金币: %d",
		"pause.hp": "生命: %d/%d",
		"pause.dmg": "伤害: %.2fx",
		"pause.spd": "速度: %.0f",
		"pause.area": "范围: %.2fx",
		"pause.cd": "冷却: -%d%%",
		"pause.armor": "护甲: %d",
		"pause.none": "（无）",

		# ── PowerUp Screen ──
		"powerup.title": "能力强化",
		"powerup.back": "返回",
		"powerup.buy": "购买",
		"powerup.maxed": "已满级",
		"powerup.cost": "需要 %d 金币",
		"powerup.level": "Lv.%d",

		# ── PowerUp Names & Descs ──
		"pu.might": "力量",
		"pu.might_desc": "+5% 伤害",
		"pu.max_hp": "生命上限",
		"pu.max_hp_desc": "+10% 最大生命值",
		"pu.recovery": "回复",
		"pu.recovery_desc": "+0.1 生命/秒",
		"pu.cooldown": "冷却",
		"pu.cooldown_desc": "-2.5% 武器冷却",
		"pu.area": "范围",
		"pu.area_desc": "+5% 攻击范围",
		"pu.movespeed": "移速",
		"pu.movespeed_desc": "+5% 移动速度",
		"pu.growth": "成长",
		"pu.growth_desc": "+3% 经验获取",
		"pu.greed": "贪婪",
		"pu.greed_desc": "+10% 金币获取",
		"pu.armor": "护甲",
		"pu.armor_desc": "+1 伤害减免",

		# ── Level Up Screen ──
		"levelup.title": "升级！",
		"levelup.new": "新物品",
		"levelup.level": "Lv.%d → Lv.%d",
		"levelup.evolve": "⚡ 进化！⚡",
		"levelup.evo_arrow": " → ",

		# ── Item Names ──
		"item.whip_name": "鞭子",
		"item.wand_name": "魔法杖",
		"item.garlic_name": "大蒜",
		"item.knife_name": "飞刀",
		"item.axe_name": "斧头",
		"item.firewand_name": "火杖",
		"item.wings_name": "翅膀",
		"item.spinach_name": "菠菜",
		"item.tome_name": "空书",
		"item.hollow_name": "空心",
		"item.candel_name": "烛台",
		"item.crown_name": "皇冠",
		"item.pummarola_name": "番茄",
		"item.duplicator_name": "复制器",
		"item.stonemask_name": "石面具",
		"item.magnet_name": "磁铁",

		# ── Item Descriptions ──
		"item.whip_desc": "前方大范围挥击",
		"item.wand_desc": "发射追踪敌人的魔法弹",
		"item.garlic_desc": "对周围敌人造成伤害",
		"item.knife_desc": "朝前方投掷飞刀",
		"item.axe_desc": "投掷一把重型斧头",
		"item.firewand_desc": "发射爆炸火球攻击敌人",
		"item.wings_desc": "提高移动速度",
		"item.spinach_desc": "提高所有伤害",
		"item.tome_desc": "降低所有武器冷却",
		"item.hollow_desc": "提高最大生命值",
		"item.candel_desc": "提高攻击范围",
		"item.crown_desc": "获得更多经验值",
		"item.pummarola_desc": "随时间回复生命",
		"item.duplicator_desc": "每级+1弹射物",
		"item.stonemask_desc": "每级+20%金币",
		"item.magnet_desc": "增加拾取范围",

		# ── Evolution Names & Descs ──
		"evo.whip_name": "血泪",
		"evo.whip_desc": "鞭子进化为血泪\n回复造成伤害的20%",
		"evo.wand_name": "圣杖",
		"evo.wand_desc": "魔法杖进化为圣杖\n超高速射击",
		"evo.garlic_name": "噬魂者",
		"evo.garlic_desc": "大蒜进化为噬魂者\n每次击杀回复1点生命",
		"evo.knife_name": "千刃",
		"evo.knife_desc": "飞刀进化为千刃\n散射3把刀刃",
		"evo.axe_name": "死亡螺旋",
		"evo.axe_desc": "斧头进化为死亡螺旋\n飞斧环绕并返回",

		# ── Pickup Floating Texts ──
		"pickup.chicken": "+30 生命",
		"pickup.gold": "金币",
		"pickup.rosary": "念珠！",
		"pickup.vacuum": "吸铁石！",

		# ── Player Floating Texts ──
		"player.level_up": "升级！",
		"player.heal": "+%d 生命",

		# ── Enemy Type Names (for boss/health bar) ──
		"enemy.0_name": "怨灵",
		"enemy.1_name": "毒蛇",
		"enemy.2_name": "魔像",
		"enemy.3_name": "诅咒之眼",
		"enemy.4_name": "螳螂",
		"enemy.5_name": "梦魇",

		# ── Boss ──
		"boss.announce": "梦魇降临……",

		# ── Weapon Names (for HUD / pause) ──
		"wpn.whip": "鞭子",
		"wpn.wand": "魔法杖",
		"wpn.garlic": "大蒜",
		"wpn.knife": "飞刀",
		"wpn.axe": "斧头",
		"wpn.firewand": "火杖",
		"wpn.evolved": "⚡",

		# ── Passive Names (for pause) ──
		"pas.wings": "翅膀",
		"pas.spinach": "菠菜",
		"pas.tome": "空书",
		"pas.hollow": "空心",
		"pas.candel": "烛台",
		"pas.crown": "皇冠",
		"pas.pummarola": "番茄",
		"pas.duplicator": "复制器",
		"pas.stonemask": "石面具",
		"pas.magnet": "磁铁",
	}


# ═══════════════════════════════════════════════════════════
#  ENGLISH
# ═══════════════════════════════════════════════════════════

static func _en() -> Dictionary:
	return {
		"menu.title": "Desire Survivors",
		"menu.subtitle": "A Vampire Survivors Tribute",
		"menu.start_game": "START GAME",
		"menu.power_ups": "POWER UPS",
		"menu.quit": "QUIT",
		"menu.gold": "Gold: ",
		"menu.footer": "v1.0 — Made with Godot 4",
		"menu.language": "中文",

		"char_select.title": "SELECT CHARACTER",
		"char_select.gold": "Gold: ",
		"char_select.back": "BACK",
		"char_select.select": "SELECT",
		"char_select.buy": "BUY",
		"char_select.cost": "Cost: %d Gold",
		"char_select.locked": "🔒",

		"char.0_name": "Antonio",
		"char.0_desc": "+10% Might",
		"char.0_full": "Starts with Whip\n+10% Might",
		"char.1_name": "Imelda",
		"char.1_desc": "+10% Growth",
		"char.1_full": "Starts with Magic Wand\n+10% Growth",
		"char.2_name": "Pasqualina",
		"char.2_desc": "+10% Move Speed",
		"char.2_full": "Starts with Knife\n+10% Move Speed",
		"char.3_name": "Gennaro",
		"char.3_desc": "+10% Area",
		"char.3_full": "Starts with Axe\n+10% Area",

		"stage_select.title": "SELECT STAGE",
		"stage_select.back": "BACK",
		"stage_select.select": "SELECT",
		"stage_select.locked": "🔒 LOCKED",
		"stage_select.time": "Time: %02d:%02d",
		"stage_select.unlock_0": "Clear Mad Forest to unlock",
		"stage_select.unlock_1": "Clear Inlaid Library to unlock",

		"stage.0_name": "Mad Forest",
		"stage.0_desc": "A dark forest overrun by evil.\nSurvive until dawn.",
		"stage.1_name": "Inlaid Library",
		"stage.1_desc": "Halls of forbidden knowledge.\n+25% Move Speed. Narrow corridor.",
		"stage.2_name": "Il Molise",
		"stage.2_desc": "Peaceful meadow hiding a secret.\n15 min limit. Enemies stay still.",

		"hud.lv": "LV ",
		"hud.kills": "Kills: ",
		"hud.gold": "Gold: ",
		"hud.game_over": "GAME OVER",
		"hud.stage_complete": "STAGE COMPLETE",
		"hud.restart": "RESTART",
		"hud.main_menu": "MAIN MENU",
		"hud.game_over_stats": "Time: %02d:%02d\nKills: %d\nLevel: %d\nGold: %d",
		"hud.victory_stats": "Stage: %s\nTime: %02d:%02d\nKills: %d\nLevel: %d\nGold: %d\n\nBonus: +500 Gold!",

		"pause.title": "PAUSED",
		"pause.resume": "RESUME",
		"pause.quit": "QUIT TO MENU",
		"pause.character": "CHARACTER",
		"pause.run_stats": "RUN STATS",
		"pause.combat_stats": "COMBAT STATS",
		"pause.weapons": "WEAPONS",
		"pause.passives": "PASSIVES",
		"pause.level": "Level %d  |  XP %d/%d",
		"pause.kills": "Kills: %d",
		"pause.time": "Time: %02d:%02d",
		"pause.gold": "Gold: %d",
		"pause.hp": "HP: %d/%d",
		"pause.dmg": "DMG: %.2fx",
		"pause.spd": "SPD: %.0f",
		"pause.area": "Area: %.2fx",
		"pause.cd": "CD: -%d%%",
		"pause.armor": "Armor: %d",
		"pause.none": "(none)",

		"powerup.title": "POWER UPS",
		"powerup.back": "BACK",
		"powerup.buy": "BUY",
		"powerup.maxed": "MAXED",
		"powerup.cost": "Need %d Gold",
		"powerup.level": "Lv.%d",

		"pu.might": "Might",
		"pu.might_desc": "+5% damage",
		"pu.max_hp": "Max HP",
		"pu.max_hp_desc": "+10% max health",
		"pu.recovery": "Recovery",
		"pu.recovery_desc": "+0.1 HP/s regen",
		"pu.cooldown": "Cooldown",
		"pu.cooldown_desc": "-2.5% weapon cooldown",
		"pu.area": "Area",
		"pu.area_desc": "+5% attack area",
		"pu.movespeed": "Move Spd",
		"pu.movespeed_desc": "+5% move speed",
		"pu.growth": "Growth",
		"pu.growth_desc": "+3% XP gain",
		"pu.greed": "Greed",
		"pu.greed_desc": "+10% gold earned",
		"pu.armor": "Armor",
		"pu.armor_desc": "+1 damage reduction",

		"levelup.title": "LEVEL UP!",
		"levelup.new": "NEW",
		"levelup.level": "Lv.%d → Lv.%d",
		"levelup.evolve": "⚡ EVOLVE! ⚡",
		"levelup.evo_arrow": " → ",

		"item.whip_name": "Whip",
		"item.wand_name": "Magic Wand",
		"item.garlic_name": "Garlic",
		"item.knife_name": "Knife",
		"item.axe_name": "Axe",
		"item.firewand_name": "Fire Wand",
		"item.wings_name": "Wings",
		"item.spinach_name": "Spinach",
		"item.tome_name": "Empty Tome",
		"item.hollow_name": "Hollow Heart",
		"item.candel_name": "Candelabrador",
		"item.crown_name": "Crown",
		"item.pummarola_name": "Pummarola",
		"item.duplicator_name": "Duplicator",
		"item.stonemask_name": "Stone Mask",
		"item.magnet_name": "Magnet",

		"item.whip_desc": "Strike enemies in a wide arc",
		"item.wand_desc": "Fire homing bolts at enemies",
		"item.garlic_desc": "Damage enemies around you",
		"item.knife_desc": "Throw daggers in faced direction",
		"item.axe_desc": "Hurl a heavy axe in an arc",
		"item.firewand_desc": "Shoot explosive fire at enemies",
		"item.wings_desc": "Increase movement speed",
		"item.spinach_desc": "Increase all damage",
		"item.tome_desc": "Reduce all weapon cooldowns",
		"item.hollow_desc": "Increase max health",
		"item.candel_desc": "Increase attack area",
		"item.crown_desc": "Gain more XP",
		"item.pummarola_desc": "Regenerate HP over time",
		"item.duplicator_desc": "+1 Projectile per level",
		"item.stonemask_desc": "+20% Gold per level",
		"item.magnet_desc": "Increase pickup range",

		"evo.whip_name": "Bloody Tear",
		"evo.whip_desc": "Whip evolves into Bloody Tear\nHeals 20% of damage dealt",
		"evo.wand_name": "Holy Wand",
		"evo.wand_desc": "Magic Wand evolves into Holy Wand\nFires at super speed",
		"evo.garlic_name": "Soul Eater",
		"evo.garlic_desc": "Garlic evolves into Soul Eater\nHeals 1 HP per kill",
		"evo.knife_name": "Thousand Edge",
		"evo.knife_desc": "Knife evolves into Thousand Edge\nFires a spread of 3 blades",
		"evo.axe_name": "Death Spiral",
		"evo.axe_desc": "Axe evolves into Death Spiral\nAxes orbit and return to you",

		"pickup.chicken": "+30 HP",
		"pickup.gold": "Gold",
		"pickup.rosary": "Rosary!",
		"pickup.vacuum": "Vacuum!",

		"player.level_up": "LEVEL UP!",
		"player.heal": "+%d HP",

		# ── Enemy Type Names ──
		"enemy.0_name": "Wraith",
		"enemy.1_name": "Viper",
		"enemy.2_name": "Golem",
		"enemy.3_name": "Cursed Eye",
		"enemy.4_name": "Mantis",
		"enemy.5_name": "Nightmare",

		"boss.announce": "Nightmare approaches...",

		"wpn.whip": "Whip",
		"wpn.wand": "Magic Wand",
		"wpn.garlic": "Garlic",
		"wpn.knife": "Knife",
		"wpn.axe": "Axe",
		"wpn.firewand": "Fire Wand",
		"wpn.evolved": "⚡",

		"pas.wings": "Wings",
		"pas.spinach": "Spinach",
		"pas.tome": "Empty Tome",
		"pas.hollow": "Hollow Heart",
		"pas.candel": "Candelabrador",
		"pas.crown": "Crown",
		"pas.pummarola": "Pummarola",
		"pas.duplicator": "Duplicator",
		"pas.stonemask": "Stone Mask",
		"pas.magnet": "Magnet",
	}
