class_name Graveyard
extends Node2D
## Temető a kocsma alatt (a városi út túloldalán, délre): sötét, kopár föld, középen egy
## elhalt fa, körülötte sírkövek és keresztek, korhadt kerítés, csontok, halvány köd.
## Egy rövid földút vezet le hozzá az útról. (A tábor építi fel: setup(camp) + build().)

const TILE := 32
const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const BONES: Texture2D = preload("res://assets/decor/bones.png")

## A temető csempékben (a városi út alatt, a kocsma ajtajával szemben).
const RECT := Rect2i(63, 21, 14, 7)
const GATE_COLUMN := 69
## Kenney RPG (CC0): elhalt fák, sírkövek, keresztek, sírlapok, kerítés.
const DEAD_TREE := Vector2i(27, 9)
const DEAD_SAPLINGS: Array[Vector2i] = [Vector2i(27, 10), Vector2i(27, 11)]
const GRAVES: Array[Vector2i] = [Vector2i(51, 9), Vector2i(52, 9), Vector2i(53, 9), Vector2i(51, 10), Vector2i(52, 10),
	Vector2i(53, 10), Vector2i(51, 11), Vector2i(52, 11), Vector2i(53, 11)]
const FENCE := Vector2i(38, 8)
const SOIL := Color(0.16, 0.12, 0.1)

var _camp: Node2D
var _entities: Node2D
var _rng := RandomNumberGenerator.new()


func setup(camp: Node2D) -> void:
	_camp = camp
	_entities = camp.get_node("Entities")


## Földút az úttól a temető kapujáig (a tábor rajzolja ki a többi földdel).
static func path_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for y in range(19, RECT.position.y):
		for x in [GATE_COLUMN, GATE_COLUMN + 1]:
			tiles.append(Vector2i(x, y))
	return tiles


## Ide nem kerülhet fa / bokor.
static func blocked_rect() -> Rect2i:
	return Rect2i(RECT.position - Vector2i(1, 2), RECT.size + Vector2i(2, 3))


func build() -> void:
	_rng.seed = 1313
	_build_soil()
	_build_fence()
	_build_tree()
	_build_graves()
	_build_fog()


## Sötét, kopár föld, szabálytalan szélekkel, itt-ott fűcsomóval.
func _build_soil() -> void:
	var soil := Soil.new()
	soil.rect = Rect2(Vector2(RECT.position) * TILE, Vector2(RECT.size) * TILE)
	soil.seed_value = 77
	soil.z_index = -9
	add_child(soil)
	for i in 14:
		var tile := RECT.position + Vector2i(_rng.randi_range(0, RECT.size.x - 1), _rng.randi_range(0, RECT.size.y - 1))
		var tuft := _rpg(Vector2i(22, 10), _center(tile) + Vector2(_rng.randf_range(-10, 10), _rng.randf_range(-8, 8)), -8)
		tuft.modulate = Color(0.45, 0.45, 0.35)
		tuft.scale = Vector2(1.4, 1.4)


## Korhadt fakerítés a temető tetején és alján (a tetején kapunyílással az ösvénynek).
func _build_fence() -> void:
	for x in range(RECT.position.x, RECT.end.x):
		if x == GATE_COLUMN or x == GATE_COLUMN + 1:
			continue
		var top := _rpg(FENCE, _center(Vector2i(x, RECT.position.y - 1)) + Vector2(0, 14), 0, _entities)
		top.modulate = Color(0.55, 0.45, 0.4)
		if _rng.randf() < 0.15:
			top.rotation = _rng.randf_range(-0.25, 0.25)
		var bottom := _rpg(FENCE, _center(Vector2i(x, RECT.end.y)) + Vector2(0, 4), 0, _entities)
		bottom.modulate = Color(0.55, 0.45, 0.4)
	_solid(Rect2(Vector2(RECT.position.x, RECT.position.y - 0.4) * TILE, Vector2(GATE_COLUMN - RECT.position.x, 0.5) * TILE))
	_solid(Rect2(Vector2(GATE_COLUMN + 2, RECT.position.y - 0.4) * TILE, Vector2(RECT.end.x - GATE_COLUMN - 2, 0.5) * TILE))
	_solid(Rect2(Vector2(RECT.position.x, RECT.end.y + 0.3) * TILE, Vector2(RECT.size.x, 0.5) * TILE))


## Az elhalt fa a temető közepén (szilárd törzzsel), tövében csontok.
func _build_tree() -> void:
	var holder := Node2D.new()
	holder.position = _center(Vector2i(GATE_COLUMN + 4, RECT.position.y + 3)) + Vector2(0, 16)
	_entities.add_child(holder)
	var tree := _rpg(DEAD_TREE, Vector2(0, -38), 0, holder)
	tree.modulate = Color(0.5, 0.45, 0.45)
	tree.scale = Vector2(5, 5)
	_body(holder, Vector2(0, -6), Vector2(20, 10))
	# Két kisebb, kiszáradt csemete a temető sarkaiban.
	for i in DEAD_SAPLINGS.size():
		# (A sírok oszlopai közé, hogy ne kerüljenek egymásra.)
		var corner := Vector2i(RECT.position.x, RECT.position.y + 2) if i == 0 else Vector2i(RECT.end.x - 2, RECT.position.y + 1)
		var sapling := _rpg(DEAD_SAPLINGS[i], _center(corner), 0, _entities)
		sapling.modulate = Color(0.5, 0.45, 0.45)
	var bones := Sprite2D.new()
	bones.texture = BONES
	bones.scale = Vector2(2, 2)
	bones.position = _center(Vector2i(GATE_COLUMN + 5, RECT.position.y + 3)) + Vector2(4, 10)
	bones.modulate = Color(0.75, 0.72, 0.68)
	bones.z_index = -7
	add_child(bones)


