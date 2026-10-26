class_name TutorialManual
## A játék kézikönyve: a főmenü Tutorial ablakában fejezetenként olvasható (CHAPTERS); a gyakorlás végén egy rövid
## összefoglaló (FINISH_TEXT). A karakterek és a lakók
## történetéből szándékosan nem árul el semmit: csak azt, ami a játékhoz kell.

const CONTROLS := "[b]W A S D[/b] (vagy a nyilak) — mozgás\n" \
	+ "[b]Bal egérgomb[/b] — támadás az egér irányába (nyomva tartva folyamatosan)\n" \
	+ "[b]Jobb egérgomb[/b] — második varázslat / második idézés (akinek van)\n" \
	+ "[b]Ctrl[/b] — a karakter képessége: suhanás, hadi kiáltás, árnyéklépés (akinek van)\n" \
	+ "[b]E[/b] — használat: ajtó, lépcső, láda, árus, üllő, tárgylift, portál, beszélgetés\n" \
	+ "[b]Q[/b] — HP bájital megivása\n[b]F[/b] — HP bájital vétele a boltos pultjánál\n" \
	+ "[b]I[/b] — felszerelés és táska\n[b]Tab[/b] — karakterlap (statok)\n[b]M[/b] — nagy térkép\n" \
	+ "[b]J[/b] — küldetések könyve (lapozás: A / D)\n" \
	+ "[b]Esc[/b] — szünet menü / a nyitott ablak bezárása (minden ablak jobb felső sarkában [b]X[/b] is van)\n" \
	+ "[b]F11[/b] vagy [b]Alt+Enter[/b] — teljes képernyő\n" \
	+ "Szintlépéskor: [b]1 2 3[/b] — kártya választása, [b]R[/b] — újradobás aranyért " \
	+ "(közös játékban az [b]L[/b] gombbal nyitod meg, amikor ráérsz)"

const DUNGEON := "Egy [b]futás[/b] a táborból indul: a lépcsőn leszállsz a kazamatába, és emeletről emeletre haladsz " \
	+ "lefelé. Az emeletek szobákból és folyosókból állnak. Ha belépsz egy szobába, [b]az ajtók bezárulnak[/b], amíg " \
	+ "minden szörnyet le nem győzöl; a kitisztított szobákban gyakran [b]láda[/b] jelenik meg. A lépcsős szobában a " \
	+ "lépcsőn rács van, amíg élnek a szörnyek.\n\n" \
	+ "Minél mélyebben jársz, annál erősebbek a szörnyek, de annál jobb tárgyak esnek, és annál jobb a bolt. Az 5. " \
	+ "emelettől nagyobbak a szobák, és időnként hirtelen erősebbek lesznek a szörnyek. Figyelj a " \
	+ "[b]tüskecsapdákra[/b], és arra, hogy sok szörnynek képessége van (rohamoz, teleportál, gyógyít, idéz, mérgez, " \
	+ "lassít, felrobban...): használat előtt [b]felvillannak[/b].\n\n" \
	+ "Minden [b]3. emeleten főellenség[/b] vár egy nagy teremben. Támadás előtt színesen felvillan, fél élete alatt " \
	+ "feldühödik. Legyőzése után jár egy HP bájital, sok arany és egy jó tárgy, kinyílik a lépcső, és megjelenik a " \
	+ "[b]kék portál[/b]: rajta át kimehetsz pihenni a táborba (lásd: Pihenő). A 20. emeleten egy különösen erős " \
	+ "ellenfél vár — és a mélység ott sem ér véget."

const COMBAT := "A [b]bal egérgombbal[/b] az egér irányába támadsz. A kard, tőr és lándzsa előre döf (a [b]Hatótáv[/b] " \
	+ "azt adja meg, milyen messzire), a balta és a buzogány ívben suhint és nagyot lök, az íjak és a számszeríj " \
	+ "nyilat lőnek. Egy találat sebzése: (a fegyver alapsebzése + Közelharci vagy Távolsági sebzés × a fegyver " \
	+ "skálázása) × (100% + Sebzés%). Kritikus találatnál a fegyver kritikus szorzója is számít.\n\n" \
	+ "A szörnyek fölött a sebzésed látszik; a narancs, felkiáltójeles szám kritikus találat. [b]Mellé![/b]: nem " \
	+ "találtál (Találati esély). [b]Kikerülte![/b]: a szörny kitért. A mellément vagy kikerült lövedék továbbrepül. Ha " \
	+ "téged találnak el, egy pillanatig villogsz, és ilyenkor nem sebezhetnek meg újra.\n\n" \
	+ "Minden karakter másként harcol: van, aki suhan, aki hadi kiáltást hallat, aki varázsol, aki csontvázakat idéz, " \
	+ "és van, aki a szörnyek háta mögé lép. A karakterlapon (Tab) és a gyakorló pályán ezt is látod."

