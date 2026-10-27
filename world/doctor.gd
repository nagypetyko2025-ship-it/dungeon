class_name Doctor
## Kálmán doktor a kalandorok kórházában (lásd Hospital): pestisdoktor-maszkos orvos. Kérdezgetni
## lehet, és küldetéseket ad (a J könyv "Doktor" fülén).
## 1. Vérgömb: egy legendás talizmán, a vérmágiájával a hordágyon hozott sebesültet menti meg.
## 2. A tudós szeme: epikus talizmán, amivel a betegek bőre alá lát (a méreg és a rejtett sebek).
## 3. Fűrészpenge (fegyver): műtétekhez és önvédelemhez; utána három új történet (SAW_STORIES).
## 4. A fekete csőrök: 11 pestisdoktor (a doktor régi rendtársai) a küldetés óta; utána két történet (BEAK_STORIES).
## 5. Rozi köhögése: egy Főnixtoll (legendás talizmán) a hamujáért; utána két történet (PHOENIX_STORIES).

const ID := "doctor"
const NAME := "Kálmán doktor"
const FIGURE := Rect2(368, 345, 16, 23)
const ORB_QUEST := "doctor_orb"
const ORB_ID := "trinket_orb"
const ORB_GOLD := 350
const EYE_QUEST := "doctor_eye"
const EYE_ID := "trinket_eye"
const EYE_GOLD := 220
const SAW_QUEST := "doctor_saw"
const SAW_ID := "sword_saw"
const SAW_GOLD := 160
const BEAKS_QUEST := "doctor_beaks"
## Belső jelző (Progress.npc_quests): ennyi pestisdoktort ölt meg a küldetés elfogadásakor (szövegként).
const BEAKS_BASE := "doctor_beaks_base"
const BEAKS_TARGET := "plague_doctor"
const BEAKS_GOAL := 11
const BEAKS_GOLD := 300
const PHOENIX_QUEST := "doctor_phoenix"
const PHOENIX_ID := "trinket_phoenix"
const PHOENIX_GOLD := 450
## A fekete csőrök után: a rend és hogy miért maradt itt (a maszkos történet kislánya Rozi).
const BEAK_STORIES: Array[Dictionary] = [
	{"id": "order", "text": "Milyen volt a Fekete Csőr Rendje?", "trust": 4,
		"answer": "[i]A doktor a maszk alatt elmosolyodik; hallani a hangján.[/i]\n\n" \
			+ "Bolondok voltunk. Tizenkét orvos, aki azt hitte, hogy a halált meg lehet előzni, ha elég gyorsan " \
			+ "érkezel. Lóháton jártuk a falvakat, ecetes szivacs a csőrben, levendula és mirha a maszk orrában, " \
			+ "hogy ne érezzük a szagot.\n\nOrbán vezetett minket, a legöregebb. Azt mondta: a doktor nem a halál " \
			+ "ellensége, csak a késleltetője. Akkor nem hittem neki. Most már igen."},
	{"id": "stayed", "text": "Miért nem mentél le velük?", "trust": 5,
		"answer": "[i]Rozi felé biccent, aki épp egy beteg párnáját igazítja.[/i]\n\n" \
			+ "Emlékszel, meséltem a kislányról, akiért levettem a maszkot? Amikor a rend elindult lefelé, én lázban " \
			+ "feküdtem mellette. Orbán megállt az ajtóban, és azt mondta: majd utánunk jössz, ha felkeltél.\n\n" \
			+ "Mire felkeltem, ők már nem jöttek vissza. A kislány pedig itt maradt velem. Azóta Rozi nővér. Szerinte " \
			+ "jól döntöttem. Én minden este eldöntöm, hogy elhiszem-e."},
]
## Rozi gyógyulása után.
const PHOENIX_STORIES: Array[Dictionary] = [
	{"id": "rozi", "text": "Mesélj Roziról!", "trust": 4,
		"answer": "[i]A doktor az ablak felé néz, ahol Rozi dúdolva hajtogatja a kötéseket.[/i]\n\n" \
			+ "Tizenkét éves volt, amikor elhoztam a faluból. Senkije nem maradt. Az első héten minden éjjel felkelt, " \
			+ "és megszámolta a betegeket, hogy mind lélegzik-e. Most huszonnégy, és még mindig megszámolja őket.\n\n" \
			+ "Szerintem jobb doktor lesz belőle, mint én. Igazam van. Csak még nem mondtam meg neki."},
	{"id": "tamas", "text": "Mi lett Tamással, a hordágyas fiúval?", "trust": 3,
		"answer": "[i]A doktor felnevet.[/i]\n\n" \
			+ "Tamás? Két hete elment. Azt mondta, lemegy újra a kilencedikre, megkeresni a bukott lovagot, aki " \
			+ "megsebezte. Kiabáltam vele, Rozi sírt. Három nap múlva visszajött, egy karcolás nélkül, a lovag " \
			+ "sisakjával a hóna alatt.\n\nNekem ajándékozta. A polcon tartom, a régi maszkom mellett. Azt mondja, " \
			+ "szerencsét hoz a kórháznak. Szerintem csak a port gyűjti."},
]
## A Fűrészpenge után: három új történet (a régiek is maradnak; a beszélgetés lapozható).
const SAW_STORIES: Array[Dictionary] = [
	{"id": "surgery", "text": "Mire kellett neked a fűrészpenge?", "trust": 4,
		"answer": "[i]Végighúzza az ujját a fogazott élen, elégedetten.[/i]\n\n" \
			+ "Tegnap egy kalandor lábát csont ette. Úgy értem, szó szerint: egy csontváz harapott bele, és " \
			+ "a fogai bent maradtak. Két órán át szedegettem ki őket csipesszel, mire rájöttem, hogy a csontot " \
			+ "kell megnyitni.\n\nA régi fűrészem kicsorbult. Ezzel tíz perc volt. A fiú jövő héten újra lemegy. " \
			+ "Bolond, de legalább két lábon."},
	{"id": "selfdefense", "text": "Önvédelem? Kitől félsz?", "trust": 4,
		"answer": "[i]A maszk csőre a kórház ajtaja felé fordul.[/i]\n\n" \
			+ "Nem mindenki jön fel élve a Mélységből, aki élőnek látszik. Múlt hónapban behoztak egy fiút, aki " \
			+ "éjjel felült az ágyában, és Rozi nyakát kereste. Már nem ő volt odabent.\n\n" \
			+ "Egy szikével nem lehet egy ilyet megállítani. Ezzel igen. Nem szeretem, de megtanultam: a doktor " \
			+ "dolga, hogy a betegek túléljék. Néha a betegeit is túl kell élnie."},
	{"id": "mask", "text": "Miért nem veszed le soha a maszkot?", "trust": 5,
		"answer": "[i]Sokáig hallgat. A maszk üveglencséi mögött nem látszik a szeme.[/i]\n\n" \
			+ "Egyszer levettem. Egy pestises faluban, egy kislány ágyánál, mert sírt, és félt a csőrös " \
			+ "embertől. Meggyógyult. Én három hétig haldokoltam utána.\n\n" \
			+ "Rozi szerint az arcomon még látszanak a nyomok. Azt mondom neki, hogy egy doktornak nem kell " \
			+ "arc. Csak kéz, ami nem remeg. Meg egy jó fűrész."},
]

