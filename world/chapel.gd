class_name Chapel
extends Node2D
## Régi kápolna a temető mellett (keletre, a városi út alatt): kőfalak, palatető, elöl egy kis
## harangtorony kereszttel, színes ablakok. Kopott és poros, de nem omlott össze. Bent padsorok,
## kifakult szőnyeg, oltár gyertyákkal, az ablakokon át fénysávok szállnak a porban. A sírásó
## (Gravedigger) a küldetése elfogadása után ide költözik; a Szent kereszt után a kereszt az
## oltár fölött lóg. (A tábor építi fel: setup(camp) + build(), mint a Romos házat.)

signal message(text: String)

const TILE := 32
const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const DUNGEON: Texture2D = preload("res://assets/0x72_dungeon/0x72_DungeonTilesetII_v1.7.png")
const COBWEB: Texture2D = preload("res://assets/decor/cobweb.png")
## A kápolna a temetőtől keletre (az ajtaja délre néz); a torony nem ér fel az útig.
const TOP_LEFT := Vector2i(79, 22)
const SIZE := Vector2i(6, 5)
const DOOR_COLUMN := 81
const STONE := Color(0.76, 0.72, 0.67)
const SLATE := Color(0.66, 0.7, 0.82)
## 0x72: kőfal, padló.
const WALL_MID := Rect2(32, 16, 16, 16)
const WALL_TOP := Rect2(32, 0, 16, 16)
const FLOOR_TILES: Array[Rect2] = [Rect2(16, 64, 16, 16), Rect2(32, 64, 16, 16), Rect2(48, 64, 16, 16),
	Rect2(16, 80, 16, 16)]
## A belső tér messze a pályától (mint a többi épület belseje).
const INTERIOR := Rect2i(420, 0, 12, 10)
const INTERIOR_DOOR := Vector2i(425, 10)
const ALTAR_TILE := Vector2i(425, 1)
const VENDEL_TILE := Vector2i(423, 2)
## Bent félhomály (gyertyák és az ablakok fénye).
const INSIDE_LIGHT := Color(0.3, 0.27, 0.27)
const LANTERN_INSIDE := 0.5
const LANTERN_OUTSIDE := 0.5
const INTERACT_RANGE := 52.0
const TALK_RANGE := 70.0

var _camp: Node2D
var _player: Node2D
var _entities: Node2D
var _prompt: Label
var _dialogue: DialoguePanel
var _inside := false
var _busy := false
var _rng := RandomNumberGenerator.new()
var _vendel: Node2D
var _cross: Node2D


func setup(camp: Node2D) -> void:
	_camp = camp
	_entities = camp.get_node("Entities")
	_player = camp.get_node("Entities/Player")
	_dialogue = DialoguePanel.new()
	_dialogue.name = "ChapelDialogue"
	_dialogue.npc_id = Gravedigger.ID
	_dialogue.npc_name = Gravedigger.NAME
	_dialogue.portrait = Gravedigger.portrait()
	_dialogue.options_provider = func() -> Array[Dictionary]:
		return Gravedigger.options(_player.get_node("Inventory"))
	camp.add_child.call_deferred(_dialogue)


## Ide nem kerülhet fa / bokor (a kápolna, a torony és előtte a tér a város széléig).
static func blocked_rect() -> Rect2i:
	return Rect2i(TOP_LEFT - Vector2i(2, 3), SIZE + Vector2i(4, 7))


static func door_position() -> Vector2:
	return Vector2(DOOR_COLUMN + 1, TOP_LEFT.y + SIZE.y) * TILE + Vector2(0, 16)


func build() -> void:
	_rng.seed = 4242
	_build_exterior()
	_build_interior()
	_build_ui()


# ---------------------------------------------------------------- kívül

