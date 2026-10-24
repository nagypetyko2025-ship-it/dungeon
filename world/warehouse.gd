class_name Warehouse
extends Node2D
## Régi raktárház a kórháztól jobbra (a város keleti, új részén). Kívül kopott, szürkésbarna fal,
## dupla ajtó, "Raktár" tábla, a fal mellett hordók. Bent poros, félhomályos raktár: egymásra rakott
## ládák és hordók, vasalt rakodóládák, polcok cserépedényekkel, egy üst, egy régi láda, pókhálók,
## porfoltok a padlón, az ablakon beeső fénysáv és lassan szálló porszemek.
## Képek: assets/shop (Kenney RPG, "Various Containers"), assets/props/storage.png (CC0).
## (A tábor építi fel: setup(camp) + build().)

const TILE := 32
const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const CONTAINERS: Texture2D = preload("res://assets/shop/barrels_and_boxes.png")
const POTTERY: Texture2D = preload("res://assets/shop/pottery.png")
const STORAGE: Texture2D = preload("res://assets/props/storage.png")
const COBWEB: Texture2D = preload("res://assets/decor/cobweb.png")
const TOP_LEFT := Vector2i(89, 9)
const SIZE := Vector2i(6, 5)
const DOOR_TILE := Vector2i(TOP_LEFT.x + SIZE.x / 2, TOP_LEFT.y + SIZE.y - 1)
const WALL_TINT := Color(0.72, 0.66, 0.58)
const ROOF_TINT := Color(0.55, 0.5, 0.48)
## A belső tér (messze a világ szélén, mint a többi épületé).
const INTERIOR := Rect2i(540, 0, 14, 9)
const INTERIOR_DOOR := Vector2i(546, 9)
const INSIDE_LIGHT := Color(0.36, 0.33, 0.3)
const INTERACT_RANGE := 52.0
## Képrészletek.
const BARREL := Rect2(0, 0, 16, 16)
const BIG_CRATE := Rect2(16, 0, 16, 16)
const SMALL_CRATE := Rect2(32, 0, 16, 16)
const OLD_CHEST := Rect2(0, 0, 16, 16)
const CARGO_A := Rect2(16, 0, 16, 16)
const CARGO_B := Rect2(32, 0, 16, 16)
const CAULDRON := Rect2(48, 0, 16, 16)
const JARS: Array[Rect2] = [Rect2(0, 0, 16, 16), Rect2(16, 16, 16, 16), Rect2(32, 0, 16, 16), Rect2(48, 32, 16, 16)]

var _camp: Node2D
var _player: Node2D
var _entities: Node2D
var _prompt: Label
var _inside := false
var _busy := false
var _rng := RandomNumberGenerator.new()


func setup(camp: Node2D) -> void:
	_camp = camp
	_entities = camp.get_node("Entities")
	_player = camp.get_node("Entities/Player")


## Ide nem kerülhet fa, virág, bokor (a ház és előtte egy sáv).
static func blocked_rect() -> Rect2i:
	return Rect2i(TOP_LEFT - Vector2i(1, 2), SIZE + Vector2i(2, 4))


