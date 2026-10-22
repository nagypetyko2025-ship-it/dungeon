extends Hitbox
## A játékos nyílvesszője (íjjal): egyenesen repül a kurzor felé `max_distance`
## távolságig (ezt a Hatótáv adja), falba csapódva vagy ellenséget eltalálva eltűnik.
## A sebzést az ellenség Hurtboxa intézi, mint bármely Hitboxnál.

const SHEET: Texture2D = preload("res://assets/0x72_dungeon/0x72_DungeonTilesetII_v1.7.png")
const ARROW_REGION := Rect2(324, 202, 7, 21)

var direction := Vector2.RIGHT
var speed := 560.0
var max_distance := 420.0
## A lövedék kinézete: "arrow" (nyíl), "orb" (lila varázsgömb), "fire" (tűzgolyó).
var look := "arrow"

var _travelled := 0.0


func _ready() -> void:
	# A játékos fegyvere (player_hitbox réteg); a falakat (1. réteg) figyeli.
	collision_layer = 8
	collision_mask = 1
	monitoring = true
	z_index = 3
	rotation = direction.angle()
	if look != "arrow":
		_build_magic_look()
		body_entered.connect(func(_body: Node2D) -> void: queue_free())
		return
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


## Varázsgömb / tűzgolyó: izzó gömb fénnyel (a tűzgolyónak lángcsóvája is van).
func _build_magic_look() -> void:
	var fire := look == "fire"
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 0.85, 0.4) if fire else Color(0.95, 0.75, 1))
	gradient.set_color(1, Color(0, 0, 0, 0))
	gradient.add_point(0.45, Color(1, 0.4, 0.1, 0.9) if fire else Color(0.65, 0.3, 1, 0.9))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	texture.width = 32
	texture.height = 32
	var orb := Sprite2D.new()
	orb.texture = texture
	orb.scale = Vector2(1.4, 1.4) if fire else Vector2(1.1, 1.1)
	add_child(orb)
	var trail := CPUParticles2D.new()
	trail.amount = 24
	trail.lifetime = 0.35
	trail.local_coords = false
	trail.direction = Vector2.LEFT
	trail.spread = 20.0
	trail.initial_velocity_min = 10.0
	trail.initial_velocity_max = 40.0
	trail.scale_amount_min = 2.0
	trail.scale_amount_max = 4.0 if fire else 3.0
	trail.color = Color(1, 0.55, 0.15) if fire else Color(0.8, 0.5, 1)
	add_child(trail)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0 if fire else 7.0
	shape.shape = circle
	add_child(shape)


## A Hurtbox hívja, ha a nyíl talált.
func on_hit() -> void:
	queue_free()
