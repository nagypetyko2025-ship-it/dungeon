extends Node2D
## Egy dungeon-szint generálása, Diablo-szerűen: különböző méretű szobák
## rövid folyosókkal összekötve, a legtávolabbi szobában lépcső lefelé.
## Minden mélyebb szint több szobát és erősebb ellenségeket kap.

const TILE := 32
## Egy rácscella mérete csempében; minden cellában egy szoba van.
const CELL := Vector2i(19, 15)
const ROOM_WIDTH := Vector2i(11, 14)
const ROOM_HEIGHT := Vector2i(8, 10)
const ROOM_JITTER := 1
## Az 5. emelettől nagyobbak a szobák (és több szörny jön): ehhez nagyobb rácscella kell,
## hogy a szomszédos szobák fala ne érjen össze.
const BIG_ROOMS_FROM := 5
const BIG_CELL := Vector2i(26, 19)
const BIG_ROOM_WIDTH := Vector2i(15, 19)
const BIG_ROOM_HEIGHT := Vector2i(11, 14)
## Nagy szobákban ennyi plusz szörny, és legfeljebb ennyi lehet egy szobában.
const BIG_ROOM_EXTRA_ENEMIES := 3
const BIG_MAX_ENEMIES := 14
const BIG_BOSS_ROOM_SIZE := Vector2i(21, 15)
## A folyosók szélessége csempében (páratlan legyen).
const CORRIDOR_WIDTH := 3
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

# Csempék helye a sprite-lapon (16 px-es rácsban).
## Az első a sima padló, a többi repedéses/díszes változat.
const FLOOR_TILES: Array[Vector2i] = [
	Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(1, 5), Vector2i(2, 5),
	Vector2i(3, 5), Vector2i(1, 6), Vector2i(2, 6),
]
const FLOOR_DECOR_CHANCE := 0.15
const WALL_FACE := Vector2i(2, 1)
const WALL_FACE_DECOR: Array[Vector2i] = [
	Vector2i(1, 2), Vector2i(2, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 2), Vector2i(3, 3),
]
const WALL_TOP := Vector2i(2, 0)
## Átlátszó csempe ütközővel: a látható fal mögötti/melletti tömör rész.
const WALL_SOLID := Vector2i(0, 0)
const WALL_THICKNESS := 2
## A bolt fapadlója: a csempekészlet 1-es forrása (Kenney RPG lap).
const WOOD_SOURCE := 1
const WOOD_TILES: Array[Vector2i] = [Vector2i(8, 2), Vector2i(8, 3)]
## A Kenney-padló világos; sötétebb, melegebb árnyalatra húzzuk.
const WOOD_TINT := Color(0.62, 0.48, 0.42)
## Ekkora eséllyel kerül láda egy harci szobába (a kitakarítás után jelenik meg).
const CHEST_CHANCE := 0.5
## Ekkora eséllyel van bolt egy emeleten (legfeljebb egy).
const SHOP_CHANCE := 0.6
## Minden ennyiedik emeleten főellenség van; a terme ekkora (csempe).
const BOSS_EVERY := 3
const RETURN_PORTAL := preload("res://rooms/obstacles/return_portal.gd")
## A gyakorló pálya szobái (balról jobbra): kezdő, harc + láda, bolt, lépcső.
const TUTORIAL_CELLS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
const BOSS_ROOM_SIZE := Vector2i(15, 11)
const NO_SHOP := Vector2i(999999, 999999)

@export var room_scene: PackedScene
@export var base_room_count := 6
@export var max_room_count := 12
@export var max_enemies_per_room := 8

var _floor := {}
## Fapadlós csempék (a bolt belseje).
var _wood_floor := {}
var _shop_return := Vector2.ZERO
var _teleporting := false
var _cell := CELL
var _big_rooms := false

