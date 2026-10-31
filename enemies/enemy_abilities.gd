class_name EnemyAbilities
extends Node
## Az ellenségek különleges képességei. A típus "abilities" listája dönti el,
## melyik ellenség mit tud (lásd EnemyTypes). Minden ellenségnek van ilyen
## csomópontja (üres listával is), hogy a harci kiáltás őt is felgyorsíthassa.
##
##   zigzag       cikázva közelít, nehezebb eltalálni
##   teleport     felvillan, majd a játékos mellé / mögé ugrik
##   summon       csontvázakat idéz (legfeljebb SUMMON_LIMIT-et); a típus "summon" kulcsa mást is megadhat
##   heal         a közeli sérült társait gyógyítja
##   war_cry      harci kiáltás: a közeli társai rövid ideig gyorsabbak
##   berserk      fél élet alatt dühöng: sokkal gyorsabb és vöröses
##   death_burst  halálakor lövedékek repülnek szét belőle minden irányba
##   regenerate   lassan visszatölti az életét
##   poison       a találata megmérgez: pár mp-ig másodpercenként sebződsz (zöld)
##   frost        a találata megfagyaszt: pár mp-ig lassabban mozogsz (kékes)
##   plunder      a találata aranyat lop tőled; ha megölöd, visszakapod (és még egy kicsit)
##   shield       időnként SHIELD_POINTS pontos pajzsot von maga köré: amíg van pajzspontja, az ütések
##                csak azt fogyasztják (a sebzés SHIELD_DAMAGE_SHARE részével), az életereje nem fogy;
##                ha elfogy, a pajzs lejön
##   explode      ha a közeledbe ér, felvillan és felrobban (a robbanás téged is megsebez)

const MAGIC_BOLT := preload("res://enemies/magic_bolt.tscn")
## Ennyi ideig villog, mielőtt képességet használ (ilyenkor áll): ennyi időd van reagálni.
const WINDUP := 0.45
const WINDUP_COLORS := {
	"teleport": Color(1.8, 0.8, 2.6), "summon": Color(0.8, 2.0, 1.0),
	"heal": Color(0.9, 2.2, 0.9), "war_cry": Color(2.4, 1.4, 0.5),
	"shield": Color(1.0, 1.8, 2.6),
}
## Két használat között eltelt idő (mp), [min, max].
const COOLDOWNS := {
	"teleport": Vector2(3.5, 5.5), "summon": Vector2(6.0, 8.0),
	"heal": Vector2(3.5, 4.5), "war_cry": Vector2(6.0, 8.0),
	"shield": Vector2(7.0, 9.0),
}
## Ennél messzebbről nem használja a képességeit.
const ACTIVE_RANGE := 420.0
const ZIGZAG_ANGLE := 0.9
const ZIGZAG_FREQUENCY := 6.0
const TELEPORT_DISTANCE := Vector2(90, 140)
const SUMMON_TYPE := "skelet"
const SUMMON_COUNT := 2
const SUMMON_LIMIT := 4
const HEAL_RADIUS := 170.0
const WAR_CRY_RADIUS := 220.0
const HASTE_TIME := 3.0
const HASTE_MULTIPLIER := 1.45
const BERSERK_MULTIPLIER := 1.6
const BERSERK_TINT := Color(1.4, 0.6, 0.55)
const BURST_BOLTS := 8
const BURST_SPEED := 190.0
const REGEN_PER_SECOND := 0.6
const POISON_TIME := 3.0
const FROST_TIME := 2.0
## Ennyi aranyat lop egy találattal (+ emeletenként egy kicsit), legfeljebb amennyi nálad van.
const PLUNDER_GOLD := 4
const SHIELD_POINTS := 30
## A pajzsot a sebzés ennyied része fogyasztja.
const SHIELD_DAMAGE_SHARE := 0.8
const SHIELD_COLOR := Color(0.55, 0.85, 1.0)
const EXPLODE_TRIGGER := 70.0
const EXPLODE_RADIUS := 95.0
const EXPLODE_WINDUP := 0.6
const COIN := preload("res://pickups/coin.tscn")

var enemy: CharacterBody2D
var abilities: Array = []

var _cooldowns := {}
var _busy := false
var _zigzag_time := 0.0
var _haste_left := 0.0
var _berserk := false
var _summoned := 0
## A pajzs hátralévő pontjai (0 = nincs pajzs).
var shield_points := 0
var _shield: Node2D
var _exploding := false
## A fosztogató által ellopott arany (halálakor visszaesik).
var _stolen := 0


