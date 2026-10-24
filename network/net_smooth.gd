class_name NetSmooth
extends RefCounted
## Távoli mozgó dolog (társ figurája, szörnybáb) sima követése a hálózati mintákból.
## A minta helyet és sebességet hoz; két minta között a sebességgel előre számolunk (legfeljebb
## MAX_AHEAD ideig), a megjelenített hely ugyanígy halad, és a maradék hibát fokozatosan dolgozza le.
## Így nincs a régi "célpont felé lassuló, aztán ugró" rángatás, és a késés is kisebb.

## Ennél tovább nem jósolunk előre (ha elmaradnak a minták, megáll).
const MAX_AHEAD := 0.12
## A hibát másodpercenként ilyen arányban dolgozza le.
const CORRECTION := 12.0
## Ekkora eltérésnél azonnal ugrik (teleport, ajtó, árnyéklépés).
const SNAP_DISTANCE := 120.0

var _position := Vector2.INF
var _velocity := Vector2.ZERO
var _age := 0.0


func has_sample() -> bool:
	return _position != Vector2.INF


## Új minta érkezett.
func receive(at: Vector2, velocity: Vector2) -> void:
	_position = at
	_velocity = velocity
	_age = 0.0


## A minta eltolása (pl. a helyben látott lökés, amíg a gazda válasza megjön).
func shift(offset: Vector2) -> void:
	if has_sample():
		_position += offset


## A becsült mostani hely.
func predicted() -> Vector2:
	return _position + _velocity * minf(_age, MAX_AHEAD)


## Egy lépés: a megjelenített helyből (`current`) az új megjelenített hely.
## `hold`: igaz, ha a jóslás most szünetel (pl. megütötték, áll).
func step(current: Vector2, delta: float, hold := false) -> Vector2:
	if not has_sample():
		return current
	_age += delta
	var target := _position if hold else predicted()
	if current.distance_to(target) > SNAP_DISTANCE:
		return target
	var moving := _velocity if not hold and _age <= MAX_AHEAD else Vector2.ZERO
	var next := current + moving * delta
	return next + (target - next) * minf(1.0, delta * CORRECTION)
