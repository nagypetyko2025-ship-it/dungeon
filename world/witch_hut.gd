class_name WitchHut
extends Node2D
## Boszorkánykunyhó a nyugati tisztás alján (a romos ház alatt): sötét, mohos tetejű ház, az ablakában zöld
## derengés, a kéményéből zöldes füst, az ajtó fölött koponya; a sáros ösvényről sáros út vezet az ajtajáig.
## Bent egy üst rotyog a tűzön (zöld gőz), a falon polcok üvegcsékkel, a mennyezetről száradó füvek lógnak,
## gyertyák, koponyák, pókhálók. Az üst mellett áll Holló Margit, a boszorkány (E: beszélgetés):
## 5 történet, 5 küldetés egymás után (CHAIN, J könyv "Boszorkány" fül), mindegyik után 3 új történet; a 3. után a
## "Test manipulálása": a képességek végleges fejlesztése aranyért és porért (ui/witch_panel.gd, Progress.witch_*).
## A tábla a tábor nyugati szélén: "Boszorkány kunyhó", alatta a régi, kopott "Lakóház" (lásd Camp._build_witch_sign).
## (A tábor építi fel: setup(camp) + build(), mint a Romot.)

const TILE := 32
const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const POTTERY: Texture2D = preload("res://assets/shop/pottery.png")
const DUNGEON: Texture2D = preload("res://assets/0x72_dungeon/0x72_DungeonTilesetII_v1.7.png")
const COBWEB: Texture2D = preload("res://assets/decor/cobweb.png")
## Üst (simples-pimples "Various Containers", CC0) és a boszorkány (a 0x72 varázslónő átszínezve).
const CAULDRON: Texture2D = preload("res://assets/props/cauldron.png")
const WITCH_SHEET: Texture2D = preload("res://assets/props/witch.png")

## A kunyhó bal felső csempéje és mérete (a nyugati tisztás alján); az ajtó oszlopa.
const TOP_LEFT := Vector2i(-26, 25)
const SIZE := Vector2i(6, 5)
const DOOR_COLUMN := -24
## A sáros út oszlopai (a nyugati ösvénytől le, aztán nyugatra az ajtóig).
const PATH_COLUMN := -19
## Az első sor a sáros ösvény alatt (az ösvény a tábor ROAD_ROW / +1 sorában fut).
const PATH_START_ROW := 19
## A belső tér (a világ távoli részén, mint a többi ház belseje) és a bejárata.
const INTERIOR := Rect2i(570, 0, 12, 8)
const INTERIOR_DOOR := Vector2i(575, 8)
const CAULDRON_TILE := Vector2i(575, 4)
const WITCH_TILE := Vector2i(577, 3)
const HUT_LIGHT := Color(0.14, 0.11, 0.18)
const ROOF_TINT := Color(0.62, 0.72, 0.52)
const WALL_TINT := Color(0.45, 0.38, 0.42)
const BREW := Color(0.45, 1.0, 0.35)
const INTERACT_RANGE := 52.0
const WITCH_RANGE := 70.0
const LANTERN_INSIDE := 0.3
const LANTERN_OUTSIDE := 0.5
const SKULL := Rect2(288, 432, 16, 16)
const FLASKS: Array[Rect2] = [Rect2(320, 336, 16, 16), Rect2(304, 336, 16, 16), Rect2(288, 336, 16, 16),
	Rect2(320, 352, 16, 16), Rect2(336, 352, 16, 16)]
const FLOOR_TILES: Array[Vector2i] = [Vector2i(8, 2), Vector2i(8, 3)]

const WITCH_ID := "witch"
const WITCH_NAME := "Holló Margit, a boszorkány"
const WITCH_GREETING := "[i]Az öregasszony meg sem fordul. Egy csontkanállal kavargatja az üstöt; a zöld gőz " \
	+ "kígyóként tekeredik a mennyezet felé.[/i]\n\nCsukd be magad mögött az ajtót, a huzat elrontja a főzetet. " \
	+ "Na. Mit akarsz?"
const WITCH_STORIES: Array[Dictionary] = [
	{"id": "who", "text": "Ki vagy te?", "trust": 3,
		"answer": "[i]Végre rád néz. Az egyik szeme zöld, a másik fakó, mint a tejüveg.[/i]\n\n" \
			+ "Margit. A faluban Holló Margitnak hívtak, amikor még volt falu. Most csak az erdő hív sehogy.\n\n" \
			+ "Előbb laktam itt, mint ahogy az első kalandor lemászott abba a lyukba. Előbb, mint a király tábora. " \
			+ "Amikor jöttek a katonák, mindenki elköltözött. Én maradtam. A füvek nem költöznek."},
	{"id": "sign", "text": "Miért írja a tábla, hogy \"lakóház\"?", "trust": 2,
		"answer": "[i]Kuncog, száraz, recsegő hangon.[/i]\n\n" \
			+ "A fenti ház, ami most rom? Az volt a lakóház. Az erdész lakott benne a feleségével, jó emberek voltak. " \
			+ "A táblát az erdész faragta, hogy a vándor odataláljon.\n\n" \
			+ "Aztán egy éjjel az asszony lement a Mélységhez vízért... nem a kútra, a Mélységhez. Az erdész utána. " \
			+ "A ház azóta omladozik. A tábla meg kopik. Az enyémet én festettem alá. Szép betűk, nem?"},
	{"id": "brew", "text": "Mi fő az üstben?", "trust": 2,
		"answer": "[i]Belekavar. Valami felbukkan a lében, aztán gyorsan el is merül.[/i]\n\n" \
			+ "Ami épp kell. Ma békanyál, csalán, három szem hamvas bogyó és egy csipet a Mélység porából. " \
			+ "Azt a ti kalandoraitok hordják fel a csizmájukon, nem is tudják, mit érnek.\n\n" \
			+ "Ne nyúlj hozzá. Az utolsó, aki belekóstolt, három napig csak brekegni tudott. Még most is ott " \
			+ "ugrál valahol a tó partján."},
	{"id": "deep", "text": "Mit tudsz a Mélységről?", "trust": 4,
		"answer": "[i]Elhallgat. Az üst rotyogása is mintha halkabb lenne.[/i]\n\n" \
			+ "Azt, hogy nem lyuk. Egy lyuknak van alja. Az a valami lélegzik, gyermekem. Telente, amikor fagy, " \
			+ "a bejárata fölött meleg a levegő, mint egy alvó állat orra fölött.\n\n" \
			+ "Járj csak le, hozz fel kincset, öld a szörnyeit. De ha egyszer a legalján valaki a neveden szólít... " \
			+ "ne felelj. Gyere inkább ide, és igyál egy jó csalánteát."},
	{"id": "village", "text": "Milyen volt itt a falu régen?", "trust": 2,
		"answer": "[i]A szeme elréved, a kanál megáll az üstben.[/i]\n\n" \
			+ "Tizenkét ház. Malom a patakon, a tisztáson vásár minden ősszel. Az erdész háza volt a legszebb, " \
			+ "faragott ablakokkal. A gyerekek a kút körül játszottak, mielőtt a kútnak alja lett volna... vagy " \
			+ "mielőtt rájöttünk, hogy nincs neki.\n\n" \
			+ "Aztán megnyílt a Mélység, és jött a király. Kardokkal, sátrakkal, kalandorokkal. A falu elment. Én itt " \
			+ "maradtam, hogy legyen, aki emlékszik rá."},
]

