class_name Progress
## Mentett játékállás (a játék bezárása után is megmarad): a táborba felküldött
## arany és a tábori, minden futásra érvényes fejlesztések szintjei.
## Minden változás azonnal mentődik, így bárhonnan (a kazamatából is) kilépve
## megmarad; a futás maga (emelet, szint, felszerelés) nem menthető, mindig
## a táborban kezdesz.

## A mentés helye az aktív profiltól függ (lásd Profiles; az 1. profil: user://save.cfg).
static func path() -> String:
	return Profiles.save_path()

## Tábori fejlesztések (minden stathoz egy; "icon_path": saját ikon, ha a szintlépés-kártyák között nincs). per_level: ennyit ad szintenként a
## `stat`-ra, minden futásra; costs: az egyes szintek ára tábori aranyban.
## 100 arany az első szint, és minden szint 100-zal drágább.
const COSTS: Array[int] = [100, 200, 300, 400, 500]
## A Többlövés nagyon erős (+1 nyíl): csak 2 szint, drágán.
const MULTISHOT_COSTS: Array[int] = [600, 1200]
const UPGRADES := {
	"strength": {"name": "Erőedzés", "stat": "damage_percent", "per_level": 3, "costs": COSTS},
	"weapon_mastery": {"name": "Fegyverforgatás", "stat": "damage", "per_level": 1, "costs": COSTS},
	"archery": {"name": "Íjásztréning", "stat": "ranged_damage", "per_level": 1, "costs": COSTS},
	"vitality": {"name": "Edzett test", "stat": "max_health", "per_level": 3, "costs": COSTS},
	"herbalism": {"name": "Gyógynövénytan", "stat": "health_regen", "per_level": 0.1, "costs": COSTS},
	"shield_training": {"name": "Pajzsgyakorlat", "stat": "defense", "per_level": 2, "costs": COSTS},
	"acrobatics": {"name": "Akrobatika", "stat": "dodge", "per_level": 1, "costs": COSTS},
	"running": {"name": "Futóedzés", "stat": "move_speed", "per_level": 3, "costs": COSTS},
	"fencing": {"name": "Vívógyakorlat", "stat": "attack_speed", "per_level": 4, "costs": COSTS},
	"precision": {"name": "Célzógyakorlat", "stat": "crit_chance", "per_level": 1, "costs": COSTS},
	"long_arms": {"name": "Nyújtózkodás", "stat": "attack_range", "per_level": 3, "costs": COSTS},
	# Az újabb statok (eddig csak tárgyakon és szintlépéskor jöttek).
	"arcana": {"name": "Rúnatanulás", "stat": "elemental_damage", "per_level": 1, "costs": COSTS},
	"aiming": {"name": "Céllövölde", "stat": "accuracy", "per_level": 2, "costs": COSTS},
	"volley": {"name": "Sortűz-gyakorlat", "stat": "multishot", "per_level": 1, "costs": MULTISHOT_COSTS,
		"icon_path": "res://assets/ui/icon_multishot.png"},
	"bloodletting": {"name": "Vérszívó ösztön", "stat": "lifesteal", "per_level": 2, "costs": COSTS,
		"icon_path": "res://assets/ui/icon_lifesteal.png"},
	"spiked_armor": {"name": "Tüskés vért", "stat": "thorns", "per_level": 1, "costs": COSTS,
		"icon_path": "res://assets/ui/icon_thorns.png"},
	"treasure_hunting": {"name": "Kincsvadászat", "stat": "gold_find", "per_level": 4, "costs": COSTS,
		"icon_path": "res://assets/ui/icon_gold.png"},
	"lore": {"name": "Mesterek könyvei", "stat": "xp_bonus", "per_level": 4, "costs": COSTS,
		"icon_path": "res://assets/ui/icon_xp.png"},
}

## A táborban váró arany (halálkor, kilépéskor, és a főellenség utáni visszatéréskor kerül ide).
static var camp_gold := 0
## Az aktív (játszott) karakter (lásd Characters).
static var character := Characters.DEFAULT
## A tábori fejlesztések: fejlesztés -> szint (KÖZÖSEK: minden karakterre érvényesek).
static var upgrades := {}
## A tábori ládában váró tárgyak (közös; a tárgylifttel / a főellenség után felküldve).
static var stash: Array = []
## Küldetések (Quests): mind egyszerre fut; id -> haladás, és a már átvett jutalmú küldetések.
static var quest_progress := {}
static var quests_done: Array = []
## NPC-k bizalma (npc -> -100..+100) és a tőlük már megkérdezett témák (npc -> [téma]).
static var trust := {}
static var asked := {}
## NPC-küldetések állapota (Dialogues): küldetés -> "active" / "done" (nincs = még nem kérte).
static var npc_quests := {}
## Szörnyek könyve (Bestiary): szörny -> hányat öltél meg belőle (minden futásból összesen).
static var kills := {}
## Az aktív karakter tábori felszerelése (Inventory.save_data); üres = kezdő felszerelés.
## Leszálláskor magaddal viszed (és innen törlődik). Minden karakternek külön.
static var camp_inventory := {}
## karakter -> tábori felszerelése (az aktívé a fenti camp_inventory-ban is).
static var _all_inventories := {}
static var _loaded := false


static func has_save() -> bool:
	return FileAccess.file_exists(path())


