class_name Town
extends Node2D
## A város a tábortól keletre, az erdőn át vezető út végén (egyelőre egy épülettel):
## az út fölött a Mélységi kocsma. Az ajtajánál E-re bemész: a belső tér messze a
## pályától van (mint a bolt a kazamatában), 10 asztallal, asztalonként 2 székkel,
## a bejárattal szemben a pult a kocsmárossal, az asztalokon korsók és borosüvegek.
## A székeken ülnek a játszható karakterek (aki épp nem az aktív): odamész, E-t
## nyomsz, feláll és átveszed az irányítást, a mostani karaktered a saját helyére ül.
## A kocsmárossal (Tóbiás) beszélgetni lehet (munka = küldetések, történetek, a kiadó szobák). A hátsó falon,
## a sarokban ajtó: mögötte a szobák folyosója, fent sorban az öt szoba ajtaja (kopogni lehet; a négyes kiadó).
## A négyest a kocsmárostól kibérelheted (ROOM_PRICE tábori arany, egyszer): belül ágy (alvás után a következő
## futást REST_POTIONS HP-bájitallal kezded), láda (a tábori ládád), trófeafal a legyőzött főellenségekkel.
## (A tábor építi fel: setup(camp), a csempe-segédeit is a tábor adja.)

signal message(text: String)

const TILE := 32
const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const INDOOR: Texture2D = preload("res://assets/shop/kenney_indoor.png")
const CONTAINERS: Texture2D = preload("res://assets/shop/barrels_and_boxes.png")
const TORCH := preload("res://rooms/decor/torch.tscn")

## A város tisztása (csempékben); az út ROAD_ROW-ban jön be nyugatról, és egyenesen átmegy rajta.
## Keleten (OLD_END_X-től) a bővítés: egyelőre üres rét, ide jöhetnek az új házak.
const RECT := Rect2i(60, 4, 68, 26)
const OLD_END_X := 94
## A kocsma épülete (bal felső csempe, méret), az ajtó a legalsó sor közepén (2 széles).
const TAVERN_TOP_LEFT := Vector2i(66, 10)
const TAVERN_SIZE := Vector2i(9, 5)
const DOOR_COLUMN := 69
## A kocsma belseje (messze mindentől): padló csempékben, a bejárat a déli fal közepén.
const INTERIOR := Rect2i(200, 0, 20, 15)
const INTERIOR_DOOR := Vector2i(209, 14)
## Belső tér: meleg, gyertyafényes.
const INTERIOR_LIGHT := Color(0.62, 0.52, 0.44)
const INTERACT_RANGE := 52.0
# Kenney RPG lap (oszlop, sor)
const ROOF_TOP := [Vector2i(34, 21), Vector2i(39, 21), Vector2i(35, 21)]
const ROOF_MID := [Vector2i(38, 22), Vector2i(39, 22), Vector2i(40, 22)]
const ROOF_LOW := [Vector2i(38, 23), Vector2i(39, 23), Vector2i(40, 23)]
const WALL_BAND := Vector2i(34, 16)
const WALL_BOARDS := Vector2i(34, 17)
const WINDOW := Vector2i(40, 0)
const DOUBLE_DOOR := [Vector2i(28, 6), Vector2i(29, 6)]
const ROOF_TINT := Color(0.78, 0.52, 0.42)
const FLOOR_TILES: Array[Vector2i] = [Vector2i(8, 2), Vector2i(8, 3)]
const FLOOR_TINT := Color(0.66, 0.5, 0.42)
const TABLE := Vector2i(19, 6)
## Oldalra néző székek (a bal oldali jobbra néz, a jobb oldali balra).
const CHAIR_FACING_RIGHT := Vector2i(21, 4)
const CHAIR_FACING_LEFT := Vector2i(22, 4)
const DRINKS: Array[Vector2i] = [Vector2i(55, 14), Vector2i(55, 11), Vector2i(54, 14), Vector2i(54, 11), Vector2i(56, 11)]
const CANDLE := Vector2i(19, 7)
const FIREPLACE := [Vector2i(54, 8), Vector2i(55, 8)]
const SHELF_COLUMNS := [43, 44, 45, 46, 47, 48, 49, 50]
## A kocsmáros (0x72 törpenő): Tóbiás. E-re beszélgetés: munka (a küldetések ablaka), történetek, a szobák.
const BARKEEP := Rect2(128, 260, 16, 28)
const BARKEEP_ID := "barkeep"
const BARKEEP_NAME := "Tóbiás, a kocsmáros"
const BARKEEP_GREETING := "[i]A törpe kocsmáros egy korsót törölget, és fel sem néz.[/i]\n\n" \
	+ "Üdv a Mélységi kocsmában! Sör, bor, mesék, szállás. Ha munkát keresel, nálam kezdd. Ha ágyat, " \
	+ "hátul, a sarokban lévő ajtón túl vannak a szobák."
