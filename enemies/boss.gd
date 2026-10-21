extends "res://enemies/enemy.gd"
## Főellenség (minden 3. emeleten). Az általános ellenségre épül (sebződés, halál,
## XP), de saját viselkedése van: követi a játékost, és időnként támad:
##   slam    földrengető csapás: felvillan, majd körben mindenkit megsebez
##   charge  roham: felvillan, majd nagy sebességgel nekiront
##   nova    varázslövedék-gyűrű minden irányba
##   summon  segítőket hív
##   blink   eltűnik, és a játékos mellett bukkan fel
##   barrage sorozatlövés: több legyezőnyi lövedék a játékos felé
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
]
const HEALTH_PER_DEPTH := 0.42
const BOSS_SCALE := 1.8
const ATTACK_INTERVAL := Vector2(2.2, 3.2)
const ENRAGE_SPEED := 1.2
const ENRAGE_INTERVAL := 0.7
## Felvillanás színe támadás előtt (ennyi időd van kitérni).
const WINDUP := {"slam": 0.75, "charge": 0.55, "nova": 0.6, "summon": 0.6, "blink": 0.55, "barrage": 0.6}
const WINDUP_COLORS := {
	"slam": Color(2.4, 0.8, 0.6), "charge": Color(2.2, 1.8, 0.6),
	"nova": Color(1.8, 0.8, 2.4), "summon": Color(0.8, 1.8, 1.0),
	"blink": Color(1.4, 0.6, 2.6), "barrage": Color(2.6, 1.2, 1.6),
}
## A felbukkanás távolsága a játékostól.
const BLINK_DISTANCE := 150.0
const BARRAGE_VOLLEYS := 3
const BARRAGE_SHOTS := 5
const BARRAGE_SPREAD := 0.22
const BARRAGE_DELAY := 0.28
const SLAM_RADIUS := 130.0
const CHARGE_TIME := 0.45
const CHARGE_MULTIPLIER := 4.5
const NOVA_BOLTS := 10
const SUMMON_COUNT := 2

var boss_name := ""

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
	_type = {"name": "boss", "rect": _def["rect"], "run": true, "tint": _def.get("tint", Color.WHITE)}
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


func _compute_size_scale() -> float:
	var boss_scale: float = _def.get("scale", BOSS_SCALE)
	return boss_scale


func _ready() -> void:
	super._ready()
	_health.changed.connect(_on_health_changed)
	_attack_left = randf_range(1.5, 2.5)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(_player):
		return
	var dir := Vector2.ZERO
	if _charge_left > 0.0:
		_charge_left -= delta
		dir = _charge_dir * CHARGE_MULTIPLIER
	elif not _busy:
		dir = global_position.direction_to(_player.global_position)
		_attack_left -= delta
		if _attack_left <= 0.0:
			_attack(_def["attacks"].pick_random())
	var speed: float = stats["speed"] * (ENRAGE_SPEED if _enraged else 1.0)
	velocity = dir * speed
	move_and_slide()
	if dir.x != 0.0:
		_sprite.flip_h = dir.x < 0.0
	_sprite.play("run" if dir != Vector2.ZERO else "idle")


## Felvillanás (ilyenkor áll), aztán a támadás.
func _attack(kind: String) -> void:
	_busy = true
	var windup: float = WINDUP[kind]
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
			_charge_left = CHARGE_TIME
		"nova": _nova()
		"summon": _summon()
		"blink": _blink()
		"barrage": await _barrage()
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


## Eltűnik, és a játékos egyik oldalán bukkan fel (szabad helyen).
func _blink() -> void:
	Audio.play("magic")
	var target := _player.global_position + Vector2.from_angle(randf() * TAU) * BLINK_DISTANCE
	var room := get_parent().get_parent()
	if room.has_method("safe_spawn_position"):
		target = room.call("safe_spawn_position", target)
	var fade := create_tween()
	fade.tween_property(_visual, "modulate:a", 0.0, 0.12)
	await fade.finished
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
