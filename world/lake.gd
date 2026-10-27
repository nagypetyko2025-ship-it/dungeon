class_name Lake
extends Node2D
## Tó a város keleti, új részén (a rét közepén): ovális víztükör földes parttal, közepén egy kis
## füves sziget egy fával, a déli partjáról móló nyúlik be a vízbe. A vízbe nem lehet belemenni
## (csak a mólóra). Vízcsempék: Kenney RPG (CC0; assets/props/lake_tiles.png, a világoszöld fű nélkül), parttal és belső sarkokkal; a móló: assets/props/pier.png.
## (A tábor építi fel: setup(camp) + build().)

const TILE := 32
const TILES: Texture2D = preload("res://assets/props/lake_tiles.png")
const PIER: Texture2D = preload("res://assets/props/pier.png")
const STAIRS_SCENE := preload("res://rooms/obstacles/stairs.tscn")
## A sziget lezárt lépcsője (a fától jobbra).
const ISLAND_STAIRS := Vector2i(118, 9)
## A tó közepe és sugarai (csempében); a sziget ugyanott, kisebb sugarakkal.
const CENTER := Vector2(117.5, 10.0)
const RADIUS := Vector2(9.0, 4.6)
const ISLAND_RADIUS := Vector2(2.2, 1.4)
## A móló: ebben az oszlopban, a déli parttól ennyi csempényit nyúlik be.
const PIER_COLUMN := 113
const PIER_LENGTH := 4
## Kenney RPG csempék (oszlop, sor): víz, a tó-blokk szélei/sarkai, és a belső sarkok.
const WATER := Vector2i(0, 0)
const EDGE := {"n": Vector2i(3, 0), "s": Vector2i(3, 2), "w": Vector2i(2, 1), "e": Vector2i(4, 1),
	"nw": Vector2i(2, 0), "ne": Vector2i(4, 0), "sw": Vector2i(2, 2), "se": Vector2i(4, 2)}
## Belső sarok: a víz-csempe sarkában egy kis szárazföld (a hiányzó átlós szomszéd felé).
const INNER := {"se": Vector2i(0, 1), "sw": Vector2i(1, 1), "ne": Vector2i(0, 2), "nw": Vector2i(1, 2)}

var _camp: Node2D
var _water := {}
var _player: Node2D
var _prompt: Label
var _panel: ChallengePanel
var _busy := false
## A sziget déli partja: itt köt ki Ábel csónakja (innen vissza a mólóhoz).
const ISLAND_LANDING := Vector2i(116, 10)
const RANGE := 50.0
## Ábel csónakja (rowboat.png): a tó déli részén, a móló mellett köt ki; a mólón a BOARD_CELL-ről lehet beszállni.
const BOAT: Texture2D = preload("res://assets/props/rowboat.png")
const BOAT_SCALE := 1.2
const BOARD_CELL := Vector2i(113, 12)
const PIER_DOCK := Vector2(114.5, 12.6)
## Az evezés útja csempében (a mólótól a sziget déli partjáig); visszafelé fordítva.
const ROUTE: Array[Vector2] = [PIER_DOCK, Vector2(115.5, 12.75), Vector2(116.6, 12.4)]
## Hová ül a játékos a csónakon belül (a lába a pad közepén).
const SEAT := Vector2(0, 8)
const ROW_SPEED := 38.0
const WALK_SPEED := 70.0
var _boat: Node2D
var _hull: Sprite2D
var _boat_at_island := false


func setup(camp: Node2D) -> void:
	_camp = camp


## Víz-e a csempe (a tó ellipszisén belül, de nem a szigeten).
static func is_water(cell: Vector2i) -> bool:
	var at := Vector2(cell) + Vector2(0.5, 0.5) - CENTER
	var lake := pow(at.x / RADIUS.x, 2) + pow(at.y / RADIUS.y, 2) <= 1.0
	var island := pow(at.x / ISLAND_RADIUS.x, 2) + pow(at.y / ISLAND_RADIUS.y, 2) <= 1.0
	return lake and not island


