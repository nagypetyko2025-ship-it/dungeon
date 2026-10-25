class_name PotionBadge
extends CanvasLayer
## HP bájital: a kazamatában az életcsík mellett (bal fent), a táborban a bal felső sarokban egy kis
## jelző mutatja, mennyi van nálad. A [Q] gombbal megiszod: az elvesztett életed felét tölti vissza.
## A bájitalok a futáshoz tartoznak (GameState.potions): a gyanús boltosnál veheted
## (boltonként legfeljebb 2-t, 60 aranyért), és minden főellenség után kapsz egyet.

const ICON_SIZE := Vector2(30, 30)
const POTION_ICON: Texture2D = preload("res://assets/ui/potion_hp.png")

## A kazamatában az életcsík (HUD) mellé kerül; a táborban nincs életcsík, ott a sarokba.
var left_offset := 246.0

var _box: HBoxContainer
var _icon: TextureRect
var _count_label: Label
var _last_count := -1


func _ready() -> void:
	layer = 4
	_box = HBoxContainer.new()
	_box.add_theme_constant_override("separation", 4)
	_box.position = Vector2(left_offset, 12)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_box)
	_icon = TextureRect.new()
	_icon.texture = POTION_ICON
	_icon.custom_minimum_size = ICON_SIZE
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_icon)
	_count_label = _label("", 18, Color.WHITE)
	_label("[Q]", 13, Color(1, 0.9, 0.6, 0.85))
	_update()


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(label)
	return label


func _process(_delta: float) -> void:
	_update()


func _update() -> void:
	if GameState.potions == _last_count:
		return
	_last_count = GameState.potions
	_count_label.text = str(GameState.potions)
	# Üresen halványan látszik, hogy itt lesz a bájital.
	_icon.modulate = Color.WHITE if GameState.potions > 0 else Color(1, 1, 1, 0.3)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or GamePause.active(get_tree()):
		return
	if key.physical_keycode == KEY_Q:
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
	flash.tween_property(_box, "modulate", Color(1.8, 1.2, 1.2), 0.08)
	flash.tween_property(_box, "modulate", Color.WHITE, 0.25)


func _say(player: Node2D, text: String, color: Color) -> void:
	FloatingText.spawn(player.get_parent(), player.global_position + Vector2(-70, -64), text, color)
