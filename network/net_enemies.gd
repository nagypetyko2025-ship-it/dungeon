class_name NetEnemies
extends Node
## Közös játékban a kazamata szörnyei (a Dungeon adja hozzá). A gazda a "főnök": nála élnek
## az igazi szörnyek (mozgás, életerő, halál, képességek), és a legközelebbi játékost üldözik
## (a többiek figuráját is, lásd nearest_target). A vendégeknél ugyanezek "bábként" jelennek meg:
##   - a gazda minden új szörnyet kihirdet (spawn), a vendég a saját szobájába rakja a bábot;
##   - a gazda 20-szor másodpercenként elküldi a helyüket, sebességüket és életerejüket (snapshot),
##     a báb ebből simán követi (NetSmooth);
##   - ha a vendég megüt egy bábot, a sebzést a gazda vonja le (report_damage);
##   - a gazdánál meghalt szörny (már a halála pillanatában) a vendégnél is meghal;
##   - a vendég szobába lépését a gazda kapja meg (request_room), ő indítja a harcot.
## A bábok érintése és lövése a vendéget a saját gépén sebzi (a saját figurájára céloznak).
## Felvehetők (XP-gömb, érme, tárgy): a gazda dobja ki, mindenkinél ugyanonnan ugyanoda pattannak, és
## a legközelebbi élő játékos felé repülnek. Hogy ki kapja meg, azt a GAZDA dönti el (claim → taken),
## így két játékos sosem veheti fel ugyanazt. A felvett XP-t mindenki megkapja.
## Ha a gazda nincs ugyanazon az emeleten (pl. kilépett, vagy a táborba ment), a vendégnél a bábok
## önállóak lesznek, és onnantól a vendég saját szörnyekkel játszik (local_mode).
## A menük a játékot megállítják, de a szörnyek ilyenkor is mennek (PROCESS_MODE_ALWAYS).
## Minden üzenet első argumentuma az emelet kulcsa (key); a NetLobby a más emeletre szólókat
## megőrzi, amíg az az emelet be nem töltődik.

const SNAPSHOT_INTERVAL := 0.05
## Egy szörny a pillanatképben: azonosító, x, y, sebesség x, y, (animáció + 1) * 2 + tükrözés, életerő.
const SNAPSHOT_STRIDE := 7
## Az animációk a pillanatképben sorszámmal mennek (ami nincs a listán, az nem változik).
const ANIMATIONS := ["idle", "run", "wake", "dormant"]
## Ennyi ideig nem hallunk a gazdától ezen az emeleten: a vendég önállóan folytatja (az első hír előtt
## hosszabb, mert a gazdánál lassabban is töltődhet be az emelet). Bőven hagyunk időt: wifin pár
## másodperces kiesés is előfordul, és az önálló mód végleges (onnan külön folyik a játék).
const HOST_TIMEOUT := 12.0
const HOST_FIRST_TIMEOUT := 20.0
## A gazda már a táborban van (a pózából tudjuk): ennyi idő után önállóan folytatjuk.
const HOST_AWAY_TIMEOUT := 1.5
const RETARGET_INTERVAL := 0.5
## Ha nézőként már egy társ sem él ennyi ideig, jön a halálképernyő (mindenki a táborba).
const ALL_DEAD_DELAY := 1.5
const ARROW := preload("res://enemies/arrow.tscn")
const MAGIC_BOLT := preload("res://enemies/magic_bolt.tscn")
## A felvehetők fajtái (a hálózaton sorszámmal).
const PICKUP_SCENES := ["res://pickups/xp_orb.tscn", "res://pickups/coin.tscn", "res://pickups/item_drop.tscn"]
const KIND_XP := 0
const KIND_COIN := 1
const KIND_ITEM := 2
## Csak a gazdától elfogadott üzenetek (a vendégek csak kérhetnek).
const FROM_HOST_ONLY := ["spawn", "gone", "attack", "pickups", "taken", "shot"]
const TO_HOST_ONLY := ["room", "damage", "plunder", "claim", "respawn_item"]

