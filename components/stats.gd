class_name Stats
extends Node
## A karakter fejleszthető tulajdonságai. Minden statnak van egy alapértéke
## (`base_*`, ezt növeli a szintlépés) és egy bónusza (a felvett tárgyakból).
## A végső érték (pl. `damage`) a kettő összege, a LIMITS korlátain belül.
## Ha bármi változik, `changed`-et jelez, és a tulajdonos alkalmazza a statokat.
##
## Sebzés (Brotato-szerűen): a fegyvernek van alapsebzése és skálázása, pl.
## "100% közelharci sebzés". Egy találat:
##   (fegyver alapsebzése + Közelharci sebzés × skálázás) × (1 + Sebzés% / 100)
## Kritikus találatnál ez még a fegyver kritikus szorzójával is szorzódik.

signal changed

const NAMES: Array[String] = [
	"damage", "ranged_damage", "damage_percent", "max_health", "health_regen", "dodge", "move_speed", "attack_speed",
	"crit_chance", "attack_range", "defense", "multishot", "accuracy", "elemental_damage",
]
const MAX_RANGE := 200
## Alapértelmezett kritikus szorzó (ha a fegyver nem ad meg sajátot).
const CRIT_MULTIPLIER := 1.5
const MAX_CRIT := 70
## A kikerülés ennél több százalékos esélyt nem adhat.
const MAX_DODGE := 75
const MAX_MOVE_SPEED := 150
const MAX_ATTACK_SPEED := 500
## A védelem (a kapott sebzés ennyi százalékát védi ki) legfeljebb ennyi lehet.
const MAX_DEFENSE := 70
## Többlövés: ennyi nyíl repül egyszerre (íjjal). Csak legendás tárgy és a legendás
## szintlépési kártya növeli; legfeljebb ennyi lehet.
const MAX_MULTISHOT := 5
## Találati esély: ennyi % eséllyel találod el a szörnyet (a szörny kikerülése ezután még
## jön). Az alapérték karakterenként más (Characters), legfeljebb ennyi lehet.
const MAX_ACCURACY := 95
## Különleges tárgy-tulajdonságok (nem szintlépéses statok, csak tárgyakból / táborból):
## lifesteal: ennyi % eséllyel gyógyulsz 1-et találatkor; thorns: ennyit sebez vissza annak,
## aki megüt; gold_find: ennyi %-kal több arany; xp_bonus: ennyi %-kal több tapasztalat.
const SPECIAL: Array[String] = ["lifesteal", "thorns", "gold_find", "xp_bonus"]
## Minden szintlépéskor automatikusan ennyivel nő minden alapstat (a választott
## fejlesztésen felül). A tört részek összeadódnak, pl. a közelharci sebzés 10 szintenként +1.
const LEVEL_GROWTH := {
	"damage": 0.1,
	"ranged_damage": 0.1,
	"damage_percent": 1.0,
	"max_health": 1.0,
	"health_regen": 0.02,
	"dodge": 0.25,
	"move_speed": 0.5,
	"attack_speed": 1.0,
	"crit_chance": 0.25,
	"attack_range": 0.5,
	"defense": 0.25,
	"accuracy": 0.2,
}
## A végső értékek korlátai: [min, max].
const LIMITS := {
	"damage": [-99, 999],
	"ranged_damage": [-99, 999],
	"damage_percent": [-90, 999],
	"max_health": [1, 9999],
	"health_regen": [0.0, 99.0],
	"dodge": [0, MAX_DODGE],
	"move_speed": [50, MAX_MOVE_SPEED],
	"attack_speed": [50, MAX_ATTACK_SPEED],
	"crit_chance": [0, MAX_CRIT],
	"attack_range": [50, MAX_RANGE],
	"defense": [0, MAX_DEFENSE],
	"multishot": [1, MAX_MULTISHOT],
	"accuracy": [5, MAX_ACCURACY],
	"elemental_damage": [-99, 999],
}

## Közelharci sebzés: a fegyver skálázása szerint adódik a fegyver alapsebzéséhez.
## (Az alapértékek törtek is lehetnek a szintenkénti növekedés miatt; a végső érték kerekített.)
@export var base_damage := 0.0:
	set(value):
		base_damage = value
		changed.emit()
## Távolsági sebzés: ugyanígy, csak az íjak skálázódnak vele.
@export var base_ranged_damage := 0.0:
	set(value):
		base_ranged_damage = value
		changed.emit()
## Sebzés %: minden találat ennyi százalékkal nagyobb (negatív = kisebb).
@export var base_damage_percent := 0.0:
	set(value):
		base_damage_percent = value
		changed.emit()
## Maximális életerő.
@export var base_max_health := 10.0:
	set(value):
		base_max_health = value
		changed.emit()
## Másodpercenként ennyi HP töltődik vissza.
@export var base_health_regen := 0.2:
	set(value):
		base_health_regen = value
		changed.emit()
