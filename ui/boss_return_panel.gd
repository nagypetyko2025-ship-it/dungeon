extends CanvasLayer
## A főellenség legyőzése után felajánlott visszatérés a táborba: a pénzed RATIO része
## és egy általad választott tárgy (a felszerelésedből vagy a táskádból) a táborba
## kerül (a tábori ládába), a többi elveszik. "Maradok": tovább lehet menni a mélybe.

const RATIO := 0.7
const CAMP := "res://world/camp.tscn"

var _grid: ItemGrid
var _items: Array = []
var _selected := -1
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
	# Minden tárgy: előbb a felszerelés, aztán a táska.
	_items = []
	for slot in Inventory.EQUIPMENT_SLOTS:
		if inventory.equipment[slot] != null:
			_items.append(inventory.equipment[slot])
	for item in inventory.bag:
		if item != null:
			_items.append(item)
	_grid.set_items(_items, 12)
	_selected = -1
	var gold: int = player.get("gold")
	_gold_label.text = "Megmentett arany: %d (a %d arany %d%%-a)" % [floori(gold * RATIO), gold, roundi(RATIO * 100)]
	_choice_label.text = "Kiválasztott tárgy: nincs"
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
	root.add_theme_constant_override("separation", 12)
	window.add_child(root)
	root.add_child(UiStyle.title_bar("Győzelem! Vissza a táborba?"))
	root.add_child(UiStyle.label("Ha most visszatérsz, a pénzed %d%%-át és EGY általad választott tárgyat megtartasz\n"
		% roundi(RATIO * 100) + "(a tábori ládába kerül) — a többi elveszik. Maradhatsz is, és mehetsz tovább a mélybe.",
		15, UiStyle.INK_LIGHT))
	_gold_label = UiStyle.label("", 18, Color(0.6, 0.38, 0.05))
	root.add_child(_gold_label)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 20)
	root.add_child(columns)
	var left := VBoxContainer.new()
	columns.add_child(left)
	left.add_child(UiStyle.label("Válaszd ki, melyik tárgyat viszed haza", 17, UiStyle.INK))
	_grid = ItemGrid.new()
	_grid.columns = 6
	_grid.item_clicked.connect(func(index: int) -> void:
		_selected = index
		_grid.select(index)
		_choice_label.text = "Kiválasztott tárgy: %s" % _items[index]["name"]
		_show_item(_items[index]))
	_grid.item_hovered.connect(func(index: int) -> void: _show_item(_grid.item_at(index)))
	left.add_child(_grid)
	_choice_label = UiStyle.label("", 16, UiStyle.INK)
	left.add_child(_choice_label)

	var info := PanelContainer.new()
	info.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	info.custom_minimum_size = Vector2(300, 260)
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

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 20)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(buttons)
	var go_home := MenuStyle.button("Vissza a táborba")
	go_home.pressed.connect(_return_to_camp)
	buttons.add_child(go_home)
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


func _return_to_camp() -> void:
	var player := get_tree().get_first_node_in_group("player")
	Progress.rescue_gold(int(player.get("gold")), RATIO)
	if _selected >= 0:
		Progress.add_to_stash(_items[_selected])
	Records.submit_run(player)
	Audio.play("level_up")
	GameState.reset()
	get_tree().paused = false
	get_tree().change_scene_to_file(CAMP)
