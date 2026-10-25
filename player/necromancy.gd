class_name Necromancy
## Vendel (a csontváz sírásó) idézésének fejlesztései: minden LEVEL_EVERY. szintlépéskor a stat-kártyák
## helyett ezek közül választ (lásd LevelUp; ha több a lehetőség, CARD_COUNT véletlenül, újradobható).
## A csontvázak statjai NEM nőnek maguktól (sem a szinttel, sem Vendel sebzésével): csak ezekkel.
## A futáshoz tartoznak (GameState.necromancy, a félbehagyott futással együtt mentődnek):
##   count     +1 csontváz lehet egyszerre — minden fajta együtt számít (alapból BASE_MAX, legfeljebb MAX_MAX)
##   life      +LIFE_STEP mp élettartam (alapból BASE_LIFE, legfeljebb MAX_LIFE)
##   damage    +1 sebzés minden csontváznak (korlát nélkül)
##   power     csontváz-erősítés: +POWER_DAMAGE sebzés, +1 kibírt találat, gyorsabb ütés/lövés (MAX_POWER-ig)
##   cooldown  gyors idézés: minden idézés COOLDOWN_STEP-szer rövidebb töltésű (MAX_COOLDOWN-ig)
##   archers   másodlagos idézés: ARCHER_COUNT íjász csontváz
##   giant     másodlagos idézés: egy óriás csontváz — erősebb, de lassabb, és ritkábban idézhető
## A másodlagos idézés (jobb klikk) a kettő közül az egyik: amelyiket választja, a másik már nem jön.
## Az idézések: Player._summon (bal klikk), _summon_archers / _summon_giant (jobb klikk).

const LEVEL_EVERY := 5
## Ennyi kártyát mutatunk egyszerre (a többi újradobással jöhet).
const CARD_COUNT := 4
const BASE_MAX := 6
const MAX_MAX := 12
const BASE_LIFE := 18.0
const LIFE_STEP := 2.0
const MAX_LIFE := 60.0
const ARCHER_COUNT := 3
## A csontvázak alapjai (a szinttel nem nőnek): sebzés, és hány találatot bírnak ki.
const BASE_DAMAGE := 3
const BASE_HITS := 4
const ARCHER_HITS := 3
## Az óriás csontváz: ennyiszer erősebb és ennyiszer többet bír, de ennyiszer lassabb.
const GIANT_DAMAGE := 3.0
const GIANT_HITS := 3
const GIANT_SPEED := 0.7
## Csontváz-erősítés szintenként.
const POWER_DAMAGE := 0.2
const POWER_HITS := 1
const POWER_ATTACK_SPEED := 0.08
const MAX_POWER := 10
## Gyors idézés szintenként.
const COOLDOWN_STEP := 0.88
const MAX_COOLDOWN := 5
## A kártyák ikonjai.
const SKELETON_REGION := Rect2(368, 88, 16, 16)
const LIFE_ICON := "res://assets/items/trinket_clock.png"
const DAMAGE_ICON := "res://assets/items/dagger_bone.png"
const POWER_ICON := "res://assets/items/amulet_bone.png"
const COOLDOWN_ICON := "res://assets/items/trinket_lantern.png"
const ARCHER_ICON := "res://assets/items/bow_old.png"
const GIANT_ICON := "res://assets/items/mace_bone.png"


static func level(key: String) -> int:
	return int(GameState.necromancy.get(key, 0))


## Ennyi csontváza lehet egyszerre (sima, íjász és óriás együtt).
static func max_minions() -> int:
	return mini(BASE_MAX + level("count"), MAX_MAX)


## Ennyi mp-ig él egy csontváz.
static func lifetime() -> float:
	return minf(BASE_LIFE + LIFE_STEP * level("life"), MAX_LIFE)


## Ennyivel többet üt minden csontváz (az "Éles csontok" fejlesztésből).
static func bonus_damage() -> int:
	return level("damage")


static func power() -> int:
	return mini(level("power"), MAX_POWER)


## Egy csontváz sebzése ("skeleton" / "archer" / "giant").
static func damage(kind: String) -> int:
	var amount := float(BASE_DAMAGE + bonus_damage()) * (1.0 + POWER_DAMAGE * power())
	return maxi(1, roundi(amount * (GIANT_DAMAGE if kind == "giant" else 1.0)))


