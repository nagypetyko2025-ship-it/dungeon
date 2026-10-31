class_name Crypt
extends Node2D
## A temető keleti bővítése a kápolnától jobbra: sötét föld, feliratos sírok (E: olvasás, mint a Graveyard-ban),
## a sarkában egy régi kripta (boltíves ajtó). E-re lemész: lent a rituálé terme
## (`INTERIOR`): oltár, a padlón izzó kör, körülötte fekete köpenyes, arctalan alakok (az "Arctalanok"),
## és Szürke Orsolya, a kripta őre (történetek + a rituálé: `RitualPanel`, `Gems`).
## (A tábor építi fel: setup(camp) + build(); csempék: 0x72 DungeonTileset II; az oltár, az alakok: assets/props/crypt, CC0.)

const TILE := 32
const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const DUNGEON: Texture2D = preload("res://assets/0x72_dungeon/0x72_DungeonTilesetII_v1.7.png")
const ALTAR: Texture2D = preload("res://assets/props/crypt/altar.png")
const HOODED: Texture2D = preload("res://assets/props/crypt/hooded.png")
const ORSOLYA: Texture2D = preload("res://assets/props/crypt/orsolya.png")
const COBWEB: Texture2D = preload("res://assets/decor/cobweb.png")

## A bővítés csempékben (a kápolna útjától keletre), és benne a kripta.
const RECT := Rect2i(89, 21, 12, 7)
const MAUSOLEUM := Rect2i(96, 21, 4, 4)
const STONE := Color(0.5, 0.48, 0.52)
const WALL_MID := Rect2(32, 16, 16, 16)
const WALL_TOP := Rect2(32, 0, 16, 16)
## 0x72 DungeonTileset II (a kazamata és a kápolna is ebből van).
const WALL_HOLE := Rect2(48, 32, 16, 16)
const BANNER := Rect2(16, 32, 16, 16)
const COLUMN := Rect2(80, 80, 16, 48)
const SKULL := Rect2(288, 432, 16, 16)
const STAIRS := Rect2(80, 192, 16, 16)
const DOOR_TOP := Rect2(32, 224, 32, 16)
const DOOR_OPEN := Rect2(80, 240, 32, 32)
const DOOR_FRAME_LEFT := Rect2(16, 240, 16, 32)
const DOOR_FRAME_RIGHT := Rect2(64, 240, 16, 32)
const GRAVES: Array[Vector2i] = Graveyard.GRAVES
const TABLETS: Array[Vector2i] = Graveyard.TABLETS
## A bővítés sírjainak feliratai: [név, szöveg].
const EPITAPHS: Array[Array] = [
	["Kőfogadó Ágota", "Harminc évig őrizte a kripta kulcsát.\nA kulcsot most a tanítványa hordja.\n\nAz ajtót senki sem zárta be azóta."],
	["Az első arctalan", "Neve volt, arca volt, alkuja volt.\nAz alku maradt meg a háromból.\n\n[color=#6b5a48]Ne kérj többet, mint amit adhatsz.[/color]"],
	["Szalai Imre, ékszerész", "Minden követ megmért, amit felhoztak.\nAz utolsót nem tudta felbecsülni.\n\nAzóta sem tudja senki."],
	["Csillag Panni", "Leesett csillagot keresett a mezőn.\nMegtalálta.\n\nA csillag is őt."],
	["Ismeretlen zarándok", "Messziről jött, hogy imádkozzon az oltárnál.\nAz oltár meghallgatta.\n\nTöbbet nem imádkozott."],
	["Orsolya húga, Kató", "„Majd jövő tavasszal lejövök én is” — mondta.\nOrsolya azóta minden tavasszal vár.\n\nA hóvirág kinyílik a sírján."],
]
const READ_RANGE := 50.0

