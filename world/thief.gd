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
## A második kérés (a fizetés után): egy epikus tőr; utána elmondja, honnan van a zsákmány.
const DAGGER_QUEST := "thief_dagger"
const DAGGER_TRUST := 20

const FIRST_GREETING := "[i]A gyertya lángja megremeg. Egy kendős alak pattan fel a ládáról, " \
	+ "a kezében kés villan.[/i]\n\nHé! Ki engedett be? [b]Mit csinálsz itt?[/b]"
const GREETING := "[i]Fel sem néz, tovább számolja az érméket.[/i]\n\nMegint te? Hozod már, amit kértem?"
const PAID_GREETING := "[i]Biccent, és egy aranyat pörget az ujjai között.[/i]\n\n" \
	+ "Á, a kedvenc ügyfelem. Üljön le, ha talál helyet a zsákmány között."
const DAGGER_GREETING := "[i]Felnéz a konyhakésről, amivel épp a körmét pucolja.[/i]\n\n" \
	+ "Na? Megvan a tőröm? Ezzel a vacakkal még egy kenyeret sem lehet rendesen megszegni."
const FRIEND_GREETING := "[i]Az új tőrét élezi, és elvigyorodik, amikor meglát.[/i]\n\n" \
	+ "Gyere csak, barátom. Neked mindig nyitva az ajtó... a ládák mögött."
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
	DAGGER_QUEST: {"name": "Egy kisebb szívesség",
		"text": "A tolvaj régi tőrét elvették tőle, és újat akar, de nem akármilyet: hozz neki egy "
			+ "[b]epikus tőrt[/b] a Mélységből (bármilyen tőr jó, csak epikus legyen). A táskádból vagy "
			+ "a kezedből is átadhatod.",
		"reward": "a tolvaj bizalma (és egy történet)", "doing": "vigyél neki egy epikus tőrt",
		"done": "a tőr átadva"},
	LETTER_QUEST: {"name": "Levél a mélybe",
		"text": "A tolvaj egy lepecsételt levelet bízott rád. Vidd le a [b]10. emeleti boltosnak[/b] "
			+ "(a táskádban legyen), és a pultnál a [b][G][/b] gombbal add át neki. Aztán mondd el a "
			+ "tolvajnak, hogy célba ért.",
		"reward": "%d arany a boltostól (és megtudod, ki a tolvaj)" % LETTER_GOLD,
		"doing": "vidd le a levelet a 10. emeleti boltosnak", "doing_delivered": "mondd el a tolvajnak",
		"done": "a levél célba ért"},
}
## A harmadik kérés (a tőr után): levél a kazamata 10. emeleti boltosának.
const LETTER_QUEST := "thief_letter"
const LETTER_FLOOR := 10
const LETTER_GOLD := 150
const LETTER_ID := "thief_letter"
## Belső jelző (Progress.npc_quests): a tolvaj a kocsmába költözött (onnantól játszható karakter, lásd Characters).
const TAVERN_FLAG := "thief_tavern"
const REAL_NAME := "Bence"
const LETTER_REQUEST := "\n\n[i]Aztán elhallgat, és sokáig babrál valamit a ládája mélyén. Végül egy " \
	+ "lepecsételt levelet húz elő.[/i]\n\n" \
	+ "Van még egy utolsó kérésem. Odalent, a [b]tizedik emeleten[/b] van egy bolt. A boltos... régi barátom. " \
	+ "Ő tartott életben, amikor először lementem. Vidd le neki ezt a levelet. Ne nyisd fel, és ne kérdezz.\n\n" \
	+ "Ha átadtad, gyere vissza, és mondd el. Akkor... akkor talán elmondom, ki vagyok."
const LETTER_GREETING := "[i]Idegesen dobol az ujjaival a ládán.[/i]\n\n" \
	+ "Na? Leértél a tizedikre? Átadtad a levelet?"
