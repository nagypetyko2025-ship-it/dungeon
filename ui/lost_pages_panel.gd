class_name LostPagesPanel
extends CanvasLayer
## Az Elveszett lapok olvasója (LostPages): bal oldalt a lapok listája (a meg nem találtak helyén "???"), jobb
## oldalt a kiválasztott lap pergamenen. Megnyílik, amikor felveszel egy lapot, és a J könyv "Elveszett lapok"
## gombjával is. A Menus kezeli (open()/close()); a show_page az aktuális jelenetben hozza létre / nyitja meg.

const PARCHMENT := Color(0.93, 0.86, 0.68)
const INK := Color(0.24, 0.15, 0.08)
const GOLD := Color(1.0, 0.85, 0.35)

## Ezt a lapot mutatja megnyitáskor (-1: az első megtaláltat).
var selected := -1
var _built := false
var _list: VBoxContainer
var _title: Label
var _text: RichTextLabel
var _count: Label


## Megnyitja az olvasót az aktuális jelenetben, a megadott lapnál (ami épp nyitva van, bezárul).
static func show_page(tree: SceneTree, index: int) -> void:
	var scene := tree.current_scene
	var menus := scene.get_node_or_null("Menus")
	if menus == null:
		return
	var panel := scene.get_node_or_null("LostPagesPanel") as LostPagesPanel
	if panel == null:
		panel = LostPagesPanel.new()
		panel.name = "LostPagesPanel"
		panel.visible = false
		scene.add_child(panel)
	panel.selected = index
	menus.call("close_current")
	menus.call_deferred("open_menu", panel)


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS


func open() -> void:
	if not _built:
		_build()
	if selected < 0 or not LostPages.found(selected):
		selected = -1
		for i in LostPages.count():
			if LostPages.found(i):
				selected = i
				break
	_refresh()
	visible = true


func close() -> void:
	visible = false


func _build() -> void:
	_built = true
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	center.add_child(root)
	var heading := MenuStyle.title_label("Elveszett lapok", 40, GOLD)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(heading)
	_count = UiStyle.label("", 16, Color(0.85, 0.8, 0.7))
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_count)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	root.add_child(row)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	_list.custom_minimum_size = Vector2(250, 0)
	row.add_child(_list)
	var sheet := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PARCHMENT
	style.border_color = Color(0.55, 0.4, 0.2)
	style.set_border_width_all(4)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(22)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 10
	sheet.add_theme_stylebox_override("panel", style)
	sheet.custom_minimum_size = Vector2(560, 470)
	row.add_child(sheet)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	sheet.add_child(page)
	_title = UiStyle.label("", 24, INK)
	page.add_child(_title)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = false
	_text.scroll_active = true
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_color_override("default_color", INK)
	_text.add_theme_font_size_override("normal_font_size", 17)
	page.add_child(_text)


func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	_count.text = "Megtalált lapok: %d / %d — Vidor bányaírnok naplója" % [LostPages.found_count(), LostPages.count()]
	for i in LostPages.count():
		var found := LostPages.found(i)
		var button := MenuStyle.button(str(LostPages.PAGES[i]["title"]) if found else "???")
		button.custom_minimum_size = Vector2(250, 40)
		button.add_theme_font_size_override("font_size", 13)
		button.focus_mode = Control.FOCUS_NONE
		button.disabled = not found
		button.modulate = Color(1.2, 1.1, 0.8) if i == selected else (Color.WHITE if found else Color(0.55, 0.5, 0.45))
		button.pressed.connect(_select.bind(i))
		_list.add_child(button)
	if selected < 0:
		_title.text = "Még egy lapot sem találtál."
		_text.text = "Vidor bányaírnok négyszáz éve széttépte a naplóját, és a lapjait elrejtette: a táborban, a régi " \
			+ "házakban, és lent, a kazamata termei között. Ha meglátsz egy aranyan izzó lapot, vedd fel."
		return
	_title.text = str(LostPages.PAGES[selected]["title"])
	_text.text = str(LostPages.PAGES[selected]["text"])
	_text.scroll_to_line(0)


func _select(index: int) -> void:
	selected = index
	_refresh()
