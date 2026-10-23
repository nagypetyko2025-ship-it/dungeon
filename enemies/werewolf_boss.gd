extends "res://enemies/boss.gd"
## A Vérfarkas: a nagy főellenség a 20. (utolsó) emeleten. A sima főellenségre épül
## (követés, roham, csapás), de sokkal erősebb, és van három saját képessége:
##   életlopás   ha megsebez, a sebzés többszörösét visszagyógyítja
##   karmos körök a földön piros körök jelennek meg (egy mindig alattad); 3 mp múlva
##               aki benne áll, megsebződik
##   feltámadás  ha először legyőzöd, a földre rogy, aztán 75% élettel feltámad, dühöngve:
##               gyorsabb, nagyobbat üt, és több kört idéz
## A szoba a `final_died` jelzésre figyel (nem a Health.died-re), mert az első "halál" nem igazi.

## Csak a második (igazi) halálnál jelez.
signal final_died

const WEREWOLF := {
	"name": "Vérfarkas, a Mélység Ura", "rect": Rect2(0, 0, 24, 32), "scale": 3.0,
	"health": 3200, "damage": 16, "speed": 95.0, "xp": 600,
	"attacks": ["circles", "circles", "charge", "slam"], "minion": "",
}
const SHEET := "res://assets/enemies/werewolf.png"
## Életlopás: a játékosnak okozott sebzés ennyiszeresét gyógyítja (de legalább a max élet ennyi részét).
const LIFESTEAL_MULTIPLIER := 8.0
const LIFESTEAL_MIN := 0.01
## Feltámadás: ennyi ideig fekszik, és ennyi élettel kel fel.
const REVIVE_DELAY := 3.0
const REVIVE_HEALTH := 0.75
## Dühöngés (a feltámadás után): sebesség- és sebzésszorzó, sűrűbb támadások.
const RAGE_SPEED := 1.35
const RAGE_DAMAGE := 1.3
const RAGE_INTERVAL := 0.55
## Karmos körök: hány darab (egy mindig a játékos alatt), mekkora, mennyi idő múlva csapnak le.
const CIRCLES := 5
const RAGE_CIRCLES := 8
const CIRCLE_RADIUS := 58.0
const RAGE_CIRCLE_RADIUS := 70.0
const CIRCLE_SPREAD := 230.0
const CIRCLE_FUSE := 3.0

var _revived := false
var _raging := false


## A vérfarkas beállítása a fába kerülés előtt (a setup_boss helyett).
func setup_werewolf(depth: int) -> void:
	mini_boss = false
	_def = WEREWOLF
	boss_name = WEREWOLF["name"]
	_depth = depth
	_type = {"name": "werewolf", "rect": WEREWOLF["rect"], "sheet": SHEET, "run": true}
	stats = {
		"health": WEREWOLF["health"],
		"damage": WEREWOLF["damage"],
		"speed": WEREWOLF["speed"],
		"dodge": 0,
		"knockback": 420.0,
		"resist": 1.0,
		"xp": WEREWOLF["xp"],
		"power": 1.0,
	}


func setup_boss(depth: int) -> void:
	setup_werewolf(depth)


## A játékos hívja, ha a vérfarkas megsebezte: életlopás.
func on_hit_player(amount: int) -> void:
	if _health.is_dead() or not is_physics_processing():
		return
	var heal := maxi(roundi(amount * LIFESTEAL_MULTIPLIER), roundi(_health.max_health * LIFESTEAL_MIN))
	_health.heal(heal)
	FloatingText.spawn(get_parent(), _head_position() + Vector2(0, 24), "+%d" % heal, Color(0.95, 0.25, 0.35), 20)


func _attack(kind: String) -> void:
	if kind != "circles":
		await super._attack(kind)
		if _raging:
			_attack_left *= RAGE_INTERVAL
		return
	_busy = true
	var flash := create_tween()
	flash.tween_property(_visual, "modulate", Color(2.4, 0.6, 0.6), 0.5)
	await flash.finished
	_visual.modulate = Color.WHITE
	if not is_physics_processing():
		return
	_spawn_circles()
	_busy = false
	var interval := randf_range(ATTACK_INTERVAL.x, ATTACK_INTERVAL.y)
	_attack_left = interval * (RAGE_INTERVAL if _raging else (ENRAGE_INTERVAL if _enraged else 1.0))


## Karmos körök: egy a játékos alatt, a többi körülötte (a termen belül).
func _spawn_circles() -> void:
	if not is_instance_valid(_player):
		return
	Audio.play("boss_roar", -6.0, 0.3)
	var count := RAGE_CIRCLES if _raging else CIRCLES
	var radius := RAGE_CIRCLE_RADIUS if _raging else CIRCLE_RADIUS
	var room := get_parent().get_parent()
	var bounds := Rect2()
	if room is Room:
		var r: Rect2i = (room as Room).rect.grow(-1)
		bounds = Rect2(Vector2(r.position) * Room.TILE, Vector2(r.size) * Room.TILE)
	for i in count:
		var at := _player.global_position
		if i > 0:
			at += Vector2.from_angle(randf() * TAU) * randf_range(radius * 1.2, CIRCLE_SPREAD)
		if bounds.has_area():
			at = at.clamp(bounds.position, bounds.end)
		var circle := GroundCircle.new()
		circle.radius = radius
		circle.fuse = CIRCLE_FUSE
		circle.damage = stats["damage"]
		circle.source = self
		get_parent().add_child(circle)
		circle.global_position = at