## A rituálé terme (bent): x 700-tól.
const INTERIOR := Rect2i(700, 0, 12, 9)
const EXIT_TILE := Vector2i(705, 8)
## Az oltár középpontja és a kör középpontja (bent, világkoordinátában számolva: lásd _altar_at / _circle_at).
const ALTAR_TILE := Vector2i(705, 1)
const ORSOLYA_TILE := Vector2i(700, 4)
const INSIDE_LIGHT := Color(0.26, 0.23, 0.3)
const INTERACT_RANGE := 52.0
const TALK_RANGE := 64.0
## A kör sugara és az arctalanok helye a körhöz képest.
const CIRCLE_RADIUS := 72.0
const HOODED_SPOTS: Array[Vector2] = [Vector2(-118, -30), Vector2(118, -30), Vector2(-104, 58), Vector2(104, 58)]

const ID := "orsolya"
const NAME := "Szürke Orsolya, a kripta őre"
const SHORT_NAME := "Orsolya"
const STORIES: Array[Dictionary] = [
	{"id": "who", "text": "Ki vagy te?", "trust": 3,
		"answer": "[i]Az öregasszony nem fordul meg. A botja végével egy kört rajzol a porba, aztán elsimítja.[/i]\n\n" \
			+ "Orsolya. A faluban Szürkének hívtak, mert már fiatalon ősz voltam. A kőtől van: aki sokáig nézi a " \
			+ "Mélység köveit, abból kifut a szín.\n\n" \
			+ "Kőfogadó vagyok. Az utolsó. Mi fogadtuk a köveket, amiket a kalandorok felhoztak, és mi mondtuk meg, " \
			+ "mit kérnek érte cserébe."},
	{"id": "hooded", "text": "Kik ezek a fekete köpenyesek?", "trust": 2,
		"answer": "[i]Lehalkítja a hangját.[/i]\n\nAz Arctalanok. Ne bámuld őket, nem szeretik. Bár hogy mit szeretnek, " \
			+ "azt már ők sem tudják.\n\n" \
			+ "Kalandorok voltak, mint te. Egyszer túl sokat kértek az oltártól, és nem volt mivel fizetni. Az oltár " \
			+ "akkor azt veszi el, ami kéznél van. Az arcot, a nevet, az emlékeket.\n\n" \
			+ "Azóta itt állnak, és őrzik a kört. Bántani nem bántanak. Csak figyelnek. Mindig figyelnek."},
	{"id": "gems", "text": "Mik ezek a drágakövek?", "trust": 2,
		"answer": "A Mélység vére. Ami odalent elfolyik, az idővel kővé dermed: a nagy dögök szívében, a régi " \
			+ "ládák alján.\n\n" \
			+ "A [color=#e05050]Vérrubin[/color] haragos, a [color=#c8ccd8]Holdkő[/color] türelmes, a " \
			+ "[color=#7090ff]Viharzafír[/color] nyugtalan, az [color=#c070ff]Árnyékametiszt[/color] alattomos. " \
			+ "Mind mást ad.\n\n" \
			+ "A [color=#d8f0ff]Csillagkő[/color] más. Az nem lentről jön, hanem fentről esett le, réges-régen, " \
			+ "és a Mélység elnyelte. Ő nyitja meg az oltár fülét. Nélküle a többi kő csak szép kavics."},
	{"id": "ritual", "text": "Hogyan működik a rituálé?", "trust": 1,
		"answer": "Két követ teszel az oltárra egy fajtából, mellé egy Csillagkövet, és megfizeted a gyertyák árát: " \
			+ "ezerötszáz aranyat. Én elmondom a szavakat. A kő áldása a [b]következő[/b] utadon veled lesz, " \
			+ "aztán elfogy.\n\n" \
			+ "Egyszerre csak egy áldás. Aki kettőt akar, az kerül a körbe. [i]A csuklyások felé biccent.[/i]\n\n" \
			+ "A köveket a főellenségek őrzik: mindegyik hagy egyet. A nagyok hármat. A huszadik emelet alatt a " \
			+ "ládákban is akad néha."},
	{"id": "margit", "text": "Ismered Holló Margitot?", "trust": 3,
		"answer": "[i]Először nevet, rekedten, aztán abbahagyja.[/i]\n\nHogy ismerem-e? Együtt tanultunk. Ő a füveket " \
			+ "választotta, én a köveket. Ő a testet formálja, én a sorsot.\n\n" \
			+ "Összevesztünk valamin, ötven éve. Már egyikünk sem emlékszik, min. De egyikünk sem megy el elsőnek " \
			+ "bocsánatot kérni. Ha látod, ne mondd neki, hogy kérdeztem. [i]Szünet.[/i] Vagy mondd. Mindegy."},
	{"id": "builder", "text": "Ki építette ezt a kriptát?", "trust": 2,
		"answer": "Régebbi, mint a kápolna. Régebbi, mint a tábor. Az első király, Aurél, ezen az oltáron alkudott " \
			+ "először a Mélységgel, mielőtt még egyetlen katonája lemászott volna.\n\n" \
			+ "Hogy mit adott érte? [i]Elhallgat, és a falon a karcolásokat nézi: vonalak, ötösével áthúzva.[/i]\n\n" \
			+ "Azt kérdezd a mostani királytól. Ha elég mélyre jutottál, talán már tudja is, hogy mit kérdezel."},
	{"id": "kato", "text": "Kié a sír a kripta előtt, Katóé?", "trust": 3,
		"answer": "A húgomé. Egy évvel volt fiatalabb, és tízszer bátrabb. Lement a tizedik emeletig, amikor " \
			+ "még nem volt lift, se Bertalan, se semmi.\n\n" \
			+ "Nem jött vissza. A sírban csak a kendője van.\n\n" \
			+ "[i]Megigazítja a kendőt a saját nyakában. Ugyanolyan.[/i]\n\n" \
			+ "Néha azt álmodom, hogy az egyik csuklyás ő. Aztán felébredek, és nem nézek a szemükbe. Nincs is szemük."},
]