func _build_exterior() -> void:
	var tl := TOP_LEFT
	var w := SIZE.x
	for x in w:
		var piece := 0 if x == 0 else (2 if x == w - 1 else 1)
		_tile(Town.ROOF_TOP[piece], tl + Vector2i(x, 0), -6).modulate = SLATE
		_tile(Town.ROOF_MID[piece], tl + Vector2i(x, 1), -6).modulate = SLATE
		_tile(Town.ROOF_LOW[piece], tl + Vector2i(x, 2), -6).modulate = SLATE.darkened(0.08)
		for y in [3, 4]:
			_dungeon(WALL_MID, tl + Vector2i(x, y), -6).modulate = STONE.darkened(_rng.randf_range(0.0, 0.1))
	# Egy-két hiányzó palacserép (alatta sötét léc).
	for spot: Vector2 in [Vector2(1.3, 1.2), Vector2(4.6, 0.7)]:
		_rect(Rect2(Vector2(tl) * TILE + spot * TILE, Vector2(12, 8)), -5, Color(0.16, 0.13, 0.12))
	# A homlokzat: kapu, csúcsíves ablakok, repedések, moha, torony (rajzolva).
	var front := ChapelFront.new()
	front.position = Vector2(tl) * TILE
	front.z_index = -5
	add_child(front)
	for i in 2:
		var leaf := _tile(Town.DOUBLE_DOOR[i], Vector2i(DOOR_COLUMN + i, tl.y + 4), -4)
		leaf.modulate = Color(0.62, 0.5, 0.42)
	_cobweb(tl + Vector2i(0, 3), false, false, -4)
	_cobweb(tl + Vector2i(w - 1, 3), true, false, -4)
	# Néhány lehullott kő a fal tövében, és egy kidőlt kő mellett gaz.
	for i in 4:
		var stone := ColorRect.new()
		stone.color = STONE.darkened(_rng.randf_range(0.15, 0.35))
		stone.size = Vector2(_rng.randf_range(6, 11), _rng.randf_range(4, 7))
		stone.position = Vector2(tl.x + [0.2, 0.7, 4.8, 5.4][i], tl.y + 5.05) * TILE + Vector2(0, _rng.randf_range(0, 6))
		stone.z_index = -4
		add_child(stone)
	_solid(Rect2(Vector2(tl) * TILE, Vector2(SIZE) * TILE - Vector2(0, 6)))


# ---------------------------------------------------------------- bent