const BARKEEP_STORIES: Array[Dictionary] = [
	{"id": "history", "text": "Mióta van ez a kocsma?", "trust": 3,
		"answer": "[i]Végigsimít a pulton, ami tele van bevésett nevekkel.[/i]\n\n" \
			+ "A nagyapám építette, amikor még ezüstöt bányásztak a hegyben. Ezüstcsákány volt a neve, " \
			+ "bányászkocsma: minden asztalnál egy brigád ült, és a pultba vésték annak a nevét, aki már nem jött " \
			+ "fel a tárnából.\n\nAztán a bánya beomlott, alattunk megnyílt a Mélység, és a bányászok helyett " \
			+ "jöttek a kalandorok. Átfestettem a cégért. A nevek a pultban maradtak, és most már a kalandoroké is " \
			+ "ott van mellettük."},
	{"id": "mimic", "text": "Mi volt a legfurcsább, ami itt történt?", "trust": 3,
		"answer": "[i]Felnevet, és a pult alatt heverő seprűre bök.[/i]\n\n" \
			+ "Egyszer egy kalandor felhozott egy szép, vasalt ládát, és egy hordó sörért akarta odaadni. Mire " \
			+ "kinyitottuk, a láda megette a fél pultot, két széket és a kalandor bal csizmáját. Mimik volt.\n\n" \
			+ "Azóta minden ládát, amit idehoznak, előbb megbökök ezzel a seprűvel. A kalandor egyébként azóta is " \
			+ "fél csizmában jár. Azt mondja, szerencsét hoz."},
	{"id": "toast", "text": "Kinek szól a teli korsó a pult végén?", "trust": 4,
		"answer": "[i]Elkomolyodik, és a pult végén álló korsóra néz.[/i]\n\n" \
			+ "Azoknak, akik lementek, és nem jöttek vissza. Minden este töltök egyet, a legjobbat a hordóból.\n\n" \
			+ "Reggelre mindig üres. Senki nem látta, ki issza meg, és én nem kérdezem. Ha egyszer nem lesz " \
			+ "üres... akkor talán már nincs odalent senki, aki szomjas."},
	{"id": "rooms", "text": "Kik laknak a hátsó szobákban?", "trust": 2,
		"answer": "[i]A hüvelykujjával a háta mögé, a sarokban lévő ajtóra bök.[/i]\n\n" \
			+ "Hátul, a folyosón öt szoba van, azokat adom ki. Az egyesben egy vándorlantos lakik, aki fizetés " \
			+ "helyett esténként játszik. A kettesben Puskás Döme, a robbantómester: ha horkolást hallasz és " \
			+ "puskaporszagot érzel, az az ő ajtaja. A hármasban egy öregasszony, akit még sosem láttam kijönni. " \
			+ "Az ötösben két testvér, akik minden reggel megesküsznek, hogy ma lemennek a Mélységbe.\n\n" \
			+ "A négyes még kiadó. Ha egyszer eleged lesz a sátorból, szólj."},
]
## A hátsó ajtó a hátsó fal jobb sarkában (a kandalló és az oldalfal között): mögötte a szobák folyosója.
const BACK_DOOR := Vector2i(218, 0)
const DOOR_TILE := Vector2i(33, 1)
## A szobák folyosója (messze mindentől): a padló 3 sor, fölötte a fal az öt szoba ajtajával, a déli falon
## (jobbra) az ajtó vissza a kocsmába.
const CORRIDOR := Rect2i(200, 30, 24, 3)
const CORRIDOR_DOOR := Vector2i(221, 33)
const CORRIDOR_LIGHT := Color(0.46, 0.38, 0.34)
const ROOM_DOOR_COLUMNS: Array[int] = [202, 206, 210, 214, 218]
## A szobák (balról jobbra): mi történik, ha kopogsz. A négyes kiadó (cetli az ajtón).
const ROOMS: Array[Dictionary] = [
	{"knock": "Halk lantszó szűrődik ki. Amikor kopogsz, abbamarad, aztán valaki dúdolni kezd: "
		+ "„Foglalt, foglalt, foglalt a szoba...” Senki nem nyit ajtót."},
	{"knock": "Bentről hangos horkolás hallatszik, és az ajtó alól puskaporszag szivárog. Itt alszik "
		+ "Puskás Döme, a robbantómester. Hiába kopogsz, fel sem ébred."},
	{"knock": "Csend. Aztán az ajtó mögül egy rekedt hang: „Nem veszek semmit!” A kulcslyukon át egy szem figyel."},
	{"vacant": true, "knock": "Az ajtón cetli: „KIADÓ — érdeklődni a pultnál.” A kilincs nem enged: "
		+ "a kulcs a kocsmárosnál van."},
	{"knock": "Két hang vitatkozik bent arról, ki megy le holnap elsőnek a Mélységbe. Mindketten azt mondják, "
		+ "hogy a másik. Észre sem veszik, hogy kopogtál."},
]
## A kiadó szoba (ROOMS indexe), ára, és a te szobád belseje (messze mindentől; a déli falon az ajtó).
const VACANT_ROOM := 3
const ROOM_PRICE := 500
const ROOM_FLAG := "tavern_room"
## Alvás után a következő futás elején (Camp) ennyi HP-bájitallal több (egyszer).
const RESTED_FLAG := "tavern_rested"
const REST_POTIONS := 1
const MY_ROOM := Rect2i(200, 40, 11, 4)
const MY_ROOM_DOOR := Vector2i(205, 44)
const MY_ROOM_LIGHT := Color(0.5, 0.42, 0.38)
## Kenney belső lap: franciaágy (két csempe, a fejtámla jobbra); 0x72: láda.
const BED: Array[Vector2i] = [Vector2i(12, 0), Vector2i(12, 1)]
const BED_TILE := Vector2i(209, 41)
const CHEST := Rect2(304, 416, 16, 16)
const CHEST_TILE := Vector2i(201, 41)

## A székek helye (világ-koordináta) és iránya: [pozíció, jobbra néz-e]. A karakterek
## a Characters.ALL "seat" indexe szerinti széken ülnek.
var seats: Array = []

var _camp: Node2D
var _player: Node2D
var _entities: Node2D
var _seated := {}
var _prompt: Label
var _inside := false
var _in_corridor := false
var _dialogue: DialoguePanel
## Puskás Döme (lásd Blaster): első kopogásra kijön, és a kettes szoba ajtaja előtt áll, amíg a bányába nem megy.
var _dome: AnimatedSprite2D
var _dome_dialogue: DialoguePanel
var _in_room := false
## A "KIADÓ" cetli a négyes ajtaján (a bérlés után eltűnik).
var _vacant_note: Array[CanvasItem] = []
var _busy := false
var _quest_panel: CanvasLayer
var _quest_mark: Label

const QUEST_PANEL := preload("res://ui/quest_panel.gd")
var _intro: PanelContainer
var _intro_title: PanelContainer
var _intro_portrait: TextureRect
var _intro_role: Label
var _intro_text: RichTextLabel
var _intro_for := ""


func setup(camp: Node2D) -> void:
	_camp = camp
	_entities = camp.get_node("Entities")
	_player = camp.get_node("Entities/Player")
	_quest_panel = QUEST_PANEL.new()
	_quest_panel.name = "QuestPanel"
	camp.add_child.call_deferred(_quest_panel)
	_dialogue = DialoguePanel.new()
	_dialogue.name = "BarkeepDialogue"
	_dialogue.npc_id = BARKEEP_ID
	_dialogue.npc_name = BARKEEP_NAME
	_dialogue.portrait = SpriteSheet.region(BARKEEP)
	_dialogue.greeting = BARKEEP_GREETING
	_dialogue.options_provider = func() -> Array[Dictionary]:
		var list: Array[Dictionary] = [{"id": "work", "text": "Van munkád számomra? (küldetések)",
			"on_choose": _open_quests}]
		if not room_rented():
			list.append({"id": "rent", "text": "Kivenném a négyes szobát (%d arany)." % ROOM_PRICE,
				"on_choose": _rent_room})
		list.append_array(BARKEEP_STORIES)
		return list
	camp.add_child.call_deferred(_dialogue)
	_dome_dialogue = DialoguePanel.new()
	_dome_dialogue.name = "BlasterDialogue"
	_dome_dialogue.npc_id = Blaster.ID
	_dome_dialogue.npc_name = Blaster.NAME
	_dome_dialogue.portrait = Blaster.portrait()
	_dome_dialogue.options_provider = func() -> Array[Dictionary]: return Blaster.options("room")
	camp.add_child.call_deferred(_dome_dialogue)


## A kocsma ajtaja előtti földút (a tábor rajzolja ki a többi földdel együtt).
static func path_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var bottom := TAVERN_TOP_LEFT.y + TAVERN_SIZE.y
	for y in range(bottom, 17):
		for x in [DOOR_COLUMN, DOOR_COLUMN + 1]:
			tiles.append(Vector2i(x, y))
	return tiles


