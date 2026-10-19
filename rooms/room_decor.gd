class_name RoomDecor
extends Node2D
## Egy szoba berendezése (csak látvány, és pár útban nem lévő akadály):
## fáklyák a hátsó falon, néha falikút, pókhálók a sarkokban, csontok / koponyák /
## vérfoltok a padlón, hordó- és ládakupacok a sarkokban.
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
const FLOOR_Z := -7

var room: Room


func _ready() -> void:
	y_sort_enabled = true
	var fountain_x := _place_fountain()
	_place_torches(fountain_x)
	_place_cobwebs()
	_place_clutter()
	_scatter_floor()


## Falikút a hátsó fal bal oldalán (FOUNTAIN_CHANCE eséllyel). Az x-et adja vissza (vagy -99999).
func _place_fountain() -> int:
	var x := room.rect.position.x + 2
	var floor_tile := Vector2i(x, room.rect.position.y)
	if randf() >= FOUNTAIN_CHANCE or room.is_tile_used(floor_tile):
		return -99999
	var color: String = ["red", "blue"].pick_random()
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
			sprite.flip_h = randf() < 0.5
			sprite.position += Vector2(randf_range(-8, 8), randf_range(-8, 8))
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
	sprite.texture = SHEET
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
		frames.add_frame("default", SpriteSheet.region(Rect2(first + Vector2(i * 16, 0), Vector2(16, 16))))
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
