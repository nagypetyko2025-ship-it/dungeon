extends Node2D
## Tábor: ide kerülsz a játék indításakor, halál után és ha kilépsz a kazamatából.
## Esti erdei tisztás: fent a kazamata bejárata (kőpadlón a lépcső: E-vel indul a futás),
## alatta kitaposott földes tábor három sátorral, tábortűzzel, egy (még néma) NPC-vel,
## hordókkal, ládákkal, fakupaccal és korsókkal. A táborból kelet felé út vezet az erdőbe
## (később a faluhoz). A tisztás körül a látóhatárig sűrű erdő.

const DUNGEON_SCENE := "res://world/dungeon.tscn"
const CAMP_UPGRADES := preload("res://ui/camp_upgrades.gd")
const STASH_PANEL := preload("res://ui/stash_panel.gd")
const MERCHANT_PANEL := preload("res://ui/merchant_panel.gd")
const RETURN_PORTAL := preload("res://rooms/obstacles/return_portal.gd")
const STAIRS_SCENE := preload("res://rooms/obstacles/stairs.tscn")
## A tábori láda képe (0x72 lap: csukott láda).
const STASH_CHEST := Rect2(304, 416, 16, 16)
const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const CONTAINERS: Texture2D = preload("res://assets/shop/barrels_and_boxes.png")
const POTTERY: Texture2D = preload("res://assets/shop/pottery.png")
const TILE := 32
## A tisztás mérete csempékben (a széleken fasor).
const SIZE := Vector2i(44, 30)
## Ennyi csempe sűrű erdő a tisztáson túl; a kamera ennél tovább nem lát.
const FOREST_DEPTH := 14
const GRASS_SOURCE := 0
const DIRT_SOURCE := 0
## Sima fű (Kenney Roguelike RPG Pack).
const GRASS_TILES: Array[Vector2i] = [Vector2i(0, 15), Vector2i(1, 15), Vector2i(0, 16), Vector2i(1, 16)]
## Kitaposott föld (Kenney, 3x3-as szélezett darabok): [bal felső, felső, jobb felső, bal, közép, jobb, bal alsó, alsó, jobb alsó].
const DIRT := {
	"tl": Vector2i(7, 9), "t": Vector2i(8, 9), "tr": Vector2i(9, 9),
	"l": Vector2i(7, 10), "c": Vector2i(8, 10), "r": Vector2i(9, 10),
	"bl": Vector2i(7, 11), "b": Vector2i(8, 11), "br": Vector2i(9, 11),
}
## Keskeny, egy csempe széles ösvény (Kenney): a felső vége (lekerekítve), a közepe, és az alja, ahol a széles útba
## torkollik (ott kiszélesedik).
const NARROW := {"top": Vector2i(6, 11), "mid": Vector2i(9, 7), "join": Vector2i(7, 12)}
## Fák és bokrok a Kenney lapról (oszlop, sor). A magas fák két csempések (felül a lomb).
const TALL_TREES: Array[Vector2i] = [Vector2i(13, 11), Vector2i(15, 11), Vector2i(16, 11), Vector2i(18, 11)]
const SMALL_TREES: Array[Vector2i] = [Vector2i(13, 9), Vector2i(15, 9), Vector2i(16, 9), Vector2i(18, 9)]
const BUSHES: Array[Vector2i] = [Vector2i(19, 9), Vector2i(21, 9), Vector2i(24, 9), Vector2i(24, 10)]
const FLOWERS: Array[Vector2i] = [Vector2i(28, 9), Vector2i(29, 9), Vector2i(28, 10), Vector2i(22, 10)]
## Sátrak (2x2 csempe, a bal felső csempe a Kenney lapon): zöld és vászonszínű.
const TENTS: Array[Vector2i] = [Vector2i(46, 10), Vector2i(48, 10)]
## Tábortűz (két képkocka) és fakupac.
const FIRE_FRAMES: Array[Vector2i] = [Vector2i(14, 8), Vector2i(15, 8)]
const LOG_PILE := Vector2i(13, 8)
## Hordó és ládák (a bolt képéről), korsók.
const BARREL := Rect2(0, 0, 16, 16)
const BIG_CRATE := Rect2(16, 0, 16, 16)
const SMALL_CRATE := Rect2(32, 0, 16, 16)
const JUGS: Array[Rect2] = [Rect2(0, 0, 16, 16), Rect2(16, 16, 16, 16), Rect2(32, 0, 16, 16), Rect2(48, 32, 16, 16)]
## Az NPC (törpe, 0x72 lap): egyelőre csak áll a sátra előtt.
const NPC_RECT := Rect2(128, 292, 16, 28)
## A kazamata bejárata (0x72 lap): lépcső kőpadlón.
const STAIRS_REGION := Rect2(80, 192, 16, 16)
const STONE_FLOOR := Rect2(16, 64, 16, 16)
const INTERACT_RANGE := 56.0
## A veterán előtt a rönk miatt messzebbről is meg lehet szólítani.
const VETERAN_RANGE := 76.0
## Gáspár sétájának sebessége a kocsmáig (pixel / mp).
const GASPAR_SPEED := 95.0
## Esti szürkület.
const EVENING := Color(0.26, 0.3, 0.48)

## A tábor elrendezése (csempékben).
const STAIRS_TILE := Vector2i(22, 7)
## A lift a lépcső kőpadlóján túl, balra (egy kis hellyel mellette: az aknája ne lógjon a kövekre).
const LIFT_TILE := Vector2i(18, 7)
const FIRE_TILE := Vector2i(22, 17)
## A kovács bódéjának bal felső csempéje (a tábor jobb alsó sarkában, az úttól délre).
const SMITHY_TILE := FIRE_TILE + Vector2i(5, 1)
const CAMP_RADIUS := Vector2(9.5, 6.0)
## Az út sorai (2 csempe széles), keletre a tábortól az erdő széléig.
const ROAD_ROW := 17
## A világ keleti széle (a város mögötti erdő vége).
const WORLD_END_X := Town.RECT.end.x + FOREST_DEPTH
## A nyugati tisztás (a várossal ellentétes irányban): ide vezet egy kis sáros ösvény a
## táborból; a végén a romos ház áll (lásd Ruin).
const WEST_RECT := Rect2i(-30, 9, 20, 16)
## A világ nyugati széle (a nyugati tisztás mögötti erdő vége).
const WORLD_START_X := WEST_RECT.position.x - FOREST_DEPTH
## A veterán sátrának bal felső csempéje (a tábor nyugati részén, a sáros ösvénytől
## délre); előtte ül a veterán.
const VETERAN_TENT := Vector2i(9, 20)
## A könyvek állványai egymás mellett, a tábor északnyugati részén, egy kitaposott földfolton (BOOKS_PATCH):
## a Szörnyek könyve, a Tárgyak könyve (ItemCodex, ui/item_book.gd) és az Eredmények könyve (Achievements,
## ui/achievement_book.gd).
const BESTIARY_TILE := Vector2i(10, 10)
const BESTIARY_BOOK := preload("res://ui/bestiary_book.gd")
const ITEM_BOOK_TILE := Vector2i(12, 10)
const ITEM_BOOK := preload("res://ui/item_book.gd")
const ACHIEVEMENT_TILE := Vector2i(14, 10)
const ACHIEVEMENT_BOOK := preload("res://ui/achievement_book.gd")
## A földfolt közepe és félátmérői (csempében).
const BOOKS_PATCH := Vector2i(12, 10)
const BOOKS_PATCH_RADIUS := Vector2(3.6, 1.7)
## Olvasóállvány nyitott könyvvel (ehhez a projekthez rajzolva).
const LECTERN: Texture2D = preload("res://assets/props/lectern.png")
## A sáros ösvény színe (a földcsempék sötét, nedves árnyalata).
const MUD_TINT := Color(0.42, 0.31, 0.25)
## A veterán botja ("16x16 RPG items", Jetrel, CC0), a rönknek támasztva.
const CANE: Texture2D = preload("res://assets/props/cane.png")
const VETERAN_SHEET: Texture2D = preload("res://assets/characters/veteran.png")
## A veterán kardja (0x72 lap), a földbe szúrva mellette.
const VETERAN_SWORD := Rect2(339, 98, 10, 29)

@onready var _ground: TileMapLayer = $Ground
@onready var _dirt_layer: TileMapLayer = $Dirt
@onready var _entities: Node2D = $Entities
@onready var _player: Node2D = $Entities/Player

