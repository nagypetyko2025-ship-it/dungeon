class_name Upgrades
## Szintlépéskor választható kártyák. Mindegyik ad valamit ("gain": stat -> érték), és cserébe elvesz egy
## másik statból ("cost": stat -> érték, pozitív szám = ennyivel kevesebb). A szöveget a statokból rakjuk össze
## (`lines`). Ritkaság (Items.RARITY_ORDER): ez szabja meg, milyen gyakran jön (`RARITY_WEIGHTS`) és a színét.
## A beépítettek (`ALL`) mellé a kártya-szerkesztőben (főmenü, bal felső sarok) készítettek jönnek a
## `CUSTOM_PATH` fájlból (a projektben, így a gitre is felmegy). Az ikonok: `ICON_DIR` (496 CC0 ikon).
## A beépítettek is átírhatók a szerkesztőben: az eltérések az `OVERRIDES_PATH` fájlba kerülnek (id -> kártya).
## "max_picks": egy futásban legfeljebb ennyiszer vehető ki (0 / hiányzik = végtelen; `GameState.card_picks`
## számolja), utána nem is jön.
## Ezen felül szintenként minden stat magától is nő egy kicsit: Stats.LEVEL_GROWTH.

const ICON_DIR := "res://assets/cards/icons/"
const CUSTOM_PATH := "res://data/custom_cards.json"
const OVERRIDES_PATH := "res://data/card_overrides.json"

