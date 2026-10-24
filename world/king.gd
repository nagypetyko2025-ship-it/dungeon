class_name King
## IV. Aurél király a királyi vár tróntermében (lásd Castle): a beszélgetése (DialoguePanel) és
## a küldetései (a J könyv "Király" fülén). Az első kihallgatáskor két küldetést ad (a hét király,
## a kincstár ajándéka); ha már találkoztál a tolvajjal, a tolvajról is kérdez: elárulhatod
## (jutalmat kapsz, de az őrök nem találják meg), vagy hallgathatsz (a tolvaj később meghálálja).

const ID := "king"
const NAME := "IV. Aurél király"
const SHEET: Texture2D = preload("res://assets/characters/king.png")
const FRAME := Vector2(16, 32)

const SEVEN_QUEST := "king_seven"
const TREASURY_QUEST := "king_treasury"
const THIEF_QUEST := "king_thief"
## A tolvaj sorsa (Progress.npc_quests): "betrayed" (elárultad) vagy "protected" (hallgattál).
const THIEF_FATE := "thief_fate"
const TREASURY_GOLD := 1000
const BETRAY_GOLD := 120

## A király küldetései (az engedély a vár kapujánál indul, lásd Castle).
const QUESTS := {
	Castle.PERMIT_QUEST: {"name": "Királyi engedély",
		"text": "A királyi vár kapujában álló őrök csak engedéllyel engednek be, vagy olyan kalandort, "
			+ "aki [b]elérte a Mélység 30. szintjét, és vissza is jött[/b]. Juss le a 30. emeletre, "
			+ "aztán térj vissza a táborba.",
		"reward": "belépés a királyi várba", "doing": "juss le a 30. emeletre, és gyere vissza",
		"done": "az őrök beengednek"},
	SEVEN_QUEST: {"name": "A hét király",
		"text": "A Mélység emeleteit hét szörnykirály uralja: az Ogrekirály, az Orkhadúr, a Gyíkkirály, "
			+ "a Démonúr, a Nekromanta-főpap, a Jégóriás és a Zombikirály. [b]Győzd le mind a hetet[/b] "
			+ "(mindegyiket legalább egyszer), aztán jelentsd a királynak.",
		"reward": "egy legendás tárgy a királyi kincstárból", "doing": "győzd le mind a hét szörnykirályt",
		"done": "a hét király elesett"},
	TREASURY_QUEST: {"name": "A kincstár ajándéka",
		"text": "A királyi kincstár üres, mióta a király a Mélységbe küldte a seregét. Vigyél a "
			+ "királynak egy [b]legendás tárgyat[/b] (bármilyet, a táskádból).",
		"reward": "%d tábori arany" % TREASURY_GOLD, "doing": "vigyél egy legendás tárgyat a királynak",
		"done": "a kincstár gyarapodott"},
	THIEF_QUEST: {"name": "Árnyék a városban",
		"text": "Valaki fosztogatja a városi urakat, a polgármestert, sőt a kocsmárost is. A király "
			+ "tudni akarja, ki az, és hol rejtőzik. Te tudod. Elárulod neki, vagy hallgatsz?",
		"reward": "%d tábori arany (ha elárulod)" % BETRAY_GOLD, "doing": "döntsd el, mit mondasz a királynak",
		"done": "döntöttél"},
}

const FIRST_GREETING := "[i]A trónterem végében, a magas, aranyozott trónon egy ősz hajú, koronás " \
	+ "férfi ül. Fáradtnak tűnik, de a tekintete éles.[/i]\n\n" \
	+ "Tehát te vagy az, aki lement a harmincadik szintre, és vissza is jött. Lépj közelebb, kalandor. " \
	+ "Régóta várok valakire, mint te."
const GREETING := "[i]A király biccent, amikor belépsz.[/i]\n\nÜdv újra, kalandor. Mi járatban?"
const INTRO := "[i]Hosszan hallgat, a gyűrűjét forgatja.[/i]\n\n" \
	+ "Tizenkét éve a Mélységbe küldtem a legjobb embereimet. Harminc pajzsot, Gáspár kapitány vezetésével. " \
	+ "Kincset és válaszokat ígértek a régi írások. Hárman jöttek vissza. Azóta minden éjjel hallom a " \
	+ "nevüket.\n\n" \
	+ "A Mélység nem egyetlen szörnyé. Az emeleteit [b]hét szörnykirály[/b] uralja, és amíg ők élnek, " \
	+ "a sötétség egyre feljebb kúszik. Győzd le mind a hetet, és a korona nem marad hálátlan.\n\n" \
	+ "[i]Körbemutat a csupasz falakon, ahol egykor festmények és kárpitok lógtak.[/i]\n\n" \
	+ "És ahogy látod, a kincstár is kiürült. Ha a mélyben [b]legendás tárgyat[/b] találsz, hozd el nekem. " \
	+ "Busásan megfizetem."
