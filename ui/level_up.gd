extends CanvasLayer
## Szintlépéskor megállítja a játékot, és 3 fejlesztés közül lehet választani
## (egérrel vagy az 1/2/3 gombokkal). Ha egyszerre több szint jött,
## egymás után többször is választhatsz.
## Közös játékban nem ugrik fel magától (harc közben nagyon zavaró): alul egy gomb jelenik meg,
## és akkor választasz, amikor neked jó (a gombra kattintva vagy az L-lel).

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
## Közös játék: a "választhatsz" gomb alul (külön rétegen, mert ez a réteg rejtve van).
var _pending_layer: CanvasLayer
var _pending_button: Button

const LEGENDARY_COLOR := Color(1, 0.6, 0.15)
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
	# Közös játék: az előző emeleten ki nem választott szintlépések.
	if _shared_game() and not GameState.pending_level_ups.is_empty():
		_level_queue.assign(GameState.pending_level_ups)
		_show_pending.call_deferred()


func _shared_game() -> bool:
	return NetLobby.is_playing(get_tree()) and not GameState.tutorial


## Közös játék: alul egy gomb, hogy van még kiválasztatlan szintlépés.
func _show_pending() -> void:
	GameState.pending_level_ups.assign(_level_queue)
	if _pending_layer == null:
		_pending_layer = CanvasLayer.new()
		_pending_layer.layer = layer
		_pending_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		add_sibling(_pending_layer)
		_pending_button = MenuStyle.button("")
		_pending_button.focus_mode = Control.FOCUS_NONE
		_pending_button.custom_minimum_size = Vector2(440, 54)
		_pending_button.add_theme_font_size_override("font_size", 22)
		_pending_button.anchor_left = 0.5
		_pending_button.anchor_right = 0.5
		_pending_button.anchor_top = 1.0
		_pending_button.anchor_bottom = 1.0
		_pending_button.offset_left = -220.0
		_pending_button.offset_right = 220.0
		_pending_button.offset_top = -160.0
		_pending_button.offset_bottom = -106.0
		_pending_button.pressed.connect(_open_pending)
		_pending_layer.add_child(_pending_button)
		# Finoman lüktet, hogy észrevedd.
		var pulse := _pending_button.create_tween().set_loops()
		pulse.tween_property(_pending_button, "self_modulate", Color(1.3, 1.2, 0.8), 0.7).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(_pending_button, "self_modulate", Color.WHITE, 0.7).set_trans(Tween.TRANS_SINE)
	var count := _level_queue.size()
	_pending_button.text = "▲ Szintlépés! Válassz fejlesztést [L]" + ("  (%d)" % count if count > 1 else "")
	_pending_layer.visible = not visible and count > 0


func _open_pending() -> void:
	if visible or _level_queue.is_empty() or get_tree().paused:
		return
	_pending_layer.visible = false
	_open()


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
	_options = _roll_options()
	_show_cards()


## Íjjal vagy íjászként a Nyílzápor legendás kártya is felbukkanhat.
func _has_bow() -> bool:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return false
	var weapon = player.get_node("Inventory").equipment.get("weapon")
	return Progress.character == "archer" or (weapon is Dictionary and Items.is_ranged(weapon))


func _growth_text() -> String:
	var parts: Array[String] = []
	for stat: String in Stats.LEVEL_GROWTH:
		var amount: float = Stats.LEVEL_GROWTH[stat]
		var text := Items.format_stat(stat, amount)
		if stat in ["damage", "ranged_damage", "dodge", "crit_chance", "health_regen", "defense", "accuracy"]:
			# A tört értékek (pl. +0.25 sebzés) tizedesekkel.
			text = "+%s%s %s" % [str(amount), "%" if stat in Items.PERCENT_STATS else "", Items.STAT_LABELS[stat]]
		parts.append(text)
	return "Minden szinten automatikusan:  " + ",  ".join(parts)


func _on_leveled_up(level: int) -> void:
	_level_queue.append(level)
	if visible:
		return
	if _shared_game():
		_show_pending()
	else:
		_open()


