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
## Ha nézőként már egy társ sem él ennyi ideig, jön a halálképernyő (mindenki a táborba).
const ALL_DEAD_DELAY := 1.5
const ARROW := preload("res://enemies/arrow.tscn")
const MAGIC_BOLT := preload("res://enemies/magic_bolt.tscn")

var local_mode := false

var _lobby: NetLobby
var _rooms: Node2D
## Szörny-azonosító -> szörny (a gazdánál az igaziak, a vendégnél a bábok).
var _by_id := {}
var _next_id := 1
var _send_left := 0.0
var _silence := 0.0
## Felvehető-azonosító -> felvehető (XP-gömb, érme, tárgy).
var _pickups := {}
var _alone := 0.0
var _floor_requested := false


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
	_watch_team(delta)
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


# ---------------------------------------------------------------- felvehetők, arany, láda, lövés

## Gazda: egy új felvehető (XP-gömb, érme, tárgy) — mindenkinél ugyanott jelenik meg.
func register_pickup(pickup: Node2D, at: Vector2) -> void:
	var id := _next_id
	_next_id += 1
	pickup.set("net_id", id)
	_pickups[id] = pickup
	pickup.tree_exiting.connect(func() -> void: _pickups.erase(id))
	_lobby.net_event("pickup", [key(), id, pickup.scene_file_path, at, pickup.get("value"), pickup.get("item")])


## Valaki felvett egy felvehetőt: a többieknél eltűnik; XP-gömbnél mindenki megkapja az XP-t.
func pickup_taken(pickup: Node2D) -> void:
	_lobby.net_event("taken", [key(), int(pickup.get("net_id")), pickup.scene_file_path, pickup.get("value")])


## A közös arany változott nálunk (felvétel, vásárlás, fosztogatás): a többieknél is.
func gold_changed(delta: int) -> void:
	_lobby.net_event("gold", [key(), delta])


## Valaki kinyitott egy ládát (a helyével azonosítjuk): mindenkinél kinyílik, a tartalmát a gazda adja.
func chest_opened(chest: Node2D) -> void:
	_lobby.net_event("chest", [key(), Vector2i(chest.global_position.round())])


## Gazda: egy szörny lőtt — a vendégeknél ugyanez a lövés repül (a saját figurájukat sebzi).
func broadcast_shot(enemy: Node2D, magic: bool, muzzle: Vector2, directions: Array, speed: float, damage: int) -> void:
	_lobby.net_event("shot", [key(), int(enemy.get("net_id")), magic, muzzle, directions, speed, damage])


func on_event(_sender: int, kind: String, args: Array) -> void:
	if args.is_empty() or str(args[0]) != key():
		return
	match kind:
		"pickup":
			if not is_client_mode() or _pickups.has(int(args[1])):
				return
			var pickup: Node2D = (load(str(args[2])) as PackedScene).instantiate()
			pickup.set("net_id", int(args[1]))
			pickup.set("net_spawned", true)
			pickup.set("value", int(args[4]))
			if args[5] is Dictionary and not (args[5] as Dictionary).is_empty():
				pickup.set("item", args[5])
			var id := int(args[1])
			_pickups[id] = pickup
			pickup.tree_exiting.connect(func() -> void: _pickups.erase(id))
			get_parent().get_node("Entities").add_child(pickup)
			pickup.global_position = args[3]
		"taken":
			var pickup: Node2D = _pickups.get(int(args[1]))
			_pickups.erase(int(args[1]))
			if is_instance_valid(pickup):
				pickup.queue_free()
			# A felvett XP-t mindenki megkapja (a saját XP-bónusza szerint).
			if str(args[2]).ends_with("xp_orb.tscn"):
				var player := _local_player()
				if player != null:
					player.call("add_xp", int(args[3]))
		"gold":
			var player := _local_player()
			if player != null:
				player.call("add_gold_from_net", int(args[1]))
		"chest":
			for chest in get_tree().get_nodes_in_group("net_chest"):
				if Vector2i((chest as Node2D).global_position.round()) == args[1]:
					chest.call("open_from_net", is_host())
		"shot":
			if not is_client_mode():
				return
			var enemy: Node2D = _by_id.get(int(args[1]))
			var parent: Node = enemy.get_parent() if is_instance_valid(enemy) else get_parent().get_node("Entities")
			for direction: Vector2 in args[4]:
				var projectile = (MAGIC_BOLT if args[2] else ARROW).instantiate()
				projectile.direction = direction
				projectile.speed = float(args[5])
				projectile.damage = int(args[6])
				if is_instance_valid(enemy):
					projectile.set_meta("source", enemy)
				parent.add_child(projectile)
				projectile.global_position = args[3]


func _local_player() -> Node2D:
	return get_parent().get_node_or_null("Entities/Player") as Node2D


# ---------------------------------------------------------------- néző mód és a lépcső

func _avatars() -> NetAvatars:
	return get_parent().get_node_or_null("NetAvatars") as NetAvatars


## Néző (meghaltunk): a kamera egy élő társat követ; ha már senki sem él, vége a futásnak.
## Lépcső: ha minden élő játékos ráállt, a gazda viszi tovább a csapatot.
func _watch_team(delta: float) -> void:
	var player := _local_player()
	var avatars := _avatars()
	if player == null or avatars == null:
		return
	var living := avatars.living()
	if bool(player.get("net_dead")):
		if living.is_empty():
			_alone += delta
			if _alone > ALL_DEAD_DELAY:
				_alone = -INF
				player.call("finish_spectating")
		else:
			_alone = 0.0
			var followed: Node2D = living.values()[0]
			player.global_position = player.global_position.lerp(followed.global_position, minf(1.0, delta * 8.0))
	if is_host() and not _floor_requested:
		var me_ready := bool(player.get("net_dead")) or bool(player.get("net_waiting"))
		var anyone_waiting := bool(player.get("net_waiting")) or not avatars.waiting_ids().is_empty()
		if anyone_waiting and me_ready and living.keys().all(func(id: int) -> bool: return avatars.waiting_ids().has(id)):
			_floor_requested = true
			_lobby.request_floor(GameState.depth + 1)


## A gazda nincs itt: a bábok önálló szörnyek lesznek, és innen a vendég maga spawnol.
func _go_local() -> void:
	local_mode = true
	for id: int in _by_id:
		var enemy: Node2D = _by_id[id]
		if is_instance_valid(enemy) and enemy.has_method("net_go_local"):
			enemy.call("net_go_local")
	_by_id.clear()
