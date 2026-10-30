extends CanvasLayer
## A trófeafal közelről (a kibérelt szobádban E-re, lásd Town): bal oldalt a keretek (a legyőzöttek színesen, a
## többi sötét árnyék), jobb oldalt a kiválasztott főellenség nagy képe, hányszor győzted le, és a játszott
## karakter véleménye róla (TrophyNotes). Megnyitását / bezárását a Menus kezeli.

const FRAME := Vector2(76, 76)
const COLUMNS := 6

var _window: PanelContainer
var _grid: GridContainer
var _picture: TextureRect
var _name: Label
var _count: Label
var _note: RichTextLabel
var _selected := ""


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func open() -> void:
	_refresh()
	visible = true


func close() -> void:
	visible = false


func close_anchor() -> Control:
	return _window


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
	_window = PanelContainer.new()
	_window.add_theme_stylebox_override("panel", UiStyle.decorated_panel())
	center.add_child(_window)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	_window.add_child(root)
	root.add_child(UiStyle.title_bar("Trófeafal"))
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	root.add_child(body)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	body.add_child(_grid)
	# A kiválasztott főellenség: kép, név, hányszor, a karakter véleménye.
	var detail := PanelContainer.new()
	detail.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	# Fix magasság: a hosszabb vélemény se méretezze át az ablakot.
	detail.custom_minimum_size = Vector2(420, 470)
	body.add_child(detail)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	detail.add_child(column)
	_picture = TextureRect.new()
	_picture.custom_minimum_size = Vector2(0, 120)
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(_picture)
	_name = UiStyle.label("", 20, UiStyle.INK)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name.custom_minimum_size.x = 380
	column.add_child(_name)
	_count = UiStyle.label("", 14, UiStyle.INK_LIGHT)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_count)
	_note = RichTextLabel.new()
	_note.bbcode_enabled = true
	_note.fit_content = true
	_note.scroll_active = false
	_note.custom_minimum_size = Vector2(380, 0)
	_note.add_theme_font_size_override("normal_font_size", 15)
	_note.add_theme_font_size_override("italics_font_size", 15)
	_note.add_theme_color_override("default_color", UiStyle.INK)
	column.add_child(_note)
	var hint := UiStyle.label("Kattints egy keretre.   [E] / [Esc] bezárás", 14, UiStyle.INK_LIGHT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(hint)


func _refresh() -> void:
	for child in _grid.get_children():
		child.queue_free()
	var bosses := Town.trophies()
	# Elsőre az utoljára legyőzött (a sorban a legkésőbbi), ha nincs ilyen, az első keret.
	if _selected.is_empty() or not bosses.has(_selected):
		_selected = bosses[0]
		for boss in bosses:
			if Bestiary.kills(boss) > 0:
				_selected = boss
	for boss in bosses:
		_grid.add_child(_frame(boss))
	_show(_selected)


## Egy keret a falon: a főellenség képe (le nem győzve sötét árnyék), a kiválasztott aranyszínű kerettel.
func _frame(boss: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = FRAME
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = boss if Bestiary.kills(boss) > 0 else "???"
	var chosen := boss == _selected
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.16, 0.12, 0.1) if state != "hover" else Color(0.24, 0.17, 0.12)
		style.border_color = Color(0.85, 0.62, 0.2) if chosen else Color(0.36, 0.22, 0.1)
		style.set_border_width_all(4)
		button.add_theme_stylebox_override(state, style)
	var icon: Array = Bestiary.icon(boss)
	var picture := TextureRect.new()
	picture.texture = icon[0]
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.offset_left = 8
	picture.offset_top = 8
	picture.offset_right = -8
	picture.offset_bottom = -8
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.modulate = icon[1] if Bestiary.kills(boss) > 0 else Color(0, 0, 0, 0.6)
	button.add_child(picture)
	button.pressed.connect(func() -> void:
		Audio.play("ui_click")
		_selected = boss
		_refresh())
	return button


func _show(boss: String) -> void:
	var beaten := Bestiary.kills(boss)
	var icon: Array = Bestiary.icon(boss)
	_picture.texture = icon[0]
	_picture.modulate = icon[1] if beaten > 0 else Color(0, 0, 0, 0.6)
	if beaten == 0:
		_name.text = "???"
		_count.text = "Még nem győzted le."
		_note.text = "[i]%s[/i]" % TrophyNotes.UNBEATEN
		return
	_name.text = boss
	_count.text = "Legyőzve: %d×" % beaten
	var character := str(Characters.ALL[Progress.character]["name"]) if Characters.ALL.has(Progress.character) else ""
	# A lovag és az íjász nem név, hanem cím: névelővel.
	character = {"knight": "A lovag", "archer": "Az íjász"}.get(Progress.character, character)
	_note.text = "[color=#7a4a10]%s gondolatai:[/color]\n\n[i]%s[/i]" % [character, TrophyNotes.note(boss, Progress.character)]
