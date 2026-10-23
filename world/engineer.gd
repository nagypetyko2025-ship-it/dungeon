class_name Engineer
## Bertalan, a mérnök a 10. emelet liftszobájában (lásd LiftRoom). Mesél, és a 4. kérdésre megmondja,
## hogy 500 aranyért (a kazamatában szerzett aranyból) megjavítja a liftet. Megjavítva a tábori
## liftről (lásd CampLift) le lehet jönni a 10. emeletre, és onnan kezdeni a kazamatát.

const ID := "engineer"
const NAME := "Bertalan, a mérnök"
## A szerelő figurája (védőszemüveg, villáskulcs): 4 kocka, 20x18 (lásd assets/characters/engineer.png).
const SHEET: Texture2D = preload("res://assets/characters/engineer.png")
const FRAME_SIZE := Vector2(20, 18)
const PRICE := 500
## Belső jelzők (Progress.npc_quests): megkérdezted az árát ("done"), és megjavította ("done").
const OFFER_FLAG := "lift_offer"
const REPAIRED_FLAG := "lift_repaired"
## A küldetés a J könyv "Mérnök" fülén (az ára elhangzásakor "active", a javításkor "done").
const LIFT_QUEST := "lift_repair"
## A javítás után (a beszélgetés bezárásakor) felmegy a lifttel a táborba: "pending", aztán "done".
const RIDE_FLAG := "lift_ride"

const QUESTS := {
	LIFT_QUEST: {"name": "Az elszakadt kötél",
		"text": "Bertalan, a mérnök a 10. emelet liftszobájában húsz éve vigyáz a régi bányaliftre. "
			+ "Ha hozol neki [b]%d aranyat[/b] (a kazamatában szerzettből, a tábori pénz odalent semmit sem ér), " % PRICE
			+ "megjavítja a liftet, és onnantól a táborból egyenesen a 10. emeletre jöhetsz le.",
		"reward": "a tábori lift a 10. emeletre is levisz",
		"doing": "vigyél Bertalannak %d aranyat a 10. emeletre" % PRICE, "done": "a lift újra jár"},
}

## A táborban (miután feljött a lifttel): két új történet.
const CAMP_STORIES: Array[Dictionary] = [
	{"id": "sunlight", "text": "Milyen volt húsz év után feljönni?", "trust": 4,
		"answer": "[i]Hunyorogva néz fel az égre, a szemüvegét a homlokára tolja.[/i]\n\n" \
			+ "Vakító. Elfelejtettem, hogy az ég ennyire... nagy. Odalent a legnagyobb dolog egy fogaskerék volt.\n\n" \
			+ "Az első éjjel nem tudtam aludni. Túl csend volt. Nem csikorgott semmi, nem morgott semmi a falak " \
			+ "mögött. Végül beraktam egy csavart a párnám alá, hogy valami ismerős legyen a közelben."},
	{"id": "plans", "text": "Mit fogsz most csinálni?", "trust": 3,
		"answer": "Karbantartani! Egy lift olyan, mint egy öreg ló: ha nem eteted, megbokrosodik.\n\n" \
			+ "[i]Közelebb hajol, és lehalkítja a hangját.[/i]\n\n" \
			+ "És van egy tervem. A huszadik emeletig is le lehetne vinni egy aknát. Persze ahhoz kellene egy " \
			+ "bátor kalandor, aki lekíséri a munkásokat... meg egy halom arany. Majd szólok, ha eljön az ideje."},
]
const DEPTH := 10

const GREETING := "[i]Egy védőszemüveges, kormos képű szerelő hajol egy hatalmas, rozsdás fogaskerék fölé. Fel sem néz.[/i]\n\n" \
	+ "Ha szörny vagy, harapj gyorsan. Ha kalandor, ne állj a fényembe."

const STORIES: Array[Dictionary] = [
	{"id": "who", "text": "Ki vagy te, és mit csinálsz itt lent?", "trust": 4,
		"answer": "Bertalan. A király mérnöke voltam, mielőtt a király rájött, hogy a mérnököket olcsóbb " \
			+ "lent hagyni, mint felhozni.\n\n[i]Megtörli a kezét egy olajos rongyban.[/i]\n\n" \
			+ "Ezt a liftet én építettem, húsz éve. Aranyat hoztunk fel vele a tizedik emeletről. Aztán jöttek a " \
			+ "szörnyek, és mindenki elfutott. Én maradtam. Valakinek vigyáznia kell rá."},
	{"id": "shaft", "text": "Hová vezet ez az akna?", "trust": 3,
		"answer": "Egyenesen fel, a táborba. A lépcső mellett jön ki, a szürke kövek mögött. Láttad? Az a " \
			+ "rácsos fülke.\n\n" \
			+ "Kilenc emeletnyi kötél. Ha működne, egy pillanat alatt lent lennél, nem kellene minden " \
			+ "alkalommal végigverekedned magad a goblinokon. Kár, hogy a fele kötél a szörnyek gyomrában van."},
	{"id": "monsters", "text": "Nem bántanak itt a szörnyek?", "trust": 3,
		"answer": "[i]Megkopogtatja a falat. Tompán kong: vastag vas.[/i]\n\n" \
			+ "Ez a szoba bányászkamra volt. Vasajtó, vasfal, és egy kis trükk: a fogaskerekek zaja " \
			+ "elriasztja őket. A szörnyek nem szeretik, ha valami náluk is hangosabb.\n\n" \
			+ "Egyszer egy minotaurusz bedugta ide a fejét. Odaadtam neki a legrozsdásabb csavarkulcsomat. " \
			+ "Azóta sem jött vissza."},
]


