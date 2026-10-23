class_name Spells
## A varázsló (Lőrinc) varázslatai. A kazamatába lépve kiválasztja az elsőt (SpellPicker); minden
## 5. szintlépéskor fejlesztheti valamelyiket (legfeljebb MAX_LEVEL szintig), vagy megtanulhat egy újat
## (legfeljebb MAX_SPELLS). Az első fejlesztés (2. szint) csak sebzést ad; a többlet gömb / tüske / ugrás
## a 3. szinttől jár.
## Az első az elsődleges támadása (bal egérgomb), a második a jobb egérgombon; mindkettő a saját töltési idejével, külön.
## Minden varázslat Elemi sebzéssel sebez (Stats.elemental_damage, csak a varázslónak).
## Az állapot a futás része: GameState.spells (sorrendben) és GameState.spell_levels.
##
##   bolt    Varázsgömb: lila gömb a kurzor felé (a 3. szinttől szintenként +1 gömb legyezőben)
##   fire    Tűzgolyó: lassabb, de felgyújtja az ellenséget (égés: sebez és lángol rajta)
##   spikes  Földtüskék: a kurzor irányában tőled indulva tüskék nőnek ki a földből, ellökve és
##           megsebezve minden szörnyet (a 3. szinttől szintenként +1 tüske)
##   chain   Láncvillám: gyenge villám a kurzorhoz legközelebbi szörnyre, ami utána fele annyi
##           sebzéssel továbbugrik a következőre (a 3. szinttől szintenként +1 ugrás)

const MAX_SPELLS := 2
## Egy varázslat legmagasabb szintje.
const MAX_LEVEL := 4
## Ennyi szintenként jön a varázslat-választás (fejlesztés vagy új).
const SPELL_LEVEL_EVERY := 5
const PLAYER_ARROW := preload("res://player/player_arrow.gd")

const ALL := {
	"bolt": {"name": "Varázsgömb", "icon_path": "res://assets/ui/spell_bolt.png", "cooldown": 1.0, "power": 1.0,
		"text": "Lila varázsgömb repül a kurzor felé.", "short": "Lila gömb a kurzor felé.",
		"upgrade": "+20% sebzés", "upgrade_more": "+1 gömb, +20% sebzés"},
	"fire": {"name": "Tűzgolyó", "icon_path": "res://assets/ui/spell_fire.png", "cooldown": 1.8, "power": 1.05,
		"text": "Lassabb, de felgyújtja az ellenséget: égés közben is sebződik.",
		"short": "Lassabb, de felgyújt: az ellenség ég.", "upgrade": "+20% sebzés",
		"upgrade_more": "+20% sebzés, erősebb égés"},
	"spikes": {"name": "Földtüskék", "icon_path": "res://assets/ui/spell_spikes.png", "cooldown": 1.4, "power": 1.0,
		"text": "A kurzor irányában 3 tüske nő ki a földből: ellöki és megsebzi a szörnyeket.",
		"short": "3 tüske nő ki: ellök és sebez.", "upgrade": "+15% sebzés", "upgrade_more": "+1 tüske, +15% sebzés"},
	"chain": {"name": "Láncvillám", "icon_path": "res://assets/ui/spell_chain.png", "cooldown": 1.3, "power": 0.75,
		"text": "Gyenge villám a kurzorhoz legközelebbi szörnyre, ami fele annyi sebzéssel a következőre ugrik.",
		"short": "Villám, ami fele sebzéssel továbbugrik.", "upgrade": "+20% sebzés",
		"upgrade_more": "+1 ugrás, +20% sebzés"},
}
## Láncvillám: ilyen messze talál (a hatótáv-statisztikával), ilyen szögben a kurzor körül,
## és ilyen messzire ugrik tovább.
const CHAIN_RANGE := 340.0
const CHAIN_CONE := 0.6
const CHAIN_JUMP := 170.0
## Ha a falba ütköző sugár ennyire megközelíti a szörnyet, az még találat.
const CHAIN_WALL_SLACK := 22.0


static func level(spell: String) -> int:
	return int(GameState.spell_levels.get(spell, 1))


