class_name EnemyTypes
## Ellenségtípusok. Minden stat egy [min, max] tartomány: spawnoláskor
## mindegyik ellenség véletlen értéket kap belőle (lásd `roll`), így két
## ugyanolyan ellenség sem egyforma.
##
## rect      az idle első képkockája a sprite-lapon
## run       van-e külön futás-animáció
## health    életerő
## damage    érintéskor ennyit sebez
## speed     mozgási sebesség (pixel / mp)
## dodge     ennyi % eséllyel kikerüli a találatot
## knockback ennyire löki hátra a játékost
## resist    0..1, mennyire áll ellen a hátralökésnek (1 = meg sem mozdul)
## xp        ennyi XP-t ad
## min_depth ettől az emelettől jelenhet meg
## weight    milyen gyakran jön (nagyobb = gyakoribb)
##
## Távolsági ellenségnél ("ranged": true) a sebzés a lövedéké, érintésre csak 1-et sebez:
## fire_interval  két lövés között eltelt idő (mp)
## arrow_speed    a lövedék sebessége (pixel / mp)
## keep_distance  ilyen távolságot próbál tartani a játékostól (pixel)
## projectile     "arrow" (nyíl) vagy "magic" (varázslövedék); weapon_region: a kézben tartott fegyver képe
##
## Különleges képességek:
## dash: true          néha rövid felvillanás után nekirohan a játékosnak
## splits_into / split_count   halálakor ennyi kisebb ellenségre oszlik
## shots / spread      legyezőlövés: egyszerre ennyi lövedék, ennyi fokonként szétterítve
## tint                a sprite színezése (ugyanaz a figura más kinézettel)
## abilities           további képességek listája, lásd EnemyAbilities (zigzag, teleport,
##                     summon, heal, war_cry, berserk, death_burst, regenerate, poison,
##                     frost, plunder, shield, explode)
## mimic: true         ládának álcázva alszik, amíg közel nem mész vagy meg nem ütöd
## sheet               saját sprite-lap (rect = egy képkocka mérete), lásd Enemy._own_frames
## gold                halálakor ennyi aranyat dob ([min, max])

