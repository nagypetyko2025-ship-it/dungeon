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
## A 21. emelettől (a második erősödéssel) még nagyobb termek és még több szörny.
## (A rácscella magassága úgy van megválasztva, hogy a pálya ne érjen le a bolthoz: y = 300.)
const HUGE_ROOMS_FROM := 21
const HUGE_CELL := Vector2i(32, 23)
const HUGE_ROOM_WIDTH := Vector2i(20, 25)
const HUGE_ROOM_HEIGHT := Vector2i(14, 17)
const HUGE_ROOM_EXTRA_ENEMIES := 7
const HUGE_MAX_ENEMIES := 20
const HUGE_BOSS_ROOM_SIZE := Vector2i(25, 17)
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
const QUEST_BOOK := preload("res://ui/quest_book.gd")
## A gyakorló pálya szobái balról jobbra, mindegyik egy leckéhez (lásd TutorialGuide): kezdőszoba, harc
## + láda, csapdák + képesség, bolt + tárgylift, gyakorló üllő, különleges szörnyek, főellenség-terem.
const TUTORIAL_CELLS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0)]
## A szobák tartalma ugyanilyen sorrendben: a szörnyek (fajtánként), csapdák, láda.
const TUTORIAL_ROOMS: Array[Dictionary] = [
	{},
	{"enemies": ["tiny_zombie", "tiny_zombie", "tiny_zombie"], "chest": true},
	{"enemies": ["skelet", "skelet", "tiny_zombie"], "traps": 3},
	{},
	{},
	{"enemies": ["archer", "imp", "tiny_zombie"]},
	{},
]
const TUTORIAL_SHOP_ROOM := 3
const TUTORIAL_ANVIL_ROOM := 4
const BOSS_ROOM_SIZE := Vector2i(15, 11)
## Az utolsó, 20. emelet: csak a kezdőszoba és a Vérfarkas nagy terme (tőle keletre).
const FINAL_DEPTH := 20
const FINAL_START_ROOM := Rect2i(-6, -5, 13, 11)
const FINAL_ARENA_SIZE := Vector2i(31, 21)
## Gáspár elesett embereinek csontvázai a 20. emeleten (az aréna és a kezdőszoba).
const FINAL_ARENA_GUARDS := 9
const FINAL_START_GUARDS := 3
## A Káosz Ura emelete: ugyanilyen (kezdőszoba és tőle keletre a nagy terem), csak Gáspár emberei nélkül.
const CHAOS_DEPTH := 40
## A Vérfarkas utáni lépcső helye a terem közepétől (csempe, keletre a portáltól).
const DEEPER_STAIRS_OFFSET := 6
## Gáspár második küldetésének célja.
const QUEST_DEPTH := 30
const VICTORY_PANEL := preload("res://ui/victory_panel.gd")
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
var _huge_rooms := false
## Az emelet generálásának magja (egyjátékosban): a pihenőből visszatérve ebből épül újra pontosan
## ugyanez az emelet (lásd break_snapshot). Közös játékban a gazda magja (net_seed) dönt.
var _floor_seed := 0
## Melyik nagy főellenség esett el ezen az emeleten (a győzelmi ablak szövegéhez).
var _victory_lord := "werewolf"

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
	Audio.music("epic")
	GameCursor.apply()
	var tile_set := _build_tile_set()
	_floor_layer.tile_set = tile_set
	_wall_layer.tile_set = tile_set

	var depth := GameState.depth
	# Pihenőből visszatérve (a főellenség után a táborba mentél): ugyanez az emelet, a kitisztított
	# szobákkal, és ugyanott állsz, ahonnan kimentél.
	var resume: Dictionary = GameState.break_floor if int(GameState.break_floor.get("depth", -1)) == depth else {}
	GameState.break_floor = {}
	# Közös játékban mindenki ugyanazt az emeletet generálja (a gazda magjából).
	if GameState.net_seed != 0 and NetLobby.is_playing(get_tree()):
		seed(hash([GameState.net_seed, depth]))
	else:
		_floor_seed = int(resume["seed"]) if resume.has("seed") else randi()
		seed(_floor_seed)
	_big_rooms = depth >= BIG_ROOMS_FROM
	_huge_rooms = depth >= HUGE_ROOMS_FROM
	_cell = HUGE_CELL if _huge_rooms else BIG_CELL if _big_rooms else CELL
	# Gyakorló pálya (tutorial): rögzített, egyenes sor (TUTORIAL_CELLS), a végén főellenség-terem.
	var tutorial := GameState.tutorial
	# A nagy főellenség emelete: a 20. (Vérfarkas) és a 40. (a Káosz Ura).
	var chaos_floor := depth == CHAOS_DEPTH and not tutorial
	var final_floor := (depth == FINAL_DEPTH or chaos_floor) and not tutorial
	var cells: Array[Vector2i] = []
	if tutorial:
		cells = TUTORIAL_CELLS.duplicate()
	elif final_floor:
		cells = [Vector2i.ZERO, Vector2i.RIGHT]
	else:
		cells = _generate_layout(mini(base_room_count + depth - 1, max_room_count))
	var distances := _distances_from_start(cells)
	var stairs_cell := _farthest(distances)
	var shop_cell := TUTORIAL_CELLS[TUTORIAL_SHOP_ROOM] if tutorial else NO_SHOP if final_floor \
		else _pick_shop_cell(cells, stairs_cell)
	# A 10. emeleten mindig van liftszoba (kék a térképen), a kezdőszobához legközelebbi szabad szobában.
	var lift_cell := NO_SHOP
	if depth == Engineer.DEPTH and not tutorial:
		var best := 999999
		for cell in cells:
			if cell != Vector2i.ZERO and cell != stairs_cell and cell != shop_cell and int(distances[cell]) < best:
				best = int(distances[cell])
				lift_cell = cell
	# Minden BOSS_EVERY. emeleten a lépcsős szoba helyett főellenség-terem van.
	# (A gyakorló pálya utolsó szobája is főellenség-terem.)
	var boss_floor := (depth % BOSS_EVERY == 0 or tutorial) and not final_floor
	var alcove_dir := _free_direction(cells, stairs_cell) if boss_floor else Vector2i.ZERO

	var room_rects := {}
	for cell in cells:
		if final_floor:
			room_rects[cell] = FINAL_START_ROOM if cell == Vector2i.ZERO \
				else Rect2i(cell * _cell - FINAL_ARENA_SIZE / 2, FINAL_ARENA_SIZE)
		elif boss_floor and cell == stairs_cell:
			var boss_size := HUGE_BOSS_ROOM_SIZE if _huge_rooms else BIG_BOSS_ROOM_SIZE if _big_rooms else BOSS_ROOM_SIZE
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
		if final_floor:
			# A nagy főellenség terme: nyitott aréna, se csapda, se láda. A 20. emeleten mindkét
			# szobában Gáspár elesett embereinek csontvázai fekszenek (a teremben a legtöbb).
			if not chaos_floor:
				room.fallen_guards = FINAL_ARENA_GUARDS if cell == Vector2i.RIGHT else FINAL_START_GUARDS
			if cell == Vector2i.RIGHT:
				room.has_boss = true
				room.final_boss = true
				room.lord = "chaos" if chaos_floor else "werewolf"
				room.enemy_count = 1
		elif cell == shop_cell:
			room.has_shop = true
		elif cell == lift_cell:
			room.has_lift_room = true
		elif boss_floor and cell == stairs_cell:
			room.has_boss = true
			room.alcove_dir = alcove_dir
			room.enemy_count = 1
		elif distance > 0:
			if _huge_rooms:
				room.enemy_count = mini(2 + HUGE_ROOM_EXTRA_ENEMIES + distance / 2 + depth - 1, HUGE_MAX_ENEMIES)
			elif _big_rooms:
				room.enemy_count = mini(2 + BIG_ROOM_EXTRA_ENEMIES + distance / 2 + depth - 1, BIG_MAX_ENEMIES)
			else:
				room.enemy_count = mini(2 + distance / 2 + depth - 1, max_enemies_per_room)
			room.trap_count = randi_range(1, mini(2 + depth / 2, 4))
			room.has_chest = randf() < CHEST_CHANCE * Challenge.mult("chest_chance")
			# Próbatétel: kevesebb / több szörny és csapda.
			if Challenge.active():
				room.enemy_count = maxi(1, roundi(room.enemy_count * Challenge.mult("enemy_count")))
				room.trap_count = roundi(room.trap_count * Challenge.mult("trap_count"))
		room.has_stairs = cell == stairs_cell and not boss_floor and not final_floor
		if tutorial:
			var plan: Dictionary = TUTORIAL_ROOMS[TUTORIAL_CELLS.find(cell)]
			room.forced_enemies.assign(plan.get("enemies", []))
			if not room.has_boss:
				room.enemy_count = room.forced_enemies.size()
			room.trap_count = int(plan.get("traps", 0))
			room.has_chest = plan.get("chest", false)
		_rooms.add_child(room)
		room.cleared.connect(_hud.show_message.bind("Szoba kitisztítva!"))
		room.stairs_used.connect(_go_deeper)
		room.shop_entered.connect(_enter_shop)
		room.boss_fight_started.connect(_on_boss_fight_started)
		room.boss_defeated.connect(_on_boss_defeated)

	# Közös játékban innentől mindenkinek saját véletlen: a bolt áruja (és a szobák tartalma)
	# játékosonként más; a terem, az oszlopok, csapdák és díszek fent már közösek.
	if NetLobby.is_playing(get_tree()):
		randomize()
	if shop_cell != NO_SHOP:
		var interior := ShopInterior.new()
		_entities.add_child(interior)
		interior.exited.connect(_exit_shop)

	_player.global_position = Room.tile_center(Vector2i.ZERO)
	if not resume.is_empty():
		_resume_floor(resume)
	_player.get_node("Camera2D").reset_smoothing()
	_player.connect("death_finished", Callable(_death_screen, "show_for").bind(_player))
	# Közös játékban, ha már halott vagy, ezen az emeleten is nézőként követed a társaidat.
	if GameState.net_dead and NetLobby.is_playing(get_tree()):
		_player.call("become_spectator")
	var rooms: Array[Room] = []
	rooms.assign(_rooms.get_children())
	_hud.call("setup_map", rooms, _player, _cell)
	_prebuild_nav.call_deferred()
	# Küldetés: elért emelet (a gyakorló pályán és a próbatételben nem számít).
	if not Challenge.active():
		Quests.notify("floor", depth)
	if not tutorial and not GameState.cheated and not Challenge.active():
		Progress.reached_depth(depth)
	add_child(QuestTracker.new())
	add_child(PotionBadge.new())
	_add_quest_book()
	var cheats := CheatMenu.new()
	cheats.name = "CheatMenu"
	add_child(cheats)
	if not tutorial:
		GameState.visited_dungeon = true
	# Közös játékban a csapattársak is itt vannak (ugyanazon az emeleten; lásd NetAvatars).
	if NetLobby.is_playing(get_tree()):
		var avatars := NetAvatars.new()
		avatars.name = "NetAvatars"
		add_child(avatars)
		avatars.setup(self)
		avatars.message.connect(_hud.show_message)
		var net_enemies := NetEnemies.new()
		net_enemies.name = "NetEnemies"
		add_child(net_enemies)
		net_enemies.setup(self)
	# A varázsló a futás elején kiválasztja az első varázslatát.
	if Characters.data(Progress.character).get("spells", false) and GameState.spells.is_empty():
		add_child(preload("res://ui/spell_picker.gd").new())
	if tutorial:
		_setup_tutorial(rooms)
		var guide := TutorialGuide.new()
		guide.name = "TutorialGuide"
		add_child(guide)
		guide.call("setup", self, rooms)
	else:
		# A királyi vár engedélyéhez: elérted a 30. emeletet (ha vissza is jössz, az a táborban számít).
		if depth >= QUEST_DEPTH and not GameState.cheated and Progress.npc_quest_state(Castle.DEEP_FLAG) == "":
			Progress.set_npc_quest(Castle.DEEP_FLAG, "reached")
			Progress.save_game()
		if chaos_floor:
			_hud.show_message("%d. emelet — keleten a Káosz Ura vár! Itt már a valóság is széthullik." % depth)
		elif final_floor and Progress.character == "veteran":
			# Gáspár visszatér oda, ahol az emberei elestek.
			_hud.show_message("Gáspár: „Visszatértem, barátaim!”")
			FloatingText.spawn(_entities, _player.global_position + Vector2(0, -60), "Visszatértem, barátaim!",
				Color(1, 0.85, 0.5), 22)
		elif final_floor:
			_hud.show_message("%d. emelet — keletre vár a Mélység Ura!" % depth)
		elif depth >= QUEST_DEPTH and Progress.npc_quest_state("depth_30") == "active" and not GameState.cheated:
			# Gáspár küldetése teljesül: elérted a 30. emeletet (hogy mi van itt, majd kiderül).
			Progress.set_npc_quest("depth_30", "done")
			_hud.show_message("%d. emelet — ennyire mélyen még senki sem járt. Mondd el Gáspárnak!" % depth)
		elif depth == EnemyTypes.SURGE_DEPTH:
			_hud.show_message("%d. emelet — a szörnyek hirtelen megerősödtek!" % depth)
		elif depth in EnemyTypes.SURGE_DEPTHS:
			_hud.show_message("%d. emelet — a szörnyek ismét megerősödtek, a termek is hatalmasak!" % depth)
		else:
			_hud.show_message(("%d. emelet — főellenség vár!" if boss_floor else "%d. emelet") % depth)
	if Challenge.active():
		_start_challenge_floor(depth, boss_floor or final_floor)


