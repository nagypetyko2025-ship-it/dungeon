extends CanvasLayer
## Küldetések könyve (J): bőrkötéses, nyitott könyv, két pergamenlappal. Minden lapon egy
## küldetés (feladat, haladás, jutalom, állapot: folyamatban / kész / teljesítve).
## Lapozás: a nyilakkal, vagy A / D, ← / →. Az első kész vagy futó küldetésnél nyílik ki.
## Megnyitását/bezárását a Menus kezeli (open()/close()).

const LEATHER := Color(0.36, 0.18, 0.1)
const LEATHER_DARK := Color(0.2, 0.09, 0.05)
const PAGE_SIZE := Vector2(400, 470)
const SCROLL: Texture2D = preload("res://assets/ui/quest_scroll.png")

var _ids: Array = []
## A bal oldali lap indexe (mindig páros).
var _spread := 0
var _pages: Array[VBoxContainer] = []
var _page_numbers: Array[Label] = []
var _prev: Button
var _next: Button


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_ids = Quests.ALL.keys()
	_build()


func open() -> void:
	# Az első kész (átvehető) küldetésnél nyílik ki, különben az első még futónál.
	var first := -1
	for i in _ids.size():
		if Quests.is_complete(_ids[i]):
			first = i
			break
	if first < 0:
		for i in _ids.size():
			if not Progress.quests_done.has(_ids[i]):
				first = i
				break
	_spread = (first - first % 2) if first >= 0 else 0
	_show_spread()
	visible = true


func close() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not visible or key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_A, KEY_LEFT: _flip(-2)
		KEY_D, KEY_RIGHT: _flip(2)
		_: return
	get_viewport().set_input_as_handled()


func _flip(step: int) -> void:
	var target := clampi(_spread + step, 0, (_ids.size() - 1) / 2 * 2)
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
	root.add_child(MenuStyle.title_label("Küldetések könyve", 56, MenuStyle.GOLD))

	# A könyv: bőrborító, benne két lap, középen a gerinc.
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
		content.add_theme_constant_override("separation", 10)
		page.add_child(content)
		_pages.append(content)
		if side == 0:
			# Gerinc: sötét csík a két lap között.
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
	_prev.pressed.connect(_flip.bind(-2))
	nav.add_child(_prev)
	for i in 2:
		var number := Label.new()
		number.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
		number.add_theme_font_size_override("font_size", 20)
		number.add_theme_color_override("font_color", MenuStyle.PARCHMENT)
		number.custom_minimum_size.x = 70
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nav.add_child(number)
		_page_numbers.append(number)
	_next = MenuStyle.button("Következő ►")
	_next.custom_minimum_size = Vector2(200, 52)
	_next.pressed.connect(_flip.bind(2))
	nav.add_child(_next)
	var hint := Label.new()
	hint.text = "A / D vagy ← / → lapozás   ·   [J] / [Esc] bezárás"
	hint.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.75, 0.68, 0.6))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)


func _show_spread() -> void:
	for side in 2:
		var index := _spread + side
		_fill_page(_pages[side], index)
		_page_numbers[side].text = "%d. lap" % (index + 1) if index < _ids.size() else ""
	_prev.disabled = _spread <= 0
	_next.disabled = _spread + 2 >= _ids.size()


func _fill_page(page: VBoxContainer, index: int) -> void:
	for child in page.get_children():
		child.queue_free()
	if index >= _ids.size():
		var end := UiStyle.label("— A könyv további lapjai még üresek. —", 17, UiStyle.INK_LIGHT)
		end.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		end.size_flags_vertical = Control.SIZE_EXPAND_FILL
		end.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		page.add_child(end)
		return
	var id: String = _ids[index]
	var quest: Dictionary = Quests.ALL[id]
	var done := Progress.quests_done.has(id)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	page.add_child(header)
	var icon := TextureRect.new()
	icon.texture = SCROLL
	icon.custom_minimum_size = Vector2(44, 44)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(icon)
	var title := UiStyle.label(quest["name"], 24, UiStyle.INK)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(title)
	page.add_child(_rule())
	var task := UiStyle.label(quest["text"], 18, UiStyle.INK)
	task.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	task.custom_minimum_size.x = PAGE_SIZE.x - 40
	page.add_child(task)

	var goal: int = quest["goal"]
	var progress := Quests.progress(id)
	page.add_child(UiStyle.label("Haladás: %d / %d" % [progress, goal], 17, UiStyle.INK_LIGHT))
	var bar := ProgressBar.new()
	bar.max_value = goal
	bar.value = progress
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(PAGE_SIZE.x - 40, 18)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.42, 0.28, 0.16, 0.3)
	back.border_color = Color(0.42, 0.28, 0.16)
	back.set_border_width_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.3, 0.6, 0.25) if progress >= goal else Color(0.75, 0.5, 0.15)
	bar.add_theme_stylebox_override("background", back)
	bar.add_theme_stylebox_override("fill", fill)
	page.add_child(bar)
	page.add_child(UiStyle.label("Jutalom: " + Quests.reward_text(id), 17, Color(0.6, 0.38, 0.05)))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(spacer)
	var state_text := "★ FOLYAMATBAN — a kazamatában számol"
	var state_color := Color(0.6, 0.3, 0.05)
	if done:
		state_text = "✔ TELJESÍTVE — jutalom átvéve"
		state_color = Color(0.24, 0.5, 0.2)
	elif progress >= goal:
		state_text = "KÉSZ — a jutalom a kocsmárosnál vár!"
		state_color = Color(0.24, 0.5, 0.2)
	var state := UiStyle.label(state_text, 19, state_color)
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	state.custom_minimum_size.x = PAGE_SIZE.x - 40
	page.add_child(state)


func _rule() -> ColorRect:
	var line := ColorRect.new()
	line.color = Color(0.42, 0.28, 0.16, 0.6)
	line.custom_minimum_size = Vector2(PAGE_SIZE.x - 40, 2)
	return line
