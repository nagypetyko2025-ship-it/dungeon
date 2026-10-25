extends CanvasLayer
## A főellenség legyőzése után: kimehetsz pihenni a táborba. Egy általad választott
## tárgyat a tábori ládába küldhetsz (végleg megmarad), a többi felszerelésed, a
## szinted és a statjaid megmaradnak: a táborban a kék portálon át ugyanide, a
## főellenség termébe térsz vissza. A pénzed kiviheted (a táborban a vándorárusnál elköltheted,
## a maradékot visszaviszed), vagy bent hagyhatod (visszatéréskor visszakapod).
## "Maradok": tovább lehet menni a lépcsőn.

const CAMP := "res://world/camp.tscn"
const FALLBACK_WEAPON := "sword_rusty"

var _grid: ItemGrid
var _items: Array = []
## Minden tárgyhoz: ["equip", hely] vagy ["bag", index].
var _sources: Array = []
var _selected := -1
var _take_gold: CheckBox
var _info_title: Label
var _info_text: RichTextLabel
var _choice_label: Label


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func open() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var inventory: Inventory = player.get_node("Inventory")
	_items = []
	_sources = []
	for slot in Inventory.EQUIPMENT_SLOTS:
		if inventory.equipment[slot] != null:
			_items.append(inventory.equipment[slot])
			_sources.append(["equip", slot])
	for i in inventory.bag.size():
		if inventory.bag[i] != null:
			_items.append(inventory.bag[i])
			_sources.append(["bag", i])
	_grid.set_items(_items, 12)
	_selected = -1
	_take_gold.text = "Kiviszem a pénzem (%d arany) — a táborban a vándorárusnál elköltheted" % int(player.get("gold"))
	_take_gold.button_pressed = true
	_choice_label.text = "A ládába küldött tárgy: nincs kiválasztva"
	_show_item(null)
	visible = true


func close() -> void:
	visible = false


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.65)
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
	root.add_child(UiStyle.title_bar("Győzelem! Kimész pihenni?"))
	root.add_child(UiStyle.label("Pihenj a táborban: egy választott tárgy a tábori ládába kerül, a többi felszerelésed, a szinted és a statjaid megmaradnak.\n"
		+ "A kék portálon át ide, a főellenség termébe térsz vissza. Pihenő közben Zoltán, a vándorárus árul.", 15, UiStyle.INK_LIGHT))

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 20)
	root.add_child(columns)
	var left := VBoxContainer.new()
	columns.add_child(left)
	left.add_child(UiStyle.label("Melyik tárgy kerüljön a tábori ládába? (nem kötelező)", 17, UiStyle.INK))
	_grid = ItemGrid.new()
	_grid.columns = 8
	_grid.item_clicked.connect(func(index: int) -> void:
		# Újra rákattintva visszavonja a választást.
		_selected = -1 if _selected == index else index
		_grid.select(_selected)
		_choice_label.text = "A ládába küldött tárgy: %s" % (_items[_selected]["name"] if _selected >= 0 else "nincs kiválasztva")
		_show_item(_items[index]))
	_grid.item_hovered.connect(func(index: int) -> void: _show_item(_grid.item_at(index)))
	# Sok tárgynál görgethető, hogy az ablak ne lógjon ki a képernyőről.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(8 * (ItemGrid.SLOT_SIZE.x + 4) + 12, 3 * (ItemGrid.SLOT_SIZE.y + 4))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_child(_grid)
	left.add_child(scroll)
	_choice_label = UiStyle.label("", 16, UiStyle.INK)
	left.add_child(_choice_label)

	var info := PanelContainer.new()
	info.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	info.custom_minimum_size = Vector2(340, 300)
	columns.add_child(info)
	var info_box := VBoxContainer.new()
	info.add_child(info_box)
	_info_title = UiStyle.label("", 19, UiStyle.INK)
	_info_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_title.custom_minimum_size.x = 260
	info_box.add_child(_info_title)
	_info_text = RichTextLabel.new()
	_info_text.bbcode_enabled = true
	_info_text.scroll_active = true
	_info_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_info_text.add_theme_color_override("default_color", UiStyle.INK_LIGHT)
	_info_text.add_theme_font_size_override("normal_font_size", 15)
	info_box.add_child(_info_text)

	_take_gold = CheckBox.new()
	_take_gold.add_theme_font_size_override("font_size", 17)
	_take_gold.add_theme_color_override("font_color", UiStyle.INK)
	_take_gold.add_theme_color_override("font_hover_color", UiStyle.INK)
	_take_gold.add_theme_color_override("font_pressed_color", UiStyle.INK)
	_take_gold.add_theme_color_override("font_hover_pressed_color", UiStyle.INK)
	root.add_child(_take_gold)
	root.add_child(UiStyle.label("Ha bent hagyod, a táborban nem költheted el, de visszatéréskor újra nálad lesz.", 14, UiStyle.INK_LIGHT))

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 20)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(buttons)
	var go_out := MenuStyle.button("Kimegyek a táborba")
	go_out.custom_minimum_size.x = 380
	go_out.pressed.connect(_go_to_camp)
	buttons.add_child(go_out)
	var stay := MenuStyle.button("Maradok")
	stay.pressed.connect(func() -> void: get_tree().current_scene.get_node("Menus").call("close_current"))
	buttons.add_child(stay)


func _show_item(item: Variant) -> void:
	if item == null:
		_info_title.text = "—"
		_info_text.text = "Vidd az egeret egy tárgy fölé a leírásáért."
		return
	_info_title.text = item["name"]
	_info_title.add_theme_color_override("font_color", Items.rarity_ink(item))
	_info_text.text = Items.describe_bbcode(item)


func _go_to_camp() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var inventory: Inventory = player.get_node("Inventory")
	# Csalt futásból nem kerül tárgy a tábori ládába.
	if _selected >= 0 and not GameState.cheated:
		var source: Array = _sources[_selected]
		Progress.add_to_stash(_items[_selected])
		if source[0] == "bag":
			inventory.take_from_bag(source[1])
		else:
			inventory.equipment[source[1]] = null
			# Fegyver nélkül nem lehet harcolni: a rozsdás kard kerül a helyére.
			if source[1] == "weapon":
				inventory.equipment["weapon"] = Items.create(FALLBACK_WEAPON)
			inventory.changed.emit()
	player.call("save_state")
	# Az emelet és a terem, ahova a kék portál visszahoz (lásd Dungeon.break_snapshot).
	var scene := get_tree().current_scene
	GameState.break_floor = scene.call("break_snapshot") if scene.has_method("break_snapshot") else {}
	if not _take_gold.button_pressed:
		GameState.break_gold_left = GameState.saved_gold
		GameState.saved_gold = 0
	GameState.on_break = true
	GameState.exits += 1
	GameState.merchant_stock = []
	Audio.play("level_up")
	GamePause.set_paused(get_tree(), false)
	get_tree().change_scene_to_file(CAMP)