static func door_position() -> Vector2:
	return Vector2(DOOR_TILE.x + 0.5, DOOR_TILE.y + 1) * TILE + Vector2(0, 12)


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
		_tile(Town.ROOF_TOP[piece], tl + Vector2i(x, 0), -6).modulate = ROOF_TINT
		_tile(Town.ROOF_MID[piece], tl + Vector2i(x, 1), -6).modulate = ROOF_TINT
		_tile(Town.ROOF_LOW[piece], tl + Vector2i(x, 2), -6).modulate = ROOF_TINT
		_tile(Town.WALL_BAND, tl + Vector2i(x, 3), -6).modulate = WALL_TINT
		_tile(Town.WALL_BOARDS, tl + Vector2i(x, 4), -6).modulate = WALL_TINT
	_tile(Town.WINDOW, tl + Vector2i(1, 3), -5).modulate = Color(0.7, 0.7, 0.7)
	_tile(Town.DOUBLE_DOOR[0], DOOR_TILE, -5).modulate = Color(0.85, 0.8, 0.75)
	var sign_text := Label.new()
	sign_text.text = "Raktár"
	sign_text.add_theme_font_override("font", MenuStyle.TITLE_FONT)
	sign_text.add_theme_font_size_override("font_size", 17)
	sign_text.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7))
	sign_text.add_theme_color_override("font_outline_color", Color(0.18, 0.1, 0.06))
	sign_text.add_theme_constant_override("outline_size", 4)
	sign_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign_text.size = Vector2(110, 22)
	sign_text.position = Vector2(DOOR_TILE.x + 0.5, tl.y + 2.6) * TILE - Vector2(55, 11)
	sign_text.z_index = -3
	var board := ColorRect.new()
	board.color = Color(0.36, 0.22, 0.12)
	board.size = Vector2(96, 22)
	board.position = sign_text.position + Vector2(7, 0)
	board.z_index = -4
	add_child(board)
	add_child(sign_text)
	# Hordók és ládák a fal mellett, kívül.
	_sprite(CONTAINERS, BARREL, _center(tl + Vector2i(w, 4)) + Vector2(2, 10), -4)
	_sprite(CONTAINERS, BARREL, _center(tl + Vector2i(w, 4)) + Vector2(18, 14), -4)
	_sprite(CONTAINERS, BIG_CRATE, _center(tl + Vector2i(-1, 4)) + Vector2(-2, 10), -4)
	_solid(Rect2(Vector2(tl) * TILE, Vector2(SIZE) * TILE - Vector2(0, 6)))


# ---------------------------------------------------------------- bent

