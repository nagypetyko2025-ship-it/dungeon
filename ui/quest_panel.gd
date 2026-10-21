extends CanvasLayer
## A kocsmáros küldetés-ablaka (a Mélységi kocsmában, E-vel): a küldetések listája
## haladással. Minden küldetés eleve fut, itt csak a kész küldetések jutalmát lehet
## átvenni (egyenként vagy mindet egyszerre). Megnyitását/bezárását a Menus kezeli.

const DONE_COLOR := Color(0.24, 0.5, 0.2)

var _list: VBoxContainer
var _summary: RichTextLabel
var _take_all: Button
var _message: Label


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func open() -> void:
	_message.text = ""
	_refresh()
	visible = true


func close() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("interact"):
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
	var window := PanelContainer.new()
	window.add_theme_stylebox_override("panel", UiStyle.decorated_panel())
	window.custom_minimum_size = Vector2(980, 0)
	center.add_child(window)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	window.add_child(root)
	root.add_child(UiStyle.title_bar("Küldetések — a kocsmáros táblája"))
	root.add_child(UiStyle.label("„Minden munkát rád bízok, nem kell kérni. Ha kész vagy, gyere a jutalomért!”",
		15, UiStyle.INK_LIGHT))

	var summary_box := PanelContainer.new()
	summary_box.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	root.add_child(summary_box)
	var summary_row := HBoxContainer.new()
	summary_row.add_theme_constant_override("separation", 12)
	summary_box.add_child(summary_row)
	_summary = RichTextLabel.new()
	_summary.bbcode_enabled = true
	_summary.fit_content = true
	_summary.scroll_active = false
	_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_summary.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_summary.add_theme_color_override("default_color", UiStyle.INK)
	_summary.add_theme_font_size_override("normal_font_size", 17)
	_summary.add_theme_font_size_override("bold_font_size", 17)
	summary_row.add_child(_summary)
	_take_all = _small_button("Mindet átveszem", _on_take_all)
	_take_all.custom_minimum_size.x = 230
	summary_row.add_child(_take_all)

	# A lista görgethető (később több küldetés is jöhet).
	var scroll := ScrollContainer.new()
	# (A 720 magas képernyőn az ablaknak bele kell férnie: a lista inkább görgethető.)
	scroll.custom_minimum_size = Vector2(0, 360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	# Alul egy sorban: az utolsó átvétel üzenete (ha hosszú, levágva) és a bezárás.
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 12)
	root.add_child(bottom)
	_message = UiStyle.label("", 16, Color(0.24, 0.5, 0.2))
	_message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_message.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_message.clip_text = true
	bottom.add_child(_message)
	var hint := UiStyle.label("[E] / [Esc] bezárás", 14, UiStyle.INK_LIGHT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bottom.add_child(hint)


func _small_button(text: String, action: Callable) -> Button:
	var button := MenuStyle.button(text)
	button.custom_minimum_size = Vector2(150, 46)
	button.add_theme_font_size_override("font_size", 18)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(action)
	return button


func _refresh() -> void:
	var ready := Quests.ready_ids().size()
	_summary.text = "[b]Teljesítve: %d / %d[/b]   ·   %s" % [Progress.quests_done.size(), Quests.ALL.size(),
		("[color=#3c6a32]%d jutalom vár rád![/color]" % ready) if ready > 0
		else "Minden küldetés fut — a kazamatában számol."]
	_take_all.disabled = ready == 0
	for child in _list.get_children():
		child.queue_free()
	for id: String in Quests.ALL:
		_list.add_child(_make_row(id))


func _make_row(id: String) -> PanelContainer:
	var definition: Dictionary = Quests.ALL[id]
	var done := Progress.quests_done.has(id)
	var complete := Quests.is_complete(id)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.4, 0.7, 0.3, 0.25) if complete else Color(0.42, 0.28, 0.16, 0.12)
	style.set_content_margin_all(6)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	# A név alatt a nehézség (könnyű / közepes), a saját színével.
	var tier: Dictionary = Quests.TIERS[definition.get("tier", "easy")]
	var name_box := VBoxContainer.new()
	name_box.add_theme_constant_override("separation", -4)
	name_box.custom_minimum_size.x = 200
	row.add_child(name_box)
	name_box.add_child(UiStyle.label(definition["name"], 17, UiStyle.INK if not done else Color(0.4, 0.35, 0.3, 0.7)))
	name_box.add_child(UiStyle.label(tier["name"], 13, tier["color"] if not done else Color(0.4, 0.35, 0.3, 0.6)))
	var text := UiStyle.label(definition["text"], 15, UiStyle.INK_LIGHT if not done else Color(0.4, 0.35, 0.3, 0.6))
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var reward := UiStyle.label(Quests.reward_text(id), 14, Color(0.6, 0.38, 0.05) if not done else Color(0.4, 0.35, 0.3, 0.6))
	reward.custom_minimum_size.x = 250
	row.add_child(reward)
	if done:
		row.add_child(_status_label("✔ Átvéve", DONE_COLOR))
	elif complete:
		var take := _small_button("Átvétel", _on_turn_in.bind(id))
		take.custom_minimum_size = Vector2(130, 34)
		take.add_theme_font_size_override("font_size", 16)
		row.add_child(take)
	else:
		row.add_child(_status_label("%d / %d" % [Quests.progress(id), definition["goal"]], Color(0.6, 0.38, 0.05)))
	return panel


func _status_label(text: String, color: Color) -> Label:
	var label := UiStyle.label(text, 16, color)
	label.custom_minimum_size.x = 130
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _on_turn_in(id: String) -> void:
	var reward := Quests.turn_in(id)
	if reward.is_empty():
		return
	Audio.play("level_up")
	_message.text = "%s — jutalom: %s" % [Quests.ALL[id]["name"], reward]
	_refresh()


func _on_take_all() -> void:
	var rewards: Array[String] = []
	for id in Quests.ready_ids():
		rewards.append(Quests.turn_in(id))
	if rewards.is_empty():
		return
	Audio.play("level_up")
	_message.text = "Jutalmak: " + ", ".join(rewards)
	_refresh()
