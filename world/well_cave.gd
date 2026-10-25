class_name WellCave
extends Node2D
## A kút alja (Lőrinc megmentése után a kútnál E-vel lemászhatsz): a létra alatti kis aknából
## egy szűk folyosó vezet egy nagyobb, nyirkos terembe. A terem túlsó végén egy régi járat
## nyílik a Mélység felé, de be van omolva. Mohos kőfalak, kőpadló, víz, fű, kövek, csontok;
## felülről a kút szája ad egy kis fényt. (A tábor építi fel, a Ruin hívja: enter().)

signal message(text: String)

const TILE := 32
const PUNY: Texture2D = preload("res://assets/decor/puny_dungeon.png")
const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const LADDER: Texture2D = preload("res://assets/props/ladder.png")
const BONES: Texture2D = preload("res://assets/decor/bones.png")
const COBWEB: Texture2D = preload("res://assets/decor/cobweb.png")

## A barlang részei (csempékben, messze a pályától): akna, folyosó, terem.
const SHAFT := Rect2i(360, 0, 5, 5)
const CORRIDOR := Rect2i(365, 2, 10, 2)
const CHAMBER := Rect2i(375, -3, 16, 12)
const LADDER_TILE := Vector2i(362, 0)
## A beomlott járat a terem keleti falán, középen.
const COLLAPSE_TILE := Vector2i(390, 2)
const BOUNDS := Rect2i(356, -7, 40, 20)

const CAVE_LIGHT := Color(0.32, 0.34, 0.4)
const LANTERN := 0.8
const INTERACT_RANGE := 56.0

## Puny Dungeon (CC0) csempék: kőpadló, mohos fal (teteje fűvel), lefolyórács csöpögő vízzel.
const FLOOR_TILES: Array[Vector2i] = [Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 1), Vector2i(4, 2), Vector2i(7, 3),
	Vector2i(5, 3)]
const WALL_TOP := Vector2i(8, 0)
const WALL_FACE := Vector2i(8, 1)
const GRATE := Vector2i(8, 3)
const MOSS := Vector2i(3, 10)
## Kenney RPG (CC0): bokrok, virágok a nedves sarkokban.
const BUSHES: Array[Vector2i] = [Vector2i(19, 9), Vector2i(21, 9), Vector2i(24, 9)]
const FLOWERS: Array[Vector2i] = [Vector2i(28, 9), Vector2i(29, 9), Vector2i(28, 10)]

var _camp: Node2D
var _player: Node2D
var _entities: Node2D
var _prompt: Label
var _inside := false
var _busy := false
var _floor := {}
var _rng := RandomNumberGenerator.new()


func setup(camp: Node2D) -> void:
	_camp = camp
	_entities = camp.get_node("Entities")
	_player = camp.get_node("Entities/Player")


func build() -> void:
	_rng.seed = 4242
	for rect in [SHAFT, CORRIDOR, CHAMBER]:
		for x in range(rect.position.x, rect.end.x):
			for y in range(rect.position.y, rect.end.y):
				_floor[Vector2i(x, y)] = true
	_build_floor()
	_build_walls()
	_build_shaft()
	_build_chamber()
	_build_collapse()
	_build_ui()


func _build_floor() -> void:
	for tile: Vector2i in _floor:
		var sprite := _puny(FLOOR_TILES[_rng.randi() % FLOOR_TILES.size()], tile, -10)
		var shade := _rng.randf_range(0.7, 0.9)
		sprite.modulate = Color(shade, shade * 1.02, shade)
		if _rng.randf() < 0.12:
			_puny(MOSS, tile, -9).modulate = Color(1, 1, 1, _rng.randf_range(0.25, 0.5))


## Fal minden nem-padló csempén a padló körül: ahol alatta padló van, mohos falfelület (fölötte
## fűvel benőtt perem), máshol sötét szikla. Mind szilárd.
func _build_walls() -> void:
	var done := {}
	for tile: Vector2i in _floor:
		for dx in range(-1, 2):
			for dy in range(-2, 2):
				var wall := tile + Vector2i(dx, dy)
				if _floor.has(wall) or done.has(wall):
					continue
				done[wall] = true
				if _floor.has(wall + Vector2i.DOWN):
					_puny(WALL_FACE + Vector2i(_rng.randi() % 8, 0), wall, -9)
				elif _floor.has(wall + Vector2i(0, 2)):
					_puny(WALL_TOP + Vector2i(_rng.randi() % 8, 0), wall, -9)
				else:
					var rock := ColorRect.new()
					rock.color = Color(0.07, 0.07, 0.09)
					rock.position = Vector2(wall) * TILE
					rock.size = Vector2(TILE, TILE)
					rock.z_index = -9
					add_child(rock)
				_solid(Rect2(Vector2(wall) * TILE, Vector2(TILE, TILE)))
	# Körben sötétség (a kamera szélén se látsszon a semmi).
	var dark := ColorRect.new()
	dark.color = Color(0.03, 0.03, 0.04)
	dark.position = Vector2(BOUNDS.position) * TILE
	dark.size = Vector2(BOUNDS.size) * TILE
	dark.z_index = -11
	add_child(dark)


