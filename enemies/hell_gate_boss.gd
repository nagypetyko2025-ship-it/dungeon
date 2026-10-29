extends "res://enemies/boss.gd"
## A Pokolkapu Őre: a 80. emelet nagy főellensége (a 20. Vérfarkas, a 40. Káosz Ura, a 60. Ősgépezet után).
## Háromfejű, láncra vert pokolkutya, ő őrzi a lejáratot a démonok mélyébe. Nincs második fázisa
## (nem dühödik fel), de huszonötmillió élete van; mindhárom fejének saját támadása van:
##   tűz      a középső fej lángcsóvája, ami lassan végigsöpör a termen
##   méreg    az alsó fej mérgező köpetei: oda csapódnak, ahol állsz, és tócsát hagynak
##   árnyék   a felső fej sötét gömbjei, amik lassan követnek, és szétrobbannak, ha utolérnek
##   lánc     a lánca végigcsapódik egy vonalon feléd (a vonal előbb kirajzolódik)
##   láva     a padló felhasad körülötted, és egy pillanattal később tűz tör fel belőle
##   falka    felvonyít, és pokolkutyákat hív
## Közben a sima főellenség rohama is megvan. Néha ugat; a zenéje csak ebben a harcban szól (Audio "gate").

const GATE := {
	"name": "A Pokolkapu Őre", "rect": Rect2(0, 0, 52, 36), "scale": 3.0,
	"health": 25000000, "damage": 200, "speed": 115.0, "xp": 9000,
	"attacks": ["fire", "chain", "spit", "shadow", "lava", "charge", "summon", "fire", "chain", "lava"],
	"minion": "hell_hound",
}
const SHEET := "res://assets/enemies/gate_hound.png"
const HIT_SHARE := Vector2(0.7, 0.5)
const WINDUP_COLORS_GATE := {
	"fire": Color(2.6, 1.3, 0.4), "spit": Color(1.0, 2.4, 0.6), "shadow": Color(1.6, 0.7, 2.6),
	"chain": Color(2.0, 2.0, 2.0), "lava": Color(2.6, 0.8, 0.3), "summon": Color(2.2, 0.6, 0.6),
}
const GATE_WINDUP := 0.6
## Lángcsóva: lángnyelvek száma, ív, időtartam.
const FIRE_BOLTS := 26
const FIRE_ARC := 1.8
const FIRE_TIME := 1.5
const FIRE_SHARE := 0.45
## Méregköpet: köpetek, közük, mikor csapódnak be, sugár.
const SPITS := 3
const SPIT_DELAY := 0.35
const SPIT_FUSE := 0.8
const SPIT_RADIUS := 46.0
const SPIT_SHARE := 0.6
## Árnyékgömbök: darab, sebesség, élettartam, robbanás sugara.
const ORBS := 4
const ORB_SPEED := 95.0
const ORB_LIFE := 4.5
const ORB_RADIUS := 40.0
const ORB_SHARE := 0.7
## Láncrántás: hossza, figyelmeztetés ideje, a sebző pontok közti távolság és sugaruk.
const CHAIN_LENGTH := 520.0
const CHAIN_WARN := 0.7
const CHAIN_STEP := 40.0
const CHAIN_RADIUS := 34.0
const CHAIN_SHARE := 0.9
## Lávarepedések: darab, mekkora körben, mikor törnek fel, sugár.
const CRACKS := 9
const CRACK_SPREAD := 230.0
const CRACK_FUSE := 0.9
const CRACK_RADIUS := 48.0
const CRACK_SHARE := 0.75
## Falka: ennyi pokolkutya jön egyszerre, és legfeljebb ennyi lehet élve a teremben.
const PACK := 2
const PACK_LIMIT := 4
## Ugatás járás közben.
const BARK_EVERY := Vector2(4.0, 7.0)

var _bark_left := 3.0