## Pihenőre a táborba (a főellenség után, lásd BossReturnPanel): amit a visszatéréshez meg kell
## jegyezni — az emelet magja, a kitisztított és a bejárt szobák, ahol még ki nem nyitott láda
## áll, és hol álltál. (A földön hagyott zsákmány nem jön vissza.)
func break_snapshot() -> Dictionary:
	var cleared: Array[int] = []
	var visited: Array[int] = []
	var chests: Array[int] = []
	for node in _rooms.get_children():
		# (A szobák mellett lebegő feliratok is ide kerülnek.)
		var room := node as Room
		if room == null:
			continue
		if room.visited:
			visited.append(room.get_index())
		if room.visited and room.is_cleared():
			cleared.append(room.get_index())
			if room.has_closed_chest():
				chests.append(room.get_index())
	return {"depth": GameState.depth, "seed": _floor_seed, "cleared": cleared, "visited": visited,
		"chests": chests, "position": _player.global_position}


## Visszatérés a pihenőből: a mentett szobák kitisztítva (a főellenség termében szabad a lépcső),
## és ott állsz, ahonnan kimentél.
func _resume_floor(state: Dictionary) -> void:
	var rooms := _rooms.get_children()
	var chests: Array = state.get("chests", [])
	for index: int in state.get("cleared", []):
		if index < rooms.size():
			(rooms[index] as Room).restore_cleared(chests.has(index))
	for index: int in state.get("visited", []):
		if index < rooms.size():
			(rooms[index] as Room).visited = true
	_player.global_position = state.get("position", _player.global_position)
	_hud.show_message.call_deferred("Visszatértél a pihenőből — a lépcső szabad, mehetsz tovább.")


