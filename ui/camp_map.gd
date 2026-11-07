class_name CampMap
extends Control
## A tábor és környéke térképe. Betöltéskor egyszer "lefényképezi" a teljes külső világot felülről (SubViewport,
## ugyanazzal a World2D-vel, esti színezés és a játékos nélkül), erre kerülnek a helyszínek jelei.
## Kicsiben (jobb alul) a játékos körüli részt mutatja és vele mozog; M-re (Menus: HUD/Minimap) nagy térkép,
## oldalakkal (◄ ► / A, D): az egész vidék, a tábor, a nyugati tisztás, a város, a vár, a tó és a bánya.
## Ha az egér egy jel fölé ér, kiírja, mit lehet ott csinálni, és egy rövid leírást.
## A titkos erdei sír (HiddenGrave) és a fája nincs jelölve: a tisztását a fényképen erdővel takarjuk le.

const TILE := 32
## A fénykép mérete a világhoz képest (1 csempe = 8 képpont).
const SCALE := 0.25
const SMALL_SIZE := Vector2(270, 180)
## Kicsiben ennyi csempényi szélesség látszik a játékos körül.
const SMALL_VIEW_TILES := 30.0
const BIG_SIZE := Vector2(1140, 620)
const MARKER_RADIUS := 7.0
const HOVER_RADIUS := 14.0
const PLAYER_COLOR := Color(1, 0.85, 0.25)
const INK := Color(0.2, 0.12, 0.07)

## A világ (csempében) és a helyszínek: {name, pos (világ-képpont), color, does, text, left?}. A tábor adja (setup).
var _world := Rect2i()
var _locations: Array[Dictionary] = []
var _pages: Array = []
var _page := 0
var _player: Node2D
var _camp: Node2D
var _map: Texture2D
var _expanded := false
var _small_offsets: Array[float] = []
var _small_style := UiStyle.plain_panel()
var _big_style := UiStyle.decorated_panel()
var _title: PanelContainer
var _title_label: Label
var _prev: Button
var _next: Button
var _tip: PanelContainer
var _tip_name: Label
var _tip_does: Label
var _tip_text: Label
var _hover := -1
var _font: Font


## `world`: a külső világ csempében; `pages`: [[név, Rect2i csempében], ...].
func setup(camp: Node2D, world: Rect2i, locations: Array[Dictionary], pages: Array) -> void:
	_camp = camp
	_player = camp.get_node("Entities/Player")
	_world = world
	_locations = locations
	_pages = pages
	_capture()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	# Jobb alsó sarok.
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -SMALL_SIZE.x - 16
	offset_right = -16
	offset_top = -SMALL_SIZE.y - 60
	offset_bottom = -60
	_small_offsets = [offset_left, offset_top, offset_right, offset_bottom]
	_title = UiStyle.title_bar("Térkép")
	_title_label = _title.find_children("*", "Label", true, false)[0] if not _title.find_children("*", "Label", true, false).is_empty() else null
	_title.visible = false
	add_child(_title)
	_prev = _page_button("◄", -1)
	_next = _page_button("►", 1)
	_tip = PanelContainer.new()
	_tip.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	_tip.visible = false
	_tip.z_index = 5
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.custom_minimum_size.x = 320
	_tip.add_child(box)
	_tip_name = UiStyle.label("", 18, INK)
	_tip_does = UiStyle.label("", 15, Color(0.24, 0.45, 0.18))
	_tip_does.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_text = UiStyle.label("", 14, UiStyle.INK_LIGHT)
	_tip_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for label in [_tip_name, _tip_does, _tip_text]:
		label.custom_minimum_size.x = 320
		box.add_child(label)
	add_child(_tip)


func _page_button(text: String, step: int) -> Button:
	var button := MenuStyle.button(text)
	button.custom_minimum_size = Vector2(56, 44)
	button.focus_mode = Control.FOCUS_NONE
	button.visible = false
	button.pressed.connect(_flip.bind(step))
	add_child(button)
	return button


# ---------------------------------------------------------------- a fénykép

## A külső világ egyszeri lefényképezése (az esti színezés, a játékos és a titkos sír nélkül).
func _capture() -> void:
	var viewport := SubViewport.new()
	viewport.world_2d = _camp.get_viewport().world_2d
	viewport.size = Vector2i(Vector2(_world.size * TILE) * SCALE)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	var camera := Camera2D.new()
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	camera.zoom = Vector2(SCALE, SCALE)
	camera.position = Vector2(_world.position * TILE)
	viewport.add_child(camera)
	add_child(viewport)
	var hidden: Array[CanvasItem] = []
	for path in ["CanvasModulate", "Entities/Player", "HiddenGrave", "NetAvatars"]:
		var node := _camp.get_node_or_null(path)
		if node is CanvasItem and (node as CanvasItem).visible:
			(node as CanvasItem).visible = false
			hidden.append(node)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	for item in hidden:
		if is_instance_valid(item):
			item.visible = true
	viewport.queue_free()
	_cover_secret(image)
	_map = ImageTexture.create_from_image(image)
	queue_redraw()


