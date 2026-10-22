class_name Ruin
extends Node2D
## Romos ház a nyugati tisztáson, a sáros ösvény végén (a várossal szemben): félig leomlott,
## a keleti fele egy kőkupac. Bent nagyon sötét (nincs fényforrás, csak a saját lámpásod),
## pókhálók, törött üvegek, felborult bútorok; hátul a ládák mögött egy rejtett ajtó. Mögötte
## a tolvaj rejtekszobája egyetlen gyertyával, tele lopott holmival (lásd Thief). Az első
## belépéskor a tolvaj rád kérdez. A ház mellett egy kút, az alján egy idegen (Stranger), aki
## létrát kér; a létra a tisztás délnyugati sarkában hever, egy bokor tövében.
## (A tábor építi fel: setup(camp) + build(), mint a Várost.)

signal message(text: String)

const TILE := 32
const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const CONTAINERS: Texture2D = preload("res://assets/shop/barrels_and_boxes.png")
const POTTERY: Texture2D = preload("res://assets/shop/pottery.png")
const DUNGEON: Texture2D = preload("res://assets/0x72_dungeon/0x72_DungeonTilesetII_v1.7.png")
const PUNY: Texture2D = preload("res://assets/decor/puny_dungeon.png")
const COBWEB: Texture2D = preload("res://assets/decor/cobweb.png")

## A ház a nyugati tisztás északi részén, az ajtaja az ösvény felé néz.
const TOP_LEFT := Vector2i(-25, 10)
const SIZE := Vector2i(8, 5)
const DOOR_COLUMN := -23
## Ennyi oszlop (balról) áll még a tetőből; a többi leomlott.
const ROOF_COLUMNS := 5
const STONE_TINT := Color(0.8, 0.78, 0.76)
## Kifakult, mohás tetőcserép.
const ROOF_TINT := Color(0.85, 0.68, 0.58)

## A ház belseje és a rejtekszoba, messze a pályától (mint a kocsma belseje).
const INTERIOR := Rect2i(240, 0, 14, 9)
const INTERIOR_DOOR := Vector2i(246, 9)
const HIDDEN_DOOR := Vector2i(243, 0)
const BACKROOM := Rect2i(270, 0, 9, 6)
const BACKROOM_DOOR := Vector2i(274, 6)
const THIEF_TILE := Vector2i(274, 1)
## Bent szinte teljes sötét (csak a lámpásod világít); a rejtekszobában egy gyertya.
const RUIN_LIGHT := Color(0.06, 0.06, 0.09)
const BACKROOM_LIGHT := Color(0.17, 0.14, 0.13)
const LANTERN_INSIDE := 0.55
const LANTERN_OUTSIDE := 0.5
const INTERACT_RANGE := 52.0
## A kút (a ház mellett, keletre) és a létra helye (a tisztás délnyugati sarkában, egy bokor tövében).
const WELL: Texture2D = preload("res://assets/props/well.png")
const LADDER: Texture2D = preload("res://assets/props/ladder.png")
const WELL_TILE := Vector2i(-14, 12)
const LADDER_TILE := Vector2i(-27, 22)
const BUSH := Vector2i(19, 9)
const THIEF_RANGE := 84.0

const FLOOR_TILES: Array[Vector2i] = [Vector2i(8, 2), Vector2i(8, 3)]
const CHAIR := Vector2i(21, 4)
const COIN := Rect2(289, 385, 6, 7)
const CHEST_FULL := Rect2(336, 416, 16, 16)
const FLASKS: Array[Rect2] = [Rect2(288, 336, 16, 16), Rect2(304, 336, 16, 16), Rect2(320, 336, 16, 16)]
const GEMS: Array[Rect2] = [Rect2(256, 144, 16, 16), Rect2(256, 160, 16, 16), Rect2(256, 176, 16, 16)]
const KEY := Rect2(320, 128, 16, 16)
## Lopott tárgyak a rejtekszobában (csak díszlet; a képük az Items-ből jön).
const STOLEN := ["sword_ruby", "ring_sapphire", "amulet_blood", "helmet_great", "trinket_clock", "dagger_curved",
	"bow_flame", "amulet_sun", "ring_ruby"]

var _camp: Node2D
var _player: Node2D
var _entities: Node2D
var _prompt: Label
var _dialogue: DialoguePanel
## "outside" | "ruin" | "backroom"
var _where := "outside"
var _busy := false
var _rng := RandomNumberGenerator.new()
var _thief: AnimatedSprite2D
var _well_dialogue: DialoguePanel
var _ladder: Node2D
var _lorinc: AnimatedSprite2D


## A tolvaj (Bence) a levél után a kocsmába költözött: a rejtekhely üres.
static func thief_gone() -> bool:
	return Progress.npc_quest_state(Thief.TAVERN_FLAG) == "done"