## Margit küldetései egymás után (mindegyik után 3 új történet; a 3. után nyílik meg a Test manipulálása):
## 1. Vámpírfog a táskából, 2. Tűzboszorkányok (a nővérei), 3. ritka por, 4. Barlangi denevérek,
## 5. Vérszellemek (az erdész felesége). A szörnyes küldetések az elvállalás óta számolnak (Progress.kills, "<id>_base").
const FANG_QUEST := "witch_fang"
const FANG_ID := "trinket_fang"
const SISTERS_QUEST := "witch_sisters"
const DUST_QUEST := "witch_dust"
const BATS_QUEST := "witch_bats"
const WIFE_QUEST := "witch_wife"
const CHAIN: Array[String] = [FANG_QUEST, SISTERS_QUEST, DUST_QUEST, BATS_QUEST, WIFE_QUEST]
## Ennek a küldetésnek a teljesítése után fejleszt (Test manipulálása).
const UNLOCK_QUEST := DUST_QUEST
## Szörnyes küldetések: szörny (Progress.kills kulcs) és darab.
const KILL_QUESTS := {
	SISTERS_QUEST: ["fire_witch", 6],
	BATS_QUEST: ["cave_bat", 12],
	WIFE_QUEST: ["blood_wraith", 5],
}
const DUST_RARITY := "rare"
const DUST_COUNT := 3
const GOLD := {FANG_QUEST: 400, SISTERS_QUEST: 500, DUST_QUEST: 600, BATS_QUEST: 700, WIFE_QUEST: 1000}
const QUESTS := {
	FANG_QUEST: {"name": "A vámpír foga",
		"text": "Holló Margitnak a főzetéhez egy igazi [b]Vámpírfog[/b] kell (epikus talizmán, a táskádban legyen). "
			+ "Azt mondja, a vámpír foga emlékszik minden vérre, amit valaha ivott, és a test is emlékezni fog rá.",
		"reward": "400 tábori arany (és a boszorkány bizalma)",
		"doing": "vigyél a boszorkánynak egy Vámpírfogat", "done": "Margit megkapta a fogat"},
	SISTERS_QUEST: {"name": "A nővérek",
		"text": "Margit két nővére évtizedekkel ezelőtt lement a Mélységbe, és [b]Tűzboszorkány[/b]ként jöttek vissza... "
			+ "vagy valami, ami a bőrüket viseli. Ölj meg [b]6 Tűzboszorkányt[/b], hogy a lelkük elszabadulhasson.",
		"reward": "500 tábori arany",
		"doing": "ölj meg 6 Tűzboszorkányt", "done": "a nővérek lelke szabad"},
	DUST_QUEST: {"name": "A Mélység pora",
		"text": "A test átformálásához olyan por kell, amiben még ott él a Mélység ereje. Vigyél Margitnak "
			+ "[b]3 ritka port[/b] (a kovácsnál szedheted szét a ritka tárgyakat).",
		"reward": "600 tábori arany és a [b]Test manipulálása[/b]",
		"doing": "vigyél Margitnak 3 ritka port", "done": "Margit megtanít a test manipulálására"},
	BATS_QUEST: {"name": "Suttogó szárnyak",
		"text": "Margit szerint a [b]Barlangi denevér[/b]ek a Mélység suttogását hordják a szárnyukon, és az egyik "
			+ "hang ismerős neki. Ölj meg [b]12 Barlangi denevért[/b], hogy kihallgathassa a szárnyukat.",
		"reward": "700 tábori arany",
		"doing": "ölj meg 12 Barlangi denevért", "done": "Margit megtalálta a hangot"},
	WIFE_QUEST: {"name": "Az erdész felesége",
		"text": "A suttogó hang Ilkáé, az erdész feleségéé, aki egy éjjel lement a Mélységhez. A lelkét egy "
			+ "[b]Vérszellem[/b] tartja fogva. Ölj meg [b]5 Vérszellemet[/b], hogy Ilka hazatérhessen.",
		"reward": "1000 tábori arany (és Margit hálája)",
		"doing": "ölj meg 5 Vérszellemet", "done": "Ilka lelke hazatért"},
}
## A következő küldetés kérése: az opció szövege és Margit válasza.
const ASK := {
	FANG_QUEST: ["Segíthetek valamiben?",
		"[i]Most először teszi le a kanalat. Hosszan néz rád.[/i]\n\n"
		+ "Talán. A főzetemből egyvalami hiányzik: egy [b]Vámpírfog[/b]. Nem bármilyen állaté, igazi vámpíré. "
		+ "A kalandorok néha felhozzák talizmánnak, a nyakukba akasztják, és azt hiszik, attól erősebbek. "
		+ "Bolondok. Az ereje nem a nyakban van.\n\n"
		+ "Hozz egyet, és megmutatom, mire jó valójában.\n\n"
		+ "[color=#7a4a10](Új küldetés a J könyvben, a Boszorkány fülön.)[/color]"],
	SISTERS_QUEST: ["Van még valami, amiben segíthetek?",
		"[i]Sokáig hallgat. Aztán a polcról levesz egy megfakult, három nőt ábrázoló rajzot.[/i]\n\n"
		+ "Hárman voltunk. Én, Borka és Rozália. Holló-lányok, a falu boszorkányai. Amikor megnyílt a Mélység, ők "
		+ "lementek megnézni, mi lélegzik odalent. Én itt maradtam az üst mellett. Gyáva voltam? Okos? Ma sem tudom.\n\n"
		+ "Évekkel később a kalandorok tűzzel dobáló, piros ruhás asszonyokról meséltek. [b]Tűzboszorkány[/b]ok, így "
		+ "hívjátok őket. Én tudom, kik azok. Nem ők már... csak a bőrüket viseli valami.\n\n"
		+ "Ölj meg hatot közülük. Ha jól sejtem, a nővéreim lelke valamelyikben ott ragadt. Szabadítsd fel őket.\n\n"
		+ "[color=#7a4a10](Új küldetés a J könyvben, a Boszorkány fülön.)[/color]"],
	DUST_QUEST: ["Megtanítasz a test manipulálására?",
		"[i]Elmosolyodik. Most először, amióta ismered.[/i]\n\n"
		+ "Már vártam, hogy megkérdezd. A test egy ház, mondtam már. Át lehet építeni. De nem fából és szögből, "
		+ "hanem porból. Abból a porból, amit a kovácsotok szitál ki az összetört tárgyakból.\n\n"
		+ "Az átlagos por gyenge, abban csak a kovács verejtéke van. Nekem [b]3 ritka por[/b] kell, abban még ott "
		+ "zümmög a Mélység ereje. Hozd el, és megmutatom, hogyan kell a csontot megcsavarni.\n\n"
		+ "[color=#7a4a10](Új küldetés a J könyvben, a Boszorkány fülön.)[/color]"],
	BATS_QUEST: ["Kérhetek még valamit... vagy te kérsz?",
		"[i]Az ablakhoz lép. Odakint denevérek cikáznak a fák között.[/i]\n\n"
		+ "Kérek. Éjszakánként, amikor a denevérek felszállnak a Mélységből, hallok valamit. Egy hangot, ami a "
		+ "szárnyukba ragadt, ahogy a pókháló ragad a ruhába. Ismerős hang. Ötven éve nem hallottam.\n\n"
		+ "A denevér szárnya mindent megőriz, amit odalent hallott. Ölj meg [b]12 Barlangi denevért[/b] ott lent, "
		+ "és a szárnyuk suttogása idetalál az üstömhöz. Akkor kihallgatom, kié az a hang.\n\n"
		+ "[color=#7a4a10](Új küldetés a J könyvben, a Boszorkány fülön.)[/color]"],
	WIFE_QUEST: ["Kié volt a hang a denevérek szárnyán?",
		"[i]Leül az üst mellé egy háromlábú székre. Most nagyon öregnek látszik.[/i]\n\n"
		+ "Ilkáé. Az erdész feleségéé, a fenti házból, amiből rom lett. Az egyetlen barátnőm volt a faluban. "
		+ "Ő hozta a gyógyfüvet a hegyről, én főztem belőle. Aztán egy éjjel lement a Mélységhez vízért.\n\n"
		+ "A lelke nem halt meg. Fogva tartja egy [b]Vérszellem[/b], abból a vörös leplű fajtából, ami a Mélység "
		+ "közepén kóborol. Ölj meg ötöt. Az egyik majd elengedi.\n\n"
		+ "[color=#7a4a10](Új küldetés a J könyvben, a Boszorkány fülön.)[/color]"],
}
## Amíg a küldetés fut: kérdés és válasz (a haladás a végén).
const WAIT := {
	FANG_QUEST: ["Hol találok vámpírfogat?",
		"[i]Meg sem fordul.[/i]\n\nAhol a vámpírok. Lent, a Mélységben, ahol a fáklya is fázik. Ha megölsz egyet, "
		+ "és szerencséd van, a foga a porban marad. Hozd ide, mielőtt eladod valami ostoba kereskedőnek."],
	SISTERS_QUEST: ["Hogyan ismerem fel a nővéreidet?",
		"Sehogy. A Tűzboszorkány mind egyforma: piros ruha, öt tűzgolyó legyezőben. A nővéreim nem fognak "
		+ "megszólítani. Csak öld meg őket, gyermekem, mindet, akit látsz. A lélek majd tudja, hová menjen."],
	DUST_QUEST: ["Honnan szerzek ritka port?",
		"A kovácsotoktól, Ambrustól. Vigyél neki ritka tárgyat, a kék fajtát, és szedesse szét. Abból jön a ritka "
		+ "por. Ha nem elég, hozz többet. A Mélység bőkezű a tárgyakkal, csak a lelkekkel fukar."],
	BATS_QUEST: ["Hol vannak a denevérek?",
		"Ahol a sötét a legsűrűbb. A kazamata felső emeletein csapatban lógnak a mennyezeten. Gyorsak, cikáznak, "
		+ "nehéz eltalálni őket. Légy türelmes. A türelem is fegyver."],
	WIFE_QUEST: ["Hol keressem a Vérszellemeket?",
		"Mélyen. Ott, ahol a kő már nem a mi kövünk. Eltűnnek és máshol bukkannak fel, és az érintésük jéghideg. "
		+ "Ne félj tőlük. Ilka sem félt semmitől, csak a sötéttől. Hozd haza."],
}
## A küldetés átadása: az opció szövege és Margit válasza (a végén a jutalom).
const TURN_IN := {
	FANG_QUEST: ["Hoztam egy Vámpírfogat.",
		"[i]Két ujjal veszi el, a gyertya fénye felé tartja. A fog hegye egy pillanatra vörösen felizzik.[/i]"
		+ "\n\nIgazi. Régi is. Ez legalább háromszáz évig harapott.\n\n"
		+ "[i]Az üstbe ejti. A zöld gőz egy szívverésnyi időre vérvörösre vált, aztán visszazöldül.[/i]\n\n"
		+ "Jól van. Most már beszélhetünk komolyabb dolgokról is."],
	SISTERS_QUEST: ["Megöltem hat Tűzboszorkányt.",
		"[i]Az üst fölött két kis, piros fénygömb jelenik meg. Körbetáncolják Margitot, aztán kirepülnek a "
		+ "kéményen.[/i]\n\n[i]Margit sokáig néz utánuk. A szeme nedves.[/i]\n\n"
		+ "Borka mindig előrement. Rozália mindig utána. Most is így mentek el. Köszönöm, gyermekem. Ezt nem tudom "
		+ "megfizetni, de azért megpróbálom."],
	DUST_QUEST: ["Itt a három ritka por.",
		"[i]A port egy csontkanálon az üst fölé tartja. A por magától felemelkedik, és kék csillámként kering a "
		+ "gőzben.[/i]\n\nÉrzed? Zümmög. Ez a Mélység ereje, ami még nem tudja, hová tartozik. Ha jól csinálom, "
		+ "a te csontjaidba fog tartozni.\n\n[i]Megfogja a csuklódat. A keze meglepően erős.[/i]\n\n"
		+ "Mostantól nálam is fejlesztheted magad. Csak arany kell és por. Meg némi fájdalomtűrés.\n\n"
		+ "[color=#7a4a10](Megnyílt a Test manipulálása.)[/color]"],
	BATS_QUEST: ["Megöltem tizenkét denevért.",
		"[i]Az üst gőze elsötétül. Halk suhogás tölti be a kunyhót, mintha száz apró szárny verdesne "
		+ "körülötted. Aztán egy női hang, alig hallhatóan: \"...Margit... sötét van...\"[/i]\n\n"
		+ "[i]A kanál kiesik Margit kezéből.[/i]\n\nIlka. Ez Ilka hangja."],
	WIFE_QUEST: ["Megöltem öt Vérszellemet.",
		"[i]A kunyhó ajtaja magától kinyílik. Hűvös, fenyőillatú szél fúj be, és egy pillanatra egy fiatal "
		+ "asszony alakja áll a küszöbön, kosárral a karján. Rámosolyog Margitra, aztán eltűnik a fák között, a "
		+ "romos ház felé.[/i]\n\n[i]Margit csak áll, és nem szól. Aztán halkan becsukja az ajtót.[/i]\n\n"
		+ "Hazament. Ötven év után hazament. Gyermekem... ezt sosem felejtem el."],
}
## Minden küldetés után 3 új történet.
const AFTER_STORIES := {
	FANG_QUEST: [
		{"id": "fang_why", "text": "Mire kellett neked az a fog?", "trust": 3,
			"answer": "[i]A fogat egy kis üvegcsébe ejti. A folyadék elsötétül, aztán lassan vörösre vált.[/i]\n\n"
				+ "A vámpír nem a vért issza, gyermekem. Az életet. A vér csak a pohár. A foga pedig ötszáz évnyi "
				+ "lopott életet hordoz magában, minden harapás egy újabb gyűrű rajta, mint a fa törzsén.\n\n"
				+ "Ebből a lőréből egy csepp elég, hogy a test emlékezzen arra, milyen erős volt valaha. Vagy arra, "
				+ "milyen erős lehetne."},
		{"id": "body", "text": "Honnan tudsz ennyit a testről?", "trust": 3,
			"answer": "[i]Felhúzza a ruhaujját. A karján apró, ezüstös hegek futnak, mint egy térkép.[/i]\n\n"
				+ "Ötven éve gyógyítok. Előbb a falu tehenét, aztán a falu népét, aztán a katonákat, akik a falut "
				+ "elűzték. A test nem titok. Csak egy ház, amiben laksz. És a házat át lehet építeni.\n\n"
				+ "A doktorotok, Kálmán, fűrésszel és szikével dolgozik. Én türelemmel. Mindkettő fáj, csak az enyém "
				+ "tovább tart."},
		{"id": "lorinc", "text": "Ismered Lőrincet, a varázslót?", "trust": 2,
			"answer": "[i]Fújtat egyet.[/i]\n\n"
				+ "A tűzgolyós fiút? Hogyne. Évekig a kútnál kísérletezett, és kétszer gyújtotta fel a tetőmet. "
				+ "A varázslók azt hiszik, a hatalom kívülről jön: csillagokból, könyvekből, szavakból.\n\n"
				+ "Pedig minden itt van belül. A csontban, az inakban, a vérben. Csak tudni kell, hol kell megcsavarni. "
				+ "Ezt a fiú sosem értette meg. Talán majd te."},
	],
	SISTERS_QUEST: [
		{"id": "borka", "text": "Milyen volt Borka?", "trust": 2,
			"answer": "[i]Elneveti magát.[/i]\n\nHangos. Mindig hangos. A vásáron ő kiabálta túl a "
				+ "lacikonyhást, és ő verte el a molnárt, amikor megcsalta a feleségét. A tüzet ő szerette a "
				+ "legjobban. Gyertyát gyújtott, ha szomorú volt, máglyát, ha dühös.\n\n"
				+ "Talán ezért lett belőle épp tűzboszorkány. A Mélység abból formál, amit talál."},
		{"id": "rozalia", "text": "És Rozália?", "trust": 2,
			"answer": "[i]Az arca ellágyul.[/i]\n\nA legkisebb. Csendes, mint a hó. Ő tudta a legtöbb "
				+ "dalt, és madarakat szelídített a kezére. Borka ment le, mert kíváncsi volt. Rozália utána, mert "
				+ "Borka nélkül nem tudott élni.\n\nÉn meg itt maradtam, mert nélkülük sem tudtam. Csak máshogy."},
		{"id": "coven", "text": "Mi lett a falu többi boszorkányával?", "trust": 3,
			"answer": "Nem volt több. Hárman voltunk, a Holló-lányok, anyánk után, aki szintén boszorkány volt. "
				+ "A falu félt tőlünk, de hozzánk jött, ha beteg volt a gyerek vagy meddő a tehén.\n\n"
				+ "[i]Megkocogtatja az üst peremét.[/i]\n\nEz az üst anyánké volt. Háromszáz éves. Többet látott, "
				+ "mint a királyotok egész családfája."},
	],
	DUST_QUEST: [
		{"id": "how_body", "text": "Hogyan működik a test manipulálása?", "trust": 2,
			"answer": "[i]Egy marék port szór a tenyerébe, és ráfúj. A por kék fényben a karodra telepszik.[/i]\n\n"
				+ "A kiképzősátorban a katonák izzadsággal építik a testet. Lassan, egyenként. Én a porral "
				+ "egyszerre a csontig hatolok. Ezért erősebb, másfélszer annyit ad.\n\n"
				+ "De drága. Arany kell a füvekre és por a Mélységből. És minél többet építek rád, annál több kell."},
		{"id": "limits", "text": "Van határa?", "trust": 2,
			"answer": "Az erőnek nincs. Az ütést, az életet, a sebzést a végtelenségig csavarhatom. Csak egyre "
				+ "többe kerül.\n\n[i]Felemeli a mutatóujját.[/i]\n\nDe a gyorsaságnak, a kitérésnek, a "
				+ "pontos szemnek van határa. Egy ember nem lehet gyorsabb a saját árnyékánál. Ott megállok, akármennyi "
				+ "port hozol."},
		{"id": "price", "text": "Fáj?", "trust": 3,
			"answer": "[i]Nem néz rád.[/i]\n\nIgen. Mindig. Ha valaki azt mondja, hogy erősebb lehetsz "
				+ "fájdalom nélkül, az hazudik, vagy el akar adni valamit.\n\n"
				+ "De te már ismered a fájdalmat. Minden alkalommal, amikor lemész abba a lyukba, és felhoznak "
				+ "hordágyon. Ehhez képest az én fájdalmam csak egy csípés."},
	],
	BATS_QUEST: [
		{"id": "ilka", "text": "Ki volt Ilka?", "trust": 2,
			"answer": "Az erdész felesége. Vörös hajú, szeplős, mindig nevetett. Ő hozta nekem a hegyről a "
				+ "kakukkfüvet és az árnikát, én meg főztem neki teát, amikor fájt a háta.\n\n"
				+ "[i]Elhallgat.[/i]\n\nEgyszer azt mondta, ha meghal, denevér lesz belőle, hogy éjjel is "
				+ "repülhessen. Nevettünk rajta. Most nem nevetek."},
		{"id": "forester", "text": "Mi lett az erdésszel?", "trust": 2,
			"answer": "Utánament. Fejszével, fáklyával, egyedül. Három nap múlva jött fel, ősz hajjal. "
				+ "Harmincéves volt.\n\nSosem mondta el, mit látott. Leült a ház küszöbére, és egy évig "
				+ "faragta a táblát. Aztán egy reggel üres volt a ház. Senki sem látta elmenni."},
		{"id": "bats", "text": "Honnan tudtad, hogy a denevérek hordják a hangot?", "trust": 3,
			"answer": "[i]Megvonja a vállát.[/i]\n\nAnyámtól. Ő azt mondta, a denevér az egyetlen állat, "
				+ "ami a hangjával lát. Amit a sötétben hall, az belekerül. A szárnya olyan, mint egy üres levél, "
				+ "amire a Mélység ír.\n\nEgy denevér csak egy szót visz. Tizenkettő már egy mondatot."},
	],
	WIFE_QUEST: [
		{"id": "after", "text": "Most mi lesz veled, Margit?", "trust": 3,
			"answer": "[i]Kavar egyet az üstön, és most először dúdol közben.[/i]\n\n"
				+ "Ugyanaz, mint eddig. Főzök, gyógyítok, és csavarom a kalandorok csontját. De most már nem "
				+ "egyedül várok. A nővéreim szabadok, Ilka hazament. Akiket vártam, megjöttek, csak máshogy.\n\n"
				+ "Most már csak te maradtál, gyermekem. Rád is várni fogok. Mindig."},
		{"id": "ruin", "text": "Ilka a romos ház felé ment...", "trust": 2,
			"answer": "Igen. Haza. Néha éjjel, ha kinézek, gyertyafényt látok a rom ablakában. A tolvaj "
				+ "fiú, aki ott rejtőzik, azt mondja, nem ő gyújtja.\n\n[i]Mosolyog.[/i]\n\n"
				+ "Hagyd csak. Ötven évig volt sötétben. Most világítson egy kicsit."},
		{"id": "blessing", "text": "Mit kívánsz nekem?", "trust": 4,
			"answer": "[i]Feláll, és a hüvelykujjával egy kis jelet rajzol a homlokodra. Hűvös és fenyőillatú.[/i]\n\n"
				+ "Azt, hogy ha egyszer a Mélység legalján valaki a neveden szólít, legyen ott valaki, aki "
				+ "visszahív. Ahogy te visszahívtad Ilkát és a nővéreimet.\n\nMost menj. És gyere vissza."},
	],
}

