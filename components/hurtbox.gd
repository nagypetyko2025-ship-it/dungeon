class_name Hurtbox
extends Area2D
## Sebezhető terület. Ha Hitboxszal fedi egymást, `hurt`-ot jelez,
## utána `invincibility_time` ideig nem sebezhető.

signal hurt(hitbox: Hitbox)

@export var invincibility_time := 0.3
## Forrásonként (a szörnyeké): ugyanaz a fegyver / lövedék csak `invincibility_time` múlva sebez újra, de egy
## másik azonnal (a többlövés nyilai, több varázslat egyszerre). Enélkül egy főellenséget másodpercenként legfeljebb
## 5 találat ért, akárhány nyíl repült rá: a Többlövés és a nagyon gyors támadás a főellenségen elveszett.
## A játékosé közös (minden találat után sebezhetetlen egy ideig).
@export var per_source := false

var _invincible_left := 0.0
## per_source: a nemrég talált Hitboxok (példány-azonosító -> hátralévő idő).
var _recent := {}


func _init() -> void:
	monitorable = false


func _physics_process(delta: float) -> void:
	if _invincible_left > 0.0:
		_invincible_left -= delta
		return
	if not _recent.is_empty():
		for id: int in _recent.keys():
			_recent[id] = float(_recent[id]) - delta
			if float(_recent[id]) <= 0.0:
				_recent.erase(id)
	if not monitoring:
		return
	for area in get_overlapping_areas():
		if area is Hitbox:
			# Átütő lövedék (hadiíj nyila): ugyanazt a célt csak egyszer sebzi.
			if area.has_method("skips") and area.call("skips", self):
				continue
			if per_source:
				if _recent.has(area.get_instance_id()):
					continue
				_recent[area.get_instance_id()] = invincibility_time
			else:
				_invincible_left = invincibility_time
			var hitbox := area as Hitbox
			hitbox.missed = false
			hurt.emit(hitbox)
			# Lövedékek (pl. nyíl) ilyenkor eltűnnek; ha mellément vagy a szörny kikerülte, továbbrepülnek
			# (ugyanazt a célt a nyíl nem találja el újra, lásd PlayerArrow.skips).
			if hitbox.has_method("on_hit") and not hitbox.missed:
				hitbox.call("on_hit")
			# (Forrásonként a többi Hitbox is sebezhet ugyanebben a lépésben; a halott már nem.)
			if not per_source or not is_inside_tree() or _invincible_left > 0.0:
				return


func is_invincible() -> bool:
	return _invincible_left > 0.0


## Egy ideig nem sebezhető (pl. feléledés után).
func grant_invincibility(seconds: float) -> void:
	_invincible_left = maxf(_invincible_left, seconds)
