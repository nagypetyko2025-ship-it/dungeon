class_name Graveyard
extends Node2D
## Temető a kocsma alatt (a városi út túloldalán, délre): sötét, kopár föld, középen egy
## elhalt fa, körülötte sírkövek és keresztek, korhadt kerítés, csontok, halvány köd.
## Egy rövid földút vezet le hozzá az útról. A feliratos sírkő-táblák feliratát E-vel el lehet
## olvasni (TABLETS, EPITAPHS), a sírásóval beszélgetni lehet. (A tábor építi fel: setup(camp) + build().)

const TILE := 32
const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const BONES: Texture2D = preload("res://assets/decor/bones.png")

## A temető csempékben (a városi út alatt, a kocsma ajtajával szemben).
const RECT := Rect2i(63, 21, 14, 7)
const GATE_COLUMN := 69
## Kenney RPG (CC0): elhalt fák, sírkövek, keresztek, sírlapok, kerítés.
const DEAD_TREE := Vector2i(27, 9)
const DEAD_SAPLINGS: Array[Vector2i] = [Vector2i(27, 10), Vector2i(27, 11)]
const GRAVES: Array[Vector2i] = [Vector2i(51, 9), Vector2i(52, 9), Vector2i(53, 9), Vector2i(51, 10), Vector2i(52, 10),
	Vector2i(53, 10), Vector2i(51, 11), Vector2i(52, 11), Vector2i(53, 11)]
const FENCE := Vector2i(38, 8)
const SOIL := Color(0.16, 0.12, 0.1)
## A feliratos sírkő-táblák (a GRAVES alsó sora): minden ilyen sír felirata E-vel olvasható
## (EPITAPHS, sorban kiosztva; az INSCRIBED_TILE sírja mindig tábla, rajta az ismeretlen kalandor).
const TABLETS: Array[Vector2i] = [Vector2i(51, 11), Vector2i(52, 11), Vector2i(53, 11)]
## A különleges sír (az alsó sorban, a kapu ösvényétől jobbra) és a felirata.
const INSCRIBED_TILE := Vector2i(72, 26)
const INSCRIPTION_TITLE := "Az ismeretlen kalandor"
const INSCRIPTION := "[center][i]Itt nyugszik, aki lement, és nem jött vissza.\n" \
	+ "A nevét elnyelte a Mélység, a kardját a fiai hozták fel.[/i]\n\n" \
	+ "Ne sirasd: ő legalább tudta, mi van odalent.\n" \
	+ "Te még csak sejted.\n\n" \
	+ "[color=#6b5a48]— A tábor népe —[/color][/center]"
const READ_RANGE := 50.0
## A többi tábla felirata: [név, szöveg] (a játék történetének halottai is itt nyugszanak).
const EPITAPHS: Array[Array] = [
	["Ambrus atya", "Harangozott, amíg bírt,\nés felírta a neveket, amíg volt fal.\n\nMost az ő nevét írta fel valaki más."],
	["Kerekes Pál, molnár", "Lement a lányáért, hogy legyen kenyér a házban.\nA lánya felnőtt. A malom áll.\n\n„Aludj, apa.” — Zsófi"],
	["Benedek, zászlóvivő", "A zászlót a Mélységben is magasan tartotta.\nA fia hazahozta helyette.\n\nA fiad jó ember lett, Benedek."],
	["Gáspár emberei", "Kilencen mentek le a kapitányukkal.\nEgy jött vissza.\n\nA nevüket ő tudja. Elég, ha ő tudja."],
	["Rézi, a dalnok", "Dalt akart írni a hetedik emelet sötétjéről.\nAz első versszakot hazaküldte.\n\nA többit odalent énekli."],
	["Ismeretlen kovácsinas", "Csak a kalapácsa jött haza,\nmég meleg volt a markolata.\n\nA kovács azóta sem tanít inast."],
	["Három testvér", "Egyszerre mentek le, egymást fogva.\nEgyszerre is temettük őket, egymás mellé.\n\nA Mélység sem tudta szétválasztani őket."],
	["Vak Márton, zsoldos", "Fizetségért ment le, kétszer is.\nHarmadszorra ingyen ment: a barátjáért.\n\nAz volt a legjobb alkuja."],
	["Ilona, a gyógyító", "Száz kalandort varrt össze a tábor szélén.\nA százegyediket a Mélységben.\n\nOtt maradt vele."],
	["Egy kutya, Bundás", "Tizenkét emeletet ment le a gazdája után,\nés egyet sem fel nélküle.\n\nA legjobb fiú volt a táborban."],
	["Névtelen kalandor", "Senki sem tudta a nevét,\nde mindenki látta, ahogy lement.\n\nAkkor is mosolygott."],
	["Öreg Lajos, térképész", "Lőrinc tanítója volt.\nAzt mondta, minden térkép hazudik egy kicsit.\n\nAz övé csak a végén hazudott."],
]
## A sírásó (Gravedigger): a kapu ösvényén áll, az első sírsor alatt (ott nincs sír). E-vel beszélni
## lehet vele; a küldetése elfogadása után (a beszélgetés bezárásakor) átsétál a kápolnába (Chapel).
const DIGGER_TILE := Vector2i(69, 23)
const TALK_RANGE := 56.0
const WALK_SPEED := 95.0

