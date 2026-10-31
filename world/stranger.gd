class_name Stranger
## A kútba esett idegen a nyugati tisztáson, a romos ház mellett (lásd Ruin). Amíg nem mondja
## meg a nevét, "???" a neve. A "Hogy kerültél oda le?" kérdésre létrát kér (a J könyv
## "Kutas idegen" fülén); a létra a tisztás délnyugati sarkában hever a fűben, egy bokor mögött
## (Lőrinc nem árulja el, hol). A megmentése után a kútba le lehet mászni (lásd WellCave).

const ID := "stranger"
const UNKNOWN_NAME := "???"
const REAL_NAME := "Lőrinc"
const LADDER_QUEST := "well_ladder"
## Belső jelző (Progress.npc_quests): a létrát felvetted ("done").
const LADDER_FOUND := "well_ladder_found"
const LADDER_ID := "well_ladder"
const REWARD_GOLD := 120
## A figurája a 0x72 lapról (wizzard_m: öreg, köpenyes tudós), és a sötét sziluettje.
const FIGURE := Rect2(128, 164, 16, 28)
const SILHOUETTE: Texture2D = preload("res://assets/characters/stranger_silhouette.png")

const GREETING := "[i]A kút mélyéről halk, rekedt hang szól fel.[/i]\n\nHé! Van ott fent valaki? " \
	+ "[b]Segíts, kérlek![/b] Itt vagyok lent, a kút alján!"
const RESCUED_GREETING := "[i]Lőrinc a kút kávájának dőlve rajzolgat valamit egy gyűrött papírra.[/i]\n\n" \
	+ "Á, a megmentőm! Gyere, nézd: a kút alatti járatokat rajzolom fel."

const QUESTS := {
	OldEntrance.QUEST: {"name": "A legrégebbi bejárat",
		"text": "Lőrinc műhelyében, a kút alatt, egy olajozott rács zár el egy lefelé vezető lépcsőt. Lőrinc szerint "
			+ "ez a Mélység legrégebbi bejárata, és valaki háromszáz éve őrzi. Lőrinc kinyitotta a rácsot: menj le "
			+ "a lépcsőn (%d emelet), és győzd le, ami a legalján vár." % OldEntrance.RUN_FLOORS,
		"reward": "Az Őrző kulcsa (egyedi legendás talizmán) és %d tábori arany" % OldEntrance.GOLD,
		"doing": "menj le a műhely rácsos lépcsőjén, és győzd le az Őrzőt",
		"doing_slain": "mondd el Lőrincnek, mi volt a rács alatt (ha a kocsmába költözött: tedd vissza a kulcsot a műhely asztalára)",
		"done": "az Őrző nyugszik"},
	LADDER_QUEST: {"name": "Létra a kútba",
		"text": "A romos ház melletti kút aljáról egy idegen kér segítséget: leszakadt alatta a kötél, "
			+ "és nem tud kimászni. Keress neki valahonnan egy [b]létrát[/b], és engedd le neki a kútba.",
		"reward": "%d tábori arany (és Lőrinc hálája)" % REWARD_GOLD,
		"doing": "keress valahol egy létrát", "doing_carrying": "vidd a létrát a kúthoz",
		"done": "Lőrinc kijutott a kútból"},
	TALISMAN_QUEST: {"name": "A varázsló fókusza",
		"text": "Lőrinc bevallotta, hogy nem csak térképész: varázsló, aki a térképeit varázslattal "
			+ "rajzolja. A régi fókuszköve a kútban maradt, és nélküle a varázslatai szétfolynak. "
			+ "Hozz neki egy [b]epikus talizmánt[/b] (bármilyet, a táskádban legyen).",
		"reward": "%d tábori arany (és Lőrinc tudása)" % TALISMAN_GOLD,
		"doing": "vigyél Lőrincnek egy epikus talizmánt", "done": "Lőrinc újra varázsol"},
	PHOENIX_QUEST: {"name": "A főnix tolla",
		"text": "Lőrinc tűzgolyót lőtt az új talizmánjával, de azt mondja, ez még semmi. Az igazi "
			+ "varázslatához egy [b]Főnixtoll[/b] kell (legendás talizmán). Ha a Mélységben rátalálsz, "
			+ "vidd el neki a kúthoz (a táskádban legyen).",
		"reward": "Lőrinc bizalma", "doing": "vigyél Lőrincnek egy Főnixtollat", "done": "a toll Lőrincnél"},
	ROYAL_LETTER_QUEST: {"name": "Levél a királynak",
		"text": "Lőrinc egy [b]aranypecsétes levelet[/b] bízott rád: vidd el a királynak a királyi várba "
			+ "(a táskádban legyen), aztán mondd el Lőrincnek, hogy célba ért.",
		"reward": "%d tábori arany a királytól" % ROYAL_LETTER_GOLD,
		"doing": "vidd el a levelet a királynak", "doing_delivered": "mondd el Lőrincnek",
		"done": "Lőrinc a kocsmába költözött"},
}
## A harmadik kérés: a talizmán után Lőrinc tűzgolyót lő (FIREBALL_FLAG), aztán Főnixtollat kér.
const FIREBALL_FLAG := "well_fireball"
const PHOENIX_QUEST := "well_phoenix"
const PHOENIX_ID := "trinket_phoenix"
## A negyedik: aranypecsétes levél a királynak; utána Lőrinc a kocsmába költözik (TAVERN_FLAG).
const ROYAL_LETTER_QUEST := "well_royal_letter"
const ROYAL_LETTER_ID := "royal_letter"
const ROYAL_LETTER_GOLD := 150
const TAVERN_FLAG := "lorinc_tavern"
## A második kérés (a megmentése után): egy epikus talizmán, mert varázsló.
const TALISMAN_QUEST := "well_talisman"
const TALISMAN_GOLD := 200
## A rács alatti lépcső (OldEntrance) közben: Lőrinc tanácsa.
const ENTRANCE_HINT := "[i]Lőrinc a rézkulcsot forgatja a kezében.[/i]\n\nA rács a műhelyem hátsó falánál van, " \
	+ "a kút alatti járat végén. Odalent minden emelet régebbi a fentieknél, és a legalján vár az őr. Ha " \
	+ "kalapácsolást hallasz, közel vagy.\n\nÉs ha nem tetszik, ami lent van, gyere fel. A lépcső nem fut el."
