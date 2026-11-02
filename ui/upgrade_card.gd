class_name UpgradeCard
## Egy szintlépési kártya megjelenése (a szintlépés ablaka és a kártya-szerkesztő előnézete is ezt használja).
## Ritkaság szerinti szín (Items.RARITIES): színezett keret és cím, a legendás és a mítikus izzik.
## A nyereség zöld, a levonás piros sorban (Upgrades.lines); a varázslat- és idézés-kártyáknak saját szövege van.

const SIZE := Vector2(210, 250)
const PADDING := 18
const PANEL: Texture2D = preload("res://assets/ui/panel.png")
const PANEL_HOVER: Texture2D = preload("res://assets/ui/panel_hover.png")
const TITLE_COLOR := Color(1, 0.88, 0.55)
const GAIN_COLOR := Color(0.55, 1.0, 0.6)
const COST_COLOR := Color(1.0, 0.45, 0.4)


## `index` < 0: nincs [1]-[4] szám (előnézet).
static func build(index: int, card: Dictionary) -> Button:
	var button := Button.new()
	button.custom_minimum_size = SIZE
	button.focus_mode = Control.FOCUS_NONE
	var rarity: String = card.get("rarity", "")
	var tint := Color.WHITE if rarity in ["", "common"] else Color.WHITE.lerp(Upgrades.rarity_color(card), 0.5)
	button.add_theme_stylebox_override("normal", panel_style(PANEL, tint))
	button.add_theme_stylebox_override("hover", panel_style(PANEL_HOVER, tint))
	button.add_theme_stylebox_override("pressed", panel_style(PANEL_HOVER, tint))

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, PADDING)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)

	var head := "[%d]" % (index + 1) if index >= 0 else ""
	if not rarity.is_empty():
		head = (head + "  " if not head.is_empty() else "") + Upgrades.rarity_name(card)
	if not head.is_empty():
		box.add_child(label(head, 14, Upgrades.rarity_color(card) if not rarity.is_empty() else Color(0.75, 0.68, 0.6)))
	var icon := TextureRect.new()
	icon.texture = Upgrades.icon(card)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(68, 68)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	# A varázslat- és idézés-kártyák szövege hosszabb: kisebb ikon és betű, hogy beférjen a kártyába.
	var spell := card.has("spell") or card.has("necromancy")
	if spell:
		icon.custom_minimum_size = Vector2(52, 52)
		box.add_theme_constant_override("separation", 6)
	var title_color := Upgrades.rarity_color(card) if rarity not in ["", "common"] else TITLE_COLOR
	var texts: Array[Label] = [label(card["title"], 20 if spell else 22, title_color)]
	if card.has("gain"):
		for line: Array in Upgrades.lines(card):
			texts.append(label(line[0], 16, GAIN_COLOR if line[1] else COST_COLOR))
	else:
		texts.append(label(card.get("text", ""), 14 if spell else 16, Color(0.9, 0.86, 0.8)))
	if card.has("note"):
		texts.append(label(card["note"], 13, Color(0.6, 0.85, 1.0)))
	# Korlátozott kártya: szintlépéskor hányszor vetted már ki ebben a futásban a korlátból (pl. "Kivéve: 2 / 5"),
	# a szerkesztő előnézetében (index < 0) csak a korlát.
	if card.has("gain") and int(card.get("max_picks", 0)) > 0:
		var limit := "Legfeljebb %d× futásonként" % int(card["max_picks"])
		if index >= 0:
			limit = "Kivéve: %d / %d" % [Upgrades.picks_taken(card), int(card["max_picks"])]
		texts.append(label(limit, 14, Color(0.85, 0.75, 0.55)))
	# Karakter-bónusz (pl. Gáspár kikerülése): külön, zöldes sorban.
	if card.has("bonus_note"):
		texts.append(label(card["bonus_note"], 14, Color(0.55, 1.0, 0.6)))
	# A tördelt sorok szélessége rögzítve: enélkül a Label nagyon keskenynek és nagyon magasnak számolja magát,
	# és az egész kártyasort a képernyő aljáig nyújtja.
	for text in texts:
		text.custom_minimum_size.x = SIZE.x - 36
		box.add_child(text)
	if rarity in ["legendary", "mythic"]:
		_glow(button, icon, Upgrades.rarity_color(card), rarity == "mythic")
	return button


## Legendás és mítikus kártya: izzó keret a ritkaság színében, lüktető fény, szikrák.
static func _glow(button: Button, icon: TextureRect, color: Color, mythic: bool) -> void:
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		var back := Color(0.24, 0.04, 0.04) if mythic else Color(0.22, 0.1, 0.03)
		style.bg_color = back if state == "normal" else back.lightened(0.12)
		style.border_color = color if state == "normal" else color.lightened(0.3)
		style.set_border_width_all(5)
		style.set_corner_radius_all(6)
		style.shadow_color = Color(color, 0.55)
		style.shadow_size = 18 if mythic else 14
		style.set_content_margin_all(16)
		button.add_theme_stylebox_override(state, style)
	icon.custom_minimum_size = Vector2(80, 80)
	var glow := button.create_tween().set_loops()
	glow.tween_property(button, "self_modulate", Color(1.35, 1.15, 0.85), 0.6).set_trans(Tween.TRANS_SINE)
	glow.tween_property(button, "self_modulate", Color.WHITE, 0.6).set_trans(Tween.TRANS_SINE)
	var sparks := CPUParticles2D.new()
	sparks.amount = 32 if mythic else 24
	sparks.lifetime = 1.4
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparks.emission_rect_extents = SIZE / 2.0
	sparks.position = SIZE / 2.0
	sparks.direction = Vector2(0, -1)
	sparks.spread = 30.0
	sparks.gravity = Vector2(0, -25)
	sparks.initial_velocity_min = 10.0
	sparks.initial_velocity_max = 30.0
	sparks.scale_amount_min = 2.0
	sparks.scale_amount_max = 3.5
	sparks.color = color.lightened(0.3)
	button.add_child(sparks)


static func label(text: String, size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = text
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.add_theme_color_override("font_outline_color", Color.BLACK)
	result.add_theme_constant_override("outline_size", 4)
	return result


static func panel_style(texture: Texture2D, tint := Color.WHITE) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.modulate_color = tint
	style.set_texture_margin_all(12)
	style.set_content_margin_all(16)
	return style