signal message(text: String)

var _camp: Node2D
var _player: Node2D
var _entities: Node2D
var _prompt: Label
var _panel: Graveyard.InscriptionPanel
var _ritual: RitualPanel
var _dialogue: DialoguePanel
var _rng := RandomNumberGenerator.new()
## "outside" | "crypt"
var _where := "outside"
var _busy := false
var _tablets: Array[Dictionary] = []
var _orsolya: Node2D
var _hooded: Array[Sprite2D] = []
var _circle: RitualCircle
var _t := 0.0


func setup(camp: Node2D) -> void:
	_camp = camp
	_entities = camp.get_node("Entities")
	_player = camp.get_node("Entities/Player")
	_panel = Graveyard.InscriptionPanel.new()
	_panel.name = "CryptInscription"
	camp.add_child.call_deferred(_panel)
	_ritual = RitualPanel.new()
	_ritual.name = "RitualPanel"
	_ritual.performed.connect(_on_ritual)
	camp.add_child.call_deferred(_ritual)
	_dialogue = DialoguePanel.new()
	_dialogue.name = "OrsolyaDialogue"
	_dialogue.npc_id = ID
	_dialogue.npc_name = NAME
	_dialogue.portrait = ORSOLYA
	_dialogue.options_provider = options
	camp.add_child.call_deferred(_dialogue)


## Ide nem kerülhet fa / bokor.
static func blocked_rect() -> Rect2i:
	return Rect2i(RECT.position - Vector2i(2, 2), RECT.size + Vector2i(3, 3))


## Keskeny ösvény a kápolna útjától a kripta ajtajáig (a tábor rajzolja ki).
static func path_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for x in range(Chapel.TOP_LEFT.x + Chapel.SIZE.x + 3, MAUSOLEUM.position.x + 3):
		tiles.append(Vector2i(x, MAUSOLEUM.end.y))
	return tiles


static func door_position() -> Vector2:
	return Vector2(MAUSOLEUM.position.x + 2, MAUSOLEUM.end.y) * TILE + Vector2(0, 10)


func build() -> void:
	_rng.seed = 6161
	_build_soil()
	_build_fence()
	_build_graves()
	_build_mausoleum()
	_build_interior()
	_build_ui()


# ---------------------------------------------------------------- kint: a temető bővítése

