extends Area2D
# Data-driven pickups matching Vampire Survivors base game (wiki).
# https://vampire.survivors.wiki/w/Pickups

enum PickupType {
	CHICKEN,        # Floor Chicken — heal 30 HP (rarity 12)
	GOLD_COIN,      # +1 Gold (rarity 50)
	COIN_BAG,       # +10 Gold (rarity 10)
	RICH_COIN_BAG,  # +100 Gold (rarity 1, unlock 5, Luck)
	ROSARY,         # Kill all enemies (rarity 1, unlock 8, Luck)
	OROLOGION,      # Freeze enemies 10s (rarity 2, unlock 4, Luck)
	VACUUM,         # Gather all gems (rarity 2, unlock 12, Luck)
	LITTLE_CLOVER,  # +10% Luck permanent (rarity 0.5, unlock 0)
	GILDED_CLOVER,  # Gather gold + Gold Fever (rarity 1, unlock 30, Luck)
	GOLD_FINGER,    # Invincibility + CD → prize (rarity 0.02, unlock 30)
	NDUJA_FRITTA,   # Breathe fire 10s (rarity 1, unlock 0, Luck)
	REROLLO,        # +1 Reroll (rarity 1, unlock 0)
	BIG_COIN_BAG,   # +25 Gold (rarity 0, unlock 100000, level-up only)
}

# Rarity data matching wiki — for light source drops and enemy drops.
const RARITY: Dictionary = {
	PickupType.GOLD_COIN: 50,
	PickupType.COIN_BAG: 10,
	PickupType.RICH_COIN_BAG: 1,
	PickupType.ROSARY: 1,
	PickupType.OROLOGION: 2,
	PickupType.VACUUM: 2,
	PickupType.CHICKEN: 12,
	PickupType.LITTLE_CLOVER: 0.5,
	PickupType.GILDED_CLOVER: 1,
	PickupType.GOLD_FINGER: 0.02,
	PickupType.NDUJA_FRITTA: 1,
	PickupType.REROLLO: 1,
}

# Base coin values
const COIN_VALUES: Dictionary = {
	PickupType.GOLD_COIN: 1,
	PickupType.COIN_BAG: 10,
	PickupType.RICH_COIN_BAG: 100,
	PickupType.BIG_COIN_BAG: 25,
}

var type: int = PickupType.CHICKEN:
	set(v):
		if type != v:
			type = v
			if is_inside_tree():
				queue_redraw()
var player: Node2D
var collected: bool = false
var attracted: bool = false
var attract_speed: float = 300.0
var _rarity: float = 12.0

const CollisionLayers = preload("res://scripts/data/collision_layers.gd")


func _ready():
	collision_layer = CollisionLayers.PICKUP
	collision_mask = CollisionLayers.MASK_PLAYER
	body_entered.connect(_on_body_entered)
	add_to_group("pickups")

	var timer = Timer.new()
	timer.wait_time = 25.0
	timer.one_shot = true
	var _self_id = get_instance_id()
	timer.timeout.connect(func():
		var _s = instance_from_id(_self_id)
		if _s:
			_s.queue_free()
	)
	add_child(timer)
	timer.start()
	
	# Floating bob animation — Tween on position.y, no _process needed
	var tw = create_tween().set_loops()
	tw.tween_property(self, "position:y", position.y - 4.0, 1.5)
	tw.tween_property(self, "position:y", position.y + 4.0, 1.5)


func _on_body_entered(body: Node):
	if body == player and not collected:
		apply_effect()


func _show_text(txt: String, col: Color, sz: int = 16):
	if is_inside_tree() and ObjectPoolManager:
		ObjectPoolManager.spawn_ft(get_parent(), global_position, txt, col, sz)


