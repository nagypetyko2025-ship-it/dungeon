extends CanvasLayer
## Szünet menü (Esc játék közben): Folytatás, Beállítások, Főmenü, Kilépés.
## Megnyitását/bezárását a Menus kezeli (open()/close()); közben áll a játék.

const MAIN_MENU := "res://ui/main_menu.tscn"
const CAMP := "res://world/camp.tscn"
## Kilépéskor a pénzed ennyi része kerül a táborba.
const QUIT_GOLD_RATIO := 0.4

var _buttons: VBoxContainer
var _settings: SettingsPanel
var _settings_button: Button


func _ready() -> void:
	layer = 18
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(center)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 22)
	center.add_child(stack)
	stack.add_child(MenuStyle.title_label("Szünet", 96, MenuStyle.GOLD))

	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 14)
	stack.add_child(_buttons)
	_add_button("Folytatás", _resume)
	# A kazamatából vissza lehet menni a táborba (a futás véget ér, bekerül az eredmények közé).
	if GameState.tutorial:
		_add_button("Kilépés a gyakorlásból", func() -> void: TutorialGuide.leave_tutorial(get_tree()))
	elif get_parent().name == "Dungeon":
		_add_button("Vissza a táborba", _to_camp)
		var note := UiStyle.label("Kilépéskor a pénzed 40%-a a táborba kerül, a tárgyaid elvesznek.", 16, MenuStyle.PARCHMENT)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_buttons.add_child(note)
	_settings_button = _add_button("Beállítások", _show_settings.bind(true))
	_add_button("Főmenü", _to_main_menu)
	_add_button("Kilépés", func() -> void:
		# Pihenő közben (egyjátékos) a futás elmentődik, és a főmenüből folytatható.
		if GameState.on_break and get_parent().name != "Dungeon" and not Profiles.multiplayer:
			RunSave.save(get_tree().get_first_node_in_group("player"))
		else:
			_record_run()
		get_tree().quit())
	if GameState.on_break and get_parent().name != "Dungeon" and not Profiles.multiplayer:
		var saved := UiStyle.label("Pihenő közben a futás elmentődik: a Folytatással innen folytathatod.", 16,
			MenuStyle.PARCHMENT)
		saved.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_buttons.add_child(saved)

	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.closed.connect(_show_settings.bind(false))
	stack.add_child(_settings)


func _add_button(text: String, action: Callable) -> Button:
	var button := MenuStyle.button(text)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(action)
	_buttons.add_child(button)
	return button


func open() -> void:
	_show_settings(false)
	visible = true
	_buttons.get_child(0).grab_focus()


func close() -> void:
	visible = false


## Esc: ha a beállítások látszanak, csak oda lép vissza (igaz = lekezelte).
func handle_escape() -> bool:
	if _settings.visible:
		_show_settings(false)
		return true
	return false


func _show_settings(open_settings: bool) -> void:
	_settings.visible = open_settings
	_buttons.visible = not open_settings
	if not open_settings and visible:
		_settings_button.grab_focus()


func _resume() -> void:
	get_tree().current_scene.get_node("Menus").call("close_current")


## A félbehagyott futás is bekerül az eredmények közé, és ha a kazamatából lépsz ki,
## a pénzed 40%-a a táborba kerül.
func _record_run() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if GameState.tutorial:
		GameState.tutorial = false
		return
	# A táborban csak pihenő közben van futás (amit így feladsz).
	if get_parent().name != "Dungeon" and not GameState.on_break:
		return
	Records.submit_run(player)
	if player:
		Progress.rescue_gold(int(player.get("gold")) + GameState.break_gold_left, QUIT_GOLD_RATIO)


func _to_camp() -> void:
	_record_run()
	RunSave.clear()
	GameState.reset()
	GamePause.set_paused(get_tree(), false)
	get_tree().change_scene_to_file(CAMP)


## Pihenő közben (egyjátékos) a főmenübe lépve a futás elmentődik, és később folytatható (RunSave);
## egyébként a futás itt ér véget.
func _to_main_menu() -> void:
	if GameState.on_break and get_parent().name != "Dungeon" and not Profiles.multiplayer:
		RunSave.save(get_tree().get_first_node_in_group("player"))
	else:
		_record_run()
		RunSave.clear()
	GameState.reset()
	GamePause.set_paused(get_tree(), false)
	get_tree().change_scene_to_file(MAIN_MENU)
