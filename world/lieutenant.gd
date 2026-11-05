class_name Lieutenant
## Vas Szilárd hadnagy a barakkban (Barracks): kemény, szigorú veterán (nem sebesült), a Harmadik Lándzsás Ezred
## maradékának parancsnoka. Fiatal őrmesterként Gáspár alatt szolgált, és ma is tiszteli. Küldetései a kocsmárosé
## mellett futnak (Quests, "giver": "lieutenant", nehezebbek), a jutalmat nála veszed át (QuestPanel), és minden
## leadott küldetés után két új történetet mond (AFTER_STORIES), új irányokba: az ezred, a határ, a király, a mélyből
## jövő jelek.

const ID := "lieutenant"
const NAME := "Vas Szilárd hadnagy"
const SHEET: Texture2D = preload("res://assets/characters/officer.png")

const GREETING := "[i]Egy szálfa egyenes, ősz halántékú tiszt áll az asztalfőn, a térképek fölött. Fekete páncélján " \
	+ "egy karcolás sincs, a csizmája tükörfényes. Rád néz, és egy pillanat alatt felmér: a fegyveredet, a " \
	+ "tartásodat, a sáros csizmádat.[/i]\n\nVigyázz! ...Ja, te nem az enyém vagy. Mondd, mit akarsz, és ne lopd az időmet."

## Mindig elérhető történetek.
const STORIES: Array[Dictionary] = [
	{"id": "who", "text": "Ki vagy te?", "trust": 3,
		"answer": "Vas Szilárd, hadnagy. A Harmadik Lándzsás Ezred parancsnoka. Pontosabban annak, ami " \
			+ "maradt belőle: harmincnégy ember, ebben a sátorban.\n\n[i]Összefonja a karját.[/i]\n\n" \
			+ "Húsz éve szolgálok. Egyszer sem sebesültem meg komolyan, és nem szerencséből. Fegyelemből. " \
			+ "Aki betartja a szabályt, az hazamegy. Aki nem, azt hazaviszik."},
	{"id": "barracks", "text": "Miért sátorban laktok, nem a várban?", "trust": 3,
		"answer": "Mert a király így döntött. A vár falai közt a testőrség lakik, a díszes egyenruhások. Mi a " \
			+ "kapun kívül vagyunk, hogy ha valami feljön a Mélységből, először minket találjon.\n\n" \
			+ "[i]Megkopogtatja a sátorrudat.[/i]\n\nNem panasz. Egy katona ott alszik, ahová állítják. " \
			+ "Csak jegyezd meg: a vár és a Mélység között most mi vagyunk. Meg te."},
	{"id": "gaspar", "text": "Ismered Gáspárt, a veteránt?", "trust": 4,
		"answer": "[i]Egy pillanatra megáll. A hangja halkabb lesz, de nem lágyabb.[/i]\n\n" \
			+ "Gáspár őrmester alatt kezdtem. Tizenhét éves voltam, és azt hittem, a kard a legfontosabb. " \
			+ "Ő tanított meg rá, hogy a pajzs az. Hogy a melletted állót véded, nem magadat.\n\n" \
			+ "Ha a táborban látod, ne nevezd öregnek. Én sem merem. És ne kérdezd a huszadikról. Majd " \
			+ "elmondja, ha akarja."},
]

