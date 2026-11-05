class_name Barracks
extends Node2D
## Katonai barakk: nagy, zöld vászonsátor a királyi vár tisztásán, a kapuhoz vezető úttól balra (a Kenney RPG
## zöld sátra felnagyítva, katonazöldre színezve, két oldalt zöld hadi zászló). Bent (INTERIOR, messze a pályától,
## mint a többi belső tér): deszkapadló, vászonfalak, két sor tábori priccs, rajtuk alvó őrök, középen hosszú
## asztal kockázó katonákkal, a falnál lándzsatartó, ládák a priccsek végén. (A tábor építi fel: setup + build.)

const TILE := 32
const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const DUNGEON: Texture2D = preload("res://assets/0x72_dungeon/0x72_DungeonTilesetII_v1.7.png")
const CONTAINERS: Texture2D = preload("res://assets/shop/barrels_and_boxes.png")
const GUARD_SHEET: Texture2D = preload("res://assets/characters/royal_guard.png")

## A sátor talppontja (alsó közepe) csempében; a sátor 5 csempe széles és magas.
const TENT_BASE := Vector2i(70, 0)
const TENT_SCALE := 5.0
const TENT := Vector2i(46, 10)
const TENT_TINT := Color(0.62, 0.72, 0.5)
const BANNER_TOP := Vector2i(49, 6)
const DOOR_TILE := Vector2i(70, 0)
const INTERACT_RANGE := 56.0

## A belső tér, messze a pályától.
const INTERIOR := Rect2i(690, 0, 16, 10)
const INTERIOR_DOOR := Vector2i(697, 10)
const INSIDE_LIGHT := Color(0.6, 0.56, 0.47)
const CANVAS := Color(0.42, 0.47, 0.32)
## Kenney "Roguelike Indoor" (CC0): zöld fémpriccs (párna balra), zöld csíkos tapéta (a vászonfal, felső és alsó
## sor, két változat), pajzsok.
const INDOOR: Texture2D = preload("res://assets/shop/kenney_indoor.png")
const COT := Vector2i(15, 11)
const CANVAS_WALL := [[Vector2i(23, 4), Vector2i(24, 4)], [Vector2i(23, 5), Vector2i(24, 5)]]
const SHIELDS: Array[Vector2i] = [Vector2i(22, 8), Vector2i(22, 9)]

const BARREL := Rect2(0, 0, 16, 16)
const SMALL_CRATE := Rect2(32, 0, 16, 16)
const SPEAR := Rect2(309, 161, 6, 30)

var _camp: Node2D
var _player: Node2D
var _entities: Node2D
var _prompt: Label
var _inside := false
var _busy := false
var _lieutenant_position := Vector2.INF
var _dialogue: DialoguePanel
var _orders: CanvasLayer
var _ready_mark: Label
var _mark_left := 0.0

const QUEST_PANEL := preload("res://ui/quest_panel.gd")
const TALK_RANGE := 84.0


func setup(camp: Node2D) -> void:
	_camp = camp
	_entities = camp.get_node("Entities")
	_player = camp.get_node("Entities/Player")


## Ide nem kerülhet fa (a sátor és előtte egy sáv).
static func blocked_rect() -> Rect2i:
	return Rect2i(TENT_BASE.x - 4, TENT_BASE.y - 6, Castle.PATH_COLUMN - TENT_BASE.x + 4, 10)


static func door_position() -> Vector2:
	return Vector2(DOOR_TILE.x, DOOR_TILE.y + 0.4) * TILE


## Kétsávos földút (a tábor _dirt rétegében, mint a városi út) a sátor bejáratától keletre, a vár útjáig.
static func path_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for x in range(DOOR_TILE.x - 1, Castle.PATH_COLUMN):
		for y in [DOOR_TILE.y + 1, DOOR_TILE.y + 2]:
			tiles.append(Vector2i(x, y))
	return tiles


func build() -> void:
	_build_exterior()
	_build_interior()
	_build_ui()


# ---------------------------------------------------------------- kívül