func _build_interior() -> void:
	var r := INTERIOR
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			var floor_tile := _region_sprite(DUNGEON, FLOOR_TILES[_rng.randi() % FLOOR_TILES.size()], _center(Vector2i(x, y)), -10)
			floor_tile.modulate = Color(0.66, 0.6, 0.55).darkened(_rng.randf_range(0.0, 0.12))
	# Hátsó fal (kő), oldalfalak és a déli fal a kapuval.
	for x in range(r.position.x, r.end.x):
		_region_sprite(DUNGEON, WALL_TOP, _center(Vector2i(x, r.position.y - 2)), -9).modulate = STONE
		_region_sprite(DUNGEON, WALL_MID, _center(Vector2i(x, r.position.y - 1)), -9).modulate = STONE
		_region_sprite(DUNGEON, WALL_MID, _center(Vector2i(x, r.position.y)), -9).modulate = STONE.darkened(0.08)
	var dark := Color(0.1, 0.08, 0.08)
	for rect: Rect2 in [Rect2(Vector2(r.position.x - 1, r.position.y - 2) * TILE, Vector2(TILE, (r.size.y + 3) * TILE)),
			Rect2(Vector2(r.end.x, r.position.y - 2) * TILE, Vector2(TILE, (r.size.y + 3) * TILE)),
			Rect2(Vector2(r.position.x, r.end.y) * TILE, Vector2((INTERIOR_DOOR.x - r.position.x) * TILE, TILE)),
			Rect2(Vector2(INTERIOR_DOOR.x + 2, r.end.y) * TILE, Vector2((r.end.x - INTERIOR_DOOR.x - 2) * TILE, TILE))]:
		_rect(rect, -9, dark)
		_solid(rect)
	_solid(Rect2(Vector2(r.position.x, r.position.y - 2) * TILE, Vector2(r.size.x * TILE, TILE * 2.6)))
	_solid(Rect2(Vector2(INTERIOR_DOOR.x, r.end.y + 1) * TILE, Vector2(2 * TILE, TILE)))
	for i in 2:
		_tile(Town.DOUBLE_DOOR[i], Vector2i(INTERIOR_DOOR.x + i, r.end.y), -8).modulate = Color(0.6, 0.5, 0.42)
	# A hátsó fal díszei: két színes ablak, közöttük a kereszt helye (rajzolva).
	var wall := ChapelWall.new()
	wall.position = Vector2(r.position) * TILE
	wall.width = r.size.x * TILE
	wall.z_index = -8
	add_child(wall)
	_cross = HolyCross.new()
	_cross.position = Vector2(ALTAR_TILE.x + 1, r.position.y - 0.15) * TILE
	_cross.z_index = -7
	add_child(_cross)
	# Kifakult vörös szőnyeg a kaputól az oltárig, foltokkal.
	var carpet := ColorRect.new()
	carpet.color = Color(0.42, 0.14, 0.13)
	carpet.position = Vector2(INTERIOR_DOOR.x, r.position.y + 2) * TILE + Vector2(6, 0)
	carpet.size = Vector2(2 * TILE - 12, (r.size.y - 2) * TILE)
	carpet.z_index = -9
	add_child(carpet)
	for i in 5:
		var stain := ColorRect.new()
		stain.color = Color(0.55, 0.48, 0.42, 0.35)
		stain.size = Vector2(_rng.randf_range(10, 24), _rng.randf_range(6, 14))
		stain.position = carpet.position + Vector2(_rng.randf_range(0, carpet.size.x - 24), _rng.randf_range(0, carpet.size.y - 14))
		stain.z_index = -9
		add_child(stain)
	# Porfoltok a padlón.
	for i in 14:
		var dust := ColorRect.new()
		dust.color = Color(0.75, 0.7, 0.62, 0.12)
		dust.size = Vector2(_rng.randf_range(18, 46), _rng.randf_range(10, 22))
		dust.position = Vector2(r.position) * TILE + Vector2(_rng.randf_range(0, r.size.x * TILE - 46), _rng.randf_range(TILE, r.size.y * TILE - 22))
		dust.z_index = -9
		add_child(dust)
	# Az oltár: kőtömb, rajta fehér (porszürke) terítő és gyertyák.
	var altar := Altar.new()
	altar.position = Vector2(ALTAR_TILE.x + 1, r.position.y + 1.75) * TILE
	_entities.add_child(altar)
	_solid(Rect2(Vector2(ALTAR_TILE.x, r.position.y + 1) * TILE + Vector2(-8, 4), Vector2(2 * TILE + 16, TILE * 0.7)))
	for side in [-1, 1]:
		var candle := _tile(Town.CANDLE, Vector2i(ALTAR_TILE.x + (0 if side < 0 else 1), r.position.y + 1), 0, altar)
		candle.position = Vector2(side * 26, -30)
		candle.scale = Vector2(1.6, 1.6)
		_light(altar.position + Vector2(side * 26, -34), Color(1.0, 0.75, 0.45), 1.2, 0.4)
	# Gyertyatartók a padsorok előtt.
	for x in [r.position.x + 1, r.end.x - 2]:
		var stand := _tile(Town.CANDLE, Vector2i(x, r.position.y + 1), 0, _entities)
		stand.position.y += 8
		_light(stand.position, Color(1.0, 0.72, 0.42), 1.1, 0.45)
	# Padsorok két oldalt; az egyik kidőlt, egy másiknak letört a vége.
	var rows := [3, 5, 7]
	for row: int in rows:
		for left in [true, false]:
			var x0 := r.position.x + 1 if left else INTERIOR_DOOR.x + 3
			var pew := Pew.new()
			pew.position = Vector2(x0, r.position.y + row) * TILE + Vector2(0, TILE * 0.8)
			pew.length = 3 * TILE - 8
			pew.broken = row == 5 and not left
			_entities.add_child(pew)
			if row == 7 and left:
				pew.rotation = 0.35
				pew.position += Vector2(6, 10)
			_solid(Rect2(pew.position + Vector2(0, -16), Vector2(pew.length, 14)))
	# Pókhálók a sarkokban, lehullott kövek, egy seprű a falnak támasztva.
	_cobweb(Vector2i(r.position.x, r.position.y), false, false, -7)
	_cobweb(Vector2i(r.end.x - 1, r.position.y), true, false, -7)
	_cobweb(Vector2i(r.position.x, r.end.y - 1), false, true, -7)
	_cobweb(Vector2i(r.end.x - 1, r.end.y - 1), true, true, -7)
	for i in 6:
		var stone := ColorRect.new()
		stone.color = STONE.darkened(_rng.randf_range(0.2, 0.4))
		stone.size = Vector2(_rng.randf_range(5, 10), _rng.randf_range(4, 7))
		stone.position = Vector2(r.end.x - 1.6, r.position.y + 1.2) * TILE + Vector2(_rng.randf_range(-20, 20), _rng.randf_range(-6, 16))
		stone.z_index = -8
		add_child(stone)
	var broom := Broom.new()
	broom.position = Vector2(r.position.x + 0.5, r.position.y + 1.4) * TILE
	broom.z_index = -7
	add_child(broom)
	# Porszemcsék lebegnek a fényben.
	var motes := CPUParticles2D.new()
	motes.position = Vector2(r.position.x + r.size.x / 2.0, r.position.y + r.size.y / 2.0) * TILE
	motes.amount = 40
	motes.lifetime = 7.0
	motes.preprocess = 7.0
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(r.size) * TILE / 2.0
	motes.gravity = Vector2(0, 2)
	motes.direction = Vector2(1, -0.3)
	motes.spread = 180.0
	motes.initial_velocity_min = 2.0
	motes.initial_velocity_max = 6.0
	motes.scale_amount_min = 1.0
	motes.scale_amount_max = 2.0
	motes.color = Color(1.0, 0.93, 0.78, 0.35)
	motes.z_index = 3
	add_child(motes)
	# Vendel az oltár mellett (csak ha már ide költözött).
	_vendel = Node2D.new()
	_vendel.position = _center(VENDEL_TILE) + Vector2(0, 14)
	_entities.add_child(_vendel)
	Gravedigger.build_figure(_vendel)
	_vendel.visible = Gravedigger.in_chapel()


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