const GREETING := "[i]A pestisdoktor-maszk mögül tompa, fáradt hang szól.[/i]\n\n" \
	+ "Csak óvatosan, ne lépj a vödörbe. Ha nem vérzel, ülj le valahova. Ha vérzel... akkor is ülj le, és várj."

const QUESTS := {
	ORB_QUEST: {"name": "A Vérgömb",
		"text": "Kálmán doktor szerint a hordágyon hozott sebesült nem éli túl a hetet, hacsak nem kap vért, "
			+ "amit egy ember nem adhat. Hozz neki egy [b]Vérgömböt[/b] (legendás talizmán, a táskádban legyen): "
			+ "a vérmágiájával talán még megmentheti.",
		"reward": "%d tábori arany (és egy megmentett élet)" % ORB_GOLD,
		"doing": "vigyél a doktornak egy Vérgömböt", "done": "a sebesült túlélte"},
	EYE_QUEST: {"name": "A tudós szeme",
		"text": "Kálmán doktor nem látja, mi mérgezi a betegeit odabent: a Mélység mérgei a bőr alatt "
			+ "bujkálnak. Hozz neki egy [b]A tudós szeme[/b] epikus talizmánt (a táskádban legyen): azzal "
			+ "a betegei bőre alá is belát.",
		"reward": "%d tábori arany" % EYE_GOLD,
		"doing": "vigyél a doktornak egy A tudós szeme talizmánt", "done": "a doktor mindent lát"},
	SAW_QUEST: {"name": "A Fűrészpenge",
		"text": "Kálmán doktor régi csontfűrésze kicsorbult, és a Mélységből néha olyan betegek jönnek fel, "
			+ "akik ellen a szike kevés. Hozz neki egy [b]Fűrészpengét[/b] (fegyver, bármilyen ritkaságú, a "
			+ "táskádban legyen): műtétekhez és önvédelemhez is jó lesz.",
		"reward": "%d tábori arany" % SAW_GOLD,
		"doing": "vigyél a doktornak egy Fűrészpengét", "done": "a doktornak van fűrésze"},
	BEAKS_QUEST: {"name": "A fekete csőrök",
		"text": "Kálmán doktor felismerte a Mélység pestisdoktorait: a régi rendtársai, a Fekete Csőr Rendjének "
			+ "orvosai, akik tizenkét éve lementek a dögvész forrását keresni. Adj nyugalmat [b]%d pestisdoktornak[/b] " % BEAKS_GOAL
			+ "a kazamatában (a küldetés elfogadása óta).",
		"reward": "%d tábori arany (és a doktor története)" % BEAKS_GOLD,
		"doing": "adj nyugalmat a pestisdoktoroknak", "done": "a fekete csőrök megpihentek"},
	PHOENIX_QUEST: {"name": "Rozi köhögése",
		"text": "Rozi nővér hetek óta köhög: a Mélységből feláramló por a tüdejébe ült. Kálmán doktor szerint csak "
			+ "egy [b]Főnixtoll[/b] (legendás talizmán, a táskádban legyen) hamuja égetheti ki belőle.",
		"reward": "%d tábori arany (és Rozi hálája)" % PHOENIX_GOLD,
		"doing": "vigyél a doktornak egy Főnixtollat", "done": "Rozi meggyógyult"},
}