func _build_exterior() -> void:
	var holder := Node2D.new()
	holder.position = Vector2(TENT_BASE) * TILE + Vector2(0, 8)
	_entities.add_child(holder)
	for dx in 2:
		for dy in 2:
			var piece := _rpg(TENT + Vector2i(dx, dy), Vector2((dx - 1) * 16, (dy - 2) * 16) * TENT_SCALE, holder)
			piece.centered = false
			piece.scale = Vector2(TENT_SCALE, TENT_SCALE)
			piece.modulate = TENT_TINT
	# Két hosszú hadi zászló a sátor elején, a bejárat két oldalán.
	for side in [-1, 1]:
		for i in 3:
			var banner := _rpg(BANNER_TOP + Vector2i(0, i), Vector2(side * 50, -118 + i * 32), holder)
			banner.z_index = 1
	var body := StaticBody2D.new()
	for rect: Rect2 in [Rect2(-80, -60, 60, 58), Rect2(20, -60, 60, 58), Rect2(-80, -150, 160, 92)]:
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		shape.position = rect.get_center()
		body.add_child(shape)
	holder.add_child(body)
	var sign_label := MenuStyle.title_label("Barakk", 20, MenuStyle.GOLD)
	sign_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign_label.size = Vector2(160, 26)
	sign_label.position = holder.position + Vector2(-80, -186)
	sign_label.z_index = 2
	add_child(sign_label)


# ---------------------------------------------------------------- bent

func _build_interior() -> void:
	var r := INTERIOR
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			_rpg(Town.FLOOR_TILES[(x + y) % 2], _center(Vector2i(x, y)), self).z_index = -10
	# A hátsó fal: zöld csíkos vászon (Kenney Indoor tapétája), két sor.
	for x in range(r.position.x, r.end.x):
		for dy in 2:
			_indoor(CANVAS_WALL[dy][x % 2], _center(Vector2i(x, r.position.y - 1 + dy)) + Vector2(0, -8 * dy), self).z_index = -9
	_walls(r)
	# Zászlók és pajzsok a hátsó falon.
	for x in [r.position.x + 4, r.end.x - 5]:
		for i in 2:
			_rpg(BANNER_TOP + Vector2i(1, i), _center(Vector2i(x, r.position.y - 1 + i)) + Vector2(0, -6), self).z_index = -8
	for i in SHIELDS.size():
		_indoor(SHIELDS[i], _center(Vector2i(r.position.x + 7 + i, r.position.y - 1)) + Vector2(0, 4), self).z_index = -8
	# Két sor tábori priccs (fent a hátsó falnál, lent a bejárat két oldalán); az ágyak felén alvó őr.
	var top_beds := [1, 4, 10, 13]
	var bottom_beds := [1, 4, 10, 13]
	var sleeping := [true, false, true, true, false, true, false, true]
	var index := 0
	for row in [[top_beds, 1], [bottom_beds, 7]]:
		for dx: int in row[0]:
			var tile := Vector2i(r.position.x + dx, r.position.y + int(row[1]))
			_bed(tile, sleeping[index])
			_crate(tile + Vector2i(2, 0))
			index += 1
	# Középen hosszú asztal, körülötte kockázó katonák; rajta korsók és kocka.
	var table_y := r.position.y + 4
	for dx in range(6, 10):
		var table := _rpg(Town.TABLE, _center(Vector2i(r.position.x + dx, table_y)), _entities)
		table.position.y += 6
	_solid(Rect2(Vector2(r.position.x + 6, table_y) * TILE + Vector2(2, 10), Vector2(4 * TILE - 4, TILE - 14)))
	for i in 3:
		var mug := _rpg(Town.DRINKS[i], _center(Vector2i(r.position.x + 6 + i, table_y)) + Vector2(10, -8), _entities)
		mug.scale = Vector2(1.3, 1.3)
		mug.z_index = 1
	for spot: Array in [[Vector2i(5, 4), false], [Vector2i(10, 4), true], [Vector2i(8, 5), true]]:
		_soldier(_center(Vector2i(r.position.x, r.position.y) + spot[0]) + Vector2(0, 10), spot[1])
	_build_lieutenant(_center(Vector2i(r.position.x + 7, r.position.y + 3)) + Vector2(16, 10))
	# A jobb falnak döntött lándzsák, mellettük egy őr; hordók a bal sarokban.
	var lean := Vector2(r.end.x, r.position.y + 4) * TILE + Vector2(-8, 0)
	for i in 4:
		var spear := _region(DUNGEON, SPEAR, lean + Vector2(-2 - i * 3, i * 22), _entities)
		spear.scale = Vector2(2, 2)
		spear.rotation = deg_to_rad(-12)
	_soldier(_center(Vector2i(r.end.x - 2, r.position.y + 5)) + Vector2(0, 10), true)
	for tile in [Vector2i(r.position.x, r.position.y + 4), Vector2i(r.position.x, r.position.y + 5)]:
		_barrel(tile)


