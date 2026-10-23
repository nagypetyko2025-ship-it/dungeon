class_name Gravedigger
## Csontos Vendel, a csontváz fejű sírásó (lásd Graveyard és Chapel). Eleinte a temetőben áll,
## és csak mesél. A "Segíthetek valamiben?" kérdésre 50 csontváz elpusztítását kéri (a J könyv
## "Csontváz sírásó" fülén); utána átsétál a temető melletti régi kápolnába, és onnantól ott van.
## Az 50 csontváz után elmeséli a történetét, és egy Szent kereszt amulettet kér. A kereszt után
## (és két újabb történet után) 20 zombit kér, aztán (újabb két történet után) egy legendás talizmánt.
## A talizmán után elsétál a kocsmába, és onnantól játszható karakter (Characters "gravedigger").

const ID := "gravedigger"
const NAME := "Csontos Vendel, a sírásó"
const SHORT_NAME := "Vendel"
const SHEET: Texture2D = preload("res://assets/characters/gravedigger.png")
const SHOVEL: Texture2D = preload("res://assets/characters/shovel.png")

const SKELETON_QUEST := "digger_skeletons"
## Belső jelző (Progress.npc_quests): ennyi csontvázat ölt meg a küldetés elfogadásakor (szövegként).
const SKELETON_BASE := "digger_skeletons_base"
const SKELETON_GOAL := 50
## Ezek számítanak csontváznak (a Progress.kills nevei).
const SKELETONS: Array[String] = ["skelet", "skeleton_legionary", "giant_skeleton"]
const SKELETON_GOLD := 150
const CROSS_QUEST := "digger_cross"
const CROSS_ID := "amulet_cross"
const CROSS_GOLD := 250
## Belső jelző: Vendel már beköltözött a kápolnába ("done"; a séta után).
const CHAPEL_FLAG := "digger_chapel"
const ZOMBIE_QUEST := "digger_zombies"
const ZOMBIE_BASE := "digger_zombies_base"
const ZOMBIE_GOAL := 20
const ZOMBIES: Array[String] = ["zombie", "tiny_zombie", "big_zombie", "ice_zombie"]
const ZOMBIE_GOLD := 200
const TALISMAN_QUEST := "digger_talisman"
const TALISMAN_GOLD := 300
## A talizmán után a kocsmába költözik: "walking" (a beszélgetés bezárása után kisétál), aztán "done".
const TAVERN_FLAG := "vendel_tavern"

const GREETING := "[i]Felnéz az ásójáról. Az arca helyén csupasz koponya, a szemgödreiben halvány fény pislákol.[/i]\n\n" \
	+ "Ne ijedj meg, vándor. Ha bántani akarnálak, már egy gödörrel arrébb feküdnél.\n" \
	+ "Vendel vagyok. Én temetem el azokat, akik visszajönnek a Mélységből... meg azokat is, akik nem."
const CHAPEL_GREETING := "[i]Vendel a por lepte padok között söprög, a régi oltár előtt. Amikor belépsz, " \
	+ "a szemgödreiben felvillan a fény.[/i]\n\nÁ, te vagy az. Gyere csak beljebb, a por nem harap."

