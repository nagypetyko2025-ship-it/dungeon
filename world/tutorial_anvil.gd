class_name TutorialAnvil
extends Node2D
## A gyakorló pálya üllője: a tábori kovács műhelyének kipróbálása. Előtte állva E-re megnyílik a kovács
## ablaka (SmithPanel) a gyakorló porokkal (GameState.tutorial_dust; a valódi porok nem változnak).

const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const ANVIL := Vector2i(15, 0)
const FORGE_FRAMES: Array[Vector2i] = [Vector2i(13, 0), Vector2i(14, 0)]
## Ilyen közelről lehet használni.
const RANGE := 64.0

var _prompt: Label


func _ready() -> void:
	z_index = 1
	var forge := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 5.0)
	for coords in FORGE_FRAMES:
		frames.add_frame("default", _rpg(coords))
	forge.sprite_frames = frames
	forge.scale = Vector2(2, 2)
	forge.position = Vector2(-30, -14)
	forge.play()
	add_child(forge)
	var anvil := Sprite2D.new()
	anvil.texture = _rpg(ANVIL)
	anvil.scale = Vector2(2, 2)
	anvil.position = Vector2(12, -12)
	add_child(anvil)
	add_child(_glow())
	_prompt = Label.new()
	_prompt.text = "[E] Gyakorló üllő"
	_prompt.add_theme_font_size_override("font_size", 14)
	_prompt.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 4)
	_prompt.position = Vector2(-60, -64)
	_prompt.size = Vector2(120, 20)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.z_index = 5
	add_child(_prompt)


func _rpg(coords: Vector2i) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = RPG
	texture.region = Rect2(Vector2(coords) * 17.0, Vector2(16, 16))
	return texture


func _glow() -> PointLight2D:
	var light := PointLight2D.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 0.55, 0.2))
	gradient.set_color(1, Color(0, 0, 0, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	light.texture = texture
	light.texture_scale = 0.7
	light.energy = 0.9
	light.position = Vector2(-20, -16)
	return light


func is_near() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	return player != null and player.global_position.distance_to(global_position) < RANGE


func _process(_delta: float) -> void:
	_prompt.visible = is_near() and not GamePause.active(get_tree())


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or not is_near() or GamePause.active(get_tree()):
		return
	var scene := get_tree().current_scene
	var panel := scene.get_node_or_null("SmithPanel")
	if panel == null:
		return
	get_viewport().set_input_as_handled()
	Audio.play("anvil", -4.0)
	scene.get_node("Menus").call("open_menu", panel)