## Küldetések könyve (J), a Menus kezeli.
func _add_quest_book() -> void:
	var book: CanvasLayer = QUEST_BOOK.new()
	book.name = "QuestBook"
	add_child(book)


func _on_boss_fight_started(boss: Node2D) -> void:
	Audio.music("boss")
	_hud.call("show_boss", boss)
	_hud.show_message("Főellenség: %s" % boss.get("boss_name"))


func _on_boss_defeated(boss: Node2D) -> void:
	Audio.music("epic")
	_hud.call("hide_boss")
	var room: Room = boss.get_parent().get_parent()
	if room.final_boss:
		_on_final_boss_defeated(room)
		return
	# A próbatételből nincs pihenő a táborban (nincs portál).
	if Challenge.active():
		_hud.show_message("%s legyőzve! A lépcső szabad." % boss.get("boss_name"))
		return
	_hud.show_message("%s legyőzve! A lépcső szabad, és megnyílt a kék portál a táborba." % boss.get("boss_name"))
	# Visszaút-portál a teremben (a fülkével ellentétes oldalon, hogy ne takarja a lépcsőt).
	var portal: Node2D = RETURN_PORTAL.new()
	portal.position = Room.tile_center(room.anchor - room.alcove_dir * 3) - room.position
	room.add_child.call_deferred(portal)


