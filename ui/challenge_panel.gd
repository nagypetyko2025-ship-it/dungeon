class_name ChallengePanel
extends CanvasLayer
## A próbatétel ablaka (lásd Challenge). Ajánlat (a bánya mélyén, a lyuk lépcsőjénél: show_offer): a kazamata
## hossza, nehézsége, könnyítései és nehezítései, a jutalom, a szabályok és hogy mikor jön új; "Lemegyek" /
## "Mégse". Eredmény (a próbatétel utolsó lépcsőjénél: show_result): a jutalom tárgya és a táborba vitt arany,
## "Vissza a táborba". Megnyitását / bezárását a Menus kezeli.

const CAMP := "res://world/camp.tscn"
const GOOD := Color(0.24, 0.5, 0.2)
const BAD := Color(0.7, 0.14, 0.12)
const GOLD := Color(0.6, 0.38, 0.05)

var _window: PanelContainer
var _body: VBoxContainer
var _timer_label: Label
var _challenge := {}
var _on_start: Callable
var _offer := false


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func open() -> void:
	visible = true


func close() -> void:
	visible = false


func close_anchor() -> Control:
	return _window


## Az ajánlat: `on_start` a "Lemegyek" gombra hívódik a próbatétellel.
func show_offer(challenge: Dictionary, on_start: Callable) -> void:
	_offer = true
	_challenge = challenge
	_on_start = on_start
	_fill_offer()


## Az eredmény: a jutalom tárgya ({} = csalt futás, nincs jutalom) és a táborba került arany.
func show_result(challenge: Dictionary, item: Dictionary, gold: int) -> void:
	_offer = false
	_challenge = challenge
	_clear()
	_body.add_child(UiStyle.title_bar("Próbatétel teljesítve!"))
	_body.add_child(_line("Végigértél mind a %d emeleten (%s nehézség)." % [challenge["floors"], challenge["difficulty"]],
		18, UiStyle.INK))
	if item.is_empty():
		_body.add_child(_line("Csalt futás: nincs jutalom.", 17, BAD))
	else:
		_body.add_child(_line("Jutalom (a tábori ládádba került):", 17, UiStyle.INK_LIGHT))
		_body.add_child(_line(item["name"], 22, Items.rarity_ink(item)))
		var details := RichTextLabel.new()
		details.bbcode_enabled = true
		details.fit_content = true
		details.scroll_active = false
		details.custom_minimum_size.x = 680
		details.add_theme_color_override("default_color", UiStyle.INK)
		details.add_theme_font_size_override("normal_font_size", 15)
		details.text = Items.describe_bbcode(item)
		_body.add_child(details)
		_body.add_child(_line("+%d tábori arany (a lent szerzett aranyad egésze)" % gold, 18, GOLD))
	_body.add_child(_line("A lent szerzett és levitt tárgyak lent maradtak. Új próbatétel vár a bánya mélyén.", 15,
		UiStyle.INK_LIGHT))
	var back := _button("Vissza a táborba", _go_to_camp)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_body.add_child(back)


func _process(_delta: float) -> void:
	if not visible or not _offer:
		return
	var left := Challenge.seconds_left()
	# Lejárt: már egy új próbatétel vár.
	if left <= 0:
		_challenge = Challenge.current()
		_fill_offer()
		return
	_timer_label.text = "Új próbatétel %d:%02d múlva (vagy ha ezt teljesítetted)." % [left / 60, left % 60]


func _unhandled_input(event: InputEvent) -> void:
	if visible and _offer and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		get_tree().current_scene.get_node("Menus").call("close_current")


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(center)
	_window = PanelContainer.new()
	_window.add_theme_stylebox_override("panel", UiStyle.decorated_panel())
	_window.custom_minimum_size = Vector2(760, 0)
	center.add_child(_window)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 8)
	_window.add_child(_body)


func _fill_offer() -> void:
	_clear()
	var challenge := _challenge
	_body.add_child(UiStyle.title_bar("A Mélység próbája"))
	_body.add_child(_line("Ez a kazamata %d emeletig tart: a %d. emelet lépcsője a cél." % [challenge["floors"],
		challenge["floors"]], 18, UiStyle.INK))
	_body.add_child(_line("Nehézség: %s   %s  (%d / %d)" % [challenge["difficulty"], Challenge.difficulty_meter(challenge),
		int(challenge.get("level", 0)) + 1, Challenge.DIFFICULTIES.size()], 20, Challenge.difficulty_color(challenge)))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	_body.add_child(columns)
	columns.add_child(_modifier_column("Könnyítések", challenge["boons"], Challenge.BOONS, GOOD, "+"))
	columns.add_child(_modifier_column("Nehezítések", challenge["banes"], Challenge.BANES, BAD, "−"))
	_body.add_child(_line("Jutalom, ha végigérsz: %s" % Challenge.reward_text(challenge), 18, GOLD))
	var rules := PanelContainer.new()
	rules.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	_body.add_child(rules)
	rules.add_child(_line("• Innen nem lehet felküldeni tárgyat: nincs tárgylift, és nincs pihenő a táborban.\n"
		+ "• Amit leviszel vagy lent kapsz, az lent marad (a felszerelésed is!). Amit nem akarsz elveszíteni, "
		+ "tedd előtte a tábori ládába.\n"
		+ "• Az arany csak akkor jön fel veled, ha nyersz (akkor az egésze). Ha meghalsz, minden lent marad.", 15,
		UiStyle.INK_LIGHT))
	_timer_label = _line("", 15, UiStyle.INK_LIGHT)
	_body.add_child(_timer_label)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	_body.add_child(buttons)
	buttons.add_child(_button("Lemegyek", _start))
	buttons.add_child(_button("Mégse", func() -> void: get_tree().current_scene.get_node("Menus").call("close_current")))
	_process(0.0)


func _modifier_column(title: String, ids: Array, pool: Dictionary, color: Color, mark: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 2)
	var heading := _line(title + ":", 17, UiStyle.INK)
	heading.custom_minimum_size.x = 330
	column.add_child(heading)
	for id: String in ids:
		var label := _line("%s %s: %s" % [mark, pool[id]["name"], pool[id]["text"]], 15, color)
		label.custom_minimum_size.x = 330
		column.add_child(label)
	return column


func _start() -> void:
	get_tree().current_scene.get_node("Menus").call("close_current")
	if _on_start.is_valid():
		_on_start.call(_challenge)


func _go_to_camp() -> void:
	GameState.reset()
	Audio.play("level_up")
	GamePause.set_paused(get_tree(), false)
	Progress.save_game()
	get_tree().change_scene_to_file(CAMP)


func _clear() -> void:
	for child in _body.get_children():
		child.queue_free()


func _line(text: String, size: int, color: Color) -> Label:
	var label := UiStyle.label(text, size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 700
	return label


func _button(text: String, action: Callable) -> Button:
	var button := MenuStyle.button(text)
	button.custom_minimum_size = Vector2(220, 48)
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(action)
	return button
