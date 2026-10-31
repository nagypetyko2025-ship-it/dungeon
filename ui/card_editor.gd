class_name CardEditor
extends Control
## Szintlépési kártya-szerkesztő (a főmenü bal felső sarkának alig látható gombjáról): saját kártyák
## névvel, ritkasággal, adott és elvett statokkal és ikonnal (Upgrades.ICON_DIR). Mentéskor a projekt
## `Upgrades.CUSTOM_PATH` fájljába ír, onnantól a kártya a szintlépéskor is jöhet. Esc / Bezárás: vissza a menübe.
## A lista alján a beépített kártyák (Upgrades.ALL) is megnézhetők; ezekből mentéskor új saját kártya lesz.

const ROWS := 3
## A lista fejléc-sorainak metaadata (nem kártya).
const HEADER := 1 << 30
const ICON_COLUMNS := 11
const ICON_SIZE := Vector2(40, 40)
## Ikoncsoportok a fájlnév eleje szerint ("496 pixel art icons").
const CATEGORIES := [["Képességek", ["s_"]], ["Bájitalok", ["p_"]], ["Fegyverek", ["w_"]],
	["Felszerelés", ["a_", "ac_", "c_"]], ["Tárgyak", ["i_", "e_"]], ["Mind", [""]]]

var _list: Array[Dictionary] = []
## A szerkesztett kártya indexe a listában (-1: új).
var _editing := -1
var _icon := "s_buff01"
var _card_list: ItemList
var _name: LineEdit
var _rarity: OptionButton
var _gain_rows: Array = []
var _cost_rows: Array = []
var _category: OptionButton
var _icons: GridContainer
var _preview_box: CenterContainer
var _status: Label
var _delete_button: Button


## Saját rétegen nyílik (a főmenü cím- és hírrétege fölött); bezáráskor a réteggel együtt megy.
static func open(parent: Node) -> CardEditor:
	var layer := CanvasLayer.new()
	layer.layer = 40
	parent.add_child(layer)
	var editor := CardEditor.new()
	layer.add_child(editor)
	return editor


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var background := ColorRect.new()
	background.color = Color(0.05, 0.035, 0.05)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	margin.add_child(columns)
	columns.add_child(_build_list_column())
	columns.add_child(_build_form_column())
	columns.add_child(_build_preview_column())
	_list = Upgrades.custom_cards().duplicate(true)
	_refresh_list()
	_new_card()


func _build_list_column() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 230
	column.add_theme_constant_override("separation", 8)
	column.add_child(_text("Kártya-szerkesztő", 24, UiStyle.TEXT_GOLD))
	column.add_child(_text("Kártyák:", 15, UiStyle.TEXT_LIGHT))
	_card_list = ItemList.new()
	_card_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_card_list.fixed_icon_size = Vector2i(24, 24)
	_card_list.item_selected.connect(_on_list_selected)
	column.add_child(_card_list)
	column.add_child(_small_button("Új kártya", _new_card))
	_delete_button = _small_button("Kártya törlése", _delete_card)
	column.add_child(_delete_button)
	column.add_child(_small_button("Bezárás (Esc)", close))
	return column


func _build_form_column() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 540
	column.add_theme_constant_override("separation", 6)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	top.add_child(_text("Név:", 16, UiStyle.TEXT_LIGHT))
	_name = LineEdit.new()
	_name.placeholder_text = "a kártya neve"
	_name.max_length = 28
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.text_changed.connect(func(_text: String) -> void: _update_preview())
	top.add_child(_name)
	top.add_child(_text("Ritkaság:", 16, UiStyle.TEXT_LIGHT))
	_rarity = OptionButton.new()
	for rarity: String in Items.RARITY_ORDER:
		_rarity.add_item(Items.RARITIES[rarity]["name"])
		_rarity.set_item_metadata(_rarity.item_count - 1, rarity)
	_rarity.item_selected.connect(func(_index: int) -> void: _update_preview())
	top.add_child(_rarity)
	column.add_child(top)
	column.add_child(_text("Ad (nyereség):", 16, UpgradeCard.GAIN_COLOR))
	for i in ROWS:
		_gain_rows.append(_stat_row(column))
	column.add_child(_text("Elvesz (levonás):", 16, UpgradeCard.COST_COLOR))
	for i in ROWS:
		_cost_rows.append(_stat_row(column))
	var icon_head := HBoxContainer.new()
	icon_head.add_child(_text("Ikon:", 16, UiStyle.TEXT_LIGHT))
	_category = OptionButton.new()
	for category: Array in CATEGORIES:
		_category.add_item(category[0])
	_category.item_selected.connect(func(_index: int) -> void: _fill_icons())
	icon_head.add_child(_category)
	column.add_child(icon_head)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_icons = GridContainer.new()
	_icons.columns = ICON_COLUMNS
	scroll.add_child(_icons)
	column.add_child(scroll)
	_fill_icons()
	return column


