extends Control
## Bevezető történet az "Új játék" után: képkockáról képkockára ugró kis jelenetek (a meglévő
## pixel-art elemekből összerakva), alattuk betűnként megjelenő szöveggel. Elmondja a Mélység
## történetét, de semmit nem árul el a mellékszereplők (veterán, tolvaj, kútba esett idegen)
## sorsáról, legfeljebb utal rájuk. Space / Enter / kattintás: tovább (ha még gépel, előbb
## kiírja a szöveget); a Space hosszan nyomva (HOLD_TIME): az egész kihagyása. A végén a tábor jön.

const NEXT_SCENE := "res://world/camp.tscn"
const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const KING: Texture2D = preload("res://assets/characters/king.png")
const THRONE: Texture2D = preload("res://assets/props/throne.png")
const VETERAN: Texture2D = preload("res://assets/characters/veteran.png")
const THIEF: Texture2D = preload("res://assets/characters/thief.png")
const WELL: Texture2D = preload("res://assets/props/well.png")

const STAGE_SIZE := Vector2(960, 400)
const PIXEL := 4.0
const HOLD_TIME := 1.0
const TYPE_SPEED := 45.0
const AUTO_NEXT := 5.0

## 0x72 csempék és figurák.
const WALL_TOP := Rect2(32, 0, 16, 16)
const WALL_MID := Rect2(32, 16, 16, 16)
const BANNER_RED := Rect2(16, 32, 16, 16)
const BANNER_YELLOW := Rect2(32, 48, 16, 16)
const FLOOR := Rect2(16, 64, 16, 16)
const STAIRS := Rect2(80, 192, 16, 16)
const KNIGHT_M := Rect2(128, 100, 16, 28)
const KNIGHT_F := Rect2(128, 68, 16, 28)
const MONSTERS: Array[Rect2] = [Rect2(368, 88, 16, 16), Rect2(368, 40, 16, 16), Rect2(368, 177, 16, 23),
	Rect2(368, 225, 16, 23), Rect2(368, 273, 16, 23), Rect2(368, 153, 16, 23)]
const BIG_DEMON := Rect2(16, 428, 32, 36)
const OGRE := Rect2(16, 380, 32, 36)

const SLIDES := [
	"Valaha a királyság fényes volt. A falak erősek voltak, a zászlók büszkék, és a király népe nem ismerte a félelmet.",
	"Aztán egy éjjel megnyílt a föld a város alatt. Egy ősi lépcső bukkant elő, ami a sötétbe vezetett, és senki sem látta az alját. Az emberek [b]Mélységnek[/b] nevezték el.",
	"A régi írások kincset és válaszokat ígértek odalent. A király útnak indította a legjobb katonáit... de a Mélység nem adja könnyen a titkait.",
	"Odalent szörnyek élnek. Minél lejjebb jutsz, annál erősebbek, és a legmélyebb termekben olyan urak várnak, akiknek a nevét is csak suttogni merik.",
	"A Mélység szájánál tábor nőtt. Kalandorok jönnek és mennek, néhányan pedig itt ragadtak. Mindegyiküknek megvan a maga története... ha elég türelmes vagy meghallgatni.",
	"Te is egy vagy közülük. Egy rozsdás kard, egy maroknyi bátorság, és egy lépcső, ami lefelé vezet.\n\n[b]A Mélység vár.[/b]",
]

var _index := -1
var _stage: Control
var _picture: Node2D
var _text: RichTextLabel
var _counter: Label
var _hold_bar: ProgressBar
var _fade: ColorRect
var _typed := 0.0
var _shown_for := 0.0
var _hold := 0.0
var _space_was_down := false
var _busy := false
var _leaving := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	RenderingServer.set_default_clear_color(Color.BLACK)
	Audio.music("menu")
	_build()
	_next()


