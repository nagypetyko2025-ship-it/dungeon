class_name QuestTracker
extends CanvasLayer
## Küldetés-kijelző a jobb oldalon (a kazamatában a térkép alatt, a táborban a tábori
## kincs alatt): a teljesítéshez legközelebb álló küldetés haladása, vagy ha van kész,
## az átvehető jutalmak; amikor egy küldetés kész lesz, zölden villog.

const SCROLL: Texture2D = preload("res://assets/ui/quest_scroll.png")

## A képernyő tetejétől ennyire van (a kazamatában a térkép alá kerül).
var top_offset := 420.0

var _box: PanelContainer
var _label: Label
var _last := "-"


func _ready() -> void:
	layer = 4
	if get_parent().name != "Dungeon":
		top_offset = 90.0
	_box = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.05, 0.04, 0.72)
	style.border_color = Color(0.6, 0.45, 0.25, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	_box.add_theme_stylebox_override("panel", style)
	_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_box.offset_right = -28
	_box.offset_left = -400
	_box.offset_top = top_offset
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_box.add_child(row)
	var icon := TextureRect.new()
	icon.texture = SCROLL
	icon.custom_minimum_size = Vector2(30, 30)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 17)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size.x = 320
	_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_label)
	_update()


func _process(_delta: float) -> void:
	_update()


func _update() -> void:
	var text := "" if GameState.tutorial else Quests.tracker_text()
	if text == _last:
		return
	var first := _last == "-"
	_last = text
	_box.visible = not text.is_empty()
	_label.text = text
	var complete := not Quests.ready_ids().is_empty()
	_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55) if complete else MenuStyle.PARCHMENT)
	# Épp most lett kész (nem a jelenet betöltésekor): villogás (hang nélkül).
	if complete and not first:
		var flash := _box.create_tween()
		for i in 3:
			flash.tween_property(_box, "modulate", Color(1.5, 1.8, 1.4), 0.2)
			flash.tween_property(_box, "modulate", Color.WHITE, 0.2)
