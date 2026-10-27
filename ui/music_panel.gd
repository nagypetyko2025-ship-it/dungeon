class_name MusicPanel
extends PanelContainer
## Zeneválasztó a szünet menüben (a "♪ Zene" gombbal, jobb oldalt): a játék összes zenéje kategóriákra
## bontva (mindenhol szóló számok, helyszínenként a sajátok, egyéb), kattintásra azonnal az a szám szól
## (lásd Audio.play_song). A most szóló szám ki van emelve.

signal closed

var _list: VBoxContainer


func _ready() -> void:
	add_theme_stylebox_override("panel", MenuStyle.box(MenuStyle.MENU_PANEL, 14, 20))
	custom_minimum_size = Vector2(400, 0)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	var head := HBoxContainer.new()
	root.add_child(head)
	var title := MenuStyle.title_label("Zenék", 34, MenuStyle.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := MenuStyle.button("✕")
	close.custom_minimum_size = Vector2(44, 40)
	close.add_theme_font_size_override("font_size", 20)
	close.pressed.connect(func() -> void: closed.emit())
	head.add_child(close)
	var hint := UiStyle.label("Kattints egy számra: azonnal az szól. Ha véget ér, a hely zenéje folytatódik.",
		14, MenuStyle.PARCHMENT)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = 360
	root.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(360, 440)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	visibility_changed.connect(func() -> void:
		if visible:
			_refresh())


## A lista újraépítése (a most szóló szám kiemelve).
func _refresh(playing := "") -> void:
	for child in _list.get_children():
		child.queue_free()
	if playing.is_empty():
		playing = Audio.current_song()
	for category: Array in Audio.music_categories():
		var songs: Array = category[1]
		if songs.is_empty():
			continue
		var header := MenuStyle.title_label(str(category[0]), 22, MenuStyle.GOLD)
		_list.add_child(header)
		for song: String in songs:
			var now := song == playing
			var button := Button.new()
			button.text = ("▶  " if now else "♪  ") + Audio.song_title(song)
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.focus_mode = Control.FOCUS_NONE
			button.add_theme_font_size_override("font_size", 16)
			button.add_theme_color_override("font_color", MenuStyle.GOLD if now else MenuStyle.PARCHMENT)
			button.add_theme_color_override("font_hover_color", MenuStyle.GOLD_LIGHT)
			button.add_theme_stylebox_override("normal", _style(Color(1, 1, 1, 0.08 if now else 0.03)))
			button.add_theme_stylebox_override("hover", _style(Color(1, 1, 1, 0.14)))
			button.add_theme_stylebox_override("pressed", _style(Color(1, 1, 1, 0.2)))
			button.pressed.connect(func() -> void:
				Audio.play("ui_click")
				Audio.play_song(song)
				_refresh(song))
			_list.add_child(button)


func _style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style
