extends CanvasLayer
## Tábori láda (a táborban, E-vel): ide kerülnek a tárgylifttel és a főellenség
## után felküldött tárgyak. Kattintással lehet áttenni őket a táskádba (amit a
## táskádban / magadon viszel, azzal szállsz le), és vissza a ládába. Minden mentődik.
## Akármennyi tárgy lehet benne: oldalanként PAGE_SIZE látszik, lapozni lehet, és
## szűrni típusra, fegyverfajtára és ritkaságra (egyszerre is, pl. fegyver + tőr + epikus).

const PAGE_SIZE := 20
const ALL := ""
## A szűrők gombjai: [kulcs, felirat]; az első mindig "Mind".
const TYPE_FILTERS := [
	[ALL, "Mind"], ["weapon", "Fegyver"], ["helmet", "Sisak"], ["chest", "Mellvért"], ["pants", "Nadrág"],
	["boots", "Cipő"], ["gloves", "Kesztyű"], ["ring", "Gyűrű"], ["amulet", "Amulett"], ["trinket", "Talizmán"],
]
const KIND_FILTERS := [
	[ALL, "Mind"], ["sword", "Kard"], ["dagger", "Tőr"], ["spear", "Lándzsa"], ["axe", "Balta"],
	["mace", "Buzogány"], ["bow", "Íj"], ["crossbow", "Számszeríj"],
]

var _type_filter := ALL
var _kind_filter := ALL
var _rarity_filter := ALL
var _page := 0
## A rácson látszó helyek -> a láda (Progress.stash) indexe.
var _shown: Array[int] = []
var _type_buttons: Dictionary = {}
var _kind_buttons: Dictionary = {}
var _page_label: Label
var _prev_page: Button
var _next_page: Button

var _stash_grid: ItemGrid
var _bag_grid: ItemGrid
var _info_title: Label
var _info_text: RichTextLabel
var _message: Label


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func open() -> void:
	_message.text = ""
	_refresh()
	_show_item(null)
	visible = true


func close() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		get_tree().current_scene.get_node("Menus").call("close_current")


