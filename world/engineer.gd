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
	# A mély aknák (a táborban, a javítás után): elvállalod, egy futásban leérsz arra az emeletre ("reached"),
	# aztán a táborban kifizeted (tábori arany), és a lift oda is levisz. Egyszerre csak a soron következő.
	"lift_20": {"name": "Akna a huszadikig",
		"text": "Bertalan a huszadik emeletig akarja levinni az aknát, de a munkásai nem mernek lemenni a Vérfarkas " \
			+ "szintjére. Juss le egy futásban a [b]20. emeletre[/b], hogy lássák, járható az út, aztán fizess " \
			+ "[b]1500 tábori aranyat[/b] a kötélre és a csigákra.",
		"reward": "a lift a 20. emeletre is levisz", "doing": "juss le a 20. emeletre",
		"doing_reached": "leértél: vigyél Bertalannak 1500 tábori aranyat", "done": "a lift a 20. emeletig jár"},
	"lift_30": {"name": "A vérkő-ér",
		"text": "A harmincadik emeleten vöröslő kő fut a falakban, és Bertalan szerint megeszi a vasat. Juss le " \
			+ "egy futásban a [b]30. emeletre[/b], és fizess [b]2500 tábori aranyat[/b] a rézzel bevont kötélre.",
		"reward": "a lift a 30. emeletre is levisz", "doing": "juss le a 30. emeletre",
		"doing_reached": "leértél: vigyél Bertalannak 2500 tábori aranyat", "done": "a lift a 30. emeletig jár"},
	"lift_40": {"name": "A Káosz pereme",
		"text": "A negyvenedik emeleten a Káosz Ura lakik, és ott a kövek sem maradnak a helyükön. Bertalannak " \
			+ "horgonyok kellenek, amik a semmibe is beleakadnak. Juss le a [b]40. emeletre[/b], és fizess " \
			+ "[b]4000 tábori aranyat[/b].",
		"reward": "a lift a 40. emeletre is levisz", "doing": "juss le a 40. emeletre",
		"doing_reached": "leértél: vigyél Bertalannak 4000 tábori aranyat", "done": "a lift a 40. emeletig jár"},
	"lift_50": {"name": "Félúton",
		"text": "Az ötvenedik emelet a Mélység közepe. Bertalan szerint ott egy régi törpe csigasor maradt, csak " \
			+ "valakinek meg kell keresnie. Juss le az [b]50. emeletre[/b], és fizess [b]5500 tábori aranyat[/b].",
		"reward": "a lift az 50. emeletre is levisz", "doing": "juss le az 50. emeletre",
		"doing_reached": "leértél: vigyél Bertalannak 5500 tábori aranyat", "done": "a lift az 50. emeletig jár"},
	"lift_60": {"name": "A gépezet szíve",
		"text": "A hatvanadik emeleten dübörög az Ősgépezet. Bertalan látni akarja, hogyan jár: ha egy ilyen gép " \
			+ "ezer évig bírta, az ő lifte is fogja. Juss le a [b]60. emeletre[/b], és fizess [b]7000 tábori aranyat[/b].",
		"reward": "a lift a 60. emeletre is levisz", "doing": "juss le a 60. emeletre",
		"doing_reached": "leértél: vigyél Bertalannak 7000 tábori aranyat", "done": "a lift a 60. emeletig jár"},
	"lift_70": {"name": "Ahol a kötél ég",
		"text": "A hetvenedik emeleten olyan forró a levegő, hogy a kender meggyullad. Bertalan láncot kovácsoltat " \
			+ "kötél helyett. Juss le a [b]70. emeletre[/b], és fizess [b]9000 tábori aranyat[/b] a láncra.",
		"reward": "a lift a 70. emeletre is levisz", "doing": "juss le a 70. emeletre",
		"doing_reached": "leértél: vigyél Bertalannak 9000 tábori aranyat", "done": "a lift a 70. emeletig jár"},
	"lift_80": {"name": "A kapu küszöbe",
		"text": "Az utolsó szakasz a nyolcvanadik emeletig, a Pokolkapu Őréig. Ennél lejjebb Bertalan nem épít. " \
			+ "Juss le a [b]80. emeletre[/b], és fizess [b]12000 tábori aranyat[/b].",
		"reward": "a lift a 80. emeletre is levisz", "doing": "juss le a 80. emeletre",
		"doing_reached": "leértél: vigyél Bertalannak 12000 tábori aranyat", "done": "a lift a 80. emeletig jár"},
}
## A mély aknák emeletei és áruk (tábori arany); a 80. alá nem visz lift.
const LIFT_FLOORS: Array[int] = [20, 30, 40, 50, 60, 70, 80]
const LIFT_PRICES := {20: 1500, 30: 2500, 40: 4000, 50: 5500, 60: 7000, 70: 9000, 80: 12000}
## Bertalan szavai fejezetenként: amikor elvállalod (%d: az ár), és amikor kifizeted.
const CHAPTERS := {
	20: ["Emlékszel, amit a huszadikról mondtam? Megvan a terv, megvan a kötél, csak a munkások hiányoznak. " \
			+ "Nem mernek lemenni oda, ahol Gáspár emberei elestek.\n\nMenj le előttük. Ha te leérsz a " \
			+ "huszadikig és élve visszajössz, ők is lemennek. Aztán kell még %d arany a csigákra.",
		"[i]A munkások éljeneznek, amikor meglátják a pénzt. Három nap kalapálás, és a lift lecsúszik a " \
			+ "huszadikig.[/i]\n\nTe vagy a legjobb reklám, amit egy lift kaphat. Mostantól a huszadik is a menüben van."],
	30: ["A harmincadikon a fal vörös, és megeszi a vasat. A kötélre réz kell, a rézhez pénz, a pénzhez... " \
			+ "na, tudod. Előbb nézd meg, merre fut az ér, aztán hozz %d aranyat.",
		"[i]Rézzel bevont kötél csillog a ketrec fölött.[/i]\n\nMegfogtuk a vérkövet! Na jó, csak kikerültük. " \
			+ "De a lift jár a harmincadikig."],
	40: ["A negyvenediken a kövek elmásznak, ha nem figyelsz oda. Horgony kell, ami a semmibe is " \
			+ "beleakad. Kitaláltam egyet. Te csak juss le, hogy lássam, hova kell verni. És %d arany.",
		"[i]Egy fura, csavart vasszerkezetet mutat, ami mintha egyszerre két helyen lenne.[/i]\n\n" \
			+ "Ne kérdezd, hogy működik. Működik. A negyvenedik a tiéd."],
	50: ["Félúton vagyunk! Az ötvenedik emeleten régi törpe csigasor van, azt mondják a térképek. Ha " \
			+ "megtalálod az utat, azt is felhasználom. Leérsz, hozol %d aranyat, és megyünk tovább.",
		"[i]Egy ősrégi, törpe rúnákkal teli csigát simogat.[/i]\n\nEzer éves, és jobb, mint bármi, amit én " \
			+ "valaha csináltam. Ne mondd el senkinek. Az ötvenedik nyitva."],
	60: ["A hatvanadikon dübörög az Ősgépezet. Tudod, mennyire szeretném látni? Ezer éve jár, és sosem " \
			+ "olajozta senki! Juss le, mondd el, milyen hangja van, és hozz %d aranyat.",
		"[i]Áhítattal hallgatja, ahogy leírod a gépezet dübörgését.[/i]\n\nTudtam! Ellensúly! Az egész ellensúlyon " \
			+ "jár! Na, ezt beépítettem. A hatvanadik a tiéd."],
	70: ["A hetvenediken ég a levegő. Szó szerint: a kender meggyullad. Láncot kovácsoltatok Ambrussal " \
			+ "kötél helyett. Előbb nézd meg, mennyire forró, aztán %d arany a láncra.",
		"[i]A ketrec fölött vastag, kormos lánc feszül.[/i]\n\nAmbrus három éjjel kalapálta. Azt mondja, ez a " \
			+ "legszebb lánc, amit valaha csinált, és ha elszakad, engem kovácsol bele a következőbe. A hetvenedik nyitva."],
	80: ["Az utolsó szakasz. A nyolcvanadik emelet, a Pokolkapu Őre. Ennél lejjebb nem viszem: ami a " \
			+ "kapu mögött van, ahhoz nem építek liftet. Juss le, és hozz %d aranyat. Ez lesz a mesterművem.",
		"[i]Bertalan sokáig nézi a ketrecet. Aztán leveszi a szemüvegét, és megtörli.[/i]\n\nNyolcvan emelet. " \
			+ "Húsz évig vigyáztam egy elszakadt kötélre, most meg az egész Mélység az enyém. Kész a lift. " \
			+ "A nyolcvanadik a tiéd.\n\nLejjebb? Oda nem. Oda gyalog mész, vagy sehogy."],
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


## A táborban: elöl a soron következő akna (elvállalás / állás / fizetés), aztán az új történetek, a régiek
## közül a még fel nem tettek, a végén a lift.
static func camp_options() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var next := next_floor()
	if next > 0:
		var quest := floor_quest(next)
		match Progress.npc_quest_state(quest):
			"":
				list.append({"id": quest, "text": "Mi lesz %s %d. emeleti aknával?" % [_article(next), next],
					"on_choose": func() -> String: return _give_floor(next)})
			"active":
				list.append({"id": quest + "_wait", "text": "Hogy áll %s %d. emeleti akna?" % [_article(next), next],
					"on_choose": func() -> String: return "[i]Rajzokat terít ki egy láda tetején.[/i]\n\n" \
						+ "Minden kész, csak téged várunk. Juss le egy futásban %s %d. emeletre, aztán gyere vissza." \
						% [_article(next), next]})
			"reached":
				list.append({"id": quest + "_pay", "text": "Leértem %s %d. emeletre. Itt a pénz (%d arany)." \
					% [_article(next), next, int(LIFT_PRICES[next])],
					"on_choose": func() -> String: return _pay_floor(next)})
	elif in_camp():
		list.append({"id": "deeper", "text": "Lejjebb nem viszed a liftet?",
			"on_choose": func() -> String: return "[i]Nagyon komolyan néz rád.[/i]\n\n" \
				+ "Nem. A kapu mögé nem építek. Van, ahová nem lift kell, hanem bátorság. Az meg nálad van, nem nálam."})
	list.append_array(CAMP_STORIES)
	var asked: Array = Progress.asked_topics(ID)
	for option in STORIES:
		if not asked.has(option["id"]):
			list.append(option)
	list.append({"id": "running", "text": "Működik a lift?",
		"on_choose": func() -> String: return "[i]Büszkén megpaskolja a rácsos fülkét.[/i]\n\n" \
			+ "Mint a svájci óra. Szállj be, és válaszd ki az emeletet. Én innen figyelem a kötelet."})
	return list


static func floor_quest(depth: int) -> String:
	return "lift_%d" % depth


## Levisz-e a lift erre az emeletre (1: mindig; 10: a javítás után; 20-80: a saját fejezetük után).
static func floor_open(depth: int) -> bool:
	if depth == 1:
		return true
	if depth == DEPTH:
		return repaired()
	return Progress.npc_quest_state(floor_quest(depth)) == "done"


## A soron következő mély akna (ha Bertalan már a táborban van, és van még nyitatlan), különben -1.
static func next_floor() -> int:
	if not in_camp():
		return -1
	for depth in LIFT_FLOORS:
		if Progress.npc_quest_state(floor_quest(depth)) != "done":
			return depth
	return -1


## A kazamatában (a Dungeon hívja): ha egy akna küldetése él, és leértél (legalább) arra az emeletre, teljesítetted.
static func note_depth(depth: int) -> void:
	if GameState.cheated:
		return
	for floor_depth in LIFT_FLOORS:
		var quest := floor_quest(floor_depth)
		if Progress.npc_quest_state(quest) == "active" and depth >= floor_depth:
			Progress.set_npc_quest(quest, "reached")
			Progress.save_game()


static func _article(depth: int) -> String:
	return "az" if depth == 50 else "a"


static func _give_floor(depth: int) -> String:
	Progress.set_npc_quest(floor_quest(depth), "active")
	Progress.save_game()
	return str(CHAPTERS[depth][0]) % int(LIFT_PRICES[depth])


static func _pay_floor(depth: int) -> String:
	var price := int(LIFT_PRICES[depth])
	if Progress.camp_gold < price:
		Audio.play("ui_error")
		return ("[i]Megszámolja a pénzt, aztán sajnálkozva visszaadja.[/i]\n\nEz nem %d arany. A kötél nem " % price) \
			+ "nyúlik a jó szándéktól. Gyere vissza, ha összejött (tábori aranyból)."
	Progress.camp_gold -= price
	Progress.set_npc_quest(floor_quest(depth), "done")
	Progress.change_trust(ID, 8)
	Progress.save_game()
	Audio.play("level_up")
	return str(CHAPTERS[depth][1]) \
		+ "\n\n[color=#7a4a10](-%d tábori arany. A lift mostantól %s %d. emeletre is levisz.)[/color]" % [price, _article(depth), depth]


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