const SMALL_TALK: Array[Dictionary] = [
	{"id": "who", "text": "Ki vagy te?", "trust": 4,
		"answer": "Kálmán. A tábor doktora, mióta az előző... nos, mióta ő is lement. Régen a pestises falvakat " \
			+ "jártam, onnan a maszk. A Mélység szaga sem sokkal jobb, úgyhogy rajtam maradt.\n\n" \
			+ "Rozi nővér segít. Nélküle a fele már a temetőben feküdne, Vendel nagy örömére."},
	{"id": "stretcher", "text": "Mi lett azzal, akit a katonák hoztak?", "trust": 3,
		"answer": "[i]Az ablak melletti ágy felé biccent.[/i]\n\n" \
			+ "Ott fekszik. A kilencedik emeleten egy bukott lovag kardja találta el, a katonák a lépcső aljáról " \
			+ "hozták fel. Sok vért vesztett, de él. Ha a láz lemegy, talán reggel már a nevét is megmondja.\n\n" \
			+ "Azt motyogta, hogy odalent a szörnyek egyre okosabbak. Kerülgetik az oszlopokat. Nem tetszik ez nekem."},
	{"id": "advice", "text": "Van valami tanácsod?", "trust": 2,
		"answer": "Három dolog. Egy: a vörös bájital nem cukorka, de ne is spórold, ha baj van.\n" \
			+ "Kettő: a mérget nem lehet kiizzadni. Ha zöldül a szél a szemed előtt, menekülj, és várd ki.\n" \
			+ "Három: ha a kiképzősátorban edzel, ritkábban látlak itt. Az nekem is jó."},
	{"id": "busy", "text": "Miért van itt ennyi sebesült?", "trust": 3,
		"answer": "Mert egyre többen mennek le. A király aranyat ígér, a kocsmáros küldetéseket ad, a fiatalok " \
			+ "hősök akarnak lenni.\n\n[i]Felsóhajt, a maszk csőre megbillen.[/i]\n\n" \
			+ "A hősökből lesznek a betegeim. A szerencsésebbekből."},
]


