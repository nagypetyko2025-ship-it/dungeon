class_name ItemGrid
extends GridContainer
## Egyszerű tárgyrács (ritkaság-színes helyek, ikonok): kattintásra `item_clicked`,
## egér fölötte: `item_hovered`. A kijelölt hely kiemelve látszik.
## A tárgylift, a tábori láda és a főellenség utáni visszatérés használja.

signal item_clicked(index: int)
signal item_hovered(index: int)

const SLOT_SIZE := Vector2(60, 60)
const SELECTED_GLOW := Color(1.5, 1.25, 0.55)

## Ha igaz, a tárgyak húzhatók (pl. a kukába): a húzott adat {"grid_index": i, "grid": rács}.
var draggable := false

var _items: Array = []
var _slots: Array[Panel] = []
var selected := -1
## Több kijelölt hely egyszerre (select_many), pl. a végső győzelem után 2 tárgy.
var selected_many: Array[int] = []


func _init() -> void:
	add_theme_constant_override("h_separation", 4)
	add_theme_constant_override("v_separation", 4)


## `items`: tárgyak (Dictionary) vagy null (üres hely); `min_slots`: legalább ennyi hely látszik.
func set_items(items: Array, min_slots := 0) -> void:
	_items = items
	for child in get_children():
		child.queue_free()
	_slots.clear()
	selected = -1
	selected_many.clear()
	for i in maxi(items.size(), min_slots):
		var item: Variant = items[i] if i < items.size() else null
		var slot := GridSlot.new()
		slot.grid = self
		slot.index = i
		slot.custom_minimum_size = SLOT_SIZE
		slot.add_theme_stylebox_override("panel", UiStyle.slot())
		if item != null:
			var fill := ColorRect.new()
			fill.color = Items.rarity_fill(item, 0.3)
			fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
			fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(fill)
			var icon := TextureRect.new()
			icon.texture = Items.icon(item)
			icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(icon)
			slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		slot.gui_input.connect(_on_slot_input.bind(i))
		slot.mouse_entered.connect(func() -> void:
			slot.add_theme_stylebox_override("panel", UiStyle.slot(true))
			item_hovered.emit(i))
		slot.mouse_exited.connect(func() -> void:
			slot.add_theme_stylebox_override("panel", UiStyle.slot(_is_selected(i))))
		add_child(slot)
		_slots.append(slot)


## Egy hely a rácsban (húzható, ha a rács az).
class GridSlot:
	extends Panel
	var grid: ItemGrid
	var index := 0

	func _get_drag_data(_at_position: Vector2) -> Variant:
		var item: Variant = grid.item_at(index)
		if not grid.draggable or item == null:
			return null
		var preview := TextureRect.new()
		preview.texture = Items.icon(item)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.size = Vector2(56, 56)
		preview.position = -Vector2(28, 28)
		preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var holder := Control.new()
		holder.add_child(preview)
		set_drag_preview(holder)
		return {"grid_index": index, "grid": grid}


func item_at(index: int) -> Variant:
	return _items[index] if index >= 0 and index < _items.size() else null


func select(index: int) -> void:
	selected = index
	selected_many.clear()
	for i in _slots.size():
		_slots[i].modulate = SELECTED_GLOW if i == index else Color.WHITE
		_slots[i].add_theme_stylebox_override("panel", UiStyle.slot(i == index))


## Több hely kijelölése egyszerre (a korábbi kijelölés helyett).
func select_many(indices: Array[int]) -> void:
	selected = -1
	selected_many = indices.duplicate()
	for i in _slots.size():
		_slots[i].modulate = SELECTED_GLOW if _is_selected(i) else Color.WHITE
		_slots[i].add_theme_stylebox_override("panel", UiStyle.slot(_is_selected(i)))


func _is_selected(index: int) -> bool:
	return index == selected or selected_many.has(index)


func _on_slot_input(event: InputEvent, index: int) -> void:
	# Elengedéskor számít kattintásnak (így a húzás, pl. a kukába, nem vált ki kattintást).
	var click := event as InputEventMouseButton
	if click and not click.pressed and click.button_index == MOUSE_BUTTON_LEFT and item_at(index) != null:
		Audio.play("ui_click")
		item_clicked.emit(index)
