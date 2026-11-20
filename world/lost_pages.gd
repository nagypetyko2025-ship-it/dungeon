class_name LostPages
## Elveszett lapok: Vidor bányaírnok négyszáz éves naplójának szétszórt lapjai (gyűjthető, összefüggő történet:
## hogyan lett Aurél bányamesterből király, mi volt az alku ára — a király szálának előzménye, lásd King, Hell).
## A lapok egy része a táborban van elrejtve ("camp": csempe a tábor világában, place_camp), a többi lent a
## kazamatában ("depth": ettől az emelettől jöhet; place_in_dungeon emeletenként legfeljebb egyet tesz le, a
## legkisebb sorszámú még meg nem találtat, PAGE_CHANCE eséllyel, a padló saját magjából). Felvéve örökre
## megvan (Progress.npc_quests FLAG), és rögtön kinyílik az olvasó (LostPagesPanel); a J könyvben is elolvasható.
## A felvehető lap feltűnő: aranyan izzik, lebeg, szikrázik, fényt vet (PagePickup).

const FLAG := "lost_page_%d"
const PAGE_CHANCE := 0.4
const TILE := 32

const PAGES: Array[Dictionary] = [
	{"title": "I. Az első bejegyzés", "camp": Vector2i(243, 6),
		"text": "Vidor vagyok, a bánya írnoka. Aurél mester megbízott, hogy írjak fel mindent, ami a hegy alatt "
			+ "történik: hány szekér követ hoztunk fel, ki sérült meg, mennyi a bér.\n\n"
			+ "Szegény falu a miénk. A hegy eddig csak rezet adott, azt is kelletlenül. De Aurél mester azt mondja, "
			+ "lent több van. Mindig ezt mondja. Az asszonyok már nevetnek rajta.\n\n"
			+ "Én nem nevetek. Láttam a szemét, amikor lefelé néz az aknába."},
	{"title": "II. A sárga ér", "camp": Vector2i(550, 6),
		"text": "Arany. A hatodik tárnában, egy repedés mögött. Akkora ér, hogy a lámpa fénye visszaverődik róla, "
			+ "mintha a hegy szeme volna nyitva.\n\n"
			+ "A falu egy hét alatt kicserélődött. Jöttek kőművesek, kereskedők, katonák. Aurél mester kőházat "
			+ "épít a régi helyén, és aranyláncot hord.\n\n"
			+ "Furcsa. Az ér nem fogy. Amit délben kibányászunk, reggelre visszanő. Senki nem kérdez rá. Én "
			+ "felírtam, és az írásom remegett."},
	{"title": "III. Kopogás a mélyben", "camp": Vector2i(428, 7),
		"text": "A bányászok éjjel nem mennek le többé. Azt mondják, a hatodik tárna alól kopogás hallatszik, "
			+ "egyenletes, mint aki ajtón zörget.\n\n"
			+ "Aurél mester kinevette őket. Aztán egy éjjel egyedül ment le, lámpa nélkül. Hajnalban jött fel. "
			+ "A ruhája száraz volt, pedig odalent csöpög a víz, és nem szólt senkihez három napig.\n\n"
			+ "Ezt a lapot a kápolnában írom. Itt nyugodtabb a kezem."},
	{"title": "IV. A rajzok", "camp": Vector2i(693, 7),
		"text": "Aurél mester rajzokat hozott. Lépegető gép, sárgarézből és vasból, gőzzel hajtva, amely magától "
			+ "ás lefelé, és nem kell neki ember.\n\n"
			+ "A mesterek azt mondják, ilyet senki nem tud kitalálni. A rajzok sarkában furcsa jelek vannak, "
			+ "egyik ábécéből sem valók. A tinta vöröses, és meleg, ha hozzáérsz.\n\n"
			+ "Két év alatt megépült. Leküldték. Azóta a föld alatt dübörög, éjjel-nappal, mint egy óramű."},
	{"title": "V. Lent jártam", "depth": 3,
		"text": "Követtem. Isten bocsássa meg, követtem Aurél mestert a hatodik tárna alá.\n\n"
			+ "A lépcsőt nem ember vágta. Túl szabályos, túl mély, és a fokok a mi lábunknál nagyobbak. Lent "
			+ "termek voltak, egymás után, oszlopokkal, mint egy templom, amit a föld nyelt el.\n\n"
			+ "Ezt a lapot itt hagyom, a második teremben. Ha nem jövök vissza, legalább ez maradjon."},
	{"title": "VI. A vörös fény", "depth": 10,
		"text": "Mélyebben jártam, mint valaha élő ember. Aurél mester előttem ment, és nem fordult hátra.\n\n"
			+ "Egy nagy terem végében vörös fény égett, láng nélkül. Aurél letérdelt előtte. Nem hallottam, "
			+ "mit mondott. Csak a választ hallottam, és az nem a fülemen át jött be, hanem a fogaimon.\n\n"
			+ "„Szabad utat.” Ennyit értettem. Szabad utat. Mihez?"},
	{"title": "VII. Az egyezség", "depth": 20,
		"text": "Engem hívatott írnoknak. Engem! Mert én tudok a legszebben írni a faluban.\n\n"
			+ "Lediktálta, és én leírtam: aranyat a mélységből, szabad utat a mélységnek. A háza fizet, valahányszor "
			+ "megremeg a föld. Nemzedékenként harminc.\n\n"
			+ "Megkérdeztem: harminc mit, mester? Nem felelt. A kezem magától írt tovább, és a tinta vörös lett.\n\n"
			+ "Ő írta alá. A vörös fényben valami más is aláírt."},
	{"title": "VIII. A láda", "depth": 30,
		"text": "Aurélt királlyá koronázták. Az Aranykezű, így hívják. A szobrát már faragják.\n\n"
			+ "Csináltatott egy vasládát, és belezárt egy levelet az unokáinak: „küldj le harminc pajzsot, és a "
			+ "sötétség visszahúzódik”. Jóslatnak nevezte. Én tudom, mi az. Számla.\n\n"
			+ "Mondtam neki. Másnap elvették a tollamat és a bányaírnoki láncomat. Azt mondják, megbolondultam."},
	{"title": "IX. Az első harminc", "depth": 45,
		"text": "Öreg vagyok már. Aurél meghalt, a fia ül a trónon. Tavaly megremegett a föld.\n\n"
			+ "A király kinyitotta a ládát. Harminc ifjú indult le a hatodik tárnába, fényes pajzzsal, énekelve. "
			+ "Láttam őket elmenni a házam előtt. Egyik sem jött vissza.\n\n"
			+ "A föld elcsendesedett. Az ér újra nőni kezdett. A piacon ünnepeltek.\n\n"
			+ "Én a nevüket írtam fel. Mind a harmincat."},
	{"title": "X. Az utolsó lap", "depth": 70,
		"text": "Ezt az utolsót a legmélyebbre viszem, ameddig a lábam elbír.\n\n"
			+ "A naplómat széttéptem, és a lapjait elrejtettem: a házamban, a raktárban, a kápolnában, a "
			+ "katonák szállásán, és idelent, a termek között. Fent elégetnék. Itt lent senki nem keresi.\n\n"
			+ "Aki mind megtalálja, tudni fogja, honnan jött az arany, és mi az ára. Talán ő az, aki egyszer "
			+ "nemet mond a vörös fénynek.\n\n"
			+ "Vidor, aki írnok volt."},
]


