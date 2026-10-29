extends "res://ui/intro_story.gd"
## Befejező kisfilm Azazel legyőzése után, a bevezetőhöz hasonlóan: karakterenként 6 kép arról, mi
## lett vele a jövőben. Az első kép mindenkinél a pokol trónja (Azazel hamuvá omló teste), a többi
## a karakter saját sorsa (`_<karakter>_<szám>`). A győzelmi ablak állítja be a `character`-t; a végén a tábor jön.

static var character := Characters.DEFAULT

const GUARD: Texture2D = preload("res://assets/characters/royal_guard.png")
const AZAZEL: Texture2D = preload("res://assets/enemies/lucifer.png")
const SKELETON := Rect2(368, 88, 16, 16)
const SWORD := Rect2(323, 10, 10, 21)

const DAY: Array[Color] = [Color(0.35, 0.5, 0.75), Color(0.7, 0.75, 0.6)]
const DAWN: Array[Color] = [Color(0.35, 0.3, 0.55), Color(0.95, 0.6, 0.4)]
const SUNSET: Array[Color] = [Color(0.3, 0.2, 0.4), Color(0.9, 0.45, 0.25)]
const NIGHT: Array[Color] = [Color(0.03, 0.04, 0.12), Color(0.1, 0.15, 0.2)]