## Ide nem kerülhet fa / bokor (az épület és körülötte).
static func blocked_rect() -> Rect2i:
	return Rect2i(TAVERN_TOP_LEFT - Vector2i(2, 2), TAVERN_SIZE + Vector2i(4, 4))


func build() -> void:
	_build_exterior()
	_build_interior()
	_build_ui()
	_build_intro()
	_seat_characters()


# ---------------------------------------------------------------- külső

func _build_exterior() -> void:
	var tl := TAVERN_TOP_LEFT
	var w := TAVERN_SIZE.x
	for x in w:
		var piece := 0 if x == 0 else (2 if x == w - 1 else 1)
		_tile(ROOF_TOP[piece], tl + Vector2i(x, 0), -6).modulate = ROOF_TINT
		_tile(ROOF_MID[piece], tl + Vector2i(x, 1), -6).modulate = ROOF_TINT
		_tile(ROOF_LOW[piece], tl + Vector2i(x, 2), -6).modulate = ROOF_TINT
		# Falak: felül deszkasáv ablakokkal, alul függőleges deszkák az ajtóval.
		_tile(WALL_BAND, tl + Vector2i(x, 3), -6)
		_tile(WALL_BOARDS, tl + Vector2i(x, 4), -6)
		if x == 2 or x == w - 3:
			_tile(WINDOW, tl + Vector2i(x, 3), -5)
	for i in 2:
		_tile(DOUBLE_DOOR[i], Vector2i(DOOR_COLUMN + i, tl.y + 4), -5)
	# Az épület szilárd (az ajtó előtt lehet megállni).
	_solid(Rect2(Vector2(tl) * TILE, Vector2(TAVERN_SIZE) * TILE - Vector2(0, 6)))
	# Cégér az ajtó fölött, két fáklya a falon.
	var sign_label := MenuStyle.title_label("Mélységi kocsma", 26, MenuStyle.GOLD)
	sign_label.size = Vector2(300, 34)
	sign_label.position = Vector2(DOOR_COLUMN + 1, tl.y + 2) * TILE + Vector2(-150, 8)
	sign_label.z_index = 2
	add_child(sign_label)
	for x in [1, w - 2]:
		var torch: Node2D = TORCH.instantiate()
		torch.position = _center(tl + Vector2i(x, 4)) + Vector2(0, -16)
		add_child(torch)
	# Hordók a fal mellett.
	_prop(CONTAINERS, Rect2(0, 0, 16, 16), _center(tl + Vector2i(w, 4)) + Vector2(4, 8))
	_prop(CONTAINERS, Rect2(0, 0, 16, 16), _center(tl + Vector2i(w, 4)) + Vector2(26, 12))
	_prop(CONTAINERS, Rect2(16, 0, 16, 16), _center(tl + Vector2i(-1, 4)) + Vector2(-4, 10))


func door_position() -> Vector2:
	return Vector2(DOOR_COLUMN + 1, TAVERN_TOP_LEFT.y + TAVERN_SIZE.y) * TILE + Vector2(0, 16)


# ---------------------------------------------------------------- belső

func _build_interior() -> void:
	var r := INTERIOR
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			_tile(FLOOR_TILES[(x + y) % 2], Vector2i(x, y), -10).modulate = FLOOR_TINT
	# Hátsó fal: italos polcok, középen a kandalló.
	for x in range(r.position.x, r.end.x):
		var col: int = SHELF_COLUMNS[(x - r.position.x) % SHELF_COLUMNS.size()]
		_tile(Vector2i(col, 14), Vector2i(x, r.position.y), -9)
		_tile(Vector2i(col, 12), Vector2i(x, r.position.y - 1), -9)
	for i in 2:
		_tile(FIREPLACE[i], Vector2i(r.position.x + 2 + i, r.position.y), -8)
		_tile(FIREPLACE[i], Vector2i(r.end.x - 4 + i, r.position.y), -8)
	_light(_center(Vector2i(r.position.x + 3, r.position.y)), Color(1, 0.6, 0.3), 2.2, 1.3)
	_light(_center(Vector2i(r.end.x - 3, r.position.y)), Color(1, 0.6, 0.3), 2.2, 1.3)
	# Oldalfalak és a déli fal (sötét gerendák), a bejárat a déli fal közepén.
	_wall_rect(Rect2(Vector2(r.position.x - 1, r.position.y - 1) * TILE, Vector2(TILE, (r.size.y + 2) * TILE)))
	_wall_rect(Rect2(Vector2(r.end.x, r.position.y - 1) * TILE, Vector2(TILE, (r.size.y + 2) * TILE)))
	_wall_rect(Rect2(Vector2(r.position.x, r.end.y) * TILE, Vector2((INTERIOR_DOOR.x - r.position.x) * TILE, TILE)))
	_wall_rect(Rect2(Vector2(INTERIOR_DOOR.x + 2, r.end.y) * TILE, Vector2((r.end.x - INTERIOR_DOOR.x - 2) * TILE, TILE)))
	_solid(Rect2(Vector2(r.position.x, r.position.y - 1) * TILE, Vector2(r.size.x * TILE, TILE * 1.6)))
	for i in 2:
		_tile(DOUBLE_DOOR[i], Vector2i(INTERIOR_DOOR.x + i, r.end.y), -8)
	_solid(Rect2(Vector2(INTERIOR_DOOR.x, r.end.y + 1) * TILE, Vector2(2 * TILE, TILE)))
	# A hátsó ajtó a polcok között (a felső polcsorban egy kis tábla).
	_tile(DOOR_TILE, BACK_DOOR, -7)
	var rooms_sign := UiStyle.label("Szobák", 13, Color(0.95, 0.85, 0.6), true)
	rooms_sign.size = Vector2(TILE * 2, 16)
	rooms_sign.position = Vector2(BACK_DOOR + Vector2i.UP) * TILE + Vector2(-TILE / 2.0, 10)
	rooms_sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rooms_sign.z_index = -6
	add_child(rooms_sign)
	_build_bar()
	_build_tables()
	_build_corridor()
	_build_my_room()


