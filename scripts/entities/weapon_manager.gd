# WeaponManager — 武器逻辑编排器
# 每种武器的 fire 逻辑在独立的 weapon_behaviors/ 脚本中
# 通过 _behaviors 字典 {type: script} 查表分发

const ItemTypes = preload("res://scripts/data/item_types.gd")

var _player
var weapons: Array[WeaponState] = []

# ── 武器状态（各 behavior 访问使用） ──
var whip_vis_time: float = 0.0
var whip_hit_window: float = 0.0
var whip_vis_area: float = 60.0

var _whip_hit_this_swing: Dictionary = {}
var _wand_sfx_cooldown: float = 0.0
var _knife_sfx_cooldown: float = 0.0

var _bible_projectiles: Array[Node2D] = []
var _bible_angle: float = 0.0

var _enemy_registry_cache = null

# ── 脚本依赖（延迟加载） ──
var _proj_vis_script = preload("res://scripts/entities/proj_vis.gd")
var _proj_mover_script = preload("res://scripts/entities/projectile_mover.gd")
var _explosion_fx_script = preload("res://scripts/entities/explosion_fx.gd")
var _emoji_node_script = preload("res://scripts/entities/emoji_node.gd")
var _fireball_node_script = preload("res://scripts/entities/fireball_node.gd")

# ── 行为注册表 ──
var _behaviors: Dictionary = {}

func _register_behaviors():
	var dir = "res://scripts/entities/weapon_behaviors/"
	_behaviors[ItemTypes.Type.WHIP] = load(dir + "whip.gd")
	_behaviors[ItemTypes.Type.MAGIC_WAND] = load(dir + "magic_wand.gd")
	_behaviors[ItemTypes.Type.GARLIC] = load(dir + "garlic.gd")
	_behaviors[ItemTypes.Type.KNIFE] = load(dir + "knife.gd")
	_behaviors[ItemTypes.Type.AXE] = load(dir + "axe.gd")
	_behaviors[ItemTypes.Type.FIRE_WAND] = load(dir + "fire_wand.gd")
	_behaviors[ItemTypes.Type.CROSS] = load(dir + "cross.gd")
	_behaviors[ItemTypes.Type.KING_BIBLE] = load(dir + "king_bible.gd")
	_behaviors[ItemTypes.Type.SANTA_WATER] = load(dir + "santa_water.gd")
	_behaviors[ItemTypes.Type.RUNETRACER] = load(dir + "runetracer.gd")
	_behaviors[ItemTypes.Type.LIGHTNING_RING] = load(dir + "lightning_ring.gd")
	_behaviors[ItemTypes.Type.PENTAGRAM] = load(dir + "pentagram.gd")
	_behaviors[ItemTypes.Type.PEACHONE] = load(dir + "peachone.gd")
	_behaviors[ItemTypes.Type.EBONY_WINGS] = load(dir + "ebony_wings.gd")
	_behaviors[ItemTypes.Type.PHIERA_DER_TUPHELLO] = load(dir + "phiera_der_tuphello.gd")
	_behaviors[ItemTypes.Type.EIGHT_THE_SPARROW] = load(dir + "eight_the_sparrow.gd")
	_behaviors[ItemTypes.Type.GATTI_AMARI] = load(dir + "gatti_amari.gd")
	_behaviors[ItemTypes.Type.SONG_OF_MANA] = load(dir + "song_of_mana.gd")
	_behaviors[ItemTypes.Type.SHADOW_PINION] = load(dir + "shadow_pinion.gd")
	_behaviors[ItemTypes.Type.CLOCK_LANCET] = load(dir + "clock_lancet.gd")
	_behaviors[ItemTypes.Type.LAUREL] = load(dir + "laurel.gd")
	_behaviors[ItemTypes.Type.VENTO_SACRO] = load(dir + "vento_sacro.gd")
	_behaviors[ItemTypes.Type.BONE] = load(dir + "bone.gd")
	_behaviors[ItemTypes.Type.CHERRY_BOMB] = load(dir + "cherry_bomb.gd")
	_behaviors[ItemTypes.Type.CARRELLO] = load(dir + "carrello.gd")
	_behaviors[ItemTypes.Type.CELESTIAL_DUSTING] = load(dir + "celestial_dusting.gd")
	_behaviors[ItemTypes.Type.LA_ROBBA] = load(dir + "la_robba.gd")
	_behaviors[ItemTypes.Type.GREATEST_JUBILEE] = load(dir + "greatest_jubilee.gd")
	_behaviors[ItemTypes.Type.BRACELET] = load(dir + "bracelet.gd")
	_behaviors[ItemTypes.Type.CANDYBOX] = load(dir + "candybox.gd")
	_behaviors[ItemTypes.Type.VICTORY_SWORD] = load(dir + "victory_sword.gd")
	_behaviors[ItemTypes.Type.FLAMES_OF_MISSPELL] = load(dir + "flames_of_misspell.gd")
	_behaviors[ItemTypes.Type.PAKO_BATTILIAR] = load(dir + "pako_battiliar.gd")
	_behaviors[ItemTypes.Type.AMMO_APPALATE] = load(dir + "ammo_appalate.gd")
	_behaviors[ItemTypes.Type.CHAOS_RUNE] = load(dir + "chaos_rune.gd")
	_behaviors[ItemTypes.Type.GLASS_FANDANGO] = load(dir + "glass_fandango.gd")
	_behaviors[ItemTypes.Type.SANTA_JAVELIN] = load(dir + "santa_javelin.gd")
	_behaviors[ItemTypes.Type.GAZE_OF_GAEA] = load(dir + "gaze_of_gaea.gd")
	_behaviors[ItemTypes.Type.MAGI_STONE] = load(dir + "magi_stone.gd")
	_behaviors[ItemTypes.Type.PHAS3R] = load(dir + "phas3r.gd")
	_behaviors[ItemTypes.Type.ARMA_DIO] = load(dir + "arma_dio.gd")