## Az Őrző után: 3 új történet.
const ENTRANCE_STORIES: Array[Dictionary] = [
	{"id": "keeper_who", "text": "Ki volt az Őrző?", "trust": 3,
		"answer": "[i]Lőrinc kiterít egy foltos pergament: egy pajzsos lovag rajza, alatta régi írás.[/i]\n\n" \
			+ "Gellért. Aurél király fegyvernöke. A krónika szerint a király a legelső kapuhoz állította, mielőtt a " \
			+ "tábort felépítette volna, és megesküdtette, hogy senki sem megy át rajta a király engedélye nélkül.\n\n" \
			+ "A király meghalt. Az eskü nem. A Mélység pedig megtartotta Gellértet, ahogy mindent megtart, ami " \
			+ "elég sokáig marad lent."},
	{"id": "keeper_door", "text": "Miért volt ez a legrégebbi bejárat?", "trust": 2,
		"answer": "Mert a falu kútja volt az első lyuk, amin a Mélység kilélegzett. Holló Margit is mondta, " \
			+ "hogy a kútnak egyszer csak nem lett alja. Aurél ezen a kúton ment le először, és ide állította az " \
			+ "őrt.\n\nA tábor lépcsőjét csak később ásták, amikor kiderült, hogy a kút szűk a sereghez. A " \
			+ "térképek szerint a két út a Mélység felső szintjein találkozik. Szóval eddig is ott jártál, csak " \
			+ "a hátsó ajtón."},
	{"id": "keeper_key", "text": "Mit csináljak az Őrző kulcsával?", "trust": 3,
		"answer": "[i]Elmosolyodik.[/i]\n\nViseld. Háromszáz évig egy hűséges ember övén lógott, aki soha " \
			+ "nem hagyta el a posztját. Az ilyen tárgy emlékszik. Nem enged meghátrálni, de el sem enged " \
			+ "esni.\n\nÉs ha egyszer újra kalapácsolást hallasz a kút alól... az már csak a visszhang lesz. " \
			+ "Remélem."},
]
## A kút alatti járat felrobbantása után (Blaster.WELL_QUEST, WellCave): a régi műhelyéről.
const WELL_STORIES: Array[Dictionary] = [
	{"id": "workshop", "text": "Megtaláltam a műhelyedet a kút alatt.", "trust": 4,
		"answer": "[i]Lőrinc elsápad, aztán felnevet.[/i]\n\n" \
			+ "Szóval Döme tényleg felrobbantotta! Tóbiás mondta, hogy odalent dörgött, de azt hittem, megint a " \
			+ "hordói.\n\nIgen, az az enyém volt. Mielőtt a kútba estem, hetekig ott dolgoztam. Királyi térképész " \
			+ "voltam, mielőtt varázsló lettem. Vagyis közben. Az ember sok mindent csinál, ha senki nem figyel rá."},
	{"id": "compass", "text": "Mi ez az iránytű?", "trust": 3,
		"answer": "Az apámé volt. Nem északra mutat, hanem lefelé: a legközelebbi lépcső felé. Apám azt mondta, " \
			+ "a Mélységben észak nem számít, csak az, merre van a kijárat. Vagy a bejárat. Attól függ, melyik irányba " \
			+ "mész.\n\nTartsd meg. Nekem már nincs rá szükségem. Én már tudom, merre van lefelé. Egyszer leestem."},
	{"id": "grate", "text": "Mi van a rácsos lépcső mögött?", "trust": 5,
		"answer": "[i]Sokáig hallgat.[/i]\n\n" \
			+ "Nem tudom. Azt hiszem, a legrégebbi út le. Régebbi a tábor lépcsőjénél, régebbi a bányánál. A rácsot " \
			+ "nem én tettem oda, és nem is a király emberei.\n\nValaki olajozza a zárat. Láttam a friss olajcseppeket. " \
			+ "És néha, ha az ember elég sokáig ül csendben odalent, kopogást hall. Nem a kőből. Az ajtó túloldaláról."},
]