const ENDINGS := {
	"knight": [
		"Azazel teste hamuvá omlik a trón előtt, és a pokol tüzei egymás után kialszanak. A Lovag leengedi a kardját. Száz emelet csendje száll rá.",
		"Amikor felért, a tábor már tudta. A tüzek mellett énekeltek, és valaki egy kupa sört nyomott a kezébe, mielőtt egy szót is szólhatott volna.",
		"A király a trónteremben fogadta. Nem aranyat adott neki, hanem egy új köpenyt: ő lett a királyi őrség kapitánya, akárcsak egykor Gáspár.",
		"Első parancsa az volt, hogy zárják le a lépcsőt. Kőből és vasból készült kapu került a Mélység szájára, és őrség állt mellé éjjel-nappal.",
		"Az évek múltak. A tábor helyén falu nőtt, a közepén gyakorlótérrel, ahol a kapitány fakardokkal tanította a fiatalokat. Az első leckéje mindig ugyanaz volt: ne félj.",
		"Öregen a rozsdás kardját a harminc kőtábla mellé tette. Nem kért magának harmincegyediket: azt mondta, a nevét elég, ha a Mélység megjegyzi.\n\n[b]Vége.[/b]",
	],
	"archer": [
		"Az utolsó nyíl még remeg Azazel mellkasában, amikor a Démonkirály térdre rogy. A pokol tüzei kialszanak, és az Íjász most először hallja a saját szívverését.",
		"Hetek után látta újra az eget. Nem a táborba ment először, hanem haza, az erdő szélére, ahol a fák ugyanúgy susogtak, mint amikor elment.",
		"A farkasok kijöttek a fák közül. Nem morogtak, nem támadtak: leültek vele szemben, mintha tudnák, honnan jött vissza.",
		"Néhány szörny még kiszökött, mielőtt lezárták a lépcsőt. Az Íjász évekig vadászott rájuk, és a falvakban az emberek újra nyitva merték hagyni az ablakot éjjel.",
		"A király az erdők őrévé tette. A falusi gyerekek hozzá jártak íjászatot tanulni, és mind tudni akarták, igaz-e, hogy egyszer a pokolba is belőtt.",
		"Öregen is a tűz mellett aludt, a csillagok alatt. Ha megkérdezték, mi volt a legnehezebb, mindig azt felelte: nem Azazel. Hanem visszajönni.\n\n[b]Vége.[/b]",
	],
	"veteran": [
		"„A fiaimért” — suttogja Gáspár, amikor Azazel elesik. Tizenkét év súlya hullik le róla a pokol hamujával együtt.",
		"Felért a táborba, és megállt a rönk mellett, amin tizenkét évig ült. Aztán nem ült le rá. Azóta senki sem ül rá: a tábor emlékként őrzi.",
		"A király szavát tartotta: az Aranykezű szobra helyén harminc kőtábla áll, a harminc névvel. Gáspár mindegyikhez odavésett valamit, amit csak ő tudott.",
		"A király újra felajánlotta neki a kapitányságot. Gáspár nemet mondott, de minden héten felment a várba, és hajnalig beszélgettek: két öreg ember, akik mindketten tévedtek.",
		"A kocsmában lett a helye, a kandalló mellett. A fiatal kalandorok köré gyűltek, és ő mesélt nekik: nem a szörnyekről, hanem az emberekről, akik vele mentek le.",
		"Egy tavaszi reggelen a kőtábláknál találták meg, a díszkard a lábánál. Mosolygott. A harmincegyedik táblát a király maga vésette: [i]Gáspár kapitány, aki hazahozta őket.[/i]\n\n[b]Vége.[/b]",
	],
	"wizard": [
		"Lőrinc utolsó tűzgolyója szétrobban Azazel szarvai között. A Démonkirály elesik, és a pokol kövei, amelyek eddig hazudtak a varázslónak, végre elcsendesednek.",
		"Hazaérve bezárkózott a szobájába, és negyven napig ki sem jött. Amikor végül ajtót nyitott, a kezében volt a Mélység teljes térképe: mind a száz emelet.",
		"A térképet a király könyvtárába vitték, a királyság legnagyobb kincseként. Lőrinc csak egyet kért: a századik emelet lapját soha senkinek ne mutassák meg.",
		"A lépcső lezárásához az ő varázslata kellett. Hét nap és hét éjjel mondta a szavakat, amíg a kövek a Mélység szájánál össze nem forrtak.",
		"A tábor mellett iskolát nyitott. A tanítványai tüzet gyújtottak a tenyerükben, és a köveket kérdezték az útról, ahogy ő tanította. Néha a kövek válaszoltak is.",
		"Egy éjjel elment, búcsú nélkül. Az asztalán egy új, üres térkép maradt, rajta egyetlen sor: [i]a csillagok felé is vezet út.[/i]\n\n[b]Vége.[/b]",
	],
	"gravedigger": [
		"Azazel elesik, és a trón mögül fények szállnak fel: a lelkek, akiket a Démonkirály ezer éve fogva tartott. Vendel leveszi előttük a kalapját.",
		"Hazafelé nem volt egyedül. A halottak, akiket a Mélység elnyelt, csontvázként követték, emeletről emeletre, egészen a felszínig.",
		"A tábor feletti dombon hónapokig ásott. Minden halott saját sírt kapott, és minden sírra név került, ha valaki még emlékezett rá.",
		"Az emberek eljöttek: anyák, testvérek, öreg barátok. Sokan húsz év után sírtak először, mert most először volt hol.",
		"Amikor az utolsó sírt is betemette, a talizmán elhalványult a nyakában. Vendel lefeküdt a domb tetején, a saját, előre megásott helyére, és végre pihenni tért.",
		"Tavasszal virágok nőttek a dombon. A falu egyik gyereke azóta minden héten felmegy, és rendben tartja a sírokat egy kopott ásóval, amit a domb tetején talált.\n\n[b]Vége.[/b]",
	],
	"thief": [
		"Bence tőre villan, és Azazel elesik. A tolvaj nem nevet és nem kiabál: leül a forró kőre, és arra gondol, mit szólna most az apja.",
		"Felfelé jövet, mélyen lent egy régi zászlót talált egy halom csont mellett. Benedek zászlaja volt. Bence összehajtotta, és a szíve fölé tette.",
		"Éjjelente bejárta a várost. Minden ajtó elé, ahonnan valaha lopott, egy erszényt tett, és egy cetlit: [i]Bocsánat. — B.[/i]",
		"A zászlót a tábor kapuja fölé tűzték fel. Az emberek megtanulták a nevét: nem a tolvajét, hanem a zászlóvivőét, aki elsőként ment le, és a fiáét, aki hazahozta.",
		"A király a felderítői élére állította. Azt mondta: aki tíz emeletet túlélt egyedül odalent, az a sötétben is lát.",
		"Évekkel később a saját fiát vitte a kapuhoz, és megmutatta neki a zászlót. „Ez a nagyapádé volt. Egyszer a tiéd lesz. De te soha ne lopj.”\n\n[b]Vége.[/b]",
	],
}


