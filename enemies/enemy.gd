extends CharacterBody2D
## Általános ellenség. A típusát a `setup()` adja meg az EnemyTypes táblából,
## még mielőtt a fába kerülne; a konkrét statjai (HP, sebzés, sebesség,
## kikerülés, hátralökés, XP) spawnoláskor véletlenül dőlnek el a típus
## tartományaiból. Ha látja a játékost, felé megy, és érintéssel sebez.

const KNOCKBACK_DECAY := 900.0
## Ennyire megközelítve egy útpontot, a következőre indul.
const PATH_REACHED := 12.0
## Ha elfogyott (vagy nincs) az út, ennyi idő múlva tervez újat (régen minden képkockában: sok szörnynél
## ez egy pillanatra megakasztotta a játékot). Az első tervezés is ezen belül, szórva jön.
const PATH_RETRY := 0.15
const HIT_STUN := 0.25
## Báb: a helyben látott lökés ilyen gyorsan (px/mp) enged el, amíg a gazdától visszajön a valódi.
const PUPPET_PUSH_FADE := 160.0
## Báb: a helyben látott lökés legfeljebb ekkora (a valódi lökés a gazdától jön), és ennyivel a fal előtt megáll.
const PUPPET_PUSH_MAX := 40.0
const PUPPET_WALL_MARGIN := 12.0
## Báb: a saját találatunk után ennyi ideig nem hiszünk a gazda (még régi, magasabb) életerejének.
const PUPPET_HP_HOLD := 0.35
const XP_ORB := preload("res://pickups/xp_orb.tscn")
const XP_ORB_SCRIPT := preload("res://pickups/xp_orb.gd")
## Ennél több gömb nem pattan ki; a maradék XP az utolsóba kerül.
const MAX_ORBS := 12
const ITEM_DROP := preload("res://pickups/item_drop.tscn")
## Tárgy-dobás esélye: minden szörnynél ugyanannyi.
const ITEM_DROP_CHANCE := 0.01
## A legerősebbre dobott példány ennyivel nagyobb, a leggyengébb ennyivel kisebb.
const SIZE_VARIATION := 0.1
const CRIT_COLOR := Color(1, 0.35, 0.15)
const CRIT_FONT_SIZE := 22

# Távolsági ellenség (íjász)
const ARROW := preload("res://enemies/arrow.tscn")
const BOW_REGION := Rect2(289, 195, 14, 26)
## Ennyi ideig céloz lövés előtt (ilyenkor áll), hogy ki lehessen térni.
const AIM_TIME := 0.35
## Ennél messzebbről nem lő.
const SHOOT_RANGE := 420.0
## Ennyivel térhet el a tartott távolságtól, mielőtt közelít / hátrál.
const DISTANCE_TOLERANCE := 30.0
## A játékos középpontja a lába fölött (ide céloz).
const PLAYER_CENTER := Vector2(0, -20)
const MAGIC_BOLT := preload("res://enemies/magic_bolt.tscn")

# Rohamozó ellenség (pl. gyík)
enum DashState { READY, WINDUP, DASHING }
## Ennél közelebbről indít rohamot.
const DASH_RANGE := 260.0
## Ennyi ideig villog sárgán roham előtt (ennyi időd van kitérni).
const DASH_WINDUP := 0.35
const DASH_TIME := 0.3
const DASH_SPEED_MULTIPLIER := 4.0
const DASH_COOLDOWN := Vector2(2.0, 3.2)
const DASH_WARNING_COLOR := Color(2.2, 1.8, 0.6)

# Mimik: ládának álcázott szörny, ami felébred, ha közel mész (vagy megütöd).
## Ennyire kell megközelíteni, hogy felébredjen.
const MIMIC_WAKE_RANGE := 110.0
const MIMIC_WAKE_TIME := 0.45
const COIN := preload("res://pickups/coin.tscn")
const MIMIC_COINS := 4

@export var detect_range := 2000.0

## A spawnoláskor kidobott statok (lásd EnemyTypes.roll).
var stats := {}

