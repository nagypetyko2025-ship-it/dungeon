class_name SettingsPanel
extends PanelContainer
## Beállítások panel (főmenüben és a szünet menüben is): teljes képernyő,
## zene- és effekt-hangerő. Minden változás azonnal életbe lép és mentődik.

signal closed

var _fullscreen_button: Button
var _back: Button


func _ready() -> void:
	add_theme_stylebox_override("panel", MenuStyle.box(MenuStyle.MENU_PANEL, 18, 34))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	box.add_child(MenuStyle.title_label("Beállítások", 56, MenuStyle.GOLD))
	_fullscreen_button = MenuStyle.button("")
	_fullscreen_button.pressed.connect(func() -> void:
		Audio.toggle_fullscreen()
		_update_fullscreen_text())
	box.add_child(_fullscreen_button)
	var audio := Audio.settings()
	box.add_child(_slider_row("Zene", audio.music_volume, audio.set_music_volume))
	box.add_child(_slider_row("Effektek", audio.sfx_volume, func(value: float) -> void:
		audio.set_sfx_volume(value)
		Audio.play("ui_click")))
	_back = MenuStyle.button("Vissza")
	_back.pressed.connect(closed.emit)
	box.add_child(_back)
	_update_fullscreen_text()
	visibility_changed.connect(func() -> void:
		if visible:
			_update_fullscreen_text()
			_fullscreen_button.grab_focus())


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
