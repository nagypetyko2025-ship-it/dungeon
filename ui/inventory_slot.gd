class_name InventorySlot
extends Panel
## Egy hely az inventory ablakban, fogd-és-vidd támogatással.
## kind = "bag" (key = táska-index) vagy "equip" (key = felszerelés-hely neve).
## Jobb klikk: gyors felvétel / levétel.

const SIZE := Vector2(64, 64)
const RARITY_FILL_ALPHA := 0.3
const DRAG_PREVIEW_SIZE := Vector2(56, 56)
const EMPTY_SLOT_TINT := Color(0.35, 0.26, 0.16, 0.4)

var kind := "bag"
var key: Variant = 0
var item: Variant = null
var inventory: Inventory
## Hívódik, ha az egér fölé ér (a leíráshoz): func(item, slot)
var on_hover: Callable
## Ha be van állítva, jobb klikkre ez fut a gyors fel/levétel helyett (pl. eladás): func(slot)
var on_right_click: Callable


func setup(slot_kind: String, slot_key: Variant, slot_item: Variant, owner_inventory: Inventory) -> void:
	kind = slot_kind
	key = slot_key
	item = slot_item
	inventory = owner_inventory
	custom_minimum_size = SIZE
	add_theme_stylebox_override("panel", UiStyle.slot())
	if item != null and item.has("rarity"):
		var fill := ColorRect.new()
		fill.color = Items.rarity_fill(item, RARITY_FILL_ALPHA)
		fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fill)
	var icon := TextureRect.new()
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if item != null:
		icon.texture = Items.icon(item)
	elif kind == "equip":
		# Üres felszerelés-hely: halványan látszik, milyen tárgy kerül ide.
		icon.texture = Items.slot_icon(key)
		icon.modulate = EMPTY_SLOT_TINT
	add_child(icon)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_set_highlight.bind(false))


func _on_mouse_entered() -> void:
	_set_highlight(true)
	if on_hover.is_valid():
		on_hover.call(item, self)


func _set_highlight(on: bool) -> void:
	add_theme_stylebox_override("panel", UiStyle.slot(on))


func _get_drag_data(_at_position: Vector2) -> Variant:
	if item == null:
		return null
	var preview := TextureRect.new()
	preview.texture = Items.icon(item)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.size = DRAG_PREVIEW_SIZE
	preview.position = -DRAG_PREVIEW_SIZE / 2.0
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var holder := Control.new()
	holder.add_child(preview)
	set_drag_preview(holder)
	return {"inventory_kind": kind, "inventory_key": key}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("inventory_kind")):
		return false
	var ok := inventory.can_move(data["inventory_kind"], data["inventory_key"], kind, key)
	_set_highlight(ok)
	return ok


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	Audio.play("equip")
	inventory.move(data["inventory_kind"], data["inventory_key"], kind, key)


## Jobb klikk: a táskából felveszi, a felszerelésből leveszi.
func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_RIGHT or item == null:
		return
	if on_right_click.is_valid():
		on_right_click.call(self)
	elif kind == "bag":
		inventory.equip_from_bag(key)
	else:
		inventory.unequip(key)
	accept_event()