func apply_effect():
	if collected:
		return
	collected = true

	match type:
		PickupType.CHICKEN:
			_show_text(I18N.t("pickup.chicken"), Color(0.3, 1.0, 0.3))
			AudioManager.play_sfx("pickup_chicken")
			if player and player.has_method("heal"):
				player.heal(30.0)

		PickupType.GOLD_COIN, PickupType.COIN_BAG, PickupType.RICH_COIN_BAG, PickupType.BIG_COIN_BAG:
			var val = COIN_VALUES.get(type, 10)
			var greed_mult = 1.0
			if is_instance_valid(player) and player.has_method("get_greed_mult"):
				greed_mult = player.get_greed_mult()
			var total = int(val * greed_mult)
			_show_text(I18N.t("pickup.gold_name") % [total], Color(0.9, 0.8, 0.1))
			AudioManager.play_sfx("pickup_gold")
			PowerUpManager.add_run_gold(total)
			if ArcanaManager and ArcanaManager.has_effect("gold_fever_extend"):
				_trigger_gold_fever()

		PickupType.ROSARY:
			_show_text(I18N.t("pickup.rosary"), Color(0.3, 0.5, 1.0), 20)
			AudioManager.play_sfx("pickup_rosary")
			var _em = get_node_or_null("/root/Main/EnemyManager")
			if _em:
				for _eid in _em.query_all_ids():
					_em.kill(_eid)

		PickupType.OROLOGION:
			_show_text(I18N.t("pickup.orologion"), Color(0.5, 0.8, 1.0), 20)
			AudioManager.play_sfx("pickup_orologion")
			EventBus.set_config("freeze_timer", 10.0)
			var _em = get_node_or_null("/root/Main/EnemyManager")
			if _em:
				for _eid in _em.query_all_ids():
						_em.freeze(_eid, 10.0)

		PickupType.VACUUM:
			_show_text(I18N.t("pickup.vacuum"), Color(0.2, 0.8, 0.9), 20)
			AudioManager.play_sfx("pickup_vacuum")
			for g in get_tree().get_nodes_in_group("gems"):
				if is_instance_valid(g):
					g.attracted = true
			EventBus.pickup_collected.emit(type)

		PickupType.LITTLE_CLOVER:
			_show_text(I18N.t("pickup.little_clover"), Color(0.2, 0.9, 0.3), 18)
			AudioManager.play_sfx("pickup_clover")
			if is_instance_valid(player) and player.has_method("add_luck"):
				player.add_luck(0.10)
			EventBus.pickup_collected.emit(type)

		PickupType.GILDED_CLOVER:
			_show_text(I18N.t("pickup.gilded_clover"), Color(0.9, 0.8, 0.1), 20)
			AudioManager.play_sfx("pickup_gold")
			_collect_all_gold()
			_trigger_gold_fever()

		PickupType.GOLD_FINGER:
			_show_text(I18N.t("pickup.gold_finger"), Color(0.9, 0.7, 0.0), 22)
			AudioManager.play_sfx("pickup_gold_finger")
			var gf_bonus = 0.0
			if is_instance_valid(player) and player.has_method("get_gold_fever_duration_bonus"):
				gf_bonus = player.get_gold_fever_duration_bonus()
			EventBus.set_config("gold_finger_timer", 14.0 * (1.0 + gf_bonus))
			EventBus.set_config("gold_finger_kills", 0)

		PickupType.NDUJA_FRITTA:
			_show_text(I18N.t("pickup.nduja_fritta"), Color(0.9, 0.4, 0.1), 18)
			AudioManager.play_sfx("pickup_nduja")
			EventBus.set_config("nduja_timer", 10.0)

		PickupType.REROLLO:
			_show_text(I18N.t("pickup.rerollo"), Color(0.7, 0.5, 0.9), 18)
			AudioManager.play_sfx("pickup_rerollo")
			if PowerUpManager:
				PowerUpManager.add_reroll(1)

	queue_free()


func _collect_all_gold():
	for p in get_tree().get_nodes_in_group("pickups"):
		if is_instance_valid(p) and not p.collected:
			if p.type in [PickupType.GOLD_COIN, PickupType.COIN_BAG, PickupType.RICH_COIN_BAG, PickupType.BIG_COIN_BAG]:
				p.apply_effect()


func _trigger_gold_fever():
	var gf_bonus = 0.0
	if is_instance_valid(player) and player.has_method("get_gold_fever_duration_bonus"):
		gf_bonus = player.get_gold_fever_duration_bonus()
	EventBus.set_config("gold_fever_timer", 10.0 * (1.0 + gf_bonus))


