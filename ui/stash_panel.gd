extends CanvasLayer
## Tábori láda (a táborban, E-vel): ide kerülnek a tárgylifttel és a főellenség
## után felküldött tárgyak. Kattintással lehet áttenni őket a táskádba (amit a
## táskádban / magadon viszel, azzal szállsz le), és vissza a ládába. Minden mentődik.

var _stash_grid: ItemGrid
var _bag_grid: ItemGrid
var _info_title: Label
var _info_text: RichTextLabel
var _message: Label


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func open() -> void:
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
	root.add_theme_constant_override("separation", 12)
	window.add_child(root)
	root.add_child(UiStyle.title_bar("Tábori láda"))
	root.add_child(UiStyle.label("A felküldött tárgyaid. Kattints egy tárgyra, hogy átkerüljön a táskádba (azzal szállsz le),\n"
		+ "vagy a táskádból vissza a ládába. Felvenni az [I] felszerelés-ablakban tudod.", 15, UiStyle.INK_LIGHT))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	root.add_child(columns)

	var stash_box := VBoxContainer.new()
	columns.add_child(stash_box)
	stash_box.add_child(UiStyle.label("Láda", 18, UiStyle.INK))
	_stash_grid = ItemGrid.new()
	_stash_grid.columns = 5
	_stash_grid.item_clicked.connect(_take_from_stash)
	_stash_grid.item_hovered.connect(func(i: int) -> void: _show_item(_stash_grid.item_at(i)))
	stash_box.add_child(_stash_grid)

	var bag_box := VBoxContainer.new()
	columns.add_child(bag_box)
	bag_box.add_child(UiStyle.label("Táska", 18, UiStyle.INK))
	_bag_grid = ItemGrid.new()
	_bag_grid.columns = 6
	_bag_grid.item_clicked.connect(_put_to_stash)
	_bag_grid.item_hovered.connect(func(i: int) -> void: _show_item(_bag_grid.item_at(i)))
	bag_box.add_child(_bag_grid)

	var info := PanelContainer.new()
	info.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	info.custom_minimum_size = Vector2(300, 300)
	columns.add_child(info)
	var info_box := VBoxContainer.new()
	info.add_child(info_box)
	_info_title = UiStyle.label("", 19, UiStyle.INK)
	_info_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_title.custom_minimum_size.x = 260
	info_box.add_child(_info_title)
	_info_text = RichTextLabel.new()
	_info_text.bbcode_enabled = true
	_info_text.scroll_active = false
	_info_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_info_text.add_theme_color_override("default_color", UiStyle.INK_LIGHT)
	_info_text.add_theme_font_size_override("normal_font_size", 15)
	info_box.add_child(_info_text)

	_message = UiStyle.label("", 15, Color(0.24, 0.5, 0.2))
	root.add_child(_message)
	var hint := UiStyle.label("[E] / [Esc] bezárás", 14, UiStyle.INK_LIGHT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(hint)


func _refresh() -> void:
	_stash_grid.set_items(Progress.stash, 20)
	_bag_grid.set_items(_inventory().bag, Inventory.BAG_SIZE)


func _take_from_stash(index: int) -> void:
	var inventory := _inventory()
	if inventory.is_bag_full():
		Audio.play("ui_error")
		_message.text = "Tele a táskád."
		return
	var item: Dictionary = Progress.stash[index]
	Progress.stash.remove_at(index)
	inventory.add_item(item)
	Progress.save_game()
	Audio.play("item_pickup")
	_message.text = "A táskádba került: %s" % item["name"]
	_refresh()


func _put_to_stash(index: int) -> void:
	var item: Variant = _inventory().take_from_bag(index)
	if item == null:
		return
	Progress.add_to_stash(item)
	Audio.play("equip")
	_message.text = "A ládába került: %s" % item["name"]
	_refresh()


func _show_item(item: Variant) -> void:
	if item == null:
		_info_title.text = "—"
		_info_text.text = "Vidd az egeret egy tárgy fölé a leírásáért."
		return
	_info_title.text = item["name"]
	_info_title.add_theme_color_override("font_color", Items.rarity_ink(item))
	_info_text.text = Items.describe_bbcode(item)