var _camp: Node2D
var _entities: Node2D
var _rng := RandomNumberGenerator.new()
var _player: Node2D
var _prompt: Label
var _panel: InscriptionPanel
## A feliratos sírok: {"position": Vector2, "title": String, "text": String}.
var _tablets: Array[Dictionary] = []
var _digger_position := Vector2.INF
var _dialogue: DialoguePanel
var _digger: Node2D
var _digger_body: CollisionShape2D
var _walking := false


func setup(camp: Node2D) -> void:
	_camp = camp
	_entities = camp.get_node("Entities")
	_player = camp.get_node("Entities/Player")
	_panel = InscriptionPanel.new()
	_panel.name = "InscriptionPanel"
	camp.add_child.call_deferred(_panel)
	_dialogue = DialoguePanel.new()
	_dialogue.name = "GravediggerDialogue"
	_dialogue.npc_id = Gravedigger.ID
	_dialogue.npc_name = Gravedigger.NAME
	_dialogue.portrait = Gravedigger.portrait()
	_dialogue.options_provider = func() -> Array[Dictionary]:
		return Gravedigger.options(_player.get_node("Inventory"))
	camp.add_child.call_deferred(_dialogue)


## Földút az úttól a temető kapujáig (a tábor rajzolja ki a többi földdel).
static func path_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for y in range(19, RECT.position.y):
		for x in [GATE_COLUMN, GATE_COLUMN + 1]:
			tiles.append(Vector2i(x, y))
	return tiles


## Ide nem kerülhet fa / bokor.
static func blocked_rect() -> Rect2i:
	return Rect2i(RECT.position - Vector2i(1, 2), RECT.size + Vector2i(2, 3))


func build() -> void:
	_rng.seed = 1313
	_build_soil()
	_build_fence()
	_build_tree()
	_build_graves()
	_build_digger()
	_build_fog()
	_build_ui()


## Sötét, kopár föld, szabálytalan szélekkel, itt-ott fűcsomóval.
func _build_soil() -> void:
	var soil := Soil.new()
	soil.rect = Rect2(Vector2(RECT.position) * TILE, Vector2(RECT.size) * TILE)
	soil.seed_value = 77
	soil.z_index = -9
	add_child(soil)
	for i in 14:
		var tile := RECT.position + Vector2i(_rng.randi_range(0, RECT.size.x - 1), _rng.randi_range(0, RECT.size.y - 1))
		var tuft := _rpg(Vector2i(22, 10), _center(tile) + Vector2(_rng.randf_range(-10, 10), _rng.randf_range(-8, 8)), -8)
		tuft.modulate = Color(0.45, 0.45, 0.35)
		tuft.scale = Vector2(1.4, 1.4)