func _ready() -> void:
	if not ENDINGS.has(character):
		character = Characters.DEFAULT
	super()


func _slide_count() -> int:
	return (ENDINGS[character] as Array).size()


func _slide_text(index: int) -> String:
	return str((ENDINGS[character] as Array)[index])


func _draw_slide(index: int) -> void:
	if index == 0:
		_fall()
	else:
		call("_%s_%d" % [character, index])


func _next_scene() -> String:
	return NEXT_SCENE


func _music() -> String:
	# Minden karakternek saját zenéje van, ami csak itt szól (és a zeneválasztóban, a "Befejezések" alatt).
	return "end_" + character


# ---------------------------------------------------------------- közös: Azazel bukása

## A pokol trónja: kialvó tüzek, Azazel sötét, porladó alakja, előtte a hős (Vendelnél lelkek szállnak fel).
func _fall() -> void:
	_sky(Color(0.12, 0.02, 0.02), Color(0.35, 0.08, 0.04))
	for x in 15:
		for y in 3:
			_tile(FLOOR, Vector2(x * 16, 54 + y * 16)).modulate = Color(0.6, 0.3, 0.25)
	for x: float in [16.0, 52.0, 196.0, 228.0]:
		_fire(Vector2(x, 70), 0.45)
	var body := _texture(_atlas(AZAZEL, Rect2(Vector2.ZERO, Vector2(160, 144))), Vector2(170, 60))
	body.scale = Vector2(0.45, 0.45)
	body.modulate = Color(0.25, 0.1, 0.1, 0.75)
	_glow(Vector2(170, 72), Color(1, 0.4, 0.1, 0.3), 50.0)
	for i in 14:
		var ash := _rect(Vector2(150 + (i * 23) % 44, 30 + (i * 17) % 40), Vector2(1, 1), Color(0.5, 0.45, 0.45, 0.8))
		ash.create_tween().tween_property(ash, "position:y", ash.position.y - 24.0, 6.0)
	_hero(Vector2(96, 94))
	if character == "gravedigger":
		for i in 7:
			_wisp(Vector2(130 + i * 13, 70 - (i % 3) * 10))


# ---------------------------------------------------------------- a Lovag

func _knight_1() -> void:
	_outdoor(DAY, Color(0.85, 0.95, 0.85))
	_tent(Vector2(30, 58))
	_fire(Vector2(120, 86), 1.0)
	_hero(Vector2(104, 92))
	_people([[KNIGHT_F, Vector2(140, 92), true], [KNIGHT_M, Vector2(160, 86), true], [KNIGHT_F, Vector2(84, 84), false],
		[Rect2(128, 292, 16, 28), Vector2(180, 94), true]])
	_rect(Vector2(110, 80), Vector2(3, 4), Color(0.85, 0.6, 0.2))


func _knight_2() -> void:
	_throne_room()
	_hero(Vector2(150, 96), true)


func _knight_3() -> void:
	_sky(Color(0.04, 0.03, 0.05), Color(0.1, 0.08, 0.08))
	_hall(Color(0.6, 0.55, 0.55))
	_sealed_stairs(Vector2(112, 74), Color(0.6, 0.6, 0.65))
	_guard(Vector2(92, 92), false)
	_guard(Vector2(148, 92), true)
	_hero(Vector2(60, 94))
	_torch(Vector2(100, 50))
	_torch(Vector2(140, 50))


func _knight_4() -> void:
	_outdoor(DAY, Color(0.85, 0.95, 0.85), false)
	_rect(Vector2(0, 50), Vector2(240, 4), Color(0.45, 0.3, 0.18))
	var teacher := _hero(Vector2(60, 90))
	teacher.modulate = Color(0.9, 0.9, 0.9)
	for i in 5:
		var kid := _frames(SpriteSheet.character_frames(KNIGHT_M if i % 2 == 0 else KNIGHT_F), Vector2(110 + i * 22, 86 + (i % 2) * 8), true)
		kid.scale = Vector2(0.65, 0.65)
		_rect(Vector2(102 + i * 22, 72 + (i % 2) * 8), Vector2(1, 8), Color(0.55, 0.38, 0.2))