var _stairs_position := Vector2.ZERO
var _prompt: Label
var _fade: ColorRect
var _leaving := false
## Kitaposott csempék (föld), és ahová nem kerülhet fa / bokor.
var _dirt := {}
## A nyugati sáros ösvény csempéi (külön, sötétebb rétegen).
var _mud := {}
## Keskeny ösvények (egy csempe szélesek) az útról az egyajtós házakhoz és a mólóhoz.
var _narrow := {}
var _blocked := {}
## A kiképzősátor bejárata (a jobb oldali sátor eleje): itt E-re nyílik a fejlesztés-ablak.
var _training_tent_position := Vector2.ZERO
var _upgrades_panel: CanvasLayer
## A tábori láda helye (E-re nyílik a láda ablaka).
var _stash_position := Vector2.ZERO
var _stash_panel: CanvasLayer
var _merchant_panel: CanvasLayer
var _npc_position := Vector2.ZERO
## A kovács (E-re nyílik a műhelye: tárgyfejlesztés, szétszedés; lásd SmithPanel).
var _smith_position := Vector2.ZERO
var _smith_panel: SmithPanel
## A Szörnyek könyve (E-re nyílik az állványnál).
var _bestiary_position := Vector2.ZERO
var _bestiary_book: CanvasLayer
var _item_book_position := Vector2.ZERO
var _item_book: CanvasLayer
var _achievement_position := Vector2.ZERO
var _achievement_book: CanvasLayer
## A veterán helye (később ide jön a beszélgetés a régi időkről).
var _veteran_position := Vector2.ZERO
var _veteran_dialogue: DialoguePanel
var _veteran_sprite: AnimatedSprite2D
## A kardja és a botja (ezeket magával viszi, amikor elmegy).
var _veteran_props: Array[Node2D] = []
var _veteran_walking := false
## Pihenő közben (főellenség után kimentél) vagy.
var _on_break := false
## A helyszín zenéjének ellenőrzése ennyi mp-enként (lásd music_place).
const MUSIC_CHECK := 0.5
var _music_left := 0.0
var _town: Town
## Pihenő közben itt van a torlasz a városba vezető úton (felirat jelenik meg a közelében).
var _road_block_position := Vector2.INF
var _toast_label: Label
var _toast_tween: Tween
## A kazamata lépcsője (pihenő közben rács van rajta).
var _stairs_node: Area2D
var _gold_label: Label


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.04, 0.06, 0.05))
	if not GameState.display_initialized:
		GameState.display_initialized = true
		if Audio.saved_fullscreen():
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	# Pihenő (főellenség után kimentél): a futás áll, a játékos a futás állapotával van itt.
	# Különben nincs futás: a játékos friss, és innen nem kerül semmi az eredmények közé.
	_on_break = GameState.on_break
	if not _on_break:
		GameState.reset()
		GameState.run_recorded = true
	Progress.load_game()
	# Ha a futásban elérted a 30. emeletet, most "vissza is jöttél" (a királyi vár engedélye).
	Castle.on_return_to_camp()
	Audio.music(music_place(_player.global_position))
	GameCursor.apply()
	$CanvasModulate.color = EVENING
	# A szabad ég alatt a lovag "lámpása" halványabb, hogy esti hangulata legyen.
	_player.get_node("PointLight2D").energy = 0.5
	_build_ground()
	_build_entrance()
	_build_dirt()
	_build_camp()
	_build_smithy()
	_build_veteran()
	_build_bestiary()
	_build_signs()
	_build_trees()
	_build_forest()
	_build_bounds()
	_build_town_sign()
	_build_fireflies()
	_build_ui()
	# A város (a kocsmával) az erdőn átvezető út végén.
	_town = Town.new()
	_town.name = "Town"
	add_child(_town)
	_town.setup(self)
	_town.build()
	_town.message.connect(_toast)
	# A város északi része: lakóház, út a királyi várhoz, a kapuban két őr.
	var castle := Castle.new()
	castle.name = "Castle"
	add_child(castle)
	castle.setup(self)
	castle.build()
	castle.message.connect(_toast)
	# A kocsmától jobbra a kalandorok kórháza (ide viszik a sebesülteket).
	var hospital := Hospital.new()
	hospital.name = "Hospital"
	add_child(hospital)
	hospital.setup(self)
	hospital.build()
	# A kórháztól jobbra a régi, poros raktár (Warehouse).
	var warehouse := Warehouse.new()
	warehouse.name = "Warehouse"
	add_child(warehouse)
	warehouse.setup(self)
	warehouse.build()
	# Temető a kocsma alatt.
	var graveyard := Graveyard.new()
	graveyard.name = "Graveyard"
	add_child(graveyard)
	graveyard.setup(self)
	graveyard.build()
	# A város keleti, új részén a tó (szigettel, mólóval).
	var lake := Lake.new()
	lake.name = "Lake"
	add_child(lake)
	lake.setup(self)
	lake.build()
	# A raktár és a tó között félúton földút vezet fel északra, az erdőn át a bánya hegyéhez.
	var mine := Mine.new()
	mine.name = "Mine"
	add_child(mine)
	mine.setup(self)
	mine.build()
	mine.message.connect(_toast)
	# A tábor jobb felső sarkából rejtett ösvény vezet egy erdei sírhoz (HiddenGrave).
	var hidden_grave := HiddenGrave.new()
	hidden_grave.name = "HiddenGrave"
	add_child(hidden_grave)
	hidden_grave.setup(self)
	hidden_grave.build()
	_entities.add_child(Fisherman.new())
	# A temető mellett (keletre) a régi kápolna; a sírásó a küldetése után ide költözik.
	var chapel := Chapel.new()
	chapel.name = "Chapel"
	add_child(chapel)
	chapel.setup(self)
	chapel.build()
	chapel.message.connect(_toast)
	# A nyugati tisztáson a romos ház (benne a tolvaj rejtekszobája).
	var ruin := Ruin.new()
	ruin.name = "Ruin"
	add_child(ruin)
	ruin.setup(self)
	ruin.build()
	ruin.message.connect(_toast)
	# A kút alja (Lőrinc megmentése után le lehet mászni).
	var cave := WellCave.new()
	cave.name = "WellCave"
	add_child(cave)
	cave.setup(self)
	cave.build()
	cave.message.connect(_toast)
	add_child(QuestTracker.new())
	var cheats := CheatMenu.new()
	cheats.name = "CheatMenu"
	add_child(cheats)
	var potion_badge := PotionBadge.new()
	potion_badge.left_offset = 16.0
	add_child(potion_badge)
	var book: CanvasLayer = preload("res://ui/quest_book.gd").new()
	book.name = "QuestBook"
	add_child(book)
	_upgrades_panel = CAMP_UPGRADES.new()
	_upgrades_panel.name = "CampUpgrades"
	add_child(_upgrades_panel)
	_stash_panel = STASH_PANEL.new()
	_stash_panel.name = "StashPanel"
	add_child(_stash_panel)
	_bestiary_book = BESTIARY_BOOK.new()
	_bestiary_book.name = "BestiaryBook"
	add_child(_bestiary_book)
	_item_book = ITEM_BOOK.new()
	_item_book.name = "ItemBook"
	add_child(_item_book)
	_achievement_book = ACHIEVEMENT_BOOK.new()
	_achievement_book.name = "AchievementBook"
	add_child(_achievement_book)
	_merchant_panel = MERCHANT_PANEL.new()
	_merchant_panel.name = "MerchantPanel"
	add_child(_merchant_panel)
	_smith_panel = SmithPanel.new()
	_smith_panel.name = "SmithPanel"
	add_child(_smith_panel)
	# Beszélgetés a veteránnal (bizalom, kérdések: Dialogues).
	_veteran_dialogue = DialoguePanel.new()
	_veteran_dialogue.name = "VeteranDialogue"
	_veteran_dialogue.npc_id = Dialogues.VETERAN_ID
	_veteran_dialogue.npc_name = Dialogues.VETERAN_NAME
	_veteran_dialogue.greeting = Dialogues.VETERAN_GREETING
	_veteran_dialogue.options_provider = func() -> Array[Dictionary]:
		return Dialogues.veteran_options(_player.get_node("Inventory"))
	var face := AtlasTexture.new()
	face.atlas = VETERAN_SHEET
	face.region = Rect2(0, 0, 16, 28)
	_veteran_dialogue.portrait = face
	add_child(_veteran_dialogue)
	# A táborban nálad lévő felszerelés mentett (a ládából kivett tárgyak nem vesznek el).
	# Pihenő közben a futás felszerelése van nálad (az a futás része, nem a táboré).
	var inventory: Inventory = _player.get_node("Inventory")
	if not _on_break:
		if not Progress.camp_inventory.is_empty():
			inventory.load_data(Progress.camp_inventory)
		inventory.changed.connect(func() -> void:
			Progress.camp_inventory = inventory.save_data()
			Progress.save_game())
	_setup_camera()
	_player.global_position = _tile_center(STAIRS_TILE + Vector2i(0, 3))
	if _on_break:
		_setup_break()
	_player.get_node("Camera2D").reset_smoothing()
	_show_title()
	# Gyakorlás: a gyakorló pálya után a tábori bemutató (lásd TutorialGuide.setup_camp).
	if GameState.tutorial:
		var guide := TutorialGuide.new()
		guide.name = "TutorialGuide"
		add_child(guide)
		guide.call("setup_camp", self)
	# Közös játékban a többiek is itt járnak a táborban (lásd NetAvatars).
	if NetLobby.is_playing(get_tree()):
		var avatars := NetAvatars.new()
		avatars.name = "NetAvatars"
		add_child(avatars)
		avatars.setup(self)
		avatars.message.connect(_toast)
	# Az első visszatéréskor a kazamatából: két katona hordágyon visz egy sebesültet az orvoshoz.
	var returned := GameState.visited_dungeon
	GameState.visited_dungeon = false
	if returned and not _on_break and StretcherScene.should_play():
		var scene := StretcherScene.new()
		scene.name = "StretcherScene"
		add_child(scene)
		scene.start(self, _stretcher_path())


## A hordágyas katonák útja: a kazamata lépcsőjétől le a tábor közepén, a tűz fölött kelet felé
## az útra, végig az úton a városba, a kocsma melletti lakóház (az orvos) ajtajáig.
func _stretcher_path() -> Array[Vector2]:
	var road_y := (ROAD_ROW + 0.6) * TILE
	var house := Castle.HOUSE_TOP_LEFT
	var door := Vector2(house.x + Castle.HOUSE_SIZE.x / 2 + 0.5, house.y + Castle.HOUSE_SIZE.y) * TILE
	return [
		_tile_center(STAIRS_TILE + Vector2i(0, 1)), Vector2(22.5 * TILE, 14.8 * TILE),
		Vector2(26.5 * TILE, 15.6 * TILE), Vector2(28.5 * TILE, road_y), Vector2(door.x, road_y),
		door + Vector2(0, 6),
	]


## Pihenő: rács a lépcsőn, kék portál a lépcső mellett (vissza a kazamatába, a főellenség termébe).
func _setup_break() -> void:
	_stairs_node.call("set_locked", true)
	var portal: Node2D = RETURN_PORTAL.new()
	portal.prompt_text = "[E] Vissza a kazamatába (%d. emelet)" % _return_depth()
	portal.on_use = _return_to_dungeon
	portal.position = _tile_center(STAIRS_TILE + Vector2i(5, 1))
	add_child(portal)
	_player.global_position = portal.position + Vector2(0, 50)
	_block_town_road()
	# A futás állapota mentődik: ha most kilépsz, innen folytathatod (RunSave).
	RunSave.save.call_deferred(_player)


## Pihenő közben a városba vezető út el van torlaszolva (fatörzsek és ládák a tisztás szélén).
func _block_town_road() -> void:
	var x := SIZE.x - 1
	for row in [ROAD_ROW - 1, ROAD_ROW, ROAD_ROW + 1, ROAD_ROW + 2]:
		var at := _tile_center(Vector2i(x, row))
		if row in [ROAD_ROW, ROAD_ROW + 1]:
			_rpg_prop(LOG_PILE, at + Vector2(0, -10))
		else:
			_prop(CONTAINERS, BIG_CRATE, at + Vector2(0, -14))
	_solid(Rect2(Vector2(x * TILE, (ROAD_ROW - 1) * TILE), Vector2(TILE, 4 * TILE)))
	_road_block_position = _tile_center(Vector2i(x - 1, ROAD_ROW)) + Vector2(0, TILE / 2.0)

## Ha pihenő közben bezárod a játékot, a futás elmentődik (RunSave), és a főmenü "Folytatás"
## gombjával innen folytathatod. (Közös játékban nincs ilyen mentés: ott ez a futás feladása,
## a pénzed 40%-a a táborba kerül.)
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and GameState.on_break and is_instance_valid(_player):
		if not Profiles.multiplayer:
			RunSave.save(_player)
			return
		Records.submit_run(_player)
		Progress.rescue_gold(int(_player.get("gold")) + GameState.break_gold_left, 0.4)


