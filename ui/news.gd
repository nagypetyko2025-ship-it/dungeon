class_name News
## A főmenü "Újdonságok" doboza (jobb oldalt, lásd MainMenu._build_news): minden változtatásnál ide kerül egy
## rövid, játékosnak szóló sor a legfrissebb dátum alá (a legújabb van felül).

const ENTRIES: Array[Dictionary] = [
	{"date": "2026-11-07", "items": [
		"Vas Szilárd hadnagy 8 új parancsot ad (összesen 16): árulók, óriások, káoszfront, sárkányok, 5000 szörny, "
			+ "30. szint és a Pokolkapun túl; mindegyik után két új történettel.",
		"A hadnagy újabb 8 parancsot ad (összesen 24): kalózok, varázslók, élőholtak, démonok, 600 szoba, 100 főellenség, "
			+ "60000 arany és a 99. emelet, mindegyik után két történettel. A szintes parancsai nehezebbek lettek "
			+ "(Tiszti rang: 50., Veterán: 80. szint).",
	]},
	{"date": "2026-11-05", "items": [
		"Futás végi összesítő: halálkor és győzelem után látod, ki ölt meg, melyik szörnyből győztél le a legtöbbet, "
			+ "milyen kártyákat vettél fel (ritkaság szerint színezve) és mi volt rajtad a végén.",
		"Az összesítő azt is kiírja, ha csapda vagy mérgezés végzett veled.",
		"Öt új ritka felszerelés: Szegecselt harci kesztyű (epikus), Éjvadász kesztyű, Hadúr vaskesztyűje, "
			+ "Orgyilkos csizma és Obszidián lábvért (mind legendás).",
		"Sárga felkiáltójel lebeg azok feje fölött, akik küldetést vagy történetet adnak; az első beszélgetés után eltűnik.",
		"Bertalan minden liftszint után 1-3 új történetet mesél (a már megnyitott szintekét rögtön), és a liftes szövegei "
			+ "pontosabbak lettek (a 21-40. emelet Káoszkő, a 41.-től Fagykő).",
		"Kikerült a hordágyas katonák bejátszása.",
		"Új épület: katonai barakk a királyi vár alatt, az úttól balra (nagy zöld sátor priccsekkel és katonákkal).",
		"A barakkban Vas Szilárd hadnagy vár: 8 nehéz és elit parancs (a kocsmárosénál keményebbek), és mindegyik után "
			+ "új történeteket mesél az ezredről, a határról, a királyról és Gáspárról.",
	]},
	{"date": "2026-11-04", "items": [
		"Két új nadrág: Lápjáró nadrág (ritka: kikerülés, regeneráció, gyorsaság) és Lángtáncos nadrág (legendás: sebzés, "
			+ "gyorsaság, kikerülés, de kevesebb védelem).",
		"Két új szörny: a Szürke farkas (az 5. emelettől, gyors, cikázik és nekiront) és a Lángkoponya (a 17. emelettől, "
			+ "lángoló repülő koponya, ami halálakor szétrobban). Mindkettő bekerült a Szörnyek könyvébe.",
		"A Vérfarkas a terem közepén vár emberként, piros védőkörben: amíg át nem változik, nem lehet megsebezni, és nem "
			+ "lehet a közelébe menni. Csak akkor kezd átváltozni, amikor már látod, így mindig végignézheted.",
		"A Vérfarkas kisebb lett (túl nagy volt), és a karmolás vagy a csapás után már nem csúszik állva a padlón: a "
			+ "mozdulata végéig áll, csak utána indul el.",
		"Új külsőt kapott a Vérfarkas, a Mélység Ura (20. emelet): a régi, erősen kockás rajz helyett részletes, sötét "
			+ "bundájú farkas. Emberként jelenik meg és előtted változik át, karmol és lecsap (látszik a mozdulat), rohamnál "
			+ "nekiiramodik, legyőzve összerogy, aztán feltápászkodik, és az igazi halála után egy ideig ott fekszik.",
	]},
	{"date": "2026-11-02", "items": [
		"A korlátos kártyákon szintlépéskor látszik, hányszor vetted már ki ebben a futásban (pl. \"Kivéve: 2 / 5\").",
		"A játék elején (a 10. karakterszintig) szintlépéskor csak átlagos kártyák jönnek, ritka és epikus csak utána.",
		"Olcsóbb újradobás szintlépéskor: 3 aranyról indul, és lassan drágul (a 10. kb. 7, a 20. kb. 18 arany; eddig a 10. "
			+ "már 344 aranyba került).",
		"30 új, egyszerű szintlépési kártya: kis bónusz, és nincs (vagy csak egy apró) hátrányuk, így az elején is szépen "
			+ "lehet erősödni (pl. +2 max élet, +3% ütési sebesség, +2% kritikus esély; ritkán két-három ilyen egyszerre). "
			+ "Szintlépéskor most szinte mindig van legalább egy hátrány nélküli kártya.",
		"Kártyák: az íjász nem kap közelharci, a többiek nem kapnak távolsági sebzés kártyát (semmi hasznuk nem volt).",
		"Kártya-szerkesztő: a beépített kártyák is átírhatók (✎ jelöli az átírtakat, az eredeti visszaállítható), és minden "
			+ "kártyán beállítható, egy futásban hányszor vehető ki (vagy végtelenszer). Ha elérted a korlátot, a kártya többet nem jön.",
		"Ritkább legendás és mítikus kártyák: eddig szintlépésenként kb. 9-13% eséllyel jött legendás és 4-5% eséllyel "
			+ "mítikus (ha egy ritkaságból nem volt választható kártya, az esélye a ritkábbakhoz adódott), most kb. 4,5% és 1%, "
			+ "és egy szintlépésen legfeljebb egy legendás vagy mítikus lehet.",
		"Kártya-szerkesztő: \"Összes beépített visszaállítása\" gomb — minden átírt alap kártya visszakapja az eredeti statjait.",
	]},
	{"date": "2026-11-01", "items": [
		"Javítva: a \"Lights at Night\" zene eleje 9 mp-ig néma volt, így kiválasztva úgy tűnt, nem szól — a néma részt kivágtuk.",
		"Javítva: a kocsmában Vendel (és minden hosszabb leírású karakter) bemutatkozó lapja kilógott a képernyőből, most kifér.",
		"A kocsmában ülő karakterekkel beszélgetni is lehet (E): mindenki mesél magáról, Gáspár, Bence, Vendel és Lőrinc a régi "
			+ "történeteit is elmondja (Lőrinc a kút és a legrégebbi bejárat utániakat is, amiket eddig nem lehetett meghallgatni, ha "
			+ "már a kocsmában ült), a lovagnak és az íjásznak új történetei vannak. Az első válasz, \"Indulunk?\", átveszi az irányítást.",
		"Javítva: a gyakorlás indításakor a tiszta lap sosem kerülhet a mentésedbe.",
		"Végigjátszottuk a játékot mind a 6 karakterrel (történetek, küldetések), és amit találtunk, javítottuk:",
		"Javítva: Ábel csónakja a kis kulcs után azonnal ott van a mólónál (eddig csak a tábor újratöltése után jelent meg).",
		"Javítva: Vendel nem kéri el az egyedi sztori talizmánokat (Lőrinc iránytűje, a tófenék gyöngye...), a mítikusat viszont elfogadja; "
			+ "a király kincstára sem viszi el a sztori legendás tárgyakat.",
		"Javítva: ha a királynál hallgattál Bencéről, de ő már a kocsmában lakik, az Árnyékpengét a tábori ládádba teszi (eddig sehol nem kaptad meg).",
		"Javítva: a főellenség utáni pihenő alatt nem indulhatsz próbatételre / történet-futásra (eddig elveszett a félbehagyott futás, "
			+ "és a tárgyak megkettőződhettek), a boszorkány sem fejleszt, és Lőrinc műhelyének, a rejtett sírnak a ládája ilyenkor a tábori ládába tesz.",
		"Javítva: ha a próbatétel vagy a történet-futás eredményablakát bezárod, akkor is a táborba jutsz (eddig az utolsó emeleten ragadtál); "
			+ "a történet-futásoknál a saját címük látszik. Közös játékban a történet-futások nem indulnak.",
		"Javítva: Bence árnyéklépése nem visz át falon és zárt ajtón (eddig a szomszéd szobába vagy a falba is léphetett).",
		"Csalt futás ölései nem számítanak a küldetésekbe és a Szörnyek könyvébe; a magától felrobbanó robbanó goblin sem (ahogy Döme mondja).",
		"Javítva: a 20 emeletes próbatétel Vérfarkasa is beszámít Gáspár küldetésébe; Bertalan javítása után a lift azonnal használható.",
		"Javítva: Vendel a temetőben is köszön; a Küldetések könyvének Horgász fülén látszik a kalózszámláló, és a kripta után a helyes teendő.",
		"Balansz: a szörnyek eddig minden találat után 0,2 mp-ig sebezhetetlenek voltak, akármi találta őket: a főellenséget "
			+ "másodpercenként legfeljebb 5 találat érte, a Többlövés nyilai elvesztek (az íjász 8 perc alatt sem ölte meg a Vérfarkast). "
			+ "Mostantól minden nyíl és varázslat külön sebez; a sorozat többi nyila ugyanazt a szörnyet fele erővel éri.",
		"Balansz: a Vérfarkas életlopása találatonként legalább 256 (eddig 1280): közelharcban eddig gyorsabban gyógyult, mint ahogy sebezték.",
		"Balansz: a 40. emelet után a sima főellenségek élete nem nő az égig (a 72.-en 13 millió helyett ~570 000, a 99.-en "
			+ "158 millió helyett ~4 millió); a nagy főellenségek (Ősgépezet, Pokolkapu Őre, Azazel) mindig erősebbek maradnak.",
		"Balansz: a rozsdás kard és a régi íj a sebzésed kisebb részét adja (skálázás 0,7), így a talált kardok és íjak tényleg jobbak.",
		"Balansz: Vendel csontvázai emeletenként 12%-kal többet sebeznek (a szinttel továbbra sem nőnek): eddig a 9. emelet után "
			+ "szinte nem lehetett vele végezni egy emelettel.",
		"Szövegek: a boszorkány megmondja, hol találsz Vámpírfogat (vámpír nincs a Mélységben); Bertalan liftes szövegei illenek a mélység "
			+ "kinézetéhez (a 30. Káoszkő, a 70. jeges); néhány elírás.",
		"Simább mozgás nagy frissítésű (pl. 144 / 160 Hz-es) monitoron: a karakter és a szörnyek minden képkockán mozdulnak, "
			+ "nem rángatnak; kevesebb apró akadás harc közben (nem ment minden ölésnél, a hangok és a következő zene előre betöltődnek).",
		"Gyorsabb betöltés: a tábor és a kazamata a főmenüben előre betöltődik, és a tábor erdeje egyben rajzolódik, így belépéskor sokkal kevesebbet akad a játék.",
		"Kilenc synthwave rock zene került a régiek mellé: minden helyszínen szól pár (a táborban nyugodtabbak, lent pörgősek, "
			+ "a mélyben sötétek); a zeneválasztóban külön \"Synthwave rock\" csoportban.",
	]},
	{"date": "2026-10-31", "items": [
		"Új szintlépési kártyák: mindegyik ad valamit, de cserébe elvesz egy másik statból (pl. +4 max élet, −4% mozgási sebesség). 26 kártya új nevekkel és ikonokkal.",
		"A kártyáknak ritkasága van (átlagos, ritka, epikus, legendás, mítikus): ettől függ, milyen gyakran jönnek, és ilyen színűek.",
		"Kivettük a temető új részét, a kriptát és a rituálét (a drágakövekkel együtt): nem lett jó, majd máshogy jön vissza.",
		"A főellenség utáni pihenő alatt a tábori lift zárva: csak a kék portálon át folytathatod a futást.",
		"A megjavított liftekkel felmehetsz a táborba, mintha győztél volna: a ketrecnél [E], a teljes pénzed felkerül, és 2 tárgyat magaddal vihetsz.",
		"Szörnyek könyve: minden felfedezett szörnynél ott áll, melyik emelettől jöhet (a főellenségeknél az emeletük).",
		"Három új szörny: a Lidércfény (4. emelettől: cikázik, teleportál, szétrobban), a Múmia (7.-től: mérgez, dühbe gurul) és a Vízköpő (11.-től: rohamoz, kőpajzsot von). Mind benne vannak a Szörnyek könyvében.",
		"Javítva: ha Vendel már a kocsmában ül, a temetőben nem jelenik meg újra, és nem sétál be a kápolnába.",
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