## Korhadt fakerítés a temető tetején és alján (a tetején kapunyílással az ösvénynek).
func _build_fence() -> void:
	for x in range(RECT.position.x, RECT.end.x):
		if x == GATE_COLUMN or x == GATE_COLUMN + 1:
			continue
		var top := _rpg(FENCE, _center(Vector2i(x, RECT.position.y - 1)) + Vector2(0, 14), 0, _entities)
		top.modulate = Color(0.55, 0.45, 0.4)
		if _rng.randf() < 0.15:
			top.rotation = _rng.randf_range(-0.25, 0.25)
		var bottom := _rpg(FENCE, _center(Vector2i(x, RECT.end.y)) + Vector2(0, 4), 0, _entities)
		bottom.modulate = Color(0.55, 0.45, 0.4)
	_solid(Rect2(Vector2(RECT.position.x, RECT.position.y - 0.4) * TILE, Vector2(GATE_COLUMN - RECT.position.x, 0.5) * TILE))
	_solid(Rect2(Vector2(GATE_COLUMN + 2, RECT.position.y - 0.4) * TILE, Vector2(RECT.end.x - GATE_COLUMN - 2, 0.5) * TILE))
	_solid(Rect2(Vector2(RECT.position.x, RECT.end.y + 0.3) * TILE, Vector2(RECT.size.x, 0.5) * TILE))


## Az elhalt fa a temető közepén (szilárd törzzsel), tövében csontok.
func _build_tree() -> void:
	var holder := Node2D.new()
	holder.position = _center(Vector2i(GATE_COLUMN + 4, RECT.position.y + 3)) + Vector2(0, 16)
	_entities.add_child(holder)
	var tree := _rpg(DEAD_TREE, Vector2(0, -38), 0, holder)
	tree.modulate = Color(0.5, 0.45, 0.45)
	tree.scale = Vector2(5, 5)
	_body(holder, Vector2(0, -6), Vector2(20, 10))
	# Két kisebb, kiszáradt csemete a temető sarkaiban.
	for i in DEAD_SAPLINGS.size():
		# (A sírok oszlopai közé, hogy ne kerüljenek egymásra.)
		var corner := Vector2i(RECT.position.x, RECT.position.y + 2) if i == 0 else Vector2i(RECT.end.x - 2, RECT.position.y + 1)
		var sapling := _rpg(DEAD_SAPLINGS[i], _center(corner), 0, _entities)
		sapling.modulate = Color(0.5, 0.45, 0.45)
	var bones := Sprite2D.new()
	bones.texture = BONES
	bones.scale = Vector2(2, 2)
	bones.position = _center(Vector2i(GATE_COLUMN + 5, RECT.position.y + 3)) + Vector2(4, 10)
	bones.modulate = Color(0.75, 0.72, 0.68)
	bones.z_index = -7
	add_child(bones)


## Sírok sorokban (kicsit ferdén, mintha megsüllyedtek volna), mindegyik előtt egy földhalom.
func _build_graves() -> void:
	var tree_tile := Vector2i(GATE_COLUMN + 4, RECT.position.y + 3)
	for row in [1, 3, 5]:
		for x in range(RECT.position.x + 1, RECT.end.x - 1, 2):
			var tile := Vector2i(x, RECT.position.y + row)
			# Az elhalt fa (és a koronája fölötte) körül nincs sír.
			if absi(tile.x - tree_tile.x) <= 1 and tile.y >= tree_tile.y - 2 and tile.y <= tree_tile.y + 1:
				continue
			if x == GATE_COLUMN or x == GATE_COLUMN + 1:
				continue
			if _rng.randf() < 0.15:
				continue
			var mound := Mound.new()
			mound.position = _center(tile) + Vector2(0, 14)
			mound.z_index = -8
			add_child(mound)
			var holder := Node2D.new()
			holder.position = _center(tile) + Vector2(0, 4)
			_entities.add_child(holder)
			var look: Vector2i = GRAVES[_rng.randi() % GRAVES.size()]
			if tile == INSCRIBED_TILE:
				look = TABLETS[0]
			var stone := _rpg(look, Vector2(0, -12), 0, holder)
			if tile == INSCRIBED_TILE:
				_tablets.append({"position": holder.position, "title": INSCRIPTION_TITLE, "text": INSCRIPTION})
			elif look in TABLETS:
				var epitaph: Array = EPITAPHS[(_tablets.size()) % EPITAPHS.size()]
				_tablets.append({"position": holder.position, "title": epitaph[0],
					"text": "[center][i]%s[/i][/center]" % epitaph[1]})
			stone.rotation = _rng.randf_range(-0.12, 0.12)
			stone.modulate = Color(0.75, 0.75, 0.8)
			_body(holder, Vector2(0, -4), Vector2(22, 8))