## A nagy főellenség (Vérfarkas, Káosz Ura) legyőzve: a terem közepén portál nyílik, ami a
## győzelmi ablakot nyitja (2 tárgy, a pénz 100%-a, aztán a táborba).
func _on_final_boss_defeated(room: Room) -> void:
	_victory_lord = room.lord
	# A próbatételben a nagy főellenség után sincs portál: a lépcső visz tovább (az utolsó emeleten: győzelem).
	if Challenge.active():
		_hud.show_message("A Mélység Ura legyőzve! A lépcső szabad.")
		room.open_stairs.call_deferred(room.anchor + Vector2i(DEEPER_STAIRS_OFFSET, 0))
		return
	if room.lord == "chaos":
		_hud.show_message("A Káosz Ura elesett! Portál a táborba — vagy a lépcsőn tovább a mélybe.")
		var chaos_portal: Node2D = RETURN_PORTAL.new()
		chaos_portal.position = Room.tile_center(room.anchor) - room.position
		chaos_portal.set("prompt_text", "[E] Győzelem — vissza a táborba")
		chaos_portal.set("on_use", _open_victory_panel)
		room.add_child.call_deferred(chaos_portal)
		room.open_stairs.call_deferred(room.anchor + Vector2i(DEEPER_STAIRS_OFFSET, 0))
		return
	_hud.show_message("A Mélység Ura legyőzve! Lépj a portálba — végigértél a kazamatán!")
	# Gáspár küldetése: bosszú a fiaiért (a jutalmat majd ő mondja meg).
	if Progress.npc_quest_state("slay_lord") == "active" and not GameState.cheated:
		Progress.set_npc_quest("slay_lord", "done")
		FloatingText.spawn(room, room.global_position + Vector2(0, -90), "Gáspár emberei megbosszulva", Color(1, 0.85, 0.4), 22)
	var portal: Node2D = RETURN_PORTAL.new()
	portal.position = Room.tile_center(room.anchor) - room.position
	portal.set("prompt_text", "[E] Győzelem — vissza a táborba")
	portal.set("on_use", _open_victory_panel)
	room.add_child.call_deferred(portal)
	# A farkas mögött mindig lépcső nyílik lefelé: hazamehetsz a portálon, vagy folytathatod a futást.
	room.open_stairs.call_deferred(room.anchor + Vector2i(DEEPER_STAIRS_OFFSET, 0))
	_hud.show_message("A Mélység Ura legyőzve! Portál a táborba — vagy a lépcsőn tovább a mélybe.")


