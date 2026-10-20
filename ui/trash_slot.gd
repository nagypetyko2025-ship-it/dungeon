class_name TrashSlot
extends Panel
## Kuka: ide húzott tárgy törlődik (előtte rákérdez, lásd ConfirmBox). Az inventory
## táskájából (inventory_kind = "bag") és a tárgyrácsokból (ItemGrid: "grid_index") fogad.
## A törlést a tulajdonos végzi: on_drop(data).

const ICON: Texture2D = preload("res://assets/ui/trash.png")
const ICON_OPEN: Texture2D = preload("res://assets/ui/trash_open.png")

var on_drop: Callable
var _icon: TextureRect


func _ready() -> void:
	custom_minimum_size = Vector2(64, 64)
	tooltip_text = "Kuka: húzz ide egy tárgyat a törléshez"
	add_theme_stylebox_override("panel", UiStyle.slot())
	_icon = TextureRect.new()
	_icon.texture = ICON
	_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.modulate = Color(0.35, 0.22, 0.14)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	mouse_exited.connect(_set_highlight.bind(false))


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var ok: bool = data is Dictionary and (data.get("inventory_kind") == "bag" or data.has("grid_index"))
	_set_highlight(ok)
	return ok


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_set_highlight(false)
	if on_drop.is_valid():
		on_drop.call(data)


func _set_highlight(on: bool) -> void:
	add_theme_stylebox_override("panel", UiStyle.slot(on))
	_icon.texture = ICON_OPEN if on else ICON
	_icon.modulate = Color(0.75, 0.15, 0.1) if on else Color(0.35, 0.22, 0.14)