func _build_soil() -> void:
	var soil := Graveyard.Soil.new()
	soil.rect = Rect2(Vector2(RECT.position) * TILE, Vector2(RECT.size) * TILE)
	soil.seed_value = 91
	soil.z_index = -9
	add_child(soil)
	for i in 6:
		var fog := Graveyard.Fog.new()
		fog.position = _center(RECT.position + Vector2i(_rng.randi_range(1, RECT.size.x - 2), _rng.randi_range(1, RECT.size.y - 2)))
		fog.phase = _rng.randf() * TAU
		fog.z_index = 2
		add_child(fog)


## Korhadt kerítés fent és lent (nyugatról, a kápolna útja felől nyitott, mint a régi temető oldalai).
func _build_fence() -> void:
	for x in range(RECT.position.x, RECT.end.x):
		var top := _rpg(Graveyard.FENCE, _center(Vector2i(x, RECT.position.y - 1)) + Vector2(0, 14), 0, _entities)
		top.modulate = Color(0.55, 0.45, 0.4)
		if _rng.randf() < 0.15:
			top.rotation = _rng.randf_range(-0.25, 0.25)
		var bottom := _rpg(Graveyard.FENCE, _center(Vector2i(x, RECT.end.y)) + Vector2(0, 4), 0, _entities)
		bottom.modulate = Color(0.55, 0.45, 0.4)
	_solid(Rect2(Vector2(RECT.position.x, RECT.position.y - 0.4) * TILE, Vector2(RECT.size.x, 0.5) * TILE))
	_solid(Rect2(Vector2(RECT.position.x, RECT.end.y + 0.3) * TILE, Vector2(RECT.size.x, 0.5) * TILE))
	# Keleten a kerítés zárja a temetőt.
	_solid(Rect2(Vector2(RECT.end.x, RECT.position.y - 0.4) * TILE, Vector2(0.4, RECT.size.y + 0.7) * TILE))
	for y in range(RECT.position.y, RECT.end.y):
		var side := _rpg(Graveyard.FENCE, _center(Vector2i(RECT.end.x, y)) + Vector2(-10, 0), 0, _entities)
		side.modulate = Color(0.55, 0.45, 0.4)
		side.rotation = PI / 2.0


## Sírok sorokban (a kripta előtt és az ösvény sorában nincs); minden második feliratos tábla.
func _build_graves() -> void:
	var path_row := MAUSOLEUM.end.y
	var placed := 0
	for row in [1, 3, 5]:
		for x in range(RECT.position.x + 1, RECT.end.x - 1, 2):
			var tile := Vector2i(x, RECT.position.y + row)
			if tile.y == path_row:
				continue
			if x >= MAUSOLEUM.position.x - 1 and tile.y <= MAUSOLEUM.end.y:
				continue
			# A kripta ajtaja előtt szabad a hely.
			if x >= MAUSOLEUM.position.x and tile.y == MAUSOLEUM.end.y + 1:
				continue
			var mound := Graveyard.Mound.new()
			mound.position = _center(tile) + Vector2(0, 14)
			mound.z_index = -8
			add_child(mound)
			var holder := Node2D.new()
			holder.position = _center(tile) + Vector2(0, 4)
			_entities.add_child(holder)
			var tablet := _tablets.size() < EPITAPHS.size() and placed % 2 == 0
			placed += 1
			var look: Vector2i = TABLETS[_rng.randi() % TABLETS.size()] if tablet else GRAVES[_rng.randi() % 6]
			var stone := _rpg(look, Vector2(0, -12), 0, holder)
			stone.rotation = _rng.randf_range(-0.12, 0.12)
			stone.modulate = Color(0.72, 0.72, 0.8)
			if tablet:
				var epitaph: Array = EPITAPHS[_tablets.size()]
				_tablets.append({"position": holder.position, "title": epitaph[0],
					"text": "[center][i]%s[/i][/center]" % epitaph[1]})
			_body(holder, Vector2(0, -4), Vector2(22, 8))


