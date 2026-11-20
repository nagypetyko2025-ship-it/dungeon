class_name SpecialRoom
extends Node2D
## Különleges szobák (a Dungeon sorsolja: Room.special; közös játékban és a gyakorló pályán nem jönnek):
## - "library": könyvtár — polcok a hátsó fal mentén és két szabadon álló polcsor, olvasópult, gyertyák, a padlón
##   könyvek. Csak díszlet: a harc a szokásos.
## - "prison": cellasor a hátsó falnál; minden cellában egy szörny, sötéten, mozdulatlanul (process kikapcsolva).
##   Belépéskor néhány rács magától kinyílik (néha 1-2, néha mind: _opened_count), és csak a kiszabadultakkal kell
##   megküzdeni; a zárt cellák lakói bent maradnak.
## - "frozen" (csak a Fagykőben, DungeonTheme.RANGES 41-80.): csúszós jégpadló (Player.on_ice), a szörnyek jégtömbben
##   állnak, és ha a közelükbe érsz (THAW_RANGE), kiolvadnak. Egy befagyott kalandor is áll a teremben: a harc végén a
##   jege szétreped, és egy (legalább epikus) tárgyat hagy.
## A Room._ready teszi be (a csapdák után, a díszek előtt), a harcot a Room._begin_fight adja át (begin_fight).

const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const SHEET: Texture2D = preload("res://assets/0x72_dungeon/0x72_DungeonTilesetII_v1.7.png")
const LECTERN: Texture2D = preload("res://assets/props/lectern.png")
const ICE_FLOOR: Texture2D = preload("res://assets/decor/ice_floor.png")
const FROST_SPARKLE: Texture2D = preload("res://assets/decor/frost_sparkle.png")
const FROST_MIST: Texture2D = preload("res://assets/decor/frost_mist.png")
const ITEM_DROP := preload("res://pickups/item_drop.tscn")

## Kenney RPG (16 px + 1 px hézag): teli könyvespolcok (felső és alsó változat), könyvek, gyertya, rácsos kapu.
const SHELVES: Array[Vector2i] = [Vector2i(43, 12), Vector2i(45, 12), Vector2i(46, 12), Vector2i(47, 12),
	Vector2i(48, 12), Vector2i(43, 14), Vector2i(45, 14), Vector2i(47, 14), Vector2i(49, 14), Vector2i(50, 14)]
const BOOKS: Array[Vector2i] = [Vector2i(46, 15), Vector2i(47, 15), Vector2i(48, 15), Vector2i(49, 15), Vector2i(50, 15)]
const CANDLE := Vector2i(19, 7)
const GATE_CLOSED := Vector2i(33, 3)
const GATE_OPEN := Vector2i(33, 4)
const MAX_CELLS := 6
const CELL_DARK := Color(0.45, 0.45, 0.5)
## A befagyott kalandor: a 0x72 lovag, jégkékre színezve.
const ADVENTURER := Rect2(128, 100, 16, 28)
## A befagyott alak: jégfehér, kicsit áttetsző (mint egy jégszobor), fagyos köddel és csillogással (_frost).
const ICE_TINT := Color(1.1, 1.4, 2.0, 0.85)
const THAW_RANGE := 90.0
const THAW_TIME := 0.5

var room: Room
## A cellák: {gate: Sprite2D, body: StaticBody2D, enemy: Node2D}.
var _cells: Array[Dictionary] = []
## A jégbe fagyott szörnyek (a kiolvadók kikerülnek belőle).
var _frozen: Array[Node2D] = []
var _adventurer: Node2D
var _ice_area: Area2D


func _ready() -> void:
	y_sort_enabled = true
	match room.special:
		"library": _build_library()
		"prison": _build_prison()
		"frozen": _build_frozen()


## A Room._begin_fight hívja: true = a harcot ez a szoba intézi (nem kell a szokásos szörnyidézés).
func begin_fight() -> bool:
	match room.special:
		"prison":
			_open_cells()
			return true
		"frozen":
			return true
	return false


# ---------------------------------------------------------------- könyvtár

