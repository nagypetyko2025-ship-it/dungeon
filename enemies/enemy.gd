extends CharacterBody2D
## Általános ellenség. A típusát a `setup()` adja meg az EnemyTypes táblából,
## még mielőtt a fába kerülne; a konkrét statjai (HP, sebzés, sebesség,
## kikerülés, hátralökés, XP) spawnoláskor véletlenül dőlnek el a típus
## tartományaiból. Ha látja a játékost, felé megy, és érintéssel sebez.

const KNOCKBACK_DECAY := 900.0
const HIT_STUN := 0.25
const XP_ORB := preload("res://pickups/xp_orb.tscn")
## Ennél több gömb nem pattan ki; a maradék XP az utolsóba kerül.
const MAX_ORBS := 6
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
var _aiming := false
var _magic := false
var _dash := false
var _dash_state := DashState.READY
var _dash_cooldown := 0.0
var _dash_time := 0.0
var _dash_dir := Vector2.ZERO
var _abilities: EnemyAbilities
## A mimik még alszik (csukott ládának látszik, nem mozdul, nem sebez).
var _dormant := false

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
		_sprite.sprite_frames = _own_frames(load(_type["sheet"]), _type["rect"].size)
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
		_bow.scale = Vector2(2, 2)
		_bow.position = Vector2(10, -24) * _size_scale
		# Pl. a sárkány a szájából köp: nincs a kezében fegyver.
		_bow.visible = not _type.get("no_weapon", false)
		_visual.add_child(_bow)

	_dash = _type.get("dash", false)
	_dash_cooldown = randf_range(1.0, 2.5)

	_abilities = EnemyAbilities.new()
	_abilities.name = "Abilities"
	add_child(_abilities)
	_abilities.setup(self, _type.get("abilities", []))

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
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")

	if _dormant:
		if is_instance_valid(_player) and global_position.distance_to(_player.global_position) < MIMIC_WAKE_RANGE:
			_wake()
		return

	var dir := Vector2.ZERO
	_stun_left -= delta
	if _stun_left <= 0.0 and is_instance_valid(_player) and not _abilities.is_busy() \
			and global_position.distance_to(_player.global_position) < detect_range:
		dir = _ranged_direction(delta) if _ranged else global_position.direction_to(_player.global_position)
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
	if not sees_player or distance > keep + DISTANCE_TOLERANCE:
		return to_player.normalized()
	if distance < keep - DISTANCE_TOLERANCE:
		return -to_player.normalized()
	return Vector2.ZERO


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
		tween.tween_property(_bow, "scale", Vector2(1.4, 2.4), AIM_TIME)
	await tween.finished
	_aiming = false
	_shoot_left = stats["fire_interval"]
	_bow.scale = Vector2(2, 2)
	_bow.modulate = Color.WHITE
	if not is_physics_processing() or not is_instance_valid(_player):
		return
	Audio.play("magic" if _magic else "arrow")
	var muzzle := _bow.global_position + (Vector2(0, -24) if _magic else Vector2.ZERO)
	var aim := muzzle.direction_to(_player.global_position + PLAYER_CENTER)
	# Legyezőlövés ("shots" > 1): több lövedék egyszerre, szétterítve.
	var shots: int = _type.get("shots", 1)
	var spread := deg_to_rad(_type.get("spread", 14.0))
	for i in shots:
		var projectile = (MAGIC_BOLT if _magic else ARROW).instantiate()
		projectile.direction = aim.rotated((i - (shots - 1) / 2.0) * spread)
		projectile.speed = stats["arrow_speed"]
		projectile.damage = stats["damage"]
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
func _own_frames(texture: Texture2D, frame_size: Vector2) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	# Mimik: 0 alvó, 1 ébredő, 2-5 futás; minden más saját lap: 0-3 álló, 4-7 futás.
	var animations := {"dormant": [0], "wake": [1], "idle": [2, 3, 4, 5], "run": [2, 3, 4, 5]} \
		if _type.get("mimic", false) else {"idle": [0, 1, 2, 3], "run": [4, 5, 6, 7]}
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
	if not _health.damage(hit["damage"], not hit["pierce"]):
		return
	# A játékos fegyvere talált: életlopás stb. (lásd Player.on_hit_enemy).
	if is_instance_valid(source) and source.has_method("on_hit_enemy"):
		source.call("on_hit_enemy", hit["damage"])
	Audio.play("crit" if hit["crit"] else "hit")
	if hit["crit"]:
		# Kritikus találat: nagyobb, piros-narancs szám felkiáltójellel.
		FloatingText.spawn(get_parent(), _head_position(), "%d!" % hit["damage"], CRIT_COLOR, CRIT_FONT_SIZE)
	else:
		FloatingText.spawn(get_parent(), _head_position(), str(hit["damage"]), Color(1, 0.9, 0.5))
	var resist: float = stats["resist"]
	var push := hitbox.knockback * (1.0 - resist)
	_knockback = hitbox.global_position.direction_to(global_position) * push
	_stun_left = HIT_STUN * (1.0 - resist)
	_visual.modulate = Color(4, 4, 4)
	create_tween().tween_property(_visual, "modulate", Color.WHITE, 0.15)


func _on_missed() -> void:
	Audio.play("swing", -8.0, 0.2)
	FloatingText.spawn(get_parent(), _head_position(), "Mellé!", Color(0.75, 0.75, 0.75))


func _on_dodged() -> void:
	Audio.play("dodge", -4.0)
	FloatingText.spawn(get_parent(), _head_position(), "Kikerülte!", Color(0.7, 0.75, 0.85))


func _on_died() -> void:
	Audio.play("enemy_die")
	set_physics_process(false)
	_hitbox.set_deferred("monitorable", false)
	_hurtbox.set_deferred("monitoring", false)
	_drop_xp.call_deferred(stats["xp"])
	_abilities.on_died()
	if _type.has("gold"):
		_drop_gold.call_deferred()
	if randf() < ITEM_DROP_CHANCE:
		_drop_item.call_deferred()
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
	var count := mini(total, MAX_ORBS)
	for i in count:
		var orb = XP_ORB.instantiate()
		orb.value = total - (count - 1) if i == count - 1 else 1
		orb.position = position + Vector2(0, -8)
		get_parent().add_child(orb)