## A kripta: tömör, sötét kőépület (0x72 fal), középen boltíves ajtókeret a nyitott ajtóval (lefelé vezet), a fal tövében koponyák.
func _build_mausoleum() -> void:
	var tl := MAUSOLEUM.position
	var w := MAUSOLEUM.size.x
	for x in w:
		_dungeon(WALL_TOP, tl + Vector2i(x, 0), -6).modulate = STONE.lightened(0.1)
		for y in [1, 2, 3]:
			_dungeon(WALL_MID, tl + Vector2i(x, y), -6).modulate = STONE.darkened(_rng.randf_range(0.0, 0.15))
	# Ajtókeret (0x72): fent a boltív, két oldalt a keret, középen a nyitott, sötét ajtó.
	var door_left := Vector2(tl.x + 1, tl.y + 2) * TILE
	# Mögötte a sötét lejárat (a nyitott ajtón át ez látszik, nem a fal).
	_rect(Rect2(door_left + Vector2(6, 4), Vector2(TILE * 2 - 12, TILE * 2 - 4)), -6, Color(0.03, 0.02, 0.05))
	_region_sprite(DUNGEON, DOOR_TOP, door_left + Vector2(TILE, -TILE * 0.5), -5).modulate = STONE.lightened(0.1)
	_region_sprite(DUNGEON, DOOR_OPEN, door_left + Vector2(TILE, TILE), -5).modulate = Color(0.75, 0.7, 0.8)
	_region_sprite(DUNGEON, DOOR_FRAME_LEFT, door_left + Vector2(-TILE * 0.5, TILE), -4).modulate = STONE.lightened(0.1)
	_region_sprite(DUNGEON, DOOR_FRAME_RIGHT, door_left + Vector2(TILE * 2.5, TILE), -4).modulate = STONE.lightened(0.1)
	var web := Sprite2D.new()
	web.texture = COBWEB
	web.scale = Vector2(2, 2)
	web.position = _center(tl + Vector2i(w - 1, 2))
	web.flip_h = true
	web.z_index = -4
	web.modulate = Color(1, 1, 1, 0.7)
	add_child(web)
	_solid(Rect2(Vector2(tl) * TILE, Vector2(MAUSOLEUM.size) * TILE - Vector2(0, 6)))
	for spot: Vector2 in [Vector2(tl.x - 0.3, tl.y + 4.2), Vector2(tl.x + 3.7, tl.y + 4.4), Vector2(tl.x + 4.2, tl.y + 3.9)]:
		_region_sprite(DUNGEON, SKULL, spot * TILE, -7).modulate = Color(0.8, 0.78, 0.75)
	# Halvány lila derengés az ajtóból.
	_light(door_position() + Vector2(0, -24), Color(0.6, 0.35, 0.9), 0.6, 0.5)


# ---------------------------------------------------------------- bent: a rituálé terme