func _get_enemies() -> Array:
	if _enemy_registry_cache == null:
		_enemy_registry_cache = EnemyRegistry
	if _enemy_registry_cache != null and _enemy_registry_cache.get_count() > 0:
		return _enemy_registry_cache.get_all_ref()
	return []


func _calc_damage(w: WeaponState) -> float:
	var dmg = w.damage * _player.damage_mult
	if _player._crit_chance > 0 and randf() < _player._crit_chance:
		dmg *= _player._crit_mult
	return dmg


func _make_emoji_node(emoji: String, sz: float) -> Node2D:
	var n = _emoji_node_script.new()
	n.setup(emoji, sz)
	return n


# ── 进化配方 ──

const EVOLUTION_RECIPES = {
	ItemTypes.Type.WHIP: {
		"passive": ItemTypes.Type.SPINACH,
		"passive_level": 5,
		"name": "Bloody Tear",
		"desc": "Whip evolves into Bloody Tear\nHeals 20% of damage dealt"
	},
	ItemTypes.Type.MAGIC_WAND: {
		"passive": ItemTypes.Type.WINGS,
		"passive_level": 5,
		"name": "Holy Wand",
		"desc": "Magic Wand evolves into Holy Wand\nFires at super speed"
	},
	ItemTypes.Type.GARLIC: {
		"passive": ItemTypes.Type.TOME,
		"passive_level": 5,
		"name": "Soul Eater",
		"desc": "Garlic evolves into Soul Eater\nHeals 1 HP per kill"
	},
	ItemTypes.Type.KNIFE: {
		"passive": ItemTypes.Type.CANDELABRADOR,
		"passive_level": 5,
		"name": "Thousand Edge",
		"desc": "Knife evolves into Thousand Edge\nFires a spread of 3 blades"
	},
	ItemTypes.Type.AXE: {
		"passive": ItemTypes.Type.HOLLOW_HEART,
		"passive_level": 5,
		"name": "Death Spiral",
		"desc": "Axe evolves into Death Spiral\nAxes orbit and return to you"
	},
	ItemTypes.Type.FIRE_WAND: {
		"passive": ItemTypes.Type.SPINACH,
		"passive_level": 5,
		"name": "Hellfire",
		"desc": "Fire Wand evolves into Hellfire\nDouble explosions"
	},
	ItemTypes.Type.CROSS: {
		"passive": ItemTypes.Type.CLOVER,
		"passive_level": 5,
		"name": "Heaven Sword",
		"desc": "Cross evolves into Heaven Sword\nSword rains from above"
	},
	ItemTypes.Type.KING_BIBLE: {
		"passive": ItemTypes.Type.SPELLBINDER,
		"passive_level": 5,
		"name": "Unholy Vespers",
		"desc": "King Bible evolves into Unholy Vespers\nDual orbiting shields"
	},
	ItemTypes.Type.SANTA_WATER: {
		"passive": ItemTypes.Type.MAGNET,
		"passive_level": 5,
		"name": "La Borra",
		"desc": "Santa Water evolves into La Borra\nTracking damaging puddles"
	},
	ItemTypes.Type.RUNETRACER: {
		"passive": ItemTypes.Type.ARMOR,
		"passive_level": 5,
		"name": "NO FUTURE",
		"desc": "Runetracer evolves into NO FUTURE\nWalls of piercing lasers"
	},
	ItemTypes.Type.LIGHTNING_RING: {
		"passive": ItemTypes.Type.SPINACH,
		"passive_level": 5,
		"name": "Thunder Loop",
		"desc": "Lightning Ring evolves into Thunder Loop\nChain lightning"
	},
	ItemTypes.Type.PENTAGRAM: {
		"passive": ItemTypes.Type.CLOVER,
		"passive_level": 5,
		"name": "Gorgeous Moon",
		"desc": "Pentagram evolves into Gorgeous Moon\nLarger range, lower cooldown"
	},
	ItemTypes.Type.PEACHONE: {
		"passive": ItemTypes.Type.EBONY_WINGS,
		"passive_level": 7,
		"need_weapon": ItemTypes.Type.EBONY_WINGS,
		"name": "Vandalier",
		"desc": "Peachone + Ebony Wings evolve into Vandalier\nDual orbiting allies"
	},
	ItemTypes.Type.EBONY_WINGS: {
		"passive": ItemTypes.Type.PEACHONE,
		"passive_level": 7,
		"need_weapon": ItemTypes.Type.PEACHONE,
		"name": "Vandalier",
		"desc": "Peachone + Ebony Wings evolve into Vandalier\nDual orbiting allies"
	},
	ItemTypes.Type.PHIERA_DER_TUPHELLO: {
		"passive": ItemTypes.Type.EIGHT_THE_SPARROW,
		"passive_level": 7,
		"need_weapon": ItemTypes.Type.EIGHT_THE_SPARROW,
		"name": "Phieraggi",
		"desc": "Phiera + Eight evolve into Phieraggi\nUltra piercing attack"
	},
	ItemTypes.Type.EIGHT_THE_SPARROW: {
		"passive": ItemTypes.Type.PHIERA_DER_TUPHELLO,
		"passive_level": 7,
		"need_weapon": ItemTypes.Type.PHIERA_DER_TUPHELLO,
		"name": "Phieraggi",
		"desc": "Phiera + Eight evolve into Phieraggi\nUltra piercing attack"
	},
	ItemTypes.Type.GATTI_AMARI: {
		"passive": ItemTypes.Type.STONE_MASK,
		"passive_level": 5,
		"name": "Vicious Hunger",
		"desc": "Gatti Amari evolves into Vicious Hunger\nCats pick up gold and items"
	},
	ItemTypes.Type.SONG_OF_MANA: {
		"passive": ItemTypes.Type.TOME,
		"passive_level": 5,
		"name": "Mannajja",
		"desc": "Song of Mana evolves into Mannajja\nTracking vines, full screen attack"
	},
	ItemTypes.Type.SHADOW_PINION: {
		"passive": ItemTypes.Type.WINGS,
		"passive_level": 5,
		"name": "Valkyrie Turner",
		"desc": "Shadow Pinion evolves into Valkyrie Turner\nEnhanced shadow strikes"
	},
	ItemTypes.Type.CLOCK_LANCET: {
		"passive": ItemTypes.Type.METAGLIO_LEFT,
		"passive_level": 5,
		"need_weapon": ItemTypes.Type.LAUREL,
		"need_weapon_level": 7,
		"name": "Infinite Corridor",
		"desc": "Clock Lancet + Laurel evolve into Infinite Corridor\nTime manipulation"
	},
	ItemTypes.Type.LAUREL: {
		"passive": ItemTypes.Type.METAGLIO_RIGHT,
		"passive_level": 5,
		"need_weapon": ItemTypes.Type.CLOCK_LANCET,
		"need_weapon_level": 7,
		"name": "Crimson Shroud",
		"desc": "Laurel + Clock Lancet evolve into Crimson Shroud\nDamage reflection"
	},
	ItemTypes.Type.VENTO_SACRO: {
		"passive": ItemTypes.Type.BRACER,
		"passive_level": 5,
		"name": "Fuwalafuwaloo",
		"desc": "Vento Sacro evolves into Fuwalafuwaloo\nAlways at full power"
	},
	ItemTypes.Type.BONE: {
		"passive": ItemTypes.Type.ARMOR,
		"passive_level": 5,
		"name": "Anima of Mortaccio",
		"desc": "Bone evolves into Anima of Mortaccio\nBones bounce more"
	},
	ItemTypes.Type.CHERRY_BOMB: {
		"passive": ItemTypes.Type.TIRAGISU,
		"passive_level": 5,
		"name": "Yatta Daikarin",
		"desc": "Cherry Bomb evolves into Yatta Daikarin\nBigger explosions"
	},
	ItemTypes.Type.CARRELLO: {
		"passive": ItemTypes.Type.SPELLBINDER,
		"passive_level": 5,
		"name": "Carozza!",
		"desc": "Carréllo evolves into Carozza!\nMore bouncing projectiles"
	},
	ItemTypes.Type.CELESTIAL_DUSTING: {
		"passive": ItemTypes.Type.DUPLICATOR,
		"passive_level": 5,
		"name": "Profusione D'Amore",
		"desc": "Celestial Dusting evolves into Profusione D'Amore\nRapid fire love burst"
	},
	ItemTypes.Type.BRACELET: {
		"passive": ItemTypes.Type.CROWN,
		"passive_level": 5,
		"name": "Bi-Bracelet",
		"desc": "Bracelet evolves into Bi-Bracelet\nDual bracelet attack"
	},
	ItemTypes.Type.FLAMES_OF_MISSPELL: {
		"passive": ItemTypes.Type.SPINACH,
		"passive_level": 5,
		"name": "Ashes of Muspell",
		"desc": "Flames of Misspell evolves into Ashes of Muspell\nInfernal blaze"
	},
	ItemTypes.Type.PAKO_BATTILIAR: {
		"passive": ItemTypes.Type.HOLLOW_HEART,
		"passive_level": 5,
		"name": "Mazo Familiar",
		"desc": "Pako Battiliar evolves into Mazo Familiar\nMore counterattacks"
	},
	ItemTypes.Type.AMMO_APPALATE: {
		"passive": ItemTypes.Type.CANDELABRADOR,
		"passive_level": 5,
		"name": "Gunastrophe",
		"desc": "Ammo Appalate evolves into Gunastrophe\nUnlimited ammo"
	},
	ItemTypes.Type.CHAOS_RUNE: {
		"passive": ItemTypes.Type.SKULL,
		"passive_level": 5,
		"name": "Wicked Ruler",
		"desc": "Chaos Rune evolves into Wicked Ruler\nChaotic rune storm"
	},
	ItemTypes.Type.GLASS_FANDANGO: {
		"passive": ItemTypes.Type.SPELLBINDER,
		"passive_level": 5,
		"name": "Celestial Voulge",
		"desc": "Glass Fandango evolves into Celestial Voulge\nCelestial ice storm"
	},
	ItemTypes.Type.SANTA_JAVELIN: {
		"passive": ItemTypes.Type.BRACER,
		"passive_level": 5,
		"name": "Seraphic Cry",
		"desc": "Santa Javelin evolves into Seraphic Cry\nHoming javelins"
	},
	ItemTypes.Type.GAZE_OF_GAEA: {
		"passive": ItemTypes.Type.CLOVER,
		"passive_level": 5,
		"name": "Embrace of Gaea",
		"desc": "Gaze of Gaea evolves into Embrace of Gaea\nNature's wrath"
	},
	ItemTypes.Type.MAGI_STONE: {
		"passive": ItemTypes.Type.TOME,
		"passive_level": 5,
		"name": "Kyra-Stones",
		"desc": "Magi-Stone evolves into Kyra-Stones\nMore magical stones"
	},
	ItemTypes.Type.PHAS3R: {
		"passive": ItemTypes.Type.DUPLICATOR,
		"passive_level": 5,
		"name": "Photonstorm",
		"desc": "Phas3r evolves into Photonstorm\nPhoton laser storm"
	},
}


