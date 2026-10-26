class_name CloseButton
extends Button
## A nyitott ablak jobb felső sarkában egy X: megnyomva bezárja az ablakot (mint az Esc). A Menus teszi ki
## minden megnyíló ablakra (lásd Menus._toggle), az ablak rétegébe. Az ablak keretét magától keresi meg
## (a legnagyobb látható panel, ami nem tölti ki az egész képernyőt); egy ablak a `close_anchor()`
## függvénnyel meg is adhatja. Minden képkockán a keret sarkához igazodik (az ablakok mérete változhat).

const SIZE := Vector2(34, 34)
## Ennyivel beljebb a keret sarkától (a díszes keretek sarkain belül).
const INSET := Vector2(14, 12)

var menu: Node
var _target: Control


## Az X az ablak rétegébe: ha az ablak maga nem CanvasLayer, a legközelebbi CanvasLayer ősébe, vagy ha
## nincs ilyen (pl. a csalómenü sima Node), az első CanvasLayer gyerekébe.
static func attach(to_menu: Node, on_press: Callable) -> CloseButton:
	var button := CloseButton.new()
	button.menu = to_menu
	button.pressed.connect(on_press)
	var layer: Node = to_menu
	while layer != null and not layer is CanvasLayer:
		layer = layer.get_parent()
	if layer == null:
		var layers := to_menu.find_children("*", "CanvasLayer", true, false)
		layer = layers[0] if not layers.is_empty() else to_menu
	layer.add_child(button)
	return button


## Az ablak kerete: a `close_anchor()` (ha van), a Control ablak maga, vagy a legnagyobb látható panel benne
## (ami nem az egész képernyős háttér). Keret nélküli ablaknál (pl. a szünet menü) a legnagyobb látható elem: az egész képernyő.
static func find_window(of_menu: Node) -> Control:
	if of_menu.has_method("close_anchor"):
		return of_menu.call("close_anchor")
	if of_menu is Control:
		return of_menu
	var screen := of_menu.get_viewport().get_visible_rect().size
	var best: Control = null
	var best_area := 0.0
	var largest: Control = null
	var largest_area := 0.0
	for node in of_menu.find_children("*", "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree() or control is CloseButton:
			continue
		var rect := control.get_global_rect()
		var area := rect.size.x * rect.size.y
		if area > largest_area:
			largest = control
			largest_area = area
		if not (control is PanelContainer or control is Panel or control is NinePatchRect or control is TextureRect):
			continue
		# Csak a tényleg az egész képernyőt kitöltő háttér nem keret: egy nagy ablak 16:9-es képernyőn
		# (1280x720) majdnem akkora lehet, mint a képernyő (pl. a kiképzősátor), az még keret.
		if rect.size.x >= screen.x - 1.0 and rect.size.y >= screen.y - 1.0:
			continue
		if area > best_area:
			best = control
			best_area = area
	return best if best != null else largest


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	text = "X"
	tooltip_text = "Bezárás"
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = SIZE
	size = SIZE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	add_theme_font_size_override("font_size", 20)
	add_theme_color_override("font_color", MenuStyle.GOLD_LIGHT)
	add_theme_color_override("font_hover_color", Color.WHITE)
	add_theme_color_override("font_pressed_color", MenuStyle.GOLD)
	add_theme_color_override("font_outline_color", MenuStyle.SHADOW)
	add_theme_constant_override("outline_size", 4)
	add_theme_stylebox_override("normal", _style(Color(0.4, 0.11, 0.07)))
	add_theme_stylebox_override("hover", _style(Color(0.62, 0.16, 0.09)))
	add_theme_stylebox_override("pressed", _style(Color(0.3, 0.08, 0.05)))
	mouse_entered.connect(Audio.play.bind("ui_hover"))
	visible = false


func _style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.86, 0.62, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 3
	return style


func _process(_delta: float) -> void:
	if not is_instance_valid(menu):
		queue_free()
		return
	# Az ablak elrendezése a megnyitás utáni képkockán dől el; ha a keret eltűnt (pl. lapozás), újrakeresi.
	if not is_instance_valid(_target) or not _target.is_visible_in_tree():
		_target = find_window(menu)
	visible = _target != null
	if _target == null:
		return
	var rect := _target.get_global_rect()
	global_position = Vector2(rect.end.x - SIZE.x - INSET.x, rect.position.y + INSET.y)
	move_to_front()