const DELIVERED_STORY := "[i]Amikor meghallja, hogy a levél célba ért, lassan leül. Aztán leveszi a " \
	+ "kendőt az arcáról. Fiatalabb, mint gondoltad, és a szeme ugyanolyan szürke, mint az öreg kapitányé.[/i]\n\n" \
	+ "A nevem [b]Bence[/b]. Az apám Benedek volt, a királyi őrség zászlóvivője. Gáspár kapitány embere.\n\n" \
	+ "Tizenkét évvel ezelőtt lement a Mélységbe a többiekkel, és nem jött vissza. Én akkor még gyerek " \
	+ "voltam. Amikor elég idős lettem, utána mentem. Azt hittem, megtalálom. A tizedik emeleten csak a " \
	+ "pajzsukat találtam meg, meg azt a boltost, aki befogadott, és megtanított túlélni.\n\n" \
	+ "Azóta lopok. A városi uraktól, akik meg sem kérdezték, mi lett az apámmal. A királytól, aki leküldte. " \
	+ "Azt hittem, ettől jobb lesz. Nem lett.\n\n" \
	+ "[i]Feláll, és körbenéz a zsákmányon.[/i]\n\n" \
	+ "A levélben azt írtam a boltosnak, hogy jól vagyok. Hogy ne várjon rám többet odalent. Mert azt hiszem, " \
	+ "ideje feljönnöm a sötétből.\n\n" \
	+ "Elmegyek a [b]kocsmába[/b]. Azt mondják, az öreg kapitány is ott iszik mostanában. Ideje, hogy " \
	+ "beszéljek vele az apámról. És ha egyszer szükséged lesz valakire, aki odalent is ismeri az utat... " \
	+ "ott megtalálsz.\n\n" \
	+ "[color=#7a4a10](Bence a kocsmába költözött. Mostantól játszható karakter: a kocsmában átveheted az irányítást.)[/color]"
## A második kérés: a fizetés után (és ha egy régebbi mentésben már fizettél, a "Van még munkád?" kérdésre).
const DAGGER_REQUEST := "\n\n[i]Aztán elkomolyodik, és a szemedbe néz.[/i]\n\n" \
	+ "Ha már ilyen megbízható vagy... volna még egy kisebb szívességem. A régi tőrömet tavaly elvették " \
	+ "tőlem, egy kocsmai verekedésben. Azóta ezzel a konyhakéssel járok, és szégyellem magam.\n\n" \
	+ "Hozz nekem egy [b]epikus tőrt[/b] a Mélységből. Nem érdekel, milyet: fagyosat, lángolót, csak " \
	+ "éles legyen, és ne törjön el az első zárnál. Odalent elég sok halott kalandor hagyott hátra ilyesmit."
## A tőr átadása után: honnan van a zsákmány (később a "Honnan van ez a sok holmi?" kérdésre is).
const LOOT_STORY := "[i]Leül a ládára, és a gyertya fényében körbemutat a zsákmányon.[/i]\n\n" \
	+ "Tudni akarod, honnan van mindez? Jó. Megérdemled.\n\n" \
	+ "A gyűrűk és a nyakláncok nagy része a városi urak ládáiból jött. Gazdag, kövér emberek, akik " \
	+ "azt hiszik, egy lakat megvédi őket. Az óra, az a megállított óra ott a sarokban... azt a polgármester " \
	+ "hálószobájából hoztam el, miközben horkolt. Azóta nem tudja, hány óra van.\n\n" \
	+ "A borosüvegek a kocsmáros pincéjéből vannak. Ő a patkányokra fogja. A patkányok nem panaszkodnak.\n\n" \
	+ "[i]Elhalkul a hangja.[/i]\n\n" \
	+ "A kardok, a sisak és a vértek viszont... azokat a Mélységből hoztam fel. A tizedik emelet környékén, " \
	+ "egy nagy teremben, csupa halott katona feküdt, a király címerével a pajzsukon. Harminc pajzs, ha jól " \
	+ "számoltam... nem, tizenöt. A többit lejjebb vitte valami. Nekik már nem kellett.\n\n" \
	+ "[i]Megforgatja a kezében az új tőrt.[/i]\n\n" \
	+ "Ha valaha találkozol egy öreg katonával, egy bekötött fejű kapitánnyal... ne mondd el " \
	+ "neki, honnan van ez a sok holmi. Ő is ott volt. És szerintem még mindig ott van, legalábbis fejben."


## A köszönése: az első találkozáskor rád kérdez, utána már ismer.
static func greeting() -> String:
	match Progress.npc_quest_state(GOLD_QUEST):
		"": return FIRST_GREETING
		"active": return GREETING
	match Progress.npc_quest_state(DAGGER_QUEST):
		"active": return DAGGER_GREETING
		"done":
			return LETTER_GREETING if Progress.npc_quest_state(LETTER_QUEST) in ["active", "delivered"] \
				else FRIEND_GREETING
	return PAID_GREETING