const STATS := "[b]Élet[/b], [b]Regeneráció[/b], [b]Védelem[/b] (a sebzés ennyi %-át kivédi, max 70%), " \
	+ "[b]Kikerülés[/b] (esély, hogy nem sebződsz), [b]Találati esély[/b] (ennyire találod el a szörnyet), " \
	+ "[b]Sebesség[/b] (max 150%), [b]Ütési sebesség[/b] (max 500%), [b]Kritikus esély[/b], [b]Hatótáv[/b], " \
	+ "[b]Közelharci[/b], [b]Távolsági[/b] és [b]Elemi sebzés[/b], [b]Sebzés%[/b], [b]Többlövés[/b] (íjjal, max 5) és " \
	+ "[b]Átütés[/b] (a nyíl ennyi szörnyön megy át; max 1). Lila különleges statok tárgyakról: életlopás, tüskék, " \
	+ "aranykereső, tapasztalat-bónusz.\n\n" \
	+ "A szörnyekből zöld [b]XP-gömbök[/b] esnek. Ha betelik az XP-csík, szintet lépsz: minden stat nő egy kicsit, és " \
	+ "[b]3 kártya[/b] közül választasz egy fejlesztést (aranyért újradobhatod őket). Ritkán arany keretű, " \
	+ "[b]legendás[/b] kártya is jön."

const ITEMS := "A tárgyaknak [b]5 ritkasága[/b] van: [color=#5c544c]átlagos[/color], [color=#1f52b8]ritka[/color], " \
	+ "[color=#7a2eae]epikus[/color], [color=#b85c00]legendás[/color] és [color=#b8120c]mítikus[/color]; minél ritkább, " \
	+ "annál erősebb. Mítikus tárgy csak nagyon ritkán jut: a nagy főellenségektől, vagy mélyen a boltban, drágán. " \
	+ "Helyek: fegyver, sisak, mellvért, nadrág, cipő, kesztyű, gyűrű, amulett, talizmán. Az [b]I[/b] ablakban húzással " \
	+ "(vagy jobb klikkel) veszed fel / le; a tárgy fölött látod a statjait és az összehasonlítást. Nem minden karakter " \
	+ "foghat minden fegyvert: a leírás megmondja.\n\n" \
	+ "[b]Bolt[/b] (a térképen narancs): nekimész az ajtajának, és bent vagy. Tárgy elé állva [b]E[/b]: vásárlás; a " \
	+ "pultnál [b]E[/b]: eladás, [b]F[/b]: HP bájital (60 arany, boltonként 2). A szoba közepén lévő karral aranyért " \
	+ "új árut kérsz. A fegyverek közül a te harcmódodhoz illők jönnek gyakrabban.\n\n" \
	+ "[b]HP bájital[/b] (Q): az elvesztett életed felét tölti vissza. Minden főellenség után kapsz egyet.\n\n" \
	+ "[b]Tárgylift[/b] (a bolt mellett): emeletenként egy tárgyat felküldhetsz vele a tábori ládába, ahol biztonságban van."

const SMITH := "A táborban a [b]kovácsnál[/b] (E) fejlesztheted és szétszedheted a tárgyaidat. Minden ritkaságnak " \
	+ "saját [b]pora[/b] van; ezek a táborban maradnak, és mentődnek.\n\n" \
	+ "[b]Szétszedés[/b]: a tárgy elvész, és a ritkaságának porából 1-et (30% eséllyel 2-t) kapsz. Ami rajtad van, azt " \
	+ "nem lehet beolvasztani.\n\n" \
	+ "[b]Fejlesztés[/b]: a tárgy a következő ritkaságba lép, és minden statja nő. Ehhez [b]4 por[/b] kell a " \
	+ "következő ritkaságból (pl. ritka → epikus: 4 epikus por). [b]65% eséllyel[/b] sikerül; ha nem, a por elvész, " \
	+ "de a tárgy megmarad. A rajtad lévő tárgyat is fejlesztheted."

const CAMP := "A [b]táborban[/b] kezdesz, és ide térsz vissza. A [b]lépcsőnél[/b] E-vel szállsz le a kazamatába; " \
	+ "amit nálad van, azt viszed magaddal.\n\n" \
	+ "[b]Tábori arany[/b]: a futásokból hazahozott pénz. Ebből a [b]kiképzősátorban[/b] tartós fejlesztéseket " \
	+ "veszel (sebzés, élet, védelem, sebesség, kritikus esély...), amelyek minden karakterre és minden futásra " \
	+ "érvényesek.\n[b]Tábori láda[/b]: ide kerülnek a felküldött tárgyak; innen veheted ki őket a következő futásra.\n" \
	+ "[b]Kovács[/b]: tárgyfejlesztés és szétszedés porokért.\n" \
	+ "[b]Szörnyek könyve[/b]: minden szörny leírása, amelyiket már legyőzted, és hogy hányat.\n" \
	+ "[b]Vándorárus[/b]: pihenő közben árul (lásd: Pihenő).\n\n" \
	+ "A táborból utak vezetnek tovább, egyebek közt egy [b]városba[/b]. Fedezd fel a környéket!"