const WITCH_PANEL := preload("res://ui/witch_panel.gd")

var _camp: Node2D
var _player: Node2D
var _panel: CanvasLayer
var _entities: Node2D
var _prompt: Label
var _dialogue: DialoguePanel
## "outside" | "hut"
var _where := "outside"
var _busy := false


func setup(camp: Node2D) -> void:
	_camp = camp
	_entities = camp.get_node("Entities")
	_player = camp.get_node("Entities/Player")
	_dialogue = DialoguePanel.new()
	_dialogue.name = "WitchDialogue"
	_dialogue.npc_id = WITCH_ID
	_dialogue.npc_name = WITCH_NAME
	_dialogue.greeting = WITCH_GREETING
	_dialogue.portrait = portrait()
	_dialogue.options_provider = func() -> Array[Dictionary]:
		var list := options(_player.get_node("Inventory"))
		# A Test manipulálása bezárja a beszélgetést, és megnyitja a boszorkány fejlesztő ablakát.
		for option in list:
			if option["id"] == "manipulate":
				option["on_choose"] = _open_panel
		return list
	_panel = WITCH_PANEL.new()
	_panel.name = "WitchPanel"
	camp.add_child.call_deferred(_panel)
	camp.add_child.call_deferred(_dialogue)


## A beszélgetés opciói: a soron következő küldetés (kérés / haladás / átadás), a Test manipulálása (a 3. küldetés
## után), a teljesített küldetések utáni történetek (a legújabbak elöl), végül a régi történetek.
static func options(inventory: Inventory) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var current := current_quest()
	if not current.is_empty():
		var state := Progress.npc_quest_state(current)
		if state == "":
			var ask: Array = ASK[current]
			list.append({"id": "help" if current == FANG_QUEST else "help_" + current, "text": ask[0],
				"on_choose": func() -> String: return _accept(current)})
		elif quest_ready(current, inventory):
			list.append({"id": "give_" + current, "text": TURN_IN[current][0],
				"on_choose": func() -> String: return _turn_in(current, inventory)})
		else:
			var wait: Array = WAIT[current]
			list.append({"id": "wait_" + current, "text": wait[0],
				"on_choose": func() -> String: return "%s%s" % [wait[1], _progress_note(current)]})
	if panel_open():
		list.append({"id": "manipulate", "text": "Test manipulálása (a képességeid végleges fejlesztése)"})
	for i in range(CHAIN.size() - 1, -1, -1):
		if Progress.npc_quest_state(CHAIN[i]) == "done":
			for story: Dictionary in AFTER_STORIES[CHAIN[i]]:
				list.append(story)
	list.append_array(WITCH_STORIES)
	return list