func _build_interior() -> void:
	var r := INTERIOR
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			var floor_tile := _region_sprite(DUNGEON, Chapel.FLOOR_TILES[_rng.randi() % Chapel.FLOOR_TILES.size()], _center(Vector2i(x, y)), -10)
			floor_tile.modulate = Color(0.58, 0.54, 0.62).darkened(_rng.randf_range(0.0, 0.15))
		_region_sprite(DUNGEON, WALL_TOP, _center(Vector2i(x, r.position.y - 2)), -9).modulate = STONE
		var face := WALL_MID
		if x == r.position.x + 3 or x == r.end.x - 4:
			face = BANNER
		elif _rng.randf() < 0.15:
			face = WALL_HOLE
		_region_sprite(DUNGEON, face, _center(Vector2i(x, r.position.y - 1)), -9).modulate = STONE.darkened(0.1)
	var dark := Color(0.06, 0.05, 0.07)
	_rect(Rect2(Vector2(r.position.x - 1, r.position.y - 3) * TILE, Vector2(1, r.size.y + 4) * TILE), -9, dark)
	_rect(Rect2(Vector2(r.end.x, r.position.y - 3) * TILE, Vector2(1, r.size.y + 4) * TILE), -9, dark)
	_rect(Rect2(Vector2(r.position.x - 1, r.end.y) * TILE, Vector2(r.size.x + 2, 1) * TILE), -9, dark)
	_solid(Rect2(Vector2(r.position.x, r.position.y - 2) * TILE, Vector2(r.size.x, 2) * TILE))
	_solid(Rect2(Vector2(r.position.x - 1, r.position.y - 2) * TILE, Vector2(1, r.size.y + 3) * TILE))
	_solid(Rect2(Vector2(r.end.x, r.position.y - 2) * TILE, Vector2(1, r.size.y + 3) * TILE))
	_solid(Rect2(Vector2(r.position.x, r.end.y) * TILE, Vector2(r.size.x, 1) * TILE))
	# Kijárat: lépcső fel, alul középen.
	_region_sprite(DUNGEON, STAIRS, _center(EXIT_TILE), -9)
	# Az oltár (gyertyákkal), a sarkokban kőoszlopok, a padlón koponyák és pókhálók.
	_prop(ALTAR, _altar_at(), Vector2(2, 2), Vector2(56, 24))
	for tile: Vector2i in [Vector2i(r.position.x, r.position.y + 1), Vector2i(r.end.x - 1, r.position.y + 1),
			Vector2i(r.position.x, r.end.y - 2), Vector2i(r.end.x - 1, r.end.y - 2)]:
		var holder := Node2D.new()
		holder.position = _center(tile) + Vector2(0, 14)
		_entities.add_child(holder)
		_region_sprite(DUNGEON, COLUMN, Vector2(0, -40), 0, holder).modulate = STONE
		_body(holder, Vector2(0, -6), Vector2(26, 12))
	for i in 5:
		var at := _center(r.position + Vector2i(_rng.randi_range(1, r.size.x - 2), _rng.randi_range(2, r.size.y - 2)))
		_region_sprite(DUNGEON, SKULL, at + Vector2(_rng.randf_range(-8, 8), _rng.randf_range(-6, 6)), -8).modulate = Color(0.75, 0.72, 0.7)
	for corner: Array in [[Vector2i(r.position.x, r.position.y), false], [Vector2i(r.end.x - 1, r.position.y), true]]:
		var web := Sprite2D.new()
		web.texture = COBWEB
		web.scale = Vector2(2, 2)
		web.position = _center(corner[0])
		web.flip_h = corner[1]
		web.z_index = -7
		web.modulate = Color(1, 1, 1, 0.6)
		add_child(web)
	# A kör a padlón, körülötte az Arctalanok.
	_circle = RitualCircle.new()
	_circle.position = _circle_at()
	_circle.radius = CIRCLE_RADIUS
	_circle.z_index = -8
	add_child(_circle)
	for spot in HOODED_SPOTS:
		var holder := Node2D.new()
		holder.position = _circle_at() + spot
		_entities.add_child(holder)
		var figure := Sprite2D.new()
		figure.texture = HOODED
		figure.scale = Vector2(1.6, 1.6)
		figure.position = Vector2(0, -24)
		figure.flip_h = spot.x > 0
		figure.modulate = Color(0.75, 0.72, 0.8)
		holder.add_child(figure)
		_hooded.append(figure)
		_body(holder, Vector2(0, -6), Vector2(22, 12))
	# Szürke Orsolya a bal oldalon, a botjára támaszkodva.
	_orsolya = Node2D.new()
	_orsolya.position = _center(ORSOLYA_TILE) + Vector2(0, 14)
	_entities.add_child(_orsolya)
	var old := Sprite2D.new()
	old.texture = ORSOLYA
	old.scale = Vector2(1.5, 1.5)
	old.position = Vector2(0, -22)
	old.modulate = Color(0.85, 0.85, 0.88)
	_orsolya.add_child(old)
	_body(_orsolya, Vector2(0, -6), Vector2(22, 12))
	# Gyertyafény az oltárnál, lila derengés a körből.
	_light(_altar_at() + Vector2(0, -20), Color(1, 0.75, 0.45), 1.2, 0.9)
	_light(_circle_at(), Color(0.6, 0.3, 1.0), 1.0, 0.6)
	_light(_center(ORSOLYA_TILE), Color(0.8, 0.75, 0.7), 0.6, 0.4)


