extends CanvasLayer
## A kocsmáros küldetés-ablaka (a Mélységi kocsmában, E-vel): a 10 küldetés listája
## (felvehető / felvett / teljesített), a felvett haladása, felvétel, feladás és leadás.
## Egyszerre egy küldetés lehet felvéve. Megnyitását/bezárását a Menus kezeli.

var _list: VBoxContainer
var _active_box: PanelContainer
var _active_label: RichTextLabel
var _turn_in: Button
var _abandon: Button
var _message: Label


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func open() -> void:
	_message.text = ""
	_refresh()
	visible = true


func close() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		get_tree().current_scene.get_node("Menus").call("close_current")


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(center)
	var window := PanelContainer.new()
	window.add_theme_stylebox_override("panel", UiStyle.decorated_panel())
	window.custom_minimum_size = Vector2(980, 0)
	center.add_child(window)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	window.add_child(root)
	root.add_child(UiStyle.title_bar("Küldetések — a kocsmáros táblája"))
	root.add_child(UiStyle.label("„Akad itt munka bőven. Egyszerre csak egyet vállalj, és a mélyben számít, nem itt fent.”",
		15, UiStyle.INK_LIGHT))

	_active_box = PanelContainer.new()
	_active_box.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	root.add_child(_active_box)
	var active_row := HBoxContainer.new()
	active_row.add_theme_constant_override("separation", 12)
	_active_box.add_child(active_row)
	_active_label = RichTextLabel.new()
	_active_label.bbcode_enabled = true
	_active_label.fit_content = true
	_active_label.scroll_active = false
	_active_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_active_label.add_theme_color_override("default_color", UiStyle.INK)
	_active_label.add_theme_font_size_override("normal_font_size", 17)
	_active_label.add_theme_font_size_override("bold_font_size", 17)
	active_row.add_child(_active_label)
	_turn_in = _small_button("Leadás", _on_turn_in)
	active_row.add_child(_turn_in)
	_abandon = _small_button("Feladás", _on_abandon)
	active_row.add_child(_abandon)

	# A lista görgethető (később több küldetés is jöhet).
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_message = UiStyle.label("", 16, Color(0.24, 0.5, 0.2))
	root.add_child(_message)
	var hint := UiStyle.label("[E] / [Esc] bezárás", 14, UiStyle.INK_LIGHT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(hint)


func _small_button(text: String, action: Callable) -> Button:
	var button := MenuStyle.button(text)
	button.custom_minimum_size = Vector2(150, 46)
	button.add_theme_font_size_override("font_size", 18)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(action)
	return button


func _refresh() -> void:
	var active := Quests.active()
	if active.is_empty():
		_active_label.text = "[b]Nincs felvett küldetésed.[/b] Válassz egyet lent!"
	else:
		var progress := int(Progress.quest.get("progress", 0))
		var state := "[color=#3c6a32]KÉSZ — add le a jutalomért![/color]" if Quests.is_complete() \
			else "Haladás: %d / %d" % [progress, active["goal"]]
		_active_label.text = "[b]Felvett: %s[/b] — %s\n%s   ·   Jutalom: %s" % [
			active["name"], active["text"], state, Quests.reward_text(Progress.quest["id"])]
	_turn_in.visible = Quests.is_complete()
	_abandon.visible = not active.is_empty() and not Quests.is_complete()
	for child in _list.get_children():
		child.queue_free()
	for id: String in Quests.ALL:
		_list.add_child(_make_row(id))


func _make_row(id: String) -> PanelContainer:
	var definition: Dictionary = Quests.ALL[id]
	var done := Progress.quests_done.has(id)
	var is_active: bool = Progress.quest.get("id", "") == id
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.42, 0.28, 0.16, 0.12) if not is_active else Color(0.85, 0.55, 0.15, 0.25)
	style.set_content_margin_all(6)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var name_label := UiStyle.label(definition["name"], 17, UiStyle.INK if not done else Color(0.4, 0.35, 0.3, 0.7))
	name_label.custom_minimum_size.x = 200
	row.add_child(name_label)
	var text := UiStyle.label(definition["text"], 15, UiStyle.INK_LIGHT if not done else Color(0.4, 0.35, 0.3, 0.6))
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var reward := UiStyle.label(Quests.reward_text(id), 14, Color(0.6, 0.38, 0.05) if not done else Color(0.4, 0.35, 0.3, 0.6))
	reward.custom_minimum_size.x = 250
	row.add_child(reward)
	if done:
		row.add_child(_status_label("✔ Teljesítve", DONE_COLOR))
	elif is_active:
		row.add_child(_status_label("Felvéve", Color(0.6, 0.38, 0.05)))
	else:
		var take := _small_button("Felvétel", _on_accept.bind(id))
		take.custom_minimum_size = Vector2(130, 34)
		take.add_theme_font_size_override("font_size", 16)
		take.disabled = not Progress.quest.is_empty()
		row.add_child(take)
	return panel


const DONE_COLOR := Color(0.24, 0.5, 0.2)


func _status_label(text: String, color: Color) -> Label:
	var label := UiStyle.label(text, 16, color)
	label.custom_minimum_size.x = 130
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _on_accept(id: String) -> void:
	if Quests.accept(id):
		Audio.play("ui_open")
		_message.text = "Felvetted: %s. A kazamatában számol." % Quests.ALL[id]["name"]
	_refresh()


func _on_abandon() -> void:
	Quests.abandon()
	Audio.play("ui_close")
	_message.text = "Feladtad a küldetést (később újra felveheted)."
	_refresh()


func _on_turn_in() -> void:
	var reward := Quests.turn_in()
	if reward.is_empty():
		return
	Audio.play("level_up")
	_message.text = "Küldetés leadva! Jutalom: " + reward
	_refresh()
