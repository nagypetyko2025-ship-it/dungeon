class_name Hell
## A 100. emelet és a pokol. A 100. emeleten (a nagy terem közepén) vörösen izzó, ismeretlen kapu áll
## (`Gate`); E-re a játékos belép, és a pokolba kerül (`GameState.hell`, ugyanaz a Dungeon-jelenet,
## más elrendezéssel): egyenes, nyitott, tüzes út kelet felé (`CELLS`), a végén a trónterem, benne
## Lucifer, a Démonkirály (`Throne`). Vele E-re lehet beszélni: öt történet, a hatodik opció a harc
## (a beszélgetés bezárul, és a Room.start_lucifer elindítja). A harc: enemies/lucifer_boss.gd.

const DEPTH := 100
const ID := "lucifer"
const NAME := "Lucifer, a Démonkirály"
## Az út szobái egy sorban, keletre; az utolsó a trónterem.
const CELLS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)]
## Az út egy szakasza: a cellánál szélesebb (a szomszédos szakaszok összeérnek), így egyetlen nyitott út.
const ROAD_SIZE := Vector2i(34, 11)
const THRONE_SIZE := Vector2i(31, 21)
## A pokol fényei: vörösebb, mint a Vérkő.
const LIGHT := Color(1.0, 0.62, 0.5)
const CLEAR := Color(0.16, 0.02, 0.02)
## Tűz az út két szélén (csempénként ennyi eséllyel), és néhány a padlón.
const EDGE_FIRE_EVERY := 3
const FLOOR_FIRES := 5
const GATE_TEXT := "Egy ismeretlen kapu, de belülről ismeretlen energiák áramolnak kifelé. Talán jobb lenne " \
	+ "elfutni... de akkor mikor tudom meg mi van bent?"
const GREETING := "[i]A trón előtt hatalmas alak lebeg. Fekete köpenye füstként hullámzik, vörös szárnyai a " \
	+ "boltozatot súrolják, szarvas koponyáján izzó arany korona. Láncain koponyák csörögnek. Lassan feléd " \
	+ "fordul, és a szemgödrében két parázs gyúl.[/i]\n\nNa lám. Egy halandó, aki végigjárta mind a száz " \
	+ "emeletet. Rég nem jött ide senki a saját lábán. Beszélj, amíg még megteheted."

const STORIES: Array[Dictionary] = [
	{"id": "who", "text": "Ki vagy te?", "trust": 0,
		"answer": "[i]Nevetése mélyről jön, mintha a föld alól szólna.[/i]\n\nLucifer. A Démonkirály. A fény " \
			+ "hozója, akit a fény elhagyott. Ezer néven hívtak, és mindegyiket ugyanazzal a remegéssel " \
			+ "suttogták.\n\nEz itt az én birodalmam. Minden tűz, amit idefelé láttál, az enyém. Minden " \
			+ "démon, akit levágtál odafent, az én gyermekem volt."},
	{"id": "dungeon", "text": "Miért van ez a kazamata?", "trust": 0,
		"answer": "Azt hiszed, véletlenül ásták ilyen mélyre? A száz emelet az én lépcsőm. Minden emelettel " \
			+ "közelebb jutottam a felszínhez: előbb a Vérkő, aztán a Fagykő, a Káosz, végül a régi kő, ahol a " \
			+ "goblinjaitok laknak.\n\n[i]Karmos kezével a mennyezet felé int.[/i]\n\nA Káosz Ura, a " \
			+ "Vérfarkas, az Ősgépezet, a háromfejű őröm... mind csak kapuőrök voltak. Hogy ne zavarjon senki, " \
			+ "amíg felérek."},
	{"id": "king", "text": "Mi köze ehhez a királynak?", "trust": 0,
		"answer": "[i]Megcsörgeti a láncait. Az egyik koponyán mintha korona nyoma látszana.[/i]\n\n" \
			+ "A királyotok ősei nyitották meg az első aknát. Aranyat akartak, és mélyebbre ástak, mint szabadott " \
			+ "volna. Én csak... meghallgattam őket. Adtam nekik aranyat. Sokat.\n\nCserébe minden emberöltőben " \
			+ "egy kicsit szabadabban jártam. Az aranyat ti költöttétek el. Az árát én szedem be."},
	{"id": "brave", "text": "Hányan jutottak el idáig?", "trust": 0,
		"answer": "Hárman. Négyszáz év alatt.\n\n[i]Fejével a trón lábánál heverő páncélok felé biccent. " \
			+ "Az egyiken még kivehető egy kopott címer.[/i]\n\nAz első lovag volt, a második tolvaj, a " \
			+ "harmadik egy öreg varázsló, aki azt hitte, egy ősi tekercs megvédi. Mind ugyanazt kérdezték, " \
			+ "amit te. És mind ugyanazt választották végül.\n\nSzerinted te más leszel?"},
	{"id": "deal", "text": "Mi lenne, ha egyezséget kötnénk?", "trust": 0,
		"answer": "[i]Előrehajol. A forróság szinte égeti az arcod.[/i]\n\nEgyezség? Most beszélsz okosan. " \
			+ "Hagyj felmenni. Állj félre, és a tiéd lesz minden, ami odafent van: a királyság, az arany, egy " \
			+ "örök élet.\n\n[i]Aztán hátradől, és a hangja hideg lesz, mint a Fagykő.[/i]\n\nDe te nem " \
			+ "egyezkedni jöttél. Látom a szemedben. Akkor ne húzzuk tovább az időt."},
]


