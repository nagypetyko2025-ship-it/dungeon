class_name UiStyle
## Közös UI-elemek a "Parchment GUI" (zwonky, CC0) képeiből: pergamen és fém
## panelek, címkecsíkok, inventory slotok, valamint a tinta-színek.

const PANEL_DECORATED: Texture2D = preload("res://assets/ui/parchment/panel_decorated.png")
const PANEL_PLAIN: Texture2D = preload("res://assets/ui/parchment/panel_plain.png")
const PANEL_METAL: Texture2D = preload("res://assets/ui/parchment/panel_metal.png")
const LABEL_EMERALD: Texture2D = preload("res://assets/ui/parchment/label_emerald.png")
const SLOT: Texture2D = preload("res://assets/ui/parchment/slot.png")
const SLOT_HOVER: Texture2D = preload("res://assets/ui/parchment/slot_hover.png")

## Sötétbarna tinta a pergamenen.
const INK := Color(0.24, 0.14, 0.08)
const INK_LIGHT := Color(0.42, 0.28, 0.16)
## Világos szöveg sötét háttéren (fém panel, címkecsík).
const TEXT_LIGHT := Color(1, 0.92, 0.7)
const TEXT_GOLD := Color(1, 0.82, 0.35)


static func decorated_panel() -> StyleBoxTexture:
	return _box(PANEL_DECORATED, 32, 40)


static func plain_panel() -> StyleBoxTexture:
	return _box(PANEL_PLAIN, 12, 14)


static func metal_panel() -> StyleBoxTexture:
	return _box(PANEL_METAL, 20, 26)


static func slot(hover := false) -> StyleBoxTexture:
	return _box(SLOT_HOVER if hover else SLOT, 16, 8)


## Díszes címkecsík (smaragdos végekkel) egy címhez.
static func title_bar(text: String, font_size := 22) -> PanelContainer:
	var bar := PanelContainer.new()
	var style := StyleBoxTexture.new()
	style.texture = LABEL_EMERALD
	style.texture_margin_left = 28
	style.texture_margin_right = 28
	style.texture_margin_top = 10
	style.texture_margin_bottom = 10
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 4
	style.content_margin_bottom = 6
	bar.add_theme_stylebox_override("panel", style)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.add_child(label(text, font_size, TEXT_GOLD, true))
	return bar


static func label(text: String, font_size: int, color: Color, outline := false) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	if outline:
		result.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
		result.add_theme_constant_override("outline_size", 5)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


static func _box(texture: Texture2D, texture_margin: int, content_margin: int) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.set_texture_margin_all(texture_margin)
	style.set_content_margin_all(content_margin)
	return style
