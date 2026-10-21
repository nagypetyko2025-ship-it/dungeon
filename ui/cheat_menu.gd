class_name CheatMenu
extends Node
## Csalómenü a [0] gombra (a Menus kezeli, megnyitva megáll a játék). Előbb a kódot kell
## beírni (CODE); ha rossz, a menü bezárja magát. Jó kód után két csalás:
##   - teleport a 20. emeletre (a kazamatában és a táborból is; pihenő közben nem)
##   - halhatatlanság be/ki (GameState.god_mode: a játékos nem sebződik)
## Halhatatlanság alatt felül középen egy kis felirat jelzi, hogy be van kapcsolva.

const CODE := "147258"
const TELEPORT_DEPTH := 20

var _layer: CanvasLayer
var _code_box: VBoxContainer
var _code_input: LineEdit
var _menu_box: VBoxContainer
var _god_button: Button
var _status: Label
var _badge: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_build_badge()


func open() -> void:
	_status.text = ""
	_code_input.text = ""
	_code_box.visible = true
	_menu_box.visible = false
	_layer.visible = true
	_code_input.grab_focus.call_deferred()


func close() -> void:
	_layer.visible = false
	_code_input.release_focus()


func _process(_delta: float) -> void:
	_badge.visible = GameState.god_mode


func _menus() -> Node:
	return get_tree().current_scene.get_node("Menus")


func _build() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 30
	_layer.visible = false
	add_child(_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(center)
	var window := PanelContainer.new()
	window.add_theme_stylebox_override("panel", MenuStyle.box(MenuStyle.MENU_PANEL, 18, 30))
	window.custom_minimum_size = Vector2(460, 0)
	center.add_child(window)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	window.add_child(root)
	root.add_child(MenuStyle.title_label("Csalások", 48, MenuStyle.GOLD))

	# 1. lépés: a kód.
	_code_box = VBoxContainer.new()
	_code_box.add_theme_constant_override("separation", 10)
	root.add_child(_code_box)
	_code_box.add_child(_text("Írd be a kódot, majd nyomj Entert:", 20, MenuStyle.PARCHMENT))
	_code_input = LineEdit.new()
	_code_input.secret = true
	_code_input.max_length = 12
	_code_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_code_input.custom_minimum_size = Vector2(0, 46)
	_code_input.add_theme_font_size_override("font_size", 26)
	_code_input.text_submitted.connect(_check_code)
	_code_box.add_child(_code_input)

	# 2. lépés: a csalások.
	_menu_box = VBoxContainer.new()
	_menu_box.add_theme_constant_override("separation", 10)
	root.add_child(_menu_box)
	var teleport := MenuStyle.button("Teleport a %d. emeletre" % TELEPORT_DEPTH)
	teleport.pressed.connect(_teleport)
	_menu_box.add_child(teleport)
	_god_button = MenuStyle.button("")
	_god_button.pressed.connect(_toggle_god_mode)
	_menu_box.add_child(_god_button)
	var back := MenuStyle.button("Bezárás")
	back.pressed.connect(func() -> void: _menus().call("close_current"))
	_menu_box.add_child(back)

	_status = _text("", 17, Color(1, 0.6, 0.45))
	root.add_child(_status)
	root.add_child(_text("[0] / [Esc] bezárás", 14, Color(0.75, 0.68, 0.6)))


func _text(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


## Halhatatlanság jelzése felül középen (a menü bezárása után is látszik).
func _build_badge() -> void:
	_badge = CanvasLayer.new()
	_badge.layer = 6
	_badge.visible = false
	add_child(_badge)
	var label := _text("HALHATATLAN (csalás)", 16, Color(1, 0.85, 0.35))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	label.offset_left = -200
	label.offset_right = 200
	label.offset_top = -150
	label.offset_bottom = -128
	_badge.add_child(label)


## Rossz kódnál a menü bezárja magát.
func _check_code(code: String) -> void:
	if code.strip_edges() != CODE:
		Audio.play("ui_error")
		_menus().call("close_current")
		return
	Audio.play("ui_open")
	_code_input.release_focus()
	_code_box.visible = false
	_menu_box.visible = true
	_update_god_button()


func _teleport() -> void:
	var scene := get_tree().current_scene
	if not scene.has_method("cheat_teleport") or not scene.call("cheat_teleport", TELEPORT_DEPTH):
		Audio.play("ui_error")
		_status.text = "Itt most nem lehet teleportálni."
		return
	_menus().call("close_current")


func _toggle_god_mode() -> void:
	GameState.god_mode = not GameState.god_mode
	Audio.play("ui_click")
	_update_god_button()


func _update_god_button() -> void:
	_god_button.text = "Halhatatlanság: %s" % ("BE" if GameState.god_mode else "KI")