## Az első "halál": a földre rogy, aztán feltámad. A második már igazi.
func _on_died() -> void:
	if _revived:
		final_died.emit()
		super._on_died()
		return
	_revived = true
	_fall_and_revive()


func _fall_and_revive() -> void:
	set_physics_process(false)
	_busy = true
	_charge_left = 0.0
	_hurtbox.set_deferred("monitoring", false)
	_hitbox.set_deferred("monitorable", false)
	# Életben tartjuk (1 HP), hogy a szoba ne tekintse halottnak; közben nem sebezhető.
	_health.current = 1
	_health.changed.emit(_health.current, _health.max_health)
	Audio.play("boss_defeated")
	_sprite.play("idle")
	_sprite.stop()
	var fall := create_tween().set_parallel()
	fall.tween_property(_visual, "rotation", PI / 2.0 * (-1.0 if _sprite.flip_h else 1.0), 0.45) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	fall.tween_property(_visual, "modulate", Color(0.5, 0.45, 0.45), 0.45)
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -60), "Legyőzted...?", Color(0.85, 0.8, 0.75), 22)
	await get_tree().create_timer(REVIVE_DELAY * 0.6, false).timeout
	# Rángatózik, mielőtt felkel.
	var twitch := create_tween()
	for i in 4:
		twitch.tween_property(_visual, "position:x", 4.0, 0.06)
		twitch.tween_property(_visual, "position:x", -4.0, 0.06)
	twitch.tween_property(_visual, "position:x", 0.0, 0.06)
	Audio.play("boss_roar", -8.0, 0.2)
	await get_tree().create_timer(REVIVE_DELAY * 0.4, false).timeout
	_revive()


func _revive() -> void:
	_raging = true
	_enraged = true
	stats["speed"] = float(stats["speed"]) * RAGE_SPEED
	stats["damage"] = roundi(float(stats["damage"]) * RAGE_DAMAGE)
	_hitbox.damage = stats["damage"]
	_health.current = roundi(_health.max_health * REVIVE_HEALTH)
	_health.changed.emit(_health.current, _health.max_health)
	_sprite.self_modulate = Color(1.35, 0.7, 0.7)
	var rise := create_tween().set_parallel()
	rise.tween_property(_visual, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	rise.tween_property(_visual, "modulate", Color.WHITE, 0.3)
	Audio.play("boss_roar")
	var ring := Shockwave.new()
	ring.radius = SLAM_RADIUS * 1.4
	ring.position = position
	get_parent().add_child(ring)
	FloatingText.spawn(get_parent(), _head_position(), "Feltámadt — dühöng!", Color(1, 0.25, 0.2), 26)
	await rise.finished
	_hurtbox.set_deferred("monitoring", true)
	_hitbox.set_deferred("monitorable", true)
	_busy = false
	_attack_left = 0.8
	set_physics_process(true)


## Karmos kör a földön: 3 mp alatt telik meg pirossal, aztán lecsap; aki benne áll, sebződik.
class GroundCircle:
	extends Node2D
	var radius := 58.0
	var fuse := 3.0
	var damage := 10
	var source: Node2D
	var _t := 0.0
	var _struck := false

	func _ready() -> void:
		z_index = -3

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
		if not _struck and _t >= fuse:
			_struck = true
			_strike()
		if _t >= fuse + 0.35:
			queue_free()

	func _strike() -> void:
		Audio.play("boss_slam", -6.0)
		var area := Hitbox.new()
		area.damage = damage
		area.knockback = 300.0
		area.collision_layer = 16
		area.collision_mask = 0
		if is_instance_valid(source):
			area.set_meta("source", source)
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = radius
		shape.shape = circle
		area.add_child(shape)
		add_child(area)
		get_tree().create_timer(0.2, false).timeout.connect(area.queue_free)

	func _draw() -> void:
		if _struck:
			# Lecsapás: fehéres-piros villanás, ami elhalványul.
			var fade := 1.0 - clampf((_t - fuse) / 0.35, 0.0, 1.0)
			draw_circle(Vector2.ZERO, radius, Color(1, 0.55, 0.45, 0.6 * fade))
			draw_arc(Vector2.ZERO, radius, 0, TAU, 40, Color(1, 0.9, 0.8, fade), 4.0)
			return
		var progress := clampf(_t / fuse, 0.0, 1.0)
		# Az utolsó fél másodpercben villog.
		var blink := 1.0 if _t < fuse - 0.5 or int(_t * 12.0) % 2 == 0 else 0.55
		draw_circle(Vector2.ZERO, radius, Color(0.8, 0.05, 0.08, 0.16 * blink))
		draw_circle(Vector2.ZERO, radius * progress, Color(0.9, 0.12, 0.12, 0.38 * blink))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 40, Color(1, 0.25, 0.2, 0.9 * blink), 3.0)
		# Karmolásnyomok középen.
		for i in 3:
			var x := (i - 1) * radius * 0.28
			draw_line(Vector2(x - 6, -radius * 0.35), Vector2(x + 6, radius * 0.35), Color(0.35, 0.02, 0.04, 0.7 * blink), 3.0)
