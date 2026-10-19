extends Node2D
## A bolt bejárata a szoba északi falában. Ha a játékos nekimegy,
## `entered`-et jelez: a Dungeon átviszi a bolt belsejébe.

## `return_position`: ide kerül vissza a játékos, ha kijön a boltból.
signal entered(return_position: Vector2)

## Ennyivel a bejárat alatt áll a játékos, amikor kijön (a bejárati területen kívül).
const RETURN_OFFSET := Vector2(0, 72)


func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Audio.play("door_unlock")
		entered.emit(global_position + RETURN_OFFSET)