static func count() -> int:
	return PAGES.size()


static func found(index: int) -> bool:
	return Progress.npc_quest_state(FLAG % index) == "found"


static func found_count() -> int:
	var total := 0
	for i in PAGES.size():
		if found(i):
			total += 1
	return total


static func mark(index: int) -> void:
	Progress.set_npc_quest(FLAG % index, "found")


## A tábor lapjai (amiket még nem találtál), a tábor világának y-szerinti rétegébe.
static func place_camp(parent: Node2D) -> void:
	for i in PAGES.size():
		if PAGES[i].has("camp") and not found(i):
			var tile: Vector2i = PAGES[i]["camp"]
			var page := PagePickup.new()
			page.index = i
			page.position = (Vector2(tile) + Vector2(0.5, 0.5)) * TILE
			parent.add_child(page)


## Lent: a legkisebb sorszámú, ezen a mélységen már jöhető, még meg nem talált lap, PAGE_CHANCE eséllyel, egy
## harci szoba szabad csempéjén. Saját véletlen (a padló magjából): a pálya többi sorsolását nem tolja el.
static func place_in_dungeon(rooms: Array[Room], depth: int, floor_seed: int) -> void:
	if GameState.tutorial or not Challenge.story().is_empty():
		return
	var index := -1
	for i in PAGES.size():
		if PAGES[i].has("depth") and depth >= int(PAGES[i]["depth"]) and not found(i):
			index = i
			break
	if index < 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = floor_seed * 31 + 7
	if rng.randf() >= PAGE_CHANCE:
		return
	var candidates := rooms.filter(func(room: Room) -> bool:
		return room.enemy_count > 0 and not room.has_boss and not room.has_shop and room.special != "prison")
	if candidates.is_empty():
		return
	var room: Room = candidates[rng.randi() % candidates.size()]
	var inner := room.rect.grow(-2)
	for attempt in 30:
		var tile := Vector2i(rng.randi_range(inner.position.x, inner.end.x - 1), rng.randi_range(inner.position.y, inner.end.y - 1))
		if room.is_tile_used(tile) or tile == room.anchor:
			continue
		var page := PagePickup.new()
		page.index = index
		page.position = room.local_pos(tile)
		room.add_child(page)
		room.mark_tile_used(tile)
		return


