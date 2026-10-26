class_name Smithy
extends Node2D
## A tábori kovács kis bódéja (a tábor jobb alsó sarkában): csíkos ponyva két oszlopon,
## alatta lobogó kohó, üllő izzó vasdarabbal, mellette egy dézsa víz. A kovács (egy
## átszínezett törpe) folyamatosan kalapál: minden ütésnél szikra pattan és cseng az üllő.
## Előtte állva E-re nyílik a műhelye (a tábor kezeli, lásd SmithPanel).
## A tábor _entities rétegébe kerül (y-rendezés), a `tile` a bódé bal felső csempéje.

const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const SMITH_SHEET: Texture2D = preload("res://assets/characters/blacksmith.png")
const TILE := 32
## Kenney RPG lap (16 px + 1 px hézag): ponyva oszloppal (bal / jobb vég), oszlopok,
## kohó (két lángkocka), üllő.
const AWNING_LEFT := Vector2i(10, 1)
const AWNING_RIGHT := Vector2i(10, 2)
const POST_LEFT := Vector2i(10, 3)
const POST_RIGHT := Vector2i(11, 3)
const FORGE_FRAMES: Array[Vector2i] = [Vector2i(13, 0), Vector2i(14, 0)]
const ANVIL := Vector2i(15, 0)
## A 0x72 kalapács (a kovács kezében).
const HAMMER := Rect2(307, 39, 10, 24)
## A kalapács szöge: felemelve / lecsapva (radián, 0 = felfelé áll).
const RAISED := -0.9
const STRUCK := 1.1
## Ennél messzebbről már nem hallani az üllőt.
const HEARING := 420.0

var tile := Vector2i.ZERO

var _hammer_pivot: Node2D
var _sparks: CPUParticles2D
var _metal: Polygon2D
var _smith: AnimatedSprite2D


func _ready() -> void:
	y_sort_enabled = true
	_build_forge()
	_build_anvil()
	_build_smith()
	_build_tub()
	_build_roof()
	_start_hammering()


func _cell(offset: Vector2i) -> Vector2:
	return (Vector2(tile + offset) + Vector2(0.5, 0.5)) * TILE


func _rpg(coords: Vector2i) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = RPG
	texture.region = Rect2(Vector2(coords) * 17.0, Vector2(16, 16))
	return texture


## Egy tárgy a saját talppontjával (y-rendezéshez), opcionális ütközővel.
func _holder(at: Vector2, body_size := Vector2.ZERO) -> Node2D:
	var holder := Node2D.new()
	holder.position = at
	add_child(holder)
	if body_size != Vector2.ZERO:
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = body_size
		shape.shape = box
		shape.position = Vector2(0, -body_size.y / 2.0)
		body.add_child(shape)
		holder.add_child(body)
	return holder


func _sprite(texture: Texture2D, parent: Node, at: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(2, 2)
	sprite.position = at
	parent.add_child(sprite)
	return sprite


## A bódé hátsó-bal sarkában a kohó: két kockás lobogó tűz, meleg fény, szikrák.
func _build_forge() -> void:
	var holder := _holder(_cell(Vector2i(0, 2)) + Vector2(2, 12), Vector2(28, 14))
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 5.0)
	for coords in FORGE_FRAMES:
		frames.add_frame("default", _rpg(coords))
	var forge := AnimatedSprite2D.new()
	forge.sprite_frames = frames
	forge.scale = Vector2(2, 2)
	forge.position = Vector2(0, -16)
	forge.play()
	holder.add_child(forge)
	var light := _glow(Color(1, 0.6, 0.3), 1.1, 1.2)
	light.position = Vector2(0, -14)
	holder.add_child(light)
	var flicker := create_tween().set_loops()
	flicker.tween_property(light, "energy", 0.95, 0.16)
	flicker.tween_property(light, "energy", 1.35, 0.2)
	flicker.tween_property(light, "energy", 1.1, 0.14)
	var embers := CPUParticles2D.new()
	embers.amount = 6
	embers.lifetime = 1.2
	embers.direction = Vector2(0, -1)
	embers.spread = 20.0
	embers.gravity = Vector2(0, -15)
	embers.initial_velocity_min = 10.0
	embers.initial_velocity_max = 25.0
	embers.scale_amount_min = 1.5
	embers.scale_amount_max = 2.0
	embers.color = Color(1, 0.55, 0.2)
	embers.position = Vector2(0, -22)
	holder.add_child(embers)


