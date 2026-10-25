class_name SkeletonMinion
extends CharacterBody2D
## Vendel megidézett csontváza (lásd Player._summon): kikel a földből, a legközelebbi szörnyre
## támad, ha nincs a közelben szörny, Vendel mellett marad. `lifetime` mp után, vagy ha `hits` találat
## érte, szétesik. A szörnyek rá is rátámadnak (lásd Enemy._pick_target): a testük, az ütéseik és a
## lövedékeik is eltalálják (minden találat egyet vesz el, utána egy pillanatig nem sebezhető).
## Olyan gyors, mint Vendel (hogy lépést tartson vele). A falakon nem megy át (megkerüli őket, lásd
## Dungeon.nav_path), a harc közbeni zárakon (Door) igen, hogy ne ragadjon kint, ha Vendel már bent van;
## a szörnyeken és a játékoson is átmegy. Fajták (`kind`):
##   "skeleton"  a sima csontváz (bal klikk)
##   "archer"    íjász (jobb klikk): kékes, íjat tart, és távolról lő (SHOOT_RANGE-en belül, ha rálát);
##               ha a szörny túl közel jön, hátrál
##   "giant"     óriás (Ctrl): nagy (a "Skeletons Rework" óriás csontváza), erős, sokat bír, de lassú,
##               és nagyot lök
## A sebzést és a kibírt találatokat Vendel fejlesztései adják (Necromancy), a szinttel nem nőnek.

## A csontvázak ütközési rétege (a többi: 1 fal, 2 játékos, 4 szörny, 8/16 találatok).
const MINION_LAYER := 32
## A szörnyek ütései, testük és lövedékeik (enemy_hitbox réteg).
const ENEMY_HITBOX_LAYER := 16
## Egy találat után ennyi ideig nem sebezhető.
const HURT_INVINCIBILITY := 0.6
## Ennyire közel állva széttolják egymást.
const SPACING := 22.0
## Ha nincs gazdája (nem kellene előfordulnia), ilyen gyors.
const SPEED := 170.0
const ATTACK_RANGE := 30.0
const ATTACK_COOLDOWN := 0.9
const SEEK_RANGE := 300.0
const FOLLOW_DISTANCE := 70.0
const LIFETIME := 18.0
const KNOCKBACK := 120.0
## A 0x72 lap csontváza (álló + futó kockák), zöldes, kísérteties színnel.
const FIGURE := Rect2(368, 88, 16, 16)
const TINT := Color(0.72, 1.0, 0.82)
## Íjász csontváz: színe, íja (a 0x72 lap íja), lövése.
const ARCHER_TINT := Color(0.78, 0.88, 1.15)
const BOW_REGION := Rect2(289, 195, 14, 26)
const BOW_POSITION := Vector2(6, -8)
const ARCHER_SEEK_RANGE := 380.0
const SHOOT_RANGE := 290.0
const KEEP_DISTANCE := 110.0
const ARCHER_COOLDOWN := 1.4
const ARROW_SPEED := 430.0
const ARROW_KNOCKBACK := 60.0
const PLAYER_ARROW := preload("res://player/player_arrow.gd")
## Óriás csontváz: saját lap (0-3 álló, 4-7 futás, 24x32), mérete, ütése.
const GIANT_SHEET := "res://assets/enemies/giant_skeleton.png"
const GIANT_FRAME := Vector2(24, 32)
const GIANT_SCALE := 2.2
const GIANT_ATTACK_RANGE := 46.0
const GIANT_ATTACK_COOLDOWN := 1.4
const GIANT_KNOCKBACK := 300.0

static var _giant_frames: SpriteFrames

var owner_player: Node2D
var damage := 1
## Ennyi találatot bír ki (Vendel fejlesztései szerint, lásd Necromancy).
var hits := 4
## Ennyi mp-ig él (Vendel fejlesztései szerint, lásd Necromancy).
var lifetime := LIFETIME
## "skeleton", "archer" vagy "giant".
var kind := "skeleton"

