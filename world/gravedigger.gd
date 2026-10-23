class_name Gravedigger
## Csontos Vendel, a csontváz fejű sírásó (lásd Graveyard és Chapel). Eleinte a temetőben áll,
## és csak mesél. A "Segíthetek valamiben?" kérdésre 50 csontváz elpusztítását kéri (a J könyv
## "Csontváz sírásó" fülén); utána átsétál a temető melletti régi kápolnába, és onnantól ott van.
## Az 50 csontváz után elmeséli a történetét, és egy Szent kereszt amulettet kér.

const ID := "gravedigger"
const NAME := "Csontos Vendel, a sírásó"
const SHORT_NAME := "Vendel"
const SHEET: Texture2D = preload("res://assets/characters/gravedigger.png")
const SHOVEL: Texture2D = preload("res://assets/characters/shovel.png")

const SKELETON_QUEST := "digger_skeletons"
## Belső jelző (Progress.npc_quests): ennyi csontvázat ölt meg a küldetés elfogadásakor (szövegként).
const SKELETON_BASE := "digger_skeletons_base"
const SKELETON_GOAL := 50
## Ezek számítanak csontváznak (a Progress.kills nevei).
const SKELETONS: Array[String] = ["skelet", "skeleton_legionary", "giant_skeleton"]
const SKELETON_GOLD := 150
const CROSS_QUEST := "digger_cross"
const CROSS_ID := "amulet_cross"
const CROSS_GOLD := 250
## Belső jelző: Vendel már beköltözött a kápolnába ("done"; a séta után).
const CHAPEL_FLAG := "digger_chapel"

const GREETING := "[i]Felnéz az ásójáról. Az arca helyén csupasz koponya, a szemgödreiben halvány fény pislákol.[/i]\n\n" \
	+ "Ne ijedj meg, vándor. Ha bántani akarnálak, már egy gödörrel arrébb feküdnél.\n" \
	+ "Vendel vagyok. Én temetem el azokat, akik visszajönnek a Mélységből... meg azokat is, akik nem."
const CHAPEL_GREETING := "[i]Vendel a por lepte padok között söprög, a régi oltár előtt. Amikor belépsz, " \
	+ "a szemgödreiben felvillan a fény.[/i]\n\nÁ, te vagy az. Gyere csak beljebb, a por nem harap."

const QUESTS := {
	SKELETON_QUEST: {"name": "Csontok nyugalma",
		"text": "Vendel, a sírásó szerint a Mélységben kóborló csontvázak a tábor elveszett halottai: "
			+ "a testüket elvitte a sötét, a lelkük nem nyugszik. Pusztíts el [b]%d csontvázat[/b] " % SKELETON_GOAL
			+ "a kazamatában (csontvázak, csontlégiósok, óriás csontvázak), hogy végre megpihenhessenek.",
		"reward": "%d tábori arany (és Vendel története)" % SKELETON_GOLD,
		"doing": "pusztíts el csontvázakat", "done": "a csontok megpihentek"},
	CROSS_QUEST: {"name": "A kápolna keresztje",
		"text": "Vendel a régi kápolnában él. Az oltár fölött egykor egy megszentelt kereszt függött, de a "
			+ "Mélység elvitte. Hozz neki egy [b]Szent kereszt[/b] amulettet (a táskádban legyen), hogy "
			+ "újra megáldhassa vele a halottakat.",
		"reward": "%d tábori arany (és Vendel áldása)" % CROSS_GOLD,
		"doing": "vigyél Vendelnek egy Szent kereszt amulettet", "done": "a kereszt újra az oltáron"},
}

const SMALL_TALK: Array[Dictionary] = [
	{"id": "who", "text": "Ki vagy te valójában?", "trust": 5,
		"answer": "Valaha én is kalandor voltam. Lementem a tizenkettedik emeletig, és ott egy lich megérintett.\n\n" \
			+ "Nem haltam meg. Csak... elfelejtettem élni. A húsom lassan lekopott, a csontjaim maradtak.\n" \
			+ "A tábor népe előbb félt tőlem, aztán megszokott. Most én vigyázok a halottaikra."},
	{"id": "graves", "text": "Kik nyugszanak itt?", "trust": 3,
		"answer": "Mindenféle népek. Kovácsinasok, zsoldosok, egy dalnok, aki a hetedik emeleten akart dalt írni a sötétről.\n\n" \
			+ "A legtöbb sír üres, tudod. Csak a nevük jött vissza, meg néha egy kard vagy egy sisak.\n" \
			+ "Azért mindegyiket rendesen megásom. Egy névnek is jár a hely."},
	{"id": "shovel", "text": "Szép ásó. Honnan van?", "trust": 2,
		"answer": "[i]Megsimítja a nyelét, mintha egy régi barát vállát veregetné.[/i]\n\n" \
			+ "Ezt még a nagyapám kovácsolta, mikor a tábor csak három sátor volt. Háromszáz sírt ástam vele.\n" \
			+ "Egyszer egy ghoult is agyoncsaptam vele, aki kimászott az egyikből. Azóta mélyebbre ások."},
	{"id": "night", "text": "Nem félsz itt egyedül éjszaka?", "trust": 2,
		"answer": "Félni? [i]Csontos nevetés, mintha kockák gurulnának egy dobozban.[/i]\n\n" \
			+ "Éjjel néha hallom, ahogy a föld alatt kaparnak. De az csak a Mélység lélegzik.\n" \
			+ "Ha egyszer kopogást hallasz egy sírból, fiam... akkor fuss. Addig ne."},
]