func _init(player: Player):
	_player = player
	_register_behaviors()


func add_weapon(ws: WeaponState):
	weapons.append(ws)


func add_or_upgrade(t: int):
	var w = _find_weapon(t)
	if w:
		w.upgrade()
	else:
		weapons.append(WeaponState.new(t))


func _can_fire(w: WeaponState) -> bool:
	var enemies = _get_enemies()
	if enemies.is_empty():
		return false
	var ppos = _player.global_position

	if w.type == ItemTypes.Type.GARLIC or w.type == ItemTypes.Type.PENTAGRAM or w.type == ItemTypes.Type.LAUREL or w.type == ItemTypes.Type.PAKO_BATTILIAR:
		return true

	var range_limit: float
	match w.type:
		ItemTypes.Type.KING_BIBLE:
			range_limit = 80.0 + w.area * _player.area_mult
		ItemTypes.Type.WHIP:
			range_limit = w.area * _player.area_mult * 3.0
		ItemTypes.Type.SANTA_WATER:
			range_limit = w.area * _player.area_mult * 2.5
		_:
			range_limit = 350.0 + w.area * _player.area_mult * 3.0

	var range_sq = range_limit * range_limit
	for e in enemies:
		if is_instance_valid(e) and ppos.distance_squared_to(e.global_position) <= range_sq:
			return true
	return false