const QUESTS := {
	SKELETON_QUEST: {"name": "Csontok nyugalma",
		"text": "Vendel, a sírásó szerint a Mélységben kóborló csontvázak a tábor elveszett halottai: "
			+ "a testüket elvitte a sötét, a lelkük nem nyugszik. Pusztíts el [b]%d csontvázat[/b] " % SKELETON_GOAL
			+ "a kazamatában (csontvázak, csontlégiósok, óriás csontvázak), hogy végre megpihenhessenek.",
		"reward": "%d tábori arany (és Vendel története)" % SKELETON_GOLD,
		"doing": "pusztíts el csontvázakat", "done": "a csontok megpihentek"},
	CROSS_QUEST: {"name": "A kápolna keresztje",
		"text": "Vendel a régi kápolnában él. Az oltár fölött egykor egy megszentelt kereszt függött, de a "
			+ "Mélység elvitte. Hozz neki egy [b]Szent kereszt[/b] amulettet (a táskádban legyen), hogy "
			+ "újra megáldhassa vele a halottakat.",
		"reward": "%d tábori arany (és Vendel áldása)" % CROSS_GOLD,
		"doing": "vigyél Vendelnek egy Szent kereszt amulettet", "done": "a kereszt újra az oltáron"},
	ZOMBIE_QUEST: {"name": "A rothadó testvérek",
		"text": "Vendel szerint a zombik a Mélység legkegyetlenebb tréfája: a halottak, akiknek a testét "
			+ "nem csak elvitte, hanem meg is tartotta. Pusztíts el [b]%d zombit[/b] a kazamatában " % ZOMBIE_GOAL
			+ "(zombik, apró zombik, nagy zombik, jégzombik).",
		"reward": "%d tábori arany (és Vendel újabb története)" % ZOMBIE_GOLD,
		"doing": "pusztíts el zombikat", "done": "a zombik megpihentek"},
	TALISMAN_QUEST: {"name": "Az utolsó kérés",
		"text": "Vendel újra le akar menni a Mélységbe, de csontokkal és egy ásóval nem elég. Hozz neki egy "
			+ "[b]legendás talizmánt[/b] (bármilyet, a táskádban legyen), hogy legyen mivel szembenéznie a sötéttel.",
		"reward": "%d tábori arany (és Vendel csatlakozik hozzád)" % TALISMAN_GOLD,
		"doing": "vigyél Vendelnek egy legendás talizmánt", "done": "Vendel a kocsmába költözött"},
}

const SMALL_TALK: Array[Dictionary] = [
	{"id": "who", "text": "Ki vagy te valójában?", "trust": 5,
		"answer": "Valaha én is kalandor voltam. Lementem a tizenkettedik emeletig, és ott egy lich megérintett.\n\n" \
			+ "Nem haltam meg. Csak... elfelejtettem élni. A húsom lassan lekopott, a csontjaim maradtak.\n" \
			+ "A tábor népe előbb félt tőlem, aztán megszokott. Most én vigyázok a halottaikra."},
	{"id": "graves", "text": "Kik nyugszanak itt?", "trust": 3,
		"answer": "Mindenféle népek. Kovácsinasok, zsoldosok, egy dalnok, aki a hetedik emeleten akart dalt írni a sötétről.\n\n" \
			+ "A legtöbb sír üres, tudod. Csak a nevük jött vissza, meg néha egy kard vagy egy sisak.\n" \
			+ "Azért mindegyiket rendesen megásom. Egy névnek is jár a hely."},
	{"id": "shovel", "text": "Szép ásó. Honnan van?", "trust": 2,
		"answer": "[i]Megsimítja a nyelét, mintha egy régi barát vállát veregetné.[/i]\n\n" \
			+ "Ezt még a nagyapám kovácsolta, mikor a tábor csak három sátor volt. Háromszáz sírt ástam vele.\n" \
			+ "Egyszer egy ghoult is agyoncsaptam vele, aki kimászott az egyikből. Azóta mélyebbre ások."},
	{"id": "night", "text": "Nem félsz itt egyedül éjszaka?", "trust": 2,
		"answer": "Félni? [i]Csontos nevetés, mintha kockák gurulnának egy dobozban.[/i]\n\n" \
			+ "Éjjel néha hallom, ahogy a föld alatt kaparnak. De az csak a Mélység lélegzik.\n" \
			+ "Ha egyszer kopogást hallasz egy sírból, fiam... akkor fuss. Addig ne."},
]


