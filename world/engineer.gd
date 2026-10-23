class_name Engineer
## Bertalan, a mérnök a 10. emelet liftszobájában (lásd LiftRoom). Mesél, és a 4. kérdésre megmondja,
## hogy 1200 aranyért (a kazamatában szerzett aranyból) megjavítja a liftet. Megjavítva a tábori
## liftről (lásd CampLift) le lehet jönni a 10. emeletre, és onnan kezdeni a kazamatát.

const ID := "engineer"
const NAME := "Bertalan, a mérnök"
## 0x72 törp (az első álló kocka).
const FIGURE := Rect2(128, 292, 16, 28)
const PRICE := 1200
## Belső jelzők (Progress.npc_quests): megkérdezted az árát ("done"), és megjavította ("done").
const OFFER_FLAG := "lift_offer"
const REPAIRED_FLAG := "lift_repaired"
const DEPTH := 10

const GREETING := "[i]Egy kormos képű törp hajol egy hatalmas, rozsdás fogaskerék fölé. Fel sem néz.[/i]\n\n" \
	+ "Ha szörny vagy, harapj gyorsan. Ha kalandor, ne állj a fényembe."

const STORIES: Array[Dictionary] = [
	{"id": "who", "text": "Ki vagy te, és mit csinálsz itt lent?", "trust": 4,
		"answer": "Bertalan. A király mérnöke voltam, mielőtt a király rájött, hogy a mérnököket olcsóbb " \
			+ "lent hagyni, mint felhozni.\n\n[i]Megtörli a kezét egy olajos rongyban.[/i]\n\n" \
			+ "Ezt a liftet én építettem, húsz éve. Aranyat hoztunk fel vele a tizedik emeletről. Aztán jöttek a " \
			+ "szörnyek, és mindenki elfutott. Én maradtam. Valakinek vigyáznia kell rá."},
	{"id": "shaft", "text": "Hová vezet ez az akna?", "trust": 3,
		"answer": "Egyenesen fel, a táborba. A lépcső mellett jön ki, a szürke kövek mögött. Láttad? Az a " \
			+ "rácsos fülke.\n\n" \
			+ "Kilenc emeletnyi kötél. Ha működne, egy pillanat alatt lent lennél, nem kellene minden " \
			+ "alkalommal végigverekedned magad a goblinokon. Kár, hogy a fele kötél a szörnyek gyomrában van."},
	{"id": "monsters", "text": "Nem bántanak itt a szörnyek?", "trust": 3,
		"answer": "[i]Megkopogtatja a falat. Tompán kong: vastag vas.[/i]\n\n" \
			+ "Ez a szoba bányászkamra volt. Vasajtó, vasfal, és egy kis trükk: a fogaskerekek zaja " \
			+ "elriasztja őket. A szörnyek nem szeretik, ha valami náluk is hangosabb.\n\n" \
			+ "Egyszer egy minotaurusz bedugta ide a fejét. Odaadtam neki a legrozsdásabb csavarkulcsomat. " \
			+ "Azóta sem jött vissza."},
]


static func repaired() -> bool:
	return Progress.npc_quest_state(REPAIRED_FLAG) == "done"


## A beszélgetés opciói: a három történet, negyediknek a lift (az ára, a fizetés, vagy a köszönet).
static func options(player: Node) -> Array[Dictionary]:
	var list: Array[Dictionary] = STORIES.duplicate()
	if repaired():
		list.append({"id": "running", "text": "Működik a lift?",
			"on_choose": func() -> String: return "[i]Megpaskolja a zúgó fogaskereket.[/i]\n\n" \
				+ "Mint a svájci óra. A táborból bármikor lejöhetsz vele ide, a tizedik emeletre. Fölfelé is " \
				+ "visz, ha meghalsz... na jó, az csak vicc volt. Fölfelé a lépcső vagy a portál."})
	elif Progress.npc_quest_state(OFFER_FLAG) != "done":
		list.append({"id": "repair", "text": "Meg lehet javítani a liftet?",
			"on_choose": func() -> String: return _offer()})
	else:
		list.append({"id": "pay", "text": "Itt az %d arany. Javítsd meg a liftet!" % PRICE,
			"on_choose": func() -> String: return _pay(player)})
	return list


static func _offer() -> String:
	Progress.set_npc_quest(OFFER_FLAG, "done")
	Progress.mark_asked(ID, "repair")
	Progress.save_game()
	return "[i]Most először néz fel rád. A szeme csillog a korom alatt.[/i]\n\n" \
		+ "Megjavítani? Hát persze, hogy meg lehet! Új kötél kell, két új fogaskerék és egy kis... nevezzük " \
		+ "ösztönzésnek.\n\n" \
		+ "Hozz nekem [b]%d aranyat[/b]. Idelentről, a kazamatából, amit odalent szedsz össze: a tábori " % PRICE \
		+ "pénzetek itt semmit sem ér, a szörnyek nem fogadnak el váltót. Ha megvan, megjavítom, és " \
		+ "onnantól a táborból egyenesen ide jöhetsz le, a tizedik emeletre."


static func _pay(player: Node) -> String:
	if not is_instance_valid(player) or int(player.get("gold")) < PRICE:
		Audio.play("ui_error")
		return "[i]Megszámolja, amit mutatsz, aztán a fejét csóválja.[/i]\n\n" \
			+ "Ez nem %d arany, barátom. Szedj még össze odalent, és gyere vissza. Megvárlak, nem megyek sehova." % PRICE
	player.call("spend_gold", PRICE)
	Progress.set_npc_quest(REPAIRED_FLAG, "done")
	Progress.mark_asked(ID, "pay")
	Progress.change_trust(ID, 30)
	Progress.save_game()
	Audio.play("level_up")
	return "[i]Bertalan zsákba söpri az aranyat, és munkához lát. Csattog a kalapács, sistereg az olaj, " \
		+ "aztán egy hosszú, mély nyikorgás után a lift zúgva életre kel.[/i]\n\n" \
		+ "Na tessék! Húsz év után újra jár. Mostantól a táborból egyenesen ide jöhetsz le: a lépcső melletti " \
		+ "liftbe szállsz, és a tizedik emeletet választod.\n\n" \
		+ "[color=#7a4a10](-%d arany. A tábori lift mostantól a 10. emeletre is levisz.)[/color]" % PRICE


static func portrait() -> AtlasTexture:
	return SpriteSheet.region(FIGURE)
