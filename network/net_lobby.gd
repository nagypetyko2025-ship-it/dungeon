class_name NetLobby
extends Node
## A többjátékos váró és kapcsolat (egyetlen példány a SceneTree gyökerén: /root/NetLobby, hogy
## jelenetváltáskor is megmaradjon, és az RPC-k minden gépen ugyanazon az úton érjék el).
##
## Gazda: create(név) – először 1 mp-ig figyeli a hálózaton hirdetett várókat (hogy a kódja ne
## egyezzen egyikkel sem), aztán elindítja a szervert, és másodpercenként bejelenti a kódját.
## Vendég: join(név, kód) – figyeli a bejelentéseket, és a megfelelő kódú várohoz csatlakozik.
## A vendégek "készen állnak"; a gazda indít (start), ekkor mindenki a saját táborába kerül.
## Játék közben a táborban a játékosok a helyzetüket küldik egymásnak (send_pose, lásd NetAvatars).

signal lobby_changed
## Hiba (nem talált várót, megtelt, megszakadt...): a szöveg magyarul.
signal failed(reason: String)
## A kapcsolat véget ért (a gazda kilépett vagy kidobott).
signal closed(reason: String)
signal pose_received(id: int, data: Dictionary)
signal player_left(id: int)

const BEACON_TAG := "DUNGEON1"
const SCAN_FOR_CODES := 1.0
const JOIN_TIMEOUT := 6.0
const BEACON_INTERVAL := 1.0
const GAME_SCENE := "res://world/camp.tscn"

## "idle" | "preparing" (a gazda kódot keres) | "searching" (a vendég a várót keresi) |
## "connecting" | "lobby" | "playing"
var state := "idle"
var code := ""
var my_name := ""
## Peer id -> {"name": String, "character": String, "ready": bool}
var players := {}

var _listener: PacketPeerUDP
var _beacon: PacketPeerUDP
var _timer := 0.0
var _taken_codes: Array = []
var _wanted_code := ""
## A SceneTree hálózati kezelője: a létrehozáskor kapja meg, így akkor is használható, ha a csomópont
## még nincs a fában (a főmenü építése közben csak késleltetve lehet a gyökérhez adni).
var _mp: MultiplayerAPI


## Az egyetlen példány (már a fába kerülése előtt is, lásd get_or_create).
static var _instance: NetLobby


static func get_or_create(tree: SceneTree) -> NetLobby:
	var existing := current(tree)
	if existing != null:
		return existing
	var lobby := NetLobby.new()
	lobby.name = "NetLobby"
	lobby._connect_network(tree.get_multiplayer())
	# Indításkor a gyökér épp a főmenüt építi: ilyenkor csak késleltetve lehet hozzáadni.
	tree.root.add_child.call_deferred(lobby)
	_instance = lobby
	return lobby


static func current(_tree: SceneTree) -> NetLobby:
	return _instance if is_instance_valid(_instance) else null


## Fut-e közös játék (a táborban ilyenkor látszanak a többiek).
static func is_playing(tree: SceneTree) -> bool:
	var lobby := current(tree)
	return lobby != null and lobby.state == "playing"


func _connect_network(api: MultiplayerAPI) -> void:
	_mp = api
	process_mode = Node.PROCESS_MODE_ALWAYS
	_mp.peer_connected.connect(_on_peer_connected)
	_mp.peer_disconnected.connect(_on_peer_disconnected)
	_mp.connected_to_server.connect(_on_connected)
	_mp.connection_failed.connect(func() -> void: _fail("Nem sikerült csatlakozni a váróhoz."))
	_mp.server_disconnected.connect(func() -> void: _close("A gazda bezárta a várót."))


func is_host() -> bool:
	return state != "idle" and _mp.multiplayer_peer != null and _mp.is_server()


func my_id() -> int:
	return _mp.get_unique_id()


# ---------------------------------------------------------------- váró készítése / csatlakozás

func create(player_name: String) -> void:
	leave()
	my_name = player_name
	state = "preparing"
	_taken_codes = []
	_timer = SCAN_FOR_CODES
	# Ha ezen a gépen már valaki figyel (pl. egy csatlakozó), a kódellenőrzés kimarad.
	_listener = PacketPeerUDP.new()
	if _listener.bind(NetSession.BEACON_PORT) != OK:
		_listener = null
		_timer = 0.0
	lobby_changed.emit()


func _open_lobby() -> void:
	_stop_listening()
	code = NetSession.new_code(_taken_codes)
	var peer := ENetMultiplayerPeer.new()
	if peer.create_server(NetSession.GAME_PORT, NetSession.MAX_PLAYERS - 1) != OK:
		_fail("Nem sikerült elindítani a várót (fut már egy váró ezen a gépen?).")
		return
	_mp.multiplayer_peer = peer
	players = {1: {"name": my_name, "character": Progress.character, "ready": true}}
	state = "lobby"
	_beacon = PacketPeerUDP.new()
	_beacon.set_broadcast_enabled(true)
	_timer = 0.0
	lobby_changed.emit()


func join(player_name: String, wanted_code: String) -> void:
	leave()
	my_name = player_name
	_wanted_code = wanted_code
	_listener = PacketPeerUDP.new()
	if _listener.bind(NetSession.BEACON_PORT) != OK:
		_listener = null
		_fail("Nem sikerült figyelni a hálózatot (fut már egy csatlakozó ezen a gépen?).")
		return
	state = "searching"
	_timer = JOIN_TIMEOUT
	lobby_changed.emit()


