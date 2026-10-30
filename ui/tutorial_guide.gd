class_name TutorialGuide
extends CanvasLayer
## A gyakorló pálya (tutorial) vezetője. A pálya hét szobája (Dungeon.TUTORIAL_CELLS) egy-egy leckéhez tartozik:
## kezdőszoba (mozgás, a képernyő, térkép, szünet), harc + láda (harc, szintlépés, felszerelés, karakterlap),
## csapdák + a karakter képessége, bolt + tárgylift (vásárlás, bájital), gyakorló üllő (kovács), különleges
## szörnyek, végül egy főellenség (jutalom, pihenő, lépcső). A lépcső a TÁBORBA visz: ott a bemutató végigvezet a
## tábor dolgain (tábori arany, kiképzősátor, láda, halál és biztonság, kovács, Szörnyek könyve, küldetések,
## vándorárus, lakók, út a városba, leszállás), a végén egy rövid "kész" ablak (TutorialManual.FINISH_TEXT).
## A Dungeon (setup) és a tábor (setup_camp) hozza létre, ha GameState.tutorial igaz. A gyakorlás alatt semmi nem
## mentődik (Progress.save_game nem ír), a tábor a valódi, de a változásai a végén eldobódnak.
##
## Hülyebiztos:
##   - fent mindig ott a feladat; ha kész, magától továbblép (a magyarázó lépéseknél Enterrel);
##   - a következő szoba ajtaja zárva marad, amíg a mostani leckék nincsenek kész (Room.set_gate), így nem lehet
##     előreszaladni és összekeverni a sorrendet;
##   - a sárga nyíl mutatja, hova kell menni, a HUD érintett részei villogó keretet kapnak;
##   - amit előre megcsinálsz, azt megjegyzi (_seen), így a lépés később azonnal teljesül;
##   - a játékos nem halhat meg (Health.cannot_die), aranyat és porokat kap, ahol kell;
##   - ha mégis elakadna, a H gomb átugorja a lépést (egy idő után ki is írja).

const MAIN_MENU := "res://ui/main_menu.tscn"
const CAMP_SCENE := "res://world/camp.tscn"
## A tábori bemutatón ennyi tábori aranyat kapsz (gyakorlásra; nem mentődik).
const CAMP_GOLD := 300
## Ilyen közel kell menni egy tábori helyhez.
const NEAR := 72.0
const XP_ORB := preload("res://pickups/xp_orb.tscn")
const RETURN_PORTAL := preload("res://rooms/obstacles/return_portal.gd")
const ITEM_LIFT := preload("res://rooms/obstacles/item_lift.gd")
const SHOP_SCENE := "res://rooms/obstacles/shop.tscn"
const PANEL_WIDTH := 780.0
const DONE_COLOR := Color(0.24, 0.5, 0.2)
## Ennyi másodperc után kiírja, hogy a H-val át lehet ugrani a lépést.
const SKIP_HINT_AFTER := 25.0
## A bolt előtt legalább ennyi aranyad lesz (vásárlás + bájital).
const SHOP_GOLD := 260
## A szobák sorszámai (lásd Dungeon.TUTORIAL_ROOMS).
const ROOM_START := 0
const ROOM_FIGHT := 1
const ROOM_SKILL := 2
const ROOM_SHOP := 3
const ROOM_ANVIL := 4
const ROOM_MONSTERS := 5
const ROOM_BOSS := 6

var _scene: Node
var _player: Node2D
var _rooms: Array = []
var _steps: Array[Dictionary] = []
var _index := 0
var _advancing := false
var _step_time := 0.0
## Magyarázó lépésnél: megnyomta-e az Entert.
var _confirmed := false
## Ami már megtörtént (bármikor): mozgás, támadás, térkép, láda, karakterlap, bolt, lift...
var _seen := {}
var _start_position := Vector2.ZERO
var _was_in_shop := false
var _bag_count_at_shop := 0
var _potions_at_shop := 0
var _last_potions := 0
var _potion_step_started := false
## Melyik szobáig lehet bemenni (a későbbiek ajtaja zárva); szoba -> zárva van-e most.
var _gate := -1
var _gated := {}
## "dungeon": a gyakorló pálya; "camp": a tábori bemutató.
var _mode := "dungeon"
## A tábori fejlesztések szintjeinek összege a bemutató elején (ebből látszik, hogy vettél-e).
var _upgrades_at_start := 0
## Ennyi tábori aranyat kaptál a bemutatóra (legalább CAMP_GOLD, és legalább a legolcsóbb fejlesztés ára).
var _camp_gift := 0
## Vége: a pálya lépcsője után a tábor felé tartunk, vagy a tábor után a "kész" ablak látszik.
var _done := false

var _panel: PanelContainer
var _counter: Label
var _title: Label
var _text: RichTextLabel
var _footer: Label
## Nyitott ablak (pl. felszerelés, kovács) idején a képernyő alján, az ablakok fölött: a teendő röviden ("short").
var _mini_layer: CanvasLayer
var _mini: PanelContainer
var _mini_text: RichTextLabel
var _highlight: HudHighlight
var _arrow: GuideArrow
var _finish_layer: Control


func setup(dungeon: Node, rooms: Array) -> void:
	_scene = dungeon
	_rooms = rooms
	_player = dungeon.get_node("Entities/Player")
	_start_position = _player.global_position
	# Gyakorlás: semmi nem kerül az eredmények közé, és a tábori arany sem nő.
	GameState.run_recorded = true
	GameState.gold_rescued = true
	_arrow = GuideArrow.new()
	_arrow.player = _player
	dungeon.get_node("Entities").add_child(_arrow)
	var smith := dungeon.get_node_or_null("SmithPanel")
	if smith != null:
		smith.connect("upgraded", func(_item: Dictionary) -> void: _seen["upgraded"] = true)
		smith.connect("dismantled", func(_item: Dictionary) -> void: _seen["dismantled"] = true)
	_build_steps()
	_build_ui()
	_show_step()


## A tábori bemutató (a gyakorló pálya lépcsője után a tábor hívja).
func setup_camp(camp: Node) -> void:
	_mode = "camp"
	_scene = camp
	_player = camp.get_node("Entities/Player")
	_start_position = _player.global_position
	GameState.run_recorded = true
	GameState.gold_rescued = true
	var cheapest := 999999
	for id: String in Progress.UPGRADES:
		var cost := Progress.next_cost(id)
		if cost > 0:
			cheapest = mini(cheapest, cost)
	_camp_gift = maxi(CAMP_GOLD, cheapest if cheapest < 999999 else 0)
	Progress.camp_gold += _camp_gift
	_upgrades_at_start = _upgrade_levels()
	_arrow = GuideArrow.new()
	_arrow.player = _player
	camp.get_node("Entities").add_child(_arrow)
	_build_camp_steps()
	_build_ui()
	_show_step()


