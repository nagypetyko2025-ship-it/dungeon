extends CanvasLayer
## Inventory ablak (I gomb): bal oldalt a felszerelés-helyek, jobbra a táska,
## alul a kijelölt tárgy leírása és az arany. A tárgyakat húzással lehet mozgatni
## (táskából a helyére, vissza, vagy a táskán belül); jobb klikk: gyors fel/levétel.
## Megnyitását/bezárását a Menus kezeli.

const BAG_COLUMNS := 6
## A leíráspanel fix mérete (ettől nem változik az ablak mérete).
const INFO_SIZE := Vector2(380, 520)
## A kijelölt táskatárgy célhelye így világít.
const TARGET_GLOW := Color(1.5, 1.25, 0.55)
## A felszerelés "karakterbábu" elrendezésben, ahogy a testen van: fent a sisak,
## középen a mellvért, alatta a nadrág és a cipő; oldalt a fegyver, a gyűrű, az amulett,
## a kesztyű és a talizmán.
## "" = üres cella.
const EQUIPMENT_LAYOUT: Array = [
	["", "helmet", "amulet"],
	["weapon", "chest", "ring"],
	["gloves", "pants", "trinket"],
	["", "boots", ""],
]

var _player: Node
var _inventory: Inventory
var _equipment_box: GridContainer
## Felszerelés-hely neve -> a hozzá tartozó InventorySlot (a célhely kiemeléséhez).
var _equip_slots := {}
var _bag_grid: GridContainer
var _gold_label: Label
var _info_title: Label
var _info_text: RichTextLabel
var _hint: Label
var _title: Label
var _sell_slot: SellSlot

## Eladás mód (a boltos pultjánál nyitva): a táska tárgyait el lehet adni.
## A Menus állítja be megnyitás előtt; bezáráskor visszaáll.
var sell_mode := false


func _ready() -> void:
	visible = false
	_build()


func open() -> void:
	if _inventory == null:
		_player = get_tree().get_first_node_in_group("player")
		_inventory = _player.get_node("Inventory")
		_inventory.changed.connect(_on_inventory_changed)
	_title.text = "Eladás a boltosnak" if sell_mode else "Felszerelés"
	_set_sell_slot_shown(sell_mode)
	_refresh()
	_show_info(null, "")
	visible = true


func close() -> void:
	visible = false
	sell_mode = false


