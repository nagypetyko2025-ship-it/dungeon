class_name Fisherman
extends Node2D
## Az öreg horgász a tó partján: egy ideig horgászik (a kezében a letöltött horgászbot, a végéről
## zsinór lóg az úszóig, az úszó billeg, néha "kapás" van), aztán a part mentén arrébb sétál, és ott
## horgászik tovább. E-vel beszélgetni lehet vele (három története van; küldetése egyelőre nincs).
## Kép: assets/characters/old_fisherman.png (0x72 öreg varázsló, zöldre színezve; 0-3: áll, 4-7: fut),
## bot: assets/items/fishing_rod_bare.png (CC0). (A tábor rakja le az Entities rétegbe.)

const SHEET: Texture2D = preload("res://assets/characters/old_fisherman.png")
const ROD: Texture2D = preload("res://assets/items/fishing_rod_bare.png")
const FRAME := Vector2i(16, 28)
const SCALE := 2.0
const WALK_SPEED := 26.0
## A part (az ellipszis) ennyivel nagyobb a tónál: itt áll és jár.
const SHORE := 1.18
const FISH_TIME := Vector2(14.0, 26.0)
## A bot nyele és hegye a bot képén (képpont).
const ROD_HANDLE := Vector2(3, 13)
const ROD_TIP := Vector2(10.5, 2.5)
## A kéz helye a figurán (jobbra nézve).
const HAND := Vector2(8, -13)
const ID := "fisherman"
const NAME := "Öreg Ábel, a horgász"
const TALK_RANGE := 60.0
const STORIES: Array[Dictionary] = [
	{"id": "lake", "text": "Mióta horgászol itt?", "trust": 3,
		"answer": "[i]Nem néz fel, csak az úszót figyeli.[/i]\n\n" \
			+ "Mióta tó van itt. Régen ez csak egy vizenyős rét volt. Aztán egy tavasszal, amikor a kazamata " \
			+ "kapuját feltörték, megremegett a föld, és reggelre itt állt a víz. Alulról jött, fiam. Nem " \
			+ "esőből, hanem a mélyből.\n\nAzóta itt állok. Valakinek figyelnie kell, mit hoz fel."},
	{"id": "fish", "text": "Mit lehet itt fogni?", "trust": 3,
		"answer": "[i]Megvakarja a szakállát.[/i]\n\n" \
			+ "Mindenfélét. Pontyot, csukát... és olyat is, aminek nincs szeme. Fehér, áttetsző halakat, " \
			+ "amik sosem láttak napot. Azokat visszadobom. Nem illik megenni, ami a sötétből jött.\n\n" \
			+ "Egyszer egy rozsdás kulcs volt az egyik gyomrában. Azóta is őrzöm. Hátha egyszer megtalálom " \
			+ "a zárat hozzá. Vagy ő talál meg engem."},
	{"id": "advice", "text": "Adnál tanácsot egy kalandornak?", "trust": 5,
		"answer": "[i]Végre rád néz. A szeme szürke és nyugodt, mint a víz hajnalban.[/i]\n\n" \
			+ "A mélység olyan, mint ez a tó. Aki kapkod, annak elriasztja a halait. Aki türelmes, annak " \
			+ "a víz magától adja oda, amit tartogat.\n\nNe akarj mindent egyszerre. Menj le egy emelettel, " \
			+ "aztán még eggyel. A gyanús boltos odalent is egyre jobb portékát tart, minél mélyebbre jutsz. " \
			+ "A mélység megjutalmazza azt, aki kitart."},
]

var _sprite: Sprite2D
var _rod: Sprite2D
var _line: Node2D
var _angle := 0.0
var _target_angle := 0.0
var _fishing := true
var _timer := 0.0
var _time := 0.0
var _bite := 0.0
## A víz felé mutató egységvektor (horgászáskor).
var _facing := Vector2.UP
var _left := false
var _player: Node2D
var _prompt: Label
var _dialogue: DialoguePanel


func _ready() -> void:
	_sprite = Sprite2D.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEET
	atlas.region = Rect2(0, 0, FRAME.x, FRAME.y)
	_sprite.texture = atlas
	_sprite.scale = Vector2(SCALE, SCALE)
	_sprite.offset = Vector2(0, -FRAME.y / 2.0)
	add_child(_sprite)
	_rod = Sprite2D.new()
	_rod.texture = ROD
	_rod.centered = false
	_rod.scale = Vector2(SCALE, SCALE)
	add_child(_rod)
	_line = Node2D.new()
	_line.draw.connect(_draw_line)
	add_child(_line)
	_build_dialogue.call_deferred()
	# A délkeleti parton kezd (a mólótól jobbra).
	_angle = PI / 2.0 - 0.6
	_place()
	_start_fishing()


func _build_dialogue() -> void:
	var camp := get_tree().current_scene
	_player = camp.get_node_or_null("Entities/Player") as Node2D
	_dialogue = DialoguePanel.new()
	_dialogue.name = "FishermanDialogue"
	_dialogue.npc_id = ID
	_dialogue.npc_name = NAME
	_dialogue.greeting = "[i]Az öreg a part szélén áll, a botját két kézzel tartja. Csak a szemével int, hogy " \
		+ "halkabban.[/i]\n\nCsendesen, fiam. A halak mindent hallanak."
	var face := AtlasTexture.new()
	face.atlas = SHEET
	face.region = Rect2(0, 0, FRAME.x, FRAME.y)
	_dialogue.portrait = face
	_dialogue.options = STORIES.duplicate()
	camp.add_child(_dialogue)
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_prompt = MenuStyle.title_label("[E] Beszélgetés: %s" % NAME, 32, MenuStyle.GOLD)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -210
	_prompt.offset_bottom = -160
	_prompt.offset_left = -500
	_prompt.offset_right = 500
	_prompt.modulate.a = 0.0
	layer.add_child(_prompt)


