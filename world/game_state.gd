class_name GameState
## Emeletek között megmaradó adatok. A statikus változók túlélik
## a jelenet újratöltését, így a lépcsőn lemenve megmarad a fejlődés.

## Hányadik emeleten jár a játékos (1-től).
static var depth := 1
## A játékos Stats értékei (üres = alapértékek).
static var saved_stats := {}
## A játékos HP-ja az emeletváltáskor (-1 = teljes életerő).
static var saved_health := -1
## Karakterszint és az abban összegyűjtött XP.
static var saved_level := 1
static var saved_xp := 0
static var saved_gold := 0
## A táska és a felszerelés (Inventory.save_data()); üres = kezdő felszerelés.
static var saved_inventory := {}

# A futás statisztikái a death screenhez.
static var kills := 0
## Kinyitott ládák ebben a futásban (a gyakorló pálya is ebből látja, hogy kinyitottad).
static var chests_opened := 0
## A varázsló varázslatai ebben a futásban (az első az elsődleges, a második a jobb egérgomb), és a szintjeik.
static var spells: Array = []
static var spell_levels := {}
## Játékidő másodpercben (szünet alatt nem nő).
static var run_time := 0.0
## A futás már bekerült az eredménytáblába (halálkor vagy feladáskor egyszer).
static var run_recorded := false
## Ezen az emeleten már felküldtél-e tárgyat a tárgylifttel (liftenként egyet lehet).
static var lift_used_floor := 0
## Az arany egy része már a táborba került ebben a futásban (halálkor / kilépéskor egyszer).
static var gold_rescued := false
## Pihenő a táborban (főellenség után kimentél): a futás áll, a tárgyaid, szinted, statjaid
## megvannak; a táborban a kék portálon át a következő emeletről folytatod.
static var on_break := false
## Ha nem vitted ki a pénzed a táborba, az "bent marad nálad": visszatéréskor visszakapod.
static var break_gold_left := 0
## Hányszor mentél ki pihenni ebben a futásban (az eredmények közé is bekerül).
static var exits := 0
## A tábori vándorárus kínálata a mostani pihenőre.
static var merchant_stock: Array = []
## Szintlépéskor hányszor dobtad újra a fejlesztéseket (minden újradobás drágább).
static var rerolls := 0
## HP bájitalok a gyorstár első helyén ([1]): a futáshoz tartoznak (boltban vehető, főellenség után jár).
static var potions := 0

## Gyakorló pálya (tutorial) megy: rögzített pálya, lépésről lépésre vezetés; semmi nem
## mentődik belőle (eredmény, tábori arany, tárgylift). A reset() nem törli, csak a kilépés.
static var tutorial := false

## Jártál-e lent a kazamatában (a gyakorló pályán kívül), mióta utoljára a táborba értél: a tábor
## ebből tudja, hogy most jöttél vissza (pl. a hordágyas bejátszáshoz). A reset() nem törli.
static var visited_dungeon := false

## Épp most győzted le a Vérfarkast (20. emelet): a tábor egyszer kiírja a győzelmet.
## (A reset() nem törli: a futás vége után állítjuk be.)
static var dungeon_won := false
## Csalás (CheatMenu): a játékos nem sebződik. A reset() nem törli, csak a menü kapcsolja.
static var god_mode := false
## Ebben a futásban csaltál (teleport vagy halhatatlanság, akár csak egyszer is): a futásból
## semmi nem mentődik (eredmény, arany, tárgyak, küldetések). Új futáskor törlődik, kivéve ha
## a halhatatlanság még be van kapcsolva.
static var cheated := false

## Az ablak már teljes képernyőre lett állítva indításkor (nem a futás része, reset nem törli).
static var display_initialized := false


## Új futás kezdése (halál után).
## Közös játékban a gazda által sorsolt mag: ebből generál mindenki ugyanolyan kazamatát
## (az emelet száma is belekerül). 0 = egyjátékos, saját véletlen. A reset nem törli.
static var net_seed := 0
## Közös játékban meghaltál, és nézőként követed a társaidat (a következő emeletre is).
static var net_dead := false
## Közös játékban a még ki nem választott szintlépések (alul a gombbal választasz; emeletváltáskor is megmaradnak).
static var pending_level_ups: Array[int] = []


static func reset() -> void:
	depth = 1
	net_dead = false
	pending_level_ups = []
	saved_stats = {}
	saved_health = -1
	saved_level = 1
	saved_xp = 0
	saved_gold = 0
	saved_inventory = {}
	kills = 0
	chests_opened = 0
	spells = []
	spell_levels = {}
	run_time = 0.0
	run_recorded = false
	lift_used_floor = 0
	gold_rescued = false
	on_break = false
	break_gold_left = 0
	exits = 0
	merchant_stock = []
	rerolls = 0
	potions = 0
	cheated = god_mode
