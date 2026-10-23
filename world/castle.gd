class_name Castle
extends Node2D
## A város északi része: a kocsma mellett egy új lakóház, mellette út vezet északra, ki a
## városból, át az erdőn egy tisztásra, ahol a királyi vár áll. A kapu előtt két lándzsás őr:
## ha a közelükbe mész, figyelmeztetnek, hogy csak engedéllyel, vagy a Mélység 30. szintjét
## megjárt (és onnan visszatért) kalandor léphet be. Ekkor a küldetések könyvében megjelenik
## a "Király" fül (KING_QUESTS). (A tábor építi fel: setup(camp) + build(), mint a Várost.)

signal message(text: String)

const TILE := 32
const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const DUNGEON: Texture2D = preload("res://assets/0x72_dungeon/0x72_DungeonTilesetII_v1.7.png")
const CONTAINERS: Texture2D = preload("res://assets/shop/barrels_and_boxes.png")
const TORCH := preload("res://rooms/decor/torch.tscn")

## Az út a kocsma mellett (2 csempe széles), a városi úttól északra a vár kapujáig.
const PATH_COLUMN := 76
## Az új lakóház (a kocsmától keletre, az út túloldalán).
const HOUSE_TOP_LEFT := Vector2i(80, 10)
const HOUSE_SIZE := Vector2i(6, 5)
## A vár tisztása (a város tisztásától északra, az erdőben).
const RECT := Rect2i(62, -18, 30, 22)
## A várfal (bal felső csempe és méret); a tornyok a két szélén magasabbak.
const WALL_TOP_LEFT := Vector2i(67, -14)
const WALL_SIZE := Vector2i(20, 7)
const TOWER_WIDTH := 3
const GATE_ROW := -8
const GUARD_RANGE := 120.0
const STONE_TINT := Color(0.86, 0.84, 0.8)

## 0x72 csempék.
const WALL_MID := Rect2(32, 16, 16, 16)
const WALL_TOP := Rect2(32, 0, 16, 16)
const BANNER_RED := Rect2(16, 32, 16, 16)
const BANNER_YELLOW := Rect2(32, 48, 16, 16)
const DOOR_FRAME_TOP := Rect2(32, 224, 32, 16)
const DOOR_FRAME_LEFT := Rect2(16, 240, 16, 32)
const DOOR_FRAME_RIGHT := Rect2(64, 240, 16, 32)
const DOOR_LEAF := Rect2(32, 240, 32, 32)
const COLUMN := Rect2(80, 80, 16, 48)
const SPEAR := Rect2(309, 161, 6, 30)
## A királyi őr (a 0x72 knight_f átszínezve: acélszürke páncél, vörös forgó).
const GUARD_SHEET: Texture2D = preload("res://assets/characters/royal_guard.png")

## A belépés küldetése (a király többi küldetése: King.QUESTS).
const PERMIT_QUEST := "king_permit"
## Belső jelző (Progress.npc_quests): elérted a 30. emeletet ("reached"), és vissza is jöttél ("done").
const DEEP_FLAG := "deep_30"
const WARNING := "Őr: „Megállj! A várba csak a király engedélyével léphetsz be, vagy ha elérted " \
	+ "a Mélység 30. szintjét, és vissza is jöttél.”"
const WELCOME := "Őr: „Üdv, kalandor! Hallottuk, hogy megjártad a harmincadik szintet. " \
	+ "A király vár rád.”   [E] Belépés"

## A trónterem, messze a pályától (mint a kocsma belseje): bejárat délen, a trón a hátsó falnál.
const THRONE_ROOM := Rect2i(300, 0, 16, 14)
const THRONE_DOOR := Vector2i(307, 14)
const THRONE_TILE := Vector2i(307, 1)
const THRONE_LIGHT := Color(0.5, 0.45, 0.45)
const FLOOR_TILES: Array[Rect2] = [Rect2(16, 64, 16, 16), Rect2(32, 64, 16, 16), Rect2(48, 64, 16, 16),
	Rect2(16, 80, 16, 16)]
