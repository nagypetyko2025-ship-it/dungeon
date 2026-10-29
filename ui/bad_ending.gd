extends "res://ui/ending_story.gd"
## Rossz befejezés: ha Azazel ellen elestél (a halálképernyő gombja után), 9 képen, pokoli zenével
## (Audio "bad_ending") elmondja, mi történt volna. Mindenkinél ugyanaz; csak az első képen a saját
## karaktered fekszik a trón előtt. A végén oda megy, ahova a halálképernyő küldött (`next_scene`).

static var next_scene := "res://world/camp.tscn"

const BAD_SLIDES := [
	"Elestél a trón előtt. Azazel nevetése betöltötte a poklot, és a tüzek a magasba csaptak, mintha ünnepelnének.",
	"Aztán felállt a trónjáról. Ezer év után először lépett át a vörös kapun, és a száz emelet minden szörnye felébredt.",
	"Felfelé indultak a lépcsőn: emeletről emeletre, egyre többen. A Mélység túlcsordult, és nem maradt, ami megállítsa.",
	"A tábor égett elsőként. A sátrak, a kocsma, a kút... Akik nem futottak el időben, azok sosem futottak el többé.",
	"A király a trónteremben várta. Nem menekült: az alapító adósságát ő akarta megfizetni. Azazel elfogadta az árat.",
	"Gáspár a város kapujában állt, egy maroknyi emberrel. Kitartottak hajnalig. Senki sem jött vissza, hogy elmondja, hogyan.",
	"Vörös lett az ég a királyság fölött, és hamu hullott a hó helyett. A várban új trón állt, és új király ült rajta.",
	"A lelked odalent maradt, láncra verve a harminc név mellett. Te lettél a harmincegyedik: az ár, amit a királyság fizetett.",
	"De ez csak egy lehetséges jövő. A lépcső még ott van, és a kard még a kezedben.\n\n[b]Kelj fel, és próbáld újra.[/b]\n\n[i]Rossz befejezés.[/i]",
]


func _ready() -> void:
	character = Progress.character
	super()


func _slide_count() -> int:
	return BAD_SLIDES.size()


func _slide_text(index: int) -> String:
	return str(BAD_SLIDES[index])


func _draw_slide(index: int) -> void:
	call("_bad_%d" % index)


func _next_scene() -> String:
	return next_scene


func _music() -> String:
	return "bad_ending"


## 1. A hős a trón előtt fekszik, fölötte Azazel teljes, izzó alakja.
func _bad_0() -> void:
	_hell_floor()
	var lord := _texture(_atlas(AZAZEL, Rect2(Vector2.ZERO, Vector2(160, 144))), Vector2(160, 56))
	lord.scale = Vector2(0.5, 0.5)
	_glow(Vector2(160, 56), Color(1, 0.3, 0.05, 0.4), 60.0)
	var fallen := _hero(Vector2(96, 82))
	fallen.rotation = PI / 2.0
	fallen.modulate = Color(0.7, 0.5, 0.5)


## 2. Azazel a kapuban, mögötte a szörnyek szemei a sötétben.
func _bad_1() -> void:
	_sky(Color(0.05, 0.01, 0.01), Color(0.25, 0.04, 0.02))
	_hall(Color(0.55, 0.3, 0.28))
	var gate := _texture(_atlas(Hell.Gate.SHEET, Rect2(Vector2.ZERO, Hell.Gate.FRAME)), Vector2(120, 62))
	gate.scale = Vector2(1.6, 1.6)
	_glow(Vector2(120, 62), Color(1, 0.35, 0.1, 0.5), 50.0)
	var lord := _texture(_atlas(AZAZEL, Rect2(Vector2.ZERO, Vector2(160, 144))), Vector2(120, 66))
	lord.scale = Vector2(0.3, 0.3)
	lord.modulate = Color(0.4, 0.15, 0.12)
	for i in 10:
		_eyes(Vector2(14 + i * 23 + (i % 2) * 6, 40 + (i * 13) % 30))


## 3. Szörnyek menetelnek felfelé a lépcsőn.
func _bad_2() -> void:
	_sky(Color(0.06, 0.02, 0.03), Color(0.2, 0.05, 0.05))
	_hall(Color(0.5, 0.35, 0.35))
	_tile(STAIRS, Vector2(212, 74))
	_glow(Vector2(220, 82), Color(1, 0.3, 0.1, 0.35), 26.0)
	for i in 9:
		var monster := _frames(SpriteSheet.character_frames(MONSTERS[i % MONSTERS.size()]), Vector2(20 + i * 21, 86 + (i % 2) * 8))
		monster.play("run")
		monster.speed_scale = 0.7
		monster.modulate = Color(1, 0.75, 0.7)
	var big := _frames(SpriteSheet.character_frames(BIG_DEMON), Vector2(40, 96))
	big.play("run")
	big.scale = Vector2(1.3, 1.3)


## 4. A tábor lángokban.
func _bad_3() -> void:
	_outdoor(NIGHT, Color(0.55, 0.35, 0.3))
	_tent(Vector2(30, 58))
	_tent(Vector2(170, 58))
	for at: Vector2 in [Vector2(46, 62), Vector2(186, 62), Vector2(110, 80), Vector2(140, 70), Vector2(70, 90), Vector2(210, 88)]:
		_fire(at, 1.0)
	_texture(WELL, Vector2(124, 66)).modulate = Color(0.6, 0.4, 0.35)
	_glow(Vector2(120, 60), Color(1, 0.35, 0.1, 0.3), 110.0)


