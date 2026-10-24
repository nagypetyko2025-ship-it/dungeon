class_name Room
extends Node2D
## Egy szoba a dungeonban. A padlót és a falakat a Dungeon rajzolja ki;
## a szoba felel az ajtókért, az oszlopokért, a csapdákért, az ellenségekért
## és a lépcsőért. Belépéskor bezárja az ajtókat és ellenségeket spawnol;
## ha mind meghalt, kinyitja az ajtókat és `cleared`-et jelez.

signal cleared
signal stairs_used
## A játékos nekiment a bolt bejáratának.
signal shop_entered(return_position: Vector2)
## Főellenség-harc kezdete / vége (a Dungeon a HUD-ot és a zenét intézi).
signal boss_fight_started(boss: Node2D)
signal boss_defeated(boss: Node2D)

const TILE := 32
const MIN_SPAWN_DISTANCE := 200.0
const MAX_PILLAR_GROUPS := 2
## Csapdák ennyi csempénél nem lehetnek közelebb az ajtókhoz.
const TRAP_DOOR_DISTANCE := 3
## Harc közben ilyen gyakran ellenőrzi, hogy minden ellenség a szobában van-e.
const CHECK_INTERVAL := 0.5
## A bolt bal szélének távolsága a cella közepétől (csempében).
const SHOP_OFFSET := 3
## A tárgylift jobb oldali csempéje ennyivel van a középső oszloptól balra.
const LIFT_OFFSET := 2
const ITEM_LIFT := preload("res://rooms/obstacles/item_lift.gd")
## Az osztódáskor keletkező ellenségek ennyire kerülnek a szülőtől.
const SPLIT_SPREAD := 18.0
## A főellenség-terem mögötti fülke mélysége (csempe); a végén a lépcső.
const ALCOVE_DEPTH := 3
## Főellenség jutalma: arany (+ emeletenként), és egy legalább ilyen ritka tárgy.
const BOSS_GOLD := 40
const BOSS_GOLD_PER_DEPTH := 10
const BOSS_ITEM_MIN_RARITY := "epic"
const COIN := preload("res://pickups/coin.tscn")
const WEREWOLF := preload("res://enemies/werewolf_boss.gd")
## A nagy főellenség (Vérfarkas, 20. emelet) jutalma: sok arany és két tárgy.
const FINAL_BOSS_GOLD := 400
const ITEM_DROP := preload("res://pickups/item_drop.tscn")

@export var enemy_scene: PackedScene
@export var pillar_scene: PackedScene
@export var trap_scene: PackedScene
@export var stairs_scene: PackedScene
@export var chest_scene: PackedScene
@export var shop_scene: PackedScene
@export var boss_scene: PackedScene

# Ezeket a Dungeon állítja be, mielőtt a szoba a fába kerül.
## A rácscella közepe (csempe-koordináta). A folyosók ennek sora/oszlopa mentén futnak.
var anchor := Vector2i.ZERO
## A szoba padlója csempe-koordinátákban.
var rect := Rect2i()
## Melyik irányokban van szomszédos szoba.
var connections: Array[Vector2i] = []
var enemy_count := 0
var trap_count := 0
var depth := 1
var has_stairs := false
var has_chest := false
## Bolt van a szoba északi falában (ilyenkor nincs harc a szobában).
var has_shop := false
## A 10. emelet liftszobája (Bertalan, a mérnök; lásd LiftRoom): nincs benne szörny, csapda, láda.
var has_lift_room := false
## Járt-e már itt a játékos (a térképhez).
var visited := false
## Főellenség-terem: a lépcső a fülkében van (lcove_dir irányban), rács mögött.
var has_boss := false
## Ennyi elesett királyi őr csontváza fekszik a szobában (a 20. emeleten: Gáspár emberei).
var fallen_guards := 0
## A nagy főellenség terme (20. emelet, Vérfarkas): nincs fülke és lépcső, győzelem után
## a portálon át a táborba mehetsz, és vége a kazamatának.
var final_boss := false
## A tárgylift jobb oldali csempéjének x-e (csak a bolt szobájában; a fáklyák kikerülik).
var lift_x := -99999
## A szoba lépcsője (ha van): a harc végéig rács van rajta.
var _stairs: Node2D
var alcove_dir := Vector2i.ZERO

