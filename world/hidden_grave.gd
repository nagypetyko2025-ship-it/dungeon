class_name HiddenGrave
extends Node2D
## Rejtett ösvény a tábor jobb felső sarkából fölfelé, sűrű erdőn át: alig látszó, kitaposott
## csapás, a végén egy kis tisztás. Ott egy magányos sír (felirattal), mellette egy öreg, elhalt
## nagy fa, a törzsén szöggel kitűzött papír, és egy láda (150 tábori arany, Görbe kés, Ismétlő
## számszeríj; csak egyszer nyitható). A sírfelirat és a papír ugyanannak a történetnek két fele.
## Fa: assets/props/dead_tree.png (bonzille "Dead Tree", CC0, átszínezve).
## (A tábor építi fel: setup(camp) + build(); a tábor fái a keeps_clear szerint kerülik az ösvényt.)

const TILE := 32
const DEAD_TREE: Texture2D = preload("res://assets/props/dead_tree.png")
const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const DUNGEON_SHEET: Texture2D = preload("res://assets/0x72_dungeon/0x72_DungeonTilesetII_v1.7.png")
## Az ösvény járható sávja (csempeoszlopok) a tábor felső szélétől a tisztásig.
const PATH_LEFT := 39
const PATH_RIGHT := 42
## A tisztás a végén.
const GLADE := Rect2i(35, -24, 12, 8)
const GRAVE_TILE := Vector2i(40, -21)
const TREE_TILE := Vector2i(43, -21)
const CHEST_TILE := Vector2i(37, -20)
const TREE_SCALE := 4.0
const RANGE := 56.0
const CHEST_FLAG := "hidden_grave_chest"
const CHEST_GOLD := 150
const CHEST_ITEMS: Array[String] = ["dagger_curved", "crossbow_repeater"]
const CHEST_FRAME := Rect2(304, 416, 16, 16)
const CHEST_OPEN_FRAME := Rect2(336, 400, 16, 16)
const GRAVE_STONE := Vector2i(51, 11)
const SMALL_TREES: Array[Vector2i] = [Vector2i(13, 9), Vector2i(15, 9), Vector2i(16, 9), Vector2i(18, 9)]
const TALL_TREES: Array[Vector2i] = [Vector2i(13, 11), Vector2i(15, 11), Vector2i(16, 11), Vector2i(18, 11)]

const EPITAPH_TITLE := "Borbás Márton"
const EPITAPH := "[center]vadász\n\nKétszer ment le a Mélységbe.\nMásodszor a hegyi patak hozta vissza.\n\n" \
	+ "[i]Itt temettem el, a vén fa alatt,\nahol hét nyáron át vártam rá.\nMost már nem kell sietnie.[/i]\n\n— I.[/center]"
const NOTE_TITLE := "Kitűzött papír"
const NOTE := "[i]Elázott, megsárgult papír, egy rozsdás szöggel a fához verve. A tinta helyenként elfolyt.[/i]\n\n" \
	+ "Márton!\n\nMegígérted, hogy a harmadik nyáron feljössz. Ez már a hetedik.\n\n" \
	+ "Minden reggel kijövök a vén fához, ahol először megcsókoltál, és minden este egyedül megyek vissza. " \
	+ "A tábor népe azt mondja, ne várjak. Én akkor is várok.\n\n" \
	+ "A ládát idehoztam, a fa tövébe, ahogy kérted: benne a pénzünk, a görbe késed és az ismétlő " \
	+ "számszeríjad. Ha feljössz, ne a táborban keress. Itt leszek.\n\n— Ilona"

var _camp: Node2D
var _entities: Node2D
var _player: Node2D
var _prompt: Label
var _grave_panel: Graveyard.InscriptionPanel
var _note_panel: Graveyard.InscriptionPanel
var _chest: Sprite2D


func setup(camp: Node2D) -> void:
	_camp = camp
	_entities = camp.get_node("Entities")
	_player = camp.get_node("Entities/Player")


