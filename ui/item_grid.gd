class_name ItemGrid
extends GridContainer
## Egyszerű tárgyrács (ritkaság-színes helyek, ikonok): kattintásra `item_clicked`,
## egér fölötte: `item_hovered`. A kijelölt hely kiemelve látszik.
## A tárgylift, a tábori láda és a főellenség utáni visszatérés használja.

signal item_clicked(index: int)
signal item_hovered(index: int)

const SLOT_SIZE := Vector2(60, 60)
const SELECTED_GLOW := Color(1.5, 1.25, 0.55)

var _items: Array = []
var _slots: Array[Panel] = []
var selected := -1


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
	for i in maxi(items.size(), min_slots):
		var item: Variant = items[i] if i < items.size() else null
		var slot := Panel.new()
		slot.custom_minimum_size = SLOT_SIZE
		slot.add_theme_stylebox_override("panel", UiStyle.slot())
		if item != null:
			var fill := ColorRect.new()
			fill.color = Color(Items.rarity_color(item), 0.3)
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
			slot.add_theme_stylebox_override("panel", UiStyle.slot(i == selected)))
		add_child(slot)
		_slots.append(slot)


func item_at(index: int) -> Variant:
	return _items[index] if index >= 0 and index < _items.size() else null


func select(index: int) -> void:
	selected = index
	for i in _slots.size():
		_slots[i].modulate = SELECTED_GLOW if i == index else Color.WHITE
		_slots[i].add_theme_stylebox_override("panel", UiStyle.slot(i == index))


func _on_slot_input(event: InputEvent, index: int) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT and item_at(index) != null:
		Audio.play("ui_click")
		item_clicked.emit(index)