## Betölti a mentést (ha még nem történt meg, vagy `force`).
static func load_game(force := false) -> void:
	if _loaded and not force:
		return
	_loaded = true
	camp_gold = 0
	character = Characters.DEFAULT
	upgrades = {}
	_all_inventories = {}
	stash = []
	quest_progress = {}
	quests_done = []
	trust = {}
	asked = {}
	npc_quests = {}
	kills = {}
	var config := ConfigFile.new()
	if config.load(path()) == OK:
		camp_gold = int(config.get_value("camp", "gold", 0))
		character = str(config.get_value("camp", "character", Characters.DEFAULT))
		if not Characters.ALL.has(character):
			character = Characters.DEFAULT
		upgrades = _load_upgrades(config)
		var inventories: Variant = config.get_value("camp", "inventory_by_character") \
			if config.has_section_key("camp", "inventory_by_character") else null
		if inventories is Dictionary:
			_all_inventories = inventories
		else:
			var old_inventory: Variant = config.get_value("camp", "inventory", {})
			_all_inventories = {Characters.DEFAULT: old_inventory if old_inventory is Dictionary else {}}
		var saved_stash: Variant = config.get_value("camp", "stash", [])
		if saved_stash is Array:
			stash = saved_stash
		var saved_progress: Variant = config.get_value("camp", "quest_progress", {})
		if saved_progress is Dictionary:
			quest_progress = saved_progress
		# Régi mentés: egyetlen felvett küldetés ({id, progress}) -> az ő haladása megmarad.
		var old_quest: Variant = config.get_value("camp", "quest", {})
		if old_quest is Dictionary and (old_quest as Dictionary).has("id"):
			var old: Dictionary = old_quest
			quest_progress[str(old["id"])] = maxi(int(quest_progress.get(old["id"], 0)), int(old.get("progress", 0)))
		var saved_done: Variant = config.get_value("camp", "quests_done", [])
		if saved_done is Array:
			quests_done = saved_done
		var saved_trust: Variant = config.get_value("camp", "trust", {})
		if saved_trust is Dictionary:
			trust = saved_trust
		var saved_asked: Variant = config.get_value("camp", "asked", {})
		if saved_asked is Dictionary:
			asked = saved_asked
		var saved_npc_quests: Variant = config.get_value("camp", "npc_quests", {})
		if saved_npc_quests is Dictionary:
			npc_quests = saved_npc_quests
		var saved_kills: Variant = config.get_value("camp", "kills", {})
		if saved_kills is Dictionary:
			kills = saved_kills
	_activate(character)


static func save_game() -> void:
	_all_inventories[character] = camp_inventory
	var config := ConfigFile.new()
	config.set_value("camp", "gold", camp_gold)
	config.set_value("camp", "character", character)
	config.set_value("camp", "upgrades", upgrades)
	config.set_value("camp", "inventory_by_character", _all_inventories)
	config.set_value("camp", "stash", stash)
	config.set_value("camp", "quest_progress", quest_progress)
	config.set_value("camp", "quests_done", quests_done)
	config.set_value("camp", "trust", trust)
	config.set_value("camp", "asked", asked)
	config.set_value("camp", "npc_quests", npc_quests)
	config.set_value("camp", "kills", kills)
	config.save(path())


static func npc_quest_state(quest_id: String) -> String:
	return str(npc_quests.get(quest_id, ""))


static func set_npc_quest(quest_id: String, state: String) -> void:
	npc_quests[quest_id] = state
	save_game()


## NPC bizalma (-100..+100, alapból 0).
static func trust_of(npc_id: String) -> int:
	return int(trust.get(npc_id, 0))


static func change_trust(npc_id: String, delta: int) -> void:
	trust[npc_id] = clampi(trust_of(npc_id) + delta, -100, 100)
	save_game()


## Az NPC-től már megkérdezett témák (opció-azonosítók).
static func asked_topics(npc_id: String) -> Array:
	return asked.get(npc_id, [])


static func mark_asked(npc_id: String, topic: String) -> void:
	var list: Array = asked_topics(npc_id).duplicate()
	if not list.has(topic):
		list.append(topic)
	asked[npc_id] = list
	save_game()


## Új játék: minden tábori haladás törlődik.
static func reset_game() -> void:
	_loaded = true
	camp_gold = 0
	upgrades = {}
	_all_inventories = {}
	stash = []
	quest_progress = {}
	quests_done = []
	trust = {}
	asked = {}
	npc_quests = {}
	kills = {}
	_activate(Characters.DEFAULT)
	save_game()


## Egy megölt szörny a Szörnyek könyvébe (a gyakorló pályán nem számít).
static func add_kill(monster: String) -> void:
	if monster.is_empty() or GameState.tutorial:
		return
	load_game()
	kills[monster] = int(kills.get(monster, 0)) + 1
	save_game()


## Másik karakterre váltás (a kocsmában): a saját tábori felszerelése töltődik be.
static func select_character(id: String) -> void:
	load_game()
	save_game()
	_activate(id)
	save_game()


## A fejlesztések a mentésből. A közös fejlesztések előtti mentésekben karakterenként voltak:
## ilyenkor fejlesztésenként a legmagasabb elért szint marad meg (semmi nem vész el).
static func _load_upgrades(config: ConfigFile) -> Dictionary:
	var result := {}
	var sources: Array = []
	if config.has_section_key("camp", "upgrades_by_character"):
		var by_character: Variant = config.get_value("camp", "upgrades_by_character")
		if by_character is Dictionary:
			sources.append_array(by_character.values())
	if config.has_section_key("camp", "upgrades"):
		sources.append(config.get_value("camp", "upgrades"))
	for source: Variant in sources:
		if source is Dictionary:
			for id: String in source:
				result[id] = maxi(int(result.get(id, 0)), int(source[id]))
	return result


static func _activate(id: String) -> void:
	character = id
	if not _all_inventories.has(id):
		_all_inventories[id] = {}
	camp_inventory = _all_inventories[id]


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
	# Csalt futásból nem kerül arany a táborba.
	if GameState.cheated:
		return 0
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