## A Lucifer elleni harc opciója (mindig a hatodik, az öt történet után).
static func options(on_fight: Callable) -> Array[Dictionary]:
	var list: Array[Dictionary] = STORIES.duplicate()
	list.append({"id": "fight", "text": "Elég a szóból. Harcolj velem!", "on_choose": func() -> String:
		on_fight.call_deferred()
		return "[i]Lucifer felemelkedik. A tüzek a teremben egyszerre lobbannak fel.[/i]\n\nLegyen hát."})
	return list


static func room_rect(cell: Vector2i, cell_size: Vector2i) -> Rect2i:
	var size := THRONE_SIZE if cell == CELLS[-1] else ROAD_SIZE
	return Rect2i(cell * cell_size - size / 2, size)


static func idle_frames() -> SpriteFrames:
	var texture: Texture2D = load(LuciferBoss.SHEET)
	var size: Vector2 = LuciferBoss.LUCIFER["rect"].size
	var result := SpriteFrames.new()
	result.set_animation_speed("default", 7.0)
	for i in 4:
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(Vector2(i * size.x, 0), size)
		result.add_frame("default", frame)
	return result


static func portrait() -> AtlasTexture:
	var face := AtlasTexture.new()
	face.atlas = load(LuciferBoss.SHEET)
	face.region = Rect2(81, 22, 38, 44)
	return face


## Tüzek az út két szélén és a padlón (csak kinézet; a pokol nem sebez magától).
static func add_fires(room: Room) -> void:
	var inner := room.rect.grow(-1)
	for x in range(inner.position.x, inner.end.x):
		if (x - inner.position.x) % EDGE_FIRE_EVERY != 0:
			continue
		for y in [inner.position.y, inner.end.y - 1]:
			var fire := Fire.new()
			fire.lit = (x / EDGE_FIRE_EVERY) % 2 == 0
			fire.position = Room.tile_center(Vector2i(x, y)) - room.position
			room.add_child(fire)
	for i in FLOOR_FIRES:
		var tile := Vector2i(randi_range(inner.position.x + 2, inner.end.x - 3), randi_range(inner.position.y + 2, inner.end.y - 3))
		if absi(tile.y - room.anchor.y) <= 1:
			continue
		var fire := Fire.new()
		fire.size = 0.7
		fire.position = Room.tile_center(tile) - room.position
		room.add_child(fire)


