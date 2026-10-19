class_name SellSlot
extends PanelContainer
## Eladás mező az inventoryban (csak a boltban, eladás módban látszik):
## ide húzva a táskából egy tárgyat, a boltos megveszi.

## Hívódik, ha egy táskabeli tárgyat ide ejtenek: func(bag_index)
var on_sell: Callable
var _label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(0, 56)
	add_theme_stylebox_override("panel", UiStyle.slot())
	_label = UiStyle.label("Húzd ide az eladáshoz  (vagy jobb klikk a tárgyon)", 15, UiStyle.INK)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_label)
	mouse_exited.connect(_set_highlight.bind(false))


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var ok: bool = data is Dictionary and data.get("inventory_kind") == "bag"
	_set_highlight(ok)
	return ok


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_set_highlight(false)
	if on_sell.is_valid():
		on_sell.call(data["inventory_key"])


func _set_highlight(on: bool) -> void:
	add_theme_stylebox_override("panel", UiStyle.slot(on))
