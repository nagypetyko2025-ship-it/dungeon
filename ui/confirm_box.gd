class_name ConfirmBox
extends Control
## Egyszerű "Biztos?" kérdés egy ablak fölött (sötétített háttérrel): Igen / Mégse.
## Használat: ConfirmBox.ask(szülő, "Kérdés", func(): ...) — az Igen gombra fut le.

var _on_yes: Callable


static func ask(parent: Node, question: String, on_yes: Callable) -> ConfirmBox:
	var box := ConfirmBox.new()
	box._on_yes = on_yes
	parent.add_child(box)
	box._build(question)
	return box


func _build(question: String) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.decorated_panel())
	panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	box.add_child(UiStyle.title_bar("Biztos?"))
	var label := UiStyle.label(question, 18, UiStyle.INK)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size.x = 460
	box.add_child(label)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 20)
	box.add_child(buttons)
	var yes := MenuStyle.button("Igen, törlöm")
	yes.custom_minimum_size = Vector2(200, 54)
	yes.add_theme_font_size_override("font_size", 20)
	yes.pressed.connect(func() -> void:
		queue_free()
		_on_yes.call())
	buttons.add_child(yes)
	var no := MenuStyle.button("Mégse")
	no.custom_minimum_size = Vector2(200, 54)
	no.add_theme_font_size_override("font_size", 20)
	no.pressed.connect(queue_free)
	buttons.add_child(no)
	no.grab_focus()
	Audio.play("ui_open")


func _input(event: InputEvent) -> void:
	# Esc: Mégse (és ne zárja be az alatta lévő ablakot).
	var key := event as InputEventKey
	if key and key.pressed and key.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		queue_free()