## A pult a bejárattal szemben (a hátsó fal előtt), mögötte a kocsmáros.
func _build_bar() -> void:
	var y := INTERIOR.position.y + 3
	var x0 := INTERIOR_DOOR.x - 4
	var pieces := [Rect2(4 * 17, 7 * 17, 16, 16)]
	for i in 8:
		pieces.append(Rect2((5 + i % 2) * 17, 7 * 17, 16, 16))
	pieces.append(Rect2(7 * 17, 7 * 17, 16, 16))
	for i in pieces.size():
		var piece := _sprite(INDOOR, pieces[i], _center(Vector2i(x0 + i, y)), 0, _entities)
		# Korsók a pulton (a pult végén az, amit a kocsmáros minden este a lent maradtaknak tölt).
		if i in [1, 4, 7, 9]:
			_on_table(piece, DRINKS[i % DRINKS.size()], Vector2(0, -6), 0.8)
	_solid(Rect2(Vector2(x0, y) * TILE, Vector2(pieces.size() * TILE, TILE)))
	var barkeep := AnimatedSprite2D.new()
	barkeep.sprite_frames = SpriteSheet.character_frames(BARKEEP, true)
	barkeep.scale = Vector2(2, 2)
	barkeep.offset.y = -BARKEEP.size.y / 2.0
	barkeep.position = _center(Vector2i(INTERIOR_DOOR.x, y - 1)) + Vector2(16, 12)
	barkeep.play("idle")
	_entities.add_child(barkeep)
	set_meta("barkeep_position", barkeep.position + Vector2(0, 2 * TILE))
	# Jel a kocsmáros fölött: "!" ha vehetsz fel küldetést, "?" ha leadhatod a kész küldetést.
	_quest_mark = MenuStyle.title_label("!", 40, MenuStyle.GOLD)
	_quest_mark.size = Vector2(40, 46)
	_quest_mark.position = barkeep.position + Vector2(-20, -84)
	_quest_mark.z_index = 20
	add_child(_quest_mark)
	var bob := _quest_mark.create_tween().set_loops()
	bob.tween_property(_quest_mark, "position:y", _quest_mark.position.y - 6, 0.6).set_trans(Tween.TRANS_SINE)
	bob.tween_property(_quest_mark, "position:y", _quest_mark.position.y, 0.6).set_trans(Tween.TRANS_SINE)


## 10 asztal, mindegyiknél 2 szék (balra és jobbra), az asztalokon italok és gyertyák.
## A középső folyosó szabadon marad a bejárattól a pultig.
func _build_tables() -> void:
	var columns := [INTERIOR.position.x + 3, INTERIOR.position.x + 7, INTERIOR.end.x - 8, INTERIOR.end.x - 4]
	var rows := [INTERIOR.position.y + 6, INTERIOR.position.y + 9, INTERIOR.position.y + 12]
	var tables: Array[Vector2i] = []
	for row in rows.slice(0, 2):
		for col in columns:
			tables.append(Vector2i(col, row))
	tables.append(Vector2i(columns[0], rows[2]))
	tables.append(Vector2i(columns[3], rows[2]))
	for t in tables:
		# Az asztal (és a székek) a y-szerint rendezett rétegbe kerülnek, hogy a játékos
		# előttük és mögöttük is helyesen látsszon; az italok és a gyertya az asztal "gyerekei".
		var table := _tile(TABLE, t, 0, _entities)
		_solid(Rect2(Vector2(t) * TILE + Vector2(4, 8), Vector2(TILE - 8, TILE - 12)))
		_on_table(table, DRINKS.pick_random(), Vector2(-3, -6), 0.7)
		if randf() < 0.6:
			_on_table(table, DRINKS.pick_random(), Vector2(4, -5), 0.7)
		_on_table(table, CANDLE, Vector2(0, -8), 0.6)
		_light(_center(t) + Vector2(0, -16), Color(1, 0.75, 0.45), 0.9, 0.7)
		for side in [-1, 1]:
			var chair_tile := t + Vector2i(side, 0)
			var chair := _tile(CHAIR_FACING_RIGHT if side < 0 else CHAIR_FACING_LEFT, chair_tile, 0, _entities)
			chair.position.y -= 2
			seats.append([_center(chair_tile), side < 0])


## Egy tárgy (ital, gyertya) az asztal lapján, az asztal sprite-jához képest (az asztal 2x-es).
func _on_table(table: Sprite2D, coords: Vector2i, offset: Vector2, scale_factor: float) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = RPG
	atlas.region = Rect2(Vector2(coords) * 17.0, Vector2(16, 16))
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.position = offset
	sprite.scale = Vector2.ONE * scale_factor
	table.add_child(sprite)


## A szobák folyosója: deszkapadló hosszú futószőnyeggel, fent deszkafal az öt szoba ajtajával (fölöttük
## sárgaréz számtábla, a négyesen "KIADÓ" cetli), köztük fali fáklyák; jobbra lent az ajtó vissza a kocsmába.
func _build_corridor() -> void:
	var r := CORRIDOR
	var top := r.position.y - 2
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			_tile(FLOOR_TILES[(x + y) % 2], Vector2i(x, y), -10).modulate = FLOOR_TINT.darkened(0.1)
		_tile(WALL_BAND, Vector2i(x, top), -9).modulate = Color(0.8, 0.68, 0.58)
		_tile(WALL_BOARDS, Vector2i(x, top + 1), -9).modulate = Color(0.8, 0.68, 0.58)
	# Fölötte és körben sötét (a kamera szélén se látsszon a semmi).
	var dark := ColorRect.new()
	dark.color = Color(0.06, 0.04, 0.04)
	dark.position = Vector2(r.position - Vector2i(2, 6)) * TILE
	dark.size = Vector2(r.size + Vector2i(4, 4)) * TILE
	dark.z_index = -11
	add_child(dark)
	# Futószőnyeg a folyosó közepén (vörös, arany szegéllyel).
	var runner := ColorRect.new()
	runner.color = Color(0.45, 0.12, 0.1)
	runner.position = Vector2(r.position.x + 0.5, r.position.y + 1.2) * TILE
	runner.size = Vector2(r.size.x - 1, 0.6) * TILE
	runner.z_index = -9
	add_child(runner)
	for edge in [0.0, runner.size.y - 3.0]:
		var trim := ColorRect.new()
		trim.color = Color(0.78, 0.6, 0.26)
		trim.position = runner.position + Vector2(0, edge)
		trim.size = Vector2(runner.size.x, 3)
		trim.z_index = -9
		add_child(trim)
	for i in ROOM_DOOR_COLUMNS.size():
		var column := ROOM_DOOR_COLUMNS[i]
		_tile(DOOR_TILE, Vector2i(column, top + 1), -8)
		var plate := ColorRect.new()
		plate.color = Color(0.75, 0.58, 0.22)
		plate.size = Vector2(14, 12)
		plate.position = _center(Vector2i(column, top)) + Vector2(-7, 4)
		plate.z_index = -7
		add_child(plate)
		var number := UiStyle.label(str(i + 1), 11, Color(0.2, 0.12, 0.05))
		number.size = plate.size
		number.position = plate.position + Vector2(0, -2)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.z_index = -6
		add_child(number)
		if ROOMS[i].get("vacant", false):
			var note := ColorRect.new()
			_vacant_note.append(note)
			note.color = Color(0.92, 0.88, 0.76)
			note.size = Vector2(36, 14)
			note.position = _center(Vector2i(column, top + 1)) + Vector2(-18, -6)
			note.rotation = deg_to_rad(-4)
			note.z_index = -7
			add_child(note)
			var vacant := UiStyle.label("KIADÓ", 9, Color(0.5, 0.1, 0.08))
			vacant.size = note.size
			vacant.position = note.position + Vector2(0, 1)
			vacant.rotation = note.rotation
			vacant.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vacant.z_index = -6
			add_child(vacant)
			_vacant_note.append(vacant)
			for node in _vacant_note:
				node.visible = not room_rented()
		# Fali fáklya a két ajtó között.
		if i < ROOM_DOOR_COLUMNS.size() - 1:
			var torch: Node2D = TORCH.instantiate()
			torch.position = _center(Vector2i(column + 2, top)) + Vector2(0, 6)
			add_child(torch)
	# Puskás Döme: a kettes szoba ajtaja mellett áll, ha már felébresztetted (és még nem ment a bányába).
	_dome = AnimatedSprite2D.new()
	_dome.sprite_frames = Blaster.frames()
	_dome.scale = Vector2(2, 2)
	_dome.offset.y = -Blaster.FIGURE.size.y / 2.0
	_dome.position = Vector2(ROOM_DOOR_COLUMNS[Blaster.ROOM] + 1.3, r.position.y + 0.75) * TILE
	_dome.play("idle")
	_dome.visible = false
	_entities.add_child(_dome)
	# Az ajtó vissza a kocsmába (a déli falon), két cserepes növény és egy szék a fal mellett.
	_tile(DOOR_TILE, CORRIDOR_DOOR, -8).modulate = Color(0.85, 0.78, 0.72)
	_sprite(INDOOR, Rect2(16 * 17, 0, 16, 16), _center(Vector2i(r.position.x, r.position.y)) + Vector2(0, -6), 0, _entities)
	_sprite(INDOOR, Rect2(17 * 17, 0, 16, 16), _center(Vector2i(r.end.x - 1, r.position.y)) + Vector2(0, -6), 0, _entities)
	_tile(CHAIR_FACING_RIGHT, Vector2i(r.position.x + 1, r.end.y - 1), 0, _entities)
	# Falak: fent a deszkafal, alul a déli fal (az ajtó kivételével), oldalt a két vég.
	_solid(Rect2(Vector2(r.position.x, top) * TILE, Vector2(r.size.x * TILE, TILE * 1.6)))
	_wall_rect(Rect2(Vector2(r.position.x, r.end.y) * TILE, Vector2((CORRIDOR_DOOR.x - r.position.x) * TILE, TILE)))
	_wall_rect(Rect2(Vector2(CORRIDOR_DOOR.x + 1, r.end.y) * TILE, Vector2((r.end.x - CORRIDOR_DOOR.x - 1) * TILE, TILE)))
	_solid(Rect2(Vector2(CORRIDOR_DOOR.x, r.end.y + 1) * TILE, Vector2(TILE, TILE)))
	_wall_rect(Rect2(Vector2(r.position.x - 1, top) * TILE, Vector2(TILE, (r.size.y + 3) * TILE)))
	_wall_rect(Rect2(Vector2(r.end.x, top) * TILE, Vector2(TILE, (r.size.y + 3) * TILE)))


