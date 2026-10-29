extends "res://enemies/boss.gd"
## Az Ősgépezet: a Fagykő nagy főellensége a 60. emeleten (mint a Vérfarkas a 20.-on, a Káosz Ura a 40.-en).
## Ősrégi, sárgaréz-patinás lépegető gép, a hátán kéménnyel. Nincs második fázisa (nem dühödik fel), de
## tízmillió élete van, és a saját, gépies támadásai:
##   gőz       kinyújtja a kéményét, és forró gőzt fúj maga köré (három, egyre táguló hullám)
##   fogaskerék  pörgő fogaskerék-fűrészeket lő ki minden irányba, amik visszatérnek hozzá
##   dugattyú  a földbe döngöl: rengéshullám-sor fut végig a földön feléd
##   tesla     villámok csapnak le oda, ahol állsz (egymás után, követnek)
##   mágnes    magához húz, aztán nagyot dobbant
## Közben a sima főellenség rohama is megvan. Lépéskor dübörög, néha csipog; a zenéje csak ebben a
## harcban szól (Audio "engine").

const ENGINE := {
	"name": "Az Ősgépezet", "rect": Rect2(0, 0, 48, 96), "scale": 1.4,
	"health": 10000000, "damage": 160, "speed": 70.0, "xp": 6000,
	"attacks": ["steam", "gears", "pistons", "tesla", "magnet", "charge", "gears", "tesla"],
}
const SHEET := "res://assets/enemies/ancient_engine.png"
## A teste (a kép alsó része, a kémény nélkül) sebez érintésre.
const HIT_SHARE := Vector2(0.62, 0.45)
const WINDUP_COLORS_ENGINE := {
	"steam": Color(2.2, 2.2, 2.2), "gears": Color(2.4, 1.8, 0.7), "pistons": Color(2.4, 1.2, 0.5),
	"tesla": Color(0.8, 1.8, 2.8), "magnet": Color(2.2, 0.7, 2.0),
}
const ENGINE_WINDUP := 0.6
## Gőz: hullámok sugara és késleltetése, a sebzés a testéhez képest.
const STEAM_RADII := [110.0, 170.0, 230.0]
const STEAM_DELAY := 0.28
const STEAM_SHARE := 0.7
## Fogaskerék-fűrészek: darabszám, meddig repülnek ki, sebesség.
const GEARS := 8
const GEAR_RANGE := 300.0
const GEAR_SPEED := 260.0
const GEAR_SHARE := 0.55
## Dugattyú: rengések száma, távolságuk, a köztük lévő idő, sugaruk.
const PISTONS := 8
const PISTON_STEP := 64.0
const PISTON_DELAY := 0.11
const PISTON_RADIUS := 50.0
const PISTON_SHARE := 0.8
## Tesla: villámok száma, közöttük eltelt idő, mennyi idő múlva csap le, sugár.
const TESLA_STRIKES := 5
const TESLA_DELAY := 0.42
const TESLA_FUSE := 0.75
const TESLA_RADIUS := 44.0
const TESLA_SHARE := 0.75
## Mágnes: meddig és milyen erővel húz.
const MAGNET_TIME := 1.6
const MAGNET_PULL := 240.0
## Lépés-dübörgés.
const STOMP_EVERY := 0.65

var _venting := false
var _stomp_left := STOMP_EVERY


## Az Ősgépezet beállítása a fába kerülés előtt (a setup_boss helyett).
func setup_engine(depth: int) -> void:
	mini_boss = false
	_def = ENGINE
	boss_name = ENGINE["name"]
	music_track = "engine"
	_depth = depth
	_type = {"name": "ancient_engine", "rect": ENGINE["rect"], "sheet": SHEET, "run": true}
	stats = {
		"health": ENGINE["health"],
		"damage": ENGINE["damage"],
		"speed": ENGINE["speed"],
		"dodge": 0,
		"knockback": 460.0,
		"resist": 1.0,
		"xp": ENGINE["xp"],
		"power": 1.0,
	}


func setup_boss(depth: int, _special := {}) -> void:
	setup_engine(depth)


