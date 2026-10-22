class_name RecordsPanel
extends PanelContainer
## Eredmények panel a főmenüben: az 5 legjobb futás rangsorolva
## (karakter, emelet, arany, megölt szörnyek, szint, hányszor mentél ki pihenni, idő, dátum).
## A régi, karakter nélkül mentett futások a lovaggal készültek (akkor még csak ő volt).

signal closed

const HEADERS := ["#", "Karakter", "Emelet", "Arany", "Szörnyek", "Szint", "Kijutás", "Idő", "Dátum"]
const COLUMN_WIDTHS := [40, 104, 80, 76, 100, 60, 80, 70, 116]
const MEDALS := [Color(1, 0.82, 0.3), Color(0.82, 0.84, 0.88), Color(0.8, 0.5, 0.28)]

var _grid: GridContainer
var _empty: Label
var _back: Button


func _ready() -> void:
	add_theme_stylebox_override("panel", MenuStyle.box(MenuStyle.MENU_PANEL, 18, 34))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	box.add_child(MenuStyle.title_label("Eredmények", 48, MenuStyle.GOLD))
	_grid = GridContainer.new()
	_grid.columns = HEADERS.size()
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 4)
	box.add_child(_grid)
	_empty = _cell("Még nincs eredmény — indulj le a mélybe!", 0, MenuStyle.PARCHMENT, 20)
	box.add_child(_empty)
	_back = MenuStyle.button("Vissza")
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.pressed.connect(closed.emit)
	box.add_child(_back)
	visibility_changed.connect(func() -> void:
		if visible:
			refresh()
			_back.grab_focus())
	refresh()


func refresh() -> void:
	for child in _grid.get_children():
		child.queue_free()
	for i in HEADERS.size():
		_grid.add_child(_cell(HEADERS[i], COLUMN_WIDTHS[i], MenuStyle.GOLD, 20))
	var entries := Records.top()
	for rank in Records.MAX_ENTRIES:
		var color: Color = MEDALS[rank] if rank < MEDALS.size() else MenuStyle.PARCHMENT
		if rank >= entries.size():
			color = Color(MenuStyle.PARCHMENT, 0.35)
		var values: Array = ["%d." % (rank + 1), "—", "—", "—", "—", "—", "—", "—", "—"]
		if rank < entries.size():
			var entry: Dictionary = entries[rank]
			var seconds := int(entry.get("time", 0))
			values = [
				"%d." % (rank + 1), Characters.data(str(entry.get("character", Characters.DEFAULT)))["name"],
				str(entry.get("depth", 0)), str(entry.get("gold", 0)),
				str(entry.get("kills", 0)), str(entry.get("level", 1)), str(entry.get("exits", 0)),
				"%d:%02d" % [seconds / 60, seconds % 60], str(entry.get("date", "")),
			]
		for i in values.size():
			_grid.add_child(_cell(values[i], COLUMN_WIDTHS[i], color, 22))
	_empty.visible = entries.is_empty()


func _cell(text: String, width: int, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(width, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", MenuStyle.SHADOW)
	label.add_theme_constant_override("outline_size", 5)
	return label
