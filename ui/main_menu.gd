extends Control
## Főmenü: "Dungeon" cím, "The Secrets Of The Deep" alcím, gombok
## (Folytatás ha van mentés, Új játék, Eredmények, Beállítások, Kilépés). A háttérben fáklyák, felszálló parázs,
## és egy dungeon-padlón álló lovag néhány szörnnyel.

## Az "Új játék" a táborba visz; onnan a lépcsőn lehet lemenni a kazamatába.
const GAME_SCENE := "res://world/camp.tscn"
const INTRO_SCENE := "res://ui/intro_story.tscn"
const TORCH := preload("res://rooms/decor/torch.tscn")
const FLOOR_TILE := Rect2(16, 64, 16, 16)
const WALL_TILE := Rect2(32, 16, 16, 16)
const WALL_TOP_TILE := Rect2(32, 0, 16, 16)
## A padlócsíkon álló figurák: [sprite-lap téglalap, x eltolás a középtől, tükrözve?]
const FIGURES := [
	[Rect2(128, 100, 16, 28), 0, false],     # lovag (a játékos)
	[Rect2(368, 88, 16, 16), -170, false],   # csontváz
	[Rect2(368, 177, 16, 23), -260, false],  # ork harcos
	[Rect2(128, 36, 16, 28), 190, true],     # íjász
	[Rect2(16, 428, 32, 36), 300, true],     # nagy démon
]
const TILE_SCALE := 4.0

var _buttons: VBoxContainer
var _settings: SettingsPanel
var _records: RecordsPanel
var _new_game_button: Button
var _records_button: Button
var _settings_button: Button
var _multiplayer: MultiplayerPanel
var _multiplayer_button: Button
var _confirm_new_game := false
var _tutorial: TutorialPanel
var _tutorial_button: Button
var _tutorial_extras: Array = []
## A profilválasztó (jobb alul): Profil 1-3, lásd Profiles.
var _profiles_box: VBoxContainer
## Újdonságok (jobb oldalt, lásd News).
var _news: PanelContainer

const TUTORIAL := "tutorial"
const DUNGEON_SCENE := "res://world/dungeon.tscn"
var _title: Label
## Az alcím és a díszcsík: panel (Eredmények/Beállítások) nyitásakor elrejtjük, hogy ne lógjon bele.
var _subtitle_parts: Array[Control] = []

const RECORDS := "records"
const SETTINGS := "settings"
const MULTIPLAYER := "multiplayer"
## A főgombok: a menüben kicsit alacsonyabbak és szorosabban állnak (6 gomb fér ki a cím alá).
const MENU_BUTTON_SIZE := Vector2(340, 54)


func _ready() -> void:
	# Háttérbetöltés: a tárgyikonok már a főmenüben elkezdenek betöltődni (lásd ResourceWarmer).
	Items.warm_icons()
	# Ha a gyakorlásból jöttünk vissza (bárhogy), annak változásai nem maradnak meg.
	GameState.tutorial = false
	Progress.discard_tutorial_changes()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Indításkor a mentett ablak-beállítás (alapból teljes képernyő); utána az F11-es választás megmarad.
	if not GameState.display_initialized:
		GameState.display_initialized = true
		if Audio.saved_fullscreen():
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	Audio.music("main_menu")
	# A főmenübe érve véget ér a közös játék (a többjátékos ablakból lehet újat kezdeni).
	var lobby := NetLobby.current(get_tree())
	if lobby != null and lobby.state == "playing":
		lobby.leave()
	GameCursor.apply()
	_build_background()
	_build_title()
	_build_buttons()
	_build_settings()
	_build_footer()
	_build_profiles()
	_build_news()
	_buttons.get_child(0).grab_focus()
	# Van-e újabb változat a GitHubon (indításonként egyszer; ha van, magától frissít, lásd Updater).
	add_child(Updater.new())


