class_name NetEnemies
extends Node
## Közös játékban a kazamata szörnyei (a Dungeon adja hozzá). A gazda a "főnök": nála élnek
## az igazi szörnyek (mozgás, életerő, halál, képességek), és a legközelebbi játékost üldözik
## (a többiek figuráját is, lásd nearest_target). A vendégeknél ugyanezek "bábként" jelennek meg:
##   - a gazda minden új szörnyet kihirdet (spawn), a vendég a saját szobájába rakja a bábot;
##   - a gazda gyakran elküldi a helyzetüket és az életerejüket (snapshot), a báb ezt követi;
##   - ha a vendég megüt egy bábot, a sebzést a gazda vonja le (report_damage);
##   - a gazdánál eltűnt szörny a vendégnél is meghal (XP, láda, szobatisztítás mindenkinél);
##   - a vendég szobába lépését a gazda kapja meg (request_room), ő indítja a harcot.
## A bábok érintése és lövése a vendéget a saját gépén sebzi (a saját figurájára céloznak).
## Ha a gazda nincs ugyanazon az emeleten (pl. meghalt), a vendégnél a bábok önállóak lesznek,
## és onnantól a vendég saját szörnyekkel játszik (local_mode).
## A menük a játékot megállítják, de a szörnyek ilyenkor is mennek (PROCESS_MODE_ALWAYS).

const SNAPSHOT_INTERVAL := 0.1
## Ennyi ideig nem hallunk a gazdától ezen az emeleten: a vendég önállóan folytatja.
const HOST_TIMEOUT := 3.0
const RETARGET_INTERVAL := 0.5

var local_mode := false

var _lobby: NetLobby
var _rooms: Node2D
## Szörny-azonosító -> szörny (a gazdánál az igaziak, a vendégnél a bábok).
var _by_id := {}
var _next_id := 1
var _send_left := 0.0
var _silence := 0.0


## Az aktuális kazamata szinkronizálója (ha közös játék van; különben null).
static func active(tree: SceneTree) -> NetEnemies:
	var scene := tree.current_scene
	return scene.get_node_or_null("NetEnemies") as NetEnemies if scene != null else null


## A gazdánál: a legközelebbi játékos (a saját figuránk vagy egy társunké) a megadott ponthoz.
static func nearest_target(tree: SceneTree, from: Vector2) -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	for node in tree.get_nodes_in_group("player") + tree.get_nodes_in_group("net_avatar"):
		var candidate := node as Node2D
		if candidate == null or not candidate.is_inside_tree():
			continue
		var distance := from.distance_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best


func setup(dungeon: Node2D) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rooms = dungeon.get_node("Entities/Rooms")
	_lobby = NetLobby.current(get_tree())
	_lobby.enemies_handler = self


func is_host() -> bool:
	return _lobby != null and _lobby.is_host()


## A vendég (nem önálló módban): a szörnyeket a gazda adja, saját maga nem spawnol.
func is_client_mode() -> bool:
	return not is_host() and not local_mode


## Melyik emelet (a közös maggal): csak az azonos kulcsú üzenetek számítanak.
func key() -> String:
	return "%d:%d" % [GameState.depth, GameState.net_seed]


func _process(delta: float) -> void:
	if _lobby == null or _lobby.state != "playing":
		return
	if is_host():
		_send_left -= delta
		if _send_left <= 0.0:
			_send_left = SNAPSHOT_INTERVAL
			_send_snapshot()
	elif not local_mode:
		_silence += delta
		if _silence > HOST_TIMEOUT:
			_go_local()


# ---------------------------------------------------------------- gazda

## Egy új szörny a gazdánál (spawn, osztódás, idézés, főellenség): azonosítót kap, és kihirdetjük.
func register(enemy: Node2D, room: Node2D, boss_kind := "") -> void:
	var id := _next_id
	_next_id += 1
	enemy.set("net_id", id)
	enemy.process_mode = Node.PROCESS_MODE_ALWAYS
	_by_id[id] = enemy
	enemy.tree_exiting.connect(_on_host_enemy_gone.bind(id))
	var type: Dictionary = enemy.get("_type")
	_lobby.net_broadcast_spawn(key(), room.get_index(), id, str(type.get("name", "")), enemy.position,
		enemy.get("stats"), boss_kind)