## Ami előtt a játékos áll: [művelet, felirat] vagy [].
func _focus() -> Array:
	if not is_instance_valid(_player) or _busy:
		return []
	var at: Vector2 = _player.global_position
	if not _inside:
		if at.distance_to(door_position()) < INTERACT_RANGE:
			return ["enter", "[E] Belépés: régi kápolna"]
		return []
	if at.distance_to(_center(INTERIOR_DOOR) + Vector2(TILE / 2.0, TILE / 2.0)) < INTERACT_RANGE:
		return ["leave", "[E] Kilépés a szabadba"]
	if _vendel.visible and at.distance_to(_vendel.position) < TALK_RANGE:
		return ["talk", "[E] Beszélgetés: %s" % Gravedigger.SHORT_NAME]
	return []


func _process(delta: float) -> void:
	if not get_tree().paused:
		_vendel.visible = Gravedigger.in_chapel()
		_cross.visible = Progress.npc_quest_state(Gravedigger.CROSS_QUEST) == "done"
	var focus := _focus()
	if not focus.is_empty():
		_prompt.text = focus[1]
	var target := 1.0 if not focus.is_empty() and not get_tree().paused else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or get_tree().paused:
		return
	var focus := _focus()
	if focus.is_empty():
		return
	get_viewport().set_input_as_handled()
	match focus[0]:
		"enter":
			_move(true, _center(INTERIOR_DOOR) + Vector2(TILE / 2.0, -TILE))
		"leave":
			_move(false, door_position() + Vector2(0, 30))
		"talk":
			Audio.play("ui_open")
			_dialogue.greeting = Gravedigger.greeting()
			_camp.get_node("Menus").call("open_menu", _dialogue)


func _move(inside: bool, at: Vector2) -> void:
	_busy = true
	_inside = inside
	Audio.play("door_unlock", -4.0)
	var room := INTERIOR
	var limits := Rect2(Vector2(room.position - Vector2i(3, 4)) * TILE, Vector2(room.size + Vector2i(6, 8)) * TILE) \
		if inside else Rect2()
	_camp.call("teleport_player", at, limits, INSIDE_LIGHT if inside else Color.BLACK)
	await get_tree().create_timer(0.25).timeout
	_player.get_node("PointLight2D").energy = LANTERN_INSIDE if inside else LANTERN_OUTSIDE
	await get_tree().create_timer(0.35).timeout
	_busy = false


# ---------------------------------------------------------------- segédek

