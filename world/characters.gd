class_name Characters
## Játszható karakterek. A kocsmában ülnek a saját helyükön; odamész és E-t nyomsz,
## átveszed az irányítást. Mindegyiknek külön tábori fejlesztései és tábori felszerelése
## van (lásd Progress), saját kezdőfegyvere és esetleges bónusza.
##
## rect          a 0x72 lapról: az álló animáció első kockája (utána futás, aztán sebződés)
## sheet         saját kép (16x28-as kockák: 0-3 álló, 4-7 futás, 8 sebződés)
## seat          melyik kocsmai széken ül, amikor nem ő az aktív karakter
## bow_damage    íjjal ennyivel nagyobbat sebez (szorzó-bónusz, pl. 0.25 = +25%)
## bow_speed     íjjal ennyivel gyorsabban lő (pl. 0.15 = 15%-kal rövidebb cooldown)

const DEFAULT := "knight"
const ALL := {
	"knight": {
		"name": "Lovag", "rect": Rect2(128, 100, 16, 28),
		"start_weapon": "sword_rusty", "seat": 0,
		"description": "Kiegyensúlyozott közelharcos. Rozsdás karddal indul.",
	},
	"archer": {
		"name": "Íjász", "sheet": "res://assets/characters/archer.png", "frame_size": Vector2(16, 28),
		"start_weapon": "bow_old", "seat": 3, "bow_damage": 0.25, "bow_speed": 0.15,
		"description": "Erdei vadász. Régi íjjal indul; íjjal +25% sebzés és 15%-kal gyorsabb lövés.",
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


## Az aktív karakter bónusza egy adott értékre (0, ha nincs).
static func bonus(key: String) -> float:
	return float(data(Progress.character).get(key, 0.0))
