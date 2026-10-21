extends CanvasLayer
## A tárgylift ablaka (a kazamatában, a bolt melletti falban, E-vel): liftenként
## (emeletenként) EGY tárgyat lehet felküldeni a táskádból a táborba. A tárgy a
## futásban elveszik, de a tábori ládában megmarad (mentve). Aranyat nem lehet felküldeni.

var _grid: ItemGrid
var _info_title: Label
var _info_text: RichTextLabel
var _status: Label
var _send_button: Button
var _selected := -1


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func open() -> void:
	_selected = -1
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
	var player := get_tree().get_first_node_in_group("player")
	return player.get_node("Inventory") if player else null


func _used() -> bool:
	return GameState.lift_used_floor == GameState.depth


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
	root.add_child(UiStyle.title_bar("Tárgylift"))
	root.add_child(UiStyle.label("Nyikorgó teherfelvonó, ami egészen a táborig ér fel. Liftenként egy tárgyat bír el:\n"
		+ "a futásban elveszik, de a tábori ládában rád vár. (Aranyat nem lehet felküldeni.)", 15, UiStyle.INK_LIGHT))

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 20)
	root.add_child(columns)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	columns.add_child(left)
	left.add_child(UiStyle.label("Táska — válassz egy tárgyat", 18, UiStyle.INK))
	_grid = ItemGrid.new()
	_grid.columns = 6
	_grid.item_clicked.connect(_on_item_clicked)
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
	_status = UiStyle.label("", 16, UiStyle.INK)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(_status)
	_send_button = MenuStyle.button("Felküldés")
	_send_button.custom_minimum_size = Vector2(220, 52)
	_send_button.add_theme_font_size_override("font_size", 20)
	_send_button.pressed.connect(_send)
	bottom.add_child(_send_button)
	var hint := UiStyle.label("[E] / [Esc] bezárás", 14, UiStyle.INK_LIGHT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(hint)


func _refresh() -> void:
	var inventory := _inventory()
	_grid.set_items(inventory.bag if inventory else [], Inventory.BAG_SIZE)
	if _selected >= 0:
		_grid.select(_selected)
	if _used():
		_status.text = "Ezen az emeleten már felküldtél egy tárgyat."
	elif _selected < 0:
		_status.text = "Kattints egy tárgyra a táskádban."
	else:
		_status.text = "Felküldésre kész: %s" % _grid.item_at(_selected)["name"]
	_send_button.disabled = _used() or _selected < 0


func _on_item_clicked(index: int) -> void:
	_selected = index
	_show_item(_grid.item_at(index))
	_refresh()


func _show_item(item: Variant) -> void:
	if item == null:
		_info_title.text = "Nincs kiválasztva"
		_info_text.text = "Vidd az egeret egy tárgy fölé a leírásáért."
		return
	_info_title.text = item["name"]
	_info_title.add_theme_color_override("font_color", Items.rarity_ink(item))
	_info_text.text = Items.describe_bbcode(item)


func _send() -> void:
	var inventory := _inventory()
	if inventory == null or _used() or _selected < 0 or inventory.bag[_selected] == null:
		Audio.play("ui_error")
		return
	if GameState.tutorial:
		Audio.play("ui_error")
		_status.text = "Gyakorláskor a lift nem küld fel semmit — az igazi játékban így működik."
		return
	if GameState.cheated:
		Audio.play("ui_error")
		_status.text = "Csalt futásból a lift nem küld fel semmit."
		return
	var item: Dictionary = inventory.take_from_bag(_selected)
	Progress.add_to_stash(item)
	GameState.lift_used_floor = GameState.depth
	Audio.play("door_lock", -2.0)
	Audio.play("item_pickup")
	_selected = -1
	_refresh()
	_status.text = "Felküldve: %s — a tábori ládában vár." % item["name"]
