extends "res://enemies/enemy.gd"
## Főellenség (minden 3. emeleten). Az általános ellenségre épül (sebződés, halál,
## XP), de saját viselkedése van: követi a játékost, és időnként támad:
##   slam    földrengető csapás: felvillan, majd körben mindenkit megsebez
##   charge  roham: felvillan, majd nagy sebességgel nekiront
##   nova    varázslövedék-gyűrű minden irányba
##   summon  segítőket hív
##   blink   eltűnik, és a játékos mellett bukkan fel
##   barrage sorozatlövés: több legyezőnyi lövedék a játékos felé
##   cannon  ágyútűz / kitörés: célkeresztek a játékos körül, kis idő múlva ott robban
##   breath  lehelet: lövedékek söprő legyezőben (balról jobbra) a játékos felé
##   pools   mérgező tócsák a játékos körül (aki belelép, megmérgeződik)
## A 21. emelet után új főellenségek jönnek (saját sprite-lappal, "sheet"; "abilities": a
## találatuk hatása, lásd EnemyAbilities, pl. méreg / fagy / fosztogatás).
## Fél élet alatt feldühödik: gyorsabb és sűrűbben támad.

signal enraged

## A főellenségek emeletenként váltják egymást (3., 6., 9. ... emelet), aztán elölről.
## scale: a kisebb figurákat jobban felnagyítjuk; tint: színezés.
const BOSSES: Array[Dictionary] = [
	{"name": "Ogrekirály", "rect": Rect2(16, 380, 32, 36), "health": 70, "damage": 3, "speed": 70.0,
		"xp": 40, "attacks": ["slam", "charge", "summon"], "minion": "goblin"},
	{"name": "Orkhadúr", "rect": Rect2(368, 177, 16, 23), "scale": 3.2, "tint": Color(0.8, 0.95, 0.75),
		"health": 75, "damage": 3, "speed": 80.0,
		"xp": 50, "attacks": ["charge", "slam", "summon"], "minion": "masked_orc"},
	{"name": "Gyíkkirály", "rect": Rect2(128, 228, 16, 28), "scale": 2.8, "tint": Color(1.0, 0.85, 0.6),
		"health": 80, "damage": 4, "speed": 85.0,
		"xp": 55, "attacks": ["charge", "barrage", "blink"], "minion": "lizard"},
	{"name": "Démonúr", "rect": Rect2(16, 428, 32, 36), "health": 90, "damage": 4, "speed": 75.0,
		"xp": 60, "attacks": ["slam", "nova", "charge"], "minion": "imp"},
	{"name": "Nekromanta-főpap", "rect": Rect2(368, 225, 16, 23), "scale": 3.2, "tint": Color(0.8, 0.75, 1.0),
		"health": 85, "damage": 4, "speed": 60.0,
		"xp": 70, "attacks": ["summon", "nova", "blink", "barrage"], "minion": "skelet"},
	{"name": "Jégóriás", "rect": Rect2(16, 380, 32, 36), "tint": Color(0.6, 0.85, 1.3),
		"health": 100, "damage": 5, "speed": 65.0,
		"xp": 75, "attacks": ["slam", "nova", "barrage"], "minion": "ice_zombie"},
	{"name": "Zombikirály", "rect": Rect2(16, 332, 32, 36), "health": 110, "damage": 4, "speed": 60.0,
		"xp": 80, "attacks": ["slam", "summon", "nova"], "minion": "zombie"},
	# --- A 21. emelet után (24., 27., 30., 33. emelet) ---
	{"name": "Kalózkirály", "sheet": "res://assets/enemies/pirate_captain.png", "rect": Rect2(0, 0, 16, 16),
		"scale": 4.2, "tint": Color(1.1, 0.95, 0.7), "health": 120, "damage": 5, "speed": 85.0,
		"xp": 90, "attacks": ["charge", "cannon", "summon"], "minion": "pirate_grunt", "abilities": ["plunder"],
		"cannon_color": Color(1, 0.6, 0.2)},
	{"name": "Lánggólem", "sheet": "res://assets/enemies/fire_golem.png", "rect": Rect2(0, 0, 32, 32),
		"scale": 2.6, "health": 140, "damage": 6, "speed": 55.0,
		"xp": 100, "attacks": ["slam", "cannon", "nova"], "minion": "imp", "cannon_color": Color(1, 0.35, 0.1)},
	{"name": "A Mélység Szeme", "sheet": "res://assets/enemies/deep_eye.png", "rect": Rect2(0, 0, 16, 16),
		"scale": 5.0, "health": 130, "damage": 6, "speed": 70.0,
		"xp": 110, "attacks": ["blink", "breath", "barrage", "summon"], "minion": "chort", "abilities": ["frost"]},
	{"name": "Nyálkakirály", "sheet": "res://assets/enemies/green_slime.png", "rect": Rect2(0, 0, 16, 16),
		"scale": 5.5, "tint": Color(0.9, 1.1, 0.8), "health": 160, "damage": 6, "speed": 60.0,
		"xp": 120, "attacks": ["slam", "pools", "summon"], "minion": "green_slime", "abilities": ["poison"]},
]
const HEALTH_PER_DEPTH := 0.42
## A főellenségek keménysége (élet / sebzés / XP szorzó), és hogy a Mélység Urának életéből
## legfeljebb mekkora részt érhetnek el.
const TOUGHNESS := 3.0
const TOUGHNESS_DAMAGE := 1.3
const TOUGHNESS_XP := 1.5
const MAX_LORD_SHARE := 0.7
const BOSS_SCALE := 1.8
const ATTACK_INTERVAL := Vector2(2.2, 3.2)
const ENRAGE_SPEED := 1.2
const ENRAGE_INTERVAL := 0.7
## Felvillanás színe támadás előtt (ennyi időd van kitérni).
const WINDUP := {"slam": 0.75, "charge": 0.55, "nova": 0.6, "summon": 0.6, "blink": 0.55, "barrage": 0.6,
	"cannon": 0.6, "breath": 0.65, "pools": 0.55}