const THRONE: Texture2D = preload("res://assets/props/throne.png")
const INTERACT_RANGE := 56.0
const KING_RANGE := 100.0

var _camp: Node2D
var _player: Node2D
var _entities: Node2D
var _prompt: Label
var _dialogue: DialoguePanel
var _inside := false
var _busy := false


func setup(camp: Node2D) -> void:
	_camp = camp
	_entities = camp.get_node("Entities")
	_player = camp.get_node("Entities/Player")
	_dialogue = DialoguePanel.new()
	_dialogue.name = "KingDialogue"
	_dialogue.npc_id = King.ID
	_dialogue.npc_name = King.NAME
	_dialogue.portrait = King.portrait()
	_dialogue.options_provider = func() -> Array[Dictionary]:
		return King.options(_player.get_node("Inventory"))
	camp.add_child.call_deferred(_dialogue)


## Az út csempéi (a tábor rajzolja ki a többi földdel együtt): a városi úttól a kapuig.
static func path_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for y in range(GATE_ROW + 1, 17):
		for x in [PATH_COLUMN, PATH_COLUMN + 1]:
			tiles.append(Vector2i(x, y))
	return tiles


## Ide nem kerülhet fa / bokor: a lakóház és a vár körül.
static func blocked_rects() -> Array[Rect2i]:
	return [Rect2i(HOUSE_TOP_LEFT - Vector2i(1, 2), HOUSE_SIZE + Vector2i(2, 4)),
		Rect2i(WALL_TOP_LEFT - Vector2i(1, 4), WALL_SIZE + Vector2i(2, 7))]


## Megjártad a 30. emeletet, és visszajöttél (a Gáspár-küldetés teljesítése is számít).
static func permit_earned() -> bool:
	return Progress.npc_quest_state(DEEP_FLAG) == "done" or Progress.npc_quest_state("depth_30") == "done"


## A táborba visszaérve: ha a futásban elérted a 30. emeletet, most már "vissza is jöttél".
static func on_return_to_camp() -> void:
	if Progress.npc_quest_state(DEEP_FLAG) == "reached":
		Progress.set_npc_quest(DEEP_FLAG, "done")
	if Progress.npc_quest_state(PERMIT_QUEST) == "active" and permit_earned():
		Progress.set_npc_quest(PERMIT_QUEST, "done")


func build() -> void:
	# A lakóház helyén most a kalandorok kórháza áll (lásd Hospital).
	_build_castle()
	_build_guards()
	_build_throne_room()
	_build_ui()


# ---------------------------------------------------------------- a lakóház

func _build_house() -> void:
	var tl := HOUSE_TOP_LEFT
	var w := HOUSE_SIZE.x
	for x in w:
		var piece := 0 if x == 0 else (2 if x == w - 1 else 1)
		_tile(Town.ROOF_TOP[piece], tl + Vector2i(x, 0), -6).modulate = Color(0.62, 0.7, 0.85)
		_tile(Town.ROOF_MID[piece], tl + Vector2i(x, 1), -6).modulate = Color(0.62, 0.7, 0.85)
		_tile(Town.ROOF_LOW[piece], tl + Vector2i(x, 2), -6).modulate = Color(0.62, 0.7, 0.85)
		_tile(Town.WALL_BAND, tl + Vector2i(x, 3), -6)
		_tile(Town.WALL_BOARDS, tl + Vector2i(x, 4), -6)
	_tile(Town.WINDOW, tl + Vector2i(1, 3), -5)
	_tile(Town.WINDOW, tl + Vector2i(w - 2, 3), -5)
	_tile(Town.DOUBLE_DOOR[0], tl + Vector2i(w / 2, 4), -5)
	# Ablak alatt virágláda, a ház mellett hordó.
	_sprite(CONTAINERS, Rect2(0, 0, 16, 16), _center(tl + Vector2i(w, 4)) + Vector2(6, 10), -4)
	_solid(Rect2(Vector2(tl) * TILE, Vector2(HOUSE_SIZE) * TILE - Vector2(0, 6)))


