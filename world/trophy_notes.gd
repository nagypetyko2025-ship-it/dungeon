class_name TrophyNotes
## A trófeafal (a kibérelt szobádban, lásd Town, ui/trophy_panel.gd) feliratai: a játszott karakter véleménye a
## legyőzött főellenségekről, egyes szám első személyben. Főellenségenként egy közös szöveg ("default"), a nagy
## főellenségeknél és ahol a karakternek személyes köze van hozzá, karakterenként saját
## (knight, archer, veteran, wizard, gravedigger, thief).

## A még le nem győzött főellenség üres kerete alatt.
const UNBEATEN := "Üres keret. Egy szög a falban, alatta a por. Egyszer ide is kerül valami, vagy ide kerülök én, " \
	+ "csak egy másik falra."

const NOTES := {
	"Ogrekirály": {
		"default": "Az első igazi főellenségem. Akkora volt, mint egy pajta, és ugyanolyan okos. Mégis, amikor elesett, " \
			+ "remegett a kezem. Nem a félelemtől. Attól, hogy rájöttem: lejjebb lesznek nagyobbak is.",
		"gravedigger": "Hármat kellett volna ásnom neki. Egy sírba nem fér bele, és őszintén szólva senki nem akart " \
			+ "segíteni lehúzni. Ott hagytam. A Mélység majd elrendezi. Mindig elrendezi.",
	},
	"Orkhadúr": {
		"default": "Kiabált, mielőtt meghalt. Nem értettem, mit, de a hangja olyan volt, mintha valakit hívna. " \
			+ "Senki nem jött. Valahol odalent egy ork tábor most vezér nélkül maradt. Remélem, szétszélednek.",
	},
	"Gyíkkirály": {
		"default": "Hideg volt a vére, és hideg volt a szeme is. Nem gyűlölt. Egyszerűen éhes volt. Valahogy ez " \
			+ "rosszabb, mint a gyűlölet.",
		"archer": "Két nyilam pattant le a pikkelyéről, mire rájöttem, hogy a szemét kell célozni. Az erdőben a " \
			+ "kígyókat is így tanultam: ne félj tőlük, csak figyelj, hová néznek.",
	},
	"Démonúr": {
		"default": "Az első démon, akit láttam, és az első, aki beszélt hozzám. Azt mondta, a lelkem kicsi és ízetlen. " \
			+ "Ezt most a falamon lógva gondolja át.",
		"knight": "Esküt tettem, hogy a sötétség ellen harcolok. Akkor még nem tudtam, hogy a sötétségnek szarva " \
			+ "is van. Az esküt megtartottam. A szarvát is.",
	},
	"Nekromanta-főpap": {
		"default": "Ő emelte fel a halottakat odalent. Mindegyiknek volt neve, anyja, otthona. Amikor elesett, " \
			+ "a csontvázak egyszerre rogytak össze, mintha megkönnyebbültek volna. Én is megkönnyebbültem.",
		"gravedigger": "Kollégának nem nevezném. Én visszaadom a halottakat a földnek, ő elvette tőle. Mondtam neki, " \
			+ "mielőtt leütöttem az ásóval: a sírnak békét ígértek. Nem tartotta be. Én betartottam helyette.",
	},
	"Jégóriás": {
		"default": "Amikor leütöttem, a szakálla jégcsapjai csengtek, mint a templomi harang. Szép hang volt. " \
			+ "Utána sokáig fáztam, pedig már halott volt.",
		"wizard": "Tűz a jég ellen: a legelső lecke, amit a mesterem tanított. Örültem, hogy végre egyszer a tankönyv " \
			+ "szerint ment valami. Utána persze majdnem megfagytam, mert elfelejtettem, hogy a gőz is jég lesz.",
	},
	"Zombikirály": {
		"default": "Koronát viselt egy rothadó fejen. Gondolom, valaha igazi király volt valahol. Most egy szög a " \
			+ "falamon. A hatalom így múlik el: először a hús, aztán a név.",
		"gravedigger": "Ennek a fickónak még a koporsója is aranyozott volt, amikor lent megtaláltam. Üres. " \
			+ "Nem szeretik a királyok a földet. Pedig egyszer mindenki odakerül, korona ide vagy oda.",
	},
	"Vérfarkas, a Mélység Ura": {
		"default": "Ő volt az első, akit a Mélység Urának neveztek. Akkor azt hittem, ezzel vége. Mindenki ünnepelt " \
			+ "a kocsmában. Én csak ültem, és a holdat néztem az ablakon át. Azóta nem szeretem a teliholdat.",
		"knight": "Hősöket tépett szét, akik jobbak voltak nálam. Mégis én álltam utoljára. Nem vagyok büszke rá. " \
			+ "Hálás vagyok. Ez nem ugyanaz.",
		"archer": "Gyorsabb volt, mint bármelyik farkas az erdőben, és okosabb is. Huszonhét nyílvesszőt lőttem bele. " \
			+ "Megszámoltam, mert nem hittem el, hogy egy élőlény ennyit kibír. Aztán a huszonnyolcadikat már nem.",
		"veteran": "Az embereim feküdtek abban a teremben. Mindegyik nevét tudom, és mindegyik nevét " \
			+ "kimondtam, amikor lecsaptam rá. A fejét nem ide akartam akasztani. A sírjuk fölé akartam. Aztán rájöttem, " \
			+ "hogy ők nem a bosszút akarnák. Hanem hogy éljek. Úgyhogy itt lóg, és én élek.",
		"wizard": "Tűzgolyóval nem lehetett eltalálni, kitért előle, mint a füst. Végül a padlót gyújtottam fel alatta. " \
			+ "A mesterem azt mondaná: nem elegáns. A mesterem nem állt szemben vele.",
		"gravedigger": "Gáspár elesett embereit temettem el a régi temetőben. Pontosabban azt, ami maradt belőlük. " \
			+ "Amikor ez a dög elesett, kimentem hozzájuk, és elmondtam nekik. Nem válaszoltak, de a szél pont akkor " \
			+ "elállt. Én ezt igennek veszem.",
		"thief": "Ezt nem lehetett ellopni, nem lehetett kicselezni, nem lehetett lefizetni. Utálom az ilyen " \
			+ "ellenfeleket. Végül hátba szúrtam. Tudom, nem szép. De ő sem volt szép.",
	},
	"Kalózkirály": {
		"default": "Kalózok a Mélységben, víz nélkül, hajó nélkül. Soha nem értettem. Ő sem, azt hiszem: ott állt a " \
			+ "kincses ládája mellett, és úgy nézett körül, mint aki most ébredt fel egy rossz álomból.",
		"thief": "Szakmabeli volt, tisztelem. Rossz oldalon állt, de szakmabeli. A ládája a táborban van, " \
			+ "a kalapját a fejemre tettem. Nem állt jól. Visszaakasztottam ide.",
	},
	"Lánggólem": {
		"default": "Kő és tűz, gondolkodás nélkül. Nem tudom, ki építette, és miért hagyta itt. A hamuja napokig " \
			+ "melegítette a kezemet, pedig zsebben hordtam.",
		"wizard": "Valaki varázsolta, és rosszul. A rúnák fordítva voltak rajta, ezért nem tudott leállni. Egy " \
			+ "kicsit sajnáltam. Ha egyszer találkozom az alkotójával, lesz egy-két szavam hozzá.",
	},
	"A Mélység Szeme": {
		"default": "Végig engem nézett. Még akkor is, amikor már nem élt. Néha éjjel arra ébredek, hogy most is néz, " \
			+ "innen a falról. Letakarnám, de akkor tudnám, hogy alatta néz.",
	},
	"Nyálkakirály": {
		"default": "Nincs benne semmi dicsőség, ezt bevallom. Három napig mostam a ragacsot a hajamból, és a " \
			+ "csizmám azóta is cuppog. Mégis főellenség volt, ezért itt a helye. A falon. Messze tőlem.",
	},
	"Skorpiókirály": {
		"default": "A mérge két napig égetett. Doktor Kálmán azt mondta, szerencsém volt. Nem érzem magam " \
			+ "szerencsésnek, de élek, és ő nem. Talán ez a szerencse.",
	},
	"Jégkirálynő": {
		"default": "Gyönyörű volt, és szomorú. Nem harcolt úgy, mint aki győzni akar. Úgy harcolt, mint aki régóta " \
			+ "vár valakire, aki végre leállítja. Amikor elolvadt, mintha megköszönte volna. Lehet, hogy csak képzeltem.",
		"archer": "A nyilaim megfagytak a levegőben, mielőtt elérték. Ilyet még sosem láttam. A végén egy " \
			+ "jégcsapot lőttem vissza rá a saját íjamból. Szerintem tetszett neki. Mosolygott.",
	},
	"Ürességfaló, a Káosz Ura": {
		"default": "Nem volt arca, nem volt alakja, csak éhség. Amikor eltűnt, a terem hirtelen olyan csendes lett, " \
			+ "hogy hallottam a saját szívverésemet. Azóta jobban figyelek rá.",
		"knight": "Nem lehetett vele becsülettel harcolni, mert a becsületet is felfalta volna. Úgyhogy egyszerűen " \
			+ "csak harcoltam. Néha ez is elég.",
		"archer": "Mit céloz az ember, ha a célpontnak nincs közepe? Mindent. Elfogyott a tegezem, kétszer. " \
			+ "A harmadikkal sikerült.",
		"veteran": "Harminc év a seregben, és ilyet még nem láttam. Nem tudott meghalni, csak elfogyni. Hát " \
			+ "elfogyasztottuk. Az embereim büszkék lennének. Ők mindig mondták, hogy a vén Gáspárt nem lehet megenni.",
		"wizard": "A káosz a mágia nyers anyaga. Ő volt maga a nyersanyag, forma nélkül. Egy részét a jegyzeteimbe " \
			+ "zártam, mielőtt szétfoszlott. Ne mondjátok el senkinek. Főleg a királynak ne.",
		"gravedigger": "Ennek nem ástam sírt. Nem maradt belőle semmi. Ez a legrosszabb halál: amikor még a csont " \
			+ "sem marad, amit eltemethetnél. Furcsa, de sajnáltam.",
		"thief": "Mindent elnyelt, amit eldobtam felé: tőrt, láncot, egy fél sonkát. Utoljára a saját árnyékát " \
			+ "dobtam vissza neki. Ne kérdezzétek, hogyan. Én sem tudom.",
	},
	"Az Ősgépezet": {
		"default": "Ezer éve járt egyedül odalent, kattogva, gőzölögve, cél nélkül. Amikor leállt, a csend " \
			+ "hangosabb volt, mint a gépei. Valaki megépítette. Valaki itt hagyta. Az a valaki rosszabb volt nála.",
		"knight": "Vas a vas ellen, ahogy a régi dalokban. Csak a dalokban a vas nem gőzöl, és nem próbál megfőzni. " \
			+ "A kardom azóta csorba. Nem cserélem le.",
		"archer": "A nyilak lepattantak róla, mint a jégeső a háztetőről. Végül a fogaskerekei közé lőttem, és " \
			+ "a saját súlya tépte szét. Az erdőben ezt hívják türelemnek.",
		"veteran": "Bertalan sírt, amikor elmeséltem neki. Azt mondta, ilyen gépet ember nem épített, csak isten vagy " \
			+ "bolond. Én szerintem bolond. Az istenek nem hagynak hátra ennyi csavart.",
		"wizard": "Villám a villám ellen. Végül a saját teslatekercsébe vezettem a varázslatomat, és túltöltöttem. " \
			+ "Egy darabja itt lóg, a másik a zsebemben szikrázik. Ha éjjel világítok, ezért.",
		"gravedigger": "Gépet még nem temettem. Megpróbáltam. Bertalan rám szólt, hogy az nem halott, csak szét van " \
			+ "szedve. Ő tudja. Én azért elmondtam fölötte pár szót.",
		"thief": "Egy ilyen szerkezetben minden alkatrész aranyat ér. Kivettem belőle a főtengelyt, és eladtam a " \
			+ "kovácsnak. Ne mondjátok el Bertalannak.",
	},
	"A Pokolkapu Őre": {
		"default": "Három feje volt, és mind a három ugatott. A pokol kapuját őrizte. Amikor elesett, a kapu " \
			+ "megnyikordult, mintha végre fellélegezhetne. Akkor tudtam, hogy nincs visszaút.",
		"knight": "Egy kutya, aki a gazdáját védte. Tiszteltem a hűségéért. A gazdáját nem tisztelem.",
		"archer": "Mindig van egy fej, ami épp rád néz. Végül hármat lőttem egyszerre. Lent, a Mélységben " \
			+ "tanultam meg, hogy a lehetetlen csak gyakorlás kérdése.",
		"veteran": "Kutyát tartottam a seregben, Bundásnak hívtuk. Nem volt három feje, de ugyanígy morgott. " \
			+ "Szegény dög. Nem tehetett róla, mi lett belőle.",
		"wizard": "Pokoltüzet okádott, én meg tüzet szórtam vissza. Két tűz összecsapása után egyikünknek sem maradt " \
			+ "szemöldöke. Neki már nem kell. Nekem még visszanő.",
		"gravedigger": "Ennek a fejeit külön-külön temettem el. Egyiket sem akartam a másik mellé tenni, látszott " \
			+ "rajtuk, hogy életükben sem bírták egymást.",
		"thief": "Három fej, három orr. Nem lehetett mögé lopózni. Végül egy csont volt a megoldás. Mindig egy csont " \
			+ "a megoldás egy kutyánál, még ha a pokolból jött is.",
	},
	"Azazel, a Halálangyal és Démonkirály": {
		"default": "Vége. Azt hittem, valami nagyot fogok érezni, amikor elesik. Diadalt, örömöt. Csak fáradtságot " \
			+ "éreztem. És aztán csendet. Ez a csend a legszebb trófeám. Mindenki boldogabb, hogy nincs többé. " \
			+ "Én is. Csak még nem tudom, mit kezdjek a nyugalommal.",
		"knight": "Egyszer egy öreg lovag azt mondta: az igazi hős nem az, aki legyőzi az ördögöt, hanem aki utána " \
			+ "hazamegy, és tovább él. Hazamentem. Most próbálok tovább élni. Nehezebb, mint a harc volt.",
		"archer": "Az utolsó nyilam a szárnyába ment. Az utolsó előtti a szívébe. Azóta nem lőttem. Talán egyszer " \
			+ "majd újra, csak úgy, egy almára, egy fán. Kíváncsi vagyok, milyen lesz, amikor nem az életem a tét.",
		"veteran": "Harminc ember volt az ár, ezt mondta a király tekercse. Harminc név, amit az alapító eladott. " \
			+ "Kifizettem helyettük. Most már nyugodhatnak. És talán én is.",
		"wizard": "A legnagyobb varázslat, amit láttam, és a legrosszabb is. Mindent tudott, amit én szerettem volna " \
			+ "tudni. És nézd, mire használta. Elégettem a jegyzeteimet, amikor hazaértem. A tudás nem elég. " \
			+ "Jónak is kell lenni hozzá.",
		"gravedigger": "Mindenkit eltemettem életemben, aki elém került. Őt nem. Neki nem jár sír. Ő maga volt " \
			+ "minden sír oka. Amikor elesett, hazamentem, és egész éjjel csak ültem a temetőben. A halottak csendben " \
			+ "voltak. Azt hiszem, megköszönték.",
		"thief": "Elloptam tőle az egyetlent, ami igazán számított neki: a győzelmet. Életem legnagyobb fogása. " \
			+ "Senki nem fog hinni nekem a kocsmában. Nem baj. Én tudom.",
	},
}


## A karakter véleménye a főellenségről (ha neki nincs sajátja, a közös).
static func note(boss: String, character: String) -> String:
	var notes: Dictionary = NOTES.get(boss, {})
	return str(notes.get(character, notes.get("default", "")))
