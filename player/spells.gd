class_name Spells
## A varázsló (Lőrinc) varázslatai. A kazamatába lépve kiválasztja az elsőt (SpellPicker); minden
## 5. szintlépéskor fejlesztheti valamelyiket, vagy megtanulhat egy újat (legfeljebb MAX_SPELLS).
## Az első az elsődleges támadása (bal egérgomb), a második a Q gombon van, saját cooldownnal.
## Minden varázslat Elemi sebzéssel sebez (Stats.elemental_damage, csak a varázslónak).
## Az állapot a futás része: GameState.spells (sorrendben) és GameState.spell_levels.
##
##   bolt    Varázsgömb: lila gömb a kurzor felé (szintenként +1 gömb legyezőben)
##   fire    Tűzgolyó: lassabb, de felgyújtja az ellenséget (égés: sebez és lángol rajta)
##   spikes  Földtüskék: a kurzor irányában tőled indulva tüskék nőnek ki a földből, ellökve és
##           megsebezve minden szörnyet (szintenként +1 tüske)

const MAX_SPELLS := 2
## Ennyi szintenként jön a varázslat-választás (fejlesztés vagy új).
const SPELL_LEVEL_EVERY := 5
const PLAYER_ARROW := preload("res://player/player_arrow.gd")

const ALL := {
	"bolt": {"name": "Varázsgömb", "icon_path": "res://assets/ui/spell_bolt.png", "cooldown": 1.0, "power": 1.0,
		"text": "Lila varázsgömb repül a kurzor felé.", "upgrade": "+1 gömb, +20% sebzés"},
	"fire": {"name": "Tűzgolyó", "icon_path": "res://assets/ui/spell_fire.png", "cooldown": 1.6, "power": 1.25,
		"text": "Lassabb, de felgyújtja az ellenséget: égés közben is sebződik.",
		"upgrade": "+20% sebzés, hosszabb és erősebb égés"},
	"spikes": {"name": "Földtüskék", "icon_path": "res://assets/ui/spell_spikes.png", "cooldown": 1.4, "power": 1.0,
		"text": "A kurzor irányában 3 tüske nő ki a földből: ellöki és megsebzi a szörnyeket.",
		"upgrade": "+1 tüske, +15% sebzés"},
}


static func level(spell: String) -> int:
	return int(GameState.spell_levels.get(spell, 1))


## A varázslat cooldownja a karakter ütési idejéhez képest.
static func cooldown_multiplier(spell: String) -> float:
	return float(ALL[spell]["cooldown"])


## Egy találat sebzése: az (elemi) alapsebzés a varázslat erejével és szintjével szorozva.
static func damage(spell: String, base_hit: int) -> int:
	var per_level := 0.15 if spell == "spikes" else 0.2
	return maxi(1, roundi(base_hit * float(ALL[spell]["power"]) * (1.0 + per_level * (level(spell) - 1))))


## A varázslat elsütése (Player hívja): a lövedékek / tüskék a játékos szülőjébe kerülnek.
static func cast(player: Node2D, spell: String, aim: Vector2) -> void:
	var direction := aim.normalized() if aim.length() > 1.0 else Vector2.RIGHT
	var hit: int = damage(spell, player.call("hit_damage"))
	var stats: Stats = player.get_node("Stats")
	match spell:
		"bolt":
			Audio.play("magic", -4.0, 0.15)
			var count := level(spell)
			for i in count:
				var k := i - (count - 1) / 2.0
				_projectile(player, direction.rotated(deg_to_rad(10.0) * k), hit, stats, "orb")
		"fire":
			Audio.play("magic", -2.0, 0.05)
			var ball := _projectile(player, direction, hit, stats, "fire")
			ball.speed = 420.0
			# Égés: másodpercenként ennyit sebez, ennyi ideig.
			ball.set_meta("burn_time", 2.5 + 0.75 * (level(spell) - 1))
			ball.set_meta("burn_damage", maxi(1, roundi(hit * (0.3 + 0.05 * (level(spell) - 1)))))
		"spikes":
			_spikes(player, direction, hit, 2 + level(spell))


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


## A varázslat-választás kártyái (minden 5. szinten): a meglévők fejlesztése, és ha még van
## hely, egy új megtanulása.
static func level_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for spell: String in GameState.spells:
		var definition: Dictionary = ALL[spell]
		options.append({"spell": spell, "stat": "", "amount": 0, "icon_path": definition["icon_path"],
			"title": "%s %d." % [definition["name"], level(spell) + 1],
			"text": "Fejlesztés: " + definition["upgrade"]})
	if GameState.spells.size() < MAX_SPELLS:
		for spell: String in ALL:
			if spell in GameState.spells:
				continue
			var definition: Dictionary = ALL[spell]
			options.append({"spell": spell, "stat": "", "amount": 0, "icon_path": definition["icon_path"],
				"title": "Új: " + definition["name"],
				"text": definition["text"] + " (Q gombbal)"})
	return options


## Egy varázslat-kártya választása: fejlesztés vagy új varázslat.
static func choose(spell: String) -> void:
	if spell in GameState.spells:
		GameState.spell_levels[spell] = level(spell) + 1
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
