class_name MultiplayerPanel
extends PanelContainer
## Többjátékos mód a főmenüben (lásd NetLobby):
##   választás  – "Váró készítése" / "Csatlakozás váróhoz"
##   név        – ha a beállításokban nincs fix név, előbb megkérdezi
##   lista      – csatlakozáskor a helyi hálózaton talált várók (kódot nem kell beírni)
##   váró       – a kód, a játékosok (legfeljebb 4, pipa = készen áll), a gazdánál "Indítás",
##                a többieknél "Készen állok"
## Ha az ablak bezárul (Vissza / Esc), a váróból is kilép.

signal closed

const MAX_LISTED_GAMES := 5

var _lobby: NetLobby
var _box: VBoxContainer
## "choose" | "name" | "browse" | "wait" | "lobby"
var _step := "choose"
## Mit csinál a név után: "create" | "join"
var _intent := ""
var _name := ""
var _error := ""
var _input: LineEdit


func _ready() -> void:
	add_theme_stylebox_override("panel", MenuStyle.box(MenuStyle.MENU_PANEL, 18, 34))
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 12)
	add_child(_box)
	_lobby = NetLobby.get_or_create(get_tree())
	_lobby.lobby_changed.connect(_on_lobby_changed)
	# Ha nem sikerült csatlakozni (vagy a gazda bezárta a várót), vissza a listához.
	_lobby.failed.connect(func(reason: String) -> void:
		_error = reason
		if visible and _intent == "join":
			_browse()
		else:
			_show("choose"))
	_lobby.games_changed.connect(func() -> void:
		if visible and _step == "browse":
			_show("browse"))
	visibility_changed.connect(func() -> void:
		if visible:
			_error = ""
			_show("choose")
		elif _lobby.state != "playing":
			# Bezáráskor nem marad nálunk a fókusz (egy elrejtett mezőn ragadva elnyelné a billentyűket),
			# és a hálózatot csak a bezárás után zárjuk le (nem a gombnyomás közben).
			var focused := get_viewport().gui_get_focus_owner()
			if focused != null and is_ancestor_of(focused):
				focused.release_focus()
			_lobby.leave.call_deferred())
	_show("choose")


func _on_lobby_changed() -> void:
	if not visible:
		return
	if _lobby.state in ["lobby"]:
		_show("lobby")
	elif _lobby.state in ["preparing", "connecting"]:
		_show("wait")


func _show(step: String) -> void:
	_step = step
	# A régi tartalom azonnal rejtve (a rejtett elem nem számít bele a méretbe), és a keret
	# a reset_size()-zal az új tartalomra zsugorodik (különben egyre nő, és kilóg a képből).
	for child in _box.get_children():
		child.visible = false
		child.queue_free()
	# A váróban sok minden van (4 sor, 3 gomb): ott tömörebb, hogy a képernyőn elférjen.
	_box.add_theme_constant_override("separation", 8 if step == "lobby" else 12)
	_title("Többjátékos")
	match step:
		"choose":
			_text("Legfeljebb %d kalandor együtt. Készíts egy várót, vagy csatlakozz egy barátod " % NetSession.MAX_PLAYERS \
				+ "várójához (ugyanazon a hálózaton: a játékuk magától megjelenik a listán).")
			_add_error()
			_button("Váró készítése", func() -> void: _begin("create"))
			_button("Csatlakozás váróhoz", func() -> void: _begin("join"))
			_button("Vissza", func() -> void: closed.emit())
		"name":
			_text("Milyen néven ismerjenek a többiek?")
			_input = _line_edit("A neved", NetSession.NAME_MAX_LENGTH)
			_input.text_submitted.connect(func(_submitted: String) -> void: _submit_name())
			_text("(A Beállításokban megadhatsz egy fix nevet, akkor nem kérdezem.)", 15)
			_button("Tovább", _submit_name)
			_button("Vissza", func() -> void: _show("choose"))
		"browse":
			_build_browse()
		"wait":
			var waiting := {"preparing": "Váró készítése...", "connecting": "Csatlakozás..."}
			_text(waiting.get(_lobby.state, "..."), 22)
			_button("Mégse", func() -> void:
				_lobby.leave()
				_show("choose"))
		"lobby":
			_build_lobby()
	reset_size()
	if _input != null and is_instance_valid(_input) and step == "name":
		_input.grab_focus.call_deferred()


## A helyi hálózaton talált várók (a gazda neve, létszám); kattintásra csatlakozik.
func _build_browse() -> void:
	var codes: Array = _lobby.games.keys()
	codes.sort_custom(func(a: String, b: String) -> bool:
		return str(_lobby.games[a]["name"]).naturalnocasecmp_to(str(_lobby.games[b]["name"])) < 0)
	if codes.is_empty():
		_text("Várók keresése a hálózaton...", 22)
		_text("Ha a barátod már készített várót, pár másodpercen belül itt lesz. Ugyanazon a hálózaton (pl. ugyanazon a wifin) legyetek.", 15)
	else:
		_text("Válaszd ki, kinek a várójához csatlakozol:")
	_add_error()
	# Ennél több ritkán van egy hálózaton; így a panel nem lóg ki a képből.
	for game_code: String in codes.slice(0, MAX_LISTED_GAMES):
		var game: Dictionary = _lobby.games[game_code]
		var full := int(game["players"]) >= int(game["max"])
		var label := "%s várója   ·   %d / %d" % [game["name"], game["players"], game["max"]]
		var button := _button(label + ("  (megtelt)" if full else ""), func() -> void:
			_error = ""
			_lobby.join_game(game_code))
		button.disabled = full
	_button("Vissza", func() -> void:
		_lobby.leave()
		_show("choose"))