func setup(camp: Node2D) -> void:
	_camp = camp
	_entities = camp.get_node("Entities")
	_player = camp.get_node("Entities/Player")
	_dialogue = DialoguePanel.new()
	_dialogue.name = "ThiefDialogue"
	_dialogue.npc_id = Thief.ID
	_dialogue.npc_name = Thief.NAME
	_dialogue.portrait = Thief.portrait()
	_dialogue.options_provider = func() -> Array[Dictionary]:
		return Thief.options(_player.get_node("Inventory"))
	camp.add_child.call_deferred(_dialogue)
	# A kútba esett idegen: amíg nem mondja meg a nevét, "???" (és csak a sziluettje látszik).
	_well_dialogue = DialoguePanel.new()
	_well_dialogue.name = "WellDialogue"
	_well_dialogue.npc_id = Stranger.ID
	_well_dialogue.options_provider = func() -> Array[Dictionary]:
		_refresh_stranger_panel()
		return Stranger.options(_player.get_node("Inventory"))
	camp.add_child.call_deferred(_well_dialogue)


## A ház ajtaja előtti sáros csempék (a tábor rajzolja ki a sárral együtt).
static func path_tiles() -> Array[Vector2i]:
	var bottom := TOP_LEFT.y + SIZE.y
	return [Vector2i(DOOR_COLUMN, bottom), Vector2i(DOOR_COLUMN + 1, bottom)]


## Ide nem kerülhet fa / virág (a ház és körülötte).
static func blocked_rect() -> Rect2i:
	return Rect2i(TOP_LEFT - Vector2i(2, 2), SIZE + Vector2i(4, 3))


func build() -> void:
	# Mindig ugyanúgy omlott össze (nem minden betöltéskor máshogy).
	_rng.seed = 1771
	_build_exterior()
	_build_interior()
	_build_backroom()
	_build_well()
	_build_ui()


# ---------------------------------------------------------------- külső

func _build_exterior() -> void:
	var house := Node2D.new()
	house.modulate = STONE_TINT
	add_child(house)
	var tl := TOP_LEFT
	var w := SIZE.x
	for x in w:
		if x < ROOF_COLUMNS:
			var piece := 0 if x == 0 else (2 if x == ROOF_COLUMNS - 1 else 1)
			if x < ROOF_COLUMNS - 1:
				_tile(Town.ROOF_TOP[piece], tl + Vector2i(x, 0), -6, house).modulate = ROOF_TINT
			_tile(Town.ROOF_MID[piece], tl + Vector2i(x, 1), -6, house).modulate = ROOF_TINT
			_tile(Town.ROOF_LOW[piece], tl + Vector2i(x, 2), -6, house).modulate = ROOF_TINT
		if x <= ROOF_COLUMNS:
			_tile(Town.WALL_BAND, tl + Vector2i(x, 3), -6, house)
		if x != w - 2:
			_tile(Town.WALL_BOARDS, tl + Vector2i(x, 4), -6, house)
	# Betört ablak, lyuk a falon.
	_tile(Town.WINDOW, tl + Vector2i(2, 3), -5, house).modulate = Color(0.35, 0.35, 0.4)
	_dark_rect(Rect2(Vector2(tl + Vector2i(w - 2, 4)) * TILE + Vector2(4, 6), Vector2(TILE - 8, TILE - 6)), -6)
	# Az ajtó: az egyik szárny a helyén, a másik félrebillenve lóg; mögötte sötét.
	_dark_rect(Rect2(Vector2(DOOR_COLUMN, tl.y + 4) * TILE, Vector2(2 * TILE, TILE)), -6)
	_tile(Town.DOUBLE_DOOR[0], Vector2i(DOOR_COLUMN, tl.y + 4), -5, house)
	var hanging := _tile(Town.DOUBLE_DOOR[1], Vector2i(DOOR_COLUMN + 1, tl.y + 4), -5, house)
	hanging.rotation = 0.28
	hanging.position += Vector2(4, 3)
	# A leomlott keleti rész: kő- és gerendakupac a fal helyén és előtte.
	_rubble(_center(tl + Vector2i(w - 2, 2)) + Vector2(0, 10), Vector2(70, 46), 26, -4)
	_rubble(_center(tl + Vector2i(w - 1, 4)) + Vector2(12, 14), Vector2(40, 18), 10, -4)
	for beam: Array in [[Vector2(-10, -26), 0.7], [Vector2(18, -8), -0.35], [Vector2(-30, 6), 0.15]]:
		var plank := ColorRect.new()
		plank.color = Color(0.3, 0.2, 0.13)
		plank.size = Vector2(56, 7)
		plank.pivot_offset = plank.size / 2.0
		plank.position = _center(tl + Vector2i(w - 2, 2)) + beam[0] - plank.size / 2.0
		plank.rotation = beam[1]
		plank.z_index = -3
		add_child(plank)
	for i in 5:
		var stone := _sprite(PUNY, Rect2(256 + 16 * (i % 4), 208, 16, 16),
			_center(tl + Vector2i(w - 3 + i % 3, 5)) + Vector2(_rng.randf_range(-12, 12), _rng.randf_range(-10, 4)), -4)
		stone.scale = Vector2(0.9, 0.9)
		stone.modulate = Color(0.75, 0.72, 0.7)
	_cobweb(tl + Vector2i(0, 3), false, false, -4)
	# Az épület és a kőkupac szilárd (az ajtó előtt lehet megállni).
	_solid(Rect2(Vector2(tl) * TILE, Vector2(SIZE) * TILE - Vector2(0, 6)))
	_solid(Rect2(Vector2(tl + Vector2i(w - 3, 5)) * TILE, Vector2(3 * TILE, TILE * 0.6)))


