class_name CheatMenu
extends Node
## Csalómenü a [0] gombra (a Menus kezeli, megnyitva megáll a játék). Csalások:
##   - teleport a 20. emeletre (a kazamatában és a táborból is; pihenő közben nem)
##   - halhatatlanság be/ki (GameState.god_mode: a játékos nem sebződik)
##   - karakterváltás (csak a táborban, a még zárolt karakterekre is; nem számít csalt futásnak)
##   - tárgyak a táskába (külön lapon: fajta és ritkaság szerint szűrve; nem számít csalt futásnak)
## Halhatatlanság alatt felül középen egy kis felirat jelzi, hogy be van kapcsolva.

const TELEPORT_DEPTH := 20
const CHARACTER_BUTTON_SIZE := Vector2(225, 48)
const ITEM_BUTTON_SIZE := Vector2(212, 44)
const ITEM_COLUMNS := 4
const FILTER_BUTTON_SIZE := Vector2(80, 36)
## A tárgylap szűrői: "" = mind.
const SLOT_FILTERS: Array[String] = ["", "weapon", "helmet", "chest", "pants", "boots", "gloves", "ring", "amulet", "trinket"]
## "" = a tárgy saját ritkasága; a többinél annak a változata (lásd Items.variant).
const RARITY_FILTERS: Array[String] = ["", "common", "rare", "epic", "legendary"]

var _layer: CanvasLayer
var _menu_box: VBoxContainer
var _items_box: VBoxContainer
var _item_grid: GridContainer
var _god_button: Button
var _character_buttons := {}
var _slot_buttons := {}
var _rarity_buttons := {}
var _slot_filter := ""
var _rarity_filter := ""
var _status: Label
var _badge: CanvasLayer
var _badge_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_build_badge()


func open() -> void:
	_status.text = ""
	_show_items_page(false)
	_update_god_button()
	_update_character_buttons()
	_layer.visible = true


func close() -> void:
	_layer.visible = false


## Esc a tárgylapon: vissza a csalásokhoz (a Menus ilyenkor nem zárja be).
func handle_escape() -> bool:
	if _items_box.visible:
		_show_items_page(false)
		return true
	return false


func _process(_delta: float) -> void:
	# A felirat: halhatatlanság, és/vagy hogy a futás csalás miatt nem mentődik.
	_badge.visible = GameState.god_mode or GameState.cheated
	var parts: Array[String] = []
	if GameState.god_mode:
		parts.append("HALHATATLAN")
	if GameState.cheated:
		parts.append("csalt futás: nem mentődik")
	_badge_label.text = "  ·  ".join(parts)


func _menus() -> Node:
	return get_tree().current_scene.get_node("Menus")


