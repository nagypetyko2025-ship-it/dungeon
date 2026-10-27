class_name RoomDecor
extends Node2D
## Egy szoba berendezése (csak látvány, és pár útban nem lévő akadály):
## fáklyák a hátsó falon, néha falikút, pókhálók a sarkokban, csontok / koponyák /
## vérfoltok a padlón, hordó- és ládakupacok a sarkokban. A mély sávokban (DungeonTheme, 21. / 41. emelettől)
## a fal, a kút és a fáklya a sáv színeiben, több a csont és a vér, és izzó repedések nyílnak a padlón.
## A Room hozza létre, miután az ajtók, oszlopok és csapdák már a helyükön vannak.

const TORCH := preload("res://rooms/decor/torch.tscn")
const SHEET: Texture2D = preload("res://assets/0x72_dungeon/0x72_DungeonTilesetII_v1.7.png")
const COBWEB: Texture2D = preload("res://assets/decor/cobweb.png")
const BONES: Texture2D = preload("res://assets/decor/bones.png")
const BLOOD: Texture2D = preload("res://assets/decor/blood.png")
const CONTAINERS: Texture2D = preload("res://assets/shop/barrels_and_boxes.png")

const SKULL := Rect2(288, 432, 16, 16)
const BARREL := Rect2(0, 0, 16, 16)
const BIG_CRATE := Rect2(16, 0, 16, 16)
const SMALL_CRATE := Rect2(32, 0, 16, 16)
## Falikút (0x72): teteje a fal tetején, közepe a falon, medencéje a padlón; 3 képkocka.
const FOUNTAIN_TOP := Rect2(64, 0, 16, 16)
const FOUNTAIN_MID := {"red": Vector2(64, 16), "blue": Vector2(64, 48)}
const FOUNTAIN_BASIN := {"red": Vector2(64, 32), "blue": Vector2(64, 64)}

const TORCH_SPACING := 4
const FOUNTAIN_CHANCE := 0.25
const TOP_COBWEB_CHANCE := 0.6
const BOTTOM_COBWEB_CHANCE := 0.3
const STACK_STEP := 13.0
## Néhány apró dísz, szobánként legfeljebb egy-egy, ennyi eséllyel: gyertyák a fal tövében
## (Kenney RPG, pislákoló fénnyel), lecsorgó nyálka (alatta tócsa) és eldobott bájitalos
## üveg (0x72). (Falizászló a falcsempék között már magától is van, lásd Dungeon.)
const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const CANDLE := Vector2i(19, 7)
const CANDLE_CHANCE := 0.3
const WALL_GOO := Rect2(64, 80, 16, 16)
const WALL_GOO_BASE := Rect2(64, 96, 16, 16)
const GOO_CHANCE := 0.2
const FLASKS: Array[Rect2] = [Rect2(288, 352, 16, 16), Rect2(304, 352, 16, 16), Rect2(320, 352, 16, 16)]
const FLASK_CHANCE := 0.3
## Elesett királyi őr: a 0x72 csontváz (fekve) és a lovagkard (rozsdásra színezve).
const FALLEN_SKELETON := Rect2(368, 88, 16, 16)
const GUARD_SWORD := Rect2(339, 98, 10, 29)
const FLOOR_Z := -7
## A mély sávokban: gyakoribb (véres / lila) falikút, több csont és vér, izzó repedések a padlón.
const DEEP_FOUNTAIN_CHANCE := 0.4
const DEEP_EXTRA_SCATTER := 3
## A Káoszkőben a vér sötét ibolya (nem vörös).
const ABYSS_BLOOD := Color(0.55, 0.32, 0.85)

var room: Room
var _band := 0
## A hátsó fal már foglalt oszlopai (fáklya, kút), hogy a falidíszek ne kerüljenek rájuk.
var _wall_used: Array[int] = []


func _ready() -> void:
	y_sort_enabled = true
	_band = DungeonTheme.band(room.depth)
	var fountain_x := _place_fountain()
	_wall_used.append(fountain_x)
	_place_torches(fountain_x)
	_place_wall_decor()
	_place_cobwebs()
	_place_clutter()
	_scatter_floor()
	_place_dropped_flask()
	_place_rifts()
	if room.fallen_guards > 0:
		_place_fallen_guards(room.fallen_guards)


