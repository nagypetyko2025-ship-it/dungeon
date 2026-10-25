class_name NetLobby
extends Node
## A többjátékos váró és kapcsolat (egyetlen példány a SceneTree gyökerén: /root/NetLobby, hogy
## jelenetváltáskor is megmaradjon, és az RPC-k minden gépen ugyanazon az úton érjék el).
##
## Gazda: create(név) – először 1 mp-ig figyeli a hálózaton hirdetett várókat (hogy a kódja ne
## egyezzen egyikkel sem), aztán elindítja a szervert, és másodpercenként bejelenti a kódját és a nevét.
## Vendég: browse(név) – figyeli a bejelentéseket, a talált várók a `games`-ben (games_changed);
## join_game(kód) – csatlakozás a kiválasztotthoz. Kódot nem kell beírni.
## A vendégek "készen állnak"; a gazda indít (start), ekkor mindenki a saját táborába kerül.
## Játék közben a táborban a játékosok a helyzetüket küldik egymásnak (send_pose, lásd NetAvatars).

signal lobby_changed
## Hiba (nem talált várót, megtelt, megszakadt...): a szöveg magyarul.
signal failed(reason: String)
## A kapcsolat véget ért (a gazda kilépett vagy kidobott).
signal closed(reason: String)
signal pose_received(id: int, data: Dictionary)
signal effect_received(id: int, kind: String, args: Array)
## Egy társ (`by_id`) felélesztett minket.
signal revive_requested(by_id: int)
signal player_left(id: int)
## Változott a hálózaton talált várók listája (games).
signal games_changed

const BEACON_TAG := "DUNGEON1"
const SCAN_FOR_CODES := 1.0
const JOIN_TIMEOUT := 6.0
## Ennyi ideig marad a listán egy váró az utolsó bejelentése után (a gazda kilépett / elindította).
const GAME_FORGET_MS := 3500
const BEACON_INTERVAL := 1.0
const GAME_SCENE := "res://world/camp.tscn"

## "idle" | "preparing" (a gazda kódot keres) | "browsing" (a vendég a várókat keresi) |
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
## A hálózaton talált várók: kód -> {"name", "address", "port", "players", "max", "seen" (ms)}.
var games := {}
## Gazda: új közös játék (a többjátékos mentések törlődnek indításkor) vagy a régi folytatása.
var fresh_save := false
## Gazda: a mostani futásban már kihirdetett emeletek (hogy egy lépcső csak egyszer vigyen le).
var _announced := {}
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


## A hálózaton hirdetett várók keresése (amíg a csatlakozó ablak nyitva van). Hamis, ha nem lehet
## figyelni a hálózatot (pl. egy másik csatlakozó már figyel ezen a gépen).
func browse(player_name: String) -> bool:
	leave()
	my_name = player_name
	_listener = PacketPeerUDP.new()
	if _listener.bind(NetSession.BEACON_PORT) != OK:
		_listener = null
		return false
	state = "browsing"
	lobby_changed.emit()
	return true


## Csatlakozás a listáról kiválasztott váróhoz.
func join_game(game_code: String) -> void:
	if state != "browsing" or not games.has(game_code):
		return
	var game: Dictionary = games[game_code]
	if int(game["players"]) >= int(game["max"]):
		_fail("A váró megtelt (legfeljebb %d játékos)." % NetSession.MAX_PLAYERS)
		return
	_connect_to(str(game["address"]), int(game["port"]))


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
	# Vissza a profil saját (egyjátékos) mentésére.
	if Profiles.multiplayer:
		Progress.save_game()
		Profiles.multiplayer = false
		Progress.load_game(true)
	GameState.net_seed = 0
	state = "idle"
	code = ""
	players = {}
	games = {}
	_pending.clear()
	_gold_pending.clear()
	_gold_acked.clear()
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
		"browsing":
			_read_beacons()
			_forget_old_games()
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
	# A név a végén: ha "|" van benne, az olvasó a maradékot összefűzi.
	var message := "%s|%s|%d|%d|%d|%s" % [BEACON_TAG, code, NetSession.GAME_PORT, players.size(), NetSession.MAX_PLAYERS, my_name]
	for address in _beacon_targets():
		_beacon.set_dest_address(address, NetSession.BEACON_PORT)
		_beacon.put_packet(message.to_utf8_buffer())