func _build() -> void:
	var background := ColorRect.new()
	background.color = Color(0.02, 0.015, 0.02)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.position = Vector2(-STAGE_SIZE.x / 2.0, -300)
	column.add_theme_constant_override("separation", 24)
	add_child(column)
	# A kép: keretes "ablak", benne a jelenet (pixel-nagyítással).
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", MenuStyle.box(MenuStyle.MENU_PANEL, 6, 6))
	column.add_child(frame)
	_stage = Control.new()
	_stage.custom_minimum_size = STAGE_SIZE
	_stage.clip_contents = true
	_stage.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_child(_stage)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.custom_minimum_size = Vector2(STAGE_SIZE.x, 120)
	_text.add_theme_font_override("normal_font", MenuStyle.BUTTON_FONT)
	_text.add_theme_font_override("bold_font", MenuStyle.BUTTON_FONT)
	_text.add_theme_font_size_override("normal_font_size", 22)
	_text.add_theme_font_size_override("bold_font_size", 22)
	_text.add_theme_color_override("default_color", MenuStyle.PARCHMENT)
	_text.add_theme_color_override("font_outline_color", MenuStyle.SHADOW)
	_text.add_theme_constant_override("outline_size", 5)
	column.add_child(_text)
	# Jobb alul: a súgó és a kihagyás csíkja.
	var hint_box := VBoxContainer.new()
	hint_box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint_box.position = Vector2(-430, -90)
	hint_box.custom_minimum_size = Vector2(400, 0)
	add_child(hint_box)
	_counter = _small_label("", MenuStyle.GOLD)
	hint_box.add_child(_counter)
	hint_box.add_child(_small_label("Space / kattintás: tovább   ·   Space hosszan: kihagyás", MenuStyle.PARCHMENT))
	_hold_bar = ProgressBar.new()
	_hold_bar.show_percentage = false
	_hold_bar.max_value = HOLD_TIME
	_hold_bar.custom_minimum_size = Vector2(400, 8)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(1, 1, 1, 0.08)
	var fill := StyleBoxFlat.new()
	fill.bg_color = MenuStyle.GOLD
	_hold_bar.add_theme_stylebox_override("background", back)
	_hold_bar.add_theme_stylebox_override("fill", fill)
	hint_box.add_child(_hold_bar)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)


func _small_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", MenuStyle.SHADOW)
	label.add_theme_constant_override("outline_size", 4)
	return label


func _process(delta: float) -> void:
	if _leaving:
		return
	# Gépelés, aztán egy idő múlva magától továbblép.
	if not _busy:
		_typed += delta * TYPE_SPEED
		_text.visible_characters = int(_typed)
		if _text.visible_ratio >= 1.0:
			_shown_for += delta
			if _shown_for >= AUTO_NEXT:
				_next()
	# Space hosszan: kihagyás; röviden (felengedéskor): tovább.
	var down := Input.is_physical_key_pressed(KEY_SPACE)
	if down:
		_hold += delta
		if _hold >= HOLD_TIME:
			_finish()
	elif _space_was_down and _hold < HOLD_TIME * 0.35:
		_advance()
	if not down:
		_hold = 0.0
	_space_was_down = down
	_hold_bar.value = _hold


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]:
		_advance()
	elif key and key.pressed and key.physical_keycode == KEY_ESCAPE:
		_finish()
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		_advance()


## Tovább: ha a szöveg még gépelődik, előbb kiírja, különben a következő kép.
func _advance() -> void:
	if _busy or _leaving:
		return
	if _text.visible_ratio < 1.0:
		_typed = 9999.0
		_text.visible_characters = -1
		return
	_next()


func _next() -> void:
	if _index + 1 >= SLIDES.size():
		_finish()
		return
	_busy = true
	var out := create_tween()
	out.tween_property(_fade, "color:a", 1.0, 0.25 if _index >= 0 else 0.0)
	await out.finished
	_index += 1
	if is_instance_valid(_picture):
		_picture.queue_free()
	_picture = Node2D.new()
	_picture.scale = Vector2(PIXEL, PIXEL)
	_stage.add_child(_picture)
	call("_slide_%d" % _index)
	# Lassú "kameramozgás": a kép picit közelít.
	var zoom := _picture.create_tween()
	zoom.tween_property(_picture, "scale", Vector2(PIXEL, PIXEL) * 1.04, AUTO_NEXT + 3.0)
	_text.text = SLIDES[_index]
	_text.visible_characters = 0
	_typed = 0.0
	_shown_for = 0.0
	_counter.text = "%d / %d" % [_index + 1, SLIDES.size()]
	Audio.play("ui_click", -6.0)
	var back := create_tween()
	back.tween_property(_fade, "color:a", 0.0, 0.35)
	await back.finished
	_busy = false