func _open_panel() -> String:
	Audio.play("ui_open")
	var menus := _camp.get_node("Menus")
	menus.call("close_current")
	menus.call_deferred("open_menu", _panel)
	return ""


## Az első még nem teljesített küldetés ("" = mind kész).
static func current_quest() -> String:
	for id in CHAIN:
		if Progress.npc_quest_state(id) != "done":
			return id
	return ""


## Nyitva van-e már a Test manipulálása (a 3. küldetés után).
static func panel_open() -> bool:
	return Progress.npc_quest_state(UNLOCK_QUEST) == "done"


## Az elvállalás óta megölt szörnyek (legfeljebb a cél).
static func kill_progress(id: String) -> int:
	var target: Array = KILL_QUESTS[id]
	var base := int(Progress.npc_quest_state(id + "_base"))
	return clampi(int(Progress.kills.get(target[0], 0)) - base, 0, int(target[1]))


## Leadható-e már a küldetés.
static func quest_ready(id: String, inventory: Inventory) -> bool:
	if id == FANG_QUEST:
		return _has(inventory, FANG_ID)
	if id == DUST_QUEST:
		return Smithing.dust_of(DUST_RARITY) >= DUST_COUNT
	if KILL_QUESTS.has(id):
		return kill_progress(id) >= int(KILL_QUESTS[id][1])
	return false


