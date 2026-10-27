extends CanvasLayer
## Tárgyak könyve (a táborban, az állványon, E-re): bőrkötéses, nyitott könyv, mint a Szörnyek könyve. Felül a
## fülek (ItemCodex.TABS), a bal lapon a fül összes tárgya ikonrácsban (a még meg nem szerzettek sötét árnyékként),
## a jobb lapon a kiválasztott tárgy: kép, név, ritkaság, statok (a saját ritkaságában), leírás.
## Fülváltás: a gombokkal vagy A / D, ← / →. Megnyitását/bezárását a Menus kezeli.

const LEATHER := Color(0.3, 0.2, 0.13)
const LEATHER_DARK := Color(0.15, 0.09, 0.05)
const PAGE_SIZE := Vector2(420, 400)
const COLUMNS := 7
const CELL := Vector2(52, 52)
const UNSEEN := Color(0.0, 0.0, 0.0, 0.55)

var _tab := 0
var _tab_buttons: Array[Button] = []
var _ids: Array[String] = []
var _selected := ""
var _grid: GridContainer
var _detail: VBoxContainer
var _found: Label
var _window: Control


func close_anchor() -> Control:
	return _window


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func open() -> void:
	ItemCodex.note_stored()
	_set_tab(_tab, false)
	visible = true


func close() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		get_tree().current_scene.get_node("Menus").call("close_current")
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_A, KEY_LEFT: _set_tab(posmod(_tab - 1, ItemCodex.TABS.size()))
		KEY_D, KEY_RIGHT: _set_tab(posmod(_tab + 1, ItemCodex.TABS.size()))
		_: return
	get_viewport().set_input_as_handled()


func _set_tab(tab: int, sound := true) -> void:
	_tab = tab
	for i in _tab_buttons.size():
		_tab_buttons[i].modulate = Color.WHITE if i == tab else Color(0.6, 0.55, 0.5)
	_ids = ItemCodex.ids(tab)
	_selected = ""
	for id in _ids:
		if ItemCodex.seen(id):
			_selected = id
			break
	if sound:
		Audio.play("ui_click")
	_fill_grid()
	_show_detail()
	var total := 0
	for i in ItemCodex.TABS.size():
		total += ItemCodex.ids(i).size()
	_found.text = "%s: %d / %d   ·   Összesen: %d / %d" % [ItemCodex.TABS[tab][0], ItemCodex.seen_count(_ids),
		_ids.size(), Progress.seen_items.size(), total]


func _select(id: String) -> void:
	_selected = id
	Audio.play("ui_click")
	_fill_grid()
	_show_detail()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(center)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	center.add_child(root)
	_window = root
	root.add_child(MenuStyle.title_label("Tárgyak könyve", 44, MenuStyle.GOLD))
	var tabs := GridContainer.new()
	tabs.columns = ceili(ItemCodex.TABS.size() / 2.0)
	tabs.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tabs.add_theme_constant_override("h_separation", 6)
	tabs.add_theme_constant_override("v_separation", 4)
	root.add_child(tabs)
	for i in ItemCodex.TABS.size():
		var tab := MenuStyle.button(ItemCodex.TABS[i][0])
		tab.custom_minimum_size = Vector2(170, 36)
		tab.add_theme_font_size_override("font_size", 14)
		tab.focus_mode = Control.FOCUS_NONE
		tab.pressed.connect(_set_tab.bind(i))
		tabs.add_child(tab)
		_tab_buttons.append(tab)

	var cover := PanelContainer.new()
	var leather := StyleBoxFlat.new()
	leather.bg_color = LEATHER
	leather.border_color = LEATHER_DARK
	leather.set_border_width_all(6)
	leather.set_corner_radius_all(10)
	leather.set_content_margin_all(16)
	leather.shadow_color = Color(0, 0, 0, 0.5)
	leather.shadow_size = 12
	cover.add_theme_stylebox_override("panel", leather)
	cover.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(cover)
	var spread := HBoxContainer.new()
	spread.add_theme_constant_override("separation", 0)
	cover.add_child(spread)
	# Bal lap: az ikonrács (görgethető).
	var left := PanelContainer.new()
	left.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	left.custom_minimum_size = PAGE_SIZE
	spread.add_child(left)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = PAGE_SIZE - Vector2(30, 30)
	left.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	scroll.add_child(_grid)
	var spine := ColorRect.new()
	spine.color = LEATHER_DARK
	spine.custom_minimum_size = Vector2(14, 0)
	spread.add_child(spine)
	# Jobb lap: a kiválasztott tárgy.
	var right := PanelContainer.new()
	right.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	right.custom_minimum_size = PAGE_SIZE
	spread.add_child(right)
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", 8)
	right.add_child(_detail)

	_found = Label.new()
	_found.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	_found.add_theme_font_size_override("font_size", 18)
	_found.add_theme_color_override("font_color", MenuStyle.PARCHMENT)
	_found.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_found)
	var hint := Label.new()
	hint.text = "Kattints egy tárgyra   ·   A / D vagy ← / → fülváltás   ·   [E] / [Esc] bezárás"
	hint.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.75, 0.68, 0.6))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)