var _fought := false
var _cleared := false
var _alive_enemies: Array[Node2D] = []
## A még pályára nem került (megjelenésre váró) szörnyek: képkockánként csak SPAWNS_PER_FRAME jön be,
## mert a mély emeleteken egyszerre 14-20 szörny (a vendégnél a bábjaik) egy pillanatra megakasztotta
## a játékot. A harc szempontjából már élnek (benne vannak az _alive_enemies-ben).
var _spawn_queue: Array[Node2D] = []
const SPAWNS_PER_FRAME := 3
var _player: Node2D
var _check_left := 0.0
## Foglalt csempék (oszlop, csapda, lépcső), hogy ne kerüljön semmi egymásra.
var _used_tiles := {}
var _doors: Array[Door] = []
var _gate: Door

@onready var _pillars: Node2D = $Pillars
@onready var _traps: Node2D = $Traps
@onready var _enemies: Node2D = $Enemies


## Egy csempe közepének világ-koordinátája.
static func tile_center(tile: Vector2i) -> Vector2:
	return Vector2(tile) * TILE + Vector2(TILE, TILE) / 2.0


func _ready() -> void:
	position = tile_center(anchor)
	_used_tiles[anchor] = true
	if has_stairs:
		_stairs = _add_at_tile(stairs_scene, _traps, anchor)
		_stairs.connect("used", stairs_used.emit)
		# Rács a lépcsőn, amíg a szoba szörnyei élnek.
		if enemy_count > 0:
			_stairs.call("set_locked", true)
	if has_shop:
		_place_shop()
	if has_lift_room:
		_place_lift_room()
	if has_boss and not final_boss:
		_create_alcove()
	_create_doors()
	_create_trigger()
	_place_pillars()
	_place_traps()
	var decor := RoomDecor.new()
	decor.room = self
	add_child(decor)


func _to_local_pos(tile: Vector2i) -> Vector2:
	return tile_center(tile) - position


## Van-e nyílás a falon ebben az irányban (folyosó vagy a főellenség-fülke).
func has_opening(dir: Vector2i) -> bool:
	return connections.has(dir) or (has_boss and alcove_dir == dir)


## A fülke csempéi: [a rács helye (3 csempe), a lépcső csempéje].
func _alcove_tiles() -> Array:
	var gate: Array[Vector2i] = []
	var stairs := Vector2i.ZERO
	for i in range(-1, 2):
		match alcove_dir:
			Vector2i.UP: gate.append(Vector2i(anchor.x + i, rect.position.y - 1))
			Vector2i.DOWN: gate.append(Vector2i(anchor.x + i, rect.end.y))
			Vector2i.LEFT: gate.append(Vector2i(rect.position.x - 1, anchor.y + i))
			Vector2i.RIGHT: gate.append(Vector2i(rect.end.x, anchor.y + i))
	match alcove_dir:
		Vector2i.UP: stairs = Vector2i(anchor.x, rect.position.y - ALCOVE_DEPTH)
		Vector2i.DOWN: stairs = Vector2i(anchor.x, rect.end.y + ALCOVE_DEPTH - 1)
		Vector2i.LEFT: stairs = Vector2i(rect.position.x - ALCOVE_DEPTH, anchor.y)
		Vector2i.RIGHT: stairs = Vector2i(rect.end.x + ALCOVE_DEPTH - 1, anchor.y)
	return [gate, stairs]


## A főellenség mögötti fülke: lépcső a végén, lezárt rács a száján.
func _create_alcove() -> void:
	var tiles := _alcove_tiles()
	_add_at_tile(stairs_scene, _traps, tiles[1]).connect("used", stairs_used.emit)
	_gate = Door.new()
	$Doors.add_child(_gate)
	var points: Array[Vector2] = []
	for tile: Vector2i in tiles[0]:
		points.append(_to_local_pos(tile))
	_gate.setup(points, TILE)
	_gate.set_blocked(true)


# A berendezéshez (RoomDecor) használt segédek.
func local_pos(tile: Vector2i) -> Vector2:
	return _to_local_pos(tile)


