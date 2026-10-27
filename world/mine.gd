class_name Mine
extends Node2D
## A bánya: a város keleti részéből (a raktár és a tó között félúton) földút vezet fel északra az erdőn át egy
## tisztásig, ahol egy hegy áll: három füves sziklaterasz, a csúcsa havas, az alsó falában ácsolt bányabejárat
## sínnel. A hegy képe: assets/props/mountain.png (a sziklacsempék az "Adventure Awaits" csomagból, CC0; a fű a
## játék füve, a hó és a bejárat ehhez a projekthez rajzolva).
## A bejáratnál E-re bemész: a belső tér messze a pályától van. Délről alagút (sín, bányakocsi, támfák, fáklyák)
## vezet egy nagy barlangterembe, amit keresztben sötét szakadék vág ketté. A régi deszkahíd közepe leszakadt:
## a déli csonkjára ráállhatsz és lenézhetsz, a túloldalon (a felborult kocsi mögött) tovább megy a járat.
## Csempék: assets/props/mine_tiles.png (a föld és a sziklafal az "Adventure Awaits" csomagból, barlangosra
## sötétítve; a szakadék, a híd, az oszlop és a támfa ehhez rajzolva), sín, kocsi, kövek: Kenney RPG.
## (A tábor építi fel: setup(camp) + build(); az utat a tábor rajzolja ki a többi földdel, a tisztás szélén a fasort
## és körülötte az erdőt is ő rakja le, a falakat is ő húzza fel.)

signal message(text: String)

const TILE := 32
const MOUNTAIN: Texture2D = preload("res://assets/props/mountain.png")
const TILES: Texture2D = preload("res://assets/props/mine_tiles.png")
const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const CONTAINERS: Texture2D = preload("res://assets/shop/barrels_and_boxes.png")
const PICKAXE: Texture2D = preload("res://assets/props/pickaxe.png")
const TORCH := preload("res://rooms/decor/torch.tscn")
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
## A bánya szája előtt (a hegy lábánál, az út végén) itt lehet belépni.
const ENTRANCE := Vector2((PATH_COLUMN + 1) * TILE, (MOUNTAIN_TOP_LEFT.y + MOUNTAIN_SIZE.y) * TILE - 4)

## A belső tér (csempékben, messze mindentől): körben sziklatömb.
const BOUNDS := Rect2i(598, -5, 28, 28)
## Az alagút délről (a bejárattól) a terem aljáig.
const TUNNEL := Rect2i(610, 12, 4, 9)
## A barlangterem: felül a túlsó perem (2 sor), alatta a szakadék, alul az innenső part (3 sor).
const CAVERN := Rect2i(602, 1, 20, 11)
const CHASM_TOP := 3
const CHASM_BOTTOM := 8
## A leszakadt híd két oszlopa: a déli csonk két sora még járható, az északi csonk a túloldalon lóg.
const BRIDGE_COLUMN := 611
## A sín oszlopa (az alagútban, a bejárattól a szakadék előtti ütközőig).
const RAIL_COLUMN := 612
const MINE_LIGHT := Color(0.3, 0.27, 0.3)
const LANTERN := 0.85
const INTERACT_RANGE := 56.0
## A csempelap (16 px) elemei: [oszlop, sor].
const FLOORS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 0),
	Vector2i(3, 0), Vector2i(2, 0)]
const MASS := Vector2i(4, 0)
const WALL_TOP := Vector2i(5, 0)
const WALL_FACE := Vector2i(6, 0)
const WALL_FOOT := Vector2i(7, 0)
const RIM_TOP := Vector2i(8, 0)
const RIM_LEFT := Vector2i(9, 0)
const RIM_RIGHT := Vector2i(10, 0)
const PIT_TOP := Vector2i(0, 1)
const PIT_FACE: Array[Vector2i] = [Vector2i(1, 1), Vector2i(2, 1)]
const PIT_VOID := Vector2i(3, 1)
const PIT_LIP := Vector2i(4, 1)
const BRIDGE: Array[Vector2i] = [Vector2i(5, 1), Vector2i(6, 1)]
const BRIDGE_BROKEN_UP: Array[Vector2i] = [Vector2i(7, 1), Vector2i(8, 1)]
const BRIDGE_BROKEN_DOWN: Array[Vector2i] = [Vector2i(9, 1), Vector2i(10, 1)]
const DANGLE: Array[Vector2i] = [Vector2i(0, 2), Vector2i(1, 2)]
const POST := Vector2i(2, 2)
const BEAM := Vector2i(3, 2)
const SUPPORT := Rect2(64, 32, 16, 32)
## Kenney RPG: függőleges sín, bányakocsik (érccel / arannyal), kőkupacok.
const RAIL := Vector2i(43, 19)
const ORE_CART := Vector2i(51, 19)
const GOLD_CART := Vector2i(49, 21)
const ROCKS: Array[Vector2i] = [Vector2i(54, 19), Vector2i(55, 19), Vector2i(56, 19), Vector2i(54, 21),
	Vector2i(55, 21), Vector2i(56, 21)]

