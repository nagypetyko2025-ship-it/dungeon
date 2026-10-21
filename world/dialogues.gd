class_name Dialogues
## NPC-beszélgetések szövegei és a hozzájuk tartozó NPC-küldetések (lásd DialoguePanel).
## Egy opció: id (mentett téma), text (a játékos kérdése), answer (az NPC válasza, BBCode),
## trust (ennyit változik a bizalom az első kérdezéskor), on_choose (egyedi művelet: ez adja
## a választ). NPC-nként legfeljebb 5 opció.

const VETERAN_ID := "veteran"
const VETERAN_NAME := "Gáspár, a veterán"
const VETERAN_GREETING := "Hm. Még egy bolond, aki le akar menni a Mélységbe...\n\n" \
	+ "Ülj le, ha akarsz. A tűz mindkettőnket melegít. Csak ne bámuld a kötést."

const WOUND_ANSWER := "[i]Sokáig hallgat, a tüzet bámulja.[/i]\n\n" \
	+ "Miért? Mert elhittem, hogy van alja.\n\n" \
	+ "Tizenkét évig voltam a királyi őrség kapitánya. Amikor a király meghallotta, hogy a Mélység " \
	+ "fenekén kincs és válasz vár, minket küldött le. Harminc pajzs, harminc jó ember.\n\n" \
	+ "A tizedik emelet után a szörnyek... megváltoztak. Erősebbek lettek, okosabbak, mintha valaki " \
	+ "figyelne minket odalentről. Ott vesztettük el a felét.\n\n" \
	+ "A huszadik emeleten egy nagy, üres terem várt. Középen egy farkas állt, ember magas, a szemében " \
	+ "értelem. Az emberek a Mélység Urának hívják. A vérünkből ivott, és minden harapással erősebb lett.\n\n" \
	+ "Levágtam. Láttam elesni. Aztán... felállt.\n\n" \
	+ "Hárman jöttünk vissza. Ezt a sebet ő hagyta a sisakomon, és alatta nem gyógyul. Telihold idején " \
	+ "hallom, ahogy hív.\n\n" \
	+ "[i]Rád néz.[/i] Ha egyszer leérsz hozzá: ne fordíts neki hátat, amikor elesik."
const SWORD_REQUEST := "\n\n[i]Megkopogtatja az üres hüvelyt az oldalán.[/i]\n\n" \
	+ "A kardom odalent maradt, a farkas termében. Egy őrkapitány kard nélkül... csak egy öregember egy " \
	+ "rönkön. Ha a mélyben találsz egy [b]epikus kardot[/b], hozd el nekem. Mindegy, milyet: " \
	+ "csak penge legyen, ami nem törik el az első csontnál."

## NPC-küldetések (a J könyv "Veterán" fülén): id -> {name, text, reward, doing, done}
## (doing / done: az állapot szövege a könyvben).
const VETERAN_QUESTS := {
	"epic_sword": {"name": "Penge az öregnek",
		"text": "Gáspár, a veterán kardja a Mélységben maradt. Vigyél neki egy [b]epikus kardot[/b] "
			+ "(bármilyen kard jó, csak epikus legyen). A tábor nyugati részén ül, a sátra előtt.",
		"reward": "+15 bizalom Gáspárnál", "doing": "vidd el Gáspárnak a táborba", "done": "átadva"},
	"slay_lord": {"name": "A Mélység Ura",
		"text": "Gáspár emberei a huszadik emeleten estek el, a Mélység Ura, a vérfarkas termében. "
			+ "Juss le a [b]20. emeletre[/b], és [b]győzd le a Mélység Urát[/b]. "
			+ "Ne fordíts neki hátat, amikor elesik.",
		"reward": "Majd meglátjuk... (Gáspár még nem mondta)", "doing": "győzd le a 20. emeleten",
		"done": "a Mélység Ura elesett"},
}
const SWORD_TRUST := 15


## A veterán aktuális opciói: a sérülés kérdése mindig; ha kért kardot, az átadás is.
static func veteran_options(inventory: Inventory) -> Array[Dictionary]:
	var list: Array[Dictionary] = [
		{"id": "wound", "text": "Hogy miért sérült meg?", "trust": 5,
			"on_choose": func() -> String: return _ask_wound()},
	]
	if Progress.npc_quest_state("epic_sword") == "active":
		list.append({"id": "give_sword", "text": "Itt a kard, amit kért. (epikus kard átadása)",
			"on_choose": func() -> String: return _give_sword(inventory)})
	return list


