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
## Többlövésnél a nyilak egymástól ennyi fokkal térnek el, és ennyi pixellel indulnak egymás mellől.
## Suhanás (íjász, Ctrl): időtartam, sebesség (kb. 180 px), fix cooldown.
const DASH_TIME := 0.18
const DASH_SPEED := 1000.0
const DASH_COOLDOWN := 5.0
## Hadi kiáltás (Gáspár): ilyen körben löki el a szörnyeket, ekkorát, ennyi időre töri meg őket.
const WAR_CRY_COOLDOWN := 7.0
const WAR_CRY_RADIUS := 120.0
const WAR_CRY_PUSH := 560.0
const WAR_CRY_STUN := 0.5
const BOSS_SCRIPT := preload("res://enemies/boss.gd")
const MULTISHOT_SPREAD := 8.0
const MULTISHOT_GAP := 16.0
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
var _war_cry_left := 0.0
var _dash_left := 0.0
var _dash_cooldown_left := 0.0
var _dash_dir := Vector2.RIGHT
@onready var _normal_mask := collision_mask


func _ready() -> void:
	_sprite.sprite_frames = Characters.frames(Progress.character)
	_sprite.play("idle")
	_weapon_pivot.visible = false
	_sword_shape.disabled = true
	_hurtbox.hurt.connect(_on_hurt)
	_health.died.connect(_on_died)
	_health.dodged.connect(_on_dodged)
	_load_state()
	# Új futás: a karakter saját alapértékei (az íjász 2 nyilat lő és gyorsabb).
	if GameState.saved_stats.is_empty():
		_apply_character_base(Progress.character)
	elif not GameState.saved_stats.has("accuracy"):
		# Régebbi futás (még nem volt találati esély): a karakter alapértéke.
		_stats.base_accuracy = float(Characters.data(Progress.character).get("accuracy", 75))
	_stats.changed.connect(_apply_stats)
	_inventory.changed.connect(_apply_equipment)
	# Minden szintlépéskor minden alapstat nő egy kicsit (a választott fejlesztésen felül).
	_experience.leveled_up.connect(func(level: int) -> void:
		_stats.apply_level_growth()
		# (A táborban nincs futás: ott nem számít a küldetésbe.)
		if get_tree().current_scene.name == "Dungeon":
			Quests.notify("level", level))
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


## A karakter saját alapstatjai (Többlövés, mozgási sebesség, találati esély).
func _apply_character_base(id: String) -> void:
	var definition := Characters.data(id)
	_stats.base_accuracy = float(definition.get("accuracy", 75))
	_stats.base_health_regen = float(definition.get("health_regen", 0.2))
	_stats.base_multishot = float(definition.get("multishot", 1))
	_stats.base_move_speed = float(definition.get("move_speed", 100))


## Másik karakterre váltás (a kocsmában): kinézet, tábori felszerelés, fejlesztések.
func set_character(id: String) -> void:
	Progress.select_character(id)
	_apply_character_base(id)
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
		# Nagy felbontású kardkép (pl. Gáspár királyi kardja) a "hand_scale" szerint kisebb.
		var hand := float(_weapon_value("hand_scale", 1.0))
		var blade := _sword_sprite.texture.get_height() * 2.0 * hand
		# A kard képe függőleges: 90°-kal elforgatva a helyi y tengelye a penge hossza.
		_sword_sprite.rotation = PI / 2.0
		_sword_sprite.scale = Vector2(2.0, 2.0) * hand
		_sword_sprite.position.x = blade / 2.0 + SWORD_HILT_OFFSET
		shape.size = Vector2(blade + SWORD_HITBOX_EXTRA, SWORD_HITBOX_WIDTH)
		_sword_shape.position.x = blade / 2.0 + SWORD_HILT_OFFSET + SWORD_HITBOX_EXTRA / 2.0
	_sword_shape.shape = shape


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


## Felszedett arany (érme): az aranykereső tárgyak szerint több.
func pick_up_gold(amount: int) -> void:
	var total := roundi(amount * (1.0 + _stats.special("gold_find") / 100.0))
	add_gold(total)
	Quests.notify("gold", total)


## Az ellenség hívja, mielőtt a fegyvered sebezné: 0..1 esély, hogy eltalálod (Találati esély).
func hit_chance() -> float:
	return _stats.accuracy / 100.0


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
	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)
	if _dash_left > 0.0:
		# Suhanás közben fix sebességgel a kurzor felé repül, a szörnyeken át.
		_dash_left -= delta
		velocity = _dash_dir * DASH_SPEED
		move_and_slide()
		if _dash_left <= 0.0:
			_end_dash()
		_cooldown_bar.set_ratio(1.0 - _cooldown_left / attack_cooldown())
		return
	if Input.is_physical_key_pressed(KEY_CTRL) and _can_dash():
		_start_dash(aim)
	_war_cry_left = maxf(_war_cry_left - delta, 0.0)
	if Input.is_physical_key_pressed(KEY_CTRL) and _can_war_cry():
		_war_cry()
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


## Hadi kiáltás (csak Gáspár, Ctrl): "A többiekért!" — a közeli szörnyeket ellöki és egy
## pillanatra megtöri (a főellenségeket nem mozdítja). WAR_CRY_COOLDOWN mp-enként.
func _can_war_cry() -> bool:
	return Characters.data(Progress.character).get("war_cry", false) and _war_cry_left <= 0.0 \
		and not get_tree().paused