## A Pokolkapu Őrének beállítása a fába kerülés előtt (a setup_boss helyett).
func setup_gate(depth: int) -> void:
	mini_boss = false
	_def = GATE
	boss_name = GATE["name"]
	music_track = "gate"
	_depth = depth
	_type = {"name": "hell_gate", "rect": GATE["rect"], "sheet": SHEET, "run": true}
	stats = {
		"health": GATE["health"],
		"damage": GATE["damage"],
		"speed": GATE["speed"],
		"dodge": 0,
		"knockback": 480.0,
		"resist": 1.0,
		"xp": GATE["xp"],
		"power": 1.0,
	}


func setup_boss(depth: int, _special := {}) -> void:
	setup_gate(depth)


func _fit_shapes(size: Vector2) -> void:
	super._fit_shapes(size)
	var hit := RectangleShape2D.new()
	hit.size = size * HIT_SHARE
	$Hitbox/CollisionShape2D.shape = hit
	$Hitbox/CollisionShape2D.position.y = -size.y * 0.35


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_bark_left -= delta
	if _bark_left <= 0.0:
		_bark_left = randf_range(BARK_EVERY.x, BARK_EVERY.y)
		Audio.play("gate_bark", -6.0, 0.15)


## Nincs második fázis: nem dühödik fel.
func _on_health_changed(_current: int, _maximum: int) -> void:
	pass


func _attack(kind: String) -> void:
	if not WINDUP_COLORS_GATE.has(kind):
		await super._attack(kind)
		return
	var net := NetEnemies.active(get_tree())
	if net != null and net.is_host():
		net.broadcast_attack(self, kind)
	_busy = true
	Audio.play("gate_bark", -2.0, 0.1)
	var flash := create_tween()
	flash.tween_property(_visual, "modulate", WINDUP_COLORS_GATE[kind], GATE_WINDUP)
	await flash.finished
	_visual.modulate = Color.WHITE
	if not is_physics_processing() or not is_instance_valid(_player):
		_busy = false
		return
	match kind:
		"fire": await _fire()
		"spit": await _spit()
		"shadow": _shadow()
		"chain": await _chain()
		"lava": _lava()
		"summon": _pack()
	_busy = false
	_attack_left = randf_range(ATTACK_INTERVAL.x, ATTACK_INTERVAL.y)


## A fejek magassága a test közepéhez képest (innen jönnek a lövések).
func _mouth() -> Vector2:
	return global_position + Vector2(0, -70)


## Lángcsóva: a tűzfej lassan végigsöpör egy széles íven.
func _fire() -> void:
	Audio.play("gate_fire", 2.0)
	var muzzle := _mouth()
	var aim := muzzle.direction_to(_player.global_position + PLAYER_CENTER)
	var side := 1.0 if randf() < 0.5 else -1.0
	for i in FIRE_BOLTS:
		if not is_physics_processing():
			return
		var bolt = MAGIC_BOLT.instantiate()
		bolt.direction = aim.rotated(side * (-FIRE_ARC / 2.0 + FIRE_ARC * i / (FIRE_BOLTS - 1)))
		bolt.speed = 260.0
		bolt.damage = roundi(stats["damage"] * FIRE_SHARE)
		bolt.modulate = Color(2.4, 1.0, 0.25)
		bolt.set_meta("source", self)
		get_parent().add_child(bolt)
		bolt.global_position = _mouth()
		if i % 9 == 8:
			Audio.play("gate_fire", -4.0, 0.2)
		await get_tree().create_timer(FIRE_TIME / FIRE_BOLTS, false).timeout


## Méregköpet: a méregfej oda köp, ahol állsz; a becsapódás sebez, és mérges tócsát hagy.
func _spit() -> void:
	for i in SPITS:
		if not is_physics_processing() or not is_instance_valid(_player):
			return
		Audio.play("gate_spit", -2.0, 0.2)
		var at := _player.global_position
		var marker := TargetMarker.new()
		marker.radius = SPIT_RADIUS
		marker.color = Color(0.5, 1.0, 0.3)
		marker.time = SPIT_FUSE
		get_parent().add_child(marker)
		marker.global_position = at
		marker.landed.connect(_spit_hit.bind(at))
		await get_tree().create_timer(SPIT_DELAY, false).timeout


