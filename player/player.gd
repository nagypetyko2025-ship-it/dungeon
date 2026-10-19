extends CharacterBody2D

signal gold_changed(gold: int)
## A halál után, a rövid szünet végén jelez: ekkor jön a death screen.
signal death_finished

const DEATH_SCREEN_DELAY := 0.8
## Mozgási sebesség 100%-os move_speed mellett (pixel / mp).
const BASE_SPEED := 200.0
const KNOCKBACK_DECAY := 1200.0
const SWING_ARC := deg_to_rad(140.0)
const MAX_SWING_TIME := 0.15
## Cooldown két ütés között 100%-os attack_speed mellett (mp).
const BASE_ATTACK_COOLDOWN := 0.6
## A markolat ennyire van a forgásponttól; a találati terület ennyivel hosszabb
## a pengénél (hogy a rövid kard se legyen használhatatlan) és ilyen széles.
const SWORD_HILT_OFFSET := 2.0
const SWORD_HITBOX_EXTRA := 14.0
const SWORD_HITBOX_WIDTH := 28.0
const SWORD_KNOCKBACK := 260.0

# Lándzsa: hosszabb, keskenyebb, szúr; átütés (nem lehet kikerülni) és nagy hátralökés.
## A lándzsa hossza 100%-os hatótávnál (pixel).
const SPEAR_LENGTH := 84.0
const SPEAR_HITBOX_WIDTH := 18.0
## A lándzsa hosszának ennyied része van a forgáspont (a kéz) mögött.
const SPEAR_GRIP := 0.3
## A lándzsaikon átlósan áll (hegye bal felül); ennyivel forgatjuk, hogy előre mutasson.
const SPEAR_SPRITE_ROTATION := PI * 0.75
const SPEAR_COOLDOWN_MULTIPLIER := 1.2
const SPEAR_KNOCKBACK := 470.0
## Szúrás: ennyit húzza vissza, majd ennyire döfi előre (pixel).
const THRUST_BACK := -10.0
const THRUST_FORWARD := 22.0
const WEAPON_PIVOT_POSITION := Vector2(0, -18)
## Fegyverfajták. style:
##   throw  egyenesen előre "dobja" a fegyvert a kurzor felé, majd visszahúzza
##          (kard, tőr, lándzsa); a Hatótáv azt adja meg, milyen messzire: `throw` × hatótáv%
##   swing  ívben suhint (balta, buzogány); a Hatótáv a testtől való távolságot növeli
##   bow    nyilat lő a kurzor felé; a Hatótáv a nyíl repülési távolsága
## A fegyver mérete sosem nő a hatótávval. length / width: az átlós ikonú fegyverek
## hossza és a találati terület szélessége.
const WEAPON_TYPES := {
	"sword": {"style": "throw", "cooldown": 1.0, "knockback": 260.0, "throw": 64.0},
	"dagger": {"style": "throw", "cooldown": 0.6, "knockback": 150.0, "throw": 56.0, "length": 34.0, "width": 24.0},
	"spear": {"style": "throw", "cooldown": 1.2, "knockback": 470.0, "throw": 80.0},
	"axe": {"style": "swing", "arc": 200.0, "cooldown": 1.3, "knockback": 380.0, "length": 58.0, "width": 34.0},
	"mace": {"style": "swing", "arc": 160.0, "cooldown": 1.45, "knockback": 520.0, "length": 56.0, "width": 36.0},
	"bow": {"style": "bow", "cooldown": 1.1, "knockback": 120.0, "length": 40.0, "width": 10.0},
}
## Az átlós ikonú fegyvereknél a markolat ennyied része a forgáspont mögött.
const ICON_WEAPON_GRIP := 0.15
## Suhintásnál +100% hatótáv ennyivel távolabb viszi a fegyvert a testtől (pixel).
const SWING_REACH_OFFSET := 40.0
## Dobásnál a fegyver ennyi idő alatt ér ki és vissza (100%-os hatótávnál, mp).
const THROW_TIME := 0.24
## Íj: a nyíl repülési távolsága 100%-os hatótávnál és a sebessége (pixel, pixel / mp).
const BOW_RANGE := 420.0
const ARROW_SPEED := 560.0
const PLAYER_ARROW := preload("res://player/player_arrow.gd")
## Ennyi megtett pixelenként szól egy lépés.
const STEP_LENGTH := 46.0

