extends Node2D
## Kék portál. A legyőzött főellenség termében: E-re felajánlja a kimenetelt a táborba
## pihenni (ui/boss_return_panel.gd); ha nem kéred, mehetsz tovább a lépcsőn.
## A táborban (pihenő közben) ugyanez a portál visz vissza a kazamatába: ott az
## `on_use` hívódik a panel helyett.

const PANEL_SCRIPT := preload("res://ui/boss_return_panel.gd")
const INTERACT_RANGE := 64.0
const COLOR := Color(0.45, 0.75, 1.0)

## A felirat, ami a közelében megjelenik.
var prompt_text := "[E] Kimegyek pihenni a táborba"
## Ha be van állítva, E-re ez fut (a táborban: vissza a kazamatába).
var on_use: Callable

var _prompt: Label
var _ring: Polygon2D
var _player: Node2D


func _ready() -> void:
	z_index = -4
	# Kék, lüktető fénykör a padlón, felszálló szikrákkal.
	_ring = Polygon2D.new()
	var points := PackedVector2Array()
	for i in 24:
		points.append(Vector2.from_angle(TAU * i / 24.0) * Vector2(30, 14))
	_ring.polygon = points
	_ring.color = Color(COLOR, 0.55)
	add_child(_ring)
	var pulse := create_tween().set_loops()
	pulse.tween_property(_ring, "scale", Vector2(1.15, 1.15), 0.8).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_ring, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_SINE)
	var sparks := CPUParticles2D.new()
	sparks.amount = 30
	sparks.lifetime = 1.6
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparks.emission_rect_extents = Vector2(26, 8)
	sparks.direction = Vector2(0, -1)
	sparks.spread = 10.0
	sparks.gravity = Vector2(0, -30)
	sparks.initial_velocity_min = 20.0
	sparks.initial_velocity_max = 45.0
	sparks.scale_amount_min = 2.0
	sparks.scale_amount_max = 3.5
	sparks.color = COLOR
	add_child(sparks)
	var light := PointLight2D.new()
	var gradient := Gradient.new()
	gradient.set_color(0, COLOR)
	gradient.set_color(1, Color(0, 0, 0, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	light.texture = texture
	light.texture_scale = 3.0
	light.energy = 1.2
	add_child(light)
	_prompt = MenuStyle.title_label(prompt_text, 22, MenuStyle.GOLD)
	_prompt.position = Vector2(-200, -80)
	_prompt.size = Vector2(400, 30)
	_prompt.modulate.a = 0.0
	_prompt.z_index = 20
	add_child(_prompt)
	scale = Vector2.ZERO
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	var target := 1.0 if _is_near() and not GamePause.active(get_tree()) else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)


func _is_near() -> bool:
	return is_instance_valid(_player) and _player.global_position.distance_to(global_position) < INTERACT_RANGE


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or not _is_near() or GamePause.active(get_tree()):
		return
	get_viewport().set_input_as_handled()
	if on_use.is_valid():
		Audio.play("magic", -6.0)
		on_use.call()
		return
	var scene := get_tree().current_scene
	var panel := scene.get_node_or_null("BossReturnPanel")
	if panel == null:
		panel = PANEL_SCRIPT.new()
		panel.name = "BossReturnPanel"
		scene.add_child(panel)
	Audio.play("magic", -6.0)
	scene.get_node("Menus").call("open_menu", panel)