func _knight_5() -> void:
	_outdoor(SUNSET, Color(0.9, 0.7, 0.6), false)
	_tablets(Vector2(85, 64))
	_sword(Vector2(160, 84), 0.25, Color(0.85, 0.6, 0.45))
	var old := _hero(Vector2(176, 94), true)
	old.modulate = Color(0.8, 0.8, 0.85)
	old.speed_scale = 0.4


# ---------------------------------------------------------------- az Íjász

func _archer_1() -> void:
	_outdoor(DAWN, Color(0.9, 0.8, 0.75), false)
	_forest(Color(0.55, 0.6, 0.55))
	_hero(Vector2(60, 92))
	_glow(Vector2(200, 30), Color(1, 0.85, 0.5, 0.5), 40.0)


func _archer_2() -> void:
	_outdoor(DAY, Color(0.75, 0.85, 0.75), false)
	_forest(Color(0.5, 0.6, 0.5))
	_hero(Vector2(70, 92))
	for i in 3:
		_wolf(Vector2(130 + i * 30, 92 - (i % 2) * 6), Color(0.55, 0.55, 0.6).lightened(i * 0.1))


func _archer_3() -> void:
	_outdoor(NIGHT, Color(0.4, 0.45, 0.55), false)
	_forest(Color(0.25, 0.3, 0.35))
	_hero(Vector2(50, 92))
	var monster := _frames(SpriteSheet.character_frames(MONSTERS[2]), Vector2(190, 90), true)
	monster.modulate = Color(0.8, 0.6, 0.6)
	var arrow := Line2D.new()
	arrow.width = 1.0
	arrow.default_color = Color(0.85, 0.8, 0.7)
	arrow.add_point(Vector2(62, 78))
	arrow.add_point(Vector2(74, 78))
	_picture.add_child(arrow)
	arrow.create_tween().tween_property(arrow, "position:x", 110.0, 1.2)
	_glow(Vector2(120, 20), Color(0.8, 0.85, 1, 0.3), 20.0)


func _archer_4() -> void:
	_outdoor(DAY, Color(0.85, 0.95, 0.85))
	for i in 2:
		var target := _rect(Vector2(180 + i * 30, 66), Vector2(10, 10), Color(0.85, 0.8, 0.65))
		_rect(target.position + Vector2(3, 3), Vector2(4, 4), Color(0.75, 0.15, 0.1))
	var teacher := _hero(Vector2(60, 92))
	teacher.modulate = Color(0.9, 0.9, 0.9)
	for i in 4:
		var kid := _frames(Characters.frames("archer"), Vector2(90 + i * 20, 90 + (i % 2) * 6))
		kid.scale = Vector2(0.6, 0.6)


func _archer_5() -> void:
	_outdoor(NIGHT, Color(0.4, 0.45, 0.55), false)
	_stars(28)
	_forest(Color(0.2, 0.25, 0.3))
	_fire(Vector2(120, 88), 1.0)
	var old := _hero(Vector2(100, 92))
	old.modulate = Color(0.75, 0.75, 0.8)
	old.speed_scale = 0.3


# ---------------------------------------------------------------- Gáspár

func _veteran_1() -> void:
	_outdoor(DAY, Color(0.85, 0.95, 0.85))
	_tent(Vector2(190, 58))
	_rect(Vector2(96, 86), Vector2(22, 6), Color(0.45, 0.3, 0.16))
	_rect(Vector2(96, 86), Vector2(22, 2), Color(0.6, 0.42, 0.24))
	_hero(Vector2(136, 94), true)


func _veteran_2() -> void:
	_outdoor(DAY, Color(0.85, 0.95, 0.85), false)
	_tablets(Vector2(85, 62))
	_hero(Vector2(70, 96))


func _veteran_3() -> void:
	_throne_room()
	_hero(Vector2(150, 96), true)