var _camp: Node2D
var _player: Node2D
var _entities: Node2D
var _prompt: Label
var _inside := false
var _busy := false
## A belső tér járható csempéi (a part, az alagút és a híd déli csonkja).
var _floor := {}
var _rng := RandomNumberGenerator.new()


func setup(camp: Node2D) -> void:
	_camp = camp
	_entities = camp.get_node("Entities")
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
	_build_interior()
	_build_ui()


## A folyosón felfelé haladva a kamera fokozatosan feljebb néz (a -2. sortól), a tisztás aljától már LOOK_UP-pal.
func _process(delta: float) -> void:
	var tile := _player.global_position / TILE
	var look := 0.0
	if tile.x >= RECT.position.x and tile.x <= RECT.end.x:
		look = clampf((-2.0 - tile.y) / (-2.0 - RECT.end.y + 2.0), 0.0, 1.0)
	(_player.get_node("Camera2D") as Camera2D).offset.y = -LOOK_UP * look
	var focus := _focus()
	if not focus.is_empty():
		_prompt.text = focus[1]
	var target := 1.0 if not focus.is_empty() and not GamePause.active(get_tree()) else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)


## A hegy képének ez a csempéje (oszlop, sor) a szikla része (a három terasz lépcsős körvonalán belül).
static func _is_rock(col: int, row: int) -> bool:
	return row >= 5 or (row >= 2 and col >= 1 and col <= 11) or (col >= 5 and col <= 9)


# ---------------------------------------------------------------- bent

func _build_interior() -> void:
	_rng.seed = 2611
	for x in range(CAVERN.position.x, CAVERN.end.x):
		for y in range(CHASM_BOTTOM + 1, CAVERN.end.y):
			_floor[Vector2i(x, y)] = true
	for x in range(TUNNEL.position.x, TUNNEL.end.x):
		for y in range(TUNNEL.position.y, TUNNEL.end.y):
			_floor[Vector2i(x, y)] = true
	for y in [CHASM_BOTTOM - 1, CHASM_BOTTOM]:
		for x in [BRIDGE_COLUMN, BRIDGE_COLUMN + 1]:
			_floor[Vector2i(x, y)] = true
	var dark := ColorRect.new()
	dark.color = Color(0.06, 0.05, 0.06)
	dark.position = Vector2(BOUNDS.position - Vector2i(4, 4)) * TILE
	dark.size = Vector2(BOUNDS.size + Vector2i(8, 8)) * TILE
	dark.z_index = -11
	add_child(dark)
	for x in range(BOUNDS.position.x, BOUNDS.end.x):
		for y in range(BOUNDS.position.y, BOUNDS.end.y):
			_build_tile(Vector2i(x, y))
	_build_bridge()
	_build_tunnel()
	_build_cavern_props()


## Egy csempe a belső térben: part / alagút (föld, a szakadék szélén omladozó perem), a túlsó perem, a szakadék
## (felül a túlsó fala, lefelé egyre sötétebb), a terem északi sziklafala, máshol sziklatömb (a járható rész felé
## világos peremmel). Ami nem járható, de járható mellett van, szilárd.
func _build_tile(tile: Vector2i) -> void:
	var in_cavern := tile.x >= CAVERN.position.x and tile.x < CAVERN.end.x
	var coords := MASS
	if _floor.has(tile) and tile.y > CHASM_BOTTOM:
		coords = PIT_LIP if tile.y == CHASM_BOTTOM + 1 and in_cavern else FLOORS[_rng.randi() % FLOORS.size()]
	elif in_cavern and tile.y >= CHASM_TOP and tile.y <= CHASM_BOTTOM:
		coords = PIT_TOP if tile.y == CHASM_TOP else (PIT_FACE[tile.y - CHASM_TOP - 1] if tile.y < CHASM_TOP + 3 else PIT_VOID)
	elif in_cavern and tile.y == CAVERN.position.y:
		coords = WALL_FOOT
	elif in_cavern and tile.y > CAVERN.position.y and tile.y < CHASM_TOP:
		coords = FLOORS[_rng.randi() % FLOORS.size()]
	elif in_cavern and tile.y == CAVERN.position.y - 1:
		coords = WALL_FACE
	elif in_cavern and tile.y == CAVERN.position.y - 2:
		coords = WALL_TOP
	elif _open(tile + Vector2i.RIGHT):
		coords = RIM_RIGHT
	elif _open(tile + Vector2i.LEFT):
		coords = RIM_LEFT
	elif _open(tile + Vector2i.UP):
		coords = RIM_TOP
	_tile(coords, tile, -10)
	if _floor.has(tile):
		return
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if _floor.has(tile + Vector2i(dx, dy)):
				_solid(Rect2(Vector2(tile) * TILE, Vector2(TILE, TILE)))
				return