## A beszélgetés opciói: elöl a küldetések (kérés / átadás / köszönet), utána a kérdések; a
## Vérgömb után a hordágyas fiúról szóló kérdés helyett a "Hogy van a sebesült?" jön (oldalanként 5).
static func options(inventory: Inventory) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	if Progress.npc_quest_state(ORB_QUEST) == "done":
		match Progress.npc_quest_state(EYE_QUEST):
			"":
				list.append({"id": "more", "text": "Kell még valami?",
					"on_choose": func() -> String: return _give_eye_quest()})
			"active":
				if _has(inventory, EYE_ID):
					list.append({"id": "eye", "text": "Hoztam egy A tudós szeme talizmánt.",
						"on_choose": func() -> String: return _give_eye(inventory)})
			"done":
				# A szem után: a Fűrészpenge kérése / átadása, a végén a három új történet.
				match Progress.npc_quest_state(SAW_QUEST):
					"":
						list.append({"id": "more_saw", "text": "Segíthetek még valamiben?",
							"on_choose": func() -> String: return _give_saw_quest()})
					"active":
						if _has(inventory, SAW_ID):
							list.append({"id": "saw", "text": "Hoztam egy Fűrészpengét.",
								"on_choose": func() -> String: return _give_saw(inventory)})
					"done":
						list.append_array(_late_options(inventory))
						list.append_array(SAW_STORIES)
				list.append({"id": "seeing", "text": "Mit látsz a szemmel?",
					"on_choose": func() -> String: return "[i]A doktor a maszkja elé emeli a szemet, és " \
						+ "végignéz a betegeken.[/i]\n\n" \
						+ "Mindent. A pókméreg kék fonalként kúszik az erekben, a fagy fehér foltként ül a " \
						+ "csontokon. Tegnap egy kalandor tüdejéből egy egész bogarat szedtem ki. Ne kérdezd."})
	match Progress.npc_quest_state(ORB_QUEST):
		"":
			list.append({"id": "help", "text": "Kell segíteni valamiben?",
				"on_choose": func() -> String: return _give_orb_quest()})
		"active":
			if has_orb(inventory):
				list.append({"id": "orb", "text": "Hoztam egy Vérgömböt.",
					"on_choose": func() -> String: return _give_orb(inventory)})
		"done":
			list.append({"id": "patient", "text": "Hogy van a sebesült?",
				"on_choose": func() -> String: return "[i]A doktor az ablak melletti ágy felé int. A sebesült ül, " \
					+ "és egy tál levest kanalaz, kicsit remegő kézzel.[/i]\n\n" \
					+ "Látod? Ma reggel megmondta a nevét: Tamás. Holnap talán már járni is tud. A gömböt elzártam: " \
					+ "ilyen erő nem való egy kórház polcára."})
	for option in SMALL_TALK:
		if option["id"] == "stretcher" and Progress.npc_quest_state(ORB_QUEST) == "done":
			continue
		list.append(option)
	return list


## A Fűrészpenge után (elöl, a régi történetek előtt): a fekete csőrök (pestisdoktorok), utána két történet,
## aztán Rozi köhögése (Főnixtoll), utána még két történet.
static func _late_options(inventory: Inventory) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	match Progress.npc_quest_state(BEAKS_QUEST):
		"":
			list.append({"id": "more_beaks", "text": "Mi az a régi maszk a polcon?",
				"on_choose": func() -> String: return _give_beaks_quest()})
		"active":
			if beaks_progress() >= BEAKS_GOAL:
				list.append({"id": "beaks_done", "text": "Megnyugvást adtam a fekete csőröknek.",
					"on_choose": func() -> String: return _finish_beaks()})
			else:
				list.append({"id": "beaks", "text": "Hány pestisdoktor van még hátra?",
					"on_choose": func() -> String: return "[i]A doktor a polcon álló maszkra néz.[/i]\n\n" \
						+ "Eddig %d. Még %d. Nem sürgetlek: ők már nem sietnek sehova." \
						% [beaks_progress(), BEAKS_GOAL - beaks_progress()]})
		"done":
			match Progress.npc_quest_state(PHOENIX_QUEST):
				"":
					list.append({"id": "rozi_cough", "text": "Rozi sokat köhög mostanában. Mi baja?",
						"on_choose": func() -> String: return _give_phoenix_quest()})
				"active":
					if _has(inventory, PHOENIX_ID):
						list.append({"id": "phoenix", "text": "Hoztam egy Főnixtollat.",
							"on_choose": func() -> String: return _give_phoenix(inventory)})
				"done":
					list.append_array(PHOENIX_STORIES)
			list.append_array(BEAK_STORIES)
	return list