# ---------------------------------------------------------------- a vár

func _build_castle() -> void:
	var castle := Node2D.new()
	castle.modulate = STONE_TINT
	add_child(castle)
	var tl := WALL_TOP_LEFT
	var w := WALL_SIZE.x
	var bottom := GATE_ROW + 1
	for x in w:
		var tower := x < TOWER_WIDTH or x >= w - TOWER_WIDTH
		# A tornyok magasabbak (a tetejük pártázatos), közöttük a fal.
		var top := tl.y if tower else tl.y + 2
		_dungeon(WALL_TOP, Vector2i(tl.x + x, top), -6, castle)
		for y in range(top + 1, bottom):
			_dungeon(WALL_MID, Vector2i(tl.x + x, y), -6, castle)
	# A falak mögött a belső vártorony (a fal fölött látszik).
	for x in range(6, w - 6):
		_dungeon(WALL_TOP, Vector2i(tl.x + x, tl.y - 3), -7, castle)
		for y in range(tl.y - 2, tl.y + 2):
			_dungeon(WALL_MID, Vector2i(tl.x + x, y), -7, castle).modulate = Color(0.8, 0.8, 0.82)
	# Zászlók a tornyokon és a vártornyon, ablakrések (sötét) a tornyokon.
	for x in [1, w - 2]:
		_dungeon(BANNER_RED, Vector2i(tl.x + x, tl.y + 2), -5, castle)
		_dark(Rect2(_center(Vector2i(tl.x + x, tl.y + 4)) - Vector2(3, 8), Vector2(6, 16)))
	for x in [7, w - 8]:
		_dungeon(BANNER_YELLOW, Vector2i(tl.x + x, tl.y - 1), -5, castle)
	_dungeon(BANNER_RED, Vector2i(tl.x + w / 2 - 1, tl.y - 1), -5, castle)
	_dungeon(BANNER_RED, Vector2i(tl.x + w / 2, tl.y - 1), -5, castle)
	# A kapu: keret és zárt kétszárnyú ajtó az út végén, két oldalt oszlop és fáklya.
	var gate := Vector2(PATH_COLUMN + 1, GATE_ROW) * TILE
	_region_sprite(DUNGEON, DOOR_FRAME_TOP, gate + Vector2(0, -TILE * 1.5), -5, castle)
	_region_sprite(DUNGEON, DOOR_FRAME_LEFT, gate + Vector2(-TILE * 1.5, 0), -5, castle)
	_region_sprite(DUNGEON, DOOR_FRAME_RIGHT, gate + Vector2(TILE * 1.5, 0), -5, castle)
	_region_sprite(DUNGEON, DOOR_LEAF, gate, -5, castle)
	for side in [-1, 1]:
		_region_sprite(DUNGEON, COLUMN, gate + Vector2(side * TILE * 2.5, -TILE * 0.5), -4, castle)
		var torch: Node2D = TORCH.instantiate()
		torch.position = gate + Vector2(side * TILE * 3.5, -TILE * 1.2)
		add_child(torch)
	_solid(Rect2(Vector2(tl) * TILE, Vector2(w, bottom - tl.y) * TILE - Vector2(0, 6)))
	# A vár mögé (és a két oldalán mellé) nem lehet bemenni: a tisztás teljes szélességében zárva.
	_solid(Rect2(Vector2(RECT.position) * TILE, Vector2(RECT.size.x, bottom - RECT.position.y) * TILE - Vector2(0, 6)))
	# A vár felirata a kapu fölött.
	var sign_label := MenuStyle.title_label("Királyi vár", 26, MenuStyle.GOLD)
	sign_label.size = Vector2(300, 34)
	sign_label.position = gate + Vector2(-150, -TILE * 3.4)
	sign_label.z_index = 2
	add_child(sign_label)


