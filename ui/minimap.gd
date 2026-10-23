class_name Minimap
extends Control
## Pergamenre "tintával rajzolt" térkép. Kicsiben a jobb felső sarokban látszik,
## M-re nagy térképpé nyílik (ezt a Menus kezeli: open()/close()).
## A szobák színe az állapotukat mutatja; ahol még nem jártál, sraffozott.

const UNCLEARED_COLOR := Color(0.72, 0.2, 0.16)
const CLEARED_COLOR := Color(0.27, 0.52, 0.24)
const SHOP_COLOR := Color(0.88, 0.58, 0.12)
## A 10. emelet liftszobája.
const LIFT_COLOR := Color(0.25, 0.5, 0.9)
const BOSS_COLOR := Color(0.46, 0.16, 0.52)
## A főellenség-terem jele: koponya a 0x72 lapról.
const SKULL := Rect2(288, 432, 16, 16)
const CORRIDOR_COLOR := Color(0.38, 0.25, 0.14)
const OUTLINE_COLOR := Color(0.2, 0.12, 0.07)
const STAIRS_COLOR := Color(0.15, 0.09, 0.06)
## Ahol még nem jártál, azt sraffozás jelzi.
const HATCH_COLOR := Color(0.97, 0.9, 0.55, 0.65)
const HATCH_SPACING := 5.0
const EXPANDED_SIZE := Vector2(760, 520)
const LEGEND_HEIGHT := 36.0
const TITLE_SPACE := 40.0
## A játékos jele: a lovag első képkockája a sprite-lapon.
const PLAYER_ICON := Rect2(128, 104, 16, 22)

var _rooms: Array[Room] = []
var _player: Node2D
var _cell := Vector2i.ONE
var _anchors := {}
var _expanded := false
var _small_offsets: Array[float] = []
var _small_style := UiStyle.plain_panel()
var _big_style := UiStyle.decorated_panel()
var _title: PanelContainer


func setup(rooms: Array[Room], player: Node2D, cell: Vector2i) -> void:
	_rooms = rooms
	_player = player
	_cell = cell
	for room in rooms:
		_anchors[room.anchor] = room


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_small_offsets = [offset_left, offset_top, offset_right, offset_bottom]
	_title = UiStyle.title_bar("Térkép — %d. emelet" % GameState.depth)
	_title.visible = false
	add_child(_title)


func _process(_delta: float) -> void:
	queue_redraw()


func open() -> void:
	_set_expanded(true)


func close() -> void:
	_set_expanded(false)


func _set_expanded(expanded: bool) -> void:
	_expanded = expanded
	if expanded:
		# Képernyő közepére, nagyban.
		anchor_left = 0.5
		anchor_right = 0.5
		anchor_top = 0.5
		anchor_bottom = 0.5
		offset_left = -EXPANDED_SIZE.x / 2.0
		offset_right = EXPANDED_SIZE.x / 2.0
		offset_top = -EXPANDED_SIZE.y / 2.0
		offset_bottom = EXPANDED_SIZE.y / 2.0
	else:
		# Vissza a jobb felső sarokba.
		anchor_left = 1.0
		anchor_right = 1.0
		anchor_top = 0.0
		anchor_bottom = 0.0
		offset_left = _small_offsets[0]
		offset_top = _small_offsets[1]
		offset_right = _small_offsets[2]
		offset_bottom = _small_offsets[3]
	_title.visible = expanded
	if expanded:
		_title.reset_size()
		_title.position = Vector2((EXPANDED_SIZE.x - _title.size.x) / 2.0, -_title.size.y / 2.0 + 4.0)