## A sírásó: lassan "lélegzik" (álló kockák), az ásójára támaszkodva; szilárd. Ha már a
## kápolnában lakik, nincs itt.
func _build_digger() -> void:
	_digger = Node2D.new()
	_digger.position = _center(DIGGER_TILE) + Vector2(16, 14)
	_entities.add_child(_digger)
	Gravedigger.build_figure(_digger)
	_digger_position = _digger.position
	var body := StaticBody2D.new()
	_digger_body = CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(22, 12)
	_digger_body.shape = box
	_digger_body.position = Vector2(0, -6)
	body.add_child(_digger_body)
	_digger.add_child(body)
	# A kocsmába költözése után a temetőben sincs (különben újra besétálna a kápolnába).
	_digger.visible = Gravedigger.in_graveyard()
	_digger_body.disabled = not Gravedigger.in_graveyard()
	# Mellette egy frissen ásott gödör, földkupaccal.
	var pit := Mound.new()
	pit.position = _center(DIGGER_TILE + Vector2i(-1, 0)) + Vector2(0, 12)
	pit.scale = Vector2(1.3, 1.6)
	pit.z_index = -8
	add_child(pit)


## Halvány, lassan hullámzó köd a sírok között.
func _build_fog() -> void:
	for i in 5:
		var fog := Fog.new()
		fog.position = _center(RECT.position + Vector2i(_rng.randi_range(1, RECT.size.x - 2), _rng.randi_range(1, RECT.size.y - 2)))
		fog.phase = _rng.randf() * TAU
		fog.z_index = 2
		add_child(fog)


# ---------------------------------------------------------------- a sírfelirat

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_prompt = MenuStyle.title_label("[E] Sírfelirat elolvasása", 32, MenuStyle.GOLD)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -210
	_prompt.offset_bottom = -160
	_prompt.offset_left = -500
	_prompt.offset_right = 500
	_prompt.modulate.a = 0.0
	layer.add_child(_prompt)


func _near_grave() -> bool:
	return not _nearest_tablet().is_empty()


## A legközelebbi feliratos sír (READ_RANGE-en belül), vagy üres.
func _nearest_tablet() -> Dictionary:
	if not is_instance_valid(_player):
		return {}
	var best := {}
	var best_distance := READ_RANGE
	for tablet in _tablets:
		var distance := _player.global_position.distance_to(tablet["position"])
		if distance < best_distance:
			best_distance = distance
			best = tablet
	return best


func _near_digger() -> bool:
	return is_instance_valid(_player) and _digger.visible and not _walking \
		and _player.global_position.distance_to(_digger_position) < TALK_RANGE


## A küldetés elfogadása után (amint bezárult a beszélgetés) kisétál a kapun, végig az út mellett
## a kápolnáig, és bemegy az ajtaján.
func _walk_to_chapel() -> void:
	_walking = true
	_digger_body.disabled = true
	var door: Vector2 = Chapel.door_position()
	var gate_x := (GATE_COLUMN + 1) * TILE
	var side_x := (Chapel.TOP_LEFT.x - 0.5) * TILE
	var points: Array[Vector2] = [Vector2(gate_x, _digger.position.y), Vector2(gate_x, (RECT.position.y - 1.6) * TILE),
		Vector2(side_x, (RECT.position.y - 1.6) * TILE), Vector2(side_x, door.y + 22), Vector2(door.x, door.y + 22), door]
	var figure := _digger.get_child(0) as AnimatedSprite2D
	var walk := create_tween()
	var from := _digger.position
	for point in points:
		walk.tween_callback(func() -> void: figure.flip_h = point.x < _digger.position.x - 1.0)
		walk.tween_property(_digger, "position", point, from.distance_to(point) / WALK_SPEED)
		from = point
	walk.tween_property(_digger, "modulate:a", 0.0, 0.4)
	await walk.finished
	Audio.play("door_unlock", -8.0)
	_digger.visible = false
	_digger.modulate.a = 1.0
	_walking = false
	Progress.set_npc_quest(Gravedigger.CHAPEL_FLAG, "done")
	Progress.save_game()


