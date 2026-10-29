class_name King
## IV. Aurél király a királyi vár tróntermében (lásd Castle): a beszélgetése (DialoguePanel) és
## a küldetései (a J könyv "Király" fülén). Az első kihallgatáskor két küldetést ad (a hét király,
## a kincstár ajándéka); ha már találkoztál a tolvajjal, a tolvajról is kérdez: elárulhatod
## (jutalmat kapsz, de az őrök nem találják meg), vagy hallgathatsz (a tolvaj később meghálálja).
## A hét király után: új küldetés (a Káosz kapuja: a 40. emelet ura) és négy új történet (STORIES).

const ID := "king"
const NAME := "IV. Aurél király"
const SHEET: Texture2D = preload("res://assets/characters/king.png")
const FRAME := Vector2(16, 32)

const SEVEN_QUEST := "king_seven"
const TREASURY_QUEST := "king_treasury"
const THIEF_QUEST := "king_thief"
## A tolvaj sorsa (Progress.npc_quests): "betrayed" (elárultad) vagy "protected" (hallgattál).
const THIEF_FATE := "thief_fate"
## A hét király után: a 40. emelet ura (Ürességfaló, a Káosz Ura) tartja nyitva a Mélység kapuját.
const CHAOS_QUEST := "king_chaos"
## A Káosz Ura után a király szála a 100. emeletig (lásd a QUESTS végét): a jég alatti gépezet (60.), a pokol
## kapuja (80.), aztán a Démonkirály (Azazel, a 100. emelet kapuja mögött, lásd Hell). Közben kiderül az
## Aurél-ház titka: az alapító király alkuja a mélységgel, és az, hogy mi volt a harminc ember ára.
const ENGINE_QUEST := "king_engine"
const GATE_QUEST := "king_gate"
const LUCIFER_QUEST := "king_lucifer"
const TREASURY_GOLD := 1000
const BETRAY_GOLD := 120
const CHAOS_GOLD := 3000
const ENGINE_GOLD := 5000
const GATE_GOLD := 8000
const LUCIFER_GOLD := 20000
## A végén a király leveszi a gyűrűjét, és neked adja (egyedi talizmán, lásd Items).
const RING_ID := "trinket_thirty_names"

## A király küldetései (az engedély a vár kapujánál indul, lásd Castle).
const QUESTS := {
	Castle.PERMIT_QUEST: {"name": "Királyi engedély",
		"text": "A királyi vár kapujában álló őrök csak engedéllyel engednek be, vagy olyan kalandort, "
			+ "aki [b]elérte a Mélység 30. szintjét, és vissza is jött[/b]. Juss le a 30. emeletre, "
			+ "aztán térj vissza a táborba.",
		"reward": "belépés a királyi várba", "doing": "juss le a 30. emeletre, és gyere vissza",
		"done": "az őrök beengednek"},
	SEVEN_QUEST: {"name": "A hét király",
		"text": "A Mélység emeleteit hét szörnykirály uralja: az Ogrekirály, az Orkhadúr, a Gyíkkirály, "
			+ "a Démonúr, a Nekromanta-főpap, a Jégóriás és a Zombikirály. [b]Győzd le mind a hetet[/b] "
			+ "(mindegyiket legalább egyszer), aztán jelentsd a királynak.",
		"reward": "egy legendás tárgy a királyi kincstárból", "doing": "győzd le mind a hét szörnykirályt",
		"done": "a hét király elesett"},
	TREASURY_QUEST: {"name": "A kincstár ajándéka",
		"text": "A királyi kincstár üres, mióta a király a Mélységbe küldte a seregét. Vigyél a "
			+ "királynak egy [b]legendás tárgyat[/b] (bármilyet, a táskádból).",
		"reward": "%d tábori arany" % TREASURY_GOLD, "doing": "vigyél egy legendás tárgyat a királynak",
		"done": "a kincstár gyarapodott"},
	THIEF_QUEST: {"name": "Árnyék a városban",
		"text": "Valaki fosztogatja a városi urakat, a polgármestert, sőt a kocsmárost is. A király "
			+ "tudni akarja, ki az, és hol rejtőzik. Te tudod. Elárulod neki, vagy hallgatsz?",
		"reward": "%d tábori arany (ha elárulod)" % BETRAY_GOLD, "doing": "döntsd el, mit mondasz a királynak",
		"done": "döntöttél"},
	CHAOS_QUEST: {"name": "A Káosz kapuja",
		"text": "A hét szörnykirály elesett, de a Mélység kapuja nem bezárult, hanem kinyílt. A legalján, "
			+ "a [b]40. emeleten[/b] Ürességfaló, a Káosz Ura ül a kapuban, és nyitva tartja. "
			+ "[b]Győzd le[/b], aztán jelentsd a királynak.",
		"reward": "%d tábori arany" % CHAOS_GOLD, "doing": "győzd le a Káosz Urát a 40. emeleten",
		"done": "a kapu bezárult"},
	ENGINE_QUEST: {"name": "Dübörgés a jég alatt",
		"text": "A Káosz kapuja bezárult, de a város alatt éjjelente újra dübörög a föld, egyenletesen, mint "
			+ "egy óramű. A király ősi feljegyzései szerint az alapító király, I. Aurél mesterei egy gépet "
			+ "építettek, ami aranyért ásott lefelé, és sosem állították le. A [b]60. emeleten[/b], a jég alatt "
			+ "jár még ma is. [b]Állítsd le az Ősgépezetet[/b], aztán jelentsd a királynak.",
		"reward": "%d tábori arany" % ENGINE_GOLD, "doing": "állítsd le az Ősgépezetet a 60. emeleten",
		"done": "a gépezet elnémult"},
	GATE_QUEST: {"name": "Az alapító titka",
		"text": "Az Ősgépezet belsejében talált pecsétes tekercs I. Aurél saját kezével írt egyezsége: "
			+ "\"aranyat a mélységből, szabad utat a mélységnek\". A tekercs szerint a [b]80. emeleten[/b] egy "
			+ "háromfejű őr vigyázza az utat lefelé, a pokol felé. [b]Győzd le a Pokolkapu Őrét[/b], aztán "
			+ "jelentsd a királynak.",
		"reward": "%d tábori arany" % GATE_GOLD, "doing": "győzd le a Pokolkapu Őrét a 80. emeleten",
		"done": "az őr elesett"},
	LUCIFER_QUEST: {"name": "A harminc név ára",
		"text": "A király bevallotta: a jóslat, ami miatt Gáspár harminc emberét a Mélységbe küldte, az "
			+ "alapító egyezségének része volt, és a harminc ember volt a nemzedékenkénti ár. Az egyezséget csak "
			+ "az törheti meg, aki legyőzi azt, akivel kötötték. A [b]100. emeleten[/b] a vörös kapu mögött "
			+ "[b]Azazel, a Halálangyal és Démonkirály[/b] vár. Győzd le, és térj vissza a királyhoz.",
		"reward": "%d tábori arany és a király gyűrűje" % LUCIFER_GOLD, "doing": "győzd le Azazelt a 100. emelet kapuja mögött",
		"done": "az egyezség megtört"},
}