func _spit_hit(at: Vector2) -> void:
	if not is_inside_tree():
		return
	Audio.play("gate_spit", -8.0, 0.3)
	var pool := PoisonPool.new()
	pool.radius = SPIT_RADIUS
	pool.time = POOL_TIME
	pool.position = get_parent().to_local(at)
	get_parent().add_child(pool)
	_burst(get_parent().to_local(at), SPIT_RADIUS, roundi(stats["damage"] * SPIT_SHARE), 160.0)


## Árnyékgömbök: lassan követnek, és szétrobbannak, ha utolérnek (vagy ha lejár az idejük).
func _shadow() -> void:
	Audio.play("gate_shadow", 0.0, 0.1)
	for i in ORBS:
		var orb := ShadowOrb.new()
		orb.source = self
		orb.speed = ORB_SPEED * randf_range(0.85, 1.15)
		orb.life = ORB_LIFE
		orb.drift = Vector2.from_angle(TAU * i / ORBS + randf() * 0.5) * 140.0
		get_parent().add_child(orb)
		orb.global_position = _mouth()


## Egy árnyékgömb robbanása (a gömb hívja).
func orb_burst(at: Vector2) -> void:
	if not is_inside_tree():
		return
	Audio.play("gate_shadow", -8.0, 0.3)
	var ring := Shockwave.new()
	ring.radius = ORB_RADIUS
	ring.position = get_parent().to_local(at)
	get_parent().add_child(ring)
	_burst(get_parent().to_local(at), ORB_RADIUS, roundi(stats["damage"] * ORB_SHARE), 260.0)


## Láncrántás: kirajzolódik a vonal, aztán végigcsapódik rajta a lánc.
func _chain() -> void:
	var start := global_position + Vector2(0, -30)
	var dir := start.direction_to(_player.global_position)
	var lash := ChainLash.new()
	lash.length = CHAIN_LENGTH
	lash.warn = CHAIN_WARN
	lash.rotation = dir.angle()
	get_parent().add_child(lash)
	lash.global_position = start
	Audio.play("gate_chain", -6.0, 0.2)
	await get_tree().create_timer(CHAIN_WARN, false).timeout
	if not is_physics_processing():
		return
	Audio.play("gate_chain", 2.0, 0.1)
	var steps := int(CHAIN_LENGTH / CHAIN_STEP)
	for i in steps:
		_burst(get_parent().to_local(start + dir * CHAIN_STEP * (i + 1)), CHAIN_RADIUS,
			roundi(stats["damage"] * CHAIN_SHARE), 420.0)
	await get_tree().create_timer(0.25, false).timeout


## Lávarepedések: a padló felhasad körülötted (egy mindig alattad), és tűz tör fel belőle.
func _lava() -> void:
	Audio.play("gate_lava", -2.0, 0.1)
	for i in CRACKS:
		var at := _player.global_position
		if i > 0:
			at += Vector2.from_angle(randf() * TAU) * randf_range(60.0, CRACK_SPREAD)
		var marker := TargetMarker.new()
		marker.radius = CRACK_RADIUS
		marker.color = Color(1.0, 0.35, 0.1)
		marker.time = CRACK_FUSE + randf() * 0.4
		get_parent().add_child(marker)
		marker.global_position = at
		marker.landed.connect(_lava_hit.bind(at))


func _lava_hit(at: Vector2) -> void:
	if not is_inside_tree():
		return
	Audio.play("gate_fire", -10.0, 0.3)
	var flame := FlameBurst.new()
	flame.position = get_parent().to_local(at)
	get_parent().add_child(flame)
	_burst(get_parent().to_local(at), CRACK_RADIUS, roundi(stats["damage"] * CRACK_SHARE), 300.0)