const ALL: Array[Dictionary] = [
	# Átlagos
	{"id": "iron_fist", "title": "Vasököl", "rarity": "common", "gain": {"damage": 2}, "cost": {"attack_range": 5},
		"icon": "s_buff08"},
	{"id": "hawk_eye", "title": "Íjászszem", "rarity": "common", "gain": {"ranged_damage": 2},
		"cost": {"move_speed": 5}, "icon": "s_bow09"},
	{"id": "bloodlust", "title": "Vérszomj", "rarity": "common", "gain": {"damage_percent": 8},
		"cost": {"max_health": 2}, "icon": "s_sword07"},
	{"id": "thick_skin", "title": "Vastag bőr", "rarity": "common", "gain": {"max_health": 4},
		"cost": {"move_speed": 4}, "icon": "s_holy01"},
	{"id": "herbs", "title": "Gyógyfű", "rarity": "common", "gain": {"health_regen": 0.4},
		"cost": {"damage_percent": 3}, "icon": "s_holy03"},
	{"id": "shadow_step", "title": "Árnyéklépés", "rarity": "common", "gain": {"dodge": 6}, "cost": {"max_health": 1},
		"icon": "s_shadow11"},
	{"id": "wind_rush", "title": "Szélroham", "rarity": "common", "gain": {"move_speed": 12},
		"cost": {"crit_chance": 2}, "icon": "s_wind06"},
	{"id": "blade_dance", "title": "Pengetánc", "rarity": "common", "gain": {"attack_speed": 8},
		"cost": {"damage_percent": 4}, "icon": "s_dagger03"},
	{"id": "eagle_eye", "title": "Sasszem", "rarity": "common", "gain": {"crit_chance": 5},
		"cost": {"attack_speed": 5}, "icon": "s_dagger05"},
	{"id": "shield_wall", "title": "Pajzsfal", "rarity": "common", "gain": {"defense": 3}, "cost": {"move_speed": 6},
		"icon": "s_holy09"},
	{"id": "long_blade", "title": "Hosszú penge", "rarity": "common", "gain": {"attack_range": 8},
		"cost": {"attack_speed": 4}, "icon": "s_ice09"},
	{"id": "mana_spring", "title": "Mágiaforrás", "rarity": "common", "gain": {"elemental_damage": 2},
		"cost": {"max_health": 2}, "icon": "s_magic02"},
	# Ritka
	{"id": "berserker", "title": "Berzerker", "rarity": "rare", "gain": {"damage": 3, "damage_percent": 5},
		"cost": {"health_regen": 0.15}, "icon": "s_buff14"},
	{"id": "stone_skin", "title": "Kőbőr", "rarity": "rare", "gain": {"defense": 5}, "cost": {"attack_speed": 8},
		"icon": "s_earth05"},
	{"id": "giant_blood", "title": "Óriásvér", "rarity": "rare", "gain": {"max_health": 7},
		"cost": {"move_speed": 8}, "icon": "s_holy08"},
	{"id": "hunter_instinct", "title": "Vadászösztön", "rarity": "rare", "gain": {"ranged_damage": 3, "crit_chance": 3},
		"cost": {"max_health": 3}, "icon": "s_bow13"},
	{"id": "snake_reflex", "title": "Kígyóreflex", "rarity": "rare", "gain": {"dodge": 10},
		"cost": {"damage_percent": 5}, "icon": "s_wind05"},
	# Epikus
	{"id": "dragon_heart", "title": "Sárkányszív", "rarity": "epic", "gain": {"max_health": 10, "health_regen": 0.3},
		"cost": {"damage_percent": 10}, "icon": "s_fire06"},
	{"id": "storm_blade", "title": "Viharpenge", "rarity": "epic", "gain": {"attack_speed": 12, "crit_chance": 6},
		"cost": {"max_health": 4}, "icon": "s_thunder02"},
	{"id": "executioner", "title": "Hóhér", "rarity": "epic", "gain": {"damage_percent": 18}, "cost": {"dodge": 4},
		"icon": "s_sword16"},
	{"id": "storm_thorn", "title": "Vihartüske", "rarity": "epic", "gain": {"elemental_damage": 4},
		"cost": {"move_speed": 10}, "icon": "s_thunder03"},
	# Legendás ("needs_bow": csak íjjal; "weight": a saját ritkaságán belül milyen gyakran)
	{"id": "arrow_storm", "title": "Nyílzápor", "rarity": "legendary", "gain": {"multishot": 1},
		"cost": {"damage_percent": 5}, "icon": "s_bow06", "needs_bow": true, "weight": 3.0},
	{"id": "pierce", "title": "Átütés", "rarity": "legendary", "gain": {"pierce": 1, "ranged_damage": 2}, "cost": {},
		"icon": "s_bow11", "needs_bow": true},
	{"id": "titan", "title": "Titánerő", "rarity": "legendary", "gain": {"damage": 6, "attack_range": 10, "max_health": 6},
		"cost": {"move_speed": 8}, "icon": "s_earth07"},
	{"id": "phoenix_feather", "title": "Főnixtoll", "rarity": "legendary",
		"gain": {"max_health": 12, "health_regen": 0.5, "defense": 3}, "cost": {"damage_percent": 5}, "icon": "s_fire08"},
	{"id": "shadow_hunter", "title": "Árnyvadász", "rarity": "legendary",
		"gain": {"crit_chance": 8, "damage_percent": 15, "dodge": 5}, "cost": {"max_health": 4}, "icon": "s_shadow16"},
	{"id": "storm_lord", "title": "Viharúr", "rarity": "legendary",
		"gain": {"attack_speed": 14, "crit_chance": 5, "move_speed": 8}, "cost": {"max_health": 4}, "icon": "s_thunder07"},
	# Mítikus
	{"id": "abyss_blessing", "title": "A Mélység áldása", "rarity": "mythic",
		"gain": {"damage_percent": 25, "max_health": 14, "attack_speed": 12, "health_regen": 0.3},
		"cost": {"move_speed": 8}, "icon": "s_shadow14"},
	{"id": "phantom_blood", "title": "Fantomvér", "rarity": "mythic",
		"gain": {"dodge": 18, "move_speed": 18, "crit_chance": 8, "damage_percent": 10}, "cost": {"max_health": 3},
		"icon": "s_shadow07"},
	# Egyszerű kártyák: kis bónusz, nincs (vagy csak egy apró) hátrányuk, hogy az elején is lehessen erősödni
	# anélkül, hogy minden választás elvenne valamit. Átlagos: tiszta előny.
	{"id": "simple_bowstring", "title": "Feszes húr", "rarity": "common", "gain": {"ranged_damage": 1}, "cost": {},
		"icon": "w_bow03"},
	{"id": "simple_spark", "title": "Szikra", "rarity": "common", "gain": {"elemental_damage": 1}, "cost": {},
		"icon": "s_magic05"},
	{"id": "simple_meal", "title": "Jó falat", "rarity": "common", "gain": {"max_health": 2}, "cost": {},
		"icon": "i_c_meat"},
	{"id": "simple_fresh_air", "title": "Friss levegő", "rarity": "common", "gain": {"health_regen": 0.1}, "cost": {},
		"icon": "i_leaf"},
	{"id": "simple_vest", "title": "Bőrmellény", "rarity": "common", "gain": {"defense": 1}, "cost": {},
		"icon": "a_clothing01"},
	{"id": "simple_light_feet", "title": "Könnyű láb", "rarity": "common", "gain": {"dodge": 2}, "cost": {},
		"icon": "a_shoes02"},
	{"id": "simple_quick_hands", "title": "Gyors kéz", "rarity": "common", "gain": {"attack_speed": 3}, "cost": {},
		"icon": "w_fist001"},
	{"id": "simple_sharp_eye", "title": "Éles szem", "rarity": "common", "gain": {"crit_chance": 2}, "cost": {},
		"icon": "i_eye"},
	{"id": "simple_long_grip", "title": "Hosszabb nyél", "rarity": "common", "gain": {"attack_range": 3}, "cost": {},
		"icon": "w_spear002"},
	{"id": "simple_clover", "title": "Szerencse", "rarity": "common", "gain": {"crit_chance": 1, "dodge": 1}, "cost": {},
		"icon": "i_clover"},
	# Átlagos, kicsit több, apró hátránnyal.
	{"id": "simple_hammer", "title": "Kovácskalapács", "rarity": "common", "gain": {"damage": 2},
		"cost": {"attack_speed": 2}, "icon": "w_mace002"},
	{"id": "simple_archer_glove", "title": "Íjászkesztyű", "rarity": "common", "gain": {"ranged_damage": 2},
		"cost": {"move_speed": 2}, "icon": "s_bow03"},
	{"id": "simple_rune", "title": "Rúnakő", "rarity": "common", "gain": {"elemental_damage": 2},
		"cost": {"move_speed": 2}, "icon": "i_crystal01"},
	{"id": "simple_feast", "title": "Kiadós vacsora", "rarity": "common", "gain": {"max_health": 4},
		"cost": {"move_speed": 2}, "icon": "i_c_pie"},
	{"id": "simple_tea", "title": "Gyógytea", "rarity": "common", "gain": {"health_regen": 0.2},
		"cost": {"attack_speed": 2}, "icon": "p_green02"},
	# Ritka: két kis bónusz, hátrány nélkül.
	{"id": "simple_wanderer", "title": "Vándor szerencséje", "rarity": "rare", "gain": {"crit_chance": 2, "dodge": 2},
		"cost": {}, "icon": "i_rabbitpaw"},
	{"id": "simple_swordplay", "title": "Kardforgató", "rarity": "rare", "gain": {"damage": 1, "attack_speed": 3},
		"cost": {}, "icon": "w_sword003"},
	{"id": "simple_marksman", "title": "Céllövő", "rarity": "rare", "gain": {"ranged_damage": 1, "crit_chance": 2},
		"cost": {}, "icon": "w_bow08"},
	{"id": "simple_focus", "title": "Mágusfókusz", "rarity": "rare", "gain": {"elemental_damage": 1, "crit_chance": 2},
		"cost": {}, "icon": "w_staff02"},
	{"id": "simple_endurance", "title": "Kitartás", "rarity": "rare", "gain": {"max_health": 3, "health_regen": 0.1},
		"cost": {}, "icon": "p_red02"},
	{"id": "simple_chainmail", "title": "Láncing", "rarity": "rare", "gain": {"defense": 2, "max_health": 2},
		"cost": {}, "icon": "a_armour02"},
	{"id": "simple_wind_runner", "title": "Szélfutó", "rarity": "rare", "gain": {"move_speed": 4, "dodge": 2},
		"cost": {}, "icon": "s_wind02"},
	{"id": "simple_momentum", "title": "Lendület", "rarity": "rare", "gain": {"damage_percent": 4, "attack_speed": 2},
		"cost": {}, "icon": "s_buff06"},
	# Epikus: három kis bónusz, hátrány nélkül (gyengébb a hátrányos epikusoknál).
	{"id": "simple_brave_heart", "title": "Hősi szív", "rarity": "epic",
		"gain": {"max_health": 5, "defense": 2, "health_regen": 0.1}, "cost": {}, "icon": "s_holy05"},
	{"id": "simple_weapon_master", "title": "Fegyvermester", "rarity": "epic", "gain": {"damage": 2, "damage_percent": 4},
		"cost": {}, "icon": "w_gold_sword"},
	{"id": "simple_falcon_eye", "title": "Sólyomszem", "rarity": "epic", "gain": {"ranged_damage": 2, "crit_chance": 3},
		"cost": {}, "icon": "i_feather01"},
	{"id": "simple_arcane", "title": "Arkán tudás", "rarity": "epic", "gain": {"elemental_damage": 2, "damage_percent": 4},
		"cost": {}, "icon": "w_book03"},
]

