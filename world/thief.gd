class_name Thief
## A tolvaj a nyugati tisztás romos házának rejtekszobájában (lásd Ruin): a beszélgetése
## (DialoguePanel) és a küldetései (a J könyv "Tolvaj" fülén). Az első találkozáskor
## megkérdezi, mit keresel ott; bármit felelsz, a végén aranyat kér tőled.

const ID := "thief"
const NAME := "Tolvaj"
const SHEET: Texture2D = preload("res://assets/characters/thief.png")
const GOLD_QUEST := "thief_gold"
const GOLD_AMOUNT := 500
const PAID_TRUST := 15

const FIRST_GREETING := "[i]A gyertya lángja megremeg. Egy kendős alak pattan fel a ládáról, " \
	+ "a kezében kés villan.[/i]\n\nHé! Ki engedett be? [b]Mit csinálsz itt?[/b]"
const GREETING := "[i]Fel sem néz, tovább számolja az érméket.[/i]\n\nMegint te? Hozod már, amit kértem?"
const PAID_GREETING := "[i]Biccent, és egy aranyat pörget az ujjai között.[/i]\n\n" \
	+ "Á, a kedvenc ügyfelem. Üljön le, ha talál helyet a zsákmány között."
const QUEST_REQUEST := "\n\n[i]Legyint, és visszadugja a kést az övébe.[/i]\n\n" \
	+ "Mindegy. Van egy küldetésem a számodra: [b]hozz nekem %d aranyat[/b]. " % GOLD_AMOUNT \
	+ "Ne kérdezd, mire kell. Ha meghozod, nem fogod megbánni: van itt elég szép holmi, " \
	+ "ami nekem már úgyis túl feltűnő.\n\n" \
	+ "És ha bárkinek beszélsz erről a helyről... [i]A kés hegyével a gyertya felé bök.[/i] " \
	+ "Jobb, ha nem."

## NPC-küldetések (a J könyv "Tolvaj" fülén), ugyanúgy, mint Dialogues.VETERAN_QUESTS.
const QUESTS := {
	GOLD_QUEST: {"name": "Aranyéhség",
		"text": "A romos ház rejtekszobájában élő tolvaj [b]%d aranyat[/b] kér tőled. " % GOLD_AMOUNT
			+ "Nem mondta meg, mire kell. A tábori aranyadból fizethetsz: menj vissza hozzá "
			+ "(a tábortól nyugatra, a sáros ösvény végén, a ládák mögötti ajtón át).",
		"reward": "valami a zsákmányából", "doing": "vigyél neki %d aranyat" % GOLD_AMOUNT,
		"done": "kifizetve"},
}


## A köszönése: az első találkozáskor rád kérdez, utána már ismer.
static func greeting() -> String:
	match Progress.npc_quest_state(GOLD_QUEST):
		"": return FIRST_GREETING
		"done": return PAID_GREETING
	return GREETING


static func options() -> Array[Dictionary]:
	var state := Progress.npc_quest_state(GOLD_QUEST)
	if state == "":
		# Az első találkozás: három válasz, mindegyik végén a küldetés.
		return [
			{"id": "wandered", "text": "Csak körülnéztem. A sáros ösvény idevezetett.",
				"on_choose": func() -> String: return _first_answer("wandered", 5,
					"[i]Gyanakodva végigmér.[/i]\n\nAz ösvény, mi? Azt a sarat évek óta senki nem tapossa, " \
					+ "csak én. Ügyes vagy, ha megtaláltad az ajtót a ládák mögött. Túl ügyes.")},
			{"id": "loot", "text": "Ez mind lopott holmi, ugye?",
				"on_choose": func() -> String: return _first_answer("loot", -5,
					"[i]Felhorkan.[/i]\n\nLopott? Én úgy mondanám: [i]kölcsönvett[/i]. A városi urak " \
					+ "úgysem veszik észre, hogy hiányzik egy-két gyűrű a ládájukból. A kocsmáros meg " \
					+ "azt hiszi, a patkányok isszák a borát.")},
			{"id": "guard", "text": "Az őrség küldött. Le vagy tartóztatva!",
				"on_choose": func() -> String: return _first_answer("guard", -10,
					"[i]Egy pillanatra megdermed, aztán hangosan felnevet.[/i]\n\nAz őrség? Ebben a " \
					+ "városban az egyetlen őr a kocsmáros, és ő is csak a hordóit őrzi. Rosszul hazudsz, " \
					+ "barátom. Ezt még gyakorolnod kell.")},
		]
	var list: Array[Dictionary] = [
		{"id": "why_gold", "text": "Mire kell neked ennyi arany?",
			"on_choose": func() -> String: return _why_gold()},
	]
	if state == "active":
		list.append({"id": "pay", "text": "Itt az %d arany. (tábori aranyból)" % GOLD_AMOUNT,
			"on_choose": func() -> String: return _pay()})
	return list


