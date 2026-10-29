extends CanvasLayer
## Halálképernyő: elsötétül a kép, beesik a véres koponya, alatta
## "MEGHALTÁL" és a futás statisztikái. A "Vissza a táborba" gombbal (vagy R / Enter)
## a táborba kerülsz, ahonnan újra le lehet menni.

const PANEL: Texture2D = preload("res://assets/ui/panel.png")
const PANEL_HOVER: Texture2D = preload("res://assets/ui/panel_hover.png")
const MAIN_MENU := "res://ui/main_menu.tscn"
const CAMP := "res://world/camp.tscn"
const GAME_SCENE := "res://world/dungeon.tscn"
const DEATH_GOLD_RATIO := 0.2
## Ha Azazel ellen estél el: a gomb után előbb a rossz befejezés (ui/bad_ending.gd), aztán a választott hely.
const BAD_ENDING := "res://ui/bad_ending.tscn"
const BadEnding := preload("res://ui/bad_ending.gd")

var _shown := false
var _azazel_won := false

@onready var _dim: ColorRect = $Dim
@onready var _content: Control = $Center/Box
@onready var _skull: TextureRect = $Center/Box/Skull
@onready var _stats_label: Label = $Center/Box/Stats
@onready var _restart: Button = $Center/Box/Buttons/Restart
@onready var _quit: Button = $Center/Box/Buttons/Quit


func _ready() -> void:
	visible = false
	for button in [_restart, _quit]:
		button.add_theme_stylebox_override("normal", _panel_style(PANEL))
		button.add_theme_stylebox_override("hover", _panel_style(PANEL_HOVER))
		button.add_theme_stylebox_override("pressed", _panel_style(PANEL_HOVER))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	# Vissza a főmenübe (az Újrakezdés és a Kilépés közé). A másolat a jelzések
	# bekötése előtt készül, hogy ne vigye magával az Újrakezdés jelzését.
	var menu_button: Button = _restart.duplicate()
	menu_button.text = "Főmenü"
	_restart.get_parent().add_child(menu_button)
	_restart.get_parent().move_child(menu_button, 1)
	menu_button.pressed.connect(_to_main_menu)
	_restart.pressed.connect(_restart_run)
	_quit.pressed.connect(func() -> void: get_tree().quit())


## A játékos halálakor hívódik; `player` a statisztikákhoz kell.
func show_for(player: Node) -> void:
	if _shown:
		return
	_shown = true
	_azazel_won = _azazel_alive()
	var experience: Experience = player.get_node("Experience")
	var seconds := int(GameState.run_time)
	var rank := Records.submit_run(player)
	_stats_label.text = "Elért emelet: %d\nKarakterszint: %d\nMegölt ellenségek: %d\nArany: %d\nJátékidő: %d:%02d" % [
		GameState.depth, experience.level, GameState.kills, player.get("gold"), seconds / 60, seconds % 60,
	]
	# Halálkor a pénzed 20%-a a táborba kerül.
	if GameState.tutorial:
		_stats_label.text += "\n\nGyakorlás: az R / Újrakezdés a gyakorló pályát kezdi újra."
		_restart.text = "Újra a gyakorlás (R)"
	elif GameState.cheated:
		_stats_label.text += "\n\nCsalt futás: semmi nem mentődött belőle."
	elif Challenge.active():
		_stats_label.text += "\n\nA próbatétel elbukott: a tárgyaid és az aranyad lent maradtak."
	else:
		var rescued := Progress.rescue_gold(int(player.get("gold")), DEATH_GOLD_RATIO)
		_stats_label.text += "\n\nA pénzed %d%%-a (%d arany) a táborba került." % [roundi(DEATH_GOLD_RATIO * 100), rescued]
	if rank > 0:
		_stats_label.text += "\n\n★ Új eredmény: %d. hely! ★" % rank
	visible = true
	GamePause.set_paused(get_tree(), true)

	_dim.modulate.a = 0.0
	_content.modulate.a = 0.0
	_skull.pivot_offset = _skull.custom_minimum_size / 2.0
	_skull.scale = Vector2(2.5, 2.5)
	var tween := create_tween()
	tween.tween_property(_dim, "modulate:a", 1.0, 0.6)
	tween.tween_property(_content, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(_skull, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not _shown or key == null or not key.pressed:
		return
	if key.physical_keycode in [KEY_R, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		_restart_run()


func _to_main_menu() -> void:
	GameState.tutorial = false
	GameState.reset()
	GamePause.set_paused(get_tree(), false)
	_leave(MAIN_MENU)


## Halál után vissza a táborba (onnan lehet újra lemenni).
func _restart_run() -> void:
	GameState.reset()
	GamePause.set_paused(get_tree(), false)
	# Gyakorláskor a gyakorló pálya indul újra.
	_leave(GAME_SCENE if GameState.tutorial else CAMP)


## Jelenetváltás; ha Azazel győzött, előtte a rossz befejezés.
func _leave(scene: String) -> void:
	if _azazel_won:
		BadEnding.next_scene = scene
		scene = BAD_ENDING
	get_tree().change_scene_to_file(scene)


## Él-e még Azazel (a pokol trónjánál, a harc közben).
func _azazel_alive() -> bool:
	if not GameState.hell:
		return false
	for node in get_tree().current_scene.find_children("*", "", true, false):
		if node is LuciferBoss and not node.is_queued_for_deletion() and int(node.get_node("Health").get("current")) > 0:
			return true
	return false


func _panel_style(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.set_texture_margin_all(12)
	style.set_content_margin_all(14)
	return style