var _sprite: AnimatedSprite2D
var _bow: Sprite2D
var _hurtbox: Hurtbox
var _attack_left := 0.4
var _life_left := LIFETIME
var _rising := true
var _path := PackedVector2Array()
var _path_index := 0
var _repath_left := 0.0


func _ready() -> void:
	add_to_group("minions")
	# A csontvázak egymásba nem mehetnek (saját réteg), a falakon sem; a játékoson és a szörnyeken át.
	collision_layer = MINION_LAYER
	collision_mask = 1 | MINION_LAYER
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0 if kind == "giant" else 9.0
	shape.shape = circle
	add_child(shape)
	for door in get_tree().get_nodes_in_group("doors"):
		add_collision_exception_with(door)
	_life_left = lifetime
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = giant_frames() if kind == "giant" else SpriteSheet.character_frames(FIGURE, true)
	_sprite.offset = Vector2(0, -GIANT_FRAME.y / 2.0) if kind == "giant" else Vector2(0, -8)
	_sprite.modulate = _tint()
	_sprite.play("idle")
	add_child(_sprite)
	if kind == "archer":
		_bow = make_bow()
		_sprite.add_child(_bow)
	_build_hurtbox()
	# Kikel a földből: alulról nő ki, por száll körülötte.
	var full := _full_scale()
	_sprite.scale = Vector2(full.x, 0.1)
	var rise := create_tween()
	rise.tween_property(_sprite, "scale", full, 0.45 if kind == "giant" else 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	rise.tween_callback(func() -> void: _rising = false)
	_dust(Color(0.45, 0.36, 0.28))


## Sebezhető terület (a teste): a szörnyek ütései, teste és lövedékei eltalálják.
func _build_hurtbox() -> void:
	_hurtbox = Hurtbox.new()
	_hurtbox.invincibility_time = HURT_INVINCIBILITY
	_hurtbox.collision_layer = 0
	_hurtbox.collision_mask = ENEMY_HITBOX_LAYER
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(30, 48) if kind == "giant" else Vector2(18, 24)
	shape.shape = box
	shape.position = Vector2(0, -box.size.y / 2.0)
	_hurtbox.add_child(shape)
	add_child(_hurtbox)
	_hurtbox.hurt.connect(_on_hurt)


func _full_scale() -> Vector2:
	return Vector2(GIANT_SCALE, GIANT_SCALE) if kind == "giant" else Vector2(2, 2)


func _on_hurt(_hitbox: Hitbox) -> void:
	if _rising:
		return
	hits -= 1
	_sprite.modulate = Color(2, 2, 2)
	create_tween().tween_property(_sprite, "modulate", _tint(), 0.2)
	Audio.play("hit", -14.0, 0.3)


func _physics_process(delta: float) -> void:
	if _rising:
		return
	_life_left -= delta
	if _life_left <= 0.0 or hits <= 0:
		_crumble()
		return
	_attack_left = maxf(_attack_left - delta, 0.0)
	var target := _nearest_enemy()
	var dir := Vector2.ZERO
	if target != null:
		var to := target.global_position - global_position
		if kind == "archer":
			# Íjász: ha rálát és elég közel van, lő; ha túl közel jön a szörny, hátrál.
			var sees := _clear_shot(target.global_position)
			if to.length() > SHOOT_RANGE or not sees:
				dir = _direction_to(target.global_position, delta)
			elif to.length() < KEEP_DISTANCE:
				dir = -to.normalized()
			if sees and to.length() <= SHOOT_RANGE and _attack_left <= 0.0:
				_shoot(target)
		elif to.length() > _attack_range():
			dir = _direction_to(target.global_position, delta)
		elif _attack_left <= 0.0:
			_attack(target)
	elif is_instance_valid(owner_player) and global_position.distance_to(owner_player.global_position) > FOLLOW_DISTANCE:
		dir = _direction_to(owner_player.global_position, delta)
	velocity = dir * _speed() + _separation() * _speed() * 0.6
	move_and_slide()
	if dir.x != 0.0 and (kind != "archer" or target == null):
		_face(dir.x < 0.0)
	_sprite.play("run" if dir != Vector2.ZERO else "idle")


func _tint() -> Color:
	return ARCHER_TINT if kind == "archer" else TINT


func _attack_range() -> float:
	return GIANT_ATTACK_RANGE if kind == "giant" else ATTACK_RANGE


## Az ütés / lövés közti szünet (a csontváz-erősítéssel rövidül, lásd Necromancy).
func _attack_interval() -> float:
	var base := GIANT_ATTACK_COOLDOWN if kind == "giant" else (ARCHER_COOLDOWN if kind == "archer" else ATTACK_COOLDOWN)
	return base * Necromancy.attack_interval_multiplier()


## Az íj (a csontváz képéhez képest, a kezében); a társak gépén is ezt mutatjuk (lásd NetAvatars).
static func make_bow() -> Sprite2D:
	var bow := Sprite2D.new()
	bow.texture = SpriteSheet.region(BOW_REGION)
	bow.scale = Vector2(0.45, 0.45)
	bow.position = BOW_POSITION
	return bow


## Az óriás csontváz képkockái (egyszer épülnek fel; a társak gépén is ezt mutatjuk).
static func giant_frames() -> SpriteFrames:
	if _giant_frames != null:
		return _giant_frames
	var texture: Texture2D = load(GIANT_SHEET)
	_giant_frames = SpriteFrames.new()
	_giant_frames.remove_animation("default")
	for anim: String in ["idle", "run"]:
		_giant_frames.add_animation(anim)
		_giant_frames.set_animation_speed(anim, 8.0)
		for i in 4:
			var frame := AtlasTexture.new()
			frame.atlas = texture
			frame.region = Rect2(Vector2((i + (4 if anim == "run" else 0)) * GIANT_FRAME.x, 0), GIANT_FRAME)
			_giant_frames.add_frame(anim, frame)
	return _giant_frames


func _face(left: bool) -> void:
	_sprite.flip_h = left
	if _bow != null:
		_bow.flip_h = left
		_bow.position.x = -BOW_POSITION.x if left else BOW_POSITION.x


## Széttolás: a túl közel álló társaitól eltávolodik (ha egymásra kerültek, ez szedi szét őket).
func _separation() -> Vector2:
	var push := Vector2.ZERO
	for node in get_tree().get_nodes_in_group("minions"):
		var other := node as Node2D
		if other == self:
			continue
		var away := global_position - other.global_position
		var distance := away.length()
		if distance < SPACING:
			push += (away / distance if distance > 0.5 else Vector2.from_angle(randf() * TAU)) * (1.0 - distance / SPACING)
	return push.limit_length(1.0)


## Vendel mozgási sebessége (a lassítás nélkül): így mindig lépést tart vele; az óriás lassabb.
func _speed() -> float:
	var speed := SPEED
	if is_instance_valid(owner_player):
		speed = float(owner_player.call("move_speed_now"))
	return speed * (Necromancy.GIANT_SPEED if kind == "giant" else 1.0)


## Merre induljon: egyenesen, ha szabad az út (a zárakon át is), különben az útkereső háló szerint.
func _direction_to(target: Vector2, delta: float) -> Vector2:
	var query := PhysicsRayQueryParameters2D.create(global_position, target, 1)
	var exclude: Array[RID] = [get_rid()]
	for door in get_tree().get_nodes_in_group("doors"):
		exclude.append((door as CollisionObject2D).get_rid())
	query.exclude = exclude
	if get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		_path = PackedVector2Array()
		return global_position.direction_to(target)
	_repath_left -= delta
	if _repath_left <= 0.0 or _path_index >= _path.size():
		_repath_left = 0.4
		var scene := get_tree().current_scene
		_path = scene.call("nav_path", global_position, target) if scene.has_method("nav_path") else PackedVector2Array()
		_path_index = 1 if _path.size() > 1 else 0
	while _path_index < _path.size() and global_position.distance_to(_path[_path_index]) < 12.0:
		_path_index += 1
	if _path_index >= _path.size():
		return global_position.direction_to(target)
	return global_position.direction_to(_path[_path_index])


func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_distance := ARCHER_SEEK_RANGE if kind == "archer" else SEEK_RANGE
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Node2D
		var hurtbox := enemy.get_node_or_null("Hurtbox") as Area2D if enemy != null else null
		if hurtbox == null or not hurtbox.monitoring:
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best


## Egy csapás: rövid életű Hitbox a szörny mellett, amit a szörny Hurtbox-a "megkap" (nem lehet mellé ütni).
func _attack(enemy: Node2D) -> void:
	_attack_left = _attack_interval()
	_face(enemy.global_position.x < global_position.x)
	var hit := Hitbox.new()
	hit.damage = damage
	hit.knockback = GIANT_KNOCKBACK if kind == "giant" else KNOCKBACK
	hit.set_meta("source", self)
	enemy.get_parent().add_child(hit)
	hit.global_position = global_position
	enemy.get_node("Hurtbox").emit_signal("hurt", hit)
	hit.queue_free()
	var lunge := create_tween()
	var toward := global_position.direction_to(enemy.global_position) * (10.0 if kind == "giant" else 6.0)
	lunge.tween_property(_sprite, "position", toward, 0.07)
	lunge.tween_property(_sprite, "position", Vector2.ZERO, 0.12)
	Audio.play("boss_slam" if kind == "giant" else "swing", -14.0 if kind == "giant" else -12.0, 0.25)


## Lőhet-e: nincs fal (vagy oszlop, zárt ajtó) közte és a szörny között.
func _clear_shot(target: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -10), target + Vector2(0, -10), 1)
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