## A választható kártyák: a varázslónál minden 5. szinten varázslat-kártyák (fejlesztés / új,
## lásd Spells), máskor a szokásos fejlesztések.
func _roll_options() -> Array[Dictionary]:
	if Characters.data(Progress.character).get("spells", false) and not _level_queue.is_empty() 			and _level_queue[0] % Spells.SPELL_LEVEL_EVERY == 0 and not GameState.spells.is_empty():
		var spell_options := Spells.level_options()
		# Ha már minden varázslat a legmagasabb szinten van: a szokásos fejlesztések.
		if not spell_options.is_empty():
			return spell_options
	return Upgrades.roll(_stats, CARD_COUNT, _has_bow())


func _open() -> void:
	_options = _roll_options()
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
	if _options[index].has("spell"):
		Spells.choose(_options[index]["spell"])
	else:
		Upgrades.apply(_stats, _options[index])
	_level_queue.pop_front()
	if _shared_game():
		GameState.pending_level_ups.assign(_level_queue)
	if _level_queue.is_empty():
		visible = false
		get_tree().paused = false
	else:
		_open()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	# Közös játék: L-lel nyílik a választás (ha van kiválasztatlan szintlépés).
	if not visible and key.physical_keycode == KEY_L and _shared_game() and not _level_queue.is_empty():
		_open_pending()
		get_viewport().set_input_as_handled()
		return
	if not visible:
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
	# A varázslat-kártyák szövege hosszabb: kisebb ikon és betű, hogy beférjen a kártyába.
	var spell := upgrade.has("spell")
	if spell:
		icon.custom_minimum_size = Vector2(52, 52)
		box.add_theme_constant_override("separation", 6)
	var title := _label(upgrade["title"], 20 if spell else 24, Color(1, 0.88, 0.55))
	var text := _label(upgrade["text"], 14 if spell else 16, Color(0.9, 0.86, 0.8))
	for label in [title, text]:
		label.custom_minimum_size.x = CARD_SIZE.x - 36
	box.add_child(title)
	box.add_child(text)
	if upgrade.has("note"):
		box.add_child(_label(upgrade["note"], 13, Color(0.6, 0.85, 1.0)))
	# Karakter-bónusz (pl. Gáspár kikerülése): külön, zöldes sorban.
	if upgrade.has("bonus_note"):
		box.add_child(_label(upgrade["bonus_note"], 15, Color(0.55, 1.0, 0.6)))
	if upgrade.get("legendary", false):
		_make_legendary(card, box, icon)
	return card


## Legendás kártya: izzó arany-narancs keret, "LEGENDÁS" felirat, lüktető fény, csillogás.
func _make_legendary(card: Button, box: VBoxContainer, icon: TextureRect) -> void:
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.22, 0.1, 0.03) if state == "normal" else Color(0.32, 0.15, 0.04)
		style.border_color = LEGENDARY_COLOR if state == "normal" else Color(1, 0.85, 0.4)
		style.set_border_width_all(5)
		style.set_corner_radius_all(6)
		style.shadow_color = Color(1, 0.55, 0.1, 0.55)
		style.shadow_size = 14
		style.set_content_margin_all(16)
		card.add_theme_stylebox_override(state, style)
	var banner := _label("★ LEGENDÁS ★", 16, LEGENDARY_COLOR)
	box.add_child(banner)
	box.move_child(banner, 1)
	icon.custom_minimum_size = Vector2(88, 88)
	# Lüktetés és szikrák.
	var glow := card.create_tween().set_loops()
	glow.tween_property(card, "self_modulate", Color(1.35, 1.15, 0.85), 0.6).set_trans(Tween.TRANS_SINE)
	glow.tween_property(card, "self_modulate", Color.WHITE, 0.6).set_trans(Tween.TRANS_SINE)
	var sparks := CPUParticles2D.new()
	sparks.amount = 24
	sparks.lifetime = 1.4
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparks.emission_rect_extents = CARD_SIZE / 2.0
	sparks.position = CARD_SIZE / 2.0
	sparks.direction = Vector2(0, -1)
	sparks.spread = 30.0
	sparks.gravity = Vector2(0, -25)
	sparks.initial_velocity_min = 10.0
	sparks.initial_velocity_max = 30.0
	sparks.scale_amount_min = 2.0
	sparks.scale_amount_max = 3.5
	sparks.color = Color(1, 0.75, 0.3)
	card.add_child(sparks)
	Audio.play("boss_defeated", -14.0)


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