func _war_cry() -> void:
	_war_cry_left = WAR_CRY_COOLDOWN
	Audio.play("boss_roar", -4.0, 0.1)
	Audio.play("boss_slam", -10.0)
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -60), "A többiekért!", Color(1, 0.8, 0.35), 22)
	var ring = BOSS_SCRIPT.Shockwave.new()
	ring.radius = WAR_CRY_RADIUS
	ring.position = position
	get_parent().add_child(ring)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var body := enemy as Node2D
		if body == null or body.global_position.distance_to(global_position) > WAR_CRY_RADIUS:
			continue
		var resist := 0.0
		var enemy_stats: Variant = body.get("stats")
		if enemy_stats is Dictionary:
			var dict: Dictionary = enemy_stats
			resist = float(dict.get("resist", 0.0))
		var push := body.global_position - global_position
		body.set("_knockback", (push.normalized() if push.length() > 1.0 else Vector2.RIGHT) * WAR_CRY_PUSH * (1.0 - resist))
		body.set("_stun_left", WAR_CRY_STUN * (1.0 - resist))


func war_cry_cooldown_ratio() -> float:
	return _war_cry_left / WAR_CRY_COOLDOWN


## Suhanás (csak az íjász, Ctrl): rövid, gyors ugrás a kurzor felé; közben a szörnyeken
## (és a lövedékeken) át lehet menni, és nem lehet megsebezni. Fix DASH_COOLDOWN mp.
func _can_dash() -> bool:
	return Characters.data(Progress.character).get("dash", false) and _dash_cooldown_left <= 0.0 \
		and not get_tree().paused


func _start_dash(aim: Vector2) -> void:
	_dash_dir = aim.normalized() if aim.length() > 1.0 else Vector2.RIGHT
	_dash_left = DASH_TIME
	_dash_cooldown_left = DASH_COOLDOWN
	_knockback = Vector2.ZERO
	# Csak a falak állítják meg (a szörnyek rétegét nem érzékeli), és nem sebezhető.
	collision_mask = 1
	_hurtbox.set_deferred("monitoring", false)
	Audio.play("dodge")
	_dash_trail()


func _end_dash() -> void:
	collision_mask = _normal_mask
	_hurtbox.set_deferred("monitoring", true)


## Halvány "utóképek" a suhanás nyomvonalán.
func _dash_trail() -> void:
	for i in 4:
		await get_tree().create_timer(DASH_TIME / 4.0, false).timeout
		var ghost := Sprite2D.new()
		ghost.texture = _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame)
		ghost.flip_h = _sprite.flip_h
		ghost.scale = _sprite.scale
		ghost.offset = _sprite.offset
		ghost.modulate = Color(0.6, 0.9, 1.0, 0.6)
		ghost.global_position = _sprite.global_position
		ghost.z_index = -1
		get_parent().add_child(ghost)
		var fade := ghost.create_tween()
		fade.tween_property(ghost, "modulate:a", 0.0, 0.3)
		fade.tween_callback(ghost.queue_free)


## A suhanás hátralévő cooldownja 0..1 (a HUD-nak; 0 = kész).
func dash_cooldown_ratio() -> float:
	return _dash_cooldown_left / DASH_COOLDOWN


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
	# Többlövés: ennyi nyíl egyszerre, egymás mellett, kicsit szétterülve (nem egymásban).
	var count := _stats.multishot
	# Az oldalirány ugyanarra mutat, amerre a szög is nő: így a nyilak egymás mellől indulnak,
	# és szétfelé repülnek (sosem keresztezik egymást).
	var side := direction.rotated(PI / 2.0)
	for i in count:
		var k := i - (count - 1) / 2.0
		var arrow: Area2D = PLAYER_ARROW.new()
		arrow.direction = direction.rotated(deg_to_rad(MULTISHOT_SPREAD) * k)
		arrow.speed = ARROW_SPEED
		arrow.max_distance = BOW_RANGE * _stats.attack_range / 100.0
		arrow.damage = hit_damage()
		arrow.crit_chance = _stats.crit_chance / 100.0
		arrow.crit_multiplier = weapon_crit_multiplier()
		arrow.knockback = WEAPON_TYPES["bow"]["knockback"]
		arrow.set_meta("source", self)
		get_parent().add_child(arrow)
		arrow.global_position = _weapon_pivot.global_position + direction * 18.0 + side * MULTISHOT_GAP * k
	await get_tree().create_timer(0.15, false).timeout
	if _weapon_pivot.rotation == aim_angle:
		_weapon_pivot.visible = false


func _on_hurt(hitbox: Hitbox) -> void:
	# Halhatatlanság (csalás): semmi nem sebez.
	if GameState.god_mode:
		return
	# A védelem a sebzés egy részét kivédi (legalább 1 marad).
	var amount := _stats.reduce_damage(hitbox.damage)
	if _health.damage(amount):
		Audio.play("hurt")
		_knockback = hitbox.global_position.direction_to(global_position) * hitbox.knockback
		_sprite.play("hit")
		FloatingText.spawn(get_parent(), global_position + Vector2(0, -56), "-%d" % amount, Color(1, 0.35, 0.3))
		_thorns(hitbox)
		# Életlopó támadó (a Vérfarkas): a sebzésből gyógyul.
		var attacker: Variant = hitbox.get_meta("source", hitbox.owner)
		if is_instance_valid(attacker) and attacker.has_method("on_hit_player"):
			attacker.call("on_hit_player", amount)


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