func setup(owner_enemy: CharacterBody2D, list: Array) -> void:
	enemy = owner_enemy
	abilities = list
	_zigzag_time = randf() * TAU
	for ability: String in COOLDOWNS:
		var range_pair: Vector2 = COOLDOWNS[ability]
		_cooldowns[ability] = randf_range(range_pair.x * 0.4, range_pair.y * 0.6)
	var health: Health = enemy.get_node("Health")
	if has("regenerate"):
		health.regen_per_second = REGEN_PER_SECOND
	if has("berserk"):
		health.changed.connect(_on_health_changed)


func has(ability: String) -> bool:
	return abilities.has(ability)


## Képesség használata közben (felvillanás) az ellenség áll.
func is_busy() -> bool:
	return _busy


## A sebesség szorzója (harci kiáltás, dühöngés).
func speed_multiplier() -> float:
	var multiplier := 1.0
	if _haste_left > 0.0:
		multiplier *= HASTE_MULTIPLIER
	if _berserk:
		multiplier *= BERSERK_MULTIPLIER
	return multiplier


## A mozgás iránya a képességek után (cikázás).
func steer(dir: Vector2, delta: float) -> Vector2:
	if not has("zigzag") or dir == Vector2.ZERO:
		return dir
	_zigzag_time += delta * ZIGZAG_FREQUENCY
	return dir.rotated(sin(_zigzag_time) * ZIGZAG_ANGLE)


## Harci kiáltás hatása (egy társ hívja).
func haste(seconds: float) -> void:
	_haste_left = maxf(_haste_left, seconds)


## Pajzs alatt semmi nem sebzi.
func is_shielded() -> bool:
	return shield_points > 0


## Egy találat a pajzsot éri: a sebzés SHIELD_DAMAGE_SHARE része (legalább 1) fogy a pajzsból;
## visszaadja, mennyi fogyott. Ha elfogy, a pajzs lejön.
func absorb(damage: int) -> int:
	var amount := maxi(1, roundi(damage * SHIELD_DAMAGE_SHARE))
	amount = mini(amount, shield_points)
	set_shield_points(shield_points - amount)
	if shield_points <= 0:
		Audio.play("door_unlock", -6.0, 0.3)
		FloatingText.spawn(enemy.get_parent(), _head(), "Pajzs széttört!", SHIELD_COLOR, 20)
	return amount


## A pajzspontok beállítása (közös játékban a báb így követi a gazda szörnyét): a buborék
## megjelenik / eltűnik, és halványul, ahogy fogy.
func set_shield_points(points: int) -> void:
	shield_points = maxi(points, 0)
	if shield_points <= 0:
		if is_instance_valid(_shield):
			_shield.queue_free()
		_shield = null
		return
	if not is_instance_valid(_shield):
		_shield = ShieldBubble.new()
		var size: Vector2 = enemy.get("_type")["rect"].size * 2.0 * float(enemy.get("_size_scale"))
		_shield.set("radius", maxf(size.x, size.y) * 0.6)
		_shield.position = Vector2(0, -size.y / 2.0)
		enemy.add_child(_shield)
	_shield.set("strength", float(shield_points) / SHIELD_POINTS)


func _physics_process(delta: float) -> void:
	_haste_left -= delta
	if _busy or not enemy.is_physics_processing():
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or enemy.global_position.distance_to(player.global_position) > ACTIVE_RANGE:
		return
	if has("explode") and not _exploding 			and enemy.global_position.distance_to(player.global_position) < EXPLODE_TRIGGER:
		_explode(player)
		return
	for ability: String in abilities:
		if not _cooldowns.has(ability):
			continue
		_cooldowns[ability] -= delta
		if _cooldowns[ability] <= 0.0 and _worth_using(ability):
			var range_pair: Vector2 = COOLDOWNS[ability]
			_cooldowns[ability] = randf_range(range_pair.x, range_pair.y)
			_use(ability, player)
			return


func _worth_using(ability: String) -> bool:
	match ability:
		"summon": return _summoned < int(_summon_spec().get("limit", SUMMON_LIMIT))
		"heal": return not _hurt_allies().is_empty()
		"war_cry": return _allies_within(WAR_CRY_RADIUS).size() > 0
		"shield": return not is_shielded()
	return true


func _use(ability: String, player: Node2D) -> void:
	_busy = true
	# A teleport célja már a felvillanás előtt eldől: piros X jelzi, hová ugrik.
	var target := _teleport_target(player) if ability == "teleport" else Vector2.ZERO
	if ability == "teleport":
		DangerMark.cross(enemy.get_parent(), target, WINDUP)
	var visual: Node2D = enemy.get_node("Visual")
	var flash := create_tween()
	flash.tween_property(visual, "modulate", WINDUP_COLORS[ability], WINDUP)
	await flash.finished
	visual.modulate = Color.WHITE
	_busy = false
	if not enemy.is_physics_processing() or not is_instance_valid(player):
		return
	match ability:
		"teleport": _teleport(target)
		"summon": _summon()
		"heal": _heal()
		"war_cry": _war_cry()
		"shield": _raise_shield()