## A J könyv "folyamatban" szövege (a szörnyes és a poros küldetésnél a haladással).
static func doing_text(id: String, fallback: String) -> String:
	if KILL_QUESTS.has(id):
		return "%s: %d / %d" % [fallback, kill_progress(id), int(KILL_QUESTS[id][1])]
	if id == DUST_QUEST:
		return "%s: %d / %d" % [fallback, mini(Smithing.dust_of(DUST_RARITY), DUST_COUNT), DUST_COUNT]
	return fallback


static func _progress_note(id: String) -> String:
	if KILL_QUESTS.has(id):
		return "\n\n[color=#7a4a10](Eddig: %d / %d)[/color]" % [kill_progress(id), int(KILL_QUESTS[id][1])]
	if id == DUST_QUEST:
		return "\n\n[color=#7a4a10](Ritka porod: %d / %d)[/color]" % [Smithing.dust_of(DUST_RARITY), DUST_COUNT]
	return ""


static func _accept(id: String) -> String:
	Progress.set_npc_quest(id, "active")
	if KILL_QUESTS.has(id):
		Progress.set_npc_quest(id + "_base", str(int(Progress.kills.get(KILL_QUESTS[id][0], 0))))
	Progress.mark_asked(WITCH_ID, "help" if id == FANG_QUEST else "help_" + id)
	Progress.save_game()
	Audio.play("ui_open")
	return ASK[id][1]


