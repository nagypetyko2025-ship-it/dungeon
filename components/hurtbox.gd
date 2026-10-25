class_name Hurtbox
extends Area2D
## Sebezhető terület. Ha Hitboxszal fedi egymást, `hurt`-ot jelez,
## utána `invincibility_time` ideig nem sebezhető.

signal hurt(hitbox: Hitbox)

@export var invincibility_time := 0.3

var _invincible_left := 0.0


func _init() -> void:
	monitorable = false


func _physics_process(delta: float) -> void:
	if _invincible_left > 0.0:
		_invincible_left -= delta
		return
	if not monitoring:
		return
	for area in get_overlapping_areas():
		if area is Hitbox:
			# Átütő lövedék (hadiíj nyila): ugyanazt a célt csak egyszer sebzi.
			if area.has_method("skips") and area.call("skips", self):
				continue
			_invincible_left = invincibility_time
			hurt.emit(area)
			# Lövedékek (pl. nyíl) ilyenkor eltűnnek.
			if area.has_method("on_hit"):
				area.call("on_hit")
			return


func is_invincible() -> bool:
	return _invincible_left > 0.0


## Egy ideig nem sebezhető (pl. feléledés után).
func grant_invincibility(seconds: float) -> void:
	_invincible_left = maxf(_invincible_left, seconds)