func _center(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE


func _tile(coords: Vector2i, tile: Vector2i, z: int, parent: Node = null) -> Sprite2D:
	return _region_sprite(RPG, Rect2(Vector2(coords) * 17.0, Vector2(16, 16)), _center(tile), z, parent)


func _dungeon(region: Rect2, tile: Vector2i, z: int) -> Sprite2D:
	return _region_sprite(DUNGEON, region, _center(tile), z)


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


func _rect(rect: Rect2, z: int, color: Color) -> void:
	var box := ColorRect.new()
	box.color = color
	box.position = rect.position
	box.size = rect.size
	box.z_index = z
	add_child(box)


func _solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	add_child(body)


func _cobweb(tile: Vector2i, flip_h: bool, flip_v: bool, z: int) -> void:
	var web := Sprite2D.new()
	web.texture = COBWEB
	web.scale = Vector2(2, 2)
	web.position = _center(tile)
	web.flip_h = flip_h
	web.flip_v = flip_v
	web.z_index = z
	web.modulate = Color(1, 1, 1, 0.75)
	add_child(web)


## Gyertyafény (sugaras színátmenetes PointLight2D).
func _light(at: Vector2, color: Color, size: float, energy: float) -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(0, 0, 0, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	texture.width = 256
	texture.height = 256
	var light := PointLight2D.new()
	light.texture = texture
	light.texture_scale = size
	light.energy = energy
	light.position = at
	add_child(light)


## Csúcsíves színes ablak (ólomkeretes, poros üveg): a talppontja (bal alsó sarok) körül.
static func draw_lancet(canvas: CanvasItem, at: Vector2, size: Vector2, dim: float) -> void:
	var half := size.x / 2.0
	var outline := PackedVector2Array([at, at + Vector2(0, -size.y + half), at + Vector2(half, -size.y),
		at + Vector2(size.x, -size.y + half), at + Vector2(size.x, 0)])
	canvas.draw_colored_polygon(outline, Color(0.2, 0.17, 0.16))
	var glass_colors := [Color(0.25, 0.35, 0.7), Color(0.65, 0.2, 0.2), Color(0.75, 0.62, 0.25), Color(0.3, 0.55, 0.35)]
	var inner := Rect2(at + Vector2(3, -size.y + half), Vector2(size.x - 6, size.y - half - 3))
	var rows := 3
	for row in rows:
		for col in 2:
			var cell := Rect2(inner.position + Vector2(col * inner.size.x / 2.0, row * inner.size.y / rows),
				Vector2(inner.size.x / 2.0 - 1, inner.size.y / rows - 1))
			canvas.draw_rect(cell, (glass_colors[(row + col) % glass_colors.size()] as Color).darkened(dim))
	canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(3, -size.y + half), at + Vector2(half, -size.y + 3),
		at + Vector2(size.x - 3, -size.y + half)]), glass_colors[2].darkened(dim))
	# Por az üvegen.
	canvas.draw_rect(inner, Color(0.7, 0.66, 0.6, 0.18))


