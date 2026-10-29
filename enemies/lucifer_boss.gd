class_name LuciferBoss
extends "res://enemies/boss.gd"
## Lucifer, a Démonkirály: az utolsó főellenség, a pokol trónterme (world/hell.gd) a 100. emelet kapuja
## mögött. Harmincmillió élete van, a felénél feldühödik (gyorsabb, sűrűbben támad), és a támadásai:
##   pokoltűz  tüzes meteorok záporoznak körülötted (egy mindig oda, ahol állsz)
##   lelkek    háromkarú spirálban lövi szét a kárhozott lelkeket
##   láncok    három lánc csapódik végig legyezőben feléd (a vonaluk előbb kirajzolódik)
##   oszlopok  nyolc irányba tűzoszlopok futnak ki belőle
##   örvény    a lábad alatt megnyílik a mélység: magába húz, aztán felrobban
##   légió     démonokat hív a pokol mélyéről
## Közben a sima főellenség csapása, villanása (mögéd teleportál) és lövedékgyűrűje is megvan.
## A zenéje csak ebben a harcban szól (Audio "lucifer").

const GateBoss := preload("res://enemies/hell_gate_boss.gd")
const LUCIFER := {
	"name": "Lucifer, a Démonkirály", "rect": Rect2(0, 0, 160, 144), "scale": 0.9,
	"health": 30000000, "damage": 260, "speed": 85.0, "xp": 15000,
	"attacks": ["hellfire", "souls", "chains", "pillars", "abyss", "blink", "summon", "souls", "hellfire",
		"chains", "slam", "nova"],
	"minion": "hell_demon",
}
const SHEET := "res://assets/enemies/lucifer.png"
const HIT_SHARE := Vector2(0.4, 0.55)
const WINDUP_COLORS_LUCIFER := {
	"hellfire": Color(2.8, 1.2, 0.3), "souls": Color(2.4, 0.4, 0.6), "chains": Color(2.0, 2.0, 2.0),
	"pillars": Color(2.8, 0.9, 0.2), "abyss": Color(0.9, 0.2, 1.6), "summon": Color(2.6, 0.5, 0.4),
}
const LUCIFER_WINDUP := 0.55
## Pokoltűz: meteorok, mekkora körben, mikor csapódnak be, sugár.
const METEORS := 12
const METEOR_SPREAD := 260.0
const METEOR_FUSE := 0.8
const METEOR_DELAY := 0.12
const METEOR_RADIUS := 56.0
const METEOR_SHARE := 0.8
## Lelkek: karok, lövések karonként, közük, forgás, sebesség.
const SOUL_ARMS := 3
const SOUL_SHOTS := 16
const SOUL_DELAY := 0.1
const SOUL_TURN := 0.24
const SOUL_SPEED := 210.0
const SOUL_SHARE := 0.45
## Láncok: hány, milyen szögben, milyen hosszan.
const CHAIN_FAN := [-0.4, 0.0, 0.4]
const CHAIN_LENGTH := 640.0
const CHAIN_WARN := 0.75
const CHAIN_STEP := 40.0
const CHAIN_RADIUS := 34.0
const CHAIN_SHARE := 1.0
## Tűzoszlopok: irányok, lépések, távolságuk, közük, sugár.
const PILLAR_RAYS := 8
const PILLAR_STEPS := 7
const PILLAR_STEP := 62.0
const PILLAR_DELAY := 0.09
const PILLAR_RADIUS := 40.0
const PILLAR_SHARE := 0.8
## Örvény: meddig húz, milyen erővel, a robbanás sugara.
const ABYSS_TIME := 1.5
const ABYSS_PULL := 210.0
const ABYSS_RADIUS := 115.0
const ABYSS_SHARE := 1.3
## Légió: ennyi démon jön egyszerre, és legfeljebb ennyi lehet élve a teremben.
const LEGION := 2
const LEGION_LIMIT := 3
## Néha felnevet harc közben.
const LAUGH_EVERY := Vector2(7.0, 12.0)

var _laugh_left := 5.0


## Lucifer beállítása a fába kerülés előtt (a setup_boss helyett).
func setup_lucifer(depth: int) -> void:
	mini_boss = false
	_def = LUCIFER
	boss_name = LUCIFER["name"]
	music_track = "lucifer"
	_depth = depth
	_type = {"name": "lucifer", "rect": LUCIFER["rect"], "sheet": SHEET, "run": true}
	stats = {
		"health": LUCIFER["health"],
		"damage": LUCIFER["damage"],
		"speed": LUCIFER["speed"],
		"dodge": 0,
		"knockback": 520.0,
		"resist": 1.0,
		"xp": LUCIFER["xp"],
		"power": 1.0,
	}


func setup_boss(depth: int, _special := {}) -> void:
	setup_lucifer(depth)