func process(delta: float):
	if _wand_sfx_cooldown > 0:
		_wand_sfx_cooldown -= delta
	if _knife_sfx_cooldown > 0:
		_knife_sfx_cooldown -= delta
	if whip_vis_time > 0:
		whip_vis_time -= delta
	if whip_hit_window > 0:
		whip_hit_window -= delta
		for w in weapons:
			if w.type == ItemTypes.Type.WHIP:
				_whip_hit_this_swing.clear()
				var b = _behaviors.get(ItemTypes.Type.WHIP)
				if b:
					b._check_hits(w, self, _player, _get_enemies)
	for w in weapons:
		w.cooldown_timer -= delta
		if w.cooldown_timer <= 0 and _can_fire(w):
			w.cooldown_timer = w.cooldown * (1.0 - _player.cooldown_reduction)
			fire_weapon(w)
	if not _bible_projectiles.is_empty():
		_bible_angle += delta * 3.0
		var i = _bible_projectiles.size() - 1
		while i >= 0:
			var p = _bible_projectiles[i]
			if not is_instance_valid(p):
				_bible_projectiles.remove_at(i)
			else:
				var angle = p.get_meta("orbit_angle", 0.0) + _bible_angle
				var radius = p.get_meta("orbit_radius", 60.0)
				p.global_position = _player.global_position + Vector2(cos(angle), sin(angle)) * radius
			i -= 1
	_update_bird_orbits(delta)