## A király szálának új kérdései: a gépezet után az alapítóról, a kapuőr után a szégyenről,
## a Démonkirály után az epilógus (mi lesz most).
const ENGINE_STORIES: Array[Dictionary] = [
	{"id": "founder", "text": "Ki volt I. Aurél?", "trust": 3,
		"answer": "[i]A király a trónterem végében álló, megfakult festményre néz: szigorú arcú, aranyláncos " \
			+ "férfi, a háttérben egy bányatorony.[/i]\n\n" \
			+ "Az Aranykezű. Így hívták a krónikák. Négyszáz éve ez a völgy egy szegény bányászfalu volt. Ő " \
			+ "talált aranyat a hegy alatt, és húsz év alatt királyságot épített rá.\n\n" \
			+ "Gyerekkoromban büszke voltam rá. Minden évben az ő szobra előtt ünnepeltük a korona napját.\n\n" \
			+ "[i]Elfordul a képtől.[/i]\n\nMost már tudom, honnan volt az a sok arany. És hogy nem ő fizette meg az árát."},
]
const GATE_STORIES: Array[Dictionary] = [
	{"id": "shame", "text": "Tudtad, felség, mit tesz a jóslat?", "trust": 2,
		"answer": "[i]Sokáig nem felel. Amikor megszólal, nem néz rád.[/i]\n\n" \
			+ "Nem. Esküszöm a harminc névre, hogy nem tudtam. A jóslatot apámtól kaptam, ő az apjától. Egy " \
			+ "lezárt ládában volt, amit csak a király nyithat ki, amikor megremeg a föld.\n\n" \
			+ "Azt írta: \"küldj le harminc pajzsot, és a sötétség visszahúzódik\". Elküldtem őket. És a " \
			+ "sötétség tényleg visszahúzódott tizenkét évre. Azt hittem, ez a jóslat igazsága.\n\n" \
			+ "[i]A keze ökölbe szorul a karfán.[/i]\n\nPedig csak kifizettem egy számlát, amit négyszáz éve nyitott " \
			+ "valaki a nevemben."},
]
const EPILOGUE: Array[Dictionary] = [
	{"id": "kingdom", "text": "Mi lesz most a királysággal?", "trust": 3,
		"answer": "[i]A király kitárja a trónterem ablakát. Lentről zene hallatszik: a piactéren ünnepelnek.[/i]\n\n" \
			+ "A hegy alatti arany elfogy, a tudósaim szerint az egyezséggel együtt. Szegényebbek leszünk. " \
			+ "Talán olyan szegények, mint a falu volt négyszáz éve.\n\n" \
			+ "De a mi aranyunk lesz. A miénk, és senki nem jön érte a mélyből.\n\n" \
			+ "[i]Elmosolyodik, most először, amióta ismered.[/i]\n\nAz Aranykezű szobrát holnap ledöntik. " \
			+ "A helyére harminc kőtáblát állíttatok, a harminc névvel."},
	{"id": "gaspar", "text": "Elmondod Gáspárnak az igazat?", "trust": 4,
		"answer": "Már elmondtam. Tegnap este eljött a várba, és én mindent elmondtam neki. A jóslatot, a " \
			+ "ládát, az alkut. Azt is, hogy az emberei nem a kincsért haltak meg, hanem egy halott király " \
			+ "adósságáért.\n\n" \
			+ "[i]Megérinti az arcát, ahol egy friss, sötét folt látszik.[/i]\n\n" \
			+ "Megütött. Megérdemeltem. Aztán leült velem szemben, és hajnalig sorolta a neveket, egyenként. " \
			+ "Mindegyikhez elmondott valamit, amit én nem tudtam.\n\n" \
			+ "Azt hiszem, soha nem bocsát meg. De hajnalban, amikor elment, azt mondta: \"felség\". " \
			+ "Tizenkét éve nem szólított így."},
	{"id": "archive", "text": "Mi lett az alapító tekercsével?", "trust": 2,
		"answer": "[i]A kandallóra mutat. A hamuban még kivehető egy megpörkölődött pecsét.[/i]\n\n" \
			+ "Elégettem. A tudósaim könyörögtek, hogy őrizzem meg, a történelemnek. Azt mondtam nekik, a " \
			+ "történelem majd emlékszik rá enélkül is.\n\n" \
			+ "A lezárt ládát is szétvertem, amiben a jóslat volt. A fiam, ha egyszer király lesz, nem fog " \
			+ "találni benne semmit, csak egy levelet tőlem. Arról, hogy mi az ára az ingyen aranynak."},
]

