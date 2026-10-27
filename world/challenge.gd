class_name Challenge
## A próbatétel: véletlen kazamata a bánya mélyén (a szakadék túloldalán, a régi tárnában egy hatalmas
## lyukba vezető lépcső, lásd Mine). 1-20 emelet hosszú, 1-3 könnyítéssel és 1-3 nehezítéssel (BOONS / BANES;
## egymásnak ellentmondók nem jönnek együtt, és a kettő súlya közel kiegyenlített). A hossz és a módosítók
## adják a nehézséget, abból a jutalmat: a végén egy biztos tárgy (epikus, legendás, a legnehezebbeknél
## ritkán mítikus). Valós időben REROLL_SECONDS-onként (és teljesítés után) új próbatétel jön.
## Szabályok: innen nem lehet felküldeni tárgyat (nincs tárgylift, nincs pihenő a táborban); amit leviszel
## vagy lent kapsz, lent marad; az arany csak győzelemkor jön fel (akkor 100%-a). Az eredménytáblába nem kerül.
## A futás közben GameState.challenge a próbatétel (üres = rendes futás); a hatásokat a mult() / add() /
## flag() adja a szörnyek, a terem, a bolt, a bájital és a játékos kódjának.

const REROLL_SECONDS := 600
const MIN_FLOORS := 1
const MAX_FLOORS := 20
## A könnyítések és nehezítések súlyának legnagyobb megengedett különbsége (a kiegyensúlyozottsághoz).
const MAX_IMBALANCE := 3
## A tárolt próbatétel (Progress.npc_quests): a magja és hogy meddig érvényes (unix idő).
const SEED_FLAG := "challenge_seed"
const UNTIL_FLAG := "challenge_until"