func _set_sell_slot_shown(shown: bool) -> void:
	_sell_slot.modulate.a = 1.0 if shown else 0.0
	_sell_slot.mouse_filter = Control.MOUSE_FILTER_STOP if shown else Control.MOUSE_FILTER_IGNORE
	for child in _sell_slot.get_children():
		(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_inventory_changed() -> void:
	if visible:
		_refresh()


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
	window.add_theme_stylebox_override("panel", UiStyle.metal_panel())
	center.add_child(window)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	window.add_child(root)
	var title_bar := UiStyle.title_bar("Felszerelés")
	_title = title_bar.get_child(0)
	root.add_child(title_bar)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 28)
	root.add_child(columns)

	var equipment_column := VBoxContainer.new()
	equipment_column.add_theme_constant_override("separation", 6)
	columns.add_child(equipment_column)
	equipment_column.add_child(UiStyle.label("Felszerelve", 18, UiStyle.TEXT_GOLD, true))
	_equipment_box = GridContainer.new()
	_equipment_box.columns = EQUIPMENT_LAYOUT[0].size()
	_equipment_box.add_theme_constant_override("h_separation", 12)
	_equipment_box.add_theme_constant_override("v_separation", 6)
	equipment_column.add_child(_equipment_box)

	var bag_box := VBoxContainer.new()
	bag_box.add_theme_constant_override("separation", 6)
	columns.add_child(bag_box)
	bag_box.add_child(UiStyle.label("Táska", 18, UiStyle.TEXT_GOLD, true))
	_bag_grid = GridContainer.new()
	_bag_grid.columns = BAG_COLUMNS
	_bag_grid.add_theme_constant_override("h_separation", 4)
	_bag_grid.add_theme_constant_override("v_separation", 4)
	bag_box.add_child(_bag_grid)
	# Az eladás mező mindig helyet foglal (csak eladáskor látszik), így nem ugrik az ablak mérete.
	# Alatta egy sorban: az eladás mező (csak a boltosnál látszik) és a kuka.
	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 8)
	bag_box.add_child(bottom_row)
	_sell_slot = SellSlot.new()
	_sell_slot.on_sell = _sell_from_bag
	_sell_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(_sell_slot)
	_set_sell_slot_shown(false)
	var trash := TrashSlot.new()
	trash.on_drop = func(data: Dictionary) -> void: _ask_trash(int(data["inventory_key"]))
	bottom_row.add_child(trash)

	# Jobbra: leírás (pergamen), fix méretű, hogy a hosszabb leírástól se változzon az ablak.
	var info := PanelContainer.new()
	info.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	info.custom_minimum_size = INFO_SIZE
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(info)
	var info_box := VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 6)
	info.add_child(info_box)
	_info_title = UiStyle.label("", 20, UiStyle.INK)
	_info_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_title.custom_minimum_size.x = INFO_SIZE.x - 40
	info_box.add_child(_info_title)
	_info_text = RichTextLabel.new()
	_info_text.bbcode_enabled = true
	_info_text.fit_content = false
	# Hosszú leírás + összehasonlítás esetén görgethető (egérgörgővel).
	_info_text.scroll_active = true
	_info_text.clip_contents = true
	_info_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_info_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_text.add_theme_color_override("default_color", UiStyle.INK_LIGHT)
	_info_text.add_theme_font_size_override("normal_font_size", 15)
	_info_text.add_theme_constant_override("line_separation", 1)
	info_box.add_child(_info_text)
	_hint = UiStyle.label("", 14, UiStyle.INK_LIGHT)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size = Vector2(INFO_SIZE.x - 40, 60)
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	info_box.add_child(_hint)

	var bottom := HBoxContainer.new()
	root.add_child(bottom)
	var coin := TextureRect.new()
	coin.texture = SpriteSheet.region(Rect2(289, 385, 6, 7))
	coin.custom_minimum_size = Vector2(18, 21)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bottom.add_child(coin)
	_gold_label = UiStyle.label("0", 20, UiStyle.TEXT_GOLD, true)
	bottom.add_child(_gold_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(spacer)
	bottom.add_child(UiStyle.label("[I] bezárás", 14, Color(0.8, 0.74, 0.62)))


func _refresh() -> void:
	for child in _equipment_box.get_children():
		child.queue_free()
	_equip_slots.clear()
	for row: Array in EQUIPMENT_LAYOUT:
		for slot: String in row:
			var cell := VBoxContainer.new()
			cell.add_theme_constant_override("separation", 2)
			cell.custom_minimum_size = InventorySlot.SIZE + Vector2(20, 0)
			_equipment_box.add_child(cell)
			if slot.is_empty():
				continue
			var slot_node := _make_slot("equip", slot, _inventory.equipment[slot])
			slot_node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			_equip_slots[slot] = slot_node
			cell.add_child(slot_node)
			var name_label := UiStyle.label(Inventory.SLOT_NAMES[slot], 14, UiStyle.TEXT_LIGHT, true)
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.add_child(name_label)

	for child in _bag_grid.get_children():
		child.queue_free()
	for index in _inventory.bag.size():
		_bag_grid.add_child(_make_slot("bag", index, _inventory.bag[index]))
	_gold_label.text = str(_player.get("gold"))


func _make_slot(kind: String, key: Variant, item: Variant) -> InventorySlot:
	var slot := InventorySlot.new()
	slot.setup(kind, key, item, _inventory)
	slot.on_hover = _on_slot_hovered
	if sell_mode and kind == "bag":
		slot.on_right_click = func(clicked: InventorySlot) -> void: _sell_from_bag(clicked.key)
	return slot


## A boltos megveszi a táska adott helyén lévő tárgyat.
## Kuka: rákérdez, és ha igen, végleg törli a táska adott helyén lévő tárgyat.
func _ask_trash(index: int) -> void:
	var item: Variant = _inventory.bag[index]
	if item == null:
		return
	if item.get("quest", false):
		Audio.play("ui_error")
		_show_info(item, "Küldetéstárgy: nem dobhatod ki.")
		return
	ConfirmBox.ask(self, "Biztosan kidobod: %s? Nem lehet visszahozni." % item["name"], func() -> void:
		_inventory.take_from_bag(index)
		Audio.play("door_lock", -6.0)
		_show_info(null, "Kidobva: " + item["name"]))


func _sell_from_bag(index: int) -> void:
	var item = _inventory.bag[index]
	if item == null:
		return
	if not Items.can_sell(item):
		Audio.play("ui_error")
		_show_info(item, "Küldetéstárgy: nem adhatod el." if item.get("quest", false) else "Sztori tárgy: nem adhatod el.")
		return
	var price := Items.sell_price(item)
	_player.call("add_gold", price)
	Audio.play("sell")
	_inventory.take_from_bag(index)
	_show_info(item, "Eladva: +%d arany" % price)


## A táskában kijelölt tárgy célhelyének kiemelése (hova lehet betenni).
func _mark_target(slot_name: String) -> void:
	for key: String in _equip_slots:
		var target: InventorySlot = _equip_slots[key]
		if is_instance_valid(target):
			target.add_theme_stylebox_override("panel", UiStyle.slot(key == slot_name))
			target.modulate = TARGET_GLOW if key == slot_name else Color.WHITE


func _on_slot_hovered(item: Variant, slot: InventorySlot) -> void:
	_mark_target(item["slot"] if item != null and slot.kind == "bag" else "")
	if item != null and sell_mode:
		if slot.kind == "bag":
			_show_info(item, "Küldetéstárgy: nem adható el" if item.get("quest", false)
				else ("Sztori tárgy: nem adható el" if not Items.can_sell(item)
				else "Eladási ár: %d arany • húzd az eladás mezőre vagy jobb klikk" % Items.sell_price(item)))
		else:
			_show_info(item, "Előbb vedd le (húzd a táskába), hogy eladhasd.")
	elif item != null:
		var hint := "Húzd a kiemelt %s helyre • jobb klikk: gyors felvétel" % Items.slot_name(item)
		if not Characters.can_use(item):
			hint = "Ezt a fegyvert a mostani karaktered nem veheti fel."
		if slot.kind == "equip":
			hint = "A fegyvert csak egy másik fegyverre cserélheted." if slot.key == "weapon" \
				else "Húzd a táskába • jobb klikk: levétel"
		_show_info(item, hint)
		# Táskabeli tárgynál összehasonlítás a helyén lévő felvett tárggyal.
		var equipped: Variant = _inventory.equipment.get(item["slot"]) if slot.kind == "bag" else null
		if equipped != null:
			_info_text.text += "\n\n" + Items.compare_bbcode(item, equipped)
	elif slot.kind == "equip":
		_show_info(null, "Üres hely: " + Inventory.SLOT_NAMES[slot.key])
	else:
		_show_info(null, "")


func _show_info(item: Variant, hint: String) -> void:
	if item == null:
		_info_title.text = hint if not hint.is_empty() else "Üres hely"
		_info_title.add_theme_color_override("font_color", UiStyle.INK)
		_info_text.text = "Vidd az egeret egy tárgy fölé a leírásáért, húzd a tárgyakat a helyükre."
		_hint.text = ""
		return
	_info_title.text = item["name"]
	_info_title.add_theme_color_override("font_color",
		Items.rarity_ink(item) if item.has("rarity") else UiStyle.INK)
	_info_text.text = Items.describe_bbcode(item)
	_hint.text = hint
