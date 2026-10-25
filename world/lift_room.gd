class_name LiftRoom
extends Node2D
## A 10. emelet liftszobája (a Room teszi bele, ha has_lift_room): a szoba közepén áll a lift (LiftRig:
## bakállvány, láncon lógó vasketrec, fogaskerék), mellette Bertalan, a mérnök (E: beszélgetés, lásd Engineer).
## A szobában nincs szörny, csapda és láda; a térképen kék.

const TILE := 32
## A lift vasketrece láncon (ETTiNGRiNDER, CC0).
const CAGE: Texture2D = preload("res://assets/props/lift_cage.png")
const CAGE_SCALE := 1.6
const TALK_RANGE := 70.0

var _player: Node2D
var _engineer: Node2D
var _engineer_body: CollisionShape2D
var _cage: Sprite2D
var _riding := false
var _dialogue: DialoguePanel
var _prompt: Label


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	# A szoba közepén a lift, jobbra mellette a mérnök (a játékossal együtt rendeződnek mélység szerint).
	y_sort_enabled = true
	var rig := LiftRig.new()
	rig.working = Engineer.repaired()
	add_child(rig)
	_cage = rig.cage
	_engineer = Node2D.new()
	_engineer.position = Vector2(TILE * 1.9, TILE * 1.0)
	add_child(_engineer)
	var figure := AnimatedSprite2D.new()
	figure.sprite_frames = Engineer.frames()
	figure.scale = Vector2(2, 2)
	figure.offset = Vector2(0, -Engineer.FRAME_SIZE.y / 2.0)
	figure.flip_h = true
	figure.play()
	_engineer.add_child(figure)
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(20, 10)
	shape.shape = box
	shape.position = Vector2(0, -4)
	body.add_child(shape)
	_engineer.add_child(body)
	_engineer_body = shape
	# A javítás után felment a lifttel: azóta a táborban van (lásd CampLift).
	_engineer.visible = not Engineer.in_camp()
	shape.disabled = Engineer.in_camp()
	_dialogue = DialoguePanel.new()
	_dialogue.name = "EngineerDialogue"
	_dialogue.npc_id = Engineer.ID
	_dialogue.npc_name = Engineer.NAME
	_dialogue.greeting = Engineer.GREETING
	_dialogue.portrait = Engineer.portrait()
	_dialogue.options_provider = func() -> Array[Dictionary]:
		return Engineer.options(_player)
	get_tree().current_scene.add_child.call_deferred(_dialogue)
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_prompt = MenuStyle.title_label("[E] Beszélgetés: %s" % Engineer.NAME, 32, MenuStyle.GOLD)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -210
	_prompt.offset_bottom = -160
	_prompt.offset_left = -500
	_prompt.offset_right = 500
	_prompt.modulate.a = 0.0
	layer.add_child(_prompt)


func _near() -> bool:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	return is_instance_valid(_player) and _engineer.visible and not _riding \
		and _player.global_position.distance_to(_engineer.global_position) < TALK_RANGE


func _process(delta: float) -> void:
	# A javítás után, amint bezárult a beszélgetés: beszáll a ketrecbe, és felmegy vele.
	if not _riding and not GamePause.active(get_tree()) and Progress.npc_quest_state(Engineer.RIDE_FLAG) == "pending":
		_ride()
	var target := 1.0 if _near() and not GamePause.active(get_tree()) else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)