## A hét király után: négy új történet (a régi kérdés is marad; a beszélgetés lapozható).
const STORIES: Array[Dictionary] = [
	{"id": "truth", "text": "Miért küldted le valójában Gáspárt?", "trust": 4,
		"answer": "[i]A király int az őröknek, hogy hagyjanak magatokra. Megvárja, amíg becsukódik mögöttük " \
			+ "az ajtó.[/i]\n\n" \
			+ "Nem a kincsért. Azt a nép kedvéért mondtam, és Gáspárnak is. Egy régi jóslatért senki sem megy " \
			+ "le meghalni.\n\n" \
			+ "Tizenkét éve megremegett a föld a város alatt. Kiszáradtak a kutak, a hegyben beomlott a bánya. " \
			+ "A régi írások szerint ez az első jel: a hét őr megerősödött, és a sötétség elindult felfelé. " \
			+ "Tudtam, hogy ha nem teszek semmit, tíz év múlva a piactéren tör fel.\n\n" \
			+ "Harminc embert küldtem le egy hazugsággal. Hármat kaptam vissza.\n\n" \
			+ "[i]Rád néz.[/i]\n\nGáspár ma is azt hiszi, a kincsért mentek le. Ha egyszer elmondod neki az " \
			+ "igazat, nem foglak megállítani. Megérdemli."},
	{"id": "mine", "text": "Mi történt a hegyi ezüstbányával?", "trust": 3,
		"answer": "[i]A király a gyűrűjét forgatja.[/i]\n\n" \
			+ "A korona ezüstje mindig a hegyből jött. Apám idejében száz bányász dolgozott a tárnákban, és a " \
			+ "kincstárban nem fért el a sok láda.\n\n" \
			+ "Aztán a legmélyebb tárnában kopogást hallottak. A kő túloldaláról, lassan, egyenletesen. Azt " \
			+ "hitték, egy másik csapat bont feléjük. Nem volt másik csapat.\n\n" \
			+ "Egy hét múlva összeomlott az egész. Huszonhét ember maradt bent, és azóta senki sem dolgozik ott.\n\n" \
			+ "[i]Elhalkul a hangja.[/i]\n\nHa arra jársz, ne menj be. Néha azt gondolom, nem a bányászok " \
			+ "találták meg a Mélységet. A Mélység talált rá a bányára."},
	{"id": "knights", "text": "Kik az elesett lovagok odalent?", "trust": 4,
		"answer": "[i]A király keze megfeszül a trón karfáján.[/i]\n\n" \
			+ "Láttad őket, ugye? A páncéljukon még ott a címerem. A hírnökeim mondták először, és nem hittem " \
			+ "nekik. Aztán valaki felhozta az egyikük pajzsát.\n\n" \
			+ "Kristóf pajzsa volt, a legfiatalabbé. Én adtam a kezébe a kapuban, és megígértem az anyjának, " \
			+ "hogy hazajön.\n\n" \
			+ "A Mélység nem engedi el a halottait. Felöltözteti őket, és ellenünk küldi.\n\n" \
			+ "[i]A hangja most először remeg meg.[/i]\n\nHa odalent találkozol velük, ne habozz. Már nem ők " \
			+ "azok. Adj nekik nyugalmat helyettem."},
	{"id": "ring", "text": "Mit jelent a gyűrű, amit mindig forgatsz?", "trust": 5,
		"answer": "[i]Leveszi az ujjáról, és feléd nyújtja. Vastag, kopott aranygyűrű, a belsejébe apró " \
			+ "betűkkel nevek vannak vésve.[/i]\n\n" \
			+ "Harminc név. Az indulásuk előtti éjjel véstem bele mindet, a saját kezemmel. Minden reggel " \
			+ "végigolvasom őket, mielőtt bárkivel szólnék.\n\n" \
			+ "[i]Megmutatja: a nevek többsége mellett egy apró kereszt.[/i]\n\n" \
			+ "Huszonhét kereszt. Benedek, a zászlóvivő. Kristóf, a legfiatalabb. Ambrus, aki lovagolni " \
			+ "tanított, amikor még herceg voltam. Mindegyikről tudnék mesélni egy estén át.\n\n" \
			+ "[i]Visszahúzza az ujjára.[/i]\n\nAmikor a hét király elesett, azt hittem, végre leveszem. Nem " \
			+ "ment. Talán majd ha a kapu is bezárul."},
]

