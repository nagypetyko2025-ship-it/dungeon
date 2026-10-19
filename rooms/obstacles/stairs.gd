extends Area2D
## Lépcső a következő szintre. Ha a játékos rálép, `used`-et jelez.

signal used

var _used := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _used or not body.is_in_group("player"):
		return
	_used = true
	Audio.play("stairs")
	used.emit()
