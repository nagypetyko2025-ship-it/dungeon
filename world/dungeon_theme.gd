class_name DungeonTheme
## A kazamata kinézete mélység szerint (három sáv): az 1-20. emelet a régi szürke kő; a 21-40. a "Vérkő"
## (vöröses kő, parázsló repedések, bíbor zászlók, vér a falikutakban, hamu száll); a 41.-től a "Káoszkő"
## (fekete-ibolya obszidián, izzó lila repedések és kutak, ibolya lángú fáklyák, lila szikrák).
## A sávon belül emeletről emeletre sötétebb (CanvasModulate). A csempelapok: assets/dungeon/*_sheet.png
## (a 0x72 lap bal felső 128x128-as része átszínezve, ugyanazokkal a csempe-koordinátákkal).

const DEPTHS_FROM := 21
const ABYSS_FROM := 41
## A 41. utáni sötétedés eddig az emeletig tart (utána már nem sötétedik tovább).
const ABYSS_DARKEST := 100
const SHEETS: Array[Texture2D] = [
	preload("res://assets/0x72_dungeon/0x72_DungeonTilesetII_v1.7.png"),
	preload("res://assets/dungeon/depths_sheet.png"),
	preload("res://assets/dungeon/abyss_sheet.png"),
]
## A kép mérete: az átszínezett lapokon csak ennyi van (a falak, padlók, kutak, oszlop).
const THEMED_AREA := Rect2(0, 0, 128, 128)
## A szín-hangulat (CanvasModulate) a sáv első és utolsó emeletén; közte emeletenként átmenet.
const LIGHT := [
	[Color(0.78, 0.74, 0.8), Color(0.78, 0.74, 0.8)],
	[Color(0.7, 0.58, 0.6), Color(0.52, 0.38, 0.42)],
	[Color(0.5, 0.42, 0.6), Color(0.32, 0.25, 0.4)],
]
const CLEAR := [Color(0.1, 0.07, 0.09), Color(0.09, 0.04, 0.05), Color(0.05, 0.03, 0.08)]
## Fáklya: a láng színezése és a fénye.
const FLAME := [Color.WHITE, Color(1.25, 0.75, 0.6), Color(0.85, 0.55, 1.6)]
const TORCH_LIGHT := [Color.WHITE, Color(1.0, 0.55, 0.4), Color(0.7, 0.4, 1.0)]
## A padló izzó repedéseinek fénye és a levegőben szálló részecskék (hamu / szikrák) színe.
const GLOW := [Color.TRANSPARENT, Color(1.0, 0.35, 0.12), Color(0.7, 0.3, 1.0)]
const MOTES := [Color.TRANSPARENT, Color(1.0, 0.45, 0.2, 0.8), Color(0.75, 0.4, 1.0, 0.85)]


## 0: régi kő (1-20.), 1: Vérkő (21-40.), 2: Káoszkő (41.-től). A gyakorló pálya mindig 0.
static func band(depth: int) -> int:
	if GameState.tutorial:
		return 0
	return 2 if depth >= ABYSS_FROM else 1 if depth >= DEPTHS_FROM else 0


static func sheet(depth: int) -> Texture2D:
	return SHEETS[band(depth)]


## A csempe- vagy díszrészlet melyik lapról jöjjön: a falak / kutak / oszlop a sáv lapjáról, a többi az eredetiről.
static func sheet_for(region: Rect2, depth: int) -> Texture2D:
	return sheet(depth) if THEMED_AREA.encloses(region) else SHEETS[0]


## A sáv szín-hangulata ezen az emeleten (a sávon belül egyre sötétebb).
static func light(depth: int) -> Color:
	var b := band(depth)
	var t := 0.0
	if b == 1:
		t = inverse_lerp(DEPTHS_FROM, ABYSS_FROM - 1, depth)
	elif b == 2:
		t = clampf(inverse_lerp(ABYSS_FROM, ABYSS_DARKEST, depth), 0.0, 1.0)
	return LIGHT[b][0].lerp(LIGHT[b][1], t)


