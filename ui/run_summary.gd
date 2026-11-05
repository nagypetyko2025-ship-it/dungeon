class_name RunSummary
## Futás végi összesítő: a halálképernyőn (ui/death_screen.gd) és a győzelem után (ui/victory_panel.gd)
## megmutatja, melyik szörnyből ölted a legtöbbet, ki ölt meg, milyen kártyákat vettél fel (ritkaság szerint
## színezve) és milyen felszerelés volt rajtad. Az adatok: GameState.kill_counts, GameState.killer (a játékos
## _on_hurt-je jegyzi fel, ki talált el utoljára), GameState.card_picks és a játékos Inventory-ja.

const WIDTH := 520
const TOP_KILLS := 3
const RARITY_ORDER: Array[String] = ["mythic", "legendary", "epic", "rare", "common"]
const CARD_ICON := Vector2(26, 26)
const ITEM_ICON := Vector2(34, 34)
const MONSTER_ICON := Vector2(36, 36)
const HEADER_COLOR := Color(1, 0.85, 0.5)
const TEXT_COLOR := Color(0.9, 0.84, 0.76)
const KILLER_COLOR := Color(1, 0.45, 0.4)


## A szörny azonosítója a Szörnyek könyvéhez: főellenségnél a neve, egyébként a típus neve; "" ha nem szörny.
## Lövedéknél / fegyvernél felfelé keres a szülők közt.
static func monster_key(node: Variant) -> String:
	var current: Node = node as Node if is_instance_valid(node) else null
	for step in 6:
		if current == null:
			return ""
		if current.is_in_group("boss") and not str(current.get("boss_name")).is_empty():
			return str(current.get("boss_name"))
		if current.is_in_group("enemies"):
			var type: Variant = current.get("_type")
			return str(type["name"]) if type is Dictionary else ""
		current = current.get_parent()
	return ""


## A szörny megjelenített neve (a Szörnyek könyvéből; a főellenségek kulcsa már a nevük).
static func monster_name(monster: String) -> String:
	var entry: Variant = Bestiary.ENTRIES.get(monster)
	return str(entry[0]) if entry is Array else monster


## Az alap statisztikák egy sorban (a győzelmi összesítőhöz).
static func stats_text(player: Node) -> String:
	var experience: Experience = player.get_node("Experience")
	var seconds := int(GameState.run_time)
	return "Elért emelet: %d   ·   Karakterszint: %d   ·   Megölt ellenségek: %d   ·   Játékidő: %d:%02d" % [
		GameState.depth, experience.level, GameState.kills, seconds / 60, seconds % 60]


## Az összesítő panel. `show_killer`: halálkor a gyilkos is megjelenik.
static func build(player: Node, show_killer: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.07, 0.08, 0.92)
	style.border_color = Color(0.72, 0.56, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size.x = WIDTH
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	if show_killer and not GameState.killer.is_empty():
		box.add_child(_header("Végzetes ellenfél"))
		box.add_child(_monster_row(GameState.killer, "", KILLER_COLOR))

	var kills := GameState.kill_counts.keys()
	kills.sort_custom(func(a: String, b: String) -> bool:
		return int(GameState.kill_counts[a]) > int(GameState.kill_counts[b]))
	box.add_child(_header("Legtöbbször legyőzött"))
	if kills.is_empty():
		box.add_child(UiStyle.label("Senkit nem győztél le.", 14, TEXT_COLOR))
	for monster: String in kills.slice(0, TOP_KILLS):
		box.add_child(_monster_row(monster, "×%d" % int(GameState.kill_counts[monster]), TEXT_COLOR))

	var cards := _taken_cards()
	var total := 0
	for entry: Array in cards:
		total += int(entry[1])
	box.add_child(_header("Felvett kártyák (%d)" % total))
	if cards.is_empty():
		box.add_child(UiStyle.label("Egy kártyát sem vettél fel.", 14, TEXT_COLOR))
	else:
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 4)
		flow.add_theme_constant_override("v_separation", 4)
		box.add_child(flow)
		for entry: Array in cards:
			flow.add_child(_card_chip(entry[0], int(entry[1])))

	box.add_child(_header("Felszerelés a végén"))
	var gear := HBoxContainer.new()
	gear.add_theme_constant_override("separation", 4)
	box.add_child(gear)
	var inventory := player.get_node_or_null("Inventory") as Inventory
	if inventory != null:
		for slot in Inventory.EQUIPMENT_SLOTS:
			var item: Variant = inventory.equipment.get(slot)
			if item is Dictionary:
				gear.add_child(_item_chip(item))
	if gear.get_child_count() == 0:
		gear.add_child(UiStyle.label("Semmi.", 14, TEXT_COLOR))
	return panel