func _update_bird_orbits(delta: float):
	var all_birds = []
	if has_meta("peachone_birds"):
		all_birds += get_meta("peachone_birds")
	if has_meta("ebony_birds"):
		all_birds += get_meta("ebony_birds")
	if all_birds.is_empty():
		return
	for p in all_birds:
		if not is_instance_valid(p):
			continue
		var angle = p.get_meta("orbit_angle", 0.0)
		var clockwise = p.get_meta("clockwise", true)
		var speed = p.get_meta("orbit_speed", 2.0)
		angle += delta * speed * (1.0 if clockwise else -1.0)
		p.set_meta("orbit_angle", angle)
		var radius = p.get_meta("orbit_radius", 60.0)
		p.global_position = _player.global_position + Vector2(cos(angle), sin(angle)) * radius


func fire_weapon(w: WeaponState):
	var behavior = _behaviors.get(w.type)
	if behavior:
		behavior.fire(w, self, _player, _get_enemies)
	else:
		push_warning("WeaponManager: no behavior for type %d" % w.type)


func get_projectile_count(weapon_type: int) -> int:
	var count = 1 + _player.projectile_bonus
	if ArcanaManager and ArcanaManager.active_arcanas_have_weapon_effect(weapon_type, "listed_amount_plus_1"):
		count += 1
	if ArcanaManager and ArcanaManager.has_effect("main_weapon_amount_plus_3"):
		if weapons.size() > 0 and weapons[0].type == weapon_type:
			count += 3
	if weapon_type == ItemTypes.Type.KNIFE:
		var w = _find_weapon(ItemTypes.Type.KNIFE)
		if w and w.evolved:
			count += 2
	elif weapon_type == ItemTypes.Type.MAGIC_WAND:
		var w = _find_weapon(ItemTypes.Type.MAGIC_WAND)
		if w and w.evolved:
			count += 1
	return max(count, 1)


