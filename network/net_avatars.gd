class_name NetAvatars
extends Node
## Közös játékban (a táborban és a kazamatában): a saját helyzetünket (hely, irány, animáció,
## karakter, és hogy hol vagyunk) gyakran elküldjük a többieknek, és az ő figuráikat (névvel a fejük
## fölött) megjelenítjük, ha ugyanott vannak (a táborban, vagy a kazamata ugyanazon emeletén).
## Akkor is küld, ha nálunk nyitva van egy menü (a játék ilyenkor áll), így a figuránk nem tűnik el.
## Aki egy ideig nem küld semmit, vagy máshol jár, annak a figurája eltűnik.
## (A tábor és a kazamata adja hozzá, ha fut közös játék: setup(scene).)

signal message(text: String)

## 20 helyzet másodpercenként (a fogadó a sebességgel előre számol közöttük, lásd NetSmooth).
const SEND_INTERVAL := 0.05
const STALE_AFTER := 2.0
## A fegyver kinézete minden ennyiedik pózzal is megy (és ha változott), hogy az újonnan jöttek is lássák.
const LOOK_EVERY := 20
## A fegyver forgáspontja a figurán (mint a Player WeaponPivot-ja).
const WEAPON_PIVOT_POSITION := Vector2(0, -18)
const PLAYER_ARROW := preload("res://player/player_arrow.gd")
## A társ lövedéke akkor tűnik el, ha szörnybe csapódik (a szörnyek teste a 3. rétegen van).
const ENEMY_BODY_LAYER := 4
## Élesztés: ilyen közel kell állni az elesett társhoz, és ennyi ideig nyomva tartani az E-t.
const REVIVE_RANGE := 56.0
const REVIVE_TIME := 3.0

var _player: Node2D
var _entities: Node2D
var _lobby: NetLobby
var _send_left := 0.0
var _look_left := 0
var _sent_look := {}
## Peer id -> a fegyvere kinézete (ha a figurája újra létrejön, pl. karakterváltáskor, ezt kapja).
var _looks := {}
## Peer id -> {"node": Node2D, "sprite": AnimatedSprite2D, "smooth": NetSmooth, "age": float, "character": String, ...}
var _avatars := {}
## Peer id -> hol járt legutóbb ("camp", vagy "d<emelet>:<mag>"; lásd _where).
var _last_where := {}


func setup(scene: Node2D) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = scene.get_node("Entities/Player")
	_entities = scene.get_node("Entities")
	_lobby = NetLobby.current(scene.get_tree())
	_lobby.pose_received.connect(_on_pose)
	_lobby.effect_received.connect(_on_effect)
	_lobby.revive_requested.connect(_on_revive_requested)
	_lobby.player_left.connect(_remove)
	_lobby.closed.connect(func(reason: String) -> void:
		for id: int in _avatars.keys():
			_remove(id)
		message.emit(reason + " Egyedül folytatod."))


func _process(delta: float) -> void:
	if _lobby == null or _lobby.state != "playing" or not is_instance_valid(_player):
		return
	# Hozzáadva (nem visszaállítva) számol, hogy a valódi ütem tényleg 20/mp legyen.
	_send_left -= delta
	if _send_left <= 0.0:
		_send_left = maxf(_send_left + SEND_INTERVAL, 0.0)
		var sprite := _player.get_node("Visual/AnimatedSprite2D") as AnimatedSprite2D
		var body := _player as CharacterBody2D
		var moving := body.velocity if body != null and body.is_physics_processing() else Vector2.ZERO
		var pose := {"p": _player.global_position, "v": moving, "f": sprite.flip_h, "a": str(sprite.animation),
			"c": Progress.character, "w": _where(), "d": bool(_player.get("net_dead")),
			"r": bool(_player.get("net_waiting"))}
		# Elesve: a társak a halálunk helyén látnak (ott élesztenek fel).
		if bool(_player.get("net_dead")):
			pose["g"] = _player.get("net_death_at")
		var look: Dictionary = _player.call("net_weapon_look") if _player.has_method("net_weapon_look") else {}
		_look_left -= 1
		if look != _sent_look or _look_left <= 0:
			_look_left = LOOK_EVERY
			_sent_look = look
			pose["l"] = look
		_lobby.send_pose(pose)
	for id: int in _avatars.keys():
		var avatar: Dictionary = _avatars[id]
		avatar["age"] = float(avatar["age"]) + delta
		if float(avatar["age"]) > STALE_AFTER:
			_remove(id)
			continue
		var node: Node2D = avatar["node"]
		var smooth: NetSmooth = avatar["smooth"]
		# Messzi ugrásnál (pl. belépett egy házba) azonnal ott van, különben simán követi.
		node.position = smooth.step(node.position, delta)
	_update_revive(delta)