func _room(i: int) -> Room:
	return _rooms[i]


func _cleared(i: int) -> bool:
	return _room(i).visited and _room(i).is_cleared()


func _room_center(i: int) -> Vector2:
	return Room.tile_center(_room(i).anchor)


## Egy feladat-lépés: magától továbblép, ha `done` igazat ad.
## extra: "room" (eddig a szobáig lehet bemenni), "target" (Callable -> Vector2, ide mutat a nyíl),
## "highlight" (a Dungeonon belüli útvonalak, ezek a HUD-elemek villognak), "start" (előkészítés).
func _task(title: String, text: String, done: Callable, extra := {}) -> Dictionary:
	var step := {"title": title, "text": text, "done": done}
	step.merge(extra)
	return step


## Egy magyarázó lépés: Enterrel lehet továbblépni.
func _info(title: String, text: String, extra := {}) -> Dictionary:
	var step := _task(title, text, func() -> bool: return _confirmed, extra)
	step["info"] = true
	return step


func _build_steps() -> void:
	var start := {"room": ROOM_START}
	var fight := {"room": ROOM_FIGHT}
	var skill := {"room": ROOM_SKILL}
	var shop := {"room": ROOM_SHOP}
	var anvil := {"room": ROOM_ANVIL}
	_steps = [
		_info("Üdv a gyakorló pályán!", "Ez egy biztonságos gyakorló pálya: itt [b]nem halhatsz meg[/b], és semmi nem "
			+ "mentődik belőle. Lépésről lépésre végigvezetlek mindenen, amit a játékban tudnod kell.\n"
			+ "A feladat mindig itt fent látszik, és ha megcsináltad, magától továbblépünk. A [color=#b07a10]sárga "
			+ "nyíl[/color] mutatja, merre menj. Ha valahol elakadnál, a [b]H[/b] gombbal átugorhatod a lépést.", start),
		_task("Mozgás", "Mozogj a [b]W A S D[/b] gombokkal (vagy a nyilakkal). Sétálj egy kicsit a szobában!",
			func() -> bool: return _seen.has("moved"), start),
		_info("Az életed", "Bal fent a [b]piros csík az életed[/b]. Ha elfogy, véget ér a futás (itt nem fogy el). "
			+ "Mellette a [b]HP bájitalaid[/b] száma: a [b]Q[/b] gombbal iszol egyet (később kipróbáljuk). Alatta a "
			+ "statjaid rövid listája.", start.merged({"highlight": ["HUD/HealthBar", "potion", "HUD/StatsLabel"]})),
		_info("Emelet, arany, térkép", "Jobb fent látod, hányadik [b]emeleten[/b] jársz, mennyi [b]aranyad[/b] van, "
			+ "alatta pedig a [b]kis térképet[/b]. Lent az [b]XP-csík[/b]: a legyőzött szörnyekből tapasztalat jár, "
			+ "és ha betelik, szintet lépsz.", start.merged({"highlight": ["HUD/DepthLabel", "HUD/Gold", "HUD/Minimap",
				"HUD/XpBar"]})),
		_task("Nagy térkép", "Nyomd meg az [b]M[/b] gombot a nagy térképhez. A [color=#b0302a]piros[/color] szobákban "
			+ "még szörnyek vannak, a [color=#3c8a32]zöldek[/color] tiszták, a [color=#c06010]narancs[/color] a bolt, a "
			+ "háromszög a lépcső. Bezárni újra az M-mel, az Esc-kel vagy a jobb felső [b]X[/b]-szel tudod.",
			func() -> bool: return _seen.has("map_closed"),
			start.merged({"window": "Minimap", "short": "Ez a nagy térkép. Bezárás: M, Esc vagy a jobb felső X."})),
		_task("Szünet", "Az [b]Esc[/b] gomb megállítja a játékot (közös játékban nem áll meg semmi). Itt vannak a "
			+ "[b]beállítások[/b] (hang, teljes képernyő), és innen [b]adhatod fel[/b] a futást is. Nyomd meg az Esc-et, "
			+ "nézz körül, aztán Folytatás (vagy újra Esc).",
			func() -> bool: return _seen.has("pause_closed"),
			start.merged({"window": "PauseMenu", "short": "Ez a szünet menü. Folytatás gomb (vagy Esc), és mehetünk tovább."})),
		_task("Harc", "Menj át a jobb oldali szobába! Amint belépsz, [b]az ajtók bezárulnak[/b], és csak akkor "
			+ "nyílnak ki, ha minden szörnyet legyőztél.\n" + _attack_text(),
			func() -> bool: return _cleared(ROOM_FIGHT), fight.merged({"target": _room_center.bind(ROOM_FIGHT)})),
		_info("Számok a harcban", "A szörnyek fölött a sebzésed látszik. A [color=#c05010]narancs, felkiáltójeles[/color] "
			+ "szám [b]kritikus találat[/b]. [b]Mellé![/b]: nem találtál (ezt a Találati esély stat dönti el). "
			+ "[b]Kikerülte![/b]: a szörny kitért. A mellément vagy kikerült nyíl és varázslat továbbrepül.\n"
			+ "Ha téged találnak el, egy pillanatig villogsz: ilyenkor nem sebezhetnek meg újra.", fight),
		_task("Szintlépés", "Szedd fel a zöld [b]XP-gömböket[/b] (maguktól feléd repülnek). Szintlépéskor minden statod "
			+ "nő egy kicsit, és [b]3 kártya[/b] közül választasz egy fejlesztést (1 / 2 / 3, vagy kattintás). Aranyért "
			+ "[b]újradobhatod[/b] a kártyákat (R). Az arany keretű [b]legendás[/b] kártya ritka és nagyon erős.",
			func() -> bool: return _player.get_node("Experience").level >= 2 and not _scene.get_node("LevelUp").visible,
			fight.merged({"start": _spawn_xp})),
		_task("Láda", "A kitisztított szobában [b]láda[/b] jelent meg. Menj oda, és érintsd meg: aranyat ad, néha "
			+ "tárgyat is.", func() -> bool: return _seen.has("chest"),
			fight.merged({"target": _chest_target})),
		_task("Felszerelés", "Kaptál egy [color=#1f52b8]kék (ritka) sisakot[/color]. Nyisd meg a felszerelést az "
			+ "[b]I[/b] gombbal, és húzd a sisakot a sisak-helyére (vagy kattints rá a [b]jobb egérgombbal[/b]). "
			+ "Ha az egeret egy tárgy fölé viszed, látod a statjait, és hogy mennyivel jobb vagy rosszabb a mostaninál.",
			func() -> bool: return _helmet_equipped(), fight.merged({"start": _give_helmet,
				"window": "Inventory", "short": "Húzd a kék sisakot (Táska) a sisak-helyére, vagy kattints rá a jobb egérgombbal."})),
		_info("Ritkaságok", "A tárgy színe a ritkasága: [color=#5c544c]átlagos[/color], [color=#1f52b8]ritka[/color], "
			+ "[color=#7a2eae]epikus[/color], [color=#b85c00]legendás[/color] és [color=#b8120c]mítikus[/color]. Minél "
			+ "ritkább, annál erősebb. A fegyvereknek fajtája is van (kard, tőr, lándzsa, balta, buzogány, íjak, "
			+ "számszeríj), és nem minden karakter foghat mindent: a tárgy leírása megmondja. A táskádba 24 tárgy fér.",
			fight.merged({"window": "Inventory", "short": "A tárgy színe a ritkasága: szürke, kék, lila, narancs, piros (a legjobb)."})),
		_task("Karakterlap", "Csukd be a felszerelést (I, Esc vagy X), és nyomd meg a [b]Tab[/b] gombot: itt az "
			+ "[b]összes statod[/b] részletesen, a fegyvered sebzésképlete és a futásod adatai. A stat-oldalakat a "
			+ "◄ ► gombokkal (vagy A / D) lapozod. Nézd meg, aztán csukd be (Tab).",
			func() -> bool: return _seen.has("stats_closed"), fight.merged({"window": "StatsScreen", "short": "Ha más ablak van nyitva, előbb azt "
				+ "csukd be, aztán Tab: nézd meg a statjaidat, és csukd be (Tab vagy X)."})),
		_task("Csapdák", "Menj a következő szobába! A padlón [b]tüskecsapdák[/b] vannak: időnként kiugranak és "
			+ "megsebeznek. Figyeld a ritmusukat, és akkor lépj át rajtuk, amikor lent vannak.",
			func() -> bool: return _room(ROOM_SKILL).visited, skill.merged({"target": _room_center.bind(ROOM_SKILL)})),
	]
	_steps.append(_skill_step(skill))
	_steps.append_array([
		_task("Győzd le őket!", "Győzd le a szoba szörnyeit, hogy kinyíljanak az ajtók.",
			func() -> bool: return _cleared(ROOM_SKILL), skill),
		_task("A bolt", "A következő szobában, a felső falban egy [b]bolt[/b] ajtaja van (a térképen narancs). "
			+ "Egyszerűen sétálj neki, és bemész. Adtam egy kis aranyat a vásárláshoz.",
			func() -> bool: return _seen.has("shop_in"),
			shop.merged({"start": _ensure_gold.bind(SHOP_GOLD), "target": _shop_target})),
		_task("Vásárlás", "Állj egy tárgy elé: látod a leírását és az árát. Ha van elég aranyad, az [b]E[/b] gombbal "
			+ "megveszed. Vegyél valamit!", func() -> bool: return _seen.has("bought"), shop),
		_task("Bájital vétele", "Menj a pulthoz, a boltos elé: ott az [b]F[/b] gombbal [b]HP bájitalt[/b] veszel "
			+ "(60 arany, boltonként legfeljebb 2). Vegyél egyet!", func() -> bool: return _seen.has("potion_bought"),
			shop.merged({"start": _ensure_gold.bind(ShopInterior.POTION_PRICE)})),
		_info("Eladás, új áru", "A pultnál az [b]E[/b] gombbal [b]el is adhatsz[/b]: megnyílik a táskád, és jobb "
			+ "klikkel (vagy kattintással) adod el a tárgyat. A szoba közepén lévő [b]karral[/b] aranyért új árut kérhetsz. "
			+ "Mélyebben a bolt egyre jobb tárgyakat árul.", shop),
		_task("Ki a boltból", "Gyere ki a bolt [b]alsó ajtaján[/b].", func() -> bool: return _seen.has("shop_out"), shop),
		_task("HP bájital", "Megsérültél! Nyomd meg a [b]Q[/b] gombot: a bájital az [b]elvesztett életed felét[/b] "
			+ "tölti vissza. Minden főellenség után is kapsz egyet.", func() -> bool: return _seen.has("potion"),
			shop.merged({"start": _start_potion_step, "highlight": ["HUD/HealthBar", "potion"]})),
		_task("Tárgylift", "A bolt mellett, a falban a [b]tárgylift[/b]: emeletenként [b]egy tárgyat[/b] felküldhetsz "
			+ "vele a táborba, a tábori ládába. Ami a ládában van, az akkor is megmarad, ha meghalsz! Menj oda, és nyomd "
			+ "meg az [b]E[/b]-t. (Gyakorláskor nem küld fel semmit.)", func() -> bool: return _seen.has("lift"),
			shop.merged({"target": _lift_target})),
		_task("Gyakorló üllő", "A következő szobában egy [b]üllő[/b] áll. Az igazi játékban ugyanez a [b]táborban, a "
			+ "kovácsnál[/b] van. Állj elé, és nyomd meg az [b]E[/b] gombot.", func() -> bool: return _seen.has("smith"),
			anvil.merged({"start": _prepare_anvil, "target": _anvil_target})),
		_task("Szétszedés", "Fent a [b]porok[/b]: minden ritkaságnak saját pora van. Húzd a kapott [b]ezüstgyűrűt[/b] "
			+ "(vagy kattints rá) a kör közepére, és nyomd meg a [b]Szétszedés[/b] gombot: a tárgy elvész, és a "
			+ "ritkaságának porát kapod (1-et, néha 2-t). Ami rajtad van, azt nem lehet beolvasztani.",
			func() -> bool: return _seen.has("dismantled"), anvil.merged({"start": _prepare_anvil,
				"window": "SmithPanel", "short": "Húzd az ezüstgyűrűt (Táska) a kör közepére, majd nyomd meg: Szétszedés."})),
		_task("Fejlesztés", "Most tedd a kör közepére a [b]sisakodat[/b] (a Felszerelésed közül), és nyomd meg a "
			+ "[b]Fejlesztés[/b] gombot. Ehhez [b]4 por[/b] kell a [b]következő[/b] ritkaságból: ezt most odaadtam. Az "
			+ "igazi játékban 65% eséllyel sikerül (ha nem, a por elvész, a tárgy marad); itt biztosan sikerül.",
			func() -> bool: return _seen.has("upgraded"), anvil.merged({"start": _prepare_upgrade,
				"window": "SmithPanel", "short": "Tedd a sisakodat (Felszerelésed) a kör közepére, majd nyomd meg: Fejlesztés."})),
		_task("Bezárás", "Csukd be az ablakot a jobb felső [b]X[/b]-szel (vagy Esc, vagy E).",
			func() -> bool: return not _scene.get_node("SmithPanel").visible,
			anvil.merged({"window": "SmithPanel", "short": "Csukd be az ablakot: a jobb felső X (vagy Esc)."})),
		_task("Különleges szörnyek", "A következő szobában más szörnyek várnak: az [b]íjász messziről lő[/b] (térj ki a "
			+ "nyilai elől), az [b]imp teleportál[/b]. Sok szörnynek van képessége: rohamoz, gyógyít, idéz, mérgez, "
			+ "lassít, felrobban... Mielőtt használja, [b]felvillan[/b]. A táborban a [b]Szörnyek könyve[/b] mindent "
			+ "leír róluk, amit már legyőztél.", func() -> bool: return _cleared(ROOM_MONSTERS),
			{"room": ROOM_MONSTERS, "target": _room_center.bind(ROOM_MONSTERS)}),
		_task("Főellenség", "Minden [b]3. emeleten főellenség[/b] vár egy nagy teremben. A támadásai előtt "
			+ "[b]színesen felvillan[/b]: ilyenkor lépj el az útjából. Fél élete alatt feldühödik. Az életét fent "
			+ "látod. Menj be, és győzd le!", func() -> bool: return _cleared(ROOM_BOSS),
			{"room": ROOM_BOSS, "target": _room_center.bind(ROOM_BOSS)}),
		_info("Jutalom", "A főellenség után jár egy [b]HP bájital[/b], sok arany és egy jó tárgy: szedd fel őket! "
			+ "Kinyílt a rács a terem fülkéjében (ott a lépcső), és megjelent egy [b]kék portál[/b].",
			{"room": ROOM_BOSS}),
		_task("Pihenő", "A [b]kék portálon[/b] (E) [b]kimehetsz pihenni a táborba[/b]: a táskádból egy tárgyat a tábori "
			+ "ládába küldhetsz, kiviheted a pénzed, és a táborban a vándorárus is árul. A felszerelésed és a szinted "
			+ "megmarad, a portál ugyanide hoz vissza. Nézd meg (E), aztán: [b]Maradok[/b].",
			func() -> bool: return _seen.has("portal_closed"), {"room": ROOM_BOSS, "target": _portal_target,
				"window": "BossReturnPanel", "short": "Ez a pihenő ablaka. Nézd meg, aztán nyomd meg: Maradok."}),
		_task("Lépcső", "A [b]lépcső[/b] a következő, nehezebb emeletre visz: lent erősebb szörnyek és jobb tárgyak "
			+ "várnak. Most viszont a [b]táborba[/b] visz, hogy azt is megmutassam. Lépj rá!", func() -> bool: return false,
			{"room": ROOM_BOSS, "target": _stairs_target}),
	])


