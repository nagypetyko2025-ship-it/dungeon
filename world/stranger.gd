class_name Stranger
## A kútba esett idegen a nyugati tisztáson, a romos ház mellett (lásd Ruin). Amíg nem mondja
## meg a nevét, "???" a neve. A "Hogy kerültél oda le?" kérdésre létrát kér (a J könyv
## "Kutas idegen" fülén); a létra a tisztás délnyugati sarkában hever a fűben, egy bokor mögött
## (Lőrinc nem árulja el, hol). A megmentése után a kútba le lehet mászni (lásd WellCave).

const ID := "stranger"
const UNKNOWN_NAME := "???"
const REAL_NAME := "Lőrinc"
const LADDER_QUEST := "well_ladder"
## Belső jelző (Progress.npc_quests): a létrát felvetted ("done").
const LADDER_FOUND := "well_ladder_found"
const LADDER_ID := "well_ladder"
const REWARD_GOLD := 120
## A figurája a 0x72 lapról (wizzard_m: öreg, köpenyes tudós), és a sötét sziluettje.
const FIGURE := Rect2(128, 164, 16, 28)
const SILHOUETTE: Texture2D = preload("res://assets/characters/stranger_silhouette.png")

const GREETING := "[i]A kút mélyéről halk, rekedt hang szól fel.[/i]\n\nHé! Van ott fent valaki? " \
	+ "[b]Segíts, kérlek![/b] Itt vagyok lent, a kút alján!"
const RESCUED_GREETING := "[i]Lőrinc a kút kávájának dőlve rajzolgat valamit egy gyűrött papírra.[/i]\n\n" \
	+ "Á, a megmentőm! Gyere, nézd: a kút alatti járatokat rajzolom fel."

const QUESTS := {
	LADDER_QUEST: {"name": "Létra a kútba",
		"text": "A romos ház melletti kút aljáról egy idegen kér segítséget: leszakadt alatta a kötél, "
			+ "és nem tud kimászni. Keress neki valahonnan egy [b]létrát[/b], és engedd le neki a kútba.",
		"reward": "%d tábori arany (és Lőrinc hálája)" % REWARD_GOLD,
		"doing": "keress valahol egy létrát", "doing_carrying": "vidd a létrát a kúthoz",
		"done": "Lőrinc kijutott a kútból"},
	TALISMAN_QUEST: {"name": "A varázsló fókusza",
		"text": "Lőrinc bevallotta, hogy nem csak térképész: varázsló, aki a térképeit varázslattal "
			+ "rajzolja. A régi fókuszköve a kútban maradt, és nélküle a varázslatai szétfolynak. "
			+ "Hozz neki egy [b]epikus talizmánt[/b] (bármilyet, a táskádban legyen).",
		"reward": "%d tábori arany (és Lőrinc tudása)" % TALISMAN_GOLD,
		"doing": "vigyél Lőrincnek egy epikus talizmánt", "done": "Lőrinc újra varázsol"},
}
## A második kérés (a megmentése után): egy epikus talizmán, mert varázsló.
const TALISMAN_QUEST := "well_talisman"
const TALISMAN_GOLD := 200


## A neve: "???", amíg meg nem kérdezed.
static func display_name() -> String:
	return REAL_NAME if Progress.asked_topics(ID).has("name") else UNKNOWN_NAME


static func greeting() -> String:
	return RESCUED_GREETING if Progress.npc_quest_state(LADDER_QUEST) == "done" else GREETING


static func options(inventory: Inventory) -> Array[Dictionary]:
	var list: Array[Dictionary] = [
		{"id": "name", "text": "Mi a neved?", "on_choose": func() -> String: return _ask_name()},
		{"id": "how", "text": "Hogy kerültél oda le?", "on_choose": func() -> String: return _ask_how()},
		{"id": "who", "text": "Ki vagy te?", "on_choose": func() -> String: return _ask_who()},
	]
	if Progress.npc_quest_state(LADDER_QUEST) in ["active", "carrying"] and has_ladder(inventory):
		list.append({"id": "ladder", "text": "Hoztam egy létrát! (leengeded a kútba)",
			"on_choose": func() -> String: return _give_ladder(inventory)})
	if is_rescued():
		match Progress.npc_quest_state(TALISMAN_QUEST):
			"":
				list.append({"id": "next", "text": "Mihez kezdesz most?",
					"on_choose": func() -> String: return _reveal_wizard()})
			"active":
				list.append({"id": "talisman", "text": "Hoztam egy epikus talizmánt.",
					"on_choose": func() -> String: return _give_talisman(inventory)})
			"done":
				list.append({"id": "magic", "text": "Mutass egy varázslatot!",
					"on_choose": func() -> String: return _show_magic()})
	return list