func _altar_at() -> Vector2:
	return Vector2(ALTAR_TILE.x + 1, ALTAR_TILE.y + 1) * TILE + Vector2(0, 8)


func _circle_at() -> Vector2:
	return Vector2(ALTAR_TILE.x + 1, ALTAR_TILE.y + 4) * TILE


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
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.modulate.a = 0.0
	layer.add_child(_prompt)


# ---------------------------------------------------------------- Orsolya

func options() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	list.append({"id": "do_ritual", "text": "Rituálét szeretnék (áldás a következő futásra)",
		"on_choose": func() -> String: return _open_ritual()})
	list.append_array(STORIES)
	return list


static func greeting() -> String:
	if not Progress.blessing.is_empty():
		return "[i]Orsolya rád néz, aztán a köpenyesekre.[/i] Az áldásod vár. Menj már le, mielőtt kihűl."
	return "[i]Az öregasszony fel sem néz.[/i] Ritkán jön le ide élő. Kérdezz, vagy hozz követ."


func _open_ritual() -> String:
	Audio.play("ui_open")
	var menus := _camp.get_node("Menus")
	menus.call("close_current")
	menus.call_deferred("open_menu", _ritual)
	return ""


## A rituálé után: a kör felizzik, az Arctalanok egyszerre rád fordulnak.
func _on_ritual(id: String) -> void:
	_circle.flash(Gems.LIST[id]["color"])
	Audio.play("magic")
	for figure in _hooded:
		figure.flip_h = _player.global_position.x < figure.global_position.x
	message.emit("%s: a következő futásod során veled lesz." % Gems.LIST[id]["blessing"])


# ---------------------------------------------------------------- mozgás, E

## Ami előtt a játékos áll: [művelet, felirat] vagy [].
func _focus() -> Array:
	if not is_instance_valid(_player) or _busy:
		return []
	var at: Vector2 = _player.global_position
	match _where:
		"outside":
			if at.distance_to(door_position()) < INTERACT_RANGE:
				return ["enter", "[E] Le a kriptába"]
			if not _nearest_tablet().is_empty():
				return ["read", "[E] Sírfelirat elolvasása"]
		"crypt":
			if at.distance_to(_center(EXIT_TILE)) < INTERACT_RANGE:
				return ["leave", "[E] Fel a temetőbe"]
			if at.distance_to(_orsolya.position) < TALK_RANGE:
				return ["talk", "[E] Beszélgetés: %s" % SHORT_NAME]
			if at.distance_to(_altar_at()) < TALK_RANGE + 10 or at.distance_to(_circle_at()) < CIRCLE_RADIUS * 0.6:
				return ["ritual", "[E] Rituálé az oltárnál"]
	return []


func _nearest_tablet() -> Dictionary:
	var best := {}
	var best_distance := READ_RANGE
	for tablet in _tablets:
		var distance := _player.global_position.distance_to(tablet["position"])
		if distance < best_distance:
			best_distance = distance
			best = tablet
	return best


func _process(delta: float) -> void:
	_t += delta
	# Az Arctalanok alig észrevehetően ringanak, és a közelükbe érő játékos felé fordulnak.
	if _where == "crypt" and is_instance_valid(_player):
		for i in _hooded.size():
			var figure := _hooded[i]
			figure.position.y = -24 + sin(_t * 0.9 + i * 1.7) * 1.2
			if figure.global_position.distance_to(_player.global_position) < 110:
				figure.flip_h = _player.global_position.x < figure.global_position.x
	var focus := _focus()
	if not focus.is_empty():
		_prompt.text = focus[1]
	var target := 1.0 if not focus.is_empty() and not GamePause.active(get_tree()) else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or GamePause.active(get_tree()):
		return
	var focus := _focus()
	if focus.is_empty():
		return
	get_viewport().set_input_as_handled()
	var menus := _camp.get_node("Menus")
	match focus[0]:
		"enter":
			_move("crypt", _center(EXIT_TILE) + Vector2(0, -TILE))
		"leave":
			_move("outside", door_position() + Vector2(0, 26))
		"read":
			Audio.play("ui_open")
			var tablet := _nearest_tablet()
			_panel.show_text(tablet["title"], tablet["text"])
			menus.call("open_menu", _panel)
		"talk":
			Audio.play("ui_open")
			_dialogue.greeting = greeting()
			menus.call("open_menu", _dialogue)
		"ritual":
			_open_ritual()