## Az akna: a létra lóg le a kút szájából, felülről halvány fény; a földön a régi kötél, csiga-héjak.
func _build_shaft() -> void:
	var ladder := Sprite2D.new()
	ladder.texture = LADDER
	ladder.scale = Vector2(2, 2)
	ladder.position = _center(LADDER_TILE) + Vector2(0, -10)
	ladder.z_index = -5
	add_child(ladder)
	_light(_center(LADDER_TILE + Vector2i(0, 1)), Color(0.75, 0.85, 1.0), 1.6, 0.9)
	# A szakadt kötél a földön (Lőrincé).
	var rope := Line2D.new()
	rope.width = 3.0
	rope.default_color = Color(0.55, 0.42, 0.25)
	for i in 7:
		rope.add_point(_center(SHAFT.position + Vector2i(3, 3)) + Vector2(i * 7, sin(i * 1.3) * 5))
	rope.z_index = -8
	add_child(rope)
	_puddle(_center(SHAFT.position + Vector2i(1, 3)), Vector2(26, 10), false)
	_bones(SHAFT.position + Vector2i(4, 4))
	_cobweb(SHAFT.position, false)
	_cobweb(Vector2i(SHAFT.end.x - 1, SHAFT.position.y), true)


## A terem: tó a közepén, körülötte fű és virág, kövek, lefolyórácsok a falon, csontok.
func _build_chamber() -> void:
	var r := CHAMBER
	_puddle(_center(Vector2i(r.position.x + 7, r.position.y + 6)), Vector2(120, 52), true)
	_light(_center(Vector2i(r.position.x + 7, r.position.y + 6)), Color(0.45, 0.7, 1.0), 1.8, 0.45)
	for x in [r.position.x + 2, r.position.x + 7, r.position.x + 12]:
		_puny(GRATE, Vector2i(x, r.position.y - 1), -8)
	for i in 26:
		var tile := Vector2i(_rng.randi_range(r.position.x, r.end.x - 1), _rng.randi_range(r.position.y, r.end.y - 1))
		var near_pool := Vector2(tile).distance_to(Vector2(r.position.x + 7, r.position.y + 6)) < 6.0
		var near_wall := tile.x <= r.position.x + 1 or tile.x >= r.end.x - 2 or tile.y >= r.end.y - 2
		if not (near_pool or near_wall):
			continue
		var at := _center(tile) + Vector2(_rng.randf_range(-10, 10), _rng.randf_range(-8, 8))
		if _rng.randf() < 0.55:
			_rpg(BUSHES[_rng.randi() % BUSHES.size()], at, -7).modulate = Color(0.7, 0.85, 0.7)
		else:
			_rpg(FLOWERS[_rng.randi() % FLOWERS.size()], at, -7).modulate = Color(0.75, 0.8, 0.9)
	for i in 9:
		var tile := Vector2i(_rng.randi_range(r.position.x + 1, r.end.x - 2), _rng.randi_range(r.position.y + 1, r.end.y - 2))
		var stone := _sprite(PUNY, Rect2(256 + 16 * (i % 4), 208, 16, 16), _center(tile), -6)
		stone.scale = Vector2.ONE * _rng.randf_range(1.2, 1.9)
		stone.modulate = Color(0.75, 0.75, 0.8)
	_bones(Vector2i(r.position.x + 2, r.end.y - 2))
	_bones(Vector2i(r.end.x - 4, r.position.y + 1))
	_cobweb(r.position, false)
	_cobweb(Vector2i(r.end.x - 1, r.position.y), true)
	_cobweb(Vector2i(r.position.x, r.end.y - 1), false, true)
	# Csöpögő víz a folyosó plafonjáról: kis pocsolya.
	_puddle(_center(Vector2i(CORRIDOR.position.x + 5, CORRIDOR.position.y + 1)), Vector2(20, 8), false)


## A beomlott járat: sötét boltív a keleti falban, előtte kőtörmelék és lezuhant gerendák.
func _build_collapse() -> void:
	var opening := ColorRect.new()
	opening.color = Color(0.02, 0.02, 0.03)
	opening.position = Vector2(COLLAPSE_TILE + Vector2i(1, -1)) * TILE + Vector2(0, 8)
	opening.size = Vector2(TILE, TILE * 3 - 16)
	opening.z_index = -8
	add_child(opening)
	var heap := Ruin.RubbleHeap.new()
	heap.position = _center(COLLAPSE_TILE)
	heap.z_index = 0
	for i in 26:
		heap.stones.append([Vector2(_rng.randf_range(-40, 30), _rng.randf_range(-50, 50)), _rng.randf_range(7, 14),
			_rng.randf_range(0.35, 0.55), _rng.randf()])
	heap.stones.sort_custom(func(a: Array, b: Array) -> bool: return a[0].y < b[0].y)
	add_child(heap)
	for beam: Array in [[Vector2(-6, -30), 1.1], [Vector2(4, 20), -0.9]]:
		var plank := ColorRect.new()
		plank.color = Color(0.28, 0.19, 0.12)
		plank.size = Vector2(70, 8)
		plank.pivot_offset = plank.size / 2.0
		plank.position = _center(COLLAPSE_TILE) + beam[0] - plank.size / 2.0
		plank.rotation = beam[1]
		plank.z_index = 1
		add_child(plank)
	_solid(Rect2(Vector2(COLLAPSE_TILE - Vector2i(1, 2)) * TILE, Vector2(2 * TILE, 5 * TILE)))