func _ready() -> void:
	super._ready()
	# A gőzkiengedés kockái (8-9: kinyúló kémény) a lap végén.
	var frames := _sprite.sprite_frames
	if not frames.has_animation("vent"):
		frames.add_animation("vent")
		frames.set_animation_speed("vent", 6.0)
		frames.set_animation_loop("vent", false)
		var texture: Texture2D = load(SHEET)
		for index in [8, 9]:
			var frame := AtlasTexture.new()
			frame.atlas = texture
			frame.region = Rect2(Vector2(index * ENGINE["rect"].size.x, 0), ENGINE["rect"].size)
			frames.add_frame("vent", frame)


func _fit_shapes(size: Vector2) -> void:
	super._fit_shapes(size)
	var hit := RectangleShape2D.new()
	hit.size = size * HIT_SHARE
	$Hitbox/CollisionShape2D.shape = hit
	$Hitbox/CollisionShape2D.position.y = -size.y * 0.25


func _physics_process(delta: float) -> void:
	if _venting and not net_puppet:
		velocity = Vector2.ZERO
		move_and_slide()
		if _sprite.animation != "vent":
			_sprite.play("vent")
		return
	super._physics_process(delta)
	# Nehéz léptek (és néha egy csipogás a belsejéből).
	if velocity.length() > 5.0:
		_stomp_left -= delta
		if _stomp_left <= 0.0:
			_stomp_left = STOMP_EVERY
			Audio.play("engine_stomp", -12.0, 0.15)
			if randf() < 0.12:
				Audio.play("engine_beep", -14.0, 0.2)


## Nincs második fázis: nem dühödik fel.
func _on_health_changed(_current: int, _maximum: int) -> void:
	pass


func _attack(kind: String) -> void:
	if not WINDUP_COLORS_ENGINE.has(kind):
		await super._attack(kind)
		return
	var net := NetEnemies.active(get_tree())
	if net != null and net.is_host():
		net.broadcast_attack(self, kind)
	_busy = true
	Audio.play("engine_beep", -6.0, 0.1)
	var flash := create_tween()
	flash.tween_property(_visual, "modulate", WINDUP_COLORS_ENGINE[kind], ENGINE_WINDUP)
	await flash.finished
	_visual.modulate = Color.WHITE
	if not is_physics_processing() or not is_instance_valid(_player):
		_busy = false
		return
	match kind:
		"steam": await _steam()
		"gears": _gears()
		"pistons": await _pistons()
		"tesla": await _tesla()
		"magnet": await _magnet()
	_busy = false
	_attack_left = randf_range(ATTACK_INTERVAL.x, ATTACK_INTERVAL.y)


## Gőzkitörés: kinyúlik a kémény, és három táguló, forró gőzhullám csap ki körülötte.
func _steam() -> void:
	_venting = true
	_sprite.play("vent")
	Audio.play("engine_steam", 0.0, 0.1)
	for radius: float in STEAM_RADII:
		if not is_physics_processing():
			break
		var cloud := SteamCloud.new()
		cloud.radius = radius
		cloud.position = position
		get_parent().add_child(cloud)
		_burst(position, radius, roundi(stats["damage"] * STEAM_SHARE), 300.0)
		await get_tree().create_timer(STEAM_DELAY, false).timeout
	Audio.play("engine_steam", -6.0, 0.2)
	await get_tree().create_timer(0.3, false).timeout
	_venting = false


## Fogaskerék-fűrészek: minden irányba kirepülnek, aztán visszatérnek a géphez.
func _gears() -> void:
	Audio.play("engine_gears", 0.0, 0.1)
	var twist := randf() * TAU
	for i in GEARS:
		var gear := GearSaw.new()
		gear.source = self
		gear.direction = Vector2.from_angle(twist + TAU * i / GEARS)
		gear.reach = GEAR_RANGE
		gear.speed = GEAR_SPEED
		gear.damage = roundi(stats["damage"] * GEAR_SHARE)
		get_parent().add_child(gear)
		gear.global_position = global_position + Vector2(0, -50)