const TYPES: Array[Dictionary] = [
	# 1. emelettől
	{"name": "tiny_zombie", "rect": Rect2(368, 16, 16, 16), "run": true,
		"health": [2, 3], "damage": [1, 1], "speed": [70, 90], "dodge": [0, 0],
		"knockback": [250, 280], "resist": [0.0, 0.0], "xp": [1, 1], "min_depth": 1, "weight": 3},
	{"name": "goblin", "abilities": ["zigzag", "plunder"], "rect": Rect2(368, 40, 16, 16), "run": true,
		"health": [1, 3], "damage": [1, 1], "speed": [100, 125], "dodge": [0, 5],
		"knockback": [220, 260], "resist": [0.0, 0.0], "xp": [1, 2], "min_depth": 1, "weight": 3},
	{"name": "skelet", "rect": Rect2(368, 88, 16, 16), "run": true,
		"health": [3, 4], "damage": [1, 1], "speed": [60, 80], "dodge": [10, 20],
		"knockback": [250, 280], "resist": [0.0, 0.1], "xp": [2, 2], "min_depth": 1, "weight": 3},
	{"name": "tiny_slug", "rect": Rect2(432, 376, 16, 16), "run": false,
		"health": [1, 2], "damage": [1, 1], "speed": [60, 75], "dodge": [0, 0],
		"knockback": [180, 200], "resist": [0.0, 0.0], "xp": [1, 1], "min_depth": 1, "weight": 2},
	# 2. emelettől
	# Mimik: ládának álcázott szörny (saját rajz a 0x72 mimik-ládájából, lábakkal).
	{"name": "mimic", "sheet": "res://assets/enemies/mimic.png", "rect": Rect2(0, 0, 16, 24),
		"run": true, "mimic": true, "gold": [8, 14],
		"health": [6, 9], "damage": [2, 3], "speed": [100, 120], "dodge": [0, 5],
		"knockback": [260, 300], "resist": [0.3, 0.5], "xp": [4, 4], "min_depth": 2, "weight": 1},
	{"name": "archer", "rect": Rect2(128, 36, 16, 28), "run": true, "ranged": true,
		"health": [3, 5], "damage": [1, 2], "speed": [70, 90], "dodge": [5, 15],
		"knockback": [140, 170], "resist": [0.0, 0.1], "xp": [3, 3], "min_depth": 2, "weight": 2,
		"fire_interval": [1.6, 2.4], "arrow_speed": [260, 320], "keep_distance": [170, 240]},
	{"name": "imp", "abilities": ["teleport"], "rect": Rect2(368, 64, 16, 16), "run": true,
		"health": [2, 3], "damage": [1, 2], "speed": [120, 145], "dodge": [0, 0],
		"knockback": [200, 240], "resist": [0.0, 0.0], "xp": [2, 2], "min_depth": 2, "weight": 2},
	{"name": "muddy", "abilities": ["regenerate"], "rect": Rect2(368, 112, 16, 16), "run": false,
		"health": [5, 7], "damage": [1, 1], "speed": [40, 55], "dodge": [0, 10],
		"knockback": [300, 340], "resist": [0.4, 0.6], "xp": [2, 3], "min_depth": 2, "weight": 2},
	{"name": "orc_warrior", "abilities": ["berserk"], "rect": Rect2(368, 177, 16, 23), "run": true,
		"health": [5, 7], "damage": [2, 2], "speed": [80, 95], "dodge": [5, 15],
		"knockback": [280, 320], "resist": [0.2, 0.3], "xp": [3, 3], "min_depth": 2, "weight": 2},
	{"name": "slug", "rect": Rect2(368, 369, 16, 23), "run": false,
		"health": [5, 7], "damage": [1, 2], "speed": [40, 50], "dodge": [0, 0],
		"knockback": [250, 280], "resist": [0.3, 0.5], "xp": [3, 3], "min_depth": 2, "weight": 2,
		"splits_into": "tiny_slug", "split_count": 2},
	{"name": "zombie", "abilities": ["regenerate"], "rect": Rect2(368, 136, 16, 16), "run": false,
		"health": [6, 8], "damage": [1, 2], "speed": [45, 55], "dodge": [0, 5],
		"knockback": [280, 320], "resist": [0.3, 0.4], "xp": [2, 3], "min_depth": 2, "weight": 2},
	# 3. emelettől
	{"name": "pumpkin_dude", "abilities": ["death_burst"], "rect": Rect2(368, 321, 16, 23), "run": true,
		"health": [4, 6], "damage": [2, 2], "speed": [115, 135], "dodge": [5, 10],
		"knockback": [240, 280], "resist": [0.1, 0.2], "xp": [3, 4], "min_depth": 3, "weight": 2},
	{"name": "lizard", "rect": Rect2(128, 228, 16, 28), "run": true, "dash": true,
		"health": [6, 8], "damage": [2, 3], "speed": [80, 95], "dodge": [10, 15],
		"knockback": [300, 340], "resist": [0.2, 0.3], "xp": [4, 5], "min_depth": 3, "weight": 2},
	{"name": "wogol", "abilities": ["zigzag"], "rect": Rect2(368, 249, 16, 23), "run": true,
		"health": [4, 6], "damage": [2, 2], "speed": [95, 115], "dodge": [0, 10],
		"knockback": [260, 300], "resist": [0.1, 0.2], "xp": [3, 3], "min_depth": 3, "weight": 2},
	{"name": "swampy", "abilities": ["regenerate", "poison"], "rect": Rect2(432, 112, 16, 16), "run": false,
		"health": [6, 9], "damage": [1, 2], "speed": [45, 60], "dodge": [0, 0],
		"knockback": [320, 360], "resist": [0.4, 0.6], "xp": [3, 3], "min_depth": 3, "weight": 2},
	{"name": "masked_orc", "abilities": ["berserk"], "rect": Rect2(368, 153, 16, 23), "run": true,
		"health": [6, 8], "damage": [2, 3], "speed": [70, 85], "dodge": [15, 25],
		"knockback": [300, 340], "resist": [0.3, 0.4], "xp": [4, 4], "min_depth": 3, "weight": 2},
	{"name": "chort", "abilities": ["teleport", "zigzag"], "rect": Rect2(368, 273, 16, 23), "run": true,
		"health": [4, 5], "damage": [2, 3], "speed": [125, 145], "dodge": [0, 5],
		"knockback": [240, 280], "resist": [0.0, 0.1], "xp": [4, 4], "min_depth": 3, "weight": 2},
	{"name": "huntress", "rect": Rect2(128, 4, 16, 28), "run": true, "ranged": true,
		"shots": 3, "spread": 16.0,
		"health": [3, 5], "damage": [1, 2], "speed": [85, 100], "dodge": [10, 20],
		"knockback": [140, 170], "resist": [0.0, 0.1], "xp": [4, 4], "min_depth": 3, "weight": 1,
		"fire_interval": [2.4, 3.2], "arrow_speed": [240, 290], "keep_distance": [190, 250]},
	{"name": "plague_doctor", "abilities": ["death_burst", "poison"], "rect": Rect2(368, 345, 16, 23), "run": true,
		"health": [5, 7], "damage": [2, 3], "speed": [75, 90], "dodge": [5, 15],
		"knockback": [260, 300], "resist": [0.1, 0.2], "xp": [4, 5], "min_depth": 3, "weight": 2},
	# 4. emelettől
	{"name": "lizard_scout", "rect": Rect2(128, 196, 16, 28), "run": true, "dash": true,
		"health": [5, 7], "damage": [2, 3], "speed": [110, 130], "dodge": [20, 30],
		"knockback": [260, 300], "resist": [0.1, 0.2], "xp": [5, 5], "min_depth": 4, "weight": 2},
	{"name": "ice_zombie", "abilities": ["death_burst", "frost"], "rect": Rect2(432, 136, 16, 16), "run": false,
		"health": [7, 10], "damage": [2, 2], "speed": [50, 65], "dodge": [10, 20],
		"knockback": [300, 340], "resist": [0.3, 0.5], "xp": [4, 4], "min_depth": 4, "weight": 2},
	{"name": "orc_shaman", "abilities": ["war_cry", "shield"], "rect": Rect2(368, 201, 16, 23), "run": true,
		"health": [6, 8], "damage": [2, 3], "speed": [70, 85], "dodge": [5, 15],
		"knockback": [280, 320], "resist": [0.2, 0.3], "xp": [4, 5], "min_depth": 4, "weight": 2},
	{"name": "necromancer", "abilities": ["summon"], "rect": Rect2(368, 225, 16, 23), "run": false,
		"health": [5, 7], "damage": [3, 3], "speed": [60, 75], "dodge": [0, 10],
		"knockback": [300, 340], "resist": [0.1, 0.2], "xp": [5, 5], "min_depth": 4, "weight": 1},
	{"name": "big_zombie", "abilities": ["regenerate"], "rect": Rect2(16, 332, 32, 36), "run": true,
		"health": [12, 16], "damage": [3, 3], "speed": [50, 60], "dodge": [10, 20],
		"knockback": [380, 420], "resist": [0.7, 0.85], "xp": [8, 8], "min_depth": 4, "weight": 1},
	{"name": "angel", "abilities": ["heal"], "rect": Rect2(368, 304, 16, 16), "run": true,
		"health": [4, 6], "damage": [2, 3], "speed": [130, 150], "dodge": [20, 30],
		"knockback": [220, 260], "resist": [0.0, 0.1], "xp": [4, 5], "min_depth": 4, "weight": 2},
	{"name": "dark_mage", "rect": Rect2(128, 164, 16, 28), "run": true, "ranged": true,
		"projectile": "magic", "weapon_region": Rect2(324, 129, 8, 30),
		"health": [4, 6], "damage": [2, 3], "speed": [60, 75], "dodge": [5, 10],
		"knockback": [150, 180], "resist": [0.0, 0.1], "xp": [5, 5], "min_depth": 4, "weight": 2,
		"fire_interval": [2.0, 2.8], "arrow_speed": [200, 240], "keep_distance": [200, 260]},
	# 5-6. emelettől
	{"name": "dwarf", "abilities": ["berserk"], "rect": Rect2(128, 292, 16, 28), "run": true,
		"health": [12, 16], "damage": [3, 4], "speed": [65, 75], "dodge": [5, 10],
		"knockback": [420, 480], "resist": [0.6, 0.75], "xp": [6, 7], "min_depth": 5, "weight": 1},
	{"name": "fire_witch", "rect": Rect2(128, 132, 16, 28), "run": true, "ranged": true,
		"projectile": "magic", "weapon_region": Rect2(324, 129, 8, 30), "shots": 5, "spread": 18.0,
		"tint": Color(1.0, 0.75, 0.6),
		"health": [6, 8], "damage": [2, 3], "speed": [60, 75], "dodge": [5, 15],
		"knockback": [150, 180], "resist": [0.0, 0.1], "xp": [7, 8], "min_depth": 5, "weight": 1,
		"fire_interval": [3.0, 3.8], "arrow_speed": [180, 220], "keep_distance": [220, 280]},
	{"name": "fallen_knight", "rect": Rect2(128, 68, 16, 28), "run": true, "dash": true,
		"tint": Color(0.45, 0.4, 0.55),
		"health": [14, 18], "damage": [3, 4], "speed": [70, 80], "dodge": [20, 30],
		"knockback": [400, 450], "resist": [0.6, 0.7], "xp": [8, 9], "min_depth": 5, "weight": 1},
	{"name": "dwarf_berserker", "abilities": ["berserk"], "rect": Rect2(128, 260, 16, 28), "run": true,
		"tint": Color(1.0, 0.7, 0.7),
		"health": [10, 13], "damage": [4, 5], "speed": [95, 110], "dodge": [0, 5],
		"knockback": [420, 480], "resist": [0.5, 0.6], "xp": [8, 8], "min_depth": 6, "weight": 1},
	{"name": "ogre", "abilities": ["war_cry"], "rect": Rect2(16, 380, 32, 36), "run": true,
		"health": [16, 20], "damage": [3, 4], "speed": [55, 65], "dodge": [15, 25],
		"knockback": [400, 450], "resist": [0.8, 0.9], "xp": [10, 10], "min_depth": 5, "weight": 1},
	{"name": "big_demon", "abilities": ["death_burst"], "rect": Rect2(16, 428, 32, 36), "run": true,
		"health": [20, 26], "damage": [4, 5], "speed": [65, 75], "dodge": [15, 25],
		"knockback": [420, 480], "resist": [0.85, 0.95], "xp": [12, 14], "min_depth": 6, "weight": 1},
	# --- Csak az 5. emelettől: erősebb, nagyobb szörnyek (MiniWorld Sprites, CC0) ---
	# sheet: 8 kockás sáv (0-3 álló, 4-7 futás); size: ennyiszer nagyobb a sima méretnél.
	{"name": "minotaur", "abilities": ["berserk"], "dash": true,
		"sheet": "res://assets/enemies/minotaur.png", "rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.8,
		"health": [24, 30], "damage": [5, 6], "speed": [80, 95], "dodge": [5, 10],
		"knockback": [460, 520], "resist": [0.75, 0.85], "xp": [14, 16], "min_depth": 5, "weight": 2},
	{"name": "yeti", "abilities": ["regenerate", "war_cry", "frost"],
		"sheet": "res://assets/enemies/yeti.png", "rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.9,
		"health": [30, 38], "damage": [5, 6], "speed": [60, 70], "dodge": [0, 5],
		"knockback": [480, 540], "resist": [0.85, 0.95], "xp": [15, 17], "min_depth": 5, "weight": 2},
	{"name": "wendigo", "abilities": ["teleport", "zigzag"],
		"sheet": "res://assets/enemies/wendigo.png", "rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.7,
		"health": [18, 22], "damage": [5, 6], "speed": [120, 140], "dodge": [15, 25],
		"knockback": [380, 420], "resist": [0.5, 0.6], "xp": [13, 15], "min_depth": 5, "weight": 2},
	{"name": "armored_demon", "abilities": ["berserk", "death_burst", "shield"], "ranged": true,
		"projectile": "magic", "weapon_region": Rect2(324, 129, 8, 30), "shots": 3, "spread": 15.0,
		"sheet": "res://assets/enemies/armored_demon.png", "rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.7,
		"health": [22, 28], "damage": [4, 5], "speed": [65, 80], "dodge": [10, 15],
		"knockback": [300, 340], "resist": [0.6, 0.7], "xp": [15, 17], "min_depth": 5, "weight": 2,
		"fire_interval": [2.2, 3.0], "arrow_speed": [220, 260], "keep_distance": [200, 260]},
	{"name": "skeleton_legionary", "abilities": ["summon"],
		"sheet": "res://assets/enemies/skeleton_legionary.png", "rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.6,
		"health": [20, 26], "damage": [4, 5], "speed": [75, 90], "dodge": [20, 30],
		"knockback": [360, 400], "resist": [0.5, 0.6], "xp": [14, 16], "min_depth": 5, "weight": 2},
	# --- Csak a 10. emelettől: a mélység urai (MiniWorld Sprites, CC0) ---
	{"name": "mammoth", "abilities": ["war_cry"], "dash": true,
		"sheet": "res://assets/enemies/mammoth.png", "rect": Rect2(0, 0, 16, 16), "run": true, "size": 2.2,
		"health": [40, 50], "damage": [6, 7], "speed": [70, 85], "dodge": [0, 5],
		"knockback": [520, 580], "resist": [0.9, 0.95], "xp": [20, 22], "min_depth": 10, "weight": 2},
	{"name": "giant_crab", "abilities": ["regenerate", "berserk"],
		"sheet": "res://assets/enemies/giant_crab.png", "rect": Rect2(0, 0, 16, 16), "run": true, "size": 2.0,
		"health": [36, 44], "damage": [6, 7], "speed": [55, 70], "dodge": [5, 10],
		"knockback": [440, 480], "resist": [0.85, 0.95], "xp": [18, 20], "min_depth": 10, "weight": 2},
	{"name": "lich", "abilities": ["summon", "teleport", "frost"], "ranged": true,
		"projectile": "magic", "weapon_region": Rect2(324, 129, 8, 30), "shots": 3, "spread": 20.0,
		"sheet": "res://assets/enemies/lich.png", "rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.8,
		"health": [26, 32], "damage": [5, 6], "speed": [60, 75], "dodge": [15, 25],
		"knockback": [260, 300], "resist": [0.5, 0.6], "xp": [20, 22], "min_depth": 10, "weight": 2,
		"fire_interval": [2.2, 3.0], "arrow_speed": [220, 260], "keep_distance": [220, 280]},
	{"name": "purple_demon", "abilities": ["teleport", "death_burst"], "dash": true,
		"sheet": "res://assets/enemies/purple_demon.png", "rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.8,
		"health": [30, 36], "damage": [6, 7], "speed": [110, 130], "dodge": [20, 30],
		"knockback": [380, 420], "resist": [0.6, 0.7], "xp": [19, 21], "min_depth": 10, "weight": 2},
	# A sárkányfióka tűzcsóvát köp (5 lövedékes legyező); nincs a kezében bot ("no_weapon").
	{"name": "fire_dragon", "abilities": ["zigzag"], "ranged": true, "no_weapon": true,
		"projectile": "magic", "weapon_region": Rect2(324, 129, 8, 30), "shots": 5, "spread": 14.0,
		"sheet": "res://assets/enemies/fire_dragon.png", "rect": Rect2(0, 0, 32, 32), "run": true, "size": 1.1,
		"health": [32, 40], "damage": [6, 7], "speed": [90, 105], "dodge": [15, 25],
		"knockback": [300, 340], "resist": [0.6, 0.7], "xp": [22, 24], "min_depth": 10, "weight": 2,
		"fire_interval": [2.6, 3.4], "arrow_speed": [230, 270], "keep_distance": [200, 260]},
	# --- Új szörnyek (MiniWorld Sprites, CC0): nyálkák, goblinok, kalózok, sárkányok ---
	{"name": "green_slime", "abilities": ["poison"],
		"sheet": "res://assets/enemies/green_slime.png", "rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.2,
		"health": [5, 7], "damage": [1, 2], "speed": [55, 70], "dodge": [0, 5],
		"knockback": [200, 240], "resist": [0.1, 0.2], "xp": [2, 3], "min_depth": 2, "weight": 2},
	{"name": "spear_goblin", "abilities": ["poison"], "dash": true,
		"sheet": "res://assets/enemies/spear_goblin.png", "rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.2,
		"health": [6, 8], "damage": [2, 2], "speed": [80, 95], "dodge": [5, 10],
		"knockback": [240, 280], "resist": [0.1, 0.2], "xp": [3, 3], "min_depth": 2, "weight": 2},
	{"name": "kamikaze_goblin", "abilities": ["explode", "zigzag"],
		"sheet": "res://assets/enemies/kamikaze_goblin.png", "rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.2,
		"health": [3, 4], "damage": [2, 3], "speed": [125, 145], "dodge": [5, 10],
		"knockback": [200, 240], "resist": [0.0, 0.1], "xp": [3, 3], "min_depth": 3, "weight": 2},
	{"name": "pirate_grunt", "abilities": ["plunder"],
		"sheet": "res://assets/enemies/pirate_grunt.png", "rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.3,
		"health": [9, 12], "damage": [2, 3], "speed": [75, 90], "dodge": [5, 15],
		"knockback": [260, 300], "resist": [0.2, 0.3], "xp": [4, 4], "min_depth": 3, "weight": 2},
	{"name": "pirate_gunner", "abilities": ["plunder"], "ranged": true, "no_weapon": true,
		"sheet": "res://assets/enemies/pirate_gunner.png", "rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.3,
		"health": [7, 9], "damage": [2, 3], "speed": [60, 75], "dodge": [5, 15],
		"knockback": [160, 200], "resist": [0.1, 0.2], "xp": [4, 5], "min_depth": 4, "weight": 2,
		"fire_interval": [1.8, 2.4], "arrow_speed": [280, 320], "keep_distance": [180, 240]},
	{"name": "frost_slime", "abilities": ["frost", "regenerate"],
		"sheet": "res://assets/enemies/frost_slime.png", "rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.4,
		"health": [9, 11], "damage": [2, 3], "speed": [55, 70], "dodge": [0, 5],
		"knockback": [260, 300], "resist": [0.3, 0.4], "xp": [4, 4], "min_depth": 4, "weight": 2},
	{"name": "pirate_captain", "abilities": ["plunder", "shield", "war_cry"],
		"sheet": "res://assets/enemies/pirate_captain.png", "rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.6,
		"health": [18, 22], "damage": [4, 5], "speed": [80, 95], "dodge": [10, 20],
		"knockback": [360, 400], "resist": [0.5, 0.6], "xp": [10, 11], "min_depth": 6, "weight": 1},
	# --- Bogarak ---
	# Légy: gyenge, de gyors és cikázik (rajzolt sprite, 2 szárnycsapás-kocka).
	# Kazamatapók (bogár): kicsi, gyors, mérges.
	{"name": "spider", "abilities": ["poison", "zigzag"], "sheet": "res://assets/enemies/spider.png",
		"rect": Rect2(0, 0, 12, 20), "run": true, "size": 1.1,
		"health": [3, 4], "damage": [1, 2], "speed": [115, 135], "dodge": [15, 25],
		"knockback": [160, 200], "resist": [0.0, 0.1], "xp": [2, 3], "min_depth": 3, "weight": 2},
	# Újabb szörnyek (MiniWorld Sprites, CC0): gyűjtögető goblin, ork martalóc, barbár, lángnindzsa,
	# hitehagyott szerzetes.
	{"name": "farmer_goblin", "abilities": ["plunder"], "sheet": "res://assets/enemies/farmer_goblin.png",
		"rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.2,
		"health": [4, 6], "damage": [1, 2], "speed": [85, 100], "dodge": [5, 10],
		"knockback": [220, 260], "resist": [0.1, 0.2], "xp": [2, 3], "min_depth": 1, "weight": 2},
	{"name": "orc_raider", "abilities": ["berserk"], "sheet": "res://assets/enemies/orc_raider.png",
		"rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.4,
		"health": [11, 14], "damage": [3, 4], "speed": [80, 95], "dodge": [5, 10],
		"knockback": [340, 380], "resist": [0.35, 0.45], "xp": [6, 7], "min_depth": 5, "weight": 2},
	{"name": "barbarian", "abilities": ["war_cry", "berserk"], "dash": true, "sheet": "res://assets/enemies/barbarian.png",
		"rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.5,
		"health": [18, 22], "damage": [4, 5], "speed": [85, 100], "dodge": [5, 10],
		"knockback": [420, 470], "resist": [0.55, 0.65], "xp": [10, 12], "min_depth": 8, "weight": 1},
	{"name": "fire_ninja", "abilities": ["teleport", "zigzag"], "dash": true, "sheet": "res://assets/enemies/fire_ninja.png",
		"rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.3,
		"health": [9, 12], "damage": [4, 5], "speed": [130, 150], "dodge": [30, 40],
		"knockback": [200, 240], "resist": [0.2, 0.3], "xp": [10, 12], "min_depth": 11, "weight": 1},
	{"name": "renegade_monk", "abilities": ["heal", "shield"], "dash": true, "sheet": "res://assets/enemies/renegade_monk.png",
		"rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.35,
		"health": [16, 20], "damage": [4, 6], "speed": [95, 110], "dodge": [20, 30],
		"knockback": [360, 400], "resist": [0.45, 0.55], "xp": [12, 14], "min_depth": 14, "weight": 1},
	{"name": "fly", "abilities": ["zigzag"],
		"sheet": "res://assets/enemies/fly.png", "rect": Rect2(0, 0, 16, 16), "run": true, "size": 0.9,
		"health": [2, 3], "damage": [1, 1], "speed": [135, 155], "dodge": [20, 30],
		"knockback": [120, 150], "resist": [0.0, 0.0], "xp": [1, 2], "min_depth": 2, "weight": 3},
	# --- Még több szörny (MiniWorld Sprites, CC0) ---
	{"name": "club_goblin", "abilities": ["berserk"], "dash": true,
		"sheet": "res://assets/enemies/club_goblin.png", "rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.3,
		"health": [8, 10], "damage": [2, 3], "speed": [80, 95], "dodge": [5, 10],
		"knockback": [280, 320], "resist": [0.2, 0.3], "xp": [3, 4], "min_depth": 2, "weight": 2},
	{"name": "archer_goblin", "abilities": ["zigzag", "plunder"], "ranged": true, "no_weapon": true,
		"sheet": "res://assets/enemies/archer_goblin.png", "rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.3,
		"health": [5, 7], "damage": [2, 2], "speed": [80, 95], "dodge": [10, 15],
		"knockback": [150, 180], "resist": [0.0, 0.1], "xp": [3, 4], "min_depth": 3, "weight": 2,
		"fire_interval": [1.4, 2.0], "arrow_speed": [280, 320], "keep_distance": [170, 230]},
	{"name": "orc_mage", "abilities": ["shield", "heal"], "ranged": true, "no_weapon": true,
		"projectile": "magic", "weapon_region": Rect2(324, 129, 8, 30), "shots": 3, "spread": 16.0,
		"sheet": "res://assets/enemies/orc_mage.png", "rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.5,
		"health": [12, 15], "damage": [3, 4], "speed": [55, 70], "dodge": [5, 10],
		"knockback": [200, 240], "resist": [0.2, 0.3], "xp": [7, 8], "min_depth": 5, "weight": 2,
		"fire_interval": [2.2, 2.8], "arrow_speed": [220, 260], "keep_distance": [200, 260]},
	{"name": "red_demon", "abilities": ["teleport", "berserk", "death_burst"], "dash": true,
		"sheet": "res://assets/enemies/red_demon.png", "rect": Rect2(0, 0, 16, 16), "run": true, "size": 1.6,
		"health": [20, 24], "damage": [5, 6], "speed": [100, 115], "dodge": [10, 20],
		"knockback": [340, 380], "resist": [0.5, 0.6], "xp": [13, 15], "min_depth": 8, "weight": 2},
	{"name": "gold_dragon", "abilities": ["plunder", "shield"], "ranged": true, "no_weapon": true,
		"projectile": "magic", "weapon_region": Rect2(324, 129, 8, 30), "shots": 4, "spread": 15.0,
		"sheet": "res://assets/enemies/gold_dragon.png", "rect": Rect2(0, 0, 32, 32), "run": true, "size": 1.15,
		"health": [38, 46], "damage": [6, 7], "speed": [95, 110], "dodge": [15, 25],
		"knockback": [320, 360], "resist": [0.65, 0.75], "xp": [25, 27], "min_depth": 14, "weight": 2,
		"fire_interval": [2.4, 3.2], "arrow_speed": [240, 280], "keep_distance": [200, 260]},
	# Az óriás csontváz ("Skeletons Rework", CC0): lassú, nagyon szívós, csontvázakat idéz,
	# rohamra hívja őket, és halálakor szétrepülnek a csontjai.
	{"name": "giant_skeleton", "abilities": ["summon", "war_cry", "death_burst"],
		"sheet": "res://assets/enemies/giant_skeleton.png", "rect": Rect2(0, 0, 24, 32), "run": true, "size": 1.7,
		"health": [34, 42], "damage": [5, 6], "speed": [50, 62], "dodge": [0, 5],
		"knockback": [480, 540], "resist": [0.85, 0.95], "xp": [16, 18], "min_depth": 7, "weight": 1},
	{"name": "frost_dragon", "abilities": ["frost", "zigzag"], "ranged": true, "no_weapon": true,
		"projectile": "magic", "weapon_region": Rect2(324, 129, 8, 30), "shots": 3, "spread": 16.0,
		"sheet": "res://assets/enemies/frost_dragon.png", "rect": Rect2(0, 0, 32, 32), "run": true, "size": 1.1,
		"health": [34, 42], "damage": [6, 7], "speed": [90, 105], "dodge": [15, 25],
		"knockback": [300, 340], "resist": [0.6, 0.7], "xp": [23, 25], "min_depth": 12, "weight": 2,
		"fire_interval": [2.4, 3.2], "arrow_speed": [230, 270], "keep_distance": [200, 260]},
	{"name": "shadow_dragon", "abilities": ["poison", "shield"], "ranged": true, "no_weapon": true,
		"projectile": "magic", "weapon_region": Rect2(324, 129, 8, 30), "shots": 5, "spread": 14.0,
		"sheet": "res://assets/enemies/shadow_dragon.png", "rect": Rect2(0, 0, 32, 32), "run": true, "size": 1.2,
		"health": [40, 48], "damage": [7, 8], "speed": [95, 110], "dodge": [20, 30],
		"knockback": [320, 360], "resist": [0.7, 0.8], "xp": [26, 28], "min_depth": 15, "weight": 2,
		"fire_interval": [2.6, 3.4], "arrow_speed": [240, 280], "keep_distance": [200, 260]},
]