func _veteran_4() -> void:
	_sky(Color(0.15, 0.08, 0.05), Color(0.3, 0.18, 0.1))
	_hall(Color(0.75, 0.6, 0.5))
	_fire(Vector2(120, 62), 1.0)
	_rect(Vector2(108, 54), Vector2(24, 2), Color(0.35, 0.3, 0.3))
	_hero(Vector2(104, 92))
	_people([[KNIGHT_M, Vector2(144, 92), true], [KNIGHT_F, Vector2(164, 96), true], [Rect2(128, 292, 16, 28), Vector2(184, 90), true]])
	var thief := _npc("thief", Vector2(76, 96))
	thief.modulate = Color(0.9, 0.9, 0.9)


func _veteran_5() -> void:
	_outdoor(DAWN, Color(0.95, 0.85, 0.8), false)
	_tablets(Vector2(85, 62))
	_rect(Vector2(158, 66), Vector2(6, 8), Color(0.7, 0.7, 0.75))
	_sword(Vector2(150, 94), 1.4, Color(1, 0.95, 0.85))
	for i in 9:
		_rect(Vector2(40 + i * 19, 90 + (i % 3) * 3), Vector2(2, 2), Color(1, 0.6 + (i % 2) * 0.3, 0.7))


# ---------------------------------------------------------------- Lőrinc

func _wizard_1() -> void:
	_sky(Color(0.1, 0.08, 0.12), Color(0.25, 0.2, 0.2))
	_hall(Color(0.75, 0.7, 0.65))
	_map(Vector2(130, 34), Vector2(60, 40))
	_torch(Vector2(110, 40))
	_hero(Vector2(100, 94))


func _wizard_2() -> void:
	_throne_room()
	_map(Vector2(30, 34), Vector2(40, 26))
	_hero(Vector2(150, 96), true)


func _wizard_3() -> void:
	_sky(Color(0.04, 0.03, 0.08), Color(0.1, 0.06, 0.14))
	_hall(Color(0.55, 0.5, 0.6))
	_sealed_stairs(Vector2(140, 74), Color(0.7, 0.6, 0.85))
	_glow(Vector2(148, 80), Color(0.6, 0.3, 1, 0.5), 36.0)
	for i in 6:
		_wisp(Vector2(126 + i * 9, 86), Color(0.7, 0.5, 1, 0.6))
	_hero(Vector2(90, 94))


func _wizard_4() -> void:
	_outdoor(DAY, Color(0.85, 0.95, 0.85))
	var teacher := _hero(Vector2(60, 92))
	teacher.modulate = Color(0.9, 0.9, 0.9)
	for i in 4:
		var pupil := _frames(Characters.frames("wizard"), Vector2(100 + i * 26, 90 + (i % 2) * 6), true)
		pupil.scale = Vector2(0.65, 0.65)
		_glow(pupil.position + Vector2(-5, -10), Color(1, 0.55, 0.2, 0.7), 5.0)


func _wizard_5() -> void:
	_outdoor(NIGHT, Color(0.4, 0.45, 0.55), false)
	_stars(40)
	_glow(Vector2(120, 20), Color(0.7, 0.75, 1, 0.35), 30.0)
	var leaving := _hero(Vector2(150, 90), true)
	leaving.modulate = Color(0.8, 0.85, 1, 0.6)
	leaving.create_tween().tween_property(leaving, "modulate:a", 0.0, 7.0)
	_map(Vector2(50, 70), Vector2(26, 16))


# ---------------------------------------------------------------- Vendel

func _gravedigger_1() -> void:
	_sky(Color(0.04, 0.03, 0.05), Color(0.1, 0.08, 0.08))
	_hall(Color(0.55, 0.5, 0.55))
	_tile(STAIRS, Vector2(210, 74))
	_glow(Vector2(218, 82), Color(1, 0.9, 0.6, 0.35), 24.0)
	var leader := _hero(Vector2(180, 92))
	leader.play("run")
	leader.speed_scale = 0.5
	for i in 7:
		var bones := _frames(SpriteSheet.character_frames(SKELETON), Vector2(150 - i * 20, 90 + (i % 2) * 6))
		bones.play("run")
		bones.speed_scale = 0.5
	_torch(Vector2(120, 50))