static func _turn_in(id: String, inventory: Inventory) -> String:
	if not quest_ready(id, inventory):
		return "Hm? Még nincs kész, gyermekem."
	if id == FANG_QUEST:
		for i in inventory.bag.size():
			var item: Variant = inventory.bag[i]
			if item is Dictionary and item.get("id", "") == FANG_ID:
				inventory.take_from_bag(i)
				break
	var gold: int = GOLD[id]
	# Az add_camp_gold újratölti a mentést: előbb az arany, aztán a többi változás.
	Progress.add_camp_gold(gold)
	if id == DUST_QUEST:
		Smithing.add_dust(DUST_RARITY, -DUST_COUNT)
	Progress.set_npc_quest(id, "done")
	Progress.mark_asked(WITCH_ID, "give_" + id)
	Progress.change_trust(WITCH_ID, 20)
	Progress.save_game()
	Audio.play("level_up")
	return "%s [color=#7a4a10](+%d tábori arany)[/color]" % [TURN_IN[id][1], gold]


static func _has(inventory: Inventory, id: String) -> bool:
	for item: Variant in inventory.bag:
		if item is Dictionary and item.get("id", "") == id:
			return true
	return false


static func portrait() -> Texture2D:
	var face := AtlasTexture.new()
	face.atlas = WITCH_SHEET
	face.region = Rect2(0, 0, 16, 28)
	return face


## A sáros út: a nyugati ösvénytől egyenesen le, aztán az ajtó előtt nyugatra (a tábor rajzolja ki).
static func path_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var front := TOP_LEFT.y + SIZE.y
	for y in range(PATH_START_ROW, front + 2):
		tiles.append(Vector2i(PATH_COLUMN, y))
		tiles.append(Vector2i(PATH_COLUMN + 1, y))
	for x in range(DOOR_COLUMN - 1, PATH_COLUMN):
		tiles.append(Vector2i(x, front))
		tiles.append(Vector2i(x, front + 1))
	return tiles


## Ide nem kerülhet fa / virág (a kunyhó és körülötte).
static func blocked_rect() -> Rect2i:
	return Rect2i(TOP_LEFT - Vector2i(2, 2), SIZE + Vector2i(4, 3))


func build() -> void:
	_build_exterior()
	_build_interior()
	_build_ui()


# ---------------------------------------------------------------- külső

func _build_exterior() -> void:
	var house := Node2D.new()
	add_child(house)
	var tl := TOP_LEFT
	for x in SIZE.x:
		var piece := 0 if x == 0 else (2 if x == SIZE.x - 1 else 1)
		for row: Array in [[Town.ROOF_TOP, 0], [Town.ROOF_MID, 1], [Town.ROOF_LOW, 2]]:
			_tile(row[0][piece], tl + Vector2i(x, row[1]), -6, house).modulate = ROOF_TINT
		_tile(Town.WALL_BAND, tl + Vector2i(x, 3), -6, house).modulate = WALL_TINT
		_tile(Town.WALL_BOARDS, tl + Vector2i(x, 4), -6, house).modulate = WALL_TINT
	# Ablak zöld derengéssel, ajtó, fölötte koponya.
	var window := _tile(Town.WINDOW, tl + Vector2i(4, 3), -5, house)
	window.modulate = Color(0.6, 1.0, 0.6)
	_light(_center(tl + Vector2i(4, 3)) + Vector2(0, 16), BREW, 1.0, 0.45)
	_tile(Town.DOOR_TILE, Vector2i(DOOR_COLUMN, tl.y + 4), -5, house).modulate = Color(0.55, 0.45, 0.5)
	_sprite(DUNGEON, SKULL, _center(Vector2i(DOOR_COLUMN, tl.y + 3)) + Vector2(0, 4), -4)
	# Görbe kémény a tetőn, zöldes füsttel.
	var chimney := ColorRect.new()
	chimney.color = Color(0.25, 0.22, 0.24)
	chimney.size = Vector2(16, 30)
	chimney.position = _center(tl + Vector2i(1, 0)) + Vector2(-8, -34)
	chimney.rotation = -0.12
	chimney.z_index = -5
	add_child(chimney)
	add_child(_smoke(chimney.position + Vector2(8, 0)))
	# Az ajtó két oldalán korsók és egy kis gombacsoport.
	_sprite(POTTERY, Rect2(0, 16, 16, 16), _center(Vector2i(DOOR_COLUMN - 1, tl.y + 5)) + Vector2(0, -10), -4)
	_sprite(POTTERY, Rect2(16, 16, 16, 16), _center(Vector2i(DOOR_COLUMN + 1, tl.y + 5)) + Vector2(4, -12), -4)
	_cobweb(tl + Vector2i(0, 3), false, false, -4)
	_solid(Rect2(Vector2(tl) * TILE, Vector2(SIZE) * TILE - Vector2(0, 6)))


func door_position() -> Vector2:
	return _center(Vector2i(DOOR_COLUMN, TOP_LEFT.y + SIZE.y)) + Vector2(0, 2)


# ---------------------------------------------------------------- belül