## A tábori bemutató lépései (a valódi táborban; semmi nem mentődik).
func _build_camp_steps() -> void:
	_steps = [
		_info("A tábor", "Megérkeztél a [b]táborba[/b]! Ez a valódi táborod: innen indul minden futás, és ide térsz "
			+ "vissza. Gyakorlás közben itt sem mentődik semmi, nyugodtan próbálj ki bármit.\nJobb fent a [b]tábori "
			+ "aranyad[/b]: a futásokból hazahozott pénz. Most kaptál %d-at gyakorlásra." % _camp_gift,
			{"highlight": ["camp_gold"]}),
		_task("Kiképzősátor", "Menj a [b]kiképzősátorhoz[/b] (a sárga nyíl mutatja), és nyomd meg az [b]E[/b] gombot.",
			func() -> bool: return _seen.has("upgrades"), {"target": _camp_spot.bind("_training_tent_position")}),
		_task("Fejlesztés vétele", "Itt [b]tábori aranyból[/b] veszel tartós fejlesztéseket (sebzés, élet, védelem, "
			+ "sebesség...): minden karakterre és minden futásra érvényesek, és sosem vesznek el. [b]Vegyél egyet[/b], "
			+ "aztán csukd be (X, Esc vagy E).", func() -> bool: return _upgrade_levels() > _upgrades_at_start \
				and not _scene.get_node("CampUpgrades").visible,
			{"window": "CampUpgrades", "short": "Kattints egy fejlesztés jobb oldali árgombjára (pl. 100), hogy megvedd; aztán csukd be (X)."}),
		_task("Tábori láda", "Menj a [b]tábori ládához[/b], és nyomd meg az [b]E[/b]-t. Ide érkeznek a tárgylifttel és a "
			+ "pihenőnél felküldött tárgyak. Tettem bele egy tárgyat: [b]kattints rá[/b], hogy a táskádba kerüljön. Amit "
			+ "a táskádban és magadon viszel, azzal szállsz le a kazamatába.", func() -> bool: return _stash_item_taken(),
			{"start": _fill_stash, "target": _camp_spot.bind("_stash_position"),
				"window": "StashPanel", "short": "Kattints a ládában a Futárcsizmára (balra fent): átkerül a táskádba."}),
		_info("Halál és biztonság", "[b]Fontos![/b] Ha a kazamatában meghalsz, [b]minden elvész, ami nálad van[/b] (a "
			+ "szinted és a tárgyaid is), és a pénzednek csak a 20%-a jut haza. Ami a [b]tábori ládában[/b] van, az "
			+ "biztonságban marad, ahogy a tábori arany és a fejlesztések is. Ezért a legjobb zsákmányt küldd fel "
			+ "(tárgylift, pihenő)!", {"short": "Halálkor elveszted, ami nálad van; ami a ládában van, megmarad."}),
		_task("Kovács", "Itt a [b]kovács[/b]: ugyanaz, amit a gyakorló üllőnél kipróbáltál, csak itt a porok megmaradnak. "
			+ "Beszélj vele ([b]E[/b]), és válaszd az első opciót ([b]1[/b]): megnyílik a műhely. Nézd meg, aztán csukd be.", func() -> bool: return _seen.has("smith_closed"),
			{"target": _camp_spot.bind("_smith_position"), "window": "SmithPanel", "short": "E, aztán 1: a kovács műhelye. Nézd meg, aztán csukd be (X)."}),
		_task("Szörnyek könyve", "Ez a [b]Szörnyek könyve[/b]: minden szörny leírása és képességei, amelyiket már "
			+ "legyőzted. Nyisd meg ([b]E[/b]), lapozz bele, aztán csukd be.",
			func() -> bool: return _seen.has("bestiary_closed"), {"target": _camp_spot.bind("_bestiary_position"),
				"window": "BestiaryBook", "short": "Lapozz bele (A / D), aztán csukd be (X)."}),
		_task("Küldetések", "Nyomd meg a [b]J[/b] gombot: a [b]küldetések könyve[/b] mutatja a feladataidat és a "
			+ "haladásukat (pl. győzz le ennyi szörnyet, juss le valahány emeletre). A kész küldetések jutalmát a városi "
			+ "[b]kocsmárosnál[/b] veszed át. Utána csukd be (J vagy X).",
			func() -> bool: return _seen.has("quests_closed"),
			{"window": "QuestBook", "short": "Itt vannak a küldetéseid és a haladásuk. Csukd be (J vagy X)."}),
		_task("Vándorárus", "Menj oda a [b]vándorároshoz[/b]. Ő akkor árul, amikor egy főellenség után kijössz "
			+ "[b]pihenni[/b]: akkor itt költheted el a futás pénzét, aztán a kék portálon visszamész.",
			func() -> bool: return _near(_camp_spot("_npc_position")), {"target": _camp_spot.bind("_npc_position")}),
		_info("A lakók", "A táborban és a környéken [b]lakók[/b] élnek. Ha közel mész hozzájuk, és megjelenik az [b]E[/b] "
			+ "felirat, beszélgethetsz velük. Feladatokat adnak, és aki megbízik benned, az akár [b]játszható "
			+ "karakterként[/b] is csatlakozhat hozzád. Hogy kik ők, azt magadnak kell kiderítened!",
			{"target": _camp_spot.bind("_veteran_position")}),
		_task("Út a városba", "Keletre vezet az út a [b]városba[/b]: a [b]kocsmában[/b] választhatsz karaktert (ott "
			+ "várnak az újak is), a kocsmárosnál pedig a küldetések jutalmát veszed át. Menj el az út elejéig!",
			func() -> bool: return _near(_road_target(), 110.0), {"target": _road_target}),
		_task("Leszállás", "Innen indul minden futás: a [b]lépcsőnél[/b] nyomd meg az [b]E[/b]-t, és lemész a "
			+ "kazamatába. Menj oda, és nyomd meg az E-t: ezzel vége a gyakorlásnak!", func() -> bool: return false,
			{"target": _camp_spot.bind("_stairs_position")}),
	]