## Ide nem kerülhet fa / virág / bokor (a tó és a partja).
static func blocked_rect() -> Rect2i:
	var top_left := Vector2i((CENTER - RADIUS).floor()) - Vector2i(2, 2)
	return Rect2i(top_left, Vector2i((RADIUS * 2.0).ceil()) + Vector2i(5, 5))


## Keskeny (egy csempe széles) ösvény a városi úttól a mólóig (a tábor rajzolja ki a többi földdel).
static func path_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for y in range(int(CENTER.y + RADIUS.y) + 1, 17):
		tiles.append(Vector2i(PIER_COLUMN, y))
	return tiles


## A móló csempéi (ezeken át lehet menni a víz fölött).
static func pier_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var shore_y := int(CENTER.y + RADIUS.y)
	for i in PIER_LENGTH + 1:
		cells.append(Vector2i(PIER_COLUMN, shore_y - i))
	return cells


func build() -> void:
	var area := blocked_rect()
	for x in range(area.position.x, area.end.x):
		for y in range(area.position.y, area.end.y):
			if is_water(Vector2i(x, y)):
				_water[Vector2i(x, y)] = true
	var body := StaticBody2D.new()
	add_child(body)
	var pier := pier_cells()
	for cell: Vector2i in _water:
		_tile(_tile_for(cell), cell)
		if not pier.has(cell):
			var shape := CollisionShape2D.new()
			var box := RectangleShape2D.new()
			box.size = Vector2(TILE, TILE)
			shape.shape = box
			shape.position = (Vector2(cell) + Vector2(0.5, 0.5)) * TILE
			body.add_child(shape)
	_build_pier()
	_build_island()


## Melyik csempe kell a víz-csempére a szomszédai szerint (part, sarok, belső sarok, sima víz).
func _tile_for(cell: Vector2i) -> Vector2i:
	var n := _water.has(cell + Vector2i.UP)
	var s := _water.has(cell + Vector2i.DOWN)
	var w := _water.has(cell + Vector2i.LEFT)
	var e := _water.has(cell + Vector2i.RIGHT)
	if not n and not w:
		return EDGE["nw"]
	if not n and not e:
		return EDGE["ne"]
	if not s and not w:
		return EDGE["sw"]
	if not s and not e:
		return EDGE["se"]
	if not n:
		return EDGE["n"]
	if not s:
		return EDGE["s"]
	if not w:
		return EDGE["w"]
	if not e:
		return EDGE["e"]
	if not _water.has(cell + Vector2i(1, 1)):
		return INNER["se"]
	if not _water.has(cell + Vector2i(-1, 1)):
		return INNER["sw"]
	if not _water.has(cell + Vector2i(1, -1)):
		return INNER["ne"]
	if not _water.has(cell + Vector2i(-1, -1)):
		return INNER["nw"]
	return WATER


func _tile(coords: Vector2i, cell: Vector2i) -> Sprite2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = TILES
	atlas.region = Rect2(Vector2(coords) * 17.0, Vector2(16, 16))
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.scale = Vector2(2, 2)
	sprite.position = (Vector2(cell) + Vector2(0.5, 0.5)) * TILE
	sprite.z_index = -9
	add_child(sprite)
	return sprite


## A móló: a déli partról egyenesen be a vízbe, a végén két cölöp és egy kikötött csónak-kötél.
func _build_pier() -> void:
	var cells := pier_cells()
	var bottom := (Vector2(cells[0]) + Vector2(0.5, 1.0)) * TILE
	var sprite := Sprite2D.new()
	sprite.texture = PIER
	sprite.centered = false
	var length := TILE * (PIER_LENGTH + 1.2)
	sprite.scale = Vector2(TILE * 1.15 / PIER.get_width(), length / PIER.get_height())
	sprite.position = bottom - Vector2(TILE * 1.15 / 2.0, length)
	sprite.z_index = -8
	# A letöltött híd sötét: kicsit világosabb, napsütötte deszkák.
	sprite.modulate = Color(1.7, 1.45, 1.2)
	add_child(sprite)