## A ritkaságok súlya: egy kártyahelyre előbb ritkaságot sorsolunk ezek szerint (mindig mind az öt közül), aztán
## azon belül egy kártyát. Ha a kisorsolt ritkaságból nincs választható kártya, egy közönségesebb jön (nem ritkább:
## régen a hiányzó ritkaság esélye a többi közt oszlott el, így pl. a varázslónál a legendás helyett mítikus jött).
## Egy szintlépésen legfeljebb egy legendás vagy mítikus (`HIGH_RARITIES`). Szintlépésenként (3 hely) kb.:
## legendás 4,5%, mítikus 1,2% (régen 9-13% és 4-5,5%).
const RARITY_WEIGHTS := {"common": 60.0, "rare": 27.0, "epic": 11.0, "legendary": 1.6, "mythic": 0.4}
const HIGH_RARITIES: Array[String] = ["legendary", "mythic"]
## A játék elején (ez alatti karakterszinten) csak átlagos kártya jön (ha abból nincs választható, a szokásos sorsolás).
const COMMON_ONLY_BELOW := 10

## A kártyákon választható statok: [név, mértékegység ("%" vagy ""), tizedes jegyek]. A sorrend a szerkesztőé.
const STAT_INFO := {
	"damage": ["közelharci sebzés", "", 0],
	"ranged_damage": ["távolsági sebzés", "", 0],
	"elemental_damage": ["elemi sebzés", "", 0],
	"damage_percent": ["sebzés", "%", 0],
	"max_health": ["max élet", "", 0],
	"health_regen": ["élet / mp", "", 2],
	"defense": ["védelem", "%", 0],
	"dodge": ["kikerülés", "%", 0],
	"move_speed": ["mozgási sebesség", "%", 0],
	"attack_speed": ["ütési sebesség", "%", 0],
	"crit_chance": ["kritikus esély", "%", 0],
	"attack_range": ["hatótáv", "%", 0],
	"multishot": ["nyíl lövésenként", "", 0],
	"pierce": ["átütés (szörnyön át)", "", 0],
}