## A neve: "???", amíg meg nem kérdezed.
static func display_name() -> String:
	return REAL_NAME if Progress.asked_topics(ID).has("name") else UNKNOWN_NAME


static func greeting() -> String:
	return RESCUED_GREETING if Progress.npc_quest_state(LADDER_QUEST) == "done" else GREETING


static func options(inventory: Inventory) -> Array[Dictionary]:
	var list: Array[Dictionary] = [
		{"id": "name", "text": "Mi a neved?", "on_choose": func() -> String: return _ask_name()},
		{"id": "how", "text": "Hogy kerültél oda le?", "on_choose": func() -> String: return _ask_how()},
		{"id": "who", "text": "Ki vagy te?", "on_choose": func() -> String: return _ask_who()},
	]
	if Progress.npc_quest_state(LADDER_QUEST) in ["active", "carrying"] and has_ladder(inventory):
		list.append({"id": "ladder", "text": "Hoztam egy létrát! (leengeded a kútba)",
			"on_choose": func() -> String: return _give_ladder(inventory)})
	if is_rescued():
		match Progress.npc_quest_state(TALISMAN_QUEST):
			"":
				list.append({"id": "next", "text": "Mihez kezdesz most?",
					"on_choose": func() -> String: return _reveal_wizard()})
			"active":
				list.append({"id": "talisman", "text": "Hoztam egy epikus talizmánt.",
					"on_choose": func() -> String: return _give_talisman(inventory)})
			"done":
				list.append({"id": "magic", "text": "Mutass egy varázslatot!",
					"on_choose": func() -> String: return _show_magic()})
	if Progress.npc_quest_state(FIREBALL_FLAG) == "done":
		match Progress.npc_quest_state(PHOENIX_QUEST):
			"":
				list.append({"id": "fireball", "text": "Mi volt ez a tűzgolyó?!",
					"on_choose": func() -> String: return _ask_phoenix()})
			"active":
				list.append({"id": "phoenix", "text": "Hoztam egy Főnixtollat.",
					"on_choose": func() -> String: return _give_phoenix(inventory)})
	if is_rescued() and Blaster.well_open():
		list.append_array(WELL_STORIES)
	if OldEntrance.available():
		match Progress.npc_quest_state(OldEntrance.QUEST):
			"":
				list.append({"id": "entrance", "text": "Mi van a műhelyed rácsa mögött?",
					"on_choose": func() -> String: return _ask_entrance()})
			"active":
				list.append({"id": "entrance_wait", "text": "Mit tudsz még a rács mögötti lépcsőről?",
					"on_choose": func() -> String: return ENTRANCE_HINT})
			"slain":
				list.append({"id": "entrance_done", "text": "Legyőztem az Őrzőt a rács alatt.",
					"on_choose": func() -> String: return _finish_entrance()})
			"done":
				list.append_array(ENTRANCE_STORIES)
	match Progress.npc_quest_state(ROYAL_LETTER_QUEST):
		"active":
			list.append({"id": "lost_royal_letter", "text": "Elvesztettem a levelet...",
				"on_choose": func() -> String: return _lost_royal_letter(inventory)})
		"delivered":
			list.append({"id": "royal_delivered", "text": "Átadtam a levelet a királynak.",
				"on_choose": func() -> String: return _royal_letter_delivered()})
	return list