## A szinttel járó többlet (gömb / tüske / ugrás / erősebb égés): az első fejlesztés még nem ad.
static func _extra(spell: String) -> int:
	return maxi(0, level(spell) - 2)


## Mit ad a következő fejlesztés ("" ha már a legmagasabb szinten van).
static func upgrade_text(spell: String) -> String:
	if level(spell) >= MAX_LEVEL:
		return ""
	return ALL[spell]["upgrade"] if level(spell) == 1 else ALL[spell]["upgrade_more"]


## A varázslat cooldownja a karakter ütési idejéhez képest.
static func cooldown_multiplier(spell: String) -> float:
	return float(ALL[spell]["cooldown"])


## Egy találat sebzése: az (elemi) alapsebzés a varázslat erejével és szintjével szorozva.
static func damage(spell: String, base_hit: int) -> int:
	var per_level := 0.15 if spell == "spikes" else 0.2
	return maxi(1, roundi(base_hit * float(ALL[spell]["power"]) * (1.0 + per_level * (level(spell) - 1))))


## Varázsgömb: ennyi gömb repül egyszerre (a 3. szinttől szintenként +1).
static func bolt_count(spell: String) -> int:
	return 1 + _extra(spell)


## Tűzgolyó: az égés hossza (mp) és félmásodpercenkénti sebzése a találat sebzéséből.
static func burn_time(spell: String) -> float:
	return 2.0 + 0.5 * _extra(spell)


static func burn_damage(spell: String, hit: int) -> int:
	return maxi(1, roundi(hit * (0.2 + 0.04 * _extra(spell))))


## Földtüskék: ennyi tüske nő ki (a 3. szinttől szintenként +1).
static func spike_count(spell: String) -> int:
	return 3 + _extra(spell)


## Láncvillám: ennyiszer ugrik tovább (a 3. szinttől szintenként +1).
static func chain_jumps(spell: String) -> int:
	return 1 + _extra(spell)


## A varázslat elsütése (Player hívja): a lövedékek / tüskék a játékos szülőjébe kerülnek.
static func cast(player: Node2D, spell: String, aim: Vector2) -> void:
	var direction := aim.normalized() if aim.length() > 0.001 else Vector2.RIGHT
	var hit: int = damage(spell, player.call("hit_damage"))
	var stats: Stats = player.get_node("Stats")
	match spell:
		"bolt":
			Audio.play("magic", -4.0, 0.15)
			var count := bolt_count(spell)
			for i in count:
				var k := i - (count - 1) / 2.0
				_projectile(player, direction.rotated(deg_to_rad(10.0) * k), hit, stats, "orb")
		"fire":
			Audio.play("magic", -2.0, 0.05)
			var ball := _projectile(player, direction, hit, stats, "fire")
			ball.speed = 420.0
			# Égés: másodpercenként ennyit sebez, ennyi ideig.
			ball.set_meta("burn_time", burn_time(spell))
			ball.set_meta("burn_damage", burn_damage(spell, hit))
		"spikes":
			_spikes(player, direction, hit, spike_count(spell))
		"chain":
			_chain(player, direction, hit, chain_jumps(spell), stats)


static func _projectile(player: Node2D, direction: Vector2, hit: int, stats: Stats, look: String) -> Area2D:
	var shot: Area2D = PLAYER_ARROW.new()
	shot.look = look
	shot.direction = direction
	shot.speed = 480.0
	shot.max_distance = 440.0 * stats.attack_range / 100.0
	shot.damage = hit
	shot.crit_chance = stats.crit_chance / 100.0
	shot.crit_multiplier = player.call("weapon_crit_multiplier")
	shot.knockback = 160.0
	shot.set_meta("source", player)
	player.get_parent().add_child(shot)
	shot.global_position = player.global_position + Vector2(0, -20) + direction * 18.0
	shot.origin = player.global_position + Vector2(0, -6)
	return shot