## A 10. és a 21. emelettől a szörnyek hirtelen sokkal erősebbek: az addigi (emeletenkénti)
## erősödés után ezekkel a szorzókkal (két ugrásnál kétszer); innen nőnek tovább emeletenként.
const SURGE_DEPTH := 10
const SURGE_DEPTHS: Array[int] = [10, 21]
const SURGE_HEALTH := 1.6
const SURGE_DAMAGE := 1.35
const SURGE_DODGE := 5
const SURGE_XP := 1.5

## Erősödés emeletenként (az 1. emelethez képest):
## HP +60%, sebzés +0.6 (lefelé kerekítve, kb. 5 emeletenként +3), sebesség +3.5%
## (legfeljebb +50%), kikerülés +1%, lövés +4%-kal gyakrabban (legfeljebb +40%), XP +20%.
const HEALTH_PER_DEPTH := 0.6
const DAMAGE_PER_DEPTH := 0.6
const SPEED_PER_DEPTH := 0.035
const MAX_SPEED_BONUS := 0.5
const DODGE_PER_DEPTH := 1
const FIRE_RATE_PER_DEPTH := 0.04
const MAX_FIRE_RATE_BONUS := 0.4
const XP_PER_DEPTH := 0.2


## Hány hirtelen erősödésen van túl ez az emelet (0, 1 vagy 2).
static func surges(depth: int) -> int:
	var count := 0
	for surge_depth in SURGE_DEPTHS:
		if depth >= surge_depth:
			count += 1
	return count


