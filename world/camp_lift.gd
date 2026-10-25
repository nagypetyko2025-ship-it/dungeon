class_name CampLift
extends Node2D
## A tábori lift a kazamata lépcsője mellett (a szürke köveken túl, balra): ugyanaz a bakállványos,
## láncon lógó vasketrec, mint lent (LiftRoom.LiftRig), csak itt egy kőperemes akna fölött lóg.
## E-re megnyílik a "Lefelé utazás" ablak: az 1. emelet mindig, a 10. emelet csak akkor, ha Bertalan,
## a mérnök megjavította a liftet (lásd Engineer). A javítás után Bertalan feljön a lifttel, és
## onnantól mellette áll (E: beszélgetés, két új történettel). (A tábor rakja le: setup(camp).)

const TILE := 32
const RANGE := 60.0
## A ketrec alja a bakállvány lábaihoz képest: az akna nyílása fölött lóg.
const CAGE_BOTTOM := 2.0

var _camp: Node2D
var _player: Node2D
var _prompt: Label
var _panel: LiftPanel
var _engineer: Node2D
var _dialogue: DialoguePanel
const TALK_RANGE := 56.0


func setup(camp: Node2D) -> void:
	_camp = camp
	_player = camp.get_node("Entities/Player")
	y_sort_enabled = true
	# Az akna a földben (mindig a figurák alatt), fölötte a bakállványon a ketrec.
	var shaft := Shaft.new()
	shaft.z_index = -7
	add_child(shaft)
	var rig := LiftRoom.LiftRig.new()
	rig.working = Engineer.repaired()
	rig.cage_bottom = CAGE_BOTTOM
	rig.solid = false
	add_child(rig)
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Shaft.OUTER.size
	shape.shape = box
	shape.position = Shaft.OUTER.get_center()
	body.add_child(shape)
	add_child(body)
	_panel = LiftPanel.new()
	_panel.name = "LiftPanel"
	_panel.chosen.connect(_on_chosen)
	camp.add_child.call_deferred(_panel)
	if Engineer.in_camp():
		_build_engineer()
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_prompt = MenuStyle.title_label("[E] Lift: lefelé utazás", 32, MenuStyle.GOLD)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -210
	_prompt.offset_bottom = -160
	_prompt.offset_left = -500
	_prompt.offset_right = 500
	_prompt.modulate.a = 0.0
	layer.add_child(_prompt)


## Bertalan a lift bal oldalán, a villáskulcsát lóbálva.
func _build_engineer() -> void:
	_engineer = Node2D.new()
	_engineer.position = Vector2(-62, 30)
	add_child(_engineer)
	var figure := AnimatedSprite2D.new()
	figure.sprite_frames = Engineer.frames()
	figure.scale = Vector2(2, 2)
	figure.offset = Vector2(0, -Engineer.FRAME_SIZE.y / 2.0)
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
	_dialogue = DialoguePanel.new()
	_dialogue.name = "CampEngineerDialogue"
	_dialogue.npc_id = Engineer.ID
	_dialogue.npc_name = Engineer.NAME
	_dialogue.greeting = "[i]Bertalan a lift kötelét vizsgálgatja, a szemüvege a homlokán.[/i]\n\n" \
		+ "Á, a megmentőm! Nézd, mennyi fény! Idelent... akarom mondani, idefent mindig ilyen világos van?"
	_dialogue.portrait = Engineer.portrait()
	_dialogue.options_provider = func() -> Array[Dictionary]:
		return Engineer.camp_options()
	_camp.add_child.call_deferred(_dialogue)


func _near() -> bool:
	return is_instance_valid(_player) and _player.global_position.distance_to(global_position + Vector2(0, 20)) < RANGE


func _near_engineer() -> bool:
	return is_instance_valid(_engineer) and is_instance_valid(_player) \
		and _player.global_position.distance_to(_engineer.global_position) < TALK_RANGE


func _process(delta: float) -> void:
	if _near_engineer():
		_prompt.text = "[E] Beszélgetés: %s" % Engineer.NAME
	elif _near():
		_prompt.text = "[E] Lift: lefelé utazás"
	var target := 1.0 if (_near() or _near_engineer()) and not get_tree().paused else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or get_tree().paused:
		return
	var talk := _near_engineer()
	if not talk and not _near():
		return
	get_viewport().set_input_as_handled()
	Audio.play("ui_open")
	_camp.get_node("Menus").call("open_menu", _dialogue if talk else _panel)


func _on_chosen(depth: int) -> void:
	_camp.get_node("Menus").call("close_current")
	Audio.play("door_unlock", -4.0)
	_camp.call("_enter_dungeon", depth)