## Tábori fémpriccs zöld pokróccal (Kenney Indoor, a párna balra), 1.5 csempe széles; `sleeper`: alvó őr
## feje a párnán (a teste a pokróc alatt).
func _bed(tile: Vector2i, sleeper: bool) -> void:
	var holder := Node2D.new()
	holder.position = Vector2(tile) * TILE + Vector2(TILE, TILE)
	_entities.add_child(holder)
	var cot := _indoor(COT, Vector2(0, -TILE * 0.75), holder)
	cot.scale = Vector2(3, 3)
	_solid(Rect2(Vector2(tile) * TILE + Vector2(TILE * 0.25, 8), Vector2(TILE * 1.5, TILE * 0.85)))
	if not sleeper:
		return
	var frame := AtlasTexture.new()
	frame.atlas = GUARD_SHEET
	frame.region = Rect2(2, 8, 14, 13)
	var head := Sprite2D.new()
	head.texture = frame
	head.rotation = -PI / 2.0
	head.scale = Vector2(1.6, 1.6)
	head.position = Vector2(-TILE * 0.38, -TILE * 0.8)
	holder.add_child(head)


## Vas Szilárd hadnagy az asztalfőn (Lieutenant): beszélgetés, a parancsai (QuestPanel "lieutenant"), fölötte
## "!" az első beszélgetésig (TalkMark), zöld "?" ha van leadható parancs.
func _build_lieutenant(at: Vector2) -> void:
	_lieutenant_position = at
	var holder := Node2D.new()
	holder.position = at
	_entities.add_child(holder)
	var figure := AnimatedSprite2D.new()
	figure.sprite_frames = Lieutenant.frames()
	figure.scale = Vector2(2, 2)
	figure.offset = Vector2(0, -14)
	figure.play()
	holder.add_child(figure)
	TalkMark.attach(figure, Lieutenant.ID)
	_ready_mark = MenuStyle.title_label("?", 40, Color(0.55, 1.0, 0.55))
	_ready_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ready_mark.custom_minimum_size = Vector2(40, 0)
	_ready_mark.position = Vector2(-20, -100)
	_ready_mark.z_index = 5
	_ready_mark.visible = false
	holder.add_child(_ready_mark)
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(20, 10)
	shape.shape = box
	shape.position = Vector2(0, -5)
	body.add_child(shape)
	holder.add_child(body)
	_orders = QUEST_PANEL.new()
	_orders.name = "LieutenantOrders"
	_orders.set("giver", Lieutenant.ID)
	_camp.add_child.call_deferred(_orders)
	_dialogue = DialoguePanel.new()
	_dialogue.name = "LieutenantDialogue"
	_dialogue.npc_id = Lieutenant.ID
	_dialogue.npc_name = Lieutenant.NAME
	_dialogue.portrait = Lieutenant.portrait()
	_dialogue.greeting = Lieutenant.GREETING
	_dialogue.options_provider = func() -> Array[Dictionary]: return Lieutenant.options(_open_orders)
	_camp.add_child.call_deferred(_dialogue)


## "Mi a parancs?": a beszélgetés helyett a parancsok ablaka (itt lehet leadni is őket).
func _open_orders() -> String:
	var menus := _camp.get_node("Menus")
	menus.call("close_current")
	menus.call_deferred("open_menu", _orders)
	return ""


## Álló / ülő őr (lassan lélegzik), ütközővel.
func _soldier(at: Vector2, flip: bool) -> void:
	var holder := Node2D.new()
	holder.position = at
	_entities.add_child(holder)
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 3.0)
	for i in 4:
		var frame := AtlasTexture.new()
		frame.atlas = GUARD_SHEET
		frame.region = Rect2(i * 16, 0, 16, 28)
		frames.add_frame("default", frame)
	var guard := AnimatedSprite2D.new()
	guard.sprite_frames = frames
	guard.scale = Vector2(2, 2)
	guard.offset = Vector2(0, -14)
	guard.flip_h = flip
	guard.frame = randi() % 4
	guard.play()
	holder.add_child(guard)
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(20, 10)
	shape.shape = box
	shape.position = Vector2(0, -5)
	body.add_child(shape)
	holder.add_child(body)


func _crate(tile: Vector2i) -> void:
	var holder := Node2D.new()
	holder.position = _center(tile) + Vector2(0, 14)
	_entities.add_child(holder)
	var crate := _region(CONTAINERS, SMALL_CRATE, Vector2(0, -14), holder)
	crate.scale = Vector2(1.6, 1.6)
	_solid(Rect2(Vector2(tile) * TILE + Vector2(6, 10), Vector2(TILE - 12, TILE - 14)))


func _barrel(tile: Vector2i) -> void:
	var holder := Node2D.new()
	holder.position = _center(tile) + Vector2(0, 14)
	_entities.add_child(holder)
	_region(CONTAINERS, BARREL, Vector2(0, -16), holder).scale = Vector2(2, 2)
	_solid(Rect2(Vector2(tile) * TILE + Vector2(4, 8), Vector2(TILE - 8, TILE - 10)))