func _camp_spot(property: String) -> Vector2:
	var spot: Variant = _scene.get(property)
	return spot if spot is Vector2 else Vector2.INF


func _road_target() -> Vector2:
	var constants: Dictionary = _scene.get_script().get_script_constant_map()
	var size: Vector2i = constants["SIZE"]
	var tile := Vector2i(size.x - 3, int(constants["ROAD_ROW"]))
	return (Vector2(tile) + Vector2(0.5, 0.5)) * Room.TILE


func _near(spot: Vector2, distance := NEAR) -> bool:
	return spot != Vector2.INF and _player.global_position.distance_to(spot) < distance


func _upgrade_levels() -> int:
	var total := 0
	for id: String in Progress.upgrades:
		total += int(Progress.upgrades[id])
	return total


## A tábori ládába egy próba-tárgy (csak a gyakorlásra; nem mentődik).
func _fill_stash() -> void:
	for item: Variant in Progress.stash:
		if item is Dictionary and item.get("tutorial", "") == "stash":
			return
	var boots := Items.create("boots_courier")
	boots["tutorial"] = "stash"
	Progress.stash.insert(0, boots)
	var panel := _scene.get_node_or_null("StashPanel")
	if panel != null and panel.visible:
		panel.call("_refresh")


func _stash_item_taken() -> bool:
	var inventory := _inventory()
	for item: Variant in inventory.bag + inventory.equipment.values():
		if item is Dictionary and item.get("tutorial", "") == "stash":
			return true
	return false


## A támadás leírása a karaktertől függően.
func _attack_text() -> String:
	match Progress.character:
		"archer":
			return "Kattints a [b]bal egérgombbal[/b]: az íjászod nyilat lő az egér felé (egyszerre kettőt). Nyomva " \
				+ "tartva folyamatosan lő."
		"wizard":
			return "Kattints a [b]bal egérgombbal[/b]: a pálcád a kiválasztott varázslatot lövi az egér felé. Nyomva " \
				+ "tartva folyamatosan varázsol."
		"gravedigger":
			return "Vendel ásója [b]magától üt[/b], ha egy szörny túl közel ér. A [b]bal egérgombbal csontvázakat " \
				+ "idézel[/b], akik harcolnak érted."
		"thief":
			return "Kattints a [b]bal egérgombbal[/b]: a tőröd az egér irányába döf. A tőr gyors, és gyakran kritikus."
	return "Kattints a [b]bal egérgombbal[/b]: a fegyvered az egér irányába üt. Nyomva tartva folyamatosan támadsz. " \
		+ "A Hatótáv stat azt adja meg, milyen messzire ér el."


## A karakter saját képessége (a csapdás szobában próbálhatod ki).
func _skill_step(extra: Dictionary) -> Dictionary:
	var player := _player
	match Progress.character:
		"archer":
			return _task("Suhanás", "Íjászként a [b]Ctrl[/b] gombbal a kurzor felé [b]suhansz[/b]: átmész a szörnyeken "
				+ "és a lövedékeken, és közben nem sebezhetnek meg. 5 másodpercenként használhatod (lent látod, mikor "
				+ "kész). Próbáld ki!", func() -> bool: return float(player.call("dash_cooldown_ratio")) > 0.0 \
					or _cleared(ROOM_SKILL), extra)
		"veteran":
			return _task("Hadi kiáltás", "Gáspár a [b]Ctrl[/b] gombbal [b]hadi kiáltást[/b] hallat: a közeli szörnyeket "
				+ "ellöki, és egy pillanatra megtöri őket. 7 másodpercenként használhatod (lent látod, mikor kész). "
				+ "Próbáld ki!", func() -> bool: return float(player.call("war_cry_cooldown_ratio")) > 0.0 \
					or _cleared(ROOM_SKILL), extra)
		"thief":
			return _task("Árnyéklépés", "Bence a [b]Ctrl[/b] gombbal a kurzorhoz legközelebbi szörny [b]háta mögé "
				+ "lép[/b], és a következő ütése biztosan kritikus. Célozz egy szörnyre, és nyomd meg a Ctrl-t! "
				+ "(6 másodpercenként megy.)", func() -> bool: return float(player.call("shadow_step_cooldown_ratio")) \
					> 0.0 or _cleared(ROOM_SKILL), extra)
		"gravedigger":
			return _task("Idézés", "Vendel a [b]bal egérgombbal csontvázakat idéz[/b] (3 másodpercenként). Minden 5. "
				+ "szinten új idézést választhatsz: íjász csontvázakat vagy egy óriást, ezek a [b]jobb egérgombra[/b] "
				+ "kerülnek. Idézz csontvázakat!", func() -> bool: return float(player.call("summon_cooldown_left")) \
					> 0.0 or _cleared(ROOM_SKILL), extra)
		"wizard":
			return _info("Varázslatok", "Lőrinc pálcája a kiválasztott varázslatot lövi (bal egérgomb). Minden 5. "
				+ "szinten új varázslatot tanulhatsz, vagy erősítheted a meglévőt; a második a [b]jobb egérgombra[/b] "
				+ "kerül. Az [b]Elemi erő[/b] stat erősíti a varázslatokat.", extra)
	return _info("A lovag", "A lovagnak nincs külön képessége, viszont kiegyensúlyozott, és bármilyen közelharci "
		+ "fegyvert foghat. Más karakterek (amiket később ismerhetsz meg) saját képességgel bírnak: suhanás, hadi "
		+ "kiáltás, varázslat, idézés...", extra)


# ---------------------------------------------------------------- előkészítések

## Pont annyi XP-gömb a játékos köré, hogy szintet lépjen (olyan közel, hogy mind magától odarepüljön:
## Pickup.MAGNET_RANGE-en belül, a kipattanással együtt is).
func _spawn_xp() -> void:
	var experience: Experience = _player.get_node("Experience")
	var total := experience.needed() - experience.xp
	var count := 5
	for i in count:
		var orb = XP_ORB.instantiate()
		orb.value = total / count + (total % count if i == 0 else 0)
		orb.position = _player.position + Vector2.from_angle(TAU * i / count) * 50.0
		_player.get_parent().add_child(orb)


func _inventory() -> Inventory:
	return _player.get_node("Inventory")


## A gyakorlás sisakja (a megjelölt példány; a kovácsnál ezt fejlesztjük).
func _tutorial_helmet() -> Variant:
	var inventory := _inventory()
	for item: Variant in inventory.bag + [inventory.equipment.get("helmet")]:
		if item is Dictionary and item.get("tutorial", "") == "helmet":
			return item
	return null


func _helmet_equipped() -> bool:
	var helmet: Variant = _inventory().equipment.get("helmet")
	return helmet is Dictionary


func _give_helmet() -> void:
	if _tutorial_helmet() != null or _helmet_equipped():
		return
	var helmet := Items.create("helmet_leather", "rare")
	helmet["tutorial"] = "helmet"
	_inventory().add_item(helmet)


func _ensure_gold(amount: int) -> void:
	var gold: int = _player.get("gold")
	if gold < amount:
		_player.call("add_gold", amount - gold)


## A bájital-lépés: egy ajándék bájital, és az élet a felére csökken, hogy legyen mit visszatölteni.
func _start_potion_step() -> void:
	GameState.potions += 1
	_last_potions = GameState.potions
	_potion_step_started = true
	var health: Health = _player.get_node("Health")
	health.current = maxi(1, health.max_health / 2)
	health.changed.emit(health.current, health.max_health)


## Az üllőhöz: egy szétszedhető ezüstgyűrű.
func _prepare_anvil() -> void:
	var inventory := _inventory()
	for item: Variant in inventory.bag:
		if item is Dictionary and item.get("tutorial", "") == "ring":
			return
	if _seen.has("dismantled"):
		return
	var ring := Items.create("ring_silver")
	ring["tutorial"] = "ring"
	if not inventory.add_item(ring):
		inventory.replace("bag", 0, ring)


## A fejlesztéshez: a felvett sisak (ha nincs, vagy nem fejleszthető, egy ritka sisak kerül a helyére), és
## 4 por a következő ritkaságából.
func _prepare_upgrade() -> void:
	var inventory := _inventory()
	var helmet: Variant = inventory.equipment.get("helmet")
	if not (helmet is Dictionary and Smithing.upgrade_block(helmet).is_empty()):
		helmet = Items.create("helmet_leather", "rare")
		helmet["tutorial"] = "helmet"
		inventory.replace("equip", "helmet", helmet)
	var next := Smithing.next_rarity(helmet["rarity"])
	if Smithing.dust_of(next) < Smithing.UPGRADE_COST:
		Smithing.add_dust(next, Smithing.UPGRADE_COST - Smithing.dust_of(next))
	var panel := _scene.get_node_or_null("SmithPanel")
	if panel != null and panel.visible:
		panel.call("_refresh")


# ---------------------------------------------------------------- célpontok (a sárga nyílnak)

func _chest_target() -> Vector2:
	return _room_center(ROOM_FIGHT) if _cleared(ROOM_FIGHT) else Vector2.INF


func _shop_target() -> Vector2:
	var shop := _shop_room_child(func(child: Node) -> bool: return child.scene_file_path == SHOP_SCENE)
	return shop.global_position + Vector2(0, 12) if shop != null and not _in_shop() else Vector2.INF


func _lift_target() -> Vector2:
	var lift := _shop_room_child(func(child: Node) -> bool: return child.get_script() == ITEM_LIFT)
	return lift.global_position + Vector2(0, 24) if lift != null and not _in_shop() else Vector2.INF


func _shop_room_child(matches: Callable) -> Node2D:
	for child in _room(ROOM_SHOP).get_children():
		if matches.call(child):
			return child as Node2D
	return null


func _anvil_target() -> Vector2:
	var anvil := _scene.get_node_or_null("Entities/TutorialAnvil") as Node2D
	return anvil.global_position + Vector2(0, -6) if anvil != null else Vector2.INF


func _portal_target() -> Vector2:
	for child in _room(ROOM_BOSS).get_children():
		if child.get_script() == RETURN_PORTAL:
			return (child as Node2D).global_position
	return Vector2.INF


func _stairs_target() -> Vector2:
	var tiles: Array = _room(ROOM_BOSS).call("_alcove_tiles")
	return Room.tile_center(tiles[1])


func _in_shop() -> bool:
	return _player.global_position.y > (ShopInterior.RECT.position.y - 1) * Room.TILE


# ---------------------------------------------------------------- figyelés és léptetés

func _process(delta: float) -> void:
	if not is_instance_valid(_player) or _done:
		return
	_remember()
	if _advancing or _index >= _steps.size():
		return
	_step_time += delta
	var step: Dictionary = _steps[_index]
	_update_pointers(step)
	_update_mini(step)
	if _step_time > SKIP_HINT_AFTER and not step.get("info", false):
		_footer.text = "Elakadtál? A [H] gombbal átugorhatod ezt a lépést."
	if (step["done"] as Callable).call():
		_advance()


## Minden képkockában feljegyzi, ami épp történik (akármelyik lépésnél tartasz).
func _remember() -> void:
	if _player.global_position.distance_to(_start_position) > 140.0:
		_seen["moved"] = true
	if Input.is_action_pressed("attack"):
		_seen["attack"] = true
	_remember_open("PauseMenu", "pause")
	_remember_open("StatsScreen", "stats")
	_remember_open("SmithPanel", "smith")
	if _mode == "camp":
		_remember_open("CampUpgrades", "upgrades")
		_remember_open("StashPanel", "stash")
		_remember_open("BestiaryBook", "bestiary")
		_remember_open("QuestBook", "quests")
		return
	var minimap := _scene.get_node_or_null("HUD/Minimap")
	if minimap != null and minimap.get("_expanded") == true:
		_seen["map"] = true
	elif _seen.has("map"):
		_seen["map_closed"] = true
	if GameState.chests_opened > 0:
		_seen["chest"] = true
	if _in_shop():
		if not _was_in_shop:
			_bag_count_at_shop = _bag_count()
			_potions_at_shop = GameState.potions
		_was_in_shop = true
		_seen["shop_in"] = true
		if _bag_count() > _bag_count_at_shop:
			_seen["bought"] = true
		if GameState.potions > _potions_at_shop:
			_seen["potion_bought"] = true
	elif _was_in_shop:
		_seen["shop_out"] = true
	var lift := _scene.get_node_or_null("ItemLiftPanel")
	if lift != null and lift.visible:
		_seen["lift"] = true
	var portal_panel := _scene.get_node_or_null("BossReturnPanel")
	if portal_panel != null and portal_panel.visible:
		_seen["portal"] = true
	elif _seen.has("portal"):
		_seen["portal_closed"] = true
	# A bájital a saját lépésétől számít (akkor kapod az ajándékot).
	if _potion_step_started and GameState.potions < _last_potions:
		_seen["potion"] = true
	_last_potions = GameState.potions


## Egy ablak: ha látszik, "<kulcs>", ha utána becsukták, "<kulcs>_closed".
func _remember_open(path: String, key: String) -> void:
	var node := _scene.get_node_or_null(path) as CanvasLayer
	if node != null and node.visible:
		_seen[key] = true
	elif _seen.has(key):
		_seen[key + "_closed"] = true


func _bag_count() -> int:
	return _inventory().bag.filter(func(item: Variant) -> bool: return item != null).size()


## Az Enter / H az ablakok előtt jut ide (egy nyitott ablak fókuszált gombja különben elnyelné).
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.alt_pressed or _done:
		return
	if _advancing or _index >= _steps.size() or get_viewport().gui_get_focus_owner() is LineEdit:
		return
	# Szintlépés, varázslat-választás alatt nem (azoknak saját gombjaik vannak); nyitott ablaknál igen.
	var menus := _scene.get_node("Menus")
	if GamePause.active(get_tree()) and not bool(menus.call("is_open")):
		return
	var step: Dictionary = _steps[_index]
	if step.get("info", false) and key.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		get_viewport().set_input_as_handled()
		_confirmed = true
	elif key.physical_keycode == KEY_H:
		get_viewport().set_input_as_handled()
		_skip()


## H: a lépés átugrása (hülyebiztos: ha valami mégsem sikerülne). A lépcsőt nem lehet átugrani, az a vége.
func _skip() -> void:
	if _index >= _steps.size() - 1:
		return
	Audio.play("ui_click")
	_advance()


func _advance() -> void:
	_advancing = true
	Audio.play("ui_click")
	_title.text = "✔ " + _steps[_index]["title"]
	_title.add_theme_color_override("font_color", DONE_COLOR)
	await get_tree().create_timer(0.8, true).timeout
	_index += 1
	_advancing = false
	_show_step()


func _show_step() -> void:
	if _index >= _steps.size():
		return
	var step: Dictionary = _steps[_index]
	_step_time = 0.0
	_confirmed = false
	_counter.text = "%s  ·  %d / %d" % ["Gyakorlás: a tábor" if _mode == "camp" else "Gyakorlás", _index + 1,
		_steps.size()]
	_title.text = step["title"]
	_title.add_theme_color_override("font_color", UiStyle.INK)
	_text.text = step["text"]
	_footer.text = "[Enter] Tovább" if step.get("info", false) else ""
	_set_gate(int(step.get("room", ROOM_BOSS)))
	# Ha már előre megcsináltad, nem kell újra előkészíteni (pl. XP-gömbök, ajándék sisak).
	var already: bool = (step["done"] as Callable).call()
	if step.has("start") and not already:
		(step["start"] as Callable).call()
	var highlights: Array[Control] = []
	for path: String in step.get("highlight", []):
		var control := _highlight_control(path)
		if control != null:
			highlights.append(control)
	_highlight.targets = highlights
	_panel.modulate.a = 0.0
	create_tween().tween_property(_panel, "modulate:a", 1.0, 0.3)


func _highlight_control(path: String) -> Control:
	if path == "potion":
		var badges := _scene.find_children("*", "PotionBadge", false, false)
		return badges[0].get("_box") as Control if not badges.is_empty() else null
	if path == "camp_gold":
		var label := _scene.get("_gold_label") as Control
		return label.get_parent() as Control if label != null else null
	return _scene.get_node_or_null(path) as Control


## Eddig a szobáig lehet bemenni: a későbbiek ajtaja zárva (a már bejártakét nem zárja vissza).
func _set_gate(last_room: int) -> void:
	if last_room == _gate:
		return
	_gate = last_room
	for i in _rooms.size():
		var blocked := i > last_room and not _room(i).visited
		if bool(_gated.get(i, false)) != blocked:
			_room(i).set_gate(blocked)
			_gated[i] = blocked


## Ha egy ablak van nyitva, a fenti pergamen alatta van: a teendő röviden a képernyő alján, az ablak fölött.
func _update_mini(step: Dictionary) -> void:
	var menus := _scene.get_node_or_null("Menus")
	var open := menus != null and bool(menus.call("is_open")) and not _advancing
	_mini.visible = open
	if not open:
		return
	# A rövid szöveg csak a lépés saját ablakához illik; másik ablaknál: előbb azt csukd be.
	var open_menu: Node = menus.get("_open")
	var own: bool = open_menu != null and open_menu.name == str(step.get("window", ""))
	var hint: String = step.get("short", "") if own else ""
	if hint.is_empty():
		hint = "Csukd be ezt az ablakot (X vagy Esc), és folytatjuk."
	if step.get("info", false):
		hint += "   [color=#ffd36a][Enter] Tovább[/color]"
	_mini_text.text = "[b]%s:[/b]  %s" % [step["title"], hint]


func _update_pointers(step: Dictionary) -> void:
	var target := Vector2.INF
	if step.has("target"):
		target = (step["target"] as Callable).call()
	_arrow.target = target