## Nyitott (nem sziklatömb) csempe: a part, az alagút, a túlsó perem és a szakadék.
func _open(tile: Vector2i) -> bool:
	if _floor.has(tile):
		return true
	return tile.x >= CAVERN.position.x and tile.x < CAVERN.end.x and tile.y >= CAVERN.position.y - 2 \
		and tile.y < CAVERN.end.y


## A leszakadt deszkahíd: a túlsó parton két oszlop és egy csonk (a végéről kötél és deszka lóg a mélybe),
## az innenső parton két oszlop és a két soros déli csonk (rá lehet állni). Előtte figyelmeztető tábla.
func _build_bridge() -> void:
	for side in 2:
		var column := BRIDGE_COLUMN + side
		_tile(BRIDGE[side], Vector2i(column, CHASM_TOP), -8)
		_tile(BRIDGE_BROKEN_DOWN[side], Vector2i(column, CHASM_TOP + 1), -8)
		_tile(DANGLE[side], Vector2i(column, CHASM_TOP + 2), -8)
		_tile(BRIDGE_BROKEN_UP[side], Vector2i(column, CHASM_BOTTOM - 1), -8)
		_tile(BRIDGE[side], Vector2i(column, CHASM_BOTTOM), -8)
	var left := BRIDGE_COLUMN * TILE + 3.0
	var right := (BRIDGE_COLUMN + 2) * TILE - 3.0
	for x: float in [left, right]:
		_sprite(TILES, _region(POST), Vector2(x, (CHASM_TOP - 0.5) * TILE), -7)
		var post := _sprite(TILES, _region(POST), Vector2(x, (CHASM_BOTTOM + 1.3) * TILE), 0, _entities)
		post.offset.y = -6
	var board := PackedVector2Array([Vector2(-40, -64), Vector2(40, -64), Vector2(40, -38), Vector2(-40, -38)])
	_camp.call("_signpost", Vector2((BRIDGE_COLUMN + 3.4) * TILE, (CHASM_BOTTOM + 2.4) * TILE), "VESZÉLY!", board,
		Rect2(-40, -64, 80, 24))


## Az alagút: sín a bejárattól a szakadék előtti ütközőig, rajta egy érces kocsi; két ácsolt támfa
## (oszlopok + szemöldökfa) fáklyákkal; a bejárat felől beszűrődő nappali fény.
func _build_tunnel() -> void:
	for y in range(CHASM_BOTTOM + 2, TUNNEL.end.y):
		_rpg(RAIL, _center(Vector2i(RAIL_COLUMN, y)), -9)
	# Az ütköző a sín végén (gerenda keresztben).
	_sprite(TILES, _region(BEAM), _center(Vector2i(RAIL_COLUMN, CHASM_BOTTOM + 2)) + Vector2(0, -12), -8)
	_prop(_rpg_region(ORE_CART), _center(Vector2i(RAIL_COLUMN, TUNNEL.position.y + 4)), Vector2(24, 14))
	for base_row in [TUNNEL.position.y + 2, TUNNEL.position.y + 6]:
		_timber_frame(base_row, base_row == TUNNEL.position.y + 2)
	# A bejárat felől beszűrődő fény: lefelé (a kijárat felé) erősödik.
	var daylight := Polygon2D.new()
	var left := TUNNEL.position.x * TILE
	var right := TUNNEL.end.x * TILE
	daylight.polygon = PackedVector2Array([Vector2(left, (TUNNEL.end.y - 1.5) * TILE), Vector2(right, (TUNNEL.end.y - 1.5) * TILE),
		Vector2(right, (TUNNEL.end.y + 0.5) * TILE), Vector2(left, (TUNNEL.end.y + 0.5) * TILE)])
	var glow := Color(0.85, 0.88, 0.74)
	daylight.vertex_colors = PackedColorArray([Color(glow, 0.0), Color(glow, 0.0), Color(glow, 0.7), Color(glow, 0.7)])
	daylight.z_index = -9
	add_child(daylight)
	_light(Vector2(TUNNEL.position.x + TUNNEL.size.x / 2.0, TUNNEL.end.y) * TILE, Color(0.85, 0.9, 1.0), 2.4, 1.1)


