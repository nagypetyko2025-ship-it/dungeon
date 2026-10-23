class_name LiftRoom
extends Node2D
## A 10. emelet liftszobája (a Room teszi bele, ha has_lift_room): a hátsó fal előtt láncon lóg a
## lift vasketrece, mellette egy nagy fogaskerék és Bertalan, a mérnök (E: beszélgetés, lásd Engineer).
## A szobában nincs szörny, csapda és láda; a térképen kék.

const TILE := 32
## A lift vasketrece láncon (ETTiNGRiNDER, CC0).
const CAGE: Texture2D = preload("res://assets/props/lift_cage.png")
const CAGE_SCALE := 1.6
const TALK_RANGE := 70.0

var _player: Node2D
var _engineer: Node2D
var _engineer_body: CollisionShape2D
var _cage: Sprite2D
var _riding := false
var _dialogue: DialoguePanel
var _prompt: Label


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	# A liftfülke a hátsó fal előtt (a szoba közepén), mellette a fogaskerék és a mérnök.
	var cage := Sprite2D.new()
	_cage = cage
	cage.texture = CAGE
	cage.scale = Vector2(CAGE_SCALE, CAGE_SCALE)
	cage.offset = Vector2(0, -CAGE.get_height() / 2.0)
	cage.position = Vector2(0, TILE * 0.6)
	add_child(cage)
	if Engineer.repaired():
		# Megjavítva: lámpás ég a ketrecben.
		var glow := PointLight2D.new()
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1.0, 0.8, 0.45))
		gradient.set_color(1, Color(0, 0, 0, 0))
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(0.5, 0.0)
		glow.texture = texture
		glow.texture_scale = 1.5
		glow.energy = 0.8
		glow.position = Vector2(0, -TILE * 0.8)
		add_child(glow)
	var cage_body := StaticBody2D.new()
	var cage_shape := CollisionShape2D.new()
	var cage_box := RectangleShape2D.new()
	cage_box.size = Vector2(CAGE.get_width() * CAGE_SCALE, 14)
	cage_shape.shape = cage_box
	cage_shape.position = Vector2(0, TILE * 0.6 - 7)
	cage_body.add_child(cage_shape)
	add_child(cage_body)
	var gear := Gear.new()
	gear.position = Vector2(TILE * 1.6, -TILE * 0.6)
	gear.spinning = Engineer.repaired()
	add_child(gear)
	_engineer = Node2D.new()
	_engineer.position = Vector2(TILE * 1.9, TILE * 1.0)
	add_child(_engineer)
	var figure := AnimatedSprite2D.new()
	figure.sprite_frames = Engineer.frames()
	figure.scale = Vector2(2, 2)
	figure.offset = Vector2(0, -Engineer.FRAME_SIZE.y / 2.0)
	figure.flip_h = true
	figure.play()
	_engineer.add_child(figure)
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(20, 10)
	shape.shape = box
	shape.position = Vector2(0, -4)
	body.add_child(shape)
	_engineer.add_child(body)
	_engineer_body = shape
	# A javítás után felment a lifttel: azóta a táborban van (lásd CampLift).
	_engineer.visible = not Engineer.in_camp()
	shape.disabled = Engineer.in_camp()
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
	return is_instance_valid(_player) and _engineer.visible and not _riding \
		and _player.global_position.distance_to(_engineer.global_position) < TALK_RANGE


func _process(delta: float) -> void:
	# A javítás után, amint bezárult a beszélgetés: beszáll a ketrecbe, és felmegy vele.
	if not _riding and not get_tree().paused and Progress.npc_quest_state(Engineer.RIDE_FLAG) == "pending":
		_ride()
	var target := 1.0 if _near() and not get_tree().paused else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)


## Bertalan a ketrechez sétál, beszáll, a ketrec felhúzódik az aknán; kis idő múlva üresen ereszkedik vissza.
func _ride() -> void:
	_riding = true
	_engineer_body.disabled = true
	var walk := create_tween()
	walk.tween_property(_engineer, "position", Vector2(0, TILE * 0.7), 1.0)
	walk.tween_property(_engineer, "modulate:a", 0.0, 0.3)
	await walk.finished
	_engineer.visible = false
	Audio.play("door_unlock", -4.0)
	Audio.play("boss_slam", -14.0, 0.1)
	var start := _cage.position
	var up := create_tween()
	up.tween_property(_cage, "position", start + Vector2(0, -TILE * 6), 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	up.parallel().tween_property(_cage, "modulate:a", 0.0, 2.2)
	await up.finished
	Progress.set_npc_quest(Engineer.RIDE_FLAG, "done")
	Progress.save_game()
	await get_tree().create_timer(1.5).timeout
	var down := create_tween()
	down.tween_property(_cage, "position", start, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	down.parallel().tween_property(_cage, "modulate:a", 1.0, 1.0)
	_riding = false


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