var _type: Dictionary = EnemyTypes.TYPES[0]
var _depth := 1
var _size_scale := 1.0
var _player: Node2D
var _knockback := Vector2.ZERO
var _stun_left := 0.0
var _ranged := false
var _bow: Sprite2D
var _shoot_left := 0.0
## Útkeresés (ha valami — oszlop, fal — áll közte és a játékos között): a kért út és a következő pontja.
var _path := PackedVector2Array()
var _path_index := 0
var _repath_left := 0.0
var _aiming := false
var _bow_scale := Vector2(2, 2)
var _magic := false
var _dash := false
var _dash_state := DashState.READY
var _dash_cooldown := 0.0
var _dash_time := 0.0
var _dash_dir := Vector2.ZERO
var _abilities: EnemyAbilities
## A mimik még alszik (csukott ládának látszik, nem mozdul, nem sebez).
var _dormant := false
## Közös játék (lásd NetEnemies): azonosító, és hogy ez csak báb-e (a gazda szörnyét követi).
var net_id := 0
var net_puppet := false
var _retarget_left := 0.0
## Báb: a gazdától jött helyzet sima követése, a megjelenített hely (lökés nélkül), a helyben látott
## lökés eltolása, és meddig ne higgyünk a gazda (még a találatunk előtti) magasabb életerejének.
var _net_smooth := NetSmooth.new()
var _net_shown := Vector2.INF
var _net_push := Vector2.ZERO
var _net_hp_hold := 0.0
## A saját sprite-lapos típusok képkockái (lap, méret, mimik -> SpriteFrames): régen minden megjelenéskor
## újra épültek, és az emelet első ilyen szörnyénél a kép is a lemezről töltődött be.
static var _sheet_frames := {}

@onready var _visual: Node2D = $Visual
@onready var _sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var _health: Health = $Health
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _hitbox: Hitbox = $Hitbox


func setup(type: Dictionary, depth: int) -> void:
	_type = type
	_depth = depth


func _ready() -> void:
	if stats.is_empty():
		stats = EnemyTypes.roll(_type, _depth)
	_size_scale = _compute_size_scale()

	if _type.has("sheet"):
		_sprite.sprite_frames = _own_frames(str(_type["sheet"]), _type["rect"].size)
	else:
		_sprite.sprite_frames = SpriteSheet.character_frames(_type["rect"], _type["run"])
	_sprite.offset.y = -_type["rect"].size.y / 2.0
	_sprite.play("idle")
	_dormant = _type.get("mimic", false)
	if _dormant:
		_sprite.play("dormant")
		_hitbox.set_deferred("monitorable", false)
	# Színezett változat (pl. a Bukott lovag sötét páncélja).
	_sprite.self_modulate = _type.get("tint", Color.WHITE)
	_fit_shapes(_type["rect"].size * 2.0 * _size_scale)

	_health.set_max_health(stats["health"])
	_health.dodge_chance = stats["dodge"] / 100.0
	_hitbox.damage = stats["damage"]
	_hitbox.knockback = stats["knockback"]

	_ranged = _type.get("ranged", false)
	if _ranged:
		# Távolsági ellenség: érintésre csak 1-et sebez, a sebzése a nyílé.
		_hitbox.damage = 1
		_shoot_left = randf_range(0.6, stats["fire_interval"])
		_magic = _type.get("projectile", "arrow") == "magic"
		_bow = Sprite2D.new()
		_bow.texture = SpriteSheet.region(_type.get("weapon_region", BOW_REGION))
		# A Visual a szörny méretével (size) már fel van nagyítva: a fegyver ezt kiegyenlíti, hogy a
		# nagy szörnyeknél se legyen óriási; a kézmagasság a sprite magasságához igazodik.
		_bow_scale = Vector2(2, 2) / _size_scale
		_bow.scale = _bow_scale
		_bow.position = Vector2(10, -_type["rect"].size.y * 0.85)
		# Pl. a sárkány a szájából köp: nincs a kezében fegyver.
		_bow.visible = not _type.get("no_weapon", false)
		_visual.add_child(_bow)

	_dash = _type.get("dash", false)
	_dash_cooldown = randf_range(1.0, 2.5)
	_repath_left = randf_range(0.0, PATH_RETRY)

	_abilities = EnemyAbilities.new()
	_abilities.name = "Abilities"
	add_child(_abilities)
	_abilities.setup(self, _type.get("abilities", []))
	# A báb képességeit a gazda szörnye használja (a helyzete úgyis onnan jön).
	if net_puppet:
		_abilities.set_physics_process(false)

	_hurtbox.hurt.connect(_on_hurt)
	_health.died.connect(_on_died)
	_health.dodged.connect(_on_dodged)
	# Megjelenési animáció spawnoláskor.
	_visual.scale = Vector2.ZERO
	create_tween().tween_property(_visual, "scale", Vector2.ONE * _size_scale, 0.3)