## Tüskék a kurzor irányában, egymás után kinőve (a falnál megállnak).
static func _spikes(player: Node2D, direction: Vector2, hit: int, count: int) -> void:
	Audio.play("boss_slam", -8.0, 0.2)
	var parent := player.get_parent()
	var start := player.global_position + Vector2(0, -4)
	for i in count:
		var at := start + direction * (52.0 + i * 46.0)
		var query := PhysicsPointQueryParameters2D.new()
		query.position = at
		query.collision_mask = 1
		if not player.get_world_2d().direct_space_state.intersect_point(query, 1).is_empty():
			break
		var spike := EarthSpike.new()
		spike.damage = hit
		spike.knockback = 460.0
		spike.set_meta("source", player)
		parent.add_child(spike)
		spike.global_position = at
		await player.get_tree().create_timer(0.07, false).timeout
		if not is_instance_valid(player):
			return


## Láncvillám: a kurzor irányába eső legközelebbi szörnyre csap, aztán (fele annyi sebzéssel)
## a hozzá legközelebbi, még nem talált szörnyre ugrik, `jumps`-szor. Ha nincs célpont, a villám
## a kurzor felé a falig / a hatótávig csap.
static func _chain(player: Node2D, direction: Vector2, hit: int, jumps: int, stats: Stats) -> void:
	Audio.play("magic", -3.0, 0.25)
	var parent := player.get_parent()
	var from := player.global_position + Vector2(0, -20) + direction * 14.0
	# Fal mellett a pálca hegye a falban lehet: akkor a villám a testéből indul (mint a lövedékek).
	if _in_wall(player, from):
		from = player.global_position + Vector2(0, -6)
	var reach := CHAIN_RANGE * stats.attack_range / 100.0
	var target := _chain_first(player, from, direction, reach)
	if target == null:
		var end := _ray_end(player, from, from + direction * reach)
		_arc(parent, from, end)
		return
	var struck: Array[Node2D] = []
	var damage := hit
	for i in jumps + 1:
		var to := _enemy_center(target)
		_arc(parent, from, to)
		_strike(player, target, from, damage, stats)
		struck.append(target)
		if i == jumps:
			return
		await player.get_tree().create_timer(0.09, false).timeout
		if not is_instance_valid(player):
			return
		from = to
		damage = maxi(1, damage / 2)
		target = _chain_next(player, from, struck)
		if target == null:
			return


## Az első célpont: a hatótávon belül, a kurzor irányától legfeljebb CHAIN_CONE szögre, látható.
static func _chain_first(player: Node2D, from: Vector2, direction: Vector2, reach: float) -> Node2D:
	var best: Node2D = null
	var best_score := INF
	for enemy: Node2D in _living_enemies(player):
		var to := _enemy_center(enemy) - from
		var angle := absf(direction.angle_to(to))
		if to.length() > reach or angle > CHAIN_CONE or not _sees(player, from, enemy):
			continue
		var score := to.length() * (1.0 + angle * 2.0)
		if score < best_score:
			best_score = score
			best = enemy
	return best


static func _chain_next(player: Node2D, from: Vector2, struck: Array[Node2D]) -> Node2D:
	var best: Node2D = null
	var best_distance := CHAIN_JUMP
	for enemy: Node2D in _living_enemies(player):
		if enemy in struck:
			continue
		var at := _enemy_center(enemy)
		var distance := from.distance_to(at)
		if distance < best_distance and _sees(player, from, enemy):
			best_distance = distance
			best = enemy
	return best


static func _living_enemies(player: Node2D) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for node in player.get_tree().get_nodes_in_group("enemies"):
		var hurtbox := node.get_node_or_null("Hurtbox") as Area2D
		if node is Node2D and hurtbox != null and hurtbox.monitoring and hurtbox.has_signal("hurt"):
			result.append(node)
	return result


static func _enemy_center(enemy: Node2D) -> Vector2:
	var shape := enemy.get_node_or_null("Hurtbox/CollisionShape2D") as Node2D
	return shape.global_position if shape != null else enemy.global_position + Vector2(0, -12)


