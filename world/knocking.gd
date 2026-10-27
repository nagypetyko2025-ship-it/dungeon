class_name Knocking
## A kopogás titka: Kormos Gyula, a bányász küldetéssora (a J könyv "Bányász" fülén), Döme hídja után.
## 1. A lyuk hangja: a régi tárna lyukas termében (Mine.DEEP_ROOM) fülelj a lyuk keleti szélén: a mélyből a brigád
##    jele szól (három hosszú, két rövid kopogás). Mondd el Gyulának.
## 2. Pókselyem kötél: selyem 12 kazamatapóktól (a küldetés elfogadása óta); Döme kötelet fon, a lyuk nyugati szélére köti.
## 3. A Kopogó: a kötélen le a régi tárnákba: 5 emelet a próbatétel szabályaival (GameState.challenge, "story":
##    "knocker"), az ötödik emelet arénájában a Kopogó (egyedi főellenség, BOSS). Jutalom: A huszonhét lámpása.
## Utána Gyula a bányába költözik (a lyukas teremben áll, lásd Mine), két új történettel; a lyuk elhallgat.

const NAME := "Kormos Gyula, a bányász"
const LISTEN_QUEST := "knock_listen"
const ROPE_QUEST := "knock_rope"
const ROPE_BASE := "knock_rope_base"
const ROPE_TARGET := "spider"
const ROPE_GOAL := 12
const ROPE_GOLD := 150
const KNOCKER_QUEST := "knock_knocker"
## Gyula a bányában (a Kopogó után): a raktárban már nincs.
const MOVED_FLAG := "knock_miner_moved"
const RUN_FLOORS := 5
const REWARD_ID := "trinket_miners_lamp"
## A Kopogó: kőből és csontból összenőtt lény, a hátán a brigád csákányai és egy lámpás; az öklével kopog (slam).
const BOSS := {"name": "A Kopogó", "sheet": "res://assets/enemies/knocker.png", "rect": Rect2(0, 0, 46, 46),
	"scale": 2.6, "health": 100, "damage": 4, "speed": 62.0, "xp": 90,
	"attacks": ["slam", "slam", "summon", "cannon", "charge"], "minion": "skelet", "cannon_color": Color(0.85, 0.7, 0.45)}

const QUESTS := {
	LISTEN_QUEST: {"name": "A lyuk hangja",
		"text": "Kormos Gyula tizenkét éve azt álmodja, hogy a lyuk alján a brigádja még kopog. Menj át a szakadék "
			+ "hídján a régi tárnába, és [b]hallgasd meg a lyukat[/b] (a lyuk keleti szélén). Aztán mondd el "
			+ "Gyulának, mit hallottál.",
		"reward": "Gyula története", "doing": "hallgasd meg a lyukat a régi tárnában",
		"doing_heard": "mondd el Gyulának, mit hallottál", "done": "a kopogás a brigád jele"},
	ROPE_QUEST: {"name": "Pókselyem kötél",
		"text": "A lyukba csak kötélen lehet leereszkedni, és a kenderkötelet a tárnák nedvessége megrohasztja. A "
			+ "kazamatapókok selyme nem: szerezz selymet [b]%d kazamatapóktól[/b] (a küldetés elfogadása óta; " % ROPE_GOAL
			+ "a 3. emelet alatt jönnek). Döme kötelet fon belőle.",
		"reward": "%d tábori arany és a kötél a lyukba" % ROPE_GOLD, "doing": "szerezz pókselymet",
		"done": "a kötél a lyuk szélén lóg"},
	KNOCKER_QUEST: {"name": "A Kopogó",
		"text": "A kötél a lyuk nyugati szélén lóg. Ereszkedj le a régi tárnákba: öt emelet lefelé, és az ötödik "
			+ "alján vár az, ami a brigád jelét kopogja. [b]Győzd le a Kopogót.[/b]",
		"reward": "A huszonhét lámpása (egyedi legendás talizmán)", "doing": "ereszkedj le a kötélen, győzd le a Kopogót",
		"doing_slain": "mondd el Gyulának", "done": "a kopogás elhallgatott"},
}

