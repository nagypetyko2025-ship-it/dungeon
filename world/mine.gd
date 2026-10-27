class_name Mine
extends Node2D
## A bánya: a város keleti részéből (a raktár és a tó között félúton) földút vezet fel északra az erdőn át egy
## tisztásig, ahol egy hegy áll: három füves sziklaterasz, a csúcsa havas, az alsó falában ácsolt bányabejárat
## sínnel. A hegy képe: assets/props/mountain.png (a sziklacsempék az "Adventure Awaits" csomagból, CC0; a fű a
## játék füve, a hó és a bejárat ehhez a projekthez rajzolva).
## A bejáratnál E-re bemész: a belső tér messze a pályától van. Délről alagút (sín, bányakocsi, támfák, fáklyák)
## vezet egy nagy barlangterembe, amit keresztben sötét szakadék vág ketté. A régi deszkahíd közepe leszakadt:
## a déli csonkjára ráállhatsz és lenézhetsz, a túloldalon (a felborult kocsi mögött) tovább megy a járat.
## Puskás Döme (lásd Blaster) a küldetései után itt vár a szakadéknál: E-re felrobbantja a túlsó fal sziklaorrát,
## ami beékelődik a leszakadt rész helyére, rá deszkát fektet, és onnantól át lehet menni a túlsó partra (ott
## egyelőre nincs semmi).
## A túlsó falban az ácsolt régi tárna (E-re be): mögötte egy terem hatalmas lyukkal, a szélétől lépcső vezet le a
## sötétbe. A lépcsőnél E-re a próbatétel ablaka (lásd Challenge, ChallengePanel): onnan indul a véletlen kazamata.
## A kopogás titka (Knocking): a lyuk keleti szélén fülelni lehet (a brigád jele szól a mélyből), a nyugati szélén a
## pókselyem kötél (a Kopogó-küldetés alatt): azon le a régi tárnákba. A Kopogó után Gyula itt áll, a lyuk mellett.
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
## A beékelődő szikla (Kenney szürke kő, 8x nagyítva: szélesebb a hídnál, hogy két oldalt kilátsszon).
const BOULDER := Vector2i(55, 21)
## Döme helye a parton, a híd bal oldalán.
const DOME_SPOT := Vector2(608.6, 10.4) * TILE
## A régi tárna bejárata a túlsó falban (a híd fölött): a túlsó parton előtte állva E.
const DEEP_DOOR := Vector2(BRIDGE_COLUMN + 1, CAVERN.position.y + 0.7) * TILE
## A lyukas terem (messze mindentől): középen a lyuk, a déli szélétől lépcső le; a déli falon az ajtó vissza.
const DEEP_ROOM := Rect2i(640, 0, 14, 10)
const DEEP_HOLE := Rect2i(643, 1, 8, 5)
const DEEP_STAIRS_COLUMN := 646
const DEEP_EXIT := Vector2i(647, 10)
const DEEP_BOUNDS := Rect2i(636, -5, 22, 18)
const DEEP_LIGHT := Color(0.24, 0.22, 0.28)
## A lyuk keleti szélén itt lehet fülelni, a nyugatin lóg a kötél; Gyula helye a Kopogó után.
const DEEP_LISTEN := Vector2(DEEP_HOLE.end.x + 0.6, DEEP_HOLE.position.y + 2.0) * TILE
const DEEP_ROPE := Vector2(DEEP_HOLE.position.x - 0.5, DEEP_HOLE.position.y + 2.0) * TILE
const GYULA_SPOT := Vector2(DEEP_ROOM.position.x + 1.6, DEEP_ROOM.position.y + 7.6) * TILE