## Falikút a hátsó fal bal oldalán (FOUNTAIN_CHANCE eséllyel). Az x-et adja vissza (vagy -99999).
func _place_fountain() -> int:
	var x := room.rect.position.x + 2
	var floor_tile := Vector2i(x, room.rect.position.y)
	if randf() >= (DEEP_FOUNTAIN_CHANCE if _band > 0 else FOUNTAIN_CHANCE) or room.is_tile_used(floor_tile):
		return -99999
	# A mélyben mindig a "vörös" kút: a sáv lapján vér (Vérkő) vagy izzó lila (Káoszkő).
	var color: String = "red" if _band > 0 else ["red", "blue"].pick_random()
	_sprite(FOUNTAIN_TOP, Vector2i(x, room.rect.position.y - 2), -4)
	_animated(FOUNTAIN_MID[color], Vector2i(x, room.rect.position.y - 1), -4)
	_animated(FOUNTAIN_BASIN[color], floor_tile, -4)
	_solid(floor_tile)
	room.mark_tile_used(floor_tile)
	return x


## Fáklyák a hátsó falon, egyenletesen, a folyosó / bolt / kút helyét kihagyva.
func _place_torches(fountain_x: int) -> void:
	var y := room.rect.position.y - 1
	var start := room.rect.position.x + 1 + randi() % 2
	for x in range(start, room.rect.end.x - 1, TORCH_SPACING):
		if room.has_opening(Vector2i.UP) and absi(x - room.anchor.x) <= 2:
			continue
		if room.has_shop and x >= room.anchor.x + Room.SHOP_OFFSET - 1 and x <= room.anchor.x + Room.SHOP_OFFSET + 2:
			continue
		if absi(x - fountain_x) <= 1:
			continue
		if x >= room.lift_x - 2 and x <= room.lift_x + 1:
			continue
		var torch: Node2D = TORCH.instantiate()
		torch.position = room.local_pos(Vector2i(x, y))
		add_child(torch)
		if _band > 0:
			(torch.get_node("AnimatedSprite2D") as AnimatedSprite2D).modulate = DungeonTheme.FLAME[_band]
			(torch.get_node("PointLight2D") as PointLight2D).color = DungeonTheme.TORCH_LIGHT[_band]
		_wall_used.append(x)


## Gyertyák a fal tövében és/vagy lecsorgó nyálka a hátsó falon, a fáklyák, a kút és a nyílások között.
func _place_wall_decor() -> void:
	var y := room.rect.position.y - 1
	for decor in ["candles", "goo"]:
		if randf() >= (CANDLE_CHANCE if decor == "candles" else GOO_CHANCE):
			continue
		var x := _free_wall_x()
		if x == -99999:
			return
		_wall_used.append(x)
		var base := Vector2i(x, room.rect.position.y)
		if decor == "candles":
			if not room.is_tile_used(base):
				_place_candles(base)
		else:
			_sprite(WALL_GOO, Vector2i(x, y), -4)
			if not room.is_tile_used(base):
				_sprite(WALL_GOO_BASE, base, FLOOR_Z)


## Két-három gyertya a padlón a fal tövében, halvány, pislákoló fénnyel (nem akadály).
func _place_candles(tile: Vector2i) -> void:
	var texture := AtlasTexture.new()
	texture.atlas = RPG
	texture.region = Rect2(Vector2(CANDLE) * 17.0, Vector2(16, 16))
	for i in randi_range(2, 3):
		var candle := _texture_sprite(texture, tile, FLOOR_Z + 1)
		candle.scale = Vector2(1.2, 1.2) * randf_range(0.8, 1.05)
		candle.position += Vector2(-12 + i * 11, -10 + (i % 2) * 6)
	var light := PointLight2D.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 0.75, 0.4))
	gradient.set_color(1, Color(0, 0, 0, 0))
	var glow := GradientTexture2D.new()
	glow.gradient = gradient
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.5)
	glow.fill_to = Vector2(0.5, 0.0)
	light.texture = glow
	light.texture_scale = 2.0
	light.energy = 0.6
	light.position = room.local_pos(tile) + Vector2(0, -14)
	add_child(light)
	var flicker := light.create_tween().set_loops()
	flicker.tween_property(light, "energy", 0.45, 0.2)
	flicker.tween_property(light, "energy", 0.7, 0.25)


## Egy szabad oszlop a hátsó falon (nem fáklya / kút mellett, nem nyílás, bolt vagy tárgylift fölött).
func _free_wall_x() -> int:
	var candidates: Array[int] = []
	for x in range(room.rect.position.x + 1, room.rect.end.x - 1):
		if room.has_opening(Vector2i.UP) and absi(x - room.anchor.x) <= 2:
			continue
		if room.has_shop and x >= room.anchor.x + Room.SHOP_OFFSET - 1 and x <= room.anchor.x + Room.SHOP_OFFSET + 2:
			continue
		if x >= room.lift_x - 2 and x <= room.lift_x + 1:
			continue
		var near_used := false
		for used in _wall_used:
			if absi(x - used) <= 1:
				near_used = true
		if not near_used:
			candidates.append(x)
	if candidates.is_empty():
		return -99999
	return candidates[randi() % candidates.size()]