## Hatások: szorzók (enemy_count, enemy_health, enemy_damage, enemy_speed, xp, gold, shop_price, potion_heal,
## player_health, chest_chance, trap_count, boss_health, drop_chance, regen) és összeadandók (start_potions,
## player_damage, regen_add, depth_offset, start_levels), illetve jelzők (darkness).
const BOONS := {
	"sparse": {"name": "Ritkás szörnyek", "text": "25%-kal kevesebb szörny", "weight": 3, "effects": {"enemy_count": 0.75}},
	"wisdom": {"name": "Tapasztalat áldása", "text": "+50% tapasztalat", "weight": 2, "effects": {"xp": 1.5}},
	"gold_rain": {"name": "Aranyeső", "text": "+60% arany", "weight": 1, "effects": {"gold": 1.6}},
	"frail_foes": {"name": "Gyenge szörnyek", "text": "a szörnyeknek 20%-kal kevesebb életük van", "weight": 3,
		"effects": {"enemy_health": 0.8}},
	"blunt_claws": {"name": "Tompa karmok", "text": "a szörnyek 20%-kal kisebbet ütnek", "weight": 3,
		"effects": {"enemy_damage": 0.8}},
	"sluggish": {"name": "Lomha szörnyek", "text": "a szörnyek 15%-kal lassabbak", "weight": 2, "effects": {"enemy_speed": 0.85}},
	"potion_belt": {"name": "Bájitalos öv", "text": "+3 HP-bájital induláskor", "weight": 2, "effects": {"start_potions": 3}},
	"hardy": {"name": "Edzett test", "text": "+30% max élet", "weight": 3, "effects": {"player_health": 1.3}},
	"keen_edge": {"name": "Éles penge", "text": "+20% sebzés", "weight": 3, "effects": {"player_damage": 20}},
	"treasure": {"name": "Kincses termek", "text": "kétszer annyi láda", "weight": 1, "effects": {"chest_chance": 2.0}},
	"bargain": {"name": "Olcsó bolt", "text": "40%-kal olcsóbb bolt", "weight": 1, "effects": {"shop_price": 0.6}},
	"spring": {"name": "Gyógyító forrás", "text": "+1 élet / mp regeneráció", "weight": 2, "effects": {"regen_add": 1.0}},
	"weak_bosses": {"name": "Gyenge főellenségek", "text": "a főellenségeknek 30%-kal kevesebb életük van", "weight": 2,
		"effects": {"boss_health": 0.7}},
	"lucky": {"name": "Szerencsés zsákmány", "text": "háromszor több tárgyat dobnak a szörnyek", "weight": 1,
		"effects": {"drop_chance": 3.0}},
	"head_start": {"name": "Előny", "text": "+2 szinttel indulsz", "weight": 2, "effects": {"start_levels": 2}},
}
const BANES := {
	"hordes": {"name": "Hordák", "text": "40%-kal több szörny", "weight": 3, "effects": {"enemy_count": 1.4}},
	"stubborn": {"name": "Szívós szörnyek", "text": "a szörnyeknek 35%-kal több életük van", "weight": 3,
		"effects": {"enemy_health": 1.35}},
	"bloodthirst": {"name": "Vérszomj", "text": "a szörnyek 25%-kal nagyobbat ütnek", "weight": 3, "effects": {"enemy_damage": 1.25}},
	"swift": {"name": "Fürge szörnyek", "text": "a szörnyek 15%-kal gyorsabbak", "weight": 2, "effects": {"enemy_speed": 1.15}},
	"dull_mind": {"name": "Szűkös tapasztalat", "text": "35%-kal kevesebb tapasztalat", "weight": 2, "effects": {"xp": 0.65}},
	"lean": {"name": "Sovány zsákmány", "text": "fele annyi arany", "weight": 1, "effects": {"gold": 0.5}},
	"greedy": {"name": "Drága bolt", "text": "60%-kal drágább bolt", "weight": 1, "effects": {"shop_price": 1.6}},
	"watered": {"name": "Híg bájitalok", "text": "a HP-bájital fele annyit gyógyít", "weight": 2, "effects": {"potion_heal": 0.5}},
	"brittle": {"name": "Törékeny test", "text": "25%-kal kevesebb max élet", "weight": 3, "effects": {"player_health": 0.75}},
	"blunt_edge": {"name": "Tompa penge", "text": "15%-kal kisebb sebzés", "weight": 3, "effects": {"player_damage": -15}},
	"traps": {"name": "Csapdás folyosók", "text": "kétszer annyi csapda", "weight": 2, "effects": {"trap_count": 2.0}},
	"strong_bosses": {"name": "Erős főellenségek", "text": "a főellenségeknek 40%-kal több életük van", "weight": 2,
		"effects": {"boss_health": 1.4}},
	"from_below": {"name": "Mélyről jöttek", "text": "a szörnyek 3 emelettel erősebbek", "weight": 3,
		"effects": {"depth_offset": 3}},
	"darkness": {"name": "Sötétség", "text": "sötétebb termek, kisebb látótáv", "weight": 2, "effects": {"darkness": 1}},
	"drought": {"name": "Kiszáradás", "text": "nincs élet-regeneráció", "weight": 2, "effects": {"regen": 0.0}},
}
const MULTIPLIERS: Array[String] = ["enemy_count", "enemy_health", "enemy_damage", "enemy_speed", "xp", "gold",
	"shop_price", "potion_heal", "player_health", "chest_chance", "trap_count", "boss_health", "drop_chance", "regen"]


## A mostani próbatétel (a tárolt mag ideje lejárt: újat sorsol). Leírás: lásd generate().
static func current() -> Dictionary:
	var now := int(Time.get_unix_time_from_system())
	if Progress.npc_quest_state(SEED_FLAG).is_empty() or now >= int(Progress.npc_quest_state(UNTIL_FLAG)):
		reroll()
	return generate(int(Progress.npc_quest_state(SEED_FLAG)))


## Hány másodperc múlva jön új próbatétel.
static func seconds_left() -> int:
	return maxi(int(Progress.npc_quest_state(UNTIL_FLAG)) - int(Time.get_unix_time_from_system()), 0)


## Új próbatétel most (teljesítés után, vagy a csalómenüből); az idő is újraindul.
static func reroll() -> void:
	Progress.npc_quests[SEED_FLAG] = str(randi())
	Progress.npc_quests[UNTIL_FLAG] = str(int(Time.get_unix_time_from_system()) + REROLL_SECONDS)
	Progress.save_game()