## A próbatétel emeletének kezdete: az első emeleten a módosítók a játékosra (élet, sebzés, regeneráció, bájitalok,
## szintek), a sötétség minden emeleten; felirat a haladással.
func _start_challenge_floor(depth: int, boss_floor: bool) -> void:
	var floors := int(GameState.challenge["floors"])
	if Challenge.flag("darkness"):
		var darkness := get_node("CanvasModulate") as CanvasModulate
		darkness.color = darkness.color.darkened(0.45)
	if not GameState.challenge.get("applied", false):
		GameState.challenge["applied"] = true
		var stats: Stats = _player.get_node("Stats")
		stats.base_max_health = maxf(1.0, roundf(stats.base_max_health * Challenge.mult("player_health")))
		stats.base_damage_percent += Challenge.add("player_damage")
		stats.base_health_regen += Challenge.add("regen_add")
		var health: Health = _player.get_node("Health")
		health.current = health.max_health
		health.changed.emit(health.current, health.max_health)
		GameState.potions += int(Challenge.add("start_potions"))
		var levels := int(Challenge.add("start_levels"))
		if levels > 0:
			var experience: Experience = _player.get_node("Experience")
			var xp := 0
			for i in levels:
				xp += Experience.xp_for_level(experience.level + i)
			experience.add.call_deferred(xp)
		_hud.show_message("Próbatétel: %d emelet, %s nehézség — sok szerencsét!" % [floors,
			str(GameState.challenge["difficulty"]).to_lower()])
		return
	_hud.show_message("Próbatétel — %d. / %d emelet%s" % [depth, floors, " — főellenség vár!" if boss_floor else ""])


