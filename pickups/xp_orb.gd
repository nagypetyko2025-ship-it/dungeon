extends Pickup
## Kis zöld XP-gömb, az ellenségekből esik.


func _collect(player: Node2D) -> bool:
	player.call("add_xp", value)
	Audio.play("xp", 0.0, 0.2)
	return true
