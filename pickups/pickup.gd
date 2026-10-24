class_name Pickup
extends Node2D
## Felvehető tárgy (XP-gömb, érme). Kipattan, lebeg, és ha a játékos
## közel ér, felé repül; érintéskor `_collect()` hívódik.

const MAGNET_RANGE := 120.0
const PICKUP_RANGE := 18.0
const MAX_SPEED := 480.0
const ACCELERATION := 1600.0
## A játékos középpontja (a lába fölött).
const PLAYER_CENTER := Vector2(0, -20)
## Ha nem sikerült felvenni, ennyi idő múlva próbálja újra.
const RETRY_DELAY := 2.0
const POP_TIME := 0.25
## Közös játék: ennyi időnként nézi meg, ki a legközelebbi élő játékos.
const RETARGET_INTERVAL := 0.2
## Közös játék: ha egy társnál ennyi ideig nem kérte senki (pl. tele a táskája), elengedi.
const AVATAR_HOLD := 1.5
## Közös játék: ha a gazda ennyi ideig nem válaszol a kérésre, újra látszik (és újra próbálja).
const CLAIM_TIMEOUT := 1.0

var value := 1
## Közös játék (lásd NetEnemies): a gazda adja ki az azonosítót; a vendégnél csak a gazdától jött
## felvehető létezik (`net_spawned`), a saját helyben esett példányok eltűnnek.
var net_id := 0
var net_spawned := false
## A gazdától jött felvehető: honnan hová pattan (globális hely), hogy mindenkinél ugyanúgy mozogjon.
var net_from := Vector2.ZERO
var net_to := Vector2.ZERO

var _player: Node2D
var _velocity := Vector2.ZERO
var _attracted := false
var _ready_to_collect := false
var _bob_phase := randf() * TAU
var _retry_left := 0.0
var _retarget_left := 0.0
var _hold_left := AVATAR_HOLD
var _claim_left := 0.0

@onready var _visual: Node2D = get_child(0)


func _ready() -> void:
	var net := NetEnemies.active(get_tree())
	if net != null and net.is_client_mode() and not net_spawned:
		queue_free()
		return
	if net_spawned:
		# A gazdától jött: ugyanonnan ugyanoda pattan, mint nála.
		global_position = net_from
		_pop_to(get_parent().to_local(net_to))
		return
	# Kipattanás véletlen irányba.
	var target := position + Vector2.from_angle(randf() * TAU) * randf_range(16, 44)
	if net != null and net.is_host():
		net.register_pickup(self, global_position, get_parent().to_global(target))
	_pop_to(target)


func _pop_to(target: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(self, "position", target, POP_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: _ready_to_collect = true)


func _physics_process(delta: float) -> void:
	_bob_phase += delta * 4.0
	_visual.position.y = -8.0 + sin(_bob_phase) * 2.0
	if not _ready_to_collect:
		return
	var net := NetEnemies.active(get_tree())
	var shared := net != null and net.shares_pickups() and net_id != 0
	if _claim_left > 0.0:
		# A gazdától kértük; a válasza (taken) eltünteti. Ha nem jön, újra látszik.
		_claim_left -= delta
		if _claim_left <= 0.0:
			visible = true
			_retry_left = RETRY_DELAY
		return
	_retarget_left -= delta
	if _retarget_left <= 0.0 or not _is_target(_player):
		_retarget_left = RETARGET_INTERVAL
		var previous := _player.get_instance_id() if is_instance_valid(_player) else 0
		_player = _nearest_player(shared)
		if _player == null or _player.get_instance_id() != previous:
			_hold_left = AVATAR_HOLD
	if _player == null:
		return
	if _retry_left > 0.0:
		_retry_left -= delta
		return
	var to_player := _player.global_position + PLAYER_CENTER - global_position
	if to_player.length() < PICKUP_RANGE:
		if not _player.is_in_group("player"):
			# Egy társnál van: ő kéri a gazdától. Ha sokáig nem kéri (tele a táskája), elengedi.
			_hold_left -= delta
			global_position += to_player * minf(1.0, delta * 10.0)
			if _hold_left <= 0.0:
				_drop_attraction()
			return
		if shared:
			if can_collect(_player):
				# A gazda dönti el, ki kapja (ha ketten érnek hozzá, csak az egyik).
				_claim_left = CLAIM_TIMEOUT
				visible = false
				net.claim_pickup(self)
			else:
				_drop_attraction()
			return
		if _collect(_player):
			queue_free()
		else:
			_drop_attraction()
		return
	if _attracted or to_player.length() < MAGNET_RANGE:
		_attracted = true
		_velocity = _velocity.move_toward(to_player.normalized() * MAX_SPEED, ACCELERATION * delta)
		global_position += _velocity * delta


## Nem fér el (pl. tele a táska): a földön marad, később újra próbálja.
func _drop_attraction() -> void:
	_attracted = false
	_velocity = Vector2.ZERO
	_retry_left = RETRY_DELAY
	_hold_left = AVATAR_HOLD


## Élő játékos-e még (a halott néző kikerül a "player" csoportból, a társ figurája a "net_avatar"-ból).
## (Variant, mert lehet már felszabadított is: a társ figurája eltűnhet.)
func _is_target(node: Variant) -> bool:
	if not is_instance_valid(node):
		return false
	var target := node as Node2D
	return target != null and target.is_inside_tree() \
		and (target.is_in_group("player") or target.is_in_group("net_avatar"))


## A legközelebbi élő játékos; közös játékban a társak figurája is (mindenkinél ugyanarra repül).
func _nearest_player(shared: bool) -> Node2D:
	var candidates := get_tree().get_nodes_in_group("player")
	if shared:
		candidates += get_tree().get_nodes_in_group("net_avatar")
	var best: Node2D = null
	var best_distance := INF
	for node in candidates:
		var candidate := node as Node2D
		if candidate == null or not candidate.is_inside_tree():
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best


## Felülírandó: most felvehető-e (pl. van-e hely a táskában).
func can_collect(_player_node: Node2D) -> bool:
	return true


## Felülírandó: mit ad a tárgy a játékosnak. Hamis, ha most nem lehet felvenni.
func _collect(_player_node: Node2D) -> bool:
	return true
