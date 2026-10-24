extends Pickup
## A földre esett tárgy (ládából vagy ellenségből). A ritkasága színében
## világít; ha a játékos odaér, a táskájába kerül (ha van benne hely).

const GLOW_ENERGY := 0.9

## A tárgy (Items.create eredménye); a ládák/ellenségek állítják be.
var item := {}


func _ready() -> void:
	super._ready()
	var icon: Sprite2D = $Sprite2D
	icon.texture = Items.icon(item)
	var glow: PointLight2D = $Glow
	glow.color = Items.rarity_color(item)
	glow.energy = GLOW_ENERGY


func can_collect(player: Node2D) -> bool:
	var inventory: Inventory = player.get_node("Inventory")
	if inventory.bag.has(null):
		return true
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -20), "Tele a táskád!", Color(1, 0.5, 0.4))
	return false


func _collect(player: Node2D) -> bool:
	var inventory: Inventory = player.get_node("Inventory")
	if not inventory.add_item(item):
		FloatingText.spawn(get_parent(), global_position + Vector2(0, -20), "Tele a táskád!", Color(1, 0.5, 0.4))
		return false
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -20), item["name"], Items.rarity_color(item))
	Audio.play("item_pickup")
	return true