func _build_interior() -> void:
	var r := INTERIOR
	# Kopott, poros deszkapadló; a hátsó fal sötét deszka.
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			_tile(Town.FLOOR_TILES[(x + y) % 2], Vector2i(x, y), -10).modulate = Color(0.6, 0.55, 0.5)
		_tile(Town.WALL_BAND, Vector2i(x, r.position.y - 1), -9).modulate = Color(0.55, 0.5, 0.45)
		_tile(Town.WALL_BOARDS, Vector2i(x, r.position.y), -9).modulate = Color(0.5, 0.45, 0.4)
	var window := r.position.x + 3
	_tile(Town.WINDOW, Vector2i(window, r.position.y - 1), -8).modulate = Color(0.75, 0.75, 0.7)
	_walls(r)
	_dust_patches(r)
	_light_beam(Vector2(window + 0.5, r.position.y) * TILE)
	# Bal oldal: egymásra rakott ládák és hordók.
	_stack(Vector2i(r.position.x, r.position.y + 1), [BIG_CRATE, SMALL_CRATE, BIG_CRATE], CONTAINERS)
	_stack(Vector2i(r.position.x + 1, r.position.y + 1), [BARREL, BARREL], CONTAINERS)
	_stack(Vector2i(r.position.x, r.position.y + 3), [BARREL, BARREL, BARREL], CONTAINERS)
	_stack(Vector2i(r.position.x, r.position.y + 6), [CARGO_A, CARGO_B], STORAGE)
	_stack(Vector2i(r.position.x + 1, r.position.y + 7), [SMALL_CRATE], CONTAINERS)
	# Az ablak alatt egy asztal két székkel (a harmadik eldőlve hever előtte), rajta poros üvegek.
	var table_tile := Vector2i(window, r.position.y + 2)
	var table := _tile_in(Town.TABLE, table_tile, _entities)
	table.modulate = Color(0.8, 0.76, 0.7)
	_solid(Rect2(Vector2(table_tile) * TILE + Vector2(4, 8), Vector2(TILE - 8, TILE - 12)))
	for i in 3:
		var bottle := _sprite(RPG, Rect2(Vector2(Town.DRINKS[i % Town.DRINKS.size()]) * 17.0, Vector2(16, 16)),
			Vector2(-5 + i * 5, -6 - (i % 2)), 1, table)
		bottle.scale = Vector2(0.65, 0.65)
		bottle.modulate = Color(0.85, 0.82, 0.76)
	_tile_in(Town.CHAIR_FACING_RIGHT, table_tile + Vector2i.LEFT, _entities).position.y -= 2
	_tile_in(Town.CHAIR_FACING_LEFT, table_tile + Vector2i.RIGHT, _entities).position.y -= 2
	var fallen := _tile_in(Town.CHAIR_FACING_LEFT, table_tile + Vector2i(1, 1), _entities)
	fallen.rotation = deg_to_rad(-90)
	fallen.position += Vector2(-6, 6)
	fallen.modulate = Color(0.85, 0.8, 0.75)
	# Hátsó fal: két polc cserépedényekkel, köztük a fénysáv.
	for start in [r.position.x + 5, r.position.x + 9]:
		var shelf := Shelf.new()
		shelf.position = Vector2(start, r.position.y) * TILE + Vector2(0, 8)
		shelf.z_index = -7
		add_child(shelf)
		for i in 5:
			var jar := _sprite(POTTERY, JARS[(start + i) % JARS.size()], shelf.position + Vector2(12 + i * 18, -6 - (i % 2) * 16), -6)
			jar.scale = Vector2(1.1, 1.1)
			jar.modulate = Color(0.7, 0.68, 0.64)
	# Jobb oldal: vasalt rakodóládák, egy régi láda, üst, hordósor.
	_stack(Vector2i(r.end.x - 1, r.position.y + 1), [CARGO_A, CARGO_B, CARGO_A], STORAGE)
	_stack(Vector2i(r.end.x - 2, r.position.y + 1), [CARGO_B], STORAGE)
	_stack(Vector2i(r.end.x - 1, r.position.y + 4), [BARREL, BARREL], CONTAINERS)
	_stack(Vector2i(r.end.x - 1, r.position.y + 6), [BARREL], CONTAINERS)
	_stack(Vector2i(r.end.x - 2, r.position.y + 7), [BIG_CRATE, BIG_CRATE], CONTAINERS)
	_stack(Vector2i(r.position.x + 7, r.position.y + 2), [OLD_CHEST], STORAGE)
	_stack(Vector2i(r.position.x + 4, r.position.y + 5), [CAULDRON], STORAGE)
	# Középen egy félredöntött hordó és szétszórt ládák (kerülgetni kell őket).
	_stack(Vector2i(r.position.x + 9, r.position.y + 5), [SMALL_CRATE, SMALL_CRATE], CONTAINERS)
	_stack(Vector2i(r.position.x + 10, r.position.y + 5), [BIG_CRATE], CONTAINERS)
	# Pókhálók a sarkokban és a polcok fölött.
	_cobweb(Vector2i(r.position.x, r.position.y), false)
	_cobweb(Vector2i(r.end.x - 1, r.position.y), true)
	_cobweb(Vector2i(r.position.x + 8, r.position.y), true)
	# Szálló por a levegőben.
	var dust := CPUParticles2D.new()
	dust.position = (Vector2(r.position) + Vector2(r.size) / 2.0) * TILE
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(r.size) * TILE / 2.0
	dust.amount = 70
	dust.lifetime = 6.0
	dust.preprocess = 6.0
	dust.direction = Vector2(0.3, -1)
	dust.spread = 60.0
	dust.gravity = Vector2.ZERO
	dust.initial_velocity_min = 2.0
	dust.initial_velocity_max = 7.0
	dust.scale_amount_min = 1.0
	dust.scale_amount_max = 2.0
	dust.color = Color(0.9, 0.85, 0.7, 0.35)
	dust.z_index = 3
	add_child(dust)