## A sziget: fű (a talaj maga), rajta egy fa és két bokor (a fa szilárd).
func _build_island() -> void:
	var center := Vector2i(CENTER.floor())
	_camp.call("_tree", center, true, true)
	_camp.call("_rpg_sprite", Vector2i(19, 9), (Vector2(center) + Vector2(-0.6, 0.9)) * TILE, 0)
	_camp.call("_rpg_sprite", Vector2i(28, 9), (Vector2(center) + Vector2(1.4, 0.7)) * TILE, -9)
	_build_island_stairs()


## A szigeten egy régi, rácsos lépcső vezet le (lezárva; Öreg Ábel tud róla valamit).
func _build_island_stairs() -> void:
	var at := (Vector2(ISLAND_STAIRS) + Vector2(0.5, 0.5)) * TILE
	var floor := Sprite2D.new()
	floor.texture = SpriteSheet.region(Rect2(16, 64, 16, 16))
	floor.scale = Vector2(2.4, 2.4)
	floor.position = at
	floor.z_index = -8
	floor.modulate = Color(0.85, 0.9, 0.85)
	add_child(floor)
	var stairs: Area2D = STAIRS_SCENE.instantiate()
	stairs.position = at
	stairs.monitoring = false
	add_child(stairs)
	# A kripta legyőzése után a rács nyitva marad.
	stairs.call("set_locked", not crypt_cleared())
	_build_crossing()


# ---------------------------------------------------------------- a tó titka (Ábel csónakja, a kripta)

## A kripta ura legyőzve (LakeCrypt).
static func crypt_cleared() -> bool:
	return Progress.npc_quest_state(Fisherman.CRYPT_QUEST) in ["slain", "done"]


## A mólón az a pont, ahonnan a csónakba lehet szállni (a tó déli részén, a csónak mellett).
func _pier_end() -> Vector2:
	return (Vector2(BOARD_CELL) + Vector2(0.5, 0.5)) * TILE


func _landing() -> Vector2:
	return (Vector2(ISLAND_LANDING) + Vector2(0.5, 0.5)) * TILE


## Ábel csónakja a tó déli részén, a móló mellett kikötve (ha már átkelhetsz).
func _build_crossing() -> void:
	_player = _camp.get_node("Entities/Player")
	if Fisherman.can_cross():
		_build_boat()
	_panel = ChallengePanel.new()
	_panel.name = "LakeChallengePanel"
	_panel.visible = false
	_camp.add_child.call_deferred(_panel)
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_prompt = MenuStyle.title_label("", 32, MenuStyle.GOLD)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -210
	_prompt.offset_bottom = -160
	_prompt.offset_left = -500
	_prompt.offset_right = 500
	_prompt.modulate.a = 0.0
	layer.add_child(_prompt)


## A csónak (CC0 kép, orral felfelé): a `_hull` lebeg a vízen, a `_boat` mozog és fordul.
func _build_boat() -> void:
	_boat = Node2D.new()
	_boat.position = PIER_DOCK * TILE
	_boat.z_index = -2
	add_child(_boat)
	_hull = Sprite2D.new()
	_hull.texture = BOAT
	_hull.scale = Vector2(BOAT_SCALE, BOAT_SCALE)
	_boat.add_child(_hull)
	var bob := _hull.create_tween().set_loops()
	bob.tween_property(_hull, "position:y", 1.5, 1.3).set_trans(Tween.TRANS_SINE)
	bob.tween_property(_hull, "position:y", -0.5, 1.3).set_trans(Tween.TRANS_SINE)


## Merre áll a játékos: "boat" (a móló vége), "back" (a sziget partja), "stairs" (a rács), vagy "".
func _focus() -> String:
	if not is_instance_valid(_player) or _busy:
		return ""
	var at: Vector2 = _player.global_position
	if _boat != null and not _boat_at_island and at.distance_to(_pier_end()) < RANGE:
		return "boat"
	if _boat != null and _boat_at_island and at.distance_to(_landing()) < RANGE:
		return "back"
	if at.distance_to((Vector2(ISLAND_STAIRS) + Vector2(0.5, 1.2)) * TILE) < RANGE:
		return "stairs"
	return ""


