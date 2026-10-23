class_name Door
extends StaticBody2D
## Folyosószáj lezárása harc közben: kiálló tüskék sora, amin nem lehet átmenni.

const SPIKES_UP := Rect2(64, 192, 16, 16)

## A lezárt csempék közepe (a szoba koordinátáiban).
var points: Array[Vector2] = []

var _shapes: Array[CollisionShape2D] = []
var _sprites: Array[Sprite2D] = []


func _init() -> void:
	collision_layer = 1
	collision_mask = 0
	z_index = -5
	# Vendel csontvázai átmennek rajta (lásd SkeletonMinion), és az útkereső háló sem számolja falnak.
	add_to_group("doors")


func setup(tile_points: Array[Vector2], tile_size: int) -> void:
	points = tile_points
	var texture := SpriteSheet.region(SPIKES_UP)
	for point in points:
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(tile_size, tile_size)
		shape.shape = rectangle
		shape.position = point
		add_child(shape)
		_shapes.append(shape)
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.scale = Vector2(2, 2)
		sprite.position = point
		add_child(sprite)
		_sprites.append(sprite)


func set_blocked(blocked: bool) -> void:
	for shape in _shapes:
		shape.set_deferred("disabled", not blocked)
	for sprite in _sprites:
		sprite.visible = blocked
