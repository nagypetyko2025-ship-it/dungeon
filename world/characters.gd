class_name Characters
## Játszható karakterek. A kocsmában ülnek a saját helyükön; odamész és E-t nyomsz,
## átveszed az irányítást. A tábori fejlesztések közösek (minden karakterre érvényesek),
## a tábori felszerelés karakterenként külön van (lásd Progress); mindegyiknek saját
## kezdőfegyvere, fegyverkorlátja és esetleges bónusza van.
##
## rect          a 0x72 lapról: az álló animáció első kockája (utána futás, aztán sebződés)
## sheet         saját kép (16x28-as kockák: 0-3 álló, 4-7 futás, 8 sebződés)
## seat          melyik kocsmai széken ül, amikor nem ő az aktív karakter
## weapons       "melee": közelharci fegyverek (íj nem), "ranged": csak íj
## bow_damage    íjjal ennyivel nagyobbat sebez (szorzó-bónusz, pl. 0.25 = +25%)
## bow_speed     íjjal ennyivel gyorsabban lő (pl. 0.15 = 15%-kal rövidebb cooldown)
## multishot     a Többlövés alapértéke (egyszerre ennyi nyíl; alapból 1)
## move_speed    a mozgási sebesség alapértéke (%, alapból 100)
## dash          van-e Suhanása (Ctrl: a kurzor felé, a szörnyeken át)
## role / traits / story   a bemutatkozó panel szövegei (a kocsmában, a karakter mellett)

const DEFAULT := "knight"
const ALL := {
	"knight": {
		"name": "Lovag", "rect": Rect2(128, 100, 16, 28),
		"start_weapon": "sword_rusty", "seat": 0, "weapons": "melee",
		"description": "Kiegyensúlyozott közelharcos. Rozsdás karddal indul.",
		"role": "Közelharcos",
		"story": "Egykor a királyi őrség tagja volt; most a mélység titkai után kutat. "
			+ "Nem fél belegázolni a szörnyek közé.",
		"traits": [
			"Rozsdás karddal indul",
			"Bármilyen közelharci fegyvert forgathat (kard, tőr, lándzsa, balta, buzogány)",
			"Íjat nem használhat",
		],
	},
	"archer": {
		"name": "Íjász", "sheet": "res://assets/characters/archer.png", "frame_size": Vector2(16, 28),
		"start_weapon": "bow_old", "seat": 3, "weapons": "ranged",
		"bow_damage": 0.25, "bow_speed": 0.15, "multishot": 2, "move_speed": 115, "dash": true,
		"description": "Erdei vadász: 2 nyíl egyszerre, gyorsabb mozgás, Ctrl-re suhanás.",
		"role": "Távolsági harcos",
		"story": "Az erdő szélén nőtt fel, ahol a farkasok is tisztelettel kerülték. "
			+ "Fürge, és sosem hagyja, hogy a szörnyek közel érjenek.",
		"traits": [
			"Régi íjjal indul; csak íjat használhat",
			"Egyszerre 2 nyilat lő (Többlövés, legfeljebb 5)",
			"Íjjal +25% sebzés és 15%-kal gyorsabb lövés",
			"15%-kal gyorsabban mozog",
			"Suhanás [Ctrl]: a kurzor felé ugrik, a szörnyeken át (5 mp)",
		],
	},
}

static var _frames_cache := {}


static func data(id: String) -> Dictionary:
	return ALL.get(id, ALL[DEFAULT])


static func frames(id: String) -> SpriteFrames:
	if _frames_cache.has(id):
		return _frames_cache[id]
	var definition := data(id)
	var result: SpriteFrames
	if definition.has("sheet"):
		result = SpriteFrames.new()
		result.remove_animation("default")
		var texture: Texture2D = load(definition["sheet"])
		var size: Vector2 = definition["frame_size"]
		var animations := {"idle": [0, 1, 2, 3], "run": [4, 5, 6, 7], "hit": [8]}
		for anim: String in animations:
			result.add_animation(anim)
			result.set_animation_speed(anim, SpriteSheet.ANIM_FPS)
			for index: int in animations[anim]:
				var frame := AtlasTexture.new()
				frame.atlas = texture
				frame.region = Rect2(Vector2(index * size.x, 0), size)
				result.add_frame(anim, frame)
	else:
		result = SpriteSheet.character_frames(definition["rect"], true, true)
	_frames_cache[id] = result
	return result


## Felveheti-e az aktív karakter a tárgyat: a fegyverfajták karakterhez kötöttek
## ("weapons": "ranged" = csak íj, "melee" = minden, csak íj nem).
static func can_use(item: Dictionary) -> bool:
	if item.get("slot", "") != "weapon":
		return true
	var bow: bool = item.get("weapon_type", "sword") == "bow"
	return bow if data(Progress.character).get("weapons", "melee") == "ranged" else not bow


## Ember-olvasható szöveg arról, ki használhatja a fegyvert ("" ha nem fegyver).
static func weapon_restriction_text(item: Dictionary) -> String:
	if item.get("slot", "") != "weapon":
		return ""
	return "Csak íjász használhatja." if item.get("weapon_type", "") == "bow" else "Íjász nem használhatja."


## Az aktív karakter bónusza egy adott értékre (0, ha nincs).
static func bonus(key: String) -> float:
	return float(data(Progress.character).get(key, 0.0))
