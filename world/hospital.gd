class_name Hospital
extends Node2D
## A kalandorok kórháza a kocsmától jobbra (a régi lakóház helyén; ide vitték a katonák a hordágyon
## a sebesültet, lásd StretcherScene). Kívül fehérre meszelt falak, piros kereszt, az ajtó fölött
## tábla. Bent két sor betegágy, rajtuk bekötözött sebesültek (néha felnyögnek), középen Kálmán
## doktor (pestisdoktor-maszkban; E: beszélgetés), mellette Rozi nővér; gyertyák, gyógyszeres polc,
## ládák, mosdótál, véres kötések, paraván, száradó gyógyfüvek, a falnak támasztott hordágy.
## (A tábor építi fel: setup(camp) + build().)

const TILE := 32
const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const DUNGEON: Texture2D = preload("res://assets/0x72_dungeon/0x72_DungeonTilesetII_v1.7.png")
const CONTAINERS: Texture2D = preload("res://assets/shop/barrels_and_boxes.png")
const POTTERY: Texture2D = preload("res://assets/shop/pottery.png")
const COBWEB: Texture2D = preload("res://assets/decor/cobweb.png")
const TOP_LEFT := Castle.HOUSE_TOP_LEFT
const SIZE := Castle.HOUSE_SIZE
const DOOR_TILE := Vector2i(TOP_LEFT.x + SIZE.x / 2, TOP_LEFT.y + SIZE.y - 1)
const WALL_TINT := Color(0.95, 0.93, 0.86)
const ROOF_TINT := Color(0.8, 0.45, 0.4)
const CROSS_RED := Color(0.78, 0.12, 0.12)
## A belső tér (messze a pályától, mint a többi épületé).
const INTERIOR := Rect2i(500, 0, 16, 10)
const INTERIOR_DOOR := Vector2i(507, 10)
const INSIDE_LIGHT := Color(0.5, 0.46, 0.42)
const INTERACT_RANGE := 52.0
const TALK_RANGE := 70.0
## 0x72 figurák (az első álló kocka): a doktor pestisdoktor-maszkban, a nővér, a betegek.
const DOCTOR := Rect2(368, 345, 16, 23)
const NURSE := Rect2(128, 4, 16, 28)
const PATIENTS: Array[Rect2] = [Rect2(128, 100, 16, 28), Rect2(128, 36, 16, 28), Rect2(128, 292, 16, 28),
	Rect2(128, 228, 16, 28), Rect2(128, 68, 16, 28), Rect2(128, 164, 16, 28)]
const FLASKS: Array[Rect2] = [Rect2(288, 336, 16, 16), Rect2(304, 336, 16, 16), Rect2(320, 336, 16, 16)]
const DOCTOR_ID := "doctor"
const DOCTOR_NAME := "Kálmán doktor"
const GREETING := "[i]A pestisdoktor-maszk mögül tompa, fáradt hang szól.[/i]\n\n" \
	+ "Csak óvatosan, ne lépj a vödörbe. Ha nem vérzel, ülj le valahova. Ha vérzel... akkor is ülj le, és várj."