func _glow(color: Color, size: float, energy: float) -> PointLight2D:
	var light := PointLight2D.new()
	var gradient := Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(0, 0, 0, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	light.texture = texture
	light.texture_scale = size
	light.energy = energy
	return light


## Az üllő a bódé jobb oldalán, rajta az izzó vasdarab; ide csapnak a szikrák.
func _build_anvil() -> void:
	var holder := _holder(_cell(Vector2i(2, 2)) + Vector2(-6, 12), Vector2(26, 10))
	_sprite(_rpg(ANVIL), holder, Vector2(0, -14))
	# Az izzó vasdarab az üllő tetején.
	_metal = Polygon2D.new()
	_metal.polygon = PackedVector2Array([Vector2(-9, -22), Vector2(5, -22), Vector2(7, -19), Vector2(-9, -19)])
	_metal.color = Color(1, 0.55, 0.15)
	holder.add_child(_metal)
	var glow := _glow(Color(1, 0.5, 0.2), 0.35, 0.8)
	glow.position = Vector2(-2, -20)
	holder.add_child(glow)
	_sparks = CPUParticles2D.new()
	_sparks.emitting = false
	_sparks.one_shot = true
	_sparks.explosiveness = 1.0
	_sparks.amount = 10
	_sparks.lifetime = 0.45
	_sparks.direction = Vector2(0, -1)
	_sparks.spread = 70.0
	_sparks.gravity = Vector2(0, 260)
	_sparks.initial_velocity_min = 60.0
	_sparks.initial_velocity_max = 120.0
	_sparks.scale_amount_min = 1.5
	_sparks.scale_amount_max = 2.5
	_sparks.color = Color(1, 0.8, 0.35)
	_sparks.position = Vector2(-2, -22)
	_sparks.z_index = 2
	holder.add_child(_sparks)


## A kovács az üllő bal oldalán, felé fordulva; a kalapács a jobb kezében.
func _build_smith() -> void:
	var holder := _holder(_cell(Vector2i(1, 2)) + Vector2(-8, 12), Vector2(14, 8))
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 5.0)
	for i in 4:
		var frame := AtlasTexture.new()
		frame.atlas = SMITH_SHEET
		frame.region = Rect2(i * 16, 0, 16, 28)
		frames.add_frame("default", frame)
	_smith = AnimatedSprite2D.new()
	_smith.sprite_frames = frames
	_smith.scale = Vector2(2, 2)
	_smith.offset = Vector2(0, -14)
	_smith.play()
	holder.add_child(_smith)
	_hammer_pivot = Node2D.new()
	_hammer_pivot.position = Vector2(8, -12)
	_hammer_pivot.rotation = RAISED
	holder.add_child(_hammer_pivot)
	var hammer := Sprite2D.new()
	var texture := AtlasTexture.new()
	texture.atlas = SpriteSheet.TEXTURE
	texture.region = HAMMER
	hammer.texture = texture
	hammer.scale = Vector2(1.2, 1.2)
	# A nyél vége a kézben (a forgáspontban), a feje felül.
	hammer.position = Vector2(0, -HAMMER.size.y * 1.2 / 2.0 + 3)
	_hammer_pivot.add_child(hammer)


## Fadézsa vízzel a bódé mellett; a víz tükre csillog.
func _build_tub() -> void:
	var holder := _holder(_cell(Vector2i(3, 2)) + Vector2(-4, 12), Vector2(30, 12))
	holder.add_child(WaterTub.new())


