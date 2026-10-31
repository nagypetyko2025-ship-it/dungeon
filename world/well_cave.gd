class_name WellCave
extends Node2D
## A kút alja (Lőrinc megmentése után a kútnál E-vel lemászhatsz): a létra alatti kis aknából
## egy szűk folyosó vezet egy nagyobb, nyirkos terembe. A terem túlsó végén egy régi járat
## nyílik a Mélység felé, de be van omolva. Mohos kőfalak, kőpadló, víz, fű, kövek, csontok;
## felülről a kút szája ad egy kis fényt. (A tábor építi fel, a Ruin hívja: enter().)

signal message(text: String)

const TILE := 32
const PUNY: Texture2D = preload("res://assets/decor/puny_dungeon.png")
const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const LADDER: Texture2D = preload("res://assets/props/ladder.png")
const BONES: Texture2D = preload("res://assets/decor/bones.png")
const COBWEB: Texture2D = preload("res://assets/decor/cobweb.png")

## A barlang részei (csempékben, messze a pályától): akna, folyosó, terem.
const SHAFT := Rect2i(360, 0, 5, 5)
const CORRIDOR := Rect2i(365, 2, 10, 2)
const CHAMBER := Rect2i(375, -3, 16, 12)
const LADDER_TILE := Vector2i(362, 0)
## A beomlott járat a terem keleti falán, középen.
const COLLAPSE_TILE := Vector2i(390, 2)
const BOUNDS := Rect2i(356, -7, 40, 20)
## A beomlott járat mögött (Döme robbantása után, Blaster.WELL_QUEST): rövid alagút, a végén Lőrinc régi
## térképész-műhelye (íróasztal a jegyzeteivel, könyvespolcok, láda az iránytűvel, lezárt rácsos lépcső lefelé).
const TUNNEL := Rect2i(391, 1, 6, 3)
const WORKSHOP := Rect2i(397, -3, 12, 10)
const OPEN_BOUNDS := Rect2i(356, -7, 56, 20)
const DOME_SPOT := Vector2i(386, 5)
const DESK_TILE := Vector2i(401, 1)
const CHEST_TILE := Vector2i(406, 3)
const GRATE_TILE := Vector2i(407, 5)
const CHEST_FLAG := "well_workshop_chest"
const CHEST_GOLD := 250
const CHEST_ITEM := "trinket_lorinc_compass"
const DUNGEON_SHEET: Texture2D = preload("res://assets/0x72_dungeon/0x72_DungeonTilesetII_v1.7.png")
const CHEST_FRAME := Rect2(304, 416, 16, 16)
const CHEST_OPEN_FRAME := Rect2(336, 400, 16, 16)
## Kenney RPG: könyvespolcok (két sor), papírok, tekercs, könyvek.
const SHELF_COLUMNS: Array[int] = [43, 44, 45, 46, 47, 48, 49, 50]
const PAPERS: Array[Vector2i] = [Vector2i(41, 15), Vector2i(42, 15), Vector2i(43, 15)]
const BOOKS: Array[Vector2i] = [Vector2i(46, 15), Vector2i(47, 15), Vector2i(48, 15)]
const NOTE_TITLE := "Lőrinc jegyzetei"
const NOTE_TEXT := "[i]Megsárgult térképlapok, a szélükön apró, sűrű kézírás.[/i]\n\n" \
	+ "„Harmadik hét. A kút alatti járat a régi királyi térképeken nincs rajta, de a szél nem hazudik: lefelé " \
	+ "vezet, egyenesen a Mélység felső szintjei alá. Ha igazam van, ez a legrégebbi bejárat. Régebbi a táborénál.\n\n" \
	+ "Negyedik hét. Rácsot találtam a lépcső előtt. Nem rozsdás. Valaki karbantartja. Vagy valami.\n\n" \
	+ "Ötödik hét. A mennyezet reccsen. Holnap felviszem a térképeket a kúthoz, aztán visszajövök az iránytűért.”" \
	+ "\n\n[i]Az utolsó bejegyzés után csak egy elmosódott pacni. Lőrinc soha nem jött vissza az iránytűért.[/i]"

const CAVE_LIGHT := Color(0.32, 0.34, 0.4)
const LANTERN := 0.8
const INTERACT_RANGE := 56.0

## Puny Dungeon (CC0) csempék: kőpadló, mohos fal (teteje fűvel), lefolyórács csöpögő vízzel.
const FLOOR_TILES: Array[Vector2i] = [Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 1), Vector2i(4, 2), Vector2i(7, 3),
	Vector2i(5, 3)]
