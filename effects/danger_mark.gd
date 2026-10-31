class_name DangerMark
extends Node2D
## Figyelmeztető jel a padlón a szörny felvillanása (windup) alatt:
## - "cross": piros X ott, ahová a szörny teleportálni fog (EnemyAbilities teleport, Boss blink);
## - "line": piros vonal a szörny lábától a roham irányába, a játékost követi, amíg el nem indul (Enemy dash, Boss charge).
## Pixeles, kockás rajz (nincs textúra); a végén elhalványul és eltűnik.

const RED := Color(1.0, 0.12, 0.1)
const PIXEL := 3.0
const CROSS_SIZE := 13.0
const LINE_WIDTH := 4.0

var kind := "cross"
var length := 120.0
## A vonal ezt követi (a játékos), amíg a jel él.
var follow: Node2D
var duration := 0.5
var _t := 0.0


## Piros X a padlón (a szülő a szörny szülője, hogy a szörnnyel együtt ne mozduljon).
static func cross(parent: Node, at: Vector2, time: float) -> DangerMark:
	var mark := DangerMark.new()
	mark.kind = "cross"
	mark.duration = time
	mark.z_index = 1
	parent.add_child(mark)
	mark.global_position = at
	return mark


## Piros vonal a szörny lábától (gyerekként vele mozog), a célpont felé fordulva.
static func line(owner_node: Node2D, target: Node2D, line_length: float, time: float) -> DangerMark:
	var mark := DangerMark.new()
	mark.kind = "line"
	mark.length = line_length
	mark.follow = target
	mark.duration = time
	mark.z_as_relative = false
	mark.z_index = 1
	owner_node.add_child(mark)
	mark._aim()
	return mark


func _process(delta: float) -> void:
	_t += delta
	if kind == "line":
		_aim()
	# Az utolsó harmadban villog, a végén eltűnik.
	if _t >= duration:
		queue_free()
		return
	modulate.a = 1.0 if _t < duration * 0.66 or int(_t * 16.0) % 2 == 0 else 0.45
	queue_redraw()


func _aim() -> void:
	if is_instance_valid(follow):
		rotation = (follow.global_position - global_position).angle()


func _draw() -> void:
	var grow := clampf(_t / maxf(duration * 0.3, 0.01), 0.0, 1.0)
	if kind == "cross":
		var size := CROSS_SIZE * (0.6 + 0.4 * grow)
		var steps := int(size / PIXEL)
		for i in range(-steps, steps + 1):
			var p := Vector2(i, i) * PIXEL
			var q := Vector2(i, -i) * PIXEL
			for at in [p, q]:
				draw_rect(Rect2(at - Vector2(PIXEL + 1, PIXEL + 1) / 2.0, Vector2(PIXEL + 1, PIXEL + 1)),
					Color(0.25, 0, 0, 0.6))
				draw_rect(Rect2(at - Vector2(PIXEL, PIXEL) / 2.0, Vector2(PIXEL, PIXEL)), RED)
		return
	# A vonal kockákból, a vége felé halványul; a végén nyílhegy.
	var drawn := length * grow
	var count := int(drawn / (PIXEL * 2.0))
	for i in count:
		var x := i * PIXEL * 2.0
		var fade := 1.0 - 0.5 * x / maxf(length, 1.0)
		draw_rect(Rect2(Vector2(x, -LINE_WIDTH / 2.0), Vector2(PIXEL * 1.6, LINE_WIDTH)), Color(RED, 0.85 * fade))
	if grow >= 1.0:
		var tip := Vector2(length, 0)
		for k in 4:
			var o := float(k) * PIXEL
			draw_rect(Rect2(tip + Vector2(-o - PIXEL, -o - PIXEL / 2.0), Vector2(PIXEL, PIXEL)), RED)
			draw_rect(Rect2(tip + Vector2(-o - PIXEL, o - PIXEL / 2.0), Vector2(PIXEL, PIXEL)), RED)