## Hány találatot bír ki, mielőtt szétesik.
static func hits(kind: String) -> int:
	var base := ARCHER_HITS if kind == "archer" else BASE_HITS
	var total := base + POWER_HITS * power()
	return total * GIANT_HITS if kind == "giant" else total


## A csontvázak ütésének / lövésének gyakorisága (az erősítéssel gyorsul): ezzel szorozzuk a szünetet.
static func attack_interval_multiplier() -> float:
	return pow(1.0 - POWER_ATTACK_SPEED, power())


## Egy idézés töltési ideje (a gyors idézéssel rövidül; a szinttel és az ütési sebességgel nem).
static func cooldown(base: float) -> float:
	return base * pow(COOLDOWN_STEP, mini(level("cooldown"), MAX_COOLDOWN))


static func has_archers() -> bool:
	return level("archers") > 0


## (Ha valahogy mindkettő meglenne, az íjászok számítanak.)
static func has_giant() -> bool:
	return level("giant") > 0 and not has_archers()


## A másodlagos idézés (jobb klikk): "archers", "giant", vagy "" ha még nem választott.
static func secondary() -> String:
	if has_archers():
		return "archers"
	if has_giant():
		return "giant"
	return ""


## A választható kártyák (minden 5. szinten): ami még nem érte el a határát, és a még meg nem tanult
## képességek; ha CARD_COUNT-nál több, véletlenül választunk közülük.
static func level_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	if max_minions() < MAX_MAX:
		options.append({"necromancy": "count", "stat": "", "amount": 0, "region": SKELETON_REGION,
			"title": "Csontvázhad", "text": "+1 csontváz lehet egyszerre (most %d, legfeljebb %d)" % [max_minions(), MAX_MAX],
			"note": "minden fajta együtt számít"})
	if lifetime() < MAX_LIFE:
		options.append({"necromancy": "life", "stat": "", "amount": 0, "icon_path": LIFE_ICON,
			"title": "Erős csontkötés", "text": "+%d mp-ig élnek a csontvázak (most %d mp, legfeljebb %d)" \
				% [roundi(LIFE_STEP), roundi(lifetime()), roundi(MAX_LIFE)], "note": "idézés"})
	options.append({"necromancy": "damage", "stat": "", "amount": 0, "icon_path": DAMAGE_ICON,
		"title": "Éles csontok", "text": "+1 sebzés minden csontváznak (most +%d)" % bonus_damage(), "note": "idézés"})
	if power() < MAX_POWER:
		options.append({"necromancy": "power", "stat": "", "amount": 0, "icon_path": POWER_ICON,
			"title": "Csontváz-erősítés", "text": "+%d%% sebzés, +%d kibírt találat, %d%%-kal gyorsabb ütés (most %d., legfeljebb %d.)" \
				% [roundi(POWER_DAMAGE * 100.0), POWER_HITS, roundi(POWER_ATTACK_SPEED * 100.0), power(), MAX_POWER],
			"note": "minden csontváz"})
	if level("cooldown") < MAX_COOLDOWN:
		options.append({"necromancy": "cooldown", "stat": "", "amount": 0, "icon_path": COOLDOWN_ICON,
			"title": "Gyors idézés", "text": "%d%%-kal rövidebb idő két idézés között (most %d / %d)" \
				% [roundi((1.0 - COOLDOWN_STEP) * 100.0), level("cooldown"), MAX_COOLDOWN], "note": "minden idézés"})
	# A másodlagos idézés (jobb klikk): íjászok VAGY óriás — ha az egyiket választotta, a másik már nem jön.
	if secondary().is_empty():
		options.append({"necromancy": "archers", "stat": "", "amount": 0, "icon_path": ARCHER_ICON,
			"title": "Íjász csontvázak", "text": "%d íjász csontváz kel ki, és távolról lő a szörnyekre" % ARCHER_COUNT,
			"note": "jobb klikk · vagy ez, vagy az óriás"})
		options.append({"necromancy": "giant", "stat": "", "amount": 0, "icon_path": GIANT_ICON,
			"title": "Óriás csontváz", "text": "Egy nagy csontváz kel ki: %dx erősebb, %dx többet bír, de lassabb" \
				% [roundi(GIANT_DAMAGE), GIANT_HITS], "note": "jobb klikk · vagy ez, vagy az íjászok"})
	options.shuffle()
	options.resize(mini(options.size(), CARD_COUNT))
	return options


static func choose(key: String) -> void:
	GameState.necromancy[key] = level(key) + 1
