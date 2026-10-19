extends Hitbox
## A játékos nyílvesszője (íjjal): egyenesen repül a kurzor felé `max_distance`
## távolságig (ezt a Hatótáv adja), falba csapódva vagy ellenséget eltalálva eltűnik.
## A sebzést az ellenség Hurtboxa intézi, mint bármely Hitboxnál.

const SHEET: Texture2D = preload("res://assets/0x72_dungeon/0x72_DungeonTilesetII_v1.7.png")
const ARROW_REGION := Rect2(324, 202, 7, 21)

var direction := Vector2.RIGHT
var speed := 560.0
var max_distance := 420.0

var _travelled := 0.0


func _ready() -> void:
	# A játékos fegyvere (player_hitbox réteg); a falakat (1. réteg) figyeli.
	collision_layer = 8
	collision_mask = 1
	monitoring = true
	z_index = 3
	rotation = direction.angle()
	var sprite := Sprite2D.new()
	var texture := AtlasTexture.new()
	texture.atlas = SHEET
	texture.region = ARROW_REGION
	sprite.texture = texture
	sprite.rotation = PI / 2.0
	sprite.scale = Vector2(2, 2)
	add_child(sprite)
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(20, 8)
	shape.shape = box
	add_child(shape)
	body_entered.connect(func(_body: Node2D) -> void: queue_free())


func _physics_process(delta: float) -> void:
	var step := speed * delta
	position += direction * step
	_travelled += step
	# A repülés végén elhalványul.
	if _travelled > max_distance * 0.85:
		modulate.a = clampf((max_distance - _travelled) / (max_distance * 0.15), 0.0, 1.0)
	if _travelled >= max_distance:
		queue_free()


## A Hurtbox hívja, ha a nyíl talált.
func on_hit() -> void:
	queue_free()