func _gravedigger_2() -> void:
	_outdoor(DAY, Color(0.8, 0.9, 0.8), false)
	_graves(10)
	_hero(Vector2(196, 94), true)
	_rect(Vector2(180, 92), Vector2(10, 3), Color(0.4, 0.28, 0.18))


func _gravedigger_3() -> void:
	_outdoor(SUNSET, Color(0.85, 0.7, 0.65), false)
	_graves(14)
	_npc("veteran", Vector2(60, 96))
	_people([[KNIGHT_F, Vector2(110, 96), false], [Rect2(128, 292, 16, 28), Vector2(150, 92), true],
		[KNIGHT_M, Vector2(186, 96), true]])
	_hero(Vector2(220, 90), true)


func _gravedigger_4() -> void:
	_outdoor(NIGHT, Color(0.45, 0.5, 0.6), false)
	_stars(24)
	_graves(14)
	var rest := _hero(Vector2(120, 70))
	rest.rotation = -PI / 2.0
	rest.modulate = Color(0.85, 0.85, 0.95)
	rest.create_tween().tween_property(rest, "modulate:a", 0.25, 7.0)
	_wisp(Vector2(126, 66), Color(0.6, 0.85, 1, 0.6))


func _gravedigger_5() -> void:
	_outdoor(DAWN, Color(0.95, 0.9, 0.85), false)
	_graves(14)
	for i in 20:
		_rect(Vector2(12 + (i * 47) % 220, 66 + (i * 11) % 30), Vector2(2, 2), [Color(1, 0.4, 0.5), Color(1, 0.9, 0.3), Color(0.7, 0.6, 1)][i % 3])
	var kid := _frames(SpriteSheet.character_frames(KNIGHT_M), Vector2(150, 94), true)
	kid.scale = Vector2(0.65, 0.65)
	_rect(Vector2(140, 78), Vector2(1, 14), Color(0.5, 0.4, 0.3))


# ---------------------------------------------------------------- Bence

func _thief_1() -> void:
	_sky(Color(0.04, 0.03, 0.05), Color(0.1, 0.08, 0.08))
	_hall(Color(0.55, 0.5, 0.55))
	var banner := _tile(BANNER_RED, Vector2(130, 86))
	banner.rotation = -PI / 2.0
	for i in 6:
		_rect(Vector2(150 + (i * 7) % 20, 86 + (i * 3) % 6), Vector2(4, 1), Color(0.85, 0.82, 0.75))
	_hero(Vector2(110, 94))
	_torch(Vector2(120, 50))


func _thief_2() -> void:
	_sky(NIGHT[0], NIGHT[1])
	_stars(20)
	for x in 15:
		_tile(WALL_MID, Vector2(x * 16, 46)).modulate = Color(0.4, 0.42, 0.55)
		_tile(WALL_MID, Vector2(x * 16, 62)).modulate = Color(0.4, 0.42, 0.55)
		_tile(FLOOR, Vector2(x * 16, 78)).modulate = Color(0.4, 0.42, 0.5)
		_tile(FLOOR, Vector2(x * 16, 94)).modulate = Color(0.4, 0.42, 0.5)
	for i in 4:
		_rect(Vector2(30 + i * 56, 60), Vector2(10, 18), Color(0.3, 0.2, 0.12))
		_rect(Vector2(32 + i * 56, 74), Vector2(5, 4), Color(0.85, 0.7, 0.2))
		_glow(Vector2(35 + i * 56, 50), Color(1, 0.75, 0.35, 0.35), 8.0)
	var sneak := _hero(Vector2(150, 92), true)
	sneak.modulate = Color(0.6, 0.6, 0.75)


func _thief_3() -> void:
	_outdoor(DAY, Color(0.85, 0.95, 0.85), false)
	for x in 15:
		_tile(WALL_TOP, Vector2(x * 16, 22))
		_tile(WALL_MID, Vector2(x * 16, 38))
	_rect(Vector2(104, 38), Vector2(32, 16), Color(0.2, 0.14, 0.1))
	_tile(BANNER_RED, Vector2(112, 22))
	_hero(Vector2(120, 92))
	_people([[KNIGHT_M, Vector2(70, 90), false], [KNIGHT_F, Vector2(90, 96), false], [Rect2(128, 292, 16, 28), Vector2(160, 94), true],
		[KNIGHT_F, Vector2(186, 90), true]])
	_guard(Vector2(40, 94), false)