## A talizmán után (a beszélgetés bezárásakor a Ruin lövi ki a tűzgolyót): rákérdezel, és Főnixtollat kér.
static func _ask_phoenix() -> String:
	Progress.mark_asked(ID, "fireball")
	Progress.set_npc_quest(PHOENIX_QUEST, "active")
	Progress.save_game()
	return "[i]Lőrinc fújja a tenyerét, mint aki forró kását fogott meg, de mosolyog.[/i]\n\n" \
		+ "Szép volt, ugye? Pedig ez semmi. Egy kis szikra. A régi mesterek tűzből egész hidakat " \
		+ "építettek, és a lángjuk nem aludt ki, akárhány évig égett.\n\n" \
		+ "Ehhez azonban több kell egy talizmánnál. Egy [b]Főnixtoll[/b] kell. A főnix lángja nem éget " \
		+ "el semmit, amit a gazdája nem akar elégetni... és sosem alszik ki.\n\n" \
		+ "Ha egyszer a Mélységben rátalálsz egy ilyen tollra, hozd el nekem. Tudom, nagy kérés. " \
		+ "De megéri, meglátod."


static func _give_phoenix(inventory: Inventory) -> String:
	for i in inventory.bag.size():
		var item: Variant = inventory.bag[i]
		if item is Dictionary and item.get("id", "") == PHOENIX_ID:
			inventory.take_from_bag(i)
			Progress.set_npc_quest(PHOENIX_QUEST, "done")
			Progress.mark_asked(ID, "phoenix")
			Progress.change_trust(ID, 30)
			Audio.play("level_up")
			return "[i]A tollat a tenyerére fekteti. A toll lassan felizzik, és apró, aranyszínű lángok " \
				+ "táncolnak rajta, de a bőrét nem égetik meg.[/i]\n\n" \
				+ "Él... még mindig él benne a tűz. Tudod, mit hoztál nekem? Ezzel a tollal újra minden " \
				+ "eszembe jut. A tűz, a jég, a kő szava, a csillagok térképe... Rengeteg mágiát tudtam " \
				+ "valaha, és most mind visszajön, mint egy elfelejtett dal.\n\n" \
				+ "[i]Elkomolyodik, és a köpenye alól egy aranypecsétes levelet húz elő.[/i]\n\n" \
				+ "Volna még egy utolsó szívességem. Ezt a levelet vidd el [b]a királynak[/b]. Ne nyisd fel. " \
				+ "Tizenkét éve tartozom neki egy magyarázattal, és most végre meg tudom adni.\n\n" \
				+ _ask_royal_letter(inventory)
	Audio.play("ui_error")
	return "[i]Végignéz a táskádon.[/i]\n\nNem látok Főnixtollat. Csak az jó, semmi más: [b]Főnixtoll[/b]."


## Az aranypecsétes levél: küldetéstárgy a táskába (ha tele van, a tábori ládába).
static func royal_letter() -> Dictionary:
	return {"id": ROYAL_LETTER_ID, "name": "Aranypecsétes levél", "slot": "quest", "rarity": "epic", "stats": {},
		"price": 0, "quest": true, "icon_path": "res://assets/items/royal_letter.png",
		"description": "Lőrinc levele a királynak. Arany viaszpecsét zárja, rajta egy csillag és egy iránytű."}


static func is_royal_letter(item: Variant) -> bool:
	return item is Dictionary and item.get("id", "") == ROYAL_LETTER_ID


static func has_royal_letter(inventory: Inventory) -> bool:
	for item: Variant in inventory.bag:
		if is_royal_letter(item):
			return true
	for item: Variant in Progress.stash:
		if is_royal_letter(item):
			return true
	return false


## Hol a levél: "bag" (táska), "stash" (tábori láda) vagy "" (sehol).
static func royal_letter_place(inventory: Inventory) -> String:
	for item: Variant in inventory.bag:
		if is_royal_letter(item):
			return "bag"
	for item: Variant in Progress.stash:
		if is_royal_letter(item):
			return "stash"
	return ""