var _camp: Node2D
var _player: Node2D
var _entities: Node2D
var _prompt: Label
var _inside := false
var _busy := false
## A belső tér járható csempéi (a part, az alagút és a híd déli csonkja).
var _floor := {}
var _rng := RandomNumberGenerator.new()
## A leszakadt híd képei (a robbantás után eltűnnek) és a megjavítotté (akkor jelennek meg), a szikla, és a
## javításig a túlpartot elzáró ütköző (a déli csonk vége előtt).
var _broken_nodes: Array[CanvasItem] = []
var _fixed_nodes: Array[CanvasItem] = []
var _boulder: Sprite2D
var _gate: StaticBody2D
var _dome: AnimatedSprite2D
var _dome_dialogue: DialoguePanel
var _flash: ColorRect
var _in_deep := false
var _challenge_panel: ChallengePanel
var _rope: Node2D
var _gyula: Node2D
var _gyula_dialogue: DialoguePanel
## A kamera rázása (pixel, csökken).
var _shake := 0.0


func setup(camp: Node2D) -> void:
	_camp = camp
	_entities = camp.get_node("Entities")
	_player = camp.get_node("Entities/Player")
	_dome_dialogue = DialoguePanel.new()
	_dome_dialogue.name = "MineBlasterDialogue"
	_dome_dialogue.npc_id = Blaster.ID
	_dome_dialogue.npc_name = Blaster.NAME
	_dome_dialogue.portrait = Blaster.portrait()
	_dome_dialogue.options_provider = func() -> Array[Dictionary]: return Blaster.options("mine", _blast_option)
	camp.add_child.call_deferred(_dome_dialogue)
	_gyula_dialogue = DialoguePanel.new()
	_gyula_dialogue.name = "MineMinerDialogue"
	_gyula_dialogue.npc_id = Warehouse.MINER_ID
	_gyula_dialogue.npc_name = Knocking.NAME
	var face := AtlasTexture.new()
	face.atlas = Warehouse.MINER_SHEET
	face.region = Rect2(0, 0, 16, 16)
	_gyula_dialogue.portrait = face
	_gyula_dialogue.greeting = "[i]Gyula a lyuk szélén ül, a csákányát a térdén tartja.[/i]\n\n" \
		+ "Csend van odalent. Tizenkét év után először. Furcsa, de jó."
	_gyula_dialogue.options_provider = func() -> Array[Dictionary]: return Knocking.options()
	camp.add_child.call_deferred(_gyula_dialogue)
	_challenge_panel = ChallengePanel.new()
	_challenge_panel.name = "ChallengePanel"
	_challenge_panel.visible = false
	camp.add_child.call_deferred(_challenge_panel)


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
	var jitter := Vector2.ZERO
	if _shake > 0.0:
		jitter = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
		_shake = move_toward(_shake, 0.0, delta * 30.0)
	(_player.get_node("Camera2D") as Camera2D).offset = Vector2(jitter.x, -LOOK_UP * look + jitter.y)
	if _dome:
		_dome.visible = Blaster.at_mine()
	if _rope:
		_rope.visible = Knocking.rope_hangs()
		_gyula.visible = Knocking.moved()
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
	# A híd (a javítás előtt a két csonk közti rész az ütköző mögött van) és a túlsó part is járható: a falak és a
	# szakadék szélei így mindkét állapotban jók.
	for y in range(CHASM_TOP, CHASM_BOTTOM + 1):
		for x in [BRIDGE_COLUMN, BRIDGE_COLUMN + 1]:
			_floor[Vector2i(x, y)] = true
	for x in range(CAVERN.position.x, CAVERN.end.x):
		for y in range(CAVERN.position.y, CHASM_TOP):
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
	_dome = AnimatedSprite2D.new()
	_dome.sprite_frames = Blaster.frames()
	_dome.scale = Vector2(2, 2)
	_dome.offset.y = -Blaster.FIGURE.size.y / 2.0
	_dome.position = DOME_SPOT
	_dome.play("idle")
	_dome.visible = Blaster.at_mine()
	_entities.add_child(_dome)
	_apply_bridge_state()
	_build_deep_room()


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
## A megjavított híd képei (a beékelődött szikla és a deszkák a résen) is itt készülnek, rejtve.
func _build_bridge() -> void:
	_boulder = _rpg(BOULDER, Vector2(BRIDGE_COLUMN + 1, CHASM_BOTTOM - 2) * TILE, -9)
	_boulder.scale = Vector2(8, 8)
	_fixed_nodes.append(_boulder)
	for side in 2:
		var column := BRIDGE_COLUMN + side
		_tile(BRIDGE[side], Vector2i(column, CHASM_TOP), -8)
		_broken_nodes.append(_tile(BRIDGE_BROKEN_DOWN[side], Vector2i(column, CHASM_TOP + 1), -8))
		_broken_nodes.append(_tile(DANGLE[side], Vector2i(column, CHASM_TOP + 2), -8))
		_broken_nodes.append(_tile(BRIDGE_BROKEN_UP[side], Vector2i(column, CHASM_BOTTOM - 1), -8))
		_tile(BRIDGE[side], Vector2i(column, CHASM_BOTTOM), -8)
		for y in range(CHASM_TOP + 1, CHASM_BOTTOM):
			_fixed_nodes.append(_tile(BRIDGE[side], Vector2i(column, y), -8))
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
	# A robbanás villanása (az egész képernyőn).
	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 4
	add_child(flash_layer)
	_flash = ColorRect.new()
	_flash.color = Color(1, 0.95, 0.85, 0.0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(_flash)


func _focus() -> Array:
	if _busy or not is_instance_valid(_player):
		return []
	var at: Vector2 = _player.global_position
	if not _inside:
		if at.distance_to(ENTRANCE) < INTERACT_RANGE:
			return ["enter", "[E] Belépés: bánya"]
		return []
	if _in_deep:
		if at.distance_to(_center(DEEP_EXIT + Vector2i.UP)) < INTERACT_RANGE:
			return ["deep_exit", "[E] Vissza a szakadékhoz"]
		if _gyula.visible and at.distance_to(GYULA_SPOT) < INTERACT_RANGE:
			return ["miner", "[E] Beszélgetés: %s" % Knocking.NAME]
		if Knocking.rope_ready() and at.distance_to(DEEP_ROPE) < INTERACT_RANGE + 8:
			return ["rope", "[E] Leereszkedni a kötélen (a régi tárnák)"]
		if at.distance_to(DEEP_LISTEN) < INTERACT_RANGE + 8:
			return ["listen", "[E] Fülelsz a lyuk szélén"]
		if at.distance_to(Vector2(DEEP_STAIRS_COLUMN + 1, DEEP_HOLE.end.y + 0.6) * TILE) < INTERACT_RANGE + 8:
			return ["challenge", "[E] Lemenni a lyukba (próbatétel)"]
		return []
	if Blaster.bridge_fixed() and at.distance_to(DEEP_DOOR) < INTERACT_RANGE:
		return ["deep_enter", "[E] Belépés: a régi tárna"]
	if at.distance_to(_exit_point()) < INTERACT_RANGE:
		return ["exit", "[E] Kilépés a bányából"]
	if _dome.visible and at.distance_to(_dome.position) < INTERACT_RANGE:
		return ["dome", "[E] Beszélgetés: %s" % Blaster.NAME]
	if not Blaster.bridge_fixed() and at.distance_to(Vector2(BRIDGE_COLUMN + 1, CHASM_BOTTOM) * TILE) < INTERACT_RANGE:
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
		"deep_enter": _move_deep(true)
		"deep_exit": _move_deep(false)
		"challenge": _offer_challenge()
		"listen":
			var heard := Knocking.listen()
			message.emit(heard)
			if heard == Knocking.LISTEN_TEXT:
				_knock_sounds()
		"rope":
			Audio.play("ui_open")
			var start := func(challenge: Dictionary) -> void: _camp.call("enter_challenge", challenge)
			_challenge_panel.show_offer(Knocking.run_challenge(), start)
			_camp.get_node("Menus").call("open_menu", _challenge_panel)
		"miner":
			Audio.play("ui_open")
			_camp.get_node("Menus").call("open_menu", _gyula_dialogue)
		"dome":
			Audio.play("ui_open")
			_dome_dialogue.greeting = Blaster.greeting("mine")
			_camp.get_node("Menus").call("open_menu", _dome_dialogue)
		"chasm":
			Audio.play("footstep", -4.0)
			message.emit("A híd közepe leszakadt, alatta koromsötét. Ledobsz egy kavicsot: sokáig nem hallod, hogy "
				+ "földet érne. A túloldalon tovább megy a járat... Puskás Döme, a robbantómester talán tudná, "
				+ "hogyan lehet átjutni.")


## A híd állapota szerint: a leszakadt vagy a megjavított képek, és a javításig a túlpartot elzáró ütköző.
func _apply_bridge_state() -> void:
	var fixed := Blaster.bridge_fixed()
	for node in _broken_nodes:
		node.visible = not fixed
	for node in _fixed_nodes:
		node.visible = fixed
	if fixed and _gate:
		_gate.queue_free()
		_gate = null
	elif not fixed and not _gate:
		_gate = _solid(Rect2(Vector2(BRIDGE_COLUMN, CHASM_BOTTOM - 2) * TILE, Vector2(2, 1) * TILE))


## Döme "Robbants!" válasza: a beszélgetés bezárul, és lejátszódik a robbantás.
func _blast_option() -> String:
	_camp.get_node("Menus").call("close_current")
	_blast.call_deferred()
	return ""


## A robbantás: Döme a csonk végére megy, átdobja a dinamitot a túlsó fal sziklaorrára, visszaszalad; robbanás
## (villanás, rázkódás, kőzápor), a sziklaorr lezuhan és beékelődik a résbe, Döme deszkát fektet rá. Utána a
## túlpart járható.
func _blast() -> void:
	if _busy or Blaster.bridge_fixed():
		return
	_busy = true
	var stub_end := Vector2(BRIDGE_COLUMN + 1, CHASM_BOTTOM - 0.6) * TILE
	var rock_face := Vector2(BRIDGE_COLUMN + 1, CAVERN.position.y - 0.7) * TILE
	_dome.play("run")
	var walk := create_tween()
	walk.tween_property(_dome, "position", stub_end + Vector2(0, 14), 0.8)
	await walk.finished
	_dome.play("idle")
	# A dinamit ívben átrepül a túlsó falra.
	var dynamite := _dynamite()
	dynamite.position = _dome.position + Vector2(0, -30)
	var from := dynamite.position
	var throw := create_tween()
	var arc := func(t: float) -> void:
		dynamite.position = from.lerp(rock_face, t) + Vector2(0, -sin(t * PI) * 90.0)
		dynamite.rotation = t * TAU * 1.5
	throw.tween_method(arc, 0.0, 1.0, 0.7)
	await throw.finished
	FloatingText.spawn(_entities, _dome.position + Vector2(0, -60), "Fedezékbe!", Color(1, 0.8, 0.4), 22)
	_dome.play("run")
	_dome.flip_h = true
	var back := create_tween()
	back.tween_property(_dome, "position", DOME_SPOT, 0.9)
	await get_tree().create_timer(1.4).timeout
	_dome.play("idle")
	_dome.flip_h = false
	# Robbanás.
	dynamite.queue_free()
	Audio.play("boss_slam", 4.0, 0.0)
	Audio.play("trap", 2.0)
	Audio.play("boss_roar", -6.0, 0.0)
	_shake = 16.0
	_flash.color.a = 0.85
	create_tween().tween_property(_flash, "color:a", 0.0, 0.5)
	_debris(rock_face, 22)
	await get_tree().create_timer(0.35).timeout
	# A sziklaorr lezuhan, és beékelődik a résbe.
	var rest := _boulder.position
	_boulder.position = rock_face
	_boulder.visible = true
	var fall := create_tween()
	fall.tween_property(_boulder, "position", rest, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await fall.finished
	Audio.play("boss_slam", 0.0)
	_shake = 10.0
	_debris(rest, 12)
	await get_tree().create_timer(0.8).timeout
	# Döme deszkát fektet a sziklára, soronként (a déli csonktól északra).
	for node in _broken_nodes:
		node.visible = false
	_dome.play("run")
	var to_bridge := create_tween()
	to_bridge.tween_property(_dome, "position", stub_end + Vector2(0, 14), 0.6)
	await to_bridge.finished
	_dome.play("idle")
	var planks := _fixed_nodes.duplicate()
	planks.erase(_boulder)
	# Soronként (mindkét fele egyszerre), délről észak felé.
	planks.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.position.y > b.position.y)
	for i in range(0, planks.size(), 2):
		for node: CanvasItem in planks.slice(i, i + 2):
			node.modulate.a = 0.0
			node.visible = true
			create_tween().tween_property(node, "modulate:a", 1.0, 0.2)
		Audio.play("anvil", -6.0)
		await get_tree().create_timer(0.35).timeout
	Progress.set_npc_quest(Blaster.BLAST_QUEST, "done")
	Progress.change_trust(Blaster.ID, 20)
	_apply_bridge_state()
	_dome.play("run")
	var home := create_tween()
	home.tween_property(_dome, "position", DOME_SPOT, 0.6)
	await home.finished
	_dome.play("idle")
	Audio.play("level_up")
	FloatingText.spawn(_entities, _dome.position + Vector2(0, -60), "Na, ugye!", Color(1, 0.85, 0.5), 22)
	message.emit("A szikla beékelődött a résbe, Döme deszkát fektetett rá: a szakadék fölött újra van híd.")
	_busy = false


## A dinamitköteg (három vörös rúd, kanóc, szikrázó vég).
func _dynamite() -> Node2D:
	var bundle := Node2D.new()
	bundle.z_index = 5
	add_child(bundle)
	for i in 3:
		var stick := ColorRect.new()
		stick.color = Color(0.75, 0.12, 0.1) if i != 1 else Color(0.85, 0.18, 0.12)
		stick.size = Vector2(5, 14)
		stick.position = Vector2(-8 + i * 5, -7)
		bundle.add_child(stick)
	var band := ColorRect.new()
	band.color = Color(0.45, 0.3, 0.15)
	band.size = Vector2(15, 3)
	band.position = Vector2(-8, -1)
	bundle.add_child(band)
	var spark := ColorRect.new()
	spark.color = Color(1, 0.9, 0.4)
	spark.size = Vector2(4, 4)
	spark.position = Vector2(-2, -12)
	bundle.add_child(spark)
	var blink := spark.create_tween().set_loops()
	blink.tween_property(spark, "modulate:a", 0.2, 0.08)
	blink.tween_property(spark, "modulate:a", 1.0, 0.08)
	return bundle


## Kőzápor és por egy pontból: szétrepülő kődarabok, amik leesnek és elhalványulnak.
func _debris(at: Vector2, count: int) -> void:
	for i in count:
		var piece := ColorRect.new()
		var size := randf_range(3, 8)
		piece.size = Vector2(size, size)
		piece.color = [Color(0.42, 0.36, 0.34), Color(0.3, 0.25, 0.24), Color(0.6, 0.55, 0.5, 0.7)][i % 3]
		piece.position = at
		piece.z_index = 4
		add_child(piece)
		var direction := Vector2.from_angle(randf() * TAU)
		var target := at + direction * randf_range(30, 110) + Vector2(0, randf_range(20, 70))
		var tween := piece.create_tween().set_parallel()
		tween.tween_property(piece, "position", target, randf_range(0.5, 0.9)).set_ease(Tween.EASE_OUT)
		tween.tween_property(piece, "modulate:a", 0.0, 1.0).set_delay(0.3)
		tween.chain().tween_callback(piece.queue_free)


## A lyukas terem: barlangpadló, északon sziklafal fáklyákkal és a felirattal, középen a hatalmas lyuk (a túlsó
## fala a mélybe vész), a déli szélétől kőlépcső vezet le a sötétbe, két oldalt kötélkorlát-oszlop. Délen az
## ácsolt ajtó vissza a szakadékhoz.
func _build_deep_room() -> void:
	var r := DEEP_ROOM
	var floor_tiles := {}
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			if not DEEP_HOLE.has_point(Vector2i(x, y)):
				floor_tiles[Vector2i(x, y)] = true
	var dark := ColorRect.new()
	dark.color = Color(0.06, 0.05, 0.06)
	dark.position = Vector2(DEEP_BOUNDS.position - Vector2i(4, 4)) * TILE
	dark.size = Vector2(DEEP_BOUNDS.size + Vector2i(8, 8)) * TILE
	dark.z_index = -11
	add_child(dark)
	for x in range(r.position.x - 1, r.end.x + 1):
		for y in range(r.position.y - 3, r.end.y + 1):
			var tile := Vector2i(x, y)
			var inside := x >= r.position.x and x < r.end.x
			var coords := MASS
			if DEEP_HOLE.has_point(tile):
				var row := y - DEEP_HOLE.position.y
				coords = PIT_TOP if row == 0 else (PIT_FACE[row - 1] if row < 3 else PIT_VOID)
			elif floor_tiles.has(tile):
				coords = WALL_FOOT if y == r.position.y else (PIT_LIP if y == DEEP_HOLE.end.y \
					and x >= DEEP_HOLE.position.x and x < DEEP_HOLE.end.x else FLOORS[_rng.randi() % FLOORS.size()])
			elif inside and y == r.position.y - 1:
				coords = WALL_FACE
			elif inside and y == r.position.y - 2:
				coords = WALL_TOP
			elif x == r.position.x - 1 and y >= r.position.y - 2:
				coords = RIM_RIGHT
			elif x == r.end.x and y >= r.position.y - 2:
				coords = RIM_LEFT
			elif inside and y == r.end.y:
				coords = RIM_TOP
			_tile(coords, tile, -10)
			if floor_tiles.has(tile) or tile == DEEP_EXIT:
				continue
			var near := false
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					near = near or floor_tiles.has(tile + Vector2i(dx, dy))
			if near:
				_solid(Rect2(Vector2(tile) * TILE, Vector2(TILE, TILE)))
	# Az ajtó vissza (a déli falban): sötét nyílás ácsolattal; mögötte ütköző.
	var door := ColorRect.new()
	door.color = Color(0.02, 0.015, 0.03)
	door.position = Vector2(DEEP_EXIT) * TILE + Vector2(4, 0)
	door.size = Vector2(TILE - 8, TILE)
	door.z_index = -9
	add_child(door)
	_solid(Rect2(Vector2(DEEP_EXIT + Vector2i.DOWN) * TILE, Vector2(TILE, TILE)))
	# A lépcső: a lyuk déli szélétől fokonként lefelé (északra), egyre sötétebb és keskenyebb.
	var left := DEEP_STAIRS_COLUMN * TILE
	for i in 6:
		var step := ColorRect.new()
		var inset := i * 3.0
		step.position = Vector2(left + inset, DEEP_HOLE.end.y * TILE - (i + 1) * 17.0)
		step.size = Vector2(2 * TILE - inset * 2, 13)
		step.color = Color(0.52, 0.47, 0.44).darkened(0.16 * i)
		step.z_index = -8
		add_child(step)
		var riser := ColorRect.new()
		riser.position = step.position + Vector2(0, step.size.y)
		riser.size = Vector2(step.size.x, 4)
		riser.color = Color(0.2, 0.17, 0.17).darkened(0.16 * i)
		riser.z_index = -8
		add_child(riser)
	for x: float in [left - 4.0, left + 2 * TILE + 4.0]:
		_sprite(TILES, _region(POST), Vector2(x, (DEEP_HOLE.end.y + 0.2) * TILE), 0, _entities).offset.y = -6
	# Fáklyák és felirat a sziklafalon, kövek a sarkokban.
	for x in [r.position.x + 1, r.end.x - 2]:
		var torch: Node2D = TORCH.instantiate()
		torch.position = _center(Vector2i(x, r.position.y - 1)) + Vector2(0, 2)
		add_child(torch)
	var plaque := UiStyle.label("A MÉLYSÉG PRÓBÁJA", 15, Color(0.9, 0.75, 0.5), true)
	plaque.size = Vector2(8 * TILE, 20)
	plaque.position = Vector2(r.position.x + 3, r.position.y - 1.75) * TILE
	plaque.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plaque.z_index = -7
	add_child(plaque)
	for tile in [Vector2i(r.position.x, r.end.y - 1), Vector2i(r.end.x - 1, r.end.y - 2), Vector2i(r.position.x + 1, 2)]:
		_prop(_rpg_region(ROCKS[_rng.randi() % ROCKS.size()]), _center(tile), Vector2(24, 12)).modulate = Color(0.55, 0.52, 0.55)
	_light(Vector2(DEEP_STAIRS_COLUMN + 1, DEEP_HOLE.end.y) * TILE, Color(0.55, 0.45, 0.8), 2.0, 0.6)
	_build_knocking()


## A lyuk kopogása: három hosszú, két rövid (a brigád jele).
func _knock_sounds() -> void:
	for wait in [0.4, 0.55, 0.55, 0.55, 0.22]:
		await get_tree().create_timer(wait).timeout
		Audio.play("door_lock", -10.0, 0.02)


## A pókselyem kötél (a lyuk nyugati szélén, egy cölöphöz kötve, lelóg a sötétbe) és Gyula (a Kopogó után).
func _build_knocking() -> void:
	_rope = Node2D.new()
	add_child(_rope)
	_sprite(TILES, _region(POST), DEEP_ROPE + Vector2(-8, -6), -7, _rope)
	var rope := Line2D.new()
	rope.width = 3.0
	rope.default_color = Color(0.9, 0.88, 0.8)
	rope.gradient = Gradient.new()
	rope.gradient.set_color(0, Color(0.92, 0.9, 0.82))
	rope.gradient.set_color(1, Color(0.92, 0.9, 0.82, 0.0))
	for i in 8:
		rope.add_point(DEEP_ROPE + Vector2(-2 + i * 4.0 + sin(i * 0.9) * 2.0, -4 + i * 9.0))
	rope.z_index = -7
	_rope.add_child(rope)
	_rope.visible = Knocking.rope_hangs()
	_gyula = Node2D.new()
	_gyula.position = GYULA_SPOT
	_entities.add_child(_gyula)
	var body := Sprite2D.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = Warehouse.MINER_SHEET
	atlas.region = Rect2(0, 0, 16, 16)
	body.texture = atlas
	body.scale = Vector2(2, 2)
	body.offset = Vector2(0, -8)
	_gyula.add_child(body)
	var pickaxe := Sprite2D.new()
	pickaxe.texture = Warehouse.PICKAXE
	pickaxe.scale = Vector2(0.6, 0.6)
	pickaxe.rotation = deg_to_rad(20)
	pickaxe.position = Vector2(14, -16)
	_gyula.add_child(pickaxe)
	_gyula.visible = Knocking.moved()


## Be a régi tárnába (a lyukas terembe), vagy onnan vissza a szakadék túlsó partjára.
func _move_deep(into: bool) -> void:
	_busy = true
	_in_deep = into
	Audio.play("door_unlock", -6.0)
	if into:
		var limits := Rect2(Vector2(DEEP_BOUNDS.position) * TILE, Vector2(DEEP_BOUNDS.size) * TILE)
		_camp.call("teleport_player", _center(DEEP_EXIT + Vector2i.UP), limits, DEEP_LIGHT)
	else:
		var limits := Rect2(Vector2(BOUNDS.position) * TILE, Vector2(BOUNDS.size) * TILE)
		_camp.call("teleport_player", DEEP_DOOR + Vector2(0, 14), limits, MINE_LIGHT)
	await get_tree().create_timer(0.6).timeout
	_busy = false


## A lyuk lépcsőjénél: a próbatétel ablaka (közös játékban nem érhető el).
func _offer_challenge() -> void:
	if NetLobby.is_playing(get_tree()):
		Audio.play("ui_error")
		message.emit("Közös játékban a próbatétel nem érhető el.")
		return
	Audio.play("ui_open")
	var start := func(challenge: Dictionary) -> void: _camp.call("enter_challenge", challenge)
	_challenge_panel.show_offer(Challenge.current(), start)
	_camp.get_node("Menus").call("open_menu", _challenge_panel)


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


func _solid(rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	add_child(body)
	return body


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