## A története után (az 50 csontváz és a kereszt kérése után) ezekről is kérdezhetsz.
const STORY_TALK: Array[Dictionary] = [
	{"id": "ambrus", "text": "Milyen ember volt Ambrus atya?", "trust": 4,
		"answer": "[i]Vendel szemgödreiben a fény megenyhül.[/i]\n\n" \
			+ "Ambrus? Nagydarab, kopasz ember volt, a keze inkább kovácsé, mint paphoz illő. Minden reggel " \
			+ "ő maga húzta meg a harangot, pedig ez az én dolgom lett volna. Azt mondta, a harang a hazavezető út: " \
			+ "akit lent ér a hangja, az tudja, merre van fent.\n\n" \
			+ "Amikor a kalandorok nem jöttek vissza, a nevüket felírta a kápolna falára. Ott vannak még most is, " \
			+ "a por alatt. Néha letörlöm őket."},
	{"id": "lich", "text": "Mi történt pontosan a tizenkettedik emeleten?", "trust": 5,
		"answer": "[i]Sokáig hallgat. A csontujjai megszorítják az ásó nyelét.[/i]\n\n" \
			+ "Hárman voltunk. Egy sötét terembe értünk, ahol a falakon jégvirágok nőttek, pedig odalent sosincs hideg. " \
			+ "A lich a terem közepén ült, és várt. Nem támadott. Csak nézett.\n\n" \
			+ "A két társam elfutott. Én maradtam, mert azt hittem, a kereszt megvéd. A lich felállt, lassan " \
			+ "odajött, és leszakította a nyakamból, mintha csak egy pókhálót söpörne le. Aztán a homlokomra tette " \
			+ "a kezét. Hideg volt. Azóta sem melegedtem fel."},
	{"id": "return", "text": "Miért nem mentél le újra a keresztért?", "trust": 3,
		"answer": "Lementem. Kétszer is.\n\n" \
			+ "[i]Megkopogtatja a saját bordáit.[/i]\n\n" \
			+ "De a Mélység nem szereti, ha a halottai visszamennek hozzá. Az első alkalommal a csontvázak " \
			+ "letérdeltek előttem, mintha a vezérük lennék. A másodiknál már követni akartak, egészen fel, a táborig. " \
			+ "Akkor értettem meg: ha még egyszer lemegyek, nem biztos, hogy én hozom fel őket... lehet, hogy ők " \
			+ "visznek le engem. Ezért kértelek téged."},
]


## A kereszt után: két újabb történet (utánuk kéri a zombikat).
const STORY_TALK_2: Array[Dictionary] = [
	{"id": "names", "text": "Mi van a kápolna falára írt nevekkel?", "trust": 3,
		"answer": "[i]Végighúzza a csontujját a falon, ahol a por alatt halványan betűk látszanak.[/i]\n\n" \
			+ "Háromszáztizenkét név. Ambrus írta fel őket, egyenként, gyertyafénynél. Az utolsót én: az övét.\n\n" \
			+ "Néha éjjel, amikor a harang magától megmozdul a szélben, úgy érzem, olvassák. A halottak szeretik, " \
			+ "ha valaki emlékszik rájuk. Talán ezért nem mentek még el egészen."},
	{"id": "zombies_story", "text": "Mi a különbség a csontvázak és a zombik között?", "trust": 4,
		"answer": "A csontváz elfelejtette, ki volt. Csak megy, mert a Mélység hajtja.\n\n" \
			+ "[i]Elhallgat, a szemgödreiben a fény elhalványul.[/i]\n\n" \
			+ "A zombi viszont emlékszik. Ott a hús, ott az arc, ott minden, ami fáj. A Mélység meghagyta nekik, " \
			+ "hogy tudják, mit veszítettek. Láttam egy zombit odalent, aki a lánya nevét suttogta, miközben rám támadt. " \
			+ "Azt hiszem, nekik nagyobb szükségük van a nyugalomra, mint bárkinek."},
]
## A zombik után: két újabb történet (utánuk kéri a legendás talizmánt).
const STORY_TALK_3: Array[Dictionary] = [
	{"id": "daughter", "text": "Megtaláltad a zombit, aki a lánya nevét suttogta?", "trust": 4,
		"answer": "[i]Bólint, lassan.[/i]\n\n" \
			+ "Te találtad meg. Az egyik a húsz közül ő volt, érzem. Kerekes Pálnak hívták, molnár volt a faluban. " \
			+ "A lánya, Zsófi, most a kovácsnál inas. Nem mondom el neki. Elég, ha tudja, hogy az apja végre alszik.\n\n" \
			+ "Holnap faragok neki egy táblát. A kápolna falán még van hely."},
	{"id": "go_down", "text": "Miért akarsz újra lemenni?", "trust": 5,
		"answer": "Mert húsz évig csak temettem. Vártam, hogy a kalandorok hazahozzák, amit lehet, és eltemettem, " \
			+ "amit hoztak.\n\n[i]Felemeli az ásót, és megforgatja a kezében, mint egy fegyvert.[/i]\n\n" \
			+ "De most láttam, mire képes egy élő, aki nem fél. Ha egy halott is lemehet, és hazahozhat egy-két " \
			+ "lelket... akkor az én helyem nem a kápolnában van. Hanem odalent. Veled."},
]