## Falka: felvonyít, és pokolkutyákat hív (ha még nincs túl sok a teremben).
func _pack() -> void:
	Audio.play("gate_howl", 2.0)
	var alive := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy != self and enemy.get("_type") is Dictionary and enemy.get("_type").get("name") == GATE["minion"]:
			alive += 1
	if alive >= PACK_LIMIT:
		return
	var room := get_parent().get_parent()
	if room.has_method("summon_minions"):
		room.call("summon_minions", GATE["minion"], mini(PACK, PACK_LIMIT - alive), global_position)


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
	Audio.play("gate_die")
	Audio.play("gate_howl", -4.0, 0.1)
	super._on_died()


## Sötét gömb: előbb kifelé sodródik, aztán lassan a játékos felé fordul; ha eléri (vagy lejár), szétrobban.
class ShadowOrb:
	extends Node2D
	var source: Node2D
	var speed := 95.0
	var life := 4.5
	var drift := Vector2.ZERO
	var _t := 0.0

	func _ready() -> void:
		z_index = 3

	func _physics_process(delta: float) -> void:
		_t += delta
		queue_redraw()
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if not is_instance_valid(source) or not source.is_inside_tree():
			queue_free()
			return
		drift = drift.move_toward(Vector2.ZERO, 160.0 * delta)
		var chase := Vector2.ZERO
		if player != null:
			chase = global_position.direction_to(player.global_position + Vector2(0, -16)) * speed
		global_position += (drift + chase) * delta
		if _t >= life or (player != null and global_position.distance_to(player.global_position + Vector2(0, -16)) < 20.0):
			source.call("orb_burst", global_position)
			queue_free()

	func _draw() -> void:
		var pulse := 1.0 + 0.15 * sin(_t * 10.0)
		draw_circle(Vector2.ZERO, 16.0 * pulse, Color(0.35, 0.1, 0.55, 0.35))
		draw_circle(Vector2.ZERO, 10.0 * pulse, Color(0.12, 0.02, 0.2, 0.9))
		draw_circle(Vector2(-2, -2), 3.0, Color(0.8, 0.45, 1.0, 0.9))


## A lánc vonala: előbb vékony, piros figyelmeztető csík, aztán vastag láncszemek, amik elhalványulnak.
class ChainLash:
	extends Node2D
	var length := 520.0
	var warn := 0.7
	var _t := 0.0

	func _ready() -> void:
		z_index = 2

	func _process(delta: float) -> void:
		_t += delta
		if _t >= warn + 0.45:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		if _t < warn:
			var k := _t / warn
			draw_line(Vector2.ZERO, Vector2(length, 0), Color(1, 0.2, 0.1, 0.25 + 0.35 * k), 2.0 + 10.0 * k)
			return
		var alpha := 1.0 - (_t - warn) / 0.45
		var x := 0.0
		var odd := false
		while x < length:
			var link := Rect2(x, -5.0 if odd else -3.0, 14.0, 10.0 if odd else 6.0)
			draw_rect(link, Color(0.45, 0.42, 0.4, alpha))
			draw_rect(link, Color(0.15, 0.12, 0.1, alpha), false, 1.5)
			x += 12.0
			odd = not odd
		draw_line(Vector2.ZERO, Vector2(length, 0), Color(1, 0.55, 0.2, 0.3 * alpha), 22.0)


## Felcsapó láng a lávarepedésből.
class FlameBurst:
	extends Node2D
	var _t := 0.0

	func _ready() -> void:
		z_index = 3

	func _process(delta: float) -> void:
		_t += delta / 0.55
		if _t >= 1.0:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var alpha := 1.0 - _t
		var rise := 70.0 * ease(_t, 0.4)
		draw_circle(Vector2.ZERO, 40.0, Color(1.0, 0.3, 0.05, 0.3 * alpha))
		for i in 7:
			var x := -30.0 + 10.0 * i
			var height := rise * (0.6 + 0.4 * sin(i * 2.3 + _t * 9.0))
			var tongue := PackedVector2Array([Vector2(x - 7, 0), Vector2(x, -height), Vector2(x + 7, 0)])
			draw_colored_polygon(tongue, Color(1.0, 0.45 + 0.1 * (i % 3), 0.1, 0.8 * alpha))
		draw_line(Vector2(-34, 0), Vector2(34, 0), Color(0.15, 0.03, 0.02, alpha), 4.0)