## A ponyva és az oszlopok legfelül (z), hogy a kovács feje fölött legyen a tető.
func _build_roof() -> void:
	var roof := Node2D.new()
	roof.z_index = 3
	add_child(roof)
	_sprite(_rpg(AWNING_LEFT), roof, _cell(Vector2i(0, 1)))
	# A középső elem: a szélső ponyva felső része (rojttal), oszlop nélkül.
	var middle := AtlasTexture.new()
	middle.atlas = RPG
	middle.region = Rect2(Vector2(AWNING_LEFT) * 17.0 + Vector2(3, 0), Vector2(13, 9))
	var mid := _sprite(middle, roof, _cell(Vector2i(1, 1)) + Vector2(0, -7))
	mid.scale = Vector2(32.0 / 13.0, 2)
	_sprite(_rpg(AWNING_RIGHT), roof, _cell(Vector2i(2, 1)))
	_sprite(_rpg(POST_LEFT), roof, _cell(Vector2i(0, 2)))
	_sprite(_rpg(POST_RIGHT), roof, _cell(Vector2i(2, 2)))


## Végtelen kalapálás: lassan felemeli, megáll, gyorsan lecsap (szikra, csengés), pihen.
func _start_hammering() -> void:
	var swing := create_tween().set_loops()
	swing.tween_property(_hammer_pivot, "rotation", RAISED, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	swing.tween_interval(0.12)
	swing.tween_property(_hammer_pivot, "rotation", STRUCK, 0.09).set_ease(Tween.EASE_IN)
	swing.tween_callback(_strike)
	swing.tween_interval(0.3)


func _strike() -> void:
	_sparks.restart()
	_metal.color = Color(1, 0.95, 0.6)
	create_tween().tween_property(_metal, "color", Color(1, 0.55, 0.15), 0.4)
	# A kovács egy kicsit "beleül" az ütésbe.
	var bob := create_tween()
	bob.tween_property(_smith, "position:y", 2.0, 0.05)
	bob.tween_property(_smith, "position:y", 0.0, 0.15)
	# Az üllő csak a közelben hallatszik, távolodva halkul.
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or not visible:
		return
	var distance := player.global_position.distance_to(_sparks.global_position)
	if distance < HEARING:
		Audio.play("anvil", lerpf(0.0, -18.0, distance / HEARING), 0.06)


## Fadézsa, a vízen mozgó csillanással.
class WaterTub:
	extends Node2D
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var wood := Color(0.45, 0.28, 0.16)
		var dark := Color(0.27, 0.16, 0.09)
		# Az oldala (dongák), alul kicsit keskenyebb.
		draw_colored_polygon(PackedVector2Array([Vector2(-15, -16), Vector2(15, -16), Vector2(13, 0), Vector2(-13, 0)]), wood)
		for x in [-8, 0, 8]:
			draw_line(Vector2(x, -15), Vector2(x * 0.9, -1), dark, 1.0)
		# Két vaspánt.
		draw_line(Vector2(-15, -11), Vector2(15, -11), Color(0.35, 0.36, 0.4), 2.0)
		draw_line(Vector2(-14, -4), Vector2(14, -4), Color(0.35, 0.36, 0.4), 2.0)
		# A pereme és a víz.
		_ellipse(Vector2(0, -16), Vector2(15, 6), dark)
		_ellipse(Vector2(0, -16), Vector2(12, 4.2), Color(0.2, 0.45, 0.75))
		var shimmer := sin(_t * 2.0) * 5.0
		_ellipse(Vector2(shimmer, -17), Vector2(3.5, 1.0), Color(0.75, 0.9, 1.0, 0.8))

	func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
		var points := PackedVector2Array()
		for i in 20:
			points.append(center + Vector2.from_angle(TAU * i / 20.0) * radius)
		draw_colored_polygon(points, color)