func _process(delta: float) -> void:
	if _prompt == null:
		return
	var focus := _focus()
	match focus:
		"boat": _prompt.text = "[E] Átevezés a szigetre"
		"back": _prompt.text = "[E] Visszaevezés a mólóhoz"
		"stairs": _prompt.text = "[E] A rácsos lépcső"
	var target := 1.0 if focus != "" and not GamePause.active(get_tree()) else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or GamePause.active(get_tree()):
		return
	var focus := _focus()
	if focus == "":
		return
	get_viewport().set_input_as_handled()
	match focus:
		"boat": _row(true)
		"back": _row(false)
		"stairs": _use_stairs()


## Átkelés: a játékos beszáll (átsétál a csónakba, leül), a csónak a vízen át a túlpartra evez (az orrával
## a menetirányba fordulva, ringatózva), ott kiszáll. Közben a karakter nem irányítható, a kamera vele megy.
func _row(to_island: bool) -> void:
	_busy = true
	var route: Array[Vector2] = []
	for tile: Vector2 in ROUTE:
		route.append(tile * TILE)
	if not to_island:
		route.reverse()
	var shore := _landing() if to_island else _pier_end()
	_player.set_physics_process(false)
	_player.set_process_unhandled_input(false)
	(_player as CharacterBody2D).velocity = Vector2.ZERO
	var sprite: AnimatedSprite2D = _player.get_node("Visual/AnimatedSprite2D")
	# Beszállás: odalép a csónakhoz, és beleül.
	await _walk(sprite, _boat.position + SEAT)
	Audio.play("footstep", -2.0)
	sprite.play("idle")
	# Evezés: pontról pontra, a csónak a menetirány felé fordul, a játékos vele megy.
	for i in range(1, route.size()):
		var from: Vector2 = route[i - 1]
		var next: Vector2 = route[i]
		await _turn((next - from).angle() + PI / 2.0)
		var leg := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		leg.tween_method(_carry.bind(from, next), 0.0, 1.0, from.distance_to(next) / ROW_SPEED)
		await leg.finished
		Audio.play("footstep", -8.0)
	# Kikötéskor a csónak orral a part felé (észak) fordul; a játékos kiszáll.
	await _turn(0.0)
	_boat_at_island = to_island
	await _walk(sprite, shore)
	sprite.play("idle")
	_player.set_physics_process(true)
	_player.set_process_unhandled_input(true)
	_busy = false


## A csónak (a legrövidebb irányba) a megadott szögbe fordul.
func _turn(angle: float) -> void:
	var start := _boat.rotation
	var turn := create_tween()
	turn.tween_method(func(t: float) -> void: _boat.rotation = lerp_angle(start, angle, t), 0.0, 1.0, 0.35)
	await turn.finished


## A csónak útja egy szakaszon (t: 0..1); a játékos a padon ül, vele együtt mozog.
func _carry(t: float, from: Vector2, to: Vector2) -> void:
	_boat.position = from.lerp(to, t)
	_player.global_position = global_position + _boat.position + SEAT


## A játékos sétál egy pontig (futó animáció, a menetirány felé néz).
func _walk(sprite: AnimatedSprite2D, to: Vector2) -> void:
	var target := global_position + to
	var from: Vector2 = _player.global_position
	if absf(target.x - from.x) > 2.0:
		sprite.flip_h = target.x < from.x
	sprite.play("run")
	var walk := create_tween()
	walk.tween_property(_player, "global_position", target, maxf(from.distance_to(target) / WALK_SPEED, 0.15))
	await walk.finished


func _use_stairs() -> void:
	var say := func(text: String) -> void: _camp.call("_toast", text)
	if crypt_cleared():
		say.call("A rács nyitva, a kripta elcsendesült. Odalent már csak a víz csobog.")
		return
	if Progress.npc_quest_state(Fisherman.CRYPT_QUEST) != "active":
		Audio.play("door_lock", -6.0)
		say.call("Két zár: egy nagy, rozsdás és egy kicsi, kalózlakat. A rács mögül hideg szél fúj, és mintha "
			+ "valami lélegezne odalent. Öreg Ábel talán tud segíteni.")
		return
	Audio.play("ui_open")
	var start := func(challenge: Dictionary) -> void: _camp.call("enter_challenge", challenge)
	_panel.show_offer(LakeCrypt.run_challenge(), start)
	_camp.get_node("Menus").call("open_menu", _panel)