func _connect_to(address: String, port: int) -> void:
	_stop_listening()
	var peer := ENetMultiplayerPeer.new()
	if peer.create_client(address, port) != OK:
		_fail("Nem sikerült csatlakozni a váróhoz.")
		return
	_mp.multiplayer_peer = peer
	state = "connecting"
	_timer = JOIN_TIMEOUT
	lobby_changed.emit()


## Kilépés a váróból / a közös játékból (vissza egyjátékosba).
func leave() -> void:
	_stop_listening()
	_beacon = null
	if _mp.multiplayer_peer != null and not (_mp.multiplayer_peer is OfflineMultiplayerPeer):
		_mp.multiplayer_peer.close()
	_mp.multiplayer_peer = OfflineMultiplayerPeer.new()
	state = "idle"
	code = ""
	players = {}
	lobby_changed.emit()


func _stop_listening() -> void:
	if _listener != null:
		_listener.close()
		_listener = null


func _fail(reason: String) -> void:
	leave()
	failed.emit(reason)


func _close(reason: String) -> void:
	var was_playing := state == "playing"
	leave()
	closed.emit(reason)
	if not was_playing:
		failed.emit(reason)


# ---------------------------------------------------------------- hirdetés és keresés

func _process(delta: float) -> void:
	match state:
		"preparing":
			_read_beacons()
			_timer -= delta
			if _timer <= 0.0:
				_open_lobby()
		"searching":
			_read_beacons()
			_timer -= delta
			if state == "searching" and _timer <= 0.0:
				_fail("Nem található váró ezzel a kóddal ezen a hálózaton.")
		"connecting":
			_timer -= delta
			if _timer <= 0.0:
				_fail("Nem sikerült csatlakozni a váróhoz (lejárt az idő).")
		"lobby":
			if is_host():
				_timer -= delta
				if _timer <= 0.0:
					_timer = BEACON_INTERVAL
					_announce()


## A váró bejelentése: üzenetszórás a helyi hálózatra, és a saját gépre is (ha ott fut a vendég).
func _announce() -> void:
	if _beacon == null:
		return
	var message := "%s|%s|%d|%d|%d" % [BEACON_TAG, code, NetSession.GAME_PORT, players.size(), NetSession.MAX_PLAYERS]
	for address in ["255.255.255.255", "127.0.0.1"]:
		_beacon.set_dest_address(address, NetSession.BEACON_PORT)
		_beacon.put_packet(message.to_utf8_buffer())


func _read_beacons() -> void:
	if _listener == null:
		return
	while _listener.get_available_packet_count() > 0:
		var parts := _listener.get_packet().get_string_from_utf8().split("|")
		var address := _listener.get_packet_ip()
		if parts.size() < 5 or parts[0] != BEACON_TAG:
			continue
		if state == "preparing":
			if not _taken_codes.has(parts[1]):
				_taken_codes.append(parts[1])
		elif state == "searching" and parts[1] == _wanted_code:
			if int(parts[3]) >= int(parts[4]):
				_fail("A váró megtelt (legfeljebb %d játékos)." % NetSession.MAX_PLAYERS)
			else:
				_connect_to(address, int(parts[2]))
			return


# ---------------------------------------------------------------- játékosok

func _on_connected() -> void:
	_register.rpc_id(1, my_name, Progress.character)


func _on_peer_connected(_id: int) -> void:
	pass


func _on_peer_disconnected(id: int) -> void:
	player_left.emit(id)
	if is_host() and players.has(id):
		players.erase(id)
		_sync.rpc(players)


@rpc("any_peer", "call_remote", "reliable")
func _register(player_name: String, character: String) -> void:
	if not is_host():
		return
	var id := _mp.get_remote_sender_id()
	if state != "lobby" or players.size() >= NetSession.MAX_PLAYERS:
		_rejected.rpc_id(id, "A váró megtelt, vagy már elindult a játék.")
		return
	players[id] = {"name": NetSession.clean_name(player_name), "character": character, "ready": false}
	_sync.rpc(players)


@rpc("authority", "call_local", "reliable")
func _sync(list: Dictionary) -> void:
	players = list
	if state == "connecting":
		state = "lobby"
	lobby_changed.emit()


@rpc("authority", "call_remote", "reliable")
func _rejected(reason: String) -> void:
	_fail(reason)


## Vendég: készen áll-e (a gazda mindenkinek elküldi).
func set_ready(value: bool) -> void:
	if state == "lobby" and not is_host():
		_set_ready.rpc_id(1, value)


@rpc("any_peer", "call_remote", "reliable")
func _set_ready(value: bool) -> void:
	var id := _mp.get_remote_sender_id()
	if is_host() and players.has(id):
		players[id]["ready"] = value
		_sync.rpc(players)


func everyone_ready() -> bool:
	for id: int in players:
		if not players[id]["ready"]:
			return false
	return true


## Gazda: indítás (ha mindenki készen áll): mindenki a saját táborába kerül.
func start() -> void:
	if is_host() and state == "lobby" and everyone_ready():
		_beacon = null
		_start.rpc()


@rpc("authority", "call_local", "reliable")
func _start() -> void:
	state = "playing"
	lobby_changed.emit()
	Progress.load_game(true)
	GameState.reset()
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE)


# ---------------------------------------------------------------- a táborban

## A saját helyzet elküldése a többieknek (gyakran, megbízhatatlan csatornán).
func send_pose(data: Dictionary) -> void:
	if state == "playing":
		_pose.rpc(data)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _pose(data: Dictionary) -> void:
	pose_received.emit(_mp.get_remote_sender_id(), data)


func player_name(id: int) -> String:
	return str(players.get(id, {}).get("name", "???"))
