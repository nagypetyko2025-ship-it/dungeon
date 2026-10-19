extends CanvasLayer
## Zoltán, a vándorárus (a táborban, pihenő közben, E-vel): olyan tárgyakat árul,
## mint a kazamata gyanús boltosa, csak MARKUP-pal drágábban. A futás pénzéből
## vásárolsz, a tárgy a táskádba kerül, és visszaviheted a kazamatába.

const STOCK_SIZE := 8
## Ennyivel drágább, mint a kazamata boltja (+14%).
const MARKUP := 1.14

var _grid: ItemGrid
var _info_title: Label
var _info_text: RichTextLabel
var _gold_label: Label
var _message: Label
var _buy_button: Button
var _selected := -1


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


## A kínálat pihenőnként egyszer dől el (a kimenetelkor ürül).
static func stock() -> Array:
	if GameState.merchant_stock.is_empty():
		var seen := {}
		while GameState.merchant_stock.size() < STOCK_SIZE:
			var item := Items.random_item()
			if seen.has(item["id"]) and seen.size() < Items.DEFINITIONS.size():
				continue
			seen[item["id"]] = true
			item["price"] = ceili(item["price"] * MARKUP)
			GameState.merchant_stock.append(item)
	return GameState.merchant_stock


func open() -> void:
	_selected = -1
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


func _player() -> Node:
	return get_tree().get_first_node_in_group("player")


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
	root.add_child(UiStyle.title_bar("Zoltán, a vándorárus"))
	root.add_child(UiStyle.label("„Ugyanazt árulom, mint az a gyanús alak odalent... csak én nem harapok.\n"
		+ "Persze a szállítás nem ingyen van: minden 14%-kal drágább.”", 15, UiStyle.INK_LIGHT))
	_gold_label = UiStyle.label("", 18, Color(0.6, 0.38, 0.05))
	root.add_child(_gold_label)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 20)
	root.add_child(columns)
	var left := VBoxContainer.new()
	columns.add_child(left)
	left.add_child(UiStyle.label("Kínálat — kattints egy tárgyra", 18, UiStyle.INK))
	_grid = ItemGrid.new()
	_grid.columns = 4
	_grid.item_clicked.connect(func(index: int) -> void:
		_selected = index
		_grid.select(index)
		_show_item(_grid.item_at(index))
		_update_buy_button())
	_grid.item_hovered.connect(func(index: int) -> void: _show_item(_grid.item_at(index)))
	left.add_child(_grid)

	var info := PanelContainer.new()
	info.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	info.custom_minimum_size = Vector2(320, 300)
	columns.add_child(info)
	var info_box := VBoxContainer.new()
	info.add_child(info_box)
	_info_title = UiStyle.label("", 19, UiStyle.INK)
	_info_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_title.custom_minimum_size.x = 280
	info_box.add_child(_info_title)
	_info_text = RichTextLabel.new()
	_info_text.bbcode_enabled = true
	_info_text.scroll_active = false
	_info_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_info_text.add_theme_color_override("default_color", UiStyle.INK_LIGHT)
	_info_text.add_theme_font_size_override("normal_font_size", 15)
	info_box.add_child(_info_text)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 16)
	root.add_child(bottom)
	_message = UiStyle.label("", 16, UiStyle.INK)
	_message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(_message)
	_buy_button = MenuStyle.button("Megveszem")
	_buy_button.custom_minimum_size = Vector2(260, 52)
	_buy_button.add_theme_font_size_override("font_size", 20)
	_buy_button.pressed.connect(_buy)
	bottom.add_child(_buy_button)
	var hint := UiStyle.label("[E] / [Esc] bezárás", 14, UiStyle.INK_LIGHT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(hint)


func _refresh() -> void:
	_grid.set_items(stock(), STOCK_SIZE)
	if _selected >= 0:
		_grid.select(_selected)
	_gold_label.text = "Nálad: %d arany" % int(_player().get("gold"))
	_update_buy_button()


func _update_buy_button() -> void:
	var item: Variant = _grid.item_at(_selected)
	_buy_button.text = "Megveszem: %d arany" % item["price"] if item != null else "Megveszem"
	_buy_button.disabled = item == null or int(_player().get("gold")) < int(item["price"])


func _show_item(item: Variant) -> void:
	if item == null:
		_info_title.text = "—"
		_info_text.text = "Vidd az egeret egy tárgy fölé a leírásáért."
		return
	_info_title.text = "%s — %d arany" % [item["name"], item["price"]]
	_info_title.add_theme_color_override("font_color", Items.rarity_ink(item))
	_info_text.text = Items.describe_bbcode(item)
	var equipped: Variant = _player().get_node("Inventory").equipment.get(item["slot"])
	if equipped != null:
		_info_text.text += "\n\n" + Items.compare_bbcode(item, equipped)


func _buy() -> void:
	var item: Variant = _grid.item_at(_selected)
	var player := _player()
	var inventory: Inventory = player.get_node("Inventory")
	if item == null:
		return
	if inventory.is_bag_full():
		Audio.play("ui_error")
		_message.text = "Tele a táskád."
		return
	if not player.call("spend_gold", item["price"]):
		Audio.play("ui_error")
		_message.text = "Nincs elég aranyad."
		return
	GameState.merchant_stock.remove_at(_selected)
	inventory.add_item(item)
	Audio.play("buy")
	_message.text = "Megvetted: %s" % item["name"]
	_selected = -1
	_refresh()
	_show_item(null)