func _draw() -> void:
	var style := _big_style if _expanded else _small_style
	draw_style_box(style, Rect2(Vector2.ZERO, size))
	if _rooms.is_empty():
		return

	var area := Rect2(Vector2.ZERO, size).grow_individual(
		-style.content_margin_left, -style.content_margin_top,
		-style.content_margin_right, -style.content_margin_bottom)
	if _expanded:
		area = area.grow_individual(0, -TITLE_SPACE + style.content_margin_top, 0, -LEGEND_HEIGHT)
	var bounds := Rect2(_rooms[0].rect)
	for room in _rooms:
		bounds = bounds.merge(Rect2(room.rect))
	var scale_factor := minf(area.size.x / bounds.size.x, area.size.y / bounds.size.y)
	var origin := area.position + (area.size - bounds.size * scale_factor) / 2.0 - bounds.position * scale_factor
	var to_map := func(tile_pos: Vector2) -> Vector2: return origin + tile_pos * scale_factor

	# Folyosók (a szobák középpontjai között), kettős tintavonallal.
	var corridor_width := maxf(3.0, scale_factor * 3.0)
	for room in _rooms:
		for dir in [Vector2i.RIGHT, Vector2i.DOWN]:
			var neighbor: Vector2i = room.anchor + dir * _cell
			if _anchors.has(neighbor):
				var from: Vector2 = to_map.call(Vector2(room.anchor) + Vector2(0.5, 0.5))
				var to: Vector2 = to_map.call(Vector2(neighbor) + Vector2(0.5, 0.5))
				draw_line(from, to, OUTLINE_COLOR, corridor_width + 2.0)
				draw_line(from, to, CORRIDOR_COLOR, corridor_width)

	# Szobák.
	var player_tile := _player.global_position / Room.TILE if is_instance_valid(_player) else Vector2.ZERO
	for room in _rooms:
		var map_rect := Rect2(to_map.call(Vector2(room.rect.position)), Vector2(room.rect.size) * scale_factor)
		draw_rect(map_rect, _room_color(room))
		if not room.visited:
			_draw_hatching(map_rect)
		draw_rect(map_rect, OUTLINE_COLOR, false, 2.0)
		if Rect2(room.rect).has_point(player_tile):
			draw_rect(map_rect.grow(3.0), OUTLINE_COLOR, false, 2.0)
		if room.has_stairs:
			_draw_stairs(to_map.call(Vector2(room.anchor) + Vector2(0.5, 0.5)), maxf(5.0, scale_factor * 1.8))
		if room.has_boss:
			var icon_size := Vector2.ONE * maxf(14.0, scale_factor * 4.0)
			var center: Vector2 = to_map.call(Vector2(room.anchor) + Vector2(0.5, 0.5))
			draw_texture_rect_region(SpriteSheet.TEXTURE, Rect2(center - icon_size / 2.0, icon_size), SKULL)

	# Játékos: a lovag kis képe. A boltban (ami a pályán kívül van) a bolt szobájánál látszik.
	if is_instance_valid(_player) and not bounds.grow(3.0).has_point(player_tile):
		for room in _rooms:
			if room.has_shop:
				player_tile = Vector2(room.anchor) + Vector2(0.5, 0.5)
	if is_instance_valid(_player):
		var icon_height := maxf(16.0, scale_factor * 4.0)
		var icon_size := Vector2(icon_height * PLAYER_ICON.size.x / PLAYER_ICON.size.y, icon_height)
		var at: Vector2 = to_map.call(player_tile) - Vector2(icon_size.x / 2.0, icon_size.y * 0.8)
		draw_texture_rect_region(SpriteSheet.TEXTURE, Rect2(at, icon_size), PLAYER_ICON)

	if _expanded:
		_draw_legend(Rect2(area.position.x, area.end.y, area.size.x, LEGEND_HEIGHT))


func _room_color(room: Room) -> Color:
	if room.has_shop:
		return SHOP_COLOR
	if room.has_lift_room:
		return LIFT_COLOR
	if room.has_boss and not room.is_cleared():
		return BOSS_COLOR
	return CLEARED_COLOR if room.is_cleared() else UNCLEARED_COLOR


## "Ködös", még be nem járt szoba: vízszintes pergamenszínű sraffozás.
func _draw_hatching(rect: Rect2) -> void:
	var y := rect.position.y + HATCH_SPACING / 2.0
	while y < rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), HATCH_COLOR, 2.0)
		y += HATCH_SPACING


## Lépcső jele: lefelé mutató háromszög.
func _draw_stairs(center: Vector2, radius: float) -> void:
	var points := PackedVector2Array([
		center + Vector2(-radius, -radius * 0.7),
		center + Vector2(radius, -radius * 0.7),
		center + Vector2(0, radius * 0.9),
	])
	draw_colored_polygon(points, STAIRS_COLOR)
	draw_polyline(points + PackedVector2Array([points[0]]), Color(0.95, 0.85, 0.55), 1.5)


func _draw_legend(rect: Rect2) -> void:
	var font := get_theme_default_font()
	var font_size := 15
	var entries := [
		["Nincs kitakarítva", UNCLEARED_COLOR], ["Kitakarítva", CLEARED_COLOR],
		["Bolt", SHOP_COLOR], ["Lift", LIFT_COLOR], ["Főellenség", BOSS_COLOR], ["Lépcső", STAIRS_COLOR], ["Ismeretlen", UNCLEARED_COLOR],
	]
	var y := rect.position.y + rect.size.y / 2.0 + 4.0
	var x := rect.position.x + 4.0
	for entry in entries:
		var text: String = entry[0]
		var color: Color = entry[1]
		if text == "Lépcső":
			_draw_stairs(Vector2(x + 7, y - 4), 6.0)
		else:
			draw_rect(Rect2(x, y - 11, 14, 14), color)
			if text == "Ismeretlen":
				_draw_hatching(Rect2(x, y - 11, 14, 14))
			draw_rect(Rect2(x, y - 11, 14, 14), OUTLINE_COLOR, false, 1.5)
		draw_string(font, Vector2(x + 20, y + 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiStyle.INK)
		x += 20.0 + font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 20.0