func _finish() -> void:
	if _leaving:
		return
	_leaving = true
	var out := create_tween()
	out.tween_property(_fade, "color:a", 1.0, 0.5)
	await out.finished
	get_tree().change_scene_to_file(NEXT_SCENE)


# ---------------------------------------------------------------- a jelenetek (240x100 "pixelen")

## 1. A fényes királyság: várfal zászlókkal, a trónon a király, két őr.
func _slide_0() -> void:
	_sky(Color(0.25, 0.32, 0.55), Color(0.55, 0.45, 0.4))
	for x in 15:
		_tile(WALL_TOP, Vector2(x * 16, 30))
		_tile(WALL_MID, Vector2(x * 16, 46))
		_tile(WALL_MID, Vector2(x * 16, 62))
	for x in [2, 6, 8, 12]:
		_tile(BANNER_RED if x % 4 == 0 else BANNER_YELLOW, Vector2(x * 16, 46))
	for x in 15:
		_tile(FLOOR, Vector2(x * 16, 78))
		_tile(FLOOR, Vector2(x * 16, 94))
	_texture(THRONE, Vector2(120, 66))
	_frames(_sheet_frames(KING, Vector2(16, 32)), Vector2(120, 74))
	_frames(SpriteSheet.character_frames(KNIGHT_F), Vector2(92, 80))
	_frames(SpriteSheet.character_frames(KNIGHT_F), Vector2(148, 80), true)
	_torch(Vector2(64, 56))
	_torch(Vector2(176, 56))


## 2. A Mélység megnyílik: sötét föld, középen a lefelé vezető lépcső, körülötte repedések.
func _slide_1() -> void:
	_sky(Color(0.05, 0.04, 0.08), Color(0.12, 0.08, 0.1))
	for x in 15:
		for y in 3:
			_tile(FLOOR, Vector2(x * 16, 52 + y * 16)).modulate = Color(0.45, 0.4, 0.45)
	var hole := ColorRect.new()
	hole.color = Color(0, 0, 0)
	hole.position = Vector2(96, 58)
	hole.size = Vector2(48, 36)
	_picture.add_child(hole)
	for i in 3:
		_tile(STAIRS, Vector2(112 + i * 0, 66 + i * 10)).modulate = Color(1, 1, 1, 1.0 - i * 0.3)
	_glow(Vector2(120, 76), Color(0.6, 0.2, 0.9, 0.35), 40.0)
	for crack: Array in [[Vector2(70, 62), Vector2(96, 70)], [Vector2(144, 72), Vector2(178, 64)], [Vector2(120, 94), Vector2(118, 100)]]:
		var line := Line2D.new()
		line.width = 1.0
		line.default_color = Color(0, 0, 0, 0.9)
		line.add_point(crack[0])
		line.add_point(crack[1])
		_picture.add_child(line)
	# Szemek a sötétben.
	for at: Vector2 in [Vector2(108, 82), Vector2(130, 88)]:
		for dx in [0, 4]:
			var eye := ColorRect.new()
			eye.color = Color(1, 0.2, 0.15)
			eye.position = at + Vector2(dx, 0)
			eye.size = Vector2(1, 1)
			_picture.add_child(eye)