func _build_library() -> void:
	var r := room.rect
	# A hátsó fal mentén végig polc (a felső ajtó előtt nem).
	for x in range(r.position.x, r.end.x):
		_shelf(Vector2i(x, r.position.y))
	# Két szabadon álló polcsor a terem közepének két oldalán, 3-3 polccal.
	for row: int in [-2, 2]:
		for side: int in [-1, 1]:
			for i in range(3, 6):
				_shelf(room.anchor + Vector2i(i * side, row))
	# Olvasópult a terem közepe fölött, két gyertyával.
	var pult := room.anchor + Vector2i(0, -3)
	if not room.is_tile_used(pult) and r.has_point(pult):
		var lectern := _sprite(LECTERN, Rect2(), pult)
		lectern.offset = Vector2(0, -6)
		_solid(pult)
		for dx: int in [-1, 1]:
			var tile := pult + Vector2i(dx, 0)
			if not room.is_tile_used(tile):
				_candle(tile)
	# Elszórt könyvek a padlón.
	var inner := r.grow(-1)
	for i in randi_range(5, 9):
		var tile := Vector2i(randi_range(inner.position.x, inner.end.x - 1), randi_range(inner.position.y, inner.end.y - 1))
		if room.is_tile_used(tile) or tile == room.anchor:
			continue
		var book_coords: Vector2i = BOOKS.pick_random()
		var book := _sprite(RPG, _rpg(book_coords), tile)
		book.scale = Vector2(1.2, 1.2)
		book.rotation = randf_range(-0.6, 0.6)
		book.position += Vector2(randf_range(-8, 8), randf_range(-6, 6))
		book.z_index = -7


func _shelf(tile: Vector2i) -> void:
	if room.is_tile_used(tile) or not room.is_away_from_doors(tile) or not room.rect.has_point(tile):
		return
	var coords: Vector2i = SHELVES.pick_random()
	_sprite(RPG, _rpg(coords), tile)
	_solid(tile)


func _candle(tile: Vector2i) -> void:
	var candle := _sprite(RPG, _rpg(CANDLE), tile)
	candle.position += Vector2(0, 6)


# ---------------------------------------------------------------- börtön

## A cellák a hátsó fal tövében: a cella a fal melletti csempe, előtte (eggyel lejjebb) a rács.
func _build_prison() -> void:
	var r := room.rect
	var xs: Array[int] = []
	for x in range(r.position.x + 1, r.end.x - 1, 2):
		var cell := Vector2i(x, r.position.y)
		var gate := cell + Vector2i.DOWN
		if room.is_tile_used(cell) or room.is_tile_used(gate) or not room.is_away_from_doors(cell) \
				or not room.is_away_from_doors(gate):
			continue
		xs.append(x)
	if xs.size() > MAX_CELLS:
		xs = xs.slice((xs.size() - MAX_CELLS) / 2, (xs.size() - MAX_CELLS) / 2 + MAX_CELLS)
	var taken := {}
	for x in xs:
		var cell := Vector2i(x, r.position.y)
		var gate_tile := cell + Vector2i.DOWN
		var enemy := _spawn(Room.tile_center(cell), taken)
		if enemy == null:
			continue
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		enemy.modulate = CELL_DARK
		var gate := _sprite(RPG, _rpg(GATE_CLOSED), gate_tile)
		gate.z_index = 1
		var body := _solid(gate_tile)
		_cells.append({"gate": gate, "body": body, "enemy": enemy})
		# A cellák két oldalán fal (hogy ne lehessen oldalról bemenni).
		for dx: int in [-1, 1]:
			var side := cell + Vector2i(dx, 0)
			if not room.is_tile_used(side):
				_solid(side)
	room.enemy_count = _cells.size()


## Hány rács nyílik ki: néha csak 1-2, néha mind, máskor valahány közte.
func _opened_count() -> int:
	var n := _cells.size()
	var roll := randf()
	if roll < 0.35:
		return mini(randi_range(1, 2), n)
	if roll < 0.65:
		return n
	return randi_range(mini(2, n), n)


