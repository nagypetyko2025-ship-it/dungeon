class_name DrillArena
extends Node2D
## A Hadgyakorlat pályája (Drill; a Dungeon "drill" történet-futásnál ezt építi a kazamata helyett): nappali,
## kitaposott földes küzdőtér a szabad ég alatt, szabálytalan alakkal (carve: hullámzó sugarú folt), fű nélkül
## körben fa cölöpsorral (ütköző is: két sor, hogy semmit ne lökhessen ki a fizika), kívül fű. A Room ("drill")
## ugyanerre a téglalapra épül (RECT), ajtó, oszlop és díszlet nélkül. A hullámok közti szünetben középen sátor a
## boltossal (Station: nekimenve a bolt belsejébe visz, mint a kazamatai bolt ajtaja) és egy kar (E: jön a következő).
## Grafika: Kenney Roguelike RPG Pack (CC0, a projektben): fű, kitaposott föld, fa oszlopok, sátor; 0x72: kar, boltos.

const TILE := 32
const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
## A pálya befoglaló téglalapja (csempe), a közepe a (0, 0): ott kezd a játékos.
const RECT := Rect2i(-18, -13, 37, 27)
const RADIUS := Vector2(16.0, 11.0)
## A fű a pályán kívül ennyi csempényire terjed.
const GRASS_MARGIN := 34
const GRASS_TILES: Array[Vector2i] = [Vector2i(0, 15), Vector2i(1, 15), Vector2i(0, 16), Vector2i(1, 16)]
const DIRT := Vector2i(8, 10)
const TUFT_CHANCE := 0.0
## Fa oszlopok (két karó egy csempén), ebből a cölöpsor.
const STAKES: Array[Vector2i] = [Vector2i(45, 23), Vector2i(45, 24)]
const CLEAR_COLOR := Color(0.25, 0.42, 0.2)

var floor_cells := {}


## A pálya padlója: hullámzó sugarú folt (minden futásban kicsit más), a Dungeon _floor szótárába.
static func carve(floor: Dictionary) -> void:
	var phase_a := randf() * TAU
	var phase_b := randf() * TAU
	for x in range(RECT.position.x, RECT.end.x):
		for y in range(RECT.position.y, RECT.end.y):
			var offset := Vector2(x, y)
			var angle := offset.angle()
			var wobble := 1.0 + 0.14 * sin(3.0 * angle + phase_a) + 0.07 * sin(5.0 * angle + phase_b)
			var scaled := Vector2(offset.x / (RADIUS.x * wobble), offset.y / (RADIUS.y * wobble))
			if scaled.length() <= 1.0:
				floor[Vector2i(x, y)] = true


func _ready() -> void:
	z_index = -10
	_build_ground()
	_build_stakes()


func _tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(16, 16)
	var source := TileSetAtlasSource.new()
	source.texture = RPG
	source.texture_region_size = Vector2i(16, 16)
	source.separation = Vector2i(1, 1)
	tile_set.add_source(source, 0)
	var tiles: Array[Vector2i] = []
	tiles.assign(GRASS_TILES)
	tiles.append(DIRT)
	for coords in tiles:
		source.create_tile(coords)
	return tile_set


func _build_ground() -> void:
	var ground := TileMapLayer.new()
	ground.tile_set = _tile_set()
	ground.scale = Vector2(2, 2)
	add_child(ground)
	var area := RECT.grow(GRASS_MARGIN)
	for x in range(area.position.x, area.end.x):
		for y in range(area.position.y, area.end.y):
			var cell := Vector2i(x, y)
			if floor_cells.has(cell) and randf() >= TUFT_CHANCE:
				ground.set_cell(cell, 0, DIRT)
			else:
				ground.set_cell(cell, 0, GRASS_TILES.pick_random())


