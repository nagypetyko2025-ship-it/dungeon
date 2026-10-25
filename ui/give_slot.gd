class_name GiveSlot
extends PanelContainer
## Átadás mező az inventoryban (csak közös játékban): egy társ neve és figurája; ide húzva a táskából
## egy tárgyat, az átkerül hozzá (lásd InventoryScreen._give_from_bag, NetLobby.send_item).

## Hívódik, ha egy táskabeli tárgyat ide ejtenek: func(bag_index, peer_id)
var on_give: Callable
var peer_id := 0


func setup(id: int, player_name: String, character: String) -> void:
	peer_id = id
	custom_minimum_size = Vector2(118, 56)
	tooltip_text = "Húzz ide egy tárgyat a táskádból: %s megkapja." % player_name
	add_theme_stylebox_override("panel", UiStyle.slot())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	var frames := Characters.frames(character)
	if frames != null and frames.has_animation("idle") and frames.get_frame_count("idle") > 0:
		var figure := TextureRect.new()
		figure.texture = frames.get_frame_texture("idle", 0)
		figure.custom_minimum_size = Vector2(36, 44)
		figure.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		figure.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(figure)
	var label := UiStyle.label(player_name, 15, UiStyle.INK)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	mouse_exited.connect(_set_highlight.bind(false))


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var ok: bool = data is Dictionary and data.get("inventory_kind") == "bag"
	_set_highlight(ok)
	return ok


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_set_highlight(false)
	if on_give.is_valid():
		on_give.call(int(data["inventory_key"]), peer_id)


func _set_highlight(on: bool) -> void:
	add_theme_stylebox_override("panel", UiStyle.slot(on))
