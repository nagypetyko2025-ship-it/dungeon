class_name Town
extends Node2D
## A város a tábortól keletre, az erdőn át vezető út végén (egyelőre egy épülettel):
## az út fölött a Mélységi kocsma. Az ajtajánál E-re bemész: a belső tér messze a
## pályától van (mint a bolt a kazamatában), 10 asztallal, asztalonként 2 székkel,
## a bejárattal szemben a pult a kocsmárossal, az asztalokon korsók és borosüvegek.
## A székeken ülnek a játszható karakterek (aki épp nem az aktív): odamész, E-t
## nyomsz, feláll és átveszed az irányítást, a mostani karaktered a saját helyére ül.
## (A tábor építi fel: setup(camp), a csempe-segédeit is a tábor adja.)

signal message(text: String)

const TILE := 32
const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const INDOOR: Texture2D = preload("res://assets/shop/kenney_indoor.png")
const CONTAINERS: Texture2D = preload("res://assets/shop/barrels_and_boxes.png")
const TORCH := preload("res://rooms/decor/torch.tscn")

## A város tisztása (csempékben); az út ROAD_ROW-ban jön be nyugatról.
const RECT := Rect2i(60, 4, 34, 26)
## A kocsma épülete (bal felső csempe, méret), az ajtó a legalsó sor közepén (2 széles).
const TAVERN_TOP_LEFT := Vector2i(66, 10)
const TAVERN_SIZE := Vector2i(9, 5)
const DOOR_COLUMN := 69
## A kocsma belseje (messze mindentől): padló csempékben, a bejárat a déli fal közepén.
const INTERIOR := Rect2i(200, 0, 20, 15)
const INTERIOR_DOOR := Vector2i(209, 14)
## Belső tér: meleg, gyertyafényes.
const INTERIOR_LIGHT := Color(0.62, 0.52, 0.44)
const INTERACT_RANGE := 52.0
# Kenney RPG lap (oszlop, sor)
const ROOF_TOP := [Vector2i(34, 21), Vector2i(39, 21), Vector2i(35, 21)]
const ROOF_MID := [Vector2i(38, 22), Vector2i(39, 22), Vector2i(40, 22)]
const ROOF_LOW := [Vector2i(38, 23), Vector2i(39, 23), Vector2i(40, 23)]
const WALL_BAND := Vector2i(34, 16)
const WALL_BOARDS := Vector2i(34, 17)
const WINDOW := Vector2i(40, 0)
const DOUBLE_DOOR := [Vector2i(28, 6), Vector2i(29, 6)]
const ROOF_TINT := Color(0.78, 0.52, 0.42)
const FLOOR_TILES: Array[Vector2i] = [Vector2i(8, 2), Vector2i(8, 3)]
const FLOOR_TINT := Color(0.66, 0.5, 0.42)
const TABLE := Vector2i(19, 6)
## Oldalra néző székek (a bal oldali jobbra néz, a jobb oldali balra).
const CHAIR_FACING_RIGHT := Vector2i(21, 4)
const CHAIR_FACING_LEFT := Vector2i(22, 4)
const DRINKS: Array[Vector2i] = [Vector2i(55, 14), Vector2i(55, 11), Vector2i(54, 14), Vector2i(54, 11), Vector2i(56, 11)]
const CANDLE := Vector2i(19, 7)
const FIREPLACE := [Vector2i(54, 8), Vector2i(55, 8)]
const SHELF_COLUMNS := [43, 44, 45, 46, 47, 48, 49, 50]
## A kocsmáros (0x72 törpenő).
const BARKEEP := Rect2(128, 260, 16, 28)
const BARKEEP_LINES: Array[String] = [
	"Üdv a Mélységi kocsmában! Sör, bor, mesék... majd később.",
	"Itt mindenki lement már egyszer. Kevesen jöttek vissza.",
	"A törzsvendégeim? Ülnek a helyükön. Szólj nekik, ha kellenek.",
]

## A székek helye (világ-koordináta) és iránya: [pozíció, jobbra néz-e]. A karakterek
## a Characters.ALL "seat" indexe szerinti széken ülnek.
var seats: Array = []

