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
## Esti szürkület.
const EVENING := Color(0.26, 0.3, 0.48)

## A tábor elrendezése (csempékben).
const STAIRS_TILE := Vector2i(22, 7)
const FIRE_TILE := Vector2i(22, 17)
const CAMP_RADIUS := Vector2(9.5, 6.0)
## Az út sorai (2 csempe széles), keletre a tábortól az erdő széléig.
const ROAD_ROW := 17

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
var _blocked := {}
## A kiképzősátor bejárata (a jobb oldali sátor eleje): itt E-re nyílik a fejlesztés-ablak.
var _training_tent_position := Vector2.ZERO
var _upgrades_panel: CanvasLayer
## A tábori láda helye (E-re nyílik a láda ablaka).
var _stash_position := Vector2.ZERO
var _stash_panel: CanvasLayer
var _merchant_panel: CanvasLayer
var _npc_position := Vector2.ZERO
## Pihenő közben (főellenség után kimentél) vagy.
var _on_break := false
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
	Audio.music("menu")
	GameCursor.apply()
	$CanvasModulate.color = EVENING
	# A szabad ég alatt a lovag "lámpása" halványabb, hogy esti hangulata legyen.
	_player.get_node("PointLight2D").energy = 0.5
	_build_ground()
	_build_entrance()
	_build_dirt()
	_build_camp()
	_build_trees()
	_build_forest()
	_build_bounds()
	_build_fireflies()
	_build_ui()
	_upgrades_panel = CAMP_UPGRADES.new()
	_upgrades_panel.name = "CampUpgrades"
	add_child(_upgrades_panel)
	_stash_panel = STASH_PANEL.new()
	_stash_panel.name = "StashPanel"
	add_child(_stash_panel)
	_merchant_panel = MERCHANT_PANEL.new()
	_merchant_panel.name = "MerchantPanel"
	add_child(_merchant_panel)
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


## Pihenő: rács a lépcsőn, kék portál a lépcső mellett (vissza a kazamatába, a következő emeletre).
func _setup_break() -> void:
	_stairs_node.call("set_locked", true)
	var portal: Node2D = RETURN_PORTAL.new()
	portal.prompt_text = "[E] Vissza a kazamatába (%d. emelet)" % (GameState.depth + 1)
	portal.on_use = _return_to_dungeon
	portal.position = _tile_center(STAIRS_TILE + Vector2i(5, 1))
	add_child(portal)
	_player.global_position = portal.position + Vector2(0, 50)


## Ha pihenő közben bezárod a játékot, az a futás feladása: a pénzed 40%-a a táborba kerül.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and GameState.on_break and is_instance_valid(_player):
		Records.submit_run(_player)
		Progress.rescue_gold(int(_player.get("gold")) + GameState.break_gold_left, 0.4)


## Vissza a kazamatába a pihenőből: a futás a következő emeletről folytatódik, minden
## megmarad (a bent hagyott pénzt is visszakapod).
func _return_to_dungeon() -> void:
	if _leaving:
		return
	_leaving = true
	Audio.play("stairs")
	_player.call("save_state")
	GameState.saved_gold += GameState.break_gold_left
	GameState.break_gold_left = 0
	GameState.on_break = false
	GameState.depth += 1
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
	for x in range(-FOREST_DEPTH, SIZE.x + FOREST_DEPTH):
		for y in range(-FOREST_DEPTH, SIZE.y + FOREST_DEPTH):
			_ground.set_cell(Vector2i(x, y), GRASS_SOURCE, Vector2i(randi() % GRASS_TILES.size(), 0))


## A kazamata bejárata: kőpadló, rajta a lefelé vezető lépcső.
func _build_entrance() -> void:
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
	# Az út: a tisztáson kicsit kanyarog, az erdőben egyenesen megy tovább.
	for x in range(FIRE_TILE.x + 5, SIZE.x + FOREST_DEPTH):
		var row := ROAD_ROW
		if x < SIZE.x - 2:
			row += roundi(sin(x * 0.45) * 1.0)
		_dirt[Vector2i(x, row)] = true
		_dirt[Vector2i(x, row + 1)] = true
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(16, 16)
	var source := TileSetAtlasSource.new()
	source.texture = RPG
	source.texture_region_size = Vector2i(16, 16)
	source.separation = Vector2i(1, 1)
	tile_set.add_source(source, DIRT_SOURCE)
	for coords: Vector2i in DIRT.values():
		source.create_tile(coords)
	_dirt_layer.tile_set = tile_set
	for cell: Vector2i in _dirt:
		_dirt_layer.set_cell(cell, DIRT_SOURCE, DIRT[_dirt_piece(cell)])
		_blocked[cell] = true