func _process(delta: float) -> void:
	if not _walking and _digger.visible and Gravedigger.should_walk() and not GamePause.active(get_tree()):
		_walk_to_chapel()
	# Lépés közben kicsit billeg.
	if _walking:
		_digger.rotation = sin(Time.get_ticks_msec() * 0.012) * 0.06
	else:
		_digger.rotation = 0.0
	var digger := _near_digger()
	if digger or _near_grave():
		_prompt.text = "[E] Beszélgetés: Vendel" if digger else "[E] Sírfelirat elolvasása"
	var target := 1.0 if (digger or _near_grave()) and not GamePause.active(get_tree()) else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or GamePause.active(get_tree()):
		return
	var digger := _near_digger()
	if not digger and not _near_grave():
		return
	get_viewport().set_input_as_handled()
	Audio.play("ui_open")
	if not digger:
		var tablet := _nearest_tablet()
		_panel.show_text(tablet["title"], tablet["text"])
	_camp.get_node("Menus").call("open_menu", _dialogue if digger else _panel)


## A sírfelirat: kőszürke tábla, rajta a vésett szöveg (E / Esc: bezárás).
class InscriptionPanel:
	extends CanvasLayer
	var _title: Label
	var _stone: PanelContainer
	var _text: RichTextLabel
	## A hosszú szöveg (pl. Lőrinc jegyzetei + levele) görgethető, hogy az ablak kiférjen a képből.
	var _scroll: ScrollContainer
	var _hint: Label
	const MAX_TEXT_HEIGHT := 440.0

	func _ready() -> void:
		layer = 15
		process_mode = Node.PROCESS_MODE_ALWAYS
		visible = false
		var dim := ColorRect.new()
		dim.color = Color(0.02, 0.02, 0.03, 0.6)
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
		var center := CenterContainer.new()
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(center)
		var stone := PanelContainer.new()
		_stone = stone
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.55, 0.56, 0.6)
		style.border_color = Color(0.3, 0.31, 0.35)
		style.set_border_width_all(6)
		style.corner_radius_top_left = 80
		style.corner_radius_top_right = 80
		style.set_content_margin_all(36)
		style.content_margin_top = 56
		style.shadow_color = Color(0, 0, 0, 0.5)
		style.shadow_size = 14
		stone.add_theme_stylebox_override("panel", style)
		stone.custom_minimum_size = Vector2(520, 0)
		center.add_child(stone)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 14)
		stone.add_child(box)
		_title = MenuStyle.title_label(INSCRIPTION_TITLE, 34, Color(0.18, 0.18, 0.22))
		var title := _title
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(title)
		var text := RichTextLabel.new()
		text.bbcode_enabled = true
		text.fit_content = true
		text.scroll_active = false
		text.custom_minimum_size.x = 440
		text.add_theme_color_override("default_color", Color(0.16, 0.16, 0.2))
		text.add_theme_font_size_override("normal_font_size", 19)
		text.add_theme_font_size_override("italics_font_size", 19)
		text.text = INSCRIPTION
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_text = text
		_scroll = ScrollContainer.new()
		_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_scroll.custom_minimum_size = Vector2(440, 0)
		_scroll.add_child(text)
		box.add_child(_scroll)
		_fit_text.call_deferred()
		var hint := UiStyle.label("[E] / [Esc] bezárás", 14, Color(0.25, 0.25, 0.3))
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_hint = hint
		box.add_child(hint)

	## Kő helyett sárgás, elázott papír (pl. a fára szögezett levél, lásd HiddenGrave).
	func use_paper() -> void:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.87, 0.8, 0.6)
		style.border_color = Color(0.55, 0.42, 0.25)
		style.set_border_width_all(3)
		style.set_corner_radius_all(3)
		style.set_content_margin_all(36)
		style.shadow_color = Color(0, 0, 0, 0.5)
		style.shadow_size = 14
		_stone.add_theme_stylebox_override("panel", style)
		_title.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1))
		_text.add_theme_color_override("default_color", Color(0.25, 0.17, 0.08))

	## Melyik sír feliratát mutassa (megnyitás előtt).
	func show_text(title: String, text: String) -> void:
		_title.text = title
		_text.text = text
		_fit_text.call_deferred()

	## A görgető magassága a szövegé, legfeljebb MAX_TEXT_HEIGHT (afölött görgetni kell).
	func _fit_text() -> void:
		# A szöveg tördelése egy képkockával később készül el: addig nincs magassága.
		if _text.get_content_height() <= 1 and is_inside_tree():
			await get_tree().process_frame
		_scroll.custom_minimum_size.y = minf(float(_text.get_content_height()), MAX_TEXT_HEIGHT)
		_scroll.scroll_vertical = 0
		var more := "Görgess az egérrel a többiért.   " if _text.get_content_height() > MAX_TEXT_HEIGHT else ""
		_hint.text = more + "[E] / [Esc] bezárás"

	func open() -> void:
		visible = true
		_fit_text.call_deferred()

	func close() -> void:
		visible = false

	func _unhandled_input(event: InputEvent) -> void:
		if visible and event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			get_tree().current_scene.get_node("Menus").call("close_current")