const WALL_TOP := Vector2i(8, 0)
const WALL_FACE := Vector2i(8, 1)
const GRATE := Vector2i(8, 3)
const MOSS := Vector2i(3, 10)
## Kenney RPG (CC0): bokrok, virágok a nedves sarkokban.
const BUSHES: Array[Vector2i] = [Vector2i(19, 9), Vector2i(21, 9), Vector2i(24, 9)]
const FLOWERS: Array[Vector2i] = [Vector2i(28, 9), Vector2i(29, 9), Vector2i(28, 10)]

var _camp: Node2D
var _player: Node2D
var _entities: Node2D
var _prompt: Label
var _inside := false
var _busy := false
var _floor := {}
var _rng := RandomNumberGenerator.new()
## A törmelék (robbantáskor eltűnik), a köd a titkos rész fölött, a műhely fényei.
var _collapse_nodes: Array[Node] = []
var _fog: ColorRect
var _workshop_lights: Array[PointLight2D] = []
var _dome: AnimatedSprite2D
var _dome_dialogue: DialoguePanel
var _note_panel: Graveyard.InscriptionPanel
var _chest: Sprite2D
var _flash: ColorRect
var _shake := 0.0


## A legrégebbi bejárat ajánlata (az első használatkor jön létre).
var _challenge_panel: ChallengePanel


func setup(camp: Node2D) -> void:
	_camp = camp
	_entities = camp.get_node("Entities")
	_player = camp.get_node("Entities/Player")


func build() -> void:
	_rng.seed = 4242
	for rect in [SHAFT, CORRIDOR, CHAMBER, TUNNEL, WORKSHOP]:
		for x in range(rect.position.x, rect.end.x):
			for y in range(rect.position.y, rect.end.y):
				_floor[Vector2i(x, y)] = true
	_build_floor()
	_build_walls()
	_build_shaft()
	_build_chamber()
	_build_workshop()
	_build_collapse()
	_build_dome()
	_build_ui()


func _build_floor() -> void:
	for tile: Vector2i in _floor:
		var sprite := _puny(FLOOR_TILES[_rng.randi() % FLOOR_TILES.size()], tile, -10)
		var shade := _rng.randf_range(0.7, 0.9)
		sprite.modulate = Color(shade, shade * 1.02, shade)
		if _rng.randf() < 0.12:
			_puny(MOSS, tile, -9).modulate = Color(1, 1, 1, _rng.randf_range(0.25, 0.5))


## Fal minden nem-padló csempén a padló körül: ahol alatta padló van, mohos falfelület (fölötte
## fűvel benőtt perem), máshol sötét szikla. Mind szilárd.
func _build_walls() -> void:
	var done := {}
	for tile: Vector2i in _floor:
		for dx in range(-1, 2):
			for dy in range(-2, 2):
				var wall := tile + Vector2i(dx, dy)
				if _floor.has(wall) or done.has(wall):
					continue
				done[wall] = true
				if _floor.has(wall + Vector2i.DOWN):
					_puny(WALL_FACE + Vector2i(_rng.randi() % 8, 0), wall, -9)
				elif _floor.has(wall + Vector2i(0, 2)):
					_puny(WALL_TOP + Vector2i(_rng.randi() % 8, 0), wall, -9)
				else:
					var rock := ColorRect.new()
					rock.color = Color(0.07, 0.07, 0.09)
					rock.position = Vector2(wall) * TILE
					rock.size = Vector2(TILE, TILE)
					rock.z_index = -9
					add_child(rock)
				_solid(Rect2(Vector2(wall) * TILE, Vector2(TILE, TILE)))
	# Körben sötétség (a kamera szélén se látsszon a semmi).
	var dark := ColorRect.new()
	dark.color = Color(0.03, 0.03, 0.04)
	dark.position = Vector2(BOUNDS.position) * TILE
	dark.size = Vector2(BOUNDS.size) * TILE
	dark.z_index = -11
	add_child(dark)