# ---------------------------------------------------------------- belépés, irányítás

## A kútnál E (Ruin hívja): lemászás a létrán.
func enter() -> void:
	_move(true, _center(LADDER_TILE + Vector2i(0, 2)))


func _move(inside: bool, at: Vector2) -> void:
	_busy = true
	_inside = inside
	Audio.play("footstep", -2.0)
	var limits := Rect2(Vector2(BOUNDS.position) * TILE, Vector2(BOUNDS.size) * TILE) if inside else Rect2()
	_camp.call("teleport_player", at, limits, CAVE_LIGHT if inside else Color.BLACK)
	await get_tree().create_timer(0.25).timeout
	_player.get_node("PointLight2D").energy = LANTERN if inside else 0.5
	await get_tree().create_timer(0.35).timeout
	_busy = false


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


func _focus() -> Array:
	if not _inside or _busy or not is_instance_valid(_player):
		return []
	var at: Vector2 = _player.global_position
	if at.distance_to(_center(LADDER_TILE + Vector2i(0, 1))) < INTERACT_RANGE:
		return ["up", "[E] Felmászás a létrán"]
	if at.distance_to(_center(COLLAPSE_TILE)) < INTERACT_RANGE + 70:
		return ["collapse", "[E] Beomlott járat"]
	return []


func _process(delta: float) -> void:
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
	match focus[0]:
		"up":
			var ruin := _camp.get_node("Ruin")
			_move(false, ruin.call("well_exit_position"))
		"collapse":
			Audio.play("door_lock", -6.0)
			message.emit("A járat be van omolva. Mögüle hideg szél fúj... a Mélység felől. "
				+ "Egy dinamit beomlaszthatná az egészet.")


# ---------------------------------------------------------------- segédek

func _center(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE


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


func _puny(coords: Vector2i, tile: Vector2i, z: int) -> Sprite2D:
	return _sprite(PUNY, Rect2(Vector2(coords) * 16.0, Vector2(16, 16)), _center(tile), z)


func _rpg(coords: Vector2i, at: Vector2, z: int) -> Sprite2D:
	return _sprite(RPG, Rect2(Vector2(coords) * 17.0, Vector2(16, 16)), at, z)


func _solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	add_child(body)


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


## Víz: a nagy tó szilárd (nem lehet átgázolni), a kis pocsolyák nem.
func _puddle(at: Vector2, size: Vector2, solid: bool) -> void:
	var water := Water.new()
	water.size = size
	water.position = at
	water.z_index = -8
	add_child(water)
	if solid:
		_solid(Rect2(at - size * 0.75, size * 1.5))


func _bones(tile: Vector2i) -> void:
	var bones := Sprite2D.new()
	bones.texture = BONES
	bones.scale = Vector2(2, 2)
	bones.position = _center(tile)
	bones.modulate = Color(0.7, 0.7, 0.68)
	bones.z_index = -7
	add_child(bones)


func _cobweb(tile: Vector2i, flip_h: bool, flip_v := false) -> void:
	var web := Sprite2D.new()
	web.texture = COBWEB
	web.scale = Vector2(2, 2)
	web.position = _center(tile)
	web.flip_h = flip_h
	web.flip_v = flip_v
	web.modulate = Color(1, 1, 1, 0.7)
	web.z_index = -7
	add_child(web)


## Sötét, csillogó víz (lassan hullámzó partvonallal és fénycsíkokkal).
class Water:
	extends Node2D
	var size := Vector2(40, 16)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var points := PackedVector2Array()
		for i in 28:
			var angle := TAU * i / 28.0
			var wobble := 1.0 + 0.05 * sin(angle * 4.0 + _t * 1.5)
			points.append(Vector2.from_angle(angle) * size * wobble)
		draw_colored_polygon(points, Color(0.08, 0.16, 0.24, 0.92))
		var inner := PackedVector2Array()
		for p in points:
			inner.append(p * 0.75)
		draw_colored_polygon(inner, Color(0.12, 0.26, 0.38, 0.8))
		for i in 4:
			var y := -size.y * 0.4 + i * size.y * 0.25
			var x := sin(_t * 1.2 + i) * size.x * 0.2
			draw_line(Vector2(x - size.x * 0.18, y), Vector2(x + size.x * 0.18, y), Color(0.6, 0.8, 1, 0.35), 1.5)
