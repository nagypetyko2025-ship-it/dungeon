class_name Upgrades
## Szintlépéskor választható fejlesztések. Mindegyik egy Stats-értéket növel
## (ezen felül szintenként minden stat magától is nő egy kicsit: Stats.LEVEL_GROWTH).
## Az ikon vagy a sprite-lapról (`region`), vagy külön fájlból (`icon_path`) jön.

const ALL: Array[Dictionary] = [
	{"stat": "damage", "title": "Erő", "text": "+1 közelharci sebzés (a fegyvered skálázása szerint)", "amount": 1,
		"region": Rect2(339, 98, 10, 29)},
	{"stat": "ranged_damage", "title": "Íjászat", "text": "+1 távolsági sebzés (az íjakat erősíti)", "amount": 1,
		"icon_path": "res://assets/ui/icon_ranged.png"},
	{"stat": "damage_percent", "title": "Pusztítás", "text": "+5% sebzés (minden találat)", "amount": 5,
		"region": Rect2(291, 137, 10, 22)},
	{"stat": "max_health", "title": "Vitalitás", "text": "+3 max élet", "amount": 3,
		"region": Rect2(289, 370, 13, 12)},
	{"stat": "health_regen", "title": "Regeneráció", "text": "+0.3 élet / mp", "amount": 0.3,
		"region": Rect2(288, 336, 16, 16)},
	{"stat": "dodge", "title": "Kikerülés", "text": "+5% kikerülési esély", "amount": 5,
		"icon_path": "res://assets/ui/icon_dodge.png"},
	{"stat": "move_speed", "title": "Gyorsaság", "text": "+10% mozgási sebesség", "amount": 10,
		"icon_path": "res://assets/ui/icon_boot.png"},
	{"stat": "attack_speed", "title": "Fürgeség", "text": "+15% ütési sebesség", "amount": 15,
		"region": Rect2(293, 66, 6, 29)},
	{"stat": "crit_chance", "title": "Precizitás", "text": "+4% kritikus esély", "amount": 4,
		"icon_path": "res://assets/ui/icon_crit.png"},
	{"stat": "defense", "title": "Páncélzat", "text": "+2% védelem (a sebzés ennyi %-át kivéded)", "amount": 2,
		"icon_path": "res://assets/ui/icon_defense.png"},
	{"stat": "attack_range", "title": "Hosszú karok", "text": "+12% hatótáv (messzebbre ér a kardod)", "amount": 12,
		"icon_path": "res://assets/ui/icon_range.png"},
]

## Melyik stat meddig fejleszthető (ami elérte, nem kerül fel választásnak).
const LIMITS := {
	"dodge": Stats.MAX_DODGE,
	"move_speed": Stats.MAX_MOVE_SPEED,
	"attack_speed": Stats.MAX_ATTACK_SPEED,
	"crit_chance": Stats.MAX_CRIT,
	"attack_range": Stats.MAX_RANGE,
	"defense": Stats.MAX_DEFENSE,
	"multishot": Stats.MAX_MULTISHOT,
}

## Legendás fejlesztések: ritkábbak a többinél (LEGENDARY_CHANCE eséllyel kerül egy a
## választhatók közé), és különleges, arany kártyán jelennek meg.
const LEGENDARY: Array[Dictionary] = [
	{"stat": "multishot", "title": "Nyílzápor", "text": "+1 nyíl lövésenként", "amount": 1,
		"icon_path": "res://assets/ui/icon_multishot.png", "legendary": true, "needs_bow": true},
]
const LEGENDARY_CHANCE := 0.1


## `count` darab különböző fejlesztés véletlenszerűen; ami már maxon van, kimarad.
## `has_bow`: íjjal (vagy íjászként) a Nyílzápor legendás kártya is felbukkanhat, ritkán.
static func roll(stats: Stats, count: int, has_bow := false) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for upgrade in ALL:
		if _available(stats, upgrade):
			options.append(upgrade)
	options.shuffle()
	options = options.slice(0, count)
	var legendary: Array[Dictionary] = []
	for upgrade in LEGENDARY:
		if _available(stats, upgrade) and (has_bow or not upgrade.get("needs_bow", false)):
			legendary.append(upgrade)
	if not legendary.is_empty() and randf() < LEGENDARY_CHANCE and not options.is_empty():
		options[randi() % options.size()] = legendary.pick_random()
	return options


static func _available(stats: Stats, upgrade: Dictionary) -> bool:
	var stat: String = upgrade["stat"]
	return not (LIMITS.has(stat) and stats.get(stat) >= LIMITS[stat])


static func apply(stats: Stats, upgrade: Dictionary) -> void:
	var stat: String = upgrade["stat"]
	stats.add_base(stat, upgrade["amount"])


static func icon(upgrade: Dictionary) -> Texture2D:
	if upgrade.has("icon_path"):
		return load(upgrade["icon_path"])
	return SpriteSheet.region(upgrade["region"])
