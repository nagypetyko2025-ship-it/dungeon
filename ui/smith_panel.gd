class_name SmithPanel
extends CanvasLayer
## A kovács műhelye (a táborban, a kovácsnál E-vel). Fent a porok (minden ritkaságnak saját pora), bal
## oldalt a táskád, jobbra a felszerelésed és a tárgy leírása, középen egy izzó kör, közepén egy hellyel:
## ide húzz (vagy kattints) egy tárgyat. Utána két lehetőség (a szabályok: Smithing):
##   Fejlesztés — a következő ritkaságba lép, ha van 4 porod abból a ritkaságból; 65% eséllyel sikerül.
##   Szétszedés — a tárgy elvész, és a ritkaságának porából 1-et (30% eséllyel 2-t) kapsz. Ami rajtad van
##     (a felszerelésed), azt nem lehet beolvasztani, csak fejleszteni.

## Sikeres fejlesztés / szétszedés (a gyakorló pálya vezetője figyeli).
signal upgraded(item: Dictionary)
signal dismantled(item: Dictionary)

const RING_SIZE := Vector2(224, 224)
const ACTION_SIZE := Vector2(236, 44)
const GOOD_INK := Color(0.24, 0.5, 0.2)
const BAD_INK := Color(0.66, 0.18, 0.15)

## Ritkaság -> a por számát mutató felirat.
var _dust_labels := {}
var _bag_grid: ItemGrid
var _equip_grid: ItemGrid
var _ring: ForgeRing
var _slot: AnvilSlot
var _item_name: Label
var _upgrade_button: Button
var _upgrade_note: Label
var _dismantle_button: Button
var _dismantle_note: Label
var _info_title: Label
var _info_text: RichTextLabel
var _message: Label
## A kiválasztott tárgy helye: ["bag", index] vagy ["equip", hely]; üres = nincs kiválasztva.
var _selected: Array = []


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func open() -> void:
	_selected = []
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
	root.add_theme_constant_override("separation", 10)
	window.add_child(root)
	root.add_child(UiStyle.title_bar("Kovácsműhely"))

	# A porok: minden ritkaságé külön.
	var dust_row := HBoxContainer.new()
	dust_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dust_row.add_theme_constant_override("separation", 10)
	root.add_child(dust_row)
	for rarity: String in Items.RARITY_ORDER:
		dust_row.add_child(_dust_chip(rarity))

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 22)
	root.add_child(columns)

	var bag_box := VBoxContainer.new()
	columns.add_child(bag_box)
	bag_box.add_child(UiStyle.label("Táska", 18, UiStyle.INK))
	_bag_grid = _grid(6)
	bag_box.add_child(_bag_grid)
	var help := UiStyle.label("Húzz (vagy kattints) egy tárgyat\na kör közepére.", 14, UiStyle.INK_LIGHT)
	bag_box.add_child(help)

	var forge := VBoxContainer.new()
	forge.add_theme_constant_override("separation", 6)
	columns.add_child(forge)
	_ring = ForgeRing.new()
	_ring.custom_minimum_size = RING_SIZE
	_ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	forge.add_child(_ring)
	_slot = AnvilSlot.new()
	_slot.panel = self
	var slot_size := InventorySlot.SIZE + Vector2(8, 8)
	_slot.custom_minimum_size = slot_size
	_ring.add_child(_slot)
	# Pontosan a kör közepére.
	_slot.anchor_left = 0.5
	_slot.anchor_right = 0.5
	_slot.anchor_top = 0.5
	_slot.anchor_bottom = 0.5
	_slot.offset_left = -slot_size.x / 2.0
	_slot.offset_right = slot_size.x / 2.0
	_slot.offset_top = -slot_size.y / 2.0
	_slot.offset_bottom = slot_size.y / 2.0
	_item_name = UiStyle.label("", 17, UiStyle.INK)
	_item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_item_name.custom_minimum_size.x = ACTION_SIZE.x
	forge.add_child(_item_name)
	_upgrade_button = _action_button("Fejlesztés", _upgrade)
	forge.add_child(_upgrade_button)
	_upgrade_note = _note()
	forge.add_child(_upgrade_note)
	_dismantle_button = _action_button("Szétszedés", _dismantle)
	forge.add_child(_dismantle_button)
	_dismantle_note = _note()
	forge.add_child(_dismantle_note)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	columns.add_child(right)
	right.add_child(UiStyle.label("Felszerelésed", 18, UiStyle.INK))
	_equip_grid = _grid(5)
	right.add_child(_equip_grid)
	var info := PanelContainer.new()
	info.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	info.custom_minimum_size = Vector2(316, 232)
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(info)
	var info_box := VBoxContainer.new()
	info.add_child(info_box)
	_info_title = UiStyle.label("", 18, UiStyle.INK)
	_info_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_title.custom_minimum_size.x = 280
	info_box.add_child(_info_title)
	_info_text = RichTextLabel.new()
	_info_text.bbcode_enabled = true
	_info_text.scroll_active = false
	_info_text.fit_content = true
	_info_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_info_text.add_theme_color_override("default_color", UiStyle.INK_LIGHT)
	_info_text.add_theme_font_size_override("normal_font_size", 14)
	info_box.add_child(_info_text)

	var bottom := HBoxContainer.new()
	root.add_child(bottom)
	_message = UiStyle.label("", 16, GOOD_INK)
	_message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(_message)
	bottom.add_child(UiStyle.label("[E] / [Esc] bezárás", 14, UiStyle.INK_LIGHT))


