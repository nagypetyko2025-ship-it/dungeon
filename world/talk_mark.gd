class_name TalkMark
extends Node2D
## Sárga "!" lebeg egy küldetést / történetet adó NPC feje fölött (mint a kút fölött, lásd Ruin), amíg először
## nem beszéltél vele (Progress.has_talked; a DialoguePanel.open jegyzi fel). A szülő a figura sprite-ja
## (Sprite2D / AnimatedSprite2D): a jel a kép teteje fölé kerül, a szülő nagyítása nem hat rá.
## Bencénél (Thief) szándékosan nincs: az ajtaját nem árulja el, és belépéskor magától megszólít.

const GAP := 4.0

var npc_id := ""
var _label: Label


## A jel a figura fölé; null, ha már beszéltél vele.
static func attach(figure: Node2D, id: String) -> TalkMark:
	if id.is_empty() or id == Thief.ID or Progress.has_talked(id):
		return null
	var mark := TalkMark.new()
	mark.npc_id = id
	figure.add_child(mark)
	return mark


func _ready() -> void:
	z_index = 5
	_label = MenuStyle.title_label("!", 40, MenuStyle.GOLD)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.custom_minimum_size = Vector2(40, 0)
	_label.position = Vector2(-20, -46)
	add_child(_label)
	var bob := _label.create_tween().set_loops()
	bob.tween_property(_label, "position:y", _label.position.y - 8, 0.5).set_trans(Tween.TRANS_SINE)
	bob.tween_property(_label, "position:y", _label.position.y, 0.5).set_trans(Tween.TRANS_SINE)
	# A sprite képét a hívó gyakran csak a hozzáadás után állítja be: egy képkocka múlva igazodunk.
	await get_tree().process_frame
	_place()


func _process(_delta: float) -> void:
	if Progress.has_talked(npc_id):
		queue_free()


## A figura képének teteje fölé, a szülő nagyítását kiegyenlítve.
func _place() -> void:
	var figure := get_parent() as Node2D
	if figure == null:
		return
	var parent_scale := figure.scale.abs()
	if parent_scale.x > 0.0 and parent_scale.y > 0.0:
		scale = Vector2.ONE / parent_scale
	# Ha a szülő csak egy tartó (Node2D), a legmagasabb sprite-gyereke számít.
	var sprite_node: Node2D = figure
	if not (figure is Sprite2D or figure is AnimatedSprite2D):
		var best := INF
		for child in figure.get_children():
			if child is Sprite2D or child is AnimatedSprite2D:
				var child_top := _top_of(child)
				if child_top.y < best:
					best = child_top.y
					sprite_node = child
		if sprite_node == figure:
			position = Vector2(0, -40)
			return
		var top_in_figure := sprite_node.position + _top_of(sprite_node) * sprite_node.scale.abs()
		position = top_in_figure - Vector2(0, GAP / maxf(parent_scale.y, 0.01))
		return
	position = _top_of(figure) - Vector2(0, GAP / maxf(parent_scale.y, 0.01))


## A sprite képének felső közepe a saját koordinátáiban.
static func _top_of(figure: Node2D) -> Vector2:
	var size := Vector2.ZERO
	var padding := 0.0
	var centered := true
	var offset := Vector2.ZERO
	if figure is AnimatedSprite2D:
		var animated := figure as AnimatedSprite2D
		centered = animated.centered
		offset = animated.offset
		if animated.sprite_frames != null and animated.sprite_frames.has_animation(animated.animation) \
				and animated.sprite_frames.get_frame_count(animated.animation) > 0:
			var texture := animated.sprite_frames.get_frame_texture(animated.animation, 0)
			if texture != null:
				size = texture.get_size()
				padding = _top_padding(texture)
	elif figure is Sprite2D:
		var sprite := figure as Sprite2D
		centered = sprite.centered
		offset = sprite.offset
		if sprite.region_enabled:
			size = sprite.region_rect.size
		elif sprite.texture != null:
			size = sprite.texture.get_size() / Vector2(sprite.hframes, sprite.vframes)
			if sprite.hframes == 1 and sprite.vframes == 1:
				padding = _top_padding(sprite.texture)
	return Vector2((0.0 if centered else size.x / 2.0) + offset.x,
		(-size.y / 2.0 if centered else 0.0) + offset.y + padding)


## A kép tetején lévő átlátszó sorok száma (hogy a jel a fej fölé kerüljön, ne a kocka üres teteje fölé).
static func _top_padding(texture: Texture2D) -> float:
	var image := texture.get_image()
	if image == null or image.is_empty():
		return 0.0
	if image.is_compressed():
		image.decompress()
	return float(image.get_used_rect().position.y)