## Dugattyú-rengés: a gép a földbe döngöl, és rengések sora fut végig feléd.
func _pistons() -> void:
	Audio.play("engine_stomp", 2.0)
	var start := global_position
	var dir := start.direction_to(_player.global_position)
	for i in PISTONS:
		if not is_physics_processing():
			return
		var at := start + dir * PISTON_STEP * (i + 1)
		var marker := TargetMarker.new()
		marker.radius = PISTON_RADIUS
		marker.color = Color(1, 0.6, 0.2)
		marker.time = 0.45
		get_parent().add_child(marker)
		marker.global_position = at
		marker.landed.connect(_piston_hit.bind(at))
		await get_tree().create_timer(PISTON_DELAY, false).timeout


func _piston_hit(at: Vector2) -> void:
	if not is_inside_tree():
		return
	Audio.play("engine_stomp", -6.0, 0.2)
	var ring := Shockwave.new()
	ring.radius = PISTON_RADIUS
	ring.position = get_parent().to_local(at)
	get_parent().add_child(ring)
	_burst(get_parent().to_local(at), PISTON_RADIUS, roundi(stats["damage"] * PISTON_SHARE), 360.0)


## Tesla-villámok: egymás után oda csapnak le, ahol éppen állsz.
func _tesla() -> void:
	for i in TESLA_STRIKES:
		if not is_physics_processing() or not is_instance_valid(_player):
			return
		var at := _player.global_position
		var marker := TargetMarker.new()
		marker.radius = TESLA_RADIUS
		marker.color = Color(0.45, 0.85, 1.0)
		marker.time = TESLA_FUSE
		get_parent().add_child(marker)
		marker.global_position = at
		marker.landed.connect(_tesla_hit.bind(at))
		Audio.play("engine_beep", -10.0, 0.3)
		await get_tree().create_timer(TESLA_DELAY, false).timeout


func _tesla_hit(at: Vector2) -> void:
	if not is_inside_tree():
		return
	Audio.play("engine_zap", -2.0, 0.15)
	var bolt := LightningBolt.new()
	bolt.position = get_parent().to_local(at)
	get_parent().add_child(bolt)
	_burst(get_parent().to_local(at), TESLA_RADIUS, roundi(stats["damage"] * TESLA_SHARE), 200.0)


## Mágnes: magához húz (amíg búg), aztán nagyot dobbant.
func _magnet() -> void:
	Audio.play("engine_magnet", 2.0)
	var field := MagnetField.new()
	field.source = self
	field.time = MAGNET_TIME
	get_parent().add_child(field)
	var left := MAGNET_TIME
	while left > 0.0:
		if not is_physics_processing():
			return
		var target := _player
		if is_instance_valid(target) and not net_puppet:
			var pull := target.global_position.direction_to(global_position) * MAGNET_PULL
			target.set("_knockback", pull)
		await get_tree().physics_frame
		left -= get_physics_process_delta_time()
	_slam()
	Audio.play("engine_stomp", 4.0)


## Rövid ideig élő, kör alakú sebző terület (a játékost sebzi).
func _burst(at: Vector2, radius: float, damage: int, push: float) -> void:
	var area := Hitbox.new()
	area.damage = damage
	area.knockback = push
	area.collision_layer = 16
	area.collision_mask = 0
	area.set_meta("source", self)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	area.add_child(shape)
	area.position = at
	get_parent().add_child(area)
	get_tree().create_timer(0.18, false).timeout.connect(area.queue_free)


func _on_died() -> void:
	Audio.play("engine_die")
	Audio.play("engine_steam", -2.0)
	super._on_died()


## Forró gőzfelhő: táguló, fehér pamacsok gyűrűje, ami elhalványul.
class SteamCloud:
	extends Node2D
	var radius := 120.0
	var _t := 0.0
	var _seed := randf() * TAU

	func _ready() -> void:
		z_index = 2

	func _process(delta: float) -> void:
		_t += delta / 0.7
		if _t >= 1.0:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var r := radius * ease(_t, 0.5)
		var alpha := 1.0 - _t
		draw_circle(Vector2.ZERO, r, Color(1, 1, 1, 0.12 * alpha))
		for i in 16:
			var angle := _seed + TAU * i / 16.0
			var puff := Vector2.from_angle(angle) * r * Vector2(1.0, 0.65)
			draw_circle(puff + Vector2(0, -10), 14.0 + 6.0 * sin(angle * 3.0 + _t * 4.0), Color(0.95, 0.95, 0.92, 0.5 * alpha))


