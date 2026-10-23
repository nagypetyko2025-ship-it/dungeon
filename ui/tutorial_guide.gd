class_name TutorialGuide
extends CanvasLayer
## Gyakorló pálya (tutorial) vezetője: a képernyő tetején egy pergamen mutatja az aktuális
## feladatot, és magától továbblép, ha megcsináltad. Végigvezet a mozgáson, a harcon, a
## térképen, a szintlépésen, a ládán, a felszerelésen, a karakterlapon, a bolton, a
## tárgylifton, (íjászként a suhanáson,) a szünet menün és a lépcsőn. A végén egy
## összefoglaló mondja el, ami a pályán nem fér bele (tábor, főellenségek, karakterek...).
## A Dungeon hozza létre, ha GameState.tutorial igaz.
## Hülyebiztos: minden mozdulatot megjegyez, amikor csak megtörténik (_seen), így ha valamit
## előre megcsinálsz (pl. kinyitod a ládát, mielőtt az lenne a feladat), az a lépés később
## azonnal teljesül, nem akad el. Ha egy lépés már kész, a "start" része sem fut le.

const MAIN_MENU := "res://ui/main_menu.tscn"
const XP_ORB := preload("res://pickups/xp_orb.tscn")
const PANEL_WIDTH := 720.0
const DONE_COLOR := Color(0.24, 0.5, 0.2)

var _dungeon: Node
var _player: Node2D
var _rooms: Array = []
var _steps: Array[Dictionary] = []
var _index := 0
var _advancing := false
var _start_position := Vector2.ZERO
var _was_in_shop := false
var _potions_at_step := 0
## Ami már megtörtént (bármikor): mozgás, támadás, térkép, láda, karakterlap, bolt, lift...
var _seen := {}
var _last_potions := 0
var _potion_step_started := false

var _panel: PanelContainer
var _counter: Label
var _title: Label
var _text: RichTextLabel
var _finish_layer: Control


func setup(dungeon: Node, rooms: Array) -> void:
	_dungeon = dungeon
	_rooms = rooms
	_player = dungeon.get_node("Entities/Player")
	_start_position = _player.global_position
	# Gyakorlás: semmi nem kerül az eredmények közé, és a tábori arany sem nő.
	GameState.run_recorded = true
	GameState.gold_rescued = true
	_build_steps()
	_build_ui()
	_show_step()


func _room(i: int) -> Room:
	return _rooms[i]