func _inventory() -> Inventory:
	return get_tree().get_first_node_in_group("player").get_node("Inventory")


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(center)
	var window := PanelContainer.new()
	window.add_theme_stylebox_override("panel", UiStyle.decorated_panel())
	center.add_child(window)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	window.add_child(root)
	root.add_child(UiStyle.title_bar("Tábori láda"))
	root.add_child(UiStyle.label("A felküldött tárgyaid. Kattints egy tárgyra, hogy átkerüljön a táskádba (azzal szállsz le),\n"
		+ "vagy a táskádból vissza a ládába. Felvenni az [I] felszerelés-ablakban tudod.", 15, UiStyle.INK_LIGHT))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	root.add_child(columns)

	# Szűrők (egyszerre mindhárom érvényes) a láda fölött.
	var filters := VBoxContainer.new()
	filters.add_theme_constant_override("separation", 4)
	root.add_child(filters)
	root.move_child(filters, columns.get_index())
	var rarity_options: Array = [[ALL, "Mind"]]
	for rarity: String in Items.RARITY_ORDER:
		rarity_options.append([rarity, Items.RARITIES[rarity]["name"]])
	filters.add_child(_chip_row("Típus:", TYPE_FILTERS, _type_buttons, _set_type_filter))
	filters.add_child(_chip_row("Fegyver:", KIND_FILTERS, _kind_buttons, _set_kind_filter))
	filters.add_child(_chip_row("Ritkaság:", rarity_options, {}, _set_rarity_filter))

	var stash_box := VBoxContainer.new()
	columns.add_child(stash_box)
	stash_box.add_child(UiStyle.label("Láda", 18, UiStyle.INK))
	_stash_grid = ItemGrid.new()
	_stash_grid.columns = 5
	_stash_grid.item_clicked.connect(_take_from_stash)
	_stash_grid.item_hovered.connect(func(i: int) -> void: _show_item(_stash_grid.item_at(i)))
	_stash_grid.draggable = true
	stash_box.add_child(_stash_grid)
	# Lapozás.
	var pages := HBoxContainer.new()
	pages.add_theme_constant_override("separation", 8)
	stash_box.add_child(pages)
	_prev_page = _small_button("◄", func() -> void: _turn_page(-1))
	pages.add_child(_prev_page)
	_page_label = UiStyle.label("", 15, UiStyle.INK)
	_page_label.custom_minimum_size.x = 196
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pages.add_child(_page_label)
	_next_page = _small_button("►", func() -> void: _turn_page(1))
	pages.add_child(_next_page)

	var bag_box := VBoxContainer.new()
	columns.add_child(bag_box)
	bag_box.add_child(UiStyle.label("Táska", 18, UiStyle.INK))
	_bag_grid = ItemGrid.new()
	_bag_grid.columns = 6
	_bag_grid.item_clicked.connect(_put_to_stash)
	_bag_grid.item_hovered.connect(func(i: int) -> void: _show_item(_bag_grid.item_at(i)))
	_bag_grid.draggable = true
	bag_box.add_child(_bag_grid)
	# Kuka (a táska alatt): a ládából vagy a táskából ide húzott tárgy (megerősítés után) törlődik.
	var trash_row := HBoxContainer.new()
	trash_row.add_theme_constant_override("separation", 10)
	bag_box.add_child(trash_row)
	var trash := TrashSlot.new()
	trash.on_drop = _ask_trash
	trash_row.add_child(trash)
	var trash_hint := UiStyle.label("Kuka: húzz ide egy tárgyat a törléshez", 14, UiStyle.INK_LIGHT)
	trash_hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	trash_row.add_child(trash_hint)

	var info := PanelContainer.new()
	info.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	info.custom_minimum_size = Vector2(300, 300)
	columns.add_child(info)
	var info_box := VBoxContainer.new()
	info.add_child(info_box)
	_info_title = UiStyle.label("", 19, UiStyle.INK)
	_info_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_title.custom_minimum_size.x = 260
	info_box.add_child(_info_title)
	_info_text = RichTextLabel.new()
	_info_text.bbcode_enabled = true
	_info_text.scroll_active = false
	_info_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_info_text.add_theme_color_override("default_color", UiStyle.INK_LIGHT)
	_info_text.add_theme_font_size_override("normal_font_size", 15)
	info_box.add_child(_info_text)

	_message = UiStyle.label("", 15, Color(0.24, 0.5, 0.2))
	root.add_child(_message)
	var hint := UiStyle.label("[E] / [Esc] bezárás", 14, UiStyle.INK_LIGHT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(hint)


## Kuka: rákérdez, és ha igen, végleg törli a tárgyat (a ládából vagy a táskából).
func _ask_trash(data: Dictionary) -> void:
	var grid: ItemGrid = data.get("grid")
	var index: int = data.get("grid_index", -1)
	var item: Variant = grid.item_at(index) if grid else null
	if item == null:
		return
	if item.get("quest", false):
		Audio.play("ui_error")
		_message.text = "Küldetéstárgy: nem dobhatod ki."
		return
	ConfirmBox.ask(self, "Biztosan kidobod: %s? Nem lehet visszahozni." % item["name"], func() -> void:
		if grid == _stash_grid:
			Progress.stash.remove_at(_shown[index])
			Progress.save_game()
		else:
			_inventory().take_from_bag(index)
		Audio.play("door_lock", -6.0)
		_message.text = "Kidobva: " + item["name"]
		_refresh())


func _refresh() -> void:
	# A szűrőknek megfelelő tárgyak, aztán ebből az aktuális oldal.
	var matching: Array[int] = []
	for i in Progress.stash.size():
		if _matches(Progress.stash[i]):
			matching.append(i)
	var page_count := maxi(1, ceili(matching.size() / float(PAGE_SIZE)))
	_page = clampi(_page, 0, page_count - 1)
	_shown = matching.slice(_page * PAGE_SIZE, (_page + 1) * PAGE_SIZE)
	var items: Array = []
	for i in _shown:
		items.append(Progress.stash[i])
	_stash_grid.set_items(items, PAGE_SIZE)
	var filtered := matching.size() != Progress.stash.size()
	_page_label.text = "%d / %d. oldal (%d%s tárgy)" % [_page + 1, page_count, matching.size(),
		(" / %d" % Progress.stash.size()) if filtered else ""]
	_prev_page.disabled = _page <= 0
	_next_page.disabled = _page >= page_count - 1
	_bag_grid.set_items(_inventory().bag, Inventory.BAG_SIZE)


## Igaz-e a tárgyra mindhárom szűrő. (A régi kardoknak nincs "weapon_type"-ja: azok kardok; az "Íj"
## szűrő a rövid íjat és a hadiíjat is mutatja.)
func _matches(item: Dictionary) -> bool:
	var slot: String = item.get("slot", "")
	if _type_filter != ALL and slot != _type_filter:
		return false
	var kind: String = item.get("weapon_type", "sword")
	if kind in ["shortbow", "warbow"]:
		kind = "bow"
	if _kind_filter != ALL and (slot != "weapon" or kind != _kind_filter):
		return false
	return _rarity_filter == ALL or item.get("rarity", "common") == _rarity_filter


func _set_type_filter(key: String) -> void:
	_type_filter = key
	# Nem fegyver típusnál a fegyverfajta szűrő nem értelmes: visszaáll "Mind"-re.
	if key != ALL and key != "weapon" and _kind_filter != ALL:
		_kind_filter = ALL
		_kind_buttons[ALL].button_pressed = true
	_page = 0
	_refresh()


func _set_kind_filter(key: String) -> void:
	_kind_filter = key
	# Egy fegyverfajta választása a típust is "Fegyver"-re állítja.
	if key != ALL and _type_filter != "weapon":
		_type_filter = "weapon"
		_type_buttons["weapon"].button_pressed = true
	_page = 0
	_refresh()


func _set_rarity_filter(key: String) -> void:
	_rarity_filter = key
	_page = 0
	_refresh()


func _turn_page(step: int) -> void:
	_page += step
	Audio.play("ui_click")
	_refresh()


## Egy sor kapcsológomb (egyszerre egy lehet benyomva); `buttons`-ba gyűjti őket kulcs szerint.
func _chip_row(title: String, options: Array, buttons: Dictionary, on_select: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var label := UiStyle.label(title, 15, UiStyle.INK)
	label.custom_minimum_size.x = 84
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	var group := ButtonGroup.new()
	for option: Array in options:
		var key: String = option[0]
		var chip := Button.new()
		chip.text = option[1]
		chip.toggle_mode = true
		chip.button_group = group
		chip.button_pressed = key == ALL
		chip.focus_mode = Control.FOCUS_NONE
		chip.add_theme_font_size_override("font_size", 14)
		var ink: Color = Items.RARITIES[key]["ink"] if Items.RARITIES.has(key) else UiStyle.INK
		chip.add_theme_color_override("font_color", ink)
		chip.add_theme_color_override("font_hover_color", ink)
		chip.add_theme_color_override("font_pressed_color", Color(1, 0.96, 0.86))
		chip.add_theme_color_override("font_hover_pressed_color", Color(1, 0.96, 0.86))
		chip.add_theme_stylebox_override("normal", _chip_style(Color(0.42, 0.28, 0.16, 0.12)))
		chip.add_theme_stylebox_override("hover", _chip_style(Color(0.42, 0.28, 0.16, 0.28)))
		chip.add_theme_stylebox_override("pressed", _chip_style(ink.darkened(0.15)))
		chip.add_theme_stylebox_override("hover_pressed", _chip_style(ink.darkened(0.05)))
		chip.toggled.connect(func(on: bool) -> void:
			if on:
				Audio.play("ui_click")
				on_select.call(key))
		row.add_child(chip)
		buttons[key] = chip
	return row


func _chip_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.42, 0.28, 0.16, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	return style


func _small_button(text: String, action: Callable) -> Button:
	var button := MenuStyle.button(text)
	button.custom_minimum_size = Vector2(54, 34)
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(action)
	return button


func _take_from_stash(index: int) -> void:
	var inventory := _inventory()
	if inventory.is_bag_full():
		Audio.play("ui_error")
		_message.text = "Tele a táskád."
		return
	if index >= _shown.size():
		return
	var item: Dictionary = Progress.stash[_shown[index]]
	Progress.stash.remove_at(_shown[index])
	inventory.add_item(item)
	Progress.save_game()
	Audio.play("item_pickup")
	_message.text = "A táskádba került: %s" % item["name"]
	_refresh()


func _put_to_stash(index: int) -> void:
	var item: Variant = _inventory().take_from_bag(index)
	if item == null:
		return
	Progress.add_to_stash(item)
	Audio.play("equip")
	_message.text = "A ládába került: %s" % item["name"]
	_refresh()


func _show_item(item: Variant) -> void:
	if item == null:
		_info_title.text = "—"
		_info_text.text = "Vidd az egeret egy tárgy fölé a leírásáért."
		return
	_info_title.text = item["name"]
	_info_title.add_theme_color_override("font_color", Items.rarity_ink(item))
	_info_text.text = Items.describe_bbcode(item)