## 3. A király katonái a lépcső felé menetelnek (az egyikük kapitány: rájuk utal).
func _slide_2() -> void:
	_sky(Color(0.1, 0.09, 0.14), Color(0.25, 0.2, 0.22))
	for x in 15:
		_tile(FLOOR, Vector2(x * 16, 70)).modulate = Color(0.7, 0.65, 0.65)
		_tile(FLOOR, Vector2(x * 16, 86)).modulate = Color(0.7, 0.65, 0.65)
	_tile(STAIRS, Vector2(208, 80))
	_glow(Vector2(216, 88), Color(0.6, 0.2, 0.9, 0.3), 26.0)
	for i in 7:
		var soldier := _frames(SpriteSheet.character_frames(KNIGHT_M if i % 2 == 0 else KNIGHT_F), Vector2(30 + i * 22, 84 + (i % 2) * 6))
		soldier.play("run")
		soldier.speed_scale = 0.6
	_torch(Vector2(196, 60))


## 4. Szörnyek a sötétben, mögöttük két óriási úr árnyéka.
func _slide_3() -> void:
	_sky(Color(0.06, 0.02, 0.04), Color(0.18, 0.05, 0.06))
	for x in 15:
		_tile(FLOOR, Vector2(x * 16, 86)).modulate = Color(0.4, 0.3, 0.3)
	var lord := _frames(SpriteSheet.character_frames(BIG_DEMON), Vector2(90, 70))
	lord.scale = Vector2(2.2, 2.2)
	lord.modulate = Color(0.15, 0.05, 0.08)
	var lord2 := _frames(SpriteSheet.character_frames(OGRE), Vector2(160, 70))
	lord2.scale = Vector2(2.0, 2.0)
	lord2.modulate = Color(0.12, 0.06, 0.08)
	for i in MONSTERS.size():
		var monster := _frames(SpriteSheet.character_frames(MONSTERS[i]), Vector2(30 + i * 36, 92 - (i % 2) * 6))
		monster.modulate = Color(0.9, 0.75, 0.75)
	_glow(Vector2(120, 60), Color(0.9, 0.1, 0.1, 0.25), 70.0)


## 5. A tábor éjjel: sátor, tűz; a tűznél egy sebesült öreg katona, a fák között egy csuklyás
## árnyék, hátul egy öreg kút (csak utalások).
func _slide_4() -> void:
	_sky(Color(0.08, 0.1, 0.2), Color(0.15, 0.25, 0.15))
	for x in 15:
		for y in 3:
			_rpg(Vector2i(x % 2, 15 + y % 2), Vector2(x * 16, 54 + y * 16)).modulate = Color(0.55, 0.65, 0.6)
	for i in 6:
		_rpg(Vector2i(13 + (i % 3) * 2, 11), Vector2(8 + i * 44, 44)).modulate = Color(0.35, 0.45, 0.4)
	for dx in 2:
		for dy in 2:
			_rpg(Vector2i(46 + dx, 10 + dy), Vector2(36 + dx * 16, 58 + dy * 16))
	var fire := AnimatedSprite2D.new()
	fire.sprite_frames = _rpg_frames([Vector2i(14, 8), Vector2i(15, 8)])
	fire.position = Vector2(120, 86)
	fire.play()
	_picture.add_child(fire)
	_glow(Vector2(120, 82), Color(1, 0.6, 0.2, 0.35), 40.0)
	var veteran := _frames(_sheet_frames(VETERAN, Vector2(16, 28)), Vector2(98, 86))
	veteran.speed_scale = 0.3
	var thief := _frames(_sheet_frames(THIEF, Vector2(16, 28)), Vector2(206, 74), true)
	thief.modulate = Color(0.15, 0.15, 0.2)
	_texture(WELL, Vector2(180, 64)).scale = Vector2(0.8, 0.8)
	_frames(SpriteSheet.character_frames(Rect2(128, 292, 16, 28)), Vector2(146, 86), true)