## A küldetés elfogadása óta megölt pestisdoktorok (legfeljebb a cél).
static func beaks_progress() -> int:
	var base := int(Progress.npc_quest_state(BEAKS_BASE))
	return clampi(int(Progress.kills.get(BEAKS_TARGET, 0)) - base, 0, BEAKS_GOAL)


## A J könyv "folyamatban" szövege (a pestisdoktoros küldetésnél a haladással).
static func doing_text(id: String, fallback: String) -> String:
	if id == BEAKS_QUEST:
		return "%s: %d / %d" % [fallback, beaks_progress(), BEAKS_GOAL]
	return fallback


static func _give_beaks_quest() -> String:
	Progress.set_npc_quest(BEAKS_QUEST, "active")
	Progress.set_npc_quest(BEAKS_BASE, str(int(Progress.kills.get(BEAKS_TARGET, 0))))
	Progress.mark_asked(ID, "more_beaks")
	Progress.save_game()
	Audio.play("ui_open")
	return "[i]A doktor leveszi a polcról a régi, kopott csőrös maszkot, és sokáig forgatja a kezében.[/i]\n\n" \
		+ "Nem csak a pestises falvakból hoztam a maszkot. Egy rendből. A Fekete Csőr Rendje: tizenkét orvos, " \
		+ "akik faluról falura üldözték a dögvészt. Tizenkét éve, amikor megremegett a föld, a dögvész a Mélységből " \
		+ "tört fel. Tizenegyen lementek a forrását keresni. A tizenkettedik én lettem volna.\n\n" \
		+ "[i]A hangja megkeményedik.[/i]\n\nA kalandorok szerint odalent csőrös alakok járnak, és halálos ködöt " \
		+ "fújnak, amikor elesnek. Nem tudom, melyik melyikük. De tizenegyen mentek le. Adj nyugalmat legalább " \
		+ "[b]tizenegy pestisdoktornak[/b].\n\n" \
		+ "[color=#7a4a10](Új küldetés a J könyvben, a Doktor fülön.)[/color]"


static func _finish_beaks() -> String:
	Progress.set_npc_quest(BEAKS_QUEST, "done")
	Progress.mark_asked(ID, "beaks_done")
	Progress.add_camp_gold(BEAKS_GOLD)
	Progress.change_trust(ID, 20)
	Progress.save_game()
	Audio.play("level_up")
	return "[i]A doktor tizenegy apró keresztet karcol a fa asztal szélébe, egyiket a másik után.[/i]\n\n" \
		+ "Tizenegy. Ha a Mélységben van igazság, most már pihennek. Szilárd, Gedeon, a vén Orbán... mind.\n\n" \
		+ "[i]Feléd fordul; a maszk lencséi mögött nem látszik a szeme.[/i]\n\nKöszönöm. Ezt nem lehet " \
		+ "megfizetni, de azért fogadd el. [color=#7a4a10](+%d tábori arany)[/color]" % BEAKS_GOLD


static func _give_phoenix_quest() -> String:
	Progress.set_npc_quest(PHOENIX_QUEST, "active")
	Progress.mark_asked(ID, "rozi_cough")
	Progress.save_game()
	Audio.play("ui_open")
	return "[i]A maszk csőre Rozi felé fordul, aztán vissza feléd.[/i]\n\n" \
		+ "Észrevetted. Hetek óta köhög, és vért is láttam a kendőjén. A lépcső aljáról feláramló por a tüdőbe ül, " \
		+ "és ott marad. A kalandorok egy idő után kiköhögik. Rozi minden nap ott áll a hordágyak mellett, ahol a " \
		+ "legtöbb por van.\n\n" \
		+ "Egy régi könyvem szerint a [b]Főnixtoll[/b] hamuja kiégeti a port a tüdőből. Legendás talizmán, a Mélység " \
		+ "mélyén terem, ha terem. Ha rátalálsz... ne add el. Hozd ide.\n\n" \
		+ "[color=#7a4a10](Új küldetés a J könyvben, a Doktor fülön.)[/color]"


