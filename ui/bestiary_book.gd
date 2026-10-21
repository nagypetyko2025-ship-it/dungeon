extends CanvasLayer
## Szörnyek könyve (a táborban, az állványon, E-re): bőrkötéses, nyitott könyv. Felül a
## kategóriák fülei, lent két lap, lapanként PER_PAGE szörny (kép, név, hányat öltél meg,
## rövid leírás). Csak az látszik, amiből már legalább egyet megöltél (Bestiary).
## Lapozás: a nyilakkal, vagy A / D, ← / →. Megnyitását/bezárását a Menus kezeli.

const LEATHER := Color(0.22, 0.2, 0.26)
const LEATHER_DARK := Color(0.11, 0.1, 0.14)
const PAGE_SIZE := Vector2(420, 400)
const PER_PAGE := 4
const ICON_SIZE := Vector2(52, 52)

var _tab := 0
var _tab_buttons: Array[Button] = []
## A bal oldali lap indexe (mindig páros).
var _spread := 0
var _ids: Array[String] = []
var _pages: Array[VBoxContainer] = []
var _found: Label
var _prev: Button
var _next: Button


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func open() -> void:
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
		KEY_A, KEY_LEFT: _flip(-2)
		KEY_D, KEY_RIGHT: _flip(2)
		_: return
	get_viewport().set_input_as_handled()


func _set_tab(tab: int, sound := true) -> void:
	_tab = tab
	for i in _tab_buttons.size():
		_tab_buttons[i].modulate = Color.WHITE if i == tab else Color(0.6, 0.55, 0.5)
	_ids = Bestiary.discovered(tab)
	_spread = 0
	if sound:
		Audio.play("ui_click")
	_show_spread()


func _flip(step: int) -> void:
	var page_count := ceili(_ids.size() / float(PER_PAGE))
	var target := clampi(_spread + step, 0, maxi(page_count - 1, 0) / 2 * 2)
	if target == _spread:
		return
	_spread = target
	Audio.play("ui_click")
	_show_spread()


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
	root.add_child(MenuStyle.title_label("Szörnyek könyve", 44, MenuStyle.GOLD))
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 6)
	root.add_child(tabs)
	for i in Bestiary.CATEGORIES.size():
		var tab := MenuStyle.button(Bestiary.CATEGORIES[i][0])
		tab.custom_minimum_size = Vector2(138, 40)
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
	for side in 2:
		var page := PanelContainer.new()
		page.add_theme_stylebox_override("panel", UiStyle.plain_panel())
		page.custom_minimum_size = PAGE_SIZE
		spread.add_child(page)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 8)
		page.add_child(content)
		_pages.append(content)
		if side == 0:
			var spine := ColorRect.new()
			spine.color = LEATHER_DARK
			spine.custom_minimum_size = Vector2(14, 0)
			spread.add_child(spine)

	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 24)
	root.add_child(nav)
	_prev = MenuStyle.button("◄ Előző")
	_prev.custom_minimum_size = Vector2(200, 52)
	_prev.focus_mode = Control.FOCUS_NONE
	_prev.pressed.connect(_flip.bind(-2))
	nav.add_child(_prev)
	_found = Label.new()
	_found.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	_found.add_theme_font_size_override("font_size", 18)
	_found.add_theme_color_override("font_color", MenuStyle.PARCHMENT)
	_found.custom_minimum_size.x = 260
	_found.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nav.add_child(_found)
	_next = MenuStyle.button("Következő ►")
	_next.custom_minimum_size = Vector2(200, 52)
	_next.focus_mode = Control.FOCUS_NONE
	_next.pressed.connect(_flip.bind(2))
	nav.add_child(_next)
	var hint := Label.new()
	hint.text = "A / D vagy ← / → lapozás   ·   [E] / [Esc] bezárás"
	hint.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.75, 0.68, 0.6))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)


func _show_spread() -> void:
	var total: int = Bestiary.CATEGORIES[_tab][1].size()
	_found.text = "Felfedezve: %d / %d" % [_ids.size(), total]
	for side in 2:
		var page := _pages[side]
		for child in page.get_children():
			child.queue_free()
		var first := (_spread + side) * PER_PAGE
		if first >= _ids.size():
			if side == 0 or _ids.is_empty():
				_empty(page, side)
			continue
		for i in range(first, mini(first + PER_PAGE, _ids.size())):
			if i > first:
				page.add_child(_rule())
			page.add_child(_entry(_ids[i]))
	var page_count := ceili(_ids.size() / float(PER_PAGE))
	_prev.disabled = _spread <= 0
	_next.disabled = _spread + 2 >= page_count


## Üres lap: a kategória még ismeretlen (bal), vagy a könyv itt véget ér (jobb).
func _empty(page: VBoxContainer, side: int) -> void:
	var text := "Ebből a fajtából még egyet sem öltél meg.\n\nA kazamatában vár rád..." if side == 0 \
		else "— A könyv további lapjai még üresek. —"
	var label := UiStyle.label(text, 17, UiStyle.INK_LIGHT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = PAGE_SIZE.x - 40
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	page.add_child(label)


## Egy szörny: kép, név, hányat öltél meg, rövid leírás.
func _entry(monster: String) -> HBoxContainer:
	var entry: Array = Bestiary.ENTRIES[monster]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var picture: Array = Bestiary.icon(monster)
	var icon := TextureRect.new()
	icon.texture = picture[0]
	icon.modulate = picture[1]
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	row.add_child(text)
	var header := HBoxContainer.new()
	text.add_child(header)
	var name_label := UiStyle.label(entry[0], 19, UiStyle.INK)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	header.add_child(UiStyle.label("× %d" % Bestiary.kills(monster), 17, Color(0.6, 0.18, 0.12)))
	var description := UiStyle.label(entry[1], 14, UiStyle.INK_LIGHT)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = PAGE_SIZE.x - ICON_SIZE.x - 50
	text.add_child(description)
	return row


func _rule() -> ColorRect:
	var line := ColorRect.new()
	line.color = Color(0.42, 0.28, 0.16, 0.4)
	line.custom_minimum_size = Vector2(PAGE_SIZE.x - 40, 2)
	return line