func _build_preview_column() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 10)
	column.add_child(_text("Előnézet", 18, UiStyle.TEXT_GOLD))
	_preview_box = CenterContainer.new()
	_preview_box.custom_minimum_size = Vector2(UpgradeCard.SIZE.x + 20, 430)
	column.add_child(_preview_box)
	var save := _small_button("Mentés", _save)
	save.custom_minimum_size.y = 44
	column.add_child(save)
	_status = _text("", 14, UiStyle.TEXT_LIGHT)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size.x = 220
	column.add_child(_status)
	var hint := _text("A kártya a mentés után a szintlépéskor is jöhet (a ritkasága szerinti gyakorisággal).",
		13, Color(0.7, 0.64, 0.58))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = 220
	column.add_child(hint)
	return column


## Egy stat-sor: stat választó ("—" = üres) és érték.
func _stat_row(parent: Container) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var stat := OptionButton.new()
	stat.custom_minimum_size.x = 260
	stat.add_item("—")
	stat.set_item_metadata(0, "")
	for key: String in Upgrades.STAT_INFO:
		var info: Array = Upgrades.STAT_INFO[key]
		stat.add_item(info[0] + (" (%)" if info[1] == "%" else ""))
		stat.set_item_metadata(stat.item_count - 1, key)
	var amount := SpinBox.new()
	amount.min_value = 0.0
	amount.max_value = 999.0
	amount.custom_minimum_size.x = 120
	stat.item_selected.connect(func(_index: int) -> void:
		var key: String = stat.get_selected_metadata()
		amount.step = 0.05 if not key.is_empty() and int(Upgrades.STAT_INFO[key][2]) > 0 else 1.0
		_update_preview())
	amount.value_changed.connect(func(_value: float) -> void: _update_preview())
	row.add_child(stat)
	row.add_child(amount)
	parent.add_child(row)
	return [stat, amount]


func _fill_icons() -> void:
	for child in _icons.get_children():
		child.queue_free()
	var prefixes: Array = CATEGORIES[maxi(_category.selected, 0)][1]
	for icon_name in Upgrades.icon_names():
		var matches := false
		for prefix: String in prefixes:
			matches = matches or icon_name.begins_with(prefix)
		if not matches:
			continue
		var button := Button.new()
		button.icon = Upgrades.icon_texture(icon_name)
		button.expand_icon = true
		button.custom_minimum_size = ICON_SIZE
		button.tooltip_text = icon_name
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.button_pressed = icon_name == _icon
		button.pressed.connect(_pick_icon.bind(icon_name))
		_icons.add_child(button)


func _pick_icon(icon_name: String) -> void:
	_icon = icon_name
	for button: Button in _icons.get_children():
		button.set_pressed_no_signal(button.tooltip_text == icon_name)
	_update_preview()


## Az űrlapból összerakott kártya (ugyanolyan szerkezet, mint az Upgrades.ALL elemei).
func _current() -> Dictionary:
	var card := {"title": _name.text.strip_edges(), "rarity": _rarity.get_selected_metadata(), "icon": _icon,
		"gain": _read_rows(_gain_rows), "cost": _read_rows(_cost_rows)}
	if _editing >= 0:
		card["id"] = _list[_editing].get("id", "")
	else:
		card["id"] = "custom_%d" % int(Time.get_unix_time_from_system())
	return card


func _read_rows(rows: Array) -> Dictionary:
	var result := {}
	for row: Array in rows:
		var key: String = (row[0] as OptionButton).get_selected_metadata()
		var amount := (row[1] as SpinBox).value
		if not key.is_empty() and amount > 0.0:
			result[key] = result.get(key, 0.0) + amount
	return result


func _update_preview() -> void:
	for child in _preview_box.get_children():
		child.queue_free()
	var card := _current()
	if String(card["title"]).is_empty():
		card["title"] = "(névtelen)"
	var shown := UpgradeCard.build(-1, card)
	shown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview_box.add_child(shown)
	# A hosszabb szövegű kártya magasabb (mint a szintlépésnél).
	await get_tree().process_frame
	if is_instance_valid(shown) and shown.get_child_count() > 0:
		var box := shown.get_child(0) as Control
		shown.custom_minimum_size.y = minf(maxf(UpgradeCard.SIZE.y, box.get_combined_minimum_size().y + UpgradeCard.PADDING * 2.0), 420.0)