var _camp: Node2D
var _player: Node2D
var _entities: Node2D
var _seated := {}
var _prompt: Label
var _inside := false
var _barkeep_line := 0
var _busy := false
var _quest_panel: CanvasLayer
var _quest_mark: Label

const QUEST_PANEL := preload("res://ui/quest_panel.gd")
var _intro: PanelContainer
var _intro_title: PanelContainer
var _intro_portrait: TextureRect
var _intro_role: Label
var _intro_text: RichTextLabel
var _intro_for := ""


func setup(camp: Node2D) -> void:
	_camp = camp
	_entities = camp.get_node("Entities")
	_player = camp.get_node("Entities/Player")
	_quest_panel = QUEST_PANEL.new()
	_quest_panel.name = "QuestPanel"
	camp.add_child.call_deferred(_quest_panel)


## A kocsma ajtaja előtti földút (a tábor rajzolja ki a többi földdel együtt).
static func path_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var bottom := TAVERN_TOP_LEFT.y + TAVERN_SIZE.y
	for y in range(bottom, 17):
		for x in [DOOR_COLUMN, DOOR_COLUMN + 1]:
			tiles.append(Vector2i(x, y))
	return tiles


## Ide nem kerülhet fa / bokor (az épület és körülötte).
static func blocked_rect() -> Rect2i:
	return Rect2i(TAVERN_TOP_LEFT - Vector2i(2, 2), TAVERN_SIZE + Vector2i(4, 4))


func build() -> void:
	_build_exterior()
	_build_interior()
	_build_ui()
	_build_intro()
	_seat_characters()


# ---------------------------------------------------------------- külső

func _build_exterior() -> void:
	var tl := TAVERN_TOP_LEFT
	var w := TAVERN_SIZE.x
	for x in w:
		var piece := 0 if x == 0 else (2 if x == w - 1 else 1)
		_tile(ROOF_TOP[piece], tl + Vector2i(x, 0), -6).modulate = ROOF_TINT
		_tile(ROOF_MID[piece], tl + Vector2i(x, 1), -6).modulate = ROOF_TINT
		_tile(ROOF_LOW[piece], tl + Vector2i(x, 2), -6).modulate = ROOF_TINT
		# Falak: felül deszkasáv ablakokkal, alul függőleges deszkák az ajtóval.
		_tile(WALL_BAND, tl + Vector2i(x, 3), -6)
		_tile(WALL_BOARDS, tl + Vector2i(x, 4), -6)
		if x == 2 or x == w - 3:
			_tile(WINDOW, tl + Vector2i(x, 3), -5)
	for i in 2:
		_tile(DOUBLE_DOOR[i], Vector2i(DOOR_COLUMN + i, tl.y + 4), -5)
	# Az épület szilárd (az ajtó előtt lehet megállni).
	_solid(Rect2(Vector2(tl) * TILE, Vector2(TAVERN_SIZE) * TILE - Vector2(0, 6)))
	# Cégér az ajtó fölött, két fáklya a falon.
	var sign_label := MenuStyle.title_label("Mélységi kocsma", 26, MenuStyle.GOLD)
	sign_label.size = Vector2(300, 34)
	sign_label.position = Vector2(DOOR_COLUMN + 1, tl.y + 2) * TILE + Vector2(-150, 8)
	sign_label.z_index = 2
	add_child(sign_label)
	for x in [1, w - 2]:
		var torch: Node2D = TORCH.instantiate()
		torch.position = _center(tl + Vector2i(x, 4)) + Vector2(0, -16)
		add_child(torch)
	# Hordók a fal mellett.
	_prop(CONTAINERS, Rect2(0, 0, 16, 16), _center(tl + Vector2i(w, 4)) + Vector2(4, 8))
	_prop(CONTAINERS, Rect2(0, 0, 16, 16), _center(tl + Vector2i(w, 4)) + Vector2(26, 12))
	_prop(CONTAINERS, Rect2(16, 0, 16, 16), _center(tl + Vector2i(-1, 4)) + Vector2(-4, 10))


func door_position() -> Vector2:
	return Vector2(DOOR_COLUMN + 1, TAVERN_TOP_LEFT.y + TAVERN_SIZE.y) * TILE + Vector2(0, 16)


# ---------------------------------------------------------------- belső

