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
## Játékidő másodpercben (szünet alatt nem nő).
static var run_time := 0.0
## A futás már bekerült az eredménytáblába (halálkor vagy feladáskor egyszer).
static var run_recorded := false
## Ezen az emeleten már felküldtél-e tárgyat a tárgylifttel (liftenként egyet lehet).
static var lift_used_floor := 0
## Az arany egy része már a táborba került ebben a futásban (halálkor / kilépéskor egyszer).
static var gold_rescued := false

## Az ablak már teljes képernyőre lett állítva indításkor (nem a futás része, reset nem törli).
static var display_initialized := false


## Új futás kezdése (halál után).
static func reset() -> void:
	depth = 1
	saved_stats = {}
	saved_health = -1
	saved_level = 1
	saved_xp = 0
	saved_gold = 0
	saved_inventory = {}
	kills = 0
	run_time = 0.0
	run_recorded = false
	lift_used_floor = 0
	gold_rescued = false