## Hol vagyunk: "camp", vagy a kazamata emelete a közös maggal (csak az azonos helyűek látják egymást).
func _where() -> String:
	if _entities.get_parent().has_method("go_to_floor"):
		return "d%d:%d" % [GameState.depth, GameState.net_seed]
	return "camp"


func _on_pose(id: int, data: Dictionary) -> void:
	_last_where[id] = str(data.get("w", "camp"))
	if str(data.get("w", "camp")) != _where():
		_remove(id)
		return
	var character := str(data.get("c", Characters.DEFAULT))
	if not _avatars.has(id) or _avatars[id]["character"] != character:
		_remove(id)
		_avatars[id] = _create(id, character, data.get("p", Vector2.ZERO))
	var avatar: Dictionary = _avatars[id]
	(avatar["smooth"] as NetSmooth).receive(data.get("p", Vector2.ZERO), data.get("v", Vector2.ZERO))
	avatar["age"] = 0.0
	if data.get("l") is Dictionary and data["l"] != _looks.get(id):
		_looks[id] = data["l"]
		_apply_look(avatar, data["l"])
	# Halott társ (néző): nem látszik, és a szörnyek sem üldözik; a lépcsőn várakozónál "(vár)".
	var dead := bool(data.get("d", false))
	var waiting := bool(data.get("r", false))
	avatar["dead"] = dead
	avatar["waiting"] = waiting
	var node: Node2D = avatar["node"]
	node.visible = not dead
	_update_grave(id, avatar, dead, data.get("g", node.position))
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
	# A fegyvere (csak támadás közben látszik, mint a sajátunk), két tőrnél a másik kézben is.
	var pivot := Node2D.new()
	pivot.position = WEAPON_PIVOT_POSITION
	pivot.visible = false
	node.add_child(pivot)
	pivot.add_child(Sprite2D.new())
	var twin := Node2D.new()
	twin.visible = false
	node.add_child(twin)
	twin.add_child(Sprite2D.new())
	var label := UiStyle.label(_lobby.player_name(id), 14, Color(0.75, 0.9, 1.0))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.add_child(label)
	label.position = Vector2(-label.get_combined_minimum_size().x / 2.0, -78)
	if not _avatars.has(id):
		message.emit("%s itt van veled." % _lobby.player_name(id))
	var smooth := NetSmooth.new()
	smooth.receive(at, Vector2.ZERO)
	var avatar := {"node": node, "sprite": sprite, "label": label, "smooth": smooth, "age": 0.0, "character": character,
		"dead": false, "waiting": false, "pivot": pivot, "twin": twin, "tween": null, "grave": null, "revive": 0.0,
		"revive_wait": 0.0}
	if _looks.get(id) is Dictionary:
		_apply_look(avatar, _looks[id])
	return avatar


# ---------------------------------------------------------------- fegyver és lövedékek

## A fegyver kinézete a figurán (a Player.net_weapon_look szerint: ikon, a kép helyzete a forgásponthoz).
func _apply_look(avatar: Dictionary, look: Dictionary) -> void:
	var item := {}
	if look.has("i"):
		item["icon_path"] = look["i"]
	elif look.has("r"):
		item["region"] = look["r"]
	var texture: Texture2D = Items.icon(item) if not item.is_empty() else null
	for key in ["pivot", "twin"]:
		var weapon := (avatar[key] as Node2D).get_child(0) as Sprite2D
		weapon.texture = texture
		if look.get("t") is Transform2D:
			weapon.transform = look["t"]
		weapon.z_index = int(look.get("z", 0))