const OPTIONS: Array[Dictionary] = [
	{"id": "who", "text": "Ki vagy te?", "trust": 4,
		"answer": "Kálmán. A tábor doktora, mióta az előző... nos, mióta ő is lement. Régen a pestises falvakat " \
			+ "jártam, onnan a maszk. A Mélység szaga sem sokkal jobb, úgyhogy rajtam maradt.\n\n" \
			+ "Rozi nővér segít. Nélküle a fele már a temetőben feküdne, Vendel nagy örömére."},
	{"id": "stretcher", "text": "Mi lett azzal, akit a katonák hoztak?", "trust": 3,
		"answer": "[i]Az ablak melletti ágy felé biccent.[/i]\n\n" \
			+ "Ott fekszik. A kilencedik emeleten egy bukott lovag kardja találta el, a katonák a lépcső aljáról " \
			+ "hozták fel. Sok vért vesztett, de él. Ha a láz lemegy, talán reggel már a nevét is megmondja.\n\n" \
			+ "Azt motyogta, hogy odalent a szörnyek egyre okosabbak. Kerülgetik az oszlopokat. Nem tetszik ez nekem."},
	{"id": "advice", "text": "Van valami tanácsod?", "trust": 2,
		"answer": "Három dolog. Egy: a vörös bájital nem cukorka, de ne is spórold, ha baj van.\n" \
			+ "Kettő: a mérget nem lehet kiizzadni. Ha zöldül a szél a szemed előtt, menekülj, és várd ki.\n" \
			+ "Három: ha a kiképzősátorban edzel, ritkábban látlak itt. Az nekem is jó."},
	{"id": "busy", "text": "Miért van itt ennyi sebesült?", "trust": 3,
		"answer": "Mert egyre többen mennek le. A király aranyat ígér, a kocsmáros küldetéseket ad, a fiatalok " \
			+ "hősök akarnak lenni.\n\n[i]Felsóhajt, a maszk csőre megbillen.[/i]\n\n" \
			+ "A hősökből lesznek a betegeim. A szerencsésebbekből."},
]
const MOANS: Array[String] = ["Aúú...", "Vizet...", "Hol vagyok?", "Anyám...", "A tizedik emelet...",
	"Ne... ne a pókok...", "Doktor úr...", "Fáj...", "Még egy kicsit...", "Kerülgetik az oszlopokat..."]

var _camp: Node2D
var _player: Node2D
var _entities: Node2D
var _prompt: Label
var _dialogue: DialoguePanel
var _inside := false
var _busy := false
var _rng := RandomNumberGenerator.new()
var _doctor_position := Vector2.ZERO
var _patients: Array[Vector2] = []
var _moan_left := 3.0


func setup(camp: Node2D) -> void:
	_camp = camp
	_entities = camp.get_node("Entities")
	_player = camp.get_node("Entities/Player")
	_dialogue = DialoguePanel.new()
	_dialogue.name = "DoctorDialogue"
	_dialogue.npc_id = DOCTOR_ID
	_dialogue.npc_name = DOCTOR_NAME
	_dialogue.greeting = GREETING
	_dialogue.options = OPTIONS
	_dialogue.portrait = SpriteSheet.region(DOCTOR)
	camp.add_child.call_deferred(_dialogue)


static func door_position() -> Vector2:
	return Vector2(DOOR_TILE.x + 0.5, DOOR_TILE.y + 1) * TILE + Vector2(0, 12)


func build() -> void:
	_rng.seed = 909
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
	_tile(Town.WINDOW, tl + Vector2i(1, 3), -5)
	_tile(Town.WINDOW, tl + Vector2i(w - 2, 3), -5)
	_tile(Town.DOUBLE_DOOR[0], DOOR_TILE, -5)
	# Piros kereszt a tetőn, tábla az ajtó fölött, lámpás az ajtó mellett.
	var front := HospitalFront.new()
	front.position = Vector2(tl) * TILE
	front.z_index = -4
	add_child(front)
	var sign_text := Label.new()
	sign_text.text = "Kalandorok kórháza"
	sign_text.add_theme_font_override("font", MenuStyle.TITLE_FONT)
	sign_text.add_theme_font_size_override("font_size", 15)
	sign_text.add_theme_color_override("font_color", Color(0.98, 0.92, 0.75))
	sign_text.add_theme_color_override("font_outline_color", Color(0.18, 0.1, 0.06))
	sign_text.add_theme_constant_override("outline_size", 4)
	sign_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign_text.size = Vector2(150, 20)
	sign_text.position = Vector2(DOOR_TILE.x + 0.5, tl.y + 2.6) * TILE - Vector2(75, 10)
	sign_text.z_index = -3
	add_child(sign_text)
	_light(Vector2(DOOR_TILE.x + 1.3, DOOR_TILE.y + 0.3) * TILE, Color(1.0, 0.8, 0.5), 1.2, 0.6)
	# Két láda és egy vödör a ház mellett (kötszeres ládák).
	_sprite(CONTAINERS, Rect2(16, 0, 16, 16), _center(tl + Vector2i(w, 4)) + Vector2(4, 10), -4)
	_sprite(CONTAINERS, Rect2(32, 0, 16, 16), _center(tl + Vector2i(w, 4)) + Vector2(10, -6), -4)
	_solid(Rect2(Vector2(tl) * TILE, Vector2(SIZE) * TILE - Vector2(0, 6)))


