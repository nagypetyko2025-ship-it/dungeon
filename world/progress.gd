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

## A boszorkány (Holló Margit) test-manipulálása (ui/witch_panel.gd): ugyanazok a statok, mint a kiképzősátorban
## (UPGRADES), de szintenként WITCH_FACTOR-szor annyit adnak, és nincs felső szint (csak a statok saját korlátja, Stats).
## Ár szintenként: [tábori arany, por ritkasága, por db] (WITCH_COSTS), a 8. szinttől mindig WITCH_LATE_COST.
const WITCH_FACTOR := 1.5
const WITCH_COSTS := [[250, "common", 1], [300, "common", 2], [350, "rare", 1], [400, "rare", 2], [450, "epic", 1],
	[500, "epic", 2], [700, "legendary", 1]]
const WITCH_LATE_COST := [1000, "legendary", 3]
## A korlátos statok (Stats.LIMITS felső értéke): ezeket a boszorkány csak addig fejleszti, amíg a karakter
## alapértéke + a kiképzősátor + a boszorkány el nem éri a korlátot (witch_maxed).
const WITCH_CAPPED: Array[String] = ["dodge", "move_speed", "attack_speed", "crit_chance", "attack_range", "defense",
	"multishot", "accuracy"]
## A boszorkány fejlesztései: fejlesztés (UPGRADES kulcs) -> szint (közös, mint az upgrades).
static var witch_levels := {}

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
## Tárgyak könyve (ItemCodex): a valaha megszerzett tárgyak azonosítói (id -> true).
static var seen_items := {}
## Az átvett könyvjutalmak (a Tárgyak könyve fülenkénti jutalmai, az Eredmények könyve): kulcs -> true.
static var rewards_claimed := {}
## A kovács porai (Smithing): ritkaság -> darab (szétszedéssel jön, fejlesztésre megy el).
static var dust := {}
## A legmélyebb emelet, ahova valaha lejutottál (csalás és gyakorló pálya nélkül). Ha egy küldetés egy
## emeletre küld, és már jártál ott, azonnal mondhatod, hogy megvolt (lásd reached_depth).
static var deepest := 0
## Az aktív karakter tábori felszerelése (Inventory.save_data); üres = kezdő felszerelés.
## Leszálláskor magaddal viszed (és innen törlődik). Minden karakternek külön.
static var camp_inventory := {}
## karakter -> tábori felszerelése (az aktívé a fenti camp_inventory-ban is).
static var _all_inventories := {}
static var _loaded := false
## Gyakorlás (GameState.tutorial): a gyakorló pálya és a tábori bemutató tiszta lappal (mint egy új játék) játszik,
## csak a memóriában: semmi nem kerül lemezre (save_game ilyenkor nem ír), és a végén discard_tutorial_changes()
## visszatölti a valódi mentést.
static var _in_tutorial := false


static func has_save() -> bool:
	return FileAccess.file_exists(path())


## Halasztott mentés a gyakori, apró változásokhoz (szörnyölés, mélységrekord): nem ír minden ölésnél a lemezre
## (az a víruskeresővel együtt akasztotta a harcot), hanem legfeljebb SAVE_DELAY másodpercenként egyszer.
## Mielőtt bármi újratölti a mentést, profilt vált, vagy a játék bezárul, a függő változás kiíródik (flush).
const SAVE_DELAY := 1.0
static var _dirty := false


static func save_soon() -> void:
	if GameState.tutorial or _dirty:
		return
	_dirty = true
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		save_game()
		return
	tree.create_timer(SAVE_DELAY, true, false, true).timeout.connect(Progress.flush)
	if not is_instance_valid(_flusher):
		_flusher = SaveFlusher.new()
		_flusher.name = "ProgressSaveFlusher"
		tree.root.add_child.call_deferred(_flusher)


static func flush() -> void:
	if _dirty:
		save_game()


static var _flusher: Node


## Bezáráskor (ablak X, Alt+F4) kiírja a függő mentést.
class SaveFlusher:
	extends Node

	func _notification(what: int) -> void:
		if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
			Progress.flush()


## Betölti a mentést (ha még nem történt meg, vagy `force`).
static func load_game(force := false) -> void:
	if _loaded and not force:
		return
	# Ami még nincs kiírva, előbb kiíródik, különben az újratöltés eldobná.
	flush()
	_loaded = true
	character = Characters.DEFAULT
	_clear()
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
			# Átnevezés: a pokol ura régen "Lucifer, a Démonkirály" volt, most Azazel, a Halálangyal és Démonkirály.
			if kills.has("Lucifer, a Démonkirály"):
				kills["Azazel, a Halálangyal és Démonkirály"] = int(kills.get("Azazel, a Halálangyal és Démonkirály", 0)) + int(kills["Lucifer, a Démonkirály"])
				kills.erase("Lucifer, a Démonkirály")
		var saved_seen: Variant = config.get_value("camp", "seen_items", {})
		if saved_seen is Dictionary:
			seen_items = saved_seen
		var saved_claimed: Variant = config.get_value("camp", "rewards_claimed", {})
		if saved_claimed is Dictionary:
			rewards_claimed = saved_claimed
		var saved_dust: Variant = config.get_value("camp", "dust", {})
		if saved_dust is Dictionary:
			dust = saved_dust
		var saved_witch: Variant = config.get_value("camp", "witch_levels", {})
		if saved_witch is Dictionary:
			witch_levels = saved_witch
		deepest = int(config.get_value("camp", "deepest", -1))
	# Régebbi mentés: az eredménytábla legjobb futásából.
	if deepest < 0:
		deepest = 0
		for run: Dictionary in Records.top():
			deepest = maxi(deepest, int(run.get("depth", 0)))
	_activate(character)