static func options(inventory: Inventory) -> Array[Dictionary]:
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
	match Progress.npc_quest_state(DAGGER_QUEST):
		"":
			# Régebbi mentés: már fizettél, de a tőrt még nem kérte.
			list.append({"id": "more_work", "text": "Van még munkád számomra?",
				"on_choose": func() -> String: return _more_work()})
		"active":
			list.append({"id": "give_dagger", "text": "Itt a tőr, amit kértél. (epikus tőr átadása)",
				"on_choose": func() -> String: return _give_dagger(inventory)})
		"done":
			list.append({"id": "loot_story", "text": "Honnan van ez a sok holmi?",
				"on_choose": func() -> String: return _loot_story()})
			match Progress.npc_quest_state(LETTER_QUEST):
				"":
					# Régebbi mentés: a tőr már megvolt, de a levelet még nem adta oda.
					list.append({"id": "more_work_letter", "text": "Van még munkád számomra?",
						"on_choose": func() -> String: return _ask_letter(inventory, "[i]Elgondolkodik.[/i]")})
				"active":
					if not has_letter(inventory):
						list.append({"id": "lost_letter", "text": "Elvesztettem a levelet...",
							"on_choose": func() -> String: return _lost_letter(inventory)})
				"delivered":
					list.append({"id": "delivered", "text": "Átadtam a levelet a boltosnak.",
						"on_choose": func() -> String: return _letter_delivered()})
	# Ha a királynál hallgattál róla, egyszer meghálálja.
	if Progress.npc_quest_state(King.THIEF_FATE) == "protected" and not Progress.asked_topics(ID).has("king_secret"):
		list.append({"id": "king_secret", "text": "A király kérdezett rólad. Nem árultalak el.",
			"on_choose": func() -> String: return _thanks_for_silence(inventory)})
	return list


## Hálából a legendás Árnyékpengét adja (a táskádba, vagy ha tele van, a tábori ládába).
static func _thanks_for_silence(inventory: Inventory) -> String:
	Progress.mark_asked(ID, "king_secret")
	Progress.change_trust(ID, 30)
	var blade := Items.create("dagger_shadow")
	var where := "a táskádba"
	if inventory.is_bag_full():
		Progress.add_to_stash(blade)
		where = "a tábori ládába (tele volt a táskád)"
	else:
		inventory.add_item(blade)
	Progress.save_game()
	Audio.play("level_up")
	return "[i]Egy pillanatig szóhoz sem jut. Aztán leveszi a kendőt, és most először látod az arcát: " \
		+ "fiatalabb, mint gondoltad.[/i]\n\n" \
		+ "A király... és te nem mondtad el neki. Pedig megfizetett volna érte, ugye? Biztosan.\n\n" \
		+ "[i]A ládához lép, és a legaljáról kivesz egy fekete, szinte fényt elnyelő pengét.[/i]\n\n" \
		+ "Ez az [b]Árnyékpenge[/b]. A király kincstárából hoztam el, a legszebb darab, ami valaha a kezembe " \
		+ "került. Soha nem adtam volna el. Neked adom.\n\n" \
		+ "[color=#7a4a10](Az Árnyékpenge %s került.)[/color]" % where


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
	Progress.set_npc_quest(DAGGER_QUEST, "active")
	Progress.mark_asked(ID, "pay")
	Progress.change_trust(ID, PAID_TRUST)
	Progress.save_game()
	Audio.play("coin")
	return "[i]Kiönti az aranyat a ládára, és gyorsan, gyakorlott mozdulatokkal megszámolja.[/i]\n\n" \
		+ "...négyszázkilencvennyolc, négyszázkilencvenkilenc, ötszáz. Hm. Pontos vagy. Ezt szeretem.\n\n" \
		+ "[i]Belenyúl a háta mögötti zsákba, és odadob neked valamit.[/i]\n\n" \
		+ "Tessék, ezt [b]%s[/b] néven ismerik. Nekem túl feltűnő, neked épp jó lesz. " % item["name"] \
		+ "Ha kérdezik, nem tőlem kaptad.\n\n" \
		+ "[color=#7a4a10](-%d tábori arany; a(z) %s a tábori ládába került.)[/color]" % [GOLD_AMOUNT, item["name"]] \
		+ DAGGER_REQUEST


## Régebbi mentés: a fizetés már megvolt, de a tőrt még nem kérte; most kéri.
static func _more_work() -> String:
	Progress.mark_asked(ID, "more_work")
	Progress.set_npc_quest(DAGGER_QUEST, "active")
	return "[i]Elgondolkodva megvakarja az állát a kendő alatt.[/i]\n\nMost, hogy mondod..." + DAGGER_REQUEST


