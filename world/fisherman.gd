class_name Fisherman
extends Node2D
## Az öreg horgász a tó partján: egy ideig horgászik (a botot és a zsinórt a játék rajzolja, az úszó
## billeg, néha "kapás" van), aztán a part mentén arrébb sétál, és ott horgászik tovább.
## Egyelőre nem lehet vele beszélni. Kép: assets/characters/old_fisherman.png (CC0; 4 irány).
## (A tó rakja le: a tábor Entities rétegébe, hogy a mélységi sorrend jó legyen.)

const SHEET: Texture2D = preload("res://assets/characters/old_fisherman.png")
const FRAME := Vector2i(20, 37)
## A képen az irányok sorrendje.
const FRONT := 0
const LEFT := 1
const RIGHT := 2
const BACK := 3
const SCALE := 1.8
const WALK_SPEED := 26.0
## A part (az ellipszis) ennyivel nagyobb a tónál: itt áll és jár.
const SHORE := 1.18
const FISH_TIME := Vector2(14.0, 26.0)

var _sprite: Sprite2D
var _rod: Node2D
var _angle := 0.0
var _target_angle := 0.0
var _fishing := true
var _timer := 0.0
var _time := 0.0
var _bite := 0.0
## A víz felé mutató egységvektor (horgászáskor).
var _facing := Vector2.UP


func _ready() -> void:
	_sprite = Sprite2D.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEET
	atlas.region = Rect2(0, 0, FRAME.x, FRAME.y)
	_sprite.texture = atlas
	_sprite.scale = Vector2(SCALE, SCALE)
	_sprite.offset = Vector2(0, -FRAME.y / 2.0 + 2)
	add_child(_sprite)
	_rod = Node2D.new()
	_rod.draw.connect(_draw_rod)
	add_child(_rod)
	# A délkeleti parton kezd (a mólótól jobbra).
	_angle = PI / 2.0 - 0.6
	_place()
	_start_fishing()


## A part egy pontja (szög szerint) képpontban.
static func shore_point(angle: float) -> Vector2:
	var at := Lake.CENTER + Vector2(cos(angle) * Lake.RADIUS.x, sin(angle) * Lake.RADIUS.y) * SHORE
	return at * Lake.TILE


func _place() -> void:
	position = shore_point(_angle)


func _start_fishing() -> void:
	_fishing = true
	_timer = randf_range(FISH_TIME.x, FISH_TIME.y)
	_facing = (Lake.CENTER * Lake.TILE - position).normalized()
	_set_frame(_facing)
	_rod.queue_redraw()


## Új horgászhely: a part mentén legfeljebb kb. negyed környit arrébb (a móló tövét kerülve).
func _start_walking() -> void:
	_fishing = false
	var step := randf_range(0.5, 1.3) * (1.0 if randf() < 0.5 else -1.0)
	_target_angle = _angle + step
	# A móló tövében ne álljon meg (ott a móló takarná a botot).
	var pier_angle := PI / 2.0 + asin((Lake.CENTER.x - Lake.PIER_COLUMN - 0.5) / (Lake.RADIUS.x * SHORE))
	if absf(wrapf(_target_angle - pier_angle, -PI, PI)) < 0.3:
		_target_angle += 0.6 * signf(step)
	_rod.queue_redraw()


func _set_frame(direction: Vector2) -> void:
	var index := FRONT
	if absf(direction.x) > absf(direction.y):
		index = RIGHT if direction.x > 0.0 else LEFT
	else:
		index = FRONT if direction.y > 0.0 else BACK
	(_sprite.texture as AtlasTexture).region = Rect2(index * FRAME.x, 0, FRAME.x, FRAME.y)


func _process(delta: float) -> void:
	_time += delta
	if _fishing:
		_timer -= delta
		if _bite <= 0.0 and randf() < delta * 0.08:
			_bite = 1.2
		_bite = maxf(_bite - delta, 0.0)
		_sprite.position = Vector2.ZERO
		if _timer <= 0.0:
			_start_walking()
		_rod.queue_redraw()
		return
	# Séta a part mentén (az ív hosszával arányos szögsebességgel), kis bicegéssel.
	var radius := shore_point(_angle).distance_to(shore_point(_angle + 0.01)) / 0.01
	var turn := WALK_SPEED * delta / maxf(radius, 1.0)
	var before := position
	_angle = move_toward(_angle, _target_angle, turn)
	_place()
	_set_frame(position - before)
	_sprite.position.y = -absf(sin(_time * 7.0)) * 2.0
	if is_equal_approx(_angle, _target_angle):
		_sprite.position = Vector2.ZERO
		_start_fishing()


## A bot a kezéből a víz fölé nyúlik, a végéről zsinór lóg az úszóig.
func _draw_rod() -> void:
	if not _fishing:
		return
	var side := Vector2(-_facing.y, _facing.x)
	var hand := Vector2(0, -28) + side * 10.0
	var sway := sin(_time * 1.3) * 2.0
	var tip := hand + _facing * 56.0 + Vector2(0, -30 + sway)
	if _bite > 0.0:
		tip.y += 6.0
	var bobber := hand + _facing * 72.0 + Vector2(0, 14)
	var dip := 4.0 if _bite > 0.0 and fmod(_time, 0.3) < 0.15 else sin(_time * 2.5) * 1.2
	bobber.y += dip
	_rod.draw_line(hand, tip, Color(0.55, 0.36, 0.18), 3.0)
	_rod.draw_line(tip, bobber, Color(0.95, 0.95, 0.9, 0.85), 1.5)
	_rod.draw_circle(bobber, 3.0, Color(0.9, 0.15, 0.1))
	_rod.draw_circle(bobber + Vector2(0, -1.5), 1.5, Color(1, 1, 1))
	if _bite > 0.0:
		_rod.draw_arc(bobber + Vector2(0, 3), 6.0 + (1.2 - _bite) * 8.0, 0.0, TAU, 16, Color(1, 1, 1, _bite * 0.5), 1.0)