## Az ütközők méretét a sprite méretéhez igazítja (nagy ellenségnél nagyobb).
## Az erősebbre dobott példány kicsit nagyobb (a főellenség felülírja).
func _compute_size_scale() -> float:
	# A típus saját mérete ("size", pl. a nagy, 5. emelet utáni szörnyeknél), ezen belül a dobás szerint.
	return float(_type.get("size", 1.0)) * (1.0 + lerpf(-SIZE_VARIATION, SIZE_VARIATION, stats["power"]))


func _fit_shapes(size: Vector2) -> void:
	var body := CircleShape2D.new()
	body.radius = size.x * 0.3
	$CollisionShape2D.shape = body
	var hurt := RectangleShape2D.new()
	hurt.size = size - Vector2(6, 6)
	$Hurtbox/CollisionShape2D.shape = hurt
	$Hurtbox/CollisionShape2D.position.y = -size.y / 2.0
	var hit := RectangleShape2D.new()
	hit.size = size - Vector2(10, 14)
	$Hitbox/CollisionShape2D.shape = hit
	$Hitbox/CollisionShape2D.position.y = -size.y / 2.0


func _physics_process(delta: float) -> void:
	if net_puppet:
		_puppet_process(delta)
		return
	_pick_target(delta)

	if _dormant:
		if is_instance_valid(_player) and global_position.distance_to(_player.global_position) < MIMIC_WAKE_RANGE:
			_wake()
		return

	var dir := Vector2.ZERO
	_stun_left -= delta
	if _stun_left <= 0.0 and is_instance_valid(_player) and not _abilities.is_busy() \
			and global_position.distance_to(_player.global_position) < detect_range:
		dir = _ranged_direction(delta) if _ranged else _chase_direction(delta)
		if _dash:
			dir = _dash_direction(delta, dir)
		dir = _abilities.steer(dir, delta)

	velocity = dir * stats["speed"] * _abilities.speed_multiplier() + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	move_and_slide()

	if _ranged and is_instance_valid(_player):
		# Az íjász mindig a játékos felé néz, akkor is, ha hátrál.
		_sprite.flip_h = _player.global_position.x < global_position.x
		# Az íj a játékos felé fordul; a varázsbot egyenesen áll.
		if not _magic:
			_bow.rotation = _bow.global_position.direction_to(_player.global_position + PLAYER_CENTER).angle()
		_bow.position.x = absf(_bow.position.x) * (-1.0 if _sprite.flip_h else 1.0)
	elif dir.x != 0.0:
		_sprite.flip_h = dir.x < 0.0
	if _sprite.animation == "wake" and _stun_left > 0.0:
		return
	_sprite.play("run" if dir != Vector2.ZERO else "idle")


## Kit üldöz: egyedül a játékost; közös játékban a gazdánál a legközelebbi játékost (társat is).
## Vendel csontvázaira is rátámad, ha egy közelebb van (a főellenség nem: ő a játékosra megy).
func _pick_target(delta: float) -> void:
	_retarget_left -= delta
	if is_instance_valid(_player) and _retarget_left > 0.0:
		return
	_retarget_left = NetEnemies.RETARGET_INTERVAL
	var net := NetEnemies.active(get_tree())
	if net != null and net.is_host():
		_player = NetEnemies.nearest_target(get_tree(), global_position)
	else:
		_player = get_tree().get_first_node_in_group("player")
	if is_in_group("boss"):
		return
	var best := global_position.distance_squared_to(_player.global_position) if is_instance_valid(_player) else INF
	for node in get_tree().get_nodes_in_group("minions"):
		var minion := node as Node2D
		var distance := global_position.distance_squared_to(minion.global_position)
		if distance < best:
			best = distance
			_player = minion


