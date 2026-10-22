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

## A király küldetései (a J könyv "Király" fülén), mint Dialogues.VETERAN_QUESTS.
const KING_NAME := "A király"
const PERMIT_QUEST := "king_permit"
## Belső jelző (Progress.npc_quests): elérted a 30. emeletet ("reached"), és vissza is jöttél ("done").
const DEEP_FLAG := "deep_30"
const KING_QUESTS := {
	PERMIT_QUEST: {"name": "Királyi engedély",
		"text": "A királyi vár kapujában álló őrök csak engedéllyel engednek be, vagy olyan kalandort, "
			+ "aki [b]elérte a Mélység 30. szintjét, és vissza is jött[/b]. Juss le a 30. emeletre, "
			+ "aztán térj vissza a táborba.",
		"reward": "belépés a királyi várba", "doing": "juss le a 30. emeletre, és gyere vissza",
		"done": "az őrök beengednek"},
}
const WARNING := "Őr: „Megállj! A várba csak a király engedélyével léphetsz be, vagy ha elérted " \
	+ "a Mélység 30. szintjét, és vissza is jöttél.”"
const WELCOME := "Őr: „Üdv, kalandor! Hallottuk, hogy megjártad a harmincadik szintet. " \
	+ "A király hamarosan fogad.”"

var _camp: Node2D
var _player: Node2D
var _entities: Node2D
var _prompt: Label


func setup(camp: Node2D) -> void:
	_camp = camp
	_entities = camp.get_node("Entities")
	_player = camp.get_node("Entities/Player")


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
	_build_house()
	_build_castle()
	_build_guards()
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


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	var gate := Vector2(PATH_COLUMN + 1, GATE_ROW + 1) * TILE
	var near := _player.global_position.distance_to(gate) < GUARD_RANGE
	if near and Progress.npc_quest_state(PERMIT_QUEST) == "":
		# Az első figyelmeztetéskor új fül nyílik a küldetések könyvében.
		Progress.set_npc_quest(PERMIT_QUEST, "done" if permit_earned() else "active")
		Progress.save_game()
		Audio.play("ui_open")
		message.emit("Új fül a küldetések könyvében: Király  [J]")
	if near:
		_prompt.text = WELCOME if Progress.npc_quest_state(PERMIT_QUEST) == "done" else WARNING
	var target := 1.0 if near and not get_tree().paused else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 4.0)


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
