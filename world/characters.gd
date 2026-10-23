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
## accuracy      a találati esély alapértéke (%): ennyi eséllyel találja el a szörnyet
## dash          van-e Suhanása (Ctrl: a kurzor felé, a szörnyeken át)
## war_cry       van-e Hadi kiáltása (Ctrl: a közeli szörnyek ellökése)
## card_bonus    szintlépési kártyák bónusza neki: stat -> többlet (pl. {"dodge": 0.25} = +25%)
## dodge / crit_chance   a kikerülés / kritikus esély alapértéke (%, alapból 10 / 2)
## dagger_damage tőrrel ennyivel nagyobbat sebez (pl. 0.25 = +25%)
## gold_bonus    ennyivel több aranyat talál (pl. 0.2 = +20%)
## summon        Vendel: Ctrl-re csontvázakat idéz (lásd Player._summon, SkeletonMinion)
## max_health    az élet alapértéke (alapból 10)
## spells        varázsló: varázspálcával a választott varázslatokat szórja (lásd Spells)
## shadow_step   van-e Árnyéklépése (Ctrl: a kurzorhoz legközelebbi szörny mögé, biztos kritikus)
## health_regen  az élet-regeneráció alapértéke (élet / mp, alapból 0.2)
## unlock        ha meg van adva: csak akkor játszható, ha ez a Progress.npc_quests jelző "done"
## role / traits / story   a bemutatkozó panel szövegei (a kocsmában, a karakter mellett)

const DEFAULT := "knight"
## Saját, egyedi fegyverfajták: aki ilyet forgat, mást nem foghat, és más nem foghatja.
const OWN_WEAPONS: Array[String] = ["wand", "shovel"]
const ALL := {
	"knight": {
		"name": "Lovag", "rect": Rect2(128, 100, 16, 28),
		"start_weapon": "sword_rusty", "seat": 0, "weapons": "melee", "accuracy": 75,
		"description": "Kiegyensúlyozott közelharcos. Rozsdás karddal indul.",
		"role": "Közelharcos",
		"story": "Egykor a királyi őrség tagja volt; most a mélység titkai után kutat. "
			+ "Nem fél belegázolni a szörnyek közé.",
		"traits": [
			"Rozsdás karddal indul",
			"Bármilyen közelharci fegyvert forgathat (kard, tőr, lándzsa, balta, buzogány)",
			"Íjat nem használhat",
			"75% találati esély",
		],
	},
	"archer": {
		"name": "Íjász", "sheet": "res://assets/characters/archer.png", "frame_size": Vector2(16, 28),
		"start_weapon": "bow_old", "seat": 3, "weapons": "ranged",
		"bow_damage": 0.25, "bow_speed": 0.15, "multishot": 2, "move_speed": 115, "dash": true,
		"accuracy": 80,
		"description": "Erdei vadász: 2 nyíl egyszerre, gyorsabb mozgás, Ctrl-re suhanás.",
		"role": "Távolsági harcos",
		"story": "Az erdő szélén nőtt fel, ahol a farkasok is tisztelettel kerülték. "
			+ "Fürge, és sosem hagyja, hogy a szörnyek közel érjenek.",
		"traits": [
			"Régi íjjal indul; csak íjat használhat",
			"Egyszerre 2 nyilat lő (Többlövés, legfeljebb 5)",
			"Íjjal +25% sebzés és 15%-kal gyorsabb lövés",
			"15%-kal gyorsabban mozog",
			"80% találati esély",
			"Suhanás [Ctrl]: a kurzor felé ugrik, a szörnyeken át (5 mp)",
		],
	},
	# Gáspár, a veterán: csak azután játszható, hogy a 30. emelet után beköltözött a kocsmába.
	"veteran": {
		"name": "Gáspár", "sheet": "res://assets/characters/veteran.png", "frame_size": Vector2(16, 28),
		"start_weapon": "sword_lavish", "seat": 5, "weapons": "melee", "unlock": "gaspar_tavern",
		"accuracy": 90, "health_regen": 0.1, "war_cry": true, "card_bonus": {"dodge": 0.25},
		"description": "A királyi őrség egykori kapitánya: pontos, de sebei lassan gyógyulnak.",
		"role": "Veterán közelharcos",
		"story": "Tizenkét évig ült a tábor szélén egy rönkön, miután a Mélység Ura megölte az embereit. "
			+ "Most, hogy a farkas elesett, újra kardot fog. A fiaiért.",
		"traits": [
			"Díszkarddal indul (ritka őrkard)",
			"Bármilyen közelharci fegyvert forgathat; íjat nem használhat",
			"90% találati esély (veterán)",
			"Sérült: csak 0.1 élet / mp regeneráció",
			"Hadi kiáltás [Ctrl]: a közelben lévő szörnyeket ellöki (7 mp)",
			"Kikerülés kártya szintlépéskor: 25%-kal többet ad neki",
		],
	},
	# Lőrinc, a varázsló: csak azután játszható, hogy a küldetései végén a kocsmába költözött.
	"wizard": {
		"name": "Lőrinc", "rect": Rect2(128, 164, 16, 28), "unlock": "lorinc_tavern",
		"start_weapon": "wand_lorinc", "seat": 6, "weapons": "wand", "accuracy": 85, "spells": true,
		"health_regen": 0.25,
		"description": "Öreg varázsló: varázsgömb, tűzgolyó, földtüskék vagy láncvillám.",
		"role": "Varázsló",
		"story": "A király egykori térképésze, aki a köveket kérdezi meg, merre vezetnek a járatok. " \
			+ "Most újra lemegy a Mélységbe, de ezúttal nem térképpel, hanem tűzzel.",
		"traits": [
			"Fix varázspálcája van, mást nem használhat",
			"A kazamatába lépve választ egy varázslatot: varázsgömb, tűzgolyó, földtüskék vagy láncvillám",
			"Minden 5. szinten fejlesztheti (legfeljebb 4. szintig), vagy megtanulhat egy másodikat (jobb egérgomb)",
			"A varázslatok Elemi sebzéssel sebeznek (csak neki van)",
			"85% találati esély, 0.25 élet / mp regeneráció",
		],
	},
	# Vendel, a csontváz sírásó: a legendás talizmán után költözik a kocsmába (a képességei még jönnek).
	"gravedigger": {
		# Oldalnézet (jobbra néz; balra tükrözve), hogy a kurzor felé forduljon.
		"name": "Vendel", "sheet": "res://assets/characters/gravedigger_side.png", "frame_size": Vector2(24, 32),
		"animations": {"idle": [1], "run": [0, 1, 2, 3], "hit": [1]},
		"start_weapon": "shovel_vendel", "seat": 1, "weapons": "shovel", "unlock": "vendel_tavern", "accuracy": 80,
		"max_health": 9, "dodge": 20, "move_speed": 86, "card_bonus": {"attack_speed": 0.15}, "summon": true,
		"description": "Csontváz sírásó: a halottak földjéről jött vissza, hogy hazahozza a többieket.",
		"role": "Élőhalott sírásó",
		"story": "Húsz évig temette a Mélység halottait a tábor szélén. Most, egy legendás talizmánnal a nyakában, " \
			+ "újra lemegy: nem meghalni, hanem hazahozni, akit lehet.",
		"traits": [
			"A saját ásójával harcol, mást nem használhat: magától üt, ha egy szörny túl közel ér; lassú és gyenge, de nagyon messzire lök",
			"Csak 9 élettel indul (csontváz), 80% találati esély, 20% kikerülés",
			"14%-kal lassabban mozog",
			"Ütési sebesség kártya szintlépéskor: 15%-kal többet ad neki",
			"Csontváz-idézés [Ctrl]: 3 csontváz kel ki a földből, és érte harcol (legfeljebb 6 egyszerre; 3 mp, az ütési sebességgel rövidül). Olyan gyorsak, mint ő, és átjutnak a harc közbeni zárakon",
		],
	},
	# Bence, a volt tolvaj (Benedek zászlóvivő fia): a levél-küldetés után költözik a kocsmába.
	"thief": {
		"name": "Bence", "sheet": "res://assets/characters/thief.png", "frame_size": Vector2(16, 28),
		"start_weapon": "dagger_curved", "seat": 4, "weapons": "melee", "unlock": "thief_tavern",
		"accuracy": 85, "move_speed": 110, "dodge": 18, "crit_chance": 8, "dagger_damage": 0.25,
		"gold_bonus": 0.2, "shadow_step": true,
		"description": "Fürge tolvaj: tőrrel halálos, és a szörnyek háta mögé lép.",
		"role": "Árnyékjáró tolvaj",
		"story": "Benedek zászlóvivő fia. Az apja után ment a Mélységbe, és a tizedik emeleten tanult meg " \
			+ "túlélni. Évekig lopott a városiaktól; most újra lemegy, de ezúttal nem egyedül.",
		"traits": [
			"Görbe késsel indul; közelharci fegyvert forgathat, íjat nem",
			"Tőrrel +25% sebzés",
			"18% kikerülés, 8% kritikus esély, 85% találati esély",
			"10%-kal gyorsabban mozog, 20%-kal több aranyat talál",
			"Árnyéklépés [Ctrl]: a kurzorhoz legközelebbi szörny háta mögé lép, a következő ütése biztos kritikus (6 mp)",
		],
	},
}


