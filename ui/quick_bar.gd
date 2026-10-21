class_name QuickBar
extends CanvasLayer
## Gyors tárgyak: 5 hely alul középen (a kazamatában az XP-csík fölött, a táborban a
## képernyő alján). Minden helynek fix tartalma van; most csak az elsőn van valami:
## a HP bájital. Az [1] gombbal megiszod: az elvesztett életed felét tölti vissza.
## A bájitalok a futáshoz tartoznak (GameState.potions): a gyanús boltosnál veheted
## (boltonként legfeljebb 2-t, 125 aranyért), és minden főellenség után kapsz egyet.

const SLOTS := 5
const SLOT_SIZE := Vector2(48, 48)
const POTION_ICON: Texture2D = preload("res://assets/ui/potion_hp.png")

## A tábor alján nincs XP-csík, ott lejjebb van.
var bottom_offset := -44.0

var _count_label: Label
var _potion_icon: TextureRect
var _slot_panels: Array[Panel] = []
var _last_count := -1


func _ready() -> void:
	layer = 4
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	var width := SLOTS * SLOT_SIZE.x + (SLOTS - 1) * 6
	row.offset_left = -width / 2.0
	row.offset_right = width / 2.0
	row.offset_bottom = bottom_offset
	row.offset_top = bottom_offset - SLOT_SIZE.y
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(row)
	for i in SLOTS:
		var slot := Panel.new()
		slot.custom_minimum_size = SLOT_SIZE
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.05, 0.04, 0.75)
		style.border_color = Color(0.6, 0.45, 0.25, 0.9)
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		slot.add_theme_stylebox_override("panel", style)
		row.add_child(slot)
		_slot_panels.append(slot)
		if i == 0:
			_potion_icon = TextureRect.new()
			_potion_icon.texture = POTION_ICON
			_potion_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			_potion_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_potion_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 5)
			_potion_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(_potion_icon)
			_count_label = _corner_label(slot, "", HORIZONTAL_ALIGNMENT_RIGHT, VERTICAL_ALIGNMENT_BOTTOM, 18, Color.WHITE)
		# A hely gombja a bal felső sarokban.
		_corner_label(slot, str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, 13, Color(1, 0.9, 0.6, 0.85))
	_update()


## A helyet kitöltő felirat, a megadott sarokba igazítva.
func _corner_label(slot: Panel, text: String, horizontal: HorizontalAlignment, vertical: VerticalAlignment,
		size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = horizontal
	label.vertical_alignment = vertical
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 3
	label.offset_right = -3
	label.offset_top = -2
	label.offset_bottom = 1
	return label


func _process(_delta: float) -> void:
	_update()


func _update() -> void:
	if GameState.potions == _last_count:
		return
	_last_count = GameState.potions
	_count_label.text = str(GameState.potions)
	# Üresen halványan látszik, hogy itt lesz a bájital.
	_potion_icon.modulate = Color.WHITE if GameState.potions > 0 else Color(1, 1, 1, 0.3)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or get_tree().paused:
		return
	if key.physical_keycode == KEY_1:
		get_viewport().set_input_as_handled()
		drink_potion()


## Megissza a bájitalt: az elvesztett élet felét (felfelé kerekítve) tölti vissza.
func drink_potion() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var health: Health = player.get_node("Health")
	if health.is_dead():
		return
	if GameState.potions <= 0:
		_say(player, "Nincs HP bájitalod", Color(1, 0.5, 0.4))
		Audio.play("ui_error")
		return
	var missing := health.max_health - health.current
	if missing <= 0:
		_say(player, "Tele az életed", Color(0.85, 0.85, 0.8))
		Audio.play("ui_error")
		return
	var amount := ceili(missing / 2.0)
	GameState.potions -= 1
	health.heal(amount)
	Audio.play("xp", 4.0, 0.15)
	_say(player, "+%d élet  (maradt: %d bájital)" % [amount, GameState.potions], Color(1, 0.45, 0.5))
	var flash := create_tween()
	flash.tween_property(_slot_panels[0], "modulate", Color(1.8, 1.2, 1.2), 0.08)
	flash.tween_property(_slot_panels[0], "modulate", Color.WHITE, 0.25)


func _say(player: Node2D, text: String, color: Color) -> void:
	FloatingText.spawn(player.get_parent(), player.global_position + Vector2(-70, -64), text, color)