## Ide nem kerülhet fa (az ösvény és a tisztás; a tábor szélén a bejárat is szabad).
static func keeps_clear(tile: Vector2i) -> bool:
	if tile.x >= PATH_LEFT and tile.x < PATH_RIGHT and tile.y >= GLADE.end.y and tile.y <= 2:
		return true
	return GLADE.has_point(tile)


func build() -> void:
	_build_trail()
	_build_forest()
	_build_grave()
	_build_tree()
	_build_chest()
	_build_ui()
	_build_bounds(64.0)


## Láthatatlan falak: az ösvény két oldalán és a tisztás körül (a tábor felső falában nyílás van).
func _build_bounds(thickness: float) -> void:
	var top := float(GLADE.end.y * TILE)
	_wall(Rect2(PATH_LEFT * TILE - thickness, top, thickness, -top))
	_wall(Rect2(PATH_RIGHT * TILE, top, thickness, -top))
	var glade := Rect2(Vector2(GLADE.position) * TILE, Vector2(GLADE.size) * TILE)
	_wall(Rect2(glade.position.x - thickness, glade.position.y - thickness, glade.size.x + thickness * 2, thickness))
	_wall(Rect2(glade.position.x - thickness, glade.position.y, thickness, glade.size.y))
	_wall(Rect2(glade.end.x, glade.position.y, thickness, glade.size.y))
	_wall(Rect2(glade.position.x, glade.end.y, PATH_LEFT * TILE - glade.position.x, thickness))
	_wall(Rect2(PATH_RIGHT * TILE, glade.end.y, glade.end.x - PATH_RIGHT * TILE, thickness))


func _wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size.abs()
	shape.shape = box
	shape.position = rect.get_center()
	body.add_child(shape)
	add_child(body)


## Alig látszó, kitaposott csapás: halvány, szabálytalan földfoltok, kicsit kanyarogva.
func _build_trail() -> void:
	for y in range(2, GLADE.end.y - 3, -1):
		var center := PATH_LEFT + 1.5 + sin(y * 0.45) * 0.6
		for i in 2:
			var patch := Polygon2D.new()
			var at := Vector2(center + randf_range(-0.35, 0.35), y + 0.25 + i * 0.5) * TILE
			var points := PackedVector2Array()
			for k in 7:
				var angle := TAU * k / 7.0
				points.append(at + Vector2(cos(angle) * randf_range(9, 15), sin(angle) * randf_range(5, 9)))
			patch.polygon = points
			patch.color = Color(0.36, 0.28, 0.18, randf_range(0.18, 0.3))
			patch.z_index = -9
			add_child(patch)


## Sűrű erdő a tisztás körül (fölötte a tábor erdeje már nem ér el); beljebb sötétebb.
func _build_forest() -> void:
	var area := Rect2i(GLADE.position - Vector2i(9, 9), GLADE.size + Vector2i(18, 9))
	for x in range(area.position.x, area.end.x):
		for y in range(area.position.y, area.end.y):
			var tile := Vector2i(x, y)
			# (Lejjebb a tábor erdeje ültet fát.)
			if y >= -14 or keeps_clear(tile):
				continue
			var outside := maxi(maxi(GLADE.position.x - x, x - GLADE.end.x + 1), maxi(GLADE.position.y - y, y - GLADE.end.y + 1))
			if outside <= 0:
				continue
			var shade := clampf(1.0 - outside * 0.07, 0.4, 1.0)
			var tree := _tree(tile, randf() < 0.75)
			tree.position += Vector2(randf_range(-8, 8), randf_range(-6, 6))
			tree.modulate = Color(shade, shade, shade * 1.05)
	# A tisztáson néhány bokor és virág.
	for i in 6:
		var tile := Vector2i(randi_range(GLADE.position.x + 1, GLADE.end.x - 2), randi_range(GLADE.position.y + 1, GLADE.end.y - 2))
		if tile.distance_to(GRAVE_TILE) < 2.5 or tile.distance_to(TREE_TILE) < 2.5 or tile.distance_to(CHEST_TILE) < 2.0:
			continue
		_rpg(Vector2i(28, 9) if i % 2 == 0 else Vector2i(29, 9), _center(tile) + Vector2(randf_range(-8, 8), randf_range(-8, 8)), -9)