## Látható-e a szörny: a fal előtt álló szörny teste (a találati területe) belelóghat a fal
## ütközési sávjába, ezért a lába is számít, és az is, ha a sugár közvetlenül előtte áll meg.
static func _sees(player: Node2D, from: Vector2, enemy: Node2D) -> bool:
	for at: Vector2 in [_enemy_center(enemy), enemy.global_position + Vector2(0, -2)]:
		if _ray_end(player, from, at).distance_to(at) < CHAIN_WALL_SLACK:
			return true
	return false


static func _in_wall(player: Node2D, at: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = at
	query.collision_mask = 1
	return not player.get_world_2d().direct_space_state.intersect_point(query, 1).is_empty()


## A faltól megállított végpont (1-es réteg: falak).
static func _ray_end(player: Node2D, from: Vector2, to: Vector2) -> Vector2:
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	var result := player.get_world_2d().direct_space_state.intersect_ray(query)
	return to if result.is_empty() else Vector2(result["position"])


## Egy villám-találat: rövid életű Hitbox a szörny mellett, amit a szörny Hurtbox-a "megkap".
static func _strike(player: Node2D, enemy: Node2D, from: Vector2, damage: int, stats: Stats) -> void:
	var bolt := Hitbox.new()
	bolt.damage = damage
	bolt.knockback = 60.0
	bolt.crit_chance = stats.crit_chance / 100.0
	bolt.crit_multiplier = player.call("weapon_crit_multiplier")
	bolt.set_meta("source", player)
	enemy.get_parent().add_child(bolt)
	# A villám felől: a szörnyet kicsit a becsapódás irányába löki.
	bolt.global_position = enemy.global_position - from.direction_to(enemy.global_position) * 8.0
	enemy.get_node("Hurtbox").emit_signal("hurt", bolt)
	bolt.queue_free()


static func _arc(parent: Node, from: Vector2, to: Vector2) -> void:
	var arc := LightningArc.new()
	arc.from = from
	arc.to = to
	parent.add_child(arc)


## A varázslat-választás kártyái (minden 5. szinten): a meglévők fejlesztése, és ha még van
## hely, egy új megtanulása.
static func level_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for spell: String in GameState.spells:
		if level(spell) >= MAX_LEVEL:
			continue
		var definition: Dictionary = ALL[spell]
		options.append({"spell": spell, "stat": "", "amount": 0, "icon_path": definition["icon_path"],
			"title": "%s %d." % [definition["name"], level(spell) + 1],
			"text": upgrade_text(spell), "note": "fejlesztés"})
	if GameState.spells.size() < MAX_SPELLS:
		for spell: String in ALL:
			if spell in GameState.spells:
				continue
			var definition: Dictionary = ALL[spell]
			options.append({"spell": spell, "stat": "", "amount": 0, "icon_path": definition["icon_path"],
				"title": definition["name"], "text": definition["short"], "note": "új varázslat · jobb klikk"})
	return options


## Egy varázslat-kártya választása: fejlesztés vagy új varázslat.
static func choose(spell: String) -> void:
	if spell in GameState.spells:
		GameState.spell_levels[spell] = mini(level(spell) + 1, MAX_LEVEL)
	elif GameState.spells.size() < MAX_SPELLS:
		GameState.spells.append(spell)
		GameState.spell_levels[spell] = 1


## Az első varázslat (a kazamatába lépéskor választva).
static func pick_first(spell: String) -> void:
	GameState.spells = [spell]
	GameState.spell_levels = {spell: 1}


## Kinövő földtüske (0x72 tüskecsapda-kockák, 2x-es): egy pillanatig sebez és ellök.
class EarthSpike:
	extends Hitbox

	func _ready() -> void:
		collision_layer = 8
		collision_mask = 0
		z_index = 2
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 22.0
		shape.shape = circle
		shape.position = Vector2(0, -8)
		add_child(shape)
		var spikes := SpikeShape.new()
		add_child(spikes)
		var dust := CPUParticles2D.new()
		dust.one_shot = true
		dust.emitting = true
		dust.amount = 14
		dust.lifetime = 0.5
		dust.explosiveness = 1.0
		dust.spread = 180.0
		dust.gravity = Vector2(0, 60)
		dust.initial_velocity_min = 30.0
		dust.initial_velocity_max = 80.0
		dust.scale_amount_min = 2.0
		dust.scale_amount_max = 4.0
		dust.color = Color(0.55, 0.42, 0.3)
		add_child(dust)
		# Csak rövid ideig sebez, aztán elhalványul.
		get_tree().create_timer(0.18, false).timeout.connect(func() -> void: set_deferred("monitorable", false))
		var fade := create_tween()
		fade.tween_interval(0.45)
		fade.tween_property(self, "modulate:a", 0.0, 0.25)
		fade.tween_callback(queue_free)


## A tüske rajza: három kőtüske, ami gyorsan kinő a földből (rajta földrepedés).
class SpikeShape:
	extends Node2D
	var _t := 0.0

	func _process(delta: float) -> void:
		_t = minf(_t + delta * 7.0, 1.0)
		queue_redraw()

	func _draw() -> void:
		var grow := ease(_t, 0.4)
		draw_colored_polygon(PackedVector2Array([Vector2(-22, 2), Vector2(-8, -3), Vector2(10, -2), Vector2(22, 3),
			Vector2(6, 7), Vector2(-12, 6)]), Color(0.22, 0.16, 0.12, 0.85))
		for spike: Array in [[-10.0, 26.0, 0.0], [10.0, 22.0, 0.0], [0.0, 38.0, 1.0]]:
			var x: float = spike[0]
			var height: float = spike[1] * grow
			var tip := Vector2(x + spike[2] * 2.0, -height)
			var base_left := Vector2(x - 7, 2)
			var base_right := Vector2(x + 7, 2)
			draw_colored_polygon(PackedVector2Array([base_left, tip, base_right]), Color(0.52, 0.42, 0.34))
			draw_colored_polygon(PackedVector2Array([base_left, tip, Vector2(x, 2)]), Color(0.68, 0.56, 0.44))
			draw_polyline(PackedVector2Array([base_left, tip, base_right]), Color(0.25, 0.18, 0.13), 1.5)


## A láncvillám rajza: cikcakkos, kék-fehér villám két pont között, ami gyorsan
## remeg (újrarajzolva), aztán elhalványul; a becsapódásnál szikrák.
class LightningArc:
	extends Node2D
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var _points := PackedVector2Array()
	var _jitter := 0.0

	func _ready() -> void:
		top_level = true
		z_index = 5
		_zigzag()
		var sparks := CPUParticles2D.new()
		sparks.position = to
		sparks.one_shot = true
		sparks.emitting = true
		sparks.amount = 12
		sparks.lifetime = 0.3
		sparks.explosiveness = 1.0
		sparks.spread = 180.0
		sparks.gravity = Vector2.ZERO
		sparks.initial_velocity_min = 60.0
		sparks.initial_velocity_max = 140.0
		sparks.scale_amount_min = 1.5
		sparks.scale_amount_max = 3.0
		sparks.color = Color(0.75, 0.9, 1.0)
		add_child(sparks)
		var fade := create_tween()
		fade.tween_interval(0.16)
		fade.tween_property(self, "modulate:a", 0.0, 0.18)
		fade.tween_callback(queue_free)

	func _process(delta: float) -> void:
		_jitter += delta
		if _jitter > 0.04:
			_jitter = 0.0
			_zigzag()

	func _zigzag() -> void:
		_points.clear()
		var length := from.distance_to(to)
		var normal := from.direction_to(to).orthogonal()
		var steps := maxi(3, int(length / 18.0))
		for i in steps + 1:
			var t := float(i) / steps
			var offset := 0.0 if i == 0 or i == steps else randf_range(-9.0, 9.0)
			_points.append(from.lerp(to, t) + normal * offset)
		queue_redraw()

	func _draw() -> void:
		draw_polyline(_points, Color(0.35, 0.6, 1.0, 0.45), 7.0)
		draw_polyline(_points, Color(0.7, 0.88, 1.0), 3.0)
		draw_polyline(_points, Color.WHITE, 1.2)