func _thief_4() -> void:
	_throne_room()
	_hero(Vector2(150, 96), true)


func _thief_5() -> void:
	_outdoor(SUNSET, Color(0.9, 0.75, 0.65), false)
	for x in 15:
		_tile(WALL_TOP, Vector2(x * 16, 22)).modulate = Color(0.9, 0.75, 0.7)
		_tile(WALL_MID, Vector2(x * 16, 38)).modulate = Color(0.9, 0.75, 0.7)
	_tile(BANNER_RED, Vector2(112, 22))
	var father := _hero(Vector2(110, 94))
	father.modulate = Color(0.9, 0.9, 0.9)
	var son := _hero(Vector2(130, 94), true)
	son.scale = Vector2(0.6, 0.6)


# ---------------------------------------------------------------- segédek

func _hero(at: Vector2, flip := false) -> AnimatedSprite2D:
	return _frames(Characters.frames(character), at, flip)


func _npc(id: String, at: Vector2, flip := false) -> AnimatedSprite2D:
	return _frames(Characters.frames(id), at, flip)


func _guard(at: Vector2, flip: bool) -> void:
	var guard := _frames(_sheet_frames(GUARD, Vector2(16, 28)), at, flip)
	guard.speed_scale = 0.5


## Ülő farkas (balra néz), néhány téglalapból; `at` a talppontja.
func _wolf(at: Vector2, color: Color) -> void:
	var dark := color.darkened(0.35)
	_rect(at + Vector2(6, -3), Vector2(7, 2), dark)
	_rect(at + Vector2(0, -9), Vector2(8, 9), color)
	_rect(at + Vector2(-3, -13), Vector2(6, 5), color)
	_rect(at + Vector2(-5, -11), Vector2(3, 2), dark)
	_rect(at + Vector2(-3, -15), Vector2(1, 2), dark)
	_rect(at + Vector2(1, -15), Vector2(1, 2), dark)
	_rect(at + Vector2(-2, -12), Vector2(1, 1), Color(0.9, 0.85, 0.4))
	_rect(at + Vector2(1, -2), Vector2(1, 2), dark)


## [rect, hely, tükrözve] hármasok: 0x72 figurák (a tömeg).
func _people(list: Array) -> void:
	for entry: Array in list:
		_frames(SpriteSheet.character_frames(entry[0]), entry[1], entry[2]).speed_scale = 0.6


func _outdoor(sky: Array[Color], tint: Color, trees := true) -> void:
	_sky(sky[0], sky[1])
	for x in 15:
		for y in 3:
			_rpg(Vector2i(x % 2, 15 + y % 2), Vector2(x * 16, 54 + y * 16)).modulate = tint
	if trees:
		for i in 6:
			_rpg(Vector2i(13 + (i % 3) * 2, 11), Vector2(8 + i * 44, 44)).modulate = tint.darkened(0.3)


func _forest(tint: Color) -> void:
	for i in 12:
		var tree := _rpg(Vector2i(13 + (i % 3) * 2, 11), Vector2(i * 20 + (i % 2) * 6, 34 + (i % 3) * 8))
		tree.modulate = tint
		tree.scale = Vector2(1.4, 1.4)


func _hall(tint: Color) -> void:
	for x in 15:
		_tile(WALL_TOP, Vector2(x * 16, 30)).modulate = tint
		_tile(WALL_MID, Vector2(x * 16, 46)).modulate = tint
		for y in 3:
			_tile(FLOOR, Vector2(x * 16, 62 + y * 16)).modulate = tint