## Cölöpsor a pálya szélén (a padló mellett közvetlenül kívül), mögötte még egy sor ütköző.
func _build_stakes() -> void:
	var ring := {}
	for cell: Vector2i in floor_cells:
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				var out := cell + Vector2i(dx, dy)
				if not floor_cells.has(out):
					ring[out] = maxi(absi(dx), absi(dy)) == 1 or ring.get(out, false)
	var stakes := Node2D.new()
	stakes.z_index = 10
	stakes.y_sort_enabled = true
	add_child(stakes)
	for cell: Vector2i in ring:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = Vector2(TILE, TILE)
		shape.shape = box
		body.add_child(shape)
		body.position = (Vector2(cell) + Vector2(0.5, 0.5)) * TILE
		add_child(body)
		if not ring[cell]:
			continue
		var coords: Vector2i = STAKES.pick_random()
		var stake := Sprite2D.new()
		stake.texture = RPG
		stake.region_enabled = true
		stake.region_rect = Rect2(Vector2(coords) * 17.0, Vector2(16, 16))
		stake.scale = Vector2(2.0, 2.6)
		stake.position = body.position + Vector2(randf_range(-2, 2), -10)
		stake.flip_h = randf() < 0.5
		stakes.add_child(stake)


## A szünet állomása a pálya közepén: sátor a boltossal (nekimenve: bolt) és a kar (E: jön a következő hullám).
class Station extends Node2D:
	signal pulled
	signal shop_entered(return_position: Vector2)

	const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
	const TENT := Vector2i(46, 10)
	const SHOPKEEPER := Rect2(368, 345, 16, 23)
	const LEVER := Rect2(80, 208, 16, 16)
	const LEVER_RANGE := 46.0
	const SHOP_OFFSET := Vector2(-110, -10)
	const LEVER_OFFSET := Vector2(90, 10)

	var _prompt: Label
	var _done := false

	func _ready() -> void:
		# Sátor (2x2 csempe) a boltossal.
		for dx in 2:
			for dy in 2:
				var piece := Sprite2D.new()
				piece.texture = RPG
				piece.region_enabled = true
				piece.region_rect = Rect2(Vector2(TENT + Vector2i(dx, dy)) * 17.0, Vector2(16, 16))
				piece.scale = Vector2(2.4, 2.4)
				piece.position = SHOP_OFFSET + Vector2((dx - 0.5) * 38.4, (dy - 1.5) * 38.4)
				add_child(piece)
		var keeper := Sprite2D.new()
		keeper.texture = SpriteSheet.TEXTURE
		keeper.region_enabled = true
		keeper.region_rect = SHOPKEEPER
		keeper.scale = Vector2(2, 2)
		keeper.position = SHOP_OFFSET + Vector2(0, -6)
		add_child(keeper)
		var shop_sign := UiStyle.label("Bolt", 14, UiStyle.TEXT_GOLD, true)
		shop_sign.size = Vector2(80, 18)
		shop_sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		shop_sign.position = SHOP_OFFSET + Vector2(-40, -112)
		add_child(shop_sign)
		var door := Area2D.new()
		door.collision_layer = 0
		door.collision_mask = 2
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = Vector2(60, 24)
		shape.shape = box
		shape.position = SHOP_OFFSET + Vector2(0, 22)
		door.add_child(shape)
		door.body_entered.connect(_on_door)
		add_child(door)
		# A kar.
		var lever := Sprite2D.new()
		lever.texture = SpriteSheet.TEXTURE
		lever.region_enabled = true
		lever.region_rect = LEVER
		lever.scale = Vector2(2.4, 2.4)
		lever.position = LEVER_OFFSET
		add_child(lever)
		var lever_sign := UiStyle.label("Következő hullám", 14, UiStyle.TEXT_GOLD, true)
		lever_sign.size = Vector2(160, 18)
		lever_sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lever_sign.position = LEVER_OFFSET + Vector2(-80, -52)
		add_child(lever_sign)
		_prompt = UiStyle.label("[E] Meghúzod a kart", 15, Color(1, 0.9, 0.6), true)
		_prompt.size = Vector2(220, 20)
		_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_prompt.position = LEVER_OFFSET + Vector2(-110, 26)
		_prompt.visible = false
		add_child(_prompt)
		z_index = 11

	func _process(_delta: float) -> void:
		_prompt.visible = not _done and _near()

	func _near() -> bool:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		return player != null and player.global_position.distance_to(global_position + LEVER_OFFSET) < LEVER_RANGE

	func _unhandled_input(event: InputEvent) -> void:
		if _done or not event.is_action_pressed("interact") or GamePause.active(get_tree()) or not _near():
			return
		get_viewport().set_input_as_handled()
		_done = true
		Audio.play("door_unlock")
		pulled.emit()

	func _on_door(body: Node2D) -> void:
		if _done or not body.is_in_group("player"):
			return
		Audio.play("door_unlock")
		shop_entered.emit(global_position + SHOP_OFFSET + Vector2(0, 80))