## Hová megy a bejelentés: az általános üzenetszórás, a saját gép, és minden helyi hálózat saját
## üzenetszórási címe (pl. 192.168.1.255). Az általánosat a Windows csak EGY hálózati kártyán küldi ki
## (a legkisebb metrikájún): ha a gépen van virtuális kártya (VirtualBox, VPN), oda megy, és a wifin
## lévő társak sosem látják a várót — ezért nem lehetett egyes gépeken hostolni.
static func _beacon_targets() -> Array[String]:
	var targets: Array[String] = ["255.255.255.255", "127.0.0.1"]
	for address in IP.get_local_addresses():
		var parts := address.split(".")
		if parts.size() != 4 or address.begins_with("127.") or address.begins_with("169.254."):
			continue
		var directed := "%s.%s.%s.255" % [parts[0], parts[1], parts[2]]
		if not targets.has(directed):
			targets.append(directed)
	return targets


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
		elif state == "browsing":
			_note_game(parts, address)


## Egy bejelentés a listára; jelez, ha új váró, vagy változott a létszáma / neve. (Ugyanaz a váró
## több címről is befuthat, pl. 127.0.0.1 és a helyi IP: a kód azonosítja.)
func _note_game(parts: PackedStringArray, address: String) -> void:
	var game_name := "|".join(parts.slice(5)) if parts.size() > 5 else "?"
	var old: Dictionary = games.get(parts[1], {})
	var changed := old.is_empty() or int(old["players"]) != int(parts[3]) or str(old["name"]) != game_name
	games[parts[1]] = {"name": game_name, "address": old.get("address", address), "port": int(parts[2]),
		"players": int(parts[3]), "max": int(parts[4]), "seen": Time.get_ticks_msec()}
	if changed:
		games_changed.emit()


func _forget_old_games() -> void:
	var now := Time.get_ticks_msec()
	var gone := false
	for game_code: String in games.keys():
		if now - int(games[game_code]["seen"]) > GAME_FORGET_MS:
			games.erase(game_code)
			gone = true
	if gone:
		games_changed.emit()


# ---------------------------------------------------------------- játékosok

func _on_connected() -> void:
	_no_throttle(1)
	_register.rpc_id(1, my_name, Progress.character)


func _on_peer_connected(id: int) -> void:
	if is_host():
		_no_throttle(id)


## Az ENet alapból "fojt": ha egy pillanatra megnő a késés (pl. egy lassabb képkocka), a megbízhatatlan
## csomagok (helyzet, szörny-pillanatkép) egy részét el sem küldi — ettől akadozott a vendégnél minden.
## A helyi hálózaton erre nincs szükség: kikapcsoljuk (lassítás = 0).
func _no_throttle(id: int) -> void:
	var peer := _mp.multiplayer_peer as ENetMultiplayerPeer
	if peer == null:
		return
	var packet_peer := peer.get_peer(id)
	if packet_peer != null:
		packet_peer.throttle_configure(5000, 32, 0)


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


## Gazda: indítás (ha mindenki készen áll): mindenki a saját táborába kerül, a profilja
## többjátékos mentésével (Profiles.multiplayer). `fresh_save`: a gazda új közös játékot kért,
## ilyenkor mindenki tiszta többjátékos mentéssel kezd.
func start() -> void:
	if is_host() and state == "lobby" and everyone_ready():
		_beacon = null
		_start.rpc(fresh_save)


@rpc("authority", "call_local", "reliable")
func _start(fresh: bool) -> void:
	state = "playing"
	lobby_changed.emit()
	Profiles.multiplayer = true
	if fresh:
		Progress.reset_game()
	else:
		Progress.load_game(true)
	GameState.reset()
	GameState.net_seed = 0
	_announced = {}
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE)


# ---------------------------------------------------------------- közös kazamata

## Valaki lemenne a táborból: a gazda sorsol egy közös magot, és mindenki, aki a táborban van,
## együtt megy le vele (a már lent lévők maradnak).
func request_descent(depth: int) -> void:
	if state != "playing":
		return
	if is_host():
		_host_descent(depth)
	else:
		_ask_descent.rpc_id(1, depth)