func _fit_shapes(size: Vector2) -> void:
	super._fit_shapes(size)
	var hit := RectangleShape2D.new()
	hit.size = size * HIT_SHARE
	$Hitbox/CollisionShape2D.shape = hit
	$Hitbox/CollisionShape2D.position.y = -size.y * 0.4


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_laugh_left -= delta
	if _laugh_left <= 0.0:
		_laugh_left = randf_range(LAUGH_EVERY.x, LAUGH_EVERY.y)
		Audio.play("lucifer_laugh", -6.0, 0.1)


func _on_health_changed(current: int, maximum: int) -> void:
	var was := _enraged
	super._on_health_changed(current, maximum)
	if _enraged and not was:
		Audio.play("lucifer_roar", 2.0)


func _attack(kind: String) -> void:
	if not WINDUP_COLORS_LUCIFER.has(kind):
		await super._attack(kind)
		return
	var net := NetEnemies.active(get_tree())
	if net != null and net.is_host():
		net.broadcast_attack(self, kind)
	_busy = true
	Audio.play("lucifer_roar", -4.0, 0.15)
	var flash := create_tween()
	flash.tween_property(_visual, "modulate", WINDUP_COLORS_LUCIFER[kind], LUCIFER_WINDUP * (0.75 if _enraged else 1.0))
	await flash.finished
	_visual.modulate = Color.WHITE
	if not is_physics_processing() or not is_instance_valid(_player):
		_busy = false
		return
	match kind:
		"hellfire": await _hellfire()
		"souls": await _souls()
		"chains": await _chains()
		"pillars": await _pillars()
		"abyss": await _abyss()
		"summon": _legion()
	_busy = false
	_attack_left = randf_range(ATTACK_INTERVAL.x, ATTACK_INTERVAL.y) * (ENRAGE_INTERVAL if _enraged else 1.0)


## A kezei magassága (innen jönnek a lövések).
func _hands() -> Vector2:
	return global_position + Vector2(0, -110)


## Pokoltűz: meteorok záporoznak körülötted, egy mindig oda, ahol éppen állsz.
func _hellfire() -> void:
	Audio.play("lucifer_cast", 0.0, 0.1)
	for i in METEORS:
		if not is_physics_processing() or not is_instance_valid(_player):
			return
		var at := _player.global_position
		if i % 3 != 0:
			at += Vector2.from_angle(randf() * TAU) * randf_range(50.0, METEOR_SPREAD)
		var marker := TargetMarker.new()
		marker.radius = METEOR_RADIUS
		marker.color = Color(1.0, 0.4, 0.1)
		marker.time = METEOR_FUSE
		get_parent().add_child(marker)
		marker.global_position = at
		marker.landed.connect(_meteor_hit.bind(at))
		await get_tree().create_timer(METEOR_DELAY, false).timeout


func _meteor_hit(at: Vector2) -> void:
	if not is_inside_tree():
		return
	Audio.play("lucifer_meteor", -6.0, 0.2)
	var flame := GateBoss.FlameBurst.new()
	flame.position = get_parent().to_local(at)
	get_parent().add_child(flame)
	var ring := Shockwave.new()
	ring.radius = METEOR_RADIUS
	ring.position = get_parent().to_local(at)
	get_parent().add_child(ring)
	_burst(get_parent().to_local(at), METEOR_RADIUS, roundi(stats["damage"] * METEOR_SHARE), 340.0)


## Lelkek: háromkarú, forgó spirál vörös lövedékekből.
func _souls() -> void:
	Audio.play("lucifer_souls", 0.0)
	var start := randf() * TAU
	var side := 1.0 if randf() < 0.5 else -1.0
	for shot in SOUL_SHOTS:
		if not is_physics_processing():
			return
		for arm in SOUL_ARMS:
			var bolt = MAGIC_BOLT.instantiate()
			bolt.direction = Vector2.from_angle(start + side * shot * SOUL_TURN + TAU * arm / SOUL_ARMS)
			bolt.speed = SOUL_SPEED
			bolt.damage = roundi(stats["damage"] * SOUL_SHARE)
			bolt.modulate = Color(2.2, 0.25, 0.3)
			bolt.set_meta("source", self)
			get_parent().add_child(bolt)
			bolt.global_position = _hands()
		await get_tree().create_timer(SOUL_DELAY, false).timeout


## Láncok: három lánc legyezőben, előbb kirajzolódik a vonaluk, aztán végigcsapódnak.
func _chains() -> void:
	var start := global_position + Vector2(0, -60)
	var aim := start.direction_to(_player.global_position)
	for angle: float in CHAIN_FAN:
		var lash := GateBoss.ChainLash.new()
		lash.length = CHAIN_LENGTH
		lash.warn = CHAIN_WARN
		lash.rotation = aim.angle() + angle
		get_parent().add_child(lash)
		lash.global_position = start
	Audio.play("gate_chain", -4.0, 0.2)
	await get_tree().create_timer(CHAIN_WARN, false).timeout
	if not is_physics_processing():
		return
	Audio.play("gate_chain", 4.0, 0.1)
	for angle: float in CHAIN_FAN:
		var dir := aim.rotated(angle)
		for i in int(CHAIN_LENGTH / CHAIN_STEP):
			_burst(get_parent().to_local(start + dir * CHAIN_STEP * (i + 1)), CHAIN_RADIUS,
				roundi(stats["damage"] * CHAIN_SHARE), 440.0)
	await get_tree().create_timer(0.3, false).timeout