## A lift aknája: kőperem, a nyílás túlsó falán a deszkabélés látszik, ahogy lefelé elsötétül, alatta
## a feneketlen sötétség (a ketrec fölötte lóg). Pixelrácsra rajzolva, mint a LiftRig.
class Shaft:
	extends Node2D
	## A kőperem külső széle és a nyílás (a lift origójához, a bakállvány lábaihoz képest).
	const OUTER := Rect2(-38, -18, 76, 56)
	const OPENING := Rect2(-32, -12, 64, 44)
	const VOID := Color8(10, 8, 12)
	const WALL := [Color8(70, 50, 38), Color8(52, 37, 30), Color8(34, 25, 22), Color8(20, 15, 15)]
	const PLANK_GAP := Color8(26, 18, 16)
	const STONES := [Color8(104, 98, 104), Color8(92, 86, 94), Color8(116, 110, 114)]

	func _draw() -> void:
		draw_rect(OUTER.grow(2.0), LiftRoom.LiftRig.OUTLINE)
		# Kőperem: 8x6-os kövek, soronként eltolva, egyenként körvonallal.
		var row := 0
		for y in range(int(OUTER.position.y), int(OUTER.end.y), 6):
			var shift := 4 if row % 2 == 1 else 0
			for x in range(int(OUTER.position.x) - shift, int(OUTER.end.x), 8):
				var stone := Rect2(x, y, 8, 6).intersection(OUTER)
				if stone.size.x <= 0.0:
					continue
				draw_rect(stone, LiftRoom.LiftRig.OUTLINE)
				var inner := stone.grow_individual(0, 0, -2, -2)
				if inner.size.x > 0.0:
					draw_rect(inner, STONES[posmod((x >> 3) + row, STONES.size())])
					draw_rect(Rect2(inner.position, Vector2(inner.size.x, 2)), LiftRoom.LiftRig.STONE_LIGHT)
			row += 1
		# A nyílás: a túlsó fal deszkái egyre sötétebben, alatta a mélység.
		draw_rect(OPENING.grow(2.0), LiftRoom.LiftRig.OUTLINE)
		draw_rect(OPENING, VOID)
		for i in WALL.size():
			draw_rect(Rect2(OPENING.position + Vector2(0, i * 4), Vector2(OPENING.size.x, 4)), WALL[i])
		for x in range(int(OPENING.position.x) + 8, int(OPENING.end.x), 10):
			draw_rect(Rect2(x, OPENING.position.y, 2, 12), PLANK_GAP)
		# A közeli perem árnyéka a nyílás alján.
		draw_rect(Rect2(OPENING.position.x, OPENING.end.y - 2, OPENING.size.x, 2), Color8(0, 0, 0))


## A "Lefelé utazás" ablak: emeletenként egy gomb (a zártak szürkék, a felirat megmondja, miért).
class LiftPanel:
	extends CanvasLayer
	signal chosen(depth: int)

	var _box: VBoxContainer

	func _ready() -> void:
		layer = 15
		process_mode = Node.PROCESS_MODE_ALWAYS
		visible = false
		var dim := ColorRect.new()
		dim.color = Color(0.02, 0.02, 0.03, 0.6)
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
		var center := CenterContainer.new()
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(center)
		var window := PanelContainer.new()
		window.add_theme_stylebox_override("panel", MenuStyle.box(MenuStyle.MENU_PANEL, 18, 30))
		center.add_child(window)
		_box = VBoxContainer.new()
		_box.add_theme_constant_override("separation", 12)
		window.add_child(_box)

	func open() -> void:
		for child in _box.get_children():
			child.queue_free()
		var title := MenuStyle.title_label("Lefelé utazás", 46, MenuStyle.GOLD)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_box.add_child(title)
		var note := UiStyle.label("A régi bányalift a kazamata mélyére.", 17, MenuStyle.PARCHMENT)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_box.add_child(note)
		var first := MenuStyle.button("1. emelet")
		first.custom_minimum_size = Vector2(420, 56)
		first.pressed.connect(func() -> void: chosen.emit(1))
		_box.add_child(first)
		var open_ten := Engineer.repaired()
		var tenth := MenuStyle.button("%d. emelet" % Engineer.DEPTH if open_ten else "%d. emelet — zárva" % Engineer.DEPTH)
		tenth.custom_minimum_size = Vector2(420, 56)
		tenth.disabled = not open_ten
		tenth.pressed.connect(func() -> void: chosen.emit(Engineer.DEPTH))
		_box.add_child(tenth)
		if not open_ten:
			var why := UiStyle.label("A kötél elszakadt. A 10. emeleten a liftszobában (a térképen kék)\n" \
				+ "egy mérnök dolgozik: talán ő meg tudja javítani.", 15, Color(1, 0.6, 0.45))
			why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_box.add_child(why)
		var back := MenuStyle.button("Mégse")
		back.custom_minimum_size = Vector2(420, 50)
		back.pressed.connect(func() -> void: get_tree().current_scene.get_node("Menus").call("close_current"))
		_box.add_child(back)
		visible = true
		first.grab_focus.call_deferred()

	func close() -> void:
		visible = false