## "Elvesztettem a levelet": ha megvan (táska / tábori láda), megmondja, hol; ha nincs, újat ír.
static func _lost_royal_letter(inventory: Inventory) -> String:
	match royal_letter_place(inventory):
		"bag":
			return "[i]Felvonja a szemöldökét, és a táskád felé biccent.[/i]\n\n" \
				+ "Elvesztetted? Ott lapul a [b]táskádban[/b], barátom, a többi holmid között. Az aranypecsét " \
				+ "messziről csillog."
		"stash":
			return "[i]Elneveti magát.[/i]\n\n" \
				+ "Nem vesztetted el, csak eltetted. A [b]tábori ládádban[/b] van. Vedd ki, mielőtt a " \
				+ "királyhoz indulsz."
	return "[i]Felsóhajt, és új lapot vesz elő.[/i]\n\nSzerencse, hogy fejből tudom.\n\n" + _hand_royal_letter(inventory)


static func _ask_royal_letter(inventory: Inventory) -> String:
	Progress.set_npc_quest(ROYAL_LETTER_QUEST, "active")
	return _hand_royal_letter(inventory)


static func _hand_royal_letter(inventory: Inventory) -> String:
	var where := "a táskádba"
	if inventory.is_bag_full():
		Progress.add_to_stash(royal_letter())
		where = "a tábori ládába (tele volt a táskád)"
	else:
		inventory.add_item(royal_letter())
	Progress.save_game()
	return "[color=#7a4a10](Az aranypecsétes levél %s került.)[/color]" % where


## A királynál (King hívja): átveszi a levelet a táskából, és fizet érte. "" ha nincs nálad.
static func deliver_to_king(inventory: Inventory) -> String:
	for i in inventory.bag.size():
		if is_royal_letter(inventory.bag[i]):
			inventory.take_from_bag(i)
			Progress.set_npc_quest(ROYAL_LETTER_QUEST, "delivered")
			Progress.camp_gold += ROYAL_LETTER_GOLD
			Progress.save_game()
			Audio.play("coin")
			return "[i]A király feltöri az aranypecsétet, és olvasni kezd. Az arca megkeményedik, aztán " \
				+ "lassan ellágyul.[/i]\n\n" \
				+ "Lőrinc... a térképészem. Azt hittem, ő is odalent maradt a többiekkel. Tizenkét éve várok " \
				+ "erre a levélre, és nem is tudtam róla.\n\n" \
				+ "[i]Összehajtja a levelet, és a keblébe teszi.[/i]\n\n" \
				+ "Mondd meg neki, hogy nincs mit megbocsátanom. És hogy a kocsmában mindig lesz számára hely. " \
				+ "Fogadd el ezt a fáradságodért.\n\n" \
				+ "[color=#7a4a10](+%d tábori arany)[/color]" % ROYAL_LETTER_GOLD
	return ""


## A levél célba ért: Lőrinc megköszöni a segítséget, és a kocsmába költözik.
static func _royal_letter_delivered() -> String:
	Progress.set_npc_quest(ROYAL_LETTER_QUEST, "done")
	Progress.set_npc_quest(TAVERN_FLAG, "done")
	Progress.mark_asked(ID, "royal_delivered")
	Progress.change_trust(ID, 20)
	Progress.save_game()
	Audio.play("level_up")
	return "[i]Amikor meghallja, mit üzent a király, Lőrinc leül a kút kávájára, és egy darabig nem szól.[/i]\n\n" \
		+ "Nincs mit megbocsátania... Tizenkét évig bujkáltam előle a kutak és a járatok között. " \
		+ "Azt hittem, haragszik rám, amiért az én térképem vezette le őket.\n\n" \
		+ "[i]Feláll, és megszorítja a kezed.[/i]\n\n" \
		+ "Köszönöm. Mindent. A létrát, a talizmánt, a tollat, a levelet. Kihúztál egy kútból, és " \
		+ "aztán valahogy az egész életemből is.\n\n" \
		+ "Lemegyek a [b]kocsmába[/b]. Ideje, hogy újra emberek között legyek. Ha egyszer szükséged lesz " \
		+ "egy öreg varázslóra odalent... ott megtalálsz.\n\n" \
		+ "[color=#7a4a10](Lőrinc a kocsmába költözött: mostantól játszható karakter, a kocsmában válthatsz rá.)[/color]"


## Elment a kocsmába (a kút mellől eltűnik).
static func moved_to_tavern() -> bool:
	return Progress.npc_quest_state(TAVERN_FLAG) == "done"


