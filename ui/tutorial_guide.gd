class_name TutorialGuide
extends CanvasLayer
## A gyakorló pálya (tutorial) vezetője. A pálya hét szobája (Dungeon.TUTORIAL_CELLS) egy-egy leckéhez tartozik:
## kezdőszoba (mozgás, a képernyő, térkép, szünet), harc + láda (harc, szintlépés, felszerelés, karakterlap),
## csapdák + a karakter képessége, bolt + tárgylift (vásárlás, bájital), gyakorló üllő (kovács), különleges
## szörnyek, végül egy főellenség (jutalom, pihenő, lépcső). A végén lapozható összefoglaló arról, ami a pályán
## nem fér bele (tábor, halál, karakterek és küldetések, közös játék; TutorialManual.FINISH_PAGES).
## A Dungeon hozza létre, ha GameState.tutorial igaz.
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

var _dungeon: Node
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

var _panel: PanelContainer
var _counter: Label
var _title: Label
var _text: RichTextLabel
var _footer: Label
var _highlight: HudHighlight
var _arrow: GuideArrow
var _finish_layer: Control
var _finish_page := 0
var _finish_title: Label
var _finish_text: RichTextLabel
var _finish_counter: Label
var _finish_prev: Button
var _finish_next: Button


func setup(dungeon: Node, rooms: Array) -> void:
	_dungeon = dungeon
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
			func() -> bool: return _seen.has("map_closed"), start),
		_task("Szünet", "Az [b]Esc[/b] gomb megállítja a játékot (közös játékban nem áll meg semmi). Itt vannak a "
			+ "[b]beállítások[/b] (hang, teljes képernyő), és innen [b]adhatod fel[/b] a futást is. Nyomd meg az Esc-et, "
			+ "nézz körül, aztán Folytatás (vagy újra Esc).",
			func() -> bool: return _seen.has("pause_closed"), start),
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
			func() -> bool: return _player.get_node("Experience").level >= 2 and not _dungeon.get_node("LevelUp").visible,
			fight.merged({"start": _spawn_xp})),
		_task("Láda", "A kitisztított szobában [b]láda[/b] jelent meg. Menj oda, és érintsd meg: aranyat ad, néha "
			+ "tárgyat is.", func() -> bool: return _seen.has("chest"),
			fight.merged({"target": _chest_target})),
		_task("Felszerelés", "Kaptál egy [color=#1f52b8]kék (ritka) sisakot[/color]. Nyisd meg a felszerelést az "
			+ "[b]I[/b] gombbal, és húzd a sisakot a sisak-helyére (vagy kattints rá a [b]jobb egérgombbal[/b]). "
			+ "Ha az egeret egy tárgy fölé viszed, látod a statjait, és hogy mennyivel jobb vagy rosszabb a mostaninál.",
			func() -> bool: return _helmet_equipped(), fight.merged({"start": _give_helmet})),
		_info("Ritkaságok", "A tárgy színe a ritkasága: [color=#5c544c]átlagos[/color], [color=#1f52b8]ritka[/color], "
			+ "[color=#7a2eae]epikus[/color], [color=#b85c00]legendás[/color] és [color=#b8120c]mítikus[/color]. Minél "
			+ "ritkább, annál erősebb. A fegyvereknek fajtája is van (kard, tőr, lándzsa, balta, buzogány, íjak, "
			+ "számszeríj), és nem minden karakter foghat mindent: a tárgy leírása megmondja. A táskádba 24 tárgy fér.",
			fight),
		_task("Karakterlap", "Csukd be a felszerelést (I, Esc vagy X), és nyomd meg a [b]Tab[/b] gombot: itt az "
			+ "[b]összes statod[/b] részletesen, a fegyvered sebzésképlete és a futásod adatai. A stat-oldalakat a "
			+ "◄ ► gombokkal (vagy A / D) lapozod. Nézd meg, aztán csukd be (Tab).",
			func() -> bool: return _seen.has("stats_closed"), fight),
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
			func() -> bool: return _seen.has("dismantled"), anvil.merged({"start": _prepare_anvil})),
		_task("Fejlesztés", "Most tedd a kör közepére a [b]sisakodat[/b] (a Felszerelésed közül), és nyomd meg a "
			+ "[b]Fejlesztés[/b] gombot. Ehhez [b]4 por[/b] kell a [b]következő[/b] ritkaságból: ezt most odaadtam. Az "
			+ "igazi játékban 65% eséllyel sikerül (ha nem, a por elvész, a tárgy marad); itt biztosan sikerül.",
			func() -> bool: return _seen.has("upgraded"), anvil.merged({"start": _prepare_upgrade})),
		_task("Bezárás", "Csukd be az ablakot a jobb felső [b]X[/b]-szel (vagy Esc, vagy E).",
			func() -> bool: return not _dungeon.get_node("SmithPanel").visible, anvil),
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
			func() -> bool: return _seen.has("portal_closed"), {"room": ROOM_BOSS, "target": _portal_target}),
		_task("Lépcső", "A [b]lépcső[/b] a következő, nehezebb emeletre visz: lent erősebb szörnyek és jobb tárgyak "
			+ "várnak. Lépj rá a gyakorlás befejezéséhez!", func() -> bool: return false,
			{"room": ROOM_BOSS, "target": _stairs_target}),
	])


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
	var panel := _dungeon.get_node_or_null("SmithPanel")
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
	var anvil := _dungeon.get_node_or_null("Entities/TutorialAnvil") as Node2D
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
	if not is_instance_valid(_player) or _finish_layer != null:
		return
	_remember()
	if _advancing or _index >= _steps.size():
		return
	_step_time += delta
	var step: Dictionary = _steps[_index]
	_update_pointers(step)
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
	if _dungeon.get_node("HUD/Minimap").get("_expanded") == true:
		_seen["map"] = true
	elif _seen.has("map"):
		_seen["map_closed"] = true
	if _dungeon.get_node("PauseMenu").visible:
		_seen["pause"] = true
	elif _seen.has("pause"):
		_seen["pause_closed"] = true
	if _dungeon.get_node("StatsScreen").visible:
		_seen["stats"] = true
	elif _seen.has("stats"):
		_seen["stats_closed"] = true
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
	var lift := _dungeon.get_node_or_null("ItemLiftPanel")
	if lift != null and lift.visible:
		_seen["lift"] = true
	var smith := _dungeon.get_node_or_null("SmithPanel")
	if smith != null and smith.visible:
		_seen["smith"] = true
	var portal_panel := _dungeon.get_node_or_null("BossReturnPanel")
	if portal_panel != null and portal_panel.visible:
		_seen["portal"] = true
	elif _seen.has("portal"):
		_seen["portal_closed"] = true
	# A bájital a saját lépésétől számít (akkor kapod az ajándékot).
	if _potion_step_started and GameState.potions < _last_potions:
		_seen["potion"] = true
	_last_potions = GameState.potions