## Ácsolt támfa keresztben az alagúton: két oszlop a két falnál, fent szemöldökfa (a játékos alatta megy át;
## a y-szerint rendezett rétegben, hogy mögötte / előtte helyesen látsszon). Az egyik oszlopon fáklya.
func _timber_frame(base_row: int, torch_left: bool) -> void:
	var holder := Node2D.new()
	holder.position = Vector2(TUNNEL.position.x + TUNNEL.size.x / 2.0, base_row + 1) * TILE
	_entities.add_child(holder)
	var half := TUNNEL.size.x * TILE / 2.0
	for x: float in [-half + 8.0, half - 8.0]:
		_sprite(TILES, SUPPORT, Vector2(x, -TILE), 0, holder)
	for i in TUNNEL.size.x:
		_sprite(TILES, _region(BEAM), Vector2(-half + (i + 0.5) * TILE, -2 * TILE + 4), 0, holder)
	var torch: Node2D = TORCH.instantiate()
	torch.position = Vector2(-half + 8.0 if torch_left else half - 8.0, -TILE - 6)
	# A fáklya alapból a fal mögött van (z -4): itt az oszlop előtt.
	torch.z_index = 1
	holder.add_child(torch)


## A terem: kőkupacok a falak mentén, ládák, hordó, a földön egy csákány; két támoszlop fáklyával a part két
## sarkában. A túlparton egy felborult kocsi (kiszórt arannyal) és az ácsolt járat, ami tovább megy a mélybe.
func _build_cavern_props() -> void:
	var spots: Array[Vector2i] = [Vector2i(603, 10), Vector2i(604, 11), Vector2i(608, 11), Vector2i(620, 9),
		Vector2i(619, 11), Vector2i(615, 11)]
	for tile in spots:
		_prop(_rpg_region(ROCKS[_rng.randi() % ROCKS.size()]), _center(tile) + Vector2(_rng.randf_range(-6, 6), 0),
			Vector2(24, 12)).modulate = Color(0.62, 0.58, 0.6)
	_prop(Rect2(16, 0, 16, 16), _center(Vector2i(617, 10)), Vector2(26, 12), CONTAINERS).modulate = Color(0.75, 0.7, 0.66)
	_prop(Rect2(32, 0, 16, 16), _center(Vector2i(618, 11)), Vector2(24, 12), CONTAINERS).modulate = Color(0.75, 0.7, 0.66)
	_prop(Rect2(0, 0, 16, 16), _center(Vector2i(606, 10)), Vector2(24, 12), CONTAINERS).modulate = Color(0.75, 0.7, 0.66)
	var pickaxe := Sprite2D.new()
	pickaxe.texture = PICKAXE
	pickaxe.scale = Vector2(0.8, 0.8)
	pickaxe.rotation = deg_to_rad(-60)
	pickaxe.position = _center(Vector2i(616, 11)) + Vector2(-6, 0)
	pickaxe.z_index = -8
	add_child(pickaxe)
	for x in [CAVERN.position.x, CAVERN.end.x - 1]:
		var holder := Node2D.new()
		holder.position = _center(Vector2i(x, CAVERN.end.y - 1)) + Vector2(0, TILE / 2.0)
		_entities.add_child(holder)
		_sprite(TILES, SUPPORT, Vector2(0, -TILE), 0, holder)
		var torch: Node2D = TORCH.instantiate()
		torch.position = Vector2(0, -TILE - 6)
		torch.z_index = 1
		holder.add_child(torch)
	# A túlpart: a folytatódó járat (sötét nyílás ácsolattal) és egy felborult kocsi.
	var tunnel_tile := Vector2i(BRIDGE_COLUMN, CAVERN.position.y - 1)
	var opening := ColorRect.new()
	opening.color = Color(0.02, 0.015, 0.03)
	opening.position = Vector2(tunnel_tile) * TILE + Vector2(6, -TILE + 10)
	opening.size = Vector2(2 * TILE - 12, 2 * TILE - 10)
	opening.z_index = -9
	add_child(opening)
	for x: float in [tunnel_tile.x * TILE + 4.0, (tunnel_tile.x + 2) * TILE - 4.0]:
		_sprite(TILES, SUPPORT, Vector2(x, tunnel_tile.y * TILE + 4), -8)
	for i in 2:
		_sprite(TILES, _region(BEAM), Vector2((tunnel_tile.x + i + 0.5) * TILE, (tunnel_tile.y - 1) * TILE + 12), -8)
	var far_torch: Node2D = TORCH.instantiate()
	far_torch.position = _center(Vector2i(BRIDGE_COLUMN + 3, CAVERN.position.y - 1)) + Vector2(0, 2)
	add_child(far_torch)
	var cart := _rpg(GOLD_CART, _center(Vector2i(606, CAVERN.position.y + 1)), -7)
	cart.rotation = deg_to_rad(100)
	for i in 5:
		var nugget := ColorRect.new()
		nugget.color = Color(1.0, 0.82, 0.25)
		nugget.size = Vector2(4, 4)
		nugget.position = _center(Vector2i(607, CAVERN.position.y + 1)) + Vector2(_rng.randf_range(-6, 22), _rng.randf_range(-10, 8))
		nugget.z_index = -7
		add_child(nugget)