var local_mode := false

var _lobby: NetLobby
var _rooms: Node2D
## Szörny-azonosító -> szörny (a gazdánál az igaziak, a vendégnél a bábok).
var _by_id := {}
var _next_id := 1
var _send_left := 0.0
var _silence := 0.0
var _heard_host := false
var _host_away := 0.0
## Felvehető-azonosító -> felvehető (XP-gömb, érme, tárgy).
var _pickups := {}
## Gazda: a most kidobott felvehetők, egy üzenetben mennek ki (a következő üzenet előtt mindenképp).
var _new_pickups: Array = []
## A már kinyitott ládák helye (ha a láda nálunk még meg sem jelent, amikor a hír jött).
var _opened_chests := {}
## A gazdánál: a már kihirdetett halálok (hogy egy szörny csak egyszer haljon meg).
var _gone := {}
var _closing := false
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
	if is_host():
		var player := _local_player()
		_lobby.start_team_gold(key(), int(player.get("gold")) if player != null else 0)
	# A más emeletre szóló, megőrzött üzenetek közül ami ide szól, most jön meg.
	_lobby.attach_handler(self)


func _exit_tree() -> void:
	_closing = true


func is_host() -> bool:
	return _lobby != null and _lobby.is_host()


## A vendég (nem önálló módban): a szörnyeket a gazda adja, saját maga nem spawnol.
func is_client_mode() -> bool:
	return not is_host() and not local_mode


## Közösek-e a felvehetők (a gazda dönti el, ki kapja meg).
func shares_pickups() -> bool:
	return _lobby != null and _lobby.state == "playing" and not local_mode


## Melyik emelet (a közös maggal): csak az azonos kulcsú üzenetek számítanak.
func key() -> String:
	return "%d:%d" % [GameState.depth, GameState.net_seed]


func _process(delta: float) -> void:
	if _lobby == null:
		return
	if _lobby.state != "playing":
		# A kapcsolat megszakadt: innen mindenki egyedül játszik tovább.
		if not local_mode:
			_go_local()
		return
	_watch_team(delta)
	if is_host():
		_flush_pickups()
		# Hozzáadva (nem visszaállítva) számol, hogy a valódi ütem tényleg 20/mp legyen.
		_send_left -= delta
		if _send_left <= 0.0:
			_send_left = maxf(_send_left + SNAPSHOT_INTERVAL, 0.0)
			_send_snapshot()
	elif not local_mode:
		_silence += delta
		var avatars := _avatars()
		_host_away = _host_away + delta if avatars != null and avatars.last_where(1) == "camp" else 0.0
		if _silence > (HOST_TIMEOUT if _heard_host else HOST_FIRST_TIMEOUT) or _host_away > HOST_AWAY_TIMEOUT:
			_go_local()


func _heard() -> void:
	_silence = 0.0
	_heard_host = true


## Üzenet küldése; előtte kimegy minden még ki nem hirdetett felvehető, hogy a sorrend megmaradjon
## (különben pl. a felvétel híre megelőzhetné magát a gömböt).
func _send(kind: String, args: Array, to_host := false) -> void:
	if is_host():
		_flush_pickups()
	_lobby.net_event(kind, args, to_host)


# ---------------------------------------------------------------- gazda

## Egy új szörny a gazdánál (spawn, osztódás, idézés, főellenség): azonosítót kap, és kihirdetjük.
func register(enemy: Node2D, room: Node2D, boss_kind := "") -> void:
	var id := _next_id
	_next_id += 1
	var floor_key := key()
	enemy.set("net_id", id)
	enemy.process_mode = Node.PROCESS_MODE_ALWAYS
	_by_id[id] = enemy
	# A halála pillanatában szólunk (nem a 0,2 mp-es halál-animáció végén), így a vendégnél is
	# akkor hal meg, és a gömbjei már utána jelennek meg. A Vérfarkasnál csak a második halál igazi.
	if boss_kind == "werewolf":
		enemy.connect("final_died", _on_host_enemy_died.bind(id, floor_key))
	else:
		enemy.get_node("Health").died.connect(_on_host_enemy_died.bind(id, floor_key))
	enemy.tree_exiting.connect(_on_host_enemy_exiting.bind(id, floor_key))
	var type: Dictionary = enemy.get("_type")
	_send("spawn", [floor_key, room.get_index(), id, str(type.get("name", "")), enemy.position,
		enemy.get("stats"), boss_kind])