## Bevallja, hogy varázsló, és egy epikus talizmánt kér (fókusznak).
static func _reveal_wizard() -> String:
	Progress.mark_asked(ID, "next")
	Progress.set_npc_quest(TALISMAN_QUEST, "active")
	Progress.save_game()
	return "[i]Körülnéz, mintha attól tartana, hogy valaki hallgatózik, aztán lehalkítja a hangját.[/i]\n\n" \
		+ "Elárulok neked valamit, mert megmentetted az életem. Nem csak térképész vagyok. [b]Varázsló[/b] " \
		+ "vagyok. A térképeimet nem tintával rajzolom: a kő emlékszik, merre vezetnek a járatai, és én " \
		+ "megkérdezem tőle.\n\n" \
		+ "[i]Kinyitja a tenyerét: egy halvány fényfolt villan fel benne, aztán szétfoszlik.[/i]\n\n" \
		+ "Látod? Szétfolyik. A fókuszkövem odalent maradt a kút alján, a víz elmosta. Fókusz nélkül egy " \
		+ "varázsló csak egy öregember, aki furcsa szavakat motyog.\n\n" \
		+ "Hozz nekem egy [b]epikus talizmánt[/b]. Bármilyet: kristályt, szemet, fogat, a lényeg, hogy " \
		+ "erős legyen benne az erő. A Mélységben akad ilyen, ha elég mélyre mész."


static func _give_talisman(inventory: Inventory) -> String:
	for i in inventory.bag.size():
		var item: Variant = inventory.bag[i]
		if item is Dictionary and item.get("slot", "") == "trinket" and item.get("rarity", "") == "epic":
			inventory.take_from_bag(i)
			Progress.set_npc_quest(TALISMAN_QUEST, "done")
			Progress.mark_asked(ID, "talisman")
			Progress.change_trust(ID, 25)
			Progress.camp_gold += TALISMAN_GOLD
			Progress.save_game()
			Audio.play("level_up")
			return "[i]Két kézzel veszi át a(z) %s, és sokáig hallgatja, mintha beszélne hozzá.[/i]\n\n" % item["name"] \
				+ "Igen... ez az. Érzed? Zümmög.\n\n" \
				+ "[i]Suttog valamit. A levegő megremeg körülöttetek, és a kút kávája halványkék fényben izzik " \
				+ "fel egy pillanatra.[/i]\n\n" \
				+ "Visszajött. Évek óta nem éreztem ilyen tisztán a követ. Köszönöm, barátom. Fogadd el ezt; " \
				+ "és ha egyszer újra lemész a kút alá, figyeld a falakat. Lehet, hogy most már mást is mutatnak.\n\n" \
				+ "[color=#7a4a10](+%d tábori arany)[/color]" % TALISMAN_GOLD
	Audio.play("ui_error")
	return "[i]Végignéz a táskádon, aztán szomorúan megrázza a fejét.[/i]\n\n" \
		+ "Nem érzem benne az erőt. [b]Epikus talizmán[/b] kell, és a táskádban legyen."


static func _show_magic() -> String:
	Progress.mark_asked(ID, "magic")
	return "[i]Felemeli a talizmánt, és a tenyerében apró, kék fénygömb születik. Lassan felemelkedik, " \
		+ "megkerüli a fejed, aztán a kút fölött szétpattan, mint egy szikra.[/i]\n\n" \
		+ "Semmi különös. Csak egy kis fény. De odalent, a sötétben, néha egy kis fény mindent jelent."


static func _ask_name() -> String:
	Progress.mark_asked(ID, "name")
	if Progress.npc_quest_state(LADDER_QUEST) == "done":
		return "Lőrinc vagyok, ahogy már mondtam. Királyi térképész. Vagy legalábbis az voltam, mielőtt " \
			+ "három napot egy kút alján töltöttem."
	return "[i]Köhög egyet, a hangja visszhangzik a kőfalakon.[/i]\n\n[b]Lőrinc[/b]. Lőrinc vagyok. " \
		+ "És hidd el, sosem gondoltam, hogy egyszer egy kút aljáról kell bemutatkoznom."


