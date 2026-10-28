extends CanvasLayer
## Eredmények könyve (a táborban, a harmadik állványon, E-re): bőrkötéses, nyitott könyv, mint a Szörnyek könyve.
## Két lap, lapanként PER_PAGE teljesítmény (Achievements.LIST): név, leírás, hol tartasz, jutalom; ha elérted,
## "Átvétel" gomb, ha átvetted, pipa. Lapozás: a nyilakkal, vagy A / D, ← / →. Megnyitását a Menus kezeli.

const LEATHER := Color(0.3, 0.25, 0.1)
const LEATHER_DARK := Color(0.15, 0.12, 0.04)
const PAGE_SIZE := Vector2(420, 430)
const PER_PAGE := 5
const DONE_INK := Color(0.2, 0.45, 0.15)

## A bal oldali lap indexe (mindig páros).
var _spread := 0
var _pages: Array[VBoxContainer] = []
var _found: Label
var _prev: Button
var _next: Button
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
	_show()
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


func _page_count() -> int:
	return ceili(Achievements.LIST.size() / float(PER_PAGE))


func _flip(step: int) -> void:
	var target := _spread + step
	if target < 0 or target >= _page_count():
		return
	_spread = target
	Audio.play("ui_click")
	_show()


func _show() -> void:
	for side in 2:
		var page := _pages[side]
		for child in page.get_children():
			child.queue_free()
		var start := (_spread + side) * PER_PAGE
		for i in range(start, mini(start + PER_PAGE, Achievements.LIST.size())):
			page.add_child(_entry(Achievements.LIST[i]))
	_prev.disabled = _spread <= 0
	_next.disabled = _spread + 2 >= _page_count()
	var waiting := Achievements.waiting()
	_found.text = "Elért eredmények: %d / %d%s" % [Achievements.done_count(), Achievements.LIST.size(),
		"   ·   Átvehető jutalom: %d" % waiting if waiting > 0 else ""]


## Egy teljesítmény sora: név (zöld, ha megvan), leírás, hol tartasz és a jutalom, jobbra a gomb vagy a pipa.
func _entry(entry: Dictionary) -> Control:
	var reached := Achievements.reached(entry)
	var claimed := Achievements.claimed(entry)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size.y = PAGE_SIZE.y / PER_PAGE - 14
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 1)
	row.add_child(texts)
	texts.add_child(UiStyle.label(str(entry["name"]), 18, DONE_INK if reached else UiStyle.INK))
	var text := UiStyle.label(str(entry["text"]), 14, UiStyle.INK_LIGHT)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = PAGE_SIZE.x - 150
	texts.add_child(text)
	var goal := int(entry["goal"])
	var status := "Jutalom: " + Achievements.reward_text(entry["reward"])
	if goal > 1:
		status = "%d / %d   ·   %s" % [mini(Achievements.progress(entry), goal), goal, status]
	texts.add_child(UiStyle.label(status, 13, UiStyle.INK_LIGHT))
	if claimed:
		var tick := UiStyle.label("✔ Átvéve", 15, DONE_INK)
		tick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tick)
	elif reached:
		var button := MenuStyle.button("Átvétel")
		button.custom_minimum_size = Vector2(96, 34)
		button.add_theme_font_size_override("font_size", 14)
		button.focus_mode = Control.FOCUS_NONE
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.pressed.connect(_claim.bind(entry))
		row.add_child(button)
	return row


func _claim(entry: Dictionary) -> void:
	if Achievements.claim(entry):
		Audio.play("coin")
		_show()


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
	root.add_child(MenuStyle.title_label("Eredmények könyve", 44, MenuStyle.GOLD))

	var book := HBoxContainer.new()
	book.add_theme_constant_override("separation", 10)
	book.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(book)
	_prev = _arrow("◀", -2)
	book.add_child(_prev)
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
	book.add_child(cover)
	var spread := HBoxContainer.new()
	spread.add_theme_constant_override("separation", 0)
	cover.add_child(spread)
	for side in 2:
		if side == 1:
			var spine := ColorRect.new()
			spine.color = LEATHER_DARK
			spine.custom_minimum_size = Vector2(14, 0)
			spread.add_child(spine)
		var page := PanelContainer.new()
		page.add_theme_stylebox_override("panel", UiStyle.plain_panel())
		page.custom_minimum_size = PAGE_SIZE
		spread.add_child(page)
		var list := VBoxContainer.new()
		list.add_theme_constant_override("separation", 10)
		page.add_child(list)
		_pages.append(list)
	_next = _arrow("▶", 2)
	book.add_child(_next)

	_found = Label.new()
	_found.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	_found.add_theme_font_size_override("font_size", 18)
	_found.add_theme_color_override("font_color", MenuStyle.PARCHMENT)
	_found.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_found)
	var hint := Label.new()
	hint.text = "A / D vagy ← / → lapozás   ·   [E] / [Esc] bezárás"
	hint.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.75, 0.68, 0.6))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)


func _arrow(text: String, step: int) -> Button:
	var button := MenuStyle.button(text)
	button.custom_minimum_size = Vector2(48, 64)
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(_flip.bind(step))
	return button