func _near_player() -> bool:
	return is_instance_valid(_player) and _player.global_position.distance_to(global_position) < TALK_RANGE


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or get_tree().paused or not _near_player() or _dialogue == null:
		return
	get_viewport().set_input_as_handled()
	Audio.play("ui_open")
	get_tree().current_scene.get_node("Menus").call("open_menu", _dialogue)


## A part egy pontja (szög szerint) képpontban.
static func shore_point(angle: float) -> Vector2:
	var at := Lake.CENTER + Vector2(cos(angle) * Lake.RADIUS.x, sin(angle) * Lake.RADIUS.y) * SHORE
	return at * Lake.TILE


func _place() -> void:
	position = shore_point(_angle)


func _start_fishing() -> void:
	_fishing = true
	_timer = randf_range(FISH_TIME.x, FISH_TIME.y)
	_facing = (Lake.CENTER * Lake.TILE - position).normalized()
	_turn(_facing.x < 0.0)


## Új horgászhely: a part mentén legfeljebb kb. negyed környit arrébb (a móló tövét kerülve).
func _start_walking() -> void:
	_fishing = false
	var step := randf_range(0.5, 1.3) * (1.0 if randf() < 0.5 else -1.0)
	_target_angle = _angle + step
	# A móló tövében ne álljon meg (ott a móló takarná a botot).
	var pier_angle := PI / 2.0 + asin((Lake.CENTER.x - Lake.PIER_COLUMN - 0.5) / (Lake.RADIUS.x * SHORE))
	if absf(wrapf(_target_angle - pier_angle, -PI, PI)) < 0.3:
		_target_angle += 0.6 * signf(step)
	_line.queue_redraw()


## Balra vagy jobbra fordul; a bot a kezével együtt tükröződik.
func _turn(left: bool) -> void:
	_left = left
	_sprite.flip_h = left
	_rod.flip_h = left
	var hand := _hand()
	var handle := ROD_HANDLE * SCALE
	if left:
		handle.x = (ROD.get_width() - ROD_HANDLE.x) * SCALE
	_rod.position = hand - handle


func _hand() -> Vector2:
	return Vector2(-HAND.x if _left else HAND.x, HAND.y) + _sprite.position


## A bot hegye (a horgász helyi koordinátáiban).
func _rod_tip() -> Vector2:
	var tip := ROD_TIP
	if _left:
		tip.x = ROD.get_width() - ROD_TIP.x
	return _rod.position + tip * SCALE


func _set_frame(index: int) -> void:
	(_sprite.texture as AtlasTexture).region = Rect2(index * FRAME.x, 0, FRAME.x, FRAME.y)


func _process(delta: float) -> void:
	_time += delta
	if _prompt != null:
		var shown := 1.0 if _near_player() and not get_tree().paused else 0.0
		_prompt.modulate.a = move_toward(_prompt.modulate.a, shown, delta * 5.0)
	if _fishing:
		_timer -= delta
		if _bite <= 0.0 and randf() < delta * 0.08:
			_bite = 1.2
		_bite = maxf(_bite - delta, 0.0)
		_set_frame(int(_time * 5.0) % 4)
		# Kapáskor megrándul a bot.
		_rod.rotation = deg_to_rad(6.0 if _bite > 0.0 and fmod(_time, 0.3) < 0.15 else 0.0) * (-1.0 if _left else 1.0)
		if _timer <= 0.0:
			_rod.rotation = 0.0
			_start_walking()
		_line.queue_redraw()
		return
	# Séta a part mentén (az ív hosszával arányos szögsebességgel).
	var radius := shore_point(_angle).distance_to(shore_point(_angle + 0.01)) / 0.01
	var turn := WALK_SPEED * delta / maxf(radius, 1.0)
	var before := position
	_angle = move_toward(_angle, _target_angle, turn)
	_place()
	var moved := position - before
	if absf(moved.x) > 0.01:
		_turn(moved.x < 0.0)
	_set_frame(4 + int(_time * 8.0) % 4)
	if is_equal_approx(_angle, _target_angle):
		_start_fishing()


## A zsinór a bot hegyétől az úszóig, és maga az úszó a vízen.
func _draw_line() -> void:
	if not _fishing:
		return
	var tip := _rod_tip()
	var bobber := _hand() + _facing * 72.0 + Vector2(0, 30)
	var dip := 4.0 if _bite > 0.0 and fmod(_time, 0.3) < 0.15 else sin(_time * 2.5) * 1.2
	bobber.y += dip
	_line.draw_line(tip, bobber, Color(0.95, 0.95, 0.9, 0.8), 1.0)
	_line.draw_rect(Rect2(bobber + Vector2(-2, -2), Vector2(4, 2)), Color(0.75, 0.2, 0.2))
	_line.draw_rect(Rect2(bobber + Vector2(-2, 0), Vector2(4, 2)), Color(1, 1, 1))
	if _bite > 0.0:
		_line.draw_arc(bobber + Vector2(0, 3), 6.0 + (1.2 - _bite) * 8.0, 0.0, TAU, 16, Color(1, 1, 1, _bite * 0.5), 1.0)