## Hova visz vissza a kék portál: ugyanarra az emeletre, ahonnan pihenni jöttél (a főellenség termébe,
## lásd GameState.break_floor). A régi, emelet nélküli futásmentésből a következő emeletre.
func _return_depth() -> int:
	return GameState.depth if not GameState.break_floor.is_empty() else GameState.depth + 1


## Vissza a kazamatába a pihenőből: ugyanoda, ahonnan kijöttél (a főellenség termébe), minden
## megmarad (a bent hagyott pénzt is visszakapod).
func _return_to_dungeon() -> void:
	if _leaving:
		return
	_leaving = true
	Audio.play("stairs")
	_player.call("save_state")
	# A futás folytatódik a kazamatában: a pihenőnél készült mentés már nem kell.
	RunSave.clear()
	GameState.saved_gold += GameState.break_gold_left
	GameState.break_gold_left = 0
	GameState.on_break = false
	GameState.depth = _return_depth()
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.5)
	await tween.finished
	get_tree().change_scene_to_file(DUNGEON_SCENE)


func _build_ground() -> void:
	# A Kenney-fűcsempék sarkában egy-egy átlátszó pixel van (sarokdarabok); ezeket
	# fűszínnel kitöltjük, és a csempéket egy saját, hézag nélküli képbe másoljuk.
	var sheet := RPG.get_image()
	sheet.convert(Image.FORMAT_RGBA8)
	var strip := Image.create(16 * GRASS_TILES.size(), 16, false, Image.FORMAT_RGBA8)
	for i in GRASS_TILES.size():
		var tile := sheet.get_region(Rect2i(Vector2i(GRASS_TILES[i]) * 17, Vector2i(16, 16)))
		var fill := tile.get_pixel(8, 8)
		for x in 16:
			for y in 16:
				if tile.get_pixel(x, y).a < 0.5:
					tile.set_pixel(x, y, fill)
		strip.blit_rect(tile, Rect2i(0, 0, 16, 16), Vector2i(i * 16, 0))
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(16, 16)
	var grass := TileSetAtlasSource.new()
	grass.texture = ImageTexture.create_from_image(strip)
	grass.texture_region_size = Vector2i(16, 16)
	tile_set.add_source(grass, GRASS_SOURCE)
	for i in GRASS_TILES.size():
		grass.create_tile(Vector2i(i, 0))
	_ground.tile_set = tile_set
	# (A királyi vár tisztása és a mögötte lévő erdő magasabbra nyúlik: ott is legyen fű.)
	for x in range(WORLD_START_X, WORLD_END_X):
		for y in range(Castle.RECT.position.y - FOREST_DEPTH, SIZE.y + FOREST_DEPTH):
			_ground.set_cell(Vector2i(x, y), GRASS_SOURCE, Vector2i(randi() % GRASS_TILES.size(), 0))


## A kazamata bejárata: kőpadló, rajta a lefelé vezető lépcső; balra mellette a lift (CampLift).
func _build_entrance() -> void:
	var lift := CampLift.new()
	lift.name = "CampLift"
	lift.position = _tile_center(LIFT_TILE)
	_entities.add_child(lift)
	lift.setup(self)
	# Az akna, a magas bakállvány és mellette Bertalan helye (fa, bokor ne kerüljön oda).
	for dx in range(-2, 2):
		for dy in range(-4, 2):
			_blocked[LIFT_TILE + Vector2i(dx, dy)] = true
	_stairs_position = _tile_center(STAIRS_TILE)
	for dx in range(-2, 3):
		for dy in range(-1, 2):
			_sprite(SpriteSheet.region(STONE_FLOOR), _tile_center(STAIRS_TILE + Vector2i(dx, dy)), -8)
			_blocked[STAIRS_TILE + Vector2i(dx, dy)] = true
	# A lépcső (a kazamata lépcsője: pihenő közben rács kerül rá). Itt nem rálépésre,
	# hanem E-re visz le, ezért a saját érzékelője ki van kapcsolva.
	_stairs_node = STAIRS_SCENE.instantiate()
	_stairs_node.position = _stairs_position
	_stairs_node.z_index = -7
	_stairs_node.monitoring = false
	add_child(_stairs_node)


## Kitaposott föld: ovális tábor a tűz körül, ösvény fel a lépcsőhöz, és az út keletre.
func _build_dirt() -> void:
	for x in range(-int(CAMP_RADIUS.x) - 1, int(CAMP_RADIUS.x) + 2):
		for y in range(-int(CAMP_RADIUS.y) - 1, int(CAMP_RADIUS.y) + 2):
			var wobble := randf_range(-0.12, 0.12)
			if pow(x / CAMP_RADIUS.x, 2) + pow(y / CAMP_RADIUS.y, 2) <= 1.0 + wobble:
				_dirt[FIRE_TILE + Vector2i(x, y)] = true
	for y in range(STAIRS_TILE.y + 2, FIRE_TILE.y):
		for dx in range(-1, 2):
			_dirt[Vector2i(STAIRS_TILE.x + dx, y)] = true
	# Kitaposott földfolt a könyvek állványai alatt.
	for x in range(-4, 5):
		for y in range(-2, 3):
			if pow(x / BOOKS_PATCH_RADIUS.x, 2) + pow(y / BOOKS_PATCH_RADIUS.y, 2) <= 1.0 + randf_range(-0.1, 0.1):
				_dirt[BOOKS_PATCH + Vector2i(x, y)] = true
	# Az út: a tisztáson kicsit kanyarog, az erdőben egyenesen megy tovább a városig, és át rajta.
	for x in range(FIRE_TILE.x + 5, Town.RECT.end.x):
		var row := ROAD_ROW
		if x < SIZE.x - 2:
			row += roundi(sin(x * 0.45) * 1.0)
		_dirt[Vector2i(x, row)] = true
		_dirt[Vector2i(x, row + 1)] = true
	# Ösvény a kocsma ajtajától az útig.
	for tile in Town.path_tiles():
		_dirt[tile] = true
	# Út a kocsma mellett északra, a királyi vár kapujáig.
	for tile in Castle.path_tiles():
		_dirt[tile] = true
	# Földút az úttól le a temetőhöz (a kocsma alatt).
	for tile in Graveyard.path_tiles():
		_dirt[tile] = true
	# Földút a kápolnához (a keleti oldala mellett le, a déli ajtajáig), és fel északra, a bánya hegyéig.
	for tile in Chapel.path_tiles():
		_dirt[tile] = true
	for tile in Mine.path_tiles():
		_dirt[tile] = true
	# Keskeny ösvények az útról a kórház és a raktár ajtajához, és a tó mólójához.
	for tiles: Array[Vector2i] in [Hospital.path_tiles(), Warehouse.path_tiles(), Lake.path_tiles()]:
		for tile in tiles:
			_narrow[tile] = true
	# Kis sáros ösvény nyugatra (a várossal ellentétes irányba): a tisztásokon kanyarog,
	# az erdőben egyenes, és a nyugati tisztáson ér véget (a végén a romos ház).
	for x in range(WEST_RECT.position.x + 3, FIRE_TILE.x - 8):
		var row := ROAD_ROW
		if x > 2 or x < WEST_RECT.end.x - 2:
			row += roundi(sin(x * 0.4 + 1.0) * 1.0)
		for tile: Vector2i in [Vector2i(x, row), Vector2i(x, row + 1)]:
			if not _dirt.has(tile):
				_mud[tile] = true
	# Rövid sáros ösvény a romos ház ajtajáig.
	for tile in Ruin.path_tiles():
		_mud[tile] = true
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(16, 16)
	var source := TileSetAtlasSource.new()
	source.texture = RPG
	source.texture_region_size = Vector2i(16, 16)
	source.separation = Vector2i(1, 1)
	tile_set.add_source(source, DIRT_SOURCE)
	for coords: Vector2i in DIRT.values() + NARROW.values():
		source.create_tile(coords)
	_dirt_layer.tile_set = tile_set
	for cell: Vector2i in _dirt:
		_dirt_layer.set_cell(cell, DIRT_SOURCE, DIRT[_dirt_piece(cell)])
		_blocked[cell] = true
	for cell: Vector2i in _narrow:
		_dirt_layer.set_cell(cell, DIRT_SOURCE, NARROW[_narrow_piece(cell)])
		_blocked[cell] = true
	# A sár ugyanazokból a földcsempékből, de egy külön, sötét, nedves rétegen (a földút
	# fölött, hogy a csatlakozásnál a sár látsszon), tócsákkal.
	var mud_layer := TileMapLayer.new()
	mud_layer.name = "Mud"
	mud_layer.tile_set = tile_set
	mud_layer.z_index = _dirt_layer.z_index
	mud_layer.scale = _dirt_layer.scale
	mud_layer.modulate = MUD_TINT
	add_child(mud_layer)
	move_child(mud_layer, _dirt_layer.get_index() + 1)
	for cell: Vector2i in _mud:
		mud_layer.set_cell(cell, DIRT_SOURCE, DIRT[_dirt_piece(cell)])
		_blocked[cell] = true
	var cells: Array = _mud.keys()
	cells.shuffle()
	for cell: Vector2i in cells.slice(0, cells.size() / 6):
		var puddle := Puddle.new()
		puddle.position = _tile_center(cell) + Vector2(randf_range(-6, 6), randf_range(-6, 6))
		puddle.size = Vector2(randf_range(7, 12), randf_range(3, 5))
		puddle.z_index = -8
		add_child(puddle)


## Tócsa a sárban: sötét víz, apró csillanással.
class Puddle:
	extends Node2D
	var size := Vector2(10, 4)

	func _draw() -> void:
		var points := PackedVector2Array()
		for i in 16:
			points.append(Vector2.from_angle(TAU * i / 16.0) * size)
		draw_colored_polygon(points, Color(0.13, 0.12, 0.14, 0.85))
		draw_line(Vector2(-size.x * 0.4, -size.y * 0.3), Vector2(size.x * 0.1, -size.y * 0.3), Color(0.55, 0.6, 0.7, 0.6), 1.0)


func _is_path(tile: Vector2i) -> bool:
	return _dirt.has(tile) or _mud.has(tile) or _narrow.has(tile)


## A keskeny ösvény darabja: alul a széles útba torkollik, felül (az ajtónál, a mólónál) lekerekítve ér véget.
func _narrow_piece(cell: Vector2i) -> String:
	if _dirt.has(cell + Vector2i.DOWN):
		return "join"
	if not _narrow.has(cell + Vector2i.UP):
		return "top"
	return "mid"


