extends Area2D
## Tüskecsapda: ha a játékos rálép, kiugranak a tüskék és egyszer sebeznek.
## Újra csak akkor sebez, ha a játékos lelép, majd újra rálép.

const ACTIVE_TIME := 0.15
const REARM_TIME := 1.0
const FRAME_DOWN := 0
const FRAME_UP := 3

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D

var _armed := true


func _ready() -> void:
	_sprite.frame = FRAME_DOWN
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not _armed or not body.is_in_group("player"):
		return
	_armed = false
	_sprite.frame = FRAME_UP
	Audio.play("trap")
	_hitbox_shape.set_deferred("disabled", false)
	await get_tree().create_timer(ACTIVE_TIME, false).timeout
	_hitbox_shape.set_deferred("disabled", true)
	await get_tree().create_timer(REARM_TIME, false).timeout
	# Tüskék vissza: lejátsszuk visszafelé.
	_sprite.play_backwards("default")
	_armed = true