const WINDUP_COLORS := {
	"slam": Color(2.4, 0.8, 0.6), "charge": Color(2.2, 1.8, 0.6),
	"nova": Color(1.8, 0.8, 2.4), "summon": Color(0.8, 1.8, 1.0),
	"blink": Color(1.4, 0.6, 2.6), "barrage": Color(2.6, 1.2, 1.6),
	"cannon": Color(2.6, 1.4, 0.5), "breath": Color(1.2, 1.8, 2.8), "pools": Color(0.9, 2.4, 0.7),
}
## A felbukkanás távolsága a játékostól.
const BLINK_DISTANCE := 150.0
## Elhalványuláskor ennyire áttetsző (nem teljesen láthatatlan).
const BLINK_ALPHA := 0.35
const BARRAGE_VOLLEYS := 3
const BARRAGE_SHOTS := 5
const BARRAGE_SPREAD := 0.22
const BARRAGE_DELAY := 0.28
const SLAM_RADIUS := 130.0
const CHARGE_TIME := 0.45
const CHARGE_MULTIPLIER := 4.5
## A kis főellenségek (nem a Mélység Ura) kíméletesebbek: lassabban járnak és rohamoznak, tovább
## villannak a roham előtt, és csak a testük közepe sebez (nem az egész, felnagyított kép).
const MINI_WALK := 0.8
const MINI_CHARGE_TIME := 0.6
const MINI_CHARGE_MULTIPLIER := 2.6
const MINI_CHARGE_WINDUP := 0.9
const MINI_HIT_SHARE := Vector2(0.5, 0.5)
const NOVA_BOLTS := 10
const SUMMON_COUNT := 2
const CANNON_SHOTS := 5
const CANNON_DELAY := 0.9
const CANNON_RADIUS := 52.0
const CANNON_SPREAD := 130.0
const BREATH_BOLTS := 14
const BREATH_ARC := 1.4
const BREATH_TIME := 0.9
const POOL_COUNT := 3
const POOL_RADIUS := 46.0
const POOL_TIME := 5.0

var boss_name := ""
## Kis főellenség-e (a vérfarkas felülírja: ő a Mélység Ura, rá nem vonatkozik a kímélet).
var mini_boss := true

var _def: Dictionary = {}
var _attack_left := 2.0
var _busy := false
var _charge_left := 0.0
var _charge_dir := Vector2.ZERO
var _enraged := false