static func by_name(type_name: String) -> Dictionary:
	for type in TYPES:
		if type["name"] == type_name:
			return type
	return TYPES[0]


## Véletlen típus, ami ezen az emeleten már megjelenhet (súlyozva).
static func pick(depth: int) -> Dictionary:
	var available: Array[Dictionary] = []
	var total := 0
	for type in TYPES:
		if type["min_depth"] <= depth:
			available.append(type)
			total += type["weight"]
	var ticket := randi_range(1, total)
	for type in available:
		ticket -= type["weight"]
		if ticket <= 0:
			return type
	return available.back()


## Konkrét statok egy ellenségnek: minden tartományból véletlen érték,
## plusz az emelet szerinti erősödés. `power` 0..1: mennyire "jó" a dobás
## (ettől függ kicsit a mérete is).
static func roll(type: Dictionary, depth: int) -> Dictionary:
	var level := depth - 1
	var health_roll := _roll_int(type["health"])
	var speed_bonus := minf(SPEED_PER_DEPTH * level, MAX_SPEED_BONUS)
	var stats := {
		"health": roundi(health_roll * (1.0 + HEALTH_PER_DEPTH * level)),
		"damage": _roll_int(type["damage"]) + floori(level * DAMAGE_PER_DEPTH),
		"speed": randf_range(type["speed"][0], type["speed"][1]) * (1.0 + speed_bonus),
		"dodge": mini(_roll_int(type["dodge"]) + DODGE_PER_DEPTH * level, 50),
		"knockback": randf_range(type["knockback"][0], type["knockback"][1]),
		"resist": randf_range(type["resist"][0], type["resist"][1]),
		"xp": roundi(_roll_int(type["xp"]) * (1.0 + XP_PER_DEPTH * level)),
	}
	for i in surges(depth):
		stats["health"] = roundi(stats["health"] * SURGE_HEALTH)
		stats["damage"] = roundi(stats["damage"] * SURGE_DAMAGE)
		stats["dodge"] = mini(stats["dodge"] + SURGE_DODGE, 50)
		stats["xp"] = roundi(stats["xp"] * SURGE_XP)
	if type.get("ranged", false):
		for key in ["fire_interval", "arrow_speed", "keep_distance"]:
			stats[key] = randf_range(type[key][0], type[key][1])
		stats["fire_interval"] /= 1.0 + minf(FIRE_RATE_PER_DEPTH * level, MAX_FIRE_RATE_BONUS)
		stats["arrow_speed"] *= 1.0 + speed_bonus / 2.0
	var health_range: Array = type["health"]
	stats["power"] = 0.5 if health_range[0] == health_range[1] \
		else inverse_lerp(health_range[0], health_range[1], health_roll)
	return stats


static func _roll_int(range_pair: Array) -> int:
	return randi_range(range_pair[0], range_pair[1])