# ---------------------------------------------------------------- vége

## A gyakorló pálya lépcsője (Dungeon._go_deeper): irány a tábor; a tábor lépcsője (Camp._enter_dungeon): a vége.
func finish() -> void:
	if _finish_layer != null:
		return
	if _done:
		return
	_done = true
	_mini.visible = false
	if _mode == "dungeon":
		_title.text = "Irány a tábor!"
		_text.text = "Most megnézzük a tábort, ahová minden futás után visszatérsz."
		_footer.text = ""
		_highlight.targets = []
		_arrow.target = Vector2.INF
		Audio.play("door_unlock")
		await get_tree().create_timer(1.6, true).timeout
		GameState.reset()
		GamePause.set_paused(get_tree(), false)
		get_tree().change_scene_to_file(CAMP_SCENE)
		return
	Audio.play("level_up")
	_panel.visible = false
	_highlight.targets = []
	_arrow.target = Vector2.INF
	GamePause.set_paused(get_tree(), true)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_finish_layer = Control.new()
	_finish_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_finish_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_finish_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_finish_layer.add_child(center)
	var window := PanelContainer.new()
	window.add_theme_stylebox_override("panel", UiStyle.decorated_panel())
	window.custom_minimum_size = Vector2(940, 0)
	center.add_child(window)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	window.add_child(box)
	box.add_child(UiStyle.title_bar("Gyakorlás kész!"))
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.custom_minimum_size.x = 860
	text.add_theme_color_override("default_color", UiStyle.INK_LIGHT)
	text.add_theme_font_size_override("normal_font_size", 17)
	text.add_theme_font_size_override("bold_font_size", 17)
	text.text = TutorialManual.FINISH_TEXT
	box.add_child(text)
	var button := MenuStyle.button("Vissza a főmenübe")
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(leave)
	box.add_child(button)
	button.grab_focus()


## Kilépés a gyakorlásból a főmenübe (a halálképernyő és a szünet menü is ezt hívja). A gyakorlás alatti
## változások (tábori arany, fejlesztés, láda...) eldobódnak.
static func leave_tutorial(tree: SceneTree) -> void:
	GameState.tutorial = false
	Progress.discard_tutorial_changes()
	GameState.reset()
	GamePause.set_paused(tree, false)
	tree.change_scene_to_file(MAIN_MENU)


func leave() -> void:
	leave_tutorial(get_tree())


# ---------------------------------------------------------------- UI

func _build_ui() -> void:
	layer = 7
	process_mode = Node.PROCESS_MODE_ALWAYS
	_highlight = HudHighlight.new()
	_highlight.set_anchors_preset(Control.PRESET_FULL_RECT)
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_highlight)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_panel.offset_left = -PANEL_WIDTH / 2.0
	_panel.offset_right = PANEL_WIDTH / 2.0
	_panel.offset_top = 70
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(box)
	_counter = UiStyle.label("", 13, UiStyle.INK_LIGHT)
	box.add_child(_counter)
	_title = UiStyle.label("", 22, UiStyle.INK)
	box.add_child(_title)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.custom_minimum_size.x = PANEL_WIDTH - 40
	_text.add_theme_color_override("default_color", UiStyle.INK_LIGHT)
	_text.add_theme_font_size_override("normal_font_size", 16)
	_text.add_theme_font_size_override("bold_font_size", 16)
	box.add_child(_text)
	_footer = UiStyle.label("", 14, Color(0.5, 0.36, 0.1))
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(_footer)
	_mini_layer = CanvasLayer.new()
	_mini_layer.layer = 26
	_mini_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_mini_layer)
	_mini = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.09, 0.05, 0.94)
	style.border_color = Color(1, 0.78, 0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	_mini.add_theme_stylebox_override("panel", style)
	_mini.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_mini.offset_left = -PANEL_WIDTH / 2.0
	_mini.offset_right = PANEL_WIDTH / 2.0
	_mini.offset_top = -64
	_mini.offset_bottom = -6
	_mini.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mini.visible = false
	_mini_layer.add_child(_mini)
	_mini_text = RichTextLabel.new()
	_mini_text.bbcode_enabled = true
	_mini_text.fit_content = true
	_mini_text.scroll_active = false
	_mini_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mini_text.custom_minimum_size.x = PANEL_WIDTH - 24
	_mini_text.add_theme_color_override("default_color", Color(1, 0.94, 0.8))
	_mini_text.add_theme_font_size_override("normal_font_size", 16)
	_mini_text.add_theme_font_size_override("bold_font_size", 16)
	_mini.add_child(_mini_text)


## Villogó keret a HUD éppen magyarázott részei körül.
class HudHighlight:
	extends Control
	var targets: Array[Control] = []
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var alpha := 0.55 + 0.45 * sin(_time * 6.0)
		for target in targets:
			if not is_instance_valid(target) or not target.is_visible_in_tree():
				continue
			var rect := target.get_global_rect().grow(6.0)
			draw_rect(rect, Color(0, 0, 0, 0.5 * alpha), false, 6.0)
			draw_rect(rect, Color(1, 0.78, 0.2, alpha), false, 3.0)


## Sárga nyíl: a cél fölött ugráló jel, és ha a cél messze van, a játékos körül a cél felé mutató hegy.
class GuideArrow:
	extends Node2D
	const FILL := Color(1, 0.8, 0.2)
	const OUTLINE := Color(0.18, 0.1, 0.02)
	var player: Node2D
	var target := Vector2.INF
	var _time := 0.0

	func _ready() -> void:
		top_level = true
		z_index = 60
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _process(delta: float) -> void:
		_time += delta
		global_position = Vector2.ZERO
		queue_redraw()

	func _draw() -> void:
		if target == Vector2.INF or not is_instance_valid(player):
			return
		var bob := sin(_time * 5.0) * 5.0
		_triangle(target + Vector2(0, -36 + bob), Vector2.DOWN, 11.0)
		var from := player.global_position + Vector2(0, -14)
		if from.distance_to(target) > 120.0:
			var direction := from.direction_to(target)
			_triangle(from + direction * (52.0 + bob * 0.6), direction, 10.0)

	func _triangle(tip: Vector2, direction: Vector2, size: float) -> void:
		var side := direction.orthogonal()
		var points := PackedVector2Array([tip, tip - direction * size * 1.6 + side * size,
			tip - direction * size * 1.6 - side * size])
		var outline := PackedVector2Array([tip + direction * 2.5, tip - direction * (size * 1.6 + 1.5) + side * (size + 2.5),
			tip - direction * (size * 1.6 + 1.5) - side * (size + 2.5)])
		draw_colored_polygon(outline, OUTLINE)
		draw_colored_polygon(points, FILL)