## Az akna: a létra lóg le a kút szájából, felülről halvány fény; a földön a régi kötél, csiga-héjak.
func _build_shaft() -> void:
	var ladder := Sprite2D.new()
	ladder.texture = LADDER
	ladder.scale = Vector2(2, 2)
	ladder.position = _center(LADDER_TILE) + Vector2(0, -10)
	ladder.z_index = -5
	add_child(ladder)
	_light(_center(LADDER_TILE + Vector2i(0, 1)), Color(0.75, 0.85, 1.0), 1.6, 0.9)
	# A szakadt kötél a földön (Lőrincé).
	var rope := Line2D.new()
	rope.width = 3.0
	rope.default_color = Color(0.55, 0.42, 0.25)
	for i in 7:
		rope.add_point(_center(SHAFT.position + Vector2i(3, 3)) + Vector2(i * 7, sin(i * 1.3) * 5))
	rope.z_index = -8
	add_child(rope)
	_puddle(_center(SHAFT.position + Vector2i(1, 3)), Vector2(26, 10), false)
	_bones(SHAFT.position + Vector2i(4, 4))
	_cobweb(SHAFT.position, false)
	_cobweb(Vector2i(SHAFT.end.x - 1, SHAFT.position.y), true)


## A terem: tó a közepén, körülötte fű és virág, kövek, lefolyórácsok a falon, csontok.
func _build_chamber() -> void:
	var r := CHAMBER
	_puddle(_center(Vector2i(r.position.x + 7, r.position.y + 6)), Vector2(120, 52), true)
	_light(_center(Vector2i(r.position.x + 7, r.position.y + 6)), Color(0.45, 0.7, 1.0), 1.8, 0.45)
	for x in [r.position.x + 2, r.position.x + 7, r.position.x + 12]:
		_puny(GRATE, Vector2i(x, r.position.y - 1), -8)
	for i in 26:
		var tile := Vector2i(_rng.randi_range(r.position.x, r.end.x - 1), _rng.randi_range(r.position.y, r.end.y - 1))
		var near_pool := Vector2(tile).distance_to(Vector2(r.position.x + 7, r.position.y + 6)) < 6.0
		var near_wall := tile.x <= r.position.x + 1 or tile.x >= r.end.x - 2 or tile.y >= r.end.y - 2
		if not (near_pool or near_wall):
			continue
		var at := _center(tile) + Vector2(_rng.randf_range(-10, 10), _rng.randf_range(-8, 8))
		if _rng.randf() < 0.55:
			_rpg(BUSHES[_rng.randi() % BUSHES.size()], at, -7).modulate = Color(0.7, 0.85, 0.7)
		else:
			_rpg(FLOWERS[_rng.randi() % FLOWERS.size()], at, -7).modulate = Color(0.75, 0.8, 0.9)
	for i in 9:
		var tile := Vector2i(_rng.randi_range(r.position.x + 1, r.end.x - 2), _rng.randi_range(r.position.y + 1, r.end.y - 2))
		var stone := _sprite(PUNY, Rect2(256 + 16 * (i % 4), 208, 16, 16), _center(tile), -6)
		stone.scale = Vector2.ONE * _rng.randf_range(1.2, 1.9)
		stone.modulate = Color(0.75, 0.75, 0.8)
	_bones(Vector2i(r.position.x + 2, r.end.y - 2))
	_bones(Vector2i(r.end.x - 4, r.position.y + 1))
	_cobweb(r.position, false)
	_cobweb(Vector2i(r.end.x - 1, r.position.y), true)
	_cobweb(Vector2i(r.position.x, r.end.y - 1), false, true)
	# Csöpögő víz a folyosó plafonjáról: kis pocsolya.
	_puddle(_center(Vector2i(CORRIDOR.position.x + 5, CORRIDOR.position.y + 1)), Vector2(20, 8), false)


## A beomlott járat: sötét boltív a keleti falban, előtte kőtörmelék és lezuhant gerendák.
func _build_collapse() -> void:
	var opening := ColorRect.new()
	opening.color = Color(0.02, 0.02, 0.03)
	opening.position = Vector2(COLLAPSE_TILE + Vector2i(1, -1)) * TILE + Vector2(0, 8)
	opening.size = Vector2(TILE, TILE * 3 - 16)
	opening.z_index = -8
	add_child(opening)
	_collapse_nodes.append(opening)
	var heap := Ruin.RubbleHeap.new()
	heap.position = _center(COLLAPSE_TILE)
	heap.z_index = 0
	for i in 26:
		heap.stones.append([Vector2(_rng.randf_range(-40, 30), _rng.randf_range(-50, 50)), _rng.randf_range(7, 14),
			_rng.randf_range(0.35, 0.55), _rng.randf()])
	heap.stones.sort_custom(func(a: Array, b: Array) -> bool: return a[0].y < b[0].y)
	add_child(heap)
	_collapse_nodes.append(heap)
	for beam: Array in [[Vector2(-6, -30), 1.1], [Vector2(4, 20), -0.9]]:
		var plank := ColorRect.new()
		plank.color = Color(0.28, 0.19, 0.12)
		plank.size = Vector2(70, 8)
		plank.pivot_offset = plank.size / 2.0
		plank.position = _center(COLLAPSE_TILE) + beam[0] - plank.size / 2.0
		plank.rotation = beam[1]
		plank.z_index = 1
		add_child(plank)
		_collapse_nodes.append(plank)
	_collapse_nodes.append(_solid(Rect2(Vector2(COLLAPSE_TILE - Vector2i(1, 2)) * TILE, Vector2(2 * TILE, 5 * TILE))))
	# A titkos rész (alagút, műhely) a robbantásig sötétben.
	_fog = ColorRect.new()
	_fog.color = Color(0.03, 0.03, 0.04)
	_fog.position = Vector2(COLLAPSE_TILE.x + 1.5, OPEN_BOUNDS.position.y) * TILE
	_fog.size = Vector2(OPEN_BOUNDS.end.x - COLLAPSE_TILE.x - 1.5, OPEN_BOUNDS.size.y) * TILE
	_fog.z_index = 8
	add_child(_fog)
	if Blaster.well_open():
		_clear_collapse()
		_fog.queue_free()
		_fog = null