## A főellenség beállítása a fába kerülés előtt.
func setup_boss(depth: int) -> void:
	_def = BOSSES[(maxi(depth / 3, 1) - 1) % BOSSES.size()]
	boss_name = _def["name"]
	_depth = depth
	_type = {"name": "boss", "rect": _def["rect"], "run": true, "tint": _def.get("tint", Color.WHITE),
		"abilities": _def.get("abilities", [])}
	if _def.has("sheet"):
		_type["sheet"] = _def["sheet"]
	stats = {
		"health": roundi(_def["health"] * (1.0 + HEALTH_PER_DEPTH * (depth - 1))),
		"damage": _def["damage"] + floori((depth - 1) * 0.6),
		"speed": _def["speed"],
		"dodge": 0,
		"knockback": 380.0,
		"resist": 1.0,
		"xp": roundi(_def["xp"] * (1.0 + 0.2 * (depth - 1))),
		"power": 1.0,
	}
	# A 10. emelettől a főellenségek is hirtelen erősebbek (mint a szörnyek, lásd EnemyTypes).
	for i in EnemyTypes.surges(depth):
		stats["health"] = roundi(stats["health"] * EnemyTypes.SURGE_HEALTH)
		stats["damage"] = roundi(stats["damage"] * EnemyTypes.SURGE_DAMAGE)
		stats["xp"] = roundi(stats["xp"] * EnemyTypes.SURGE_XP)
	# Keményebb főellenségek: TOUGHNESS-szeres élet, nagyobb sebzés és több XP, de a Mélység Ura
	# (a nagy boss) szintjét nem érik el: az élet legfeljebb a vérfarkasénak MAX_LORD_SHARE része,
	# a sebzés kisebb az övénél. (Ami eleve erősebb ennél, azt nem gyengíti.)
	var lord: Dictionary = preload("res://enemies/werewolf_boss.gd").WEREWOLF
	var health_cap := roundi(float(lord["health"]) * MAX_LORD_SHARE)
	stats["health"] = maxi(stats["health"], mini(roundi(stats["health"] * TOUGHNESS), health_cap))
	stats["damage"] = maxi(stats["damage"], mini(roundi(stats["damage"] * TOUGHNESS_DAMAGE), int(lord["damage"]) - 3))
	stats["xp"] = roundi(stats["xp"] * TOUGHNESS_XP)


## A kis főellenségnek csak a teste közepe sebez (a kép alsó-középső része).
func _fit_shapes(size: Vector2) -> void:
	super._fit_shapes(size)
	if not mini_boss:
		return
	var hit := RectangleShape2D.new()
	hit.size = size * MINI_HIT_SHARE
	$Hitbox/CollisionShape2D.shape = hit
	$Hitbox/CollisionShape2D.position.y = -size.y * 0.4


func _compute_size_scale() -> float:
	var boss_scale: float = _def.get("scale", BOSS_SCALE)
	return boss_scale


func _ready() -> void:
	super._ready()
	_health.changed.connect(_on_health_changed)
	_attack_left = randf_range(1.5, 2.5)


func _physics_process(delta: float) -> void:
	if net_puppet:
		_puppet_process(delta)
		return
	_pick_target(delta)
	if not is_instance_valid(_player):
		return
	var dir := Vector2.ZERO
	if _charge_left > 0.0:
		_charge_left -= delta
		dir = _charge_dir * (MINI_CHARGE_MULTIPLIER if mini_boss else CHARGE_MULTIPLIER)
	elif not _busy:
		dir = global_position.direction_to(_player.global_position)
		_attack_left -= delta
		if _attack_left <= 0.0:
			_attack(_def["attacks"].pick_random())
	var speed: float = stats["speed"] * (ENRAGE_SPEED if _enraged else 1.0) * (MINI_WALK if mini_boss else 1.0)
	velocity = dir * speed
	move_and_slide()
	if dir.x != 0.0:
		_sprite.flip_h = dir.x < 0.0
	_sprite.play("run" if dir != Vector2.ZERO else "idle")


## Felvillanás (ilyenkor áll), aztán a támadás.
func _attack(kind: String) -> void:
	# Közös játékban a gazda szól: a vendégeknél a báb is eljátssza (a saját figurájukra).
	var net := NetEnemies.active(get_tree())
	if net != null and net.is_host():
		net.broadcast_attack(self, kind)
	_busy = true
	var windup: float = MINI_CHARGE_WINDUP if mini_boss and kind == "charge" else WINDUP[kind]
	var flash := create_tween()
	flash.tween_property(_visual, "modulate", WINDUP_COLORS[kind], windup)
	await flash.finished
	_visual.modulate = Color.WHITE
	if not is_physics_processing():
		return
	match kind:
		"slam": _slam()
		"charge":
			_charge_dir = global_position.direction_to(_player.global_position)
			_charge_left = MINI_CHARGE_TIME if mini_boss else CHARGE_TIME
		"nova": _nova()
		"summon": _summon()
		"blink": _blink()
		"barrage": await _barrage()
		"cannon": _cannon()
		"breath": await _breath()
		"pools": _pools()
	_busy = false
	var interval := randf_range(ATTACK_INTERVAL.x, ATTACK_INTERVAL.y)
	_attack_left = interval * (ENRAGE_INTERVAL if _enraged else 1.0)