## Bevallja, hogy varázsló, és egy epikus talizmánt kér (fókusznak).
static func _reveal_wizard() -> String:
	Progress.mark_asked(ID, "next")
	Progress.set_npc_quest(TALISMAN_QUEST, "active")
	Progress.save_game()
	return "[i]Körülnéz, mintha attól tartana, hogy valaki hallgatózik, aztán lehalkítja a hangját.[/i]\n\n" \
		+ "Elárulok neked valamit, mert megmentetted az életem. Nem csak térképész vagyok. [b]Varázsló[/b] " \
		+ "vagyok. A térképeimet nem tintával rajzolom: a kő emlékszik, merre vezetnek a járatai, és én " \
		+ "megkérdezem tőle.\n\n" \
		+ "[i]Kinyitja a tenyerét: egy halvány fényfolt villan fel benne, aztán szétfoszlik.[/i]\n\n" \
		+ "Látod? Szétfolyik. A fókuszkövem odalent maradt a kút alján, a víz elmosta. Fókusz nélkül egy " \
		+ "varázsló csak egy öregember, aki furcsa szavakat motyog.\n\n" \
		+ "Hozz nekem egy [b]epikus talizmánt[/b]. Bármilyet: kristályt, szemet, fogat, a lényeg, hogy " \
		+ "erős legyen benne az erő. A Mélységben akad ilyen, ha elég mélyre mész."


static func _give_talisman(inventory: Inventory) -> String:
	for i in inventory.bag.size():
		var item: Variant = inventory.bag[i]
		if item is Dictionary and item.get("slot", "") == "trinket" and item.get("rarity", "") == "epic":
			inventory.take_from_bag(i)
			Progress.set_npc_quest(TALISMAN_QUEST, "done")
			# A beszélgetés bezárása után tűzgolyót lő (lásd Ruin).
			Progress.set_npc_quest(FIREBALL_FLAG, "pending")
			Progress.mark_asked(ID, "talisman")
			Progress.change_trust(ID, 25)
			Progress.camp_gold += TALISMAN_GOLD
			Progress.save_game()
			Audio.play("level_up")
			return "[i]Két kézzel veszi át a(z) %s, és sokáig hallgatja, mintha beszélne hozzá.[/i]\n\n" % item["name"] \
				+ "Igen... ez az. Érzed? Zümmög.\n\n" \
				+ "[i]Suttog valamit. A levegő megremeg körülöttetek, és a kút kávája halványkék fényben izzik " \
				+ "fel egy pillanatra.[/i]\n\n" \
				+ "Visszajött. Évek óta nem éreztem ilyen tisztán a követ. Köszönöm, barátom. Fogadd el ezt; " \
				+ "és ha egyszer újra lemész a kút alá, figyeld a falakat. Lehet, hogy most már mást is mutatnak.\n\n" \
				+ "[color=#7a4a10](+%d tábori arany)[/color]" % TALISMAN_GOLD
	Audio.play("ui_error")
	return "[i]Végignéz a táskádon, aztán szomorúan megrázza a fejét.[/i]\n\n" \
		+ "Nem érzem benne az erőt. [b]Epikus talizmán[/b] kell, és a táskádban legyen."


static func _show_magic() -> String:
	return show_magic_intro()


## A varázslat-bemutató eleje (a beszélgetés utána magától bezárul, lásd Ruin).
static func show_magic_intro() -> String:
	Progress.mark_asked(ID, "magic")
	return "[i]Lőrinc hátrébb lép, és a magasba emeli a talizmánt. A szemében apró lángok gyúlnak.[/i]\n\n" \
		+ "Állj egy kicsit odébb, barátom... és figyelj!"


## A bemutató után, amikor a beszélgetés újra megnyílik.
static func show_magic_after(first: bool) -> String:
	if first:
		return "[i]Lőrinc elégedetten fújja meg a füstölgő tenyerét.[/i]\n\n" \
			+ "Na? Évek óta nem sikerült ilyen tisztán. A talizmánod... él. Érzem, ahogy ég benne az erő."
	return "[i]Lőrinc leporolja a köpenyét, a talizmán még halványan izzik a kezében.[/i]\n\n" \
		+ "Ennyi elég is mára, mielőtt felgyújtom az egész tisztást. A romos ház már így is eleget szenvedett."