## A járat nyitva: a törmelék, a gerendák és az ütköző eltűnik, a műhely fényei kigyulladnak; marad pár szétszórt
## kő az alagút szájánál. (A ködöt a hívó tünteti el.)
func _clear_collapse() -> void:
	for node in _collapse_nodes:
		node.queue_free()
	_collapse_nodes.clear()
	for light in _workshop_lights:
		light.enabled = true
	for i in 7:
		var tile := Vector2i(COLLAPSE_TILE.x + _rng.randi_range(-1, 2), _rng.randi_range(0, 4))
		var stone := _sprite(PUNY, Rect2(256 + 16 * (i % 4), 208, 16, 16), _center(tile), -6)
		stone.scale = Vector2.ONE * _rng.randf_range(1.0, 1.6)
		stone.modulate = Color(0.6, 0.58, 0.6)


## Lőrinc régi műhelye: polcok az északi falnál, íróasztal a térképekkel és gyertyával, láda, a déli sarokban a
## lezárt rácsos lépcső; az alagútban gerendák.
func _build_workshop() -> void:
	var r := WORKSHOP
	for x in range(r.position.x, r.end.x):
		var col: int = SHELF_COLUMNS[(x - r.position.x) % SHELF_COLUMNS.size()]
		_rpg(Vector2i(col, 14), _center(Vector2i(x, r.position.y)), -6)
		_rpg(Vector2i(col, 12), _center(Vector2i(x, r.position.y - 1)), -6)
	_solid(Rect2(Vector2(r.position) * TILE, Vector2(r.size.x * TILE, TILE - 6)))
	# Íróasztal (két asztal egymás mellett), rajta térképek, könyv, gyertya; mellette szék.
	for i in 2:
		_rpg(Town.TABLE, _center(DESK_TILE + Vector2i(i, 0)), -5).modulate = Color(0.85, 0.8, 0.72)
	for i in PAPERS.size():
		_rpg(PAPERS[i], _center(DESK_TILE) + Vector2(-6 + i * 14, -8 + (i % 2) * 3), -4).scale = Vector2(1.4, 1.4)
	_rpg(BOOKS[0], _center(DESK_TILE + Vector2i(1, 0)) + Vector2(4, -6), -4).scale = Vector2(1.4, 1.4)
	_rpg(Town.CANDLE, _center(DESK_TILE + Vector2i(1, 0)) + Vector2(-8, -14), -4)
	_rpg(Town.CHAIR_FACING_RIGHT, _center(DESK_TILE + Vector2i(-1, 0)) + Vector2(0, -2), -5)
	_solid(Rect2(Vector2(DESK_TILE) * TILE + Vector2(4, 8), Vector2(2 * TILE - 8, TILE - 12)))
	# Szétszórt könyvek a földön.
	for i in 4:
		var tile := Vector2i(_rng.randi_range(r.position.x + 1, r.end.x - 2), _rng.randi_range(r.position.y + 3, r.end.y - 2))
		var book := _rpg(BOOKS[i % BOOKS.size()], _center(tile) + Vector2(_rng.randf_range(-8, 8), 6), -7)
		book.rotation = _rng.randf_range(-0.6, 0.6)
	# Láda (nyitva, ha már kinyitottad).
	_chest = Sprite2D.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = DUNGEON_SHEET
	atlas.region = CHEST_OPEN_FRAME if _chest_opened() else CHEST_FRAME
	_chest.texture = atlas
	_chest.scale = Vector2(2, 2)
	_chest.position = _center(CHEST_TILE)
	_chest.z_index = -5
	add_child(_chest)
	_solid(Rect2(Vector2(CHEST_TILE) * TILE + Vector2(2, 10), Vector2(TILE - 4, TILE - 12)))
	# A rácsos lépcső: sötét akna, lefelé futó fokok, előtte vasrács.
	var pit := ColorRect.new()
	pit.color = Color(0.02, 0.02, 0.03)
	pit.position = Vector2(GRATE_TILE) * TILE
	pit.size = Vector2(TILE * 1.5, TILE * 1.5)
	pit.z_index = -8
	add_child(pit)
	for i in 4:
		var step := ColorRect.new()
		step.color = Color(0.3, 0.3, 0.34).darkened(i * 0.2)
		step.position = pit.position + Vector2(2, 4 + i * 11)
		step.size = Vector2(TILE * 1.5 - 4, 5)
		step.z_index = -7
		add_child(step)
	for i in 6:
		var bar := ColorRect.new()
		bar.color = Color(0.42, 0.42, 0.48)
		bar.position = pit.position + Vector2(3 + i * 8, -2)
		bar.size = Vector2(3, TILE * 1.5 + 2)
		bar.z_index = -6
		add_child(bar)
	_solid(Rect2(pit.position, pit.size))
	# Az alagút gerendái.
	for x in [TUNNEL.position.x + 1, TUNNEL.position.x + 4]:
		var beam := ColorRect.new()
		beam.color = Color(0.3, 0.2, 0.12)
		beam.position = Vector2(x, TUNNEL.position.y - 1) * TILE + Vector2(10, 0)
		beam.size = Vector2(10, (TUNNEL.size.y + 1) * TILE)
		beam.z_index = -6
		add_child(beam)
	_cobweb(r.position + Vector2i(0, 1), false)
	_cobweb(Vector2i(r.end.x - 1, r.position.y + 1), true)
	_bones(Vector2i(r.end.x - 3, r.end.y - 1))
	for at: Vector2 in [_center(DESK_TILE + Vector2i(1, 0)), _center(TUNNEL.position + Vector2i(3, 1))]:
		_workshop_lights.append(_light(at, Color(1, 0.75, 0.45), 1.8, 0.8))
	for light in _workshop_lights:
		light.enabled = false