func _throne_room() -> void:
	_sky(Color(0.25, 0.32, 0.55), Color(0.55, 0.45, 0.4))
	_hall(Color.WHITE)
	for x in [2, 6, 8, 12]:
		_tile(BANNER_RED if x % 4 == 0 else BANNER_YELLOW, Vector2(x * 16, 46))
	_texture(THRONE, Vector2(120, 66))
	_frames(_sheet_frames(KING, Vector2(16, 32)), Vector2(120, 74))
	_guard(Vector2(84, 84), false)
	_torch(Vector2(64, 56))
	_torch(Vector2(176, 56))


func _tent(at: Vector2) -> void:
	for dx in 2:
		for dy in 2:
			_rpg(Vector2i(46 + dx, 10 + dy), at + Vector2(dx * 16, dy * 16))


func _fire(at: Vector2, strength: float) -> void:
	var fire := AnimatedSprite2D.new()
	fire.sprite_frames = _rpg_frames([Vector2i(14, 8), Vector2i(15, 8)])
	fire.position = at
	fire.scale = Vector2.ONE * (0.6 + strength * 0.4)
	fire.modulate.a = 0.5 + strength * 0.5
	fire.play()
	_picture.add_child(fire)
	_glow(at - Vector2(0, 4), Color(1, 0.6, 0.2, 0.35 * strength), 40.0 * strength)


func _sword(at: Vector2, angle: float, color: Color) -> void:
	var sword := Sprite2D.new()
	sword.texture = SpriteSheet.region(SWORD)
	sword.position = at
	sword.rotation = angle
	sword.modulate = color
	_picture.add_child(sword)


## A harminc kőtábla (három sorban), a harminc névvel.
func _tablets(origin: Vector2) -> void:
	for row in 3:
		for column in 10:
			var at := origin + Vector2(column * 7, row * 9)
			_rect(at, Vector2(5, 7), Color(0.6, 0.6, 0.65))
			_rect(at + Vector2(1, 2), Vector2(3, 1), Color(0.35, 0.35, 0.4))


func _graves(count: int) -> void:
	for i in count:
		var at := Vector2(14 + (i * 37) % 200, 60 + (i * 13) % 26)
		_rect(at + Vector2(-2, 8), Vector2(10, 3), Color(0.35, 0.25, 0.16))
		_rect(at, Vector2(6, 9), Color(0.6, 0.6, 0.62))
		_rect(at + Vector2(1, 2), Vector2(4, 1), Color(0.35, 0.35, 0.4))


func _sealed_stairs(at: Vector2, color: Color) -> void:
	_tile(STAIRS, at)
	_rect(at + Vector2(-2, -2), Vector2(20, 20), color)
	for i in 3:
		_rect(at + Vector2(-2, 2 + i * 6), Vector2(20, 1), color.darkened(0.45))


## Pergamen térkép, rajta kanyargó járatok.
func _map(at: Vector2, size: Vector2) -> void:
	_rect(at, size, Color(0.85, 0.75, 0.55))
	var path := Line2D.new()
	path.width = 1.0
	path.default_color = Color(0.45, 0.3, 0.18)
	for i in 9:
		path.add_point(at + Vector2(3 + i * (size.x - 6) / 8.0, 3 + ((i * 7) % 5) * (size.y - 6) / 4.0))
	_picture.add_child(path)


func _stars(count: int) -> void:
	for i in count:
		_rect(Vector2((i * 53) % 240, (i * 29) % 40), Vector2(1, 1), Color(1, 1, 0.9, 0.5 + (i % 3) * 0.2))


## Felszálló halvány fény (lélek / varázslat).
func _wisp(at: Vector2, color := Color(0.6, 0.85, 1, 0.6)) -> void:
	var holder := Node2D.new()
	holder.position = at
	_picture.add_child(holder)
	var keep := _picture
	_picture = holder
	_glow(Vector2.ZERO, color, 6.0)
	_picture = keep
	var rise := holder.create_tween().set_loops()
	rise.tween_property(holder, "position:y", at.y - 30.0, 4.0 + fmod(at.x, 3.0))
	rise.tween_property(holder, "position:y", at.y, 0.0)


func _rect(at: Vector2, size: Vector2, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = at
	rect.size = size
	rect.color = color
	_picture.add_child(rect)
	return rect


func _atlas(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas
