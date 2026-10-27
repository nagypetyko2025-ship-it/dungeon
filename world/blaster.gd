class_name Blaster
## Puskás Döme, a robbantómester: a kocsma kettes szobájában lakik (lásd Town.ROOMS). Első kopogásra felébred,
## kijön, és onnantól az ajtaja előtt áll a folyosón. Küldetései (a J könyv "Robbantómester" fülén):
## 1. Goblinpor: puskapor 8 robbanó goblintól (a küldetés elfogadása óta).
## 2. Lassú kanóc: kanóc 5 kalózpuskástól.
## 3. Híd a szakadék fölött: Döme előremegy a bányába, a szakadéknál vár; ott E-re felrobbantja a túlsó fal
##    sziklaorrát, ami beékelődik a leszakadt híd helyére, rá deszkát fektet: át lehet menni (lásd Mine).
## (A beszélgetést a Town (folyosó) és a Mine (szakadék) is megnyitja; a hely szerint mások az opciók.)

const ID := "blaster"
const NAME := "Puskás Döme, a robbantómester"
## 0x72 törpe (dwarf_m): álló + futó kockák.
const FIGURE := Rect2(128, 292, 16, 28)
## A szobája a kocsma folyosóján (Town.ROOMS indexe).
const ROOM := 1
const MET_FLAG := "blaster_met"
const POWDER_QUEST := "blaster_powder"
const POWDER_BASE := "blaster_powder_base"
const POWDER_TARGET := "kamikaze_goblin"
const POWDER_GOAL := 8
const POWDER_GOLD := 120
const FUSE_QUEST := "blaster_fuse"
const FUSE_BASE := "blaster_fuse_base"
const FUSE_TARGET := "pirate_gunner"
const FUSE_GOAL := 5
const FUSE_GOLD := 150
const BLAST_QUEST := "blaster_blast"
## A kút alatti beomlott járat (a híd után): tűzhangya-mirigy a gyújtáshoz, aztán Döme a kút aljára megy, és ott
## felrobbantja a törmeléket (WellCave). "ready": a kút alján vár, "done": a járat nyitva (Lőrinc régi műhelye).
const WELL_QUEST := "blaster_well"
const WELL_BASE := "blaster_well_base"
const WELL_TARGET := "fire_ant"
const WELL_GOAL := 6

const QUESTS := {
	POWDER_QUEST: {"name": "Goblinpor",
		"text": "Puskás Döme egy sziklaorr felrobbantásával hidat verne a bánya szakadéka fölött, de nincs "
			+ "puskapora. A robbanó goblinok hordónyi port cipelnek a hátukon: szerezz port [b]%d robbanó " % POWDER_GOAL
			+ "goblintól[/b] (a küldetés elfogadása óta; a 3. emelet alatt jönnek).",
		"reward": "%d tábori arany" % POWDER_GOLD, "doing": "szerezz port a robbanó goblinoktól",
		"done": "van puskapor"},
	FUSE_QUEST: {"name": "Lassú kanóc",
		"text": "Döme kanócai a bányában beáztak. A kalózpuskások száraz, kátrányos, egyenletesen égő kanóccal "
			+ "gyújtanak: szerezz kanócot [b]%d kalózpuskástól[/b] (a küldetés elfogadása óta)." % FUSE_GOAL,
		"reward": "%d tábori arany" % FUSE_GOLD, "doing": "szerezz kanócot a kalózpuskásoktól",
		"done": "van kanóc"},
	BLAST_QUEST: {"name": "Híd a szakadék fölött",
		"text": "Döme előrement a bányába, a szakadéknál vár. Menj oda, és nézd meg, ahogy felrobbantja a túlsó "
			+ "fal sziklaorrát: ha jól számolt, a szikla pont beékelődik oda, ahol a híd leszakadt.",
		"reward": "átjárás a szakadék túlsó partjára", "doing": "menj a bányába, Döméhez",
		"done": "a szakadék fölött újra van híd"},
	WELL_QUEST: {"name": "A kút alatti járat",
		"text": "A kút alján, Lőrinc régi barlangjában egy beomlott járat vezet kelet felé. Döme felrobbantaná, de a "
			+ "nedves barlangban a kanóc nem gyullad: tűzhangya-mirigy kell a gyújtáshoz. Győzz le [b]%d tűzhangyát[/b] " % WELL_GOAL
			+ "(a küldetés elfogadása óta), aztán szólj Döménak a bányában. Utána a kút alján vár, a törmeléknél.",
		"reward": "átjárás a beomlott járaton", "doing": "győzz le tűzhangyákat",
		"done": "a kút alatti járat nyitva"},
}

## Első kopogásra (a folyosón, felirat).
const WAKE_TEXT := "Kopogsz. A horkolás abbamarad, bent valami nagyot csattan, aztán kivágódik az ajtó: egy kormos " \
	+ "képű, szakállas öreg törpe áll benne, a szemöldöke félig leégett."
const GREETING := "[i]Az alacsony, széles vállú öreg a szemöldökét vakarja. Pontosabban azt, ami maradt belőle.[/i]" \
	+ "\n\nNa? Mi kell? Ha robbantani, jó helyen jársz. Ha csendet, akkor rossz helyen."
const MINE_GREETING := "[i]Döme a szakadék szélén guggol, és fél szemmel a túlsó sziklafalat méregeti.[/i]\n\n" \
	+ "Na, megjöttél. Ott, az a sziklaorr a híd csonkja fölött. Ha szólok, menj hátra."
const DONE_GREETING := "[i]Döme elégedetten nézi a beékelődött sziklát és a frissen lerakott deszkákat.[/i]\n\n" \
	+ "Ugye mondtam? Hogy a túloldalon mi vár, azt nem tudom. Azt viszont igen, hogy most már át lehet menni."
const WELL_GREETING := "[i]Döme a törmelékkupac mellett térdel, és a fülét a kőhöz szorítja.[/i]\n\n" \
	+ "Hallod? Fütyül mögötte a szél. Üreg van ott, nem is kicsi. Ha szólsz, gyújtok. Te meg addig menj a létra alá."
const STORIES: Array[Dictionary] = [
	{"id": "who", "text": "Ki vagy te?", "trust": 3,
		"answer": "Puskás Döme. Robbantómester, harminc évig a hegyi ezüstbányában. Mind a tíz ujjam megvan, mind " \
			+ "a két fülem, és a szemöldökömből is maradt valami. Ezt a szakmában úgy hívják: szerencse.\n\n" \
			+ "Mióta a bánya bezárt, Tóbiásnál lakom. Fizetek, néha. Amikor nem, megjavítom a hordóit. Egyszer egy " \
			+ "kicsit túlságosan is megjavítottam."},
	{"id": "collapse", "text": "Hogyan omlott be a bánya?", "trust": 4,
		"answer": "[i]Elkomorodik, a pipájáért nyúl, de nem gyújtja meg.[/i]\n\n" \
			+ "Nem én robbantottam, ha erre gondolsz. Mindenki erre gondol.\n\n" \
			+ "A legmélyebb tárnában kopogást hallottunk a kő túloldaláról. Én mondtam, hogy ne bontsák tovább. Nem " \
			+ "hallgattak rám. Egy héttel később a hegy magától omlott össze, alulról, mintha valami lerántotta " \
			+ "volna. Huszonheten maradtak lent.\n\nAzóta nem mentem be. Eddig."},
	{"id": "bridge", "text": "Ki építette a hidat a szakadék fölött?", "trust": 3,
		"answer": "Én. Vagyis én robbantottam neki helyet, a brigád ácsolta. Azon toltuk át a csilléket a túlsó " \
			+ "tárnákhoz, ahol a legjobb ezüst volt.\n\nAz omlás után a közepe beszakadt. Azóta senki nem járt " \
			+ "odaát. Ami ott van, az tizenkét éve vár valakire."},
]


static func met() -> bool:
	return Progress.npc_quest_state(MET_FLAG) == "done"


## Nincs otthon (a bányában vagy a kút alján dolgozik): a folyosón nincs.
static func away() -> bool:
	return Progress.npc_quest_state(BLAST_QUEST) != ""


## A bányában vár (vagy már ott dolgozik).
static func at_mine() -> bool:
	return away() and not at_well()


## A kút alján vár a törmeléknél (WellCave), amíg fel nem robbantja a járatot.
static func at_well() -> bool:
	return Progress.npc_quest_state(WELL_QUEST) == "ready"


static func well_open() -> bool:
	return Progress.npc_quest_state(WELL_QUEST) == "done"


static func bridge_fixed() -> bool:
	return Progress.npc_quest_state(BLAST_QUEST) == "done"


static func portrait() -> AtlasTexture:
	return SpriteSheet.region(FIGURE)


static func frames() -> SpriteFrames:
	return SpriteSheet.character_frames(FIGURE, true)


## Az első kopogás: felébred (onnantól a folyosón áll az ajtaja előtt).
static func wake() -> void:
	Progress.set_npc_quest(MET_FLAG, "done")


## A beszélgetés köszöntése a hely szerint ("room" = a folyosón, "mine" = a szakadéknál).
static func greeting(place: String) -> String:
	if place == "well":
		return WELL_GREETING
	if place == "mine":
		return DONE_GREETING if bridge_fixed() else MINE_GREETING
	return GREETING


## A beszélgetés opciói: elöl a küldetés lépése (a helyhez illően), utána a történetek. `blast`: a bányában a
## robbantás indítása (a Mine adja; a válasz után zárja a beszélgetést és lejátssza).
static func options(place: String, blast: Callable = Callable()) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	if place == "well":
		if at_well() and blast.is_valid():
			list.append({"id": "well_blast", "text": "Robbants!", "on_choose": blast})
		list.append_array(STORIES)
		return list
	if place == "mine":
		if Progress.npc_quest_state(BLAST_QUEST) == "active" and blast.is_valid():
			list.append({"id": "blast", "text": "Robbants!", "on_choose": blast})
		if bridge_fixed() and Stranger.is_rescued():
			match Progress.npc_quest_state(WELL_QUEST):
				"":
					list.append({"id": "well", "text": "A kút alján is van egy beomlott járat...",
						"on_choose": func() -> String: return _give_well_quest()})
				"active":
					if kills_since(WELL_TARGET, WELL_BASE, WELL_GOAL) >= WELL_GOAL:
						list.append({"id": "well_ready", "text": "Megvannak a tűzhangya-mirigyek.",
							"on_choose": func() -> String: return _finish_well_glands()})
					else:
						list.append({"id": "well_count", "text": "Mennyi tűzhangya kell még?",
							"on_choose": func() -> String: return "Eddig %d mirigy. Még %d tűzhangya." % [
								kills_since(WELL_TARGET, WELL_BASE, WELL_GOAL),
								WELL_GOAL - kills_since(WELL_TARGET, WELL_BASE, WELL_GOAL)]})
		list.append_array(STORIES)
		return list
	match Progress.npc_quest_state(POWDER_QUEST):
		"":
			list.append({"id": "chasm", "text": "Át kellene jutnom a bánya szakadékán.",
				"on_choose": func() -> String: return _give_powder_quest()})
		"active":
			if kills_since(POWDER_TARGET, POWDER_BASE, POWDER_GOAL) >= POWDER_GOAL:
				list.append({"id": "powder_done", "text": "Megvan a puskapor.",
					"on_choose": func() -> String: return _finish_powder()})
			else:
				list.append({"id": "powder", "text": "Mennyi puskapor kell még?",
					"on_choose": func() -> String: return "Eddig %d hordó. Még %d kell. A robbanó goblinok a " \
						% [kills_since(POWDER_TARGET, POWDER_BASE, POWDER_GOAL),
							POWDER_GOAL - kills_since(POWDER_TARGET, POWDER_BASE, POWDER_GOAL)] \
						+ "3. emelet alatt kezdenek szaladgálni. Leszedd őket, mielőtt odaérnek, különben nincs " \
						+ "mit hoznod. Meg téged sem."})
		"done":
			match Progress.npc_quest_state(FUSE_QUEST):
				"":
					list.append({"id": "more", "text": "Mi kell még?",
						"on_choose": func() -> String: return _give_fuse_quest()})
				"active":
					if kills_since(FUSE_TARGET, FUSE_BASE, FUSE_GOAL) >= FUSE_GOAL:
						list.append({"id": "fuse_done", "text": "Hoztam kanócot.",
							"on_choose": func() -> String: return _finish_fuse()})
					else:
						list.append({"id": "fuse", "text": "Mennyi kanóc kell még?",
							"on_choose": func() -> String: return "Eddig %d. Még %d kalózpuskás." % [
								kills_since(FUSE_TARGET, FUSE_BASE, FUSE_GOAL),
								FUSE_GOAL - kills_since(FUSE_TARGET, FUSE_BASE, FUSE_GOAL)]})
				"done":
					if Progress.npc_quest_state(BLAST_QUEST) == "":
						list.append({"id": "go", "text": "Mehetünk a bányába?",
							"on_choose": func() -> String: return _start_blast_quest()})
	list.append_array(STORIES)
	return list


## A küldetés elfogadása óta megölt szörnyek ebből a fajtából (legfeljebb a cél).
static func kills_since(target: String, base_flag: String, goal: int) -> int:
	var base := int(Progress.npc_quest_state(base_flag))
	return clampi(int(Progress.kills.get(target, 0)) - base, 0, goal)


## A J könyv "folyamatban" szövege (az ölős küldetéseknél a haladással).
static func doing_text(id: String, fallback: String) -> String:
	if id == POWDER_QUEST:
		return "%s: %d / %d" % [fallback, kills_since(POWDER_TARGET, POWDER_BASE, POWDER_GOAL), POWDER_GOAL]
	if id == FUSE_QUEST:
		return "%s: %d / %d" % [fallback, kills_since(FUSE_TARGET, FUSE_BASE, FUSE_GOAL), FUSE_GOAL]
	if id == WELL_QUEST:
		if at_well():
			return "Döme a kút alján vár, a törmeléknél"
		return "%s: %d / %d" % [fallback, kills_since(WELL_TARGET, WELL_BASE, WELL_GOAL), WELL_GOAL]
	return fallback


static func _give_well_quest() -> String:
	Progress.set_npc_quest(WELL_QUEST, "active")
	Progress.set_npc_quest(WELL_BASE, str(int(Progress.kills.get(WELL_TARGET, 0))))
	Progress.mark_asked(ID, "well")
	Audio.play("ui_open")
	return "[i]Döme felkapja a fejét.[/i]\n\n" \
		+ "A kút alatt? Ahol az a varázsló fiú majdnem éhen halt? Hallottam róla, Tóbiás mindenkinek elmesélte. " \
		+ "Ha hideg szél fúj a törmelék mögül, akkor ott üreg van, nem tömör kő. Azt meg lehet nyitni.\n\n" \
		+ "Csak az a baj, hogy lent csöpög a víz, a nedves kőben a kanóc kialszik. Kell valami, ami vizesen is ég. " \
		+ "A tűzhangyák potrohában van egy mirigy: ha szétnyomod, magától lángra kap. Hozz [b]%d tűzhangyától[/b] " \
		% WELL_GOAL + "mirigyet, aztán szólj. Itt leszek."


static func _finish_well_glands() -> String:
	Progress.set_npc_quest(WELL_QUEST, "ready")
	Progress.mark_asked(ID, "well_ready")
	Progress.change_trust(ID, 10)
	Audio.play("ui_open")
	return "[i]Döme óvatosan, két ujjal veszi el a parázsló mirigyeket, és egy agyagbögrébe teszi őket.[/i]\n\n" \
		+ "Na, ezek még a víz alatt is égnének. Megyek a kúthoz. Ne félj, a létrát nem robbantom fel. Valószínűleg.\n\n" \
		+ "[color=#7a4a10](Döme a kút aljára ment: a beomlott járatnál vár.)[/color]"


static func _give_powder_quest() -> String:
	Progress.set_npc_quest(POWDER_QUEST, "active")
	Progress.set_npc_quest(POWDER_BASE, str(int(Progress.kills.get(POWDER_TARGET, 0))))
	Progress.mark_asked(ID, "chasm")
	Audio.play("ui_open")
	return "[i]Döme felhúzza azt, ami a szemöldökéből maradt.[/i]\n\n" \
		+ "A szakadékon? Hm. A túlsó falon, a híd csonkja fölött van egy sziklaorr. Ha jó helyen robbantom meg, " \
		+ "beleesik a szakadékba, és pont beékelődik oda, ahol a híd leszakadt. Rá egy pár deszka, és kész a híd.\n\n" \
		+ "Csakhogy nincs puskaporom. Tóbiás elkobozta, miután a hordóit... mindegy. A Mélységben a robbanó " \
		+ "goblinok hordónyi port cipelnek a hátukon. Ha leszeded őket, mielőtt felrobbannak, a hordójuk megmarad. " \
		+ "Hozz port [b]%d robbanó goblintól[/b].\n\n" % POWDER_GOAL \
		+ "[color=#7a4a10](Új fül a küldetések könyvében: Robbantómester  [J])[/color]"


static func _finish_powder() -> String:
	Progress.set_npc_quest(POWDER_QUEST, "done")
	Progress.mark_asked(ID, "powder_done")
	Progress.add_camp_gold(POWDER_GOLD)
	Progress.change_trust(ID, 15)
	Audio.play("coin")
	return "[i]Döme beleszagol a hordókba, és elégedetten hümmög.[/i]\n\n" \
		+ "Goblinpor. Durva, büdös, de erős. Pont jó. A maradékot megveszem tőled, kár lenne, ha Tóbiás megint " \
		+ "elkobozná. [color=#7a4a10](+%d tábori arany)[/color]" % POWDER_GOLD


static func _give_fuse_quest() -> String:
	Progress.set_npc_quest(FUSE_QUEST, "active")
	Progress.set_npc_quest(FUSE_BASE, str(int(Progress.kills.get(FUSE_TARGET, 0))))
	Progress.mark_asked(ID, "more")
	Audio.play("ui_open")
	return "Kanóc. A régi kanócaim a bányában beáztak, és a nedves kanóc vagy meg sem gyullad, vagy túl gyorsan " \
		+ "ég. Egyik se jó, ha te állsz mellette.\n\n" \
		+ "A kalózpuskások lassú kanóccal gyújtják a puskájukat: kátrányos, száraz, egyenletesen ég. Szedj össze " \
		+ "[b]%d kalózpuskás[/b] kanócát." % FUSE_GOAL


static func _finish_fuse() -> String:
	Progress.set_npc_quest(FUSE_QUEST, "done")
	Progress.mark_asked(ID, "fuse_done")
	Progress.add_camp_gold(FUSE_GOLD)
	Progress.change_trust(ID, 15)
	Audio.play("coin")
	return "[i]Döme meggyújtja az egyik kanóc végét, és a homokórájával méri, ahogy parázslik.[/i]\n\n" \
		+ "Egyenletes. Tökéletes. Most már csak az kell, hogy te is ott legyél, és lásd. Ilyet nem minden nap lát " \
		+ "az ember. Kétszer meg végképp nem. [color=#7a4a10](+%d tábori arany)[/color]" % FUSE_GOLD


static func _start_blast_quest() -> String:
	Progress.set_npc_quest(BLAST_QUEST, "active")
	Progress.mark_asked(ID, "go")
	Audio.play("ui_open")
	return "[i]Döme a hátára veti a szerszámos zsákját, a hóna alá csapja a hordót.[/i]\n\n" \
		+ "Én megyek előre. Te gyere utánam: a bányában, a szakadéknál várlak. És ne állj túl közel, amikor " \
		+ "szólok.\n\n[color=#7a4a10](Döme a bányába ment: a szakadéknál vár.)[/color]"