## Tűzoszlopok: nyolc irányba futnak ki belőle, lépésenként felcsapó lángokkal.
func _pillars() -> void:
	Audio.play("lucifer_cast", 2.0, 0.1)
	var start := global_position
	var twist := randf() * TAU
	for step in PILLAR_STEPS:
		if not is_physics_processing():
			return
		for ray in PILLAR_RAYS:
			var at := start + Vector2.from_angle(twist + TAU * ray / PILLAR_RAYS) * PILLAR_STEP * (step + 1)
			var flame := GateBoss.FlameBurst.new()
			flame.position = get_parent().to_local(at)
			get_parent().add_child(flame)
			_burst(get_parent().to_local(at), PILLAR_RADIUS, roundi(stats["damage"] * PILLAR_SHARE), 300.0)
		if step % 2 == 0:
			Audio.play("lucifer_meteor", -10.0, 0.3)
		await get_tree().create_timer(PILLAR_DELAY, false).timeout


## Örvény: a lábad alatt megnyílik a mélység, magába húz, aztán felrobban.
func _abyss() -> void:
	var center := _player.global_position
	Audio.play("lucifer_abyss", 2.0)
	var vortex := AbyssVortex.new()
	vortex.radius = ABYSS_RADIUS
	vortex.time = ABYSS_TIME
	get_parent().add_child(vortex)
	vortex.global_position = center
	var left := ABYSS_TIME
	while left > 0.0:
		if not is_physics_processing():
			return
		if is_instance_valid(_player) and not net_puppet and _player.global_position.distance_to(center) > 8.0:
			_player.set("_knockback", _player.global_position.direction_to(center) * ABYSS_PULL)
		await get_tree().physics_frame
		left -= get_physics_process_delta_time()
	Audio.play("lucifer_meteor", 4.0)
	var ring := Shockwave.new()
	ring.radius = ABYSS_RADIUS
	ring.position = get_parent().to_local(center)
	get_parent().add_child(ring)
	_burst(get_parent().to_local(center), ABYSS_RADIUS, roundi(stats["damage"] * ABYSS_SHARE), 520.0)


## Légió: démonokat hív a pokol mélyéről (ha még nincs túl sok a teremben).
func _legion() -> void:
	Audio.play("lucifer_laugh", 2.0)
	var alive := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy != self and enemy.get("_type") is Dictionary and enemy.get("_type").get("name") == LUCIFER["minion"]:
			alive += 1
	if alive >= LEGION_LIMIT:
		return
	var room := get_parent().get_parent()
	if room.has_method("summon_minions"):
		room.call("summon_minions", LUCIFER["minion"], mini(LEGION, LEGION_LIMIT - alive), global_position)


## Rövid ideig élő, kör alakú sebző terület (a játékost sebzi).
func _burst(at: Vector2, radius: float, damage: int, push: float) -> void:
	var area := Hitbox.new()
	area.damage = damage
	area.knockback = push
	area.collision_layer = 16
	area.collision_mask = 0
	area.set_meta("source", self)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	area.add_child(shape)
	area.position = at
	get_parent().add_child(area)
	get_tree().create_timer(0.18, false).timeout.connect(area.queue_free)


func _on_died() -> void:
	Audio.play("lucifer_die", 2.0)
	Audio.play("lucifer_meteor", 0.0)
	super._on_died()


## A mélység örvénye: forgó, sötét spirál a padlón, ami a robbanás előtt egyre fényesebb.
class AbyssVortex:
	extends Node2D
	var radius := 115.0
	var time := 1.5
	var _t := 0.0

	func _ready() -> void:
		z_index = -2

	func _process(delta: float) -> void:
		_t += delta
		if _t >= time + 0.1:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := clampf(_t / time, 0.0, 1.0)
		var squash := Vector2(1.0, 0.6)
		var points := PackedVector2Array()
		for i in 32:
			points.append(Vector2.from_angle(TAU * i / 32.0) * radius * squash)
		draw_colored_polygon(points, Color(0.08, 0.0, 0.06, 0.55 + 0.3 * k))
		for arm in 4:
			var spiral := PackedVector2Array()
			for j in 14:
				var r := radius * (1.0 - j / 14.0)
				var angle := -_t * 5.0 + arm * TAU / 4.0 + j * 0.35
				spiral.append(Vector2.from_angle(angle) * r * squash)
			draw_polyline(spiral, Color(0.85, 0.15 + 0.5 * k, 0.6, 0.7), 2.5)
		draw_set_transform(Vector2.ZERO, 0.0, squash)
		draw_arc(Vector2.ZERO, radius * 0.98, 0.0, TAU, 40, Color(1.0, 0.3, 0.2, 0.5 + 0.5 * k), 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