func door_position() -> Vector2:
	return Vector2(DOOR_COLUMN + 1, TOP_LEFT.y + SIZE.y) * TILE + Vector2(0, 16)


# ---------------------------------------------------------------- a romos szoba

func _build_interior() -> void:
	var r := INTERIOR
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			# Itt-ott hiányzik a padló (alatta föld).
			_tile(FLOOR_TILES[(x + y) % 2], Vector2i(x, y), -10).modulate = Color(0.55, 0.47, 0.42)
			if _rng.randf() < 0.05 and y > r.position.y:
				var hole := Vector2(_rng.randf_range(12, 26), _rng.randf_range(8, 18))
				_dark_rect(Rect2(_center(Vector2i(x, y)) - hole / 2.0, hole), -10, Color(0.2, 0.15, 0.11))
	# Hátsó fal: kopott deszkák, betört ablak; a hátsó fal mögött ott a rejtett ajtó.
	for x in range(r.position.x, r.end.x):
		_tile(Town.WALL_BAND, Vector2i(x, r.position.y - 1), -9).modulate = Color(0.5, 0.46, 0.44)
		_tile(Town.WALL_BOARDS, Vector2i(x, r.position.y), -9).modulate = Color(0.5, 0.46, 0.44)
	_tile(Town.WINDOW, Vector2i(r.end.x - 5, r.position.y - 1), -8).modulate = Color(0.3, 0.3, 0.36)
	_tile(Town.DOUBLE_DOOR[0], HIDDEN_DOOR, -8).modulate = Color(0.55, 0.5, 0.48)
	_walls(r, INTERIOR_DOOR, 2)
	for i in 2:
		_tile(Town.DOUBLE_DOOR[i], Vector2i(INTERIOR_DOOR.x + i, r.end.y), -8).modulate = Color(0.6, 0.55, 0.5)
	# A leomlott sarok (jobbra hátul): kőkupac és lezuhant gerendák.
	_rubble(_center(Vector2i(r.end.x - 2, r.position.y + 1)), Vector2(62, 44), 22, 0)
	_solid(Rect2(Vector2(r.end.x - 3, r.position.y) * TILE, Vector2(3 * TILE, 2 * TILE)))
	var beam := ColorRect.new()
	beam.color = Color(0.28, 0.19, 0.12)
	beam.size = Vector2(120, 9)
	beam.pivot_offset = beam.size / 2.0
	beam.position = _center(Vector2i(r.end.x - 4, r.position.y + 3)) - beam.size / 2.0
	beam.rotation = -0.5
	beam.z_index = -7
	add_child(beam)
	# Törött üveg az ablak alatt és szerteszét, ledőlt üvegek.
	_glass(_center(Vector2i(r.end.x - 5, r.position.y + 1)), 9)
	_glass(_center(Vector2i(r.position.x + 3, r.position.y + 5)), 6)
	_glass(_center(Vector2i(r.position.x + 9, r.position.y + 6)), 5)
	for i in FLASKS.size():
		var flask := _sprite(DUNGEON, FLASKS[i], _center(Vector2i(r.position.x + 2 + i * 4, r.position.y + 4 + i % 2)), -7)
		flask.rotation = PI / 2.0 + i
		flask.modulate = Color(0.7, 0.7, 0.7)
	# Felborult asztal és székek.
	var table := _tile(Town.TABLE, Vector2i(r.position.x + 7, r.position.y + 4), 0, _entities)
	table.rotation = 0.5
	_solid(Rect2(Vector2(r.position.x + 7, r.position.y + 4) * TILE + Vector2(4, 8), Vector2(TILE - 8, TILE - 12)))
	_tile(CHAIR, Vector2i(r.position.x + 5, r.position.y + 5), 0, _entities).rotation = PI / 2.0
	_tile(CHAIR, Vector2i(r.position.x + 9, r.position.y + 3), 0, _entities).rotation = -2.0
	# Ládák a rejtett ajtó előtt (köztük egy szűk rés), mellettük hordó és korsók.
	_prop(CONTAINERS, Rect2(16, 0, 16, 16), _center(HIDDEN_DOOR + Vector2i(-1, 1)))
	_prop(CONTAINERS, Rect2(16, 0, 16, 16), _center(HIDDEN_DOOR + Vector2i(1, 1)))
	_prop(CONTAINERS, Rect2(32, 0, 16, 16), _center(HIDDEN_DOOR + Vector2i(-2, 2)))
	_prop(CONTAINERS, Rect2(0, 0, 16, 16), _center(HIDDEN_DOOR + Vector2i(2, 2)))
	_sprite(CONTAINERS, Rect2(32, 0, 16, 16), _center(HIDDEN_DOOR + Vector2i(-1, 1)) + Vector2(2, -18), 1)
	_sprite(POTTERY, Rect2(16, 16, 16, 16), _center(Vector2i(r.position.x + 1, r.end.y - 2)), -7).rotation = 1.4
	# Pókhálók a sarkokban és a gerendák alatt.
	_cobweb(r.position, false, false, -7)
	_cobweb(Vector2i(r.end.x - 1, r.position.y), true, false, -7)
	_cobweb(Vector2i(r.position.x, r.end.y - 1), false, true, -7)
	_cobweb(Vector2i(r.end.x - 1, r.end.y - 1), true, true, -7)
	_cobweb(Vector2i(r.position.x + 6, r.position.y), false, false, -7)
	_cobweb(HIDDEN_DOOR + Vector2i(1, 0), true, false, -7)
	_cobweb(Vector2i(r.position.x, r.position.y + 4), false, false, -7)