func _open_cells() -> void:
	var order := _cells.duplicate()
	order.shuffle()
	var count := _opened_count()
	for i in count:
		var cell: Dictionary = order[i]
		# Azonnal a harc listájára (különben a szoba egy pillanatra üresnek látszana, és kitisztulna).
		room.track_enemy(cell["enemy"])
		var delay := 0.25 * i
		_open_cell.call_deferred(cell, delay)
	if count > 0:
		FloatingText.spawn(room, room.global_position + Vector2(0, -60),
			"A rácsok felnyílnak!" if count > 1 else "Egy rács felnyílik!", Color(1, 0.75, 0.45), 22)


func _open_cell(cell: Dictionary, delay: float) -> void:
	var enemy: Node2D = cell["enemy"]
	if not is_instance_valid(enemy):
		return
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout
	if not is_instance_valid(enemy):
		return
	Audio.play("door_unlock", -4.0)
	(cell["gate"] as Sprite2D).region_rect = _rpg(GATE_OPEN)
	(cell["body"] as Node).queue_free()
	enemy.process_mode = Node.PROCESS_MODE_INHERIT
	create_tween().tween_property(enemy, "modulate", Color.WHITE, 0.3)


# ---------------------------------------------------------------- fagyott terem

func _build_frozen() -> void:
	var r := room.rect
	# Jégpadló a terem egészén (áttetsző, a kő átlátszik).
	var ice := TextureRect.new()
	ice.texture = ICE_FLOOR
	ice.stretch_mode = TextureRect.STRETCH_TILE
	ice.position = room.local_pos(r.position) - Vector2(Room.TILE, Room.TILE) / 2.0
	ice.size = Vector2(r.size) * Room.TILE
	ice.z_index = -9
	ice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ice)
	# Csúszás: amíg a játékos a teremben van (Player.on_ice).
	_ice_area = Area2D.new()
	_ice_area.collision_layer = 0
	_ice_area.collision_mask = 2
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(r.size) * Room.TILE
	shape.shape = box
	shape.position = ice.position + box.size / 2.0
	_ice_area.add_child(shape)
	_ice_area.body_entered.connect(_set_ice.bind(true))
	_ice_area.body_exited.connect(_set_ice.bind(false))
	add_child(_ice_area)
	# A jégbe fagyott szörnyek.
	var taken := {}
	var far := Vector2(1e7, 1e7)
	for i in room.enemy_count:
		var enemy := _spawn(room._random_spawn_point(far, taken), taken)
		if enemy == null:
			continue
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		enemy.modulate = ICE_TINT
		enemy.add_child(_frost())
		_frozen.append(enemy)
	# A befagyott kalandor.
	for attempt in 20:
		var tile := Vector2i(randi_range(r.position.x + 1, r.end.x - 2), randi_range(r.position.y + 1, r.end.y - 2))
		if room.is_tile_used(tile) or tile == room.anchor or taken.has(tile):
			continue
		_adventurer = Node2D.new()
		_adventurer.position = room.local_pos(tile)
		add_child(_adventurer)
		var knight := Sprite2D.new()
		knight.texture = SHEET
		knight.region_enabled = true
		knight.region_rect = ADVENTURER
		knight.scale = Vector2(2, 2)
		knight.offset = Vector2(0, -6)
		knight.modulate = ICE_TINT
		_adventurer.add_child(knight)
		_adventurer.add_child(_frost())
		_solid(tile)
		break
	room.cleared.connect(_shatter_adventurer)


func _set_ice(body: Node2D, on: bool) -> void:
	if body.is_in_group("player"):
		body.set("on_ice", on)


func _physics_process(_delta: float) -> void:
	if _frozen.is_empty():
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	for enemy in _frozen.duplicate():
		if not is_instance_valid(enemy):
			_frozen.erase(enemy)
		elif enemy.is_inside_tree() and enemy.global_position.distance_to(player.global_position) <= THAW_RANGE:
			_frozen.erase(enemy)
			_thaw(enemy)