var gold := 0

@onready var _visual: Node2D = $Visual
@onready var _sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var _weapon_pivot: Node2D = $WeaponPivot
@onready var _sword_hitbox: Hitbox = $WeaponPivot/SwordHitbox
@onready var _sword_sprite: Sprite2D = $WeaponPivot/Sword
@onready var _sword_shape: CollisionShape2D = $WeaponPivot/SwordHitbox/CollisionShape2D
@onready var _stats: Stats = $Stats
@onready var _health: Health = $Health
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _experience: Experience = $Experience
@onready var _cooldown_bar: CooldownBar = $CooldownBar
@onready var _inventory: Inventory = $Inventory

var _knockback := Vector2.ZERO
var _cooldown_left := 0.0
var _swing_side := 1.0
## A felszerelt fegyver fajtája: "sword" vagy "spear".
var _weapon_type := "sword"
var _step_distance := 0.0


func _ready() -> void:
	_sprite.sprite_frames = Characters.frames(Progress.character)
	_sprite.play("idle")
	_weapon_pivot.visible = false
	_sword_shape.disabled = true
	_hurtbox.hurt.connect(_on_hurt)
	_health.died.connect(_on_died)
	_health.dodged.connect(_on_dodged)
	_load_state()
	_stats.changed.connect(_apply_stats)
	_inventory.changed.connect(_apply_equipment)
	# Minden szintlépéskor minden alapstat nő egy kicsit (a választott fejlesztésen felül).
	_experience.leveled_up.connect(func(_level: int) -> void: _stats.apply_level_growth())
	_apply_equipment()
	_apply_stats()
	if GameState.saved_health > 0:
		_health.current = mini(GameState.saved_health, _health.max_health)
		_health.changed.emit(_health.current, _health.max_health)


## A Stats értékeit átadja a fegyvernek és a Health-nek.
func _apply_stats() -> void:
	_sword_hitbox.damage = hit_damage()
	_sword_hitbox.crit_chance = _stats.crit_chance / 100.0
	_sword_hitbox.crit_multiplier = weapon_crit_multiplier()
	_health.set_max_health(_stats.max_health)
	_health.regen_per_second = _stats.health_regen
	_health.dodge_chance = _stats.dodge / 100.0
	_update_sword_geometry()


## A felszerelt fegyver adatai (Brotato-szerű sebzés, lásd Stats).
func weapon_base_damage() -> int:
	return _weapon_value("base_damage", 1)


func weapon_scaling() -> float:
	return _weapon_value("scaling", 1.0)


func weapon_crit_multiplier() -> float:
	return _weapon_value("crit_multiplier", Stats.CRIT_MULTIPLIER)


## Egy (nem kritikus) találat sebzése a jelenlegi fegyverrel és statokkal. Az íjat a
## Távolsági sebzés erősíti (a többit a Közelharci), és az íjász karakter íjjal többet sebez.
func hit_damage() -> int:
	var bow := _weapon_type == "bow"
	var damage := _stats.hit_damage(weapon_base_damage(), weapon_scaling(), bow)
	if bow:
		damage = roundi(damage * (1.0 + Characters.bonus("bow_damage")))
	return damage


## Másik karakterre váltás (a kocsmában): kinézet, tábori felszerelés, fejlesztések.
func set_character(id: String) -> void:
	Progress.select_character(id)
	_sprite.sprite_frames = Characters.frames(id)
	_sprite.play("idle")
	if Progress.camp_inventory.is_empty():
		_inventory.reset_to_start()
	else:
		_inventory.load_data(Progress.camp_inventory)
	_apply_equipment()
	_health.current = _health.max_health
	_health.changed.emit(_health.current, _health.max_health)


func _weapon_value(key: String, default: Variant) -> Variant:
	var weapon = _inventory.equipment.get("weapon") if _inventory.equipment else null
	return weapon.get(key, default) if weapon is Dictionary else default


func add_xp(amount: int) -> void:
	# A tapasztalat-bónuszos tárgyak (pl. Tudós szeme) szerint több.
	_experience.add(roundi(amount * (1.0 + _stats.special("xp_bonus") / 100.0)))