# ---------------------------------------------------------------- a tolvaj rejtekszobája

func _build_backroom() -> void:
	var r := BACKROOM
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			_tile(FLOOR_TILES[(x + y) % 2], Vector2i(x, y), -10).modulate = Town.FLOOR_TINT
	# Hátul polcok (tele lopott üvegekkel), elöl az ajtó.
	for x in range(r.position.x, r.end.x):
		var col: int = Town.SHELF_COLUMNS[(x - r.position.x) % Town.SHELF_COLUMNS.size()]
		_tile(Vector2i(col, 14), Vector2i(x, r.position.y), -9)
		_tile(Vector2i(col, 12), Vector2i(x, r.position.y - 1), -9)
	_walls(r, BACKROOM_DOOR, 1)
	_tile(Town.DOUBLE_DOOR[0], Vector2i(BACKROOM_DOOR.x, r.end.y), -8)
	# A tolvaj az asztala mögött, az asztalon gyertya (az egyetlen fény) és arany.
	_thief = AnimatedSprite2D.new()
	_thief.sprite_frames = Thief.frames()
	_thief.scale = Vector2(2, 2)
	_thief.offset = Vector2(0, -14)
	_thief.position = _center(THIEF_TILE) + Vector2(0, 10)
	_thief.play()
	_entities.add_child(_thief)
	var table_tile := THIEF_TILE + Vector2i(0, 1)
	var table := _tile(Town.TABLE, table_tile, 0, _entities)
	_solid(Rect2(Vector2(table_tile) * TILE + Vector2(-4, 8), Vector2(TILE + 8, TILE - 12)))
	_solid(Rect2(Vector2(THIEF_TILE) * TILE + Vector2(6, 4), Vector2(TILE - 12, TILE - 8)))
	_on_table(table, RPG, Rect2(Vector2(Town.CANDLE) * 17.0, Vector2(16, 16)), Vector2(-4, -8), 0.6)
	_on_table(table, DUNGEON, COIN, Vector2(5, -5), 0.8)
	_on_table(table, DUNGEON, COIN, Vector2(8, -3), 0.8)
	_on_table(table, PUNY, GEMS[2], Vector2(3, -7), 0.5)
	_light(_center(table_tile) + Vector2(-6, -20), Color(1, 0.7, 0.4), 1.4, 1.1)
	# Zsákmány mindenütt: nyitott, teli ládák, aranykupacok, drágakövek, lopott tárgyak.
	_sprite(DUNGEON, CHEST_FULL, _center(Vector2i(r.position.x + 1, r.position.y + 1)), -7)
	_sprite(DUNGEON, CHEST_FULL, _center(Vector2i(r.end.x - 2, r.position.y + 1)), -7)
	_solid(Rect2(Vector2(r.position.x + 1, r.position.y + 1) * TILE + Vector2(4, 4), Vector2(TILE - 8, TILE - 8)))
	_solid(Rect2(Vector2(r.end.x - 2, r.position.y + 1) * TILE + Vector2(4, 4), Vector2(TILE - 8, TILE - 8)))
	for pile: Array in [[Vector2i(r.position.x + 2, r.position.y + 1), 14], [Vector2i(r.end.x - 3, r.position.y + 1), 12],
			[Vector2i(r.position.x, r.position.y + 3), 18], [Vector2i(r.end.x - 1, r.position.y + 3), 16],
			[Vector2i(r.position.x + 2, r.end.y - 1), 9], [Vector2i(r.end.x - 2, r.end.y - 2), 10]]:
		_coins(_center(pile[0]), pile[1])
	for i in GEMS.size():
		_sprite(PUNY, GEMS[i], _center(Vector2i(r.position.x + 1 + i, r.position.y + 2)) + Vector2(_rng.randf_range(-6, 6), 8),
			-7).scale = Vector2(1.2, 1.2)
	_sprite(PUNY, KEY, _center(Vector2i(r.end.x - 3, r.position.y + 3)), -7).rotation = 0.6
	var spots := [Vector2i(r.position.x + 1, r.position.y + 4), Vector2i(r.position.x + 2, r.position.y + 3),
		Vector2i(r.end.x - 2, r.position.y + 4), Vector2i(r.end.x - 3, r.position.y + 2), Vector2i(r.end.x - 1, r.position.y + 2),
		Vector2i(r.position.x, r.position.y + 2), Vector2i(r.end.x - 1, r.end.y - 1), Vector2i(r.position.x + 3, r.end.y - 2),
		Vector2i(r.position.x, r.end.y - 1)]
	for i in STOLEN.size():
		var icon := Sprite2D.new()
		icon.texture = Items.icon(Items.create(STOLEN[i]))
		var longest := maxf(icon.texture.get_width(), icon.texture.get_height())
		icon.scale = Vector2.ONE * (26.0 / longest)
		icon.rotation = _rng.randf_range(-0.6, 0.6)
		icon.position = _center(spots[i]) + Vector2(_rng.randf_range(-6, 6), _rng.randf_range(-4, 6))
		icon.z_index = -7
		add_child(icon)
	_prop(CONTAINERS, Rect2(0, 0, 16, 16), _center(Vector2i(r.position.x, r.end.y - 2)))
	_prop(CONTAINERS, Rect2(16, 0, 16, 16), _center(Vector2i(r.end.x - 1, r.end.y - 3)))
	_sprite(POTTERY, Rect2(0, 0, 16, 16), _center(Vector2i(r.position.x + 3, r.position.y + 1)) + Vector2(0, -6), -7)
	_cobweb(Vector2i(r.position.x, r.end.y - 1), false, true, -7)