## Egymásra rakott tárgyak egy csempén (alul az első), a legalsó ütközik.
func _stack(tile: Vector2i, regions: Array, texture: Texture2D) -> void:
	var holder := Node2D.new()
	holder.position = _center(tile) + Vector2(0, 14)
	_entities.add_child(holder)
	for i in regions.size():
		var sprite := _sprite(texture, regions[i], Vector2(_rng.randf_range(-2, 2), -16 - i * 26), 0, holder)
		# A por miatt kicsit fakóbb mind.
		sprite.modulate = Color(0.82, 0.78, 0.72)
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(28, 14)
	shape.shape = box
	shape.position = Vector2(0, -7)
	body.add_child(shape)
	holder.add_child(body)


## Porfoltok a padlón (halvány, szabálytalan szürke foltok), és egy kitaposott csík az ajtótól.
func _dust_patches(r: Rect2i) -> void:
	for i in 26:
		var at := Vector2(_rng.randf_range(r.position.x + 0.5, r.end.x - 0.5), _rng.randf_range(r.position.y + 1, r.end.y - 0.3)) * TILE
		var patch := Polygon2D.new()
		var points := PackedVector2Array()
		for k in 8:
			var angle := TAU * k / 8.0
			points.append(at + Vector2(cos(angle) * _rng.randf_range(10, 26), sin(angle) * _rng.randf_range(6, 14)))
		patch.polygon = points
		patch.color = Color(0.78, 0.74, 0.66, _rng.randf_range(0.1, 0.22))
		patch.z_index = -9
		add_child(patch)


## Az ablakon beeső, ferde, halvány fénysáv.
func _light_beam(top: Vector2) -> void:
	var beam := Polygon2D.new()
	beam.polygon = PackedVector2Array([top + Vector2(-14, 0), top + Vector2(14, 0), top + Vector2(90, 200),
		top + Vector2(40, 210)])
	beam.color = Color(1.0, 0.92, 0.7, 0.12)
	beam.z_index = 2
	add_child(beam)


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
			return ["enter", "[E] Belépés: raktár"]
		return []
	if at.distance_to(_center(INTERIOR_DOOR) + Vector2(TILE / 2.0, TILE / 2.0)) < INTERACT_RANGE:
		return ["leave", "[E] Kilépés a szabadba"]
	return []


func _process(delta: float) -> void:
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
			_move(false, door_position() + Vector2(0, 26))


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


func _tile(coords: Vector2i, tile: Vector2i, z: int) -> Sprite2D:
	return _sprite(RPG, Rect2(Vector2(coords) * 17.0, Vector2(16, 16)), _center(tile), z)


## Kenney RPG csempe egy adott szülőbe (pl. az y-szerint rendezett rétegbe, hogy elé-mögé lehessen menni).
func _tile_in(coords: Vector2i, tile: Vector2i, parent: Node) -> Sprite2D:
	return _sprite(RPG, Rect2(Vector2(coords) * 17.0, Vector2(16, 16)), _center(tile), 0, parent)


func _sprite(texture: Texture2D, region: Rect2, at: Vector2, z: int, parent: Node = null) -> Sprite2D:
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


func _solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	add_child(body)


## A szoba oldal- és déli falai (az ajtónyílással) és a hátsó fal ütközője.
func _walls(r: Rect2i) -> void:
	var dark := Color(0.12, 0.1, 0.08)
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


func _cobweb(tile: Vector2i, flip_h: bool) -> void:
	var web := Sprite2D.new()
	web.texture = COBWEB
	web.scale = Vector2(2, 2)
	web.position = _center(tile)
	web.flip_h = flip_h
	web.z_index = -7
	web.modulate = Color(1, 1, 1, 0.7)
	add_child(web)


## Fali polc (két poros deszka).
class Shelf:
	extends Node2D

	func _draw() -> void:
		for y in [0.0, -16.0]:
			draw_rect(Rect2(0, y, 100, 4), Color(0.36, 0.24, 0.15))
			draw_rect(Rect2(0, y + 4, 100, 2), Color(0.2, 0.13, 0.08))
			draw_rect(Rect2(0, y - 1, 100, 1), Color(0.7, 0.66, 0.58, 0.5))