static func _ask_how() -> String:
	Progress.mark_asked(ID, "how")
	match Progress.npc_quest_state(LADDER_QUEST):
		"done":
			return "Ne is emlékeztess rá. A kötél elszakadt, én meg zuhantam. Szerencsére víz volt alattam... " \
				+ "meg egy csomó csiga."
		"active", "carrying":
			return "[i]Felsóhajt.[/i]\n\nMint mondtam: elszakadt a kötél. Kérlek, keress valahol egy " \
				+ "[b]létrát[/b]! Akármilyet, csak bírjon el."
	Progress.set_npc_quest(LADDER_QUEST, "active")
	Progress.save_game()
	return "[i]Hosszan hallgat, aztán megszólal.[/i]\n\nKötélen ereszkedtem le, hogy feltérképezzem a kút " \
		+ "alját. Azt beszélik, a falában egy régi járat nyílik, ami egészen a Mélységig vezet. Igaz is: ott " \
		+ "van, csak éppen be van omolva. Amikor vissza akartam mászni, a kötél elszakadt.\n\n" \
		+ "Három napja vagyok itt lent. Kiabáltam, de errefelé senki nem jár.\n\n" \
		+ "[i]A hangja elcsuklik.[/i]\n\nKérlek... szerezz nekem valahonnan egy [b]létrát[/b]. Hozd ide, " \
		+ "és engedd le. Nem tudom, hol találsz, de nélküle innen nem jutok ki."


static func _ask_who() -> String:
	Progress.mark_asked(ID, "who")
	return "A király térképésze vagyok. Vagyis... az voltam. Tizenkét éve én rajzoltam meg a Mélység első " \
		+ "tíz emeletének térképét a király seregének. Gáspár kapitány embereinek.\n\n" \
		+ "[i]Elhallgat.[/i]\n\nAz én térképem vitte le őket a halálba. Azóta minden régi kutat és járatot " \
		+ "feltérképezek, hátha találok egy másik utat lefelé. Egy biztonságosabbat."


## A létra: küldetéstárgy (nem vehető fel, nem adható el).
static func ladder() -> Dictionary:
	return {"id": LADDER_ID, "name": "Régi létra", "slot": "quest", "rarity": "common", "stats": {},
		"price": 0, "quest": true, "icon_path": "res://assets/props/ladder.png",
		"description": "Kicsit korhadt, de elbír egy embert. A kútba lógó idegennek kell."}


static func is_ladder(item: Variant) -> bool:
	return item is Dictionary and item.get("id", "") == LADDER_ID


static func has_ladder(inventory: Inventory) -> bool:
	for item: Variant in inventory.bag:
		if is_ladder(item):
			return true
	for item: Variant in Progress.stash:
		if is_ladder(item):
			return true
	return false


## A fűben heverő létra felvétele: a táskába (ha tele van, a tábori ládába). Visszaadja, hová került.
static func pick_up_ladder(inventory: Inventory) -> String:
	Progress.set_npc_quest(LADDER_FOUND, "done")
	if Progress.npc_quest_state(LADDER_QUEST) == "active":
		Progress.set_npc_quest(LADDER_QUEST, "carrying")
	var where := "a táskádba"
	if inventory.is_bag_full():
		Progress.add_to_stash(ladder())
		where = "a tábori ládába (tele volt a táskád)"
	else:
		inventory.add_item(ladder())
	Progress.save_game()
	return where


static func _give_ladder(inventory: Inventory) -> String:
	var removed := false
	for i in inventory.bag.size():
		if is_ladder(inventory.bag[i]):
			inventory.take_from_bag(i)
			removed = true
			break
	if not removed:
		for i in Progress.stash.size():
			if is_ladder(Progress.stash[i]):
				Progress.stash.remove_at(i)
				break
	Progress.set_npc_quest(LADDER_QUEST, "done")
	Progress.mark_asked(ID, "ladder")
	Progress.change_trust(ID, 30)
	Progress.camp_gold += REWARD_GOLD
	Progress.save_game()
	Audio.play("level_up")
	return "[i]Leengeded a létrát. Hosszú percekig csak a nyikorgását hallod, aztán egy sovány, kormos " \
		+ "arcú férfi bukkan fel a kút peremén, és a fűbe zuhan.[/i]\n\n" \
		+ "Ég... igazi ég. Azt hittem, soha többé nem látom.\n\n" \
		+ "[i]Feltápászkodik, és megszorítja a kezed.[/i]\n\n" \
		+ "Köszönöm. Nincs sok mindenem, de ezt fogadd el. És ha egyszer lejutsz oda, ahová én sosem " \
		+ "mertem, gondolj rám: a kút alatti járat is a Mélységbe vezet. Egyszer kiássuk.\n\n" \
		+ "[color=#7a4a10](+%d tábori arany)[/color]" % REWARD_GOLD


## Kijutott a kútból (onnantól a kút mellett áll).
static func is_rescued() -> bool:
	return Progress.npc_quest_state(LADDER_QUEST) == "done"


## A képe a beszélgetésben: amíg nem tudod a nevét, csak egy sötét sziluett.
static func portrait() -> Texture2D:
	var face := AtlasTexture.new()
	face.atlas = SpriteSheet.TEXTURE if display_name() == REAL_NAME else SILHOUETTE
	face.region = FIGURE if display_name() == REAL_NAME else Rect2(Vector2.ZERO, FIGURE.size)
	return face
