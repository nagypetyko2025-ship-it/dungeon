class_name TutorialPanel
extends PanelContainer
## Tutorial ablak a főmenüben: a gyakorló pálya indítása (ami végigvezet mindenen),
## és a kézikönyv fejezetei (TutorialManual) bal oldalt választhatók.

signal closed
signal start_requested

var _text: RichTextLabel
var _chapter_buttons: Array[Button] = []
var _start: Button


func _ready() -> void:
	add_theme_stylebox_override("panel", MenuStyle.box(MenuStyle.MENU_PANEL, 18, 34))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	box.add_child(MenuStyle.title_label("Tutorial", 46, MenuStyle.GOLD))
	_start = MenuStyle.button("Gyakorló pálya indítása")
	_start.custom_minimum_size = Vector2(440, 54)
	_start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_start.pressed.connect(start_requested.emit)
	box.add_child(_start)
	var hint := Label.new()
	hint.text = "Egy külön pálya, ami lépésről lépésre végigvezet mindenen. Itt nem halhatsz meg, és semmi nem mentődik."
	hint.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", MenuStyle.PARCHMENT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	box.add_child(columns)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 3)
	columns.add_child(list)
	for i in TutorialManual.CHAPTERS.size():
		var button := MenuStyle.button(TutorialManual.CHAPTERS[i][0])
		button.custom_minimum_size = Vector2(250, 30)
		button.add_theme_font_size_override("font_size", 15)
		# Kisebb belső margó, hogy mind a 11 fejezet elférjen egymás alatt.
		var textures := {"normal": MenuStyle.BUTTON_NORMAL, "hover": MenuStyle.BUTTON_HOVER,
			"focus": MenuStyle.BUTTON_HOVER, "pressed": MenuStyle.BUTTON_PRESSED}
		for state: String in textures:
			button.add_theme_stylebox_override(state, MenuStyle.box(textures[state], 10, 3))
		button.pressed.connect(_show_chapter.bind(i))
		list.add_child(button)
		_chapter_buttons.append(button)
	var page := PanelContainer.new()
	page.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	page.custom_minimum_size = Vector2(620, 360)
	columns.add_child(page)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = true
	_text.add_theme_color_override("default_color", UiStyle.INK)
	_text.add_theme_font_size_override("normal_font_size", 17)
	_text.add_theme_font_size_override("bold_font_size", 17)
	page.add_child(_text)

	var back := MenuStyle.button("Vissza")
	back.custom_minimum_size.y = 54
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(closed.emit)
	box.add_child(back)
	_show_chapter(0)
	visibility_changed.connect(func() -> void:
		if visible:
			_start.grab_focus())


func _show_chapter(index: int) -> void:
	var chapter: Array = TutorialManual.CHAPTERS[index]
	_text.text = "[font_size=24][b]%s[/b][/font_size]\n\n%s" % [chapter[0], chapter[1]]
	for i in _chapter_buttons.size():
		_chapter_buttons[i].modulate = Color(1.25, 1.15, 0.8) if i == index else Color.WHITE