func _build_steps() -> void:
	var archer: bool = Characters.data(Progress.character).get("dash", false)
	var attack_text := "Kattints a bal egérgombbal: a karaktered az egér irányába támad. " \
		+ ("Az íjászod nyilat lő (egyszerre többet is)." if archer else "A kard egyenesen előre döf; a Hatótáv stat azt adja meg, milyen messzire.")
	_steps = [
		{"title": "Mozgás", "text": "Üdv a Mélységben! Mozogj a [b]W A S D[/b] gombokkal.",
			"done": func() -> bool: return _seen.has("moved")},
		{"title": "Támadás", "text": attack_text,
			"done": func() -> bool: return _seen.has("attack")},
		{"title": "Térkép", "text": "Jobb fent a kis térkép. Nyomd meg az [b]M[/b] gombot a nagy térképhez (újra M: bezárás). "
			+ "A piros szobák még tele vannak szörnnyel, a zöldek tiszták, a narancs a bolt, a háromszög a lépcső.",
			"done": func() -> bool: return _seen.has("map")},
		{"title": "Harc", "text": "Menj át a jobb oldali szobába! Amint belépsz, az ajtók bezárulnak, és csak akkor nyílnak ki, "
			+ "ha minden szörnyet legyőztél. Kerüld a tüskéket, és figyeld az életerődet bal fent.",
			"done": func() -> bool: return _room(1).visited and _room(1).is_cleared()},
		{"title": "Tapasztalat", "text": "A szörnyekből zöld XP-gömbök esnek; szedd fel őket (magukhoz vonzódnak). "
			+ "Ha betelik az alsó XP-csík, szintet lépsz: válassz egy fejlesztést a 3 kártya közül (1/2/3 vagy kattintás). "
			+ "Aranyért újradobhatod a kártyákat (R).",
			"start": _spawn_xp,
			"done": func() -> bool: return _player.get_node("Experience").level >= 2 and not _dungeon.get_node("LevelUp").visible},
		{"title": "Láda", "text": "A kitisztított szobában megjelent egy láda. Érintsd meg: aranyat dob, néha tárgyat is.",
			"done": func() -> bool: return _seen.has("chest")},
		{"title": "Felszerelés", "text": "Kaptál egy sisakot. Nyisd meg a felszerelést az [b]I[/b] gombbal, és húzd a sisakot a "
			+ "helyére (vagy jobb klikk rá). Az egeret egy tárgy fölé víve látod a statjait és az összehasonlítást.",
			"start": _give_helmet,
			"done": func() -> bool: return _player.get_node("Inventory").equipment["helmet"] != null},
		{"title": "Karakterlap", "text": "Csukd be (I), és nyomd meg a [b]Tab[/b] gombot: itt látod az összes statodat "
			+ "(sebzés, élet, védelem, kikerülés, kritikus esély, hatótáv...) és a fegyvered sebzésképletét.",
			"done": func() -> bool: return _seen.has("stats")},
		{"title": "Bolt", "text": "Csukd be (Tab), és menj tovább jobbra. Ebben a szobában a falban egy bolt van: "
			+ "egyszerűen sétálj neki az ajtajának, és bemész.",
			"done": func() -> bool: return _seen.has("shop_in")},
		{"title": "Vásárlás", "text": "A gyanús boltos árul: állj egy tárgy elé, és ha van elég aranyad, E-vel megveszed. "
			+ "A pultnál E-vel el is adhatsz, [b]F[/b]-fel pedig HP bájitalt vehetsz tőle (60 arany, boltonként 2 db). "
			+ "A szoba közepén lévő karral új árut kérhetsz. Ha körülnéztél, gyere ki a lenti ajtón.",
			"done": func() -> bool: return _seen.has("shop_out")},
		{"title": "HP bájital", "text": "Alul, az XP-csík fölött a [b]gyorstár[/b]: az első helyén vannak a HP bájitalaid "
			+ "(a szám mutatja, mennyi van nálad). A boltos adott egyet kóstolónak, és közben megsérültél. "
			+ "Nyomd meg az [b]1[/b]-es gombot: a bájital az elvesztett életed felét tölti vissza. "
			+ "Minden főellenség után is kapsz egyet.",
			"start": _start_potion_step,
			"done": func() -> bool: return _seen.has("potion")},
		{"title": "Tárgylift", "text": "A bolt mellett a falban a [b]tárgylift[/b]: emeletenként egy tárgyat felküldhetsz vele a "
			+ "táborba (a tábori ládába kerül, megmarad). Menj oda, és nyomd meg az [b]E[/b] gombot. "
			+ "(Gyakorláskor nem küld fel semmit.)",
			"done": func() -> bool: return _seen.has("lift")},
	]
	if archer:
		_steps.append({"title": "Suhanás", "text": "Íjászként a [b]Ctrl[/b] gombbal a kurzor felé suhansz: átmész a "
			+ "szörnyeken, és közben nem sebezhetnek meg. 5 másodpercenként használhatod (alul látod, mikor kész).",
			"done": func() -> bool: return _seen.has("dash")})
	_steps.append_array([
		{"title": "Szünet", "text": "Az [b]Esc[/b] gombbal szünetelteted a játékot: innen állíthatod a hangot és a teljes "
			+ "képernyőt, vagy feladhatod a futást (ilyenkor a pénzed 40%-a a táborba kerül). Nyomd meg az Esc-et.",
			"done": func() -> bool: return _seen.has("pause")},
		{"title": "Az utolsó szoba", "text": "Folytasd (Esc), és menj a jobb szélső szobába. A lépcsőn rács van, "
			+ "amíg a szoba szörnyei élnek: győzd le mindet!",
			"done": func() -> bool: return _room(3).visited and _room(3).is_cleared()},
		{"title": "Lépcső", "text": "A rács eltűnt. Lépj a lépcsőre: az igazi játékban ez visz a következő, egyre nehezebb emeletre.",
			"done": func() -> bool: return false},
	])


## A bájital-lépés: egy ajándék bájital, és az élet a felére csökken, hogy legyen mit visszatölteni.
func _start_potion_step() -> void:
	GameState.potions += 1
	_potions_at_step = GameState.potions
	_last_potions = GameState.potions
	_potion_step_started = true
	var health: Health = _player.get_node("Health")
	health.current = maxi(1, health.max_health / 2)
	health.changed.emit(health.current, health.max_health)


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return
	_remember()
	if _advancing or _index >= _steps.size():
		return
	var done: Callable = _steps[_index]["done"]
	if done.call():
		_advance()