static func _give_phoenix(inventory: Inventory) -> String:
	for i in inventory.bag.size():
		var item: Variant = inventory.bag[i]
		if not (item is Dictionary and item.get("id", "") == PHOENIX_ID):
			continue
		inventory.take_from_bag(i)
		Progress.set_npc_quest(PHOENIX_QUEST, "done")
		Progress.mark_asked(ID, "phoenix")
		Progress.add_camp_gold(PHOENIX_GOLD)
		Progress.change_trust(ID, 25)
		Progress.save_game()
		Audio.play("level_up")
		return "[i]A doktor egy cserépedényben elégeti a tollat. A lángja aranyszínű, és egy pillanatra az egész " \
			+ "kórház megtelik meleg fénnyel. A hamut borba keveri, és Rozi kezébe adja.[/i]\n\n" \
			+ "[i]Rozi grimaszol, megissza, köhög egy nagyot... aztán mély levegőt vesz. Egy hosszút, szabadot.[/i]" \
			+ "\n\nRozi: „Már el is felejtettem, milyen ez.”\n\n" \
			+ "[i]A doktor feléd fordul. Most hallod először nevetni.[/i]\n\n" \
			+ "Köszönöm. Ezt sosem felejtem el. [color=#7a4a10](+%d tábori arany)[/color]" % PHOENIX_GOLD
	return "Hm? Nem látom nálad a Főnixtollat."


static func _has(inventory: Inventory, id: String) -> bool:
	for item: Variant in inventory.bag:
		if item is Dictionary and item.get("id", "") == id:
			return true
	return false


static func _give_eye_quest() -> String:
	Progress.set_npc_quest(EYE_QUEST, "active")
	Progress.mark_asked(ID, "more")
	Progress.save_game()
	Audio.play("ui_open")
	return "[i]A doktor egy beteg fölé hajol, aztán bosszúsan kiegyenesedik.[/i]\n\n" \
		+ "Kell. Látod ezt a fiút? Nincs rajta seb, mégis lázas, és napról napra gyengül. A Mélység mérgei " \
		+ "a bőr alatt bujkálnak, és én nem látom őket. Vakon gyógyítok, mint egy falusi kuruzsló.\n\n" \
		+ "Hallottam egy talizmánról, amit [b]A tudós szemének[/b] hívnak. Aki a markában tartja, a dolgok " \
		+ "belsejébe lát. Ha rátalálsz odalent, hozd el nekem. Rozi már előre fél tőle.\n\n" \
		+ "[color=#7a4a10](Új küldetés a J könyvben, a Doktor fülön.)[/color]"


static func _give_eye(inventory: Inventory) -> String:
	for i in inventory.bag.size():
		var item: Variant = inventory.bag[i]
		if not (item is Dictionary and item.get("id", "") == EYE_ID):
			continue
		inventory.take_from_bag(i)
		Progress.set_npc_quest(EYE_QUEST, "done")
		Progress.add_camp_gold(EYE_GOLD)
		Progress.change_trust(ID, 20)
		Progress.save_game()
		Audio.play("level_up")
		return "[i]A doktor a maszkja elé tartja a szemet. Hosszan, mozdulatlanul néz a lázas fiúra, aztán " \
			+ "halkan felnevet.[/i]\n\n" \
			+ "Ott vagy, te kis féreg. Pókméreg, a bal vállában, egy apró tüske. Rozi, a csipeszt!\n\n" \
			+ "[i]Feléd fordul.[/i]\n\nEzzel a szemmel több életet mentek meg, mint az elmúlt tíz évben " \
			+ "összesen. Fogadd el ezt. [color=#7a4a10](+%d tábori arany)[/color]" % EYE_GOLD
	return "Hm? Nem látom nálad a szemet."


