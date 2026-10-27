class_name Smithing
## A tábori kovács (E-vel nála, lásd SmithPanel): tárgyfejlesztés és -szétszedés porokért.
## Minden ritkaságnak saját pora van (Progress.dust).
##   Fejlesztés: a tárgy a következő ritkaságba lép (ugyanaz a tárgy, annak a ritkaságnak a változata,
##     lásd Items.variant), ha van UPGRADE_COST pora a KÖVETKEZŐ ritkaságból. UPGRADE_CHANCE eséllyel
##     sikerül; ha nem, a por elvész, a tárgy marad. A statok ugyanannyira jók maradnak a tartományukban
##     (a ritkasággal együtt nőnek), az új extra stat a tartományából jön, a mélységi bónusz megmarad.
##   Szétszedés: a tárgy elvész, és a SAJÁT ritkaságának porából 1-et (DOUBLE_DUST_CHANCE eséllyel 2-t) adja.
##   Mítikus tárgy: nem lép feljebb, hanem tovább fejleszthető (legfeljebb MYTHIC_MAX_UPGRADES-szor)
##     MYTHIC_UPGRADE_COST mítikus porért, ugyanazzal az eséllyel: a statjai és az alapsebzése az eredeti
##     MYTHIC_STAT_STEP-részével nőnek fejlesztésenként, a ritkasága marad, a neve mögé kiírja, hányszor fejlesztették
##     ("Véróra (kétszer fejlesztett)"; "upgrades": a szám, "base_name": az eredeti név).

const UPGRADE_COST := 4
const UPGRADE_CHANCE := 0.65
const DOUBLE_DUST_CHANCE := 0.3
const MYTHIC_UPGRADE_COST := 3
const MYTHIC_MAX_UPGRADES := 5
const MYTHIC_STAT_STEP := 0.1
const TIMES: Array[String] = ["", "egyszer", "kétszer", "háromszor", "négyszer", "ötször"]
const DUST_ICONS := {
	"common": preload("res://assets/ui/dust_common.png"),
	"rare": preload("res://assets/ui/dust_rare.png"),
	"epic": preload("res://assets/ui/dust_epic.png"),
	"legendary": preload("res://assets/ui/dust_legendary.png"),
	"mythic": preload("res://assets/ui/dust_mythic.png"),
}


## Ennyi porod van ebből a ritkaságból (a gyakorló pályán a gyakorló porok, a valódiak nem változnak).
static func dust_of(rarity: String) -> int:
	if GameState.tutorial:
		return int(GameState.tutorial_dust.get(rarity, 0))
	return Progress.dust_of(rarity)


static func add_dust(rarity: String, amount: int) -> void:
	if GameState.tutorial:
		GameState.tutorial_dust[rarity] = maxi(dust_of(rarity) + amount, 0)
	else:
		Progress.add_dust(rarity, amount)


## A fejlesztés esélye (a gyakorló pályán mindig sikerül, hogy biztosan meglásd).
static func upgrade_chance() -> float:
	return 1.0 if GameState.tutorial else UPGRADE_CHANCE


## Pl. "Ritka por".
static func dust_name(rarity: String) -> String:
	return "%s por" % Items.RARITIES[rarity]["name"]


## A következő ritkaság ("" ha már mítikus).
static func next_rarity(rarity: String) -> String:
	var index := Items.RARITY_ORDER.find(rarity)
	return Items.RARITY_ORDER[index + 1] if index >= 0 and index + 1 < Items.RARITY_ORDER.size() else ""


## A fejlesztéshez kellő por ritkasága: a következő ritkaságé (mítikusnál maga a mítikus por).
static func upgrade_dust(item: Dictionary) -> String:
	var rarity: String = item.get("rarity", "common")
	return rarity if rarity == "mythic" else next_rarity(rarity)


static func upgrade_cost(item: Dictionary) -> int:
	return MYTHIC_UPGRADE_COST if item.get("rarity", "") == "mythic" else UPGRADE_COST


## Hányszor fejlesztették mítikusként (0..MYTHIC_MAX_UPGRADES).
static func upgrade_count(item: Dictionary) -> int:
	return int(item.get("upgrades", 0))


## Miért nem fejleszthető ("" = fejleszthető; a porokat nem nézi).
static func upgrade_block(item: Dictionary) -> String:
	if item.get("quest", false) or item.get("story", false):
		return "Ezt a tárgyat a kovács nem fejlesztheti."
	var definition: Dictionary = Items.DEFINITIONS.get(item.get("id", ""), {})
	if definition.is_empty() or definition.get("unique", false):
		return "Ez egyedi tárgy: nem fejleszthető."
	if item.get("rarity", "common") == "mythic":
		if upgrade_count(item) >= MYTHIC_MAX_UPGRADES:
			return "Már %s fejlesztett: ennél jobb nem lehet." % TIMES[MYTHIC_MAX_UPGRADES]
		return ""
	if next_rarity(item.get("rarity", "common")).is_empty():
		return "Ennél jobb nem lehet."
	return ""


## Miért nem szedhető szét ("" = szétszedhető).
static func dismantle_block(item: Dictionary) -> String:
	if not Items.can_sell(item):
		return "Küldetés- vagy sztoritárgy: nem szedheted szét."
	return ""