## A szomszédok alapján melyik szélezett földdarab kell (a széle lekerekített).
func _dirt_piece(cell: Vector2i) -> String:
	var up := _dirt.has(cell + Vector2i.UP)
	var down := _dirt.has(cell + Vector2i.DOWN)
	var left := _dirt.has(cell + Vector2i.LEFT)
	var right := _dirt.has(cell + Vector2i.RIGHT)
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
	_blocked[FIRE_TILE] = true


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
			if _blocked.has(tile):
				continue
			var edge := mini(mini(x, SIZE.x - 1 - x), mini(y, SIZE.y - 1 - y))
			if (edge == 0 and randf() < 0.85) or (edge == 1 and randf() < 0.35):
				_tree(tile, randf() < 0.6, true)
	var free_area := Rect2i(Vector2i(3, 3), SIZE - Vector2i(6, 6))
	for i in 110:
		var tile := Vector2i(randi_range(free_area.position.x, free_area.end.x), randi_range(free_area.position.y, free_area.end.y))
		if _near_blocked(tile, 2):
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
	for x in range(-FOREST_DEPTH, SIZE.x + FOREST_DEPTH):
		for y in range(-FOREST_DEPTH, SIZE.y + FOREST_DEPTH):
			var tile := Vector2i(x, y)
			if Rect2i(Vector2i.ZERO, SIZE).has_point(tile) or _dirt.has(tile):
				continue
			if _dirt.has(tile + Vector2i.UP) or _dirt.has(tile + Vector2i.DOWN):
				if randf() < 0.6:
					continue
			# Hány csempére van a tisztás szélétől.
			var depth := maxi(maxi(-x, x - SIZE.x + 1), maxi(-y, y - SIZE.y + 1))
			var shade := clampf(1.0 - depth * 0.06, 0.35, 1.0)
			var tree := _tree(tile, randf() < 0.75, false)
			tree.position += Vector2(randf_range(-8, 8), randf_range(-6, 6))
			tree.modulate = Color(shade, shade, shade * 1.05)


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
	_solid(Rect2(area.position - Vector2(thickness, thickness), Vector2(area.size.x + thickness * 2, thickness)))
	_solid(Rect2(Vector2(area.position.x - thickness, area.end.y), Vector2(area.size.x + thickness * 2, thickness)))
	_solid(Rect2(area.position - Vector2(thickness, 0), Vector2(thickness, area.size.y)))
	# Jobb oldal: nyílás az út sorainál.
	var gap_top := ROAD_ROW * TILE
	var gap_bottom := (ROAD_ROW + 2) * TILE
	_solid(Rect2(Vector2(area.end.x, 0), Vector2(thickness, gap_top)))
	_solid(Rect2(Vector2(area.end.x, gap_bottom), Vector2(thickness, area.size.y - gap_bottom)))
	var road_end := (SIZE.x + FOREST_DEPTH) * TILE
	_solid(Rect2(Vector2(area.end.x, gap_top - thickness), Vector2(road_end - area.end.x, thickness)))
	_solid(Rect2(Vector2(area.end.x, gap_bottom), Vector2(road_end - area.end.x, thickness)))
	_solid(Rect2(Vector2(road_end - TILE, gap_top), Vector2(TILE, gap_bottom - gap_top)))


## A kamera nem lát túl az erdő szélén (ott már nincs semmi).
func _setup_camera() -> void:
	var camera: Camera2D = _player.get_node("Camera2D")
	camera.limit_left = -FOREST_DEPTH * TILE
	camera.limit_top = -FOREST_DEPTH * TILE
	camera.limit_right = (SIZE.x + FOREST_DEPTH) * TILE
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
	var hint := Label.new()
	hint.text = "WASD — mozgás   ·   I — felszerelés   ·   Tab — karakter   ·   Esc — szünet"
	hint.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.8, 0.78, 0.7, 0.75))
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_top = -40
	hint.offset_bottom = -16
	hint.offset_left = -400
	hint.offset_right = 400
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(hint)
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


func _process(delta: float) -> void:
	var near_stairs := _is_near_stairs()
	var near_tent := _is_near_tent()
	var near_stash := _is_near_stash()
	var near_npc := _is_near_npc()
	var any_near := near_stairs or near_tent or near_stash or near_npc
	if near_stairs:
		_prompt.text = "A kazamata lezárva — a kék portálon át folytathatod" if _on_break else "[E] Leszállás a mélybe"
	elif near_tent:
		_prompt.text = "Kiképzősátor — pihenő közben zárva" if _on_break else "[E] Kiképzősátor"
	elif near_stash:
		_prompt.text = "Tábori láda — pihenő közben zárva" if _on_break \
			else "[E] Tábori láda (%d tárgy)" % Progress.stash.size()
	elif near_npc:
		_prompt.text = "[E] Zoltán, a vándorárus" if _on_break else "Zoltán: \"Majd ha visszajössz a mélyből...\""
	var target := 1.0 if any_near and not _leaving and not get_tree().paused else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)
	_update_gold()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or _leaving or get_tree().paused:
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
func _enter_dungeon() -> void:
	_leaving = true
	Audio.play("stairs")
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.5)
	await tween.finished
	GameState.reset()
	# A nálad lévő felszereléssel szállsz le; az a táborból "elfogy" (a futásban veszhet el).
	GameState.saved_inventory = _player.get_node("Inventory").save_data()
	Progress.camp_inventory = {}
	Progress.save_game()
	get_tree().change_scene_to_file(DUNGEON_SCENE)


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
