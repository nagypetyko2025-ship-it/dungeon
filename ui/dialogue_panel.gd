class_name DialoguePanel
extends CanvasLayer
## Beszélgetés egy NPC-vel: felül a bizalom-sáv (-100..+100, alapból 0, NPC-nként mentve),
## középen az NPC képe, neve és a mondandója, alul oldalanként MAX_OPTIONS választható
## opció (egérrel vagy az 1-5 gombokkal); ha több van, lapozni lehet (nyilak / ◀ ▶ gombok). Egy opció: {id, text, answer, trust}; a "trust"
## csak az első kérdezéskor számít. A már feltett kérdések pipát kapnak (újra kérdezhetők).
## Ha van `options_provider`, minden választás után újra lekéri az opciókat (pl. küldetés
## után új opció jelenik meg); egy opció "on_choose" Callable-je adja a választ (pl. átadás).
## Megnyitását/bezárását a Menus kezeli (E / Esc: bezárás).

const MAX_OPTIONS := 5
const TRUST_MIN := -100
const TRUST_MAX := 100
const BAR_SIZE := Vector2(420, 18)
## A bal oldali oszlop (kép, név, választható mondatok) szélessége.
const OPTIONS_WIDTH := 380.0

var npc_id := ""
var npc_name := ""
var portrait: Texture2D
var greeting := ""
var options: Array[Dictionary] = []
## Ha be van állítva: () -> Array[Dictionary], az aktuális opciók (az `options` helyett).
var options_provider: Callable

var _trust_value: Label
var _trust_fill: ColorRect
var _trust_bar: Control
var _name_label: Label
var _portrait_rect: TextureRect
var _text: RichTextLabel
var _options_box: VBoxContainer
var _typing: Tween
var _current: Array = []
## Az opciók aktuális oldala (oldalanként MAX_OPTIONS).
var _page := 0
var _page_row: HBoxContainer
var _page_label: Label
var _prev_button: Button
var _next_button: Button


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func open() -> void:
	_name_label.text = npc_name
	_portrait_rect.texture = portrait
	_say(greeting)
	_page = 0
	_refresh_options()
	_update_trust(false)
	visible = true