func _build_background() -> void:
	var background := ColorRect.new()
	background.color = Color(0.06, 0.04, 0.06)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	# A jelenet (fal, padló, figurák, fáklyák) egy Node2D-ben, a képernyő alján középen.
	var scene := Node2D.new()
	add_child(scene)
	var screen := get_viewport_rect().size
	scene.position = Vector2(screen.x / 2.0, screen.y - 40)
	resized.connect(func() -> void: scene.position = Vector2(size.x / 2.0, size.y - 40))

	var tile := 16.0 * TILE_SCALE
	for i in range(-12, 13):
		_tile_sprite(scene, FLOOR_TILE, Vector2(i * tile, 0))
		_tile_sprite(scene, WALL_TILE, Vector2(i * tile, -tile * 1.5))
		_tile_sprite(scene, WALL_TOP_TILE, Vector2(i * tile, -tile * 2.5))
	for figure in FIGURES:
		var rect: Rect2 = figure[0]
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = SpriteSheet.character_frames(rect, true)
		sprite.scale = Vector2.ONE * 3.0
		sprite.offset.y = -rect.size.y / 2.0
		sprite.position = Vector2(figure[1], -tile * 0.2)
		sprite.flip_h = figure[2]
		sprite.play("idle")
		sprite.frame = randi() % 4
		scene.add_child(sprite)
	for x in [-420, 420]:
		var torch: Node2D = TORCH.instantiate()
		torch.scale = Vector2(2.2, 2.2)
		torch.position = Vector2(x, -tile * 1.6)
		torch.z_index = 0
		scene.add_child(torch)

	# Felszálló parázs.
	var embers := CPUParticles2D.new()
	embers.amount = 60
	embers.lifetime = 7.0
	embers.preprocess = 7.0
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(700, 10)
	embers.direction = Vector2(0, -1)
	embers.spread = 20.0
	embers.gravity = Vector2(0, -12)
	embers.initial_velocity_min = 20.0
	embers.initial_velocity_max = 55.0
	embers.scale_amount_min = 2.0
	embers.scale_amount_max = 4.0
	embers.color = Color(1, 0.55, 0.2, 0.9)
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 0.7, 0.3, 1))
	fade.set_color(1, Color(1, 0.3, 0.1, 0))
	embers.color_ramp = fade
	embers.position = Vector2(0, -20)
	scene.add_child(embers)


## Horgony (0..1) + eltolás + minimális méret: így az ablak átméretezésekor is a helyén marad.
func _place(control: Control, anchor: Vector2, offset: Vector2, min_size: Vector2) -> void:
	control.anchor_left = anchor.x
	control.anchor_right = anchor.x
	control.anchor_top = anchor.y
	control.anchor_bottom = anchor.y
	control.offset_left = offset.x
	control.offset_top = offset.y
	control.offset_right = offset.x + min_size.x
	control.offset_bottom = offset.y + min_size.y
	control.custom_minimum_size = min_size