## A Kopogó után, a bányában.
const STORIES: Array[Dictionary] = [
	{"id": "brigade", "text": "Milyen volt a brigád?", "trust": 4,
		"answer": "[i]Gyula leül a lyuk szélére, a lába a sötétbe lóg.[/i]\n\n" \
			+ "Huszonheten voltunk, plusz én, aki aznap a kocsmában maradt, mert fájt a feje. Ezt sosem bocsátom meg " \
			+ "magamnak. A legöregebb Vince bácsi volt, ő tanított kopogni: három hosszú, két rövid, ha élsz, és " \
			+ "jöjjenek érted. A legfiatalabb Jancsi, tizenhat éves. Az első fizetéséből csizmát vett az anyjának.\n\n" \
			+ "Minden reggel együtt ereszkedtünk le, és minden este együtt jöttünk fel. Egy kivétellel."},
	{"id": "knocker", "text": "Mi volt a Kopogó?", "trust": 4,
		"answer": "[i]Gyula a csákánya nyelét forgatja.[/i]\n\n" \
			+ "Döme szerint a Mélység nem csak öl, hanem utánoz is. Valami, ami a kő túloldalán élt, és tizenkét éve " \
			+ "hallgatta, ahogy a fiúk kopognak. Megtanulta a jelünket, mert tudta, hogy arra mindenki odamegy.\n\n" \
			+ "Én azt mondom, mindegy, mi volt. A fiúk csontjait fel fogom hozni, egyenként, és eltemetjük őket " \
			+ "a kápolna mellett. Vendel már helyet is mutatott."},
]

const LISTEN_TEXT := "Fülelsz a lyuk szélén. Sokáig semmi, csak a saját szívverésed. Aztán mélyről, nagyon mélyről: " \
	+ "kopp... kopp... kopp... kopp-kopp. Három hosszú, két rövid. Szünet. Aztán újra, pontosan ugyanúgy."
const SILENT_TEXT := "Fülelsz a lyuk szélén. Csend. Csak a víz csöpög valahol mélyen. A kopogás elhallgatott."


static func state(quest: String) -> String:
	return Progress.npc_quest_state(quest)


static func moved() -> bool:
	return state(MOVED_FLAG) == "done"


## A kötél a lyuk szélén lóg (a Kopogó-küldetés óta), és még nem győzted le.
static func rope_ready() -> bool:
	return state(KNOCKER_QUEST) == "active"


## A kötél a pókselyem leadása óta a lyuk szélén lóg (a Kopogó után is, csak már nem visz le).
static func rope_hangs() -> bool:
	return state(ROPE_QUEST) == "done"


static func rope_progress() -> int:
	var base := int(state(ROPE_BASE))
	return clampi(int(Progress.kills.get(ROPE_TARGET, 0)) - base, 0, ROPE_GOAL)


## A J könyv "folyamatban" szövege.
static func doing_text(id: String, fallback: String) -> String:
	if id == ROPE_QUEST and state(ROPE_QUEST) == "active":
		return "%s: %d / %d" % [fallback, rope_progress(), ROPE_GOAL]
	return fallback


## A lyuk szélén fülelve (a Mine hívja): a küldetés első lépése itt teljesül.
static func listen() -> String:
	if state(KNOCKER_QUEST) in ["slain", "done"]:
		return SILENT_TEXT
	if state(LISTEN_QUEST) == "active":
		Progress.set_npc_quest(LISTEN_QUEST, "heard")
	return LISTEN_TEXT


## A beszélgetés küldetés-opciói (a raktárban és utána a bányában is; a régi történetek a hívónál).
static func options() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	match state(LISTEN_QUEST):
		"":
			if Blaster.bridge_fixed():
				list.append({"id": "knock_bridge", "text": "Döme hidat robbantott a bánya szakadéka fölé.",
					"on_choose": func() -> String: return _give_listen()})
		"heard":
			list.append({"id": "knock_heard", "text": "Hallottam a kopogást: három hosszú, két rövid.",
				"on_choose": func() -> String: return _finish_listen()})
		"done":
			match state(ROPE_QUEST):
				"":
					list.append({"id": "knock_rope", "text": "Hogyan juthatnánk le a lyukba?",
						"on_choose": func() -> String: return _give_rope()})
				"active":
					if rope_progress() >= ROPE_GOAL:
						list.append({"id": "rope_done", "text": "Megvan a pókselyem.",
							"on_choose": func() -> String: return _finish_rope()})
					else:
						list.append({"id": "rope", "text": "Mennyi pókselyem kell még?",
							"on_choose": func() -> String: return "Eddig %d pók selyme van meg. Még %d kell. " \
								% [rope_progress(), ROPE_GOAL - rope_progress()] \
								+ "A kazamatapókok a harmadik emelet alatt szövik a hálóikat."})
				"done":
					if state(KNOCKER_QUEST) == "slain":
						list.append({"id": "knocker_done", "text": "Legyőztem a Kopogót.",
							"on_choose": func() -> String: return _finish_knocker()})
	if state(KNOCKER_QUEST) == "done":
		list.append_array(STORIES)
	return list


static func _give_listen() -> String:
	Progress.set_npc_quest(LISTEN_QUEST, "active")
	Progress.mark_asked(Warehouse.MINER_ID, "knock_bridge")
	Audio.play("ui_open")
	return "[i]Gyula kezéből kiesik a kupa. Nem veszi fel.[/i]\n\n" \
		+ "Hidat? Akkor át lehet menni a régi tárnához. Ott van a lyuk, ahol a brigádom... huszonheten voltak.\n\n" \
		+ "Tizenkét éve minden éjjel azt álmodom, hogy még kopognak. Menj át, és hallgasd meg a lyukat. Ha nem " \
		+ "hallasz semmit, végre megnyugszom. Ha hallasz... gyere vissza, és mondd el, milyen ütemben kopog.\n\n" \
		+ "[color=#7a4a10](Új fül a küldetések könyvében: Bányász  [J])[/color]"