const FIRST_GREETING := "[i]A trónterem végében, a magas, aranyozott trónon egy ősz hajú, koronás " \
	+ "férfi ül. Fáradtnak tűnik, de a tekintete éles.[/i]\n\n" \
	+ "Tehát te vagy az, aki lement a harmincadik szintre, és vissza is jött. Lépj közelebb, kalandor. " \
	+ "Régóta várok valakire, mint te."
const GREETING := "[i]A király biccent, amikor belépsz.[/i]\n\nÜdv újra, kalandor. Mi járatban?"
const INTRO := "[i]Hosszan hallgat, a gyűrűjét forgatja.[/i]\n\n" \
	+ "Tizenkét éve a Mélységbe küldtem a legjobb embereimet. Harminc pajzsot, Gáspár kapitány vezetésével. " \
	+ "Kincset és válaszokat ígértek a régi írások. Hárman jöttek vissza. Azóta minden éjjel hallom a " \
	+ "nevüket.\n\n" \
	+ "A Mélység nem egyetlen szörnyé. Az emeleteit [b]hét szörnykirály[/b] uralja, és amíg ők élnek, " \
	+ "a sötétség egyre feljebb kúszik. Győzd le mind a hetet, és a korona nem marad hálátlan.\n\n" \
	+ "[i]Körbemutat a csupasz falakon, ahol egykor festmények és kárpitok lógtak.[/i]\n\n" \
	+ "És ahogy látod, a kincstár is kiürült. Ha a mélyben [b]legendás tárgyat[/b] találsz, hozd el nekem. " \
	+ "Busásan megfizetem."
const THIEF_ASK := "\n\n[i]Közelebb hajol, és lehalkítja a hangját.[/i]\n\n" \
	+ "Még valami. Valaki fosztogatja a városi urakat. A polgármester órája, a nemesek gyűrűi, sőt a " \
	+ "kocsmáros bora is eltűnt. Azt beszélik, a sáros ösvény környékén látták egy kendős alakot. " \
	+ "[b]Tudsz róla valamit?[/b]"
const DEEP_STORY := "[i]A király a trón karfáját szorítja.[/i]\n\n" \
	+ "Azt mondják, a Mélység alja egy kapu. Hogy hová vezet, azt senki sem tudja; aki látta, nem jött " \
	+ "vissza. A régi írások szerint a hét szörnykirály ennek a kapunak az őrei. Ha elesnek, a kapu " \
	+ "megnyílik... vagy bezárul. Ezt még a tudósaim sem tudják eldönteni."


static func greeting() -> String:
	return FIRST_GREETING if Progress.npc_quest_state(SEVEN_QUEST) == "" else GREETING


static func met_thief() -> bool:
	return Progress.npc_quest_state(Thief.GOLD_QUEST) != ""


static func options(inventory: Inventory) -> Array[Dictionary]:
	# Lőrinc aranypecsétes levele (az első kihallgatáskor is átadható).
	var letter: Array[Dictionary] = []
	if Progress.npc_quest_state(Stranger.ROYAL_LETTER_QUEST) == "active" and Stranger.has_royal_letter(inventory):
		letter.append({"id": "royal_letter", "text": "Levelet hoztam Lőrinctől, felség.",
			"on_choose": func() -> String: return _royal_letter(inventory)})
	if Progress.npc_quest_state(SEVEN_QUEST) == "":
		var first: Array[Dictionary] = [{"id": "why", "text": "Felség, miért hívatott?",
			"on_choose": func() -> String: return _intro()}]
		return first + letter
	# Elöl a küldetések (jelentés / átadás / új feladat), utána a kérdések, a hét király után a négy új történet.
	var list: Array[Dictionary] = []
	list.append_array(letter)
	match Progress.npc_quest_state(SEVEN_QUEST):
		"active":
			list.append({"id": "seven", "text": "Legyőztem a hét szörnykirályt.",
				"on_choose": func() -> String: return _report_seven()})
		"done":
			match Progress.npc_quest_state(CHAOS_QUEST):
				"":
					list.append({"id": "next", "text": "Mi lesz most, felség?",
						"on_choose": func() -> String: return _give_chaos_quest()})
				"active":
					list.append({"id": "chaos", "text": "Legyőztem a Káosz Urát.",
						"on_choose": func() -> String: return _report_chaos()})
				"done":
					list.append_array(_deep_quest_options())
	if Progress.npc_quest_state(TREASURY_QUEST) == "active":
		list.append({"id": "treasury", "text": "Hoztam legendás tárgyat.",
			"on_choose": func() -> String: return _give_legendary(inventory)})
	match Progress.npc_quest_state(THIEF_QUEST):
		"":
			if met_thief():
				list.append({"id": "more", "text": "Van még valami, felség?",
					"on_choose": func() -> String: return _ask_thief("")})
		"active":
			list.append({"id": "betray", "text": "Tudom, hol rejtőzik a tolvaj.",
				"on_choose": func() -> String: return _betray()})
			list.append({"id": "protect", "text": "Nem tudok róla semmit, felség.",
				"on_choose": func() -> String: return _protect()})
	list.append({"id": "deep", "text": "Mi van a Mélység alján?", "answer": DEEP_STORY})
	if Progress.npc_quest_state(SEVEN_QUEST) == "done":
		list.append_array(STORIES)
	if Progress.npc_quest_state(ENGINE_QUEST) == "done":
		list.append_array(ENGINE_STORIES)
	if Progress.npc_quest_state(GATE_QUEST) == "done":
		list.append_array(GATE_STORIES)
	if Progress.npc_quest_state(LUCIFER_QUEST) == "done":
		for i in range(list.size() - 1, -1, -1):
			if list[i]["id"] == "deep":
				list.remove_at(i)
		list.append_array(EPILOGUE)
	return list