## A statok saját jele (Tab-statok, tábori fejlesztések): ugyanaz marad, mint a régi kártyákon.
const STAT_ICONS := {
	"damage": Rect2(339, 98, 10, 29),
	"ranged_damage": "res://assets/ui/icon_ranged.png",
	"damage_percent": Rect2(291, 137, 10, 22),
	"max_health": Rect2(289, 370, 13, 12),
	"health_regen": Rect2(288, 336, 16, 16),
	"dodge": "res://assets/ui/icon_dodge.png",
	"move_speed": "res://assets/ui/icon_boot.png",
	"attack_speed": Rect2(293, 66, 6, 29),
	"crit_chance": "res://assets/ui/icon_crit.png",
	"defense": "res://assets/ui/icon_defense.png",
	"accuracy": "res://assets/ui/icon_accuracy.png",
	"elemental_damage": "res://assets/ui/spell_bolt.png",
	"attack_range": "res://assets/ui/icon_range.png",
	"multishot": "res://assets/ui/icon_multishot.png",
	"pierce": "res://assets/ui/icon_pierce.png",
}

## Melyik stat meddig fejleszthető (ami elérte, az azt adó kártya nem kerül fel választásnak).
const LIMITS := {
	"dodge": Stats.MAX_DODGE,
	"move_speed": Stats.MAX_MOVE_SPEED,
	"attack_speed": Stats.MAX_ATTACK_SPEED,
	"crit_chance": Stats.MAX_CRIT,
	"attack_range": Stats.MAX_RANGE,
	"defense": Stats.MAX_DEFENSE,
	"multishot": Stats.MAX_MULTISHOT,
	"pierce": Stats.MAX_PIERCE,
	"accuracy": Stats.MAX_ACCURACY,
}