func _build_interior() -> void:
	var r := INTERIOR
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			_tile(FLOOR_TILES[(x + y) % 2], Vector2i(x, y), -10).modulate = FLOOR_TINT
	# Hátsó fal: italos polcok, középen a kandalló.
	for x in range(r.position.x, r.end.x):
		var col: int = SHELF_COLUMNS[(x - r.position.x) % SHELF_COLUMNS.size()]
		_tile(Vector2i(col, 14), Vector2i(x, r.position.y), -9)
		_tile(Vector2i(col, 12), Vector2i(x, r.position.y - 1), -9)
	for i in 2:
		_tile(FIREPLACE[i], Vector2i(r.position.x + 2 + i, r.position.y), -8)
		_tile(FIREPLACE[i], Vector2i(r.end.x - 4 + i, r.position.y), -8)
	_light(_center(Vector2i(r.position.x + 3, r.position.y)), Color(1, 0.6, 0.3), 2.2, 1.3)
	_light(_center(Vector2i(r.end.x - 3, r.position.y)), Color(1, 0.6, 0.3), 2.2, 1.3)
	# Oldalfalak és a déli fal (sötét gerendák), a bejárat a déli fal közepén.
	_wall_rect(Rect2(Vector2(r.position.x - 1, r.position.y - 1) * TILE, Vector2(TILE, (r.size.y + 2) * TILE)))
	_wall_rect(Rect2(Vector2(r.end.x, r.position.y - 1) * TILE, Vector2(TILE, (r.size.y + 2) * TILE)))
	_wall_rect(Rect2(Vector2(r.position.x, r.end.y) * TILE, Vector2((INTERIOR_DOOR.x - r.position.x) * TILE, TILE)))
	_wall_rect(Rect2(Vector2(INTERIOR_DOOR.x + 2, r.end.y) * TILE, Vector2((r.end.x - INTERIOR_DOOR.x - 2) * TILE, TILE)))
	_solid(Rect2(Vector2(r.position.x, r.position.y - 1) * TILE, Vector2(r.size.x * TILE, TILE * 1.6)))
	for i in 2:
		_tile(DOUBLE_DOOR[i], Vector2i(INTERIOR_DOOR.x + i, r.end.y), -8)
	_solid(Rect2(Vector2(INTERIOR_DOOR.x, r.end.y + 1) * TILE, Vector2(2 * TILE, TILE)))
	_build_bar()
	_build_tables()


## A pult a bejárattal szemben (a hátsó fal előtt), mögötte a kocsmáros.
func _build_bar() -> void:
	var y := INTERIOR.position.y + 3
	var x0 := INTERIOR_DOOR.x - 4
	var pieces := [Rect2(4 * 17, 7 * 17, 16, 16)]
	for i in 8:
		pieces.append(Rect2((5 + i % 2) * 17, 7 * 17, 16, 16))
	pieces.append(Rect2(7 * 17, 7 * 17, 16, 16))
	for i in pieces.size():
		var piece := _sprite(INDOOR, pieces[i], _center(Vector2i(x0 + i, y)), 0, _entities)
		# Korsók a pulton.
		if i in [1, 4, 7]:
			_on_table(piece, DRINKS[i % DRINKS.size()], Vector2(0, -6), 0.8)
	_solid(Rect2(Vector2(x0, y) * TILE, Vector2(pieces.size() * TILE, TILE)))
	var barkeep := AnimatedSprite2D.new()
	barkeep.sprite_frames = SpriteSheet.character_frames(BARKEEP, true)
	barkeep.scale = Vector2(2, 2)
	barkeep.offset.y = -BARKEEP.size.y / 2.0
	barkeep.position = _center(Vector2i(INTERIOR_DOOR.x, y - 1)) + Vector2(16, 12)
	barkeep.play("idle")
	_entities.add_child(barkeep)
	set_meta("barkeep_position", barkeep.position + Vector2(0, 2 * TILE))
	# Jel a kocsmáros fölött: "!" ha vehetsz fel küldetést, "?" ha leadhatod a kész küldetést.
	_quest_mark = MenuStyle.title_label("!", 40, MenuStyle.GOLD)
	_quest_mark.size = Vector2(40, 46)
	_quest_mark.position = barkeep.position + Vector2(-20, -84)
	_quest_mark.z_index = 20
	add_child(_quest_mark)
	var bob := _quest_mark.create_tween().set_loops()
	bob.tween_property(_quest_mark, "position:y", _quest_mark.position.y - 6, 0.6).set_trans(Tween.TRANS_SINE)
	bob.tween_property(_quest_mark, "position:y", _quest_mark.position.y, 0.6).set_trans(Tween.TRANS_SINE)