func _on_host_enemy_died(id: int, floor_key: String) -> void:
	if _gone.has(id):
		return
	_gone[id] = true
	_by_id.erase(id)
	_send("gone", [floor_key, id])


## Halál nélkül tűnt el (pl. kikerült a szobából): a vendégnél is eltűnik. A jelenet lebontásakor
## (emeletváltás) nem szólunk: a vendég úgyis maga is lebontja a sajátját.
func _on_host_enemy_exiting(id: int, floor_key: String) -> void:
	_by_id.erase(id)
	if _closing or _gone.has(id) or _lobby == null or _lobby.state != "playing":
		return
	_gone[id] = true
	_send("gone", [floor_key, id])


## Főellenség-támadás: a vendégeknél a báb is eljátssza (a saját figurájukra céloz).
func broadcast_attack(enemy: Node2D, kind: String) -> void:
	var id := int(enemy.get("net_id"))
	if id != 0:
		_send("attack", [key(), id, kind])


func _send_snapshot() -> void:
	var data := PackedFloat32Array()
	for id: int in _by_id.keys():
		var node: Variant = _by_id[id]
		if not is_instance_valid(node):
			_by_id.erase(id)
			continue
		var enemy := node as CharacterBody2D
		if enemy == null or not enemy.is_inside_tree() or not enemy.is_node_ready():
			continue
		var sprite := enemy.get_node("Visual/AnimatedSprite2D") as AnimatedSprite2D
		var health := enemy.get_node("Health") as Health
		var moving := enemy.velocity if enemy.is_physics_processing() else Vector2.ZERO
		var code := (ANIMATIONS.find(str(sprite.animation)) + 1) * 2 + (1 if sprite.flip_h else 0)
		data.append_array(PackedFloat32Array([id, enemy.position.x, enemy.position.y, moving.x, moving.y, code,
			health.current]))
	# Üres is megy: ebből tudja a vendég, hogy a gazda ugyanezen az emeleten van.
	_lobby.net_broadcast_snapshot(key(), data)


## Egy vendég belépett egy szobába: a gazda indítja ott a harcot.
func _on_remote_room(room_index: int, at: Vector2) -> void:
	if room_index >= _rooms.get_child_count():
		return
	var room := _rooms.get_child(room_index)
	if room.has_method("remote_enter"):
		room.call("remote_enter", at)


## A gazda igazi szörnye (vagy null, ha már nincs).
func _host_enemy(id: int) -> Node2D:
	var node: Variant = _by_id.get(id)
	if not is_instance_valid(node):
		_by_id.erase(id)
		return null
	return node as Node2D


# ---------------------------------------------------------------- vendég

## A vendég belépett egy szobába: a gazdától kéri a harcot (igazat ad, ha így lesz).
func request_room(room: Node2D, at: Vector2) -> bool:
	if not is_client_mode():
		return false
	_send("room", [key(), room.get_index(), at], true)
	return true


## A vendég megütött egy bábot: elküldjük a gazdának a sebzést és a lökést (`direct`: égés, tüskék —
## ezektől a gazda szörnye nem torpan meg).
func report_damage(enemy: Node2D, amount: int, push: Vector2, direct := false) -> void:
	var id := int(enemy.get("net_id"))
	if id != 0 and is_client_mode():
		_send("damage", [key(), id, amount, push, direct], true)