static func save_game() -> void:
	if GameState.tutorial:
		return
	_dirty = false
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
	config.set_value("camp", "seen_items", seen_items)
	config.set_value("camp", "rewards_claimed", rewards_claimed)
	config.set_value("camp", "dust", dust)
	config.set_value("camp", "witch_levels", witch_levels)
	config.set_value("camp", "deepest", deepest)
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
	_clear()
	_activate(Characters.DEFAULT)
	save_game()


## Üres tábori haladás (a karakter marad): nincs arany, fejlesztés, felszerelés, láda, küldetés, bizalom, por...
static func _clear() -> void:
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
	seen_items = {}
	rewards_claimed = {}
	dust = {}
	witch_levels = {}
	deepest = 0


## A gyakorlás kezdete: tiszta lappal, mint egy új játék (a meglévő mentés aranya, fejlesztései, tárgyai nem
## látszanak, és nem is segítenek), csak a memóriában. A végén discard_tutorial_changes() visszatölti a mentést.
static func begin_tutorial() -> void:
	load_game()
	_in_tutorial = true
	_clear()
	_activate(character)


## A gyakorlás vége (a főmenübe lépve mindig): a gyakorlás alatti változások (tábori arany, fejlesztések, láda,
## porok...) eldobódnak, az állapot újra a mentésből jön.
static func discard_tutorial_changes() -> void:
	if not _in_tutorial:
		return
	_in_tutorial = false
	load_game(true)


## Ennyi porod van ebből a ritkaságból (lásd Smithing).
static func dust_of(rarity: String) -> int:
	return int(dust.get(rarity, 0))


## Por hozzáadása (negatívval elvétele); mentődik.
static func add_dust(rarity: String, amount: int) -> void:
	dust[rarity] = maxi(dust_of(rarity) + amount, 0)
	save_game()


## Egy megölt szörny a Szörnyek könyvébe (a gyakorló pályán nem számít).
static func add_kill(monster: String) -> void:
	if monster.is_empty() or GameState.tutorial:
		return
	load_game()
	kills[monster] = int(kills.get(monster, 0)) + 1
	save_soon()


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
	# A próbatételből az arany csak győzelemkor jön fel (lásd Dungeon._challenge_won).
	if Challenge.active():
		return 0
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


## A fejlesztések stat-bónuszai (minden futás elején a játékosra kerülnek): a kiképzősátor és a boszorkány.
static func permanent_bonuses() -> Dictionary:
	var bonuses := {}
	for id: String in UPGRADES:
		var definition: Dictionary = UPGRADES[id]
		var stat: String = definition["stat"]
		bonuses[stat] = bonuses.get(stat, 0.0) + level(id) * float(definition["per_level"]) + witch_bonus(id, witch_level(id))
	return bonuses


static func witch_level(id: String) -> int:
	load_game()
	return int(witch_levels.get(id, 0))


## Ennyit ad összesen `levels` szint a boszorkánytól (a nyíl csak egész lehet: lefelé kerekítve).
static func witch_bonus(id: String, levels: int) -> float:
	var definition: Dictionary = UPGRADES[id]
	var value := levels * float(definition["per_level"]) * WITCH_FACTOR
	return floorf(value) if definition["stat"] == "multishot" else value


## A következő szint ára: [tábori arany, por ritkasága, por db].
static func witch_cost(id: String) -> Array:
	var current := witch_level(id)
	return WITCH_COSTS[current] if current < WITCH_COSTS.size() else WITCH_LATE_COST


## Elérte-e már a korlátját ez a stat (`base`: a karakter alapértéke, tárgyak nélkül).
static func witch_maxed(id: String, base: float) -> bool:
	var definition: Dictionary = UPGRADES[id]
	var stat: String = definition["stat"]
	if not stat in WITCH_CAPPED:
		return false
	var total := base + level(id) * float(definition["per_level"]) + witch_bonus(id, witch_level(id))
	return total >= float(Stats.LIMITS[stat][1]) - 0.001


## Megveszi a boszorkánytól a következő szintet, ha van rá elég tábori arany és por, és a stat még nincs
## a korlátján.
static func witch_buy(id: String, base: float) -> bool:
	if witch_maxed(id, base):
		return false
	var cost := witch_cost(id)
	var gold := int(cost[0])
	var rarity := str(cost[1])
	var amount := int(cost[2])
	if camp_gold < gold or dust_of(rarity) < amount:
		return false
	camp_gold -= gold
	dust[rarity] = dust_of(rarity) - amount
	witch_levels[id] = witch_level(id) + 1
	save_game()
	return true


## Elérted ezt az emeletet (a kazamata hívja): ha mélyebb, mint eddig bármikor, megjegyezzük.
static func reached_depth(depth: int) -> void:
	if depth > deepest:
		deepest = depth
		save_soon()