func is_tile_used(tile: Vector2i) -> bool:
	return _used_tiles.has(tile)


func mark_tile_used(tile: Vector2i) -> void:
	_used_tiles[tile] = true


func is_away_from_doors(tile: Vector2i) -> bool:
	return _is_away_from_doors(tile)


## Kitakarítottnak számít-e (a térképhez): harc nélküli szoba mindig az.
func is_cleared() -> bool:
	return enemy_count <= 0 or _cleared


## A bolt az északi falba kerül, a középső folyosótól jobbra (két csempe széles),
## így akkor sem takar el ajtót, ha felfelé is van folyosó.
func _place_shop() -> void:
	var left_tile := Vector2i(anchor.x + SHOP_OFFSET, rect.position.y)
	var shop: Node2D = shop_scene.instantiate()
	shop.position = Vector2(left_tile.x + 1, left_tile.y) * TILE - position
	add_child(shop)
	shop.connect("entered", shop_entered.emit)
	for dx in 2:
		for dy in 2:
			_used_tiles[left_tile + Vector2i(dx, dy)] = true
	# A bolt előtti hely (ide jössz ki a boltból) is szabad marad: se oszlop, se csapda.
	for dx in range(-1, 3):
		for dy in range(2, 5):
			_used_tiles[left_tile + Vector2i(dx, dy)] = true
	_place_item_lift()


## A liftszoba: a fülke a hátsó fal előtt, a szoba közepén; körülötte nem lesz oszlop.
func _place_lift_room() -> void:
	var top := Vector2i(anchor.x, rect.position.y + 1)
	var lift_room := LiftRoom.new()
	lift_room.position = tile_center(top) - position
	add_child(lift_room)
	for dx in range(-2, 4):
		for dy in range(0, 4):
			_used_tiles[top + Vector2i(dx, dy)] = true


## Tárgylift ugyanebben a falban, a középső folyosó bal oldalán (két csempe széles,
## mellette a kar): ezzel lehet egy tárgyat felküldeni a táborba.
func _place_item_lift() -> void:
	var right_tile := Vector2i(anchor.x - LIFT_OFFSET, rect.position.y)
	lift_x = right_tile.x
	var lift: Node2D = ITEM_LIFT.new()
	lift.position = Vector2(right_tile.x, right_tile.y) * TILE - position
	add_child(lift)
	for dx in range(-2, 1):
		for dy in 2:
			_used_tiles[right_tile + Vector2i(dx, dy)] = true


func _add_at_tile(scene: PackedScene, parent: Node, tile: Vector2i) -> Node2D:
	var node: Node2D = scene.instantiate()
	node.position = _to_local_pos(tile)
	parent.add_child(node)
	_used_tiles[tile] = true
	return node


## Ajtó minden folyosó szájánál, közvetlenül a szoba padlóján kívül.
func _create_doors() -> void:
	for dir in connections:
		var tiles: Array[Vector2i] = []
		for i in range(-1, 2):
			match dir:
				Vector2i.LEFT: tiles.append(Vector2i(rect.position.x - 1, anchor.y + i))
				Vector2i.RIGHT: tiles.append(Vector2i(rect.end.x, anchor.y + i))
				Vector2i.UP: tiles.append(Vector2i(anchor.x + i, rect.position.y - 1))
				Vector2i.DOWN: tiles.append(Vector2i(anchor.x + i, rect.end.y))
		var door := Door.new()
		$Doors.add_child(door)
		var points: Array[Vector2] = []
		for tile in tiles:
			points.append(_to_local_pos(tile))
		door.setup(points, TILE)
		door.set_blocked(false)
		_doors.append(door)


## A belépést érzékelő terület: a padló egy csempével beljebb,
## így az ajtó biztosan nem a játékosra záródik.
func _create_trigger() -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitorable = false
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(rect.size - Vector2i(2, 2)) * TILE
	shape.shape = rectangle
	area.position = (Vector2(rect.position) + Vector2(rect.size) / 2.0) * TILE - position
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_trigger_body_entered)