# ── 进化 ──

func can_evolve(weapon_type: int) -> bool:
	if not EVOLUTION_RECIPES.has(weapon_type):
		return false
	var w = _find_weapon(weapon_type)
	if not w or w.level < w.max_level or w.evolved:
		return false
	var recipe = EVOLUTION_RECIPES[weapon_type]
	var passive_type = recipe["passive"]
	var ok = false
	var passive_lv = _player.passive_inventory.get_level(passive_type)
	if passive_lv > 0:
		ok = passive_lv >= recipe["passive_level"]
	else:
		var other_w = _find_weapon(passive_type)
		ok = other_w != null and other_w.level >= recipe["passive_level"]
	if not ok:
		return false
	if recipe.has("need_weapon"):
		var need = recipe["need_weapon"]
		var need_w = _find_weapon(need)
		var need_lv = recipe.get("need_weapon_level", 7)
		if not need_w or need_w.level < need_lv:
			return false
	if recipe.has("need_passive"):
		var need_p = recipe["need_passive"]
		var need_lv = recipe.get("need_passive_level", 5)
		if _player.passive_inventory.get_level(need_p) < need_lv:
			return false
	return true


func evolve_weapon(weapon_type: int):
	var w = _find_weapon(weapon_type)
	if not w:
		return
	w.evolve()
	var recipe = EVOLUTION_RECIPES[weapon_type]
	var passive_type = recipe["passive"]
	if _player.passive_inventory.get_level(passive_type) > 0:
		_player.passive_inventory.remove(passive_type)
	else:
		var other_w = _find_weapon(passive_type)
		if other_w:
			other_w.evolved = true
			other_w.max_level = w.max_level
	if recipe.has("need_weapon"):
		var need = recipe["need_weapon"]
		var need_w = _find_weapon(need)
		if need_w:
			need_w.evolved = true
	if recipe.has("need_passive"):
		var need_p = recipe["need_passive"]
		_player.passive_inventory.remove(need_p)
	_player.recalculate_stats()
	var evo_name = I18N.t("evo." + _evo_name_key(weapon_type) + "_name")
	_player.show_floating_text("⚡ " + evo_name + " ⚡", Color(0.9, 0.7, 0.1), 22)
	AudioManager.play_sfx("evolution")


