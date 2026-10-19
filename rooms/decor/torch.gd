extends Node2D
## Fali fáklya: animált láng és meleg, vibráló fény.

const FLICKER_SPEED := 9.0
const FLICKER_AMOUNT := 0.12

var _phase := randf() * TAU
var _base_energy := 0.0

@onready var _light: PointLight2D = $PointLight2D
@onready var _flame: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_base_energy = _light.energy
	_flame.frame = randi() % _flame.sprite_frames.get_frame_count("default")
	_flame.play()


func _process(delta: float) -> void:
	_phase += delta * FLICKER_SPEED
	# Két szinusz keveréke: kevésbé gépies vibrálás.
	_light.energy = _base_energy * (1.0 + FLICKER_AMOUNT * (sin(_phase) * 0.6 + sin(_phase * 2.3) * 0.4))