const THIEF_ASK := "\n\n[i]Közelebb hajol, és lehalkítja a hangját.[/i]\n\n" \
	+ "Még valami. Valaki fosztogatja a városi urakat. A polgármester órája, a nemesek gyűrűi, sőt a " \
	+ "kocsmáros bora is eltűnt. Azt beszélik, a sáros ösvény környékén látták egy kendős alakot. " \
	+ "[b]Tudsz róla valamit?[/b]"
const DEEP_STORY := "[i]A király a trón karfáját szorítja.[/i]\n\n" \
	+ "Azt mondják, a Mélység alja egy kapu. Hogy hová vezet, azt senki sem tudja; aki látta, nem jött " \
	+ "vissza. A régi írások szerint a hét szörnykirály ennek a kapunak az őrei. Ha elesnek, a kapu " \
	+ "megnyílik... vagy bezárul. Ezt még a tudósaim sem tudják eldönteni."


static func greeting() -> String:
	return FIRST_GREETING if Progress.npc_quest_state(SEVEN_QUEST) == "" else GREETING


static func met_thief() -> bool:
	return Progress.npc_quest_state(Thief.GOLD_QUEST) != ""


static func options(inventory: Inventory) -> Array[Dictionary]:
	# Lőrinc aranypecsétes levele (az első kihallgatáskor is átadható).
	var letter: Array[Dictionary] = []
	if Progress.npc_quest_state(Stranger.ROYAL_LETTER_QUEST) == "active" and Stranger.has_royal_letter(inventory):
		letter.append({"id": "royal_letter", "text": "Levelet hoztam Lőrinctől, felség.",
			"on_choose": func() -> String: return _royal_letter(inventory)})
	if Progress.npc_quest_state(SEVEN_QUEST) == "":
		var first: Array[Dictionary] = [{"id": "why", "text": "Felség, miért hívatott?",
			"on_choose": func() -> String: return _intro()}]
		return first + letter
	var list: Array[Dictionary] = [
		{"id": "deep", "text": "Mi van a Mélység alján?", "answer": DEEP_STORY},
	]
	if Progress.npc_quest_state(SEVEN_QUEST) == "active":
		list.append({"id": "seven", "text": "Legyőztem a hét szörnykirályt.",
			"on_choose": func() -> String: return _report_seven()})
	if Progress.npc_quest_state(TREASURY_QUEST) == "active":
		list.append({"id": "treasury", "text": "Hoztam legendás tárgyat.",
			"on_choose": func() -> String: return _give_legendary(inventory)})
	match Progress.npc_quest_state(THIEF_QUEST):
		"":
			if met_thief():
				list.append({"id": "more", "text": "Van még valami, felség?",
					"on_choose": func() -> String: return _ask_thief("")})
		"active":
			list.append({"id": "betray", "text": "Tudom, hol rejtőzik a tolvaj.",
				"on_choose": func() -> String: return _betray()})
			list.append({"id": "protect", "text": "Nem tudok róla semmit, felség.",
				"on_choose": func() -> String: return _protect()})
	return list + letter


static func _royal_letter(inventory: Inventory) -> String:
	var answer := Stranger.deliver_to_king(inventory)
	if answer.is_empty():
		Audio.play("ui_error")
		return "Levél? Nem látok nálad levelet, kalandor. (A táskádban legyen.)"
	Progress.mark_asked(ID, "royal_letter")
	return answer


static func _intro() -> String:
	Progress.mark_asked(ID, "why")
	Progress.change_trust(ID, 5)
	Progress.set_npc_quest(SEVEN_QUEST, "active")
	Progress.set_npc_quest(TREASURY_QUEST, "active")
	if met_thief():
		return _ask_thief(INTRO)
	return INTRO


static func _ask_thief(before: String) -> String:
	Progress.set_npc_quest(THIEF_QUEST, "active")
	if before.is_empty():
		return "[i]A király elgondolkodik.[/i]" + THIEF_ASK
	return before + THIEF_ASK


## A hét szörnykirály közül, akit még nem győztél le (a Szörnyek könyve szerint).
static func missing_kings() -> Array[String]:
	var missing: Array[String] = []
	for boss: String in Bestiary.KINGS:
		if boss != "Vérfarkas, a Mélység Ura" and Bestiary.kills(boss) <= 0:
			missing.append(boss)
	return missing