## Báb (közös játék, vendég): a gazda szörnyének helyét és animációját követi; a lövés és az
## érintés a saját figuránkat sebzi (lásd NetEnemies).
func _puppet_process(delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	_net_hp_hold -= delta
	_stun_left -= delta
	# A mi ütésünk lökése azonnal látszik; amíg a gazdánál is meglökött helyzet visszajön, lassan elenged.
	if _knockback != Vector2.ZERO:
		_net_push = (_net_push + _knockback * delta).limit_length(PUPPET_PUSH_MAX)
		_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	elif _stun_left <= 0.0:
		_net_push = _net_push.move_toward(Vector2.ZERO, PUPPET_PUSH_FADE * delta)
	if _net_smooth.has_sample():
		if _net_shown == Vector2.INF:
			_net_shown = position
		_net_shown = _net_smooth.step(_net_shown, delta, _stun_left > 0.0)
		_net_push = _push_until_wall(_net_shown, _net_push)
		position = _net_shown + _net_push
	# (A lövéseit a gazda szörnye adja le, és mindenkinél ugyanaz a lövés repül: NetEnemies "shot".)
	if _ranged and is_instance_valid(_player) and not _dormant:
		_sprite.flip_h = _player.global_position.x < global_position.x
		if not _magic:
			_bow.rotation = _bow.global_position.direction_to(_player.global_position + PLAYER_CENTER).angle()
		_bow.position.x = absf(_bow.position.x) * (-1.0 if _sprite.flip_h else 1.0)


## Báb: a helyben látott lökés nem viheti át a falon (az igazi szörny a gazdánál is megáll a falnál).
func _push_until_wall(base: Vector2, push: Vector2) -> Vector2:
	if push.length() < 1.0:
		return push
	var from: Vector2 = (get_parent() as Node2D).to_global(base)
	var query := PhysicsRayQueryParameters2D.create(from, from + push, 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return push
	var reach := maxf(from.distance_to(hit["position"]) - PUPPET_WALL_MARGIN, 0.0)
	return push.limit_length(reach)


## Báb: a gazdától jött állapot (hely, sebesség, tükrözés, animáció — "" ha nem változik —, életerő).
func net_apply(at: Vector2, moving: Vector2, flip: bool, animation: String, hp: int, shield := 0) -> void:
	_net_smooth.receive(at, moving)
	# Még nincs a fában (késleltetve kerül be): a helyét megjegyeztük, a többi a következő mintával jön.
	if not is_node_ready():
		return
	# A gazda szörnyének pajzsa (buborék, pontok).
	if shield != _abilities.shield_points:
		_abilities.set_shield_points(shield)
	if not _ranged:
		_sprite.flip_h = flip
	if _dormant and animation != "" and animation != "dormant":
		_wake()
	if animation != "" and _sprite.sprite_frames.has_animation(animation) and _sprite.animation != animation:
		_sprite.play(animation)
	# A saját találatunk után egy darabig csak a kisebb életerőt hisszük el (a gazda még nem vonta le).
	if hp > 0 and hp != _health.current and not _health.is_dead() and (hp < _health.current or _net_hp_hold <= 0.0):
		_health.current = hp
		_health.changed.emit(_health.current, _health.max_health)


## Báb: a gazdánál meghalt (vagy eltűnt) — itt is meghal (szobatisztítás; a zsákmány a gazdától jön).
func net_kill() -> void:
	if not is_node_ready():
		ready.connect(net_kill, CONNECT_ONE_SHOT)
		return
	if not _health.is_dead():
		_health.damage(_health.current, false)


## Báb: a gazda elment, innen önálló szörny.
func net_go_local() -> void:
	net_puppet = false
	_abilities.set_physics_process(true)


## Gazda: egy vendég ütése (a találatot és a kikerülést a vendég már eldöntötte). `direct`: égés vagy
## tüske — ettől nem torpan meg.
func net_take_damage(amount: int, push: Vector2, direct := false) -> void:
	if direct:
		_health.damage(amount, false)
		return
	_wake()
	if _abilities.is_shielded():
		var absorbed := _abilities.absorb(amount)
		FloatingText.spawn(get_parent(), _head_position(), "-%d pajzs" % absorbed, EnemyAbilities.SHIELD_COLOR)
		return
	if not _health.damage(amount, false):
		return
	FloatingText.spawn(get_parent(), _head_position(), str(amount), Color(0.75, 0.9, 1.0))
	var resist: float = stats["resist"]
	_knockback = push * (1.0 - resist)
	_stun_left = HIT_STUN * (1.0 - resist)
	_visual.modulate = Color(4, 4, 4)
	create_tween().tween_property(_visual, "modulate", Color.WHITE, 0.15)


## Távolsági ellenség: tartja a távolságot (közelít, ha messze van vagy nem lát,
## hátrál, ha túl közel vagy), és ha rálát a játékosra, rendszeresen lő.
func _ranged_direction(delta: float) -> Vector2:
	var to_player := _player.global_position - global_position
	var distance := to_player.length()
	var sees_player := _has_line_of_sight()
	_shoot_left -= delta
	if sees_player and _shoot_left <= 0.0 and not _aiming and distance < SHOOT_RANGE:
		_aim_and_shoot()
	if _aiming:
		return Vector2.ZERO
	var keep: float = stats["keep_distance"]
	if not sees_player:
		return _chase_direction(delta)
	if distance > keep + DISTANCE_TOLERANCE:
		return to_player.normalized()
	if distance < keep - DISTANCE_TOLERANCE:
		return -to_player.normalized()
	return Vector2.ZERO


## Merre induljon a játékos felé: ha szabad az út (a teste szélességében sincs útban semmi),
## egyenesen; különben az útkereső háló szerint (lásd Dungeon.nav_path), az oszlopokat megkerülve.
func _chase_direction(delta: float) -> Vector2:
	var target := _player.global_position
	if _clear_to(target):
		_path = PackedVector2Array()
		return global_position.direction_to(target)
	_repath_left -= delta
	if _path_index >= _path.size():
		_repath_left = minf(_repath_left, PATH_RETRY)
	if _repath_left <= 0.0:
		_repath_left = randf_range(0.4, 0.6)
		var scene := get_tree().current_scene
		_path = scene.call("nav_path", global_position, target) if scene.has_method("nav_path") else PackedVector2Array()
		_path_index = 1 if _path.size() > 1 else 0
	while _path_index < _path.size() and global_position.distance_to(_path[_path_index]) < PATH_REACHED:
		_path_index += 1
	if _path_index >= _path.size():
		return global_position.direction_to(target)
	return global_position.direction_to(_path[_path_index])


## Szabad-e az egyenes út: két sugár a test két szélén (a falak és az oszlopok rétegén).
func _clear_to(target: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var side := global_position.direction_to(target).orthogonal() * _body_radius()
	for offset: Vector2 in [side, -side]:
		var query := PhysicsRayQueryParameters2D.create(global_position + offset, target + offset, 1)
		query.exclude = [get_rid()]
		if not space.intersect_ray(query).is_empty():
			return false
	return true


func _body_radius() -> float:
	var shape := $CollisionShape2D.shape as CircleShape2D
	return shape.radius if shape != null else 8.0


func _has_line_of_sight(from := Vector2.INF) -> bool:
	if from == Vector2.INF:
		from = _bow.global_position
	var query := PhysicsRayQueryParameters2D.create(from, _player.global_position + PLAYER_CENTER, 1)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


## Rövid célzás (megfeszíti az íjat / felizzik a bot, ilyenkor megáll),
## aztán kilő egy nyilat vagy varázslövedéket.
func _aim_and_shoot() -> void:
	_aiming = true
	var tween := create_tween()
	if _magic:
		tween.tween_property(_bow, "modulate", Color(3, 1.2, 3.5), AIM_TIME)
	else:
		tween.tween_property(_bow, "scale", _bow_scale * Vector2(0.7, 1.2), AIM_TIME)
	await tween.finished
	_aiming = false
	_shoot_left = stats["fire_interval"]
	_bow.scale = _bow_scale
	_bow.modulate = Color.WHITE
	if not is_physics_processing() or not is_instance_valid(_player):
		return
	Audio.play("magic" if _magic else "arrow")
	var muzzle := _bow.global_position + (Vector2(0, -24) if _magic else Vector2.ZERO)
	var aim := muzzle.direction_to(_player.global_position + PLAYER_CENTER)
	# Legyezőlövés ("shots" > 1): több lövedék egyszerre, szétterítve.
	var shots: int = _type.get("shots", 1)
	var spread := deg_to_rad(_type.get("spread", 14.0))
	var net := NetEnemies.active(get_tree())
	if net != null and net.is_host() and net_id != 0:
		var directions: Array = []
		for i in shots:
			directions.append(aim.rotated((i - (shots - 1) / 2.0) * spread))
		net.broadcast_shot(self, _magic, muzzle, directions, stats["arrow_speed"], stats["damage"])
	for i in shots:
		var projectile = (MAGIC_BOLT if _magic else ARROW).instantiate()
		projectile.direction = aim.rotated((i - (shots - 1) / 2.0) * spread)
		projectile.speed = stats["arrow_speed"]
		projectile.damage = stats["damage"]
		# A lövedék találata is az ellenségé (méreg, fagy, fosztogatás).
		projectile.set_meta("source", self)
		get_parent().add_child(projectile)
		projectile.global_position = muzzle


## Rohamozó ellenség: ha közel van és rálát, rövid felvillanás (ilyenkor megáll),
## aztán DASH_SPEED_MULTIPLIER-szeres sebességgel nekiront a játékosnak.
func _dash_direction(delta: float, chase: Vector2) -> Vector2:
	match _dash_state:
		DashState.READY:
			_dash_cooldown -= delta
			var close := global_position.distance_to(_player.global_position) < DASH_RANGE
			if _dash_cooldown <= 0.0 and close and _has_line_of_sight(global_position + PLAYER_CENTER):
				_dash_state = DashState.WINDUP
				_dash_time = DASH_WINDUP
				create_tween().tween_property(_visual, "modulate", DASH_WARNING_COLOR, DASH_WINDUP)
			return chase
		DashState.WINDUP:
			_dash_time -= delta
			if _dash_time <= 0.0:
				_dash_state = DashState.DASHING
				_dash_time = DASH_TIME
				_dash_dir = global_position.direction_to(_player.global_position)
				_visual.modulate = Color.WHITE
			return Vector2.ZERO
		_:
			_dash_time -= delta
			if _dash_time <= 0.0:
				_dash_state = DashState.READY
				_dash_cooldown = randf_range(DASH_COOLDOWN.x, DASH_COOLDOWN.y)
			return _dash_dir * DASH_SPEED_MULTIPLIER


## Saját sprite-lap (pl. a mimiké): 0 = alvó, 1 = ébredő, 2-5 = futás.
func _own_frames(sheet: String, frame_size: Vector2) -> SpriteFrames:
	var mimic: bool = _type.get("mimic", false)
	var key := [sheet, frame_size, mimic]
	if _sheet_frames.has(key):
		return _sheet_frames[key]
	var texture: Texture2D = load(sheet)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_sheet_frames[key] = frames
	# Mimik: 0 alvó, 1 ébredő, 2-5 futás; minden más saját lap: 0-3 álló, 4-7 futás.
	var animations := {"dormant": [0], "wake": [1], "idle": [2, 3, 4, 5], "run": [2, 3, 4, 5]} \
		if mimic else {"idle": [0, 1, 2, 3], "run": [4, 5, 6, 7]}
	for anim: String in animations:
		frames.add_animation(anim)
		frames.set_animation_speed(anim, 10.0)
		for index: int in animations[anim]:
			var frame := AtlasTexture.new()
			frame.atlas = texture
			frame.region = Rect2(Vector2(index * frame_size.x, 0), frame_size)
			frames.add_frame(anim, frame)
	return frames


## A mimik felébred: kinyílik a szája, lábra áll, és támad.
func _wake() -> void:
	if not _dormant:
		return
	_dormant = false
	_stun_left = MIMIC_WAKE_TIME
	_sprite.play("wake")
	Audio.play("chest_open")
	Audio.play("boss_roar", -10.0, 0.25)
	FloatingText.spawn(get_parent(), _head_position(), "Mimik!", Color(1, 0.55, 0.3), 22)
	var hop := create_tween()
	hop.tween_property(_visual, "position:y", -14.0, 0.15).set_ease(Tween.EASE_OUT)
	hop.tween_property(_visual, "position:y", 0.0, 0.15).set_ease(Tween.EASE_IN)
	_hitbox.set_deferred("monitorable", true)


func _head_position() -> Vector2:
	return global_position + Vector2(0, -_type["rect"].size.y * 2.0 * _size_scale)


func _on_hurt(hitbox: Hitbox) -> void:
	_wake()
	# (A nyílvesszőnek nincs owner-e: a kilövője a "source" metában van.)
	var source: Variant = hitbox.get_meta("source", hitbox.owner)
	# A játékos találati esélye: ha mellé megy, nem sebez (utána jön a szörny kikerülése).
	if is_instance_valid(source) and source.has_method("hit_chance") and randf() >= float(source.call("hit_chance")):
		_on_missed()
		return
	var hit := hitbox.roll_hit()
	# Pajzs alatt (pajzs képesség) csak a pajzspontok fogynak (a sebzés 80%-ával), az élete nem.
	# Báb: a gazda szörnyének pajzsa fogy (a pontok a pillanatképpel jönnek vissza).
	if _abilities.is_shielded():
		Audio.play("door_lock", -10.0, 0.3)
		if net_puppet:
			var net := NetEnemies.active(get_tree())
			if net != null:
				net.report_damage(self, hit["damage"], Vector2.ZERO)
			var shown := mini(maxi(1, roundi(hit["damage"] * EnemyAbilities.SHIELD_DAMAGE_SHARE)), _abilities.shield_points)
			FloatingText.spawn(get_parent(), _head_position(), "-%d pajzs" % shown, EnemyAbilities.SHIELD_COLOR)
		else:
			var absorbed := _abilities.absorb(hit["damage"])
			FloatingText.spawn(get_parent(), _head_position(), "-%d pajzs" % absorbed, EnemyAbilities.SHIELD_COLOR)
		return
	if net_puppet:
		# Báb: itt csak a kikerülés dől el és a látszat; meghalni csak a gazda szavára hal meg.
		if not hit["pierce"] and randf() < _health.dodge_chance:
			_health.dodged.emit()
			return
		_health.current = maxi(_health.current - int(hit["damage"]), 1)
		_health.changed.emit(_health.current, _health.max_health)
		_net_hp_hold = PUPPET_HP_HOLD
	elif not _health.damage(hit["damage"], not hit["pierce"]):
		return
	# A játékos fegyvere talált: életlopás stb. (lásd Player.on_hit_enemy).
	if is_instance_valid(source) and source.has_method("on_hit_enemy"):
		source.call("on_hit_enemy", hit["damage"])
	# Tűzgolyó: felgyullad (égés közben is sebződik).
	if hitbox.has_meta("burn_time"):
		ignite(float(hitbox.get_meta("burn_time")), int(hitbox.get_meta("burn_damage")))
	Audio.play("crit" if hit["crit"] else "hit")
	if hit["crit"]:
		# Kritikus találat: nagyobb, piros-narancs szám felkiáltójellel.
		FloatingText.spawn(get_parent(), _head_position(), "%d!" % hit["damage"], CRIT_COLOR, CRIT_FONT_SIZE)
	else:
		FloatingText.spawn(get_parent(), _head_position(), str(hit["damage"]), Color(1, 0.9, 0.5))
	var resist: float = stats["resist"]
	# Báb: a sebzést és a lökést a gazda szörnye kapja meg (az életerő onnan jön vissza).
	if net_puppet:
		var net := NetEnemies.active(get_tree())
		if net != null:
			net.report_damage(self, hit["damage"], hitbox.global_position.direction_to(global_position) * hitbox.knockback)
	var push := hitbox.knockback * (1.0 - resist)
	_knockback = hitbox.global_position.direction_to(global_position) * push
	_stun_left = HIT_STUN * (1.0 - resist)
	_visual.modulate = Color(4, 4, 4)
	create_tween().tween_property(_visual, "modulate", Color.WHITE, 0.15)


## A játékos hívja, ha ez az ellenség (vagy a lövedéke) megsebezte: a képességek hatása.
func on_hit_player(_amount: int) -> void:
	# (Közös játékban a _player egy társ figurája is lehet: a hatás a megsebzett saját figuránkra megy.)
	_abilities.on_hit_player(get_tree().get_first_node_in_group("player"))


## Égés: `seconds` mp-ig félmásodpercenként `damage` sebzés, lángokkal a szörnyön.
func ignite(seconds: float, damage: int) -> void:
	var burn := get_node_or_null("Burn") as Burn
	if burn == null:
		burn = Burn.new()
		burn.name = "Burn"
		burn.position = Vector2(0, -_type["rect"].size.y * _size_scale)
		add_child(burn)
	burn.time_left = maxf(burn.time_left, seconds)
	burn.damage = maxi(burn.damage, damage)


func _on_missed() -> void:
	Audio.play("swing", -8.0, 0.2)
	FloatingText.spawn(get_parent(), _head_position(), "Mellé!", Color(0.75, 0.75, 0.75))


## Közvetlen sebzés (égés, tüskék): a bábon csak a látszat (legfeljebb 1 HP-ig), a sebzést a gazda
## vonja le; különben a vendégnél "meghalhatna" egy báb, ami a gazdánál él.
func take_direct_damage(amount: int) -> bool:
	if not net_puppet:
		return _health.damage(amount, false)
	if _health.is_dead():
		return false
	_health.current = maxi(_health.current - amount, 1)
	_health.changed.emit(_health.current, _health.max_health)
	_net_hp_hold = PUPPET_HP_HOLD
	var net := NetEnemies.active(get_tree())
	if net != null:
		net.report_damage(self, amount, Vector2.ZERO, true)
	return true


func _on_dodged() -> void:
	Audio.play("dodge", -4.0)
	FloatingText.spawn(get_parent(), _head_position(), "Kikerülte!", Color(0.7, 0.75, 0.85))


func _on_died() -> void:
	Audio.play("enemy_die")
	set_physics_process(false)
	_hitbox.set_deferred("monitorable", false)
	_hurtbox.set_deferred("monitoring", false)
	# A báb zsákmánya a gazdától jön (ő dobja ki a sajátját, és mindenkinél ugyanott jelenik meg).
	if not net_puppet:
		_drop_xp.call_deferred(stats["xp"])
		if _type.has("gold"):
			_drop_gold.call_deferred()
		if randf() < ITEM_DROP_CHANCE:
			_drop_item.call_deferred()
	_abilities.on_died()
	var tween := create_tween()
	tween.tween_property(_visual, "scale", Vector2.ZERO, 0.2)
	tween.tween_callback(queue_free)


func _drop_item() -> void:
	var drop = ITEM_DROP.instantiate()
	drop.item = Items.random_item()
	drop.position = position + Vector2(0, -8)
	get_parent().add_child(drop)


## Aranyat dobó ellenség (mimik): a típus "gold" tartományából, mélyebben kicsit többet.
func _drop_gold() -> void:
	var gold_range: Array = _type["gold"]
	var total := randi_range(gold_range[0], gold_range[1]) + _depth
	for i in MIMIC_COINS:
		var coin = COIN.instantiate()
		coin.value = total / MIMIC_COINS + (total % MIMIC_COINS if i == 0 else 0)
		coin.position = position + Vector2(0, -8)
		get_parent().add_child(coin)


func _drop_xp(total: int) -> void:
	# A legnagyobb gömbökkel (10, 8, 5, 3, 1 XP), lásd xp_orb.gd.
	for amount: int in XP_ORB_SCRIPT.split(total, MAX_ORBS):
		var orb = XP_ORB.instantiate()
		orb.value = amount
		orb.position = position + Vector2(0, -8)
		get_parent().add_child(orb)


## Égés a szörnyön: lobogó lángok (Kenney tűz-kockák, CC0) és szikrák; félmásodpercenként sebez.
class Burn:
	extends Node2D
	const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
	const TICK := 0.5
	var time_left := 2.0
	var damage := 1
	var _tick := TICK

	func _ready() -> void:
		z_index = 3
		var frames := SpriteFrames.new()
		frames.set_animation_speed("default", 10.0)
		for coords in [Vector2i(14, 8), Vector2i(15, 8)]:
			var texture := AtlasTexture.new()
			texture.atlas = RPG
			texture.region = Rect2(Vector2(coords) * 17.0, Vector2(16, 16))
			frames.add_frame("default", texture)
		for side in [-1, 1]:
			var flame := AnimatedSprite2D.new()
			flame.sprite_frames = frames
			flame.scale = Vector2(1.6, 1.6)
			flame.position = Vector2(side * 8, 0)
			flame.speed_scale = 1.0 + side * 0.2
			flame.play()
			add_child(flame)
		var sparks := CPUParticles2D.new()
		sparks.amount = 16
		sparks.lifetime = 0.6
		sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		sparks.emission_rect_extents = Vector2(10, 6)
		sparks.gravity = Vector2(0, -70)
		sparks.initial_velocity_min = 5.0
		sparks.initial_velocity_max = 20.0
		sparks.scale_amount_min = 1.5
		sparks.scale_amount_max = 3.0
		sparks.color = Color(1, 0.6, 0.2)
		add_child(sparks)

	func _process(delta: float) -> void:
		time_left -= delta
		_tick -= delta
		var enemy := get_parent()
		var health: Health = enemy.get_node("Health")
		if _tick <= 0.0 and not health.is_dead():
			_tick = TICK
			if enemy.call("take_direct_damage", damage):
				FloatingText.spawn(enemy.get_parent(), enemy.global_position + position + Vector2(0, -16), str(damage),
					Color(1, 0.55, 0.15), 16)
		enemy.get_node("Visual").modulate = Color(1.4, 0.85, 0.6) if fmod(time_left, 0.3) < 0.15 else Color.WHITE
		if time_left <= 0.0 or health.is_dead():
			enemy.get_node("Visual").modulate = Color.WHITE
			queue_free()