static func greeting() -> String:
	return CHAPEL_GREETING if in_chapel() else GREETING


## A küldetés elfogadása után a kápolnába költözik (a séta után ott marad).
static func in_chapel() -> bool:
	return Progress.npc_quest_state(CHAPEL_FLAG) == "done" and Progress.npc_quest_state(TAVERN_FLAG) != "done"


## A talizmán után épp kisétál a kápolnából (a beszélgetés bezárásakor, lásd Chapel).
static func leaving() -> bool:
	return Progress.npc_quest_state(TAVERN_FLAG) == "walking"


## El kell-e indulnia a kápolnába (elfogadta a küldetést, de még a temetőben áll).
static func should_walk() -> bool:
	return Progress.npc_quest_state(SKELETON_QUEST) != "" and not in_chapel()


static func skeleton_kills() -> int:
	return _kills(SKELETONS)


static func zombie_kills() -> int:
	return _kills(ZOMBIES)


static func _kills(names: Array[String]) -> int:
	var total := 0
	for name in names:
		total += int(Progress.kills.get(name, 0))
	return total


static func zombie_progress() -> int:
	var base := int(Progress.npc_quest_state(ZOMBIE_BASE))
	return mini(zombie_kills() - base, ZOMBIE_GOAL)


## A küldetés elfogadása óta elpusztított csontvázak (legfeljebb a cél).
static func skeleton_progress() -> int:
	var base := int(Progress.npc_quest_state(SKELETON_BASE))
	return mini(skeleton_kills() - base, SKELETON_GOAL)


## A J könyv "folyamatban" szövege (a csontváz-küldetésnél a haladással).
static func doing_text(id: String, fallback: String) -> String:
	if id == SKELETON_QUEST:
		return "%s: %d / %d" % [fallback, skeleton_progress(), SKELETON_GOAL]
	if id == ZOMBIE_QUEST:
		return "%s: %d / %d" % [fallback, zombie_progress(), ZOMBIE_GOAL]
	return fallback


## A beszélgetés opciói: elöl a küldetéshez tartozó, utána a legújabb történetek, aztán a még fel nem
## tett régi kérdések (legfeljebb 5 fér ki). A következő kérés csak a szakasz két történetje után jön.
static func options(inventory: Inventory) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var asked: Array = Progress.asked_topics(ID)
	match Progress.npc_quest_state(SKELETON_QUEST):
		"":
			list.append({"id": "help", "text": "Segíthetek valamiben?",
				"on_choose": func() -> String: return _give_skeleton_quest()})
		"active":
			if skeleton_progress() >= SKELETON_GOAL:
				list.append({"id": "skeletons_done", "text": "Elpusztítottam ötven csontvázat.",
					"on_choose": func() -> String: return _finish_skeletons()})
			else:
				list.append({"id": "skeletons", "text": "Hogy állok a csontvázakkal?",
					"on_choose": func() -> String: return _count_answer(skeleton_progress(), SKELETON_GOAL)})
	if Progress.npc_quest_state(CROSS_QUEST) == "active" and has_cross(inventory):
		list.append({"id": "cross", "text": "Hoztam egy Szent kereszt amulettet.",
			"on_choose": func() -> String: return _give_cross(inventory)})
	match Progress.npc_quest_state(ZOMBIE_QUEST):
		"":
			if Progress.npc_quest_state(CROSS_QUEST) == "done" and _all_asked(STORY_TALK_2, asked):
				list.append({"id": "more_help", "text": "Van még, amiben segíthetek?",
					"on_choose": func() -> String: return _give_zombie_quest()})
		"active":
			if zombie_progress() >= ZOMBIE_GOAL:
				list.append({"id": "zombies_done", "text": "Elpusztítottam húsz zombit.",
					"on_choose": func() -> String: return _finish_zombies()})
			else:
				list.append({"id": "zombies", "text": "Hogy állok a zombikkal?",
					"on_choose": func() -> String: return _count_answer(zombie_progress(), ZOMBIE_GOAL)})
	match Progress.npc_quest_state(TALISMAN_QUEST):
		"":
			if Progress.npc_quest_state(ZOMBIE_QUEST) == "done" and _all_asked(STORY_TALK_3, asked):
				list.append({"id": "last_wish", "text": "Mire van még szükséged?",
					"on_choose": func() -> String: return _give_talisman_quest()})
		"active":
			if has_legendary_talisman(inventory):
				list.append({"id": "talisman", "text": "Hoztam egy legendás talizmánt.",
					"on_choose": func() -> String: return _give_talisman(inventory)})
	# Történetek: a legújabb szakaszé elöl, a régebbiekből csak a fel nem tettek.
	var stages: Array = []
	if Progress.npc_quest_state(ZOMBIE_QUEST) == "done":
		stages.append(STORY_TALK_3)
	if Progress.npc_quest_state(CROSS_QUEST) == "done":
		stages.append(STORY_TALK_2)
	if Progress.npc_quest_state(SKELETON_QUEST) == "done":
		stages.append(STORY_TALK)
	if stages.is_empty():
		list.append_array(SMALL_TALK)
		return list
	list.append_array(stages[0])
	for stage: Array in stages.slice(1) + [SMALL_TALK]:
		for option: Dictionary in stage:
			if not asked.has(option["id"]):
				list.append(option)
	return list


