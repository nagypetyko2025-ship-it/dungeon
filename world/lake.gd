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
	stairs.call("set_locked", true)