@rpc("any_peer", "call_remote", "reliable")
func _ask_descent(depth: int) -> void:
	if is_host():
		_host_descent(depth)


func _host_descent(depth: int) -> void:
	_announced = {depth: true}
	_descend.rpc(depth, randi_range(1, 2147483646))


@rpc("authority", "call_local", "reliable")
func _descend(depth: int, run_seed: int) -> void:
	var scene := get_tree().current_scene
	if scene == null or not scene.has_method("enter_dungeon_now"):
		return
	GameState.net_seed = run_seed
	scene.call("enter_dungeon_now", depth)


## Valaki a lépcsőhöz ért: a gazda az egész csapatot leviszi a következő emeletre (egyszer).
func request_floor(depth: int) -> void:
	if state != "playing":
		return
	if is_host():
		_host_floor(depth)
	else:
		_ask_floor.rpc_id(1, depth)


@rpc("any_peer", "call_remote", "reliable")
func _ask_floor(depth: int) -> void:
	if is_host():
		_host_floor(depth)


func _host_floor(depth: int) -> void:
	if _announced.has(depth):
		return
	_announced[depth] = true
	_floor.rpc(depth)


# ---------------------------------------------------------------- közös szörnyek (lásd NetEnemies)

## Ennyi ideig őrizzük meg az épp nem kézbesíthető üzeneteket: emeletváltáskor a másik gép már (vagy
## még) másik emeleten jár, vagy épp töltődik nála a jelenet — ilyenkor régen elvesztek a szörnyek,
## gömbök és ládanyitások. Amint az új emelet szinkronizálója jelentkezik, megkapja őket.
const PENDING_KEEP_MS := 5000
const PENDING_MAX := 400
## Ezek elavulnak, nem érdemes őket megőrizni.
const PENDING_SKIP := ["shot", "attack"]

## A kazamata szinkronizálója (NetEnemies); az RPC-k ide futnak be, mert a NetLobby útvonala
## mindenkinél ugyanaz.
var enemies_handler: Node
## [idő (ms), küldő, fajta, argumentumok] — a még nem kézbesített üzenetek.
var _pending: Array = []


func _handler() -> NetEnemies:
	return enemies_handler as NetEnemies if is_instance_valid(enemies_handler) else null


## Az új emelet szinkronizálója jelentkezik: megkapja a neki szóló, korábban érkezett üzeneteket.
func attach_handler(handler: NetEnemies) -> void:
	enemies_handler = handler
	var now := Time.get_ticks_msec()
	var waiting := _pending
	_pending = []
	for entry: Array in waiting:
		if now - int(entry[0]) <= PENDING_KEEP_MS:
			_deliver(int(entry[1]), str(entry[2]), entry[3])
	_show_gold()


## Közös esemény (szörny megjelenése/halála, felvehető, felvétel, láda, lövés...): mindenkinek, vagy
## `to_host`: csak a gazdának. Az args[0] mindig az emelet kulcsa (NetEnemies.key).
func net_event(kind: String, args: Array, to_host := false) -> void:
	if state != "playing":
		return
	if to_host:
		if is_host():
			_deliver(my_id(), kind, args)
		else:
			_net_event.rpc_id(1, kind, args)
	else:
		_net_event.rpc(kind, args)


@rpc("any_peer", "call_remote", "reliable")
func _net_event(kind: String, args: Array) -> void:
	_deliver(_mp.get_remote_sender_id(), kind, args)


## Kézbesítés a mostani emelet szinkronizálójának; ha most nem ide szól, megőrizzük.
func _deliver(sender: int, kind: String, args: Array) -> void:
	var handler := _handler()
	if handler != null and not args.is_empty() and str(args[0]) == handler.key():
		handler.on_event(sender, kind, args)
		return
	if PENDING_SKIP.has(kind):
		return
	_pending.append([Time.get_ticks_msec(), sender, kind, args])
	if _pending.size() > PENDING_MAX:
		_pending.pop_front()


## A szörnyek helyzete (gyakran, megbízhatatlanul, külön csatornán, hogy a pózok ne nyomják el).
func net_broadcast_snapshot(room_key: String, data: PackedFloat32Array) -> void:
	_net_snapshot.rpc(room_key, data)