## Egy eldobott (felborult) bájitalos üveg valahol a padlón, harci szobákban.
func _place_dropped_flask() -> void:
	if room.enemy_count <= 0 or randf() >= FLASK_CHANCE:
		return
	var inner := room.rect.grow(-1)
	for attempt in 10:
		var tile := Vector2i(randi_range(inner.position.x, inner.end.x - 1), randi_range(inner.position.y, inner.end.y - 1))
		if room.is_tile_used(tile) or tile == room.anchor:
			continue
		var flask := _sprite(FLASKS.pick_random(), tile, FLOOR_Z)
		flask.rotation = deg_to_rad([90.0, -90.0].pick_random())
		flask.scale *= 0.8
		flask.position += Vector2(randf_range(-6, 6), randf_range(-4, 6))
		return


## Elesett királyi őrök (Gáspár emberei): fekvő, megfakult csontváz, mellette a rozsdás
## kardja, körülötte csontok vagy rég megszáradt vér. Csak látvány, nem akadály.
func _place_fallen_guards(count: int) -> void:
	var inner := room.rect.grow(-2)
	var taken := {}
	for i in count:
		for attempt in 20:
			var tile := Vector2i(randi_range(inner.position.x, inner.end.x - 1), randi_range(inner.position.y, inner.end.y - 1))
			if room.is_tile_used(tile) or tile == room.anchor or taken.has(tile) \
					or taken.has(tile + Vector2i.LEFT) or taken.has(tile + Vector2i.RIGHT):
				continue
			taken[tile] = true
			var side := -1.0 if randf() < 0.5 else 1.0
			var body := _sprite(FALLEN_SKELETON, tile, FLOOR_Z + 1)
			body.rotation = PI / 2.0 * side
			body.modulate = Color(0.72, 0.68, 0.62)
			body.position += Vector2(randf_range(-6, 6), randf_range(-2, 6))
			var sword := _sprite(GUARD_SWORD, tile, FLOOR_Z)
			sword.rotation = deg_to_rad(randf_range(50, 130)) * side
			sword.modulate = Color(0.62, 0.48, 0.38)
			sword.scale = Vector2(1.5, 1.5)
			sword.position += Vector2(18 * side, randf_range(4, 12))
			var extra := _texture_sprite(BONES if randf() < 0.5 else BLOOD, tile, FLOOR_Z - 1)
			extra.modulate = Color(0.6, 0.55, 0.5, 0.85)
			extra.flip_h = randf() < 0.5
			extra.position += Vector2(randf_range(-14, 14), randf_range(8, 16))
			break


func _place_cobwebs() -> void:
	var r := room.rect
	var corners := [
		[Vector2i(r.position.x, r.position.y), false, false, TOP_COBWEB_CHANCE],
		[Vector2i(r.end.x - 1, r.position.y), true, false, TOP_COBWEB_CHANCE],
		[Vector2i(r.position.x, r.end.y - 1), false, true, BOTTOM_COBWEB_CHANCE],
		[Vector2i(r.end.x - 1, r.end.y - 1), true, true, BOTTOM_COBWEB_CHANCE],
	]
	for corner in corners:
		if randf() < corner[3]:
			var web := _texture_sprite(COBWEB, corner[0], FLOOR_Z + 1)
			web.flip_h = corner[1]
			web.flip_v = corner[2]
			web.modulate.a = 0.85