## A homlokzat rajza (a kápolna bal felső sarkához képest): csúcsíves kapu, ablakok, repedések,
## moha, és a harangtorony kereszttel.
class ChapelFront:
	extends Node2D

	func _draw() -> void:
		var t := float(TILE)
		var stone := STONE
		# Palacserepek a tetőn: soronként eltolt, sötétebb illesztések.
		for row in 11:
			var y := 4.0 + row * 8.0
			# A felső sor sarkai ferdék (kontyolt tető): ott beljebb kezdődnek a sorok.
			var inset := maxf(2.0, t - y)
			draw_line(Vector2(inset, y), Vector2(SIZE.x * t - inset, y), SLATE.darkened(0.45), 1.0)
			var shift := 0.0 if row % 2 == 0 else 7.0
			var x := inset + 2.0 + shift
			while x < SIZE.x * t - inset - 2.0:
				draw_line(Vector2(x, y), Vector2(x, y + 8), SLATE.darkened(0.35), 1.0)
				x += 14.0
		# Kapu: csúcsíves kőkeret, mögötte sötét.
		var door := Vector2((DOOR_COLUMN - TOP_LEFT.x) * t, 5 * t)
		var arch := PackedVector2Array([door, door + Vector2(0, -1.25 * t), door + Vector2(t, -1.75 * t),
			door + Vector2(2 * t, -1.25 * t), door + Vector2(2 * t, 0)])
		draw_colored_polygon(PackedVector2Array([door + Vector2(-5, 0), door + Vector2(-5, -1.3 * t),
			door + Vector2(t, -1.95 * t), door + Vector2(2 * t + 5, -1.3 * t), door + Vector2(2 * t + 5, 0)]), stone.lightened(0.1))
		draw_colored_polygon(arch, Color(0.07, 0.05, 0.05))
		# Csúcsíves ablakok a kapu két oldalán.
		for x in [0.75, 4.75]:
			Chapel.draw_lancet(self, Vector2(x * t, 4.8 * t), Vector2(0.55 * t, 1.5 * t), 0.35)
		# Repedések és moha a falon.
		var crack := Color(0.25, 0.22, 0.2)
		draw_polyline(PackedVector2Array([Vector2(1.7 * t, 3.1 * t), Vector2(1.85 * t, 3.5 * t), Vector2(1.75 * t, 3.8 * t),
			Vector2(1.95 * t, 4.2 * t)]), crack, 2.0)
		draw_polyline(PackedVector2Array([Vector2(4.3 * t, 3.0 * t), Vector2(4.15 * t, 3.35 * t), Vector2(4.3 * t, 3.6 * t)]), crack, 2.0)
		var moss := Color(0.3, 0.42, 0.22, 0.85)
		for spot: Vector2 in [Vector2(0.1, 4.75), Vector2(0.4, 4.85), Vector2(5.5, 4.7), Vector2(3.9, 4.85), Vector2(2.6, 3.05)]:
			draw_rect(Rect2(spot * t, Vector2(10, 6)), moss)
			draw_rect(Rect2(spot * t + Vector2(4, -3), Vector2(6, 4)), moss.darkened(0.2))
		# Harangtorony a tető közepén, elöl: kőtorony, harangablak, palasüveg, kereszt.
		var cx := 3.0 * t
		var tower := Rect2(cx - 22, -1.0 * t, 44, 1.9 * t)
		draw_rect(tower, stone)
		for row in 5:
			var y := tower.position.y + row * 12.0
			draw_line(Vector2(tower.position.x, y), Vector2(tower.end.x, y), stone.darkened(0.2), 1.0)
			var offset := 0.0 if row % 2 == 0 else 11.0
			for k in 3:
				var x := tower.position.x + offset + k * 22.0
				if x > tower.position.x and x < tower.end.x:
					draw_line(Vector2(x, y), Vector2(x, y + 12), stone.darkened(0.2), 1.0)
		draw_rect(tower, stone.darkened(0.35), false, 2.0)
		# Harangablak, benne a harang.
		var bell_arch := PackedVector2Array([Vector2(cx - 10, -0.05 * t), Vector2(cx - 10, -0.5 * t), Vector2(cx, -0.75 * t),
			Vector2(cx + 10, -0.5 * t), Vector2(cx + 10, -0.05 * t)])
		draw_colored_polygon(bell_arch, Color(0.08, 0.06, 0.06))
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 7, -0.12 * t), Vector2(cx - 5, -0.42 * t), Vector2(cx, -0.5 * t),
			Vector2(cx + 5, -0.42 * t), Vector2(cx + 7, -0.12 * t)]), Color(0.62, 0.5, 0.25))
		# Kis kerek rózsaablak a torony alján.
		var rose := Vector2(cx, 0.55 * t)
		draw_circle(rose, 9.0, Color(0.2, 0.17, 0.16))
		var petals := [Color(0.6, 0.2, 0.2), Color(0.25, 0.35, 0.65), Color(0.7, 0.6, 0.25)]
		for k in 6:
			draw_circle(rose + Vector2.from_angle(k * TAU / 6.0) * 4.5, 3.0, (petals[k % 3] as Color).darkened(0.3))
		draw_circle(rose, 2.5, Color(0.75, 0.65, 0.3))
		# Palasüveg és a kereszt a csúcsán.
		var spire := PackedVector2Array([Vector2(cx - 27, tower.position.y + 2), Vector2(cx, tower.position.y - 0.95 * t),
			Vector2(cx + 27, tower.position.y + 2)])
		draw_colored_polygon(spire, SLATE.darkened(0.15))
		draw_line(Vector2(cx, tower.position.y - 0.95 * t), Vector2(cx + 27, tower.position.y + 2), SLATE.darkened(0.4), 2.0)
		draw_polyline(spire, SLATE.darkened(0.5), 1.5)
		var top := Vector2(cx, tower.position.y - 0.95 * t)
		var iron := Color(0.35, 0.33, 0.32)
		draw_rect(Rect2(top + Vector2(-2, -20), Vector2(4, 22)), iron)
		draw_rect(Rect2(top + Vector2(-8, -15), Vector2(16, 4)), iron)