func close() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		get_tree().current_scene.get_node("Menus").call("close_current")
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode in [KEY_LEFT, KEY_RIGHT]:
		get_viewport().set_input_as_handled()
		_turn_page(-1 if key.physical_keycode == KEY_LEFT else 1)
		return
	var index := key.physical_keycode - KEY_1
	if index >= 0 and index < _page_count_on_page():
		get_viewport().set_input_as_handled()
		_choose(_page * MAX_OPTIONS + index)


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	# Felül: bizalom-sáv (bal fele piros, jobb fele zöld, középen a 0).
	var trust_panel := PanelContainer.new()
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color(0.08, 0.05, 0.04, 0.92)
	backing.border_color = Color(0.6, 0.45, 0.25, 0.9)
	backing.set_border_width_all(2)
	backing.set_corner_radius_all(6)
	backing.set_content_margin_all(10)
	trust_panel.add_theme_stylebox_override("panel", backing)
	trust_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	trust_panel.offset_left = -BAR_SIZE.x / 2.0 - 12
	trust_panel.offset_right = BAR_SIZE.x / 2.0 + 12
	trust_panel.offset_top = 14
	add_child(trust_panel)
	var trust_box := VBoxContainer.new()
	trust_box.add_theme_constant_override("separation", 4)
	trust_panel.add_child(trust_box)
	_trust_value = MenuStyle.title_label("", 26, MenuStyle.GOLD)
	_trust_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trust_box.add_child(_trust_value)
	_trust_bar = Control.new()
	_trust_bar.custom_minimum_size = BAR_SIZE
	trust_box.add_child(_trust_bar)
	var back := ColorRect.new()
	back.color = Color(0.1, 0.06, 0.05, 0.9)
	back.size = BAR_SIZE
	_trust_bar.add_child(back)
	_trust_fill = ColorRect.new()
	_trust_bar.add_child(_trust_fill)
	var middle := ColorRect.new()
	middle.color = Color(1, 0.9, 0.6)
	middle.size = Vector2(2, BAR_SIZE.y + 6)
	middle.position = Vector2(BAR_SIZE.x / 2.0 - 1, -3)
	_trust_bar.add_child(middle)
	var scale_row := HBoxContainer.new()
	trust_box.add_child(scale_row)
	for text: String in ["-100  Gyanakvó", "Bizalmas  +100"]:
		var label := Label.new()
		label.text = text
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if text.begins_with("-") else HORIZONTAL_ALIGNMENT_RIGHT
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", MenuStyle.PARCHMENT)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 4)
		scale_row.add_child(label)

	# Lent: a beszélgetés ablaka.
	var window := PanelContainer.new()
	window.add_theme_stylebox_override("panel", UiStyle.decorated_panel())
	window.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	window.offset_left = -520
	window.offset_right = 520
	window.offset_top = -530
	# Ha a tartalom mégis nagyobb, fölfelé nőjön (ne lógjon ki a képernyő aljából).
	window.grow_vertical = Control.GROW_DIRECTION_BEGIN
	window.offset_bottom = -24
	window.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(window)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	window.add_child(root)
	# Bal oldalt: az NPC képe és neve, alatta a választható mondatok; jobbra az NPC szövege.
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(top)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.custom_minimum_size.x = OPTIONS_WIDTH
	top.add_child(left)
	var who := HBoxContainer.new()
	who.add_theme_constant_override("separation", 12)
	left.add_child(who)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	who.add_child(frame)
	_portrait_rect = TextureRect.new()
	_portrait_rect.custom_minimum_size = Vector2(72, 112)
	_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.add_child(_portrait_rect)
	_name_label = UiStyle.label("", 19, UiStyle.INK)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	who.add_child(_name_label)
	left.add_child(UiStyle.label("Mit mondasz?", 16, UiStyle.INK_LIGHT))
	_options_box = VBoxContainer.new()
	_options_box.add_theme_constant_override("separation", 4)
	left.add_child(_options_box)
	_page_row = HBoxContainer.new()
	_page_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_page_row.add_theme_constant_override("separation", 16)
	left.add_child(_page_row)
	_prev_button = _page_button("◀  Előző")
	_prev_button.pressed.connect(_turn_page.bind(-1))
	_page_row.add_child(_prev_button)
	_page_label = UiStyle.label("1 / 1", 16, UiStyle.INK_LIGHT)
	_page_row.add_child(_page_label)
	_next_button = _page_button("Következő  ▶")
	_next_button.pressed.connect(_turn_page.bind(1))
	_page_row.add_child(_next_button)
	var divider := ColorRect.new()
	divider.color = Color(0.42, 0.28, 0.16, 0.5)
	divider.custom_minimum_size.x = 2
	top.add_child(divider)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = true
	_text.scroll_following = false
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_color_override("default_color", UiStyle.INK)
	_text.add_theme_font_size_override("normal_font_size", 17)
	_text.add_theme_font_size_override("italics_font_size", 17)
	top.add_child(_text)
	var hint := UiStyle.label("1-5 / kattintás: választás   ·   ← → lapozás   ·   [E] / [Esc] búcsú", 14, UiStyle.INK_LIGHT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(hint)


func _refresh_options() -> void:
	for child in _options_box.get_children():
		child.queue_free()
	if options_provider.is_valid():
		_current = options_provider.call()
	else:
		_current = options
	var pages := _page_total()
	_page = clampi(_page, 0, pages - 1)
	_page_row.visible = pages > 1
	_page_label.text = "%d / %d" % [_page + 1, pages]
	_prev_button.disabled = _page == 0
	_next_button.disabled = _page == pages - 1
	var asked: Array = Progress.asked_topics(npc_id)
	for slot in _page_count_on_page():
		var i := _page * MAX_OPTIONS + slot
		var option: Dictionary = _current[i]
		var was_asked := asked.has(option["id"])
		var button := Button.new()
		button.text = "%d.  %s%s" % [slot + 1, option["text"], "   ✔" if was_asked else ""]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.x = OPTIONS_WIDTH
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 17)
		var ink := UiStyle.INK_LIGHT if was_asked else UiStyle.INK
		button.add_theme_color_override("font_color", ink)
		button.add_theme_color_override("font_hover_color", Color(0.6, 0.3, 0.05))
		button.add_theme_color_override("font_pressed_color", Color(0.6, 0.3, 0.05))
		button.add_theme_stylebox_override("normal", _option_style(Color(0.42, 0.28, 0.16, 0.1)))
		button.add_theme_stylebox_override("hover", _option_style(Color(0.42, 0.28, 0.16, 0.25)))
		button.add_theme_stylebox_override("pressed", _option_style(Color(0.42, 0.28, 0.16, 0.35)))
		button.pressed.connect(_choose.bind(i))
		_options_box.add_child(button)