## A szomszédok alapján melyik szélezett földdarab kell (a széle lekerekített).
func _dirt_piece(cell: Vector2i) -> String:
	# A föld és a sár egymásba folyik (a csatlakozásnál nincs lekerekített szél).
	var up := _is_path(cell + Vector2i.UP)
	var down := _is_path(cell + Vector2i.DOWN)
	var left := _is_path(cell + Vector2i.LEFT)
	var right := _is_path(cell + Vector2i.RIGHT)
	var vertical := "t" if not up else ("b" if not down else "")
	var horizontal := "l" if not left else ("r" if not right else "")
	if vertical.is_empty() and horizontal.is_empty():
		return "c"
	if vertical.is_empty():
		return horizontal
	if horizontal.is_empty():
		return vertical
	return vertical + horizontal


## Sátrak, tábortűz, NPC, hordók, ládák, fakupac, korsók.
func _build_camp() -> void:
	_tent(FIRE_TILE + Vector2i(-7, -3), 0)
	_tent(FIRE_TILE + Vector2i(5, -4), 1)
	_tent(FIRE_TILE + Vector2i(-4, 3), 1)
	_campfire(_tile_center(FIRE_TILE))
	# Az NPC a bal oldali sátor előtt, a tűz felé fordulva.
	_npc_position = _tile_center(FIRE_TILE + Vector2i(-6, -1)) + Vector2(0, 6)
	_npc(_npc_position)
	# Hordók és ládák a jobb oldali sátor mellett, korsók a bal oldali mellett.
	var right_tent := FIRE_TILE + Vector2i(5, -4)
	# A jobb oldali sátor a kiképzősátor (előtte nem áll senki).
	_training_tent_position = Vector2(right_tent + Vector2i(1, 2)) * TILE + Vector2(0, 14)
	_training_sign(Vector2(right_tent + Vector2i(1, 2)) * TILE + Vector2(-46, 6))
	_prop(CONTAINERS, BARREL, _tile_center(right_tent + Vector2i(2, 1)))
	_prop(CONTAINERS, BARREL, _tile_center(right_tent + Vector2i(2, 2)) + Vector2(6, 0))
	_prop(CONTAINERS, BIG_CRATE, _tile_center(right_tent + Vector2i(3, 2)) + Vector2(4, 2))
	_prop(CONTAINERS, SMALL_CRATE, _tile_center(right_tent + Vector2i(3, 1)) + Vector2(2, 6))
	var left_tent := FIRE_TILE + Vector2i(-7, -3)
	_prop(POTTERY, JUGS[0], _tile_center(left_tent + Vector2i(-1, 1)) + Vector2(4, 6), false)
	_prop(POTTERY, JUGS[1], _tile_center(left_tent + Vector2i(-1, 1)) + Vector2(-10, 12), false)
	_prop(POTTERY, JUGS[3], _tile_center(left_tent + Vector2i(-1, 2)) + Vector2(2, 4), false)
	# Fakupac a tűz mellett, és két korsó a tűz körül.
	_rpg_prop(LOG_PILE, _tile_center(FIRE_TILE + Vector2i(2, 1)) + Vector2(4, 4))
	_rpg_prop(LOG_PILE, _tile_center(FIRE_TILE + Vector2i(3, 1)) + Vector2(-6, 8))
	_prop(POTTERY, JUGS[2], _tile_center(FIRE_TILE + Vector2i(-2, 1)) + Vector2(0, 4), false)
	# Ládák az alsó sátor mellett.
	var bottom_tent := FIRE_TILE + Vector2i(-4, 3)
	_prop(CONTAINERS, BIG_CRATE, _tile_center(bottom_tent + Vector2i(2, 1)) + Vector2(4, 2))
	_prop(CONTAINERS, BARREL, _tile_center(bottom_tent + Vector2i(-1, 1)) + Vector2(4, 4))
	# Tábori láda az alsó sátor előtt: ide érkeznek a felküldött tárgyak.
	_stash_position = _tile_center(bottom_tent + Vector2i(3, 2)) + Vector2(6, 4)
	var chest := AtlasTexture.new()
	chest.atlas = SpriteSheet.TEXTURE
	chest.region = STASH_CHEST
	var holder := Node2D.new()
	holder.position = _stash_position + Vector2(0, 14)
	_entities.add_child(holder)
	_sprite(chest, Vector2(0, -16), 0, holder)
	_body(holder, Vector2(0, -6), Vector2(28, 12))


## A kovács bódéja a tábor jobb alsó sarkában (lásd Smithy); előtte állva E-re nyílik a műhelye.
func _build_smithy() -> void:
	var smithy := Smithy.new()
	smithy.name = "Smithy"
	smithy.tile = SMITHY_TILE
	_entities.add_child(smithy)
	# A kovács és az üllő előtt (a bódé alsó szélén).
	_smith_position = _tile_center(SMITHY_TILE + Vector2i(1, 2)) + Vector2(16, 26)


## A tábor nyugati részén: sátor, előtte egy farönkön a sebesült veterán ül (kötés a
## sisakján), mellette a földbe szúrt kardja és a botja, előtte kis tűz. Később a régi időkről
## (a kazamata történetéről) lehet majd vele beszélni; egyelőre nem mond semmit.
func _build_veteran() -> void:
	_tent(VETERAN_TENT, 1)
	var seat := _tile_center(VETERAN_TENT + Vector2i(1, 2)) + Vector2(-4, 8)
	# Ha már elköltözött a kocsmába, csak a sátra, a rönk és a tűz marad.
	var moved_out := Progress.npc_quest_state(Dialogues.TAVERN_FLAG) == "done"
	_veteran_position = Vector2.INF if moved_out else seat
	# A veterán: lassan "lélegzik" (álló kockák lassan), lejjebb ülve, a lábát a rönk takarja.
	if not moved_out:
		_veteran_sprite = AnimatedSprite2D.new()
		_veteran_sprite.sprite_frames = Dialogues.veteran_frames()
		_veteran_sprite.scale = Vector2(2, 2)
		_veteran_sprite.offset = Vector2(0, -14)
		_veteran_sprite.position = seat + Vector2(0, 6)
		_veteran_sprite.play("idle")
		_entities.add_child(_veteran_sprite)
	# A rönk, amin ül (előtte, hogy takarja a lábát).
	var log_holder := Node2D.new()
	log_holder.position = seat + Vector2(0, 12)
	_entities.add_child(log_holder)
	log_holder.add_child(SeatLog.new())
	_body(log_holder, Vector2(0, -4), Vector2(34, 10))
	# A kardja a földbe szúrva, és a botja a rönknek támasztva.
	var sword_holder := Node2D.new()
	sword_holder.position = seat + Vector2(30, 6)
	_entities.add_child(sword_holder)
	if not moved_out:
		var sword := _sprite(SpriteSheet.region(VETERAN_SWORD), Vector2(0, -22), 0, sword_holder)
		sword.rotation = deg_to_rad(172)
		sword.scale = Vector2(1.5, 1.5)
		sword.position = Vector2(0, -16)
		sword.modulate = Color(0.7, 0.68, 0.66)
		# (A bot képe átlós, a kampója balra fent: 35 fokkal elforgatva szinte függőleges.)
		var cane := _sprite(CANE, Vector2(-26, -20), 0, log_holder)
		cane.rotation = deg_to_rad(35)
		cane.scale = Vector2(2.4, 2.4)
		_veteran_props = [sword, cane]
	# Kis tűz előtte, hogy esténként is látsszon.
	_campfire(_tile_center(VETERAN_TENT + Vector2i(3, 2)) + Vector2(6, 4))
	for dx in range(-1, 3):
		_blocked[VETERAN_TENT + Vector2i(dx, 2)] = true
		_blocked[VETERAN_TENT + Vector2i(dx, 3)] = true


## A három könyv: nyitott könyv egy-egy faállványon (E-re nyílnak), mindegyik kicsit más színű.
func _build_bestiary() -> void:
	_bestiary_position = _lectern(BESTIARY_TILE, Color.WHITE)
	_item_book_position = _lectern(ITEM_BOOK_TILE, Color(1.0, 0.86, 0.7))
	_achievement_position = _lectern(ACHIEVEMENT_TILE, Color(1.0, 0.95, 0.62))


func _lectern(tile: Vector2i, tint: Color) -> Vector2:
	var holder := Node2D.new()
	holder.position = _tile_center(tile) + Vector2(0, 14)
	_entities.add_child(holder)
	var lectern := Sprite2D.new()
	lectern.texture = LECTERN
	lectern.scale = Vector2(2, 2)
	lectern.position = Vector2(0, -LECTERN.get_height())
	lectern.modulate = tint
	holder.add_child(lectern)
	_body(holder, Vector2(0, -4), Vector2(30, 10))
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			_blocked[tile + Vector2i(dx, dy)] = true
	return holder.position


## A 30. emelet híre után Gáspár feláll, magához veszi a kardját és a botját, és útvonal-
## pontokon át (a tábortüzet, a sátrakat és az árust kikerülve) a városba, a kocsmába sétál.
func _start_gaspar_walk() -> void:
	_veteran_walking = true
	_veteran_position = Vector2.INF
	for prop: Node2D in _veteran_props:
		create_tween().tween_property(prop, "modulate:a", 0.0, 0.4)
	FloatingText.spawn(_entities, _veteran_sprite.global_position + Vector2(0, -60),
		"Ideje inni egyet a fiúkra...", Color(0.95, 0.9, 0.8), 18)
	var road_y := (ROAD_ROW + 0.6) * TILE
	var door := _town.door_position()
	var path: Array[Vector2] = [
		_veteran_sprite.position + Vector2(0, -14),
		Vector2(12.5 * TILE, 18.5 * TILE), Vector2(19.5 * TILE, 18.5 * TILE),
		Vector2(20.5 * TILE, 16.2 * TILE), Vector2(26.5 * TILE, 16.2 * TILE),
		Vector2(28.5 * TILE, road_y), Vector2(door.x, road_y), door,
	]
	var walk := create_tween()
	walk.tween_interval(1.0)
	walk.tween_callback(func() -> void: _veteran_sprite.play("run"))
	var from := _veteran_sprite.position
	for point in path:
		var target := point
		walk.tween_callback(func() -> void:
			if target.x != _veteran_sprite.position.x:
				_veteran_sprite.flip_h = target.x < _veteran_sprite.position.x)
		walk.tween_property(_veteran_sprite, "position", target, from.distance_to(target) / GASPAR_SPEED)
		from = target
	# Az ajtóban eltűnik, és bent leül.
	walk.tween_property(_veteran_sprite, "modulate:a", 0.0, 0.4)
	walk.tween_callback(func() -> void:
		_veteran_sprite.queue_free()
		_town.seat_gaspar()
		Audio.play("door_unlock", -8.0))