## A Káosz Ura utáni fejezetek: mindig a soron következő feladat (megkapás / jelentés).
static func _deep_quest_options() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	match Progress.npc_quest_state(ENGINE_QUEST):
		"":
			list.append({"id": "rumble", "text": "Elcsendesedett végre a föld, felség?",
				"on_choose": func() -> String: return _give_engine_quest()})
			return list
		"active":
			list.append({"id": "engine", "text": "Leállítottam az Ősgépezetet.",
				"on_choose": func() -> String: return _report_engine()})
			return list
	match Progress.npc_quest_state(GATE_QUEST):
		"":
			list.append({"id": "scroll", "text": "Mit írt az alapító a tekercsben?",
				"on_choose": func() -> String: return _give_gate_quest()})
			return list
		"active":
			list.append({"id": "gate", "text": "Legyőztem a Pokolkapu Őrét.",
				"on_choose": func() -> String: return _report_gate()})
			return list
	match Progress.npc_quest_state(LUCIFER_QUEST):
		"":
			list.append({"id": "price", "text": "Mi van a kapu túloldalán, felség?",
				"on_choose": func() -> String: return _give_lucifer_quest()})
		"active":
			list.append({"id": "lucifer", "text": "Azazel elesett, felség.",
				"on_choose": func() -> String: return _report_lucifer()})
	return list


static func _give_engine_quest() -> String:
	Progress.set_npc_quest(ENGINE_QUEST, "active")
	Progress.mark_asked(ID, "rumble")
	Progress.save_game()
	Audio.play("ui_open")
	return "[i]A király a gyűrűjét forgatja. Újra az ujján van.[/i]\n\n" \
		+ "Három éjszakát aludtam végig. A negyediken megint felébredtem. Nem remegés volt, mint régen. " \
		+ "Dübörgés. Egyenletes, mint egy óramű, mélyről, valahonnan a jég alól.\n\n" \
		+ "Lementem a kincstár alatti levéltárba, ahová apám óta senki nem tette be a lábát. Az alapító, " \
		+ "[b]I. Aurél[/b] mesterei négyszáz éve egy gépet építettek. Aranyért ásott lefelé, gőzzel és " \
		+ "fogaskerekekkel, és a feljegyzések szerint [b]soha nem állították le[/b]. Egyszerűen otthagyták " \
		+ "dolgozni a mélyben.\n\n" \
		+ "[i]Egy megsárgult rajzot terít ki eléd: kéményes, lépegető sárgaréz szörnyeteg.[/i]\n\n" \
		+ "A tudósaim szerint a [b]hatvanadik emeleten[/b] jár, a jég alatt, és minden lépésével közelebb " \
		+ "ássa magát hozzánk. Ősgépezetnek hívják. [b]Állítsd le.[/b]\n\n" \
		+ "[color=#7a4a10](Új küldetés a J könyvben, a Király fülön.)[/color]"


static func _report_engine() -> String:
	if Bestiary.kills(Bestiary.ENGINE) <= 0:
		Audio.play("ui_error")
		return "[i]A király a padlóra mutat.[/i]\n\nHallgasd. Ott van, a talpad alatt. Dübörög. " \
			+ "Az Ősgépezet még jár, a hatvanadik emeleten."
	Progress.set_npc_quest(ENGINE_QUEST, "done")
	Progress.mark_asked(ID, "engine")
	Progress.change_trust(ID, 20)
	Progress.camp_gold += ENGINE_GOLD
	Progress.save_game()
	Audio.play("level_up")
	return "[i]Elmondod, mit láttál: a gőzt, a fogaskerekeket, a villámokat. És azt, hogy amikor a gép " \
		+ "végre leállt, a mellkasa kinyílt, és egy ólomtokot találtál benne, Aurél-pecséttel.[/i]\n\n" \
		+ "[i]A király remegő kézzel töri fel a pecsétet. A tokban egy tekercs.[/i]\n\n" \
		+ "Ez... ez az alapító keze írása. Ismerem, minden oklevelünk alján ott van.\n\n" \
		+ "[i]Olvasni kezd, aztán elsápad, és összetekeri.[/i]\n\nKöszönöm, kalandor. A korona fizet. A " \
		+ "tekercsről... arról majd beszélünk. Adj egy éjszakát.\n\n" \
		+ "[color=#7a4a10](+%d tábori arany)[/color]" % ENGINE_GOLD