func _dust_chip(rarity: String) -> PanelContainer:
	var chip := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.42, 0.28, 0.16, 0.12)
	style.border_color = Items.RARITIES[rarity]["ink"]
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 6
	style.content_margin_right = 10
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	chip.add_theme_stylebox_override("panel", style)
	chip.tooltip_text = "%s: szétszedéssel kapod, a %s szintre fejlesztéshez kell (%d db)." % [
		Smithing.dust_name(rarity), Items.RARITIES[rarity]["name"].to_lower(), Smithing.UPGRADE_COST]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	chip.add_child(row)
	var icon := TextureRect.new()
	icon.texture = Smithing.DUST_ICONS[rarity]
	icon.custom_minimum_size = Vector2(36, 36)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", -4)
	row.add_child(texts)
	texts.add_child(UiStyle.label(Smithing.dust_name(rarity), 13, Items.RARITIES[rarity]["ink"]))
	var count := UiStyle.label("0", 19, UiStyle.INK)
	texts.add_child(count)
	_dust_labels[rarity] = count
	return chip


func _grid(columns: int) -> ItemGrid:
	var grid := ItemGrid.new()
	grid.columns = columns
	grid.draggable = true
	grid.item_clicked.connect(func(index: int) -> void: select_from(grid, index))
	grid.item_hovered.connect(func(index: int) -> void:
		if grid.item_at(index) != null:
			_show_item(grid.item_at(index)))
	return grid


func _action_button(text: String, action: Callable) -> Button:
	var button := MenuStyle.button(text)
	button.custom_minimum_size = ACTION_SIZE
	button.add_theme_font_size_override("font_size", 20)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(action)
	return button