@onready var _floor_layer: TileMapLayer = $FloorLayer
@onready var _wall_layer: TileMapLayer = $WallLayer
@onready var _entities: Node2D = $Entities
@onready var _rooms: Node2D = $Entities/Rooms
@onready var _player: Node2D = $Entities/Player
@onready var _hud: CanvasLayer = $HUD
@onready var _death_screen: CanvasLayer = $DeathScreen


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.1, 0.07, 0.09))
	# Indításkor egyszer teljes képernyő; utána az F11-es váltás megmarad.
	if not GameState.display_initialized:
		GameState.display_initialized = true
		if Audio.saved_fullscreen():
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	Audio.music("dungeon")
	GameCursor.apply()
	var tile_set := _build_tile_set()
	_floor_layer.tile_set = tile_set
	_wall_layer.tile_set = tile_set

	var depth := GameState.depth
	_big_rooms = depth >= BIG_ROOMS_FROM
	_cell = BIG_CELL if _big_rooms else CELL
	# Gyakorló pálya (tutorial): rögzített, egyenes sor: kezdőszoba, harc + láda, bolt, lépcső.
	var tutorial := GameState.tutorial
	var cells: Array[Vector2i] = TUTORIAL_CELLS.duplicate() if tutorial \
		else _generate_layout(mini(base_room_count + depth - 1, max_room_count))
	var distances := _distances_from_start(cells)
	var stairs_cell := _farthest(distances)
	var shop_cell := TUTORIAL_CELLS[2] if tutorial else _pick_shop_cell(cells, stairs_cell)
	# Minden BOSS_EVERY. emeleten a lépcsős szoba helyett főellenség-terem van.
	var boss_floor := depth % BOSS_EVERY == 0 and not tutorial
	var alcove_dir := _free_direction(cells, stairs_cell) if boss_floor else Vector2i.ZERO

	var room_rects := {}
	for cell in cells:
		if boss_floor and cell == stairs_cell:
			var boss_size := BIG_BOSS_ROOM_SIZE if _big_rooms else BOSS_ROOM_SIZE
			room_rects[cell] = Rect2i(cell * _cell - boss_size / 2, boss_size)
		else:
			room_rects[cell] = _random_room_rect(cell)
		_carve(room_rects[cell])
	if boss_floor and alcove_dir != Vector2i.ZERO:
		_carve(_alcove_rect(room_rects[stairs_cell], stairs_cell * _cell, alcove_dir))
	for cell in cells:
		for dir in [Vector2i.RIGHT, Vector2i.DOWN]:
			if cells.has(cell + dir):
				_carve_corridor(room_rects[cell], room_rects[cell + dir], cell, dir)
	if shop_cell != NO_SHOP:
		# A bolt belseje: külön szoba fapadlóval, messze a pályától.
		for rect in [ShopInterior.RECT, ShopInterior.EXIT_RECT]:
			_carve(rect)
			for x in range(rect.position.x, rect.end.x):
				for y in range(rect.position.y, rect.end.y):
					_wood_floor[Vector2i(x, y)] = true
	_paint_tiles()

	for cell in cells:
		var room: Room = room_scene.instantiate()
		room.anchor = cell * _cell
		room.rect = room_rects[cell]
		room.depth = depth
		for dir in DIRECTIONS:
			if cells.has(cell + dir):
				room.connections.append(dir)
		var distance: int = distances[cell]
		if cell == shop_cell:
			room.has_shop = true
		elif boss_floor and cell == stairs_cell:
			room.has_boss = true
			room.alcove_dir = alcove_dir
			room.enemy_count = 1
		elif distance > 0:
			if _big_rooms:
				room.enemy_count = mini(2 + BIG_ROOM_EXTRA_ENEMIES + distance / 2 + depth - 1, BIG_MAX_ENEMIES)
			else:
				room.enemy_count = mini(2 + distance / 2 + depth - 1, max_enemies_per_room)
			room.trap_count = randi_range(1, mini(2 + depth / 2, 4))
			room.has_chest = randf() < CHEST_CHANCE
		room.has_stairs = cell == stairs_cell and not boss_floor
		if tutorial:
			room.trap_count = 1 if cell == stairs_cell else 0
			room.has_chest = cell == TUTORIAL_CELLS[1]
			if room.enemy_count > 0:
				room.enemy_count = 3 if cell == TUTORIAL_CELLS[1] else 4
		_rooms.add_child(room)
		room.cleared.connect(_hud.show_message.bind("Szoba kitisztítva!"))
		room.stairs_used.connect(_go_deeper)
		room.shop_entered.connect(_enter_shop)
		room.boss_fight_started.connect(_on_boss_fight_started)
		room.boss_defeated.connect(_on_boss_defeated)

	if shop_cell != NO_SHOP:
		var interior := ShopInterior.new()
		_entities.add_child(interior)
		interior.exited.connect(_exit_shop)

	_player.global_position = Room.tile_center(Vector2i.ZERO)
	_player.get_node("Camera2D").reset_smoothing()
	_player.connect("death_finished", Callable(_death_screen, "show_for").bind(_player))
	var rooms: Array[Room] = []
	rooms.assign(_rooms.get_children())
	_hud.call("setup_map", rooms, _player, _cell)
	# Küldetés: elért emelet (a gyakorló pályán nem számít).
	Quests.notify("floor", depth)
	add_child(QuestTracker.new())
	if tutorial:
		_hud.show_message("Gyakorló pálya")
		var guide := TutorialGuide.new()
		guide.name = "TutorialGuide"
		add_child(guide)
		guide.call("setup", self, rooms)
	else:
		_hud.show_message(("%d. emelet — főellenség vár!" if boss_floor else "%d. emelet") % depth)