## Egy báb (fosztogató) aranyat lopott tőlünk: a gazda igazi szörnye viszi, és halálakor ő ejti el.
func report_plunder(enemy: Node2D, amount: int) -> void:
	var id := int(enemy.get("net_id"))
	if id != 0 and is_client_mode():
		_send("plunder", [key(), id, amount], true)


## A báb (vagy null, ha már nincs).
func _puppet(id: int) -> Node2D:
	var node: Variant = _by_id.get(id)
	if not is_instance_valid(node):
		_by_id.erase(id)
		return null
	return node as Node2D


func _on_spawn(room_index: int, id: int, type_name: String, at: Vector2, stats: Dictionary,
		boss_kind: String) -> void:
	if not is_client_mode() or _by_id.has(id) or room_index >= _rooms.get_child_count():
		return
	var room := _rooms.get_child(room_index)
	var enemy: Node2D = room.call("add_puppet", type_name, at, stats, id, boss_kind)
	if enemy != null:
		enemy.process_mode = Node.PROCESS_MODE_ALWAYS
		_by_id[id] = enemy
		enemy.tree_exiting.connect(func() -> void:
			if _by_id.get(id) == enemy:
				_by_id.erase(id))


func on_snapshot(room_key: String, data: PackedFloat32Array) -> void:
	if room_key != key() or local_mode:
		return
	_heard()
	for i in range(0, data.size() - SNAPSHOT_STRIDE + 1, SNAPSHOT_STRIDE):
		var enemy := _puppet(int(data[i]))
		if enemy == null or not enemy.has_method("net_apply"):
			continue
		var code := int(data[i + 5])
		var animation_index := code / 2 - 1
		var animation: String = ANIMATIONS[animation_index] if animation_index >= 0 and animation_index < ANIMATIONS.size() else ""
		enemy.call("net_apply", Vector2(data[i + 1], data[i + 2]), Vector2(data[i + 3], data[i + 4]),
			code % 2 == 1, animation, int(data[i + 6]))


func _on_gone(id: int) -> void:
	if local_mode:
		return
	var enemy := _puppet(id)
	_by_id.erase(id)
	if enemy != null and enemy.has_method("net_kill"):
		enemy.call("net_kill")


func _on_attack(id: int, kind: String) -> void:
	if local_mode:
		return
	var enemy := _puppet(id)
	# (A még pályára sem került bábbal nem játszatjuk el: a tween és a célzás a fát kéri.)
	if enemy == null or not enemy.is_inside_tree():
		return
	# A Vérfarkas első "halála" (földre rogy, aztán feltámad).
	if kind == "fall":
		if enemy.has_method("net_fall"):
			enemy.call("net_fall")
	elif enemy.has_method("_attack"):
		enemy.call("_attack", kind)


# ---------------------------------------------------------------- felvehetők

func _pickup_kind(pickup: Node2D) -> int:
	return PICKUP_SCENES.find(pickup.scene_file_path)


## Gazda: egy új felvehető (XP-gömb, érme, tárgy) — mindenkinél ugyanonnan ugyanoda pattan.
func register_pickup(pickup: Node2D, from: Vector2, to: Vector2) -> void:
	var kind := _pickup_kind(pickup)
	if kind == -1:
		return
	var id := _next_id
	_next_id += 1
	pickup.set("net_id", id)
	_pickups[id] = pickup
	pickup.tree_exiting.connect(func() -> void:
		if _pickups.get(id) == pickup:
			_pickups.erase(id))
	var item: Variant = pickup.get("item")
	_new_pickups.append([id, kind, from, to, int(pickup.get("value")), item if item is Dictionary else {}])


func _flush_pickups() -> void:
	if _new_pickups.is_empty():
		return
	var batch := _new_pickups
	_new_pickups = []
	_lobby.net_event("pickups", [key(), batch])