# ---------------------------------------------------------------- be- és kilépés

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
	if _busy or not is_instance_valid(_player):
		return []
	var at: Vector2 = _player.global_position
	if not _inside:
		if at.distance_to(ENTRANCE) < INTERACT_RANGE:
			return ["enter", "[E] Belépés: bánya"]
		return []
	if at.distance_to(_exit_point()) < INTERACT_RANGE:
		return ["exit", "[E] Kilépés a bányából"]
	if at.distance_to(Vector2(BRIDGE_COLUMN + 1, CHASM_BOTTOM) * TILE) < INTERACT_RANGE:
		return ["chasm", "[E] Lenézel a mélységbe"]
	return []


func _exit_point() -> Vector2:
	return Vector2(TUNNEL.position.x + TUNNEL.size.x / 2.0, TUNNEL.end.y - 0.5) * TILE


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or GamePause.active(get_tree()):
		return
	var focus := _focus()
	if focus.is_empty():
		return
	get_viewport().set_input_as_handled()
	match focus[0]:
		"enter": _move(true, _exit_point() + Vector2(0, -TILE))
		"exit": _move(false, ENTRANCE + Vector2(0, 30))
		"chasm":
			Audio.play("footstep", -4.0)
			message.emit("A híd közepe leszakadt, alatta koromsötét. Ledobsz egy kavicsot: sokáig nem hallod, hogy "
				+ "földet érne. A túloldalon tovább megy a járat... Puskás Döme, a robbantómester talán tudná, "
				+ "hogyan lehet átjutni.")


func _move(inside: bool, at: Vector2) -> void:
	_busy = true
	_inside = inside
	Audio.play("door_unlock", -6.0)
	var limits := Rect2(Vector2(BOUNDS.position) * TILE, Vector2(BOUNDS.size) * TILE) if inside else Rect2()
	_camp.call("teleport_player", at, limits, MINE_LIGHT if inside else Color.BLACK)
	await get_tree().create_timer(0.25).timeout
	_player.get_node("PointLight2D").energy = LANTERN if inside else 0.5
	await get_tree().create_timer(0.35).timeout
	_busy = false


# ---------------------------------------------------------------- segédek

func _center(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE


func _region(coords: Vector2i) -> Rect2:
	return Rect2(Vector2(coords) * 16.0, Vector2(16, 16))


func _rpg_region(coords: Vector2i) -> Rect2:
	return Rect2(Vector2(coords) * 17.0, Vector2(16, 16))


func _tile(coords: Vector2i, tile: Vector2i, z: int) -> Sprite2D:
	return _sprite(TILES, _region(coords), _center(tile), z)


func _rpg(coords: Vector2i, at: Vector2, z: int) -> Sprite2D:
	return _sprite(RPG, _rpg_region(coords), at, z)


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


## Szilárd kellék a y-szerint rendezett rétegben (a talppontja a csempe alja felé), `foot` méretű ütközővel.
func _prop(region: Rect2, at: Vector2, foot: Vector2, texture: Texture2D = RPG) -> Sprite2D:
	var holder := Node2D.new()
	holder.position = at + Vector2(0, region.size.y)
	_entities.add_child(holder)
	var sprite := _sprite(texture, region, Vector2(0, -region.size.y), 0, holder)
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = foot
	shape.shape = box
	shape.position = Vector2(0, -foot.y / 2.0)
	body.add_child(shape)
	holder.add_child(body)
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