## Fekvő farönk (ülőhely): kéreg, csíkok, világos évgyűrűs vége.
class SeatLog:
	extends Node2D

	func _draw() -> void:
		var bark := Color(0.38, 0.24, 0.13)
		var dark := Color(0.24, 0.14, 0.07)
		draw_rect(Rect2(-16, -12, 30, 11), bark)
		draw_line(Vector2(-16, -12), Vector2(14, -12), dark, 1.0)
		draw_line(Vector2(-16, -1), Vector2(14, -1), dark, 2.0)
		for x in [-10, -2, 6]:
			draw_line(Vector2(x, -10), Vector2(x + 4, -10), dark, 1.0)
		# A rönk vége (évgyűrűkkel).
		draw_circle(Vector2(14, -6.5), 6.0, Color(0.62, 0.45, 0.28))
		draw_arc(Vector2(14, -6.5), 6.0, 0, TAU, 16, dark, 1.0)
		draw_arc(Vector2(14, -6.5), 3.0, 0, TAU, 12, Color(0.45, 0.3, 0.17), 1.0)


## Fegyverállvány a kiképzősátor előtt: néhány kard egy ládának támasztva.
func _training_sign(at: Vector2) -> void:
	var holder := Node2D.new()
	holder.position = at
	_entities.add_child(holder)
	var swords := [Rect2(339, 98, 10, 29), Rect2(307, 129, 10, 30), Rect2(307, 10, 10, 21)]
	for i in swords.size():
		var sword := _sprite(SpriteSheet.region(swords[i]), Vector2(-10 + i * 10, -30), 0, holder)
		sword.rotation = deg_to_rad(-12 + i * 12)
	var crate := AtlasTexture.new()
	crate.atlas = CONTAINERS
	crate.region = SMALL_CRATE
	_sprite(crate, Vector2(0, -12), 0, holder)
	_body(holder, Vector2(0, -6), Vector2(28, 12))


func _tent(top_left: Vector2i, kind: int) -> void:
	var holder := Node2D.new()
	# A sátor alja (talppontja) a y-rendezéshez.
	holder.position = Vector2(top_left + Vector2i(1, 2)) * TILE
	_entities.add_child(holder)
	for dx in 2:
		for dy in 2:
			var coords := TENTS[kind] + Vector2i(dx, dy)
			var offset := Vector2((dx - 0.5) * TILE, (dy - 1.5) * TILE)
			_rpg_sprite(coords, offset, 0, holder)
			_blocked[top_left + Vector2i(dx, dy)] = true
	_body(holder, Vector2(0, -14), Vector2(TILE * 2 - 8, 26))