## Szétszedéskor ennyi port ad (1, vagy DOUBLE_DUST_CHANCE eséllyel 2).
static func roll_dust() -> int:
	return 2 if randf() < DOUBLE_DUST_CHANCE else 1


## Mítikus fejlesztés (új példány): minden fejlesztés az EREDETI pozitív statok és alapsebzés MYTHIC_STAT_STEP-részét
## adja hozzá (5 fejlesztés után másfélszeres; kerekítve, de sosem csökken); a hátrányok és a lövésenkénti nyílszám
## maradnak. Az eredeti értékek az "unupgraded" kulcsban. A ritkaság marad, a név mögé kerül a szám.
static func improved(item: Dictionary) -> Dictionary:
	var result := item.duplicate(true)
	var count := upgrade_count(item) + 1
	result["upgrades"] = count
	var base_name: String = item.get("base_name", item["name"])
	result["base_name"] = base_name
	result["name"] = "%s (%s fejlesztett)" % [base_name, TIMES[count]]
	var original: Dictionary = item.get("unupgraded", {"stats": item.get("stats", {}).duplicate(),
		"base_damage": item.get("base_damage", 0), "price": item.get("price", 0)})
	result["unupgraded"] = original
	var factor := 1.0 + MYTHIC_STAT_STEP * count
	var stats: Dictionary = result.get("stats", {})
	for stat: String in original["stats"]:
		var value: float = original["stats"][stat]
		if value <= 0.0 or stat == "multishot" or not stats.has(stat):
			continue
		var grown := snappedf(value * factor, 0.1) if stat == "health_regen" else float(roundi(value * factor))
		stats[stat] = maxf(grown, float(stats[stat]))
	result["stats"] = stats
	if item.has("base_damage"):
		result["base_damage"] = maxi(roundi(int(original["base_damage"]) * factor), int(item["base_damage"]))
	result["price"] = roundi(float(original["price"]) * (1.0 + MYTHIC_STAT_STEP * 1.5 * count))
	return result


## A tárgy következő ritkaságú változata (új példány; az eredetit nem módosítja).
static func upgraded(item: Dictionary) -> Dictionary:
	var id: String = item["id"]
	var rarity: String = item.get("rarity", "common")
	var next := next_rarity(rarity)
	var old_definition := Items.variant(id, rarity)
	var new_definition := Items.variant(id, next)
	var result := item.duplicate(true)
	result["rarity"] = next
	result["name"] = new_definition["name"]
	var floors := maxi(int(item.get("depth", 1)) - 1, 0)
	var stat_factor := 1.0 + Items.STAT_PER_FLOOR * floors
	var old_stats: Dictionary = item.get("stats", {})
	var stats := {}
	for stat: String in new_definition["stats"]:
		var new_range: Array = new_definition["stats"][stat]
		var quality := randf()
		var old_value := 0.0
		var had: bool = old_stats.has(stat) and old_definition["stats"].has(stat)
		if had:
			old_value = old_stats[stat]
			var raw := old_value / stat_factor if old_value > 0.0 else old_value
			var old_range: Array = old_definition["stats"][stat]
			quality = 0.5 if is_equal_approx(old_range[0], old_range[1]) \
				else clampf(inverse_lerp(old_range[0], old_range[1], raw), 0.0, 1.0)
		var value := lerpf(new_range[0], new_range[1], quality)
		if value > 0.0:
			value *= stat_factor
		value = snappedf(value, 0.1) if stat == "health_regen" else float(roundi(value))
		# Ami eddig is megvolt és a ritkasággal nő, annak tényleg nőnie kell (legalább egy lépést).
		if had and new_range[1] > old_definition["stats"][stat][1] and old_value > 0.0:
			value = maxf(value, old_value + (0.1 if stat == "health_regen" else 1.0))
		stats[stat] = value
	# Amit a tárgy a definíción felül kapott (ha volt ilyen), megmarad.
	for stat: String in old_stats:
		if not stats.has(stat):
			stats[stat] = old_stats[stat]
	result["stats"] = stats
	if item.has("base_damage") and new_definition.has("base"):
		var old_base: Array = old_definition["base"]
		var new_base: Array = new_definition["base"]
		var base_factor := 1.0 + Items.BASE_PER_FLOOR * floors
		var raw_base := float(item["base_damage"]) / base_factor
		var quality := 0.5 if old_base[0] == old_base[1] \
			else clampf(inverse_lerp(old_base[0], old_base[1], raw_base), 0.0, 1.0)
		var damage := roundi(lerpf(new_base[0], new_base[1], quality) * base_factor)
		result["base_damage"] = maxi(damage, int(item["base_damage"]) + 1)
		result["scaling"] = new_definition["scaling"]
		result["crit_multiplier"] = new_definition["crit"]
	# Az ár a ritkaságok árával arányosan nő.
	var old_price: Array = Items.RARITIES[rarity]["price"]
	var new_price: Array = Items.RARITIES[next]["price"]
	result["price"] = roundi(float(item.get("price", 0)) * (new_price[0] + new_price[1]) / float(old_price[0] + old_price[1]))
	return result