## A felvett tárgyak statjait összeadja, és bónuszként átadja a Stats-nak;
## a kézben a felszerelt fegyver képe látszik. Lándzsánál: átütés és nagy hátralökés.
func _apply_equipment() -> void:
	# A felszerelés bónuszai + a tábori (minden futásra érvényes) fejlesztések.
	var bonuses := _inventory.equipment_bonuses()
	var permanent := Progress.permanent_bonuses()
	for stat: String in permanent:
		bonuses[stat] = bonuses.get(stat, 0.0) + permanent[stat]
	_stats.set_bonuses(bonuses)
	var weapon = _inventory.equipment["weapon"]
	if weapon == null:
		return
	_weapon_type = weapon.get("weapon_type", "sword")
	_apply_stats()
	_sword_hitbox.ignore_dodge = _weapon_type == "spear"
	_sword_hitbox.knockback = WEAPON_TYPES[_weapon_type]["knockback"]
	_set_sword_look(Items.icon(weapon))


func _set_sword_look(texture: Texture2D) -> void:
	_sword_sprite.texture = texture
	_update_sword_geometry()


## A fegyver képe és a találati terület a fegyver saját méretéhez igazodik (a hatótáv
## nem nagyítja: dobásnál a dobás távolságát, suhintásnál a testtől való távolságot,
## íjnál a nyíl repülését adja). A markolat a forgáspontnál, a hegy a célzás irányában.
func _update_sword_geometry() -> void:
	if _sword_sprite.texture == null:
		return
	var reach := _stats.attack_range / 100.0
	var shape := RectangleShape2D.new()
	var type_data: Dictionary = WEAPON_TYPES[_weapon_type]
	if type_data.has("length"):
		# Tőr, balta, buzogány, íj: átlós ikon (feje bal felül); a kéz a nyél végén.
		var length: float = type_data["length"]
		var icon_length := _sword_sprite.texture.get_width() * sqrt(2.0)
		_sword_sprite.rotation = SPEAR_SPRITE_ROTATION
		_sword_sprite.scale = Vector2.ONE * length / icon_length
		_sword_sprite.position.x = length / 2.0 - length * ICON_WEAPON_GRIP
		if type_data["style"] == "swing":
			_sword_sprite.position.x += maxf((reach - 1.0) * SWING_REACH_OFFSET, -10.0)
		elif type_data["style"] == "bow":
			# Az íj ikonja átlós; 45°-kal elforgatva függőlegesen áll a célzás irányára merőlegesen.
			_sword_sprite.rotation = PI / 4.0
			_sword_sprite.position.x = 10.0
		shape.size = Vector2(length + SWORD_HITBOX_EXTRA, type_data["width"])
		_sword_shape.position.x = _sword_sprite.position.x + SWORD_HITBOX_EXTRA / 2.0
	elif _weapon_type == "spear":
		var length := SPEAR_LENGTH
		# Az ikon átlósan áll: a hossza az átlója.
		var icon_length := _sword_sprite.texture.get_width() * sqrt(2.0)
		_sword_sprite.rotation = SPEAR_SPRITE_ROTATION
		_sword_sprite.scale = Vector2.ONE * length / icon_length
		_sword_sprite.position.x = length / 2.0 - length * SPEAR_GRIP
		shape.size = Vector2(length + SWORD_HITBOX_EXTRA, SPEAR_HITBOX_WIDTH)
		_sword_shape.position.x = _sword_sprite.position.x + SWORD_HITBOX_EXTRA / 2.0
	else:
		var blade := _sword_sprite.texture.get_height() * 2.0
		# A kard képe függőleges: 90°-kal elforgatva a helyi y tengelye a penge hossza.
		_sword_sprite.rotation = PI / 2.0
		_sword_sprite.scale = Vector2(2.0, 2.0)
		_sword_sprite.position.x = blade / 2.0 + SWORD_HILT_OFFSET
		shape.size = Vector2(blade + SWORD_HITBOX_EXTRA, SWORD_HITBOX_WIDTH)
		_sword_shape.position.x = blade / 2.0 + SWORD_HILT_OFFSET + SWORD_HITBOX_EXTRA / 2.0
	_sword_shape.shape = shape


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


## Felszedett arany (érme): az aranykereső tárgyak szerint több.
func pick_up_gold(amount: int) -> void:
	add_gold(roundi(amount * (1.0 + _stats.special("gold_find") / 100.0)))


