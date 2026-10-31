extends CanvasLayer
## Szörnyek könyve (a táborban, az állványon, E-re): bőrkötéses, nyitott könyv. Felül a
## kategóriák fülei, lent két lap, lapanként legfeljebb PER_PAGE szörny (kép, név, hányat öltél meg,
## rövid leírás) — ha a hosszú leírások nem férnek el, kevesebb (lásd _paginate). Csak az látszik, amiből már legalább egyet megöltél (Bestiary).
## Lapozás: a nyilakkal, vagy A / D, ← / →. Megnyitását/bezárását a Menus kezeli.

const LEATHER := Color(0.22, 0.2, 0.26)
const LEATHER_DARK := Color(0.11, 0.1, 0.14)
const PAGE_SIZE := Vector2(420, 400)
const PER_PAGE := 3
const ICON_SIZE := Vector2(52, 52)
## A lap belső magassága (a lap kerete nélkül), és a szövegoszlop / a név szélessége.
const PAGE_INNER_HEIGHT := PAGE_SIZE.y - 28.0
const TEXT_WIDTH := PAGE_SIZE.x - ICON_SIZE.x - 50
const NAME_WIDTH := TEXT_WIDTH - 64
const ENTRY_GAP := 8.0

var _tab := 0
var _tab_buttons: Array[Button] = []
## A bal oldali lap indexe (mindig páros).
var _spread := 0
var _ids: Array[String] = []
## Lapok: az _ids-ből melyik [első, utolsó utáni] indexek kerülnek egy lapra (a mért magasság szerint).
var _page_ranges: Array[Vector2i] = []
var _pages: Array[VBoxContainer] = []
var _found: Label
var _prev: Button
var _next: Button
## Az egész elrendezés (cím, fülek, könyv): az X ennek a jobb felső sarkába kerül, a cím mellé.
var _window: Control


## A bezáró X helye (lásd CloseButton): a könyv lapjain nem takar el semmit.
func close_anchor() -> Control:
	return _window


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
	_paginate()
	_spread = 0
	if sound:
		Audio.play("ui_click")
	_show_spread()


func _flip(step: int) -> void:
	var page_count := _page_ranges.size()
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
	_window = root
	root.add_child(MenuStyle.title_label("Szörnyek könyve", 44, MenuStyle.GOLD))
	# Kategória-fülek két sorban.
	var tabs := GridContainer.new()
	tabs.columns = ceili(Bestiary.CATEGORIES.size() / 2.0)
	tabs.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tabs.add_theme_constant_override("h_separation", 6)
	tabs.add_theme_constant_override("v_separation", 4)
	root.add_child(tabs)
	for i in Bestiary.CATEGORIES.size():
		var tab := MenuStyle.button(Bestiary.CATEGORIES[i][0])
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
		var index := _spread + side
		if index >= _page_ranges.size():
			if side == 0 or _ids.is_empty():
				_empty(page, side)
			continue
		var range_on_page := _page_ranges[index]
		for i in range(range_on_page.x, range_on_page.y):
			if i > range_on_page.x:
				page.add_child(_rule())
			page.add_child(_entry(_ids[i]))
	var page_count := _page_ranges.size()
	_prev.disabled = _spread <= 0
	_next.disabled = _spread + 2 >= page_count


## A felfedezett szörnyek lapokra osztása: egy lapra legfeljebb PER_PAGE kerül, de csak annyi, amennyinek a
## (betűtípussal megmért, tördelt) szövege kifér a lap magasságába. Egy túl hosszú bejegyzés egyedül kap lapot.
func _paginate() -> void:
	_page_ranges.clear()
	var start := 0
	var used := 0.0
	for i in _ids.size():
		var height := _entry_height(_ids[i])
		var extra := height if i == start else height + ENTRY_GAP * 2.0 + 2.0
		if i > start and (i - start >= PER_PAGE or used + extra > PAGE_INNER_HEIGHT):
			_page_ranges.append(Vector2i(start, i))
			start = i
			used = height
		else:
			used += extra
	if start < _ids.size():
		_page_ranges.append(Vector2i(start, _ids.size()))


## Egy bejegyzés várható magassága: a név, a leírás és a képességek tördelt sorai (legalább az ikon).
func _entry_height(monster: String) -> float:
	var entry: Array = Bestiary.ENTRIES[monster]
	var height := _text_height(entry[0], 19, NAME_WIDTH) + _text_height(entry[1], 14, TEXT_WIDTH)
	var abilities := Bestiary.abilities_text(monster)
	if not abilities.is_empty():
		height += _text_height("Képességek: " + abilities, 13, TEXT_WIDTH)
	if not Bestiary.depth_text(monster).is_empty():
		height += _text_height("Megjelenik: " + Bestiary.depth_text(monster), 13, TEXT_WIDTH)
	return maxf(height, ICON_SIZE.y)


func _text_height(text: String, font_size: int, width: float) -> float:
	var probe := _pages[0]
	var font := probe.get_theme_font("font", "Label")
	var spacing := float(probe.get_theme_constant("line_spacing", "Label"))
	var size := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size,
		-1, TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE)
	var lines := maxf(1.0, roundf(size.y / font.get_height(font_size)))
	return size.y + lines * spacing + 2.0


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
	# A hosszú név (pl. Azazelé) tördelődik, és nem tolja ki a lapból a szöveget.
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.x = NAME_WIDTH
	header.add_child(name_label)
	header.add_child(UiStyle.label("× %d" % Bestiary.kills(monster), 17, Color(0.6, 0.18, 0.12)))
	var description := UiStyle.label(entry[1], 14, UiStyle.INK_LIGHT)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = TEXT_WIDTH
	text.add_child(description)
	var abilities := Bestiary.abilities_text(monster)
	if not abilities.is_empty():
		var ability_label := UiStyle.label("Képességek: " + abilities, 13, Color(0.45, 0.22, 0.6))
		ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ability_label.custom_minimum_size.x = TEXT_WIDTH
		text.add_child(ability_label)
	# Melyik emelettől jöhet (a felfedezett szörnyeknél; a könyv csak azokat mutatja).
	var depth := Bestiary.depth_text(monster)
	if not depth.is_empty():
		var depth_label := UiStyle.label("Megjelenik: " + depth, 13, Color(0.2, 0.38, 0.55))
		depth_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		depth_label.custom_minimum_size.x = TEXT_WIDTH
		text.add_child(depth_label)
	return row


func _rule() -> ColorRect:
	var line := ColorRect.new()
	line.color = Color(0.42, 0.28, 0.16, 0.4)
	line.custom_minimum_size = Vector2(PAGE_SIZE.x - 40, 2)
	return line