@rpc("authority", "call_remote", "unreliable_ordered", 2)
func _net_snapshot(room_key: String, data: PackedFloat32Array) -> void:
	if _handler() != null:
		_handler().on_snapshot(room_key, data)


# ---------------------------------------------------------------- közös arany

## A kazamatában az arany közös. A hiteles összeg a gazdánál van: mindenki csak a változást küldi
## neki (sorszámmal), ő mindenkinek visszaküldi az új összeget és azt, hogy kinek melyik változásáig
## jutott el. A vendég a még vissza nem igazolt saját változásait hozzászámolja, így nem villog,
## és a gépek összege nem tud elcsúszni egymástól (régen csak a változások mentek körbe).
var team_gold := 0
var _gold_key := ""
var _gold_seq := 0
## Vendég: sorszám -> még vissza nem igazolt változás.
var _gold_pending := {}
## Gazda: peer id -> az utolsó beszámított sorszáma.
var _gold_acked := {}


## Gazda, az emelet elején: a saját aranya a közös összeg (mindenki ehhez igazodik).
func start_team_gold(room_key: String, gold: int) -> void:
	if not is_host():
		return
	team_gold = maxi(gold, 0)
	_gold_key = room_key
	_gold_total.rpc(_gold_key, team_gold, _gold_acked)


## Nálunk változott az arany (felvétel, vásárlás, fosztogatás).
func gold_delta(delta: int) -> void:
	if state != "playing" or delta == 0:
		return
	if is_host():
		_apply_gold(my_id(), 0, delta)
		return
	_gold_seq += 1
	_gold_pending[_gold_seq] = delta
	_gold_add.rpc_id(1, _gold_seq, delta)


@rpc("any_peer", "call_remote", "reliable")
func _gold_add(seq: int, delta: int) -> void:
	if is_host():
		_apply_gold(_mp.get_remote_sender_id(), seq, delta)


func _apply_gold(sender: int, seq: int, delta: int) -> void:
	team_gold = maxi(team_gold + delta, 0)
	if sender != my_id():
		_gold_acked[sender] = seq
	_gold_total.rpc(_gold_key, team_gold, _gold_acked)
	_show_gold()


@rpc("authority", "call_remote", "reliable")
func _gold_total(room_key: String, total: int, acked: Dictionary) -> void:
	team_gold = total
	_gold_key = room_key
	var done := int(acked.get(my_id(), 0))
	for seq: int in _gold_pending.keys():
		if seq <= done:
			_gold_pending.erase(seq)
	_show_gold()


## A közös összeg és a még úton lévő saját változásaink.
func shown_gold() -> int:
	var total := team_gold
	for seq: int in _gold_pending:
		total += int(_gold_pending[seq])
	return maxi(total, 0)


func _show_gold() -> void:
	var handler := _handler()
	if handler != null and handler.key() == _gold_key:
		handler.set_team_gold(shown_gold())


@rpc("authority", "call_local", "reliable")
func _floor(depth: int) -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("go_to_floor") and GameState.depth < depth:
		scene.call("go_to_floor", depth)


# ---------------------------------------------------------------- a táborban

## A saját helyzet elküldése a többieknek (gyakran, megbízhatatlanul, a saját csatornáján: régen a
## szörny-pillanatképekkel közös sorban egymást dobták el, ha felcserélődtek).
func send_pose(data: Dictionary) -> void:
	if state == "playing":
		_pose.rpc(data)


@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func _pose(data: Dictionary) -> void:
	pose_received.emit(_mp.get_remote_sender_id(), data)


## A saját támadásunk látszata a többieknek (fegyver, lövedék; lásd NetAvatars.share).
func send_effect(kind: String, args: Array) -> void:
	if state == "playing":
		_effect.rpc(kind, args)


@rpc("any_peer", "call_remote", "reliable")
func _effect(kind: String, args: Array) -> void:
	effect_received.emit(_mp.get_remote_sender_id(), kind, args)


## Felélesztjük az elesett társat (`id`): az ő gépén áll fel (lásd NetAvatars).
func send_revive(id: int) -> void:
	if state == "playing":
		_revive.rpc_id(id)


@rpc("any_peer", "call_remote", "reliable")
func _revive() -> void:
	revive_requested.emit(_mp.get_remote_sender_id())


func player_name(id: int) -> String:
	return str(players.get(id, {}).get("name", "???"))