# ---------------------------------------------------------------- bent

func _build_interior() -> void:
	var r := INTERIOR
	# Fehérre súrolt deszkapadló, a falak mentén meszelt fal.
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			_tile(Town.FLOOR_TILES[(x + y) % 2], Vector2i(x, y), -10).modulate = Color(0.86, 0.78, 0.68)
		_tile(Town.WALL_BAND, Vector2i(x, r.position.y - 1), -9).modulate = WALL_TINT
		_tile(Town.WALL_BOARDS, Vector2i(x, r.position.y), -9).modulate = WALL_TINT.darkened(0.05)
	for x in [r.position.x + 3, r.end.x - 4]:
		_tile(Town.WINDOW, Vector2i(x, r.position.y - 1), -8)
	var walls := HospitalWall.new()
	walls.position = Vector2(r.position) * TILE
	walls.width = r.size.x * TILE
	walls.z_index = -8
	add_child(walls)
	_walls(r)
	for i in 2:
		_tile(Town.DOUBLE_DOOR[i], Vector2i(INTERIOR_DOOR.x + i, r.end.y), -8)
	# Két sor ágy a falak mentén; a legtöbbön sebesült fekszik.
	var beds: Array[Vector2i] = []
	for y in [1, 3, 5, 7]:
		beds.append(Vector2i(r.position.x + 1, r.position.y + y))
		beds.append(Vector2i(r.end.x - 3, r.position.y + y))
	var occupied := [true, true, false, true, true, true, false, true]
	for i in beds.size():
		var bed := Bed.new()
		bed.position = Vector2(beds[i]) * TILE + Vector2(0, TILE * 0.9)
		bed.blood = i == 1 or i == 4
		_entities.add_child(bed)
		_solid(Rect2(Vector2(beds[i]) * TILE + Vector2(0, 4), Vector2(2 * TILE, TILE * 0.75)))
		if occupied[i]:
			# Hanyatt fekszik, a feje a párnán (az ágy bal végén), a teste a takaró alatt.
			var patient := _region_sprite(DUNGEON, PATIENTS[i % PATIENTS.size()], Vector2(TILE * 0.55, -TILE * 0.46), 1, bed)
			patient.rotation = -PI / 2.0
			patient.modulate = Color(0.92, 0.85, 0.82)
			var blanket := Blanket.new()
			blanket.blood = bed.blood
			blanket.z_index = 2
			bed.add_child(blanket)
			var wrap := Bandage.new()
			wrap.position = Vector2(TILE * 0.62, -TILE * 0.46)
			wrap.heavy = i == 1
			wrap.z_index = 3
			bed.add_child(wrap)
			_patients.append(bed.position + Vector2(TILE, -TILE))
		# Éjjeliszekrény gyertyával az ágy mellett.
		var side_x := beds[i].x + (2 if i % 2 == 0 else -1)
		if i % 2 == 0 or i < 6:
			var stand := _tile(Town.TABLE, Vector2i(side_x, beds[i].y), 0, _entities)
			stand.scale = Vector2(1.4, 1.4)
			stand.position.y += 6
			_sprite(DUNGEON, FLASKS[i % FLASKS.size()], Vector2(-4, -6), 1, stand).scale = Vector2(0.45, 0.45)
			if i % 3 == 0:
				_tile(Town.CANDLE, Vector2i.ZERO, 1, stand).position = Vector2(5, -8)
				_light(Vector2(side_x, beds[i].y) * TILE + Vector2(TILE / 2.0, 0), Color(1.0, 0.76, 0.48), 1.1, 0.55)
	# A doktor középen, az asztala mellett; a nővér a súlyos beteg ágyánál.
	var desk := _tile(Town.TABLE, Vector2i(INTERIOR_DOOR.x, r.position.y + 2), 0, _entities)
	desk.scale = Vector2(2.4, 2.0)
	_solid(Rect2(Vector2(INTERIOR_DOOR.x, r.position.y + 2) * TILE + Vector2(-8, 4), Vector2(TILE + 16, TILE * 0.8)))
	for i in FLASKS.size():
		_sprite(DUNGEON, FLASKS[i], Vector2(-6 + i * 5, -6), 1, desk).scale = Vector2(0.3, 0.3)
	_tile(Town.CANDLE, Vector2i.ZERO, 1, desk).position = Vector2(8, -7)
	_light(Vector2(INTERIOR_DOOR.x + 0.5, r.position.y + 2) * TILE, Color(1.0, 0.78, 0.5), 1.6, 0.7)
	_doctor_position = Vector2(INTERIOR_DOOR.x + 1.5, r.position.y + 2.8) * TILE
	_npc(DOCTOR, _doctor_position)
	_npc(NURSE, Vector2(r.position.x + 3.6, r.position.y + 3.0) * TILE).flip_h = true
	# Gyógyszeres polc a hátsó falon, ládák a sarokban, mosdótál, kosár véres kötéssel, paraván,
	# száradó gyógyfüvek, a falnak támasztott hordágy, pókháló a sarokban.
	var shelf := Shelf.new()
	shelf.position = Vector2(INTERIOR_DOOR.x - 2, r.position.y) * TILE + Vector2(0, 6)
	shelf.z_index = -7
	add_child(shelf)
	for i in 6:
		_sprite(DUNGEON, FLASKS[i % FLASKS.size()], shelf.position + Vector2(10 + i * 14, -4 - (i % 2) * 14), -6).scale = Vector2(0.9, 0.9)
	for spot: Array in [[Vector2i(r.end.x - 1, r.end.y - 1), Rect2(16, 0, 16, 16)], [Vector2i(r.end.x - 1, r.end.y - 2), Rect2(32, 0, 16, 16)],
			[Vector2i(r.position.x, r.end.y - 1), Rect2(0, 0, 16, 16)]]:
		_prop(CONTAINERS, spot[1], _center(spot[0]))
	_sprite(POTTERY, Rect2(16, 16, 16, 16), _center(Vector2i(INTERIOR_DOOR.x - 2, r.end.y - 2)), 0, _entities)
	var basket := Laundry.new()
	basket.position = _center(Vector2i(INTERIOR_DOOR.x + 3, r.end.y - 2)) + Vector2(0, 10)
	_entities.add_child(basket)
	var screen := Screen.new()
	screen.position = Vector2(r.end.x - 5.2, r.position.y + 5.9) * TILE
	_entities.add_child(screen)
	var herbs := Herbs.new()
	herbs.position = Vector2(r.position.x + 1, r.position.y - 0.5) * TILE
	herbs.z_index = -7
	add_child(herbs)
	var stretcher := StretcherProp.new()
	stretcher.position = Vector2(r.end.x - 1.3, r.position.y + 0.1) * TILE
	stretcher.z_index = -7
	add_child(stretcher)
	_cobweb(Vector2i(r.end.x - 1, r.position.y), true)


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
			return ["enter", "[E] Belépés: kalandorok kórháza"]
		return []
	if at.distance_to(_center(INTERIOR_DOOR) + Vector2(TILE / 2.0, TILE / 2.0)) < INTERACT_RANGE:
		return ["leave", "[E] Kilépés a szabadba"]
	if at.distance_to(_doctor_position) < TALK_RANGE:
		return ["talk", "[E] Beszélgetés: %s" % DOCTOR_NAME]
	return []


