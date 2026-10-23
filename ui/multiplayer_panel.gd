class_name MultiplayerPanel
extends PanelContainer
## Többjátékos mód a főmenüben: egyelőre "hamarosan". Már látszik, mi lesz benne (gazdaként
## indítás, csatlakozás IP-címmel), de a gombok még tiltva vannak (lásd NetSession.ENABLED).

signal closed

var _address: LineEdit


func _ready() -> void:
	add_theme_stylebox_override("panel", MenuStyle.box(MenuStyle.MENU_PANEL, 18, 34))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	var title := MenuStyle.title_label("Többjátékos mód", 52, MenuStyle.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var soon := MenuStyle.title_label("Hamarosan!", 30, Color(1, 0.6, 0.35))
	soon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(soon)
	var text := UiStyle.label("Legfeljebb %d kalandor együtt a Mélységben: az egyikőtök indítja a játékot, " % NetSession.MAX_PLAYERS \
		+ "a többiek az IP-címével csatlakoznak hozzá. Mindenki a saját karakterével és a saját táskájával jön; " \
		+ "a tábor és a küldetések mindenkinél a sajátjai maradnak.", 18, MenuStyle.PARCHMENT)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = 440
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(text)
	var host := MenuStyle.button("Játék indítása")
	host.disabled = not NetSession.ENABLED
	box.add_child(host)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	_address = LineEdit.new()
	_address.placeholder_text = "IP-cím (pl. %s)" % NetSession.DEFAULT_ADDRESS
	_address.custom_minimum_size = Vector2(240, 56)
	_address.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_address.editable = NetSession.ENABLED
	_address.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	_address.add_theme_font_size_override("font_size", 20)
	row.add_child(_address)
	var join := MenuStyle.button("Csatlakozás")
	join.custom_minimum_size = Vector2(190, 56)
	join.disabled = not NetSession.ENABLED
	row.add_child(join)
	var back := MenuStyle.button("Vissza")
	back.pressed.connect(func() -> void: closed.emit())
	box.add_child(back)