## 10 asztal, mindegyiknél 2 szék (balra és jobbra), az asztalokon italok és gyertyák.
## A középső folyosó szabadon marad a bejárattól a pultig.
func _build_tables() -> void:
	var columns := [INTERIOR.position.x + 3, INTERIOR.position.x + 7, INTERIOR.end.x - 8, INTERIOR.end.x - 4]
	var rows := [INTERIOR.position.y + 6, INTERIOR.position.y + 9, INTERIOR.position.y + 12]
	var tables: Array[Vector2i] = []
	for row in rows.slice(0, 2):
		for col in columns:
			tables.append(Vector2i(col, row))
	tables.append(Vector2i(columns[0], rows[2]))
	tables.append(Vector2i(columns[3], rows[2]))
	for t in tables:
		# Az asztal (és a székek) a y-szerint rendezett rétegbe kerülnek, hogy a játékos
		# előttük és mögöttük is helyesen látsszon; az italok és a gyertya az asztal "gyerekei".
		var table := _tile(TABLE, t, 0, _entities)
		_solid(Rect2(Vector2(t) * TILE + Vector2(4, 8), Vector2(TILE - 8, TILE - 12)))
		_on_table(table, DRINKS.pick_random(), Vector2(-3, -6), 0.7)
		if randf() < 0.6:
			_on_table(table, DRINKS.pick_random(), Vector2(4, -5), 0.7)
		_on_table(table, CANDLE, Vector2(0, -8), 0.6)
		_light(_center(t) + Vector2(0, -16), Color(1, 0.75, 0.45), 0.9, 0.7)
		for side in [-1, 1]:
			var chair_tile := t + Vector2i(side, 0)
			var chair := _tile(CHAIR_FACING_RIGHT if side < 0 else CHAIR_FACING_LEFT, chair_tile, 0, _entities)
			chair.position.y -= 2
			seats.append([_center(chair_tile), side < 0])


## Egy tárgy (ital, gyertya) az asztal lapján, az asztal sprite-jához képest (az asztal 2x-es).
func _on_table(table: Sprite2D, coords: Vector2i, offset: Vector2, scale_factor: float) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = RPG
	atlas.region = Rect2(Vector2(coords) * 17.0, Vector2(16, 16))
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.position = offset
	sprite.scale = Vector2.ONE * scale_factor
	table.add_child(sprite)


# ---------------------------------------------------------------- karakterek

## Minden nem aktív, már játszható karakter a saját székén ül (Gáspár csak a 30. emelet után).
func _seat_characters() -> void:
	for id: String in Characters.ALL:
		if id != Progress.character and Characters.is_unlocked(id):
			_sit(id)


## Gáspár beért a kocsmába (a táborból sétált ide): leül a helyére, és onnantól játszható.
func seat_gaspar() -> void:
	if _seated.has("veteran") or Progress.character == "veteran":
		return
	_sit("veteran")


func _sit(id: String) -> AnimatedSprite2D:
	var seat: Array = seats[int(Characters.data(id)["seat"]) % seats.size()]
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = Characters.frames(id)
	sprite.scale = Vector2(2, 2)
	sprite.offset = Vector2(0, -14)
	# Ülve: a szék fölött, az asztal felé fordulva.
	sprite.position = seat[0] + Vector2(0, 10)
	sprite.flip_h = not seat[1]
	sprite.play("idle")
	_entities.add_child(sprite)
	_seated[id] = sprite
	return sprite