## Hordó- és ládakupacok 1-2 sarokban (L alakban a fal mellett, így nem zárnak el utat).
func _place_clutter() -> void:
	if room.enemy_count <= 0 and not room.has_chest:
		return
	var r := room.rect
	var corners := [
		[Vector2i(r.position.x, r.position.y + 1), Vector2i(1, 0), Vector2i(0, 1)],
		[Vector2i(r.end.x - 1, r.position.y + 1), Vector2i(-1, 0), Vector2i(0, 1)],
		[Vector2i(r.position.x, r.end.y - 1), Vector2i(1, 0), Vector2i(0, -1)],
		[Vector2i(r.end.x - 1, r.end.y - 1), Vector2i(-1, 0), Vector2i(0, -1)],
	]
	corners.shuffle()
	for i in randi_range(2, 3):
		var corner: Vector2i = corners[i][0]
		var along: Vector2i = corners[i][1]
		var up: Vector2i = corners[i][2]
		var tiles: Array[Vector2i] = [corner, corner + along, corner + up]
		if tiles.any(func(t: Vector2i) -> bool: return room.is_tile_used(t) or not room.is_away_from_doors(t)):
			continue
		_barrel_stack(tiles[0], randi_range(1, 3))
		if randf() < 0.5:
			_crate(tiles[1], BIG_CRATE)
		else:
			_barrel_stack(tiles[1], randi_range(1, 2))
		if randf() < 0.6:
			_crate(tiles[2], SMALL_CRATE)


## Csontok, koponyák és vérfoltok szétszórva a padlón (nem akadályoznak).
func _scatter_floor() -> void:
	var count := randi_range(2, 3) if room.enemy_count <= 0 else randi_range(5, 9)
	if _band > 0:
		count += DEEP_EXTRA_SCATTER
	var inner := room.rect.grow(-1)
	for i in count:
		for attempt in 10:
			var tile := Vector2i(randi_range(inner.position.x, inner.end.x - 1),
				randi_range(inner.position.y, inner.end.y - 1))
			if room.is_tile_used(tile) or tile == room.anchor:
				continue
			var pick := randi() % 3
			var sprite: Sprite2D
			if pick == 0:
				sprite = _sprite(SKULL, tile, FLOOR_Z)
				sprite.scale *= 0.8
			elif pick == 1:
				sprite = _texture_sprite(BONES, tile, FLOOR_Z)
			else:
				sprite = _texture_sprite(BLOOD, tile, FLOOR_Z)
				if _band == 2:
					sprite.modulate = ABYSS_BLOOD
			sprite.flip_h = randf() < 0.5
			sprite.position += Vector2(randf_range(-8, 8), randf_range(-8, 8))
			break


## Izzó repedések a padlón a mély sávokban (DungeonTheme.add_rift): harci szobában 1-2 (a Káoszkőben 2-3).
func _place_rifts() -> void:
	if _band == 0:
		return
	var count := randi_range(1, 2) + (1 if _band == 2 else 0)
	if room.enemy_count <= 0:
		count = randi_range(0, 1)
	var inner := room.rect.grow(-2)
	for i in count:
		for attempt in 10:
			var tile := Vector2i(randi_range(inner.position.x, inner.end.x - 1), randi_range(inner.position.y, inner.end.y - 1))
			if room.is_tile_used(tile) or tile == room.anchor:
				continue
			DungeonTheme.add_rift(room.depth, self, room.local_pos(tile), FLOOR_Z + 1)
			break


func _barrel_stack(tile: Vector2i, count: int) -> void:
	for i in count:
		var barrel := _container(BARREL, tile)
		barrel.offset.y = -i * STACK_STEP / 2.0
		barrel.z_index = i
	_solid(tile)


func _crate(tile: Vector2i, region: Rect2) -> void:
	_container(region, tile)
	_solid(tile)


func _container(region: Rect2, tile: Vector2i) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = CONTAINERS
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.scale = Vector2(2, 2)
	sprite.position = room.local_pos(tile)
	add_child(sprite)
	return sprite


## Képrészlet a 0x72 lapról egy csempe közepén.
func _sprite(region: Rect2, tile: Vector2i, z: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = DungeonTheme.sheet_for(region, room.depth)
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.scale = Vector2(2, 2)
	sprite.position = room.local_pos(tile)
	sprite.z_index = z
	add_child(sprite)
	return sprite


func _texture_sprite(texture: Texture2D, tile: Vector2i, z: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(2, 2)
	sprite.position = room.local_pos(tile)
	sprite.z_index = z
	add_child(sprite)
	return sprite


## 3 képkockás animáció a 0x72 lapról (a képkockák egymás mellett, 16 px-enként).
func _animated(first: Vector2, tile: Vector2i, z: int) -> void:
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 6.0)
	for i in 3:
		var frame := AtlasTexture.new()
		frame.region = Rect2(first + Vector2(i * 16, 0), Vector2(16, 16))
		frame.atlas = DungeonTheme.sheet_for(frame.region, room.depth)
		frames.add_frame("default", frame)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.scale = Vector2(2, 2)
	sprite.position = room.local_pos(tile)
	sprite.z_index = z
	add_child(sprite)
	sprite.play()


func _solid(tile: Vector2i) -> void:
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