## 6. Te: egyedül a lépcső előtt, rozsdás karddal, a fáklya fényében.
func _slide_5() -> void:
	_sky(Color(0.04, 0.03, 0.05), Color(0.1, 0.08, 0.08))
	for x in 15:
		_tile(WALL_TOP, Vector2(x * 16, 30)).modulate = Color(0.6, 0.55, 0.55)
		_tile(WALL_MID, Vector2(x * 16, 46)).modulate = Color(0.6, 0.55, 0.55)
		_tile(FLOOR, Vector2(x * 16, 62)).modulate = Color(0.7, 0.65, 0.65)
		_tile(FLOOR, Vector2(x * 16, 78)).modulate = Color(0.7, 0.65, 0.65)
		_tile(FLOOR, Vector2(x * 16, 94)).modulate = Color(0.7, 0.65, 0.65)
	_tile(STAIRS, Vector2(150, 74))
	_glow(Vector2(158, 82), Color(0.6, 0.2, 0.9, 0.35), 24.0)
	_torch(Vector2(100, 50))
	_torch(Vector2(200, 50))
	_frames(SpriteSheet.character_frames(KNIGHT_M), Vector2(110, 86))
	var sword := Sprite2D.new()
	sword.texture = SpriteSheet.region(Rect2(323, 10, 10, 21))
	sword.position = Vector2(120, 80)
	sword.rotation = 0.6
	sword.modulate = Color(0.85, 0.6, 0.45)
	_picture.add_child(sword)


# ---------------------------------------------------------------- segédek

func _sky(top: Color, bottom: Color) -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, top)
	gradient.set_color(1, bottom)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	var sky := TextureRect.new()
	sky.texture = texture
	sky.size = STAGE_SIZE / PIXEL
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.add_child(sky)


func _tile(region: Rect2, at: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = SpriteSheet.region(region)
	sprite.centered = false
	sprite.position = at
	_picture.add_child(sprite)
	return sprite


func _rpg(coords: Vector2i, at: Vector2) -> Sprite2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = RPG
	atlas.region = Rect2(Vector2(coords) * 17.0, Vector2(16, 16))
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.centered = false
	sprite.position = at
	_picture.add_child(sprite)
	return sprite


func _rpg_frames(list: Array[Vector2i]) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 6.0)
	for coords in list:
		var atlas := AtlasTexture.new()
		atlas.atlas = RPG
		atlas.region = Rect2(Vector2(coords) * 17.0, Vector2(16, 16))
		frames.add_frame("default", atlas)
	return frames


func _texture(texture: Texture2D, at: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = at
	_picture.add_child(sprite)
	return sprite


## Saját lap (álló kockák: 0-3) animációja "idle" néven.
func _sheet_frames(sheet: Texture2D, frame_size: Vector2) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 4.0)
	for i in 4:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(Vector2(i * frame_size.x, 0), frame_size)
		frames.add_frame("idle", atlas)
	return frames


## Animált figura, talppontjával az `at` helyen.
func _frames(frames: SpriteFrames, at: Vector2, flip := false) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.centered = true
	var size := frames.get_frame_texture("idle", 0).get_size()
	sprite.offset = Vector2(0, -size.y / 2.0)
	sprite.position = at
	sprite.flip_h = flip
	sprite.play("idle")
	_picture.add_child(sprite)
	return sprite


## Fali fáklya: fa nyél, rajta lobogó láng (a Kenney tábortűz kockáiból).
func _torch(at: Vector2) -> void:
	var handle := ColorRect.new()
	handle.color = Color(0.35, 0.22, 0.12)
	handle.position = at + Vector2(-1, 2)
	handle.size = Vector2(2, 7)
	_picture.add_child(handle)
	var flame := AnimatedSprite2D.new()
	flame.sprite_frames = _rpg_frames([Vector2i(14, 8), Vector2i(15, 8)])
	flame.position = at + Vector2(0, -1)
	flame.scale = Vector2(0.55, 0.55)
	flame.play()
	_picture.add_child(flame)
	_glow(at, Color(1, 0.6, 0.25, 0.35), 20.0)


## Lágy fényfolt (sugárirányú átmenet).
func _glow(at: Vector2, color: Color, radius: float) -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(color, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	texture.width = 64
	texture.height = 64
	var glow := Sprite2D.new()
	glow.texture = texture
	glow.position = at
	glow.scale = Vector2.ONE * radius * 2.0 / 64.0
	_picture.add_child(glow)
