extends CanvasLayer
## Szintlépéskor megállítja a játékot, és 3 fejlesztés közül lehet választani
## (egérrel vagy az 1/2/3 gombokkal). Ha egyszerre több szint jött,
## egymás után többször is választhatsz.

const CARD_COUNT := 3
const CARD_SIZE := Vector2(210, 250)
## Ennyi ideig nem fogad kattintást, hogy egy harc közbeni kattintás
## ne válasszon véletlenül.
const INPUT_DELAY := 0.4
const PANEL: Texture2D = preload("res://assets/ui/panel.png")
const PANEL_HOVER: Texture2D = preload("res://assets/ui/panel_hover.png")

var _level_queue: Array[int] = []
var _options: Array[Dictionary] = []
var _accepting_input := false
var _stats: Stats
var _reroll_button: Button

const REROLL_BASE := 5.0
const REROLL_GROWTH := 1.6

@onready var _title: Label = $Center/Box/Title
@onready var _cards: HBoxContainer = $Center/Box/Cards


func _ready() -> void:
	visible = false
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	_stats = player.get_node("Stats")
	player.get_node("Experience").leveled_up.connect(_on_leveled_up)
	# A cím alatt: mennyit nőtt magától minden stat ezen a szinten.
	var growth := _label(_growth_text(), 16, Color(0.6, 0.95, 0.6))
	growth.custom_minimum_size.x = CARD_SIZE.x * CARD_COUNT
	_title.get_parent().add_child(growth)
	_title.get_parent().move_child(growth, _title.get_index() + 1)
	# Újradobás aranyért (R): új fejlesztések, minden alkalommal drágábban.
	_reroll_button = MenuStyle.button("")
	_reroll_button.custom_minimum_size = Vector2(360, 56)
	_reroll_button.add_theme_font_size_override("font_size", 20)
	_reroll_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_reroll_button.focus_mode = Control.FOCUS_NONE
	_reroll_button.pressed.connect(_reroll)
	_cards.get_parent().add_child(_reroll_button)


## Az újradobás ára: REROLL_BASE, majd minden újradobás után REROLL_GROWTH-szor több (futásonként).
static func reroll_cost() -> int:
	return roundi(REROLL_BASE * pow(REROLL_GROWTH, GameState.rerolls))


func _update_reroll_button() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var cost := reroll_cost()
	_reroll_button.text = "[R] Újradobás: %d arany" % cost
	_reroll_button.disabled = player == null or int(player.get("gold")) < cost


func _reroll() -> void:
	if not _accepting_input:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not player.call("spend_gold", reroll_cost()):
		Audio.play("ui_error")
		return
	GameState.rerolls += 1
	Audio.play("coin")
	_options = Upgrades.roll(_stats, CARD_COUNT)
	_show_cards()


func _growth_text() -> String:
	var parts: Array[String] = []
	for stat: String in Stats.LEVEL_GROWTH:
		var amount: float = Stats.LEVEL_GROWTH[stat]
		var text := Items.format_stat(stat, amount)
		if stat in ["damage", "dodge", "crit_chance", "health_regen", "defense"]:
			# A tört értékek (pl. +0.25 sebzés) tizedesekkel.
			text = "+%s%s %s" % [str(amount), "%" if stat in Items.PERCENT_STATS else "", Items.STAT_LABELS[stat]]
		parts.append(text)
	return "Minden szinten automatikusan:  " + ",  ".join(parts)


func _on_leveled_up(level: int) -> void:
	_level_queue.append(level)
	if not visible:
		_open()


func _open() -> void:
	_options = Upgrades.roll(_stats, CARD_COUNT)
	_title.text = "Szintlépés! — %d. szint" % _level_queue[0]
	_show_cards()
	visible = true
	get_tree().paused = true
	Audio.play("level_up")
	_accepting_input = false
	await get_tree().create_timer(INPUT_DELAY, true).timeout
	_accepting_input = true


func _show_cards() -> void:
	for child in _cards.get_children():
		child.queue_free()
	for i in _options.size():
		_cards.add_child(_make_card(i, _options[i]))
	_update_reroll_button()


func _choose(index: int) -> void:
	if not _accepting_input or index >= _options.size():
		return
	Audio.play("ui_click")
	Upgrades.apply(_stats, _options[index])
	_level_queue.pop_front()
	if _level_queue.is_empty():
		visible = false
		get_tree().paused = false
	else:
		_open()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not visible or key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_1: _choose(0)
		KEY_2: _choose(1)
		KEY_3: _choose(2)
		KEY_R: _reroll()
	get_viewport().set_input_as_handled()


func _make_card(index: int, upgrade: Dictionary) -> Button:
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_NONE
	card.add_theme_stylebox_override("normal", _panel_style(PANEL))
	card.add_theme_stylebox_override("hover", _panel_style(PANEL_HOVER))
	card.add_theme_stylebox_override("pressed", _panel_style(PANEL_HOVER))
	card.pressed.connect(_choose.bind(index))

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 18)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)

	box.add_child(_label("[%d]" % (index + 1), 14, Color(0.75, 0.68, 0.6)))
	var icon := TextureRect.new()
	icon.texture = Upgrades.icon(upgrade)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(72, 72)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	box.add_child(_label(upgrade["title"], 24, Color(1, 0.88, 0.55)))
	box.add_child(_label(upgrade["text"], 16, Color(0.9, 0.86, 0.8)))
	return card


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	return label


func _panel_style(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.set_texture_margin_all(12)
	style.set_content_margin_all(16)
	return style