static func _first_answer(topic: String, trust: int, answer: String) -> String:
	Progress.mark_asked(ID, topic)
	Progress.change_trust(ID, trust)
	Progress.set_npc_quest(GOLD_QUEST, "active")
	return answer + QUEST_REQUEST


static func _why_gold() -> String:
	Progress.mark_asked(ID, "why_gold")
	if Progress.npc_quest_state(GOLD_QUEST) == "done":
		return "[i]Elvigyorodik a kendő alatt.[/i]\n\nAzt mondtam, ne kérdezd. De mivel fizettél... " \
			+ "a kocsmáros adósa vagyok. Nem pénzzel, hanem egy hordó borral, amit tavaly... " \
			+ "kölcsönvettem. Ő ezt még nem tudja. És jobb, ha nem is tudja meg."
	return "[i]Közelebb hajol, a gyertya fénye megvillan a szemében.[/i]\n\nNe kérdezd. " \
		+ "Annyit mondhatok, hogy nem magamnak kell. Na jó, nem csak magamnak."


## A fizetés a tábori aranyból: utána a zsákmányából ad egy epikus tárgyat (a tábori ládába).
static func _pay() -> String:
	if Progress.camp_gold < GOLD_AMOUNT:
		Audio.play("ui_error")
		return "[i]Megrázza az erszényedet, aztán visszadobja.[/i]\n\nEz nem %d arany. " % GOLD_AMOUNT \
			+ "Nekem is tudok számolni, barátom. (Tábori aranyad: %d)" % Progress.camp_gold
	Progress.camp_gold -= GOLD_AMOUNT
	var item := Items.random_item("epic", "epic")
	Progress.add_to_stash(item)
	Progress.set_npc_quest(GOLD_QUEST, "done")
	Progress.mark_asked(ID, "pay")
	Progress.change_trust(ID, PAID_TRUST)
	Progress.save_game()
	Audio.play("coin")
	return "[i]Kiönti az aranyat a ládára, és gyorsan, gyakorlott mozdulatokkal megszámolja.[/i]\n\n" \
		+ "...négyszázkilencvennyolc, négyszázkilencvenkilenc, ötszáz. Hm. Pontos vagy. Ezt szeretem.\n\n" \
		+ "[i]Belenyúl a háta mögötti zsákba, és odadob neked valamit.[/i]\n\n" \
		+ "Tessék, ezt [b]%s[/b] néven ismerik. Nekem túl feltűnő, neked épp jó lesz. " % item["name"] \
		+ "Ha kérdezik, nem tőlem kaptad.\n\n" \
		+ "[color=#7a4a10](-%d tábori arany; a(z) %s a tábori ládába került.)[/color]" % [GOLD_AMOUNT, item["name"]]


## Az álló kockája a beszélgetés képéhez.
static func portrait() -> Texture2D:
	var face := AtlasTexture.new()
	face.atlas = SHEET
	face.region = Rect2(0, 0, 16, 28)
	return face


## Álló animáció (lassan lélegzik) a rejtekszobában.
static func frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 3.0)
	for i in 4:
		var frame := AtlasTexture.new()
		frame.atlas = SHEET
		frame.region = Rect2(i * 16, 0, 16, 28)
		frames.add_frame("default", frame)
	return frames
