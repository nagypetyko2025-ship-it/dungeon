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

var value := 1
## Közös játék (lásd NetEnemies): a gazda adja ki az azonosítót; a vendégnél csak a gazdától jött
## felvehető létezik (`net_spawned`), a saját helyben esett példányok eltűnnek.
var net_id := 0
var net_spawned := false

var _player: Node2D
var _velocity := Vector2.ZERO
var _attracted := false
var _ready_to_collect := false
var _bob_phase := randf() * TAU
var _retry_left := 0.0

@onready var _visual: Node2D = get_child(0)


func _ready() -> void:
	var net := NetEnemies.active(get_tree())
	if net != null and net.is_client_mode() and not net_spawned:
		queue_free()
		return
	if net_spawned:
		# A gazdától jött: már a végső helyén van.
		_ready_to_collect = true
		return
	# Kipattanás véletlen irányba.
	var target := position + Vector2.from_angle(randf() * TAU) * randf_range(16, 44)
	if net != null and net.is_host():
		net.register_pickup(self, get_parent().to_global(target))
	var tween := create_tween()
	tween.tween_property(self, "position", target, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: _ready_to_collect = true)


func _physics_process(delta: float) -> void:
	_bob_phase += delta * 4.0
	_visual.position.y = -8.0 + sin(_bob_phase) * 2.0
	if not _ready_to_collect:
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	if _retry_left > 0.0:
		_retry_left -= delta
		return
	var to_player := _player.global_position + PLAYER_CENTER - global_position
	if to_player.length() < PICKUP_RANGE:
		if _collect(_player):
			var net := NetEnemies.active(get_tree())
			if net != null and net_id != 0:
				net.pickup_taken(self)
			queue_free()
		else:
			# Nem fér el (pl. tele a táska): a földön marad, később újra próbálja.
			_attracted = false
			_velocity = Vector2.ZERO
			_retry_left = RETRY_DELAY
		return
	if _attracted or to_player.length() < MAGNET_RANGE:
		_attracted = true
		_velocity = _velocity.move_toward(to_player.normalized() * MAX_SPEED, ACCELERATION * delta)
		global_position += _velocity * delta


## Felülírandó: mit ad a tárgy a játékosnak. Hamis, ha most nem lehet felvenni.
func _collect(_player_node: Node2D) -> bool:
	return true