# ---------------------------------------------------------------- a kút és a létra

func _build_well() -> void:
	# A kút (szilárd), mellette egy vödör; a megmentés után Lőrinc áll mellette.
	var holder := Node2D.new()
	holder.position = _center(WELL_TILE) + Vector2(0, 16)
	_entities.add_child(holder)
	var well := Sprite2D.new()
	well.texture = WELL
	well.scale = Vector2(2, 2)
	well.position = Vector2(0, -WELL.get_height())
	holder.add_child(well)
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(40, 18)
	shape.shape = box
	shape.position = Vector2(0, -10)
	body.add_child(shape)
	holder.add_child(body)
	_lorinc = AnimatedSprite2D.new()
	_lorinc.sprite_frames = SpriteSheet.character_frames(Stranger.FIGURE, true)
	_lorinc.scale = Vector2(2, 2)
	_lorinc.offset = Vector2(0, -14)
	_lorinc.position = _center(WELL_TILE + Vector2i(-2, 1)) + Vector2(-4, 10)
	_lorinc.play("idle")
	_entities.add_child(_lorinc)
	# A létra a fűben hever, félig egy bokor mögött.
	_ladder = Node2D.new()
	_ladder.position = _center(LADDER_TILE)
	_entities.add_child(_ladder)
	var ladder := Sprite2D.new()
	ladder.texture = LADDER
	ladder.scale = Vector2(1.6, 1.6)
	ladder.rotation = PI / 2.0 - 0.25
	ladder.modulate = Color(0.85, 0.8, 0.75)
	_ladder.add_child(ladder)
	_tile(BUSH, LADDER_TILE + Vector2i(1, 0), 1, _entities).position += Vector2(-10, 4)