func _teleport_target(player: Node2D) -> Vector2:
	var room := _room()
	var side := Vector2.from_angle(randf() * TAU)
	var target := player.global_position + side * randf_range(TELEPORT_DISTANCE.x, TELEPORT_DISTANCE.y)
	if room != null:
		target = room.safe_spawn_position(target)
	return target


func _teleport(target: Vector2) -> void:
	Audio.play("magic", -6.0)
	_puff(enemy.global_position)
	enemy.global_position = target
	_puff(target)


func _summon() -> void:
	var room := _room()
	if room == null:
		return
	Audio.play("boss_roar", -12.0, 0.3)
	var spec := _summon_spec()
	var count := int(spec.get("count", SUMMON_COUNT))
	_summoned += count
	room.summon_minions(str(spec.get("type", SUMMON_TYPE)), count, enemy.global_position)
	FloatingText.spawn(enemy.get_parent(), _head(), str(spec.get("text", "Ébredjetek!")),
		Color(0.85, 0.55, 1) if spec.has("type") else Color(0.6, 1, 0.6))


## A típus saját idézése ("summon": {type, count, limit, text}, pl. a Káoszszövő káoszivadékot idéz); üres = csontvázak.
func _summon_spec() -> Dictionary:
	var type: Dictionary = enemy.get("_type")
	return type.get("summon", {})


func _heal() -> void:
	var amount := 2 + int(enemy.get("_depth")) / 2
	Audio.play("xp", 2.0)
	for ally in _hurt_allies():
		var health: Health = ally.get_node("Health")
		health.heal(amount)
		FloatingText.spawn(ally.get_parent(), ally.global_position + Vector2(0, -40), "+%d" % amount, Color(0.4, 1, 0.4))


func _war_cry() -> void:
	Audio.play("boss_roar", -10.0, 0.2)
	FloatingText.spawn(enemy.get_parent(), _head(), "Rohamra!", Color(1, 0.7, 0.3))
	haste(HASTE_TIME)
	for ally in _allies_within(WAR_CRY_RADIUS):
		var other := ally.get_node_or_null("Abilities") as EnemyAbilities
		if other:
			other.haste(HASTE_TIME)


func _on_health_changed(current: int, maximum: int) -> void:
	if _berserk or current <= 0 or current > maximum / 2:
		return
	_berserk = true
	enemy.get_node("Visual/AnimatedSprite2D").self_modulate *= BERSERK_TINT
	FloatingText.spawn(enemy.get_parent(), _head(), "Dühöng!", Color(1, 0.35, 0.25))


## Az ellenség találata (közelharc vagy lövedék) a játékost: méreg, fagy, fosztogatás.
func on_hit_player(player: Node2D) -> void:
	if not is_instance_valid(player):
		return
	if has("poison"):
		player.call("apply_poison", POISON_TIME)
	if has("frost"):
		player.call("apply_slow", FROST_TIME)
	if has("plunder"):
		var taken: int = player.call("lose_gold", PLUNDER_GOLD + int(enemy.get("_depth")) / 2)
		if taken > 0:
			# Báb: a zsákmányt a gazda igazi szörnye viszi (ő ejti el a halálakor, mindenkinél).
			var net := NetEnemies.active(enemy.get_tree())
			if bool(enemy.get("net_puppet")) and net != null:
				net.report_plunder(enemy, taken)
			else:
				_stolen += taken
			Audio.play("coin", -6.0, 0.3)
			FloatingText.spawn(enemy.get_parent(), _head(), "-%d arany!" % taken, Color(1, 0.8, 0.2))


func _raise_shield() -> void:
	Audio.play("magic", -8.0, 0.2)
	set_shield_points(SHIELD_POINTS)