func _page_total() -> int:
	return maxi(1, ceili(_current.size() / float(MAX_OPTIONS)))


## Hány opció van az aktuális oldalon.
func _page_count_on_page() -> int:
	return clampi(_current.size() - _page * MAX_OPTIONS, 0, MAX_OPTIONS)


func _turn_page(step: int) -> void:
	var target := clampi(_page + step, 0, _page_total() - 1)
	if target == _page:
		return
	_page = target
	Audio.play("ui_click")
	_refresh_options()


func _page_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", UiStyle.INK)
	button.add_theme_color_override("font_hover_color", Color(0.6, 0.3, 0.05))
	button.add_theme_color_override("font_disabled_color", Color(UiStyle.INK_LIGHT, 0.4))
	button.add_theme_stylebox_override("normal", _option_style(Color(0.42, 0.28, 0.16, 0.1)))
	button.add_theme_stylebox_override("hover", _option_style(Color(0.42, 0.28, 0.16, 0.25)))
	button.add_theme_stylebox_override("pressed", _option_style(Color(0.42, 0.28, 0.16, 0.35)))
	button.add_theme_stylebox_override("disabled", _option_style(Color(0.42, 0.28, 0.16, 0.04)))
	return button


func _option_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style


func _choose(index: int) -> void:
	var option: Dictionary = _current[index]
	Audio.play("ui_click")
	var trust_before := Progress.trust_of(npc_id)
	# A bizalom csak az első kérdezéskor változik. Egyedi opciónál ("on_choose") a Callable
	# maga jelöli meg (pl. sikertelen átadásnál ne kapjon pipát), és ő kezeli a bizalmat is.
	if not option.has("on_choose") and not Progress.asked_topics(npc_id).has(option["id"]):
		Progress.mark_asked(npc_id, option["id"])
		var delta: int = option.get("trust", 0)
		if delta != 0:
			Progress.change_trust(npc_id, delta)
	# Egyedi opció (pl. tárgy átadása): a Callable dönt, és ő adja a választ.
	var answer := ""
	if option.has("on_choose"):
		answer = (option["on_choose"] as Callable).call()
	else:
		answer = option["answer"]
	if Progress.trust_of(npc_id) != trust_before:
		_update_trust(true)
	_say("[i]„%s”[/i]\n\n%s" % [option["text"], answer])
	_refresh_options()


## Az NPC szövege betűnként jelenik meg (kattintásra / gombra nem kell várni, görgethető).
func _say(text: String) -> void:
	_text.text = text
	_text.scroll_to_line(0)
	_text.visible_ratio = 0.0
	if _typing:
		_typing.kill()
	_typing = create_tween()
	_typing.tween_property(_text, "visible_ratio", 1.0, clampf(text.length() / 260.0, 0.3, 3.0))


func _update_trust(animate: bool) -> void:
	var trust := Progress.trust_of(npc_id)
	_trust_value.text = "Bizalom: %+d" % trust if trust != 0 else "Bizalom: 0"
	var half := BAR_SIZE.x / 2.0
	var width := half * absf(trust) / float(TRUST_MAX)
	_trust_fill.color = Color(0.35, 0.75, 0.3) if trust >= 0 else Color(0.8, 0.25, 0.2)
	_trust_fill.size = Vector2(width, BAR_SIZE.y)
	_trust_fill.position = Vector2(half if trust >= 0 else half - width, 0)
	if animate:
		var flash := create_tween()
		flash.tween_property(_trust_value, "modulate", Color(1.6, 1.6, 1.0), 0.15)
		flash.tween_property(_trust_value, "modulate", Color.WHITE, 0.4)