func _chest_opened() -> bool:
	return Progress.npc_quest_state(CHEST_FLAG) == "done"


## Döme a törmeléknél (amíg a robbantásra vár), a beszélgetése, és Lőrinc jegyzeteinek ablaka.
func _build_dome() -> void:
	_dome = AnimatedSprite2D.new()
	_dome.sprite_frames = Blaster.frames()
	_dome.scale = Vector2(2, 2)
	_dome.offset.y = -Blaster.FIGURE.size.y / 2.0
	_dome.position = _center(DOME_SPOT)
	_dome.play("idle")
	_dome.visible = Blaster.at_well()
	add_child(_dome)
	_dome_dialogue = DialoguePanel.new()
	_dome_dialogue.name = "WellBlasterDialogue"
	_dome_dialogue.npc_id = Blaster.ID
	_dome_dialogue.npc_name = Blaster.NAME
	_dome_dialogue.portrait = Blaster.portrait()
	_dome_dialogue.options_provider = func() -> Array[Dictionary]: return Blaster.options("well", _blast_option)
	_camp.add_child.call_deferred(_dome_dialogue)
	_note_panel = Graveyard.InscriptionPanel.new()
	_note_panel.name = "WellNotePanel"
	_note_panel.ready.connect(_note_panel.use_paper)
	_camp.add_child.call_deferred(_note_panel)


# ---------------------------------------------------------------- belépés, irányítás

## A kútnál E (Ruin hívja): lemászás a létrán.
func enter() -> void:
	_move(true, _center(LADDER_TILE + Vector2i(0, 2)))


func _move(inside: bool, at: Vector2) -> void:
	_busy = true
	_inside = inside
	# Döme a tábor betöltése után is lejöhet (a bányában adod le a mirigyeket): belépéskor újranézzük.
	if inside:
		_dome.visible = Blaster.at_well()
	Audio.play("footstep", -2.0)
	var limits := _limits() if inside else Rect2()
	_camp.call("teleport_player", at, limits, CAVE_LIGHT if inside else Color.BLACK)
	await get_tree().create_timer(0.25).timeout
	_player.get_node("PointLight2D").energy = LANTERN if inside else 0.5
	await get_tree().create_timer(0.35).timeout
	_busy = false