## Bertalan a ketrechez sétál, beszáll, a ketrec felhúzódik az aknán; kis idő múlva üresen ereszkedik vissza.
func _ride() -> void:
	_riding = true
	_engineer_body.disabled = true
	var walk := create_tween()
	walk.tween_property(_engineer, "position", Vector2(0, TILE * 0.7), 1.0)
	walk.tween_property(_engineer, "modulate:a", 0.0, 0.3)
	await walk.finished
	_engineer.visible = false
	Audio.play("door_unlock", -4.0)
	Audio.play("boss_slam", -14.0, 0.1)
	var start := _cage.position
	var up := create_tween()
	up.tween_property(_cage, "position", start + Vector2(0, -TILE * 3), 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	up.parallel().tween_property(_cage, "modulate:a", 0.0, 2.2)
	await up.finished
	Progress.set_npc_quest(Engineer.RIDE_FLAG, "done")
	Progress.save_game()
	await get_tree().create_timer(1.5).timeout
	var down := create_tween()
	down.tween_property(_cage, "position", start, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	down.parallel().tween_property(_cage, "modulate:a", 1.0, 1.0)
	_riding = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or GamePause.active(get_tree()) or not _near():
		return
	get_viewport().set_input_as_handled()
	Audio.play("ui_open")
	get_tree().current_scene.get_node("Menus").call("open_menu", _dialogue)


## A lift (a kazamatában és a táborban is ez áll, lásd CampLift): fa bakállvány két oszloppal és
## gerendával, a gerenda alatt csiga, róla láncon lóg a vasketrec; a gerenda bal végén a csörlő
## rozsdás fogaskereke. Pixelrácsra rajzolva (2 px = 1 képpont), mint a pálya többi grafikája.
## Az origó a lábak vonala a földön. `working`: megjavítva forog a kerék, és lámpa ég a ketrecben.
class LiftRig:
	extends Node2D
	const GEAR: Texture2D = preload("res://assets/props/lift_gear.png")
	const GEAR_FRAMES := 8
	const GEAR_FPS := 10.0
	const POST_X := 38.0
	const BEAM_TOP := -128.0
	const OUTLINE := Color8(29, 20, 24)
	const WOOD_DARK := Color8(92, 58, 38)
	const WOOD := Color8(130, 86, 52)
	const WOOD_LIGHT := Color8(166, 116, 70)
	const IRON_DARK := Color8(50, 48, 60)
	const IRON := Color8(82, 80, 96)
	const IRON_LIGHT := Color8(122, 119, 138)
	const STONE := Color8(96, 90, 98)
	const STONE_LIGHT := Color8(128, 121, 128)

	var working := false
	## A ketrec alja a lábak vonalához képest (a tábori akna fölött kisebb, ott a lyukba lóg).
	var cage_bottom := 18.0
	## Ütközik-e (a táborban az akna teste ütközik helyette).
	var solid := true
	var cage: Sprite2D
	var _gear: Sprite2D
	var _gear_time := 0.0

	func _init() -> void:
		cage = Sprite2D.new()
		_gear = Sprite2D.new()

	func _ready() -> void:
		cage.texture = CAGE
		cage.scale = Vector2(CAGE_SCALE, CAGE_SCALE)
		cage.offset = Vector2(0, -CAGE.get_height() / 2.0)
		cage.position = Vector2(0, cage_bottom)
		add_child(cage)
		_gear.texture = GEAR
		_gear.hframes = GEAR_FRAMES
		_gear.scale = Vector2(2, 2)
		_gear.position = Vector2(-POST_X - 10.0, BEAM_TOP + 4.0)
		add_child(_gear)
		if working:
			# Megjavítva: lámpás ég a ketrecben.
			var glow := PointLight2D.new()
			var gradient := Gradient.new()
			gradient.set_color(0, Color(1.0, 0.8, 0.45))
			gradient.set_color(1, Color(0, 0, 0, 0))
			var texture := GradientTexture2D.new()
			texture.gradient = gradient
			texture.fill = GradientTexture2D.FILL_RADIAL
			texture.fill_from = Vector2(0.5, 0.5)
			texture.fill_to = Vector2(0.5, 0.0)
			glow.texture = texture
			glow.texture_scale = 1.5
			glow.energy = 0.8
			glow.position = Vector2(0, cage_bottom - 44.0)
			add_child(glow)
		if solid:
			var body := StaticBody2D.new()
			var shape := CollisionShape2D.new()
			var box := RectangleShape2D.new()
			box.size = Vector2(POST_X * 2.0 + 8.0, cage_bottom + 8.0)
			shape.shape = box
			shape.position = Vector2(0, (cage_bottom - 8.0) / 2.0)
			body.add_child(shape)
			add_child(body)

	func _process(delta: float) -> void:
		if working:
			_gear_time += delta
			_gear.frame = int(_gear_time * GEAR_FPS) % GEAR_FRAMES

	## Kitöltött téglalap 2 px-es körvonallal, bal/felső világos és jobb/alsó sötét széllel.
	func _block(rect: Rect2, fill: Color, light: Color, dark: Color) -> void:
		draw_rect(rect.grow(2.0), OUTLINE)
		draw_rect(rect, fill)
		draw_rect(Rect2(rect.position, Vector2(2, rect.size.y)), light)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2)), light)
		draw_rect(Rect2(rect.end - Vector2(2, rect.size.y), Vector2(2, rect.size.y)), dark)

	func _draw() -> void:
		var beam_bottom := BEAM_TOP + 10.0
		# Kőtalpak az oszlopok alatt.
		for side: float in [-1.0, 1.0]:
			_block(Rect2(side * POST_X - 7.0, -4.0, 14.0, 6.0), STONE, STONE_LIGHT, IRON_DARK)
		# Oszlopok és ferde merevítők (lépcsőzetes pixelvonal).
		for side: float in [-1.0, 1.0]:
			_block(Rect2(side * POST_X - 4.0, beam_bottom, 8.0, -beam_bottom - 2.0), WOOD, WOOD_LIGHT, WOOD_DARK)
			for i in 9:
				var at := Vector2(side * (POST_X - 4.0 - 2.0 * i) - (2.0 if side > 0 else 0.0), beam_bottom + 20.0 - 2.0 * i)
				draw_rect(Rect2(at - Vector2(1, 1), Vector2(4, 4)), OUTLINE)
			for i in 9:
				var at := Vector2(side * (POST_X - 4.0 - 2.0 * i) - (2.0 if side > 0 else 0.0), beam_bottom + 20.0 - 2.0 * i)
				draw_rect(Rect2(at, Vector2(2, 2)), WOOD_LIGHT if side < 0 else WOOD)
		# Gerenda.
		_block(Rect2(-POST_X - 10.0, BEAM_TOP, POST_X * 2.0 + 20.0, 10.0), WOOD, WOOD_LIGHT, WOOD_DARK)
		# Vasszegecsek a gerenda és az oszlopok találkozásánál.
		for side: float in [-1.0, 1.0]:
			draw_rect(Rect2(side * POST_X - 1.0, BEAM_TOP + 4.0, 2, 2), IRON_LIGHT)
		# Csiga a gerenda alatt (pixelkör).
		var hub := Vector2(0, beam_bottom + 8.0)
		draw_rect(Rect2(-2, beam_bottom, 4, 4), IRON_DARK)
		for y in range(-9, 9, 2):
			for x in range(-9, 9, 2):
				var cell := Vector2(x + 1, y + 1)
				var d := cell.length()
				if d <= 8.0:
					draw_rect(Rect2(hub + Vector2(x, y), Vector2(2, 2)), OUTLINE)
				if d <= 6.0:
					var shade := IRON_LIGHT if x + y < -4 else (IRON_DARK if x + y > 4 else IRON)
					draw_rect(Rect2(hub + Vector2(x, y), Vector2(2, 2)), shade)
		draw_rect(Rect2(hub - Vector2(1, 1), Vector2(2, 2)), OUTLINE)