## Az ellenség hívja, ha a fegyvered eltalálta: életlopás.
func on_hit_enemy(_damage: int) -> void:
	if randf() * 100.0 < _stats.special("lifesteal") and _health.current < _health.max_health:
		_health.heal(1)
		FloatingText.spawn(get_parent(), global_position + Vector2(0, -56), "+1", Color(0.9, 0.3, 0.5))


## Levonja az árat, ha van elég arany; különben hamisat ad.
func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	add_gold(-amount)
	return true


func attack_cooldown() -> float:
	var cooldown := BASE_ATTACK_COOLDOWN / (_stats.attack_speed / 100.0)
	cooldown *= float(WEAPON_TYPES[_weapon_type]["cooldown"])
	# Az íjász íjjal gyorsabban lő.
	if _weapon_type == "bow":
		cooldown *= 1.0 - Characters.bonus("bow_speed")
	return cooldown


## Emeletváltás előtt elmenti a statokat, a HP-t és a szintet a GameState-be.
func save_state() -> void:
	for stat in Stats.NAMES:
		GameState.saved_stats[stat] = _stats.get_base(stat)
	GameState.saved_health = _health.current
	GameState.saved_level = _experience.level
	GameState.saved_xp = _experience.xp
	GameState.saved_gold = gold
	GameState.saved_inventory = _inventory.save_data()


func _load_state() -> void:
	for stat in GameState.saved_stats:
		_stats.set_base(stat, GameState.saved_stats[stat])
	_experience.restore(GameState.saved_level, GameState.saved_xp)
	gold = GameState.saved_gold
	if not GameState.saved_inventory.is_empty():
		_inventory.load_data(GameState.saved_inventory)


func _physics_process(delta: float) -> void:
	var aim := _weapon_pivot.get_global_mouse_position() - _weapon_pivot.global_position

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * BASE_SPEED * (_stats.move_speed / 100.0) + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	move_and_slide()
	_update_footsteps(delta, input_dir)

	_sprite.flip_h = aim.x < 0.0
	if _sprite.animation != "hit" or not _hurtbox.is_invincible():
		_sprite.play("run" if input_dir != Vector2.ZERO else "idle")

	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if Input.is_action_pressed("attack") and _cooldown_left <= 0.0:
		_swing(aim.angle())
	_cooldown_bar.set_ratio(1.0 - _cooldown_left / attack_cooldown())

	# Villogás, amíg sérthetetlen.
	_visual.visible = not _hurtbox.is_invincible() or fmod(Time.get_ticks_msec() / 80.0, 2.0) < 1.0


## Lépéshangok mozgás közben (a megtett úttal arányosan).
func _update_footsteps(delta: float, input_dir: Vector2) -> void:
	if input_dir == Vector2.ZERO:
		_step_distance = STEP_LENGTH * 0.6
		return
	_step_distance += BASE_SPEED * (_stats.move_speed / 100.0) * delta
	if _step_distance >= STEP_LENGTH:
		_step_distance = 0.0
		Audio.play("footstep", 0.0, 0.15)


func _swing(aim_angle: float) -> void:
	match WEAPON_TYPES[_weapon_type]["style"]:
		"throw":
			_thrust(aim_angle)
			return
		"bow":
			_shoot(aim_angle)
			return
	_cooldown_left = attack_cooldown()
	Audio.play("swing")
	_swing_side = -_swing_side
	_weapon_pivot.visible = true
	_sword_shape.set_deferred("disabled", false)
	var arc := deg_to_rad(WEAPON_TYPES[_weapon_type]["arc"])
	_weapon_pivot.rotation = aim_angle - _swing_side * arc / 2.0
	# Nagyon gyors ütésnél a suhintás is gyorsabb, hogy beleférjen a cooldownba.
	var swing_time := minf(MAX_SWING_TIME * arc / SWING_ARC, _cooldown_left * 0.6)
	var tween := create_tween()
	tween.tween_property(_weapon_pivot, "rotation", aim_angle + _swing_side * arc / 2.0, swing_time)
	await tween.finished
	_sword_shape.set_deferred("disabled", true)
	_weapon_pivot.visible = false


