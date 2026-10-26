class_name Mine
extends Node2D
## A bánya: a város keleti részéből (a raktár és a tó között félúton) földút vezet fel északra az erdőn át egy
## tisztásig, ahol egy hegy áll: három füves sziklaterasz, a csúcsa havas, az alsó falában ácsolt bányabejárat
## sínnel (egyelőre csak díszlet). A hegy képe: assets/props/mountain.png (a sziklacsempék az "Adventure Awaits"
## csomagból, CC0; a fű a játék füve, a hó és a bejárat ehhez a projekthez rajzolva).
## (A tábor építi fel: setup(camp) + build(); az utat a tábor rajzolja ki a többi földdel, a tisztás szélén a fasort
## és körülötte az erdőt is ő rakja le, a falakat is ő húzza fel.)

const TILE := 32
const MOUNTAIN: Texture2D = preload("res://assets/props/mountain.png")
## Az út két oszlopa: a városi úttól a bánya bejáratáig.
const PATH_COLUMN := 101
## A tisztás: felül a hegy, alatta egy kis rét, ahova az út beér (alul nyílás az útnak).
const RECT := Rect2i(94, -24, 18, 16)
## A hegy képének bal felső sarka (csempében, 2x nagyítva 15x11 csempe): a bejárat (a kép közepe) az út közepére esik.
const MOUNTAIN_TOP_LEFT := Vector2(PATH_COLUMN + 1 - 7.5, -23)
const MOUNTAIN_SIZE := Vector2(15, 11)
## A tisztáson (és a folyosó felső részén) a kamera ennyivel feljebb néz, hogy az egész hegy látsszon, a csúcsa is
## (a kamera nagyít: a hegy lábánál állva különben csak az alsó terasz férne a képbe).
const LOOK_UP := 4.0 * TILE
## Kis fák a teraszokon (csempében, a fa töve).
const TERRACE_TREES: Array[Vector2] = [Vector2(96.3, -19.2), Vector2(98.5, -19.5), Vector2(105.6, -19.3),
	Vector2(95.0, -16.2), Vector2(107.4, -16.3), Vector2(108.9, -16.6)]

var _camp: Node2D
var _player: Node2D


func setup(camp: Node2D) -> void:
	_camp = camp
	_player = camp.get_node("Entities/Player")


## Az út csempéi (a tábor rajzolja ki a többi földdel): a városi úttól fel, a hegy lábáig (a bejárat elé).
static func path_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for y in range(int(MOUNTAIN_TOP_LEFT.y + MOUNTAIN_SIZE.y) - 1, 17):
		for x in [PATH_COLUMN, PATH_COLUMN + 1]:
			tiles.append(Vector2i(x, y))
	return tiles


## A hegy csempéi: ide nem kerülhet fa (a teraszok kis fái külön).
static func mountain_rect() -> Rect2i:
	var top_left := Vector2i(MOUNTAIN_TOP_LEFT.floor())
	return Rect2i(top_left, Vector2i((MOUNTAIN_TOP_LEFT + MOUNTAIN_SIZE).ceil()) - top_left)


func build() -> void:
	var mountain := Sprite2D.new()
	mountain.texture = MOUNTAIN
	mountain.centered = false
	mountain.scale = Vector2(2, 2)
	mountain.position = MOUNTAIN_TOP_LEFT * TILE
	# A föld (és az út) fölött, de minden álló dolog (fák, a játékos) alatt.
	mountain.z_index = -8
	add_child(mountain)
	# A hegyre (és mellette a fák közé, a hegy mögé) nem lehet felmenni: csak a hegy előtti rét járható
	# (a hegy lábáig, ahol a bejárat előtti föld van).
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(RECT.size.x, MOUNTAIN_TOP_LEFT.y + MOUNTAIN_SIZE.y - RECT.position.y) * TILE - Vector2(0, 14)
	shape.shape = box
	shape.position = Vector2(RECT.position) * TILE + box.size / 2.0
	body.add_child(shape)
	add_child(body)
	for at: Vector2 in TERRACE_TREES:
		var tree: Node2D = _camp.call("_tree", Vector2i(at), false, false)
		tree.position = at * TILE
	# A lépcsős hegy üres sarkaiba (a felső teraszok mellé, mögé) sötétebb erdő.
	for col in int(MOUNTAIN_SIZE.x):
		for row in int(MOUNTAIN_SIZE.y):
			if _is_rock(col, row) or randf() < 0.2:
				continue
			var at := MOUNTAIN_TOP_LEFT + Vector2(col + 0.5, row + 0.9)
			var tree: Node2D = _camp.call("_tree", Vector2i(at), randf() < 0.7, false)
			tree.position = at * TILE + Vector2(randf_range(-6, 6), randf_range(-4, 2))
			tree.modulate = Color(0.66, 0.66, 0.7)


## A folyosón felfelé haladva a kamera fokozatosan feljebb néz (a -2. sortól), a tisztás aljától már LOOK_UP-pal.
func _process(_delta: float) -> void:
	var tile := _player.global_position / TILE
	var look := 0.0
	if tile.x >= RECT.position.x and tile.x <= RECT.end.x:
		look = clampf((-2.0 - tile.y) / (-2.0 - RECT.end.y + 2.0), 0.0, 1.0)
	(_player.get_node("Camera2D") as Camera2D).offset.y = -LOOK_UP * look


## A hegy képének ez a csempéje (oszlop, sor) a szikla része (a három terasz lépcsős körvonalán belül).
static func _is_rock(col: int, row: int) -> bool:
	return row >= 5 or (row >= 2 and col >= 1 and col <= 11) or (col >= 5 and col <= 9)