func _bag_count() -> int:
	return _inventory().bag.filter(func(item: Variant) -> bool: return item != null).size()


## Az Enter / H az ablakok előtt jut ide (egy nyitott ablak fókuszált gombja különben elnyelné).
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.alt_pressed or _finish_layer != null:
		return
	if _advancing or _index >= _steps.size() or get_viewport().gui_get_focus_owner() is LineEdit:
		return
	# Szintlépés, varázslat-választás alatt nem (azoknak saját gombjaik vannak); nyitott ablaknál igen.
	var menus := _dungeon.get_node("Menus")
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
	_counter.text = "Gyakorlás  ·  %d / %d" % [_index + 1, _steps.size()]
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
		var badges := _dungeon.find_children("*", "PotionBadge", false, false)
		return badges[0].get("_box") as Control if not badges.is_empty() else null
	return _dungeon.get_node_or_null(path) as Control


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


func _update_pointers(step: Dictionary) -> void:
	var target := Vector2.INF
	if step.has("target"):
		target = (step["target"] as Callable).call()
	_arrow.target = target


# ---------------------------------------------------------------- vége

## A lépcsőre lépve (Dungeon._go_deeper): lapozható összefoglaló, amit a pályán nem lehetett megmutatni.
func finish() -> void:
	if _finish_layer != null:
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
	box.add_child(UiStyle.label("Ügyes voltál! Ami a pályára nem fért fel, azt itt olvashatod el (a főmenü Tutorial "
		+ "ablakában később is megtalálod).", 15, UiStyle.INK_LIGHT))
	var page := PanelContainer.new()
	page.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	page.custom_minimum_size = Vector2(880, 330)
	box.add_child(page)
	var page_box := VBoxContainer.new()
	page.add_child(page_box)
	_finish_title = UiStyle.label("", 22, UiStyle.INK)
	page_box.add_child(_finish_title)
	_finish_text = RichTextLabel.new()
	_finish_text.bbcode_enabled = true
	_finish_text.scroll_active = true
	_finish_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_finish_text.add_theme_color_override("default_color", UiStyle.INK_LIGHT)
	_finish_text.add_theme_font_size_override("normal_font_size", 16)
	_finish_text.add_theme_font_size_override("bold_font_size", 16)
	page_box.add_child(_finish_text)
	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 16)
	box.add_child(nav)
	_finish_prev = _nav_button("◄ Előző", func() -> void: _show_finish_page(_finish_page - 1))
	nav.add_child(_finish_prev)
	_finish_counter = UiStyle.label("", 16, UiStyle.INK)
	_finish_counter.custom_minimum_size.x = 120
	_finish_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_finish_counter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nav.add_child(_finish_counter)
	_finish_next = _nav_button("Következő ►", func() -> void: _show_finish_page(_finish_page + 1))
	nav.add_child(_finish_next)
	var button := MenuStyle.button("Vissza a főmenübe")
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(leave)
	box.add_child(button)
	_show_finish_page(0)
	_finish_next.grab_focus()


func _nav_button(text: String, action: Callable) -> Button:
	var button := MenuStyle.button(text)
	button.custom_minimum_size = Vector2(220, 52)
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(action)
	return button


func _show_finish_page(index: int) -> void:
	var pages: Array = TutorialManual.FINISH_PAGES
	_finish_page = clampi(index, 0, pages.size() - 1)
	_finish_title.text = pages[_finish_page][0]
	_finish_text.text = pages[_finish_page][1]
	_finish_text.scroll_to_line(0)
	_finish_counter.text = "%d / %d" % [_finish_page + 1, pages.size()]
	_finish_prev.disabled = _finish_page == 0
	_finish_next.disabled = _finish_page == pages.size() - 1


## Kilépés a gyakorlásból a főmenübe (a halálképernyő és a szünet menü is ezt hívja).
static func leave_tutorial(tree: SceneTree) -> void:
	GameState.tutorial = false
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