## A felvehető lap: aranyan izzó pergamen, lebeg, lüktet, szikrázik és fényt vet. Hozzáérve felveszed.
class PagePickup extends Node2D:
	const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
	const SCROLL := Rect2(44 * 17, 15 * 17, 16, 16)
	const GOLD := Color(1.0, 0.85, 0.35)
	var index := 0
	var _taken := false

	func _ready() -> void:
		z_index = 2
		var light := PointLight2D.new()
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 1))
		gradient.set_color(1, Color(1, 1, 1, 0))
		var glow := GradientTexture2D.new()
		glow.gradient = gradient
		glow.fill = GradientTexture2D.FILL_RADIAL
		glow.fill_from = Vector2(0.5, 0.5)
		glow.fill_to = Vector2(1.0, 0.5)
		glow.width = 128
		glow.height = 128
		light.texture = glow
		light.texture_scale = 2.2
		light.color = GOLD
		light.energy = 1.3
		add_child(light)
		var halo := Sprite2D.new()
		halo.texture = glow
		halo.modulate = Color(1.0, 0.8, 0.3, 0.45)
		halo.scale = Vector2(0.55, 0.55)
		halo.position = Vector2(0, -10)
		add_child(halo)
		var sparks := CPUParticles2D.new()
		sparks.amount = 14
		sparks.lifetime = 1.4
		sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		sparks.emission_sphere_radius = 16.0
		sparks.direction = Vector2.UP
		sparks.spread = 30.0
		sparks.gravity = Vector2(0, -20)
		sparks.initial_velocity_min = 8.0
		sparks.initial_velocity_max = 22.0
		sparks.scale_amount_min = 1.5
		sparks.scale_amount_max = 3.0
		sparks.color = Color(1.0, 0.9, 0.45)
		sparks.position = Vector2(0, -10)
		add_child(sparks)
		var sprite := Sprite2D.new()
		sprite.texture = RPG
		sprite.region_enabled = true
		sprite.region_rect = SCROLL
		sprite.scale = Vector2(2.4, 2.4)
		sprite.position = Vector2(0, -10)
		sprite.modulate = Color(1.5, 1.3, 0.8)
		add_child(sprite)
		var bob := create_tween().set_loops()
		bob.tween_property(sprite, "position:y", -18.0, 0.9).set_trans(Tween.TRANS_SINE)
		bob.tween_property(sprite, "position:y", -10.0, 0.9).set_trans(Tween.TRANS_SINE)
		var pulse := create_tween().set_loops()
		pulse.tween_property(halo, "scale", Vector2(0.7, 0.7), 0.8).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(halo, "scale", Vector2(0.5, 0.5), 0.8).set_trans(Tween.TRANS_SINE)
		var area := Area2D.new()
		area.collision_layer = 0
		area.collision_mask = 2
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 30.0
		shape.shape = circle
		area.add_child(shape)
		area.body_entered.connect(_on_body)
		add_child(area)

	func _on_body(body: Node2D) -> void:
		if _taken or not body.is_in_group("player"):
			return
		# Közös játékban csak a saját karaktered veheti fel (a lap a te gyűjteményed).
		if body.has_method("is_multiplayer_authority") and not body.is_multiplayer_authority():
			return
		_taken = true
		LostPages.mark(index)
		Audio.play("level_up")
		FloatingText.spawn(get_parent(), global_position + Vector2(0, -40),
			"Elveszett lap! (%d / %d)" % [LostPages.found_count(), LostPages.count()], GOLD, 22)
		LostPagesPanel.show_page(get_tree(), index)
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.4)
		tween.tween_callback(queue_free)
