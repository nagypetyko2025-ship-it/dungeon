class_name ShopTooltip
extends CanvasLayer
## Pergamen leírás a képernyő jobb oldalán, amikor a játékos egy áru előtt áll:
## név (ritkaság színével), ritkaság, statok, ár és hogy meg tudja-e venni.

const WIDTH := 300.0

var _panel: PanelContainer
var _title: Label
var _text: RichTextLabel
var _price: Label
var _hint: Label


func _ready() -> void:
	layer = 5
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_panel.custom_minimum_size = Vector2(WIDTH, 0)
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -WIDTH - 24
	_panel.offset_right = -24
	_panel.offset_top = -40
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_panel.add_child(box)
	_title = UiStyle.label("", 19, UiStyle.INK)
	box.add_child(_title)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.add_theme_color_override("default_color", UiStyle.INK_LIGHT)
	_text.add_theme_font_size_override("normal_font_size", 15)
	box.add_child(_text)
	_price = UiStyle.label("", 17, Color(0.55, 0.38, 0.05))
	box.add_child(_price)
	_hint = UiStyle.label("", 15, UiStyle.INK)
	box.add_child(_hint)
	visible = false


func show_item(item: Dictionary, hint: String, can_buy: bool) -> void:
	_title.text = item["name"]
	_title.add_theme_color_override("font_color", Items.rarity_ink(item))
	_text.text = Items.describe_bbcode(item)
	_price.text = "Ár: %d arany" % item["price"]
	_hint.text = hint
	_hint.add_theme_color_override("font_color", Color(0.2, 0.42, 0.15) if can_buy else Color(0.62, 0.18, 0.14))
	visible = true


func hide_tooltip() -> void:
	visible = false
