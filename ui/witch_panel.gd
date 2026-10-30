extends "res://ui/camp_upgrades.gd"
## Holló Margit test-manipulálása (a boszorkánykunyhóban, a beszélgetés "Test manipulálása" opciójából):
## ugyanazok a statok, mint a kiképzősátorban, de szintenként 1,5× annyit adnak, és bármeddig fejleszthetők.
## Ár: tábori arany + por (Progress.witch_cost: 1-2. szint átlagos, 3-4. ritka, 5-6. epikus, 7. legendás por,
## a 8.-tól 1000 arany és 3 legendás por). A kártya, a fejléc és a vásárlás itt; a többi a kiképzősátoré.

## Boszorkányos nevek a kiképzősátor fejlesztéseihez (ugyanaz a stat, más módszer).
const NAMES := {
	"strength": "Bikavér-főzet", "weapon_mastery": "Acélín-kenőcs", "archery": "Sólyomszem-csepp",
	"vitality": "Vasgyökér-tea", "herbalism": "Életfű-borogatás", "shield_training": "Kéregbőr",
	"acrobatics": "Macskacsont-főzet", "running": "Nyúlláb-ital", "fencing": "Darázsméreg",
	"precision": "Bagolyszem", "long_arms": "Nyújtott inak", "arcana": "Lidércláng", "aiming": "Hollószem",
	"volley": "Pókujjak", "bloodletting": "Vámpírfog-lőre", "spiked_armor": "Tövisbőr",
	"treasure_hunting": "Szarkafészek", "lore": "Öregek álma",
}

var _dust_labels := {}


func _title() -> String:
	return "Test manipulálása — Holló Margit"


func _header_text() -> String:
	return "   ·   1,5× a kiképzősátornál, bármeddig."


## A fejlécben a porok is (amiből a boszorkány dolgozik).
func _header_extra(row: HBoxContainer) -> void:
	for rarity: String in ["common", "rare", "epic", "legendary"]:
		row.add_child(UiStyle.label("  ", 14, UiStyle.INK))
		row.add_child(_dust_icon(rarity, 22))
		var label := UiStyle.label("0", 18, Items.RARITIES[rarity]["ink"])
		label.tooltip_text = "%s por" % Items.RARITIES[rarity]["name"]
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(label)
		_dust_labels[rarity] = label


func _refresh() -> void:
	super._refresh()
	for rarity: String in _dust_labels:
		(_dust_labels[rarity] as Label).text = str(Progress.dust_of(rarity))


## Egy fejlesztés kártyája: ikon, név, szintenként mit ad, a szint és az összes, ár (arany + por) gomb.
func _make_row(id: String) -> PanelContainer:
	var definition: Dictionary = Progress.UPGRADES[id]
	var stat: String = definition["stat"]
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	panel.custom_minimum_size = Vector2(284, 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var icon := TextureRect.new()
	icon.texture = load(definition["icon_path"]) if definition.has("icon_path") else _icon_for(stat)
	icon.custom_minimum_size = Vector2(36, 36)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var level := Progress.witch_level(id)
	info.add_child(_fitted(UiStyle.label(NAMES.get(id, definition["name"]), 15, UiStyle.INK)))
	var step := Progress.witch_bonus(id, level + 1) - Progress.witch_bonus(id, level)
	info.add_child(_fitted(UiStyle.label(_precise(stat, step) + " / szint", 12, UiStyle.INK_LIGHT)))
	var total := "%d. szint" % level
	if level > 0:
		total += " = %s" % _precise(stat, Progress.witch_bonus(id, level)).get_slice(" ", 0)
	info.add_child(_fitted(UiStyle.label(total, 12, Color(0.24, 0.5, 0.2) if level > 0 else UiStyle.INK_LIGHT)))

	var cost := Progress.witch_cost(id)
	var gold := int(cost[0])
	var rarity := str(cost[1])
	var amount := int(cost[2])
	var button := MenuStyle.button("%d\n%d×" % [gold, amount])
	button.icon = Smithing.DUST_ICONS[rarity]
	button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	button.expand_icon = false
	button.add_theme_constant_override("icon_max_width", 18)
	button.tooltip_text = "%d tábori arany + %d %s por" % [gold, amount, str(Items.RARITIES[rarity]["name"]).to_lower()]
	button.custom_minimum_size = Vector2(76, 44)
	button.add_theme_font_size_override("font_size", 12)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.disabled = Progress.camp_gold < gold or Progress.dust_of(rarity) < amount
	button.pressed.connect(_buy.bind(id))
	row.add_child(button)
	return panel


## Mint a _stat_text, de a szám nincs egészre kerekítve (1,5× miatt gyakran fél érték: +4.5% sebzés).
func _precise(stat: String, value: float) -> String:
	var text := _stat_text(stat, value)
	if stat == "health_regen" or is_equal_approx(value, roundf(value)):
		return text
	var first := text.get_slice(" ", 0)
	var number := "%s%s" % ["+" if value >= 0 else "", str(snappedf(value, 0.1))]
	if first.ends_with("%"):
		number += "%"
	return number + text.substr(first.length())


func _dust_icon(rarity: String, size: float) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = Smithing.DUST_ICONS[rarity]
	icon.custom_minimum_size = Vector2(size, size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return icon


func _buy(id: String) -> void:
	var cost := Progress.witch_cost(id)
	if Progress.witch_buy(id):
		Audio.play("level_up")
		_message.text = "%s: %d. szint kész! A boszorkány elégedetten szuszog." % [NAMES.get(id, id), Progress.witch_level(id)]
		_message.add_theme_color_override("font_color", Color(0.24, 0.5, 0.2))
		var player := get_tree().get_first_node_in_group("player")
		if player:
			player.get_node("Inventory").changed.emit()
	else:
		Audio.play("ui_error")
		var rarity := str(cost[1])
		_message.text = "Nincs elég tábori arany." if Progress.camp_gold < int(cost[0]) \
			else "Nincs elég %s por." % str(Items.RARITIES[rarity]["name"]).to_lower()
		_message.add_theme_color_override("font_color", Color(0.6, 0.2, 0.12))
	_refresh()
	if get_tree().current_scene.has_method("_update_gold"):
		get_tree().current_scene.call("_update_gold")