func _on_pickups(batch: Array) -> void:
	if not is_client_mode():
		return
	var entities := get_parent().get_node("Entities")
	for entry: Array in batch:
		var id := int(entry[0])
		var kind := int(entry[1])
		if _pickups.has(id) or kind < 0 or kind >= PICKUP_SCENES.size():
			continue
		var pickup: Node2D = (load(PICKUP_SCENES[kind]) as PackedScene).instantiate()
		pickup.set("net_id", id)
		pickup.set("net_spawned", true)
		pickup.set("net_from", entry[2])
		pickup.set("net_to", entry[3])
		pickup.set("value", int(entry[4]))
		if entry[5] is Dictionary and not (entry[5] as Dictionary).is_empty():
			pickup.set("item", entry[5])
		_pickups[id] = pickup
		pickup.tree_exiting.connect(func() -> void:
			if _pickups.get(id) == pickup:
				_pickups.erase(id))
		entities.add_child(pickup)


## A saját játékosunk hozzáért egy közös felvehetőhöz: a gazdától kérjük (a gazda maga azonnal dönt).
func claim_pickup(pickup: Node2D) -> void:
	var id := int(pickup.get("net_id"))
	if is_host():
		_grant(id, _lobby.my_id())
	else:
		_send("claim", [key(), id], true)


## Gazda: a felvehető azé, aki először kérte; mindenkinek kihirdetjük (a többi kérés elkésett).
func _grant(id: int, taker: int) -> void:
	var node: Variant = _pickups.get(id)
	_pickups.erase(id)
	if not is_instance_valid(node):
		return
	var pickup := node as Node2D
	var kind := _pickup_kind(pickup)
	var value := int(pickup.get("value"))
	_send("taken", [key(), id, taker, kind, value])
	_apply_taken(taker, kind, value, pickup)


func _on_taken(id: int, taker: int, kind: int, value: int) -> void:
	var node: Variant = _pickups.get(id)
	_pickups.erase(id)
	_apply_taken(taker, kind, value, node as Node2D if is_instance_valid(node) else null)


## A felvétel hatása nálunk: ha mi vettük fel, megkapjuk; a felvett XP-t mindenki megkapja.
func _apply_taken(taker: int, kind: int, value: int, pickup: Node2D) -> void:
	var player := _local_player()
	var mine := taker == _lobby.my_id()
	if pickup != null:
		if mine and player != null and not pickup.call("_collect", player) and kind == KIND_ITEM:
			# Közben megtelt a táska: a gazda újra kidobja (nem vész el).
			_send("respawn_item", [key(), pickup.get("item"), pickup.global_position], true)
		pickup.queue_free()
	elif mine and player != null:
		match kind:
			KIND_XP: player.call("add_xp", value)
			KIND_COIN: player.call("pick_up_gold", value)
	if not mine and kind == KIND_XP and player != null:
		player.call("add_xp", value)


func _on_respawn_item(item: Dictionary, at: Vector2) -> void:
	if not is_host() or item.is_empty():
		return
	var drop: Node2D = (load(PICKUP_SCENES[KIND_ITEM]) as PackedScene).instantiate()
	drop.set("item", item)
	var entities := get_parent().get_node("Entities")
	drop.position = entities.to_local(at)
	entities.add_child(drop)


# ---------------------------------------------------------------- arany, láda, lövés

## A közös arany változott nálunk (felvétel, vásárlás, fosztogatás): a gazda vezeti az összeget.
func gold_changed(delta: int) -> void:
	if not local_mode:
		_lobby.gold_delta(delta)


## A gazdától jött közös összeg (lásd NetLobby: közös arany).
func set_team_gold(gold: int) -> void:
	var player := _local_player()
	if player != null and not local_mode:
		player.call("set_gold_from_net", gold)


## Valaki kinyitott egy ládát (a helyével azonosítjuk): mindenkinél kinyílik, a tartalmát a gazda adja.
func chest_opened(chest: Node2D) -> void:
	_send("chest", [key(), Vector2i(chest.global_position.round())])


