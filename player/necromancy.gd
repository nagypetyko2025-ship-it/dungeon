class_name Necromancy
## Vendel (a csontváz sírásó) idézésének fejlesztései: minden LEVEL_EVERY. szintlépéskor a stat-kártyák
## helyett ezek közül választ (lásd LevelUp, mint Lőrinc a varázslatai közül). A futáshoz tartoznak
## (GameState.necromancy, a félbehagyott futással együtt mentődnek):
##   count    +1 csontváz lehet egyszerre (alapból BASE_MAX, legfeljebb MAX_MAX)
##   life     +LIFE_STEP mp élettartam a csontvázaknak (alapból BASE_LIFE, legfeljebb MAX_LIFE)
##   damage   +1 sebzés minden csontváznak (korlát nélkül)
##   archers  jobb klikk: ARCHER_COUNT íjász csontváz (egyszer lehet megtanulni)
## Az idézés bal klikkre megy (lásd Player._summon), az íjászoké jobb klikkre (Player._summon_archers).

const LEVEL_EVERY := 5
const BASE_MAX := 6
const MAX_MAX := 12
const BASE_LIFE := 18.0
const LIFE_STEP := 2.0
const MAX_LIFE := 60.0
const ARCHER_COUNT := 3
## A kártyák ikonjai.
const SKELETON_REGION := Rect2(368, 88, 16, 16)
const LIFE_ICON := "res://assets/items/trinket_clock.png"
const DAMAGE_ICON := "res://assets/items/dagger_bone.png"
const ARCHER_ICON := "res://assets/items/bow_old.png"


static func level(key: String) -> int:
	return int(GameState.necromancy.get(key, 0))


## Ennyi (sima) csontváza lehet egyszerre.
static func max_minions() -> int:
	return mini(BASE_MAX + level("count"), MAX_MAX)


## Ennyi mp-ig él egy csontváz.
static func lifetime() -> float:
	return minf(BASE_LIFE + LIFE_STEP * level("life"), MAX_LIFE)


## Ennyivel többet üt minden csontváz.
static func bonus_damage() -> int:
	return level("damage")


static func has_archers() -> bool:
	return level("archers") > 0


## A választható kártyák (minden 5. szinten): ami még nem érte el a határát, és az íjászok, ha még nincsenek.
static func level_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	if max_minions() < MAX_MAX:
		options.append({"necromancy": "count", "stat": "", "amount": 0, "region": SKELETON_REGION,
			"title": "Csontvázhad", "text": "+1 csontváz lehet egyszerre (most %d, legfeljebb %d)" % [max_minions(), MAX_MAX],
			"note": "idézés · bal klikk"})
	if lifetime() < MAX_LIFE:
		options.append({"necromancy": "life", "stat": "", "amount": 0, "icon_path": LIFE_ICON,
			"title": "Erős csontkötés", "text": "+%d mp-ig élnek a csontvázak (most %d mp, legfeljebb %d)" \
				% [roundi(LIFE_STEP), roundi(lifetime()), roundi(MAX_LIFE)], "note": "idézés"})
	options.append({"necromancy": "damage", "stat": "", "amount": 0, "icon_path": DAMAGE_ICON,
		"title": "Éles csontok", "text": "+1 sebzés minden csontváznak (most +%d)" % bonus_damage(), "note": "idézés"})
	if not has_archers():
		options.append({"necromancy": "archers", "stat": "", "amount": 0, "icon_path": ARCHER_ICON,
			"title": "Íjász csontvázak", "text": "%d íjász csontváz kel ki, és távolról lő a szörnyekre" % ARCHER_COUNT,
			"note": "új képesség · jobb klikk"})
	return options


static func choose(key: String) -> void:
	GameState.necromancy[key] = level(key) + 1
