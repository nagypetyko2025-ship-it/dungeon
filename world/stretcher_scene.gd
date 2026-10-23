class_name StretcherScene
extends Node2D
## Bejátszás az első visszatéréskor a kazamatából: két királyi katona hordágyon visz egy súlyosan
## sebesült kalandort a lépcsőtől végig a táboron és a városon át az orvoshoz (a kocsma melletti
## lakóházba). A kamera végig követi őket, közben nem tudsz mozogni; a katonák kiabálnak.
## Egyszer játszódik le (FLAG a Progress.npc_quests-ben). (A tábor indítja: start(camp, path).)

const FLAG := "stretcher_scene"
const SPEED := 120.0
const GUARD_SHEET: Texture2D = preload("res://assets/characters/royal_guard.png")
const DUNGEON: Texture2D = preload("res://assets/0x72_dungeon/0x72_DungeonTilesetII_v1.7.png")
## A sebesült (a 0x72 lapról: egy kalandor, sápadtra színezve, fekve).
const WOUNDED := Rect2(128, 100, 16, 28)
## A két katona távolsága a hordágy közepétől.
const BEARER_GAP := 30.0
const LINES: Array[Array] = [[0.4, "Gyorsan, az orvoshoz!", 0], [0.5, "Még egy sérült!", 1]]

var _camp: Node2D
var _player: CharacterBody2D
var _camera: Camera2D
var _group: Node2D
var _bearers: Array[AnimatedSprite2D] = []
var _following := false
var _drip_left := 0.0


static func should_play() -> bool:
	return not GameState.tutorial and Progress.npc_quest_state(FLAG) == ""


func start(camp: Node2D, path: Array[Vector2]) -> void:
	_camp = camp
	_player = camp.get_node("Entities/Player")
	Progress.set_npc_quest(FLAG, "done")
	Progress.save_game()
	# Amíg tart, a játékos áll (semmilyen billentyű nem ér el hozzá, lásd _input).
	_player.set_physics_process(false)
	_player.velocity = Vector2.ZERO
	(_player.get_node("Visual/AnimatedSprite2D") as AnimatedSprite2D).play("idle")
	_build_group(path[0])
	var player_camera: Camera2D = _player.get_node("Camera2D")
	_camera = Camera2D.new()
	_camera.zoom = player_camera.zoom
	_camera.limit_left = player_camera.limit_left
	_camera.limit_top = player_camera.limit_top
	_camera.limit_right = player_camera.limit_right
	_camera.limit_bottom = player_camera.limit_bottom
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 4.0
	add_child(_camera)
	# A játékos helyéből indul (a játékos kamerájának képernyőközepe a tábor betöltésekor még
	# elavult, a pálya sarkára mutat), és rögtön ott is van, nem úszik be.
	_camera.global_position = _player.global_position + player_camera.position
	_camera.make_current()
	_camera.reset_smoothing()
	_following = true
	_walk(path)


func _build_group(at: Vector2) -> void:
	_group = Node2D.new()
	_group.position = at
	_group.modulate.a = 0.0
	_camp.get_node("Entities").add_child(_group)
	# A hordágy: két rúd, köztük véres vászon, rajta a sebesült.
	var stretcher := Stretcher.new()
	stretcher.position = Vector2(0, -18)
	_group.add_child(stretcher)
	var atlas := AtlasTexture.new()
	atlas.atlas = DUNGEON
	atlas.region = WOUNDED
	var wounded := Sprite2D.new()
	wounded.texture = atlas
	wounded.scale = Vector2(2, 2)
	wounded.rotation = -PI / 2.0
	wounded.position = Vector2(0, -26)
	wounded.modulate = Color(0.85, 0.75, 0.72)
	_group.add_child(wounded)
	var wounds := Wounds.new()
	wounds.position = Vector2(0, -26)
	_group.add_child(wounds)
	for side in [1, -1]:
		var bearer := AnimatedSprite2D.new()
		bearer.sprite_frames = _guard_frames()
		bearer.scale = Vector2(2, 2)
		bearer.offset = Vector2(0, -14)
		bearer.position = Vector2(side * BEARER_GAP * 1.6, 0)
		bearer.play("run")
		_group.add_child(bearer)
		_bearers.append(bearer)


func _guard_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("run")
	frames.set_animation_speed("run", 10.0)
	for i in range(4, 8):
		var frame := AtlasTexture.new()
		frame.atlas = GUARD_SHEET
		frame.region = Rect2(i * 16, 0, 16, 28)
		frames.add_frame("run", frame)
	return frames


func _walk(path: Array[Vector2]) -> void:
	var total := 0.0
	for i in range(1, path.size()):
		total += path[i - 1].distance_to(path[i])
	var walk := create_tween()
	# Feljönnek a lépcsőn (előtűnnek), aztán sietve indulnak.
	walk.tween_property(_group, "modulate:a", 1.0, 0.5)
	var from := path[0]
	for i in range(1, path.size()):
		var target := path[i]
		walk.tween_callback(func() -> void: _face(target))
		walk.tween_property(_group, "position", target, from.distance_to(target) / SPEED)
		from = target
	walk.tween_property(_group, "modulate:a", 0.0, 0.5)
	walk.tween_callback(func() -> void: Audio.play("door_unlock", -6.0))
	# A két kiáltás: az út elején és nagyjából a felénél.
	for line: Array in LINES:
		var at: float = 0.5 + float(line[0]) * total / SPEED if line[2] == 1 else float(line[0]) + 0.5
		get_tree().create_timer(at, false).timeout.connect(_shout.bind(line[1], int(line[2])))
	await walk.finished
	_finish()