## Dobás / döfés (kard, tőr, lándzsa): a fegyver egyenesen a kurzor felé repül ki,
## `throw` × hatótáv% távolságra, aztán visszatér; közben mindent eltalál az útjában.
func _thrust(aim_angle: float) -> void:
	_cooldown_left = attack_cooldown()
	Audio.play("thrust" if _weapon_type == "spear" else "swing")
	var direction := Vector2.from_angle(aim_angle)
	var distance: float = WEAPON_TYPES[_weapon_type]["throw"] * _stats.attack_range / 100.0
	_weapon_pivot.visible = true
	_weapon_pivot.rotation = aim_angle
	_weapon_pivot.position = WEAPON_PIVOT_POSITION + direction * THRUST_BACK
	_sword_shape.set_deferred("disabled", false)
	# Messzebbre dobva kicsit tovább tart, de mindig belefér a cooldownba.
	var thrust_time := minf(THROW_TIME * sqrt(distance / 64.0), _cooldown_left * 0.8)
	var tween := create_tween()
	tween.tween_property(_weapon_pivot, "position", WEAPON_PIVOT_POSITION + direction * distance,
		thrust_time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Csak kifelé menet sebez (visszafelé nem, hogy egy dobás ne találjon kétszer).
	tween.tween_callback(func() -> void: _sword_shape.set_deferred("disabled", true))
	tween.tween_property(_weapon_pivot, "position", WEAPON_PIVOT_POSITION, thrust_time * 0.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	_weapon_pivot.visible = false
	_weapon_pivot.position = WEAPON_PIVOT_POSITION


## Íj: nyílvessző a kurzor felé; a hatótáv a nyíl repülési távolsága.
func _shoot(aim_angle: float) -> void:
	_cooldown_left = attack_cooldown()
	Audio.play("arrow")
	var direction := Vector2.from_angle(aim_angle)
	# Az íj egy pillanatra látszik a kézben, a célzás irányába fordítva.
	_weapon_pivot.visible = true
	_weapon_pivot.rotation = aim_angle
	_weapon_pivot.position = WEAPON_PIVOT_POSITION
	var arrow: Area2D = PLAYER_ARROW.new()
	arrow.direction = direction
	arrow.speed = ARROW_SPEED
	arrow.max_distance = BOW_RANGE * _stats.attack_range / 100.0
	arrow.damage = hit_damage()
	arrow.crit_chance = _stats.crit_chance / 100.0
	arrow.crit_multiplier = weapon_crit_multiplier()
	arrow.knockback = WEAPON_TYPES["bow"]["knockback"]
	arrow.set_meta("source", self)
	get_parent().add_child(arrow)
	arrow.global_position = _weapon_pivot.global_position + direction * 18.0
	await get_tree().create_timer(0.15, false).timeout
	if _weapon_pivot.rotation == aim_angle:
		_weapon_pivot.visible = false


func _on_hurt(hitbox: Hitbox) -> void:
	# A védelem a sebzés egy részét kivédi (legalább 1 marad).
	var amount := _stats.reduce_damage(hitbox.damage)
	if _health.damage(amount):
		Audio.play("hurt")
		_knockback = hitbox.global_position.direction_to(global_position) * hitbox.knockback
		_sprite.play("hit")
		FloatingText.spawn(get_parent(), global_position + Vector2(0, -56), "-%d" % amount, Color(1, 0.35, 0.3))
		_thorns(hitbox)


## Tüskék: aki közelharcban megüt, maga is sebződik.
func _thorns(hitbox: Hitbox) -> void:
	var thorns := roundi(_stats.special("thorns"))
	var attacker := hitbox.owner
	if thorns <= 0 or attacker == null or not attacker.is_in_group("enemies") or attacker.get_node_or_null("Health") == null:
		return
	attacker.get_node("Health").damage(thorns, false)
	FloatingText.spawn(get_parent(), attacker.global_position + Vector2(0, -40), str(thorns), Color(0.75, 0.9, 0.4))


func _on_dodged() -> void:
	Audio.play("dodge")
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -56), "Kikerülve!", Color(0.6, 0.8, 1))


func _on_died() -> void:
	Audio.play("death")
	Audio.music("")
	set_physics_process(false)
	_hurtbox.set_deferred("monitoring", false)
	_visual.visible = false
	_weapon_pivot.visible = false
	await get_tree().create_timer(DEATH_SCREEN_DELAY).timeout
	death_finished.emit()