static func _give_gate_quest() -> String:
	Progress.set_npc_quest(GATE_QUEST, "active")
	Progress.mark_asked(ID, "scroll")
	Progress.save_game()
	Audio.play("ui_open")
	return "[i]A király szeme alatt sötét karikák. A tekercs a térdén fekszik.[/i]\n\n" \
		+ "Nem aludtam. Felolvasom, mert neked is tudnod kell.\n\n" \
		+ "[i]„Én, Aurél, a hegy alatti falu bányamestere, egyezséget kötök a mélység Urával. Ő aranyat ad " \
		+ "nekem és a házamnak, amíg a házam áll. Cserébe szabad utat kap: minden emelet, amit kiásunk, " \
		+ "az övé. És amikor a föld megremeg, a házam fizet.”[/i]\n\n" \
		+ "Négyszáz év aranya. Minden korona, minden kárpit, minden ünnep ebből van.\n\n" \
		+ "[i]Ujja egy rajzon áll meg a tekercs alján: háromfejű kutya, láncon.[/i]\n\n" \
		+ "A mélység Ura őrt állított az út végére, hogy senki ne mehessen le hozzá egyezség nélkül. A " \
		+ "[b]nyolcvanadik emeleten[/b] vár, a Fagykő legalján. A Pokolkapu Őre. Ha él, a mélység Urához " \
		+ "senki sem jut el.\n\n" \
		+ "[i]Feláll.[/i]\n\nÉn akarom tudni, mi van ott lent. Ha te is, [b]győzd le az őrt[/b].\n\n" \
		+ "[color=#7a4a10](Új küldetés a J könyvben, a Király fülön.)[/color]"


static func _report_gate() -> String:
	if Bestiary.kills(Bestiary.GATE) <= 0:
		Audio.play("ui_error")
		return "[i]A király a fejét rázza.[/i]\n\nA tudósaim éjjelente hallják a vonyítást a kutakból. " \
			+ "A háromfejű őr él, a nyolcvanadik emeleten."
	Progress.set_npc_quest(GATE_QUEST, "done")
	Progress.mark_asked(ID, "gate")
	Progress.change_trust(ID, 20)
	Progress.camp_gold += GATE_GOLD
	Progress.save_game()
	Audio.play("level_up")
	return "[i]A király a tekercset szorongatja, mintha attól félne, hogy kiesik a kezéből.[/i]\n\n" \
		+ "Az őr elesett. Akkor az út szabad. A tudósaim szerint a legalján, a [b]századik emeleten[/b] " \
		+ "egy kapu áll, ami nem a Mélységbe vezet, hanem azon túl.\n\n" \
		+ "Vedd el ezt. És gyere vissza holnap. Van még valami, amit el kell mondanom. Valami, amit " \
		+ "tizenkét éve kellett volna valakinek elmondanom.\n\n" \
		+ "[color=#7a4a10](+%d tábori arany)[/color]" % GATE_GOLD


static func _give_lucifer_quest() -> String:
	Progress.set_npc_quest(LUCIFER_QUEST, "active")
	Progress.mark_asked(ID, "price")
	Progress.change_trust(ID, 10)
	Progress.save_game()
	Audio.play("ui_open")
	return "[i]A király egyedül vár a trónteremben. Az őröket elküldte, a fáklyák fele kialudt. Leveszi a " \
		+ "gyűrűt, és a tenyerén tartja feléd.[/i]\n\n" \
		+ "Emlékszel a jóslatra, ami miatt Gáspárt leküldtem? \"Küldj le harminc pajzsot, és a sötétség " \
		+ "visszahúzódik.\" Egy lezárt ládában volt, amit csak a király nyithat ki.\n\n" \
		+ "Az alapító írta. Ugyanazzal a kézzel, mint az egyezséget. [b]A harminc ember volt az ár.[/b] Az, " \
		+ "amit a házam fizet, amikor a föld megremeg. Nem jóslat volt, hanem egy számla. És én kifizettem, " \
		+ "anélkül, hogy tudtam volna.\n\n" \
		+ "[i]A hangja elcsuklik.[/i]\n\nBenedek. Kristóf. Ambrus. Huszonhét név. Az én nevemben haltak meg.\n\n" \
		+ "[i]Aztán összeszedi magát, és újra király.[/i]\n\nA tekercs szerint az egyezséget csak az törheti " \
		+ "meg, aki legyőzi azt, akivel kötötték. A századik emelet kapuja mögött ül. A neve [b]Azazel, a " \
		+ "Halálangyal és Démonkirály[/b].\n\nNem kérhetem, hogy menj le érte. Harminc embert már leküldtem. De ha mégis " \
		+ "megteszed... a házam soha többé nem fizet. És senki más sem.\n\n" \
		+ "[color=#7a4a10](Új küldetés a J könyvben, a Király fülön.)[/color]"


