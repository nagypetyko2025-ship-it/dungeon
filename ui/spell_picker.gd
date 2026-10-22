extends CanvasLayer
## A varázsló első varázslatának kiválasztása a kazamatába lépéskor (ha a futásban még nincs
## varázslata): három kártya (varázsgömb, tűzgolyó, földtüskék), kattintással vagy 1/2/3-mal.
## Amíg nyitva van, a játék áll. A Dungeon hozza létre (Characters "spells").

const CARD_SIZE := Vector2(250, 280)

var _ids: Array[String] = []


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.04, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	center.add_child(box)
	var title := MenuStyle.title_label("Válassz varázslatot", 46, MenuStyle.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var hint := UiStyle.label("Ez lesz a fő támadásod (bal egér). Minden 5. szinten fejlesztheted, vagy egy másodikat " \
		+ "tanulhatsz (Q gomb).", 17, MenuStyle.PARCHMENT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	for spell: String in Spells.ALL:
		_ids.append(spell)
		row.add_child(_card(_ids.size() - 1, spell))
	get_tree().paused = true


func _card(index: int, spell: String) -> Button:
	var definition: Dictionary = Spells.ALL[spell]
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_NONE
	card.add_theme_stylebox_override("normal", MenuStyle.box(MenuStyle.MENU_PANEL, 16, 18))
	var hover := MenuStyle.box(MenuStyle.MENU_PANEL, 16, 18)
	card.add_theme_stylebox_override("hover", hover)
	card.add_theme_stylebox_override("pressed", hover)
	card.mouse_entered.connect(func() -> void: card.modulate = Color(1.25, 1.15, 1.0))
	card.mouse_exited.connect(func() -> void: card.modulate = Color.WHITE)
	card.pressed.connect(_choose.bind(index))
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 18)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	box.add_child(_label("[%d]" % (index + 1), 15, MenuStyle.PARCHMENT))
	var icon := TextureRect.new()
	icon.texture = load(definition["icon_path"])
	icon.custom_minimum_size = Vector2(80, 80)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	box.add_child(_label(definition["name"], 26, MenuStyle.GOLD))
	box.add_child(_label(definition["text"], 16, Color(0.9, 0.86, 0.8)))
	return card


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = CARD_SIZE.x - 40
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	return label


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var index := key.physical_keycode - KEY_1
	if index >= 0 and index < _ids.size():
		get_viewport().set_input_as_handled()
		_choose(index)


func _choose(index: int) -> void:
	Audio.play("level_up")
	Spells.pick_first(_ids[index])
	get_tree().paused = false
	queue_free()