## Láda megjelenésekor: kinyitotta-e már valaki (a hír előbb jött, mint ahogy nálunk megjelent).
func take_opened_chest(chest: Node2D) -> bool:
	return _opened_chests.erase(Vector2i(chest.global_position.round()))


func _on_chest(at: Vector2i) -> void:
	for chest in get_tree().get_nodes_in_group("net_chest"):
		if Vector2i((chest as Node2D).global_position.round()) == at:
			chest.call("open_from_net", is_host())
			return
	_opened_chests[at] = true


## Gazda: egy szörny lőtt — a vendégeknél ugyanez a lövés repül (a saját figurájukat sebzi).
func broadcast_shot(enemy: Node2D, magic: bool, muzzle: Vector2, directions: Array, speed: float, damage: int) -> void:
	_send("shot", [key(), int(enemy.get("net_id")), magic, muzzle, directions, speed, damage])


func _on_shot(id: int, magic: bool, muzzle: Vector2, directions: Array, speed: float, damage: int) -> void:
	if not is_client_mode():
		return
	var enemy := _puppet(id)
	# A báb még nincs a pályán (késleltetve kerül be), vagy már kikerült: a lövés akkor is repül.
	var parent: Node = enemy.get_parent() if enemy != null and enemy.is_inside_tree() else null
	if parent == null:
		parent = get_parent().get_node("Entities")
	for direction: Vector2 in directions:
		var projectile = (MAGIC_BOLT if magic else ARROW).instantiate()
		projectile.direction = direction
		projectile.speed = speed
		projectile.damage = damage
		if enemy != null:
			projectile.set_meta("source", enemy)
		parent.add_child(projectile)
		projectile.global_position = muzzle


## A NetLobby hívja (a kulcs már egyezik).
func on_event(sender: int, kind: String, args: Array) -> void:
	if FROM_HOST_ONLY.has(kind) and sender != 1:
		return
	if TO_HOST_ONLY.has(kind) and not is_host():
		return
	if sender == 1 and not is_host():
		_heard()
	match kind:
		"spawn": _on_spawn(int(args[1]), int(args[2]), str(args[3]), args[4], args[5], str(args[6]))
		"gone": _on_gone(int(args[1]))
		"attack": _on_attack(int(args[1]), str(args[2]))
		"room": _on_remote_room(int(args[1]), args[2])
		"damage":
			var enemy := _host_enemy(int(args[1]))
			if enemy != null and enemy.has_method("net_take_damage"):
				enemy.call("net_take_damage", int(args[2]), args[3], bool(args[4]))
		"plunder":
			var thief := _host_enemy(int(args[1]))
			if thief != null and thief.has_node("Abilities"):
				thief.get_node("Abilities").call("add_stolen", int(args[2]))
		"pickups": _on_pickups(args[1])
		"claim": _grant(int(args[1]), sender)
		"taken": _on_taken(int(args[1]), int(args[2]), int(args[3]), int(args[4]))
		"respawn_item": _on_respawn_item(args[1], args[2])
		"chest": _on_chest(args[1])
		"shot": _on_shot(int(args[1]), bool(args[2]), args[3], args[4], float(args[5]), int(args[6]))


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
		if not me_ready:
			return
		var waiting := avatars.waiting_ids()
		var anyone_waiting := bool(player.get("net_waiting")) or not waiting.is_empty()
		if anyone_waiting and living.keys().all(func(id: int) -> bool: return waiting.has(id)):
			_floor_requested = true
			_lobby.request_floor(GameState.depth + 1)


## A gazda nincs itt: a bábok önálló szörnyek lesznek, és innen a vendég maga spawnol.
func _go_local() -> void:
	local_mode = true
	for id: int in _by_id.keys():
		var node: Variant = _by_id[id]
		if is_instance_valid(node) and (node as Node).has_method("net_go_local"):
			(node as Node).call("net_go_local")
	_by_id.clear()
	# A közös felvehetők innen a mieink (a felvételt már nem kell a gazdától kérni).
	_pickups.clear()