static func _all_asked(stage: Array[Dictionary], asked: Array) -> bool:
	for option in stage:
		if not asked.has(option["id"]):
			return false
	return true


static func _count_answer(done: int, goal: int) -> String:
	return "[i]Vendel az ujjain számol, a csontjai halkan kocognak.[/i]\n\n" \
		+ "%d megpihent, még %d vár rád odalent. Ne siess: a halottak ráérnek." % [done, goal - done]


static func _give_zombie_quest() -> String:
	Progress.set_npc_quest(ZOMBIE_QUEST, "active")
	Progress.set_npc_quest(ZOMBIE_BASE, str(zombie_kills()))
	Progress.mark_asked(ID, "more_help")
	Progress.save_game()
	return "[i]Vendel az oltár előtt áll, a kereszt fénye megcsillan a koponyáján.[/i]\n\n" \
		+ "Van. A zombik. Már beszéltem róluk: emlékeznek. Minden nap, minden órában emlékeznek.\n\n" \
		+ "Pusztíts el közülük [b]húszat[/b]. Gyorsan, ha lehet, ne szenvedjenek. Én addig itt imádkozom értük, " \
		+ "ahogy Ambrus tanította. Talán így könnyebben találnak haza.\n\n" \
		+ "[color=#7a4a10](Új küldetés a J könyvben.)[/color]"


static func _finish_zombies() -> String:
	Progress.set_npc_quest(ZOMBIE_QUEST, "done")
	Progress.add_camp_gold(ZOMBIE_GOLD)
	Progress.change_trust(ID, 20)
	Progress.save_game()
	Audio.play("level_up")
	return "[i]A gyertyák lángja megremeg, mintha valaki elsétálna mellettük. Vendel lehajtja a fejét.[/i]\n\n" \
		+ "Húsz. Érzem mindet. Az egyik... ő volt az, akiről meséltem. Köszönöm. Ezt neked tettem félre. " \
		+ "[color=#7a4a10](+%d tábori arany)[/color]\n\n" % ZOMBIE_GOLD \
		+ "Ülj le egy kicsit, ha van időd. Van még mit mesélnem."


static func _give_talisman_quest() -> String:
	Progress.set_npc_quest(TALISMAN_QUEST, "active")
	Progress.mark_asked(ID, "last_wish")
	Progress.save_game()
	return "[i]Vendel sokáig nézi az ásóját, aztán a kereszt felé fordul.[/i]\n\n" \
		+ "Egy dologra. Ha lemegyek, nem mehetek csak csontokkal és egy ásóval. A lich egyszer már elvett " \
		+ "tőlem mindent. Kell valami, ami erősebb nála.\n\n" \
		+ "Hozz nekem egy [b]legendás talizmánt[/b]. Tudom, ritka kincs, és nagy kérés egy halottól. " \
		+ "De ha meghozod, esküszöm a kápolna harangjára: melletted leszek odalent, amíg a csontjaim bírják.\n\n" \
		+ "[color=#7a4a10](Új küldetés a J könyvben.)[/color]"