static func _evo_name_key(weapon_type: int) -> String:
	match weapon_type:
		ItemTypes.Type.WHIP: return "whip"
		ItemTypes.Type.MAGIC_WAND: return "wand"
		ItemTypes.Type.GARLIC: return "garlic"
		ItemTypes.Type.KNIFE: return "knife"
		ItemTypes.Type.AXE: return "axe"
		ItemTypes.Type.FIRE_WAND: return "firewand"
		ItemTypes.Type.CROSS: return "cross"
		ItemTypes.Type.KING_BIBLE: return "king_bible"
		ItemTypes.Type.SANTA_WATER: return "santa_water"
		ItemTypes.Type.RUNETRACER: return "runetracer"
		ItemTypes.Type.LIGHTNING_RING: return "lightning_ring"
		ItemTypes.Type.PENTAGRAM: return "pentagram"
		ItemTypes.Type.PEACHONE: return "peachone"
		ItemTypes.Type.EBONY_WINGS: return "ebony_wings"
		ItemTypes.Type.PHIERA_DER_TUPHELLO: return "phiera"
		ItemTypes.Type.EIGHT_THE_SPARROW: return "eight"
		ItemTypes.Type.GATTI_AMARI: return "gatti_amari"
		ItemTypes.Type.SONG_OF_MANA: return "song_of_mana"
		ItemTypes.Type.SHADOW_PINION: return "shadow_pinion"
		ItemTypes.Type.CLOCK_LANCET: return "clock_lancet"
		ItemTypes.Type.LAUREL: return "laurel"
		ItemTypes.Type.VENTO_SACRO: return "vento_sacro"
		ItemTypes.Type.BONE: return "bone"
		ItemTypes.Type.CHERRY_BOMB: return "cherry_bomb"
		ItemTypes.Type.CARRELLO: return "carrello"
		ItemTypes.Type.CELESTIAL_DUSTING: return "celestial_dusting"
		ItemTypes.Type.LA_ROBBA: return "la_robba"
		ItemTypes.Type.GREATEST_JUBILEE: return "greatest_jubilee"
		ItemTypes.Type.BRACELET: return "bracelet"
		ItemTypes.Type.VICTORY_SWORD: return "victory_sword"
		ItemTypes.Type.FLAMES_OF_MISSPELL: return "flames_of_misspell"
		ItemTypes.Type.PAKO_BATTILIAR: return "pako_battiliar"
		ItemTypes.Type.AMMO_APPALATE: return "ammo_appalate"
		ItemTypes.Type.CHAOS_RUNE: return "chaos_rune"
		ItemTypes.Type.GLASS_FANDANGO: return "glass_fandango"
		ItemTypes.Type.SANTA_JAVELIN: return "santa_javelin"
		ItemTypes.Type.GAZE_OF_GAEA: return "gaze_of_gaea"
		ItemTypes.Type.MAGI_STONE: return "magi_stone"
		ItemTypes.Type.PHAS3R: return "phas3r"
	return "whip"


# ── 查找 ──

func _find_weapon(t: int) -> WeaponState:
	for w in weapons:
		if w.type == t: return w
	return null


func get_level(t: int) -> int:
	var w = _find_weapon(t)
	return w.level if w else 0


func get_max_level(t: int) -> int:
	var w = _find_weapon(t)
	return w.max_level if w else DataRegistry.items().item_max_level(t)


func get_count() -> int:
	return weapons.size()


# ═══════════════════════════════════════════════════════════════════
#  共享回调工具（被 weapon_behaviors/*.gd 引用）
# ═══════════════════════════════════════════════════════════════════

func _on_proj_hit(body, proj, dmg: float):
	if not is_instance_valid(body) or not is_instance_valid(proj):
		return
	if body.has_method("take_damage"):
		body.take_damage(dmg, Vector2.ZERO)


func _on_proj_hit_and_free(body, proj, dmg: float):
	if not is_instance_valid(body) or not is_instance_valid(proj):
		return
	if body.has_method("take_damage"):
		body.take_damage(dmg, Vector2.ZERO)
	if is_instance_valid(proj):
		proj.queue_free()


func _on_tween_done(proj):
	if is_instance_valid(proj):
		proj.queue_free()


func _on_axe_arc_done(proj, end_pos: Vector2):
	if not is_instance_valid(proj):
		return
	var tw = _player.create_tween()
	tw.set_parallel(true)
	tw.tween_property(proj, "global_position", end_pos, 0.5)
	tw.tween_property(proj, "rotation", proj.rotation - TAU * 1.5, 0.5)
	tw.finished.connect(_on_tween_done.bind(proj))


