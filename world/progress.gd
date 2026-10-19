class_name Progress
## Mentett játékállás (a játék bezárása után is megmarad): a táborba felküldött
## arany és a tábori, minden futásra érvényes fejlesztések szintjei.
## Minden változás azonnal mentődik, így bárhonnan (a kazamatából is) kilépve
## megmarad; a futás maga (emelet, szint, felszerelés) nem menthető, mindig
## a táborban kezdesz.

const PATH := "user://save.cfg"

## Tábori fejlesztések (minden alapstathoz egy). per_level: ennyit ad szintenként a
## `stat`-ra, minden futásra; costs: az egyes szintek ára tábori aranyban.
## 100 arany az első szint, és minden szint 100-zal drágább.
const COSTS: Array[int] = [100, 200, 300, 400, 500]
const UPGRADES := {
	"strength": {"name": "Erőedzés", "stat": "damage_percent", "per_level": 3, "costs": COSTS},
	"weapon_mastery": {"name": "Fegyverforgatás", "stat": "damage", "per_level": 1, "costs": COSTS},
	"vitality": {"name": "Edzett test", "stat": "max_health", "per_level": 3, "costs": COSTS},
	"herbalism": {"name": "Gyógynövénytan", "stat": "health_regen", "per_level": 0.1, "costs": COSTS},
	"shield_training": {"name": "Pajzsgyakorlat", "stat": "defense", "per_level": 2, "costs": COSTS},
	"acrobatics": {"name": "Akrobatika", "stat": "dodge", "per_level": 1, "costs": COSTS},
	"running": {"name": "Futóedzés", "stat": "move_speed", "per_level": 3, "costs": COSTS},
	"fencing": {"name": "Vívógyakorlat", "stat": "attack_speed", "per_level": 4, "costs": COSTS},
	"precision": {"name": "Célzógyakorlat", "stat": "crit_chance", "per_level": 1, "costs": COSTS},
	"long_arms": {"name": "Nyújtózkodás", "stat": "attack_range", "per_level": 3, "costs": COSTS},
}

## A táborban váró arany (halálkor, kilépéskor, és a főellenség utáni visszatéréskor kerül ide).
static var camp_gold := 0
## fejlesztés -> szint
static var upgrades := {}
## A tábori ládában váró tárgyak (a tárgylifttel / a főellenség után felküldve).
static var stash: Array = []
## A táborban nálad lévő felszerelés (Inventory.save_data); üres = kezdő felszerelés.
## Leszálláskor magaddal viszed (és innen törlődik).
static var camp_inventory := {}
static var _loaded := false


static func has_save() -> bool:
	return FileAccess.file_exists(PATH)


## Betölti a mentést (ha még nem történt meg, vagy `force`).
static func load_game(force := false) -> void:
	if _loaded and not force:
		return
	_loaded = true
	camp_gold = 0
	upgrades = {}
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	camp_gold = int(config.get_value("camp", "gold", 0))
	var saved: Variant = config.get_value("camp", "upgrades", {})
	if saved is Dictionary:
		upgrades = saved
	var saved_stash: Variant = config.get_value("camp", "stash", [])
	if saved_stash is Array:
		stash = saved_stash
	var saved_inventory: Variant = config.get_value("camp", "inventory", {})
	if saved_inventory is Dictionary:
		camp_inventory = saved_inventory


static func save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("camp", "gold", camp_gold)
	config.set_value("camp", "upgrades", upgrades)
	config.set_value("camp", "stash", stash)
	config.set_value("camp", "inventory", camp_inventory)
	config.save(PATH)


## Új játék: minden tábori haladás törlődik.
static func reset_game() -> void:
	_loaded = true
	camp_gold = 0
	upgrades = {}
	stash = []
	camp_inventory = {}
	save_game()


## Egy tárgy a tábori ládába (mentve).
static func add_to_stash(item: Dictionary) -> void:
	load_game()
	stash.append(item)
	save_game()


## A futás aranyának egy része a táborba kerül (halál 20%, kilépés 40%, főellenség után 70%).
## Futásonként csak egyszer (GameState.gold_rescued). Visszaadja, mennyi került fel.
static func rescue_gold(gold: int, ratio: float) -> int:
	if GameState.gold_rescued:
		return 0
	GameState.gold_rescued = true
	var amount := floori(gold * ratio)
	if amount > 0:
		add_camp_gold(amount)
	return amount


static func add_camp_gold(amount: int) -> void:
	load_game()
	camp_gold += amount
	save_game()


static func level(id: String) -> int:
	load_game()
	return int(upgrades.get(id, 0))


static func max_level(id: String) -> int:
	return UPGRADES[id]["costs"].size()


## A következő szint ára (-1, ha már max szinten van).
static func next_cost(id: String) -> int:
	var current := level(id)
	var costs: Array = UPGRADES[id]["costs"]
	return costs[current] if current < costs.size() else -1


## Megveszi a következő szintet, ha van rá elég tábori arany.
static func buy(id: String) -> bool:
	var cost := next_cost(id)
	if cost < 0 or camp_gold < cost:
		return false
	camp_gold -= cost
	upgrades[id] = level(id) + 1
	save_game()
	return true


## A fejlesztések stat-bónuszai (minden futás elején a játékosra kerülnek).
static func permanent_bonuses() -> Dictionary:
	var bonuses := {}
	for id: String in UPGRADES:
		var definition: Dictionary = UPGRADES[id]
		var stat: String = definition["stat"]
		bonuses[stat] = bonuses.get(stat, 0.0) + level(id) * float(definition["per_level"])
	return bonuses