static func repaired() -> bool:
	return Progress.npc_quest_state(REPAIRED_FLAG) == "done"


## A táborban van-e már (a javítás után felment a lifttel).
static func in_camp() -> bool:
	return repaired() and Progress.npc_quest_state(RIDE_FLAG) != "pending"


## A táborban: az új történetek elöl, a régiek közül a még fel nem tettek, a végén a lift.
static func camp_options() -> Array[Dictionary]:
	var list: Array[Dictionary] = CAMP_STORIES.duplicate()
	var asked: Array = Progress.asked_topics(ID)
	for option in STORIES:
		if not asked.has(option["id"]):
			list.append(option)
	list.append({"id": "running", "text": "Működik a lift?",
		"on_choose": func() -> String: return "[i]Büszkén megpaskolja a rácsos fülkét.[/i]\n\n" \
			+ "Mint a svájci óra. Szállj be, és válaszd a tizedik emeletet. Én innen figyelem a kötelet."})
	return list


## A beszélgetés opciói: a három történet, negyediknek a lift (az ára, a fizetés, vagy a köszönet).
static func options(player: Node) -> Array[Dictionary]:
	var list: Array[Dictionary] = STORIES.duplicate()
	if repaired():
		list.append({"id": "running", "text": "Működik a lift?",
			"on_choose": func() -> String: return "[i]Megpaskolja a zúgó fogaskereket.[/i]\n\n" \
				+ "Mint a svájci óra. A táborból bármikor lejöhetsz vele ide, a tizedik emeletre. Fölfelé is " \
				+ "visz, ha meghalsz... na jó, az csak vicc volt. Fölfelé a lépcső vagy a portál."})
	elif Progress.npc_quest_state(OFFER_FLAG) != "done":
		list.append({"id": "repair", "text": "Meg lehet javítani a liftet?",
			"on_choose": func() -> String: return _offer()})
	else:
		list.append({"id": "pay", "text": "Itt az %d arany. Javítsd meg a liftet!" % PRICE,
			"on_choose": func() -> String: return _pay(player)})
	return list


static func _offer() -> String:
	Progress.set_npc_quest(OFFER_FLAG, "done")
	Progress.set_npc_quest(LIFT_QUEST, "active")
	Progress.mark_asked(ID, "repair")
	Progress.save_game()
	return "[i]Most először néz fel rád. A szeme csillog a korom alatt.[/i]\n\n" \
		+ "Megjavítani? Hát persze, hogy meg lehet! Új kötél kell, két új fogaskerék és egy kis... nevezzük " \
		+ "ösztönzésnek.\n\n" \
		+ "Hozz nekem [b]%d aranyat[/b]. Idelentről, a kazamatából, amit odalent szedsz össze: a tábori " % PRICE \
		+ "pénzetek itt semmit sem ér, a szörnyek nem fogadnak el váltót. Ha megvan, megjavítom, és " \
		+ "onnantól a táborból egyenesen ide jöhetsz le, a tizedik emeletre."


static func _pay(player: Node) -> String:
	if not is_instance_valid(player) or int(player.get("gold")) < PRICE:
		Audio.play("ui_error")
		return "[i]Megszámolja, amit mutatsz, aztán a fejét csóválja.[/i]\n\n" \
			+ "Ez nem %d arany, barátom. Szedj még össze odalent, és gyere vissza. Megvárlak, nem megyek sehova." % PRICE
	player.call("spend_gold", PRICE)
	Progress.set_npc_quest(REPAIRED_FLAG, "done")
	Progress.set_npc_quest(LIFT_QUEST, "done")
	Progress.set_npc_quest(RIDE_FLAG, "pending")
	Progress.mark_asked(ID, "pay")
	Progress.change_trust(ID, 30)
	Progress.save_game()
	Audio.play("level_up")
	return "[i]Bertalan zsákba söpri az aranyat, és munkához lát. Csattog a kalapács, sistereg az olaj, " \
		+ "aztán egy hosszú, mély nyikorgás után a lift zúgva életre kel.[/i]\n\n" \
		+ "Na tessék! Húsz év után újra jár. Mostantól a táborból egyenesen ide jöhetsz le: a lépcső melletti " \
		+ "liftbe szállsz, és a tizedik emeletet választod.\n\n" \
		+ "[i]Leporolja a nadrágját, és a ketrec felé indul.[/i]\n\nÉn meg felmegyek vele. Húsz év elég volt " \
		+ "a sötétből. Fent találkozunk, a lépcső mellett!\n\n" \
		+ "[color=#7a4a10](-%d arany. A tábori lift mostantól a 10. emeletre is levisz.)[/color]" % PRICE


static func portrait() -> AtlasTexture:
	var face := AtlasTexture.new()
	face.atlas = SHEET
	face.region = Rect2(Vector2.ZERO, FRAME_SIZE)
	return face


## Álló animáció (a villáskulcsát lóbálja).
static func frames() -> SpriteFrames:
	var result := SpriteFrames.new()
	result.set_animation_speed("default", 4.0)
	for i in 4:
		var frame := AtlasTexture.new()
		frame.atlas = SHEET
		frame.region = Rect2(Vector2(i * FRAME_SIZE.x, 0), FRAME_SIZE)
		result.add_frame("default", frame)
	return result