## A te szobád (a kibérelt négyes): deszkapadló szőnyeggel, fent a trófeafal (a legyőzött főellenségek képe
## keretben, a még le nem győzötteké sötét árnyék), jobbra az ágy, balra a láda, középen asztal gyertyával.
func _build_my_room() -> void:
	var r := MY_ROOM
	var top := r.position.y - 2
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			_tile(FLOOR_TILES[(x + y) % 2], Vector2i(x, y), -10).modulate = FLOOR_TINT
		_tile(WALL_BAND, Vector2i(x, top), -9).modulate = Color(0.78, 0.66, 0.56)
		_tile(WALL_BOARDS, Vector2i(x, top + 1), -9).modulate = Color(0.78, 0.66, 0.56)
	var dark := ColorRect.new()
	dark.color = Color(0.06, 0.04, 0.04)
	dark.position = Vector2(r.position - Vector2i(2, 6)) * TILE
	dark.size = Vector2(r.size + Vector2i(4, 10)) * TILE
	dark.z_index = -11
	add_child(dark)
	var rug := ColorRect.new()
	rug.color = Color(0.32, 0.16, 0.28)
	rug.position = Vector2(r.position.x + 3.3, r.position.y + 1.2) * TILE
	rug.size = Vector2(4.4, 1.8) * TILE
	rug.z_index = -9
	add_child(rug)
	var rug_trim := ReferenceRect.new()
	rug_trim.border_color = Color(0.78, 0.6, 0.26)
	rug_trim.border_width = 3.0
	rug_trim.editor_only = false
	rug_trim.position = rug.position + Vector2(4, 4)
	rug_trim.size = rug.size - Vector2(8, 8)
	rug_trim.z_index = -9
	add_child(rug_trim)
	# Trófeafal: keretek a felső falsávon.
	var bosses := trophies()
	var step := 24.0
	var start := r.position.x * TILE + (r.size.x * TILE - step * bosses.size()) / 2.0
	for i in bosses.size():
		var frame := ColorRect.new()
		frame.color = Color(0.36, 0.22, 0.1)
		frame.size = Vector2(23, 23)
		frame.position = Vector2(start + i * step, top * TILE + 10)
		frame.z_index = -7
		add_child(frame)
		var inner := ColorRect.new()
		inner.color = Color(0.16, 0.12, 0.1)
		inner.size = Vector2(19, 19)
		inner.position = frame.position + Vector2(2, 2)
		inner.z_index = -7
		add_child(inner)
		var icon: Array = Bestiary.icon(bosses[i])
		var picture := Sprite2D.new()
		picture.texture = icon[0]
		var biggest := maxf(picture.texture.get_size().x, picture.texture.get_size().y)
		picture.scale = Vector2.ONE * 17.0 / biggest
		picture.position = frame.position + frame.size / 2.0
		picture.z_index = -6
		picture.modulate = icon[1] if Bestiary.kills(bosses[i]) > 0 else Color(0, 0, 0, 0.55)
		add_child(picture)
	# Ágy (jobbra, a fejtámla a falnál), láda (balra), asztal gyertyával és székkel.
	for i in BED.size():
		_sprite(INDOOR, Rect2(Vector2(BED[i]) * 17.0, Vector2(16, 16)), _center(BED_TILE + Vector2i(0, i)), -8)
	_solid(Rect2(Vector2(BED_TILE) * TILE + Vector2(2, 4), Vector2(TILE - 4, 2 * TILE - 8)))
	_sprite(SpriteSheet.TEXTURE, CHEST, _center(CHEST_TILE), 0, _entities)
	_solid(Rect2(Vector2(CHEST_TILE) * TILE + Vector2(4, 10), Vector2(TILE - 8, TILE - 14)))
	var table_tile := Vector2i(r.position.x + 2, r.end.y - 1)
	var table := _tile(TABLE, table_tile, 0, _entities)
	_solid(Rect2(Vector2(table_tile) * TILE + Vector2(4, 8), Vector2(TILE - 8, TILE - 12)))
	_on_table(table, CANDLE, Vector2(0, -8), 0.6)
	_light(_center(table_tile) + Vector2(0, -16), Color(1, 0.75, 0.45), 1.2, 0.8)
	_tile(CHAIR_FACING_LEFT, table_tile + Vector2i.RIGHT, 0, _entities).position.y -= 2
	_light(_center(BED_TILE), Color(1, 0.8, 0.55), 1.4, 0.6)
	var torch: Node2D = TORCH.instantiate()
	torch.position = _center(Vector2i(r.position.x + 1, top + 1)) + Vector2(0, -2)
	add_child(torch)
	# Falak és az ajtó (a déli falon).
	_tile(DOOR_TILE, MY_ROOM_DOOR, -8).modulate = Color(0.85, 0.78, 0.72)
	_solid(Rect2(Vector2(r.position.x, top) * TILE, Vector2(r.size.x * TILE, TILE * 1.6)))
	_wall_rect(Rect2(Vector2(r.position.x, r.end.y) * TILE, Vector2((MY_ROOM_DOOR.x - r.position.x) * TILE, TILE)))
	_wall_rect(Rect2(Vector2(MY_ROOM_DOOR.x + 1, r.end.y) * TILE, Vector2((r.end.x - MY_ROOM_DOOR.x - 1) * TILE, TILE)))
	_solid(Rect2(Vector2(MY_ROOM_DOOR.x, r.end.y + 1) * TILE, Vector2(TILE, TILE)))
	_wall_rect(Rect2(Vector2(r.position.x - 1, top) * TILE, Vector2(TILE, (r.size.y + 3) * TILE)))
	_wall_rect(Rect2(Vector2(r.end.x, top) * TILE, Vector2(TILE, (r.size.y + 3) * TILE)))


