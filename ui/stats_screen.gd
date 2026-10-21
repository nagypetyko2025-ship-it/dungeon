extends CanvasLayer
## Karakter ablak (Tab): a statok részletesen, a fejlődés és a futás adatai,
## pergamenre írva. A statok lapozhatók (◄ ► vagy A / D): harc, védekezés és mozgás,
## különleges (lila: életlopás, tüskék, aranykereső, tapasztalat). Megnyitását/bezárását
## a Menus kezeli.

const ICON_SIZE := Vector2(32, 32)
const PLAYER_SCRIPT := preload("res://player/player.gd")
const SPECIAL_INK := Color(0.48, 0.23, 0.66)
## A stat-oldalak: cím és a statok sorrendje.
const PAGES := [
	["Harc", ["damage", "ranged_damage", "damage_percent", "crit_chance", "attack_speed", "attack_range",
		"accuracy", "multishot"]],
	["Védekezés és mozgás", ["max_health", "health_regen", "defense", "dodge", "move_speed"]],
	["Különleges", ["lifesteal", "thorns", "gold_find", "xp_bonus"]],
]
## A lila statok ikonja egy-egy jellemző tárgy képe.
const SPECIAL_ICONS := {"lifesteal": "trinket_fang", "thorns": "gloves_spiked", "gold_find": "trinket_clover",
	"xp_bonus": "trinket_eye"}

var _player: Node
var _left: GridContainer
var _right: GridContainer
var _page := 0
var _page_label: Label


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
	# Bal oldalt a lapozható statok (fölöttük a lapozó), jobbra a fegyver és a futás.
	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 10)
	left_box.custom_minimum_size = Vector2(560, 470)
	columns.add_child(left_box)
	var pager := HBoxContainer.new()
	pager.add_theme_constant_override("separation", 10)
	left_box.add_child(pager)
	pager.add_child(_page_button("◄", -1))
	_page_label = UiStyle.label("", 19, UiStyle.INK)
	_page_label.custom_minimum_size.x = 360
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pager.add_child(_page_label)
	pager.add_child(_page_button("►", 1))
	_left = _make_grid(4)
	_right = _make_grid(2)
	left_box.add_child(_left)
	columns.add_child(_right)

	var hint := UiStyle.label("◄ ► / A D: lapozás   ·   [Tab] bezárás", 14, UiStyle.INK_LIGHT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(hint)


func _page_button(text: String, step: int) -> Button:
	var button := MenuStyle.button(text)
	button.custom_minimum_size = Vector2(60, 40)
	button.add_theme_font_size_override("font_size", 18)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_turn_page.bind(step))
	return button


func _turn_page(step: int) -> void:
	_page = wrapi(_page + step, 0, PAGES.size())
	Audio.play("ui_click")
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not visible or key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_A, KEY_LEFT: _turn_page(-1)
		KEY_D, KEY_RIGHT: _turn_page(1)
		_: return
	get_viewport().set_input_as_handled()


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

	_page_label.text = "%s  (%d / %d)" % [PAGES[_page][0], _page + 1, PAGES.size()]
	for stat: String in PAGES[_page][1]:
		_add_stat(stat, stats, health)

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


## Egy stat sora a megfelelő felirattal, értékkel és magyarázattal.
func _add_stat(stat: String, stats: Stats, health: Health) -> void:
	match stat:
		"damage": _stat_row(stat, "Közelharci sebzés", "%+d" % stats.damage,
			"×%d%% a fegyver szerint" % roundi(_player.call("weapon_scaling") * 100.0))
		"ranged_damage": _stat_row(stat, "Távolsági sebzés", "%+d" % stats.ranged_damage, "az íjakat erősíti")
		"damage_percent": _stat_row(stat, "Sebzés", "%+d%%" % stats.damage_percent, "minden találat")
		"max_health": _stat_row(stat, "Élet", "%d / %d" % [health.current, health.max_health], "")
		"health_regen": _stat_row(stat, "Regeneráció", "%.1f / mp" % stats.health_regen, "")
		"multishot": _stat_row(stat, "Többlövés", "%d nyíl" % stats.multishot,
			"íjjal egyszerre, max %d (csak legendás növeli)" % Stats.MAX_MULTISHOT)
		"defense": _stat_row(stat, "Védelem", "%d%%" % stats.defense, "a sebzésből, max %d%%" % Stats.MAX_DEFENSE)
		"accuracy": _stat_row(stat, "Találati esély", "%d%%" % stats.accuracy,
			"ennyire találod el a szörnyet, max %d%%" % Stats.MAX_ACCURACY)
		"dodge": _stat_row(stat, "Kikerülés", "%d%%" % stats.dodge, "max %d%%" % Stats.MAX_DODGE)
		"move_speed": _stat_row(stat, "Sebesség", "%d%%" % stats.move_speed,
			"%d px / mp" % roundi(PLAYER_SCRIPT.BASE_SPEED * stats.move_speed / 100.0))
		"attack_speed": _stat_row(stat, "Ütési sebesség", "%d%%" % stats.attack_speed,
			"%.2f mp / ütés" % _player.call("attack_cooldown"))
		"crit_chance": _stat_row(stat, "Kritikus esély", "%d%%" % stats.crit_chance,
			"×%s sebzés, max %d%%" % [str(_player.call("weapon_crit_multiplier")), Stats.MAX_CRIT])
		"attack_range": _stat_row(stat, "Hatótáv", "%d%%" % stats.attack_range, "max %d%%" % Stats.MAX_RANGE)
		# A lila (különleges) statok csak tárgyakból jönnek.
		"lifesteal": _stat_row(stat, "Életlopás", "%d%%" % roundi(stats.special(stat)),
			"ennyi eséllyel +1 élet találatkor")
		"thorns": _stat_row(stat, "Tüskék", "%d" % roundi(stats.special(stat)), "ennyit sebez vissza annak, aki megüt")
		"gold_find": _stat_row(stat, "Aranykereső", "%+d%%" % roundi(stats.special(stat)), "ennyivel több arany")
		"xp_bonus": _stat_row(stat, "Tapasztalat", "%+d%%" % roundi(stats.special(stat)), "ennyivel több XP")


func _stat_row(stat: String, title: String, value: String, detail: String) -> void:
	var special := stat in Stats.SPECIAL
	var icon := TextureRect.new()
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	for upgrade in Upgrades.ALL + Upgrades.LEGENDARY:
		if upgrade["stat"] == stat:
			icon.texture = Upgrades.icon(upgrade)
	if special:
		icon.texture = Items.icon(Items.create(SPECIAL_ICONS[stat]))
	_left.add_child(icon)
	_left.add_child(_cell(title, SPECIAL_INK if special else UiStyle.INK_LIGHT))
	_left.add_child(_cell(value, SPECIAL_INK if special else UiStyle.INK, 18))
	# A tárgyakból jövő rész külön sorban, zölden / pirosan (a lila statoknál az egész onnan jön).
	var bonus: float = _player.get_node("Stats").get_bonus(stat)
	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", -2)
	detail_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if not detail.is_empty():
		detail_box.add_child(_cell(detail, UiStyle.INK_LIGHT, 14))
	if not is_zero_approx(bonus) and not special:
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