## A belső hátsó fal díszei: két csúcsíves ablak, a fényük ferdén hull a padlóra, és a
## kereszt helye az oltár fölött (világosabb folt a falon, egy szög).
class ChapelWall:
	extends Node2D
	var width := 0.0

	func _draw() -> void:
		var t := float(TILE)
		for x in [1.6, 9.6]:
			var base := Vector2(x * t, 0.9 * t)
			Chapel.draw_lancet(self, base, Vector2(0.8 * t, 2.2 * t), 0.15)
			# Fénysáv a padlóra.
			draw_colored_polygon(PackedVector2Array([base + Vector2(4, -0.2 * t), base + Vector2(0.8 * t - 4, -0.2 * t),
				base + Vector2(1.9 * t, 4.2 * t), base + Vector2(0.6 * t, 4.2 * t)]), Color(1.0, 0.9, 0.65, 0.09))
		var mark := Vector2((ALTAR_TILE.x - INTERIOR.position.x + 1) * t, -0.15 * t)
		draw_rect(Rect2(mark + Vector2(-5, -22), Vector2(10, 46)), Color(0.86, 0.82, 0.76, 0.35))
		draw_rect(Rect2(mark + Vector2(-16, -12), Vector2(32, 9)), Color(0.86, 0.82, 0.76, 0.35))
		draw_circle(mark + Vector2(0, -26), 2.0, Color(0.25, 0.22, 0.2))


## A kereszt az oltár fölött (a Szent kereszt amulett átadása után): arany, halványan fénylik.
class HolyCross:
	extends Node2D
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var glow := 0.18 + 0.08 * sin(_t * 2.0)
		draw_circle(Vector2.ZERO, 30.0, Color(1.0, 0.85, 0.4, glow))
		var gold := Color(0.9, 0.72, 0.28)
		draw_rect(Rect2(Vector2(-4, -22), Vector2(8, 46)), gold.darkened(0.3))
		draw_rect(Rect2(Vector2(-15, -12), Vector2(30, 8)), gold.darkened(0.3))
		draw_rect(Rect2(Vector2(-3, -21), Vector2(6, 44)), gold)
		draw_rect(Rect2(Vector2(-14, -11), Vector2(28, 6)), gold)
		draw_line(Vector2(0, -26), Vector2(0, -22), Color(0.25, 0.22, 0.2), 1.5)


## Az oltár: kőtömb (a talppontja a közepe alján), rajta poros fehér terítő.
class Altar:
	extends Node2D

	func _draw() -> void:
		var t := float(TILE)
		draw_rect(Rect2(-t - 6, -t * 0.95, 2 * t + 12, t * 0.95), STONE.darkened(0.15))
		draw_rect(Rect2(-t - 6, -t * 0.95, 2 * t + 12, t * 0.95), STONE.darkened(0.45), false, 2.0)
		draw_rect(Rect2(-t - 10, -t * 1.05, 2 * t + 20, 8), STONE)
		draw_rect(Rect2(-t + 2, -t * 1.08, 2 * t - 4, 24), Color(0.68, 0.64, 0.57))
		draw_rect(Rect2(-6, -t * 1.08 + 4, 12, 14), Color(0.6, 0.18, 0.16))
		draw_line(Vector2(-t + 6, -t * 0.62), Vector2(-t + 14, -t * 0.62), Color(0.7, 0.66, 0.6), 1.0)


## Templomi pad (fa ülés, magas háttámla); `broken`: a jobb vége letört.
class Pew:
	extends Node2D
	var length := 88.0
	var broken := false

	func _draw() -> void:
		var wood := Color(0.36, 0.24, 0.16)
		var end := length - (24.0 if broken else 0.0)
		draw_rect(Rect2(0, -30, end, 12), wood.darkened(0.25))
		draw_rect(Rect2(0, -18, end, 10), wood)
		draw_rect(Rect2(0, -8, end, 4), wood.darkened(0.4))
		for x in [2.0, end - 8.0]:
			draw_rect(Rect2(x, -32, 6, 30), wood.darkened(0.15))
		# Por a tetején.
		draw_rect(Rect2(2, -30, end - 4, 2), Color(0.75, 0.7, 0.62, 0.5))
		if broken:
			draw_colored_polygon(PackedVector2Array([Vector2(end, -18), Vector2(end + 8, -12), Vector2(end, -8)]), wood)
			draw_rect(Rect2(end + 14, -6, 12, 5), wood.darkened(0.2))


## Seprű a falnak támasztva.
class Broom:
	extends Node2D

	func _draw() -> void:
		draw_line(Vector2(0, 0), Vector2(10, -40), Color(0.45, 0.32, 0.2), 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(-7, 8), Vector2(-2, -4), Vector2(4, -2), Vector2(5, 10)]),
			Color(0.7, 0.58, 0.32))