static func _finish_listen() -> String:
	Progress.set_npc_quest(LISTEN_QUEST, "done")
	Progress.mark_asked(Warehouse.MINER_ID, "knock_heard")
	Progress.change_trust(Warehouse.MINER_ID, 15)
	Audio.play("ui_open")
	return "[i]Gyula elsápad a korom alatt.[/i]\n\n" \
		+ "Három hosszú, két rövid. Ez a mi jelünk. A brigádé. Azt jelentette: élünk, gyertek értünk.\n\n" \
		+ "[i]Sokáig hallgat, aztán megrázza a fejét.[/i]\n\n" \
		+ "Nem. Tizenkét évig senki nem él a kő alatt. Valami odalent megtanulta a jelünket. Valami, ami tudja, " \
		+ "hogy arra a kopogásra minden bányász odamegy. Ahogy mi is odamentünk volna."


static func _give_rope() -> String:
	Progress.set_npc_quest(ROPE_QUEST, "active")
	Progress.set_npc_quest(ROPE_BASE, str(int(Progress.kills.get(ROPE_TARGET, 0))))
	Progress.mark_asked(Warehouse.MINER_ID, "knock_rope")
	Audio.play("ui_open")
	return "Nem a próbatétel lépcsőjén: az a Mélység egy másik ága. A régi tárnákba csak kötélen lehet " \
		+ "leereszkedni, a lyuk nyugati falán, ahol régen a csigasor állt.\n\n" \
		+ "A kenderkötelet a tárnák nedvessége egy hét alatt megrohasztja. A pókselyem nem rohad. Hozz selymet " \
		+ "[b]%d kazamatapóktól[/b], Döme majd megfonja. Ő az egyetlen, aki még nálam is jobban ért a kötelekhez." % ROPE_GOAL


static func _finish_rope() -> String:
	Progress.set_npc_quest(ROPE_QUEST, "done")
	Progress.set_npc_quest(KNOCKER_QUEST, "active")
	Progress.mark_asked(Warehouse.MINER_ID, "rope_done")
	Progress.add_camp_gold(ROPE_GOLD)
	Progress.change_trust(Warehouse.MINER_ID, 15)
	Audio.play("coin")
	return "[i]Gyula végighúzza a selymet az ujjai között, és elégedetten bólint.[/i]\n\n" \
		+ "Döme már fonja. Mire átérsz, a kötél a lyuk nyugati szélén lóg. Én is lemennék, de a lábam már nem visz.\n\n" \
		+ "Öt emelet lefelé a régi tárnákon, aztán ott lesz, ami kopog. Ha a fiúk csontjait látod... adj nekik " \
		+ "nyugalmat. [color=#7a4a10](+%d tábori arany)[/color]" % ROPE_GOLD


static func _finish_knocker() -> String:
	Progress.set_npc_quest(KNOCKER_QUEST, "done")
	Progress.set_npc_quest(MOVED_FLAG, "done")
	Progress.mark_asked(Warehouse.MINER_ID, "knocker_done")
	Progress.change_trust(Warehouse.MINER_ID, 30)
	Audio.play("level_up")
	return "[i]Gyula sokáig nem szól. Aztán feláll, a vállára veti a csákányát, és megigazítja a sapkáját.[/i]\n\n" \
		+ "Elhallgatott. Tizenkét év után. A fiúk most már pihennek.\n\n" \
		+ "Megyek vissza a bányába. Valakinek vigyáznia kell a lyukra, és a csontokat is fel kell hozni. Ha " \
		+ "keresel, a régi tárnában találsz, a lyuk mellett.\n\n" \
		+ "[color=#7a4a10](Kormos Gyula a bányába költözött: a régi tárna lyukas termében áll.)[/color]"


## A régi tárnák (a kötél alján): a próbatétel szabályaival, RUN_FLOORS emelet, a végén a Kopogó.
static func run_challenge() -> Dictionary:
	return {"seed": 0, "floors": RUN_FLOORS, "boons": [], "banes": [], "score": 0.0, "level": 3,
		"difficulty": "Nehéz", "reward": "legendary", "mythic_chance": 0.0, "story": "knocker"}


## Győzelem a régi tárnákban (a Dungeon hívja): a küldetés lépése és a jutalom.
static func reward() -> Dictionary:
	if state(KNOCKER_QUEST) == "active":
		Progress.set_npc_quest(KNOCKER_QUEST, "slain")
	return Items.mark_story(Items.create(REWARD_ID))