## A szerkesztőben készült kártyák (betöltve; `reload_custom` frissíti).
static var _custom: Array[Dictionary] = []
static var _custom_loaded := false
## A beépített kártyák szerkesztőben átírt változatai: id -> kártya.
static var _overrides := {}


## Minden kártya: a beépítettek (az átírásokkal) és a szerkesztőben készültek.
static func cards() -> Array[Dictionary]:
	var result := builtin_cards()
	result.append_array(custom_cards())
	return result


## A beépített kártyák, a szerkesztőben átírtak az átírt alakjukban (a "weight" az eredetié marad).
static func builtin_cards() -> Array[Dictionary]:
	if not _custom_loaded:
		reload_custom()
	var result: Array[Dictionary] = []
	for card in ALL:
		if not _overrides.has(card["id"]):
			result.append(card)
			continue
		var changed: Dictionary = (_overrides[card["id"]] as Dictionary).duplicate(true)
		changed.erase("custom")
		changed["id"] = card["id"]
		changed["changed"] = true
		if card.has("weight"):
			changed["weight"] = card["weight"]
		result.append(changed)
	return result


static func overrides() -> Dictionary:
	if not _custom_loaded:
		reload_custom()
	return _overrides


## A szerkesztő menti: a beépítettek átírásai (id -> kártya) az `OVERRIDES_PATH` fájlba. Igaz, ha sikerült.
static func save_overrides(changed: Dictionary) -> bool:
	if not _write_json(OVERRIDES_PATH, changed):
		return false
	reload_custom()
	return true


static func custom_cards() -> Array[Dictionary]:
	if not _custom_loaded:
		reload_custom()
	return _custom


static func reload_custom() -> void:
	_custom_loaded = true
	_custom.clear()
	_overrides.clear()
	if FileAccess.file_exists(OVERRIDES_PATH):
		var changed: Variant = JSON.parse_string(FileAccess.get_file_as_string(OVERRIDES_PATH))
		if changed is Dictionary:
			for id: Variant in changed:
				if changed[id] is Dictionary and _valid(changed[id]):
					_overrides[String(id)] = _clean(changed[id])
	if not FileAccess.file_exists(CUSTOM_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CUSTOM_PATH))
	if not parsed is Array:
		return
	for entry: Variant in parsed:
		if entry is Dictionary and _valid(entry):
			_custom.append(_clean(entry))


## A szerkesztő menti: a teljes saját lista a projekt `CUSTOM_PATH` fájljába. Igaz, ha sikerült.
static func save_custom(list: Array[Dictionary]) -> bool:
	if not _write_json(CUSTOM_PATH, list):
		return false
	reload_custom()
	return true


static func _write_json(path: String, data: Variant) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


static func _valid(entry: Dictionary) -> bool:
	return entry.get("gain") is Dictionary and not (entry["gain"] as Dictionary).is_empty() \
		and String(entry.get("title", "")) != ""


## A JSON számai float-ok: az egész értékű statokat (és a ritkaságot, ikont) rendbe tesszük.
static func _clean(entry: Dictionary) -> Dictionary:
	var result := {"id": String(entry.get("id", "")), "title": String(entry["title"]), "custom": true,
		"rarity": String(entry.get("rarity", "common")), "icon": String(entry.get("icon", "s_buff01")),
		"max_picks": maxi(int(entry.get("max_picks", 0)), 0)}
	if not result["rarity"] in RARITY_WEIGHTS:
		result["rarity"] = "common"
	for key: String in ["gain", "cost"]:
		var stats := {}
		var source: Variant = entry.get(key, {})
		if source is Dictionary:
			for stat: Variant in source:
				if STAT_INFO.has(stat) and float(source[stat]) > 0.0:
					stats[String(stat)] = float(source[stat])
		result[key] = stats
	if (result["gain"] as Dictionary).has("multishot") or (result["gain"] as Dictionary).has("pierce"):
		result["needs_bow"] = true
	return result