static func is_legendary_talisman(item: Variant) -> bool:
	return item is Dictionary and item.get("slot", "") == "trinket" and item.get("rarity", "") == "legendary"


static func has_legendary_talisman(inventory: Inventory) -> bool:
	for item: Variant in inventory.bag:
		if is_legendary_talisman(item):
			return true
	return false


## A talizmán után: megköszöni, mesél, és (a beszélgetés bezárásakor) elsétál a kocsmába.
static func _give_talisman(inventory: Inventory) -> String:
	for i in inventory.bag.size():
		var item: Variant = inventory.bag[i]
		if not is_legendary_talisman(item):
			continue
		inventory.take_from_bag(i)
		Progress.set_npc_quest(TALISMAN_QUEST, "done")
		Progress.set_npc_quest(TAVERN_FLAG, "walking")
		Progress.add_camp_gold(TALISMAN_GOLD)
		Progress.change_trust(ID, 30)
		Progress.save_game()
		Audio.play("level_up")
		return "[i]Vendel két kézzel veszi át a(z) %s. A talizmán felizzik a csontujjai között, " % item["name"] \
			+ "és a fény lassan végigkúszik a karján, egészen a szemgödreiig.[/i]\n\n" \
			+ "Érzed? Meleg. Húsz éve nem éreztem meleget.\n\n" \
			+ "Tudod, mit mondott Ambrus, amikor utoljára láttam? Hogy a halottaknak nem az a dolguk, hogy " \
			+ "várjanak. Hanem hogy emlékeztessék az élőket, miért érdemes visszajönni. Azt hittem, ezt a sírokkal " \
			+ "teszem. De most már tudom: azzal, ha lemegyek, és hazahozom, akit lehet.\n\n" \
			+ "[i]Felveszi az ásót, a vállára veti, és az ajtó felé indul.[/i]\n\n" \
			+ "A kocsmában várlak. Mondd meg a kocsmárosnak, hogy a csontváz nem iszik... de egy széket azért kérek.\n\n" \
			+ "[color=#7a4a10](+%d tábori arany. Vendel a kocsmába költözik: mostantól játszható karakter.)[/color]" \
			% TALISMAN_GOLD
	return "Hm? Nem látok nálad legendás talizmánt."


static func _give_skeleton_quest() -> String:
	Progress.set_npc_quest(SKELETON_QUEST, "active")
	Progress.set_npc_quest(SKELETON_BASE, str(skeleton_kills()))
	Progress.mark_asked(ID, "help")
	Progress.save_game()
	return "[i]Vendel megtámaszkodik az ásóján, és sokáig nézi a sírokat.[/i]\n\n" \
		+ "Segíthetsz. Tudod, kik azok a csontvázak odalent? Ők a mieink. Akiket nem tudtunk felhozni. " \
		+ "A testüket elvitte a Mélység, és most céltalanul járnak a sötétben, mert senki nem temette el őket.\n\n" \
		+ "Pusztíts el közülük [b]ötvenet[/b]. Nem gyilkosság ez, hidd el: megváltás. Minden csont, ami " \
		+ "széthullik, egy lélek, ami végre hazatalál.\n\n" \
		+ "[i]Felveszi az ásóját.[/i]\n\nÉn addig átmegyek a régi kápolnába, itt a temető mellett. Túl rég " \
		+ "állt üresen. Ott keress, ha végeztél.\n\n" \
		+ "[color=#7a4a10](Új küldetés a J könyvben, a \"Csontváz sírásó\" fülön.)[/color]"