func _build_lobby() -> void:
	var host := _lobby.is_host()
	var code_row := HBoxContainer.new()
	code_row.alignment = BoxContainer.ALIGNMENT_CENTER
	code_row.add_theme_constant_override("separation", 14)
	_box.add_child(code_row)
	code_row.add_child(UiStyle.label("Váró kódja:", 22, MenuStyle.PARCHMENT))
	var code := MenuStyle.title_label(_lobby.code if not _lobby.code.is_empty() else "······", 44, MenuStyle.GOLD)
	code_row.add_child(code)
	if not host:
		code.text = "csatlakozva"
		code.add_theme_font_size_override("font_size", 28)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	_box.add_child(list)
	var ids: Array = _lobby.players.keys()
	ids.sort()
	for i in NetSession.MAX_PLAYERS:
		var row := PanelContainer.new()
		# Vékonyabb belső margó: így a 4 sor és a gombok is elférnek a képernyőn.
		var style := UiStyle.plain_panel()
		style.content_margin_top = 5
		style.content_margin_bottom = 5
		row.add_theme_stylebox_override("panel", style)
		row.custom_minimum_size = Vector2(440, 32)
		list.add_child(row)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		row.add_child(line)
		if i >= ids.size():
			line.add_child(UiStyle.label("— üres hely —", 18, UiStyle.INK_LIGHT))
			continue
		var id: int = ids[i]
		var player: Dictionary = _lobby.players[id]
		var name_label := UiStyle.label(str(player["name"]) + (" (te)" if id == _lobby.my_id() else ""), 20, UiStyle.INK)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(name_label)
		line.add_child(UiStyle.label(Characters.data(str(player["character"]))["name"], 17, UiStyle.INK_LIGHT))
		var status := "gazda" if id == 1 else ("✔" if player["ready"] else "")
		var mark := UiStyle.label(status, 22 if status == "✔" else 16, Color(0.24, 0.55, 0.2) if status == "✔" else Color(0.6, 0.38, 0.05))
		mark.custom_minimum_size.x = 60
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		line.add_child(mark)
	var leave := func() -> void:
		_lobby.leave()
		_show("choose")
	if host:
		var start := _button("Indítás", _lobby.start)
		start.disabled = not _lobby.everyone_ready()
		if start.disabled:
			_text("Indítás, ha mindenki készen áll.", 15)
		# A profil többjátékos mentése: folytatható, vagy indításkor új közös játék kezdődik.
		# (A mentés és a kilépés egy sorban, hogy a váró elférjen a képernyőn.)
		var has_save := FileAccess.file_exists("user://save_mp_%d.cfg" % Profiles.current())
		if not has_save:
			_lobby.fresh_save = false
			_text("Új közös játék (a %d. profil többjátékos mentése még üres)." % Profiles.current(), 15)
			_button("Kilépés a váróból", leave)
		else:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			_box.add_child(row)
			_half_button("Mentés: ÚJ KEZDÉS" if _lobby.fresh_save else "Mentés: folytatás", func() -> void:
				_lobby.fresh_save = not _lobby.fresh_save
				_show("lobby"), row)
			_half_button("Kilépés", leave, row)
	else:
		var me: Dictionary = _lobby.players.get(_lobby.my_id(), {})
		var ready := bool(me.get("ready", false))
		_button("Mégsem állok készen" if ready else "Készen állok", func() -> void: _lobby.set_ready(not ready))
		_button("Kilépés a váróból", leave)


func _begin(intent: String) -> void:
	_intent = intent
	_error = ""
	_name = NetSession.fixed_name()
	if _name.is_empty():
		_show("name")
	else:
		_after_name()


func _submit_name() -> void:
	var value := NetSession.clean_name(_input.text)
	if value.is_empty():
		_input.placeholder_text = "Adj meg egy nevet!"
		return
	_name = value
	_after_name()


func _after_name() -> void:
	if _intent == "create":
		_lobby.create(_name)
		_show("wait")
	else:
		_browse()


## A várók keresése; ha nem lehet figyelni a hálózatot, vissza a választáshoz a hibával.
func _browse() -> void:
	if _lobby.browse(_name):
		_show("browse")
	else:
		_error = "Nem sikerült figyelni a hálózatot (fut már egy csatlakozó ezen a gépen?)."
		_show("choose")


# ---------------------------------------------------------------- segédek

func _title(text: String) -> void:
	var title := MenuStyle.title_label(text, 40, MenuStyle.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(title)


func _text(text: String, size := 18) -> void:
	var label := UiStyle.label(text, size, MenuStyle.PARCHMENT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 440
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(label)


func _add_error() -> void:
	if _error.is_empty():
		return
	var label := UiStyle.label(_error, 17, Color(1, 0.5, 0.4))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 440
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(label)


func _button(text: String, action: Callable) -> Button:
	var button := MenuStyle.button(text)
	button.custom_minimum_size = Vector2(440, 44 if _step == "lobby" else 54)
	button.pressed.connect(action)
	_box.add_child(button)
	return button


## Fél szélességű gomb egy sorba (a váróban).
func _half_button(text: String, action: Callable, row: HBoxContainer) -> Button:
	var button := MenuStyle.button(text)
	button.custom_minimum_size = Vector2(216, 44)
	button.add_theme_font_size_override("font_size", 20)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	row.add_child(button)
	return button


func _line_edit(placeholder: String, max_length: int) -> LineEdit:
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.max_length = max_length
	edit.custom_minimum_size = Vector2(440, 54)
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	edit.add_theme_font_size_override("font_size", 24)
	_box.add_child(edit)
	return edit