## 5. A király a trónteremben, előtte Azazel; az őrök a földön.
func _bad_4() -> void:
	_sky(Color(0.2, 0.05, 0.05), Color(0.4, 0.12, 0.08))
	_hall(Color(0.8, 0.55, 0.5))
	for x in [2, 12]:
		_tile(BANNER_RED, Vector2(x * 16, 46)).modulate = Color(0.6, 0.4, 0.4)
	_texture(THRONE, Vector2(120, 66))
	_frames(_sheet_frames(KING, Vector2(16, 32)), Vector2(120, 74))
	for at: Vector2 in [Vector2(70, 82), Vector2(196, 86)]:
		var guard := _frames(_sheet_frames(GUARD, Vector2(16, 28)), at)
		guard.rotation = PI / 2.0
		guard.modulate = Color(0.6, 0.5, 0.5)
	var lord := _texture(_atlas(AZAZEL, Rect2(Vector2.ZERO, Vector2(160, 144))), Vector2(170, 60))
	lord.scale = Vector2(0.4, 0.4)
	lord.flip_h = true
	_glow(Vector2(170, 60), Color(1, 0.3, 0.05, 0.35), 45.0)


## 6. Gáspár a város kapujában, egy maroknyi emberrel, szemben a szörnyekkel.
func _bad_5() -> void:
	_sky(Color(0.15, 0.04, 0.04), Color(0.45, 0.15, 0.08))
	for x in 15:
		_tile(WALL_TOP, Vector2(x * 16, 22)).modulate = Color(0.7, 0.5, 0.45)
		_tile(WALL_MID, Vector2(x * 16, 38)).modulate = Color(0.7, 0.5, 0.45)
		for y in 3:
			_tile(FLOOR, Vector2(x * 16, 54 + y * 16)).modulate = Color(0.6, 0.45, 0.4)
	_rect(Vector2(16, 38), Vector2(32, 16), Color(0.15, 0.08, 0.06))
	_npc("veteran", Vector2(60, 92))
	_guard(Vector2(40, 96), false)
	_people([[KNIGHT_M, Vector2(78, 96), false], [KNIGHT_F, Vector2(24, 90), false]])
	for i in 7:
		var monster := _frames(SpriteSheet.character_frames(MONSTERS[i % MONSTERS.size()]), Vector2(130 + i * 15, 88 + (i % 3) * 5), true)
		monster.modulate = Color(1, 0.7, 0.65)
	_fire(Vector2(110, 70), 0.8)


## 7. Vörös ég, hamueső, a vár fölött Azazel izzó alakja.
func _bad_6() -> void:
	_sky(Color(0.35, 0.05, 0.03), Color(0.7, 0.25, 0.08))
	for x in 15:
		var height := 20 + (x * 7) % 18
		_rect(Vector2(x * 16, 100 - height), Vector2(16, height), Color(0.08, 0.03, 0.03))
	_rect(Vector2(96, 40), Vector2(48, 30), Color(0.08, 0.03, 0.03))
	for i in 4:
		_rect(Vector2(96 + i * 14, 34), Vector2(6, 6), Color(0.08, 0.03, 0.03))
	var lord := _texture(_atlas(AZAZEL, Rect2(Vector2.ZERO, Vector2(160, 144))), Vector2(120, 26))
	lord.scale = Vector2(0.3, 0.3)
	lord.modulate = Color(1, 0.5, 0.4, 0.8)
	_glow(Vector2(120, 26), Color(1, 0.4, 0.1, 0.4), 40.0)
	for i in 40:
		var ash := _rect(Vector2((i * 37) % 240, (i * 23) % 100), Vector2(1, 1), Color(0.6, 0.55, 0.55, 0.8))
		ash.create_tween().tween_property(ash, "position:y", ash.position.y + 30.0, 7.0)


## 8. A hős lelke láncra verve, körülötte a harminc név halvány lelkei.
func _bad_7() -> void:
	_sky(Color(0.04, 0.01, 0.02), Color(0.15, 0.03, 0.03))
	for i in 30:
		_wisp(Vector2(10 + (i * 41) % 220, 40 + (i * 17) % 50), Color(0.8, 0.3, 0.25, 0.35))
	var soul := _hero(Vector2(120, 80))
	soul.modulate = Color(0.7, 0.8, 1, 0.7)
	for side in [-1.0, 1.0]:
		var chain := Line2D.new()
		chain.width = 1.0
		chain.default_color = Color(0.5, 0.45, 0.45)
		chain.add_point(Vector2(120 + side * 6, 66))
		chain.add_point(Vector2(120 + side * 60, 20))
		_picture.add_child(chain)
	_glow(Vector2(120, 66), Color(0.6, 0.75, 1, 0.3), 20.0)


## 9. A lépcső még ott van, rajta egy halvány fénycsík: még nem késő.
func _bad_8() -> void:
	_sky(Color(0.04, 0.03, 0.05), Color(0.1, 0.08, 0.08))
	_hall(Color(0.6, 0.55, 0.55))
	_tile(STAIRS, Vector2(112, 74))
	_glow(Vector2(120, 82), Color(1, 0.85, 0.6, 0.45), 30.0)
	_torch(Vector2(100, 50))
	_torch(Vector2(140, 50))
	_sword(Vector2(96, 90), 1.2, Color(0.85, 0.6, 0.45))


func _hell_floor() -> void:
	_sky(Color(0.12, 0.02, 0.02), Color(0.35, 0.08, 0.04))
	for x in 15:
		for y in 3:
			_tile(FLOOR, Vector2(x * 16, 54 + y * 16)).modulate = Color(0.6, 0.3, 0.25)
	for x: float in [16.0, 52.0, 196.0, 228.0]:
		_fire(Vector2(x, 70), 1.0)


## Két vörös szem a sötétben.
func _eyes(at: Vector2) -> void:
	for dx in [0, 3]:
		_rect(at + Vector2(dx, 0), Vector2(1, 1), Color(1, 0.2, 0.1))
