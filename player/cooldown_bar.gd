class_name CooldownBar
extends Node2D
## Vékony csík a játékos lába alatt, ami a fegyver cooldownját mutatja.
## Csak akkor látszik, amíg a cooldown tart.

const SIZE := Vector2(28, 4)
const BACK_COLOR := Color(0.1, 0.08, 0.1, 0.8)
const FILL_COLOR := Color(0.95, 0.85, 0.5, 1)

var _ratio := 1.0


func set_ratio(ratio: float) -> void:
	ratio = clampf(ratio, 0.0, 1.0)
	if is_equal_approx(ratio, _ratio):
		return
	_ratio = ratio
	queue_redraw()


func _draw() -> void:
	if _ratio >= 1.0:
		return
	var origin := -SIZE / 2.0
	draw_rect(Rect2(origin - Vector2.ONE, SIZE + Vector2(2, 2)), BACK_COLOR)
	draw_rect(Rect2(origin, Vector2(SIZE.x * _ratio, SIZE.y)), FILL_COLOR)