## Minden képkockában feljegyzi, ami épp történik (akármelyik lépésnél tartasz).
func _remember() -> void:
	if _player.global_position.distance_to(_start_position) > 140.0:
		_seen["moved"] = true
	if Input.is_action_pressed("attack"):
		_seen["attack"] = true
	if _dungeon.get_node("HUD/Minimap").get("_expanded") == true:
		_seen["map"] = true
	if GameState.chests_opened > 0:
		_seen["chest"] = true
	if _dungeon.get_node("StatsScreen").visible:
		_seen["stats"] = true
	if _in_shop():
		_was_in_shop = true
		_seen["shop_in"] = true
	elif _was_in_shop:
		_seen["shop_out"] = true
	var lift := _dungeon.get_node_or_null("ItemLiftPanel")
	if lift != null and lift.visible:
		_seen["lift"] = true
	if Characters.data(Progress.character).get("dash", false) and _player.call("dash_cooldown_ratio") > 0.0:
		_seen["dash"] = true
	if _dungeon.get_node("PauseMenu").visible:
		_seen["pause"] = true
	# A bájital a saját lépésétől számít (akkor kapod az ajándékot).
	if _potion_step_started and GameState.potions < _last_potions:
		_seen["potion"] = true
	_last_potions = GameState.potions


func _advance() -> void:
	_advancing = true
	Audio.play("ui_click")
	_title.text = "✔ " + _steps[_index]["title"]
	_title.add_theme_color_override("font_color", DONE_COLOR)
	await get_tree().create_timer(0.9, true).timeout
	_index += 1
	_advancing = false
	_show_step()


func _show_step() -> void:
	if _index >= _steps.size():
		return
	var step: Dictionary = _steps[_index]
	_counter.text = "Gyakorlás  ·  %d / %d" % [_index + 1, _steps.size()]
	_title.text = step["title"]
	_title.add_theme_color_override("font_color", UiStyle.INK)
	_text.text = step["text"]
	# Ha már előre megcsináltad, nem kell újra előkészíteni (pl. XP-gömbök, ajándék sisak).
	var already: bool = (step["done"] as Callable).call()
	if step.has("start") and not already:
		(step["start"] as Callable).call()
	_panel.modulate.a = 0.0
	create_tween().tween_property(_panel, "modulate:a", 1.0, 0.3)


func _in_shop() -> bool:
	return _player.global_position.y > (ShopInterior.RECT.position.y - 1) * Room.TILE


## Pont annyi XP-gömb a játékos köré, hogy szintet lépjen.
func _spawn_xp() -> void:
	var experience: Experience = _player.get_node("Experience")
	var total := experience.needed() - experience.xp
	var count := 5
	for i in count:
		var orb = XP_ORB.instantiate()
		orb.value = total / count + (total % count if i == 0 else 0)
		orb.position = _player.position + Vector2.from_angle(TAU * i / count) * 90.0
		_player.get_parent().add_child(orb)


func _give_helmet() -> void:
	var inventory: Inventory = _player.get_node("Inventory")
	if inventory.equipment["helmet"] == null:
		inventory.add_item(Items.create("helmet_leather"))


# ---------------------------------------------------------------- vége

## A lépcsőre lépve: összefoglaló, amit a pályán nem lehetett megmutatni.
func finish() -> void:
	if _finish_layer != null:
		return
	Audio.play("level_up")
	_panel.visible = false
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	_finish_layer = Control.new()
	_finish_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_finish_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_finish_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_finish_layer.add_child(center)
	var window := PanelContainer.new()
	window.add_theme_stylebox_override("panel", UiStyle.decorated_panel())
	window.custom_minimum_size = Vector2(900, 0)
	center.add_child(window)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	window.add_child(box)
	box.add_child(UiStyle.title_bar("Gyakorlás kész!"))
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.add_theme_color_override("default_color", UiStyle.INK_LIGHT)
	text.add_theme_font_size_override("normal_font_size", 16)
	text.text = TutorialManual.SUMMARY
	box.add_child(text)
	var button := MenuStyle.button("Vissza a főmenübe")
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(leave)
	box.add_child(button)
	button.grab_focus()


## Kilépés a gyakorlásból a főmenübe (a halálképernyő és a szünet menü is ezt hívja).
static func leave_tutorial(tree: SceneTree) -> void:
	GameState.tutorial = false
	GameState.reset()
	tree.paused = false
	tree.change_scene_to_file(MAIN_MENU)


func leave() -> void:
	leave_tutorial(get_tree())


# ---------------------------------------------------------------- UI

func _build_ui() -> void:
	layer = 7
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_panel.offset_left = -PANEL_WIDTH / 2.0
	_panel.offset_right = PANEL_WIDTH / 2.0
	_panel.offset_top = 70
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(box)
	_counter = UiStyle.label("", 13, UiStyle.INK_LIGHT)
	box.add_child(_counter)
	_title = UiStyle.label("", 22, UiStyle.INK)
	box.add_child(_title)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.custom_minimum_size.x = PANEL_WIDTH - 40
	_text.add_theme_color_override("default_color", UiStyle.INK_LIGHT)
	_text.add_theme_font_size_override("normal_font_size", 16)
	_text.add_theme_font_size_override("bold_font_size", 16)
	box.add_child(_text)