static func _report_seven() -> String:
	var missing := missing_kings()
	if not missing.is_empty():
		Audio.play("ui_error")
		return "[i]A király felvonja a szemöldökét.[/i]\n\nA hírnökeim mást mondanak. Még élnek: [b]%s[/b]. " \
			% ", ".join(missing) + "Gyere vissza, ha mind a hét elesett."
	var item := Items.mark_story(Items.random_item("legendary", "legendary"))
	Progress.add_to_stash(item)
	Progress.set_npc_quest(SEVEN_QUEST, "done")
	Progress.mark_asked(ID, "seven")
	Progress.change_trust(ID, 25)
	Progress.save_game()
	Audio.play("level_up")
	return "[i]A király feláll a trónról. A teremben hirtelen csend lesz.[/i]\n\n" \
		+ "Mind a hét... Tizenkét éve erre várok. Gáspár emberei nem haltak meg hiába.\n\n" \
		+ "[i]Int az egyik őrnek, aki egy bársonypárnán hoz valamit.[/i]\n\n" \
		+ "Fogadd el ezt a királyi kincstárból: [b]%s[/b]. Megérdemled.\n\n" % item["name"] \
		+ "[color=#7a4a10](A tárgy a tábori ládába került.)[/color]"


## Legendás tárgy a táskából a kincstárnak: tábori arany a jutalom.
static func _give_legendary(inventory: Inventory) -> String:
	for i in inventory.bag.size():
		var item: Variant = inventory.bag[i]
		if item is Dictionary and item.get("rarity", "") == "legendary":
			inventory.take_from_bag(i)
			Progress.camp_gold += TREASURY_GOLD
			Progress.set_npc_quest(TREASURY_QUEST, "done")
			Progress.mark_asked(ID, "treasury")
			Progress.change_trust(ID, 15)
			Progress.save_game()
			Audio.play("coin")
			return "[i]A király a kezébe veszi a(z) %s, és sokáig nézi a fáklyák fényében.[/i]\n\n" % item["name"] \
				+ "Ilyet már régen láttam. A kincstárban a helye. A kincstárnokom kifizet.\n\n" \
				+ "[color=#7a4a10](+%d tábori arany)[/color]" % TREASURY_GOLD
	Audio.play("ui_error")
	return "[i]A király végignéz a táskádon, aztán megrázza a fejét.[/i]\n\n" \
		+ "Ezek közt nincs legendás tárgy, kalandor. Csak a legjobbat fogadom el. (A táskádban legyen.)"


static func _betray() -> String:
	Progress.set_npc_quest(THIEF_QUEST, "done")
	Progress.set_npc_quest(THIEF_FATE, "betrayed")
	Progress.mark_asked(ID, "betray")
	Progress.change_trust(ID, 15)
	Progress.camp_gold += BETRAY_GOLD
	Progress.save_game()
	Audio.play("coin")
	return "[i]Elmondod: a romos házban, a sáros ösvény végén, a ládák mögötti ajtó mögött.[/i]\n\n" \
		+ "[i]A király elégedetten bólint, és int az őröknek. Két lándzsás kisiet a teremből.[/i]\n\n" \
		+ "A romos házban, mi? Ott, ahol senki sem keresné. Okos. De nem elég okos.\n\n" \
		+ "Hűséges alattvaló vagy. Fogadd el ezt a fáradságodért.\n\n" \
		+ "[color=#7a4a10](+%d tábori arany. Az őrök később üres kézzel tértek vissza: a tolvaj idejében elrejtőzött.)[/color]" % BETRAY_GOLD


static func _protect() -> String:
	Progress.set_npc_quest(THIEF_QUEST, "done")
	Progress.set_npc_quest(THIEF_FATE, "protected")
	Progress.mark_asked(ID, "protect")
	Progress.change_trust(ID, -5)
	Progress.save_game()
	return "[i]A király hosszan a szemedbe néz, mintha a gondolataidban olvasna.[/i]\n\n" \
		+ "Semmit? Hm. Kár. Pedig azt hittem, a Mélység hőse a korona szeme és füle is lehet.\n\n" \
		+ "[i]Legyint.[/i] Rendben. Előbb-utóbb úgyis hibázik. Mindenki hibázik."


static func portrait() -> Texture2D:
	var face := AtlasTexture.new()
	face.atlas = SHEET
	face.region = Rect2(Vector2.ZERO, FRAME)
	return face


## Álló animáció (lassan lélegzik) a trónon.
static func frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 2.5)
	for i in 4:
		var frame := AtlasTexture.new()
		frame.atlas = SHEET
		frame.region = Rect2(Vector2(i * FRAME.x, 0), FRAME)
		frames.add_frame("default", frame)
	return frames