## Kamikaze: megáll, vörösen felvillan, aztán felrobban (ő maga is meghal).
func _explode(player: Node2D) -> void:
	_exploding = true
	_busy = true
	var visual: Node2D = enemy.get_node("Visual")
	var flash := create_tween().set_loops(3)
	flash.tween_property(visual, "modulate", Color(3, 0.8, 0.5), EXPLODE_WINDUP / 6.0)
	flash.tween_property(visual, "modulate", Color.WHITE, EXPLODE_WINDUP / 6.0)
	await get_tree().create_timer(EXPLODE_WINDUP, false).timeout
	if not is_instance_valid(enemy) or not enemy.is_physics_processing():
		return
	Audio.play("boss_slam", -4.0)
	_blast(enemy.global_position + Vector2(0, -12))
	if is_instance_valid(player) and player.global_position.distance_to(enemy.global_position) < EXPLODE_RADIUS:
		var blast := Hitbox.new()
		blast.damage = roundi(int(enemy.get("stats")["damage"]) * 1.5)
		blast.knockback = 520.0
		enemy.get_parent().add_child(blast)
		blast.global_position = enemy.global_position
		player.call("_on_hurt", blast)
		blast.queue_free()
	_busy = false
	enemy.get_node("Health").damage(99999, false)


func _blast(at: Vector2) -> void:
	var fire := CPUParticles2D.new()
	fire.one_shot = true
	fire.emitting = true
	fire.amount = 40
	fire.lifetime = 0.55
	fire.explosiveness = 1.0
	fire.spread = 180.0
	fire.initial_velocity_min = 80.0
	fire.initial_velocity_max = 220.0
	fire.scale_amount_min = 4.0
	fire.scale_amount_max = 8.0
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 0.9, 0.4))
	gradient.set_color(1, Color(0.6, 0.15, 0.05, 0))
	fire.color_ramp = gradient
	enemy.get_parent().add_child(fire)
	fire.global_position = at
	get_tree().create_timer(1.2, false).timeout.connect(fire.queue_free)


## Közös játék, gazda: egy vendég bábja lopott (lásd NetEnemies.report_plunder).
func add_stolen(amount: int) -> void:
	_stolen += amount


## Halálkor hívja az ellenség.
func on_died() -> void:
	if _stolen > 0:
		# A fosztogató elejti a zsákmányt (és egy kis ráadást).
		var coin = COIN.instantiate()
		coin.value = _stolen + 2
		coin.position = enemy.position + Vector2(0, -8)
		enemy.get_parent().add_child.call_deferred(coin)
	if not has("death_burst"):
		return
	Audio.play("magic", -4.0)
	var offset := randf() * TAU
	for i in BURST_BOLTS:
		var bolt = MAGIC_BOLT.instantiate()
		bolt.direction = Vector2.from_angle(offset + TAU * i / BURST_BOLTS)
		bolt.speed = BURST_SPEED
		bolt.damage = maxi(1, int(enemy.get("stats")["damage"]) - 1)
		enemy.get_parent().add_child.call_deferred(bolt)
		bolt.position = enemy.position + Vector2(0, -16)


func _allies_within(radius: float) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for other in enemy.get_parent().get_children():
		if other != enemy and other is CharacterBody2D and other.is_in_group("enemies") \
				and other.global_position.distance_to(enemy.global_position) <= radius \
				and not other.get_node("Health").is_dead():
			result.append(other)
	return result


func _hurt_allies() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for ally in _allies_within(HEAL_RADIUS):
		var health: Health = ally.get_node("Health")
		if health.current < health.max_health:
			result.append(ally)
	return result


func _room() -> Room:
	return enemy.get_parent().get_parent() as Room


func _head() -> Vector2:
	return enemy.global_position + Vector2(0, -48)


## Kis lila füstfelhő a teleportnál.
func _puff(at: Vector2) -> void:
	var puff := CPUParticles2D.new()
	puff.one_shot = true
	puff.emitting = true
	puff.amount = 14
	puff.lifetime = 0.45
	puff.explosiveness = 1.0
	puff.spread = 180.0
	puff.initial_velocity_min = 40.0
	puff.initial_velocity_max = 90.0
	puff.gravity = Vector2(0, -40)
	puff.scale_amount_min = 3.0
	puff.scale_amount_max = 5.0
	puff.color = Color(0.75, 0.45, 1.0, 0.8)
	enemy.get_parent().add_child(puff)
	puff.global_position = at + Vector2(0, -16)
	get_tree().create_timer(1.0, false).timeout.connect(puff.queue_free)


## Áttetsző kék pajzsbuborék az ellenség körül (a pajzs képesség ideje alatt).
class ShieldBubble:
	extends Node2D
	var radius := 24.0
	## 0..1: mennyi pajzspont maradt (fogyáskor halványabb).
	var strength := 1.0
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var pulse := 0.85 + 0.15 * sin(_time * 8.0)
		var alpha := 0.35 + 0.65 * strength
		draw_circle(Vector2.ZERO, radius * pulse, Color(SHIELD_COLOR, 0.22 * alpha))
		draw_arc(Vector2.ZERO, radius * pulse, 0.0, TAU, 32, Color(SHIELD_COLOR, 0.8 * alpha), 2.0)