func _build_interior() -> void:
	var r := INTERIOR
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			_tile(FLOOR_TILES[(x + y) % 2], Vector2i(x, y), -10).modulate = Color(0.5, 0.42, 0.45)
	# Hátsó fal: polcok üvegcsékkel és könyvekkel.
	for x in range(r.position.x, r.end.x):
		var col: int = Town.SHELF_COLUMNS[(x - r.position.x) % Town.SHELF_COLUMNS.size()]
		_tile(Vector2i(col, 14), Vector2i(x, r.position.y), -9).modulate = Color(0.6, 0.55, 0.65)
		_tile(Vector2i(col, 12), Vector2i(x, r.position.y - 1), -9).modulate = Color(0.6, 0.55, 0.65)
	# Oldalfalak és a déli fal (sötét gerendák), a bejárat a déli falon.
	var color := Color(0.1, 0.07, 0.09)
	for rect: Rect2 in [Rect2(Vector2(r.position.x - 1, r.position.y - 1) * TILE, Vector2(TILE, (r.size.y + 2) * TILE)),
			Rect2(Vector2(r.end.x, r.position.y - 1) * TILE, Vector2(TILE, (r.size.y + 2) * TILE)),
			Rect2(Vector2(r.position.x, r.end.y) * TILE, Vector2((INTERIOR_DOOR.x - r.position.x) * TILE, TILE)),
			Rect2(Vector2(INTERIOR_DOOR.x + 1, r.end.y) * TILE, Vector2((r.end.x - INTERIOR_DOOR.x - 1) * TILE, TILE))]:
		_dark_rect(rect, -9, color)
		_solid(rect)
	_solid(Rect2(Vector2(r.position.x, r.position.y - 1) * TILE, Vector2(r.size.x * TILE, TILE * 1.6)))
	_solid(Rect2(Vector2(INTERIOR_DOOR.x, r.end.y + 1) * TILE, Vector2(TILE, TILE)))
	_tile(Town.DOOR_TILE, INTERIOR_DOOR, -8).modulate = Color(0.55, 0.45, 0.5)
	# Az üst a tűzön, rotyogó zöld lével és gőzzel.
	var pot := Node2D.new()
	pot.position = _center(CAULDRON_TILE) + Vector2(0, 16)
	_entities.add_child(pot)
	var cauldron := Sprite2D.new()
	cauldron.texture = CAULDRON
	cauldron.scale = Vector2(3, 3)
	cauldron.position = Vector2(0, -26)
	pot.add_child(cauldron)
	# A lángok elöl nyaldossák az üst alját.
	var fire := Fire.new()
	fire.position = Vector2(0, 2)
	pot.add_child(fire)
	pot.add_child(_steam(Vector2(0, -40)))
	_body(pot, Vector2(0, -12), Vector2(44, 18))
	_light(pot.position + Vector2(0, -30), BREW, 4.0, 1.4)
	_light(pot.position, Color(1, 0.5, 0.2), 0.9, 0.5)
	# A boszorkány az üst mellett (lassan lélegzik).
	var witch := AnimatedSprite2D.new()
	witch.sprite_frames = _witch_frames()
	witch.play()
	witch.scale = Vector2(2, 2)
	witch.flip_h = true
	witch.offset = Vector2(0, -14)
	witch.position = _center(WITCH_TILE) + Vector2(0, 14)
	_entities.add_child(witch)
	_body(witch, Vector2(0, -2), Vector2(8, 4))
	# Asztal üvegcsékkel, koponyával és gyertyával (balra elöl).
	var table := _tile(Town.TABLE, Vector2i(r.position.x + 2, r.position.y + 4), 0, _entities)
	_solid(Rect2(Vector2(r.position.x + 2, r.position.y + 4) * TILE + Vector2(2, 8), Vector2(TILE - 4, TILE - 12)))
	for i in 2:
		var flask := _sprite(DUNGEON, FLASKS[i], Vector2(-4 + i * 7, -6), 1, table)
		flask.scale = Vector2(0.5, 0.5)
	_sprite(DUNGEON, SKULL, Vector2(5, -3), 1, table).scale = Vector2(0.45, 0.45)
	_tile(Town.CANDLE, Vector2i(r.position.x + 2, r.position.y + 3), -7).position += Vector2(0, 12)
	_light(_center(Vector2i(r.position.x + 2, r.position.y + 3)) + Vector2(0, 10), Color(0.9, 0.7, 1.0), 1.0, 0.45)
	# Szétszórt üvegcsék és koponyák a polcok alatt, korsók a sarokban.
	for i in range(2, FLASKS.size()):
		_sprite(DUNGEON, FLASKS[i], _center(Vector2i(r.end.x - 6 + i, r.position.y + 1)) + Vector2(0, -6), -7)
	_sprite(DUNGEON, SKULL, _center(Vector2i(r.end.x - 2, r.end.y - 1)), -7)
	_sprite(DUNGEON, SKULL, _center(Vector2i(r.end.x - 1, r.end.y - 1)) + Vector2(-6, 6), -7).rotation = 0.6
	_sprite(POTTERY, Rect2(0, 16, 16, 16), _center(Vector2i(r.position.x, r.end.y - 1)), -7)
	_sprite(POTTERY, Rect2(16, 16, 16, 16), _center(Vector2i(r.position.x + 1, r.end.y - 1)), -7)
	_tile(Town.CANDLE, Vector2i(r.end.x - 1, r.position.y + 1), -7)
	_light(_center(Vector2i(r.end.x - 1, r.position.y + 1)), Color(0.9, 0.7, 1.0), 0.9, 0.45)
	# Száradó fűcsomók a mennyezet gerendáján.
	var herbs := Herbs.new()
	herbs.position = Vector2(r.position.x * TILE, r.position.y * TILE + 34)
	herbs.width = r.size.x * TILE
	herbs.z_index = 2
	add_child(herbs)
	_cobweb(r.position, false, false, -7)
	_cobweb(Vector2i(r.end.x - 1, r.position.y), true, false, -7)
	_cobweb(Vector2i(r.position.x, r.end.y - 1), false, true, -7)


func _witch_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 3.0)
	for i in 4:
		var frame := AtlasTexture.new()
		frame.atlas = WITCH_SHEET
		frame.region = Rect2(i * 16, 0, 16, 28)
		frames.add_frame("default", frame)
	return frames


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_prompt = MenuStyle.title_label("", 32, MenuStyle.GOLD)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -210
	_prompt.offset_bottom = -160
	_prompt.offset_left = -500
	_prompt.offset_right = 500
	_prompt.modulate.a = 0.0
	layer.add_child(_prompt)


## Ami előtt a játékos áll: [művelet, felirat] vagy [].
func _focus() -> Array:
	if not is_instance_valid(_player) or _busy:
		return []
	var at: Vector2 = _player.global_position
	match _where:
		"outside":
			if at.distance_to(door_position()) < INTERACT_RANGE:
				return ["enter", "[E] Belépés: boszorkánykunyhó"]
		"hut":
			if at.distance_to(_center(INTERIOR_DOOR)) < INTERACT_RANGE:
				return ["leave", "[E] Kilépés a szabadba"]
			if at.distance_to(_center(WITCH_TILE) + Vector2(0, 14)) < WITCH_RANGE:
				return ["witch", "[E] Beszélgetés: %s" % WITCH_NAME]
	return []


