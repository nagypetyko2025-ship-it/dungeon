class_name LiftRoom
extends Node2D
## A 10. emelet liftszobája (a Room teszi bele, ha has_lift_room): a hátsó falnál a liftakna
## fülkéje, mellette egy nagy fogaskerék és Bertalan, a mérnök (E: beszélgetés, lásd Engineer).
## A szobában nincs szörny, csapda és láda; a térképen kék.

const TILE := 32
const GATE: Texture2D = preload("res://assets/props/lift_gate.png")
const TALK_RANGE := 70.0

var _player: Node2D
var _engineer: Node2D
var _dialogue: DialoguePanel
var _prompt: Label


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	# A liftfülke a hátsó fal előtt (a szoba közepén), mellette a fogaskerék és a mérnök.
	var cabin := LiftCabin.new()
	cabin.position = Vector2(0, -TILE * 0.2)
	cabin.working = Engineer.repaired()
	add_child(cabin)
	var gear := Gear.new()
	gear.position = Vector2(TILE * 1.6, -TILE * 0.6)
	gear.spinning = Engineer.repaired()
	add_child(gear)
	_engineer = Node2D.new()
	_engineer.position = Vector2(TILE * 1.9, TILE * 1.0)
	add_child(_engineer)
	var figure := AnimatedSprite2D.new()
	figure.sprite_frames = SpriteSheet.character_frames(Engineer.FIGURE, false)
	figure.scale = Vector2(2, 2)
	figure.offset = Vector2(0, -Engineer.FIGURE.size.y / 2.0)
	figure.flip_h = true
	figure.play("idle")
	_engineer.add_child(figure)
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(20, 10)
	shape.shape = box
	shape.position = Vector2(0, -4)
	body.add_child(shape)
	_engineer.add_child(body)
	_dialogue = DialoguePanel.new()
	_dialogue.name = "EngineerDialogue"
	_dialogue.npc_id = Engineer.ID
	_dialogue.npc_name = Engineer.NAME
	_dialogue.greeting = Engineer.GREETING
	_dialogue.portrait = Engineer.portrait()
	_dialogue.options_provider = func() -> Array[Dictionary]:
		return Engineer.options(_player)
	get_tree().current_scene.add_child.call_deferred(_dialogue)
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_prompt = MenuStyle.title_label("[E] Beszélgetés: %s" % Engineer.NAME, 32, MenuStyle.GOLD)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -210
	_prompt.offset_bottom = -160
	_prompt.offset_left = -500
	_prompt.offset_right = 500
	_prompt.modulate.a = 0.0
	layer.add_child(_prompt)


func _near() -> bool:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	return is_instance_valid(_player) and _player.global_position.distance_to(_engineer.global_position) < TALK_RANGE


func _process(delta: float) -> void:
	var target := 1.0 if _near() and not get_tree().paused else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or get_tree().paused or not _near():
		return
	get_viewport().set_input_as_handled()
	Audio.play("ui_open")
	get_tree().current_scene.get_node("Menus").call("open_menu", _dialogue)


## A liftfülke: sötét akna vaskerettel, a tetején csigakerék és kötél, elöl a csukott ollórács.
## (A táborban is ez áll, lásd CampLift.) `working`: ég benne a lámpa.
class LiftCabin:
	extends Node2D
	const GATE_TEXTURE: Texture2D = preload("res://assets/props/lift_gate.png")
	const GATE_SCALE := 0.42
	var working := false

	func _draw() -> void:
		var w := GATE_TEXTURE.get_width() * GATE_SCALE + 8.0
		var h := GATE_TEXTURE.get_height() * GATE_SCALE + 8.0
		var top := Vector2(-w / 2.0, -h)
		var iron := Color(0.28, 0.27, 0.3)
		# A fülke: sötét belső, vaskeret, felette a gerenda a csigakerékkel.
		draw_rect(Rect2(top, Vector2(w, h)), Color(0.05, 0.05, 0.07))
		if working:
			draw_rect(Rect2(top + Vector2(4, 4), Vector2(w - 8, 6)), Color(1.0, 0.82, 0.45, 0.6))
		draw_set_transform(top + Vector2(4, 4), 0.0, Vector2(GATE_SCALE, GATE_SCALE))
		draw_texture(GATE_TEXTURE, Vector2.ZERO)
		draw_set_transform(Vector2.ZERO)
		draw_rect(Rect2(top, Vector2(w, h)), iron, false, 3.0)
		draw_rect(Rect2(top + Vector2(-6, -8), Vector2(w + 12, 8)), Color(0.36, 0.25, 0.16))
		var wheel := top + Vector2(w / 2.0, -16)
		draw_line(wheel, wheel + Vector2(0, 12), Color(0.55, 0.48, 0.36), 2.0)
		draw_circle(wheel, 8.0, iron)
		draw_circle(wheel, 3.0, Color(0.6, 0.58, 0.55))
		draw_arc(wheel, 8.0, 0.0, TAU, 16, Color(0.15, 0.15, 0.17), 2.0)


## Nagy, rozsdás fogaskerék a lift mellett (megjavítva forog).
class Gear:
	extends Node2D
	var spinning := false

	func _process(delta: float) -> void:
		if spinning:
			rotation += delta * 1.2

	func _draw() -> void:
		var rust := Color(0.5, 0.32, 0.2)
		for i in 10:
			var dir := Vector2.from_angle(TAU * i / 10.0)
			draw_colored_polygon(PackedVector2Array([dir * 14.0 + dir.orthogonal() * 4.0, dir * 20.0 + dir.orthogonal() * 3.0,
				dir * 20.0 - dir.orthogonal() * 3.0, dir * 14.0 - dir.orthogonal() * 4.0]), rust)
		draw_circle(Vector2.ZERO, 15.0, rust)
		draw_circle(Vector2.ZERO, 6.0, Color(0.2, 0.15, 0.12))
		draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 20, rust.darkened(0.4), 2.0)