## Nyíl a szörny felé (a játékos nyila: csak a szörnyeket sebzi); a társak is látják.
func _shoot(enemy: Node2D) -> void:
	_attack_left = _attack_interval()
	var from := global_position + Vector2(0, -12)
	var direction := from.direction_to(enemy.global_position + Vector2(0, -10))
	_face(direction.x < 0.0)
	var arrow: Area2D = PLAYER_ARROW.new()
	arrow.direction = direction
	arrow.speed = ARROW_SPEED
	arrow.max_distance = SHOOT_RANGE + 60.0
	arrow.damage = damage
	arrow.knockback = ARROW_KNOCKBACK
	arrow.set_meta("source", self)
	get_parent().add_child(arrow)
	arrow.global_position = from + direction * 10.0
	arrow.origin = global_position + Vector2(0, -6)
	if is_instance_valid(owner_player) and owner_player.has_method("share_shot"):
		owner_player.call("share_shot", arrow)
	Audio.play("arrow", -10.0, 0.2)
	var recoil := create_tween()
	recoil.tween_property(_sprite, "position", -direction * 3.0, 0.06)
	recoil.tween_property(_sprite, "position", Vector2.ZERO, 0.12)


## Szétesik: csontok porzanak szét, és eltűnik.
func _crumble() -> void:
	set_physics_process(false)
	remove_from_group("minions")
	_hurtbox.set_deferred("monitoring", false)
	_dust(Color(0.85, 0.85, 0.78))
	var flat := _full_scale() * Vector2(1.2, 0.1)
	var fall := create_tween()
	fall.tween_property(_sprite, "scale", flat, 0.25)
	fall.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.3)
	fall.tween_callback(queue_free)


func _dust(color: Color) -> void:
	var dust := CPUParticles2D.new()
	dust.one_shot = true
	dust.emitting = true
	dust.amount = 20 if kind == "giant" else 12
	dust.lifetime = 0.5
	dust.explosiveness = 1.0
	dust.spread = 180.0
	dust.gravity = Vector2(0, 80)
	dust.initial_velocity_min = 30.0
	dust.initial_velocity_max = 70.0
	dust.scale_amount_min = 2.0
	dust.scale_amount_max = 3.5
	dust.color = color
	add_child(dust)