## Menetirány szerint fordulnak (a hordágy elöl lévő vége az első katona).
func _face(target: Vector2) -> void:
	var dir := _group.position.direction_to(target)
	if dir.length() < 0.01:
		return
	var horizontal := absf(dir.x) >= absf(dir.y)
	for i in _bearers.size():
		var bearer := _bearers[i]
		var front := 1.0 if i == 0 else -1.0
		if horizontal:
			bearer.position = Vector2(signf(dir.x) * front * BEARER_GAP * 1.6, 0)
			bearer.flip_h = dir.x < 0.0
		else:
			bearer.position = Vector2(0, signf(dir.y) * front * BEARER_GAP * 0.9)
		bearer.z_index = 1 if bearer.position.y > 0 else 0


func _shout(text: String, who: int) -> void:
	if not is_instance_valid(_group) or who >= _bearers.size():
		return
	var label := UiStyle.label(text, 15, Color(1, 0.92, 0.75))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(240, 0)
	label.position = _bearers[who].position + Vector2(-120, -86)
	label.z_index = 10
	_group.add_child(label)
	Audio.play("boss_roar", -18.0, 0.3)
	var fade := label.create_tween()
	fade.tween_interval(2.4)
	fade.tween_property(label, "modulate:a", 0.0, 0.5)
	fade.tween_callback(label.queue_free)


func _process(delta: float) -> void:
	if not _following or not is_instance_valid(_group):
		return
	_camera.global_position = _group.global_position + Vector2(0, -24)
	# Vércseppek a földön a hordágy nyomában.
	_drip_left -= delta
	if _drip_left <= 0.0 and _group.modulate.a > 0.5:
		_drip_left = randf_range(0.25, 0.6)
		var drop := BloodDrop.new()
		drop.position = _group.position + Vector2(randf_range(-10, 10), randf_range(-4, 4))
		drop.z_index = -8
		_camp.add_child(drop)


## A bejátszás vége: a kamera visszaúszik a játékoshoz, és újra irányíthatod.
func _finish() -> void:
	_following = false
	if is_instance_valid(_group):
		_group.queue_free()
	var player_camera: Camera2D = _player.get_node("Camera2D")
	var back := create_tween()
	_camera.position_smoothing_enabled = false
	back.tween_property(_camera, "global_position", _player.global_position + player_camera.position, 1.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await back.finished
	player_camera.make_current()
	player_camera.reset_smoothing()
	_player.set_physics_process(true)
	queue_free()


## Amíg a bejátszás tart, semmilyen bevitel nem jut el a játékhoz.
func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()


## A hordágy: két hosszú rúd, köztük vászon, rajta vérfoltok.
class Stretcher:
	extends Node2D

	func _draw() -> void:
		var wood := Color(0.42, 0.29, 0.17)
		draw_rect(Rect2(-56, -7, 112, 3), wood)
		draw_rect(Rect2(-56, 6, 112, 3), wood)
		draw_rect(Rect2(-34, -5, 68, 12), Color(0.72, 0.66, 0.55))
		draw_rect(Rect2(-6, -3, 14, 9), Color(0.55, 0.08, 0.08, 0.85))
		draw_rect(Rect2(12, 0, 8, 6), Color(0.5, 0.06, 0.06, 0.8))
		draw_rect(Rect2(-24, 2, 6, 4), Color(0.5, 0.06, 0.06, 0.7))


## A sebesült kötései és sebei (a fekvő figura fölött): véres kötés a fején, vér a mellkasán,
## lelógó kar.
class Wounds:
	extends Node2D

	func _draw() -> void:
		draw_rect(Rect2(-26, -9, 7, 14), Color(0.88, 0.86, 0.8))
		draw_rect(Rect2(-24, -4, 4, 5), Color(0.6, 0.06, 0.06))
		draw_rect(Rect2(-6, -6, 12, 10), Color(0.6, 0.05, 0.05, 0.85))
		draw_rect(Rect2(8, 2, 6, 5), Color(0.55, 0.05, 0.05, 0.8))
		draw_line(Vector2(-4, 8), Vector2(-2, 22), Color(0.8, 0.65, 0.55), 3.0)


## Egy vércsepp a földön, ami lassan felszárad.
class BloodDrop:
	extends Node2D

	func _ready() -> void:
		var fade := create_tween()
		fade.tween_interval(6.0)
		fade.tween_property(self, "modulate:a", 0.0, 3.0)
		fade.tween_callback(queue_free)

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 2.5, Color(0.5, 0.03, 0.03, 0.9))
		draw_circle(Vector2(3, 1), 1.5, Color(0.45, 0.03, 0.03, 0.8))
