class_name SettingsPanel
extends PanelContainer
## Beállítások panel (főmenüben és a szünet menüben is), két füllel:
## Általános (teljes képernyő, zene- és effekt-hangerő; minden változás azonnal életbe
## lép és mentődik) és Irányítás (a billentyűk listája).

signal closed

var _fullscreen_button: Button
var _back: Button
var _general: VBoxContainer
var _controls: PanelContainer
var _tab_buttons: Array[Button] = []


func _ready() -> void:
	add_theme_stylebox_override("panel", MenuStyle.box(MenuStyle.MENU_PANEL, 18, 34))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	box.add_child(MenuStyle.title_label("Beállítások", 56, MenuStyle.GOLD))
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	box.add_child(tabs)
	for title: String in ["Általános", "Irányítás"]:
		var tab := MenuStyle.button(title)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.pressed.connect(_show_tab.bind(_tab_buttons.size()))
		tabs.add_child(tab)
		_tab_buttons.append(tab)

	_general = VBoxContainer.new()
	_general.add_theme_constant_override("separation", 14)
	box.add_child(_general)
	_fullscreen_button = MenuStyle.button("")
	_fullscreen_button.pressed.connect(func() -> void:
		Audio.toggle_fullscreen()
		_update_fullscreen_text())
	_general.add_child(_fullscreen_button)
	var audio := Audio.settings()
	_general.add_child(_slider_row("Zene", audio.music_volume, audio.set_music_volume))
	_general.add_child(_slider_row("Effektek", audio.sfx_volume, func(value: float) -> void:
		audio.set_sfx_volume(value)
		Audio.play("ui_click")))

	# Irányítás fül: ugyanaz a lista, mint a kézikönyv első fejezetében.
	_controls = PanelContainer.new()
	_controls.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	box.add_child(_controls)
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.custom_minimum_size = Vector2(520, 0)
	text.add_theme_font_override("normal_font", MenuStyle.BUTTON_FONT)
	text.add_theme_font_override("bold_font", MenuStyle.BUTTON_FONT)
	text.add_theme_font_size_override("normal_font_size", 18)
	text.add_theme_font_size_override("bold_font_size", 18)
	text.add_theme_color_override("default_color", UiStyle.INK)
	text.text = TutorialManual.CHAPTERS[0][1]
	_controls.add_child(text)

	_back = MenuStyle.button("Vissza")
	_back.pressed.connect(closed.emit)
	box.add_child(_back)
	_update_fullscreen_text()
	_show_tab(0)
	visibility_changed.connect(func() -> void:
		if visible:
			_update_fullscreen_text()
			_show_tab(0)
			_fullscreen_button.grab_focus())


func _show_tab(index: int) -> void:
	_general.visible = index == 0
	_controls.visible = index == 1
	for i in _tab_buttons.size():
		# A kiválasztott fül arany, a másik halványabb.
		_tab_buttons[i].modulate = Color.WHITE if i == index else Color(0.65, 0.6, 0.55)
	# Fülváltáskor a panel összezsugorodik az új tartalomra.
	reset_size()


func _slider_row(title: String, value: float, on_change: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var label := Label.new()
	label.text = title
	label.custom_minimum_size = Vector2(110, 0)
	label.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", MenuStyle.PARCHMENT)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(210, 32)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.18, 0.12, 0.1)
	track.border_color = Color(0.6, 0.45, 0.25)
	track.set_border_width_all(2)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.62, 0.28)
	fill.content_margin_top = 4
	fill.content_margin_bottom = 4
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	slider.value_changed.connect(on_change)
	row.add_child(slider)
	return row


func _update_fullscreen_text() -> void:
	_fullscreen_button.text = "Teljes képernyő: %s" % ("Be" if Audio.is_fullscreen() else "Ki")