# ---------------------------------------------------------------- karakterek

## Minden nem aktív, már játszható karakter a saját székén ül (Gáspár csak a 30. emelet után).
func _seat_characters() -> void:
	for id: String in Characters.ALL:
		if id != Progress.character and Characters.is_unlocked(id):
			_sit(id)


## Gáspár beért a kocsmába (a táborból sétált ide): leül a helyére, és onnantól játszható.
func seat_gaspar() -> void:
	if _seated.has("veteran") or Progress.character == "veteran":
		return
	_sit("veteran")


func _sit(id: String) -> AnimatedSprite2D:
	var seat: Array = seats[int(Characters.data(id)["seat"]) % seats.size()]
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = Characters.frames(id)
	sprite.scale = Vector2(2, 2)
	sprite.offset = Vector2(0, -14)
	# Ülve: a szék fölött, az asztal felé fordulva.
	sprite.position = seat[0] + Vector2(0, 10)
	sprite.flip_h = not seat[1]
	sprite.play("idle")
	_entities.add_child(sprite)
	_seated[id] = sprite
	return sprite


## Karakterváltás: a kiválasztott feláll (őt irányítod), a mostani a helyére sétál és leül.
func _switch_to(id: String) -> void:
	if GameState.on_break:
		message.emit("Pihenő közben nem válthatsz karaktert.")
		Audio.play("ui_error")
		return
	_busy = true
	var old_id := Progress.character
	var new_sprite: AnimatedSprite2D = _seated[id]
	_seated.erase(id)
	var stand_at := new_sprite.position + Vector2(0, 26)
	new_sprite.queue_free()
	var old_position := _player.global_position
	_player.global_position = stand_at
	_player.call("set_character", id)
	Audio.play("equip")
	message.emit("Mostantól vele játszol: %s" % Characters.data(id)["name"])
	# A régi karakter a saját székéhez sétál, és leül.
	var walker := _sit(old_id)
	var seat_position := walker.position
	walker.position = old_position
	walker.play("run")
	walker.flip_h = seat_position.x < old_position.x
	var duration := clampf(old_position.distance_to(seat_position) / 130.0, 0.3, 3.0)
	var tween := create_tween()
	tween.tween_property(walker, "position", seat_position, duration)
	tween.tween_callback(func() -> void:
		var seat: Array = seats[int(Characters.data(old_id)["seat"]) % seats.size()]
		walker.flip_h = not seat[1]
		walker.play("idle")
		_busy = false)


## Csalás (CheatMenu): azonnali karakterváltás bárhol a táborban, a zárolt karakterekre is.
## A játékos helyben marad; a kiválasztott eltűnik a székéről, a régi (ha már játszható) leül.
func cheat_switch_to(id: String) -> bool:
	if GameState.on_break or _busy or not Characters.ALL.has(id):
		return false
	var old_id := Progress.character
	if id == old_id:
		return true
	if _seated.has(id):
		var sprite: AnimatedSprite2D = _seated[id]
		_seated.erase(id)
		sprite.queue_free()
	_player.call("set_character", id)
	if Characters.is_unlocked(old_id) and not _seated.has(old_id):
		_sit(old_id)
	Audio.play("equip")
	message.emit("Mostantól vele játszol: %s" % Characters.data(id)["name"])
	return true


# ---------------------------------------------------------------- belépés / kilépés, E

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


## Ami előtt a játékos áll: ["door" | "exit" | "barkeep" | karakter-id, felirat] vagy [].
func _focus() -> Array:
	if not is_instance_valid(_player) or _busy:
		return []
	var at: Vector2 = _player.global_position
	if _in_room:
		if at.distance_to(_center(MY_ROOM_DOOR + Vector2i.UP)) < INTERACT_RANGE:
			return ["room_exit", "[E] Vissza a folyosóra"]
		if at.distance_to(_center(BED_TILE) + Vector2(-TILE / 2.0, TILE / 2.0)) < INTERACT_RANGE + 10:
			return ["bed", "[E] Alvás"]
		if at.distance_to(_center(CHEST_TILE)) < INTERACT_RANGE:
			return ["chest", "[E] Láda (a tábori ládád)"]
		if at.y < (MY_ROOM.position.y + 1) * TILE:
			return ["trophies", "[E] Trófeafal"]
		return []
	if _in_corridor:
		if at.distance_to(_center(CORRIDOR_DOOR + Vector2i.UP)) < INTERACT_RANGE:
			return ["corridor_exit", "[E] Vissza a kocsmába"]
		if _dome.visible and at.distance_to(_dome.position) < INTERACT_RANGE:
			return ["dome", "[E] Beszélgetés: %s" % Blaster.NAME]
		for i in ROOM_DOOR_COLUMNS.size():
			# Döme ajtaja előtt maga Döme áll (lásd fent).
			if i == Blaster.ROOM and _dome.visible:
				continue
			if at.distance_to(_center(Vector2i(ROOM_DOOR_COLUMNS[i], CORRIDOR.position.y))) < INTERACT_RANGE:
				if i == VACANT_ROOM and room_rented():
					return ["my_room", "[E] %d. szoba: a te szobád" % (i + 1)]
				var vacant: bool = ROOMS[i].get("vacant", false)
				return ["room_%d" % i, "[E] %d. szoba%s" % [i + 1, " (kiadó)" if vacant else ": kopogás"]]
		return []
	if not _inside:
		if at.distance_to(door_position()) < INTERACT_RANGE:
			return ["door", "[E] Belépés: Mélységi kocsma"]
		return []
	if at.distance_to(_center(BACK_DOOR + Vector2i.DOWN)) < INTERACT_RANGE:
		return ["back_door", "[E] Hátsó ajtó: a szobák"]
	if at.distance_to(_center(INTERIOR_DOOR) + Vector2(TILE / 2.0, TILE / 2.0)) < INTERACT_RANGE:
		return ["exit", "[E] Kilépés a városba"]
	if at.distance_to(get_meta("barkeep_position")) < INTERACT_RANGE + 10:
		return ["barkeep", "[E] Beszélgetés: %s" % BARKEEP_NAME]
	for id: String in _seated:
		if at.distance_to(_seated[id].position) < INTERACT_RANGE:
			return [id, "[E] %s" % Characters.data(id)["name"]]
	return []