## Földrengető csapás: táguló gyűrű, ami a kör belsejében sebez.
func _slam() -> void:
	Audio.play("boss_slam")
	var ring := Shockwave.new()
	ring.radius = SLAM_RADIUS
	ring.position = position
	get_parent().add_child(ring)
	var area := Hitbox.new()
	area.damage = stats["damage"] + 1
	area.knockback = 420.0
	area.collision_layer = 16
	area.collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = SLAM_RADIUS
	shape.shape = circle
	area.add_child(shape)
	area.position = position
	get_parent().add_child(area)
	get_tree().create_timer(0.2, false).timeout.connect(area.queue_free)


func _nova() -> void:
	Audio.play("magic")
	for i in NOVA_BOLTS:
		var bolt = MAGIC_BOLT.instantiate()
		bolt.direction = Vector2.from_angle(TAU * i / NOVA_BOLTS + randf() * 0.2)
		bolt.speed = 210.0
		bolt.damage = stats["damage"]
		get_parent().add_child(bolt)
		bolt.global_position = global_position + Vector2(0, -40)


## Elhalványul (áttetsző lesz, de nem tűnik el teljesen, hogy mindig látni és ütni lehessen), és a
## játékos egyik oldalán bukkan fel (szabad helyen).
func _blink() -> void:
	Audio.play("magic")
	var target := _player.global_position + Vector2.from_angle(randf() * TAU) * BLINK_DISTANCE
	var room := get_parent().get_parent()
	if room.has_method("safe_spawn_position"):
		target = room.call("safe_spawn_position", target)
	var fade := create_tween()
	fade.tween_property(_visual, "modulate:a", BLINK_ALPHA, 0.12)
	await fade.finished
	# A báb nem ugrik el magától: a gazda szörnyének új helye úgyis megjön (különben visszarántódna).
	if not net_puppet:
		global_position = target
	create_tween().tween_property(_visual, "modulate:a", 1.0, 0.18)


## Néhány legyezőnyi lövedék gyors egymásutánban, mindig a játékos felé.
func _barrage() -> void:
	for volley in BARRAGE_VOLLEYS:
		if not is_physics_processing() or not is_instance_valid(_player):
			return
		Audio.play("magic", -4.0)
		var muzzle := global_position + Vector2(0, -40)
		var aim := muzzle.direction_to(_player.global_position + PLAYER_CENTER)
		for i in BARRAGE_SHOTS:
			var bolt = MAGIC_BOLT.instantiate()
			bolt.direction = aim.rotated((i - (BARRAGE_SHOTS - 1) / 2.0) * BARRAGE_SPREAD)
			bolt.speed = 240.0
			bolt.damage = stats["damage"]
			get_parent().add_child(bolt)
			bolt.global_position = muzzle
		await get_tree().create_timer(BARRAGE_DELAY, false).timeout


## Ágyútűz / kitörés: célkeresztek a játékos körül (egy pont mindig rajta), CANNON_DELAY mp
## múlva mindegyik helyén robbanás, ami CANNON_RADIUS-on belül sebez.
func _cannon() -> void:
	Audio.play("boss_roar", -8.0, 0.2)
	var color: Color = _def.get("cannon_color", Color(1, 0.5, 0.2))
	for i in CANNON_SHOTS:
		var at := _player.global_position
		if i > 0:
			at += Vector2.from_angle(randf() * TAU) * randf_range(40.0, CANNON_SPREAD)
		var marker := TargetMarker.new()
		marker.radius = CANNON_RADIUS
		marker.color = color
		marker.time = CANNON_DELAY
		marker.position = get_parent().to_local(at)
		get_parent().add_child(marker)
		marker.landed.connect(_cannon_blast.bind(marker.position))


func _cannon_blast(at: Vector2) -> void:
	if not is_inside_tree() or not is_physics_processing():
		return
	Audio.play("boss_slam", -6.0, 0.2)
	var ring := Shockwave.new()
	ring.radius = CANNON_RADIUS
	ring.position = at
	get_parent().add_child(ring)
	var area := Hitbox.new()
	area.damage = stats["damage"]
	area.knockback = 300.0
	area.collision_layer = 16
	area.collision_mask = 0
	area.set_meta("source", self)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = CANNON_RADIUS
	shape.shape = circle
	area.add_child(shape)
	area.position = at
	get_parent().add_child(area)
	get_tree().create_timer(0.15, false).timeout.connect(area.queue_free)