func _build() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 30
	_layer.visible = false
	add_child(_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(center)
	var window := PanelContainer.new()
	window.add_theme_stylebox_override("panel", MenuStyle.box(MenuStyle.MENU_PANEL, 18, 30))
	window.custom_minimum_size = Vector2(460, 0)
	center.add_child(window)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	window.add_child(root)
	root.add_child(MenuStyle.title_label("Csalások", 48, MenuStyle.GOLD))

	# A csalások.
	_menu_box = VBoxContainer.new()
	_menu_box.add_theme_constant_override("separation", 10)
	root.add_child(_menu_box)
	var teleport := MenuStyle.button("Teleport a %d. emeletre" % TELEPORT_DEPTH)
	teleport.pressed.connect(_teleport)
	_menu_box.add_child(teleport)
	_god_button = MenuStyle.button("")
	_god_button.pressed.connect(_toggle_god_mode)
	_menu_box.add_child(_god_button)
	var items := MenuStyle.button("Tárgyak a táskába")
	items.pressed.connect(_show_items_page.bind(true))
	_menu_box.add_child(items)
	_menu_box.add_child(_text("Karakter (csak a táborban):", 18, MenuStyle.PARCHMENT))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	_menu_box.add_child(grid)
	for id: String in Characters.ALL:
		var character_button := _small_button("", CHARACTER_BUTTON_SIZE, 20)
		character_button.pressed.connect(_select_character.bind(id))
		grid.add_child(character_button)
		_character_buttons[id] = character_button
	var back := MenuStyle.button("Bezárás")
	back.pressed.connect(func() -> void: _menus().call("close_current"))
	_menu_box.add_child(back)

	_build_items_page(root)

	_status = _text("", 17, Color(1, 0.6, 0.45))
	root.add_child(_status)
	root.add_child(_text("[0] / [Esc] bezárás", 14, Color(0.75, 0.68, 0.6)))


## A tárgylap: felül a fajta- és ritkaság-szűrők, alatta görgethető rács; kattintásra a táskába.
func _build_items_page(root: VBoxContainer) -> void:
	_items_box = VBoxContainer.new()
	_items_box.add_theme_constant_override("separation", 8)
	_items_box.visible = false
	root.add_child(_items_box)
	var slots := HFlowContainer.new()
	slots.alignment = FlowContainer.ALIGNMENT_CENTER
	slots.add_theme_constant_override("h_separation", 5)
	_items_box.add_child(slots)
	for slot: String in SLOT_FILTERS:
		var slot_button := _small_button("Mind" if slot.is_empty() else String(Inventory.SLOT_NAMES[slot]),
			FILTER_BUTTON_SIZE, 15)
		slot_button.pressed.connect(func() -> void:
			_slot_filter = slot
			_fill_items())
		slots.add_child(slot_button)
		_slot_buttons[slot] = slot_button
	var rarities := HBoxContainer.new()
	rarities.alignment = BoxContainer.ALIGNMENT_CENTER
	rarities.add_theme_constant_override("separation", 6)
	_items_box.add_child(rarities)
	for rarity: String in RARITY_FILTERS:
		var rarity_button := _small_button("Saját ritkaság" if rarity.is_empty() else String(Items.RARITIES[rarity]["name"]),
			Vector2(150 if rarity.is_empty() else 110, 36), 15)
		if not rarity.is_empty():
			rarity_button.add_theme_color_override("font_color", Items.RARITIES[rarity]["color"])
		rarity_button.pressed.connect(func() -> void:
			_rarity_filter = rarity
			_fill_items())
		rarities.add_child(rarity_button)
		_rarity_buttons[rarity] = rarity_button
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(ITEM_COLUMNS * (ITEM_BUTTON_SIZE.x + 8) + 16, 290)
	_items_box.add_child(scroll)
	_item_grid = GridContainer.new()
	_item_grid.columns = ITEM_COLUMNS
	_item_grid.add_theme_constant_override("h_separation", 8)
	_item_grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(_item_grid)
	var back := MenuStyle.button("Vissza")
	back.pressed.connect(_show_items_page.bind(false))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_items_box.add_child(back)


func _show_items_page(show: bool) -> void:
	_menu_box.visible = not show
	_items_box.visible = show
	_status.text = ""
	if show:
		_fill_items()


## A rács újratöltése a szűrők szerint (fajta, majd ritkaság szerint rendezve).
func _fill_items() -> void:
	for child: Node in _item_grid.get_children():
		child.queue_free()
	for slot: String in _slot_buttons:
		_mark(_slot_buttons[slot], slot == _slot_filter)
	for rarity: String in _rarity_buttons:
		_mark(_rarity_buttons[rarity], rarity == _rarity_filter)
	var ids: Array = Items.DEFINITIONS.keys().filter(func(id: String) -> bool:
		return _slot_filter.is_empty() or Items.DEFINITIONS[id]["slot"] == _slot_filter)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var slot_a := Inventory.EQUIPMENT_SLOTS.find(Items.DEFINITIONS[a]["slot"])
		var slot_b := Inventory.EQUIPMENT_SLOTS.find(Items.DEFINITIONS[b]["slot"])
		if slot_a != slot_b:
			return slot_a < slot_b
		return Items.RARITY_ORDER.find(Items.DEFINITIONS[a]["rarity"]) < Items.RARITY_ORDER.find(Items.DEFINITIONS[b]["rarity"]))
	for id: String in ids:
		var definition := Items.variant(id, _rarity_filter)
		var item_button := _small_button(definition["name"], ITEM_BUTTON_SIZE, 15)
		item_button.icon = Items.icon(Items.create(id))
		item_button.expand_icon = false
		item_button.add_theme_constant_override("icon_max_width", 30)
		item_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		item_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		item_button.clip_text = true
		item_button.add_theme_color_override("font_color", Items.RARITIES[definition["rarity"]]["color"])
		item_button.tooltip_text = "%s (%s, %s)" % [definition["name"], Items.RARITIES[definition["rarity"]]["name"],
			Inventory.SLOT_NAMES[definition["slot"]]]
		item_button.pressed.connect(_give_item.bind(id))
		_item_grid.add_child(item_button)