func _process(delta: float) -> void:
	_dome.visible = Blaster.met() and not Blaster.away()
	# Bence (a volt tolvaj) a levél után, Lőrinc a királynak vitt levél után ideköltözik:
	# leül a helyére, és onnantól játszható.
	for id: String in ["thief", "wizard", "gravedigger"]:
		if Characters.is_unlocked(id) and not _seated.has(id) and Progress.character != id:
			_sit(id)
	var focus := _focus()
	if not focus.is_empty():
		_prompt.text = focus[1]
	var target := 1.0 if not focus.is_empty() and not GamePause.active(get_tree()) else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)
	if _quest_mark:
		# Zöld "?" a kocsmáros fölött, ha van átvehető jutalom.
		_quest_mark.visible = not Quests.ready_ids().is_empty()
		_quest_mark.text = "?"
		_quest_mark.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55))
	# Egy ülő karakter mellett oldalt megjelenik a bemutatkozása.
	var character_id: String = focus[0] if not focus.is_empty() and Characters.ALL.has(focus[0]) else ""
	if character_id != _intro_for:
		_intro_for = character_id
		if not character_id.is_empty():
			_fill_intro(character_id)
	var intro_target := 1.0 if not character_id.is_empty() and not GamePause.active(get_tree()) else 0.0
	_intro.modulate.a = move_toward(_intro.modulate.a, intro_target, delta * 6.0)
	_intro.visible = _intro.modulate.a > 0.01


## A karakter bemutatkozó panelje (jobb oldalt): kép, név, szerep, történet, tulajdonságok.
func _build_intro() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	_intro = PanelContainer.new()
	_intro.add_theme_stylebox_override("panel", UiStyle.decorated_panel())
	_intro.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	_intro.offset_left = -470
	_intro.offset_right = -30
	_intro.offset_top = -260
	_intro.offset_bottom = 260
	_intro.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_intro.modulate.a = 0.0
	_intro.visible = false
	layer.add_child(_intro)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_intro.add_child(box)
	_intro_title = UiStyle.title_bar("")
	box.add_child(_intro_title)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	box.add_child(header)
	_intro_portrait = TextureRect.new()
	_intro_portrait.custom_minimum_size = Vector2(72, 112)
	_intro_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_intro_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(_intro_portrait)
	_intro_role = UiStyle.label("", 18, UiStyle.INK)
	_intro_role.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_intro_role)
	_intro_text = RichTextLabel.new()
	_intro_text.bbcode_enabled = true
	_intro_text.fit_content = true
	_intro_text.scroll_active = false
	_intro_text.custom_minimum_size.x = 390
	_intro_text.add_theme_color_override("default_color", UiStyle.INK_LIGHT)
	_intro_text.add_theme_font_size_override("normal_font_size", 15)
	box.add_child(_intro_text)
	box.add_child(UiStyle.label("[E] Átveszed az irányítást", 15, UiStyle.INK))


func _fill_intro(id: String) -> void:
	var definition := Characters.data(id)
	(_intro_title.get_child(0) as Label).text = definition["name"]
	_intro_portrait.texture = Characters.frames(id).get_frame_texture("idle", 0)
	_intro_role.text = definition.get("role", "")
	var lines: Array[String] = ["[i]%s[/i]" % definition.get("story", ""), ""]
	for trait_text: String in definition.get("traits", []):
		lines.append("[color=#3c6a32]•[/color] " + trait_text)
	_intro_text.text = "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or GamePause.active(get_tree()):
		return
	var focus := _focus()
	if focus.is_empty():
		return
	get_viewport().set_input_as_handled()
	match focus[0]:
		"door": _enter()
		"exit": _exit()
		"barkeep":
			Audio.play("ui_open")
			_camp.get_node("Menus").call("open_menu", _dialogue)
		"back_door": _move_corridor(true)
		"corridor_exit": _move_corridor(false)
		"dome":
			Audio.play("ui_open")
			_dome_dialogue.greeting = Blaster.greeting("room")
			_camp.get_node("Menus").call("open_menu", _dome_dialogue)
		"my_room": _move_room(true)
		"room_exit": _move_room(false)
		"bed": _sleep()
		"chest":
			Audio.play("chest_open", -4.0)
			_camp.get_node("Menus").call("open_menu", _camp.get_node("StashPanel"))
		"trophies":
			var beaten := 0
			for boss: String in trophies():
				if Bestiary.kills(boss) > 0:
					beaten += 1
			message.emit("Trófeafal: %d / %d főellenség emléke lóg a falon. Az üres keretek még várnak." % [beaten,
				trophies().size()] if beaten < trophies().size() else "Trófeafal: mind a %d főellenség emléke a falon. " \
				% trophies().size() + "Tóbiás szerint ilyet még nem látott.")
		_:
			if str(focus[0]).begins_with("room_"):
				_knock(int(str(focus[0]).trim_prefix("room_")))
			else:
				_switch_to(focus[0])


## Kopogás egy szoba ajtaján. Döme ajtaján először: felébred és kijön (onnantól az ajtaja előtt áll).
func _knock(index: int) -> void:
	Audio.play("door_lock", -6.0)
	if index == Blaster.ROOM and not Blaster.met():
		Blaster.wake()
		Audio.play("boss_slam", -14.0)
		_dome.visible = true
		message.emit(Blaster.WAKE_TEXT)
		return
	if index == Blaster.ROOM and Blaster.away():
		message.emit("A szoba üres, az ajtón cetli: „A bányában vagyok. Ne gyere utánam, ha nem hívtalak. D.”")
		return
	message.emit(ROOMS[index]["knock"])


static func room_rented() -> bool:
	return Progress.npc_quest_state(ROOM_FLAG) == "done"


## A trófeafal főellenségei: a hét király, a Vérfarkas, a mély főellenségek és a Káosz Ura.
static func trophies() -> Array[String]:
	var list: Array[String] = []
	list.assign(Bestiary.KINGS + [Bestiary.LORD] + Bestiary.DEEP_BOSSES + [Bestiary.CHAOS_LORD, Bestiary.ENGINE, Bestiary.GATE])
	return list


## A futás elején (a Camp hívja): ha kipihented magad a szobádban, ennyi bájitallal több (egyszer).
static func take_rest_bonus() -> int:
	if Progress.npc_quest_state(RESTED_FLAG) != "rested":
		return 0
	Progress.set_npc_quest(RESTED_FLAG, "")
	return REST_POTIONS