func _tile_sprite(parent: Node, region: Rect2, at: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = SpriteSheet.region(region)
	sprite.scale = Vector2.ONE * TILE_SCALE
	sprite.position = at
	sprite.modulate = Color(0.55, 0.5, 0.55)
	parent.add_child(sprite)


func _build_title() -> void:
	var box := VBoxContainer.new()
	_place(box, Vector2(0.5, 0.0), Vector2(-400, 40), Vector2(800, 0))
	box.add_theme_constant_override("separation", -8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	_title = MenuStyle.title_label("Dungeon", 144, MenuStyle.GOLD)
	box.add_child(_title)
	var subtitle := MenuStyle.title_label("The Secrets Of The Deep", 48, MenuStyle.PARCHMENT)
	box.add_child(subtitle)
	_subtitle_parts.append(subtitle)
	var divider := HBoxContainer.new()
	divider.alignment = BoxContainer.ALIGNMENT_CENTER
	divider.add_theme_constant_override("separation", 0)
	for path in ["res://assets/menu/divider_left.png", "res://assets/menu/divider_right.png"]:
		var part := TextureRect.new()
		part.texture = load(path)
		part.custom_minimum_size = Vector2(96, 22) * 2.5
		part.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		part.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		divider.add_child(part)
	box.add_child(divider)
	_subtitle_parts.append(divider)
	# A cím lassan "izzik".
	var glow := create_tween().set_loops()
	glow.tween_property(_title, "modulate", Color(1.25, 1.15, 1.0), 1.6).set_trans(Tween.TRANS_SINE)
	glow.tween_property(_title, "modulate", Color.WHITE, 1.6).set_trans(Tween.TRANS_SINE)


func _build_buttons() -> void:
	_buttons = VBoxContainer.new()
	_place(_buttons, Vector2(0.5, 0.5), Vector2(-MenuStyle.BUTTON_SIZE.x / 2.0, -98), Vector2(MenuStyle.BUTTON_SIZE.x, 0))
	_buttons.add_theme_constant_override("separation", 6)
	add_child(_buttons)
	# Ha van mentés: Folytatás (a táborba, a mentett haladással).
	if Progress.has_save():
		var resume := MenuStyle.button("Folytatás")
		# Félbehagyott futás (a főellenség utáni pihenőnél léptél ki): onnan folytatódik.
		if RunSave.exists():
			resume.text = "Folytatás (futás)"
			resume.tooltip_text = "A félbehagyott futás: %s" % RunSave.summary()
		resume.pressed.connect(_on_continue)
		_buttons.add_child(resume)
	_new_game_button = MenuStyle.button("Új játék")
	_new_game_button.pressed.connect(_on_new_game)
	_buttons.add_child(_new_game_button)
	# Többjátékos mód: egyelőre "hamarosan" (a gomb jobb felső sarkán egy kis szalag).
	_multiplayer_button = MenuStyle.button("Többjátékos")
	_multiplayer_button.pressed.connect(_show_panel.bind(MULTIPLAYER))
	_buttons.add_child(_multiplayer_button)
	var badge := Label.new()
	badge.text = "HAMAROSAN"
	badge.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	badge.add_theme_font_size_override("font_size", 13)
	badge.add_theme_color_override("font_color", Color(1, 0.62, 0.35))
	badge.add_theme_color_override("font_outline_color", MenuStyle.SHADOW)
	badge.add_theme_constant_override("outline_size", 4)
	badge.rotation = 0.18
	badge.position = Vector2(MENU_BUTTON_SIZE.x - 96, -4)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_multiplayer_button.add_child(badge)
	_records_button = MenuStyle.button("Eredmények")
	_records_button.pressed.connect(_show_panel.bind(RECORDS))
	_buttons.add_child(_records_button)
	_settings_button = MenuStyle.button("Beállítások")
	_settings_button.pressed.connect(_show_panel.bind(SETTINGS))
	_buttons.add_child(_settings_button)
	var quit := MenuStyle.button("Kilépés")
	quit.pressed.connect(func() -> void: get_tree().quit())
	_buttons.add_child(quit)
	for button in _buttons.get_children():
		(button as Button).custom_minimum_size = MENU_BUTTON_SIZE


func _build_settings() -> void:
	_settings = SettingsPanel.new()
	_place(_settings, Vector2(0.5, 0.5), Vector2(-240, -150), Vector2(480, 0))
	_settings.visible = false
	_settings.closed.connect(_show_panel.bind(""))
	add_child(_settings)
	_records = RecordsPanel.new()
	_place(_records, Vector2(0.5, 0.5), Vector2(-440, -175), Vector2(880, 0))
	_records.visible = false
	_records.closed.connect(_show_panel.bind(""))
	add_child(_records)
	_multiplayer = MultiplayerPanel.new()
	_place(_multiplayer, Vector2(0.5, 0.5), Vector2(-260, -205), Vector2(520, 0))
	_multiplayer.visible = false
	_multiplayer.closed.connect(_show_panel.bind(""))
	add_child(_multiplayer)
	_tutorial = TutorialPanel.new()
	_place(_tutorial, Vector2(0.5, 0.5), Vector2(-470, -330), Vector2(940, 0))
	_tutorial.visible = false
	_tutorial.closed.connect(_show_panel.bind(""))
	_tutorial.start_requested.connect(_start_tutorial)
	add_child(_tutorial)
	# A Tutorial gomb a főgomboktól kicsit oldalra (bal alul), saját "könyv" kerettel.
	_tutorial_button = MenuStyle.button("Tutorial")
	_tutorial_button.custom_minimum_size = Vector2(240, 60)
	_place(_tutorial_button, Vector2(0.0, 1.0), Vector2(40, -110), Vector2(240, 60))
	_tutorial_button.pressed.connect(_show_panel.bind(TUTORIAL))
	add_child(_tutorial_button)
	var tag := Label.new()
	tag.text = "Új vagy? Kezdd itt!"
	tag.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	tag.add_theme_font_size_override("font_size", 16)
	tag.add_theme_color_override("font_color", MenuStyle.PARCHMENT)
	tag.add_theme_color_override("font_outline_color", MenuStyle.SHADOW)
	tag.add_theme_constant_override("outline_size", 5)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(tag, Vector2(0.0, 1.0), Vector2(40, -138), Vector2(240, 24))
	add_child(tag)
	_tutorial_extras = [_tutorial_button, tag]
	var bob := tag.create_tween().set_loops()
	bob.tween_property(tag, "modulate:a", 0.45, 0.9).set_trans(Tween.TRANS_SINE)
	bob.tween_property(tag, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)


func _build_footer() -> void:
	var footer := Label.new()
	# A változat a GitHub-commit rövid azonosítója (közös játékhoz mindenkinél ugyanaz kell).
	var version := Updater.current_version()
	footer.text = "F11 — teljes képernyő   ·   v0.1" + ("  (%s)" % version if not version.is_empty() else "")
	footer.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Color(0.6, 0.52, 0.45, 0.8))
	_place(footer, Vector2(1.0, 1.0), Vector2(-260, -26), Vector2(240, 20))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(footer)


## Újdonságok a jobb oldalon (a cím alatt, a profilválasztó fölött): görgethető lista, a legújabb felül (News).
func _build_news() -> void:
	_news = PanelContainer.new()
	_news.add_theme_stylebox_override("panel", MenuStyle.box(MenuStyle.MENU_PANEL, 18, 20))
	_place(_news, Vector2(1.0, 0.5), Vector2(-410, -96), Vector2(390, 300))
	add_child(_news)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_news.add_child(box)
	box.add_child(MenuStyle.title_label("Újdonságok", 30, MenuStyle.GOLD))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(350, 230)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.custom_minimum_size.x = 340
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_color_override("default_color", MenuStyle.PARCHMENT)
	text.add_theme_font_size_override("normal_font_size", 14)
	text.add_theme_font_size_override("bold_font_size", 15)
	text.text = News.bbcode()
	scroll.add_child(text)


## Profilválasztó a jobb alsó sarokban: ◄ előző / ► következő profil, középen a szám és egy
## rövid összefoglaló. Lapozáskor az a mentés töltődik be, és a menü újraépül (Folytatás / Új játék).
func _build_profiles() -> void:
	_profiles_box = VBoxContainer.new()
	_profiles_box.add_theme_constant_override("separation", 4)
	_place(_profiles_box, Vector2(1.0, 1.0), Vector2(-380, -140), Vector2(360, 0))
	add_child(_profiles_box)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 8)
	_profiles_box.add_child(row)
	row.add_child(_profile_arrow("◄", -1))
	var info := VBoxContainer.new()
	info.custom_minimum_size.x = 210
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 0)
	row.add_child(info)
	info.add_child(_profile_label("Profil %d / %d" % [Profiles.current(), Profiles.COUNT], 20, MenuStyle.GOLD))
	info.add_child(_profile_label(Profiles.summary(Profiles.current()), 14, MenuStyle.PARCHMENT))
	row.add_child(_profile_arrow("►", 1))