static func clear_color(depth: int) -> Color:
	return CLEAR[band(depth)]


## A 0x72 lapról vett AtlasTexture-ös sprite (pl. az oszlop) a sáv kövéből.
static func retheme(sprite: Sprite2D, depth: int) -> void:
	var atlas := sprite.texture as AtlasTexture
	if band(depth) == 0 or atlas == null or not THEMED_AREA.encloses(atlas.region):
		return
	var themed := AtlasTexture.new()
	themed.atlas = sheet(depth)
	themed.region = atlas.region
	sprite.texture = themed


## Szálló részecskék a kamera körül (a Vérkőben felfelé szálló hamu és parázs, a Káoszkőben lassan
## örvénylő lila szikrák). Az 1-20. emeleten nincs. A `follow` (a játékos) gyereke lesz.
static func add_motes(depth: int, follow: Node2D) -> void:
	var b := band(depth)
	if b == 0:
		return
	var motes := CPUParticles2D.new()
	motes.name = "ThemeMotes"
	motes.amount = 36 if b == 1 else 44
	motes.lifetime = 5.0
	motes.preprocess = 5.0
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(460, 280)
	motes.local_coords = false
	motes.direction = Vector2(0, -1) if b == 1 else Vector2(1, 0)
	motes.spread = 25.0 if b == 1 else 180.0
	motes.gravity = Vector2(0, -6) if b == 1 else Vector2.ZERO
	motes.initial_velocity_min = 8.0
	motes.initial_velocity_max = 22.0
	motes.scale_amount_min = 1.5
	motes.scale_amount_max = 3.0
	motes.color = MOTES[b]
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.add_point(0.25, Color(1, 1, 1, 1))
	fade.add_point(0.75, Color(1, 1, 1, 1))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0))
	motes.color_ramp = fade
	motes.z_index = 5
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	motes.material = glow
	follow.add_child(motes)


## Izzó repedés a padlón (a Vérkőben parázs, a Káoszkőben ibolya): cikcakkos vonal halvány fénnyel.
## `parent`-be kerül, `at` helyre (helyi koordináta). Az 1-20. emeleten nincs.
static func add_rift(depth: int, parent: Node2D, at: Vector2, z: int) -> void:
	var b := band(depth)
	if b == 0:
		return
	var rift := Line2D.new()
	var length := randf_range(26.0, 54.0)
	var angle := randf_range(-0.5, 0.5) + (PI / 2.0 if randf() < 0.3 else 0.0)
	var steps := 5
	for i in steps + 1:
		var along := Vector2(length * (float(i) / steps - 0.5), 0).rotated(angle)
		var jitter := Vector2(0, randf_range(-4.0, 4.0)).rotated(angle) if i > 0 and i < steps else Vector2.ZERO
		rift.add_point(at + along + jitter)
	rift.width = 3.0
	var taper := Curve.new()
	taper.add_point(Vector2(0, 0.2))
	taper.add_point(Vector2(0.5, 1.0))
	taper.add_point(Vector2(1, 0.2))
	rift.width_curve = taper
	rift.default_color = GLOW[b].lightened(0.25)
	rift.z_index = z
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	rift.material = add
	parent.add_child(rift)
	var light := PointLight2D.new()
	var gradient := Gradient.new()
	gradient.set_color(0, GLOW[b])
	gradient.set_color(1, Color(0, 0, 0, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	light.texture = texture
	light.texture_scale = length / 40.0
	light.energy = 0.55
	light.position = at
	parent.add_child(light)
	var pulse := light.create_tween().set_loops()
	pulse.tween_property(light, "energy", 0.3, randf_range(0.9, 1.4)).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(light, "energy", 0.6, randf_range(0.9, 1.4)).set_trans(Tween.TRANS_SINE)