func _campfire(at: Vector2) -> void:
	var holder := Node2D.new()
	holder.position = at + Vector2(0, 10)
	_entities.add_child(holder)
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 6.0)
	for coords in FIRE_FRAMES:
		var texture := AtlasTexture.new()
		texture.atlas = RPG
		texture.region = Rect2(Vector2(coords) * 17.0, Vector2(16, 16))
		frames.add_frame("default", texture)
	var fire := AnimatedSprite2D.new()
	fire.sprite_frames = frames
	fire.scale = Vector2(2, 2)
	fire.position = Vector2(0, -10)
	fire.play()
	holder.add_child(fire)
	# Meleg, pislákoló fény.
	var light := PointLight2D.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 0.75, 0.4))
	gradient.set_color(1, Color(0, 0, 0, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 512
	texture.height = 512
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	light.texture = texture
	light.texture_scale = 1.6
	light.energy = 1.3
	light.position = Vector2(0, -14)
	holder.add_child(light)
	var flicker := create_tween().set_loops()
	flicker.tween_property(light, "energy", 1.05, 0.18)
	flicker.tween_property(light, "energy", 1.4, 0.22)
	flicker.tween_property(light, "energy", 1.2, 0.15)
	# Szikrák.
	var sparks := CPUParticles2D.new()
	sparks.amount = 10
	sparks.lifetime = 1.4
	sparks.direction = Vector2(0, -1)
	sparks.spread = 25.0
	sparks.gravity = Vector2(0, -20)
	sparks.initial_velocity_min = 15.0
	sparks.initial_velocity_max = 35.0
	sparks.scale_amount_min = 1.5
	sparks.scale_amount_max = 2.5
	sparks.color = Color(1, 0.6, 0.2)
	sparks.position = Vector2(0, -18)
	holder.add_child(sparks)
	_body(holder, Vector2(0, -6), Vector2(24, 14))
	_blocked[Vector2i((at / TILE).floor())] = true


func _npc(at: Vector2) -> void:
	var npc := AnimatedSprite2D.new()
	npc.sprite_frames = SpriteSheet.character_frames(NPC_RECT, true)
	npc.scale = Vector2(2, 2)
	npc.offset = Vector2(0, -NPC_RECT.size.y / 2.0)
	npc.position = at
	npc.play("idle")
	_entities.add_child(npc)
	var body := StaticBody2D.new()
	npc.add_child(body)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	body.add_child(shape)


## Egy kellék (hordó, láda, korsó) a saját talppontjával, ütközővel.
func _prop(texture: Texture2D, region: Rect2, at: Vector2, solid := true) -> void:
	var holder := Node2D.new()
	holder.position = at + Vector2(0, region.size.y)
	_entities.add_child(holder)
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	_sprite(atlas, Vector2(0, -region.size.y), 0, holder)
	if solid:
		_body(holder, Vector2(0, -6), Vector2(region.size.x * 2 - 6, 12))


func _rpg_prop(coords: Vector2i, at: Vector2) -> void:
	var holder := Node2D.new()
	holder.position = at + Vector2(0, 14)
	_entities.add_child(holder)
	# A Kenney-fakupac világos; a földön sötétebb fában jobban látszik.
	_rpg_sprite(coords, Vector2(0, -14), 0, holder).modulate = Color(0.7, 0.5, 0.36)
	_body(holder, Vector2(0, -6), Vector2(24, 12))


## Fasor a tisztás szélén, és néhány fa, bokor, virág belül (a tábortól, úttól távol).
func _build_trees() -> void:
	for x in range(0, SIZE.x):
		for y in range(0, SIZE.y):
			var tile := Vector2i(x, y)
			if _blocked.has(tile) or HiddenGrave.keeps_clear(tile):
				continue
			var edge := mini(mini(x, SIZE.x - 1 - x), mini(y, SIZE.y - 1 - y))
			if (edge == 0 and randf() < 0.85) or (edge == 1 and randf() < 0.35):
				_tree(tile, randf() < 0.6, true)
	# A város tisztásának szélén is fasor (az épület és az út kimarad).
	var town := Town.RECT
	for x in range(town.position.x, town.end.x):
		for y in range(town.position.y, town.end.y):
			var tile := Vector2i(x, y)
			if _blocked.has(tile) or Town.blocked_rect().has_point(tile) or _castle_blocked(tile) \
					or Warehouse.blocked_rect().has_point(tile) \
					or Graveyard.blocked_rect().has_point(tile) or Chapel.blocked_rect().has_point(tile) \
					or Lake.blocked_rect().has_point(tile) or _near_path(tile):
				continue
			var edge := mini(mini(x - town.position.x, town.end.x - 1 - x), mini(y - town.position.y, town.end.y - 1 - y))
			if (edge == 0 and randf() < 0.85) or (edge == 1 and randf() < 0.3):
				_tree(tile, randf() < 0.6, true)
			elif x >= Town.OLD_END_X and edge >= 3:
				# A bővítés (keleti) része: rét, itt-ott virággal, bokorral.
				var roll := randf()
				if roll < 0.05:
					_rpg_sprite(FLOWERS.pick_random(), _tile_center(tile) + Vector2(randf_range(-8, 8), randf_range(-8, 8)), -9)
				elif roll < 0.065:
					_rpg_sprite(BUSHES.pick_random(), _tile_center(tile), 0)
	# A vár tisztásának szélén is fasor (az út és a vár kimarad).
	var castle := Castle.RECT
	for x in range(castle.position.x, castle.end.x):
		for y in range(castle.position.y, castle.end.y):
			var tile := Vector2i(x, y)
			if _blocked.has(tile) or _castle_blocked(tile) or _near_path(tile):
				continue
			var edge := mini(mini(x - castle.position.x, castle.end.x - 1 - x), mini(y - castle.position.y, castle.end.y - 1 - y))
			# A vár két oldalán (ahova úgysem lehet bemenni) sűrű erdő.
			var beside_castle := y <= Castle.GATE_ROW
			if (edge == 0 and randf() < 0.85) or (edge == 1 and randf() < 0.3) or (beside_castle and randf() < 0.6):
				_tree(tile, randf() < 0.6, true)
			elif edge >= 3 and randf() < 0.04:
				_rpg_sprite(FLOWERS.pick_random(), _tile_center(tile) + Vector2(randf_range(-8, 8), randf_range(-8, 8)), -9)
	# A bánya tisztásának szélén is fasor (a hegy és az út kimarad; a hegy körül a Mine rak fát), a réten virág.
	var mine := Mine.RECT
	for x in range(mine.position.x, mine.end.x):
		for y in range(mine.position.y, mine.end.y):
			var tile := Vector2i(x, y)
			if _blocked.has(tile) or Mine.mountain_rect().has_point(tile) or _near_path(tile):
				continue
			var edge := mini(mini(x - mine.position.x, mine.end.x - 1 - x), mini(y - mine.position.y, mine.end.y - 1 - y))
			if (edge == 0 and randf() < 0.85) or (edge == 1 and randf() < 0.3):
				_tree(tile, randf() < 0.6, true)
			elif edge >= 2 and randf() < 0.06:
				_rpg_sprite(FLOWERS.pick_random(), _tile_center(tile) + Vector2(randf_range(-8, 8), randf_range(-8, 8)), -9)
	# A nyugati tisztás szélén is fasor (az ösvény kimarad).
	var west := WEST_RECT
	for x in range(west.position.x, west.end.x):
		for y in range(west.position.y, west.end.y):
			var tile := Vector2i(x, y)
			if _blocked.has(tile) or _near_blocked(tile, 1) or Ruin.blocked_rect().has_point(tile):
				continue
			var edge := mini(mini(x - west.position.x, west.end.x - 1 - x), mini(y - west.position.y, west.end.y - 1 - y))
			if (edge == 0 and randf() < 0.85) or (edge == 1 and randf() < 0.3):
				_tree(tile, randf() < 0.6, true)
			elif edge >= 3 and randf() < 0.05:
				_rpg_sprite(FLOWERS.pick_random(), _tile_center(tile) + Vector2(randf_range(-8, 8), randf_range(-8, 8)), -9)
	var free_area := Rect2i(Vector2i(3, 3), SIZE - Vector2i(6, 6))
	for i in 110:
		var tile := Vector2i(randi_range(free_area.position.x, free_area.end.x), randi_range(free_area.position.y, free_area.end.y))
		if _near_blocked(tile, 2) or HiddenGrave.keeps_clear(tile):
			continue
		var roll := randf()
		if roll < 0.15:
			_tree(tile, randf() < 0.5, true)
		elif roll < 0.4:
			_rpg_sprite(BUSHES.pick_random(), _tile_center(tile), 0)
		else:
			_rpg_sprite(FLOWERS.pick_random(), _tile_center(tile) + Vector2(randf_range(-8, 8), randf_range(-8, 8)), -9)


## Sűrű erdő a tisztáson túl, ameddig a kamera ellát (beljebb egyre sötétebb).
## Ezeknek a fáknak nincs ütközőjük (oda úgysem lehet bemenni), az útra nem kerül fa.
func _build_forest() -> void:
	# A vár tisztása fölött (és körülötte) magasabbra nyúlik az erdő.
	var castle_forest := Rect2i(Castle.RECT.position - Vector2i(FOREST_DEPTH, FOREST_DEPTH),
		Castle.RECT.size + Vector2i(FOREST_DEPTH * 2, FOREST_DEPTH))
	# A bánya hegye körül is (keletre a világ széléig, hogy a kamera sehol ne lásson üres rétet).
	var mine_forest := Rect2i(Mine.RECT.position - Vector2i(FOREST_DEPTH, FOREST_DEPTH),
		Vector2i(WORLD_END_X - Mine.RECT.position.x + FOREST_DEPTH, Mine.RECT.size.y + FOREST_DEPTH))
	for x in range(WORLD_START_X, WORLD_END_X):
		for y in range(Castle.RECT.position.y - FOREST_DEPTH, SIZE.y + FOREST_DEPTH):
			var tile := Vector2i(x, y)
			if y < -FOREST_DEPTH and not castle_forest.has_point(tile) and not mine_forest.has_point(tile):
				continue
			if Rect2i(Vector2i.ZERO, SIZE).has_point(tile) or Town.RECT.has_point(tile) or WEST_RECT.has_point(tile) \
					or Castle.RECT.has_point(tile) or Mine.RECT.has_point(tile) or _is_path(tile) 					or HiddenGrave.keeps_clear(tile):
				continue
			if _is_path(tile + Vector2i.UP) or _is_path(tile + Vector2i.DOWN) or _is_path(tile + Vector2i.LEFT) \
					or _is_path(tile + Vector2i.RIGHT):
				if randf() < 0.6:
					continue
			# Hány csempére van a tisztás szélétől.
			var depth := mini(mini(mini(mini(_outside_distance(tile, Rect2i(Vector2i.ZERO, SIZE)), _outside_distance(tile, Town.RECT)),
				_outside_distance(tile, WEST_RECT)), _outside_distance(tile, Castle.RECT)), _outside_distance(tile, Mine.RECT))
			var shade := clampf(1.0 - depth * 0.06, 0.35, 1.0)
			var tree := _tree(tile, randf() < 0.75, false)
			tree.position += Vector2(randf_range(-8, 8), randf_range(-6, 6))
			tree.modulate = Color(shade, shade, shade * 1.05)


## Útjelző tábla az út mellett, a tisztás keleti szélén: "Város →" (a város felé mutat).
func _build_town_sign() -> void:
	var holder := _signpost(_tile_center(Vector2i(SIZE.x - 4, ROAD_ROW - 1)) + Vector2(0, 12), "Város",
		PackedVector2Array([Vector2(-46, -62), Vector2(40, -62), Vector2(56, -47), Vector2(40, -32), Vector2(-46, -32)]),
		Rect2(-46, -60, 90, 26))
	# Lebegő, csillogó nyíl a tábla fölött, a város felé.
	var label := MenuStyle.title_label("Város →", 26, MenuStyle.GOLD)
	label.size = Vector2(160, 32)
	label.position = Vector2(-80, -104)
	label.z_index = 5
	holder.add_child(label)
	var bob := label.create_tween().set_loops()
	bob.tween_property(label, "position:x", -72.0, 0.7).set_trans(Tween.TRANS_SINE)
	bob.tween_property(label, "position:x", -80.0, 0.7).set_trans(Tween.TRANS_SINE)


## Útjelző táblák a leágazásoknál, felfelé mutató (hegyes tetejű) deszkával: a királyi palotához vezető úton,
## a bánya útjának elején és a móló felé vezető ösvénynél. A deszka az út mellé kerül (nem lóg az útra).
func _build_signs() -> void:
	_branch_sign(Vector2i(Castle.PATH_COLUMN + 2, 8), "Királyi palota", true)
	_branch_sign(Vector2i(Mine.PATH_COLUMN + 2, ROAD_ROW - 1), "Bánya", true)
	_branch_sign(Vector2i(Lake.PIER_COLUMN, ROAD_ROW - 1), "Tó", false)


## Egy felfelé mutató tábla: `tile` az út melletti csempe (`east`: az út jobb oldalán, különben a bal oldalán).
func _branch_sign(tile: Vector2i, text: String, east: bool) -> void:
	var measure := UiStyle.label(text, 18, Color.BLACK)
	_entities.add_child(measure)
	var half := maxf(measure.get_minimum_size().x / 2.0 + 10.0, 26.0)
	measure.free()
	var x := tile.x * TILE + half + 4.0 if east else tile.x * TILE - half - 4.0
	_signpost(Vector2(x, (tile.y + 0.5) * TILE + 12), text,
		PackedVector2Array([Vector2(-half, -32), Vector2(-half, -60), Vector2(0, -72), Vector2(half, -60), Vector2(half, -32)]),
		Rect2(-half, -59, half * 2.0, 26))
	_blocked[tile] = true


## Fa útjelző tábla: oszlop, rajta a deszka (`board`: a körvonala, a hegye mutatja az irányt) a felirattal.
func _signpost(at: Vector2, text: String, board: PackedVector2Array, text_rect: Rect2) -> Node2D:
	var holder := Node2D.new()
	holder.position = at
	_entities.add_child(holder)
	_body(holder, Vector2(0, -4), Vector2(12, 8))
	var post := ColorRect.new()
	post.color = Color(0.36, 0.22, 0.12)
	post.size = Vector2(8, 52)
	post.position = Vector2(-4, -50)
	holder.add_child(post)
	var plank := Polygon2D.new()
	plank.polygon = board
	plank.color = Color(0.62, 0.42, 0.22)
	holder.add_child(plank)
	var rim := Line2D.new()
	rim.points = board
	rim.closed = true
	rim.width = 3.0
	rim.default_color = Color(0.3, 0.17, 0.08)
	holder.add_child(rim)
	var label := UiStyle.label(text, 18, Color(0.2, 0.1, 0.04))
	label.size = text_rect.size
	label.position = text_rect.position
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	holder.add_child(label)
	return holder


## Hány csempére van egy csempe a téglalapon kívül (0, ha benne van).
func _outside_distance(tile: Vector2i, rect: Rect2i) -> int:
	var dx := maxi(maxi(rect.position.x - tile.x, tile.x - rect.end.x + 1), 0)
	var dy := maxi(maxi(rect.position.y - tile.y, tile.y - rect.end.y + 1), 0)
	return maxi(dx, dy)


func _tree(tile: Vector2i, tall: bool, solid: bool) -> Node2D:
	var at := _tile_center(tile)
	var holder := Node2D.new()
	holder.position = at + Vector2(0, TILE / 2.0 - 4)
	_entities.add_child(holder)
	var index := randi() % TALL_TREES.size()
	if tall:
		_rpg_sprite(TALL_TREES[index], Vector2(0, -TILE / 2.0 + 4), 0, holder)
		_rpg_sprite(TALL_TREES[index] + Vector2i(0, -1), Vector2(0, -TILE * 1.5 + 4), 0, holder)
	else:
		_rpg_sprite(SMALL_TREES[index], Vector2(0, -TILE / 2.0 + 4), 0, holder)
	if solid:
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 9.0
		shape.shape = circle
		shape.position = Vector2(0, -6)
		body.add_child(shape)
		holder.add_child(body)
	return holder


## Láthatatlan fal a tisztás körül; az útnál nyílás, az út mentén folyosó az erdő széléig.
func _build_bounds() -> void:
	var area := Rect2(Vector2.ZERO, Vector2(SIZE) * TILE)
	var thickness := 64.0
	# Felül nyílás a rejtett ösvénynél (az ösvény és a tisztás falait a HiddenGrave rakja le).
	var trail_left := HiddenGrave.PATH_LEFT * TILE
	var trail_right := HiddenGrave.PATH_RIGHT * TILE
	_solid(Rect2(area.position - Vector2(thickness, thickness), Vector2(trail_left - area.position.x + thickness, thickness)))
	_solid(Rect2(Vector2(trail_right, area.position.y - thickness), Vector2(area.end.x + thickness - trail_right, thickness)))
	_solid(Rect2(Vector2(area.position.x - thickness, area.end.y), Vector2(area.size.x + thickness * 2, thickness)))
	# Jobb és bal oldal: nyílás az út / a nyugati ösvény sorainál.
	var gap_top := ROAD_ROW * TILE
	var gap_bottom := (ROAD_ROW + 2) * TILE
	_solid(Rect2(area.position - Vector2(thickness, 0), Vector2(thickness, gap_top)))
	_solid(Rect2(Vector2(area.position.x - thickness, gap_bottom), Vector2(thickness, area.size.y - gap_bottom)))
	_solid(Rect2(Vector2(area.end.x, 0), Vector2(thickness, gap_top)))
	_solid(Rect2(Vector2(area.end.x, gap_bottom), Vector2(thickness, area.size.y - gap_bottom)))
	# Az út folyosója az erdőn át a városig.
	var town := Rect2(Vector2(Town.RECT.position) * TILE, Vector2(Town.RECT.size) * TILE)
	_solid(Rect2(Vector2(area.end.x, gap_top - thickness), Vector2(town.position.x - area.end.x, thickness)))
	_solid(Rect2(Vector2(area.end.x, gap_bottom), Vector2(town.position.x - area.end.x, thickness)))
	# A város tisztása körül (nyugaton nyílás az útnál, északon a vár felé vezető útnál;
	# keleten egyelőre zárva).
	var castle_gap_left := Castle.PATH_COLUMN * TILE
	var castle_gap_right := (Castle.PATH_COLUMN + 2) * TILE
	_solid(Rect2(town.position - Vector2(thickness, thickness), Vector2(castle_gap_left - town.position.x + thickness, thickness)))
	var mine_gap_left := Mine.PATH_COLUMN * TILE
	var mine_gap_right := (Mine.PATH_COLUMN + 2) * TILE
	_solid(Rect2(Vector2(castle_gap_right, town.position.y - thickness), Vector2(mine_gap_left - castle_gap_right, thickness)))
	_solid(Rect2(Vector2(mine_gap_right, town.position.y - thickness), Vector2(town.end.x + thickness - mine_gap_right, thickness)))
	# A bánya útja: folyosó az erdőn át a város északi falának nyílásától, fent a tisztás a hegy előtt (alul nyílás).
	var mine := Rect2(Vector2(Mine.RECT.position) * TILE, Vector2(Mine.RECT.size) * TILE)
	_solid(Rect2(Vector2(mine_gap_left - thickness, mine.end.y), Vector2(thickness, town.position.y - mine.end.y)))
	_solid(Rect2(Vector2(mine_gap_right, mine.end.y), Vector2(thickness, town.position.y - mine.end.y)))
	_solid(Rect2(mine.position - Vector2(thickness, thickness), Vector2(mine.size.x + thickness * 2, thickness)))
	_solid(Rect2(Vector2(mine.position.x - thickness, mine.position.y), Vector2(thickness, mine.size.y)))
	_solid(Rect2(Vector2(mine.end.x, mine.position.y), Vector2(thickness, mine.size.y)))
	_solid(Rect2(Vector2(mine.position.x - thickness, mine.end.y), Vector2(mine_gap_left - mine.position.x + thickness, thickness)))
	_solid(Rect2(Vector2(mine_gap_right, mine.end.y), Vector2(mine.end.x + thickness - mine_gap_right, thickness)))
	# A vár tisztása közvetlenül a város fölött (délen a város északi fala zárja, az útnál nyitva).
	var castle := Rect2(Vector2(Castle.RECT.position) * TILE, Vector2(Castle.RECT.size) * TILE)
	_solid(Rect2(castle.position - Vector2(thickness, thickness), Vector2(castle.size.x + thickness * 2, thickness)))
	_solid(Rect2(Vector2(castle.position.x - thickness, castle.position.y), Vector2(thickness, castle.size.y)))
	_solid(Rect2(Vector2(castle.end.x, castle.position.y), Vector2(thickness, castle.size.y)))
	_solid(Rect2(Vector2(town.position.x - thickness, town.end.y), Vector2(town.size.x + thickness * 2, thickness)))
	_solid(Rect2(Vector2(town.end.x, town.position.y), Vector2(thickness, town.size.y)))
	_solid(Rect2(Vector2(town.position.x - thickness, town.position.y), Vector2(thickness, gap_top - town.position.y)))
	_solid(Rect2(Vector2(town.position.x - thickness, gap_bottom), Vector2(thickness, town.end.y - gap_bottom)))
	# A nyugati ösvény folyosója, és a nyugati tisztás (keleten nyílás az ösvénynél).
	var west := Rect2(Vector2(WEST_RECT.position) * TILE, Vector2(WEST_RECT.size) * TILE)
	_solid(Rect2(Vector2(west.end.x, gap_top - thickness), Vector2(-west.end.x, thickness)))
	_solid(Rect2(Vector2(west.end.x, gap_bottom), Vector2(-west.end.x, thickness)))
	_solid(Rect2(west.position - Vector2(thickness, thickness), Vector2(west.size.x + thickness * 2, thickness)))
	_solid(Rect2(Vector2(west.position.x - thickness, west.end.y), Vector2(west.size.x + thickness * 2, thickness)))
	_solid(Rect2(Vector2(west.position.x - thickness, west.position.y), Vector2(thickness, west.size.y)))
	_solid(Rect2(Vector2(west.end.x, west.position.y), Vector2(thickness, gap_top - west.position.y)))
	_solid(Rect2(Vector2(west.end.x, gap_bottom), Vector2(thickness, west.end.y - gap_bottom)))


## Melyik helyszín zenéje szól itt (lásd Audio.PLACE_TRACKS): a bánya (a tisztás is) és a kút alja: "cave";
## a város, a vár és a városi házak belseje: "town"; minden más (a tábor, a nyugati tisztás, a rom, a bolt): "camp".
static func music_place(at: Vector2) -> String:
	var tile := Vector2i((at / TILE).floor())
	if tile.x >= Mine.BOUNDS.position.x - 4 or Mine.RECT.grow(2).has_point(tile) or WellCave.BOUNDS.has_point(tile):
		return "cave"
	# A kocsma belseje, a folyosó és a szobák (x 200-tól) egy tömbben.
	var town: Array[Rect2i] = [Town.RECT, Castle.RECT, Rect2i(196, -5, 40, 52), Castle.THRONE_ROOM.grow(4),
		Chapel.INTERIOR.grow(4), Hospital.INTERIOR.grow(4), Warehouse.INTERIOR.grow(4)]
	for area in town:
		if area.has_point(tile):
			return "town"
	return "camp"


## Átlépés egy másik helyre elsötétüléssel (pl. be a kocsmába): `limits` a kamera határai
## (üres = a szabadtéri határok), `light` a szín-hangulat (fekete = az esti szürkület).
func teleport_player(at: Vector2, limits: Rect2, light: Color) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.25)
	await tween.finished
	_player.global_position = at
	var camera: Camera2D = _player.get_node("Camera2D")
	if limits.has_area():
		camera.limit_left = int(limits.position.x)
		camera.limit_top = int(limits.position.y)
		camera.limit_right = int(limits.end.x)
		camera.limit_bottom = int(limits.end.y)
	else:
		_setup_camera()
	camera.reset_smoothing()
	$CanvasModulate.color = EVENING if light == Color.BLACK else light
	create_tween().tween_property(_fade, "color:a", 0.0, 0.3)


## Rövid felirat a képernyő közepén (pl. a kocsmáros szavai), ami magától elhalványul.
func _toast(text: String) -> void:
	if _toast_label == null:
		var layer := CanvasLayer.new()
		layer.layer = 6
		add_child(layer)
		_toast_label = Label.new()
		_toast_label.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
		_toast_label.add_theme_font_size_override("font_size", 24)
		_toast_label.add_theme_color_override("font_color", MenuStyle.PARCHMENT)
		_toast_label.add_theme_color_override("font_outline_color", MenuStyle.SHADOW)
		_toast_label.add_theme_constant_override("outline_size", 8)
		_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		_toast_label.offset_top = 150
		_toast_label.offset_left = -600
		_toast_label.offset_right = 600
		layer.add_child(_toast_label)
	_toast_label.text = text
	_toast_label.modulate.a = 1.0
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(3.0)
	_toast_tween.tween_property(_toast_label, "modulate:a", 0.0, 0.8)


## A kamera nem lát túl az erdő szélén (ott már nincs semmi).
func _setup_camera() -> void:
	var camera: Camera2D = _player.get_node("Camera2D")
	camera.limit_left = WORLD_START_X * TILE
	camera.limit_top = (Castle.RECT.position.y - FOREST_DEPTH) * TILE
	camera.limit_right = WORLD_END_X * TILE
	camera.limit_bottom = (SIZE.y + FOREST_DEPTH) * TILE


## Szentjánosbogarak az esti fűben.
func _build_fireflies() -> void:
	var flies := CPUParticles2D.new()
	flies.amount = 50
	flies.lifetime = 6.0
	flies.preprocess = 6.0
	flies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	flies.emission_rect_extents = Vector2(SIZE) * TILE / 2.0
	flies.position = Vector2(SIZE) * TILE / 2.0
	flies.gravity = Vector2.ZERO
	flies.direction = Vector2(0, -1)
	flies.spread = 180.0
	flies.initial_velocity_min = 5.0
	flies.initial_velocity_max = 18.0
	flies.scale_amount_min = 2.0
	flies.scale_amount_max = 3.0
	var fade := Gradient.new()
	fade.set_color(0, Color(0.8, 1.0, 0.4, 0.0))
	fade.add_point(0.5, Color(0.85, 1.0, 0.45, 1.0))
	fade.set_color(fade.get_point_count() - 1, Color(0.8, 1.0, 0.4, 0.0))
	flies.color_ramp = fade
	flies.z_index = 5
	add_child(flies)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_prompt = MenuStyle.title_label("[E] Leszállás a mélybe", 34, MenuStyle.GOLD)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -150
	_prompt.offset_bottom = -100
	_prompt.offset_left = -300
	_prompt.offset_right = 300
	_prompt.modulate.a = 0.0
	layer.add_child(_prompt)
	# Jobb felül: a táborban váró arany (ebből lehet fejleszteni).
	var gold_box := HBoxContainer.new()
	gold_box.add_theme_constant_override("separation", 10)
	gold_box.alignment = BoxContainer.ALIGNMENT_END
	gold_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	gold_box.offset_left = -640
	gold_box.offset_right = -28
	gold_box.offset_top = 24
	layer.add_child(gold_box)
	var gold_title := Label.new()
	gold_title.text = "Tábori kincs:"
	gold_title.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	gold_title.add_theme_font_size_override("font_size", 24)
	gold_title.add_theme_color_override("font_color", MenuStyle.PARCHMENT)
	gold_title.add_theme_color_override("font_outline_color", MenuStyle.SHADOW)
	gold_title.add_theme_constant_override("outline_size", 6)
	gold_box.add_child(gold_title)
	var coin := TextureRect.new()
	coin.texture = SpriteSheet.region(Rect2(289, 385, 6, 7))
	coin.custom_minimum_size = Vector2(24, 28)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	gold_box.add_child(coin)
	_gold_label = gold_title.duplicate()
	_gold_label.add_theme_color_override("font_color", MenuStyle.GOLD)
	gold_box.add_child(_gold_label)
	_update_gold()
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)
	create_tween().tween_property(_fade, "color:a", 0.0, 0.6)