func _new_card() -> void:
	_editing = -1
	_card_list.deselect_all()
	_name.text = ""
	_rarity.select(0)
	_set_rows(_gain_rows, {})
	_set_rows(_cost_rows, {})
	_delete_button.disabled = true
	_status.text = "Új kártya."
	_update_preview()


## A lista elemének metaadata: >= 0 saját kártya indexe, -1-i a beépített i. kártya.
func _on_list_selected(item: int) -> void:
	var index: int = _card_list.get_item_metadata(item)
	if index >= 0:
		_load_card(index)
		return
	var card: Dictionary = Upgrades.ALL[-1 - index]
	_fill_form(card)
	_editing = -1
	_delete_button.disabled = true
	_status.text = "Beépített kártya: %s. Csak megnézni lehet; ha átírod és mented, új saját kártya lesz belőle." % card["title"]


func _load_card(index: int) -> void:
	_editing = index
	var card: Dictionary = _list[index]
	_fill_form(card)
	_delete_button.disabled = false
	_status.text = "Szerkesztés: %s" % card["title"]


func _fill_form(card: Dictionary) -> void:
	_name.text = card["title"]
	_rarity.select(maxi(Items.RARITY_ORDER.find(card["rarity"]), 0))
	_set_rows(_gain_rows, card["gain"])
	_set_rows(_cost_rows, card["cost"])
	_icon = card["icon"]
	_fill_icons()
	_update_preview()


func _set_rows(rows: Array, stats: Dictionary) -> void:
	var keys := stats.keys()
	for i in rows.size():
		var stat: OptionButton = rows[i][0]
		var amount: SpinBox = rows[i][1]
		var key: String = keys[i] if i < keys.size() else ""
		stat.select(0)
		for item in stat.item_count:
			if stat.get_item_metadata(item) == key:
				stat.select(item)
		amount.step = 0.05 if not key.is_empty() and int(Upgrades.STAT_INFO[key][2]) > 0 else 1.0
		amount.set_value_no_signal(float(stats[key]) if not key.is_empty() else 0.0)


func _save() -> void:
	var card := _current()
	if String(card["title"]).is_empty():
		_status.text = "Adj nevet a kártyának!"
		return
	if (card["gain"] as Dictionary).is_empty():
		_status.text = "Legalább egy statot adnia kell."
		return
	if _editing >= 0:
		_list[_editing] = card
	else:
		_list.append(card)
		_editing = _list.size() - 1
	if not _write():
		return
	_refresh_list()
	for item in _card_list.item_count:
		if _card_list.get_item_metadata(item) == _editing:
			_card_list.select(item)
	_delete_button.disabled = false
	_status.text = "Elmentve: %s" % card["title"]


func _delete_card() -> void:
	if _editing < 0:
		return
	var title: String = _list[_editing]["title"]
	_list.remove_at(_editing)
	if not _write():
		return
	_refresh_list()
	_new_card()
	_status.text = "Törölve: %s" % title


func _write() -> bool:
	if not Upgrades.save_custom(_list):
		_status.text = "Nem sikerült menteni (%s)." % Upgrades.CUSTOM_PATH
		return false
	return true


func _refresh_list() -> void:
	_card_list.clear()
	_header("— Saját kártyáid —" if not _list.is_empty() else "— Nincs saját kártyád —")
	for i in _list.size():
		_add_card_item(_list[i], i)
	_header("— Beépített kártyák —")
	for i in Upgrades.ALL.size():
		_add_card_item(Upgrades.ALL[i], -1 - i)


func _add_card_item(card: Dictionary, meta: int) -> void:
	var item := _card_list.add_item(card["title"], Upgrades.icon(card))
	_card_list.set_item_custom_fg_color(item, Upgrades.rarity_color(card))
	_card_list.set_item_metadata(item, meta)
	_card_list.set_item_tooltip(item, "%s — %s" % [Upgrades.rarity_name(card),
		", ".join(Upgrades.lines(card).map(func(line: Array) -> String: return line[0]))])


func _header(text: String) -> void:
	var item := _card_list.add_item(text, null, false)
	_card_list.set_item_custom_fg_color(item, Color(0.7, 0.64, 0.58))
	_card_list.set_item_metadata(item, HEADER)
	_card_list.set_item_disabled(item, true)


func close() -> void:
	Upgrades.reload_custom()
	var layer := get_parent() as CanvasLayer
	if layer != null:
		layer.queue_free()
	else:
		queue_free()


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()


func _text(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _small_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(action)
	return button