func _process(delta: float) -> void:
	var focus := _focus()
	if not focus.is_empty():
		_prompt.text = focus[1]
	var target := 1.0 if not focus.is_empty() and not get_tree().paused else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)
	# Bent a betegek néha felnyögnek.
	if _inside and not get_tree().paused and not _patients.is_empty():
		_moan_left -= delta
		if _moan_left <= 0.0:
			_moan_left = _rng.randf_range(3.5, 7.0)
			var at: Vector2 = _patients[_rng.randi() % _patients.size()]
			FloatingText.spawn(_entities, at, MOANS[_rng.randi() % MOANS.size()], Color(0.95, 0.88, 0.8), 15)


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
		"talk":
			Audio.play("ui_open")
			_camp.get_node("Menus").call("open_menu", _dialogue)


func _move(inside: bool, at: Vector2) -> void:
	_busy = true
	_inside = inside
	_moan_left = 2.0
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


func _tile(coords: Vector2i, tile: Vector2i, z: int, parent: Node = null) -> Sprite2D:
	return _region_sprite(RPG, Rect2(Vector2(coords) * 17.0, Vector2(16, 16)), _center(tile), z, parent)


func _sprite(texture: Texture2D, region: Rect2, at: Vector2, z: int, parent: Node = null) -> Sprite2D:
	return _region_sprite(texture, region, at, z, parent)


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


