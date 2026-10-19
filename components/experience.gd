class_name Experience
extends Node
## Tapasztalat és karakterszint. Az első szintlépéshez BASE_XP kell, utána a
## követelmény csak lassan (nem exponenciálisan) nő, hogy magasabb szinten is
## gyakran jöjjön szintlépés: BASE_XP + LINEAR * n + QUADRATIC * n² (n = szint - 1).

signal changed(xp: int, needed: int, level: int)
## Minden egyes megszerzett szintnél külön jelez (ha egyszerre több szint jön).
signal leveled_up(level: int)

const BASE_XP := 10
const LINEAR := 6.0
const QUADRATIC := 0.5

var level := 1
var xp := 0


static func xp_for_level(for_level: int) -> int:
	var n := for_level - 1
	return roundi(BASE_XP + LINEAR * n + QUADRATIC * n * n)


func needed() -> int:
	return xp_for_level(level)


func add(amount: int) -> void:
	xp += amount
	var gained: Array[int] = []
	while xp >= needed():
		xp -= needed()
		level += 1
		gained.append(level)
	changed.emit(xp, needed(), level)
	for new_level in gained:
		leveled_up.emit(new_level)


func restore(saved_level: int, saved_xp: int) -> void:
	level = saved_level
	xp = saved_xp
	changed.emit(xp, needed(), level)
