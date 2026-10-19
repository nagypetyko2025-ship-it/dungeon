extends CanvasLayer
## Karakter ablak (Tab): a statok részletesen, a fejlődés és a futás adatai,
## pergamenre írva. Megnyitását/bezárását a Menus kezeli.

const ICON_SIZE := Vector2(32, 32)
const PLAYER_SCRIPT := preload("res://player/player.gd")

var _player: Node
var _left: GridContainer
var _right: GridContainer


func _ready() -> void:
	visible = false
	_build()


func open() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_refresh()
	visible = true


func close() -> void:
	visible = false


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
	center.add_child(window)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	window.add_child(root)
	root.add_child(UiStyle.title_bar("Karakter"))

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 48)
	root.add_child(columns)
	_left = _make_grid(4)
	_right = _make_grid(2)
	columns.add_child(_left)
	columns.add_child(_right)

	var hint := UiStyle.label("[Tab] bezárás", 14, UiStyle.INK_LIGHT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(hint)


func _make_grid(columns: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	return grid


func _refresh() -> void:
	for grid in [_left, _right]:
		for child in grid.get_children():
			child.queue_free()
	var stats: Stats = _player.get_node("Stats")
	var health: Health = _player.get_node("Health")
	var experience: Experience = _player.get_node("Experience")

	_section(_left, "Tulajdonságok", 4)
	_stat_row("damage", "Közelharci sebzés", "%+d" % stats.damage,
		"×%d%% a fegyver szerint" % roundi(_player.call("weapon_scaling") * 100.0))
	_stat_row("ranged_damage", "Távolsági sebzés", "%+d" % stats.ranged_damage, "az íjakat erősíti")
	_stat_row("damage_percent", "Sebzés", "%+d%%" % stats.damage_percent, "minden találat")
	_stat_row("max_health", "Élet", "%d / %d" % [health.current, health.max_health], "")
	_stat_row("health_regen", "Regeneráció", "%.1f / mp" % stats.health_regen, "")
	_stat_row("defense", "Védelem", "%d%%" % stats.defense, "a sebzésből, max %d%%" % Stats.MAX_DEFENSE)
	_stat_row("dodge", "Kikerülés", "%d%%" % stats.dodge, "max %d%%" % Stats.MAX_DODGE)
	_stat_row("move_speed", "Sebesség", "%d%%" % stats.move_speed,
		"%d px / mp" % roundi(PLAYER_SCRIPT.BASE_SPEED * stats.move_speed / 100.0))
	_stat_row("attack_speed", "Ütési sebesség", "%d%%" % stats.attack_speed,
		"%.2f mp / ütés" % _player.call("attack_cooldown"))
	_stat_row("crit_chance", "Kritikus esély", "%d%%" % stats.crit_chance,
		"×%s sebzés, max %d%%" % [str(_player.call("weapon_crit_multiplier")), Stats.MAX_CRIT])
	_stat_row("attack_range", "Hatótáv", "%d%%" % stats.attack_range, "max %d%%" % Stats.MAX_RANGE)

	# A fegyver és a végső sebzés (Brotato-szerű képlet, lásd Stats).
	_section(_right, "Fegyver", 2)
	var weapon = _player.get_node("Inventory").equipment["weapon"]
	_pair("Fegyver", weapon["name"] if weapon else "—")
	var base: int = _player.call("weapon_base_damage")
	var scaling: float = _player.call("weapon_scaling")
	var hit: int = _player.call("hit_damage")
	_pair("Alapsebzés", str(base))
	var scaled_stat: int = stats.ranged_damage if weapon and weapon.get("weapon_type", "") == "bow" else stats.damage
	_pair("Képlet", "(%d + %d × %d%%) × %d%%" % [base, scaled_stat, roundi(scaling * 100.0), 100 + stats.damage_percent])
	_pair("Karakter", Characters.data(Progress.character)["name"])
	_pair("Sebzés / ütés", str(hit))
	_pair("Kritikus ütés", str(roundi(hit * float(_player.call("weapon_crit_multiplier")))))
	# Különleges tárgy-képességek (csak ha van ilyen).
	var specials: Array[String] = []
	for stat: String in Stats.SPECIAL:
		var value := stats.special(stat)
		if value > 0.0:
			specials.append(Items.format_stat(stat, value))
	if not specials.is_empty():
		_section(_right, "Különleges", 2)
		for text in specials:
			_pair(text, "")
	_section(_right, "Fejlődés", 2)
	_pair("Karakterszint", str(experience.level))
	_pair("Tapasztalat", "%d / %d XP" % [experience.xp, experience.needed()])
	_pair("Arany", str(_player.get("gold")))
	_section(_right, "Futás", 2)
	_pair("Emelet", str(GameState.depth))
	_pair("Megölt ellenségek", str(GameState.kills))
	var seconds := int(GameState.run_time)
	_pair("Játékidő", "%d:%02d" % [seconds / 60, seconds % 60])


## Szakaszcím, ami a rács teljes szélességét kitölti (a többi oszlopba üres hely kerül).
func _section(grid: GridContainer, title: String, columns: int) -> void:
	grid.add_child(UiStyle.label(title, 19, UiStyle.INK, false))
	for i in columns - 1:
		grid.add_child(Control.new())


func _stat_row(stat: String, title: String, value: String, detail: String) -> void:
	var icon := TextureRect.new()
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	for upgrade in Upgrades.ALL:
		if upgrade["stat"] == stat:
			icon.texture = Upgrades.icon(upgrade)
	_left.add_child(icon)
	_left.add_child(_cell(title, UiStyle.INK_LIGHT))
	_left.add_child(_cell(value, UiStyle.INK, 18))
	# A tárgyakból jövő rész külön sorban, zölden / pirosan.
	var bonus: float = _player.get_node("Stats").get_bonus(stat)
	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", -2)
	detail_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if not detail.is_empty():
		detail_box.add_child(_cell(detail, UiStyle.INK_LIGHT, 14))
	if not is_zero_approx(bonus):
		var color := Color(0.24, 0.5, 0.2) if bonus > 0 else Color(0.66, 0.18, 0.15)
		detail_box.add_child(_cell("tárgyakból / táborból: " + Items.format_stat(stat, bonus).get_slice(" ", 0), color, 14))
	_left.add_child(detail_box)


func _pair(title: String, value: String) -> void:
	_right.add_child(_cell(title, UiStyle.INK_LIGHT))
	_right.add_child(_cell(value, UiStyle.INK, 18))


func _cell(text: String, color: Color, font_size := 16) -> Label:
	var cell := UiStyle.label(text, font_size, color)
	cell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return cell