func _on_axe_return(proj, return_pos: Vector2):
	if not is_instance_valid(proj):
		return
	var tw = _player.create_tween()
	tw.tween_property(proj, "global_position", return_pos, 0.5)
	tw.tween_property(proj, "scale", Vector2(0.3, 0.3), 0.5)
	tw.finished.connect(_on_tween_done.bind(proj))


func _on_firewand_hit(body, proj, explosion_radius: float, dmg: float, w: WeaponState):
	if not is_instance_valid(body) or not is_instance_valid(proj):
		return
	var pos = proj.global_position
	if body.has_method("take_damage"):
		body.take_damage(dmg, Vector2.ZERO)
	_explode_at(pos, explosion_radius, dmg, w)
	if is_instance_valid(proj):
		for c in proj.get_children():
			if c.has_method("mark_hit"):
				c.mark_hit()
		proj.queue_free()


func _on_firewand_explode(proj, explosion_radius: float, dmg: float, w: WeaponState = null):
	if not is_instance_valid(proj):
		return
	_explode_at(proj.global_position, explosion_radius, dmg, w)
	if is_instance_valid(proj):
		proj.queue_free()


func _explode_at(pos: Vector2, explosion_radius: float, dmg: float, w: WeaponState):
	_spawn_explosion_fx(pos, explosion_radius, Color(0.9, 0.4, 0.1))
	var enemies = _get_enemies()
	for e in enemies:
		if is_instance_valid(e) and pos.distance_to(e.global_position) < explosion_radius:
			if e.has_method("take_damage"):
				e.take_damage(dmg, Vector2.ZERO)
	var evolved = w and w.evolved
	if evolved:
		var dbl_radius = explosion_radius * 1.6
		_spawn_explosion_fx(pos, dbl_radius, Color(1.0, 0.3, 0.0))
		for e in enemies:
			if is_instance_valid(e) and pos.distance_to(e.global_position) < dbl_radius:
				if e.has_method("take_damage"):
					e.take_damage(dmg, Vector2.ZERO)


func _spawn_explosion_fx(pos: Vector2, radius: float, color: Color):
	var node = _explosion_fx_script.new()
	node._radius = radius
	node._color = color
	node.global_position = pos
	node.name = "FireWandExplosion"
	_player.get_parent().add_child(node)
	var tw = _player.create_tween()
	tw.tween_property(node, "modulate:a", 0.0, 0.3).from(1.0)
	tw.parallel().tween_property(node, "scale", Vector2(1.6, 1.6), 0.3).from(Vector2(0.4, 0.4))
	tw.finished.connect(node.queue_free)


func _on_boomerang_return(proj, dmg: float):
	if not is_instance_valid(proj):
		return
	for e in _get_enemies():
		if is_instance_valid(e) and proj.global_position.distance_to(e.global_position) < 50:
			if e.has_method("take_damage"):
				e.take_damage(dmg * 0.75, Vector2.ZERO)
	if is_instance_valid(proj):
		proj.queue_free()


func _on_bible_expire(proj):
	var idx = _bible_projectiles.find(proj)
	if idx >= 0:
		_bible_projectiles.remove_at(idx)
	if is_instance_valid(proj):
		proj.queue_free()


func _on_water_tick(zone: Area2D, area: float, dmg: float, evolved: bool):
	if not is_instance_valid(zone):
		return
	var src_pos = zone.global_position
	for e in _get_enemies():
		if not is_instance_valid(e):
			continue
		if src_pos.distance_to(e.global_position) <= area:
			if e.has_method("take_damage"):
				e.take_damage(dmg * 0.5, Vector2.ZERO)
	if evolved:
		var nearest: Node2D = null
		var min_d = INF
		for e in _get_enemies():
			if not is_instance_valid(e):
				continue
			var d = src_pos.distance_squared_to(e.global_position)
			if d < min_d:
				min_d = d
				nearest = e
		if nearest:
			var dir = (nearest.global_position - src_pos).normalized()
			zone.global_position += dir * 30.0


func _on_water_cleanup(zone):
	if is_instance_valid(zone):
		zone.queue_free()
