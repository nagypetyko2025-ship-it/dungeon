class_name Dialogues
## NPC-beszélgetések szövegei (lásd DialoguePanel). Egy opció: id (mentett téma), text (a
## játékos kérdése), answer (az NPC válasza, BBCode), trust (ennyit változik a bizalom
## az első kérdezéskor). NPC-nként legfeljebb 5 opció.

const VETERAN_ID := "veteran"
const VETERAN_NAME := "Gáspár, a veterán"
const VETERAN_GREETING := "Hm. Még egy bolond, aki le akar menni a Mélységbe...\n\n" \
	+ "Ülj le, ha akarsz. A tűz mindkettőnket melegít. Csak ne bámuld a kötést."

const VETERAN_OPTIONS: Array[Dictionary] = [
	{"id": "wound", "text": "Hogy miért sérült meg?", "trust": 5,
		"answer": "[i]Sokáig hallgat, a tüzet bámulja.[/i]\n\n"
			+ "Miért? Mert elhittem, hogy van alja.\n\n"
			+ "Tizenkét évig voltam a királyi őrség kapitánya. Amikor a király meghallotta, hogy a Mélység "
			+ "fenekén kincs és válasz vár, minket küldött le. Harminc pajzs, harminc jó ember.\n\n"
			+ "A tizedik emelet után a szörnyek... megváltoztak. Erősebbek lettek, okosabbak, mintha valaki "
			+ "figyelne minket odalentről. Ott vesztettük el a felét.\n\n"
			+ "A huszadik emeleten egy nagy, üres terem várt. Középen egy farkas állt, ember magas, a szemében "
			+ "értelem. Az emberek a Mélység Urának hívják. A vérünkből ivott, és minden harapással erősebb lett.\n\n"
			+ "Levágtam. Láttam elesni. Aztán... felállt.\n\n"
			+ "Hárman jöttünk vissza. Ezt a sebet ő hagyta a sisakomon, és alatta nem gyógyul. Telihold idején "
			+ "hallom, ahogy hív.\n\n"
			+ "[i]Rád néz.[/i] Ha egyszer leérsz hozzá: ne fordíts neki hátat, amikor elesik."},
]