func _show_title() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	var title := MenuStyle.title_label("Tábor — pihenő" if _on_break else "Tábor", 72, MenuStyle.GOLD)
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.offset_top = 40
	title.offset_left = -300
	title.offset_right = 300
	layer.add_child(title)
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(title, "modulate:a", 0.0, 1.0)
	# A Vérfarkas (vagy a Káosz Ura) után egyszer: győzelmi felirat.
	if GameState.dungeon_won:
		GameState.dungeon_won = false
		var text := "Legyőzted a Káosz Urát! A 40. emelet elcsendesedett." if GameState.won_lord == "chaos" \
			else "Leállítottad az Ősgépezetet! A 60. emelet elnémult." if GameState.won_lord == "engine" \
			else "Legyőzted a Pokolkapu Őrét! A pokol kapuja nyitva áll." if GameState.won_lord == "gate" \
			else "Legyőzted Lucifert, a Démonkirályt! A pokol tüzei kialudtak." if GameState.won_lord == "lucifer" \
			else "Végigértél a kazamatán! A Mélység Ura elesett."
		var won := MenuStyle.title_label(text, 40, Color(1, 0.85, 0.4))
		won.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		won.offset_top = 130
		won.offset_left = -500
		won.offset_right = 500
		won.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		layer.add_child(won)
		var fade := create_tween()
		fade.tween_interval(5.0)
		fade.tween_property(won, "modulate:a", 0.0, 1.5)