static func greeting() -> String:
	return CHAPEL_GREETING if in_chapel() else GREETING


## A küldetés elfogadása után a kápolnába költözik (a séta után ott marad).
static func in_chapel() -> bool:
	return Progress.npc_quest_state(CHAPEL_FLAG) == "done"


## El kell-e indulnia a kápolnába (elfogadta a küldetést, de még a temetőben áll).
static func should_walk() -> bool:
	return Progress.npc_quest_state(SKELETON_QUEST) != "" and not in_chapel()


static func skeleton_kills() -> int:
	var total := 0
	for name in SKELETONS:
		total += int(Progress.kills.get(name, 0))
	return total


## A küldetés elfogadása óta elpusztított csontvázak (legfeljebb a cél).
static func skeleton_progress() -> int:
	var base := int(Progress.npc_quest_state(SKELETON_BASE))
	return mini(skeleton_kills() - base, SKELETON_GOAL)


## A J könyv "folyamatban" szövege (a csontváz-küldetésnél a haladással).
static func doing_text(id: String, fallback: String) -> String:
	if id == SKELETON_QUEST:
		return "%s: %d / %d" % [fallback, skeleton_progress(), SKELETON_GOAL]
	return fallback


static func options(inventory: Inventory) -> Array[Dictionary]:
	var list: Array[Dictionary] = SMALL_TALK.duplicate()
	match Progress.npc_quest_state(SKELETON_QUEST):
		"":
			list.append({"id": "help", "text": "Segíthetek valamiben?",
				"on_choose": func() -> String: return _give_skeleton_quest()})
		"active":
			if skeleton_progress() >= SKELETON_GOAL:
				list.append({"id": "skeletons_done", "text": "Elpusztítottam ötven csontvázat.",
					"on_choose": func() -> String: return _finish_skeletons()})
			else:
				list.append({"id": "skeletons", "text": "Hogy állok a csontvázakkal?",
					"on_choose": func() -> String: return "[i]Vendel az ujjain számol, a csontjai halkan " \
						+ "kocognak.[/i]\n\n%d megpihent, még %d vár rád odalent. Ne siess: a halottak ráérnek." \
						% [skeleton_progress(), SKELETON_GOAL - skeleton_progress()]})
	match Progress.npc_quest_state(CROSS_QUEST):
		"active":
			if has_cross(inventory):
				list.append({"id": "cross", "text": "Hoztam egy Szent kereszt amulettet.",
					"on_choose": func() -> String: return _give_cross(inventory)})
		"done":
			list.append({"id": "blessing", "text": "Hogy vagy, Vendel?",
				"on_choose": func() -> String: return "[i]Az oltár felé biccent, ahol a kereszt halványan " \
					+ "csillog.[/i]\n\nJobban, mint az elmúlt húsz évben bármikor. Éjjel már nem kaparnak a " \
					+ "sírok. Ha egyszer te is odalent maradnál... ne félj. Megtalálom a neved, és helyet " \
					+ "ások neki."})
	return list


static func _give_skeleton_quest() -> String:
	Progress.set_npc_quest(SKELETON_QUEST, "active")
	Progress.set_npc_quest(SKELETON_BASE, str(skeleton_kills()))
	Progress.mark_asked(ID, "help")
	Progress.save_game()
	return "[i]Vendel megtámaszkodik az ásóján, és sokáig nézi a sírokat.[/i]\n\n" \
		+ "Segíthetsz. Tudod, kik azok a csontvázak odalent? Ők a mieink. Akiket nem tudtunk felhozni. " \
		+ "A testüket elvitte a Mélység, és most céltalanul járnak a sötétben, mert senki nem temette el őket.\n\n" \
		+ "Pusztíts el közülük [b]ötvenet[/b]. Nem gyilkosság ez, hidd el: megváltás. Minden csont, ami " \
		+ "széthullik, egy lélek, ami végre hazatalál.\n\n" \
		+ "[i]Felveszi az ásóját.[/i]\n\nÉn addig átmegyek a régi kápolnába, itt a temető mellett. Túl rég " \
		+ "állt üresen. Ott keress, ha végeztél.\n\n" \
		+ "[color=#7a4a10](Új küldetés a J könyvben, a \"Csontváz sírásó\" fülön.)[/color]"