const REST := "A főellenség legyőzése után a [b]kék portálon[/b] (E) kimehetsz [b]pihenni[/b] a táborba. Közben a " \
	+ "táskádból [b]egy tárgyat[/b] a tábori ládába küldhetsz (ami rajtad van, azt nem), és eldöntheted, kiviszed-e " \
	+ "a pénzed: kint a vándorárusnál elköltheted, a maradékot visszaviszed. A felszerelésed, a szinted és a statjaid " \
	+ "megmaradnak, és a táborban álló kék portál ugyanide, a főellenség termébe hoz vissza. Ha nem akarsz kimenni: " \
	+ "Maradok, és mehetsz tovább a lépcsőn."

const DEATH := "Ha az életed elfogy, [b]véget ér a futás[/b]: a szinted, a statjaid és [b]minden tárgy, ami nálad " \
	+ "volt[/b], elvész, a pénzednek csak a [b]20%-a[/b] kerül a táborba. Ha a szünet menüben [b]feladod[/b] a futást, " \
	+ "a pénzed 40%-a jut haza.\n\n" \
	+ "Ami [b]biztonságban[/b] van: a tábori ládában lévő tárgyak (tárgylift, pihenő), a tábori arany, a kiképzősátor " \
	+ "fejlesztései, a kovács porai és a küldetéseid. Ezért érdemes a legjobb zsákmányt felküldeni!\n\n" \
	+ "A tábori haladás magától mentődik. Ha egy pihenő közben lépsz ki a játékból, a futást is folytathatod a " \
	+ "főmenüből."

const PEOPLE := "A táborban és a környéken [b]emberek élnek[/b]. Ha odamész hozzájuk, [b]E[/b]-vel beszélgethetsz " \
	+ "velük: kérdezhetsz tőlük, és a válaszaid számítanak. Van, aki [b]feladatot[/b] ad, van, aki segítséget kér; ha " \
	+ "segítesz nekik, megbíznak benned — és van, aki ezután [b]játszható karakterként[/b] csatlakozik hozzád. Az új " \
	+ "karaktereket a városi kocsmában választhatod ki: odamész, E, és átveszed az irányítást. Mindegyik másként " \
	+ "harcol, más fegyvert foghat, és saját képessége lehet.\n\n" \
	+ "A [b]küldetések könyve[/b] (J) mutatja a futó küldetéseidet és a haladásukat (pl. ennyi szörnyet győzz le, " \
	+ "juss el valahány emeletre). A kész küldetések jutalmát a [b]kocsmárosnál[/b] veheted át.\n\n" \
	+ "Hogy kik ők és mi a történetük, azt magadnak kell kiderítened!"

const MULTIPLAYER := "A főmenü [b]Közös játék[/b] gombjával legfeljebb [b]4-en[/b] játszhattok együtt ugyanazon a " \
	+ "hálózaton. A gazda létrehoz egy várót, a többiek a listából csatlakoznak, és ha mindenki kész, indul a játék.\n\n" \
	+ "Közös játékban: a szobák ajtajai [b]nem záródnak be[/b]; a menük alatt [b]nem áll meg[/b] az idő; az [b]arany " \
	+ "közös[/b]; a szintlépés kártyáit az [b]L[/b] gombbal választod ki, amikor ráérsz. Ha egy társ elesik, állj mellé, " \
	+ "és [b]tartsd nyomva az E-t[/b] 3 másodpercig: felállítod. Egy tárgyat úgy adsz át, hogy az [b]I[/b] ablakban a " \
	+ "táska alatti [b]társ nevére húzod[/b]; ha nála nincs hely, visszajön."

## Fejezetek a főmenü Tutorial ablakában: [cím, szöveg (BBCode)]. Az első az irányítás (a beállításokban is).
const CHAPTERS := [
	["Irányítás", CONTROLS],
	["A kazamata", DUNGEON],
	["Harc", COMBAT],
	["Statok, szintlépés", STATS],
	["Tárgyak és bolt", ITEMS],
	["A kovács", SMITH],
	["A tábor", CAMP],
	["Pihenő", REST],
	["Halál és biztonság", DEATH],
	["Lakók, küldetések", PEOPLE],
	["Közös játék", MULTIPLAYER],
]

## A gyakorlás legvégén (a tábori bemutató után): rövid, nem kell sokat olvasni.
const FINISH_TEXT := "Ügyes voltál, most már mindent tudsz, ami az induláshoz kell!\n\n" \
	+ "[b]•[/b] A tábor lépcsőjénél kezdesz; minden 3. emeleten főellenség vár, utána kimehetsz pihenni.\n" \
	+ "[b]•[/b] Halálkor elveszted, ami nálad van: a legjobb tárgyakat küldd fel (tárgylift, pihenő).\n" \
	+ "[b]•[/b] A tábori aranyból a kiképzősátorban erősödsz; a kovácsnál a tárgyaidat fejleszted.\n" \
	+ "[b]•[/b] Beszélgess a lakókkal: feladatokat adnak, és új karakterek csatlakozhatnak hozzád.\n" \
	+ "[b]•[/b] Barátokkal a főmenü [b]Közös játék[/b] gombjával játszhattok (az elesett társat E-t nyomva tartva " \
	+ "felállítod).\n\n" \
	+ "Ha valamit elfelejtenél: a főmenü [b]Tutorial[/b] ablakában fejezetenként mindent megtalálsz. Sok sikert a mélyben!"
