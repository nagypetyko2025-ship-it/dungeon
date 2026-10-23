class_name CampLift
extends Node2D
## A tábori lift a kazamata lépcsője mellett (a szürke köveken túl, balra): rácsos fülke, egy csempényi.
## E-re megnyílik a "Lefelé utazás" ablak: az 1. emelet mindig, a 10. emelet csak akkor, ha Bertalan,
## a mérnök megjavította a liftet (lásd Engineer). (A tábor rakja le: setup(camp).)

const TILE := 32
const RANGE := 52.0

var _camp: Node2D
var _player: Node2D
var _prompt: Label
var _panel: LiftPanel


func setup(camp: Node2D) -> void:
	_camp = camp
	_player = camp.get_node("Entities/Player")
	var cabin := LiftRoom.LiftCabin.new()
	cabin.working = Engineer.repaired()
	cabin.position = Vector2(0, 8)
	add_child(cabin)
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(36, 14)
	shape.shape = box
	shape.position = Vector2(0, 0)
	body.add_child(shape)
	add_child(body)
	_panel = LiftPanel.new()
	_panel.name = "LiftPanel"
	_panel.chosen.connect(_on_chosen)
	camp.add_child.call_deferred(_panel)
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


func _near() -> bool:
	return is_instance_valid(_player) and _player.global_position.distance_to(global_position + Vector2(0, 20)) < RANGE


func _process(delta: float) -> void:
	var target := 1.0 if _near() and not get_tree().paused else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or get_tree().paused or not _near():
		return
	get_viewport().set_input_as_handled()
	Audio.play("ui_open")
	_camp.get_node("Menus").call("open_menu", _panel)


func _on_chosen(depth: int) -> void:
	_camp.get_node("Menus").call("close_current")
	Audio.play("door_unlock", -4.0)
	_camp.call("_enter_dungeon", depth)


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