## Játszható-e már a karakter ("unlock": egy Progress.npc_quests jelző, aminek "done"-nak kell lennie).
static func is_unlocked(id: String) -> bool:
	var unlock: String = data(id).get("unlock", "")
	return unlock.is_empty() or Progress.npc_quest_state(unlock) == "done"

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
		# Alapból 0-3 álló, 4-7 futás, 8 sebződés; a karakter "animations"-szel felülírhatja.
		var animations: Dictionary = definition.get("animations", {"idle": [0, 1, 2, 3], "run": [4, 5, 6, 7], "hit": [8]})
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
	var kind: String = data(Progress.character).get("weapons", "melee")
	# A varázspálca csak a varázslóé, az ásó csak Vendelé, és ők mást nem foghatnak.
	var weapon_type: String = item.get("weapon_type", "")
	if kind in OWN_WEAPONS or weapon_type in OWN_WEAPONS:
		return kind == weapon_type
	var bow: bool = Items.is_ranged(item)
	return bow if kind == "ranged" else not bow


## Ember-olvasható szöveg arról, ki használhatja a fegyvert ("" ha nem fegyver).
static func weapon_restriction_text(item: Dictionary) -> String:
	if item.get("slot", "") != "weapon":
		return ""
	if item.get("weapon_type", "") == "wand":
		return "Csak a varázsló használhatja."
	if item.get("weapon_type", "") == "shovel":
		return "Csak Vendel használhatja."
	return "Csak íjász használhatja." if Items.is_ranged(item) else "Íjász és varázsló nem használhatja."


## Az aktív karakter bónusza egy adott értékre (0, ha nincs).
static func bonus(key: String) -> float:
	return float(data(Progress.character).get(key, 0.0))
