extends Node
## A teljes képernyős ablakok kezelője: I = felszerelés, Tab = karakter,
## M = térkép, Esc = bezárás, F11 / Alt+Enter = teljes képernyő be/ki.
## Egyszerre csak egy lehet nyitva (másik gombra
## átvált), és amíg valamelyik nyitva van, megáll a játék.
## Szintlépés vagy halál közben (amikor már más állította meg a játékot) nem nyílik.

## Gomb -> a kezelt ablak útvonala (a Dungeon jelenetben).
const KEYS := {
	KEY_I: "../Inventory",
	KEY_TAB: "../StatsScreen",
	KEY_M: "../HUD/Minimap",
	KEY_J: "../QuestBook",
}

const PAUSE_MENU := "../PauseMenu"

var _open: Node = null


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_F11 or (key.physical_keycode == KEY_ENTER and key.alt_pressed):
		Audio.toggle_fullscreen()
	elif key.physical_keycode == KEY_ESCAPE:
		# Esc: ha van nyitott ablak, bezárja (a szünet menü előbb a beállításokból lép vissza);
		# ha nincs, a szünet menüt nyitja meg.
		if _open != null:
			if not (_open.has_method("handle_escape") and _open.call("handle_escape")):
				_close()
		else:
			_toggle(get_node(PAUSE_MENU))
	elif KEYS.has(key.physical_keycode) and get_node_or_null(KEYS[key.physical_keycode]) != null:
		# (A táborban pl. nincs térkép: ott az M nem csinál semmit.)
		_toggle(get_node(KEYS[key.physical_keycode]))
	else:
		return
	get_viewport().set_input_as_handled()


func is_open() -> bool:
	return _open != null


## A nyitott ablak bezárása kívülről (pl. a szünet menü "Folytatás" gombja).
func close_current() -> void:
	if _open != null:
		_close()


## Egy ablak megnyitása kívülről (pl. a tárgylift vagy a tábori sátor E-re).
func open_menu(menu: Node) -> void:
	if _open != null or get_tree().paused:
		return
	_toggle(menu)


## A boltos pultjánál: az inventory eladás módban nyílik meg.
func open_sell() -> void:
	if _open != null or get_tree().paused:
		return
	var inventory := get_node(KEYS[KEY_I])
	inventory.set("sell_mode", true)
	_toggle(inventory)


func _toggle(menu: Node) -> void:
	if _open == menu:
		_close()
		return
	if _open == null and get_tree().paused:
		return
	if _open != null:
		_open.call("close")
	_open = menu
	menu.call("open")
	get_tree().paused = true
	Audio.play("ui_open")


func _close() -> void:
	Audio.play("ui_close")
	_open.call("close")
	_open = null
	get_tree().paused = false