## Új példány a választott ritkaságban, egyenesen a játékos táskájába.
func _give_item(id: String) -> void:
	var player := get_tree().current_scene.get_node_or_null("Entities/Player")
	var inventory: Inventory = player.get_node_or_null("Inventory") if player != null else null
	if inventory == null:
		Audio.play("ui_error")
		_status.text = "Itt most nem lehet tárgyat kapni."
		return
	var item := Items.create(id, _rarity_filter)
	if not inventory.add_item(item):
		Audio.play("ui_error")
		_status.text = "Tele a táska."
		return
	Audio.play("equip")
	_status.text = "A táskába került: %s (%s)" % [item["name"], Items.rarity_name(item)]


## A kiválasztott szűrőgomb arany betűs.
func _mark(button: Button, selected: bool) -> void:
	if selected:
		button.add_theme_color_override("font_outline_color", MenuStyle.GOLD)
		button.add_theme_constant_override("outline_size", 2)
	else:
		button.add_theme_color_override("font_outline_color", MenuStyle.SHADOW)
		button.add_theme_constant_override("outline_size", 6)


func _small_button(text: String, size: Vector2, font_size: int) -> Button:
	var result := MenuStyle.button(text)
	result.custom_minimum_size = size
	result.add_theme_font_size_override("font_size", font_size)
	return result


func _text(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


## Halhatatlanság jelzése felül középen (a menü bezárása után is látszik).
func _build_badge() -> void:
	_badge = CanvasLayer.new()
	_badge.layer = 6
	_badge.visible = false
	add_child(_badge)
	var label := _text("", 16, Color(1, 0.85, 0.35))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	label.offset_left = -320
	label.offset_right = 320
	_badge_label = label
	label.offset_top = -150
	label.offset_bottom = -128
	_badge.add_child(label)


func _teleport() -> void:
	var scene := get_tree().current_scene
	if not scene.has_method("cheat_teleport") or not scene.call("cheat_teleport", TELEPORT_DEPTH):
		Audio.play("ui_error")
		_status.text = "Itt most nem lehet teleportálni."
		return
	GameState.cheated = true
	_menus().call("close_current")


func _toggle_god_mode() -> void:
	GameState.god_mode = not GameState.god_mode
	# Akár egyszer is bekapcsolva: a futás már nem számít (kikapcsolva sem).
	if GameState.god_mode:
		GameState.cheated = true
	Audio.play("ui_click")
	_update_god_button()


func _update_god_button() -> void:
	_god_button.text = "Halhatatlanság: %s" % ("BE" if GameState.god_mode else "KI")


func _select_character(id: String) -> void:
	var scene := get_tree().current_scene
	if not scene.has_method("cheat_select_character") or not scene.call("cheat_select_character", id):
		Audio.play("ui_error")
		_status.text = "Karaktert csak a táborban lehet váltani (pihenő közben ott sem)."
		return
	_status.text = ""
	_update_character_buttons()


## Az aktív karakter gombja jelölve; a már amúgy is játszhatók mellett nincs megjegyzés.
func _update_character_buttons() -> void:
	for id: String in _character_buttons:
		var character_button: Button = _character_buttons[id]
		var label: String = Characters.data(id)["name"]
		if id == Progress.character:
			label = "» %s «" % label
		elif not Characters.is_unlocked(id):
			label += " (zárolt)"
		character_button.text = label