func _process(delta: float) -> void:
	var focus := _focus()
	if not focus.is_empty():
		_prompt.text = focus[1]
	var target := 1.0 if not focus.is_empty() and not GamePause.active(get_tree()) else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or GamePause.active(get_tree()):
		return
	var focus := _focus()
	if focus.is_empty():
		return
	get_viewport().set_input_as_handled()
	match focus[0]:
		"enter":
			_move("hut", _center(INTERIOR_DOOR) + Vector2(0, -TILE), INTERIOR, HUT_LIGHT)
		"leave":
			_move("outside", door_position() + Vector2(0, 24), Rect2i(), Color.BLACK)
		"witch":
			Audio.play("ui_open")
			_camp.get_node("Menus").call("open_menu", _dialogue)


## Átlépés: a kamera a szoba határaihoz igazodik (üres = szabadtér); bent erősebb a lámpás.
func _move(where: String, at: Vector2, room: Rect2i, light: Color) -> void:
	_busy = true
	_where = where
	Audio.play("door_unlock", -4.0)
	var limits := Rect2()
	if room.has_area():
		limits = Rect2(Vector2(room.position - Vector2i(3, 3)) * TILE, Vector2(room.size + Vector2i(6, 6)) * TILE)
	_camp.call("teleport_player", at, limits, light)
	await get_tree().create_timer(0.25).timeout
	_player.get_node("PointLight2D").energy = LANTERN_OUTSIDE if where == "outside" else LANTERN_INSIDE
	await get_tree().create_timer(0.3).timeout
	_busy = false


# ---------------------------------------------------------------- segédek

func _center(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE


## Egy csempe a Kenney RPG lapról (16 px + 1 px hézag), 2x-es nagyításban.
func _tile(coords: Vector2i, tile: Vector2i, z: int, parent: Node = null) -> Sprite2D:
	return _sprite(RPG, Rect2(Vector2(coords) * 17.0, Vector2(16, 16)), _center(tile), z, parent)


func _sprite(texture: Texture2D, region: Rect2, at: Vector2, z: int, parent: Node = null) -> Sprite2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.scale = Vector2(2, 2)
	sprite.position = at
	sprite.z_index = z
	(parent if parent else self).add_child(sprite)
	return sprite


func _body(parent: Node2D, offset: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = size
	shape.shape = box
	shape.position = offset
	body.add_child(shape)
	parent.add_child(body)


func _solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	add_child(body)


func _light(at: Vector2, color: Color, size: float, energy: float) -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(0, 0, 0, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	texture.width = 256
	texture.height = 256
	var light := PointLight2D.new()
	light.texture = texture
	light.texture_scale = size
	light.energy = energy
	light.position = at
	add_child(light)


func _dark_rect(rect: Rect2, z: int, color: Color) -> void:
	var dark := ColorRect.new()
	dark.color = color
	dark.position = rect.position
	dark.size = rect.size
	dark.z_index = z
	add_child(dark)


func _cobweb(tile: Vector2i, flip_h: bool, flip_v: bool, z: int) -> void:
	var web := Sprite2D.new()
	web.texture = COBWEB
	web.scale = Vector2(2, 2)
	web.position = _center(tile)
	web.flip_h = flip_h
	web.flip_v = flip_v
	web.z_index = z
	web.modulate = Color(1, 1, 1, 0.8)
	add_child(web)


## Lassan felszálló, szétterülő füst a kéményből (zöldes árnyalattal).
func _smoke(at: Vector2) -> CPUParticles2D:
	var smoke := CPUParticles2D.new()
	smoke.position = at
	smoke.z_index = 3
	smoke.amount = 14
	smoke.lifetime = 3.0
	smoke.direction = Vector2(0.3, -1)
	smoke.spread = 12.0
	smoke.gravity = Vector2(6, -8)
	smoke.initial_velocity_min = 12.0
	smoke.initial_velocity_max = 20.0
	smoke.scale_amount_min = 4.0
	smoke.scale_amount_max = 9.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.5, 0.65, 0.45, 0.55))
	ramp.set_color(1, Color(0.35, 0.4, 0.35, 0.0))
	smoke.color_ramp = ramp
	return smoke


## Zöld gőz és buborékok az üst fölött.
func _steam(at: Vector2) -> CPUParticles2D:
	var steam := _smoke(at)
	steam.amount = 18
	steam.lifetime = 1.6
	steam.direction = Vector2(0, -1)
	steam.spread = 20.0
	steam.gravity = Vector2(0, -12)
	steam.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	steam.emission_rect_extents = Vector2(14, 2)
	steam.scale_amount_min = 2.0
	steam.scale_amount_max = 5.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color(BREW, 0.7))
	ramp.set_color(1, Color(0.3, 0.7, 0.3, 0.0))
	steam.color_ramp = ramp
	return steam


## Kis tűz az üst alatt (lobogó lángnyelvek).
class Fire:
	extends Node2D
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(-16, -2, 32, 5), Color(0.25, 0.15, 0.1))
		for i in 5:
			var x := -12.0 + i * 6.0
			var tall := 8.0 + 4.0 * sin(_t * 9.0 + i * 1.7)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 4, 0), Vector2(x, -tall), Vector2(x + 4, 0)]),
				Color(1, 0.5, 0.1, 0.9))
			draw_colored_polygon(PackedVector2Array([Vector2(x - 2, 0), Vector2(x, -tall * 0.55), Vector2(x + 2, 0)]),
				Color(1, 0.9, 0.4))


## Száradó fűcsomók egy zsinóron a mennyezet alatt (zöld, barna, lila csokrok).
class Herbs:
	extends Node2D
	var width := 300.0

	func _draw() -> void:
		draw_line(Vector2(0, 0), Vector2(width, 0), Color(0.35, 0.25, 0.15), 2.0)
		var colors: Array[Color] = [Color(0.35, 0.55, 0.25), Color(0.5, 0.4, 0.25), Color(0.5, 0.35, 0.55),
			Color(0.45, 0.6, 0.3)]
		var x := 22.0
		var i := 0
		while x < width - 16.0:
			var color := colors[i % colors.size()]
			var length := 14.0 + (i * 7 % 9)
			draw_line(Vector2(x, 0), Vector2(x, 5), Color(0.35, 0.25, 0.15), 1.5)
			for leaf in 5:
				var spread := (leaf - 2) * 2.2
				draw_line(Vector2(x, 4), Vector2(x + spread, 4 + length - absf(spread)), color.darkened(leaf * 0.06), 2.0)
			x += 34.0 + (i * 13 % 11)
			i += 1