func _move(where: String, at: Vector2) -> void:
	_busy = true
	_where = where
	Audio.play("footstep", -2.0)
	var inside := where != "outside"
	var r := INTERIOR
	var limits := Rect2(Vector2(r.position - Vector2i(3, 4)) * TILE, Vector2(r.size + Vector2i(6, 8)) * TILE) \
		if inside else Rect2()
	_camp.call("teleport_player", at, limits, INSIDE_LIGHT if inside else Color.BLACK)
	await get_tree().create_timer(0.6).timeout
	_busy = false


# ---------------------------------------------------------------- segédek

func _center(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE


func _rpg(coords: Vector2i, at: Vector2, z: int, parent: Node = null) -> Sprite2D:
	return _region_sprite(RPG, Rect2(Vector2(coords) * 17.0, Vector2(16, 16)), at, z, parent)


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


## Tereptárgy a talppontjánál (y szerint rendeződik), szilárd talppal.
func _prop(texture: Texture2D, at: Vector2, scale_by: Vector2, foot: Vector2) -> void:
	var holder := Node2D.new()
	holder.position = at
	_entities.add_child(holder)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = scale_by
	sprite.position = Vector2(0, -texture.get_height() * scale_by.y / 2.0 + 4)
	sprite.modulate = Color(0.85, 0.82, 0.88)
	holder.add_child(sprite)
	_body(holder, Vector2(0, -foot.y / 2.0), foot)


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


func _rect(rect: Rect2, z: int, color: Color) -> void:
	var box := ColorRect.new()
	box.color = color
	box.position = rect.position
	box.size = rect.size
	box.z_index = z
	add_child(box)


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


## Izzó kör a padlón: két gyűrű, köztük rúnajelek, lassan lüktet; a rituálékor a kő színében felvillan.
class RitualCircle:
	extends Node2D
	var radius := 70.0
	var _t := 0.0
	var _flash := 0.0
	var _flash_color := Color.WHITE

	func flash(color: Color) -> void:
		_flash = 1.0
		_flash_color = color

	func _process(delta: float) -> void:
		_t += delta
		_flash = maxf(0.0, _flash - delta * 0.6)
		queue_redraw()

	func _draw() -> void:
		var glow := 0.35 + 0.15 * sin(_t * 1.6)
		var color := Color(0.62, 0.35, 0.95, glow).lerp(Color(_flash_color, 0.95), _flash)
		var squash := Vector2(1.0, 0.55)
		_ring(radius, color, 2.0, squash)
		_ring(radius - 12.0, color, 1.5, squash)
		_ring(radius * 0.35, Color(color, color.a * 0.7), 1.5, squash)
		# Rúnák a két gyűrű között (forog egy kicsit).
		for i in 12:
			var angle := TAU * i / 12.0 + _t * 0.05
			var at := Vector2.from_angle(angle) * (radius - 6.0) * squash
			var tangent := Vector2.from_angle(angle + PI / 2.0) * squash
			draw_line(at - tangent * 3.0, at + tangent * 3.0, color, 2.0)
			draw_line(at, at + Vector2.from_angle(angle) * squash * 3.0, color, 1.5)
		# Pentagramszerű csillag a közepén.
		var points := PackedVector2Array()
		for i in 5:
			points.append(Vector2.from_angle(-PI / 2.0 + TAU * (i * 2 % 5) / 5.0) * (radius - 12.0) * squash)
		points.append(points[0])
		draw_polyline(points, Color(color, color.a * 0.8), 1.5)

	func _ring(r: float, color: Color, width: float, squash: Vector2) -> void:
		var points := PackedVector2Array()
		for i in 49:
			points.append(Vector2.from_angle(TAU * i / 48.0) * r * squash)
		draw_polyline(points, color, width)