## `count` darab különböző kártya: kártyahelyenként ritkaság (RARITY_WEIGHTS), azon belül egy kártya ("weight").
## Ami nem választható (max stat, nem elég a levonandó stat, más karakteré), kimarad.
## `has_bow`: íjjal (vagy íjászként) a csak íjas kártyák (Nyílzápor, Átütés) is jöhetnek.
static func roll(stats: Stats, count: int, has_bow := false, level := 0) -> Array[Dictionary]:
	# `level`: a szint, amire lépett (0 = nem számít); COMMON_ONLY_BELOW alatt csak átlagos kártya.
	var only_common := level > 0 and level < COMMON_ONLY_BELOW
	var by_rarity := {}
	for card in cards():
		# Íjjal a közelharci sebzés, íj nélkül a távolsági sebzés kártyája nem jön (annak semmi haszna nem lenne).
		var gain: Dictionary = card["gain"]
		if (has_bow and gain.has("damage")) or (not has_bow and gain.has("ranged_damage")):
			continue
		if _available(stats, card) and (has_bow or not card.get("needs_bow", false)):
			var rarity: String = card["rarity"]
			if not by_rarity.has(rarity):
				by_rarity[rarity] = [] as Array[Dictionary]
			(by_rarity[rarity] as Array[Dictionary]).append(card)
	var options: Array[Dictionary] = []
	var high_taken := false
	while options.size() < count:
		var rarity := "common" if only_common and by_rarity.has("common") else _pick_rarity(by_rarity, high_taken)
		if rarity.is_empty():
			break
		high_taken = high_taken or rarity in HIGH_RARITIES
		var pool: Array[Dictionary] = by_rarity[rarity]
		var card := _pick_weighted(pool)
		pool.erase(card)
		if pool.is_empty():
			by_rarity.erase(rarity)
		options.append(_with_character_bonus(card))
	return options


## Egy kártyahely ritkasága mind az öt közül sorsolva; ha abból nincs választható kártya (`by_rarity`), a következő
## közönségesebb, és csak ha az sincs, a ritkább. `no_high`: legendás / mítikus már nem jöhet. "" = nincs semmi.
static func _pick_rarity(by_rarity: Dictionary, no_high := false) -> String:
	var allowed: Array[String] = []
	for rarity in Items.RARITY_ORDER:
		if RARITY_WEIGHTS.has(rarity) and not (no_high and rarity in HIGH_RARITIES):
			allowed.append(rarity)
	var total := 0.0
	for rarity in allowed:
		total += float(RARITY_WEIGHTS[rarity])
	var ticket := randf() * total
	var chosen := allowed.size() - 1
	for i in allowed.size():
		ticket -= float(RARITY_WEIGHTS[allowed[i]])
		if ticket <= 0.0:
			chosen = i
			break
	for i in range(chosen, -1, -1):
		if by_rarity.has(allowed[i]):
			return allowed[i]
	for i in range(chosen + 1, allowed.size()):
		if by_rarity.has(allowed[i]):
			return allowed[i]
	return ""


## Egy a listából a "weight" szerint súlyozva.
static func _pick_weighted(list: Array[Dictionary]) -> Dictionary:
	var total := 0.0
	for card in list:
		total += float(card.get("weight", 1.0))
	var ticket := randf() * total
	for card in list:
		ticket -= float(card.get("weight", 1.0))
		if ticket <= 0.0:
			return card
	return list[-1]


## A karakter saját kártya-bónusza ("card_bonus": stat -> szorzó-többlet, pl. Gáspárnál a
## kikerülés +25%): a kártya másolata nagyobb nyereséggel, és egy megjegyzéssel.
static func _with_character_bonus(card: Dictionary) -> Dictionary:
	var character := Characters.data(Progress.character)
	var bonuses: Dictionary = character.get("card_bonus", {})
	var gain: Dictionary = card["gain"]
	var result := card
	var copied := false
	for stat: String in gain:
		if not bonuses.has(stat):
			continue
		var extra: float = bonuses[stat]
		if not copied:
			result = card.duplicate(true)
			copied = true
		result["gain"][stat] = float(gain[stat]) * (1.0 + extra)
		result["bonus_note"] = "%s: +%d%% (csak neki)" % [character["name"], roundi(extra * 100)]
	return result