## A titkos ösvényt és tisztást (HiddenGrave) a tőle balra lévő, ugyanakkora erdősávval takarja le.
func _cover_secret(image: Image) -> void:
	# A világ tetejétől a tábor felső széléig, a tisztás szélességében; a jobbra mellette lévő sűrű erdőből másolva.
	var secret := Rect2i(HiddenGrave.GLADE.position.x - 1, _world.position.y,
		HiddenGrave.GLADE.size.x + 2, -_world.position.y)
	var shift := secret.size.x + 1
	var source := Rect2i(_to_image(Vector2(secret.position + Vector2i(shift, 0)) * TILE), Vector2i(Vector2(secret.size * TILE) * SCALE))
	var target := _to_image(Vector2(secret.position) * TILE)
	source = source.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	if source.size.x > 0 and source.size.y > 0:
		image.blit_rect(image, source, target)


## Világ-képpont -> fénykép-képpont.
func _to_image(world_pos: Vector2) -> Vector2i:
	return Vector2i((world_pos - Vector2(_world.position * TILE)) * SCALE)


func _to_map(world_pos: Vector2) -> Vector2:
	return (world_pos - Vector2(_world.position * TILE)) * SCALE


# ---------------------------------------------------------------- megnyitás

func open() -> void:
	_set_expanded(true)


func close() -> void:
	_set_expanded(false)


func _set_expanded(expanded: bool) -> void:
	_expanded = expanded
	if expanded:
		anchor_left = 0.5
		anchor_right = 0.5
		anchor_top = 0.5
		anchor_bottom = 0.5
		offset_left = -BIG_SIZE.x / 2.0
		offset_right = BIG_SIZE.x / 2.0
		offset_top = -BIG_SIZE.y / 2.0
		offset_bottom = BIG_SIZE.y / 2.0
		# Az oldal, ahol éppen vagy (az egész vidék helyett a környéked).
		_page = _page_of_player()
	else:
		anchor_left = 1.0
		anchor_right = 1.0
		anchor_top = 1.0
		anchor_bottom = 1.0
		offset_left = _small_offsets[0]
		offset_top = _small_offsets[1]
		offset_right = _small_offsets[2]
		offset_bottom = _small_offsets[3]
	_title.visible = expanded
	_prev.visible = expanded
	_next.visible = expanded
	_tip.visible = false
	_update_title()
	queue_redraw()


func _page_of_player() -> int:
	if not is_instance_valid(_player):
		return 0
	var tile := Vector2i((_player.global_position / TILE).floor())
	for i in range(1, _pages.size()):
		if (_pages[i][1] as Rect2i).has_point(tile):
			return i
	return 0


func _flip(step: int) -> void:
	if _pages.is_empty():
		return
	_page = posmod(_page + step, _pages.size())
	Audio.play("ui_click")
	_update_title()
	queue_redraw()


func _update_title() -> void:
	if _pages.is_empty():
		return
	if _title_label != null:
		_title_label.text = "Térkép — %s  (%d / %d)" % [_pages[_page][0], _page + 1, _pages.size()]
	_title.reset_size()
	_title.position = Vector2((BIG_SIZE.x - _title.size.x) / 2.0, -_title.size.y / 2.0 + 4.0)
	_prev.position = Vector2(24, BIG_SIZE.y - 64)
	_next.position = Vector2(BIG_SIZE.x - 80, BIG_SIZE.y - 64)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not _expanded or key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_A, KEY_LEFT: _flip(-1)
		KEY_D, KEY_RIGHT: _flip(1)
		_: return
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	queue_redraw()
	if _expanded:
		_update_hover()


# ---------------------------------------------------------------- rajzolás

## A térkép területe a panelen belül.
func _area() -> Rect2:
	var style := _big_style if _expanded else _small_style
	var area := Rect2(Vector2.ZERO, size).grow_individual(-style.content_margin_left, -style.content_margin_top,
		-style.content_margin_right, -style.content_margin_bottom)
	if _expanded:
		area = area.grow_individual(-8, -26, -8, -64)
	return area