## A próbatétel utolsó emeletének lépcsője: a jutalom (tárgy a tábori ládába, az arany 100%-a a táborba), a lent
## szerzett tárgyak lent maradnak; új próbatétel sorsolódik; vissza a táborba (az eredményablak gombjával).
func _challenge_won() -> void:
	if get_node_or_null("ChallengePanel") != null:
		return
	var challenge := GameState.challenge
	var item := {}
	var gold := int(_player.get("gold"))
	if not GameState.cheated:
		item = Challenge.roll_reward(challenge)
		Progress.add_to_stash(item)
		Progress.add_camp_gold(gold)
		Challenge.reroll()
	else:
		gold = 0
	var panel := ChallengePanel.new()
	panel.name = "ChallengePanel"
	add_child(panel)
	panel.show_result(challenge, item, gold)
	get_node("Menus").call("open_menu", panel)


func _open_victory_panel() -> void:
	var panel := get_node_or_null("VictoryPanel")
	if panel == null:
		panel = VICTORY_PANEL.new()
		panel.name = "VictoryPanel"
		panel.set("lord", _victory_lord)
		add_child(panel)
	get_node("Menus").call("open_menu", panel)


## Ha a kazamatában bezárod az ablakot, az is kilépésnek számít: a pénzed 40%-a a táborba kerül.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not GameState.tutorial:
		var player := get_tree().get_first_node_in_group("player")
		if player and not player.get_node("Health").is_dead():
			Records.submit_run(player)
			Progress.rescue_gold(int(player.get("gold")), 0.4)


## A főellenség-terem mögötti fülke iránya: olyan oldal, ahol nincs szomszédos szoba
## (előnyben az észak). Vector2i.ZERO, ha minden oldalon van szomszéd.
## A gyakorló pálya kellékei: a kovács ablaka és a gyakorló üllő, a játékos nem halhat meg, és a HUD üzenetei
## lejjebb kerülnek (fent a vezető pergamenje van).
func _setup_tutorial(rooms: Array[Room]) -> void:
	_hud.show_message("Gyakorló pálya")
	var smith := SmithPanel.new()
	smith.name = "SmithPanel"
	add_child(smith)
	var anvil := TutorialAnvil.new()
	anvil.name = "TutorialAnvil"
	anvil.position = Room.tile_center(rooms[TUTORIAL_ANVIL_ROOM].anchor)
	_entities.add_child(anvil)
	(_player.get_node("Health") as Health).cannot_die = true
	var message := _hud.get_node("Message") as Control
	message.offset_top += 130
	message.offset_bottom += 130


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
	# A tolvaj levelével a 10. emeleten mindig van bolt (ott vár a címzett).
	# (Közös játékban mindenkinél van itt bolt: a játékosonként más küldetés nem bonthatja meg a közös
	# véletlent, különben a gépeken más lenne a pálya.)
	var letter_floor := GameState.depth == Thief.LETTER_FLOOR 		and (NetLobby.is_playing(get_tree()) or Progress.npc_quest_state(Thief.LETTER_QUEST) == "active")
	if randf() >= SHOP_CHANCE and not letter_floor:
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
	# Biztonsági háló: ha a visszatérési pont mégis foglalt (oszlop, láda), a legközelebbi szabad helyre.
	var target := _shop_return
	for room in _rooms.get_children():
		if room is Room and (room as Room).rect.has_point(Vector2i((target / Room.TILE).floor())):
			target = (room as Room).safe_spawn_position(target)
	_teleport(target, "")


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


## Csalás (CheatMenu): ugrás a megadott emeletre a mostani állapottal. A gyakorló pályán nem megy.
func cheat_teleport(target_depth: int) -> bool:
	if GameState.tutorial or _teleporting:
		return false
	_player.save_state()
	GameState.depth = target_depth
	GamePause.set_paused(get_tree(), false)
	get_tree().reload_current_scene.call_deferred()
	return true


func _go_deeper() -> void:
	# A gyakorló pálya végén a lépcső befejezi a gyakorlást.
	if GameState.tutorial:
		get_node("TutorialGuide").call("finish")
		return
	# A próbatétel utolsó emeletének lépcsője: győzelem.
	if Challenge.active() and GameState.depth >= int(GameState.challenge["floors"]):
		_challenge_won()
		return
	# Közös játékban a lépcsőn megvárod a társaidat: ha minden élő játékos ráállt, a gazda viszi
	# tovább a csapatot (NetEnemies._watch_team). Ha a gazda nincs itt, egyedül mész tovább.
	var net := NetEnemies.active(get_tree())
	if net != null and not net.local_mode:
		_player.call("start_waiting")
		_hud.show_message("A lépcsőn vársz a társaidra... (ha elindulsz, lelépsz róla)")
		return
	go_to_floor(GameState.depth + 1)


