class_name MultiplayerPanel
extends PanelContainer
## Többjátékos mód a főmenüben (lásd NetLobby):
##   választás  – "Váró készítése" / "Csatlakozás váróhoz"
##   név        – ha a beállításokban nincs fix név, előbb megkérdezi
##   kód        – csatlakozáskor a 6 jegyű meghívókód
##   váró       – a kód, a játékosok (legfeljebb 4, pipa = készen áll), a gazdánál "Indítás",
##                a többieknél "Készen állok"
## Ha az ablak bezárul (Vissza / Esc), a váróból is kilép.

signal closed

var _lobby: NetLobby
var _box: VBoxContainer
## "choose" | "name" | "code" | "wait" | "lobby"
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
	_lobby.failed.connect(func(reason: String) -> void:
		_error = reason
		_show("code" if _intent == "join" else "choose"))
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
	elif _lobby.state in ["preparing", "searching", "connecting"]:
		_show("wait")


func _show(step: String) -> void:
	_step = step
	# A régi tartalom azonnal rejtve (a rejtett elem nem számít bele a méretbe), és a keret
	# a reset_size()-zal az új tartalomra zsugorodik (különben egyre nő, és kilóg a képből).
	for child in _box.get_children():
		child.visible = false
		child.queue_free()
	_title("Többjátékos")
	match step:
		"choose":
			_text("Legfeljebb %d kalandor együtt. Készíts egy várót, vagy csatlakozz egy barátod " % NetSession.MAX_PLAYERS \
				+ "várójához a meghívókódjával (ugyanazon a hálózaton).")
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
		"code":
			_text("Írd be a váró 6 jegyű meghívókódját:")
			_input = _line_edit("123456", NetSession.CODE_DIGITS)
			_input.text_submitted.connect(func(_submitted: String) -> void: _submit_code())
			_add_error()
			_button("Csatlakozás", _submit_code)
			_button("Vissza", func() -> void: _show("choose"))
		"wait":
			var waiting := {"preparing": "Váró készítése...", "searching": "A váró keresése a hálózaton...",
				"connecting": "Csatlakozás..."}
			_text(waiting.get(_lobby.state, "..."), 22)
			_button("Mégse", func() -> void:
				_lobby.leave()
				_show("choose"))
		"lobby":
			_build_lobby()
	reset_size()
	if _input != null and is_instance_valid(_input) and step in ["name", "code"]:
		_input.grab_focus.call_deferred()


func _build_lobby() -> void:
	var host := _lobby.is_host()
	var code_row := HBoxContainer.new()
	code_row.alignment = BoxContainer.ALIGNMENT_CENTER
	code_row.add_theme_constant_override("separation", 14)
	_box.add_child(code_row)
	code_row.add_child(UiStyle.label("Meghívókód:", 22, MenuStyle.PARCHMENT))
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
		row.add_theme_stylebox_override("panel", UiStyle.plain_panel())
		row.custom_minimum_size = Vector2(440, 38)
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
	if host:
		var start := _button("Indítás", _lobby.start)
		start.disabled = not _lobby.everyone_ready()
		if start.disabled:
			_text("Indítás, ha mindenki készen áll.", 15)
	else:
		var me: Dictionary = _lobby.players.get(_lobby.my_id(), {})
		var ready := bool(me.get("ready", false))
		_button("Mégsem állok készen" if ready else "Készen állok", func() -> void: _lobby.set_ready(not ready))
	_button("Kilépés a váróból", func() -> void:
		_lobby.leave()
		_show("choose"))


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
		_show("code")


func _submit_code() -> void:
	var value := _input.text.strip_edges()
	if not NetSession.is_valid_code(value):
		_error = "A kód 6 számjegyből áll."
		_show("code")
		return
	_error = ""
	_lobby.join(_name, value)
	_show("wait")


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
	button.custom_minimum_size = Vector2(440, 54)
	button.pressed.connect(action)
	_box.add_child(button)
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