## Lehelet: lövedékek söprő legyezőben, BREATH_TIME alatt balról jobbra a játékos felé.
func _breath() -> void:
	Audio.play("magic", -2.0)
	var muzzle := global_position + Vector2(0, -40)
	var aim := muzzle.direction_to(_player.global_position + PLAYER_CENTER)
	for i in BREATH_BOLTS:
		if not is_physics_processing():
			return
		var bolt = MAGIC_BOLT.instantiate()
		bolt.direction = aim.rotated(-BREATH_ARC / 2.0 + BREATH_ARC * i / (BREATH_BOLTS - 1))
		bolt.speed = 230.0
		bolt.damage = stats["damage"]
		bolt.set_meta("source", self)
		get_parent().add_child(bolt)
		bolt.global_position = muzzle
		await get_tree().create_timer(BREATH_TIME / BREATH_BOLTS, false).timeout


## Mérgező tócsák a játékos körül (egy mindig alatta): aki benne áll, megmérgeződik.
func _pools() -> void:
	Audio.play("magic", -6.0, 0.3)
	for i in POOL_COUNT:
		var at := _player.global_position
		if i > 0:
			at += Vector2.from_angle(TAU * i / POOL_COUNT + randf()) * randf_range(70.0, 130.0)
		var pool := PoisonPool.new()
		pool.radius = POOL_RADIUS
		pool.time = POOL_TIME
		pool.position = get_parent().to_local(at)
		get_parent().add_child(pool)


func _summon() -> void:
	Audio.play("boss_roar", -4.0)
	var room := get_parent().get_parent()
	if room.has_method("summon_minions"):
		room.call("summon_minions", _def["minion"], SUMMON_COUNT, global_position)


func _on_health_changed(current: int, maximum: int) -> void:
	if not _enraged and current > 0 and current <= maximum / 2:
		_enraged = true
		enraged.emit()
		FloatingText.spawn(get_parent(), _head_position(), "Feldühödött!", Color(1, 0.3, 0.2), 22)


## A főellenséget nem lehet ellökni és nem kábul el.
func _on_hurt(hitbox: Hitbox) -> void:
	super._on_hurt(hitbox)
	_knockback = Vector2.ZERO
	_stun_left = 0.0


func _on_died() -> void:
	Audio.play("boss_defeated")
	super._on_died()


## Táguló, halványuló gyűrű a csapás jelzésére.
class Shockwave:
	extends Node2D
	var radius := 120.0
	var _t := 0.0

	func _ready() -> void:
		z_index = -3

	func _process(delta: float) -> void:
		_t += delta / 0.35
		if _t >= 1.0:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var r := radius * ease(_t, 0.4)
		var alpha := 1.0 - _t
		draw_circle(Vector2.ZERO, r, Color(1, 0.45, 0.2, 0.18 * alpha))
		draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(1, 0.75, 0.4, alpha), 4.0)


## Célkereszt a földön (ágyútűz / kitörés): összehúzódó kör, a végén "landed".
class TargetMarker:
	extends Node2D
	signal landed
	var radius := 50.0
	var color := Color(1, 0.5, 0.2)
	var time := 0.9
	var _t := 0.0

	func _ready() -> void:
		z_index = -3

	func _process(delta: float) -> void:
		_t += delta
		if _t >= time:
			landed.emit()
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := _t / time
		draw_circle(Vector2.ZERO, radius, Color(color, 0.12 + 0.18 * k))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 40, Color(color, 0.9), 2.0)
		draw_arc(Vector2.ZERO, radius * (1.0 - k), 0, TAU, 40, Color(color, 0.9), 3.0)


## Mérgező tócsa: amíg a játékos benne áll, félmásodpercenként megmérgeződik.
class PoisonPool:
	extends Node2D
	var radius := 46.0
	var time := 5.0
	var _t := 0.0
	var _tick := 0.0

	func _ready() -> void:
		z_index = -4

	func _process(delta: float) -> void:
		_t += delta
		if _t >= time:
			queue_free()
			return
		_tick -= delta
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if _tick <= 0.0 and player and player.global_position.distance_to(global_position) < radius:
			_tick = 0.5
			player.call("apply_poison", 2.0)
		queue_redraw()

	func _draw() -> void:
		var fade := clampf((time - _t) / 0.6, 0.0, 1.0) * clampf(_t / 0.3, 0.0, 1.0)
		var points := PackedVector2Array()
		for i in 20:
			var angle := TAU * i / 20.0
			points.append(Vector2.from_angle(angle) * radius * Vector2(1.0, 0.6) * (0.9 + 0.1 * sin(angle * 5.0 + _t * 3.0)))
		draw_colored_polygon(points, Color(0.35, 0.8, 0.2, 0.45 * fade))
		draw_circle(Vector2(radius * 0.3 * sin(_t * 2.0), -4), 3.0, Color(0.7, 1, 0.5, 0.7 * fade))
