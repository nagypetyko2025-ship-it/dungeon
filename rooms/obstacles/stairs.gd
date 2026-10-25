extends Area2D
## Lépcső a következő szintre. Ha a játékos rálép, `used`-et jelez.
## Lezárva (`set_locked(true)`) vasrács van rajta, és nem lehet használni: a lépcsős
## szobában addig, amíg minden szörnyet le nem győzöl, a táborban pedig pihenő közben.

signal used

const BAR_COLOR := Color(0.32, 0.3, 0.33)
const BAR_HIGHLIGHT := Color(0.55, 0.53, 0.56)

var _used := false
var _locked := false
var _bars: Node2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Közös játékban a lépcsőn várni kell a társakra, de le is lehet lépni róla: ha visszalépsz,
	# újra jelez.
	body_exited.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			_used = false)


func is_locked() -> bool:
	return _locked


func set_locked(locked: bool) -> void:
	_locked = locked
	if locked and _bars == null:
		_bars = _make_bars()
		add_child(_bars)
	elif not locked and _bars != null:
		# A rács felcsúszik és eltűnik.
		var bars := _bars
		_bars = null
		var tween := create_tween()
		tween.tween_property(bars, "position:y", -24.0, 0.4)
		tween.parallel().tween_property(bars, "modulate:a", 0.0, 0.4)
		tween.tween_callback(bars.queue_free)
		# Ha épp a lépcsőn állsz, a felnyitás után azonnal használható.
		for body in get_overlapping_bodies():
			_on_body_entered.call_deferred(body)


## Vasrács a lépcső fölött: függőleges és vízszintes rudak, szegecsekkel.
func _make_bars() -> Node2D:
	var bars := Node2D.new()
	bars.z_index = 1
	for i in 5:
		var x := -12.0 + i * 6.0
		_line(bars, Vector2(x, -15), Vector2(x, 15), 3.0, BAR_COLOR)
		_line(bars, Vector2(x - 1, -15), Vector2(x - 1, 15), 1.0, BAR_HIGHLIGHT)
	for y in [-10.0, 9.0]:
		_line(bars, Vector2(-15, y), Vector2(15, y), 3.0, BAR_COLOR)
		_line(bars, Vector2(-15, y - 1), Vector2(15, y - 1), 1.0, BAR_HIGHLIGHT)
	return bars


func _line(parent: Node2D, from: Vector2, to: Vector2, width: float, color: Color) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([from, to])
	line.width = width
	line.default_color = color
	parent.add_child(line)


func _on_body_entered(body: Node2D) -> void:
	if _used or _locked or not body.is_in_group("player"):
		return
	_used = true
	Audio.play("stairs")
	used.emit()