## A magból a próbatétel: {"seed", "floors", "boons": [id], "banes": [id], "score", "difficulty", "reward",
## "mythic_chance"}. A könnyítések és a nehezítések hatása nem ütközik (ugyanarra a hatásra csak az egyik
## jöhet), és a súlyuk különbsége legfeljebb MAX_IMBALANCE.
static func generate(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var floors := rng.randi_range(MIN_FLOORS, MAX_FLOORS)
	var boons: Array[String] = []
	var banes: Array[String] = []
	for attempt in 200:
		boons = _pick(rng, BOONS, rng.randi_range(1, 3), [])
		var taken := {}
		for id in boons:
			for key: String in BOONS[id]["effects"]:
				taken[key] = true
				# A "Gyógyító forrás" és a "Kiszáradás" sem jöhet együtt.
				if key == "regen_add":
					taken["regen"] = true
		banes = _pick(rng, BANES, rng.randi_range(1, 3), taken.keys())
		if banes.size() >= 1 and absi(_weight(BANES, banes) - _weight(BOONS, boons)) <= MAX_IMBALANCE:
			break
	# A nehézség: a hossz, a módosítók egyenlegével (egy-egy súlypont 8%).
	var balance := _weight(BANES, banes) - _weight(BOONS, boons)
	var score := floors * (1.0 + 0.08 * balance)
	var reward := "epic"
	var mythic := 0.0
	if score >= 7.0:
		reward = "legendary"
	if score >= 14.0:
		mythic = clampf(0.04 + (score - 14.0) * 0.015, 0.04, 0.15)
	return {"seed": seed_value, "floors": floors, "boons": boons, "banes": banes, "score": score,
		"difficulty": _difficulty_name(score), "reward": reward, "mythic_chance": mythic}


static func _pick(rng: RandomNumberGenerator, pool: Dictionary, count: int, blocked: Array) -> Array[String]:
	var ids: Array = pool.keys()
	var result: Array[String] = []
	for i in 40:
		if result.size() >= count:
			break
		var id: String = ids[rng.randi_range(0, ids.size() - 1)]
		if result.has(id):
			continue
		var clash := false
		for key: String in pool[id]["effects"]:
			clash = clash or blocked.has(key)
		if clash:
			continue
		result.append(id)
	return result


static func _weight(pool: Dictionary, ids: Array[String]) -> int:
	var total := 0
	for id in ids:
		total += int(pool[id]["weight"])
	return total


static func _difficulty_name(score: float) -> String:
	if score < 4.0:
		return "Könnyű"
	if score < 8.0:
		return "Közepes"
	if score < 13.0:
		return "Nehéz"
	if score < 18.0:
		return "Nagyon nehéz"
	return "Brutális"


## A jutalom szövege: "legendás tárgy (5% eséllyel mítikus)".
static func reward_text(challenge: Dictionary) -> String:
	var text := "%s tárgy" % Items.RARITIES[challenge["reward"]]["name"].to_lower()
	if float(challenge.get("mythic_chance", 0.0)) > 0.0:
		text += " (%d%% eséllyel mítikus)" % roundi(float(challenge["mythic_chance"]) * 100.0)
	return text


## A jutalom tárgya (győzelemkor): a ritkasága a nehézségből, a statjai a próbatétel hossza szerinti mélységből.
static func roll_reward(challenge: Dictionary) -> Dictionary:
	var rarity: String = challenge["reward"]
	if randf() < float(challenge.get("mythic_chance", 0.0)):
		rarity = "mythic"
	return Items.random_item(rarity, rarity, int(challenge["floors"]))


# ---------------------------------------------------------------- futás közben

static func active() -> bool:
	return not GameState.challenge.is_empty()


static func _effects() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for id: String in GameState.challenge.get("boons", []):
		list.append(BOONS[id]["effects"])
	for id: String in GameState.challenge.get("banes", []):
		list.append(BANES[id]["effects"])
	return list


## Szorzó (1.0, ha nincs próbatétel, vagy egyik módosító sem hat rá).
static func mult(key: String) -> float:
	var value := 1.0
	for effects in _effects():
		value *= float(effects.get(key, 1.0))
	return value


## Összeadandó (0, ha nincs).
static func add(key: String) -> float:
	var value := 0.0
	for effects in _effects():
		value += float(effects.get(key, 0.0))
	return value


static func flag(key: String) -> bool:
	return add(key) > 0.0


## A módosítók egy sorban (a HUD üzenetéhez): "Ritkás szörnyek, Aranyeső · Hordák".
static func summary(challenge: Dictionary) -> String:
	var good: Array[String] = []
	for id: String in challenge.get("boons", []):
		good.append(BOONS[id]["name"])
	var bad: Array[String] = []
	for id: String in challenge.get("banes", []):
		bad.append(BANES[id]["name"])
	return "%s  ·  %s" % [", ".join(good), ", ".join(bad)]