## Az 50 csontváz után: jutalom, a története, és a Szent keresztet kéri.
static func _finish_skeletons() -> String:
	Progress.set_npc_quest(SKELETON_QUEST, "done")
	Progress.add_camp_gold(SKELETON_GOLD)
	Progress.change_trust(ID, 20)
	Progress.set_npc_quest(CROSS_QUEST, "active")
	Progress.save_game()
	Audio.play("level_up")
	return "[i]Vendel lehunyja a szemgödreit. A kápolna hűvös levegője mintha egy pillanatra megmozdulna, " \
		+ "és a gyertyák lángja egyszerre lehajlik.[/i]\n\n" \
		+ "Érzem őket. Ötven lélek... hazaértek. Köszönöm. Fogd, ez a tiéd. " \
		+ "[color=#7a4a10](+%d tábori arany)[/color]\n\n" % SKELETON_GOLD \
		+ "[i]Leül az egyik poros padra, és az ásóját a térdére fekteti.[/i]\n\n" \
		+ "Elmondom, hogy kerültem ide. Húsz éve ebben a kápolnában szolgált Ambrus atya. Én voltam a " \
		+ "harangozója, mielőtt kalandornak álltam. Amikor lementem, Ambrus a nyakamba akasztotta a " \
		+ "kápolna keresztjét: \"Ez hazahoz, fiam.\"\n\n" \
		+ "A tizenkettedik emeleten a lich letépte rólam. Aztán megérintett. A kereszt nélkül nem haltam " \
		+ "meg, de élni sem tudtam tovább: csak a csontjaim jöttek haza. Ambrus atya akkor már nem élt. " \
		+ "Én temettem el, itt, a kápolna mellett.\n\n" \
		+ "[i]Feláll, és az üres falra néz az oltár fölött.[/i]\n\n" \
		+ "A kereszt azóta is hiányzik onnan. Ha a Mélységben valaha rátalálsz egy [b]Szent kereszt[/b] " \
		+ "amulettre, hozd el nekem. Nem lesz ugyanaz... de egy kereszt az kereszt. Újra megáldhatnám " \
		+ "vele a halottainkat.\n\n" \
		+ "[color=#7a4a10](Új küldetés a J könyvben.)[/color]"


static func is_cross(item: Variant) -> bool:
	return item is Dictionary and item.get("id", "") == CROSS_ID


static func has_cross(inventory: Inventory) -> bool:
	for item: Variant in inventory.bag:
		if is_cross(item):
			return true
	return false


static func _give_cross(inventory: Inventory) -> String:
	for i in inventory.bag.size():
		if is_cross(inventory.bag[i]):
			inventory.take_from_bag(i)
			Progress.set_npc_quest(CROSS_QUEST, "done")
			Progress.add_camp_gold(CROSS_GOLD)
			Progress.change_trust(ID, 30)
			Progress.save_game()
			Audio.play("level_up")
			return "[i]Vendel két csontujja közé fogja a keresztet, és a fény felé tartja. Aztán lassan " \
				+ "az oltárhoz lép, és felakasztja a fal szögére, ahol egykor a régi függött.[/i]\n\n" \
				+ "Ambrus atya... nézd. Újra van keresztünk.\n\n" \
				+ "[i]A szemgödreiben a fény melegebb lesz, szinte aranyszínű.[/i]\n\n" \
				+ "Köszönöm, vándor. Fogadd el ezt, és az áldásomat is. Akárhová visz a Mélység, a neved " \
				+ "itt mindig hazatalál. [color=#7a4a10](+%d tábori arany)[/color]" % CROSS_GOLD
	return "Hm? Nem látom nálad a keresztet."


static func frames() -> SpriteFrames:
	var result := SpriteFrames.new()
	result.set_animation_speed("default", 2.0)
	for i in 4:
		var frame := AtlasTexture.new()
		frame.atlas = SHEET
		frame.region = Rect2(i * 24, 0, 24, 32)
		result.add_frame("default", frame)
	return result


static func portrait() -> AtlasTexture:
	var face := AtlasTexture.new()
	face.atlas = SHEET
	face.region = Rect2(0, 0, 24, 32)
	return face


## A figura (ásóval) egy tartó alá: a lába a tartó origójában.
static func build_figure(holder: Node2D) -> AnimatedSprite2D:
	var digger := AnimatedSprite2D.new()
	digger.sprite_frames = frames()
	digger.scale = Vector2(2, 2)
	digger.offset = Vector2(0, -16)
	digger.play()
	holder.add_child(digger)
	# A letöltött ásó: a jobb oldalán, a földbe szúrva, a nyele a keze felé dől.
	var shovel := Sprite2D.new()
	shovel.texture = SHOVEL
	shovel.position = Vector2(14, -18)
	shovel.rotation = -0.45
	shovel.scale = Vector2(1.4, 1.4)
	holder.add_child(shovel)
	return digger