## A fénykép kivágása (fénykép-képpontban), amit a területre rajzolunk, és a területen belüli cél-téglalap.
func _view() -> Array:
	var area := _area()
	if not _expanded:
		var center := _to_map(_player.global_position) if is_instance_valid(_player) else Vector2.ZERO
		var width := SMALL_VIEW_TILES * TILE * SCALE
		var view := Vector2(width, width * area.size.y / area.size.x)
		var source := Rect2(center - view / 2.0, view)
		# A világ szélén nem lóg ki (a játékos jele ilyenkor nem középen van).
		var limit := Vector2(_map.get_size())
		source.position = source.position.clamp(Vector2.ZERO, (limit - view).max(Vector2.ZERO))
		return [source, area]
	var page: Rect2i = _pages[_page][1]
	var source := Rect2(_to_map(Vector2(page.position * TILE)), Vector2(page.size * TILE) * SCALE)
	source = source.intersection(Rect2(Vector2.ZERO, Vector2(_map.get_size())))
	# Az oldal arányát megtartva, középre igazítva.
	var fit := minf(area.size.x / source.size.x, area.size.y / source.size.y)
	var target_size := source.size * fit
	return [source, Rect2(area.position + (area.size - target_size) / 2.0, target_size)]


## Fénykép-képpont -> a panel képpontja.
func _map_to_panel(map_pos: Vector2, view: Array) -> Vector2:
	var source: Rect2 = view[0]
	var target: Rect2 = view[1]
	return target.position + (map_pos - source.position) * (target.size / source.size)


func _draw() -> void:
	draw_style_box(_big_style if _expanded else _small_style, Rect2(Vector2.ZERO, size))
	if _map == null:
		draw_string(_font, _area().get_center() - Vector2(40, 0), "Rajzolás...", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, INK)
		return
	var view := _view()
	var target: Rect2 = view[1]
	draw_texture_rect_region(_map, target, view[0])
	draw_rect(target, INK, false, 2.0)
	# Helyszínek.
	for i in _locations.size():
		var at := _map_to_panel(_to_map(_locations[i]["pos"]), view)
		if not target.grow(2).has_point(at):
			continue
		var radius := MARKER_RADIUS if _expanded else 4.0
		if i == _hover:
			radius += 3.0
		draw_circle(at, radius + 2.0, INK)
		draw_circle(at, radius, _locations[i]["color"])
		# A nevek csak a környék-oldalakon (az egész vidéken egymásra csúsznának; ott az egér hozza elő).
		if _expanded and _page > 0:
			var name: String = _locations[i]["name"]
			# "left": a név a jel bal oldalára kerül (ahol két jel közel van egymáshoz).
			var text_at := at + Vector2(radius + 4, 5)
			if _locations[i].get("left", false):
				text_at = at + Vector2(-radius - 4 - _font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x, 5)
			draw_string_outline(_font, text_at, name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color(1, 0.96, 0.85))
			draw_string(_font, text_at, name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, INK)
	# A játékos.
	if is_instance_valid(_player):
		var me := _map_to_panel(_to_map(_player.global_position), view)
		if target.has_point(me):
			var r := 6.0 if _expanded else 5.0
			draw_circle(me, r + 2.5, INK)
			draw_circle(me, r, PLAYER_COLOR)
			if _expanded:
				draw_string_outline(_font, me + Vector2(-10, -12), "Te", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, INK)
				draw_string(_font, me + Vector2(-10, -12), "Te", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, PLAYER_COLOR)
	if not _expanded:
		draw_string_outline(_font, Vector2(14, size.y - 10), "[M] nagy térkép", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4,
			Color(1, 0.96, 0.85))
		draw_string(_font, Vector2(14, size.y - 10), "[M] nagy térkép", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
	else:
		var hint := "◄ ► / A, D: lapozás   ·   egér a jelre: mit lehet ott csinálni   ·   [M] / [Esc] bezárás"
		draw_string(_font, Vector2(100, size.y - 34), hint, HORIZONTAL_ALIGNMENT_CENTER, size.x - 200, 14, UiStyle.INK_LIGHT)


## A nagy térképen: melyik jel fölött van az egér; a leírás mellette jelenik meg.
func _update_hover() -> void:
	if _map == null:
		return
	var mouse := get_local_mouse_position()
	var view := _view()
	var best := -1
	var best_distance := HOVER_RADIUS
	for i in _locations.size():
		var at := _map_to_panel(_to_map(_locations[i]["pos"]), view)
		var distance := at.distance_to(mouse)
		if distance < best_distance and (view[1] as Rect2).grow(2).has_point(at):
			best = i
			best_distance = distance
	if best == _hover:
		return
	_hover = best
	_tip.visible = best >= 0
	if best < 0:
		return
	var location: Dictionary = _locations[best]
	_tip_name.text = location["name"]
	_tip_does.text = "Itt: " + str(location["does"])
	_tip_text.text = location["text"]
	_tip.reset_size()
	var at := _map_to_panel(_to_map(location["pos"]), view)
	var place := at + Vector2(18, -_tip.size.y / 2.0)
	if place.x + _tip.size.x > size.x - 10:
		place.x = at.x - 18 - _tip.size.x
	place.y = clampf(place.y, 10, size.y - _tip.size.y - 10)
	_tip.position = place