## A kocsmáros: a négyes szoba kibérlése (egyszer, tábori aranyból).
func _rent_room() -> String:
	if Progress.camp_gold < ROOM_PRICE:
		Audio.play("ui_error")
		return "[i]Tóbiás végignéz rajtad.[/i]\n\nÖtszáz arany, kalandor. Előre. Nem alkuszom, és hitelbe sem adok, " \
			+ "mióta Döme hitelbe lakik nálam."
	Progress.camp_gold -= ROOM_PRICE
	Progress.set_npc_quest(ROOM_FLAG, "done")
	Progress.change_trust(BARKEEP_ID, 10)
	Progress.mark_asked(BARKEEP_ID, "rent")
	Progress.save_game()
	Audio.play("coin")
	for node in _vacant_note:
		node.visible = false
	return "[i]Tóbiás leakaszt egy kulcsot a pult mögötti szögről, és a tenyeredbe nyomja.[/i]\n\n" \
		+ "A négyes a tiéd. Ágy, láda, és egy üres fal: oda akaszthatod, amit odalent legyőztél. A ládát " \
		+ "összekötöttem a táboriddal; ne kérdezd, hogyan, Döme csinálta. Ugyanazt éred el benne.\n\n" \
		+ "Ha kialszod magad egy rendes ágyban, másnap jobban mész lefelé. Ezt én mondom, aki harminc éve nem " \
		+ "aludtam ki magam.\n\n[color=#7a4a10](-%d tábori arany. A szobád a hátsó folyosón, a négyes ajtó: " % ROOM_PRICE \
		+ "alvás után a következő futást +%d HP-bájitallal kezded.)[/color]" % REST_POTIONS


## Alvás a szobádban: rövid elsötétülés, és a következő futás elején REST_POTIONS bájital (egyszer).
func _sleep() -> void:
	if Progress.npc_quest_state(RESTED_FLAG) == "rested":
		message.emit("Már kialudtad magad: a következő futást +%d HP-bájitallal kezded." % REST_POTIONS)
		return
	_busy = true
	Progress.set_npc_quest(RESTED_FLAG, "rested")
	var limits := Rect2(Vector2(MY_ROOM.position - Vector2i(1, 4)) * TILE, Vector2(MY_ROOM.size + Vector2i(2, 6)) * TILE)
	_camp.call("teleport_player", _player.global_position, limits, MY_ROOM_LIGHT)
	await get_tree().create_timer(0.6).timeout
	Audio.play("level_up", -6.0)
	message.emit("Kialudtad magad egy rendes ágyban. A következő futást +%d HP-bájitallal kezded." % REST_POTIONS)
	_busy = false


## A szobádba (`into`), vagy onnan vissza a folyosóra.
func _move_room(into: bool) -> void:
	_busy = true
	Audio.play("door_unlock", -4.0)
	_in_room = into
	_in_corridor = not into
	if into:
		var limits := Rect2(Vector2(MY_ROOM.position - Vector2i(1, 4)) * TILE, Vector2(MY_ROOM.size + Vector2i(2, 6)) * TILE)
		_camp.call("teleport_player", _center(MY_ROOM_DOOR + Vector2i.UP), limits, MY_ROOM_LIGHT)
	else:
		var limits := Rect2(Vector2(CORRIDOR.position - Vector2i(1, 5)) * TILE, Vector2(CORRIDOR.size + Vector2i(2, 7)) * TILE)
		_camp.call("teleport_player", _center(Vector2i(ROOM_DOOR_COLUMNS[VACANT_ROOM], CORRIDOR.position.y)) + Vector2(0, 10),
			limits, CORRIDOR_LIGHT)
	await get_tree().create_timer(0.6).timeout
	_busy = false


## A kocsmáros "munka" válasza: a küldetések ablaka (a beszélgetés helyett; itt lehet leadni is őket).
func _open_quests() -> String:
	var menus := _camp.get_node("Menus")
	menus.call("close_current")
	menus.call_deferred("open_menu", _quest_panel)
	return ""


## Át a hátsó ajtón a szobák folyosójára (`into`), vagy onnan vissza a kocsmába.
func _move_corridor(into: bool) -> void:
	_busy = true
	Audio.play("door_unlock", -4.0)
	_in_corridor = into
	if into:
		var limits := Rect2(Vector2(CORRIDOR.position - Vector2i(1, 5)) * TILE, Vector2(CORRIDOR.size + Vector2i(2, 7)) * TILE)
		_camp.call("teleport_player", _center(CORRIDOR_DOOR + Vector2i.UP), limits, CORRIDOR_LIGHT)
	else:
		var limits := Rect2(Vector2(INTERIOR.position - Vector2i(2, 3)) * TILE, Vector2(INTERIOR.size + Vector2i(4, 6)) * TILE)
		_camp.call("teleport_player", _center(BACK_DOOR + Vector2i.DOWN) + Vector2(0, 10), limits, INTERIOR_LIGHT)
	await get_tree().create_timer(0.6).timeout
	_busy = false


func _enter() -> void:
	Audio.play("door_unlock", -4.0)
	_inside = true
	var limits := Rect2(Vector2(INTERIOR.position - Vector2i(2, 3)) * TILE, Vector2(INTERIOR.size + Vector2i(4, 6)) * TILE)
	_camp.call("teleport_player", _center(INTERIOR_DOOR) + Vector2(TILE / 2.0, -TILE), limits, INTERIOR_LIGHT)


func _exit() -> void:
	Audio.play("door_unlock", -4.0)
	_inside = false
	_camp.call("teleport_player", door_position() + Vector2(0, 30), Rect2(), Color.BLACK)


# ---------------------------------------------------------------- segédek

func _center(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE


## Egy csempe a Kenney RPG lapról (16 px + 1 px hézag), 2x-es nagyításban.
func _tile(coords: Vector2i, tile: Vector2i, z: int, parent: Node = null) -> Sprite2D:
	return _sprite(RPG, Rect2(Vector2(coords) * 17.0, Vector2(16, 16)), _center(tile), z, parent)


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


func _prop(texture: Texture2D, region: Rect2, at: Vector2) -> void:
	var holder := Node2D.new()
	holder.position = at + Vector2(0, 16)
	_entities.add_child(holder)
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.scale = Vector2(2, 2)
	sprite.position = Vector2(0, -16)
	holder.add_child(sprite)
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


## Sötét gerendafal (szilárd).
func _wall_rect(rect: Rect2) -> void:
	var wall := ColorRect.new()
	wall.color = Color(0.16, 0.1, 0.08)
	wall.position = rect.position
	wall.size = rect.size
	wall.z_index = -9
	add_child(wall)
	_solid(rect)


func _light(at: Vector2, color: Color, size: float, energy: float) -> void:
	var light := PointLight2D.new()
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
	light.texture = texture
	light.texture_scale = size
	light.energy = energy
	light.position = at
	add_child(light)
