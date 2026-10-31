class_name News
## A főmenü "Újdonságok" doboza (jobb oldalt, lásd MainMenu._build_news): minden változtatásnál ide kerül egy
## rövid, játékosnak szóló sor a legfrissebb dátum alá (a legújabb van felül).

const ENTRIES: Array[Dictionary] = [
	{"date": "2026-10-31", "items": [
		"Figyelmeztetések: ha egy szörny vagy főellenség teleportálni készül, piros X mutatja, hová érkezik; ha rohamozni készül, piros vonal mutatja az irányát.",
		"Javítva: a hosszú feliratok és jegyzetek (pl. Lőrinc jegyzetei) görgethetők, nem lógnak ki a képből; Lőrinc új levele felül van.",
		"Ha Lőrinc már a kocsmába költözött, a rács kulcsát a kút alatti műhelye asztalán hagyja egy levéllel; az Őrző után oda tedd vissza a jutalomért.",
		"Javítva: Puskás Döme most már ott vár a kút alján, ha a tűzhangyák után nem töltötted újra a tábort (a beomlott járatnál is szólhatsz neki).",
		"Holló Margit, a boszorkány története folytatódik: 4 új küldetés (összesen 5), mindegyik után 3 új beszélgetés. A Test manipulálása mostantól a 3. küldetés után nyílik meg.",
		"Lőrinc műhelyének rácsos lépcsője kinyílt: kérdezd meg Lőrincet, mi van mögötte. Odalent 5 emelet és egy háromszáz éves őr vár, jutalma egy egyedi talizmán.",
	]},
	{"date": "2026-10-30", "items": [
		"Az első 15 emeleten a ládák sosem üresek.",
		"A találati esély egyelőre kikerült a játékból: minden ütésed és lövésed talál (a szörnyek kikerülése maradt).",
		"Zeneválasztó: a kiválasztott szám ismétlődik, amíg újra rá nem kattintasz.",
		"A szobád trófeafala közelről is megnézhető (E): kattints egy főellenségre, és a karaktered elmondja, mit gondol róla. Mindenkinek más a véleménye a nagyokról.",
		"Javítva: Bertalan aknáinál számít, ha már korábban (csalás nélkül) jártál azon az emeleten: rögtön fizethetsz neki, és utána ott a lift.",
		"Javítva: Bertalan liftje most már ott áll minden megnyitott liftes emeleten (20-80.), a nagy főellenséges emeleteken a kezdőszobában.",
		"Javítva: a szünet menü zeneválasztója nem lóg ki a képből (a hosszú címek két sorba törnek).",
		"Javítva: a szobád trófeafalán a főellenségek képei két sorban, kilógás nélkül férnek el.",
		"Működik a boszorkány Test manipulálása: aranyért és porért végleg erősíti a képességeidet, szintenként 1,5× annyival, mint a kiképzősátor, és bármeddig fejleszthető (a korlátos képességek, pl. kikerülés, nyilak, csak a korlátjukig).",
		"Holló Margit, a boszorkány küldetést ad: vigyél neki egy Vámpírfogat! Utána új történeteket mesél, és szóba kerül a test manipulálása is (hamarosan).",
		"A Küldetések könyvének fülei két sorba kerültek (új fül: Boszorkány).",
		"Új hely: a romos ház tisztása lejjebb nyúlik, az alján boszorkánykunyhó áll (bent rotyog az üst, Holló Margit mesél). Odatalálsz a tábor nyugati szélén álló kettős táblával.",
		"A főmenünek saját, epikus zenéje lett (a zeneválasztóban az Egyéb alatt is lejátszható).",
		"Gyorsabb játék: nem akad meg a harc sok ölésnél, a csalómenü tárgylistája és a könyvek azonnal nyílnak, és rövidebb a lejutás a kazamatába.",
		"Javítva: A harminc név gyűrűjének hiányzott az ikonja.",
		"Javítva: a Szörnyek könyvéből nem lóg ki többé a lap (a hosszú leírású szörnyek, pl. Azazel, saját lapot kapnak).",
		"Bertalan, a mérnök tovább építi a liftet: a táborban fejezetenként elvállalhatod a 20., 30., 40., 50., 60., 70. és 80. " \
			+ "emeleti aknát (leérsz arra az emeletre, aztán kifizeted tábori aranyból). A 80. alá nem visz lift.",
		"A lift ablakában a még zárt emeleteken lakat látszik.",
		"A kovácsnak neve lett (Ambrus): E-re beszélget, 4 történetet mesél, és az első opcióval nyílik a műhelye.",
	]},
	{"date": "2026-10-29", "items": [
		"Rossz befejezés: ha Azazel ellen elesel, 9 képen, pokoli zenével kiderül, mi történt volna a királysággal.",
		"A pokol kapuja új kinézetet kapott (izzó, animált kőkapu), és a belépéskor nincs többé hosszú zúgás.",
		"A pokol útján elesett harcosok fekszenek, mellettük a fegyvereik (balta, buzogány, lándzsa, íj...), és sok csont.",
		"A pokolnak saját, epikus zenéje van, ami folyamatosan szól (Azazel harcában az ő zenéje marad).",
		"Javítva: a szintlépés kártyái néha a képernyő aljáig megnyúltak (pl. Vendel Fürgeség-kártyájánál).",
		"Befejező kisfilm: Azazel legyőzése után minden karakternek saját, 6 képes története van arról, mi lett vele " \
			+ "a jövőben, saját zenével (a zeneválasztóban: Befejezések).",
		"A pokol urának új neve: Azazel, a Halálangyal és Démonkirály.",
		"Javítva: Azazel trónterme a harc kezdetén most teljesen bezárul (a bejárat keskeny folyosó lett, a tüskék lezárják).",
		"A király története a végéig folytatódik: a Káosz Ura után három új fejezet (Dübörgés a jég alatt, Az alapító "
			+ "titka, A harminc név ára). Kiderül, mit kötött az alapító király a mélységgel, és mi volt Gáspár harminc "
			+ "emberének ára. A végén a király gyűrűje a tiéd, és utána is van mit kérdezni tőle.",
		"Csalómenü: a teleportba a 100. emelet is beírható, és új csalás a végtelen sebzés: minden ütésed egyből megöl.",
		"A 100. emeleten vörösen izzó, ismeretlen kapu vár. Mögötte a pokol: egyenes, tüzes út, a végén Azazel, "
			+ "a Démonkirály. Beszélgethetsz vele (öt titok a kazamatáról), aztán jöhet a végső harc: 30 000 000 élet, "
			+ "meteorok, lelkek spirálja, láncok, tűzoszlopok, a mélység örvénye és démonlégió — saját zenével. "
			+ "Új eredmény: A Démonkirály bukása.",
		"Új nagy főellenség a 80. emeleten: a Pokolkapu Őre, egy háromfejű, láncra vert pokolkutya (25 000 000 élet). "
			+ "Lángcsóva, méregköpet, követő árnyékgömbök, lánccsapás, lávarepedések, és ha felvonyít, jön a falka — "
			+ "saját hangokkal és egy sötét, csak ebben a harcban szóló zenével. Új eredmény: A kapu nyitva.",
		"Új ellenség a Népek közt a 14. emelettől: az őrült bohóc. Vihogva ugrál, és nagyon sűrűn ront neked.",
		"Új nagy főellenség a 60. emeleten: az Ősgépezet, egy ősrégi, sárgaréz lépegető gép (10 000 000 élet, "
			+ "nincs második fázisa). Gőzkitörés, fogaskerék-fűrészek, dugattyú-rengés, Tesla-villámok, mágneses "
			+ "rántás — saját gépies hangokkal és egy epikus zenével, ami csak ebben a harcban szól.",
		"A Jégkirálynő az 51. emeletre költözött; új eredmény: Óramű-leállás.",
		"A Vérkő démonjainak saját hangjuk lett: a pokolkutya ugat és vonyít, a pokolfajzat hörög, a lidércló "
			+ "fújtat, a pokolúr bömböl; vadászat közben időnként hallatják magukat, és saját halálhörgésük van.",
	]},
	{"date": "2026-10-28", "items": [
		"32 új lövészfelszerelés: minden sisakból, mellvértből, nadrágból, cipőből, kesztyűből, gyűrűből, amulettből "
			+ "és talizmánból 4 (átlagostól legendásig), mind távolsági sebzést ad, saját új képpel.",
		"A Vérkő lakói (81. emelettől): négy igazán erős démon — pokolkutya (falkában ront rád), pokolfajzat "
			+ "(tűzgolyó-legyező), lidércló (lángsörényű paripa, nekivágtat) és pokolúr (pokolkutyákat hív, pajzs, "
			+ "gyógyítás). Ők adják a mélység szörnyeinek majdnem felét.",
		"Eredmények könyve: új, harmadik állvány a táborban, 49 teljesítménnyel (szörnyirtás, szörnyfajták, mélység, küldetések, "
			+ "gyűjtés ritkaság szerint, tábori fejlesztések, főellenségek); mindegyikért arany, a nehezebbekért egy kis por is.",
		"A Tárgyak könyve fülenként jutalmat ad (25%, 50% és 100% után: arany és egy kis por).",
		"A három könyv állványa arrébb került, a tábor nyugati, füves részére, egy kitaposott földfoltra.",
	]},
	{"date": "2026-10-27", "items": [
		"Tárgyak könyve: új állvány a Szörnyek könyve mellett. Minden tárgy, amit valaha megszereztél, bekerül "
			+ "(statokkal és leírással), a többi sötét árnyékként várja, hogy megtaláld.",
		"A kút alatti járat: Döme új küldetése (tűzhangya-mirigyek), aztán a kút alján felrobbantja a törmeléket; "
			+ "mögötte Lőrinc régi műhelye (jegyzetek, láda: Lőrinc iránytűje), egy rejtélyes rácsos lépcső, és "
			+ "Lőrinc három új története.",
		"Ábel csónakja új képet kapott, és a tó déli részén, a móló mellett ring; átkeléskor beszállsz, a csónak "
			+ "átevez a szigetre, ott kiszállsz (és ugyanígy vissza).",
		"A tó titka: Öreg Ábel új küldetéssora (a kis zár kulcsa a kalózoktól, átkelés a csónakkal a szigetre), "
			+ "a sziget lépcsője alatt az elárasztott kripta (4 emelet), a legalján a Tófenék Ura; jutalom: "
			+ "A tófenék gyöngye, és Ábel három új története.",
		"A Fagykő lakói (41–80. emelet): jégszellem, jégpók, hógólem és fagyott lovag; a 60. emeleten a Jégkirálynő.",
		"Új mélységi sorrend: a 21. emelettől a lila Káoszkő, a 41.-től az új Fagykő (jégkék kripta, cián fényű "
			+ "repedések, fagyott kutak, hulló hópelyhek), a 81.-től a vöröses Vérkő.",
		"A nagy térkép (M) jelmagyarázata már nem lóg ki az ablakból.",
		"Zeneválasztó a szünet menüben (Esc → ♪ Zene, jobb oldalt): bármelyik zenét lejátszhatod, kategóriákra "
			+ "bontva (bárhol szóló, tábor, város, bánya, kazamata, mélység, káosz, próbatétel, egyéb).",
		"Új kinézet a mélyben: a 21. emelettől Vérkő (vöröses kő, parázsló repedések, szálló hamu), a 41.-től Káoszkő "
			+ "(fekete-ibolya obszidián, lila lángú fáklyák) — emeletről emeletre egyre sötétebb.",
		"Helyszínenként saját zene (tábor, város, bánya, kazamata, mélység, próbatétel), és pár szám mindenhol szól; "
			+ "négy új, sötétebb zene a mélyre és a táborra.",
		"Öt új zene a tábor és a kazamata lejátszási listáján (epikus és misztikus, mind CC0).",
		"Öt új bogár a kazamatában: tűzhangya, dongóbogár, katonahangya, óriás lódarázs és barlangi skorpió.",
		"Új főellenség a 36. emeleten: a Skorpiókirály (méregköpés, mérges tócsák, roham, skorpióhad).",
		"A kopogás titka: Kormos Gyula küldetéssora a bánya mélyén, a végén a Kopogóval (egyedi főellenség) "
			+ "és A huszonhét lámpása jutalommal.",
		"A próbatétel nehézsége hatfokú (Nagyon könnyű – Brutális), és sokkal nagyobb eséllyel ad mítikus tárgyat "
			+ "(a Brutálisnál 30%).",
		"Próbatétel: random kazamata a bánya mélyén (1–20 emelet, könnyítések és nehezítések, biztos jutalom a végén; "
			+ "10 percenként új).",
		"A kocsmáros küldetésablaka már nem lóg ki a képből.",
		"Puskás Döme, a robbantómester: küldetések, és hidat robbant a bánya szakadéka fölé.",
		"Kibérelhető szoba a kocsmában: ágy (+1 bájital a következő futásra), láda, trófeafal.",
		"Szűrők a küldetések könyvében (J).",
		"30 új kocsmai küldetés (összesen 100).",
		"Kálmán doktor két új küldetése és négy új története.",
		"Mítikus tárgyak fejlesztése mítikus porral (legfeljebb ötször).",
		"Bemehetsz a bányába: alagút, barlangterem, leszakadt híd a szakadék fölött.",
		"Beszélgethetsz a kocsmárossal; a kocsma hátsó folyosóján kiadó szobák.",
	]},
	{"date": "2026-10-26", "items": [
		"Zene a táborban és a kazamatában (5 szám), bal alul kiírja, mi szól.",
		"Három új káoszszörny a 25. emelet után.",
		"A város ládái és hordói már nem átjárhatók.",
		"A király új küldetése (A Káosz kapuja) és négy új története.",
		"Utak minden házhoz, útjelző táblák, a bánya hegye.",
		"Új tutorial saját pályával és tábori bemutatóval.",
		"Kovácsműhely: tárgyfejlesztés és szétszedés porokért.",
	]},
]


## Az egész lista BBCode-ban (dátum aranyszínnel, alatta a pontok).
static func bbcode() -> String:
	var lines: Array[String] = []
	for entry: Dictionary in ENTRIES:
		lines.append("[color=#e8c36a][b]%s[/b][/color]" % entry["date"])
		for item: String in entry["items"]:
			lines.append("• " + item)
		lines.append("")
	return "\n".join(lines).strip_edges()
