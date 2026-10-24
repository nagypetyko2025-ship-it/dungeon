extends Pickup
## Zöld XP-gömb, az ellenségekből esik. Nagyobb értékű gömbök is vannak (lásd split): minél többet
## ér, annál sötétebb zöld és egy picivel nagyobb. (Közös játékban az érték a gazdától jön, a kinézet
## abból adódik, így mindenkinél ugyanolyan.)

## A gömbök értékei, a legnagyobbtól (egy szörny XP-je ezekre bomlik).
const SIZES: Array[int] = [10, 8, 5, 3, 1]
## Értékenként: szín (egyre sötétebb) és méret (egyre kicsit nagyobb).
const LOOKS := {
	1: [Color(1.3, 1.6, 1.3), 2.0],
	3: [Color(1.0, 1.35, 1.0), 2.15],
	5: [Color(0.78, 1.15, 0.8), 2.3],
	8: [Color(0.6, 0.95, 0.62), 2.45],
	10: [Color(0.45, 0.78, 0.5), 2.6],
}


## Egy szörny XP-je gömbökre bontva (a legnagyobbakkal kezdve), legfeljebb `max_orbs` darab:
## ha ennél több kellene, a maradékot az utolsó viszi.
static func split(total: int, max_orbs: int) -> Array[int]:
	var values: Array[int] = []
	var left := total
	for size in SIZES:
		while left >= size:
			values.append(size)
			left -= size
	while values.size() > max_orbs:
		var last: int = values.pop_back()
		values[values.size() - 1] += last
	return values


func _ready() -> void:
	var tier := 1
	for size in SIZES:
		if value >= size:
			tier = size
			break
	var look: Array = LOOKS[tier]
	var sprite := get_node("Sprite2D") as Sprite2D
	sprite.modulate = look[0]
	sprite.scale = Vector2.ONE * float(look[1])
	super._ready()


func _collect(player: Node2D) -> bool:
	player.call("add_xp", value)
	Audio.play("xp", 0.0, 0.2)
	return true