## Karakterváltás: a kiválasztott feláll (őt irányítod), a mostani a helyére sétál és leül.
func _switch_to(id: String) -> void:
	if GameState.on_break:
		message.emit("Pihenő közben nem válthatsz karaktert.")
		Audio.play("ui_error")
		return
	_busy = true
	var old_id := Progress.character
	var new_sprite: AnimatedSprite2D = _seated[id]
	_seated.erase(id)
	var stand_at := new_sprite.position + Vector2(0, 26)
	new_sprite.queue_free()
	var old_position := _player.global_position
	_player.global_position = stand_at
	_player.call("set_character", id)
	Audio.play("equip")
	message.emit("Mostantól vele játszol: %s" % Characters.data(id)["name"])
	# A régi karakter a saját székéhez sétál, és leül.
	var walker := _sit(old_id)
	var seat_position := walker.position
	walker.position = old_position
	walker.play("run")
	walker.flip_h = seat_position.x < old_position.x
	var duration := clampf(old_position.distance_to(seat_position) / 130.0, 0.3, 3.0)
	var tween := create_tween()
	tween.tween_property(walker, "position", seat_position, duration)
	tween.tween_callback(func() -> void:
		var seat: Array = seats[int(Characters.data(old_id)["seat"]) % seats.size()]
		walker.flip_h = not seat[1]
		walker.play("idle")
		_busy = false)


# ---------------------------------------------------------------- belépés / kilépés, E

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_prompt = MenuStyle.title_label("", 32, MenuStyle.GOLD)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -210
	_prompt.offset_bottom = -160
	_prompt.offset_left = -500
	_prompt.offset_right = 500
	_prompt.modulate.a = 0.0
	layer.add_child(_prompt)


## Ami előtt a játékos áll: ["door" | "exit" | "barkeep" | karakter-id, felirat] vagy [].
func _focus() -> Array:
	if not is_instance_valid(_player) or _busy:
		return []
	var at: Vector2 = _player.global_position
	if not _inside:
		if at.distance_to(door_position()) < INTERACT_RANGE:
			return ["door", "[E] Belépés: Mélységi kocsma"]
		return []
	if at.distance_to(_center(INTERIOR_DOOR) + Vector2(TILE / 2.0, TILE / 2.0)) < INTERACT_RANGE:
		return ["exit", "[E] Kilépés a városba"]
	if at.distance_to(get_meta("barkeep_position")) < INTERACT_RANGE + 10:
		return ["barkeep", "[E] Küldetések (kocsmáros)"]
	for id: String in _seated:
		if at.distance_to(_seated[id].position) < INTERACT_RANGE:
			return [id, "[E] %s" % Characters.data(id)["name"]]
	return []


func _process(delta: float) -> void:
	var focus := _focus()
	if not focus.is_empty():
		_prompt.text = focus[1]
	var target := 1.0 if not focus.is_empty() and not get_tree().paused else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)
	if _quest_mark:
		# Zöld "?" a kocsmáros fölött, ha van átvehető jutalom.
		_quest_mark.visible = not Quests.ready_ids().is_empty()
		_quest_mark.text = "?"
		_quest_mark.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55))
	# Egy ülő karakter mellett oldalt megjelenik a bemutatkozása.
	var character_id: String = focus[0] if not focus.is_empty() and Characters.ALL.has(focus[0]) else ""
	if character_id != _intro_for:
		_intro_for = character_id
		if not character_id.is_empty():
			_fill_intro(character_id)
	var intro_target := 1.0 if not character_id.is_empty() and not get_tree().paused else 0.0
	_intro.modulate.a = move_toward(_intro.modulate.a, intro_target, delta * 6.0)
	_intro.visible = _intro.modulate.a > 0.01


## A karakter bemutatkozó panelje (jobb oldalt): kép, név, szerep, történet, tulajdonságok.
func _build_intro() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	_intro = PanelContainer.new()
	_intro.add_theme_stylebox_override("panel", UiStyle.decorated_panel())
	_intro.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	_intro.offset_left = -470
	_intro.offset_right = -30
	_intro.offset_top = -260
	_intro.offset_bottom = 260
	_intro.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_intro.modulate.a = 0.0
	_intro.visible = false
	layer.add_child(_intro)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_intro.add_child(box)
	_intro_title = UiStyle.title_bar("")
	box.add_child(_intro_title)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	box.add_child(header)
	_intro_portrait = TextureRect.new()
	_intro_portrait.custom_minimum_size = Vector2(72, 112)
	_intro_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_intro_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(_intro_portrait)
	_intro_role = UiStyle.label("", 18, UiStyle.INK)
	_intro_role.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_intro_role)
	_intro_text = RichTextLabel.new()
	_intro_text.bbcode_enabled = true
	_intro_text.fit_content = true
	_intro_text.scroll_active = false
	_intro_text.custom_minimum_size.x = 390
	_intro_text.add_theme_color_override("default_color", UiStyle.INK_LIGHT)
	_intro_text.add_theme_font_size_override("normal_font_size", 15)
	box.add_child(_intro_text)
	box.add_child(UiStyle.label("[E] Átveszed az irányítást", 15, UiStyle.INK))


