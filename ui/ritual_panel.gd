class_name RitualPanel
extends CanvasLayer
## A kripta oltára (Crypt): a köveid, a tábori aranyad, és a rituálé — 2 kő egy fajtából + 1 Csillagkő
## + tábori arany → áldás a következő futásra (Gems). Egyszerre egy áldás várhat. Esc / X: bezárás (Menus).

signal performed(id: String)

const ROW_ICON := 40

var _counts: Dictionary = {}
var _gold: Label
var _pending: Label
var _message: Label
var _buttons: Dictionary = {}


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.05, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.decorated_panel())
	panel.custom_minimum_size = Vector2(820, 0)
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)
	root.add_child(UiStyle.title_bar("Rituálé — áldás a következő futásra"))
	var intro := UiStyle.label("Két kő egy fajtából, egy Csillagkő és %d tábori arany: a kő áldása a következő futásodon veled lesz." \
		% Gems.RITUAL_GOLD, 16, UiStyle.INK)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size.x = 760
	root.add_child(intro)
	# A köveid.
	var stones := HBoxContainer.new()
	stones.alignment = BoxContainer.ALIGNMENT_CENTER
	stones.add_theme_constant_override("separation", 18)
	root.add_child(stones)
	for id: String in Gems.LIST:
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 4)
		cell.add_child(_icon(id, 30))
		var count := UiStyle.label("", 17, UiStyle.INK)
		cell.add_child(count)
		_counts[id] = count
		stones.add_child(cell)
	_gold = UiStyle.label("", 17, UiStyle.INK)
	_gold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_gold)
	_pending = UiStyle.label("", 17, Color(0.4, 0.15, 0.5))
	_pending.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_pending)
	# A választható áldások.
	for id: String in Gems.LIST:
		if id == Gems.STAR:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.add_child(_icon(id, ROW_ICON))
		var texts := VBoxContainer.new()
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texts.add_theme_constant_override("separation", 0)
		texts.add_child(UiStyle.label("%s (%s)" % [Gems.LIST[id]["blessing"], Gems.gem_name(id)], 19, UiStyle.INK))
		texts.add_child(UiStyle.label(String(Gems.LIST[id]["text"]), 16, UiStyle.INK_LIGHT))
		row.add_child(texts)
		var button := MenuStyle.button("Elvégzem")
		button.custom_minimum_size = Vector2(170, 46)
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(_perform.bind(id))
		row.add_child(button)
		_buttons[id] = button
		root.add_child(row)
	_message = UiStyle.label("", 17, UiStyle.INK)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_message)


func _icon(id: String, size: int) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = Gems.icon(id)
	icon.custom_minimum_size = Vector2(size, size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.tooltip_text = Gems.gem_name(id)
	return icon


func open() -> void:
	Progress.load_game()
	_message.text = ""
	_refresh()
	visible = true


func close() -> void:
	visible = false


func _refresh() -> void:
	for id: String in _counts:
		(_counts[id] as Label).text = "%s: %d" % [Gems.gem_name(id), Gems.count(id)]
	_gold.text = "Tábori arany: %d" % Progress.camp_gold
	if Progress.blessing.is_empty():
		_pending.text = "Nincs várakozó áldás."
	else:
		var gem: Dictionary = Gems.LIST[Progress.blessing]
		_pending.text = "Várakozó áldás a következő futásra: %s (%s)" % [gem["blessing"], gem["text"]]
	for id: String in _buttons:
		var problem := Gems.ritual_problem(id)
		(_buttons[id] as Button).disabled = not problem.is_empty()
		(_buttons[id] as Button).tooltip_text = problem


func _perform(id: String) -> void:
	var problem := Gems.ritual_problem(id)
	if not problem.is_empty() or not Gems.perform(id):
		Audio.play("ui_error")
		_message.text = problem
		_message.add_theme_color_override("font_color", Color(0.6, 0.2, 0.12))
		return
	_message.text = "Orsolya elmondja a szavakat. A kövek elporladnak, a kör felizzik."
	_message.add_theme_color_override("font_color", Color(0.24, 0.5, 0.2))
	_refresh()
	performed.emit(id)
	if get_tree().current_scene.has_method("_update_gold"):
		get_tree().current_scene.call("_update_gold")
