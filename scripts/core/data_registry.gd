extends Node
# DataRegistry — 所有游戏数据的懒加载访问入口。
#
# 使用方式：
#   DataRegistry.items().item_data(type)
#   DataRegistry.enemies().get_type(id)
#   DataRegistry.arcanas().get_arcana(id)
#
# 数据脚本在首次访问时通过 load() 加载，不占用启动时间。
# 枚举类型单独抽取到 item_types.gd 等小文件，按需 preload。

var _item_defs = null
var _enemy_defs = null
var _arcana_defs = null
var _relic_defs = null
var _character_defs = null
var _stage_defs = null
var _unlock_defs = null

const _PATH_ITEM := "res://scripts/data/item_defs.gd"
const _PATH_ENEMY := "res://scripts/data/enemy_defs.gd"
const _PATH_ARCANA := "res://scripts/data/arcana_defs.gd"
const _PATH_RELIC := "res://scripts/data/relic_defs.gd"
const _PATH_CHARACTER := "res://scripts/data/character_defs.gd"
const _PATH_STAGE := "res://scripts/data/stage_defs.gd"
const _PATH_UNLOCK := "res://scripts/data/unlock_defs.gd"


func items():
	if not _item_defs:
		_item_defs = load(_PATH_ITEM)
	return _item_defs


func enemies():
	if not _enemy_defs:
		_enemy_defs = load(_PATH_ENEMY)
	return _enemy_defs


func arcanas():
	if not _arcana_defs:
		_arcana_defs = load(_PATH_ARCANA)
	return _arcana_defs


func relics():
	if not _relic_defs:
		_relic_defs = load(_PATH_RELIC)
	return _relic_defs


func characters():
	if not _character_defs:
		_character_defs = load(_PATH_CHARACTER)
	return _character_defs


func stages():
	if not _stage_defs:
		_stage_defs = load(_PATH_STAGE)
	return _stage_defs


func unlocks():
	if not _unlock_defs:
		_unlock_defs = load(_PATH_UNLOCK)
	return _unlock_defs