## Álló figura (lassan "lélegzik": az első álló kocka, és a következő három).
func _npc(region: Rect2, at: Vector2) -> AnimatedSprite2D:
	var npc := AnimatedSprite2D.new()
	npc.sprite_frames = SpriteSheet.character_frames(region, false)
	npc.scale = Vector2(2, 2)
	npc.offset = Vector2(0, -region.size.y / 2.0)
	npc.position = at
	npc.play("idle")
	_entities.add_child(npc)
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(20, 10)
	shape.shape = box
	shape.position = Vector2(0, -4)
	body.add_child(shape)
	npc.add_child(body)
	return npc


func _prop(texture: Texture2D, region: Rect2, at: Vector2) -> void:
	var holder := Node2D.new()
	holder.position = at + Vector2(0, 16)
	_entities.add_child(holder)
	_region_sprite(texture, region, Vector2(0, -16), 0, holder)
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(26, 12)
	shape.shape = box
	shape.position = Vector2(0, -6)
	body.add_child(shape)
	holder.add_child(body)


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
	var dark := Color(0.16, 0.12, 0.1)
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


func _cobweb(tile: Vector2i, flip_h: bool) -> void:
	var web := Sprite2D.new()
	web.texture = COBWEB
	web.scale = Vector2(2, 2)
	web.position = _center(tile)
	web.flip_h = flip_h
	web.z_index = -7
	web.modulate = Color(1, 1, 1, 0.6)
	add_child(web)