func _tree(tile: Vector2i, tall: bool) -> Node2D:
	var holder := Node2D.new()
	holder.position = _center(tile) + Vector2(0, TILE / 2.0 - 4)
	_entities.add_child(holder)
	var index := randi() % TALL_TREES.size()
	if tall:
		_rpg(TALL_TREES[index], Vector2(0, -TILE / 2.0 + 4), 0, holder)
		_rpg(TALL_TREES[index] + Vector2i(0, -1), Vector2(0, -TILE * 1.5 + 4), 0, holder)
	else:
		_rpg(SMALL_TREES[index], Vector2(0, -TILE / 2.0 + 4), 0, holder)
	return holder


## A sír: felhantolt föld, a fejénél kőtábla.
func _build_grave() -> void:
	var mound := Polygon2D.new()
	var at := _center(GRAVE_TILE) + Vector2(0, 26)
	var points := PackedVector2Array()
	for k in 12:
		var angle := TAU * k / 12.0
		points.append(at + Vector2(cos(angle) * 18, sin(angle) * 30))
	mound.polygon = points
	mound.color = Color(0.3, 0.22, 0.14)
	mound.z_index = -9
	add_child(mound)
	var holder := Node2D.new()
	holder.position = _center(GRAVE_TILE) + Vector2(0, 10)
	_entities.add_child(holder)
	_rpg(GRAVE_STONE, Vector2(0, -12), 0, holder)
	_body(holder, Vector2(0, -4), Vector2(24, 10))


## Az öreg, elhalt nagy fa; a törzsén a kitűzött papír (szöggel).
func _build_tree() -> void:
	var holder := Node2D.new()
	holder.position = _center(TREE_TILE) + Vector2(0, 14)
	_entities.add_child(holder)
	var sprite := Sprite2D.new()
	sprite.texture = DEAD_TREE
	sprite.scale = Vector2(TREE_SCALE, TREE_SCALE)
	sprite.centered = false
	# A törzs alja (a képen a 24,5. oszlop, az utolsó előtti sor) kerül a csempére.
	sprite.position = Vector2(-24.5, -49.0) * TREE_SCALE
	holder.add_child(sprite)
	_body(holder, Vector2(0, -6), Vector2(26, 14))
	# A papír a törzsön, egy kicsit ferdén, fölül egy szöggel.
	var paper := Polygon2D.new()
	paper.polygon = PackedVector2Array([Vector2(0, -51), Vector2(16, -53), Vector2(17, -30), Vector2(1, -29)])
	paper.color = Color(0.9, 0.84, 0.66)
	holder.add_child(paper)
	for row in [-45.0, -40.0, -35.0]:
		var line := Line2D.new()
		line.points = PackedVector2Array([Vector2(3, row), Vector2(14, row - 1)])
		line.width = 1.0
		line.default_color = Color(0.35, 0.3, 0.25, 0.7)
		holder.add_child(line)
	var nail := Polygon2D.new()
	nail.polygon = PackedVector2Array([Vector2(6, -51), Vector2(10, -51), Vector2(10, -47), Vector2(6, -47)])
	nail.color = Color(0.45, 0.32, 0.22)
	holder.add_child(nail)


## A láda a tisztás bal oldalán (ha már kinyitottad, nyitva és üresen áll).
func _build_chest() -> void:
	var holder := Node2D.new()
	holder.position = _center(CHEST_TILE) + Vector2(0, 10)
	_entities.add_child(holder)
	_chest = Sprite2D.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = DUNGEON_SHEET
	atlas.region = CHEST_OPEN_FRAME if _opened() else CHEST_FRAME
	_chest.texture = atlas
	_chest.scale = Vector2(2, 2)
	_chest.position = Vector2(0, -14)
	holder.add_child(_chest)
	_body(holder, Vector2(0, -6), Vector2(28, 12))