## Az 50 csontváz után: jutalom, a története, és a Szent keresztet kéri.
static func _finish_skeletons() -> String:
	Progress.set_npc_quest(SKELETON_QUEST, "done")
	Progress.add_camp_gold(SKELETON_GOLD)
	Progress.change_trust(ID, 20)
	Progress.set_npc_quest(CROSS_QUEST, "active")
	Progress.save_game()
	Audio.play("level_up")
	return "[i]Vendel lehunyja a szemgödreit. A kápolna hűvös levegője mintha egy pillanatra megmozdulna, " \
		+ "és a gyertyák lángja egyszerre lehajlik.[/i]\n\n" \
		+ "Érzem őket. Ötven lélek... hazaértek. Köszönöm. Fogd, ez a tiéd. " \
		+ "[color=#7a4a10](+%d tábori arany)[/color]\n\n" % SKELETON_GOLD \
		+ "[i]Leül az egyik poros padra, és az ásóját a térdére fekteti.[/i]\n\n" \
		+ "Elmondom, hogy kerültem ide. Húsz éve ebben a kápolnában szolgált Ambrus atya. Én voltam a " \
		+ "harangozója, mielőtt kalandornak álltam. Amikor lementem, Ambrus a nyakamba akasztotta a " \
		+ "kápolna keresztjét: \"Ez hazahoz, fiam.\"\n\n" \
		+ "A tizenkettedik emeleten a lich letépte rólam. Aztán megérintett. A kereszt nélkül nem haltam " \
		+ "meg, de élni sem tudtam tovább: csak a csontjaim jöttek haza. Ambrus atya akkor már nem élt. " \
		+ "Én temettem el, itt, a kápolna mellett.\n\n" \
		+ "[i]Feláll, és az üres falra néz az oltár fölött.[/i]\n\n" \
		+ "A kereszt azóta is hiányzik onnan. Ha a Mélységben valaha rátalálsz egy [b]Szent kereszt[/b] " \
		+ "amulettre, hozd el nekem. Nem lesz ugyanaz... de egy kereszt az kereszt. Újra megáldhatnám " \
		+ "vele a halottainkat.\n\n" \
		+ "[color=#7a4a10](Új küldetés a J könyvben.)[/color]"


static func is_cross(item: Variant) -> bool:
	return item is Dictionary and item.get("id", "") == CROSS_ID


static func has_cross(inventory: Inventory) -> bool:
	for item: Variant in inventory.bag:
		if is_cross(item):
			return true
	return false


static func _give_cross(inventory: Inventory) -> String:
	for i in inventory.bag.size():
		if is_cross(inventory.bag[i]):
			inventory.take_from_bag(i)
			Progress.set_npc_quest(CROSS_QUEST, "done")
			Progress.add_camp_gold(CROSS_GOLD)
			Progress.change_trust(ID, 30)
			Progress.save_game()
			Audio.play("level_up")
			return "[i]Vendel két csontujja közé fogja a keresztet, és a fény felé tartja. Aztán lassan " \
				+ "az oltárhoz lép, és felakasztja a fal szögére, ahol egykor a régi függött.[/i]\n\n" \
				+ "Ambrus atya... nézd. Újra van keresztünk.\n\n" \
				+ "[i]A szemgödreiben a fény melegebb lesz, szinte aranyszínű.[/i]\n\n" \
				+ "Köszönöm, vándor. Fogadd el ezt, és az áldásomat is. Akárhová visz a Mélység, a neved " \
				+ "itt mindig hazatalál. [color=#7a4a10](+%d tábori arany)[/color]" % CROSS_GOLD
	return "Hm? Nem látom nálad a keresztet."


static func frames() -> SpriteFrames:
	var result := SpriteFrames.new()
	result.set_animation_speed("default", 2.0)
	for i in 4:
		var frame := AtlasTexture.new()
		frame.atlas = SHEET
		frame.region = Rect2(i * 24, 0, 24, 32)
		result.add_frame("default", frame)
	return result


static func portrait() -> AtlasTexture:
	var face := AtlasTexture.new()
	face.atlas = SHEET
	face.region = Rect2(0, 0, 24, 32)
	return face


## A figura (ásóval) egy tartó alá: a lába a tartó origójában.
static func build_figure(holder: Node2D) -> AnimatedSprite2D:
	var digger := AnimatedSprite2D.new()
	digger.sprite_frames = frames()
	digger.scale = Vector2(2, 2)
	digger.offset = Vector2(0, -16)
	digger.play()
	holder.add_child(digger)
	# A letöltött ásó: a jobb oldalán, a földbe szúrva, a nyele a keze felé dől.
	var shovel := Sprite2D.new()
	shovel.texture = SHOVEL
	shovel.position = Vector2(14, -18)
	shovel.rotation = -0.45
	shovel.scale = Vector2(1.4, 1.4)
	holder.add_child(shovel)
	return digger