## A leadott küldetések után (Quests id -> két történet). A legutóbbi kerül előre.
const AFTER_STORIES := {
	"lt_drill": [
		{"id": "drill_rules", "text": "Mi a legfontosabb szabályod?", "trust": 3,
			"answer": "Három van. Egy: soha ne menj be egy szobába úgy, hogy nem tudod, hol a kijárat. Kettő: a " \
				+ "sebesültet nem hagyod hátra. Három: ha egy parancs ostobaság, előbb végrehajtod, aztán panaszt " \
				+ "teszel.\n\n[i]Egy hosszú másodpercig hallgat.[/i]\n\nA harmadikat Gáspártól tanultam. Ő maga " \
				+ "nem tartotta be. Ezért él még."},
		{"id": "drill_recruits", "text": "Honnan jönnek az újoncaid?", "trust": 3,
			"answer": "Sehonnan. Évek óta nem jött egy sem. A falvakban azt mesélik, hogy aki a Mélység mellé " \
				+ "katonának áll, az a Mélységé lesz.\n\n[i]Megvetően horkant.[/i]\n\nBabona. De a babona is " \
				+ "fegyver, ha az ellenség kezében van. Valaki terjeszti ezeket a meséket. És én tudni akarom, ki."},
	],
	"lt_frost_line": [
		{"id": "frost_north", "text": "Jártál már ilyen hidegben?", "trust": 3,
			"answer": "Az északi határon, a Hóhatárnál. Két telet töltöttünk ott, a jégbarlangok szájánál. " \
				+ "Azt mondták, csak farkasok jönnek ki onnan.\n\n[i]A térkép egy fehér foltjára bök.[/i]\n\n" \
				+ "Nem farkasok voltak. Ugyanaz a dér volt a szőrükön, amit te most a Fagykőből hozol a " \
				+ "csizmádon. Ezt a térképet azóta senki nem akarja látni a várban."},
		{"id": "frost_link", "text": "A Mélység az északi határig ér?", "trust": 4,
			"answer": "Nem tudom. És egy tiszt nem mondja ki, amit nem tud.\n\nDe feljegyeztem minden jeges " \
				+ "lényt, amit az ezred megölt, és hogy hol. A pontok egy vonalra esnek. Innen, a kazamata " \
				+ "lejáratától egyenesen észak felé.\n\n[i]Összehajtja a térképet.[/i]\n\nMaradjon köztünk. " \
				+ "Egyelőre."},
	],
	"lt_war_chest": [
		{"id": "chest_pay", "text": "Mire kell az ezrednek ennyi pénz?", "trust": 3,
			"answer": "Zsoldra. Fél éve nem kaptunk. A kincstárnok szerint \"a háború nem hivatalos\", így a " \
				+ "zsold sem jár.\n\n[i]A szája sarka megrándul.[/i]\n\nAz embereim nem hivatalosan halnak meg " \
				+ "odalent. Abból, amit felhoztál, mindenki kap. Én utoljára."},
		{"id": "chest_ledger", "text": "Mi ez a vastag könyv az asztalon?", "trust": 3,
			"answer": "A hadi napló. Minden nap, minden őrség, minden halott. Az első lapot még Gáspár írta, amikor " \
				+ "az ezred először ment le.\n\nAz utolsó tíz évben a halottak oldala vastagabb lett, mint az " \
				+ "élőké. Ha egyszer valaki számon kéri a királytól, mi történt itt, ezt a könyvet fogom az " \
				+ "asztalára tenni."},
	],
	"lt_officer": [
		{"id": "officer_rank", "text": "Hogyan lettél tiszt?", "trust": 3,
			"answer": "Egy rossz éjszakán. A tizennegyedik emeleten ránk szakadt a mennyezet, a hadnagyunk " \
				+ "alatta maradt. Valakinek parancsot kellett adnia. Én adtam.\n\n" \
				+ "Reggelre heten maradtunk, de heten feljöttünk. Gáspár másnap a saját rangjelzését tűzte a " \
				+ "mellemre. Azt mondta, a rang nem kitüntetés, hanem teher.\n\n[i]Megérinti a jelvényt.[/i]\n\n" \
				+ "Igaza volt. Mint mindig."},
		{"id": "officer_you", "text": "Mit gondolsz rólam?", "trust": 2,
			"answer": "[i]Végigmér, tetőtől talpig.[/i]\n\nRendetlen vagy. A táskád tele van " \
				+ "ilyen-olyan kacatokkal, a pajzsodat rosszul fogod, és egyedül mész le, ami öngyilkosság.\n\n" \
				+ "És mégis mindig visszajössz. Azt nem tudom, hogyan. De ha egyszer beállsz az ezredbe, a " \
				+ "saját századomat adom alád. Ezt nem mondom kétszer."},
	],
	"lt_fiftieth": [
		{"id": "fifty_deserters", "text": "Szöktek már meg emberek az ezredből?", "trust": 3,
			"answer": "Hárman. Egy éjszaka eltűntek, a fegyvereikkel együtt. A nyomuk a kazamata lejáratához " \
				+ "vezetett. Lefelé.\n\n[i]Az arca kemény marad.[/i]\n\nNem a félelem vitte őket. A félős katona " \
				+ "felfelé szökik. Ezek valamit hallottak odalent. Ha a mélyben három fegyveres emberrel " \
				+ "találkozol, akik az ezred jelvényét viselik... ne bízz bennük. És szólj nekem."},
		{"id": "fifty_voice", "text": "Mit hallhattak odalent?", "trust": 4,
			"answer": "Az egyik szökevény, Barta, az utolsó őrsége alatt ezt írta a hadi naplóba:\n\n" \
				+ "[i]\"A kövek alatt valaki számol. Egytől harmincig, újra és újra.\"[/i]\n\n" \
				+ "Azt hittem, a láz beszél belőle. Aztán a király gyűrűjén megláttam a harminc vésett nevet. " \
				+ "Nem tudom, mi köze a kettőnek egymáshoz. De nem hiszek a véletlenben."},
	],
	"lt_bosses": [
		{"id": "bosses_tactics", "text": "Hogyan győznél le egy főellenséget?", "trust": 3,
			"answer": "Sehogy. Egyedül senki nem győz le semmit. Az ezred győz.\n\nDe ha muszáj: figyeld a " \
				+ "lábát, ne a karmát. Mielőtt üt, a súlya átbillen. Ha látod, hogy átbillen, már ott sem vagy.\n\n" \
				+ "[i]Majdnem elmosolyodik.[/i]\n\nGáspár a pajzsával a tenyerébe vágott, valahányszor nem " \
				+ "figyeltem a lábát. Egy hónapig kék volt a kezem. Azóta figyelem."},
		{"id": "bosses_trophies", "text": "Nincsenek trófeáid?", "trust": 3,
			"answer": "Egy katona nem gyűjt koponyákat. Az a vadászok dolga, meg a hiú kalandoroké.\n\n" \
				+ "[i]Az övén lógó, kopott bőrzacskóra pillant.[/i]\n\nEbben harmincnégy kavics van, a " \
				+ "kazamata lejárata elől. Mindenkié, aki most a parancsnokságom alatt áll. Ha valaki nem jön " \
				+ "vissza, a kavicsát a sírjára teszem. Eddig hármat tettem le. Ennyi a trófeám."},
	],
	"lt_engine": [
		{"id": "engine_king", "text": "Mit szól a király a jelentéseidhez?", "trust": 3,
			"answer": "Semmit. Elolvassa, megköszöni, és a kandallóba teszi. Láttam.\n\n" \
				+ "[i]Kiegyenesedik.[/i]\n\nEgy katona nem bírálja a királyát. De egy katona emlékszik. És én " \
				+ "emlékszem, hogy amikor Gáspár emberei a huszadikon odavesztek, a vár aznap este bált tartott."},
		{"id": "engine_plan", "text": "Van terved arra, ha a Mélység feljön?", "trust": 4,
			"answer": "Van. Három vonal: a barakk, a tábor és a kocsma. A kocsmáros pincéjében ötven lándzsa " \
				+ "van elrejtve, Ambrus tudja, hol. Bertalan liftjét két perc alatt le tudjuk vágni.\n\n" \
				+ "[i]Rád néz.[/i]\n\nEzt most te is tudod. Ha egyszer megszólal a vészkürt, ne a királyt " \
				+ "keresd. Engem."},
	],
	"lt_hellfire": [
		{"id": "hell_respect", "text": "Mit mondanál Gáspárnak, ha most itt lenne?", "trust": 4,
			"answer": "[i]Sokáig nem felel. Aztán leveszi a kesztyűjét, és az asztalra teszi.[/i]\n\n" \
				+ "Hogy jelentem: az ezred áll. Harmincnégy ember, egy sem dezertált a tavasz óta. A hadi napló " \
				+ "naprakész. És hogy a pajzsot ma is úgy fogom, ahogy tanította.\n\nAztán valószínűleg rám " \
				+ "szólna, hogy ne álljak vigyázzban egy bekötött fejű öreg előtt. És én akkor is vigyázzban állnék."},
		{"id": "hell_end", "text": "Mi lesz az ezreddel, ha egyszer vége ennek?", "trust": 3,
			"answer": "Nem lesz vége. A Mélység nem háború, amit meg lehet nyerni. Inkább olyan, mint a gát: " \
				+ "valakinek mindig rajta kell állnia.\n\n[i]Kinéz a sátor nyílásán, a vár felé.[/i]\n\n" \
				+ "De ha egyszer mégis, akkor hazaviszem az embereimet. Mindegyiket, a kavicsokat is. És a " \
				+ "hadi naplót a király asztalára teszem. Az lesz az utolsó parancs, amit végrehajtok."},
	],
}


## A beszélgetés opciói: elöl a parancsok (a küldetések ablaka), aztán a legutóbb teljesített küldetések
## utáni történetek (a legújabb elöl), végül az alap történetek.
static func options(open_orders: Callable) -> Array[Dictionary]:
	var ready := Quests.ready_ids(ID).size()
	var list: Array[Dictionary] = [{"id": "orders",
		"text": ("Jelentkezem! Teljesítettem a parancsot (%d)." % ready) if ready > 0 else "Mi a parancs? (küldetések)",
		"on_choose": open_orders}]
	var ids := Quests.ids_of(ID)
	ids.reverse()
	for id in ids:
		if Progress.quests_done.has(id) and AFTER_STORIES.has(id):
			for story: Dictionary in AFTER_STORIES[id]:
				list.append(story)
	list.append_array(STORIES)
	return list


static func frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 3.0)
	for i in 4:
		var frame := AtlasTexture.new()
		frame.atlas = SHEET
		frame.region = Rect2(i * 16, 0, 16, 28)
		frames.add_frame("default", frame)
	return frames


static func portrait() -> AtlasTexture:
	var frame := AtlasTexture.new()
	frame.atlas = SHEET
	frame.region = Rect2(0, 0, 16, 28)
	return frame