func _limits() -> Rect2:
	var bounds := OPEN_BOUNDS if Blaster.well_open() else BOUNDS
	return Rect2(Vector2(bounds.position) * TILE, Vector2(bounds.size) * TILE)


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
	# A robbanás villanása (az egész képernyőn).
	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 4
	add_child(flash_layer)
	_flash = ColorRect.new()
	_flash.color = Color(1, 0.95, 0.85, 0.0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(_flash)


func _focus() -> Array:
	if not _inside or _busy or not is_instance_valid(_player):
		return []
	var at: Vector2 = _player.global_position
	if at.distance_to(_center(LADDER_TILE + Vector2i(0, 1))) < INTERACT_RANGE:
		return ["up", "[E] Felmászás a létrán"]
	if _dome.visible and at.distance_to(_dome.position) < INTERACT_RANGE + 24:
		return ["dome", "[E] Puskás Döme"]
	if not Blaster.well_open():
		if at.distance_to(_center(COLLAPSE_TILE)) < INTERACT_RANGE + 70:
			return ["collapse", "[E] Beomlott járat"]
		return []
	if at.distance_to(_center(DESK_TILE) + Vector2(TILE / 2.0, 0)) < INTERACT_RANGE + 10:
		return ["desk", "[E] Lőrinc jegyzetei"]
	if not _chest_opened() and at.distance_to(_center(CHEST_TILE)) < INTERACT_RANGE:
		return ["chest", "[E] Láda kinyitása"]
	if at.distance_to(_center(GRATE_TILE) + Vector2(8, 8)) < INTERACT_RANGE + 10:
		return ["grate", "[E] Rácsos lépcső"]
	return []


func _process(delta: float) -> void:
	if _shake > 0.0 and _inside:
		var camera: Camera2D = _player.get_node("Camera2D")
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
		_shake = move_toward(_shake, 0.0, delta * 30.0)
		if _shake <= 0.0:
			camera.offset = Vector2.ZERO
	var focus := _focus()
	if not focus.is_empty():
		_prompt.text = focus[1]
	var target := 1.0 if not focus.is_empty() and not GamePause.active(get_tree()) else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or GamePause.active(get_tree()):
		return
	var focus := _focus()
	if focus.is_empty():
		return
	get_viewport().set_input_as_handled()
	match focus[0]:
		"up":
			var ruin := _camp.get_node("Ruin")
			_move(false, ruin.call("well_exit_position"))
		"collapse":
			if Blaster.at_well():
				# Döme a törmeléknél: a beomlott járatnál is szólhatsz neki.
				_dome.visible = true
				Audio.play("ui_open")
				_dome_dialogue.greeting = Blaster.greeting("well")
				_camp.get_node("Menus").call("open_menu", _dome_dialogue)
			else:
				Audio.play("door_lock", -6.0)
				message.emit("A járat be van omolva. Mögüle hideg szél fúj... a Mélység felől. "
					+ "Egy dinamit beomlaszthatná az egészet.")
		"dome":
			Audio.play("ui_open")
			_dome_dialogue.greeting = Blaster.greeting("well")
			_camp.get_node("Menus").call("open_menu", _dome_dialogue)
		"desk":
			Audio.play("ui_open")
			# Ha Lőrinc már nincs a kútnál, a rácsról szóló levele is itt van (OldEntrance.desk_letter).
			var letter := OldEntrance.desk_letter()
			_note_panel.show_text(NOTE_TITLE, NOTE_TEXT + ("\n\n" + letter if not letter.is_empty() else ""))
			_camp.get_node("Menus").call("open_menu", _note_panel)
		"chest":
			_open_chest()
		"grate":
			_use_grate()


## A rácsos lépcső: Lőrinc kulcsával (OldEntrance) le lehet menni a legrégebbi bejáraton.
func _use_grate() -> void:
	if OldEntrance.cleared():
		message.emit("A rács nyitva, odalent csend van. A kalapácsolás elhallgatott.")
		return
	if Progress.npc_quest_state(OldEntrance.QUEST) != "active":
		Audio.play("door_lock", -6.0)
		message.emit("Vasrács egy lefelé vezető lépcső előtt. Nem rozsdás, a lakatja olajos... Lentről halk, "
			+ "egyenletes kopogás szűrődik fel. Most nem nyílik." + ((" Lőrinc asztalán talán van róla valami."
			if OldEntrance.lorinc_away() else " Talán Lőrinc tud róla valamit.") if OldEntrance.available() else ""))
		return
	if _challenge_panel == null:
		_challenge_panel = ChallengePanel.new()
		_challenge_panel.name = "EntranceChallengePanel"
		_challenge_panel.visible = false
		_camp.add_child(_challenge_panel)
	Audio.play("ui_open")
	var start := func(challenge: Dictionary) -> void: _camp.call("enter_challenge", challenge)
	_challenge_panel.show_offer(OldEntrance.run_challenge(), start)
	_camp.get_node("Menus").call("open_menu", _challenge_panel)


## Döme "Robbants!" válasza: a beszélgetés bezárul, és lejátszódik a robbantás.
func _blast_option() -> String:
	_camp.get_node("Menus").call("close_current")
	_blast.call_deferred()
	return ""


## A robbantás: Döme a törmelékhez megy, beékeli a köteget, hátraszalad; robbanás (villanás, rázkódás, kőzápor),
## a törmelék eltűnik, a köd felszáll, mögötte az alagút és a műhely. Utána Döme visszamegy a bányába.
func _blast() -> void:
	if _busy or not Blaster.at_well():
		return
	_busy = true
	_dome.play("run")
	var walk := create_tween()
	walk.tween_property(_dome, "position", _center(COLLAPSE_TILE) + Vector2(-34, 30), 0.7)
	await walk.finished
	_dome.play("idle")
	var dynamite := _dynamite()
	dynamite.position = _center(COLLAPSE_TILE) + Vector2(-14, 8)
	Audio.play("footstep", -4.0)
	await get_tree().create_timer(0.6).timeout
	FloatingText.spawn(self, _dome.position + Vector2(0, -60), "Fedezékbe!", Color(1, 0.8, 0.4), 22)
	_dome.play("run")
	_dome.flip_h = true
	var back := create_tween()
	back.tween_property(_dome, "position", _center(DOME_SPOT + Vector2i(-6, 0)), 1.0)
	await get_tree().create_timer(1.6).timeout
	_dome.play("idle")
	_dome.flip_h = false
	dynamite.queue_free()
	Audio.play("boss_slam", 4.0, 0.0)
	Audio.play("trap", 2.0)
	Audio.play("boss_roar", -6.0, 0.0)
	_shake = 16.0
	_flash.color.a = 0.85
	create_tween().tween_property(_flash, "color:a", 0.0, 0.5)
	_debris(_center(COLLAPSE_TILE), 26)
	await get_tree().create_timer(0.3).timeout
	Progress.set_npc_quest(Blaster.WELL_QUEST, "done")
	Progress.change_trust(Blaster.ID, 15)
	Progress.save_game()
	_clear_collapse()
	var fog := _fog
	_fog = null
	var lift := create_tween()
	lift.tween_property(fog, "color:a", 0.0, 1.6)
	lift.tween_callback(fog.queue_free)
	(_player.get_node("Camera2D") as Camera2D).limit_right = int(_limits().end.x)
	await get_tree().create_timer(1.2).timeout
	Audio.play("level_up")
	FloatingText.spawn(self, _dome.position + Vector2(0, -60), "Na, ugye!", Color(1, 0.85, 0.5), 22)
	message.emit("A törmelék szétrepült: mögötte alagút vezet kelet felé, a végén egy régi, elhagyott műhely.")
	await get_tree().create_timer(1.6).timeout
	# Döme visszamegy a bányába (onnantól ott áll).
	var fade := create_tween()
	fade.tween_property(_dome, "modulate:a", 0.0, 0.6)
	await fade.finished
	_dome.visible = false
	_dome.modulate.a = 1.0
	_busy = false


## A láda: Lőrinc iránytűje és tábori arany (a táskába, ha van hely; különben a tábori ládába).
func _open_chest() -> void:
	Progress.set_npc_quest(CHEST_FLAG, "done")
	Audio.play("chest_open")
	(_chest.texture as AtlasTexture).region = CHEST_OPEN_FRAME
	Progress.camp_gold += CHEST_GOLD
	var inventory: Inventory = _player.get_node("Inventory")
	var item := Items.mark_story(Items.create(CHEST_ITEM))
	var text := "+%d tábori arany, Lőrinc iránytűje" % CHEST_GOLD
	if not inventory.add_item(item):
		Progress.stash.append(item)
		text += " (a tábori ládádba került)"
	Progress.camp_inventory = inventory.save_data()
	Progress.save_game()
	_camp.call("_update_gold")
	FloatingText.spawn(self, _center(CHEST_TILE) + Vector2(0, -30), text, Color(1, 0.85, 0.3), 18)


## A dinamitköteg (három vörös rúd, szikrázó kanócvég).
func _dynamite() -> Node2D:
	var bundle := Node2D.new()
	bundle.z_index = 5
	add_child(bundle)
	for i in 3:
		var stick := ColorRect.new()
		stick.color = Color(0.75, 0.12, 0.1) if i != 1 else Color(0.85, 0.18, 0.12)
		stick.size = Vector2(5, 14)
		stick.position = Vector2(-8 + i * 5, -7)
		bundle.add_child(stick)
	var spark := ColorRect.new()
	spark.color = Color(1, 0.9, 0.4)
	spark.size = Vector2(4, 4)
	spark.position = Vector2(-2, -12)
	bundle.add_child(spark)
	var blink := spark.create_tween().set_loops()
	blink.tween_property(spark, "modulate:a", 0.2, 0.08)
	blink.tween_property(spark, "modulate:a", 1.0, 0.08)
	return bundle


## Kőzápor és por egy pontból.
func _debris(at: Vector2, count: int) -> void:
	for i in count:
		var piece := ColorRect.new()
		var size := randf_range(3, 8)
		piece.size = Vector2(size, size)
		piece.color = [Color(0.42, 0.36, 0.34), Color(0.3, 0.25, 0.24), Color(0.6, 0.55, 0.5, 0.7)][i % 3]
		piece.position = at
		piece.z_index = 9
		add_child(piece)
		var direction := Vector2.from_angle(randf() * TAU)
		var target := at + direction * randf_range(30, 130) + Vector2(0, randf_range(20, 70))
		var tween := piece.create_tween().set_parallel()
		tween.tween_property(piece, "position", target, randf_range(0.5, 0.9)).set_ease(Tween.EASE_OUT)
		tween.tween_property(piece, "modulate:a", 0.0, 1.0).set_delay(0.3)
		tween.chain().tween_callback(piece.queue_free)


# ---------------------------------------------------------------- segédek

func _center(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE


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


func _puny(coords: Vector2i, tile: Vector2i, z: int) -> Sprite2D:
	return _sprite(PUNY, Rect2(Vector2(coords) * 16.0, Vector2(16, 16)), _center(tile), z)


func _rpg(coords: Vector2i, at: Vector2, z: int) -> Sprite2D:
	return _sprite(RPG, Rect2(Vector2(coords) * 17.0, Vector2(16, 16)), at, z)


func _solid(rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	add_child(body)
	return body


func _light(at: Vector2, color: Color, size: float, energy: float) -> PointLight2D:
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
	return light


## Víz: a nagy tó szilárd (nem lehet átgázolni), a kis pocsolyák nem.
func _puddle(at: Vector2, size: Vector2, solid: bool) -> void:
	var water := Water.new()
	water.size = size
	water.position = at
	water.z_index = -8
	add_child(water)
	if solid:
		_solid(Rect2(at - size * 0.75, size * 1.5))


func _bones(tile: Vector2i) -> void:
	var bones := Sprite2D.new()
	bones.texture = BONES
	bones.scale = Vector2(2, 2)
	bones.position = _center(tile)
	bones.modulate = Color(0.7, 0.7, 0.68)
	bones.z_index = -7
	add_child(bones)


func _cobweb(tile: Vector2i, flip_h: bool, flip_v := false) -> void:
	var web := Sprite2D.new()
	web.texture = COBWEB
	web.scale = Vector2(2, 2)
	web.position = _center(tile)
	web.flip_h = flip_h
	web.flip_v = flip_v
	web.modulate = Color(1, 1, 1, 0.7)
	web.z_index = -7
	add_child(web)


## Sötét, csillogó víz (lassan hullámzó partvonallal és fénycsíkokkal).
class Water:
	extends Node2D
	var size := Vector2(40, 16)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var points := PackedVector2Array()
		for i in 28:
			var angle := TAU * i / 28.0
			var wobble := 1.0 + 0.05 * sin(angle * 4.0 + _t * 1.5)
			points.append(Vector2.from_angle(angle) * size * wobble)
		draw_colored_polygon(points, Color(0.08, 0.16, 0.24, 0.92))
		var inner := PackedVector2Array()
		for p in points:
			inner.append(p * 0.75)
		draw_colored_polygon(inner, Color(0.12, 0.26, 0.38, 0.8))
		for i in 4:
			var y := -size.y * 0.4 + i * size.y * 0.25
			var x := sin(_t * 1.2 + i) * size.x * 0.2
			draw_line(Vector2(x - size.x * 0.18, y), Vector2(x + size.x * 0.18, y), Color(0.6, 0.8, 1, 0.35), 1.5)