static func _give_saw_quest() -> String:
	Progress.set_npc_quest(SAW_QUEST, "active")
	Progress.mark_asked(ID, "more_saw")
	Progress.save_game()
	Audio.play("ui_open")
	return "[i]A doktor egy kicsorbult, rozsdás csontfűrészt emel fel a tálcáról, és undorral nézi.[/i]\n\n" \
		+ "Ha már kérdezed... ezzel nem lehet dolgozni. Inkább tépi a csontot, mint vágja. És van más is: " \
		+ "néha olyan betegeket hoznak fel, akik ellen a szike kevés. Nem részletezem.\n\n" \
		+ "Odalent a kalandorok néha találnak egy [b]Fűrészpengét[/b]. Fegyvernek szánták, de nekem kétszer " \
		+ "annyit ér: műtétekhez és önvédelemhez. Hozz egyet, és megfizetem.\n\n" \
		+ "[color=#7a4a10](Új küldetés a J könyvben, a Doktor fülön.)[/color]"


static func _give_saw(inventory: Inventory) -> String:
	for i in inventory.bag.size():
		var item: Variant = inventory.bag[i]
		if not (item is Dictionary and item.get("id", "") == SAW_ID):
			continue
		inventory.take_from_bag(i)
		Progress.set_npc_quest(SAW_QUEST, "done")
		Progress.add_camp_gold(SAW_GOLD)
		Progress.change_trust(ID, 15)
		Progress.save_game()
		Audio.play("level_up")
		return "[i]A doktor a fény felé tartja a pengét, végigfuttatja a hüvelykujját a fogakon, és " \
			+ "elégedetten bólint.[/i]\n\n" \
			+ "Éles. Kiegyensúlyozott. A kovács, aki ezt csinálta, értett a csonthoz, akár akarta, akár nem.\n\n" \
			+ "[i]Az övébe tűzi, a szike mellé.[/i]\n\nKöszönöm. Ha legközelebb erre jársz, mesélek, mire " \
			+ "kellett. [color=#7a4a10](+%d tábori arany)[/color]" % SAW_GOLD
	return "Hm? Nem látom nálad a fűrészpengét."


static func _give_orb_quest() -> String:
	Progress.set_npc_quest(ORB_QUEST, "active")
	Progress.mark_asked(ID, "help")
	Progress.save_game()
	Audio.play("ui_open")
	return "[i]A doktor sokáig hallgat, a maszk csőre a padló felé fordul.[/i]\n\n" \
		+ "Segíteni? Talán. A hordágyas fiú... nem éli túl a hetet. Túl sok vért vesztett, és amit én adhatok, " \
		+ "az kevés. Ember nem adhat annyit.\n\n" \
		+ "Hallottál már a [b]Vérgömbről[/b]? Legendás talizmán, a Mélység legmélyén terem. Azt mondják, a vér " \
		+ "dobog benne, mint egy szív. Ha valaha rátalálsz, hozd el nekem. A vérmágiájával talán még " \
		+ "visszahozhatom a fiút.\n\n" \
		+ "[color=#7a4a10](Új fül a küldetések könyvében: Doktor  [J])[/color]"


static func is_orb(item: Variant) -> bool:
	return item is Dictionary and item.get("id", "") == ORB_ID


static func has_orb(inventory: Inventory) -> bool:
	for item: Variant in inventory.bag:
		if is_orb(item):
			return true
	return false


static func _give_orb(inventory: Inventory) -> String:
	for i in inventory.bag.size():
		if not is_orb(inventory.bag[i]):
			continue
		inventory.take_from_bag(i)
		Progress.set_npc_quest(ORB_QUEST, "done")
		Progress.add_camp_gold(ORB_GOLD)
		Progress.change_trust(ID, 30)
		Progress.save_game()
		Audio.play("level_up")
		return "[i]A doktor kesztyűs kézzel, óvatosan veszi át a gömböt. Vörösen lüktet a tenyerében, mintha " \
			+ "élne. Az ablak melletti ágyhoz siet, és a sebesült mellkasára fekteti.[/i]\n\n" \
			+ "[i]Hosszú csend. Aztán a fiú köhög egyet, és kinyitja a szemét.[/i]\n\n" \
			+ "Él. Él! Rozi, hozz vizet!\n\n[i]Feléd fordul, a maszk mögül alig hallani a hangját.[/i]\n\n" \
			+ "Köszönöm, kalandor. Nem sokan hoznak ide életet; a legtöbben csak sebeket. " \
			+ "[color=#7a4a10](+%d tábori arany)[/color]" % ORB_GOLD
	return "Hm? Nem látom nálad a Vérgömböt."


static func portrait() -> AtlasTexture:
	return SpriteSheet.region(FIGURE)