## Epikus tőr átadása: a táskából vagy a kézből (a kezedben lévő helyére a rozsdás kard kerül).
static func _give_dagger(inventory: Inventory) -> String:
	var dagger: Variant = null
	for i in inventory.bag.size():
		if is_epic_dagger(inventory.bag[i]):
			dagger = inventory.take_from_bag(i)
			break
	if dagger == null and is_epic_dagger(inventory.equipment["weapon"]):
		dagger = inventory.equipment["weapon"]
		inventory.equipment["weapon"] = Items.create("sword_rusty")
		inventory.changed.emit()
	if dagger == null:
		Audio.play("ui_error")
		return "[i]Végignéz a fegyvereiden, aztán csalódottan legyint.[/i]\n\n" \
			+ "Ez nem az, amit kértem. [b]Epikus tőrt[/b] hozz, ne ilyen kenyérvágót. Odalent a Mélységben " \
			+ "keresd, a ládákban vagy a halottaknál."
	Progress.set_npc_quest(DAGGER_QUEST, "done")
	Progress.mark_asked(ID, "give_dagger")
	Progress.change_trust(ID, DAGGER_TRUST)
	Progress.save_game()
	Audio.play("level_up")
	return "[i]Elveszi a(z) %s pengét, és sokáig forgatja a gyertya fényében. " % dagger["name"] \
		+ "Végighúzza a hüvelykujját az élén, aztán halkan füttyent.[/i]\n\n" \
		+ "Ez... ez gyönyörű. Ilyen pengével bármelyik zár kinyílik, és bármelyik vita gyorsan véget ér. " \
		+ "Köszönöm, barátom. Komolyan.\n\n" \
		+ "[i]Kidobja a konyhakést a sarokba, a tőrt pedig az övébe csúsztatja.[/i]\n\n" \
		+ "Te többet tettél értem, mint bárki ebben a nyomorult városban. Úgyhogy most elmondok valamit, " \
		+ "amit eddig senkinek.\n\n" + LOOT_STORY + _ask_letter(inventory, "")


## A levél: küldetéstárgy (nem vehető fel, nem adható el), a táskában kell lennie.
static func letter() -> Dictionary:
	return {"id": LETTER_ID, "name": "Lepecsételt levél", "slot": "quest", "rarity": "rare", "stats": {},
		"price": 0, "quest": true, "icon_path": "res://assets/items/thief_letter.png",
		"description": "A tolvaj levele a 10. emeleti boltosnak. Vörös viaszpecsét zárja. Ne nyisd fel."}


static func is_letter(item: Variant) -> bool:
	return item is Dictionary and item.get("id", "") == LETTER_ID


## Nálad van-e a levél (a táskában vagy a tábori ládában).
static func has_letter(inventory: Inventory) -> bool:
	for item: Variant in inventory.bag:
		if is_letter(item):
			return true
	for item: Variant in Progress.stash:
		if is_letter(item):
			return true
	return false


## A levél a táskába (ha tele van, a tábori ládába); a küldetés elindul.
static func _ask_letter(inventory: Inventory, before: String) -> String:
	Progress.set_npc_quest(LETTER_QUEST, "active")
	return before + LETTER_REQUEST + "\n\n" + _hand_letter(inventory)


static func _hand_letter(inventory: Inventory) -> String:
	var where := "a táskádba"
	if inventory.is_bag_full():
		Progress.add_to_stash(letter())
		where = "a tábori ládába (tele volt a táskád; vedd ki, mielőtt leszállsz)"
	else:
		inventory.add_item(letter())
	Progress.save_game()
	return "[color=#7a4a10](A lepecsételt levél %s került.)[/color]" % where


static func _lost_letter(inventory: Inventory) -> String:
	return "[i]Mélyet sóhajt, aztán új lapot vesz elő, és gyorsan újraírja.[/i]\n\n" \
		+ "Ezt most ne veszítsd el. A tizedik emelet, a boltos. [G] a pultnál.\n\n" + _hand_letter(inventory)


## A levél célba ért: elmondja, ki ő, és a kocsmába költözik.
static func _letter_delivered() -> String:
	Progress.set_npc_quest(LETTER_QUEST, "done")
	Progress.set_npc_quest(TAVERN_FLAG, "done")
	Progress.mark_asked(ID, "delivered")
	Progress.change_trust(ID, 25)
	Progress.save_game()
	Audio.play("level_up")
	return DELIVERED_STORY


## A boltos a 10. emeleten: átveszi a levelet a táskából (G a pultnál), és fizet érte.
## Visszaadja, amit a boltos mond ("" ha itt nincs mit átadni).
static func deliver_to_shopkeeper(player: Node) -> String:
	if Progress.npc_quest_state(LETTER_QUEST) != "active" or GameState.depth != LETTER_FLOOR:
		return ""
	var inventory: Inventory = player.get_node("Inventory")
	for i in inventory.bag.size():
		if is_letter(inventory.bag[i]):
			inventory.take_from_bag(i)
			player.call("add_gold", LETTER_GOLD)
			Progress.set_npc_quest(LETTER_QUEST, "delivered")
			Progress.save_game()
			return "Bencétől? Végre! Azt hittem, már a farkas gyomrában van... Tessék, %d arany a fáradságodért." \
				% LETTER_GOLD
	return ""


static func _loot_story() -> String:
	Progress.mark_asked(ID, "loot_story")
	return LOOT_STORY


static func is_epic_dagger(item: Variant) -> bool:
	return item is Dictionary and item.get("slot", "") == "weapon" \
		and item.get("weapon_type", "") == "dagger" and item.get("rarity", "") == "epic"


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