func _process(delta: float) -> void:
	# A zene a helyszínhez igazodik (fél mp-enként nézi; ha a szóló szám az új helyen is szólhat, marad).
	_music_left -= delta
	if _music_left <= 0.0:
		_music_left = MUSIC_CHECK
		Audio.music(music_place(_player.global_position))
	# Gáspár elköszönt (30. emelet): amint bezárult a beszélgetés, elindul a kocsmába.
	if is_instance_valid(_veteran_sprite) and not _veteran_walking and not GamePause.active(get_tree()) \
			and Progress.npc_quest_state(Dialogues.TAVERN_FLAG) == "done":
		_start_gaspar_walk()
	var near_stairs := _is_near_stairs()
	var near_tent := _is_near_tent()
	var near_stash := _is_near_stash()
	var near_npc := _is_near_npc()
	var near_veteran := _is_near_veteran()
	var near_block := _player.global_position.distance_to(_road_block_position) < 90.0
	var near_bestiary := _is_near_bestiary()
	var near_item_book := _is_near_item_book()
	var near_achievements := _is_near_achievements()
	var near_smith := _is_near_smith()
	var any_near := near_stairs or near_tent or near_stash or near_npc or near_veteran or near_block or near_bestiary \
		or near_smith or near_item_book or near_achievements
	if near_smith:
		_prompt.text = "[E] Kovács — tárgyfejlesztés, szétszedés"
	elif near_veteran:
		_prompt.text = "[E] Beszélgetés: %s" % Dialogues.VETERAN_NAME
	elif near_bestiary:
		_prompt.text = "[E] Szörnyek könyve"
	elif near_item_book:
		_prompt.text = "[E] Tárgyak könyve"
	elif near_achievements:
		_prompt.text = "[E] Eredmények könyve"
	elif near_block:
		_prompt.text = "Pihenő közben nem mehetsz a városba"
	elif near_stairs:
		_prompt.text = "A kazamata lezárva — a kék portálon át folytathatod" if _on_break else "[E] Leszállás a mélybe"
	elif near_tent:
		_prompt.text = "Kiképzősátor — pihenő közben zárva" if _on_break else "[E] Kiképzősátor"
	elif near_stash:
		_prompt.text = "Tábori láda — pihenő közben zárva" if _on_break \
			else "[E] Tábori láda (%d tárgy)" % Progress.stash.size()
	elif near_npc:
		_prompt.text = "[E] Zoltán, a vándorárus" if _on_break else "Zoltán: \"Majd ha visszajössz a mélyből...\""
	var target := 1.0 if any_near and not _leaving and not GamePause.active(get_tree()) else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)
	_update_gold()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or _leaving or GamePause.active(get_tree()):
		return
	# A veteránnal pihenő közben is lehet beszélgetni.
	if _is_near_veteran():
		get_viewport().set_input_as_handled()
		Audio.play("ui_open")
		$Menus.open_menu(_veteran_dialogue)
		return
	# A Szörnyek könyve is mindig olvasható.
	if _is_near_bestiary():
		get_viewport().set_input_as_handled()
		$Menus.open_menu(_bestiary_book)
		return
	if _is_near_item_book():
		get_viewport().set_input_as_handled()
		$Menus.open_menu(_item_book)
		return
	if _is_near_achievements():
		get_viewport().set_input_as_handled()
		$Menus.open_menu(_achievement_book)
		return
	# A kovács pihenő közben is dolgozik (akkor a futás felszerelésével).
	if _is_near_smith():
		get_viewport().set_input_as_handled()
		Audio.play("anvil", -4.0)
		$Menus.open_menu(_smith_panel)
		return
	var near_something := _is_near_stairs() or _is_near_tent() or _is_near_stash() or _is_near_npc()
	if not near_something:
		return
	get_viewport().set_input_as_handled()
	if _on_break:
		# Pihenő közben csak az árus használható (a kazamatába a kék portál visz vissza).
		if _is_near_npc():
			Audio.play("ui_open")
			$Menus.open_menu(_merchant_panel)
		else:
			Audio.play("ui_error")
		return
	if _is_near_stairs():
		_enter_dungeon()
	elif _is_near_tent():
		Audio.play("door_unlock", -6.0)
		$Menus.open_menu(_upgrades_panel)
	elif _is_near_stash():
		Audio.play("chest_open", -4.0)
		$Menus.open_menu(_stash_panel)


func _is_near_veteran() -> bool:
	return is_instance_valid(_player) and _player.global_position.distance_to(_veteran_position) < VETERAN_RANGE


func _is_near_bestiary() -> bool:
	return is_instance_valid(_player) and _player.global_position.distance_to(_bestiary_position) < INTERACT_RANGE


func _is_near_item_book() -> bool:
	return is_instance_valid(_player) and _player.global_position.distance_to(_item_book_position) < INTERACT_RANGE


func _is_near_achievements() -> bool:
	return is_instance_valid(_player) and _player.global_position.distance_to(_achievement_position) < INTERACT_RANGE


func _is_near_smith() -> bool:
	return is_instance_valid(_player) and _player.global_position.distance_to(_smith_position) < INTERACT_RANGE


func _is_near_npc() -> bool:
	return is_instance_valid(_player) and _player.global_position.distance_to(_npc_position) < INTERACT_RANGE


func _is_near_stash() -> bool:
	return is_instance_valid(_player) and _player.global_position.distance_to(_stash_position) < INTERACT_RANGE


func _is_near_tent() -> bool:
	return is_instance_valid(_player) and _player.global_position.distance_to(_training_tent_position) < INTERACT_RANGE + 10.0


func _update_gold() -> void:
	if _gold_label:
		_gold_label.text = str(Progress.camp_gold)
		# Pihenő közben a futás pénze is látszik (ezt költheted az árusnál).
		if _on_break:
			_gold_label.text += "   ·   Nálad: %d" % int(_player.get("gold"))


func _is_near_stairs() -> bool:
	return is_instance_valid(_player) and _player.global_position.distance_to(_stairs_position) < INTERACT_RANGE


## Új futás indul az 1. emeletről.
## Csalás (CheatMenu): leszállás egyenesen a megadott emeletre. Pihenő közben nem megy.
func cheat_teleport(target_depth: int) -> bool:
	if _on_break or _leaving:
		return false
	_enter_dungeon(target_depth, true)
	return true


## Csalás (CheatMenu): karakterváltás a kocsma nélkül (a zárolt karakterekre is).
func cheat_select_character(id: String) -> bool:
	if _on_break or _leaving:
		return false
	return _town.cheat_switch_to(id)


func _enter_dungeon(start_depth := 1, cheat := false) -> void:
	# A tábori bemutató (gyakorlás) a lépcsőnél ér véget.
	if GameState.tutorial:
		var guide := get_node_or_null("TutorialGuide")
		if guide != null:
			guide.call("finish")
		return
	# Közös játékban a gazda indítja a lejutást, és a táborban lévők együtt mennek le
	# (NetLobby._descend → enter_dungeon_now).
	if NetLobby.is_playing(get_tree()) and not cheat:
		if not _leaving:
			NetLobby.current(get_tree()).request_descent(start_depth)
		return
	_enter_dungeon_now(start_depth, cheat)


## A lejutás közös játékban (mindenkinél, aki a táborban van; a NetLobby hívja).
func enter_dungeon_now(start_depth: int) -> void:
	if not _leaving:
		_enter_dungeon_now(start_depth, false)


## A próbatétel indítása (a bánya mélyén, a lyuk lépcsőjénél; lásd Mine és ChallengePanel).
func enter_challenge(challenge: Dictionary) -> void:
	if not _leaving:
		_enter_dungeon_now(1, false, challenge)


func _enter_dungeon_now(start_depth: int, cheat: bool, challenge := {}) -> void:
	_leaving = true
	# A nyitott ablakok (táska, könyv...) bezárulnak, és a játék sem marad megállítva.
	get_node("Menus").call("close_current")
	GamePause.set_paused(get_tree(), false)
	Audio.play("stairs")
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.5)
	await tween.finished
	GameState.reset()
	GameState.depth = start_depth
	GameState.challenge = challenge.duplicate(true)
	if cheat:
		GameState.cheated = true
	else:
		# Ha kialudtad magad a kocsmai szobádban: extra bájital (egyszer).
		GameState.potions += Town.take_rest_bonus()
	# A nálad lévő felszereléssel szállsz le; az a táborból "elfogy" (a futásban veszhet el).
	GameState.saved_inventory = _player.get_node("Inventory").save_data()
	Progress.camp_inventory = {}
	Progress.save_game()
	get_tree().change_scene_to_file(DUNGEON_SCENE)


func _castle_blocked(tile: Vector2i) -> bool:
	for rect in Castle.blocked_rects():
		if rect.has_point(tile):
			return true
	return false


## Az út melletti csempe (ide se kerüljön ütköző fa, hogy kényelmesen el lehessen menni).
func _near_path(tile: Vector2i) -> bool:
	return _is_path(tile + Vector2i.LEFT) or _is_path(tile + Vector2i.RIGHT)


func _near_blocked(tile: Vector2i, radius: int) -> bool:
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if _blocked.has(tile + Vector2i(dx, dy)):
				return true
	return false


func _tile_center(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE


func _sprite(texture: Texture2D, at: Vector2, z: int, parent: Node = self) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(2, 2)
	sprite.position = at
	sprite.z_index = z
	parent.add_child(sprite)
	return sprite


## Egy csempe a Kenney RPG lapról (16 px + 1 px hézag).
func _rpg_sprite(coords: Vector2i, at: Vector2, z: int, parent: Node = null) -> Sprite2D:
	var texture := AtlasTexture.new()
	texture.atlas = RPG
	texture.region = Rect2(Vector2(coords) * 17.0, Vector2(16, 16))
	return _sprite(texture, at, z, parent if parent else _entities)


## Ütköző egy kellék / sátor aljához.
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