static func _report_lucifer() -> String:
	if Bestiary.kills(Bestiary.LUCIFER) <= 0:
		Audio.play("ui_error")
		return "[i]A király a gyűrűjét forgatja.[/i]\n\nAz arany még ott van a hegy alatt, kalandor. " \
			+ "Amíg ott van, az egyezség áll. Azazel él."
	# Előbb a gyűrű (az add_to_stash újratölti a mentést, ami az utána jövő változásokat nem érinti).
	Progress.add_to_stash(Items.mark_story(Items.create(RING_ID)))
	Progress.set_npc_quest(LUCIFER_QUEST, "done")
	Progress.mark_asked(ID, "lucifer")
	Progress.change_trust(ID, 40)
	Progress.camp_gold += LUCIFER_GOLD
	Progress.save_game()
	Audio.play("level_up")
	return "[i]Ahogy belépsz, a trónterem megtelik emberekkel. Ott van Gáspár, Bence, Lőrinc, Vendel, a " \
		+ "doktor, Rozi, a kocsmáros, a bányászok. Senki nem szól. A király lejön a trónról, és megáll " \
		+ "előtted.[/i]\n\n" \
		+ "Reggel a bányászok jöttek a várba. Azt mondták, a hegy alatti arany fekete kővé vált, egyetlen " \
		+ "éjszaka alatt. Négyszáz év aranya.\n\n" \
		+ "[i]Mosolyog.[/i]\n\nSoha nem örültem még ennyire szegénységnek. Az egyezség megtört.\n\n" \
		+ "[i]Leveszi az ujjáról a kopott aranygyűrűt. Ezúttal könnyen jön le. A huszonhét kereszt mellé " \
		+ "egy új név van vésve: a tiéd, kereszt nélkül.[/i]\n\n" \
		+ "Ezt tizenkét évig hordtam, hogy ne felejtsem el, mit tettem. Most a tiéd, hogy ne felejtsd el, " \
		+ "mit tettél te. Harminc név, és még egy, aki hazajött.\n\n" \
		+ "[i]A teremben valaki tapsolni kezd. Aztán mindenki.[/i]\n\n" \
		+ "[color=#7a4a10](+%d tábori arany. A harminc név gyűrűje a tábori ládába került.)[/color]" % LUCIFER_GOLD


static func _royal_letter(inventory: Inventory) -> String:
	var answer := Stranger.deliver_to_king(inventory)
	if answer.is_empty():
		Audio.play("ui_error")
		return "Levél? Nem látok nálad levelet, kalandor. (A táskádban legyen.)"
	Progress.mark_asked(ID, "royal_letter")
	return answer


static func _intro() -> String:
	Progress.mark_asked(ID, "why")
	Progress.change_trust(ID, 5)
	Progress.set_npc_quest(SEVEN_QUEST, "active")
	Progress.set_npc_quest(TREASURY_QUEST, "active")
	if met_thief():
		return _ask_thief(INTRO)
	return INTRO


static func _ask_thief(before: String) -> String:
	Progress.set_npc_quest(THIEF_QUEST, "active")
	if before.is_empty():
		return "[i]A király elgondolkodik.[/i]" + THIEF_ASK
	return before + THIEF_ASK


## A hét szörnykirály közül, akit még nem győztél le (a Szörnyek könyve szerint).
static func missing_kings() -> Array[String]:
	var missing: Array[String] = []
	for boss: String in Bestiary.KINGS:
		if boss != "Vérfarkas, a Mélység Ura" and Bestiary.kills(boss) <= 0:
			missing.append(boss)
	return missing


static func _report_seven() -> String:
	var missing := missing_kings()
	if not missing.is_empty():
		Audio.play("ui_error")
		return "[i]A király felvonja a szemöldökét.[/i]\n\nA hírnökeim mást mondanak. Még élnek: [b]%s[/b]. " \
			% ", ".join(missing) + "Gyere vissza, ha mind a hét elesett."
	var item := Items.mark_story(Items.random_item("legendary", "legendary"))
	Progress.add_to_stash(item)
	Progress.set_npc_quest(SEVEN_QUEST, "done")
	Progress.mark_asked(ID, "seven")
	Progress.change_trust(ID, 25)
	Progress.save_game()
	Audio.play("level_up")
	return "[i]A király feláll a trónról. A teremben hirtelen csend lesz.[/i]\n\n" \
		+ "Mind a hét... Tizenkét éve erre várok. Gáspár emberei nem haltak meg hiába.\n\n" \
		+ "[i]Int az egyik őrnek, aki egy bársonypárnán hoz valamit.[/i]\n\n" \
		+ "Fogadd el ezt a királyi kincstárból: [b]%s[/b]. Megérdemled.\n\n" % item["name"] \
		+ "[color=#7a4a10](A tárgy a tábori ládába került.)[/color]"


## A hét király után: a kapu kinyílt, a Káosz Ura tartja nyitva (új küldetés).
static func _give_chaos_quest() -> String:
	Progress.set_npc_quest(CHAOS_QUEST, "active")
	Progress.mark_asked(ID, "next")
	Progress.save_game()
	Audio.play("ui_open")
	return "[i]A király az ablakhoz lép, és sokáig nézi a várost.[/i]\n\n" \
		+ "Azt hittem, ezzel vége. Hogy ha a hét őr elesik, a kapu bezárul, és a sötétség visszahúzódik.\n\n" \
		+ "Tévedtem. A tudósaim az éjjel felébresztettek: a kapu nem bezárult, hanem [b]kinyílt[/b]. Az őrök " \
		+ "nemcsak a sötétséget hozták fel. Valamit odalent is tartottak.\n\n" \
		+ "A legmélyebb szintekről fekete-lila, alaktalan dolgok törnek fel; a kalandorok Káoszivadéknak " \
		+ "hívják őket. A Mélység legalján, a [b]negyvenedik emeleten[/b] pedig valami a kapuban ül, és nyitva " \
		+ "tartja. A régi írások [b]Ürességfalónak[/b] nevezik. A Káosz Urának.\n\n" \
		+ "[i]Feléd fordul.[/i]\n\nEgyszer már Gáspárt is erre kértem, és harmincból hárman jöttek vissza. " \
		+ "Most téged kérlek. Győzd le, és a kapu bezárul. Örökre.\n\n" \
		+ "[color=#7a4a10](Új küldetés a J könyvben, a Király fülön.)[/color]"