## Lobogó tűz: felszálló lángnyelvek és szikrák, minden másodikon fény.
class Fire:
	extends Node2D
	var lit := true
	var size := 1.0

	func _ready() -> void:
		z_index = -3
		var flames := CPUParticles2D.new()
		flames.amount = 14
		flames.lifetime = 0.7
		flames.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		flames.emission_rect_extents = Vector2(10, 3) * size
		flames.direction = Vector2(0, -1)
		flames.spread = 12.0
		flames.gravity = Vector2(0, -60)
		flames.initial_velocity_min = 25.0
		flames.initial_velocity_max = 50.0
		flames.scale_amount_min = 4.0 * size
		flames.scale_amount_max = 7.0 * size
		var ramp := Gradient.new()
		ramp.set_color(0, Color(1.0, 0.85, 0.3, 0.95))
		ramp.set_color(1, Color(0.8, 0.1, 0.02, 0.0))
		flames.color_ramp = ramp
		add_child(flames)
		var sparks := CPUParticles2D.new()
		sparks.amount = 4
		sparks.lifetime = 1.4
		sparks.direction = Vector2(0, -1)
		sparks.spread = 35.0
		sparks.gravity = Vector2(0, -20)
		sparks.initial_velocity_min = 30.0
		sparks.initial_velocity_max = 60.0
		sparks.scale_amount_min = 1.5
		sparks.scale_amount_max = 2.5
		sparks.color = Color(1.0, 0.6, 0.2)
		add_child(sparks)
		if lit:
			var light := PointLight2D.new()
			var gradient := Gradient.new()
			gradient.set_color(0, Color(1.0, 0.45, 0.15))
			gradient.set_color(1, Color(0, 0, 0, 0))
			var texture := GradientTexture2D.new()
			texture.gradient = gradient
			texture.fill = GradientTexture2D.FILL_RADIAL
			texture.fill_from = Vector2(0.5, 0.5)
			texture.fill_to = Vector2(0.5, 0.0)
			light.texture = texture
			light.texture_scale = 2.2 * size
			light.energy = 0.9
			add_child(light)
			var flicker := create_tween().set_loops()
			flicker.tween_property(light, "energy", 0.6, randf_range(0.15, 0.3))
			flicker.tween_property(light, "energy", 1.0, randf_range(0.15, 0.3))

	func _draw() -> void:
		draw_circle(Vector2(0, 2), 12.0 * size, Color(0.15, 0.02, 0.0, 0.6))
		draw_circle(Vector2(0, 1), 7.0 * size, Color(1.0, 0.4, 0.05, 0.5))


## A 100. emelet vörösen izzó kapuja: álló, lüktető ovális örvény. Közel érve kiírja a szövegét, E-re belépsz.
class Gate:
	extends Node2D
	const RANGE := 150.0
	const ENTER_RANGE := 80.0
	var on_enter: Callable
	var _t := 0.0
	var _player: Node2D
	var _text: Label
	var _prompt: Label
	var _used := false

	func _ready() -> void:
		z_index = 1
		var light := PointLight2D.new()
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1.0, 0.15, 0.05))
		gradient.set_color(1, Color(0, 0, 0, 0))
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(0.5, 0.0)
		light.texture = texture
		light.texture_scale = 6.0
		light.energy = 1.6
		light.position = Vector2(0, -60)
		add_child(light)
		var embers := CPUParticles2D.new()
		embers.amount = 40
		embers.lifetime = 1.8
		embers.position = Vector2(0, -60)
		embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		embers.emission_rect_extents = Vector2(34, 56)
		embers.direction = Vector2(0, 1)
		embers.spread = 180.0
		embers.gravity = Vector2(0, -25)
		embers.initial_velocity_min = 30.0
		embers.initial_velocity_max = 80.0
		embers.scale_amount_min = 2.0
		embers.scale_amount_max = 4.0
		embers.color = Color(1.0, 0.3, 0.1)
		add_child(embers)
		var layer := CanvasLayer.new()
		layer.layer = 5
		add_child(layer)
		_text = MenuStyle.title_label(GATE_TEXT, 24, Color(1.0, 0.55, 0.45))
		_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_text.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		_text.offset_top = -270
		_text.offset_bottom = -190
		_text.offset_left = -520
		_text.offset_right = 520
		_text.modulate.a = 0.0
		layer.add_child(_text)
		_prompt = MenuStyle.title_label("[E] Belépek a kapun", 30, MenuStyle.GOLD)
		_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		_prompt.offset_top = -180
		_prompt.offset_bottom = -140
		_prompt.offset_left = -400
		_prompt.offset_right = 400
		_prompt.modulate.a = 0.0
		layer.add_child(_prompt)

	func _distance() -> float:
		if not is_instance_valid(_player):
			_player = get_tree().get_first_node_in_group("player")
		return _player.global_position.distance_to(global_position) if is_instance_valid(_player) else INF

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
		var paused := GamePause.active(get_tree())
		var distance := _distance()
		_text.modulate.a = move_toward(_text.modulate.a, 1.0 if distance < RANGE and not paused else 0.0, delta * 3.0)
		_prompt.modulate.a = move_toward(_prompt.modulate.a, 1.0 if distance < ENTER_RANGE and not paused else 0.0, delta * 5.0)

	func _unhandled_input(event: InputEvent) -> void:
		if _used or not event.is_action_pressed("interact") or GamePause.active(get_tree()) or _distance() >= ENTER_RANGE:
			return
		get_viewport().set_input_as_handled()
		_used = true
		Audio.play("lucifer_portal", 2.0)
		var fade := create_tween()
		fade.tween_property(_player, "modulate", Color(3, 0.4, 0.2, 0), 0.8)
		await fade.finished
		on_enter.call()

	func _draw() -> void:
		var center := Vector2(0, -60)
		var pulse := 1.0 + 0.05 * sin(_t * 4.0)
		# Kőkeret, aztán az örvény rétegei (kívülről befelé egyre világosabb).
		_oval(center, Vector2(46, 72) * pulse, Color(0.12, 0.03, 0.03))
		_oval(center, Vector2(40, 66) * pulse, Color(0.5, 0.02, 0.02))
		for i in 5:
			var k := 1.0 - i * 0.17
			var wobble := 0.06 * sin(_t * 3.0 + i)
			_oval(center + Vector2(0, 2 * i), Vector2(36, 60) * (k + wobble), Color(0.8 + i * 0.04, 0.08 + i * 0.1, 0.02 + i * 0.03, 0.85))
		for i in 3:
			var angle := _t * (1.6 + i * 0.5) + i * TAU / 3.0
			draw_arc(center, 22.0 + i * 8.0, angle, angle + 2.2, 16, Color(1.0, 0.75, 0.35, 0.7), 2.0)
		draw_rect(Rect2(-50, -4, 100, 8), Color(0.18, 0.05, 0.04))

	func _oval(center: Vector2, radius: Vector2, color: Color) -> void:
		var points := PackedVector2Array()
		for i in 28:
			points.append(center + Vector2.from_angle(TAU * i / 28.0) * radius)
		draw_colored_polygon(points, color)


