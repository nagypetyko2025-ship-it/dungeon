extends "res://enemies/boss.gd"
## Ürességfaló, a Káosz Ura: a második nagy főellenség, a 40. emeleten (mint a Vérfarkas a 20.-on).
## Fekete-lila csápgomolyag fogas torokkal. A sima főellenségre épül (követés, roham, felbukkanás,
## lövedékgyűrű, idézés: Káoszivadékok), de sokkal erősebb, és van három saját képessége:
##   hasadékok    lila körök nyílnak a földön (egy mindig alattad); kis idő múlva kitörnek, és aki
##                benne áll, nagyot sebződik
##   káoszörvény  forgó lövedékspirál, több hullámban
##   káoszalak    fél élet alatt széthasad a valóság: gyorsabb, nagyobbat üt, sűrűbben támad, több
##                hasadékot nyit, és Káoszkopókat idéz maga mellé
## A szoba a Health.died-re figyel (nincs feltámadás); a csapás és a lövedékek a társak gépén is
## lejátszódnak (NetEnemies.broadcast_attack).

const LORD := {
	"name": "Ürességfaló, a Káosz Ura", "rect": Rect2(0, 0, 64, 64), "scale": 1.5,
	"health": 1000000, "damage": 120, "speed": 100.0, "xp": 3000,
	"attacks": ["rifts", "rifts", "vortex", "blink", "charge", "summon", "nova"], "minion": "chaos_spawn",
}
const SHEET := "res://assets/enemies/chaos_lord.png"
## A hasadék a Vérfarkas karmos köre, lilában.
const WEREWOLF_SCRIPT := preload("res://enemies/werewolf_boss.gd")
## A teste közepe sebez érintésre (a csápvégek nem): az ütközők ekkora része.
const HIT_SHARE := Vector2(0.55, 0.55)
## Hasadékok: hány darab (egy mindig a játékos alatt), mekkora, mennyi idő múlva törnek ki.
const RIFTS := 6
const FORM_RIFTS := 10
const RIFT_RADIUS := 62.0
const FORM_RIFT_RADIUS := 74.0
const RIFT_SPREAD := 260.0
const RIFT_FUSE := 2.4
const FORM_RIFT_FUSE := 1.9
## Káoszörvény: hullámok, lövedék hullámonként, elfordulás hullámonként, a lövedék sebzése a
## testéhez képest.
const VORTEX_WAVES := 4
const VORTEX_BOLTS := 12
const FORM_VORTEX_BOLTS := 16
const VORTEX_TWIST := 0.22
const VORTEX_DELAY := 0.35
const BOLT_SHARE := 0.6
const BOLT_TINT := Color(0.85, 0.45, 1.4)
## Káoszalak (fél élet alatt): sebesség- és sebzésszorzó, sűrűbb támadások, idézett kopók.
const FORM_AT := 0.5
const FORM_SPEED := 1.3
const FORM_DAMAGE := 1.25
const FORM_INTERVAL := 0.5
const FORM_HOUNDS := 2
const WINDUP_COLOR := Color(1.6, 0.5, 2.6)

var _chaos_form := false


## A Káosz Ura beállítása a fába kerülés előtt (a setup_boss helyett).
func setup_chaos(depth: int) -> void:
	mini_boss = false
	_def = LORD
	boss_name = LORD["name"]
	_depth = depth
	_type = {"name": "chaos_lord", "rect": LORD["rect"], "sheet": SHEET, "run": true}
	stats = {
		"health": LORD["health"],
		"damage": LORD["damage"],
		"speed": LORD["speed"],
		"dodge": 0,
		"knockback": 460.0,
		"resist": 1.0,
		"xp": LORD["xp"],
		"power": 1.0,
	}


func setup_boss(depth: int, _special := {}) -> void:
	setup_chaos(depth)


func _fit_shapes(size: Vector2) -> void:
	super._fit_shapes(size)
	var hit := RectangleShape2D.new()
	hit.size = size * HIT_SHARE
	$Hitbox/CollisionShape2D.shape = hit
	$Hitbox/CollisionShape2D.position.y = -size.y * 0.5