## Az ikonrács: a megszerzett tárgyak a ritkaságuk színű kerettel, a többi sötét árnyék (nem kattintható).
func _fill_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	for id in _ids:
		var definition: Dictionary = Items.DEFINITIONS[id]
		var known := ItemCodex.seen(id)
		var cell := PanelContainer.new()
		var frame := StyleBoxFlat.new()
		frame.bg_color = Items.rarity_fill(definition, 0.25) if known else Color(0.3, 0.25, 0.2, 0.25)
		frame.border_color = Items.rarity_ink(definition) if id == _selected else Color(0.42, 0.28, 0.16, 0.5)
		frame.set_border_width_all(3 if id == _selected else 1)
		frame.set_corner_radius_all(4)
		cell.add_theme_stylebox_override("panel", frame)
		cell.custom_minimum_size = CELL
		var icon := TextureButton.new()
		icon.texture_normal = _icon(id)
		icon.ignore_texture_size = true
		icon.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = CELL - Vector2(10, 10)
		icon.focus_mode = Control.FOCUS_NONE
		icon.modulate = Color.WHITE if known else UNSEEN
		icon.tooltip_text = str(definition["name"]) if known else "???"
		if known:
			icon.pressed.connect(_select.bind(id))
		cell.add_child(icon)
		_grid.add_child(cell)


func _show_detail() -> void:
	for child in _detail.get_children():
		child.queue_free()
	if _selected.is_empty():
		var empty := UiStyle.label("Ebből a fajtából még semmit nem szereztél.\n\nA kazamatában, a boltokban és "
			+ "a ládákban vár rád...", 17, UiStyle.INK_LIGHT)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size.x = PAGE_SIZE.x - 40
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_detail.add_child(empty)
		return
	var definition: Dictionary = Items.DEFINITIONS[_selected]
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	_detail.add_child(header)
	var icon := TextureRect.new()
	icon.texture = _icon(_selected)
	icon.custom_minimum_size = Vector2(72, 72)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(icon)
	var titles := VBoxContainer.new()
	titles.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(titles)
	var name_label := UiStyle.label(str(definition["name"]), 21, Items.rarity_ink(definition))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.x = PAGE_SIZE.x - 130
	titles.add_child(name_label)
	var kind := "%s · %s" % [Items.rarity_name(definition), Inventory.SLOT_NAMES.get(definition["slot"], "")]
	if definition.get("unique", false):
		kind += " · egyedi"
	titles.add_child(UiStyle.label(kind, 15, UiStyle.INK_LIGHT))
	_detail.add_child(_rule())
	var stats := ItemCodex.stats_text(_selected)
	if not stats.is_empty():
		var stat_label := UiStyle.label(stats, 16, UiStyle.INK)
		stat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stat_label.custom_minimum_size.x = PAGE_SIZE.x - 40
		_detail.add_child(stat_label)
	var description := str(definition.get("description", ""))
	if not description.is_empty():
		_detail.add_child(_rule())
		var text := UiStyle.label(description, 15, UiStyle.INK_LIGHT)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size.x = PAGE_SIZE.x - 40
		_detail.add_child(text)


func _icon(id: String) -> Texture2D:
	var definition: Dictionary = Items.DEFINITIONS[id]
	if definition.has("region"):
		return SpriteSheet.region(definition["region"])
	return load("res://assets/items/%s.png" % id)


func _rule() -> ColorRect:
	var line := ColorRect.new()
	line.color = Color(0.42, 0.28, 0.16, 0.4)
	line.custom_minimum_size = Vector2(PAGE_SIZE.x - 40, 2)
	return line
