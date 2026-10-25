extends CanvasLayer

const MESSAGE_TIME := 1.6
const FADE_TIME := 0.25

@onready var _bar: ProgressBar = $HealthBar
@onready var _label: Label = $HealthBar/Label
@onready var _stats_label: Label = $StatsLabel
@onready var _depth_label: Label = $DepthLabel
@onready var _message: Label = $Message
@onready var _xp_bar: ProgressBar = $XpBar
@onready var _xp_label: Label = $XpBar/Label
@onready var _gold_label: Label = $Gold/Label

var _stats: Stats
var _message_tween: Tween
var _fade: ColorRect
var _dash_label: Label
var _boss_box: VBoxContainer
var _boss_name: Label
var _boss_bar: ProgressBar


func _ready() -> void:
	_message.modulate.a = 0.0
	# Fekete átmenet helyváltáskor (pl. a boltba be/ki).
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)
	_depth_label.text = "Emelet: %d" % GameState.depth
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var health: Health = player.get_node("Health")
	health.changed.connect(_on_health_changed)
	_on_health_changed(health.current, health.max_health)
	_stats = player.get_node("Stats")
	_stats.changed.connect(_on_stats_changed)
	_on_stats_changed()
	var experience: Experience = player.get_node("Experience")
	experience.changed.connect(_on_xp_changed)
	_on_xp_changed(experience.xp, experience.needed(), experience.level)
	player.connect("gold_changed", _on_gold_changed)
	_on_gold_changed(player.get("gold"))


## Suhanás-kijelző (csak az íjásznál): "Suhanás [Ctrl]: kész" / hátralévő idő.
func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	var has_dash: bool = player != null and Characters.data(Progress.character).get("dash", false)
	var has_cry: bool = player != null and Characters.data(Progress.character).get("war_cry", false)
	if has_cry:
		_update_skill_label("Hadi kiáltás", player.call("war_cry_cooldown_ratio") * player.WAR_CRY_COOLDOWN)
		return
	# A varázsló második varázslata (jobb egérgomb).
	if player != null and Characters.data(Progress.character).get("spells", false):
		if GameState.spells.size() > 1:
			_update_skill_label(Spells.ALL[GameState.spells[1]]["name"], player.call("secondary_cooldown_left"), "Jobb klikk")
		elif _dash_label != null:
			_dash_label.visible = false
		return
	if player != null and Characters.data(Progress.character).get("summon", false):
		if _dash_label == null:
			_create_skill_label()
		_dash_label.visible = true
		_update_skill_label("Csontvázak", player.call("summon_cooldown_left"), "Bal klikk")
		# A másodlagos idézés (jobb klikk: íjászok vagy óriás) állapota is mellette, ha már választotta.
		if Necromancy.has_archers():
			var archers_left: float = player.call("archer_cooldown_left")
			_dash_label.text += "   ·   Íjászok [Jobb klikk]: " + ("kész" if archers_left <= 0.0 else "%.1f mp" % archers_left)
		if Necromancy.has_giant():
			var giant_left: float = player.call("giant_cooldown_left")
			_dash_label.text += "   ·   Óriás [Jobb klikk]: " + ("kész" if giant_left <= 0.0 else "%.1f mp" % giant_left)
		return
	if player != null and Characters.data(Progress.character).get("shadow_step", false):
		_update_skill_label("Árnyéklépés", player.call("shadow_step_cooldown_ratio") * player.SHADOW_STEP_COOLDOWN)
		return
	if _dash_label == null:
		if not has_dash:
			return
		_create_skill_label()
	_dash_label.visible = has_dash
	if not has_dash:
		return
	_update_skill_label("Suhanás", player.call("dash_cooldown_ratio") * player.DASH_COOLDOWN)


## A Ctrl-képesség felirata (suhanás / hadi kiáltás): kész, vagy mennyi idő van még hátra.
func _update_skill_label(skill: String, left: float, key := "Ctrl") -> void:
	if _dash_label == null:
		_create_skill_label()
	_dash_label.visible = true
	if left <= 0.0:
		_dash_label.text = "%s [%s]: kész" % [skill, key]
		_dash_label.add_theme_color_override("font_color", Color(0.6, 0.95, 1.0))
	else:
		_dash_label.text = "%s [%s]: %.1f mp" % [skill, key, left]
		_dash_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))