static func _ask_name() -> String:
	Progress.mark_asked(ID, "name")
	if Progress.npc_quest_state(LADDER_QUEST) == "done":
		return "Lőrinc vagyok, ahogy már mondtam. Királyi térképész. Vagy legalábbis az voltam, mielőtt " \
			+ "három napot egy kút alján töltöttem."
	return "[i]Köhög egyet, a hangja visszhangzik a kőfalakon.[/i]\n\n[b]Lőrinc[/b]. Lőrinc vagyok. " \
		+ "És hidd el, sosem gondoltam, hogy egyszer egy kút aljáról kell bemutatkoznom."


static func _ask_how() -> String:
	Progress.mark_asked(ID, "how")
	match Progress.npc_quest_state(LADDER_QUEST):
		"done":
			return "Ne is emlékeztess rá. A kötél elszakadt, én meg zuhantam. Szerencsére víz volt alattam... " \
				+ "meg egy csomó csiga."
		"active", "carrying":
			return "[i]Felsóhajt.[/i]\n\nMint mondtam: elszakadt a kötél. Kérlek, keress valahol egy " \
				+ "[b]létrát[/b]! Akármilyet, csak bírjon el."
	Progress.set_npc_quest(LADDER_QUEST, "active")
	Progress.save_game()
	return "[i]Hosszan hallgat, aztán megszólal.[/i]\n\nKötélen ereszkedtem le, hogy feltérképezzem a kút " \
		+ "alját. Azt beszélik, a falában egy régi járat nyílik, ami egészen a Mélységig vezet. Igaz is: ott " \
		+ "van, csak éppen be van omolva. Amikor vissza akartam mászni, a kötél elszakadt.\n\n" \
		+ "Három napja vagyok itt lent. Kiabáltam, de errefelé senki nem jár.\n\n" \
		+ "[i]A hangja elcsuklik.[/i]\n\nKérlek... szerezz nekem valahonnan egy [b]létrát[/b]. Hozd ide, " \
		+ "és engedd le. Nem tudom, hol találsz, de nélküle innen nem jutok ki."


static func _ask_who() -> String:
	Progress.mark_asked(ID, "who")
	return "A király térképésze vagyok. Vagyis... az voltam. Tizenkét éve én rajzoltam meg a Mélység első " \
		+ "tíz emeletének térképét a király seregének. Gáspár kapitány embereinek.\n\n" \
		+ "[i]Elhallgat.[/i]\n\nAz én térképem vitte le őket a halálba. Azóta minden régi kutat és járatot " \
		+ "feltérképezek, hátha találok egy másik utat lefelé. Egy biztonságosabbat."


## A létra: küldetéstárgy (nem vehető fel, nem adható el).
static func ladder() -> Dictionary:
	return {"id": LADDER_ID, "name": "Régi létra", "slot": "quest", "rarity": "common", "stats": {},
		"price": 0, "quest": true, "icon_path": "res://assets/props/ladder.png",
		"description": "Kicsit korhadt, de elbír egy embert. A kútba lógó idegennek kell."}


static func is_ladder(item: Variant) -> bool:
	return item is Dictionary and item.get("id", "") == LADDER_ID


static func has_ladder(inventory: Inventory) -> bool:
	for item: Variant in inventory.bag:
		if is_ladder(item):
			return true
	for item: Variant in Progress.stash:
		if is_ladder(item):
			return true
	return false


## A fűben heverő létra felvétele: a táskába (ha tele van, a tábori ládába). Visszaadja, hová került.
static func pick_up_ladder(inventory: Inventory) -> String:
	Progress.set_npc_quest(LADDER_FOUND, "done")
	if Progress.npc_quest_state(LADDER_QUEST) == "active":
		Progress.set_npc_quest(LADDER_QUEST, "carrying")
	var where := "a táskádba"
	if inventory.is_bag_full():
		Progress.add_to_stash(ladder())
		where = "a tábori ládába (tele volt a táskád)"
	else:
		inventory.add_item(ladder())
	Progress.save_game()
	return where


