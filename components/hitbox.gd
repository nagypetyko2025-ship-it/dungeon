class_name Hitbox
extends Area2D
## Sebző terület (kard, ellenség teste, lövedék). A Hurtbox érzékeli.
## Ha `crit_chance` > 0, minden találatnál külön dobás dönti el, hogy kritikus-e.

@export var damage := 1
@export var knockback := 200.0
## 0..1 esély a kritikus találatra.
@export_range(0.0, 1.0) var crit_chance := 0.0
@export var crit_multiplier := 1.5
## Átütés: ezt a találatot nem lehet kikerülni (pl. lándzsa).
@export var ignore_dodge := false


func _init() -> void:
	monitoring = false


## Egy találat sebzése: {"damage": int, "crit": bool, "pierce": bool}.
func roll_hit() -> Dictionary:
	if randf() < crit_chance:
		return {"damage": roundi(damage * crit_multiplier), "crit": true, "pierce": ignore_dodge}
	return {"damage": damage, "crit": false, "pierce": ignore_dodge}
