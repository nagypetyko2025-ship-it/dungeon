extends Pickup
## Aranyérme, a ládákból esik.


func _collect(player: Node2D) -> bool:
	player.call("pick_up_gold", value)
	Audio.play("coin")
	return true