func _build_ui() -> void:
	_grave_panel = Graveyard.InscriptionPanel.new()
	_grave_panel.name = "HiddenGravePanel"
	_camp.add_child.call_deferred(_grave_panel)
	_note_panel = Graveyard.InscriptionPanel.new()
	_note_panel.name = "HiddenNotePanel"
	_note_panel.ready.connect(_note_panel.use_paper)
	_camp.add_child.call_deferred(_note_panel)
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


func _opened() -> bool:
	return Progress.npc_quest_state(CHEST_FLAG) == "done"


## Melyik közelében vagy: "grave", "note", "chest" vagy "".
func _near() -> String:
	if not is_instance_valid(_player):
		return ""
	var at := _player.global_position
	if at.distance_to(_center(GRAVE_TILE) + Vector2(0, 10)) < RANGE:
		return "grave"
	if at.distance_to(_center(TREE_TILE) + Vector2(0, 14)) < RANGE + 6.0:
		return "note"
	if at.distance_to(_center(CHEST_TILE) + Vector2(0, 10)) < RANGE and not _opened():
		return "chest"
	return ""


func _process(delta: float) -> void:
	var near := _near()
	match near:
		"grave": _prompt.text = "[E] Sírfelirat elolvasása"
		"note": _prompt.text = "[E] A fára szögezett papír elolvasása"
		"chest": _prompt.text = "[E] Láda kinyitása"
	var target := 1.0 if near != "" and not get_tree().paused else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or get_tree().paused:
		return
	var near := _near()
	if near == "":
		return
	get_viewport().set_input_as_handled()
	match near:
		"grave":
			Audio.play("ui_open")
			_grave_panel.show_text(EPITAPH_TITLE, EPITAPH)
			_camp.get_node("Menus").call("open_menu", _grave_panel)
		"note":
			Audio.play("ui_open")
			_note_panel.show_text(NOTE_TITLE, NOTE)
			_camp.get_node("Menus").call("open_menu", _note_panel)
		"chest":
			_open_chest()


## A láda: 150 tábori arany és a két tárgy (a táskádba, ha van hely; különben a tábori ládába).
func _open_chest() -> void:
	Progress.set_npc_quest(CHEST_FLAG, "done")
	Audio.play("chest_open")
	(_chest.texture as AtlasTexture).region = CHEST_OPEN_FRAME
	Progress.camp_gold += CHEST_GOLD
	var inventory: Inventory = _player.get_node("Inventory")
	var to_stash := false
	for id in CHEST_ITEMS:
		var item := Items.mark_story(Items.create(id))
		if not inventory.add_item(item):
			Progress.stash.append(item)
			to_stash = true
	Progress.camp_inventory = inventory.save_data()
	Progress.save_game()
	_camp.call("_update_gold")
	var text := "+%d tábori arany, Görbe kés, Ismétlő számszeríj" % CHEST_GOLD
	if to_stash:
		text += " (ami nem fért el, a tábori ládádba került)"
	FloatingText.spawn(_entities, _center(CHEST_TILE) + Vector2(0, -30), text, Color(1, 0.85, 0.3), 18)


# ---------------------------------------------------------------- segédek

func _center(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE


func _body(parent: Node2D, at: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	body.add_child(shape)
	parent.add_child(body)


func _rpg(coords: Vector2i, at: Vector2, z: int, parent: Node = null) -> Sprite2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = RPG
	atlas.region = Rect2(Vector2(coords) * 17.0, Vector2(16, 16))
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.scale = Vector2(2, 2)
	sprite.position = at
	sprite.z_index = z
	(parent if parent else self).add_child(sprite)
	return sprite