## A sérülés története; az első alkalommal a végén kardot kér (elindul a küldetés).
static func _ask_wound() -> String:
	match Progress.npc_quest_state("epic_sword"):
		"":
			Progress.set_npc_quest("epic_sword", "active")
			return WOUND_ANSWER + SWORD_REQUEST
		"active":
			return WOUND_ANSWER + "\n\n[i]Az üres hüvelyre bök.[/i] És a kard... még mindig várom."
	match Progress.npc_quest_state("slay_lord"):
		"active":
			return WOUND_ANSWER + "\n\n[i]Megsimítja az új kard markolatát.[/i] A fiaim még mindig odalent vannak. " \
				+ "A huszadik emeleten. Ne feledd."
		"done":
			return WOUND_ANSWER + "\n\n[i]Hosszan hallgat.[/i] De most már tudom, hogy nem hiába estek el."
	return WOUND_ANSWER + "\n\n[i]Megsimítja az új kard markolatát.[/i] De most már nem vagyok fegyvertelen."


## Epikus kard átadása: a táskából vagy a kézből (ha a kezedben van, a rozsdás kard kerül a helyére).
static func _give_sword(inventory: Inventory) -> String:
	var sword: Variant = null
	for i in inventory.bag.size():
		if is_epic_sword(inventory.bag[i]):
			sword = inventory.take_from_bag(i)
			break
	if sword == null and is_epic_sword(inventory.equipment["weapon"]):
		sword = inventory.equipment["weapon"]
		inventory.equipment["weapon"] = Items.create("sword_rusty")
		inventory.changed.emit()
	if sword == null:
		Audio.play("ui_error")
		return "[i]Végigméri a fegyvereidet, aztán megrázza a fejét.[/i]\n\n" \
			+ "Ez nem az, amit kértem. [b]Epikus kardot[/b] hozz. A lándzsát, baltát meg a kis késeket tartsd meg magadnak."
	Progress.set_npc_quest("epic_sword", "done")
	Progress.change_trust(VETERAN_ID, SWORD_TRUST)
	# A kard után elmeséli, hogyan győzte le őket a vérfarkas, és új küldetést ad.
	if Progress.npc_quest_state("slay_lord") == "":
		Progress.set_npc_quest("slay_lord", "active")
	Audio.play("level_up")
	return "[i]Kezébe veszi a(z) %s pengéjét, megforgatja, végighúzza a hüvelykujját az élén.[/i]\n\n" % sword["name"] \
		+ "Ez jó fajta kard. Kiegyensúlyozott, és az acélja nem mai darab: ezt még törpe kovács edzette. " \
		+ "Ilyen volt az enyém is.\n\n" \
		+ "[i]Leteszi a térdére, és a tűzbe néz.[/i]\n\n" \
		+ "Tudod, mi volt a legrosszabb? Nem a fogai. Az, hogy várt ránk. Mire beértünk a terembe, már ott ült " \
		+ "középen, mintha vendégeket várna. Elsőnek Benedeket kapta el, a zászlóvivőnket. Aztán sorban a többieket. " \
		+ "Minden harapással erősebb lett, és amikor végre levágtam... felkelt, dühösebben, mint előtte.\n\n" \
		+ "Engem a fal mellé dobott, mint egy rongybabát. Ott feküdtem, és néztem, ahogy a fiaim egymás után elesnek. " \
		+ "Mire magamhoz tértem, csak hárman álltunk. Ő pedig hagyta, hogy elmenjünk. Hogy meséljünk róla.\n\n" \
		+ "[i]Feláll a rönkről, és egyenesen a szemedbe néz.[/i]\n\n" \
		+ "A fiaim még mindig ott fekszenek a huszadik emeleten. Juss le odáig, és [b]öld meg a Mélység Urát[/b]. " \
		+ "Nem a kincsért. Értük.\n\n" \
		+ "És ha megtetted... gyere vissza hozzám. Akkor majd beszélünk."


static func is_epic_sword(item: Variant) -> bool:
	return item is Dictionary and item.get("slot", "") == "weapon" \
		and item.get("weapon_type", "sword") == "sword" and item.get("rarity", "") == "epic"