static func _give_ladder(inventory: Inventory) -> String:
	var removed := false
	for i in inventory.bag.size():
		if is_ladder(inventory.bag[i]):
			inventory.take_from_bag(i)
			removed = true
			break
	if not removed:
		for i in Progress.stash.size():
			if is_ladder(Progress.stash[i]):
				Progress.stash.remove_at(i)
				break
	Progress.set_npc_quest(LADDER_QUEST, "done")
	Progress.mark_asked(ID, "ladder")
	Progress.change_trust(ID, 30)
	Progress.camp_gold += REWARD_GOLD
	Progress.save_game()
	Audio.play("level_up")
	return "[i]Leengeded a létrát. Hosszú percekig csak a nyikorgását hallod, aztán egy sovány, kormos " \
		+ "arcú férfi bukkan fel a kút peremén, és a fűbe zuhan.[/i]\n\n" \
		+ "Ég... igazi ég. Azt hittem, soha többé nem látom.\n\n" \
		+ "[i]Feltápászkodik, és megszorítja a kezed.[/i]\n\n" \
		+ "Köszönöm. Nincs sok mindenem, de ezt fogadd el. És ha egyszer lejutsz oda, ahová én sosem " \
		+ "mertem, gondolj rám: a kút alatti járat is a Mélységbe vezet. Egyszer kiássuk.\n\n" \
		+ "[i]Visszanéz a kút sötét szájára.[/i]\n\n" \
		+ "Most, hogy itt a létra, menj le, és nézz körül odalent. Hátha találsz valami izgalmasat. " \
		+ "Én húsz évig csak a falakat bámultam.\n\n" \
		+ "[color=#7a4a10](+%d tábori arany)[/color]" % REWARD_GOLD


## Kijutott a kútból (onnantól a kút mellett áll).
static func _ask_entrance() -> String:
	Progress.set_npc_quest(OldEntrance.QUEST, "active")
	Progress.mark_asked(ID, "entrance")
	Progress.save_game()
	Audio.play("ui_open")
	return "[i]Lőrinc leteszi a térképet. Sokáig hallgat.[/i]\n\n" \
		+ "A rács. Hetekig néztem, mielőtt a kútba estem. Tudod, mi a furcsa? Nem rozsdás. Háromszáz éves vas, " \
		+ "és a lakatja olajos, mintha tegnap kenték volna. Éjjelente pedig odalentről kalapácsolás hallatszik. " \
		+ "Egyenletes, türelmes, mint aki javít valamit.\n\n" \
		+ "A királyi levéltárban találtam egy feljegyzést: I. Aurél, a tábor alapítója, \"őrt állított a legelső " \
		+ "kapuhoz, aki nem alszik és nem felejt\". Szerintem az az őr még mindig ott van.\n\n" \
		+ "[i]Elővesz egy kis, rézből reszelt kulcsot.[/i]\n\nAz iránytűm mutatta meg a lakat belsejét. Ezt " \
		+ "csináltam hozzá. Én nem merek lemenni. De te... te már a Mélység aljáig jártál. Nyisd ki.\n\n" \
		+ "[color=#7a4a10](Új küldetés a J könyvben. A rács a kút alatti műhelyben most nyitható.)[/color]"


static func _finish_entrance() -> String:
	# Az add_camp_gold újratölti a mentést: előbb az arany, aztán a többi változás.
	Progress.add_camp_gold(OldEntrance.GOLD)
	Progress.set_npc_quest(OldEntrance.QUEST, "done")
	Progress.mark_asked(ID, "entrance_done")
	Progress.change_trust(ID, 15)
	Progress.save_game()
	Audio.play("level_up")
	return "[i]Lőrinc tágra nyílt szemmel hallgatja, a toll megáll a kezében.[/i]\n\n" \
		+ "Egy páncélos lovag. Háromszáz évig. Egyedül, a sötétben, és olajozta a lakatot, hogy a kapu " \
		+ "rendben legyen, ha a király egyszer visszajön...\n\n" \
		+ "[i]Leveszi a kalapját.[/i]\n\nNem jött vissza senki. Csak te. Talán épp ezt várta: hogy valaki " \
		+ "végre leváltsa az őrségből. Fogadd el ezt az aranyat a térképész-céh nevében. Meg az enyémben." \
		+ "\n\n[color=#7a4a10](+%d tábori arany)[/color]" % OldEntrance.GOLD


static func is_rescued() -> bool:
	return Progress.npc_quest_state(LADDER_QUEST) == "done"


## A képe a beszélgetésben: amíg nem tudod a nevét, csak egy sötét sziluett.
static func portrait() -> Texture2D:
	var face := AtlasTexture.new()
	face.atlas = SpriteSheet.TEXTURE if display_name() == REAL_NAME else SILHOUETTE
	face.region = FIGURE if display_name() == REAL_NAME else Rect2(Vector2.ZERO, FIGURE.size)
	return face