## Sírok sorokban (kicsit ferdén, mintha megsüllyedtek volna), mindegyik előtt egy földhalom.
func _build_graves() -> void:
	var tree_tile := Vector2i(GATE_COLUMN + 4, RECT.position.y + 3)
	for row in [1, 3, 5]:
		for x in range(RECT.position.x + 1, RECT.end.x - 1, 2):
			var tile := Vector2i(x, RECT.position.y + row)
			# Az elhalt fa (és a koronája fölötte) körül nincs sír.
			if absi(tile.x - tree_tile.x) <= 1 and tile.y >= tree_tile.y - 2 and tile.y <= tree_tile.y + 1:
				continue
			if x == GATE_COLUMN or x == GATE_COLUMN + 1:
				continue
			if _rng.randf() < 0.15:
				continue
			var mound := Mound.new()
			mound.position = _center(tile) + Vector2(0, 14)
			mound.z_index = -8
			add_child(mound)
			var holder := Node2D.new()
			holder.position = _center(tile) + Vector2(0, 4)
			_entities.add_child(holder)
			var stone := _rpg(GRAVES[_rng.randi() % GRAVES.size()], Vector2(0, -12), 0, holder)
			stone.rotation = _rng.randf_range(-0.12, 0.12)
			stone.modulate = Color(0.75, 0.75, 0.8)
			_body(holder, Vector2(0, -4), Vector2(22, 8))


## Halvány, lassan hullámzó köd a sírok között.
func _build_fog() -> void:
	for i in 5:
		var fog := Fog.new()
		fog.position = _center(RECT.position + Vector2i(_rng.randi_range(1, RECT.size.x - 2), _rng.randi_range(1, RECT.size.y - 2)))
		fog.phase = _rng.randf() * TAU
		fog.z_index = 2
		add_child(fog)


# ---------------------------------------------------------------- segédek

func _center(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE


func _rpg(coords: Vector2i, at: Vector2, z: int, parent: Node = null) -> Sprite2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = RPG
	atlas.region = Rect2(Vector2(coords) * 17.0, Vector2(16, 16))
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.scale = Vector2(2, 2)
	sprite.position = at
	sprite.z_index = z
	(parent if parent else self).add_child(sprite)
	return sprite


func _body(parent: Node2D, offset: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = size
	shape.shape = box
	shape.position = offset
	body.add_child(shape)
	parent.add_child(body)


func _solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	add_child(body)


## Sötét föld rücskös szélekkel és apró kövekkel.
class Soil:
	extends Node2D
	var rect := Rect2()
	var seed_value := 1

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var points := PackedVector2Array()
		var center := rect.get_center()
		for i in 48:
			var angle := TAU * i / 48.0
			var dir := Vector2.from_angle(angle)
			var reach := minf(rect.size.x / 2.0 / maxf(absf(dir.x), 0.01), rect.size.y / 2.0 / maxf(absf(dir.y), 0.01))
			points.append(center + dir * (reach + rng.randf_range(-6, 10)))
		draw_colored_polygon(points, SOIL)
		for i in 60:
			var at := rect.position + Vector2(rng.randf() * rect.size.x, rng.randf() * rect.size.y)
			draw_circle(at, rng.randf_range(1.0, 2.5), Color(0.24, 0.2, 0.17))


## Földhalom a sír előtt.
class Mound:
	extends Node2D

	func _draw() -> void:
		var points := PackedVector2Array()
		for i in 16:
			points.append(Vector2.from_angle(TAU * i / 16.0) * Vector2(13, 6))
		draw_colored_polygon(points, Color(0.22, 0.17, 0.13))
		draw_line(Vector2(-9, -2), Vector2(7, -3), Color(0.3, 0.24, 0.18), 1.5)


## Lassan úszó, halvány ködfolt.
class Fog:
	extends Node2D
	var phase := 0.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		position.x += sin(_t * 0.3 + phase) * 0.15
		queue_redraw()

	func _draw() -> void:
		# Sok halvány, egymásra rétegzett kör: puha szélű köd (nem látszanak a körvonalak).
		var alpha := 0.018 + 0.008 * sin(_t * 0.7 + phase)
		for i in 8:
			var radius := 14.0 + i * 6.0
			draw_circle(Vector2(sin(phase + i) * 6.0, 0), radius, Color(0.75, 0.8, 0.85, alpha))