func _on_host_enemy_gone(id: int) -> void:
	_by_id.erase(id)
	if _lobby != null and _lobby.state == "playing":
		_lobby.net_broadcast_gone(key(), id)


## Főellenség-támadás: a vendégeknél a báb is eljátssza (a saját figurájukra céloz).
func broadcast_attack(enemy: Node2D, kind: String) -> void:
	var id := int(enemy.get("net_id"))
	if id != 0:
		_lobby.net_broadcast_attack(key(), id, kind)


func _send_snapshot() -> void:
	var data := {}
	for id: int in _by_id:
		var enemy: Node2D = _by_id[id]
		if not is_instance_valid(enemy) or not enemy.is_inside_tree():
			continue
		var sprite := enemy.get_node("Visual/AnimatedSprite2D") as AnimatedSprite2D
		var health := enemy.get_node("Health") as Health
		data[id] = [enemy.position, sprite.flip_h, str(sprite.animation), health.current]
	# Üres is megy: ebből tudja a vendég, hogy a gazda ugyanezen az emeleten van.
	_lobby.net_broadcast_snapshot(key(), data)


## Egy vendég belépett egy szobába: a gazda indítja ott a harcot.
func on_remote_room(room_key: String, room_index: int, at: Vector2) -> void:
	if room_key != key() or room_index >= _rooms.get_child_count():
		return
	var room := _rooms.get_child(room_index)
	if room.has_method("remote_enter"):
		room.call("remote_enter", at)


## Egy vendég megütött egy szörnyet: a gazda vonja le.
func on_remote_damage(room_key: String, id: int, amount: int, push: Vector2) -> void:
	if room_key != key() or not _by_id.has(id):
		return
	var enemy: Node2D = _by_id[id]
	if is_instance_valid(enemy) and enemy.has_method("net_take_damage"):
		enemy.call("net_take_damage", amount, push)


# ---------------------------------------------------------------- vendég

## A vendég belépett egy szobába: a gazdától kéri a harcot (igazat ad, ha így lesz).
func request_room(room: Node2D, at: Vector2) -> bool:
	if not is_client_mode():
		return false
	_lobby.net_request_room(key(), room.get_index(), at)
	return true


## A vendég megütött egy bábot: elküldjük a gazdának a sebzést és a lökést.
func report_damage(enemy: Node2D, amount: int, push: Vector2) -> void:
	var id := int(enemy.get("net_id"))
	if id != 0 and is_client_mode():
		_lobby.net_report_damage(key(), id, amount, push)


func on_spawn(room_key: String, room_index: int, id: int, type_name: String, at: Vector2, stats: Dictionary,
		boss_kind: String) -> void:
	if room_key != key() or not is_client_mode() or _by_id.has(id) or room_index >= _rooms.get_child_count():
		return
	_silence = 0.0
	var room := _rooms.get_child(room_index)
	var enemy: Node2D = room.call("add_puppet", type_name, at, stats, id, boss_kind)
	if enemy != null:
		enemy.process_mode = Node.PROCESS_MODE_ALWAYS
		_by_id[id] = enemy


func on_snapshot(room_key: String, data: Dictionary) -> void:
	if room_key != key() or local_mode:
		return
	_silence = 0.0
	for id: int in data:
		var enemy: Node2D = _by_id.get(id)
		if is_instance_valid(enemy) and enemy.has_method("net_apply"):
			enemy.call("net_apply", data[id])


func on_gone(room_key: String, id: int) -> void:
	if room_key != key() or local_mode:
		return
	var enemy: Node2D = _by_id.get(id)
	_by_id.erase(id)
	if is_instance_valid(enemy) and enemy.has_method("net_kill"):
		enemy.call("net_kill")


func on_attack(room_key: String, id: int, kind: String) -> void:
	if room_key != key() or local_mode:
		return
	var enemy: Node2D = _by_id.get(id)
	if is_instance_valid(enemy) and enemy.has_method("_attack"):
		enemy.call("_attack", kind)


## A gazda nincs itt: a bábok önálló szörnyek lesznek, és innen a vendég maga spawnol.
func _go_local() -> void:
	local_mode = true
	for id: int in _by_id:
		var enemy: Node2D = _by_id[id]
		if is_instance_valid(enemy) and enemy.has_method("net_go_local"):
			enemy.call("net_go_local")
	_by_id.clear()