# ---------------------------------------------------------------- belépés

func _build_ui() -> void:
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


func _focus() -> Array:
	if not is_instance_valid(_player) or _busy:
		return []
	var at: Vector2 = _player.global_position
	if not _inside:
		if at.distance_to(door_position()) < INTERACT_RANGE:
			return ["enter", "[E] Belépés: barakk"]
		return []
	if at.distance_to(_center(INTERIOR_DOOR) + Vector2(TILE / 2.0, -TILE / 2.0)) < INTERACT_RANGE:
		return ["leave", "[E] Kilépés a szabadba"]
	if at.distance_to(_lieutenant_position) < TALK_RANGE:
		return ["talk", "[E] Beszélgetés: %s" % Lieutenant.NAME]
	return []


func _process(delta: float) -> void:
	var focus := _focus()
	if not focus.is_empty():
		_prompt.text = focus[1]
	var target := 1.0 if not focus.is_empty() and not GamePause.active(get_tree()) else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)
	# Zöld "?" a hadnagy fölött, ha van leadható parancs (fél mp-enként nézi).
	_mark_left -= delta
	if is_instance_valid(_ready_mark) and _mark_left <= 0.0:
		_mark_left = 0.5
		_ready_mark.visible = Progress.has_talked(Lieutenant.ID) and not Quests.ready_ids(Lieutenant.ID).is_empty()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or GamePause.active(get_tree()):
		return
	var focus := _focus()
	if focus.is_empty():
		return
	get_viewport().set_input_as_handled()
	match focus[0]:
		"enter":
			_move(true, _center(INTERIOR_DOOR) + Vector2(TILE / 2.0, -TILE * 1.2))
		"leave":
			_move(false, door_position() + Vector2(0, 30))
		"talk":
			Audio.play("ui_open")
			_camp.get_node("Menus").call("open_menu", _dialogue)


func _move(inside: bool, at: Vector2) -> void:
	_busy = true
	_inside = inside
	Audio.play("door_unlock", -4.0)
	var room := INTERIOR
	var limits := Rect2(Vector2(room.position - Vector2i(3, 4)) * TILE, Vector2(room.size + Vector2i(6, 8)) * TILE) \
		if inside else Rect2()
	_camp.call("teleport_player", at, limits, INSIDE_LIGHT if inside else Color.BLACK)
	await get_tree().create_timer(0.6).timeout
	_busy = false


# ---------------------------------------------------------------- segédek

func _center(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE


## Kenney RPG csempe (16 px, 2× nagyítva).
func _rpg(coords: Vector2i, at: Vector2, parent: Node) -> Sprite2D:
	return _region(RPG, Rect2(Vector2(coords) * 17.0, Vector2(16, 16)), at, parent, 2.0)


func _region(texture: Texture2D, region: Rect2, at: Vector2, parent: Node, size := 1.0) -> Sprite2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.scale = Vector2(size, size)
	sprite.position = at
	parent.add_child(sprite)
	return sprite


func _solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	add_child(body)


## Oldalfalak és a déli fal (az ajtónyílással), a hátsó fal ütközője.
func _walls(r: Rect2i) -> void:
	var dark := CANVAS.darkened(0.55)
	for rect: Rect2 in [Rect2(Vector2(r.position.x - 1, r.position.y - 1) * TILE, Vector2(TILE, (r.size.y + 2) * TILE)),
			Rect2(Vector2(r.end.x, r.position.y - 1) * TILE, Vector2(TILE, (r.size.y + 2) * TILE)),
			Rect2(Vector2(r.position.x, r.end.y) * TILE, Vector2((INTERIOR_DOOR.x - r.position.x) * TILE, TILE)),
			Rect2(Vector2(INTERIOR_DOOR.x + 2, r.end.y) * TILE, Vector2((r.end.x - INTERIOR_DOOR.x - 2) * TILE, TILE))]:
		var wall := ColorRect.new()
		wall.color = dark
		wall.position = rect.position
		wall.size = rect.size
		wall.z_index = -9
		add_child(wall)
		_solid(rect)
	_solid(Rect2(Vector2(r.position.x, r.position.y - 1) * TILE, Vector2(r.size.x * TILE, TILE * 1.6)))
	_solid(Rect2(Vector2(INTERIOR_DOOR.x, r.end.y + 1) * TILE, Vector2(2 * TILE, TILE)))


## Kenney Indoor csempe (16 px, 2× nagyítva).
func _indoor(coords: Vector2i, at: Vector2, parent: Node) -> Sprite2D:
	return _region(INDOOR, Rect2(Vector2(coords) * 17.0, Vector2(16, 16)), at, parent, 2.0)