## Pörgő fogaskerék-fűrész: kirepül, majd visszatér a géphez (oda-vissza is sebez).
class GearSaw:
	extends Hitbox
	var direction := Vector2.RIGHT
	var reach := 300.0
	var speed := 260.0
	var source: Node2D
	var _travelled := 0.0
	var _returning := false
	var _spin := 0.0

	func _ready() -> void:
		knockback = 220.0
		collision_layer = 16
		collision_mask = 0
		z_index = 3
		set_meta("source", source)
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 16.0
		shape.shape = circle
		add_child(shape)

	func _physics_process(delta: float) -> void:
		_spin += delta * 14.0
		queue_redraw()
		if not _returning:
			global_position += direction * speed * delta
			_travelled += speed * delta
			if _travelled >= reach:
				_returning = true
			return
		if not is_instance_valid(source) or not source.is_inside_tree():
			queue_free()
			return
		var home := source.global_position + Vector2(0, -50)
		global_position = global_position.move_toward(home, speed * 1.2 * delta)
		if global_position.distance_to(home) < 12.0:
			queue_free()

	func _draw() -> void:
		var teeth := PackedVector2Array()
		for i in 20:
			var angle := _spin + TAU * i / 20.0
			teeth.append(Vector2.from_angle(angle) * (16.0 if i % 2 == 0 else 11.0))
		draw_colored_polygon(teeth, Color(0.78, 0.6, 0.28))
		draw_polyline(teeth + PackedVector2Array([teeth[0]]), Color(0.3, 0.18, 0.06), 1.5)
		draw_circle(Vector2.ZERO, 5.0, Color(0.35, 0.22, 0.1))


## Villám az égből: cikcakkos, kékesfehér vonal, ami gyorsan elhalványul.
class LightningBolt:
	extends Node2D
	var _t := 0.0
	var _points := PackedVector2Array()

	func _ready() -> void:
		z_index = 4
		var y := -420.0
		var x := 0.0
		while y < 0.0:
			_points.append(Vector2(x, y))
			y += randf_range(30.0, 55.0)
			x = randf_range(-18.0, 18.0)
		_points.append(Vector2.ZERO)

	func _process(delta: float) -> void:
		_t += delta / 0.3
		if _t >= 1.0:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var alpha := 1.0 - _t
		draw_polyline(_points, Color(0.5, 0.85, 1.0, 0.6 * alpha), 7.0)
		draw_polyline(_points, Color(0.95, 1.0, 1.0, alpha), 2.5)
		draw_circle(Vector2.ZERO, 30.0 * (1.0 - _t * 0.5), Color(0.6, 0.9, 1.0, 0.35 * alpha))


## Mágneses mező: lila ívek a gép és a játékos között, amíg húz.
class MagnetField:
	extends Node2D
	var source: Node2D
	var time := 1.6
	var _t := 0.0

	func _ready() -> void:
		z_index = 3

	func _process(delta: float) -> void:
		_t += delta
		if _t >= time or not is_instance_valid(source):
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player == null:
			return
		var from := to_local(source.global_position + Vector2(0, -60))
		var to := to_local(player.global_position + Vector2(0, -20))
		for i in 3:
			var points := PackedVector2Array()
			for j in 9:
				var k := j / 8.0
				var bend := sin(k * PI) * (18.0 + i * 10.0) * sin(_t * 9.0 + i * 2.0)
				points.append(from.lerp(to, k) + (to - from).orthogonal().normalized() * bend)
			draw_polyline(points, Color(1.0, 0.45, 0.95, 0.55), 2.0)
		draw_circle(from, 10.0 + 3.0 * sin(_t * 12.0), Color(1.0, 0.5, 1.0, 0.4))
