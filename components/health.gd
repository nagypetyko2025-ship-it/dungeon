class_name Health
extends Node
## Életerő bárminek (játékos, ellenség, törhető tárgy).

signal changed(current: int, maximum: int)
signal died
## A találatot sikerült kikerülni.
signal dodged

@export var max_health := 10
## Másodpercenként ennyi HP töltődik vissza.
@export var regen_per_second := 0.0
## 0..1 közötti esély, hogy egy találat nem sebez.
@export_range(0.0, 1.0) var dodge_chance := 0.0
## Ha igaz, a sebzés legfeljebb 1 életig visz le (a gyakorló pályán a játékos nem halhat meg).
var cannot_die := false

var current := 0

var _regen_progress := 0.0


func _ready() -> void:
	current = max_health


func _process(delta: float) -> void:
	if regen_per_second <= 0.0 or is_dead() or current >= max_health:
		_regen_progress = 0.0
		return
	_regen_progress += regen_per_second * delta
	if _regen_progress >= 1.0:
		var amount := int(_regen_progress)
		_regen_progress -= amount
		heal(amount)


## Igazat ad vissza, ha a találat tényleg sebzett (kikerülni is lehet,
## kivéve ha `can_dodge` hamis, pl. lándzsás átütésnél).
func damage(amount: int, can_dodge := true) -> bool:
	if is_dead():
		return false
	if can_dodge and randf() < dodge_chance:
		dodged.emit()
		return false
	current = maxi(current - amount, 1 if cannot_die else 0)
	changed.emit(current, max_health)
	if current == 0:
		died.emit()
	return true


func heal(amount: int) -> void:
	if is_dead():
		return
	current = mini(current + amount, max_health)
	changed.emit(current, max_health)


## A maximum változását a jelenlegi HP is követi (növeléskor nő, csökkenéskor
## csökken, de nem hal bele). Így egy tárgy le- és felvételével nem lehet gyógyulni.
func set_max_health(value: int) -> void:
	var difference := value - max_health
	max_health = value
	if not is_dead():
		current = clampi(current + difference, 1, max_health)
	changed.emit(current, max_health)


func is_dead() -> bool:
	return current <= 0
