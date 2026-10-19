extends Hitbox
## Nyílvessző: egyenesen repül, a játékost eltalálva (vagy falba, oszlopba
## csapódva) eltűnik. A sebzést a játékos Hurtboxa intézi, mint bármely Hitboxnál.

const LIFETIME := 3.0

var direction := Vector2.RIGHT
var speed := 300.0

var _life_left := LIFETIME


func _ready() -> void:
	# A Hitbox alapból nem figyel; a nyílnak érzékelnie kell a falakat.
	monitoring = true
	rotation = direction.angle()
	body_entered.connect(func(_body: Node2D) -> void: queue_free())


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_life_left -= delta
	if _life_left <= 0.0:
		queue_free()


## A Hurtbox hívja, ha a nyíl talált.
func on_hit() -> void:
	queue_free()