## Oszlopok tükrözve a cella középpontjára; a középső sor és oszlop
## szabadon marad, hogy minden ajtó elérhető legyen.
func _place_pillars() -> void:
	if has_boss:
		return  # a főellenség-terem nyitott aréna
	var inner := rect.grow(-2)
	for i in randi_range(0, MAX_PILLAR_GROUPS):
		var offset := Vector2i(randi_range(3, 5), randi_range(2, 3))
		for mirror in [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
			var tile: Vector2i = anchor + offset * mirror
			if inner.has_point(tile) and not _used_tiles.has(tile):
				_add_at_tile(pillar_scene, _pillars, tile)


func _place_traps() -> void:
	var inner := rect.grow(-1)
	for i in trap_count:
		for attempt in 20:
			var tile := Vector2i(
				randi_range(inner.position.x, inner.end.x - 1),
				randi_range(inner.position.y, inner.end.y - 1))
			if _is_free(tile) and _is_away_from_doors(tile):
				_add_at_tile(trap_scene, _traps, tile)
				break


func _is_free(tile: Vector2i) -> bool:
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if _used_tiles.has(tile + Vector2i(dx, dy)):
				return false
	return true


func _is_away_from_doors(tile: Vector2i) -> bool:
	for door in _doors:
		for point in door.points:
			if tile_center(tile).distance_to(point + position) < TRAP_DOOR_DISTANCE * TILE:
				return false
	return true


func _on_trigger_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	visited = true
	if _fought or enemy_count <= 0:
		return
	# Közös játékban (vendégként) a gazda indítja a harcot, a szörnyek tőle jönnek (NetEnemies).
	var net := NetEnemies.active(get_tree())
	if net != null and net.request_room(self, body.global_position):
		return
	_begin_fight(body.global_position, body)


## Közös játék, gazda: egy vendég lépett be ebbe a szobába (nálunk is itt kezdődik a harc).
func remote_enter(at: Vector2) -> void:
	visited = true
	if _fought or enemy_count <= 0:
		return
	_begin_fight(at, null)


func _begin_fight(at: Vector2, body: Node2D) -> void:
	_fought = true
	_player = body
	_set_doors_locked(true)
	if has_boss:
		_spawn_boss()
		return
	var taken := {}
	for i in enemy_count:
		_spawn_enemy(at, taken)


## Közös játék, vendég: a gazda egy szörnye itt jelent meg (báb; lásd NetEnemies).
func add_puppet(type_name: String, at: Vector2, stats: Dictionary, id: int, boss_kind: String) -> Node2D:
	if not _fought:
		_fought = true
		visited = true
		_set_doors_locked(true)
	var enemy: Node2D = boss_scene.instantiate() if boss_kind != "" else enemy_scene.instantiate()
	enemy.set("net_id", id)
	enemy.set("net_puppet", true)
	if boss_kind == "werewolf":
		enemy.set_script(WEREWOLF)
		enemy.set("net_id", id)
		enemy.set("net_puppet", true)
		enemy.call("setup_werewolf", depth)
		enemy.connect("final_died", _on_enemy_died.bind(enemy))
	elif boss_kind != "":
		enemy.call("setup_boss", depth)
		enemy.get_node("Health").died.connect(_on_enemy_died.bind(enemy))
	else:
		enemy.call("setup", EnemyTypes.by_name(type_name), depth)
		enemy.set("stats", stats)
		enemy.get_node("Health").died.connect(_on_enemy_died.bind(enemy))
	enemy.position = at
	_alive_enemies.append(enemy)
	if boss_kind != "":
		_enemies.add_child.call_deferred(enemy)
		Audio.play("boss_roar")
		boss_fight_started.emit(enemy)
	else:
		_queue_spawn(enemy)
	return enemy


## A főellenség a terem fülke felőli felén jelenik meg (a lépcső "mögötte" van).
func _spawn_boss() -> void:
	var net := NetEnemies.active(get_tree())
	if net != null and net.is_client_mode():
		return
	var boss = boss_scene.instantiate()
	if final_boss:
		# A Vérfarkas a terem túlsó (keleti) felén vár; csak az igazi halála számít.
		boss.set_script(WEREWOLF)
		boss.setup_werewolf(depth)
		boss.position = Vector2(rect.size.x * 0.25, 0) * TILE
		boss.connect("final_died", _on_enemy_died.bind(boss))
	else:
		boss.setup_boss(depth)
		var toward_alcove := Vector2(alcove_dir) * Vector2(rect.size) * 0.25
		boss.position = toward_alcove * TILE
		boss.get_node("Health").died.connect(_on_enemy_died.bind(boss))
	_alive_enemies.append(boss)
	_enemies.add_child.call_deferred(boss)
	if net != null:
		net.register(boss, self, "werewolf" if final_boss else "boss")
	Audio.play("boss_roar")
	boss_fight_started.emit(boss)


## A főellenség (vagy egy idéző ellenség) hívja: segítők jelennek meg körülötte.
func summon_minions(type_name: String, count: int, around: Vector2) -> void:
	var taken := {}
	for i in count:
		var offset := Vector2.from_angle(TAU * i / count + randf()) * 70.0
		_add_enemy(EnemyTypes.by_name(type_name), around + offset, taken)


## Biztonságos hely egy ellenségnek a kért pont közelében: ha a pont szabad padlón
## van (nem falban, oszlopban, berendezésben, és más nem kapta meg ezt a csempét),
## akkor maga a pont; különben a legközelebbi ilyen csempe közepe.
## `taken`: az ebben a körben már kiosztott csempék (bele is írja a választottat).
func safe_spawn_position(world_position: Vector2, taken := {}) -> Vector2:
	var wanted := Vector2i((world_position / TILE).floor())
	if _can_spawn_at(wanted, taken) and _point_free(world_position):
		taken[wanted] = true
		return world_position
	var inner := rect.grow(-1)
	var best := anchor
	var best_distance := INF
	for x in range(inner.position.x, inner.end.x):
		for y in range(inner.position.y, inner.end.y):
			var tile := Vector2i(x, y)
			var distance := tile_center(tile).distance_squared_to(world_position)
			if distance < best_distance and _can_spawn_at(tile, taken) and _point_free(tile_center(tile)):
				best = tile
				best_distance = distance
	taken[best] = true
	return tile_center(best)


func _can_spawn_at(tile: Vector2i, taken: Dictionary) -> bool:
	return rect.grow(-1).has_point(tile) and not _used_tiles.has(tile) and not taken.has(tile)


## Nincs-e ott szilárd test (fal, oszlop, láda, hordó, zárt ajtó).
func _point_free(world_position: Vector2) -> bool:
	if not is_inside_tree():
		return true
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_position
	query.collision_mask = 1
	return get_world_2d().direct_space_state.intersect_point(query, 1).is_empty()


func _on_boss_defeated(boss: Node2D) -> void:
	Quests.notify("boss")
	# Minden főellenség után jár egy HP bájital (a gyorstár első helyére).
	GameState.potions += 1
	if is_instance_valid(_player):
		FloatingText.spawn(get_parent(), _player.global_position + Vector2(-60, -80),
			"+1 HP bájital (%d)" % GameState.potions, Color(1, 0.45, 0.5), 20)
	if final_boss:
		pass  # nincs lépcső: a Dungeon nyit portált a táborba
	elif is_instance_valid(_gate):
		_gate.set_blocked(false)
	elif alcove_dir == Vector2i.ZERO:
		# Nem fért el fülke (minden oldalon szomszéd van): a lépcső most jelenik meg középen.
		_add_at_tile.call_deferred(stairs_scene, _traps, anchor)
		_connect_center_stairs.call_deferred()
	Audio.play("door_unlock")
	_drop_boss_loot.call_deferred(boss.position)
	boss_defeated.emit(boss)


## Lépcső lefelé a megadott csempén (pl. a Vérfarkas után, ha Gáspár küldetése mélyebbre visz).
func open_stairs(tile: Vector2i) -> void:
	var stairs := _add_at_tile(stairs_scene, _traps, tile)
	stairs.connect("used", stairs_used.emit)
	Audio.play("door_unlock")


func _connect_center_stairs() -> void:
	var stairs := _traps.get_child(_traps.get_child_count() - 1)
	stairs.connect("used", stairs_used.emit)


## Sok arany és egy biztosan legalább epikus tárgy.
func _drop_boss_loot(at: Vector2) -> void:
	var total := FINAL_BOSS_GOLD if final_boss else BOSS_GOLD + depth * BOSS_GOLD_PER_DEPTH
	var coins := 20 if final_boss else 10
	for i in coins:
		var coin = COIN.instantiate()
		coin.value = total / coins + (total % coins if i == 0 else 0)
		coin.position = at + Vector2(0, -20)
		_enemies.add_child(coin)
	var drop = ITEM_DROP.instantiate()
	drop.item = Items.random_item("legendary", BOSS_ITEM_MIN_RARITY)
	drop.position = at + Vector2(0, -20)
	_enemies.add_child(drop)
	if final_boss:
		# A Vérfarkas egy biztos legendás tárgyat is hagy.
		var legendary = ITEM_DROP.instantiate()
		legendary.item = Items.random_item("legendary", "legendary")
		legendary.position = at + Vector2(40, -20)
		_enemies.add_child(legendary)


## `taken`: az ebben a körben már kiosztott csempék, hogy két ellenség
## ne kerüljön egymásra (az egymásba lógó testeket a fizika szétlökné,
## akár a falon át is).
func _spawn_enemy(player_pos: Vector2, taken: Dictionary) -> void:
	_add_enemy(EnemyTypes.pick(depth), _random_spawn_point(player_pos, taken), taken)


## Minden új ellenség (spawn, osztódás, idézés) biztonságos helyre kerül, hogy ne
## jelenhessen meg falban, oszlopban vagy egy másik ellenségen.
func _add_enemy(type: Dictionary, world_position: Vector2, taken := {}) -> void:
	# Közös játékban a vendég nem spawnol: a gazda szörnyei bábként jönnek (add_puppet).
	var net := NetEnemies.active(get_tree())
	if net != null and net.is_client_mode():
		return
	var enemy = enemy_scene.instantiate()
	enemy.setup(type, depth)
	enemy.position = safe_spawn_position(world_position, taken) - position
	enemy.get_node("Health").died.connect(_on_enemy_died.bind(enemy))
	_alive_enemies.append(enemy)
	_queue_spawn(enemy)
	if net != null:
		# A statok már most dőlnek el, hogy a vendégek bábja ugyanilyen legyen.
		enemy.stats = EnemyTypes.roll(type, depth)
		net.register(enemy, self)


## A szörny a következő képkockák egyikén kerül pályára (lásd _spawn_queue).
func _queue_spawn(enemy: Node2D) -> void:
	_spawn_queue.append(enemy)
	if _spawn_queue.size() == 1:
		_drain_spawn_queue.call_deferred()


func _drain_spawn_queue() -> void:
	while not _spawn_queue.is_empty():
		for i in mini(SPAWNS_PER_FRAME, _spawn_queue.size()):
			var enemy: Node2D = _spawn_queue.pop_front()
			if is_instance_valid(enemy):
				_enemies.add_child(enemy)
		if _spawn_queue.is_empty():
			return
		# (A process_frame megállított játék alatt is jön: közös játékban a gazda szörnyei menü alatt is élnek.)
		await get_tree().process_frame


func _exit_tree() -> void:
	# Emeletváltáskor a még várakozók nincsenek a fában, maguktól nem szabadulnának fel.
	for enemy in _spawn_queue:
		if is_instance_valid(enemy):
			enemy.free()
	_spawn_queue.clear()


## Osztódó ellenség (pl. csiga) halálakor a kisebbek a helyén jelennek meg.
func _spawn_splits(enemy: Node2D) -> void:
	var type: Dictionary = enemy.get("_type")
	if not type.has("splits_into"):
		return
	var child_type: Dictionary = EnemyTypes.by_name(type["splits_into"])
	var taken := {}
	for i in type.get("split_count", 2):
		var offset := Vector2.from_angle(TAU * i / type.get("split_count", 2) + randf()) * SPLIT_SPREAD
		_add_enemy(child_type, enemy.global_position + offset, taken)


func _random_spawn_point(avoid: Vector2, taken := {}) -> Vector2:
	var inner := rect.grow(-2)
	var tile := Vector2i.ZERO
	for attempt in 40:
		tile = Vector2i(
			randi_range(inner.position.x, inner.end.x - 1),
			randi_range(inner.position.y, inner.end.y - 1))
		if not _used_tiles.has(tile) and not taken.has(tile) \
				and tile_center(tile).distance_to(avoid) >= MIN_SPAWN_DISTANCE:
			break
	return tile_center(tile)


func _on_enemy_died(enemy: Node2D) -> void:
	GameState.kills += 1
	var type: Variant = enemy.get("_type")
	Quests.notify("kill", type["name"] if type is Dictionary else "")
	# A Szörnyek könyvébe a főellenségek a saját nevükkel kerülnek.
	Progress.add_kill(str(enemy.get("boss_name")) if enemy.is_in_group("boss") \
		else (str(type["name"]) if type is Dictionary else ""))
	if enemy.is_in_group("boss"):
		_on_boss_defeated(enemy)
	# Előbb az osztódás, hogy a harc ne érjen véget, mielőtt a kicsik megjelennek.
	_spawn_splits(enemy)
	_alive_enemies.erase(enemy)
	if _alive_enemies.is_empty():
		_finish_fight()


## Biztonsági háló harc közben: ha egy ellenség valahogy kikerült a szobából,
## visszarakjuk; ha már nincs élő ellenség, mindenképp véget ér a harc.
func _physics_process(delta: float) -> void:
	if not _fighting():
		return
	_check_left -= delta
	if _check_left > 0.0:
		return
	_check_left = CHECK_INTERVAL
	var bounds := Rect2(Vector2(rect.position) * TILE, Vector2(rect.size) * TILE)
	# A már törölt vagy halott ellenségeket kiszűrjük (törölt példányt nem lehet erase-elni).
	# A még fába sem került (épp megjelenő) ellenség életereje 0, de ő még nem halott.
	_alive_enemies = _alive_enemies.filter(func(enemy: Node2D) -> bool:
		return is_instance_valid(enemy) and (not enemy.is_inside_tree() or not enemy.get_node("Health").is_dead()))
	# Közös játékban az ajtók nyitva vannak: a szörnyek kijöhetnek a szobából utánad (a főellenség
	# nem, ő a termében marad).
	var roaming := NetLobby.is_playing(get_tree())
	for enemy in _alive_enemies:
		# (A báb helyét a gazda adja, azt nem igazítjuk.)
		if not enemy.is_inside_tree() or enemy.get("net_puppet"):
			continue
		if not bounds.has_point(enemy.global_position) and not (roaming and not enemy.is_in_group("boss")):
			enemy.global_position = safe_spawn_position(
				_random_spawn_point(_player.global_position if is_instance_valid(_player) else position))
		elif not _point_free(enemy.global_position):
			# Beszorult (falba, oszlopba): a legközelebbi szabad csempére kerül.
			enemy.global_position = safe_spawn_position(enemy.global_position)
	if _alive_enemies.is_empty():
		_finish_fight()


func _fighting() -> bool:
	return _fought and not _cleared


func _finish_fight() -> void:
	if _cleared:
		return
	_cleared = true
	Quests.notify("room")
	_set_doors_locked(false)
	if is_instance_valid(_stairs) and _stairs.call("is_locked"):
		_stairs.call("set_locked", false)
	if has_chest:
		_spawn_chest.call_deferred()
	cleared.emit()


## A láda a szoba közepéhez legközelebbi szabad csempén jelenik meg.
func _spawn_chest() -> void:
	for radius in range(0, 4):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var tile := anchor + Vector2i(dx, dy)
				if not _used_tiles.has(tile) and rect.grow(-1).has_point(tile):
					var chest := _add_at_tile(chest_scene, _pillars, tile)
					chest.set("depth", depth)
					return


func _set_doors_locked(locked: bool) -> void:
	# Közös játékban a szobák nem záródnak be: a társ bármikor utánad jöhet (és ki is futhatsz).
	# A szörnyek ilyenkor is a szobájukban maradnak (lásd _physics_process).
	if NetLobby.is_playing(get_tree()):
		return
	if not _doors.is_empty():
		Audio.play("door_lock" if locked else "door_unlock")
	for door in _doors:
		door.set_blocked(locked)