func _create_skill_label() -> void:
	_dash_label = Label.new()
	_dash_label.add_theme_font_size_override("font_size", 18)
	_dash_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_dash_label.add_theme_constant_override("outline_size", 5)
	_dash_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	# Az XP-csík fölött.
	_dash_label.offset_top = -66
	_dash_label.offset_bottom = -42
	_dash_label.offset_left = -200
	_dash_label.offset_right = 200
	_dash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_dash_label)


func _on_gold_changed(gold: int) -> void:
	_gold_label.text = str(gold)


func _on_xp_changed(xp: int, needed: int, level: int) -> void:
	_xp_bar.max_value = needed
	_xp_bar.value = xp
	_xp_label.text = "%d. szint   ·   %d / %d XP" % [level, xp, needed]


## A főellenség neve és életcsíkja a képernyő tetején, a harc idejére.
func show_boss(boss: Node2D) -> void:
	if _boss_box == null:
		_build_boss_bar()
	_boss_name.text = str(boss.get("boss_name"))
	var health: Health = boss.get_node("Health")
	_boss_bar.max_value = health.max_health
	_boss_bar.value = health.current
	if not health.changed.is_connected(_on_boss_health_changed):
		health.changed.connect(_on_boss_health_changed)
	_boss_box.visible = true
	_boss_box.modulate.a = 0.0
	create_tween().tween_property(_boss_box, "modulate:a", 1.0, 0.5)


func hide_boss() -> void:
	if _boss_box:
		create_tween().tween_property(_boss_box, "modulate:a", 0.0, 0.8)


func _on_boss_health_changed(current: int, maximum: int) -> void:
	_boss_bar.max_value = maximum
	create_tween().tween_property(_boss_bar, "value", float(current), 0.15)


func _build_boss_bar() -> void:
	_boss_box = VBoxContainer.new()
	_boss_box.anchor_left = 0.5
	_boss_box.anchor_right = 0.5
	_boss_box.offset_left = -320
	_boss_box.offset_right = 320
	_boss_box.offset_top = 12
	_boss_box.add_theme_constant_override("separation", 2)
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_boss_box)
	_boss_name = MenuStyle.title_label("", 40, MenuStyle.GOLD)
	_boss_box.add_child(_boss_name)
	_boss_bar = ProgressBar.new()
	_boss_bar.custom_minimum_size = Vector2(640, 22)
	_boss_bar.show_percentage = false
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.1, 0.04, 0.05, 0.9)
	back.border_color = MenuStyle.GOLD.darkened(0.25)
	back.set_border_width_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.68, 0.1, 0.16)
	fill.border_color = MenuStyle.GOLD.darkened(0.25)
	fill.set_border_width_all(3)
	_boss_bar.add_theme_stylebox_override("background", back)
	_boss_bar.add_theme_stylebox_override("fill", fill)
	_boss_box.add_child(_boss_bar)


## Elsötétítés; a visszaadott jelre lehet várni (await).
func fade_out() -> Signal:
	return _fade_to(1.0)


func fade_in() -> Signal:
	return _fade_to(0.0)


func _fade_to(alpha: float) -> Signal:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, FADE_TIME)
	return tween.finished


func setup_map(rooms: Array[Room], player: Node2D, cell: Vector2i) -> void:
	$Minimap.setup(rooms, player, cell)


## Nagy felirat a képernyő közepén, ami magától elhalványul.
func show_message(text: String) -> void:
	_message.text = text
	_message.modulate.a = 1.0
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_interval(MESSAGE_TIME)
	_message_tween.tween_property(_message, "modulate:a", 0.0, 0.5)


func _on_health_changed(current: int, maximum: int) -> void:
	_bar.max_value = maximum
	_bar.value = current
	_label.text = "HP %d / %d" % [current, maximum]


func _on_stats_changed() -> void:
	var player := _stats.get_parent()
	_stats_label.text = "Sebzés / ütés: %d\nKözelharci: %+d\nTávolsági: %+d\nTöbblövés: %d nyíl\nSebzés: %+d%%\nÉlet: %d\nRegen: %.1f / mp\nVédelem: %d%%\nTalálat: %d%%\nKikerülés: %d%%\nSebesség: %d%%\nÜtési seb.: %d%%\nKritikus: %d%%\nHatótáv: %d%%" % [
		player.call("hit_damage"), _stats.damage, _stats.ranged_damage, _stats.multishot, _stats.damage_percent,
		_stats.max_health, _stats.health_regen, _stats.defense, _stats.accuracy, _stats.dodge, _stats.move_speed,
		_stats.attack_speed, _stats.crit_chance, _stats.attack_range,
	]
	if _stats.pierce > 0:
		_stats_label.text += "\nÁtütés: %d" % _stats.pierce