## Győzelem után: teljes képernyős összesítő egy "Tovább" gombbal. Visszaadja [réteg, gomb]; a hívó a gomb
## `pressed` jelére vár, utána törli a réteget.
static func overlay(player: Node, title: String, rank: int) -> Array:
	var layer := CanvasLayer.new()
	layer.layer = 25
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.05, 0.9)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	center.add_child(box)
	var heading := UiStyle.label(title, 40, Color(1, 0.82, 0.35), true)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	var stats := UiStyle.label(stats_text(player), 16, TEXT_COLOR, true)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(stats)
	if rank > 0:
		var record := UiStyle.label("★ Új eredmény: %d. hely! ★" % rank, 20, Color(1, 0.9, 0.4), true)
		record.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(record)
	var panel := build(player, false)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(panel)
	var button := MenuStyle.button("Tovább")
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(button)
	button.ready.connect(button.grab_focus)
	return [layer, button]


## A futásban felvett kártyák [kártya, hányszor], ritkaság szerint (a legritkábbtól), azon belül a többször
## felvettek elöl.
static func _taken_cards() -> Array:
	var by_id := {}
	for card: Dictionary in Upgrades.cards():
		by_id[card.get("id", "")] = card
	var result := []
	for id: String in GameState.card_picks:
		if by_id.has(id):
			result.append([by_id[id], int(GameState.card_picks[id])])
	result.sort_custom(func(a: Array, b: Array) -> bool:
		var ra := RARITY_ORDER.find(str(a[0].get("rarity", "common")))
		var rb := RARITY_ORDER.find(str(b[0].get("rarity", "common")))
		return ra < rb if ra != rb else int(a[1]) > int(b[1]))
	return result


static func _header(text: String) -> Label:
	return UiStyle.label(text, 15, HEADER_COLOR, true)


static func _monster_row(monster: String, count: String, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var picture: Array = Bestiary.icon(monster)
	var icon := TextureRect.new()
	icon.texture = picture[0]
	icon.modulate = picture[1]
	icon.custom_minimum_size = MONSTER_ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var name := UiStyle.label(monster_name(monster), 16, color, true)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name)
	if not count.is_empty():
		var amount := UiStyle.label(count, 16, color, true)
		amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(amount)
	return row


## Keretes kis doboz: a keret a ritkaság színe.
static func _chip(color: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.07, 0.85)
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(2)
	chip.add_theme_stylebox_override("panel", style)
	return chip


static func _card_chip(card: Dictionary, count: int) -> PanelContainer:
	var chip := _chip(Upgrades.rarity_color(card))
	chip.tooltip_text = "%s (%s)" % [card.get("title", ""), Upgrades.rarity_name(card)]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(row)
	var icon := TextureRect.new()
	icon.texture = Upgrades.icon(card)
	icon.custom_minimum_size = CARD_ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	if count > 1:
		var amount := UiStyle.label("×%d" % count, 13, Upgrades.rarity_color(card), true)
		amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(amount)
	return chip


static func _item_chip(item: Dictionary) -> PanelContainer:
	var chip := _chip(Items.rarity_color(item))
	chip.tooltip_text = str(item.get("name", ""))
	var icon := TextureRect.new()
	icon.texture = Items.icon(item)
	icon.custom_minimum_size = ITEM_ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(icon)
	return chip