## Lőrinc első varázslata a talizmánnal: tűzgolyó a romos ház felé, végig az úton; a karaktered
## meglepődik. Utána Lőrinc Főnixtollat kér (Stranger).
func _fireball() -> void:
	Progress.set_npc_quest(Stranger.FIREBALL_FLAG, "done")
	Progress.save_game()
	var ball := Fireball.new()
	ball.position = _lorinc.position + Vector2(-10, -30)
	_entities.add_child(ball)
	Audio.play("magic", 0.0, 0.1)
	FloatingText.spawn(_entities, _lorinc.position + Vector2(0, -70), "Ignis!", Color(1, 0.6, 0.2), 20)
	var target := door_position() + Vector2(-40, -40)
	var fly := ball.create_tween()
	fly.tween_property(ball, "position", target, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fly.tween_callback(func() -> void:
		Audio.play("boss_slam", -6.0)
		ball.burst())
	await get_tree().create_timer(1.4, false).timeout
	if is_instance_valid(_player):
		FloatingText.spawn(_entities, _player.global_position + Vector2(0, -70), "Hű... ez szép volt!", Color(1, 0.9, 0.6), 22)


## Ide érkezel, ha a kútból felmászol (a kút elé).
func well_exit_position() -> Vector2:
	return _center(WELL_TILE + Vector2i(0, 2))


## A beszélgetés neve és képe: "???" és sziluett, amíg nem mondja meg a nevét.
func _refresh_stranger_panel() -> void:
	_well_dialogue.npc_name = Stranger.display_name()
	_well_dialogue.portrait = Stranger.portrait()
	var name_label: Label = _well_dialogue.get("_name_label")
	var portrait_rect: TextureRect = _well_dialogue.get("_portrait_rect")
	if name_label:
		name_label.text = _well_dialogue.npc_name
	if portrait_rect:
		portrait_rect.texture = _well_dialogue.portrait


# ---------------------------------------------------------------- irányítás

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


## Ami előtt a játékos áll: [művelet, felirat] vagy [].
func _focus() -> Array:
	if not is_instance_valid(_player) or _busy:
		return []
	var at: Vector2 = _player.global_position
	match _where:
		"outside":
			if at.distance_to(door_position()) < INTERACT_RANGE:
				return ["enter", "[E] Belépés: romos ház"]
			# Lőrinc a megmentése után a kúttól kicsit arrébb áll; a kútba onnantól le lehet mászni.
			if Stranger.is_rescued() and _lorinc.visible and at.distance_to(_lorinc.position) < INTERACT_RANGE:
				return ["lorinc", "[E] Beszélgetés: %s" % Stranger.REAL_NAME]
			if at.distance_to(_center(WELL_TILE) + Vector2(0, 20)) < INTERACT_RANGE + 8:
				return ["descend", "[E] Lemászás a kútba"] if Stranger.is_rescued() else ["well", "[E] A kút"]
			if is_instance_valid(_ladder) and _ladder.visible and at.distance_to(_ladder.position) < INTERACT_RANGE:
				return ["ladder", "[E] Létra felvétele"]
		"ruin":
			if at.distance_to(_center(INTERIOR_DOOR) + Vector2(TILE / 2.0, TILE / 2.0)) < INTERACT_RANGE:
				return ["leave", "[E] Kilépés a szabadba"]
			if at.distance_to(_center(HIDDEN_DOOR + Vector2i(0, 1))) < INTERACT_RANGE - 8:
				return ["hidden", "[E] Ajtó a ládák mögött"]
		"backroom":
			if at.distance_to(_center(BACKROOM_DOOR) + Vector2(0, TILE / 2.0)) < INTERACT_RANGE:
				return ["back", "[E] Vissza a romos házba"]
			if at.distance_to(_center(THIEF_TILE)) < THIEF_RANGE:
				if not thief_gone():
					return ["thief", "[E] Beszélgetés: %s" % Thief.NAME]
	return []


func _process(delta: float) -> void:
	if is_instance_valid(_thief):
		_thief.visible = not thief_gone()
	# A létra csak a küldetés alatt hever a fűben (amíg fel nem veszed); Lőrinc a megmentése után áll a kútnál.
	if is_instance_valid(_ladder):
		_ladder.visible = Progress.npc_quest_state(Stranger.LADDER_QUEST) == "active" \
			and Progress.npc_quest_state(Stranger.LADDER_FOUND) != "done"
	if is_instance_valid(_lorinc):
		# A kocsmába költözése után (a beszélgetés bezárásakor) eltűnik a kút mellől.
		if not get_tree().paused:
			_lorinc.visible = Stranger.is_rescued() and not Stranger.moved_to_tavern()
		# A talizmán után, amint bezárult a beszélgetés, tűzgolyót lő a romos ház felé.
		if Progress.npc_quest_state(Stranger.FIREBALL_FLAG) == "pending" and not get_tree().paused:
			_fireball()
	var focus := _focus()
	if not focus.is_empty():
		_prompt.text = focus[1]
	var target := 1.0 if not focus.is_empty() and not get_tree().paused else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or get_tree().paused:
		return
	var focus := _focus()
	if focus.is_empty():
		return
	get_viewport().set_input_as_handled()
	match focus[0]:
		"descend":
			_camp.get_node("WellCave").call("enter")
		"well", "lorinc":
			Audio.play("ui_open")
			_well_dialogue.greeting = Stranger.greeting()
			_refresh_stranger_panel()
			_camp.get_node("Menus").call("open_menu", _well_dialogue)
		"ladder":
			Audio.play("door_unlock", -6.0)
			var where := Stranger.pick_up_ladder(_player.get_node("Inventory"))
			message.emit("Régi létra: %s került." % where)
		"enter":
			_move("ruin", _center(INTERIOR_DOOR) + Vector2(TILE / 2.0, -TILE), INTERIOR, RUIN_LIGHT, "door_unlock")
		"leave":
			_move("outside", door_position() + Vector2(0, 30), Rect2i(), Color.BLACK, "door_unlock")
		"hidden":
			_move("backroom", _center(BACKROOM_DOOR) + Vector2(0, -TILE), BACKROOM, BACKROOM_LIGHT, "chest_open")
			if thief_gone():
				await get_tree().create_timer(0.7).timeout
				message.emit("A rejtekhely üres. Bence a kocsmába költözött.")
			# Az első alkalommal a tolvaj rögtön rád kérdez.
			elif Progress.npc_quest_state(Thief.GOLD_QUEST) == "":
				await get_tree().create_timer(0.7).timeout
				_talk()
		"back":
			_move("ruin", _center(HIDDEN_DOOR + Vector2i(0, 2)), INTERIOR, RUIN_LIGHT, "chest_open")
		"thief":
			_talk()


func _talk() -> void:
	Audio.play("ui_open")
	_dialogue.greeting = Thief.greeting()
	_camp.get_node("Menus").call("open_menu", _dialogue)


## Átlépés: a kamera a szoba határaihoz igazodik (üres = szabadtér); bent erősebb a lámpás.
func _move(where: String, at: Vector2, room: Rect2i, light: Color, sound: String) -> void:
	_busy = true
	_where = where
	Audio.play(sound, -4.0)
	var limits := Rect2()
	if room.has_area():
		limits = Rect2(Vector2(room.position - Vector2i(3, 3)) * TILE, Vector2(room.size + Vector2i(6, 6)) * TILE)
	_camp.call("teleport_player", at, limits, light)
	await get_tree().create_timer(0.25).timeout
	_player.get_node("PointLight2D").energy = LANTERN_OUTSIDE if where == "outside" else LANTERN_INSIDE
	await get_tree().create_timer(0.3).timeout
	_busy = false


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


## Egy kis tárgy az asztal lapján, az asztal sprite-jához képest (az asztal 2x-es).
func _on_table(table: Sprite2D, texture: Texture2D, region: Rect2, offset: Vector2, scale_factor: float) -> void:
	var item := _sprite(texture, region, offset, 1, table)
	item.scale = Vector2(scale_factor, scale_factor)


## Szilárd díszlet (láda, hordó) a y-szerint rendezett rétegben.
func _prop(texture: Texture2D, region: Rect2, at: Vector2) -> void:
	var holder := Node2D.new()
	holder.position = at + Vector2(0, 16)
	_entities.add_child(holder)
	_sprite(texture, region, Vector2(0, -16), 0, holder)
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


## Egy szoba oldal- és déli falai (sötét gerendák), a déli falon `door_width` széles nyílással,
## és a hátsó fal ütközője.
func _walls(r: Rect2i, door: Vector2i, door_width: int) -> void:
	var color := Color(0.12, 0.08, 0.07)
	for rect: Rect2 in [Rect2(Vector2(r.position.x - 1, r.position.y - 1) * TILE, Vector2(TILE, (r.size.y + 2) * TILE)),
			Rect2(Vector2(r.end.x, r.position.y - 1) * TILE, Vector2(TILE, (r.size.y + 2) * TILE)),
			Rect2(Vector2(r.position.x, r.end.y) * TILE, Vector2((door.x - r.position.x) * TILE, TILE)),
			Rect2(Vector2(door.x + door_width, r.end.y) * TILE, Vector2((r.end.x - door.x - door_width) * TILE, TILE))]:
		_dark_rect(rect, -9, color)
		_solid(rect)
	_solid(Rect2(Vector2(r.position.x, r.position.y - 1) * TILE, Vector2(r.size.x * TILE, TILE * 1.6)))
	_solid(Rect2(Vector2(door.x, r.end.y + 1) * TILE, Vector2(door_width * TILE, TILE)))


## Gyertyafény (sugaras színátmenetes PointLight2D).
func _light(at: Vector2, color: Color, size: float, energy: float) -> void:
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
	var light := PointLight2D.new()
	light.texture = texture
	light.texture_scale = size
	light.energy = energy
	light.position = at
	add_child(light)


func _dark_rect(rect: Rect2, z: int, color := Color(0.04, 0.03, 0.03)) -> void:
	var dark := ColorRect.new()
	dark.color = color
	dark.position = rect.position
	dark.size = rect.size
	dark.z_index = z
	add_child(dark)


func _cobweb(tile: Vector2i, flip_h: bool, flip_v: bool, z: int) -> void:
	var web := Sprite2D.new()
	web.texture = COBWEB
	web.scale = Vector2(2, 2)
	web.position = _center(tile)
	web.flip_h = flip_h
	web.flip_v = flip_v
	web.z_index = z
	web.modulate = Color(1, 1, 1, 0.8)
	add_child(web)


func _rubble(at: Vector2, extent: Vector2, count: int, z: int) -> void:
	var heap := RubbleHeap.new()
	heap.position = at
	heap.z_index = z
	for i in count:
		var offset := Vector2(_rng.randf_range(-1, 1) * extent.x, _rng.randf_range(-1, 1) * extent.y) * 0.8
		heap.stones.append([offset, _rng.randf_range(6, 13), _rng.randf_range(0.42, 0.62), _rng.randf()])
	heap.stones.sort_custom(func(a: Array, b: Array) -> bool: return a[0].y < b[0].y)
	add_child(heap)


func _glass(at: Vector2, count: int) -> void:
	var shards := GlassShards.new()
	shards.position = at
	shards.z_index = -7
	for i in count:
		shards.shards.append([Vector2(_rng.randf_range(-18, 18), _rng.randf_range(-10, 10)), _rng.randf_range(2, 6),
			_rng.randf() * TAU])
	add_child(shards)


func _coins(at: Vector2, count: int) -> void:
	for i in count:
		var spread := 4.0 + i * 0.9
		var coin := _sprite(DUNGEON, COIN, at + Vector2(_rng.randf_range(-spread, spread), _rng.randf_range(-spread, spread) * 0.6 - i * 0.6), -7)
		coin.scale = Vector2(1.6, 1.6)


## Kőtörmelék: egymásra hullott, szögletes kövek (hátulról előre rajzolva).
class RubbleHeap:
	extends Node2D
	## [eltolás, méret, világosság, alak] kövenként.
	var stones: Array = []

	func _draw() -> void:
		for stone: Array in stones:
			var points := PackedVector2Array()
			var shape: float = stone[3]
			var corners := 5 + int(shape * 3)
			for i in corners:
				var angle: float = TAU * i / corners + shape
				points.append(stone[0] + Vector2.from_angle(angle) * stone[1] * Vector2(1.0, 0.7) * (0.9 + 0.1 * sin(angle * 3.0)))
			var shade: float = stone[2]
			draw_colored_polygon(points, Color(shade, shade * 0.96, shade * 0.92))
			points.append(points[0])
			draw_polyline(points, Color(shade * 0.5, shade * 0.48, shade * 0.46), 1.5)


## Törött üvegszilánkok a padlón (halvány kékes csillanással).
class GlassShards:
	extends Node2D
	## [hely, méret, szög] szilánkonként.
	var shards: Array = []

	func _draw() -> void:
		for shard: Array in shards:
			var at: Vector2 = shard[0]
			var size: float = shard[1]
			var angle: float = shard[2]
			var points := PackedVector2Array([at + Vector2.from_angle(angle) * size,
				at + Vector2.from_angle(angle + 2.3) * size * 0.6, at + Vector2.from_angle(angle + 3.6) * size * 0.8])
			draw_colored_polygon(points, Color(0.7, 0.85, 0.95, 0.55))
			draw_line(points[0], points[1], Color(0.95, 1, 1, 0.8), 1.0)


## Tűzgolyó: izzó gömb lángcsóvával; a végén szétrobban és eltűnik.
class Fireball:
	extends Node2D
	var _trail: CPUParticles2D
	var _t := 0.0

	func _ready() -> void:
		z_index = 5
		_trail = CPUParticles2D.new()
		_trail.amount = 40
		_trail.lifetime = 0.45
		_trail.local_coords = false
		_trail.spread = 25.0
		_trail.gravity = Vector2(0, -40)
		_trail.initial_velocity_min = 10.0
		_trail.initial_velocity_max = 30.0
		_trail.scale_amount_min = 3.0
		_trail.scale_amount_max = 6.0
		var ramp := Gradient.new()
		ramp.set_color(0, Color(1, 0.9, 0.4))
		ramp.set_color(1, Color(0.8, 0.2, 0.05, 0))
		_trail.color_ramp = ramp
		add_child(_trail)
		var light := PointLight2D.new()
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 0.6, 0.2))
		gradient.set_color(1, Color(0, 0, 0, 0))
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(0.5, 0.0)
		light.texture = texture
		light.texture_scale = 2.5
		light.energy = 1.2
		add_child(light)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var pulse := 1.0 + 0.15 * sin(_t * 30.0)
		draw_circle(Vector2.ZERO, 11.0 * pulse, Color(1, 0.45, 0.1, 0.8))
		draw_circle(Vector2.ZERO, 7.0 * pulse, Color(1, 0.8, 0.3))
		draw_circle(Vector2.ZERO, 3.5, Color(1, 1, 0.85))

	func burst() -> void:
		_trail.emitting = false
		var boom := CPUParticles2D.new()
		boom.one_shot = true
		boom.emitting = true
		boom.amount = 50
		boom.lifetime = 0.6
		boom.explosiveness = 1.0
		boom.spread = 180.0
		boom.initial_velocity_min = 60.0
		boom.initial_velocity_max = 200.0
		boom.scale_amount_min = 3.0
		boom.scale_amount_max = 7.0
		boom.color = Color(1, 0.6, 0.2)
		add_child(boom)
		var fade := create_tween()
		fade.tween_property(self, "modulate:a", 0.0, 0.7)
		fade.tween_callback(queue_free)