## Ebben a futásban még hányszor vehető ki (-1: végtelen).
static func picks_left(card: Dictionary) -> int:
	var limit := int(card.get("max_picks", 0))
	if limit <= 0:
		return -1
	return maxi(limit - picks_taken(card), 0)


## Ebben a futásban hányszor vetted már ki.
static func picks_taken(card: Dictionary) -> int:
	return int(GameState.card_picks.get(card.get("id", ""), 0))


static func _available(stats: Stats, card: Dictionary) -> bool:
	if picks_left(card) == 0:
		return false
	var gain: Dictionary = card["gain"]
	var cost: Dictionary = card.get("cost", {})
	var spells: bool = Characters.data(Progress.character).get("spells", false)
	# Az elemi sebzés csak a varázslónak kell, a közelharci / távolsági sebzés neki nem.
	if gain.has("elemental_damage") and not spells:
		return false
	if spells and (gain.has("damage") or gain.has("ranged_damage")):
		return false
	for stat: String in gain:
		if stat == "accuracy" and not Stats.ACCURACY_ENABLED:
			return false
		if LIMITS.has(stat) and stats.get(stat) >= LIMITS[stat]:
			return false
	# A levonás nem viheti a statot a legkisebb értéke alá (amiből nincs elég, az a kártya nem jön).
	for stat: String in cost:
		if stats.get_base(stat) - float(cost[stat]) < float(Stats.LIMITS[stat][0]):
			return false
	return true


static func apply(stats: Stats, card: Dictionary) -> void:
	var id: String = card.get("id", "")
	if not id.is_empty():
		GameState.card_picks[id] = int(GameState.card_picks.get(id, 0)) + 1
	var gain: Dictionary = card["gain"]
	var cost: Dictionary = card.get("cost", {})
	for stat: String in gain:
		stats.add_base(stat, float(gain[stat]))
	for stat: String in cost:
		stats.add_base(stat, -float(cost[stat]))


## A kártya sorai: [szöveg, nyereség-e] (pl. ["+4 max élet", true], ["−4% mozgási sebesség", false]).
static func lines(card: Dictionary) -> Array:
	var result := []
	for key: String in ["gain", "cost"]:
		var stats: Dictionary = card.get(key, {})
		for stat: String in stats:
			result.append([stat_text(stat, float(stats[stat]), key == "gain"), key == "gain"])
	return result


static func stat_text(stat: String, amount: float, positive: bool) -> String:
	var info: Array = STAT_INFO.get(stat, [stat, "", 0])
	var shown := str(snappedf(amount, 0.01)) if int(info[2]) > 0 or amount != roundf(amount) else str(roundi(amount))
	return "%s%s%s %s" % ["+" if positive else "−", shown, info[1], info[0]]


static func rarity_color(card: Dictionary) -> Color:
	return Items.RARITIES[card.get("rarity", "common")]["color"]


static func rarity_name(card: Dictionary) -> String:
	return Items.RARITIES[card.get("rarity", "common")]["name"]


static func icon(card: Dictionary) -> Texture2D:
	if card.has("icon"):
		return icon_texture(card["icon"])
	if card.has("icon_path"):
		return load(card["icon_path"])
	if card.has("region"):
		return SpriteSheet.region(card["region"])
	return null


static func icon_texture(name: String) -> Texture2D:
	var path := ICON_DIR + name + ".png"
	return load(path) if ResourceLoader.exists(path) else null


## A választható ikonok nevei (kiterjesztés nélkül, ábécérendben).
static func icon_names() -> PackedStringArray:
	var names := PackedStringArray()
	for file in ResourceLoader.list_directory(ICON_DIR):
		if file.ends_with(".png"):
			names.append(file.get_basename())
	names.sort()
	return names


## Egy stat saját jele (Tab-statok, tábori fejlesztések).
static func stat_icon(stat: String) -> Texture2D:
	var source: Variant = STAT_ICONS.get(stat)
	if source is Rect2:
		return SpriteSheet.region(source)
	if source is String:
		return load(source)
	return null