## Kiolvadás: a jég megremeg, szétreped, és a szörny megmozdul.
func _thaw(enemy: Node2D) -> void:
	var frost := enemy.get_node_or_null("Frost") as Node2D
	Audio.play("door_unlock", -6.0)
	# Megremeg (a szörny maga, mert a process ki van kapcsolva, a tween a szobán fut), aztán a dér elszáll.
	var base := enemy.position
	var shake := create_tween()
	for i in 5:
		shake.tween_property(enemy, "position:x", base.x + (3.0 if i % 2 == 0 else -3.0), THAW_TIME / 5.0)
	shake.tween_property(enemy, "position:x", base.x, 0.03)
	await shake.finished
	if not is_instance_valid(enemy):
		return
	if frost != null:
		frost.queue_free()
	enemy.process_mode = Node.PROCESS_MODE_INHERIT
	create_tween().tween_property(enemy, "modulate", Color.WHITE, 0.4)


func _shatter_adventurer() -> void:
	if not is_instance_valid(_adventurer):
		return
	Audio.play("door_unlock")
	FloatingText.spawn(room, _adventurer.global_position + Vector2(0, -50), "A jég szétreped...", Color(0.7, 0.9, 1), 20)
	var drop = ITEM_DROP.instantiate()
	drop.item = Items.random_item("legendary", "epic", room.depth)
	drop.position = _adventurer.global_position - room.global_position + Vector2(0, 20)
	room.add_child.call_deferred(drop)
	var tween := create_tween()
	tween.tween_property(_adventurer, "modulate:a", 0.0, 0.6)
	tween.tween_callback(_adventurer.queue_free)


func _exit_tree() -> void:
	var player := get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	if _ice_area != null and player != null:
		player.set("on_ice", false)


# ---------------------------------------------------------------- segédek

## A befagyott alak dere: halvány fagyos köd a lába körül és lassan villogó jégcsillogás (DCSS CC0 effektek).
func _frost() -> Node2D:
	var frost := Node2D.new()
	frost.name = "Frost"
	var mist := Sprite2D.new()
	mist.texture = FROST_MIST
	mist.modulate = Color(1, 1, 1, 0.55)
	mist.scale = Vector2(1.4, 0.8)
	mist.position = Vector2(0, -2)
	mist.z_index = -1
	frost.add_child(mist)
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 2.5)
	for i in 2:
		var frame := AtlasTexture.new()
		frame.atlas = FROST_SPARKLE
		frame.region = Rect2(i * 32, 0, 32, 32)
		frames.add_frame("default", frame)
	var sparkle := AnimatedSprite2D.new()
	sparkle.sprite_frames = frames
	sparkle.scale = Vector2(0.7, 0.7)
	sparkle.position = Vector2(randf_range(-8, 8), randf_range(-30, -18))
	sparkle.z_index = 2
	sparkle.process_mode = Node.PROCESS_MODE_ALWAYS
	sparkle.play()
	frost.add_child(sparkle)
	return frost


## Egy szörny (a mélység szokásos sorsolásával) a megadott helyen, a Room-on át (a harc listáján NINCS rajta:
## a börtönben a kinyíló cellák, a jégben mind rákerül a track_enemy-vel).
func _spawn(at: Vector2, taken: Dictionary) -> Node2D:
	var enemy := room.spawn_enemy_at(EnemyTypes.pick(room.depth), at, taken)
	if enemy == null:
		return null
	if room.special == "frozen":
		room.track_enemy(enemy)
	# A szörny megjelenési animációja (0-ról felnő) a kikapcsolt process miatt nem futna le: azonnal teljes méret.
	enemy.ready.connect(func() -> void:
		var visual := enemy.get("_visual") as Node2D
		if visual != null:
			visual.scale = Vector2.ONE * float(enemy.get("_size_scale")), CONNECT_ONE_SHOT)
	return enemy


func _rpg(coords: Vector2i) -> Rect2:
	return Rect2(Vector2(coords) * 17.0, Vector2(16, 16))


func _sprite(texture: Texture2D, region: Rect2, tile: Vector2i) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	if region.size != Vector2.ZERO:
		sprite.region_enabled = true
		sprite.region_rect = region
	sprite.scale = Vector2(2, 2)
	sprite.position = room.local_pos(tile)
	add_child(sprite)
	return sprite


func _solid(tile: Vector2i) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(28, 28)
	shape.shape = rectangle
	body.add_child(shape)
	body.position = room.local_pos(tile)
	add_child(body)
	room.mark_tile_used(tile)
	return body
