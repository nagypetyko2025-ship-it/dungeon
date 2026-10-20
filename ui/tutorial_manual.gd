class_name TutorialManual
## A játék kézikönyve: a főmenü Tutorial ablakában fejezetenként olvasható, és a gyakorló
## pálya végén az összefoglaló (SUMMARY) is innen jön.

const SUMMARY := "Megtanultad az alapokat. Ami a gyakorló pályán nem fért bele:\n\n" \
	+ "[b]Tábor[/b] — Itt kezdesz. A lépcsőnél E-vel szállsz le a kazamatába. A [b]kiképzősátorban[/b] tábori aranyból " \
	+ "minden futásra érvényes fejlesztéseket veszel; a [b]tábori ládába[/b] a felküldött tárgyak kerülnek.\n" \
	+ "[b]Arany a táborba[/b] — Halálkor a pénzed 20%-a, a futás feladásakor 40%-a kerül a táborba.\n" \
	+ "[b]Főellenség[/b] — Minden 3. emeleten. Legyőzése után a kék portálon kimehetsz pihenni: egy tárgy a ládába kerül, " \
	+ "a felszerelésed megmarad, és a tábor árusa, Zoltán is árul. A portálon át folytatod.\n" \
	+ "[b]Város és kocsma[/b] — A tábortól keletre vezető út végén. A kocsmában ülnek a játszható karakterek: " \
	+ "odamész, E, és átveszed az irányítást (pl. az íjász csak íjat használ, 2 nyilat lő, Ctrl-re suhan).\n" \
	+ "[b]Mentés[/b] — A tábori haladás magától mentődik; a futás nem, mindig a táborban kezdesz.\n\n" \
	+ "Sok sikert a mélyben!"

## Fejezetek: [cím, szöveg (BBCode)].
const CHAPTERS := [
	["Irányítás",
		"[b]W A S D[/b] — mozgás\n[b]Bal klikk[/b] — támadás az egér irányába (nyomva tartva folyamatosan)\n"
		+ "[b]E[/b] — használat (ajtó, lépcső, tárgylift, árus, karakterek)\n[b]I[/b] — felszerelés\n"
		+ "[b]Tab[/b] — karakterlap\n[b]M[/b] — nagy térkép\n[b]J[/b] — küldetések könyve (lapozás: A / D)\n[b]Esc[/b] — szünet menü / ablak bezárása\n"
		+ "[b]Ctrl[/b] — suhanás (csak íjász)\n[b]F11[/b] vagy [b]Alt+Enter[/b] — teljes képernyő\n"
		+ "Szintlépéskor: [b]1 2 3[/b] — kártya választása, [b]R[/b] — újradobás aranyért"],
	["A kazamata",
		"Az emeletek szobákból és rövid folyosókból állnak. Ha belépsz egy szobába, az ajtók bezárulnak, amíg minden "
		+ "szörnyet le nem győzöl. A kitisztított szobákban gyakran láda jelenik meg.\n\n"
		+ "A lépcsős szobában a lépcsőn rács van, amíg élnek a szörnyek; utána a lépcső a következő, nehezebb emeletre visz. "
		+ "Mélyebben erősebbek a szörnyek, az 5. emelettől nagyobbak a szobák, és új, erős szörnyek jönnek.\n\n"
			+ "A 20. emelet az utolsó: egy hatalmas teremben a Vérfarkas, a Mélység Ura vár. Életet lop, karmos köröket "
			+ "idéz a földre (3 mp múlva lecsapnak), és ha legyőzöd, egyszer feltámad. Utána a pénzed 100%-ával és "
			+ "2 választott tárggyal térhetsz vissza a táborba.\n\n"
		+ "Figyelj a tüskecsapdákra, és arra, hogy a szörnyek képességei is vannak: rohamoznak, teleportálnak, "
		+ "gyógyítják egymást, idéznek, dühöngenek vagy halálukkor szétrobbannak. Támadás előtt felvillannak."],
	["Harc és fegyverek",
		"[b]Kard, tőr, lándzsa[/b] — egyenesen előre döfi / dobja; a Hatótáv azt adja meg, milyen messzire.\n"
		+ "[b]Balta, buzogány[/b] — ívben suhint, nagyot lök.\n[b]Íj[/b] — nyilat lő a kurzor felé (csak íjász).\n\n"
		+ "Egy találat sebzése: (a fegyver alapsebzése + Közelharci vagy Távolsági sebzés × a fegyver skálázása) "
		+ "× (100% + Sebzés%). Kritikus találatnál a fegyver kritikus szorzója is számít."],
	["Statok",
		"[b]Élet[/b], [b]Regeneráció[/b], [b]Védelem[/b] (a sebzés %-át kivédi, max 70%), [b]Találati esély[/b] (ennyire találod el a szörnyet; íjász 80%, lovag 75%), [b]Kikerülés[/b] (esély, hogy nem sebződsz),"
		+ "[b]Sebesség[/b], [b]Ütési sebesség[/b], [b]Kritikus esély[/b], [b]Hatótáv[/b], [b]Közelharci[/b] és [b]Távolsági sebzés[/b], "
		+ "[b]Sebzés%[/b], [b]Többlövés[/b] (íjjal, max 5, csak legendás növeli).\n\n"
		+ "Szintlépéskor minden stat nő egy kicsit, és 3 kártya közül választasz. Ritkán legendás kártya is felbukkan."],
	["Tárgyak és bolt",
		"A tárgyaknak 4 ritkasága van: átlagos, ritka, epikus, legendás. Ládákból, szörnyekből és a boltból jutsz hozzájuk. "
		+ "A felszerelés-helyek: fegyver, sisak, mellvért, nadrág, cipő, kesztyű, gyűrű, amulett, talizmán.\n\n"
		+ "A boltba (a térképen narancs) nekimész az ajtajának: E-vel vásárolsz, a pultnál eladhatsz. Mellette a "
		+ "[b]tárgylift[/b]: emeletenként egy tárgyat felküldhetsz a tábori ládába."],
	["Tábor és fejlődés",
		"A [b]táborban[/b] kezdesz. A [b]kiképzősátorban[/b] tábori aranyból veszel fejlesztéseket, amelyek minden karakterre "
		+ "és minden futásra érvényesek. Halálkor a pénzed 20%-a, a futás feladásakor 40%-a kerül a táborba.\n\n"
		+ "Minden 3. emeleten [b]főellenség[/b] vár. Legyőzése után kimehetsz pihenni: egy tárgy a tábori ládába kerül, "
		+ "a felszerelésed, a szinted megmarad, Zoltán, a vándorárus pedig árul. A kék portál visz vissza.\n\n"
		+ "A tábortól keletre a [b]város[/b] és a [b]Mélységi kocsma[/b]: itt választhatsz karaktert."],
]