## A homlokzat díszei: piros kereszt a tetőn, a tábla deszkája az ajtó fölött, és egy lámpás.
class HospitalFront:
	extends Node2D

	func _draw() -> void:
		var t := float(TILE)
		var w := SIZE.x * t
		# Kereszt a tető közepén, fehér alapon.
		var c := Vector2(w / 2.0, 1.2 * t)
		draw_circle(c, 18.0, Color(0.96, 0.94, 0.9))
		draw_arc(c, 18.0, 0.0, TAU, 24, Color(0.5, 0.3, 0.25), 2.0)
		draw_rect(Rect2(c + Vector2(-4, -12), Vector2(8, 24)), CROSS_RED)
		draw_rect(Rect2(c + Vector2(-12, -4), Vector2(24, 8)), CROSS_RED)
		# A tábla deszkája (rajta a felirat egy Label-ben) és a két lánc.
		var door_x := (DOOR_TILE.x - TOP_LEFT.x + 0.5) * t
		var board := Rect2(Vector2(door_x - 80, 2.6 * t - 13), Vector2(160, 24))
		draw_line(Vector2(board.position.x + 14, board.position.y), Vector2(board.position.x + 14, board.position.y - 10), Color(0.25, 0.22, 0.2), 2.0)
		draw_line(Vector2(board.end.x - 14, board.position.y), Vector2(board.end.x - 14, board.position.y - 10), Color(0.25, 0.22, 0.2), 2.0)
		draw_rect(board, Color(0.45, 0.28, 0.16))
		draw_rect(board, Color(0.25, 0.14, 0.08), false, 2.0)
		draw_rect(Rect2(board.position + Vector2(4, 4), Vector2(10, 16)), CROSS_RED.lightened(0.1))
		# Lámpás az ajtó mellett.
		var lamp := Vector2(door_x + 40, 3.3 * t)
		draw_rect(Rect2(lamp + Vector2(-5, -8), Vector2(10, 14)), Color(0.2, 0.18, 0.16))
		draw_rect(Rect2(lamp + Vector2(-3, -6), Vector2(6, 10)), Color(1.0, 0.82, 0.45))


## A belső hátsó fal díszei: nagy piros kereszt, falitábla a betegek neveivel.
class HospitalWall:
	extends Node2D
	var width := 0.0

	func _draw() -> void:
		var t := float(TILE)
		var c := Vector2(width / 2.0 + t, -0.15 * t)
		draw_rect(Rect2(c + Vector2(-5, -14), Vector2(10, 28)), CROSS_RED)
		draw_rect(Rect2(c + Vector2(-14, -5), Vector2(28, 10)), CROSS_RED)
		var board := Rect2(Vector2(width / 2.0 - 3.2 * t, -0.55 * t), Vector2(1.4 * t, 0.9 * t))
		draw_rect(board, Color(0.3, 0.22, 0.15))
		draw_rect(board.grow(-3), Color(0.88, 0.84, 0.74))
		for i in 4:
			draw_line(board.position + Vector2(7, 8 + i * 5), board.position + Vector2(board.size.x - 7 - (i % 2) * 8, 8 + i * 5),
				Color(0.3, 0.26, 0.22), 1.0)


## Betegágy (fa keret, fehér lepedő, párna); `blood`: vérfolt a lepedőn.
class Bed:
	extends Node2D
	var blood := false

	func _draw() -> void:
		var t := float(TILE)
		var wood := Color(0.42, 0.28, 0.17)
		draw_rect(Rect2(0, -t * 0.85, 2 * t, t * 0.8), wood.darkened(0.2))
		draw_rect(Rect2(3, -t * 0.82, 2 * t - 6, t * 0.66), Color(0.92, 0.9, 0.85))
		draw_rect(Rect2(5, -t * 0.78, 14, t * 0.56), Color(0.98, 0.97, 0.93))
		draw_rect(Rect2(0, -t * 0.85, 4, t * 0.8), wood)
		draw_rect(Rect2(2 * t - 4, -t * 0.85, 4, t * 0.8), wood)
		if blood:
			draw_circle(Vector2(t * 1.1, -t * 0.4), 6.0, Color(0.6, 0.06, 0.06, 0.8))
			draw_circle(Vector2(t * 1.25, -t * 0.32), 3.5, Color(0.55, 0.05, 0.05, 0.8))


## A takaró a beteg testén (a figura fölött rajzolva); `blood`: átvérzett folt rajta.
class Blanket:
	extends Node2D
	var blood := false

	func _draw() -> void:
		var t := float(TILE)
		draw_rect(Rect2(t * 0.9, -t * 0.84, t * 1.02, t * 0.7), Color(0.55, 0.62, 0.72))
		draw_line(Vector2(t * 0.9, -t * 0.84), Vector2(t * 0.9, -t * 0.14), Color(0.92, 0.9, 0.85), 3.0)
		for x in [1.1, 1.5]:
			draw_line(Vector2(t * x, -t * 0.8), Vector2(t * x + 4, -t * 0.2), Color(0.45, 0.52, 0.62), 1.0)
		if blood:
			draw_circle(Vector2(t * 1.0, -t * 0.5), 5.0, Color(0.55, 0.07, 0.07, 0.85))