static func _report_chaos() -> String:
	if Bestiary.kills(Bestiary.CHAOS_LORD) <= 0:
		Audio.play("ui_error")
		return "[i]A király megrázza a fejét.[/i]\n\nA föld még mindig remeg a város alatt, kalandor. " \
			+ "Ürességfaló él. A negyvenedik emeleten vár rád."
	Progress.set_npc_quest(CHAOS_QUEST, "done")
	Progress.mark_asked(ID, "chaos")
	Progress.change_trust(ID, 30)
	Progress.camp_gold += CHAOS_GOLD
	Progress.save_game()
	Audio.play("level_up")
	return "[i]Mielőtt megszólalhatnál, a király feláll. Az ajtónál álló őrök kihúzzák magukat, mintha " \
		+ "díszőrséget állnának.[/i]\n\n" \
		+ "Tudom. Az éjjel elcsendesedett a föld. Tizenkét év óta először végigaludtam egy éjszakát.\n\n" \
		+ "[i]Leveszi az ujjáról a kopott aranygyűrűt, sokáig nézi, aztán a trón karfájára teszi.[/i]\n\n" \
		+ "A kapu bezárult. Harminc ember indult el, hogy ezt megtegye, és végül egyetlen kalandor fejezte be " \
		+ "helyettük. Az ő nevüket nem felejtem el. A tiédet sem.\n\n" \
		+ "Fogadd el ezt a korona hálájaként.\n\n" \
		+ "[color=#7a4a10](+%d tábori arany)[/color]" % CHAOS_GOLD


## Legendás tárgy a táskából a kincstárnak: tábori arany a jutalom.
static func _give_legendary(inventory: Inventory) -> String:
	for i in inventory.bag.size():
		var item: Variant = inventory.bag[i]
		if item is Dictionary and item.get("rarity", "") == "legendary":
			inventory.take_from_bag(i)
			Progress.camp_gold += TREASURY_GOLD
			Progress.set_npc_quest(TREASURY_QUEST, "done")
			Progress.mark_asked(ID, "treasury")
			Progress.change_trust(ID, 15)
			Progress.save_game()
			Audio.play("coin")
			return "[i]A király a kezébe veszi a(z) %s, és sokáig nézi a fáklyák fényében.[/i]\n\n" % item["name"] \
				+ "Ilyet már régen láttam. A kincstárban a helye. A kincstárnokom kifizet.\n\n" \
				+ "[color=#7a4a10](+%d tábori arany)[/color]" % TREASURY_GOLD
	Audio.play("ui_error")
	return "[i]A király végignéz a táskádon, aztán megrázza a fejét.[/i]\n\n" \
		+ "Ezek közt nincs legendás tárgy, kalandor. Csak a legjobbat fogadom el. (A táskádban legyen.)"


static func _betray() -> String:
	Progress.set_npc_quest(THIEF_QUEST, "done")
	Progress.set_npc_quest(THIEF_FATE, "betrayed")
	Progress.mark_asked(ID, "betray")
	Progress.change_trust(ID, 15)
	Progress.camp_gold += BETRAY_GOLD
	Progress.save_game()
	Audio.play("coin")
	return "[i]Elmondod: a romos házban, a sáros ösvény végén, a ládák mögötti ajtó mögött.[/i]\n\n" \
		+ "[i]A király elégedetten bólint, és int az őröknek. Két lándzsás kisiet a teremből.[/i]\n\n" \
		+ "A romos házban, mi? Ott, ahol senki sem keresné. Okos. De nem elég okos.\n\n" \
		+ "Hűséges alattvaló vagy. Fogadd el ezt a fáradságodért.\n\n" \
		+ "[color=#7a4a10](+%d tábori arany. Az őrök később üres kézzel tértek vissza: a tolvaj idejében elrejtőzött.)[/color]" % BETRAY_GOLD


static func _protect() -> String:
	Progress.set_npc_quest(THIEF_QUEST, "done")
	Progress.set_npc_quest(THIEF_FATE, "protected")
	Progress.mark_asked(ID, "protect")
	Progress.change_trust(ID, -5)
	Progress.save_game()
	return "[i]A király hosszan a szemedbe néz, mintha a gondolataidban olvasna.[/i]\n\n" \
		+ "Semmit? Hm. Kár. Pedig azt hittem, a Mélység hőse a korona szeme és füle is lehet.\n\n" \
		+ "[i]Legyint.[/i] Rendben. Előbb-utóbb úgyis hibázik. Mindenki hibázik."


static func portrait() -> Texture2D:
	var face := AtlasTexture.new()
	face.atlas = SHEET
	face.region = Rect2(Vector2.ZERO, FRAME)
	return face


## Álló animáció (lassan lélegzik) a trónon.
static func frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 2.5)
	for i in 4:
		var frame := AtlasTexture.new()
		frame.atlas = SHEET
		frame.region = Rect2(Vector2(i * FRAME.x, 0), FRAME)
		frames.add_frame("default", frame)
	return frames
