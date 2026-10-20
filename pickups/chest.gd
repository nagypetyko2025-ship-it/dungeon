extends StaticBody2D
## Láda: a kitakarított szobában jelenik meg. Ha a játékos hozzáér,
## kinyílik, és aranyérmék pattannak ki belőle (néha üres); ITEM_CHANCE
## eséllyel egy tárgy is, legfeljebb ITEM_MAX_RARITY ritkaságú.

const COIN := preload("res://pickups/coin.tscn")
const ITEM_DROP := preload("res://pickups/item_drop.tscn")
const EMPTY_CHANCE := 0.15
const MAX_COINS := 8
## Arany: GOLD_BASE véletlen része + emeletenként GOLD_PER_DEPTH.
const GOLD_BASE := Vector2i(5, 12)
const GOLD_PER_DEPTH := 3
const ITEM_CHANCE := 0.08
const ITEM_MAX_RARITY := "rare"
const FULL_FIRST_FRAME := Rect2(304, 416, 16, 16)
const EMPTY_FIRST_FRAME := Rect2(304, 400, 16, 16)
const OPEN_FRAMES := 3

## Az emelet; mélyebben több arany van a ládákban.
var depth := 1

var _empty := false
var _opened := false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_empty = randf() < EMPTY_CHANCE
	_sprite.sprite_frames = _make_frames()
	_sprite.animation = "empty" if _empty else "full"
	_sprite.frame = 0
	$TouchArea.body_entered.connect(_on_body_entered)
	# Megjelenési animáció.
	_sprite.scale = Vector2.ZERO
	create_tween().tween_property(_sprite, "scale", Vector2(2, 2), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _open() -> void:
	if _opened:
		return
	_opened = true
	Quests.notify("chest")
	Audio.play("chest_open")
	_sprite.play()
	await _sprite.animation_finished
	if _empty:
		FloatingText.spawn(get_parent(), global_position + Vector2(0, -16), "Üres...", Color(0.75, 0.7, 0.65))
		return
	if randf() < ITEM_CHANCE:
		var drop = ITEM_DROP.instantiate()
		drop.item = Items.random_item(ITEM_MAX_RARITY)
		drop.position = position + Vector2(0, -12)
		get_parent().add_child(drop)
	var total := randi_range(GOLD_BASE.x, GOLD_BASE.y) + depth * GOLD_PER_DEPTH
	var count := mini(total, MAX_COINS)
	for i in count:
		var coin = COIN.instantiate()
		# Az utolsó érme viszi a maradékot.
		coin.value = total - (count - 1) * (total / count) if i == count - 1 else total / count
		coin.position = position + Vector2(0, -12)
		get_parent().add_child(coin)
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -16), "+%d arany" % total, Color(1, 0.85, 0.3))


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_open()


func _make_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim in ["full", "empty"]:
		var first := FULL_FIRST_FRAME if anim == "full" else EMPTY_FIRST_FRAME
		frames.add_animation(anim)
		frames.set_animation_loop(anim, false)
		frames.set_animation_speed(anim, 10.0)
		for i in OPEN_FRAMES:
			var rect := first
			rect.position.x += i * first.size.x
			frames.add_frame(anim, SpriteSheet.region(rect))
	return frames