func _on_boss_fight_started(boss: Node2D) -> void:
	Audio.music("boss")
	_hud.call("show_boss", boss)
	_hud.show_message("Főellenség: %s" % boss.get("boss_name"))


func _on_boss_defeated(boss: Node2D) -> void:
	Audio.music("dungeon")
	_hud.call("hide_boss")
	_hud.show_message("%s legyőzve! A lépcső szabad, és megnyílt a kék portál a táborba." % boss.get("boss_name"))
	# Visszaút-portál a teremben (a fülkével ellentétes oldalon, hogy ne takarja a lépcsőt).
	var room: Room = boss.get_parent().get_parent()
	var portal: Node2D = RETURN_PORTAL.new()
	portal.position = Room.tile_center(room.anchor - room.alcove_dir * 3) - room.position
	room.add_child.call_deferred(portal)


## Ha a kazamatában bezárod az ablakot, az is kilépésnek számít: a pénzed 40%-a a táborba kerül.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not GameState.tutorial:
		var player := get_tree().get_first_node_in_group("player")
		if player and not player.get_node("Health").is_dead():
			Records.submit_run(player)
			Progress.rescue_gold(int(player.get("gold")), 0.4)


## A főellenség-terem mögötti fülke iránya: olyan oldal, ahol nincs szomszédos szoba
## (előnyben az észak). Vector2i.ZERO, ha minden oldalon van szomszéd.
func _free_direction(cells: Array[Vector2i], cell: Vector2i) -> Vector2i:
	for dir: Vector2i in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
		if not cells.has(cell + dir):
			return dir
	return Vector2i.ZERO


## A fülke padlója (a szoba szélétől kifelé, a cella közepének vonalán, 3 széles).
func _alcove_rect(room_rect: Rect2i, anchor: Vector2i, dir: Vector2i) -> Rect2i:
	var depth := Room.ALCOVE_DEPTH
	match dir:
		Vector2i.UP: return Rect2i(anchor.x - 1, room_rect.position.y - depth, 3, depth)
		Vector2i.DOWN: return Rect2i(anchor.x - 1, room_rect.end.y, 3, depth)
		Vector2i.LEFT: return Rect2i(room_rect.position.x - depth, anchor.y - 1, depth, 3)
		_: return Rect2i(room_rect.end.x, anchor.y - 1, depth, 3)


## Emeletenként legfeljebb egy bolt, SHOP_CHANCE eséllyel; nem a kezdő-
## és nem a lépcsős szobába kerül. NO_SHOP, ha ezen az emeleten nincs bolt.
func _pick_shop_cell(cells: Array[Vector2i], stairs_cell: Vector2i) -> Vector2i:
	if randf() >= SHOP_CHANCE:
		return NO_SHOP
	var candidates := cells.filter(func(c: Vector2i) -> bool: return c != Vector2i.ZERO and c != stairs_cell)
	if candidates.is_empty():
		return NO_SHOP
	var cell: Vector2i = candidates.pick_random()
	return cell


func _process(delta: float) -> void:
	GameState.run_time += delta


func _enter_shop(return_position: Vector2) -> void:
	_shop_return = return_position
	_teleport(ShopInterior.entrance_position(), "Bolt")


func _exit_shop() -> void:
	_teleport(_shop_return, "")


## Elsötétül a kép, átteszi a játékost, majd kivilágosodik.
func _teleport(target: Vector2, message: String) -> void:
	if _teleporting:
		return
	_teleporting = true
	_player.set_physics_process(false)
	await _hud.call("fade_out")
	_player.global_position = target
	_player.get_node("Camera2D").reset_smoothing()
	await _hud.call("fade_in")
	_player.set_physics_process(true)
	_teleporting = false
	if not message.is_empty():
		_hud.show_message(message)


func _go_deeper() -> void:
	# A gyakorló pálya végén a lépcső befejezi a gyakorlást.
	if GameState.tutorial:
		get_node("TutorialGuide").call("finish")
		return
	_player.save_state()
	GameState.depth += 1
	get_tree().reload_current_scene.call_deferred()