## Kötés a beteg fején / mellkasán (`heavy`: sok kötés, átvérzett).
class Bandage:
	extends Node2D
	var heavy := false

	func _draw() -> void:
		draw_rect(Rect2(-6, -6, 5, 12), Color(0.97, 0.96, 0.92))
		if heavy:
			draw_rect(Rect2(2, -7, 9, 14), Color(0.97, 0.96, 0.92))
			draw_rect(Rect2(5, -3, 4, 5), Color(0.65, 0.08, 0.08))
			draw_rect(Rect2(-5, -2, 3, 3), Color(0.65, 0.08, 0.08))


## Gyógyszeres polc (két deszka a falon).
class Shelf:
	extends Node2D

	func _draw() -> void:
		for y in [0.0, -14.0]:
			draw_rect(Rect2(0, y, 96, 4), Color(0.42, 0.28, 0.17))
			draw_rect(Rect2(0, y + 4, 96, 2), Color(0.25, 0.16, 0.1))


## Kosár véres kötésekkel.
class Laundry:
	extends Node2D

	func _draw() -> void:
		draw_rect(Rect2(-12, -14, 24, 14), Color(0.6, 0.45, 0.25))
		for x in [-8, -2, 4]:
			draw_line(Vector2(x, -14), Vector2(x, 0), Color(0.45, 0.32, 0.18), 1.0)
		draw_circle(Vector2(-4, -15), 6.0, Color(0.95, 0.93, 0.88))
		draw_circle(Vector2(5, -16), 5.0, Color(0.95, 0.93, 0.88))
		draw_circle(Vector2(5, -16), 2.5, Color(0.6, 0.07, 0.07))


## Paraván (vászon fakereten) a vizsgálóágy előtt.
class Screen:
	extends Node2D

	func _draw() -> void:
		for i in 3:
			var x := -36.0 + i * 24.0
			draw_rect(Rect2(x, -40, 22, 38), Color(0.88, 0.86, 0.78))
			draw_rect(Rect2(x, -40, 22, 38), Color(0.45, 0.3, 0.18), false, 2.0)
			draw_line(Vector2(x + 2, -2), Vector2(x + 2, 4), Color(0.45, 0.3, 0.18), 2.0)


## Száradó gyógyfű-csokrok egy zsinóron a hátsó falon.
class Herbs:
	extends Node2D

	func _draw() -> void:
		draw_line(Vector2(0, 0), Vector2(84, 0), Color(0.5, 0.42, 0.3), 1.0)
		for i in 5:
			var x := 8.0 + i * 17.0
			var color := [Color(0.35, 0.55, 0.28), Color(0.5, 0.6, 0.3), Color(0.55, 0.4, 0.55)][i % 3] as Color
			draw_line(Vector2(x, 0), Vector2(x, 4), Color(0.5, 0.42, 0.3), 1.0)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 4, 4), Vector2(x + 4, 4), Vector2(x + 2, 14), Vector2(x - 2, 14)]), color)


## A falnak támasztott hordágy (a bejátszásból ismerős).
class StretcherProp:
	extends Node2D

	func _draw() -> void:
		draw_line(Vector2(-6, 0), Vector2(-2, 56), Color(0.42, 0.29, 0.17), 3.0)
		draw_line(Vector2(8, 0), Vector2(12, 56), Color(0.42, 0.29, 0.17), 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(-5, 8), Vector2(9, 8), Vector2(11, 46), Vector2(-3, 46)]), Color(0.72, 0.66, 0.55))
		draw_circle(Vector2(3, 24), 3.0, Color(0.55, 0.08, 0.08, 0.8))
