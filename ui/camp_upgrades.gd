extends CanvasLayer
## Kiképzősátor (a táborban, E-vel): itt lehet a táborba felküldött aranyból
## minden futásra érvényes fejlesztéseket venni (lásd Progress.UPGRADES).
## Megnyitását/bezárását a Menus kezeli (open()/close()); közben áll a játék.

const PIP_SIZE := Vector2(22, 22)
const PIP_ON := Color(0.85, 0.55, 0.15)
const PIP_OFF := Color(0.42, 0.28, 0.16, 0.35)

var _gold_label: Label
var _rows: GridContainer
var _message: Label


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func open() -> void:
	_message.text = ""
	_refresh()
	visible = true


func close() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		get_tree().current_scene.get_node("Menus").call("close_current")


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.03, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(center)
	var window := PanelContainer.new()
	window.add_theme_stylebox_override("panel", UiStyle.decorated_panel())
	window.custom_minimum_size = Vector2(1180, 0)
	center.add_child(window)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	window.add_child(root)
	root.add_child(UiStyle.title_bar("Kiképzősátor"))
	# Egy sorban: a tábori kincs, és hogy mit mutat a kártya (szintenkénti érték, a következő szint ára).
	var gold_row := HBoxContainer.new()
	gold_row.add_theme_constant_override("separation", 8)
	root.add_child(gold_row)
	gold_row.add_child(UiStyle.label("Tábori kincs:", 18, UiStyle.INK))
	var coin := TextureRect.new()
	coin.texture = SpriteSheet.region(Rect2(289, 385, 6, 7))
	coin.custom_minimum_size = Vector2(18, 21)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gold_row.add_child(coin)
	_gold_label = UiStyle.label("0", 20, Color(0.6, 0.38, 0.05))
	gold_row.add_child(_gold_label)
	gold_row.add_child(UiStyle.label("   ·   Minden futásra érvényes. A kártyán: amit szintenként ad, és a következő szint ára (arany).",
		14, UiStyle.INK_LIGHT))
	_rows = GridContainer.new()
	_rows.columns = 4
	_rows.add_theme_constant_override("h_separation", 10)
	_rows.add_theme_constant_override("v_separation", 8)
	root.add_child(_rows)
	_message = UiStyle.label("", 15, Color(0.6, 0.2, 0.12))
	root.add_child(_message)
	var hint := UiStyle.label("[E] / [Esc] bezárás", 14, UiStyle.INK_LIGHT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(hint)


func _refresh() -> void:
	_gold_label.text = str(Progress.camp_gold)
	for child in _rows.get_children():
		child.queue_free()
	for id: String in Progress.UPGRADES:
		_rows.add_child(_make_row(id))


## Egy fejlesztés kártyája: ikon, név és szint, mit ad, szint-pöttyök, ár / gomb.
func _make_row(id: String) -> PanelContainer:
	var definition: Dictionary = Progress.UPGRADES[id]
	var stat: String = definition["stat"]
	var per_level: float = definition["per_level"]
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.plain_panel())
	panel.custom_minimum_size = Vector2(284, 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
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
	var level := Progress.level(id)
	var max_level := Progress.max_level(id)
	info.add_child(_fitted(UiStyle.label(definition["name"], 15, UiStyle.INK)))
	info.add_child(_fitted(UiStyle.label(_stat_text(stat, per_level) + " / szint", 12, UiStyle.INK_LIGHT)))
	var pips := HBoxContainer.new()
	pips.add_theme_constant_override("separation", 4)
	for i in max_level:
		var pip := ColorRect.new()
		pip.custom_minimum_size = PIP_SIZE * 0.65
		pip.color = PIP_ON if i < level else PIP_OFF
		pips.add_child(pip)
	if level > 0:
		# Az összesen kapott érték (csak a szám: a stat neve a kártyán fölötte van).
		pips.add_child(_fitted(UiStyle.label(" = %s" % _stat_text(stat, per_level * level).get_slice(" ", 0), 12, Color(0.24, 0.5, 0.2))))
	info.add_child(pips)

	var cost := Progress.next_cost(id)
	var button := MenuStyle.button("Max" if cost < 0 else str(cost))
	button.tooltip_text = "" if cost < 0 else "%d tábori arany" % cost
	button.custom_minimum_size = Vector2(62, 38)
	button.add_theme_font_size_override("font_size", 14)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.disabled = cost < 0 or Progress.camp_gold < cost
	button.pressed.connect(_buy.bind(id))
	row.add_child(button)
	return panel


## A stat ikonja a szintlépés-kártyák közül (ugyanaz a jel mindenhol).
func _icon_for(stat: String) -> Texture2D:
	for upgrade in Upgrades.ALL:
		if upgrade["stat"] == stat:
			return Upgrades.icon(upgrade)
	return null


## Rövid felirat a kártyára (a tárgyleírások hosszabb szövegei nem férnének ki).
const SHORT_LABELS := {"multishot": "nyíl", "lifesteal": "életlopás", "thorns": "tüskesebzés",
	"gold_find": "több arany", "xp_bonus": "több tapasztalat"}


func _stat_text(stat: String, value: float) -> String:
	if stat == "health_regen":
		return "+%s élet / mp" % str(snappedf(value, 0.01))
	if SHORT_LABELS.has(stat):
		var number := str(roundi(value)) + ("%" if stat in Items.PERCENT_STATS else "")
		return "+%s %s" % [number, SHORT_LABELS[stat]]
	return Items.format_stat(stat, value)


## A címke nem szélesítheti a kártyát: ami nem fér ki, "..."-ra rövidül.
func _fitted(label: Label) -> Label:
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.x = 1
	return label


func _buy(id: String) -> void:
	if Progress.buy(id):
		Audio.play("level_up")
		_message.text = "%s: %d. szint kész!" % [Progress.UPGRADES[id]["name"], Progress.level(id)]
		_message.add_theme_color_override("font_color", Color(0.24, 0.5, 0.2))
		# A játékos statjai azonnal frissülnek.
		var player := get_tree().get_first_node_in_group("player")
		if player:
			player.get_node("Inventory").changed.emit()
	else:
		Audio.play("ui_error")
		_message.text = "Nincs elég arany a táborban."
		_message.add_theme_color_override("font_color", Color(0.6, 0.2, 0.12))
	_refresh()
	# A tábor jobb felső sarkában lévő kijelző is frissül (a játék közben áll).
	if get_tree().current_scene.has_method("_update_gold"):
		get_tree().current_scene.call("_update_gold")