## Véletlen bolyongás a rácson: egy meglévő szoba mellé tesz újat.
func _generate_layout(count: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = [Vector2i.ZERO]
	while cells.size() < count:
		var next: Vector2i = cells.pick_random() + DIRECTIONS.pick_random()
		if not cells.has(next):
			cells.append(next)
	return cells


## Hány szobányi lépésre van minden szoba a kezdőtől (szélességi bejárás).
func _distances_from_start(cells: Array[Vector2i]) -> Dictionary:
	var distances := {Vector2i.ZERO: 0}
	var queue: Array[Vector2i] = [Vector2i.ZERO]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for dir in DIRECTIONS:
			var next := cell + dir
			if cells.has(next) and not distances.has(next):
				distances[next] = distances[cell] + 1
				queue.append(next)
	return distances


func _farthest(distances: Dictionary) -> Vector2i:
	var best := Vector2i.ZERO
	for cell: Vector2i in distances:
		if distances[cell] > distances[best]:
			best = cell
	return best


## A szoba mindig tartalmazza a cella középső sorát és oszlopát,
## mert a folyosók ezek mentén futnak.
func _random_room_rect(cell: Vector2i) -> Rect2i:
	var widths := BIG_ROOM_WIDTH if _big_rooms else ROOM_WIDTH
	var heights := BIG_ROOM_HEIGHT if _big_rooms else ROOM_HEIGHT
	var size := Vector2i(randi_range(widths.x, widths.y), randi_range(heights.x, heights.y))
	var jitter := Vector2i(randi_range(-ROOM_JITTER, ROOM_JITTER), randi_range(-ROOM_JITTER, ROOM_JITTER))
	return Rect2i(cell * _cell - size / 2 + jitter, size)


func _carve(rect: Rect2i) -> void:
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			_floor[Vector2i(x, y)] = true


func _carve_corridor(from: Rect2i, to: Rect2i, cell: Vector2i, dir: Vector2i) -> void:
	var anchor := cell * _cell
	var half := CORRIDOR_WIDTH / 2
	if dir == Vector2i.RIGHT:
		_carve(Rect2i(from.end.x, anchor.y - half, to.position.x - from.end.x, CORRIDOR_WIDTH))
	else:
		_carve(Rect2i(anchor.x - half, from.end.y, CORRIDOR_WIDTH, to.position.y - from.end.y))


## Padló + falak. A padló fölötti falcsempe "homlokzat" (téglafal),
## fölötte a fal teteje; a többi falcella láthatatlan, de tömör.
func _paint_tiles() -> void:
	for pos: Vector2i in _floor:
		if _wood_floor.has(pos):
			_floor_layer.set_cell(pos, WOOD_SOURCE, WOOD_TILES.pick_random())
			continue
		var floor_tile: Vector2i = FLOOR_TILES.pick_random() if randf() < FLOOR_DECOR_CHANCE else FLOOR_TILES[0]
		_floor_layer.set_cell(pos, 0, floor_tile)
	var faces := {}
	for pos: Vector2i in _floor:
		# Két csempe vastag fal, hogy semmit ne lökhessen át rajta a fizika.
		for dx in range(-WALL_THICKNESS, WALL_THICKNESS + 1):
			for dy in range(-WALL_THICKNESS, WALL_THICKNESS + 1):
				var wall := pos + Vector2i(dx, dy)
				if _floor.has(wall) or _wall_layer.get_cell_source_id(wall) != -1:
					continue
				if _floor.has(wall + Vector2i.DOWN):
					var face: Vector2i = WALL_FACE_DECOR.pick_random() if randf() < 0.08 else WALL_FACE
					_wall_layer.set_cell(wall, 0, face)
					faces[wall] = true
				else:
					_wall_layer.set_cell(wall, 0, WALL_SOLID)
	for face: Vector2i in faces:
		var top := face + Vector2i.UP
		if not _floor.has(top) and not faces.has(top):
			_wall_layer.set_cell(top, 0, WALL_TOP)


func _build_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(16, 16)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 0)
	var source := TileSetAtlasSource.new()
	source.texture = SpriteSheet.TEXTURE
	source.texture_region_size = Vector2i(16, 16)
	tile_set.add_source(source, 0)
	var square := PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
	var solid: Array[Vector2i] = [WALL_FACE, WALL_TOP, WALL_SOLID]
	solid.append_array(WALL_FACE_DECOR)
	for coords in solid:
		source.create_tile(coords)
		var data := source.get_tile_data(coords, 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, square)
	for coords in FLOOR_TILES:
		if not source.has_tile(coords):
			source.create_tile(coords)
	# Fapadló a bolthoz (Kenney Roguelike RPG Pack, 1 px hézaggal).
	var wood := TileSetAtlasSource.new()
	wood.texture = ShopInterior.RPG
	wood.texture_region_size = Vector2i(16, 16)
	wood.separation = Vector2i(1, 1)
	tile_set.add_source(wood, WOOD_SOURCE)
	for coords in WOOD_TILES:
		wood.create_tile(coords)
		wood.get_tile_data(coords, 0).modulate = WOOD_TINT
	return tile_set