func _attack(kind: String) -> void:
	if kind != "rifts" and kind != "vortex":
		await super._attack(kind)
		if _chaos_form:
			_attack_left *= FORM_INTERVAL
		return
	var net := NetEnemies.active(get_tree())
	if net != null and net.is_host():
		net.broadcast_attack(self, kind)
	_busy = true
	var flash := create_tween()
	flash.tween_property(_visual, "modulate", WINDUP_COLOR, 0.5)
	await flash.finished
	_visual.modulate = Color.WHITE
	if not is_physics_processing():
		return
	if kind == "rifts":
		_open_rifts()
	else:
		await _vortex()
	_busy = false
	var interval := randf_range(ATTACK_INTERVAL.x, ATTACK_INTERVAL.y)
	_attack_left = interval * (FORM_INTERVAL if _chaos_form else (ENRAGE_INTERVAL if _enraged else 1.0))


## Hasadékok: egy a játékos alatt, a többi körülötte (a termen belül).
func _open_rifts() -> void:
	if not is_instance_valid(_player):
		return
	Audio.play("boss_roar", -6.0, 0.5)
	var count := FORM_RIFTS if _chaos_form else RIFTS
	var radius := FORM_RIFT_RADIUS if _chaos_form else RIFT_RADIUS
	var room := get_parent().get_parent()
	var bounds := Rect2()
	if room is Room:
		var r: Rect2i = (room as Room).rect.grow(-1)
		bounds = Rect2(Vector2(r.position) * Room.TILE, Vector2(r.size) * Room.TILE)
	for i in count:
		var at := _player.global_position
		if i > 0:
			at += Vector2.from_angle(randf() * TAU) * randf_range(radius * 1.2, RIFT_SPREAD)
		if bounds.has_area():
			at = at.clamp(bounds.position, bounds.end)
		var rift := WEREWOLF_SCRIPT.GroundCircle.new()
		rift.radius = radius
		rift.fuse = FORM_RIFT_FUSE if _chaos_form else RIFT_FUSE
		rift.damage = stats["damage"]
		rift.source = self
		rift.fill_color = Color(0.3, 0.05, 0.45)
		rift.core_color = Color(0.45, 0.1, 0.7)
		rift.edge_color = Color(0.75, 0.35, 1.0)
		rift.mark_color = Color(0.08, 0.0, 0.12)
		rift.flash_color = Color(0.85, 0.5, 1.0)
		get_parent().add_child(rift)
		rift.global_position = at


## Káoszörvény: lövedékgyűrűk hullámokban, mindegyik kicsit elfordulva (forgó spirál).
func _vortex() -> void:
	Audio.play("magic", -2.0, 0.2)
	var bolts := FORM_VORTEX_BOLTS if _chaos_form else VORTEX_BOLTS
	var twist := randf() * TAU
	for wave in VORTEX_WAVES:
		if not is_physics_processing():
			return
		for i in bolts:
			var bolt = MAGIC_BOLT.instantiate()
			bolt.direction = Vector2.from_angle(twist + TAU * i / bolts + wave * VORTEX_TWIST)
			bolt.speed = 190.0
			bolt.damage = roundi(float(stats["damage"]) * BOLT_SHARE)
			bolt.modulate = BOLT_TINT
			bolt.set_meta("source", self)
			get_parent().add_child(bolt)
			bolt.global_position = global_position + Vector2(0, -60)
		Audio.play("magic", -8.0, 0.3)
		await get_tree().create_timer(VORTEX_DELAY, false).timeout


func _on_health_changed(current: int, maximum: int) -> void:
	if not _chaos_form and current > 0 and current <= roundi(maximum * FORM_AT):
		_enter_chaos_form()


## Káoszalak: széthasad a valóság (fél élet alatt, egyszer).
func _enter_chaos_form() -> void:
	_chaos_form = true
	_enraged = true
	enraged.emit()
	stats["speed"] = float(stats["speed"]) * FORM_SPEED
	stats["damage"] = roundi(float(stats["damage"]) * FORM_DAMAGE)
	_hitbox.damage = stats["damage"]
	_sprite.self_modulate = Color(1.3, 0.7, 1.6)
	Audio.play("boss_roar")
	var ring := Shockwave.new()
	ring.radius = SLAM_RADIUS * 1.6
	ring.position = position
	get_parent().add_child(ring)
	FloatingText.spawn(get_parent(), _head_position(), "Káoszalak — a valóság széthasad!", Color(0.85, 0.45, 1.0), 26)
	# (A báb nem idéz: a kopók a gazdától jönnek.)
	if not net_puppet:
		var room := get_parent().get_parent()
		if room.has_method("summon_minions"):
			room.call("summon_minions", "chaos_hound", FORM_HOUNDS, global_position)