# ---------------------------------------------------------------- segédek

func _center(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE


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


func _body(parent: Node2D, offset: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = size
	shape.shape = box
	shape.position = offset
	body.add_child(shape)
	parent.add_child(body)


func _solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	add_child(body)


## Sötét föld rücskös szélekkel és apró kövekkel.
class Soil:
	extends Node2D
	var rect := Rect2()
	var seed_value := 1

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var points := PackedVector2Array()
		var center := rect.get_center()
		for i in 48:
			var angle := TAU * i / 48.0
			var dir := Vector2.from_angle(angle)
			var reach := minf(rect.size.x / 2.0 / maxf(absf(dir.x), 0.01), rect.size.y / 2.0 / maxf(absf(dir.y), 0.01))
			points.append(center + dir * (reach + rng.randf_range(-6, 10)))
		draw_colored_polygon(points, SOIL)
		for i in 60:
			var at := rect.position + Vector2(rng.randf() * rect.size.x, rng.randf() * rect.size.y)
			draw_circle(at, rng.randf_range(1.0, 2.5), Color(0.24, 0.2, 0.17))


## Földhalom a sír előtt.
class Mound:
	extends Node2D

	func _draw() -> void:
		var points := PackedVector2Array()
		for i in 16:
			points.append(Vector2.from_angle(TAU * i / 16.0) * Vector2(13, 6))
		draw_colored_polygon(points, Color(0.22, 0.17, 0.13))
		draw_line(Vector2(-9, -2), Vector2(7, -3), Color(0.3, 0.24, 0.18), 1.5)


## Lassan úszó, halvány ködfolt.
class Fog:
	extends Node2D
	var phase := 0.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		position.x += sin(_t * 0.3 + phase) * 0.15
		queue_redraw()

	func _draw() -> void:
		# Sok halvány, egymásra rétegzett kör: puha szélű köd (nem látszanak a körvonalak).
		var alpha := 0.018 + 0.008 * sin(_t * 0.7 + phase)
		for i in 8:
			var radius := 14.0 + i * 6.0
			draw_circle(Vector2(sin(phase + i) * 6.0, 0), radius, Color(0.75, 0.8, 0.85, alpha))