## Két lándzsás őr a kapu két oldalán, lassan "lélegezve", a lándzsa a kezükben.
func _build_guards() -> void:
	for side in [-1, 1]:
		var holder := Node2D.new()
		holder.position = Vector2(PATH_COLUMN + 1, GATE_ROW + 1) * TILE + Vector2(side * TILE * 1.6, 20)
		_entities.add_child(holder)
		var guard := AnimatedSprite2D.new()
		guard.sprite_frames = _guard_frames()
		guard.scale = Vector2(2, 2)
		guard.offset = Vector2(0, -14)
		guard.flip_h = side > 0
		guard.play()
		holder.add_child(guard)
		var spear := _region_sprite(DUNGEON, SPEAR, Vector2(-side * 14, -34), 1, holder)
		spear.scale = Vector2(2, 2)
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = Vector2(22, 12)
		shape.shape = box
		shape.position = Vector2(0, -6)
		body.add_child(shape)
		holder.add_child(body)


## Az őr álló kockái (assets/characters/royal_guard.png: 0-3 álló), lassan.
func _guard_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 3.0)
	for i in 4:
		var frame := AtlasTexture.new()
		frame.atlas = GUARD_SHEET
		frame.region = Rect2(i * 16, 0, 16, 28)
		frames.add_frame("default", frame)
	return frames


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_prompt = UiStyle.label("", 22, Color(1, 0.92, 0.75))
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 6)
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -230
	_prompt.offset_bottom = -150
	_prompt.offset_left = -520
	_prompt.offset_right = 520
	_prompt.modulate.a = 0.0
	layer.add_child(_prompt)


## Ami előtt a játékos áll: [művelet ("" = csak felirat), felirat] vagy [].
func _focus() -> Array:
	if not is_instance_valid(_player) or _busy:
		return []
	var at: Vector2 = _player.global_position
	if _inside:
		if at.distance_to(_center(THRONE_DOOR) + Vector2(TILE / 2.0, 0)) < INTERACT_RANGE:
			return ["leave", "[E] Kilépés a várból"]
		if at.distance_to(_center(THRONE_TILE) + Vector2(TILE / 2.0, TILE)) < KING_RANGE:
			return ["king", "[E] Kihallgatás: %s" % King.NAME]
		return []
	if at.distance_to(Vector2(PATH_COLUMN + 1, GATE_ROW + 1) * TILE) < GUARD_RANGE:
		if Progress.npc_quest_state(PERMIT_QUEST) == "done":
			return ["enter", WELCOME]
		return ["", WARNING]
	return []


func _process(delta: float) -> void:
	var focus := _focus()
	if not focus.is_empty() and not _inside and Progress.npc_quest_state(PERMIT_QUEST) == "":
		# Az első figyelmeztetéskor új fül nyílik a küldetések könyvében.
		Progress.set_npc_quest(PERMIT_QUEST, "done" if permit_earned() else "active")
		Progress.save_game()
		Audio.play("ui_open")
		message.emit("Új fül a küldetések könyvében: Király  [J]")
		focus = _focus()
	if not focus.is_empty():
		_prompt.text = focus[1]
	var target := 1.0 if not focus.is_empty() and not get_tree().paused else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 4.0)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or get_tree().paused:
		return
	var focus := _focus()
	if focus.is_empty() or focus[0] == "":
		return
	get_viewport().set_input_as_handled()
	match focus[0]:
		"enter":
			_move(true, _center(THRONE_DOOR) + Vector2(TILE / 2.0, -TILE))
		"leave":
			_move(false, Vector2(PATH_COLUMN + 1, GATE_ROW + 2) * TILE + Vector2(0, 20))
		"king":
			Audio.play("ui_open")
			_dialogue.greeting = King.greeting()
			_camp.get_node("Menus").call("open_menu", _dialogue)


