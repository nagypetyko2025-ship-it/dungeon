class_name TavernTalk
## Beszélgetés a kocsmában ülő karakterekkel (lásd Town): E-re beszélgetés nyílik, az első opció átveszi az
## irányítást (karakterváltás), a többi a karakter története. Az NPC-ből lett karakterek (Gáspár, Bence, Vendel,
## Lőrinc) a saját beszélgetésüket hozzák (ugyanazzal a bizalommal és pipákkal); a lovagnak és az íjásznak itt
## vannak a történetei.

const GREETINGS := {
	"knight": "[i]A lovag a kandalló mellett ül, a rozsdás kardját fenőkővel csiszolja.[/i]\n\n" \
		+ "Na, megint itt vagy. Iszunk egyet, vagy indulunk? Én bármelyikre kapható vagyok.",
	"archer": "[i]Az íjász a sarokasztalnál ül, előtte egy kupac toll és egy félkész nyílvessző.[/i]\n\n" \
		+ "Ülj le, csak ne lökd meg az asztalt. Ez a toll egy holló farkából van, nehezen adta.",
	"veteran": "[i]Gáspár a kupáját forgatja, és a tüzet nézi.[/i]\n\nKapitány nélkül is megy a sorakozó, mi? " \
		+ "Gyere, ülj le. Egy öreg katonának mindig jólesik egy kis beszélgetés.",
	"thief": "[i]Bence a széken hintázik, a lábát az asztalra teszi, amikor a kocsmáros nem néz oda.[/i]\n\n" \
		+ "Na, mi újság odalent? Vagy csak a borom miatt jöttél? Mert az nem eladó.",
	"wizard": "[i]Lőrinc egy kupa forralt bor fölött térképet rajzol. A tinta helyenként halványan világít.[/i]\n\n" \
		+ "Á, te vagy az! Ülj le egy kicsit. Vagy indulunk? A kövek ma különösen beszédesek.",
	"gravedigger": "[i]Vendel egyenesen ül a széken, az ásója a falnak támasztva. A kupája előtte, érintetlenül.[/i]\n\n" \
		+ "Inni már nem tudok. De a meleg jó. És a hangok. Húsz évig csak a szél beszélt hozzám.",
}

## A lovag és az íjász történetei (a többiek a saját beszélgetésüket hozzák, lásd options).
const STORIES := {
	"knight": [
		{"id": "guard", "text": "Miért hagytad ott a királyi őrséget?", "trust": 4,
			"answer": "[i]Leteszi a fenőkövet.[/i]\n\nA palotában a legveszélyesebb ellenfél egy részeg nemesúr volt, " \
				+ "aki elkérte a kardomat, hogy megmutassa, hogyan kell vívni. Közben tizenkét éve minden reggel " \
				+ "felolvasták a gyakorlótéren harminc ember nevét, akik lementek a Mélységbe, és nem jöttek vissza.\n\n" \
				+ "Egy reggel rájöttem, hogy én nem a falak mögött akarok megöregedni, miközben odalent valami " \
				+ "felfalta a legjobbjainkat."},
		{"id": "rusty", "text": "Miért egy rozsdás karddal indultál?", "trust": 2,
			"answer": "[i]Felnevet, és megforgatja a pengét a tűz fényében.[/i]\n\nAz őrség kardját le kellett adnom, " \
				+ "amikor kiléptem. Ezt Ambrus selejtjei között találtam. Azt mondta, jobb a semminél.\n\n" \
				+ "Igaza volt. Épp csak egy kicsit."},
		{"id": "secret", "text": "Mit keresel valójában odalent?", "trust": 3,
			"answer": "A választ. Hogy miért nyílt meg a Mélység, ki ásta a régi tárnákat, és mi kopog alattunk " \
				+ "éjjelente, amikor elcsendesedik a tábor.\n\n[i]Elhallgat, aztán halkabban folytatja.[/i]\n\n" \
				+ "És talán azt is, hogy ha a királyi őrség legjobbjai elestek, nekem miért sikerül még mindig " \
				+ "visszajönnöm. Szerencse? Vagy valami odalent azt akarja, hogy újra és újra lemenjek?"},
	],
	"archer": [
		{"id": "forest", "text": "Hogyan kerültél a táborba?", "trust": 4,
			"answer": "[i]A tollat a fény felé tartja, és az erezetét vizsgálja.[/i]\n\nAz erdő elnémult. Egy télen a " \
				+ "farkasok mind elmentek, egyik éjjelről a másikra. Követtem a nyomaikat: délnek tartottak, egyenesen " \
				+ "a Mélység felé. Mintha hívta volna őket valami.\n\nA nyomok a tábor lépcsőjénél értek véget."},
		{"id": "distance", "text": "Miért nem engeded közel a szörnyeket?", "trust": 2,
			"answer": "Anyám mondta: aki közel engedi magához a farkast, az már nem íjász, hanem vacsora.\n\n" \
				+ "[i]Elvigyorodik.[/i]\n\nAz erdőben ezt hamar megtanulja az ember. A Mélységben még hamarabb."},
		{"id": "wolf", "text": "Hallottad, hogy odalent egy farkas az úr?", "trust": 3,
			"answer": "[i]A keze megáll a nyílvesszőn.[/i]\n\nHallottam. Gáspár mesélt róla, amikor még a rönkön ült. " \
				+ "Egy farkas, ami állva jár, és ami a holtakból is felkel.\n\nAz erdő farkasai sosem bántottak. " \
				+ "Kikerültek, én is őket. Kíváncsi vagyok, ez is tisztel-e majd... vagy csak ő hívta le a többit."},
	],
}


## A beszélgetés NPC-azonosítója (a bizalom és a feltett kérdések ehhez tartoznak): a régi NPC-ké a sajátjuk.
static func npc_id(character: String) -> String:
	match character:
		"veteran": return Dialogues.VETERAN_ID
		"thief": return Thief.ID
		"wizard": return Stranger.ID
		"gravedigger": return Gravedigger.ID
	return character


## A karakter beszélgetési opciói a kocsmában (a karakterváltás nélkül; azt a Town teszi elé).
static func options(character: String, inventory: Inventory) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	match character:
		"veteran":
			list = Dialogues.veteran_options(inventory)
		"thief":
			list = Thief.options(inventory)
		"gravedigger":
			list = Gravedigger.options(inventory)
		"wizard":
			list = Stranger.tavern_options()
		_:
			list.assign(STORIES.get(character, []))
	return list
