extends CanvasLayer
## A Vérfarkas (a 20. emelet nagy főellensége) legyőzése után, a portálnál: vége a
## kazamatának. A pénzed 100%-a a táborba kerül, és legfeljebb 2 választott tárgyat
## felvihetsz (a tábori ládába); a többi felszerelésed elvész, mint egy futás végén.
## A következő leszállás újra az 1. emeletről indul. "Még maradok": körülnézhetsz.

const CAMP := "res://world/camp.tscn"
const MAX_ITEMS := 2

var _grid: ItemGrid
var _items: Array = []
var _chosen: Array[int] = []
var _gold_label: Label
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
	for slot in Inventory.EQUIPMENT_SLOTS:
		if inventory.equipment[slot] != null:
			_items.append(inventory.equipment[slot])
	for item in inventory.bag:
		if item != null:
			_items.append(item)
	_grid.set_items(_items, 16)
	_chosen.clear()
	_gold_label.text = "A teljes pénzed a táborba kerül: %d arany (100%%)" % (int(player.get("gold")) + GameState.break_gold_left)
	if GameState.cheated:
		_gold_label.text = "Csalt futás: sem a pénz, sem a tárgyak nem kerülnek a táborba."
	_update_choice()
	_show_item(null)
	visible = true


func close() -> void:
	visible = false


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.7)
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
	root.add_child(UiStyle.title_bar("A Mélység Ura elesett — győzelem!"))
	root.add_child(UiStyle.label("Legyőzted a Vérfarkast, és ezzel végigértél a kazamatán. A pénzed 100%-át megtartod,\n"
		+ "és 2 tárgyat felvihetsz a tábori ládába; a többi felszerelésed itt marad. A következő út az 1. emeletről indul.",
		15, UiStyle.INK_LIGHT))

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 20)
	root.add_child(columns)
	var left := VBoxContainer.new()
	columns.add_child(left)
	left.add_child(UiStyle.label("Melyik 2 tárgyat viszed magaddal? (kattints; újra kattintva visszavonod)", 17, UiStyle.INK))
	_grid = ItemGrid.new()
	_grid.columns = 8
	_grid.item_clicked.connect(_on_item_clicked)
	_grid.item_hovered.connect(func(index: int) -> void: _show_item(_grid.item_at(index)))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(8 * (ItemGrid.SLOT_SIZE.x + 4) + 12, 3 * (ItemGrid.SLOT_SIZE.y + 4))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_child(_grid)
	left.add_child(scroll)
	_choice_label = UiStyle.label("", 16, UiStyle.INK)
	_choice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_choice_label.custom_minimum_size.x = 8 * (ItemGrid.SLOT_SIZE.x + 4)
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

	_gold_label = UiStyle.label("", 18, Color(0.6, 0.38, 0.05))
	root.add_child(_gold_label)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 20)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(buttons)
	var go_out := MenuStyle.button("Vissza a táborba")
	go_out.custom_minimum_size.x = 380
	go_out.pressed.connect(_go_to_camp)
	buttons.add_child(go_out)
	var stay := MenuStyle.button("Még maradok")
	stay.pressed.connect(func() -> void: get_tree().current_scene.get_node("Menus").call("close_current"))
	buttons.add_child(stay)


func _on_item_clicked(index: int) -> void:
	if index >= _items.size():
		return
	if _chosen.has(index):
		_chosen.erase(index)
	elif _chosen.size() < MAX_ITEMS:
		_chosen.append(index)
	else:
		Audio.play("ui_error")
	_grid.select_many(_chosen)
	_update_choice()
	_show_item(_items[index])


func _update_choice() -> void:
	var names: Array[String] = []
	for index in _chosen:
		names.append(_items[index]["name"])
	_choice_label.text = "Felviszed (%d / %d): %s" % [_chosen.size(), MAX_ITEMS,
		", ".join(names) if not names.is_empty() else "még semmi"]


func _show_item(item: Variant) -> void:
	if item == null:
		_info_title.text = "—"
		_info_text.text = "Vidd az egeret egy tárgy fölé a leírásáért."
		return
	_info_title.text = item["name"]
	_info_title.add_theme_color_override("font_color", Items.rarity_ink(item))
	_info_text.text = Items.describe_bbcode(item)


## A futás vége: 2 tárgy a ládába, a pénz 100%-a a táborba, eredmény mentése, új futás.
func _go_to_camp() -> void:
	var player := get_tree().get_first_node_in_group("player")
	# Csalt futásból semmi nem kerül a táborba (a Records és a rescue_gold is figyeli).
	if not GameState.cheated:
		for index in _chosen:
			Progress.add_to_stash(_items[index])
	Records.submit_run(player)
	Progress.rescue_gold(int(player.get("gold")) + GameState.break_gold_left, 1.0)
	GameState.reset()
	GameState.dungeon_won = true
	Audio.play("level_up")
	get_tree().paused = false
	get_tree().change_scene_to_file(CAMP)