func _move(inside: bool, at: Vector2) -> void:
	_busy = true
	_inside = inside
	Audio.play("door_unlock", -4.0)
	var room := THRONE_ROOM
	var limits := Rect2(Vector2(room.position - Vector2i(3, 4)) * TILE, Vector2(room.size + Vector2i(6, 8)) * TILE) \
		if inside else Rect2()
	_camp.call("teleport_player", at, limits, THRONE_LIGHT if inside else Color.BLACK)
	await get_tree().create_timer(0.6).timeout
	_busy = false


# ---------------------------------------------------------------- a trónterem

func _build_throne_room() -> void:
	var r := THRONE_ROOM
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			_region_sprite(DUNGEON, FLOOR_TILES[rng.randi() % FLOOR_TILES.size()], _center(Vector2i(x, y)), -10) \
				.modulate = Color(0.85, 0.82, 0.8)
	# Hátsó fal pártázattal, zászlókkal és fáklyákkal.
	for x in range(r.position.x, r.end.x):
		_region_sprite(DUNGEON, WALL_TOP, _center(Vector2i(x, r.position.y - 2)), -9)
		_region_sprite(DUNGEON, WALL_MID, _center(Vector2i(x, r.position.y - 1)), -9)
		_region_sprite(DUNGEON, WALL_MID, _center(Vector2i(x, r.position.y)), -9)
	for x in [2, 5, r.size.x - 6, r.size.x - 3]:
		_region_sprite(DUNGEON, BANNER_RED if x % 2 == 0 else BANNER_YELLOW,
			_center(Vector2i(r.position.x + x, r.position.y - 1)), -8)
	for x in [4, r.size.x - 5]:
		var torch: Node2D = TORCH.instantiate()
		torch.position = _center(Vector2i(r.position.x + x, r.position.y)) + Vector2(0, -8)
		add_child(torch)
	# Oldalfalak és a déli fal (a kapu nyílásával).
	var dark := Color(0.1, 0.08, 0.1)
	for rect: Rect2 in [Rect2(Vector2(r.position.x - 1, r.position.y - 2) * TILE, Vector2(TILE, (r.size.y + 3) * TILE)),
			Rect2(Vector2(r.end.x, r.position.y - 2) * TILE, Vector2(TILE, (r.size.y + 3) * TILE)),
			Rect2(Vector2(r.position.x, r.end.y) * TILE, Vector2((THRONE_DOOR.x - r.position.x) * TILE, TILE)),
			Rect2(Vector2(THRONE_DOOR.x + 2, r.end.y) * TILE, Vector2((r.end.x - THRONE_DOOR.x - 2) * TILE, TILE))]:
		var wall := ColorRect.new()
		wall.color = dark
		wall.position = rect.position
		wall.size = rect.size
		wall.z_index = -9
		add_child(wall)
		_solid(rect)
	_solid(Rect2(Vector2(r.position.x, r.position.y - 2) * TILE, Vector2(r.size.x * TILE, TILE * 2.6)))
	_solid(Rect2(Vector2(THRONE_DOOR.x, r.end.y + 1) * TILE, Vector2(2 * TILE, TILE)))
	_region_sprite(DUNGEON, DOOR_LEAF, Vector2(THRONE_DOOR.x + 1, r.end.y + 0.5) * TILE, -8)
	# Vörös szőnyeg aranyszegéllyel a bejárattól a trónig.
	var carpet := ColorRect.new()
	carpet.color = Color(0.72, 0.56, 0.18)
	carpet.position = Vector2(THRONE_DOOR.x, r.position.y + 2) * TILE + Vector2(-4, 0)
	carpet.size = Vector2(2 * TILE + 8, (r.size.y - 2) * TILE)
	carpet.z_index = -9
	add_child(carpet)
	var velvet := ColorRect.new()
	velvet.color = Color(0.55, 0.1, 0.12)
	velvet.position = carpet.position + Vector2(4, 0)
	velvet.size = carpet.size - Vector2(8, 0)
	velvet.z_index = -9
	add_child(velvet)
	# Emelvény a trón alatt (két lépcsőfok), rajta a trón és a király.
	for step in 2:
		var dais := ColorRect.new()
		dais.color = Color(0.5, 0.48, 0.5) if step == 0 else Color(0.62, 0.6, 0.62)
		dais.size = Vector2((6 - step * 2) * TILE, (2 - step) * TILE * 0.7 + TILE * 0.6)
		dais.position = Vector2(THRONE_TILE.x + 1, r.position.y + 0.6) * TILE - Vector2(dais.size.x / 2.0, 0)
		dais.z_index = -8
		add_child(dais)
	var throne := Sprite2D.new()
	throne.texture = THRONE
	throne.scale = Vector2(2, 2)
	throne.position = Vector2(THRONE_TILE.x + 1, r.position.y + 0.4) * TILE
	throne.z_index = -7
	add_child(throne)
	var king := AnimatedSprite2D.new()
	king.sprite_frames = King.frames()
	king.scale = Vector2(2, 2)
	king.position = throne.position + Vector2(0, 4)
	king.z_index = -6
	king.play()
	add_child(king)
	_solid(Rect2(Vector2(THRONE_TILE.x - 1, r.position.y) * TILE, Vector2(4 * TILE, 1.6 * TILE)))
	# Oszlopsor a szőnyeg két oldalán, és két őr a trón mellett.
	for y in [4, 7, 10]:
		for x in [THRONE_DOOR.x - 3, THRONE_DOOR.x + 4]:
			_region_sprite(DUNGEON, COLUMN, _center(Vector2i(x, r.position.y + y)) + Vector2(0, -TILE), 0, _entities)
			_solid(Rect2(Vector2(x, r.position.y + y) * TILE + Vector2(4, 4), Vector2(TILE - 8, TILE - 8)))
	for side in [-1, 1]:
		var holder := Node2D.new()
		holder.position = _center(THRONE_TILE + Vector2i(1 + side * 3, 1)) + Vector2(side * -TILE / 2.0, 14)
		_entities.add_child(holder)
		var guard := AnimatedSprite2D.new()
		guard.sprite_frames = _guard_frames()
		guard.scale = Vector2(2, 2)
		guard.offset = Vector2(0, -14)
		guard.flip_h = side > 0
		guard.play()
		holder.add_child(guard)
		_region_sprite(DUNGEON, SPEAR, Vector2(-side * 14, -34), 1, holder)


# ---------------------------------------------------------------- segédek

func _center(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE


func _tile(coords: Vector2i, tile: Vector2i, z: int) -> Sprite2D:
	return _region_sprite(RPG, Rect2(Vector2(coords) * 17.0, Vector2(16, 16)), _center(tile), z)


func _dungeon(region: Rect2, tile: Vector2i, z: int, parent: Node) -> Sprite2D:
	return _region_sprite(DUNGEON, region, _center(tile), z, parent)


func _sprite(texture: Texture2D, region: Rect2, at: Vector2, z: int) -> Sprite2D:
	return _region_sprite(texture, region, at, z)


func _region_sprite(texture: Texture2D, region: Rect2, at: Vector2, z: int, parent: Node = null) -> Sprite2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.scale = Vector2(2, 2)
	sprite.position = at
	sprite.z_index = z
	(parent if parent else self).add_child(sprite)
	return sprite


func _dark(rect: Rect2) -> void:
	var dark := ColorRect.new()
	dark.color = Color(0.05, 0.04, 0.06)
	dark.position = rect.position
	dark.size = rect.size
	dark.z_index = -4
	add_child(dark)


func _solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	add_child(body)
