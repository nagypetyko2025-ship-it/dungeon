class_name MenuStyle
## A főmenü (és a halálképernyő gombjai) közös kinézete: díszkeretes gombok
## (Kenney "Fantasy UI Borders", CC0, aranyra színezve) és a betűtípusok
## (Jacquard 24 a címekhez, Pixelify Sans a gombokhoz; SIL OFL).

const TITLE_FONT: Font = preload("res://assets/fonts/Jacquard24-Regular.ttf")
const BUTTON_FONT: Font = preload("res://assets/fonts/PixelifySans.ttf")
const BUTTON_NORMAL: Texture2D = preload("res://assets/menu/button_normal.png")
const BUTTON_HOVER: Texture2D = preload("res://assets/menu/button_hover.png")
const BUTTON_PRESSED: Texture2D = preload("res://assets/menu/button_pressed.png")
const BUTTON_DISABLED: Texture2D = preload("res://assets/menu/button_disabled.png")
const MENU_PANEL: Texture2D = preload("res://assets/menu/menu_panel.png")

const GOLD := Color(1, 0.82, 0.42)
const GOLD_LIGHT := Color(1, 0.93, 0.7)
const PARCHMENT := Color(0.87, 0.74, 0.55)
const SHADOW := Color(0.08, 0.03, 0.02)
const BUTTON_SIZE := Vector2(340, 64)


static func button(text: String) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = BUTTON_SIZE
	result.add_theme_font_override("font", BUTTON_FONT)
	result.add_theme_font_size_override("font_size", 26)
	result.add_theme_color_override("font_color", PARCHMENT)
	result.add_theme_color_override("font_hover_color", GOLD_LIGHT)
	result.add_theme_color_override("font_focus_color", GOLD_LIGHT)
	result.add_theme_color_override("font_pressed_color", GOLD)
	result.add_theme_color_override("font_outline_color", SHADOW)
	result.add_theme_constant_override("outline_size", 6)
	result.add_theme_stylebox_override("normal", box(BUTTON_NORMAL))
	result.add_theme_stylebox_override("hover", box(BUTTON_HOVER))
	result.add_theme_stylebox_override("focus", box(BUTTON_HOVER))
	result.add_theme_stylebox_override("pressed", box(BUTTON_PRESSED))
	result.add_theme_stylebox_override("disabled", box(BUTTON_DISABLED))
	result.mouse_entered.connect(Audio.play.bind("ui_hover"))
	result.pressed.connect(Audio.play.bind("ui_click"))
	return result


static func box(texture: Texture2D, margin := 16, content := 12) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.set_texture_margin_all(margin)
	style.set_content_margin_all(content)
	return style


static func title_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", TITLE_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", SHADOW)
	label.add_theme_constant_override("outline_size", maxi(4, size / 10))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", maxi(3, size / 20))
	return label