func _draw():
	var off = Vector2.ZERO
	match type:
		PickupType.CHICKEN:
			draw_circle(off, 8, Color(0.9, 0.15, 0.15))
			draw_circle(off, 8, Color(1, 0.3, 0.3), false, 1.5)
			draw_line(off + Vector2(-3, 0), off + Vector2(3, 0), Color.WHITE, 2.0)
			draw_line(off + Vector2(0, -3), off + Vector2(0, 3), Color.WHITE, 2.0)

		PickupType.GOLD_COIN:
			var d = PackedVector2Array([
				off + Vector2(0, -6), off + Vector2(5, 0),
				off + Vector2(0, 6), off + Vector2(-5, 0)
			])
			draw_polygon(d, [Color(0.9, 0.8, 0.1)])
			draw_circle(off, 2, Color(0.7, 0.6, 0.05))

		PickupType.COIN_BAG:
			var d = PackedVector2Array([
				off + Vector2(0, -8), off + Vector2(6, 0),
				off + Vector2(0, 8), off + Vector2(-6, 0)
			])
			draw_polygon(d, [Color(0.85, 0.7, 0.15)])
			draw_circle(off, 3, Color(0.9, 0.8, 0.2))

		PickupType.RICH_COIN_BAG:
			var d = PackedVector2Array([
				off + Vector2(0, -9), off + Vector2(7, 0),
				off + Vector2(0, 9), off + Vector2(-7, 0)
			])
			draw_polygon(d, [Color(0.6, 0.2, 0.8)])
			draw_line(off + Vector2(-3, -1), off + Vector2(3, -1), Color(0.9, 0.8, 0.2), 1.5)
			draw_line(off + Vector2(-3, 2), off + Vector2(3, 2), Color(0.9, 0.8, 0.2), 1.5)

		PickupType.ROSARY:
			draw_circle(off, 8, Color(0.2, 0.3, 0.9))
			draw_arc(off, 8, 0, TAU, 12, Color(0.5, 0.6, 1.0), 2.0)
			draw_line(off + Vector2(-3, -3), off + Vector2(3, 3), Color.WHITE, 2.0)
			draw_line(off + Vector2(3, -3), off + Vector2(-3, 3), Color.WHITE, 2.0)

		PickupType.OROLOGION:
			draw_circle(off, 8, Color(0.4, 0.7, 1.0, 0.6))
			draw_arc(off, 8, 0, TAU, 12, Color(0.6, 0.9, 1.0), 2.0)
			draw_line(off + Vector2(0, -5), off + Vector2(0, 0), Color.WHITE, 2.0)
			draw_line(off + Vector2(0, 0), off + Vector2(4, 0), Color.WHITE, 2.0)

		PickupType.VACUUM:
			var d2 = PackedVector2Array([
				off + Vector2(0, -8), off + Vector2(6, 0),
				off + Vector2(0, 8), off + Vector2(-6, 0)
			])
			draw_polygon(d2, [Color(0.2, 0.8, 0.9, 0.8)])
			draw_circle(off, 4, Color(0.5, 0.9, 1.0))

		PickupType.LITTLE_CLOVER:
			_draw_clover(off, 5, Color(0.2, 0.85, 0.3))

		PickupType.GILDED_CLOVER:
			_draw_clover(off, 7, Color(0.9, 0.8, 0.1))

		PickupType.GOLD_FINGER:
			draw_circle(off, 9, Color(0.9, 0.7, 0.0, 0.5))
			draw_arc(off, 9, 0, TAU, 12, Color(1.0, 0.85, 0.2), 2.0)
			draw_line(off + Vector2(0, -6), off + Vector2(0, 6), Color(1.0, 0.9, 0.3), 2.0)
			draw_line(off + Vector2(-4, -2), off + Vector2(4, -2), Color(1.0, 0.9, 0.3), 2.0)

		PickupType.NDUJA_FRITTA:
			draw_circle(off, 8, Color(0.9, 0.3, 0.05))
			draw_circle(off, 8, Color(1.0, 0.5, 0.1), false, 1.5)
			var pts = PackedVector2Array([
				off + Vector2(-2, -4), off + Vector2(2, -4),
				off + Vector2(4, 0), off + Vector2(2, 4),
				off + Vector2(-2, 4), off + Vector2(-4, 0)
			])
			draw_polygon(pts, [Color(0.9, 0.4, 0.1)])

		PickupType.REROLLO:
			draw_circle(off, 7, Color(0.6, 0.4, 0.8))
			draw_arc(off, 7, 0, TAU, 10, Color(0.8, 0.6, 1.0), 1.5)
			draw_line(off + Vector2(-3, 0), off + Vector2(3, 0), Color.WHITE, 2.0)
			draw_line(off + Vector2(0, -3), off + Vector2(3, 0), Color(0.8, 0.6, 1.0), 1.5)
			draw_line(off + Vector2(0, 3), off + Vector2(3, 0), Color(0.8, 0.6, 1.0), 1.5)

		PickupType.BIG_COIN_BAG:
			var d = PackedVector2Array([
				off + Vector2(0, -10), off + Vector2(8, 0),
				off + Vector2(0, 10), off + Vector2(-8, 0)
			])
			draw_polygon(d, [Color(0.8, 0.6, 0.1)])
			draw_circle(off, 5, Color(0.9, 0.8, 0.2))
			draw_line(off + Vector2(-4, 0), off + Vector2(4, 0), Color(0.6, 0.4, 0.05), 2.0)


func _draw_clover(off: Vector2, r: float, col: Color):
	var cx = off.x
	var cy = off.y
	var s = r * 0.5
	# Four leaves
	var leaves = [
		Vector2(cx, cy - s),
		Vector2(cx + s, cy),
		Vector2(cx, cy + s),
		Vector2(cx - s, cy),
	]
	for l in leaves:
		draw_circle(l, s, col)
	# Stem
	draw_line(Vector2(cx, cy + s), Vector2(cx, cy + s * 1.8), Color(0.15, 0.5, 0.15), 1.5)
