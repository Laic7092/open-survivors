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

		# ── Main Menu — Relics ──
		"menu.relics": "遗物收集",

		# ── Relic Screen ──
		"relic_screen.title": "遗物图鉴",
		"relic_screen.back": "返回",
		"relic_screen.progress": "收集进度: %d / %d",

		# ── Relic Names & Descs ──
		"relic.grim_grimoire": "格里姆卷轴",
		"relic.grim_grimoire_desc": "查看武器进化配方",
		"relic.milky_way_map": "银河地图",
		"relic.milky_way_map_desc": "暂停时显示地图",
		"relic.sorceress_tears": "魔女之泪",
		"relic.sorceress_tears_desc": "解锁急速模式",
		"relic.magic_banger": "魔法爆竹",
		"relic.magic_banger_desc": "切换音乐",
		"relic.great_gospel": "伟大福音",
		"relic.great_gospel_desc": "武器升级突破上限",
		"relic.seventh_trumpet": "第七号角",
		"relic.seventh_trumpet_desc": "解锁无尽模式",
		"relic.randomazzo": "秘术卡牌",
		"relic.randomazzo_desc": "解锁秘术系统",

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
		"char.4_name": "阿尔卡",
		"char.4_desc": "-10% 冷却",
		"char.4_full": "初始武器：火杖\n-10% 冷却时间",
		"char.5_name": "波尔塔",
		"char.5_desc": "-15% 冷却",
		"char.5_full": "初始武器：闪电环\n-15% 冷却时间",
		"char.6_name": "拉玛",
		"char.6_desc": "+20% 伤害, +1 护甲",
		"char.6_full": "初始武器：斧头\n+20% 伤害, +1 护甲",
		"char.7_name": "波",
		"char.7_desc": "+30% 最大生命",
		"char.7_full": "初始武器：大蒜\n+30% 最大生命值",
		"char.8_name": "克莱里奇",
		"char.8_desc": "+0.5 HP/秒 回复",
		"char.8_full": "初始武器：圣水\n+0.5 HP/秒 生命回复",
		"char.9_name": "多马里奥",
		"char.9_desc": "+10% 金币, +10% 经验",
		"char.9_full": "初始武器：圣经\n+10% 金币获取, +10% 经验获取",
		"char.10_name": "克罗奇",
		"char.10_desc": "+10% 移速, +10% 生命",
		"char.10_full": "初始武器：十字架\n+10% 移动速度, +10% 最大生命",
		"char.11_name": "克里斯汀",
		"char.11_desc": "-20% 冷却, +10% 范围",
		"char.11_full": "初始武器：魔法杖\n-20% 冷却时间, +10% 攻击范围",

		# ── Stage Select ──
		"stage_select.title": "选择关卡",
		"stage_select.back": "返回",
		"stage_select.select": "选择",
		"stage_select.locked": "🔒 未解锁",
		"stage_select.time": "时间: %02d:%02d",
		"stage_select.unlock_0": "通关「疯狂森林」解锁",
		"stage_select.unlock_1": "通关「嵌花图书馆」解锁",
		"stage_select.unlock_2": "通关「莫利塞」解锁",
		"stage_select.unlock_3": "通关「奶牛场」解锁",
		"stage_select.unlock_4": "通关「加洛塔」解锁",
		"stage_select.unlock_5": "通关「卡佩拉教堂」解锁",
		"stage_select.reach_30": "达到 30 级解锁",
		"stage_select.reach_40": "达到 40 级解锁",
		"stage_select.reach_50": "达到 50 级解锁",
		"stage_select.reach_55": "达到 55 级解锁",
		"stage_select.reach_60": "达到 60 级解锁",
		"stage_select.reach_65": "达到 65 级解锁",
		"stage_select.relic_yellow": "获得「黄色印记」遗物解锁",
		"stage_select.hurry": "⏩ 急速模式 (1.5x 速度)",
		"stage_select.endless": "♾️ 无尽模式 (无时间限制)",
		"stage_select.music": "🎵 切换音乐",
		"stage_select.arcana": "🃏 秘术 (开/关)",
		"stage_select.locked_relic": "🔒 需要遗物: %s",

		# ── Stage Names & Descs ──
		"stage.0_name": "疯狂森林",
		"stage.0_desc": "被邪恶笼罩的黑暗森林。\n存活到黎明。",
		"stage.1_name": "嵌花图书馆",
		"stage.1_desc": "禁忌知识的大厅。\n+25% 移动速度。狭窄通道。",
		"stage.2_name": "莫利塞",
		"stage.2_desc": "隐藏着秘密的宁静草原。\n15分钟限时。敌人静止不动。",
		"stage.3_name": "奶牛场",
		"stage.3_desc": "被实验体占领的废弃工厂。\n+25% 移动速度。+20% 金币。奶车阻挡路径。",
		"stage.4_name": "加洛塔",
		"stage.4_desc": "科学与巫术的殿堂。\n+25% 移动速度。+30% 金币。垂直攀登。",
		"stage.5_name": "卡佩拉教堂",
		"stage.5_desc": "堕落圣洁的交汇点。\n+40% 移动速度。+40% 金币。大教堂。",
		"stage.6_name": "月下城",
		"stage.6_desc": "被海吞没的城市。\n15分钟限时。全被动可用。",
		"stage.7_name": "翠绿田野",
		"stage.7_desc": "命运变迁的领域。\n随机敌人波次。+50% 敌人生命。",
		"stage.8_name": "骸骨地带",
		"stage.8_desc": "死者去往之地。\n无掉落。敌人随时间变强。",
		"stage.9_name": "首领狂潮",
		"stage.9_desc": "怪物寻求娱乐。\n15分钟。全是首领。",
		"stage.10_name": "极寒暴雪",
		"stage.10_desc": "北极冰川。\n20分钟限时。火焰武器造成额外伤害。",
		"stage.11_name": "利凯姆学院",
		"stage.11_desc": "沉入阳光湖泊的学校。\n+20% 金币。奇异的鱼类。",
		"stage.12_name": "养鸡场",
		"stage.12_desc": "野兽学会合作的农场。\n-65% 经验。场景随时间扩张。",
		"stage.13_name": "54号空间",
		"stage.13_desc": "空间折叠的宇宙平面。\n+30% 金币。维度混沌。",
		"stage.14_name": "蝙蝠国度",
		"stage.14_desc": "我们停不下来。\n-75% 经验。敌人超速强化。",
		"stage.15_name": "幸福装置",
		"stage.15_desc": "空间之间的空间。\n99分钟限时。终局之战。",

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
		"pause.grimoire": "📖 进化配方",
		"pause.map_available": "🗺️ 地图已解锁（查看小地图）",

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
		"item.cross_name": "十字架",
		"item.bible_name": "圣经",
		"item.santa_water_name": "圣水",
		"item.runetracer_name": "符文追踪",
		"item.lightning_name": "闪电环",
		"item.clover_name": "三叶草",
		"item.spellbinder_name": "法术绑定",
		"item.armor_name": "护甲",
		"item.bracer_name": "护腕",
		"item.skull_name": "狂乱骷髅",
		"item.tiragisu_name": "提拉吉苏",
		"item.torrona_name": "托罗纳之箱",
		"item.silver_ring_name": "银戒指",
		"item.gold_ring_name": "金戒指",
		"item.metaglio_left_name": "左金属碑",
		"item.metaglio_right_name": "右金属碑",

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
		"item.cross_desc": "回旋镖追踪敌人",
		"item.bible_desc": "环绕玩家的弹幕",
		"item.santa_water_desc": "创造地面伤害区域",
		"item.runetracer_desc": "穿透反弹的弹射物",
		"item.lightning_desc": "用闪电打击敌人",
		"item.clover_desc": "提高幸运值",
		"item.spellbinder_desc": "提高效果持续时间",
		"item.armor_desc": "减少受到的伤害",
		"item.bracer_desc": "提高弹射物速度",
		"item.skull_desc": "提高敌人难度（诅咒）",
		"item.tiragisu_desc": "死亡时复活一次",
		"item.torrona_desc": "小幅提升所有属性",
		"item.silver_ring_desc": "+持续时间, +攻击范围",
		"item.gold_ring_desc": "诅咒敌人（提高难度）",
		"item.metaglio_left_desc": "+生命回复, +最大生命",
		"item.metaglio_right_desc": "诅咒敌人（提高难度）",

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
		"evo.firewand_name": "地狱火",
		"evo.firewand_desc": "火杖进化为地狱火\n双重爆炸范围",
		"evo.cross_name": "天剑",
		"evo.cross_desc": "十字架进化为天剑\n从天空降下剑雨",
		"evo.king_bible_name": "圣歌",
		"evo.king_bible_desc": "圣经进化为圣歌\n双重环绕护盾",
		"evo.santa_water_name": "追踪水坑",
		"evo.santa_water_desc": "圣水进化为追踪水坑\n追踪敌人的伤害区域",
		"evo.runetracer_name": "无未来",
		"evo.runetracer_desc": "符文进化为无未来\n穿透激光墙",
		"evo.lightning_ring_name": "雷霆环",
		"evo.lightning_ring_desc": "闪电环进化为雷霆环\n连锁闪电",

		# ── Pickup Floating Texts ──
		"pickup.chicken": "+30 生命",
		"pickup.gold": "金币",
		"pickup.rosary": "念珠！",
		"pickup.vacuum": "吸铁石！",

		# ── Player Floating Texts ──
		"player.level_up": "升级！",
		"player.heal": "+%d 生命",
		"player.revive": "复活！",

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
		"wpn.cross": "十字架",
		"wpn.bible": "圣经",
		"wpn.santa_water": "圣水",
		"wpn.runetracer": "符文追踪",
		"wpn.lightning": "闪电环",
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
		"pas.clover": "三叶草",
		"pas.spellbinder": "法术绑定",
		"pas.armor": "护甲",
		"pas.bracer": "护腕",
		"pas.skull": "狂乱骷髅",
		"pas.tiragisu": "提拉吉苏",
		"pas.torrona": "托罗纳之箱",
		"pas.silver_ring": "银戒指",
		"pas.gold_ring": "金戒指",
		"pas.metaglio_left": "左金属碑",
		"pas.metaglio_right": "右金属碑",

		# ── Arcana UI ──
		"arcana.title": "选择秘术",
		"arcana.first_pick": "选择你的起始秘术",
		"arcana.chest_pick": "获得一个额外的秘术",
		"arcana.random": "🎲 随机选择",
		"arcana.select": "选择",
		"arcana.equipped": "秘术 %s 已装备！",
		"arcana.boss_announce": "秘术守护者降临！",

		# ── Arcana Names (0-21) ──
		"arcana.0_name": "游戏终结者",
		"arcana.1_name": "双子座",
		"arcana.2_name": "黄昏安魂曲",
		"arcana.3_name": "悲剧公主",
		"arcana.4_name": "觉醒",
		"arcana.5_name": "暗夜混沌",
		"arcana.6_name": "治愈萨拉班德",
		"arcana.7_name": "钢铁意志",
		"arcana.8_name": "疯狂律动",
		"arcana.9_name": "神圣血脉",
		"arcana.10_name": "初始",
		"arcana.11_name": "珍珠华尔兹",
		"arcana.12_name": "越界",
		"arcana.13_name": "邪恶季节",
		"arcana.14_name": "水晶牢笼",
		"arcana.15_name": "黄金迪斯科",
		"arcana.16_name": "斩击",
		"arcana.17_name": "失落的画作",
		"arcana.18_name": "幻象布吉舞",
		"arcana.19_name": "火焰之心",
		"arcana.20_name": "寂静古圣殿",
		"arcana.21_name": "鲜血占星术",

		# ── Arcana Descriptions ──
		"arcana.0_desc": "XP停止增长。经验宝石变为爆炸射弹。所有宝箱至少包含3个物品。",
		"arcana.1_desc": "列出的武器获得对应的伴生武器。",
		"arcana.2_desc": "列出的武器射弹在消失时产生爆炸。爆炸伤害受诅咒影响。",
		"arcana.3_desc": "移动时减少列出的武器冷却时间。",
		"arcana.4_desc": "+3 复活次数。复活时获得+10%最大生命、+1护甲、+5%伤害/范围/持续时间/速度。",
		"arcana.5_desc": "射弹速度在-50%到+50%之间连续变化（周期10秒）。每级+1%射弹速度。",
		"arcana.6_desc": "治疗效果翻倍。恢复HP时对附近敌人造成等量伤害。",
		"arcana.7_desc": "列出的武器射弹获得最多3次弹跳，可穿透敌人和墙壁。",
		"arcana.8_desc": "每2分钟将所有地面物品、补给予拾取物拉向角色。",
		"arcana.9_desc": "护甲增加列出的武器伤害并反射敌人伤害。根据损失的生命值获得额外伤害。",
		"arcana.10_desc": "列出的武器+1弹射量。主武器+3弹射量。",
		"arcana.11_desc": "列出的武器射弹获得最多3次弹跳。",
		"arcana.12_desc": "冻结敌人时产生爆炸。更容易找到时钟道具。",
		"arcana.13_desc": "成长/幸运/贪婪/诅咒按固定间隔翻倍。每2级+1%成长/幸运/贪婪/诅咒。",
		"arcana.14_desc": "列出的武器射弹有几率冻结敌人。",
		"arcana.15_desc": "拾取金币触发黄金狂热。获得金币时回复HP。",
		"arcana.16_desc": "列出的武器可以暴击。暴击伤害翻倍。",
		"arcana.17_desc": "持续时间在-50%到+50%之间连续变化（周期10秒）。每级+1%持续时间。",
		"arcana.18_desc": "攻击范围在-25%到+25%之间连续变化（周期10秒）。每级+1%范围。",
		"arcana.19_desc": "列出的武器射弹在命中时爆炸。光源爆炸。角色受伤时爆炸。",
		"arcana.20_desc": "+3 重掷/跳过/移除。每空一个武器栏位+20%伤害和-8%冷却。",
		"arcana.21_desc": "列出的武器发射受弹射量和磁铁影响的特殊伤害区域。磁铁范围内的敌人受到伤害。",

		# ── Arcana Unlock Conditions ──
		"arcana.0_unlock": "击败最终关卡的BOSS解锁",
		"arcana.1_unlock": "角色达到30级解锁",
		"arcana.2_unlock": "角色达到30级解锁",
		"arcana.3_unlock": "角色达到30级解锁",
		"arcana.4_unlock": "角色达到30级解锁",
		"arcana.5_unlock": "角色达到30级解锁",
		"arcana.6_unlock": "找到Randomazzo遗物解锁",
		"arcana.7_unlock": "角色达到30级解锁",
		"arcana.8_unlock": "在疯狂森林存活31分钟解锁",
		"arcana.9_unlock": "角色达到30级解锁",
		"arcana.10_unlock": "角色达到30级解锁",
		"arcana.11_unlock": "角色达到30级解锁",
		"arcana.12_unlock": "在嵌花图书馆存活31分钟解锁",
		"arcana.13_unlock": "角色达到30级解锁",
		"arcana.14_unlock": "角色达到30级解锁",
		"arcana.15_unlock": "在嵌花图书馆存活31分钟解锁",
		"arcana.16_unlock": "角色达到30级解锁",
		"arcana.17_unlock": "角色达到30级解锁",
		"arcana.18_unlock": "角色达到30级解锁",
		"arcana.19_unlock": "角色达到30级解锁",
		"arcana.20_unlock": "在莫利塞存活31分钟解锁",
		"arcana.21_unlock": "角色达到30级解锁",

		# ── Unlock Notification ──
		"unlock.notification_title": "新内容已解锁！",
		"unlock.notification_subtitle": "看看你获得了什么：",
		"unlock.continue": "继续",
		"unlock.new_badge": "NEW!",
		"unlock.type_stage": "关卡",
		"unlock.type_arcana": "密术",
		"unlock.type_character": "角色",
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

		# ── Main Menu — Relics ──
		"menu.relics": "RELICS",

		# ── Relic Screen ──
		"relic_screen.title": "RELIC COLLECTION",
		"relic_screen.back": "BACK",
		"relic_screen.progress": "Progress: %d / %d",

		# ── Relic Names & Descs ──
		"relic.grim_grimoire": "Grim Grimoire",
		"relic.grim_grimoire_desc": "View weapon evolution recipes",
		"relic.milky_way_map": "Milky Way Map",
		"relic.milky_way_map_desc": "Show map on pause",
		"relic.sorceress_tears": "Sorceress' Tears",
		"relic.sorceress_tears_desc": "Unlock Hurry Mode",
		"relic.magic_banger": "Magic Banger",
		"relic.magic_banger_desc": "Switch music tracks",
		"relic.great_gospel": "Great Gospel",
		"relic.great_gospel_desc": "Weapons can exceed level 8",
		"relic.seventh_trumpet": "Seventh Trumpet",
		"relic.seventh_trumpet_desc": "Unlock Endless Mode",
		"relic.randomazzo": "Randomazzo",
		"relic.randomazzo_desc": "Unlock Arcana system",

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
		"char.4_name": "Arca",
		"char.4_desc": "-10% Cooldown",
		"char.4_full": "Starts with Fire Wand\n-10% Cooldown",
		"char.5_name": "Porta",
		"char.5_desc": "-15% Cooldown",
		"char.5_full": "Starts with Lightning Ring\n-15% Cooldown",
		"char.6_name": "Lama",
		"char.6_desc": "+20% Might, +1 Armor",
		"char.6_full": "Starts with Axe\n+20% Might, +1 Armor",
		"char.7_name": "Poe",
		"char.7_desc": "+30% Max HP",
		"char.7_full": "Starts with Garlic\n+30% Max HP",
		"char.8_name": "Clerici",
		"char.8_desc": "+0.5 HP/s Regen",
		"char.8_full": "Starts with Santa Water\n+0.5 HP/s Regen",
		"char.9_name": "Dommario",
		"char.9_desc": "+10% Greed, +10% Growth",
		"char.9_full": "Starts with King Bible\n+10% Greed, +10% Growth",
		"char.10_name": "Krochi",
		"char.10_desc": "+10% Move Speed, +10% HP",
		"char.10_full": "Starts with Cross\n+10% Move Speed, +10% HP",
		"char.11_name": "Christine",
		"char.11_desc": "-20% CD, +10% Area",
		"char.11_full": "Starts with Magic Wand\n-20% CD, +10% Area",

		"stage_select.title": "SELECT STAGE",
		"stage_select.back": "BACK",
		"stage_select.select": "SELECT",
		"stage_select.locked": "🔒 LOCKED",
		"stage_select.time": "Time: %02d:%02d",
		"stage_select.unlock_0": "Clear Mad Forest to unlock",
		"stage_select.unlock_1": "Clear Inlaid Library to unlock",
		"stage_select.unlock_2": "Clear Il Molise to unlock",
		"stage_select.unlock_3": "Clear Dairy Plant to unlock",
		"stage_select.unlock_4": "Clear Gallo Tower to unlock",
		"stage_select.unlock_5": "Clear Cappella Magna to unlock",
		"stage_select.reach_30": "Reach level 30 to unlock",
		"stage_select.reach_40": "Reach level 40 to unlock",
		"stage_select.reach_50": "Reach level 50 to unlock",
		"stage_select.reach_55": "Reach level 55 to unlock",
		"stage_select.reach_60": "Reach level 60 to unlock",
		"stage_select.reach_65": "Reach level 65 to unlock",
		"stage_select.relic_yellow": "Collect the Yellow Sign relic to unlock",
		"stage_select.hurry": "⏩ Hurry Mode (1.5x Speed)",
		"stage_select.endless": "♾️ Endless Mode (No Time Limit)",
		"stage_select.music": "🎵 Alternate Music",
		"stage_select.arcana": "🃏 Arcanas (ON/OFF)",
		"stage_select.locked_relic": "🔒 Need Relic: %s",

		"stage.0_name": "Mad Forest",
		"stage.0_desc": "A dark forest overrun by evil.\nSurvive until dawn.",
		"stage.1_name": "Inlaid Library",
		"stage.1_desc": "Halls of forbidden knowledge.\n+25% Move Speed. Narrow corridor.",
		"stage.2_name": "Il Molise",
		"stage.2_desc": "Peaceful meadow hiding a secret.\n15 min limit. Enemies stay still.",
		"stage.3_name": "Dairy Plant",
		"stage.3_desc": "Abandoned factory overrun by experiments.\n+25% Move Speed. +20% Gold. Carts block paths.",
		"stage.4_name": "Gallo Tower",
		"stage.4_desc": "An edifice of science and sorcery.\n+25% Move Speed. +30% Gold. Vertical ascent.",
		"stage.5_name": "Cappella Magna",
		"stage.5_desc": "Nexus of debased purity.\n+40% Move Speed. +40% Gold. Grand chapel.",
		"stage.6_name": "Moongolow",
		"stage.6_desc": "City swallowed by the sea.\n15 min limit. All passives available.",
		"stage.7_name": "Green Acres",
		"stage.7_desc": "Realm of changing fate.\nRandom enemy waves. +50% Enemy HP.",
		"stage.8_name": "The Bone Zone",
		"stage.8_desc": "Where the dead go to live.\nNo item drops. Enemies grow stronger.",
		"stage.9_name": "Boss Rash",
		"stage.9_desc": "The monsters want entertainment.\n15 min limit. All bosses, all the time.",
		"stage.10_name": "Whiteout",
		"stage.10_desc": "Arctic glacier.\n20 min limit. Fire weapons deal extra damage.",
		"stage.11_name": "The Lycaeum",
		"stage.11_desc": "School submerged beneath a sunlit lake.\n+20% Gold. Strange fish.",
		"stage.12_name": "The Coop",
		"stage.12_desc": "Farm where beasts learned cooperation.\n-65% XP. Stage grows over time.",
		"stage.13_name": "Space 54",
		"stage.13_desc": "Cosmic plane where space folds.\n+30% Gold. Dimensional chaos.",
		"stage.14_name": "Bat Country",
		"stage.14_desc": "We can't stop here.\n-75% XP. Enemies hyper-scale over time.",
		"stage.15_name": "Eudaimonia Machine",
		"stage.15_desc": "A space between spaces.\n99 min limit. The culmination.",

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
		"pause.grimoire": "📖 Evolution Recipes",
		"pause.map_available": "🗺️ Map Available (check minimap)",

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
		"item.cross_name": "Cross",
		"item.bible_name": "King Bible",
		"item.santa_water_name": "Santa Water",
		"item.runetracer_name": "Runetracer",
		"item.lightning_name": "Lightning Ring",
		"item.clover_name": "Clover",
		"item.spellbinder_name": "Spellbinder",
		"item.armor_name": "Armor",
		"item.bracer_name": "Bracer",
		"item.skull_name": "Skull O'Maniac",
		"item.tiragisu_name": "Tiragisú",
		"item.torrona_name": "Torrona's Box",
		"item.silver_ring_name": "Silver Ring",
		"item.gold_ring_name": "Gold Ring",
		"item.metaglio_left_name": "Metaglio Left",
		"item.metaglio_right_name": "Metaglio Right",

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
		"item.cross_desc": "Boomerang that seeks enemies",
		"item.bible_desc": "Orbiting projectiles",
		"item.santa_water_desc": "Create damaging puddles",
		"item.runetracer_desc": "Bouncing tracer projectiles",
		"item.lightning_desc": "Strike enemies with lightning",
		"item.clover_desc": "Increase luck",
		"item.spellbinder_desc": "Increase effect duration",
		"item.armor_desc": "Reduce damage taken",
		"item.bracer_desc": "Increase projectile speed",
		"item.skull_desc": "Increase enemy difficulty (Curse)",
		"item.tiragisu_desc": "Revive on death",
		"item.torrona_desc": "Boost all stats slightly",
		"item.silver_ring_desc": "+Duration, +Area",
		"item.gold_ring_desc": "Curse enemies",
		"item.metaglio_left_desc": "+Recovery, +Max HP",
		"item.metaglio_right_desc": "Curse enemies",

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
		"evo.firewand_name": "Hellfire",
		"evo.firewand_desc": "Fire Wand evolves into Hellfire\nDouble explosions",
		"evo.cross_name": "Heaven Sword",
		"evo.cross_desc": "Cross evolves into Heaven Sword\nSword rains from above",
		"evo.king_bible_name": "Unholy Vespers",
		"evo.king_bible_desc": "King Bible evolves into Unholy Vespers\nDual orbiting shields",
		"evo.santa_water_name": "La Borra",
		"evo.santa_water_desc": "Santa Water evolves into La Borra\nTracking damaging puddles",
		"evo.runetracer_name": "NO FUTURE",
		"evo.runetracer_desc": "Runetracer evolves into NO FUTURE\nWalls of piercing lasers",
		"evo.lightning_ring_name": "Thunder Loop",
		"evo.lightning_ring_desc": "Lightning Ring evolves into Thunder Loop\nChain lightning",

		"pickup.chicken": "+30 HP",
		"pickup.gold": "Gold",
		"pickup.rosary": "Rosary!",
		"pickup.vacuum": "Vacuum!",

		"player.level_up": "LEVEL UP!",
		"player.heal": "+%d HP",
		"player.revive": "REVIVE!",

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
		"wpn.cross": "Cross",
		"wpn.bible": "King Bible",
		"wpn.santa_water": "Santa Water",
		"wpn.runetracer": "Runetracer",
		"wpn.lightning": "Lightning Ring",
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
		"pas.clover": "Clover",
		"pas.spellbinder": "Spellbinder",
		"pas.armor": "Armor",
		"pas.bracer": "Bracer",
		"pas.skull": "Skull O'Maniac",
		"pas.tiragisu": "Tiragisú",
		"pas.torrona": "Torrona's Box",
		"pas.silver_ring": "Silver Ring",
		"pas.gold_ring": "Gold Ring",
		"pas.metaglio_left": "Metaglio Left",
		"pas.metaglio_right": "Metaglio Right",

		# ── Arcana UI ──
		"arcana.title": "CHOOSE AN ARCANA",
		"arcana.first_pick": "Select your starting Arcana",
		"arcana.chest_pick": "Pick an additional Arcana",
		"arcana.random": "🎲 Random",
		"arcana.select": "SELECT",
		"arcana.equipped": "Arcana %s equipped!",
		"arcana.boss_announce": "Arcana Guardian appears!",

		# ── Arcana Names (0-21) ──
		"arcana.0_name": "Game Killer",
		"arcana.1_name": "Gemini",
		"arcana.2_name": "Twilight Requiem",
		"arcana.3_name": "Tragic Princess",
		"arcana.4_name": "Awake",
		"arcana.5_name": "Chaos in the Dark Night",
		"arcana.6_name": "Sarabande of Healing",
		"arcana.7_name": "Iron Blue Will",
		"arcana.8_name": "Mad Groove",
		"arcana.9_name": "Divine Bloodline",
		"arcana.10_name": "Beginning",
		"arcana.11_name": "Waltz of Pearls",
		"arcana.12_name": "Out of Bounds",
		"arcana.13_name": "Wicked Season",
		"arcana.14_name": "Jail of Crystal",
		"arcana.15_name": "Disco of Gold",
		"arcana.16_name": "Slash",
		"arcana.17_name": "Lost & Found Painting",
		"arcana.18_name": "Boogaloo of Illusions",
		"arcana.19_name": "Heart of Fire",
		"arcana.20_name": "Silent Old Sanctuary",
		"arcana.21_name": "Blood Astronomia",

		# ── Arcana Descriptions ──
		"arcana.0_desc": "Halts XP gain. XP Gems become exploding projectiles. All Chests contain at least 3 items.",
		"arcana.1_desc": "Listed weapons come with a counterpart.",
		"arcana.2_desc": "Listed weapon projectiles explode when expiring. Explosion damage affected by Curse.",
		"arcana.3_desc": "Listed weapons' cooldown reduces when moving.",
		"arcana.4_desc": "+3 Revivals. Revival gives +10% Max HP, +1 Armor, +5% Might/Area/Duration/Speed.",
		"arcana.5_desc": "Projectile Speed oscillates -50%~+50% over 10s. +1% Projectile Speed per level.",
		"arcana.6_desc": "Healing doubled. Recovering HP damages nearby enemies.",
		"arcana.7_desc": "Listed projectiles gain up to 3 bounces, may pass through enemies/walls.",
		"arcana.8_desc": "Every 2 minutes attracts all stage items toward the character.",
		"arcana.9_desc": "Armor boosts listed weapon damage. Bonus damage from missing HP.",
		"arcana.10_desc": "Listed weapons +1 Amount. Main weapon +3 Amount.",
		"arcana.11_desc": "Listed weapon projectiles gain up to 3 bounces.",
		"arcana.12_desc": "Freezing enemies creates explosions. Orologions easier to find.",
		"arcana.13_desc": "Growth/Luck/Greed/Curse doubled at intervals. +1% each every 2 levels.",
		"arcana.14_desc": "Listed weapon projectiles have a chance to freeze enemies.",
		"arcana.15_desc": "Picking up gold triggers Gold Fever. Gold restores HP.",
		"arcana.16_desc": "Listed weapons can crit. Critical damage doubled.",
		"arcana.17_desc": "Duration oscillates -50%~+50% over 10s. +1% Duration per level.",
		"arcana.18_desc": "Area oscillates -25%~+25% over 10s. +1% Area per level.",
		"arcana.19_desc": "Listed projectiles explode on impact. Light sources explode. Explode when hit.",
		"arcana.20_desc": "+3 Reroll, Skip, Banish. +20% Might, -8% CD per empty weapon slot.",
		"arcana.21_desc": "Listed weapons emit damaging zones. Enemies in Magnet range take damage.",

		# ── Arcana Unlock Conditions ──
		"arcana.0_unlock": "Defeat the final boss of the last stage.",
		"arcana.1_unlock": "Reach level 30 with a character.",
		"arcana.2_unlock": "Reach level 30 with a character.",
		"arcana.3_unlock": "Reach level 30 with a character.",
		"arcana.4_unlock": "Reach level 30 with a character.",
		"arcana.5_unlock": "Reach level 30 with a character.",
		"arcana.6_unlock": "Find the Randomazzo relic.",
		"arcana.7_unlock": "Reach level 30 with a character.",
		"arcana.8_unlock": "Survive 31 minutes in Mad Forest.",
		"arcana.9_unlock": "Reach level 30 with a character.",
		"arcana.10_unlock": "Reach level 30 with a character.",
		"arcana.11_unlock": "Reach level 30 with a character.",
		"arcana.12_unlock": "Survive 31 minutes in Inlaid Library.",
		"arcana.13_unlock": "Reach level 30 with a character.",
		"arcana.14_unlock": "Reach level 30 with a character.",
		"arcana.15_unlock": "Survive 31 minutes in Inlaid Library.",
		"arcana.16_unlock": "Reach level 30 with a character.",
		"arcana.17_unlock": "Reach level 30 with a character.",
		"arcana.18_unlock": "Reach level 30 with a character.",
		"arcana.19_unlock": "Reach level 30 with a character.",
		"arcana.20_unlock": "Survive 31 minutes in Il Molise.",
		"arcana.21_unlock": "Reach level 30 with a character.",

		# ── Unlock Notification ──
		"unlock.notification_title": "New Content Unlocked!",
		"unlock.notification_subtitle": "Check out what you have earned:",
		"unlock.continue": "Continue",
		"unlock.new_badge": "NEW!",
		"unlock.type_stage": "Stage",
		"unlock.type_arcana": "Arcana",
		"unlock.type_character": "Character",
	}
