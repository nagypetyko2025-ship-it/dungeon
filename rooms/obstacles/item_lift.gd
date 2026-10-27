extends Node2D
## Tárgylift a bolt melletti falban: boltíves nyílás egy sötét aknára, benne
## kötélen lógó láda, mellette egy kar. Ha a közelében E-t nyomsz, megnyílik
## a tárgylift ablaka (ui/item_lift_panel.gd): liftenként egy tárgyat küldhetsz fel
## a táborba. A csomópont helye a nyílás alja.

const SHEET: Texture2D = preload("res://assets/0x72_dungeon/0x72_DungeonTilesetII_v1.7.png")
const CONTAINERS: Texture2D = preload("res://assets/shop/barrels_and_boxes.png")
const PANEL_SCRIPT := preload("res://ui/item_lift_panel.gd")
## Nyitott, boltíves ajtókeret (0x72); a belsejét mi rajzoljuk sötétre.
const ARCH := Rect2(80, 240, 32, 32)
const LEVER := Rect2(80, 208, 16, 16)
const CRATE := Rect2(32, 0, 16, 16)
const INTERACT_RANGE := 70.0
const ROPE_COLOR := Color(0.55, 0.4, 0.22)

var _prompt: Label
var _crate: Sprite2D
var _player: Node2D


func _ready() -> void:
	z_index = -4
	# Az akna sötétje a keret mögött.
	var shaft := Polygon2D.new()
	shaft.color = Color(0.03, 0.02, 0.03)
	shaft.polygon = PackedVector2Array([Vector2(-18, -2), Vector2(18, -2), Vector2(18, -50), Vector2(-18, -50)])
	add_child(shaft)
	# Csiga fent, kötelek le a ládáig.
	var pulley := Polygon2D.new()
	pulley.color = Color(0.45, 0.42, 0.4)
	var points := PackedVector2Array()
	for i in 10:
		points.append(Vector2(0, -50) + Vector2.from_angle(TAU * i / 10.0) * 7.0)
	pulley.polygon = points
	add_child(pulley)
	for x in [-6.0, 6.0]:
		var rope := Line2D.new()
		rope.width = 2.0
		rope.default_color = ROPE_COLOR
		rope.points = PackedVector2Array([Vector2(x, -50), Vector2(x, -22)])
		add_child(rope)
	_crate = _sprite(CONTAINERS, CRATE, Vector2(0, -12), 1.6)
	# Lassan billeg, mintha a kötélen lógna.
	var sway := create_tween().set_loops()
	sway.tween_property(_crate, "position:y", -14.0, 1.1).set_trans(Tween.TRANS_SINE)
	sway.tween_property(_crate, "position:y", -12.0, 1.1).set_trans(Tween.TRANS_SINE)
	_sprite(SHEET, ARCH, Vector2(0, -32), 2.0)
	# A kar a bal oldalon (jobbra a középső folyosó ajtaja lehet).
	_sprite(SHEET, LEVER, Vector2(-46, -12), 2.0).flip_h = true
	_prompt = MenuStyle.title_label("[E] Tárgylift", 22, MenuStyle.GOLD)
	_prompt.position = Vector2(-90, -100)
	_prompt.size = Vector2(180, 30)
	_prompt.modulate.a = 0.0
	_prompt.z_index = 20
	add_child(_prompt)


func _sprite(texture: Texture2D, region: Rect2, at: Vector2, scale_factor: float) -> Sprite2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.scale = Vector2.ONE * scale_factor
	sprite.position = at
	add_child(sprite)
	return sprite


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	var target := 1.0 if _is_near() and not GamePause.active(get_tree()) else 0.0
	_prompt.modulate.a = move_toward(_prompt.modulate.a, target, delta * 5.0)


func _is_near() -> bool:
	return is_instance_valid(_player) and _player.global_position.distance_to(global_position + Vector2(0, 16)) < INTERACT_RANGE


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or not _is_near() or GamePause.active(get_tree()):
		return
	get_viewport().set_input_as_handled()
	# A próbatételből nem lehet felküldeni semmit.
	if Challenge.active():
		Audio.play("ui_error")
		FloatingText.spawn(get_parent(), global_position + Vector2(0, -40), "A próbatételből nem lehet felküldeni tárgyat.",
			Color(1, 0.6, 0.45), 18)
		return
	var scene := get_tree().current_scene
	var panel := scene.get_node_or_null("ItemLiftPanel")
	if panel == null:
		panel = PANEL_SCRIPT.new()
		panel.name = "ItemLiftPanel"
		scene.add_child(panel)
	Audio.play("door_unlock", -4.0)
	scene.get_node("Menus").call("open_menu", panel)