## Lucifer a trónja előtt: beszélgetni lehet vele (E), a hatodik opcióra indul a harc.
class Throne:
	extends Node2D
	const TALK_RANGE := 170.0
	var room: Room
	var _player: Node2D
	var _dialogue: DialoguePanel
	var _prompt: Label
	var _figure: AnimatedSprite2D

	func _ready() -> void:
		_figure = AnimatedSprite2D.new()
		_figure.sprite_frames = Hell.idle_frames()
		_figure.scale = Vector2.ONE * 2.0 * float(LuciferBoss.LUCIFER["scale"])
		_figure.offset = Vector2(0, -LuciferBoss.LUCIFER["rect"].size.y / 2.0)
		_figure.flip_h = true
		_figure.play()
		add_child(_figure)
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = Vector2(90, 30)
		shape.shape = box
		shape.position = Vector2(0, -12)
		body.add_child(shape)
		add_child(body)
		_dialogue = DialoguePanel.new()
		_dialogue.name = "LuciferDialogue"
		_dialogue.npc_id = Hell.ID
		_dialogue.npc_name = Hell.NAME
		_dialogue.greeting = Hell.GREETING
		_dialogue.portrait = Hell.portrait()
		_dialogue.page_size = 6
		_dialogue.options_provider = func() -> Array[Dictionary]:
			return Hell.options(_start_fight)
		get_tree().current_scene.add_child.call_deferred(_dialogue)
		var layer := CanvasLayer.new()
		layer.layer = 5
		add_child(layer)
		_prompt = MenuStyle.title_label("[E] Beszélgetés: %s" % Hell.NAME, 32, Color(1.0, 0.5, 0.4))
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
		return is_instance_valid(_player) and visible and _player.global_position.distance_to(global_position) < TALK_RANGE

	func _process(delta: float) -> void:
		var target := 1.0 if _near() and not GamePause.active(get_tree()) else 0.0
		_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)

	func _unhandled_input(event: InputEvent) -> void:
		if not event.is_action_pressed("interact") or GamePause.active(get_tree()) or not _near():
			return
		get_viewport().set_input_as_handled()
		Audio.play("lucifer_laugh", -2.0)
		get_tree().current_scene.get_node("Menus").call("open_menu", _dialogue)

	## A hatodik opció: bezárul a beszélgetés, Lucifer eltűnik a helyéről, és a harc indul (ugyanott).
	func _start_fight() -> void:
		get_tree().current_scene.get_node("Menus").call("close_current")
		visible = false
		set_process_unhandled_input(false)
		for child in get_children():
			if child is StaticBody2D:
				child.queue_free()
		room.call("start_lucifer", position, _player)
		queue_free()