## Ennyi százalék eséllyel kikerülsz egy találatot (nem sebződsz).
@export var base_dodge := 10.0:
	set(value):
		base_dodge = value
		changed.emit()
## Mozgási sebesség százalékban (100 = alap sebesség).
@export var base_move_speed := 100.0:
	set(value):
		base_move_speed = value
		changed.emit()
## Ütési sebesség százalékban (100 = alap). Minél nagyobb,
## annál rövidebb a fegyver cooldownja két ütés között.
@export var base_attack_speed := 100.0:
	set(value):
		base_attack_speed = value
		changed.emit()
## Ennyi százalék eséllyel kritikus a találat (CRIT_MULTIPLIER-szer nagyobbat sebez).
@export var base_crit_chance := 2.0:
	set(value):
		base_crit_chance = value
		changed.emit()
## A kard hatótávja százalékban (100 = a penge hossza): ilyen messzire ér el az ütés.
@export var base_attack_range := 100.0:
	set(value):
		base_attack_range = value
		changed.emit()
## Védelem: a kapott sebzés ennyi százalékát kivéded (legfeljebb MAX_DEFENSE).
@export var base_defense := 0.0:
	set(value):
		base_defense = value
		changed.emit()
## Többlövés: ennyi nyíl repül egyszerre (az íjásznál alapból 2, lásd Characters).
@export var base_multishot := 1.0:
	set(value):
		base_multishot = value
		changed.emit()
## Elemi sebzés: a varázsló (Lőrinc) varázslatai skálázódnak vele; egyelőre csak neki van.
@export var base_elemental_damage := 0.0:
	set(value):
		base_elemental_damage = value
		changed.emit()
## Találati esély százalékban (a lovagé 75, az íjászé 80; lásd Characters).
@export var base_accuracy := 75.0:
	set(value):
		base_accuracy = value
		changed.emit()

# Végső értékek (alap + tárgyak, korlátozva). Csak olvasásra.
var damage: int:
	get: return floori(_final("damage"))
var ranged_damage: int:
	get: return floori(_final("ranged_damage"))
var damage_percent: int:
	get: return floori(_final("damage_percent"))
var max_health: int:
	get: return roundi(_final("max_health"))
var health_regen: float:
	get: return _final("health_regen")
var dodge: int:
	get: return roundi(_final("dodge"))
var move_speed: int:
	get: return roundi(_final("move_speed"))
var attack_speed: int:
	get: return roundi(_final("attack_speed"))
var crit_chance: int:
	get: return roundi(_final("crit_chance"))
var attack_range: int:
	get: return roundi(_final("attack_range"))
var defense: int:
	get: return floori(_final("defense"))
var multishot: int:
	get: return floori(_final("multishot"))
var accuracy: int:
	get: return roundi(_final("accuracy"))
var elemental_damage: int:
	get: return floori(_final("elemental_damage"))

## stat -> a felvett tárgyakból jövő összeg.
var _bonus := {}


func get_base(stat: String) -> float:
	return get("base_" + stat)


func set_base(stat: String, value: float) -> void:
	set("base_" + stat, value)


func add_base(stat: String, amount: float) -> void:
	set_base(stat, get_base(stat) + amount)


## Szintlépéskor: minden alapstat nő egy kicsit (LEVEL_GROWTH). A korlátokon túl nem.
func apply_level_growth() -> void:
	for stat: String in LEVEL_GROWTH:
		var limit: float = LIMITS[stat][1]
		if get_base(stat) < limit:
			set_base(stat, minf(get_base(stat) + LEVEL_GROWTH[stat], limit))


## Egy találat sebzése a fegyver alapsebzéséből és skálázásából (lásd fent).
## `ranged`: íjnál a Távolsági sebzés skálázódik a Közelharci helyett; `elemental`: a
## varázspálcánál az Elemi sebzés.
func hit_damage(weapon_base: float, scaling: float, ranged := false, elemental := false) -> int:
	var scaled := elemental_damage if elemental else (ranged_damage if ranged else damage)
	var raw := weapon_base + scaled * scaling
	return maxi(1, roundi(raw * (1.0 + damage_percent / 100.0)))


func get_bonus(stat: String) -> float:
	return _bonus.get(stat, 0.0)


## A felvett tárgyak bónuszai (stat -> összeg); a régieket lecseréli.
func set_bonuses(bonuses: Dictionary) -> void:
	_bonus = bonuses.duplicate()
	changed.emit()


## A kapott sebzés a védelem után (legalább 1 marad).
func reduce_damage(amount: int) -> int:
	return maxi(1, roundi(amount * (1.0 - defense / 100.0)))


## Különleges tárgy-tulajdonság összege (lásd SPECIAL), csak a bónuszokból.
func special(stat: String) -> float:
	return get_bonus(stat)


func _final(stat: String) -> float:
	var limits: Array = LIMITS[stat]
	return clampf(get_base(stat) + get_bonus(stat), limits[0], limits[1])