func _profile_arrow(text: String, step: int) -> Button:
	var button := MenuStyle.button(text)
	button.custom_minimum_size = Vector2(56, 56)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 20)
	button.tooltip_text = "Előző profil" if step < 0 else "Következő profil"
	button.pressed.connect(func() -> void:
		_select_profile(wrapi(Profiles.current() - 1 + step, 0, Profiles.COUNT) + 1))
	return button


func _profile_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", MenuStyle.SHADOW)
	label.add_theme_constant_override("outline_size", 5)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _select_profile(profile: int) -> void:
	if profile == Profiles.current():
		return
	Audio.play("ui_click")
	Profiles.select(profile)
	get_tree().reload_current_scene()


## Egy panel (Eredmények / Beállítások) megnyitása a gombok helyén; "" = vissza a gombokhoz.
func _show_panel(panel: String) -> void:
	var previous := RECORDS if _records.visible else (TUTORIAL if _tutorial.visible 		else (MULTIPLAYER if _multiplayer.visible else SETTINGS))
	_records.visible = panel == RECORDS
	_multiplayer.visible = panel == MULTIPLAYER
	_settings.visible = panel == SETTINGS
	_tutorial.visible = panel == TUTORIAL
	_buttons.visible = panel.is_empty()
	for part in _subtitle_parts + _tutorial_extras:
		part.modulate.a = 1.0 if panel.is_empty() else 0.0
	_tutorial_button.visible = panel.is_empty()
	_profiles_box.visible = panel.is_empty()
	_news.visible = panel.is_empty()
	# A nagy Tutorial ablak a címig ér: ilyenkor a cím is eltűnik.
	_title.get_parent().modulate.a = 0.0 if panel == TUTORIAL else 1.0
	if panel.is_empty():
		var focus_target: Button = _records_button if previous == RECORDS else (_tutorial_button if previous == TUTORIAL 			else (_multiplayer_button if previous == MULTIPLAYER else _settings_button))
		focus_target.grab_focus()


## Gyakorló pálya: külön pálya a jelenlegi karakterrel, semmi nem mentődik belőle.
func _start_tutorial() -> void:
	Progress.begin_tutorial()
	GameState.reset()
	GameState.tutorial = true
	get_tree().change_scene_to_file(DUNGEON_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_F11 or (key.physical_keycode == KEY_ENTER and key.alt_pressed):
		Audio.toggle_fullscreen()
		get_viewport().set_input_as_handled()
	elif key.physical_keycode == KEY_ESCAPE and not _buttons.visible:
		_show_panel("")
		get_viewport().set_input_as_handled()

func _on_continue() -> void:
	Progress.load_game(true)
	GameState.reset()
	# Ha a főellenség utáni pihenőnél léptél ki, a futás onnan folytatódik (minden tárgyaddal).
	if RunSave.exists():
		RunSave.restore()
	get_tree().change_scene_to_file(GAME_SCENE)


## Új játék: ha van mentés, előbb rákérdez (második kattintásra törli a tábori haladást).
func _on_new_game() -> void:
	if Progress.has_save() and not _confirm_new_game:
		_confirm_new_game = true
		_new_game_button.text = "Biztos? Mentés törlése"
		return
	Progress.reset_game()
	RunSave.clear()
	GameState.reset()
	# Előbb a bevezető történet (Space hosszan: kihagyás), utána a tábor.
	get_tree().change_scene_to_file(INTRO_SCENE)