## A saját támadásunk látszata a társaknál (suhintás, döfés, lövés, varázslat; lásd Player.share_effect).
## A sebzést mindenki a saját gépén számolja, ezek csak a látványt adják.
func share(kind: String, args: Array) -> void:
	if _lobby != null and _lobby.state == "playing":
		_lobby.send_effect(kind, [_where()] + args)


func _on_effect(id: int, kind: String, args: Array) -> void:
	if args.is_empty() or str(args[0]) != _where() or not _avatars.has(id):
		return
	var avatar: Dictionary = _avatars[id]
	if avatar["dead"]:
		return
	var pivot: Node2D = avatar["pivot"]
	var twin: Node2D = avatar["twin"]
	match kind:
		"swing":
			# [hely, célzás, ív, oldal, idő]
			var aim := float(args[1])
			var half := float(args[2]) / 2.0 * float(args[3])
			_show_weapon(avatar, aim - half, WEAPON_PIVOT_POSITION)
			var tween := _new_tween(avatar)
			tween.tween_property(pivot, "rotation", aim + half, float(args[4]))
			tween.tween_callback(_hide_weapon.bind(avatar))
		"thrust":
			# [hely, célzás, honnan, meddig, hová vissza, idő, a másik tőr helye (INF: nincs)]
			var aim := float(args[1])
			var thrust_time := float(args[5])
			_show_weapon(avatar, aim, args[2])
			var twin_at: Vector2 = args[6]
			if twin_at != Vector2.INF:
				twin.position = twin_at
				twin.rotation = aim
				twin.visible = true
			var tween := _new_tween(avatar)
			tween.tween_property(pivot, "position", args[3], thrust_time * 0.5) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(pivot, "position", args[4], thrust_time * 0.5) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_callback(_hide_weapon.bind(avatar))
		"hold":
			# [hely, célzás, idő] — íj vagy varázspálca egy pillanatra a kézben.
			_show_weapon(avatar, float(args[1]), WEAPON_PIVOT_POSITION)
			var tween := _new_tween(avatar)
			tween.tween_interval(float(args[2]))
			tween.tween_callback(_hide_weapon.bind(avatar))
		"shot":
			# [hely, kinézet, hely, kiinduló pont, irány, sebesség, táv]
			var shot: Area2D = PLAYER_ARROW.new()
			shot.set("look", str(args[1]))
			shot.set("direction", args[4])
			shot.set("speed", float(args[5]))
			shot.set("max_distance", float(args[6]))
			_entities.add_child(shot)
			_make_harmless(shot)
			shot.collision_mask = ENEMY_BODY_LAYER
			shot.body_entered.connect(func(_body: Node2D) -> void: shot.queue_free())
			shot.global_position = args[2]
			shot.set("origin", args[3])
		"spike":
			var spike := Spells.EarthSpike.new()
			_entities.add_child(spike)
			_make_harmless(spike)
			spike.global_position = args[1]
		"arc":
			var arc := Spells.LightningArc.new()
			arc.from = args[1]
			arc.to = args[2]
			_entities.add_child(arc)


## A társ lövedéke itt nem sebez (nála már eltalálta, amit kellett): kivesszük a játékos-fegyver rétegből.
func _make_harmless(area: Area2D) -> void:
	area.collision_layer = 0
	area.set_deferred("monitorable", false)


func _show_weapon(avatar: Dictionary, angle: float, at: Vector2) -> void:
	var pivot: Node2D = avatar["pivot"]
	pivot.rotation = angle
	pivot.position = at
	pivot.visible = true


func _hide_weapon(avatar: Dictionary) -> void:
	(avatar["pivot"] as Node2D).visible = false
	(avatar["twin"] as Node2D).visible = false
	(avatar["pivot"] as Node2D).position = WEAPON_PIVOT_POSITION