func _fill_intro(id: String) -> void:
	var definition := Characters.data(id)
	(_intro_title.get_child(0) as Label).text = definition["name"]
	_intro_portrait.texture = Characters.frames(id).get_frame_texture("idle", 0)
	_intro_role.text = definition.get("role", "")
	var lines: Array[String] = ["[i]%s[/i]" % definition.get("story", ""), ""]
	for trait_text: String in definition.get("traits", []):
		lines.append("[color=#3c6a32]•[/color] " + trait_text)
	_intro_text.text = "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or get_tree().paused:
		return
	var focus := _focus()
	if focus.is_empty():
		return
	get_viewport().set_input_as_handled()
	match focus[0]:
		"door": _enter()
		"exit": _exit()
		"barkeep":
			# A kocsmáros küldetéseket ad (és itt lehet leadni őket).
			Audio.play("ui_open")
			message.emit("Kocsmáros: \"%s\"" % BARKEEP_LINES[_barkeep_line % BARKEEP_LINES.size()])
			_barkeep_line += 1
			_camp.get_node("Menus").call("open_menu", _quest_panel)
		_: _switch_to(focus[0])


func _enter() -> void:
	Audio.play("door_unlock", -4.0)
	_inside = true
	var limits := Rect2(Vector2(INTERIOR.position - Vector2i(2, 3)) * TILE, Vector2(INTERIOR.size + Vector2i(4, 6)) * TILE)
	_camp.call("teleport_player", _center(INTERIOR_DOOR) + Vector2(TILE / 2.0, -TILE), limits, INTERIOR_LIGHT)


func _exit() -> void:
	Audio.play("door_unlock", -4.0)
	_inside = false
	_camp.call("teleport_player", door_position() + Vector2(0, 30), Rect2(), Color.BLACK)


# ---------------------------------------------------------------- segédek

func _center(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE


## Egy csempe a Kenney RPG lapról (16 px + 1 px hézag), 2x-es nagyításban.
func _tile(coords: Vector2i, tile: Vector2i, z: int, parent: Node = null) -> Sprite2D:
	return _sprite(RPG, Rect2(Vector2(coords) * 17.0, Vector2(16, 16)), _center(tile), z, parent)


func _sprite(texture: Texture2D, region: Rect2, at: Vector2, z: int, parent: Node = null) -> Sprite2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.scale = Vector2(2, 2)
	sprite.position = at
	sprite.z_index = z
	(parent if parent else self).add_child(sprite)
	return sprite


func _prop(texture: Texture2D, region: Rect2, at: Vector2) -> void:
	var holder := Node2D.new()
	holder.position = at + Vector2(0, 16)
	_entities.add_child(holder)
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.scale = Vector2(2, 2)
	sprite.position = Vector2(0, -16)
	holder.add_child(sprite)
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(26, 12)
	shape.shape = box
	shape.position = Vector2(0, -6)
	body.add_child(shape)
	holder.add_child(body)


func _solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	add_child(body)


## Sötét gerendafal (szilárd).
func _wall_rect(rect: Rect2) -> void:
	var wall := ColorRect.new()
	wall.color = Color(0.16, 0.1, 0.08)
	wall.position = rect.position
	wall.size = rect.size
	wall.z_index = -9
	add_child(wall)
	_solid(rect)


func _light(at: Vector2, color: Color, size: float, energy: float) -> void:
	var light := PointLight2D.new()
	var gradient := Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(0, 0, 0, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	texture.width = 256
	texture.height = 256
	light.texture = texture
	light.texture_scale = size
	light.energy = energy
	light.position = at
	add_child(light)