func _note() -> Label:
	var label := UiStyle.label("", 13, UiStyle.INK_LIGHT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = ACTION_SIZE.x + 20
	return label


## Egy rácsból kiválasztott tárgy a kör közepére kerül (kattintás vagy behúzás).
func select_from(grid: ItemGrid, index: int) -> void:
	if grid.item_at(index) == null:
		return
	_selected = ["bag", index] if grid == _bag_grid else ["equip", Inventory.EQUIPMENT_SLOTS[index]]
	Audio.play("equip")
	_message.text = ""
	_refresh()
	_show_item(_selected_item())


## Elfogadja-e a kör közepe ezt a húzást (a táska vagy a felszerelés egy tárgyát).
func accepts(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var grid: Variant = data.get("grid")
	return (grid == _bag_grid or grid == _equip_grid) and (grid as ItemGrid).item_at(int(data.get("grid_index", -1))) != null


## A kör közepére kattintva kiveszi onnan a tárgyat.
func clear_selection() -> void:
	if _selected.is_empty():
		return
	_selected = []
	Audio.play("ui_click")
	_refresh()


func _selected_item() -> Variant:
	if _selected.is_empty():
		return null
	var inventory := _inventory()
	return inventory.bag[_selected[1]] if _selected[0] == "bag" else inventory.equipment.get(_selected[1])


func _refresh() -> void:
	for rarity: String in _dust_labels:
		(_dust_labels[rarity] as Label).text = str(Smithing.dust_of(rarity))
	var inventory := _inventory()
	_bag_grid.set_items(inventory.bag, Inventory.BAG_SIZE)
	var equipped: Array = []
	for slot: String in Inventory.EQUIPMENT_SLOTS:
		equipped.append(inventory.equipment.get(slot))
	_equip_grid.set_items(equipped, equipped.size())
	var item: Variant = _selected_item()
	if item == null:
		_selected = []
	elif _selected[0] == "bag":
		_bag_grid.select(_selected[1])
	else:
		_equip_grid.select(Inventory.EQUIPMENT_SLOTS.find(_selected[1]))
	_slot.show_item(item)
	_ring.tint = Items.rarity_color(item) if item != null else ForgeRing.IDLE_TINT
	if item == null:
		_item_name.text = "Húzz ide egy tárgyat"
		_item_name.add_theme_color_override("font_color", UiStyle.INK_LIGHT)
		_upgrade_button.disabled = true
		_dismantle_button.disabled = true
		_upgrade_note.text = "%d por a következő ritkaságból\n%d%% esély a sikerre" % [Smithing.UPGRADE_COST,
			roundi(Smithing.upgrade_chance() * 100.0)]
		_dismantle_note.text = "1 por a tárgy ritkaságából\n(%d%% eséllyel 2)" \
			% roundi(Smithing.DOUBLE_DUST_CHANCE * 100.0)
		_set_note_color(_upgrade_note, UiStyle.INK_LIGHT)
		_set_note_color(_dismantle_note, UiStyle.INK_LIGHT)
		return
	_item_name.text = item["name"]
	_item_name.add_theme_color_override("font_color", Items.rarity_ink(item))
	# Fejlesztés: mi kell hozzá, és megvan-e.
	var block := Smithing.upgrade_block(item)
	if not block.is_empty():
		_upgrade_button.disabled = true
		_upgrade_note.text = block
		_set_note_color(_upgrade_note, BAD_INK)
	else:
		var next := Smithing.next_rarity(item["rarity"])
		var have := Smithing.dust_of(next)
		_upgrade_button.disabled = have < Smithing.UPGRADE_COST
		_upgrade_note.text = "→ %s: %d %s (van: %d)\n%d%% esély a sikerre" % [Items.RARITIES[next]["name"],
			Smithing.UPGRADE_COST, Smithing.dust_name(next).to_lower(), have, roundi(Smithing.upgrade_chance() * 100.0)]
		_set_note_color(_upgrade_note, BAD_INK if have < Smithing.UPGRADE_COST else UiStyle.INK_LIGHT)
	block = Smithing.dismantle_block(item)
	if block.is_empty() and _selected[0] == "equip":
		block = "Rajtad van: nem olvaszthatod be. Előbb vedd le az [I] ablakban."
	_dismantle_button.disabled = not block.is_empty()
	_dismantle_note.text = block if not block.is_empty() else "A tárgy elvész: +1 %s\n(%d%% eséllyel 2)" % [
		Smithing.dust_name(item["rarity"]).to_lower(), roundi(Smithing.DOUBLE_DUST_CHANCE * 100.0)]
	_set_note_color(_dismantle_note, BAD_INK if not block.is_empty() else UiStyle.INK_LIGHT)


func _set_note_color(label: Label, color: Color) -> void:
	label.add_theme_color_override("font_color", color)


func _upgrade() -> void:
	var item: Variant = _selected_item()
	if item == null or not Smithing.upgrade_block(item).is_empty():
		return
	var next := Smithing.next_rarity(item["rarity"])
	if Smithing.dust_of(next) < Smithing.UPGRADE_COST:
		Audio.play("ui_error")
		return
	Smithing.add_dust(next, -Smithing.UPGRADE_COST)
	Audio.play("anvil", 2.0)
	if randf() < Smithing.upgrade_chance():
		var better := Smithing.upgraded(item)
		_inventory().replace(_selected[0], _selected[1], better)
		Audio.play("level_up", -6.0)
		_ring.flash(Items.rarity_color(better))
		_say("Sikerült! %s mostantól %s." % [better["name"], Items.rarity_name(better).to_lower()], GOOD_INK)
		_refresh()
		_show_item(better)
		upgraded.emit(better)
	else:
		Audio.play("door_lock", -4.0)
		_ring.flash(Color(0.35, 0.3, 0.3))
		_say("Nem sikerült... a %d %s elveszett, a tárgy megmaradt." % [Smithing.UPGRADE_COST,
			Smithing.dust_name(next).to_lower()], BAD_INK)
		_refresh()


func _dismantle() -> void:
	var item: Variant = _selected_item()
	if item == null or not Smithing.dismantle_block(item).is_empty() or _selected[0] == "equip":
		return
	# Értékes tárgynál megerősítést kér.
	if Items.at_least(item["rarity"], "epic"):
		ConfirmBox.ask(self, "Biztosan szétszeded: %s? A tárgy elvész." % item["name"], _do_dismantle)
	else:
		_do_dismantle()


func _do_dismantle() -> void:
	var item: Variant = _selected_item()
	if item == null or _selected[0] == "equip":
		return
	var amount := Smithing.roll_dust()
	_inventory().replace(_selected[0], _selected[1], null)
	Smithing.add_dust(item["rarity"], amount)
	_selected = []
	Audio.play("anvil", 2.0)
	Audio.play("coin")
	_ring.flash(Items.rarity_color(item))
	_say("Szétszedve: %s  →  +%d %s" % [item["name"], amount, Smithing.dust_name(item["rarity"]).to_lower()], GOOD_INK)
	_refresh()
	_show_item(null)
	dismantled.emit(item)


func _say(text: String, color: Color) -> void:
	_message.text = text
	_message.add_theme_color_override("font_color", color)


func _show_item(item: Variant) -> void:
	if item == null:
		_info_title.text = "—"
		_info_title.add_theme_color_override("font_color", UiStyle.INK)
		_info_text.text = "Vidd az egeret egy tárgy fölé a leírásáért."
		return
	_info_title.text = item["name"]
	_info_title.add_theme_color_override("font_color", Items.rarity_ink(item))
	_info_text.text = Items.describe_bbcode(item)


## A kör közepén lévő hely: ide lehet húzni a táska / felszerelés tárgyait; rákattintva kiürül.
class AnvilSlot:
	extends Panel
	var panel: SmithPanel
	var _fill: ColorRect
	var _icon: TextureRect

	func _ready() -> void:
		add_theme_stylebox_override("panel", UiStyle.slot())
		_fill = ColorRect.new()
		_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 7)
		_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_fill)
		_icon = TextureRect.new()
		_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 11)
		_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_icon)
		show_item(null)

	func show_item(item: Variant) -> void:
		if _icon == null:
			return
		_fill.color = Items.rarity_fill(item, 0.35) if item != null else Color(0, 0, 0, 0)
		_icon.texture = Items.icon(item) if item != null else null
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if item != null else Control.CURSOR_ARROW

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		var ok := panel.accepts(data)
		add_theme_stylebox_override("panel", UiStyle.slot(ok))
		return ok

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		add_theme_stylebox_override("panel", UiStyle.slot())
		panel.select_from(data["grid"], int(data["grid_index"]))

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_EXIT or what == NOTIFICATION_DRAG_END:
			add_theme_stylebox_override("panel", UiStyle.slot())

	func _gui_input(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			panel.clear_selection()
			accept_event()


## Az izzó kör: sötét kőkorong, bronzkeret, lassan forgó rúnagyűrű. A kiválasztott tárgy ritkaságának
## színében izzik; fejlesztéskor / szétszedéskor felvillan.
class ForgeRing:
	extends Control
	const IDLE_TINT := Color(1.0, 0.55, 0.2)
	const RUNES := 16
	## Egy rúna vonalai (a rúna közepéhez képest, egységnyi méretben), felváltva.
	const GLYPHS := [
		[[Vector2(0, -1), Vector2(0, 1)], [Vector2(0, -1), Vector2(0.7, -0.3)]],
		[[Vector2(-0.6, -1), Vector2(0.6, 1)], [Vector2(0.6, -1), Vector2(-0.6, 1)]],
		[[Vector2(0, -1), Vector2(0, 1)], [Vector2(-0.6, 0), Vector2(0.6, -0.6)], [Vector2(-0.6, 0.6), Vector2(0.6, 0)]],
		[[Vector2(-0.6, 1), Vector2(0, -1)], [Vector2(0, -1), Vector2(0.6, 1)]],
	]
	var tint := IDLE_TINT
	var _angle := 0.0
	var _flash := 0.0
	var _flash_color := Color.WHITE

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func flash(color: Color) -> void:
		_flash = 1.0
		_flash_color = color

	func _process(delta: float) -> void:
		_angle = wrapf(_angle + delta * 0.22, 0.0, TAU)
		_flash = move_toward(_flash, 0.0, delta * 1.6)
		queue_redraw()

	func _draw() -> void:
		var middle := size / 2.0
		var radius := minf(size.x, size.y) / 2.0 - 4.0
		var glow := tint.lerp(_flash_color, _flash)
		# Kőkorong, rajta befelé erősödő izzás.
		draw_circle(middle, radius, Color(0.13, 0.08, 0.06))
		for i in 10:
			var t := float(i) / 10.0
			draw_circle(middle, radius * (0.95 - t * 0.6), Color(glow, 0.02 + t * 0.02 + _flash * 0.05))
		# Bronzkeret.
		draw_arc(middle, radius, 0.0, TAU, 96, Color(0.42, 0.26, 0.12), 7.0)
		draw_arc(middle, radius - 4.0, 0.0, TAU, 96, Color(0.86, 0.62, 0.3), 2.0)
		# Rúnagyűrű a két vékony kör között.
		var rune_radius := radius * 0.74
		var ring_color := Color(glow, 0.75 + 0.25 * _flash)
		draw_arc(middle, rune_radius + 14.0, 0.0, TAU, 96, ring_color, 2.0)
		draw_arc(middle, rune_radius - 14.0, 0.0, TAU, 96, ring_color, 2.0)
		for i in RUNES:
			var angle := _angle + TAU * i / RUNES
			var at := middle + Vector2.from_angle(angle) * rune_radius
			var turn := angle + PI / 2.0
			for stroke: Array in GLYPHS[i % GLYPHS.size()]:
				var a: Vector2 = stroke[0]
				var b: Vector2 = stroke[1]
				draw_line(at + (a * 6.0).rotated(turn), at + (b * 6.0).rotated(turn), ring_color, 2.0)
		# A közepén a hely mögött világosabb folt.
		draw_circle(middle, 52.0, Color(glow, 0.12 + 0.3 * _flash))