## Átlépés a megadott emeletre (közös játékban a NetLobby hívja mindenkinél).
func go_to_floor(target_depth: int) -> void:
	# Közös játékban nyitott ablak (táska, könyv, szintlépés) mellett is jöhet: az ablak bezárul, és a
	# játék sem marad megállítva (régen az új emeleten minden állt, és semmi nem nyílt meg).
	var menus := get_node_or_null("Menus")
	if menus != null:
		menus.call("close_current")
	GamePause.set_paused(get_tree(), false)
	_player.save_state()
	GameState.depth = target_depth
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
	var widths := HUGE_ROOM_WIDTH if _huge_rooms else BIG_ROOM_WIDTH if _big_rooms else ROOM_WIDTH
	var heights := HUGE_ROOM_HEIGHT if _huge_rooms else BIG_ROOM_HEIGHT if _big_rooms else ROOM_HEIGHT
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


# ---------------------------------------------------------------- útkeresés

## Útkereső háló az ellenségeknek (lásd Enemy._chase_direction): a padló cellái, kivéve ahol valami
## szilárd áll (oszlop, láda, bolt). Az első kéréskor épül fel, amikor már minden a helyén van.
var _nav: AStarGrid2D


## A háló már a betöltés után felépül (az első harc első útkérésekor a nagy emeleteken egy pillanatra
## megakasztotta a szobába lépést). Az oszlopoknak, ládáknak ehhez már a fizikai térben kell lenniük.
func _prebuild_nav() -> void:
	for i in 2:
		await get_tree().physics_frame
	if _nav == null and is_inside_tree():
		_build_nav()


## Út (világkoordináta-pontok) `from`-tól `to`-ig a falakat és az oszlopokat kerülve; üres, ha nincs.
func nav_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	if _nav == null:
		_build_nav()
	var start := _nav_cell(from)
	var goal := _nav_cell(to)
	var result := PackedVector2Array()
	if not _nav.is_in_boundsv(start) or not _nav.is_in_boundsv(goal) or _nav.is_point_solid(goal):
		return result
	# Ha az ellenség épp egy szilárd cella szélén áll (pl. oszlophoz nyomódott), a legközelebbi szabadból indul.
	if _nav.is_point_solid(start):
		start = _nearest_free(start)
		if start == Vector2i(-99999, -99999):
			return result
	for cell: Vector2i in _nav.get_id_path(start, goal, true):
		result.append(_wall_layer.to_global(_wall_layer.map_to_local(cell)))
	return result


func _nav_cell(at: Vector2) -> Vector2i:
	return _wall_layer.local_to_map(_wall_layer.to_local(at))


func _nearest_free(cell: Vector2i) -> Vector2i:
	for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		var next := cell + offset
		if _nav.is_in_boundsv(next) and not _nav.is_point_solid(next):
			return next
	return Vector2i(-99999, -99999)


func _build_nav() -> void:
	_nav = AStarGrid2D.new()
	var bounds := Rect2i()
	var first := true
	for cell: Vector2i in _floor:
		if first:
			bounds = Rect2i(cell, Vector2i.ONE)
			first = false
		else:
			bounds = bounds.expand(cell).expand(cell + Vector2i.ONE)
	_nav.region = bounds
	_nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_nav.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_nav.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_nav.update()
	var space := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.collision_mask = 1
	# A harc közbeni zárak (Door) nem számítanak: azok csak ideiglenesek.
	var doors: Array[RID] = []
	for door in get_tree().get_nodes_in_group("doors"):
		doors.append((door as CollisionObject2D).get_rid())
	query.exclude = doors
	for x in range(bounds.position.x, bounds.end.x):
		for y in range(bounds.position.y, bounds.end.y):
			var cell := Vector2i(x, y)
			var solid := not _floor.has(cell)
			if not solid:
				query.position = _wall_layer.to_global(_wall_layer.map_to_local(cell))
				solid = not space.intersect_point(query, 1).is_empty()
			_nav.set_point_solid(cell, solid)


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
