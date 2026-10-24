class_name NetAvatars
extends Node
## Közös játékban (a táborban és a kazamatában): a saját helyzetünket (hely, irány, animáció,
## karakter, és hogy hol vagyunk) gyakran elküldjük a többieknek, és az ő figuráikat (névvel a fejük
## fölött) megjelenítjük, ha ugyanott vannak (a táborban, vagy a kazamata ugyanazon emeletén).
## Akkor is küld, ha nálunk nyitva van egy menü (a játék ilyenkor áll), így a figuránk nem tűnik el.
## Aki egy ideig nem küld semmit, vagy máshol jár, annak a figurája eltűnik.
## (A tábor és a kazamata adja hozzá, ha fut közös játék: setup(scene).)

signal message(text: String)

const SEND_INTERVAL := 0.07
const STALE_AFTER := 2.0
const FOLLOW := 14.0

var _player: Node2D
var _entities: Node2D
var _lobby: NetLobby
var _send_left := 0.0
## Peer id -> {"node": Node2D, "sprite": AnimatedSprite2D, "target": Vector2, "age": float, "character": String}
var _avatars := {}


func setup(scene: Node2D) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = scene.get_node("Entities/Player")
	_entities = scene.get_node("Entities")
	_lobby = NetLobby.current(scene.get_tree())
	_lobby.pose_received.connect(_on_pose)
	_lobby.player_left.connect(_remove)
	_lobby.closed.connect(func(reason: String) -> void:
		for id: int in _avatars.keys():
			_remove(id)
		message.emit(reason + " Egyedül folytatod."))


func _process(delta: float) -> void:
	if _lobby == null or _lobby.state != "playing" or not is_instance_valid(_player):
		return
	_send_left -= delta
	if _send_left <= 0.0:
		_send_left = SEND_INTERVAL
		var sprite := _player.get_node("Visual/AnimatedSprite2D") as AnimatedSprite2D
		_lobby.send_pose({"p": _player.global_position, "f": sprite.flip_h, "a": str(sprite.animation),
			"c": Progress.character, "w": _where(), "d": bool(_player.get("net_dead")),
			"r": bool(_player.get("net_waiting"))})
	for id: int in _avatars.keys():
		var avatar: Dictionary = _avatars[id]
		avatar["age"] = float(avatar["age"]) + delta
		if float(avatar["age"]) > STALE_AFTER:
			_remove(id)
			continue
		var node: Node2D = avatar["node"]
		var target: Vector2 = avatar["target"]
		# Messzi ugrásnál (pl. belépett egy házba) azonnal ott van, különben simán követi.
		if node.position.distance_to(target) > 200.0:
			node.position = target
		else:
			node.position = node.position.lerp(target, minf(1.0, delta * FOLLOW))


## Hol vagyunk: "camp", vagy a kazamata emelete a közös maggal (csak az azonos helyűek látják egymást).
func _where() -> String:
	if _entities.get_parent().has_method("go_to_floor"):
		return "d%d:%d" % [GameState.depth, GameState.net_seed]
	return "camp"


func _on_pose(id: int, data: Dictionary) -> void:
	if str(data.get("w", "camp")) != _where():
		_remove(id)
		return
	var character := str(data.get("c", Characters.DEFAULT))
	if not _avatars.has(id) or _avatars[id]["character"] != character:
		_remove(id)
		_avatars[id] = _create(id, character, data.get("p", Vector2.ZERO))
	var avatar: Dictionary = _avatars[id]
	avatar["target"] = data.get("p", Vector2.ZERO)
	avatar["age"] = 0.0
	# Halott társ (néző): nem látszik, és a szörnyek sem üldözik; a lépcsőn várakozónál "(vár)".
	var dead := bool(data.get("d", false))
	var waiting := bool(data.get("r", false))
	avatar["dead"] = dead
	avatar["waiting"] = waiting
	var node: Node2D = avatar["node"]
	node.visible = not dead
	if dead or waiting:
		node.remove_from_group("net_avatar")
	elif not node.is_in_group("net_avatar"):
		node.add_to_group("net_avatar")
	var label: Label = avatar["label"]
	label.text = _lobby.player_name(id) + ("  (vár)" if waiting else "")
	var sprite: AnimatedSprite2D = avatar["sprite"]
	sprite.flip_h = bool(data.get("f", false))
	var animation := str(data.get("a", "idle"))
	if sprite.sprite_frames.has_animation(animation) and sprite.animation != animation:
		sprite.play(animation)


func _create(id: int, character: String, at: Vector2) -> Dictionary:
	var node := Node2D.new()
	node.position = at
	# A gazda szörnyei őt is üldözhetik (NetEnemies.nearest_target).
	node.add_to_group("net_avatar")
	_entities.add_child(node)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = Characters.frames(character)
	sprite.scale = Vector2(2, 2)
	sprite.offset = Vector2(0, -12)
	sprite.play("idle")
	node.add_child(sprite)
	var label := UiStyle.label(_lobby.player_name(id), 14, Color(0.75, 0.9, 1.0))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.add_child(label)
	label.position = Vector2(-label.get_combined_minimum_size().x / 2.0, -78)
	if not _avatars.has(id):
		message.emit("%s itt van veled." % _lobby.player_name(id))
	return {"node": node, "sprite": sprite, "label": label, "target": at, "age": 0.0, "character": character,
		"dead": false, "waiting": false}


## Az itt (ugyanezen a helyen) lévő élő társak: peer id -> figura.
func living() -> Dictionary:
	var result := {}
	for id: int in _avatars:
		var avatar: Dictionary = _avatars[id]
		if not avatar["dead"]:
			result[id] = avatar["node"]
	return result


## A lépcsőn várakozó (élő) társak azonosítói.
func waiting_ids() -> Array:
	var result: Array = []
	for id: int in _avatars:
		if _avatars[id]["waiting"] and not _avatars[id]["dead"]:
			result.append(id)
	return result


func _remove(id: int) -> void:
	if not _avatars.has(id):
		return
	var node: Node2D = _avatars[id]["node"]
	if is_instance_valid(node):
		node.queue_free()
	_avatars.erase(id)