## Új támadás-animáció a figurán (az előző, még futó félbeszakad).
func _new_tween(avatar: Dictionary) -> Tween:
	var previous: Variant = avatar["tween"]
	if previous is Tween and (previous as Tween).is_valid():
		(previous as Tween).kill()
	var tween := (avatar["node"] as Node2D).create_tween()
	avatar["tween"] = tween
	return tween


## Hol járt legutóbb a társ ("" ha még nem hallottunk róla).
func last_where(id: int) -> String:
	return str(_last_where.get(id, ""))


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
	var grave: Variant = _avatars[id]["grave"]
	if is_instance_valid(grave):
		(grave as Node).queue_free()
	_avatars.erase(id)


# ---------------------------------------------------------------- élesztés

## Az elesett társ a halála helyén fekszik (halványan, a nevével); ha feléledt, eltűnik.
func _update_grave(id: int, avatar: Dictionary, dead: bool, at: Vector2) -> void:
	var existing: Variant = avatar["grave"]
	if not dead:
		if is_instance_valid(existing):
			(existing as Node).queue_free()
		avatar["grave"] = null
		avatar["revive"] = 0.0
		return
	if is_instance_valid(existing):
		(existing as Node2D).position = at
		return
	var grave := Node2D.new()
	grave.position = at
	_entities.add_child(grave)
	var body := AnimatedSprite2D.new()
	body.sprite_frames = Characters.frames(str(avatar["character"]))
	body.animation = "idle"
	body.scale = Vector2(2, 2)
	body.offset = Vector2(0, -12)
	body.rotation = PI / 2.0
	body.position = Vector2(-10, -8)
	body.modulate = Color(0.65, 0.65, 0.8, 0.7)
	grave.add_child(body)
	var label := UiStyle.label(_lobby.player_name(id), 14, Color(1, 0.6, 0.55))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size.x = 260.0
	label.position = Vector2(-130.0, -64)
	grave.add_child(label)
	grave.set_meta("label", label)
	avatar["grave"] = grave


## Élesztés: ha élünk, és egy elesett társ mellett nyomva tartjuk az E-t, REVIVE_TIME alatt feláll.
func _update_revive(delta: float) -> void:
	var alive := _player.is_in_group("player") and not bool(_player.get("net_dead")) \
		and not get_tree().paused
	var holding := alive and Input.is_action_pressed("interact")
	for id: int in _avatars:
		var avatar: Dictionary = _avatars[id]
		var grave: Variant = avatar["grave"]
		if not is_instance_valid(grave):
			continue
		var marker := grave as Node2D
		var label: Label = marker.get_meta("label")
		var who := _lobby.player_name(id)
		avatar["revive_wait"] = maxf(float(avatar["revive_wait"]) - delta, 0.0)
		var near := alive and _player.global_position.distance_to(marker.global_position) < REVIVE_RANGE
		if not near or float(avatar["revive_wait"]) > 0.0:
			avatar["revive"] = 0.0
			label.text = who + ("  (élesztés...)" if float(avatar["revive_wait"]) > 0.0 else "  (elesett)")
			continue
		if not holding:
			avatar["revive"] = 0.0
			label.text = who + "\nÉlesztés: tartsd nyomva az E-t"
			continue
		avatar["revive"] = float(avatar["revive"]) + delta
		label.text = who + "\nÉlesztés... %d%%" % mini(roundi(float(avatar["revive"]) / REVIVE_TIME * 100.0), 100)
		if float(avatar["revive"]) >= REVIVE_TIME:
			avatar["revive"] = 0.0
			# Amíg az ő gépéről vissza nem jön, hogy feláll, nem küldjük újra.
			avatar["revive_wait"] = 2.0
			_lobby.send_revive(id)
			message.emit("Felélesztetted: %s" % who)


## Egy társ felélesztett minket.
func _on_revive_requested(by_id: int) -> void:
	if not is_instance_valid(_player) or not bool(_player.get("net_dead")):
		return
	_player.call("revive_from_net")
	message.emit("%s felélesztett!" % _lobby.player_name(by_id))
