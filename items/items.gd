class_name Items
## Tárgyak: minden tárgynak fix a helye, a ritkasága és hogy MELYIK statokat
## adja; azt viszont, hogy MENNYIT, minden példánynál a tartományból dobjuk
## (pl. a Zafírszív mindig regenerációt ad, egyszer +0.3-at, máskor +0.5-öt).
## Az ár a ritkaságtól és attól függ, mennyire jó lett a dobás.

## color: fény / slot-árnyalat (sötét háttéren); ink: szöveg a világos pergamenen.
const RARITIES := {
	"common": {"name": "Átlagos", "color": Color(0.85, 0.85, 0.82), "ink": Color(0.36, 0.33, 0.3),
		"price": [12, 22], "weight": 50},
	"rare": {"name": "Ritka", "color": Color(0.35, 0.62, 1.0), "ink": Color(0.12, 0.32, 0.72),
		"price": [35, 55], "weight": 30},
	"epic": {"name": "Epikus", "color": Color(0.78, 0.42, 1.0), "ink": Color(0.48, 0.18, 0.68),
		"price": [80, 120], "weight": 15},
	"legendary": {"name": "Legendás", "color": Color(1.0, 0.62, 0.15), "ink": Color(0.72, 0.36, 0.0),
		"price": [170, 250], "weight": 6},
}
const RARITY_ORDER: Array[String] = ["common", "rare", "epic", "legendary"]
## A boltos a vételár ennyied részéért veszi meg a tárgyakat.
const SELL_RATIO := 0.4
## A távolsági fegyverfajták (íj, számszeríj).
const RANGED_TYPES: Array[String] = ["bow", "crossbow"]
const SPEAR_NOTE_INK := Color(0.42, 0.28, 0.12)
const SLOT_NOTE_INK := Color(0.3, 0.22, 0.14)
const WEAPON_NOTE_INK := Color(0.45, 0.16, 0.1)
const WEAPON_KIND_NAMES := {"sword": "Kard", "spear": "Lándzsa", "axe": "Balta", "dagger": "Tőr", "mace": "Buzogány", "bow": "Íj",
	"crossbow": "Számszeríj", "wand": "Varázspálca"}
## A fegyverfajták rövid leírása (a kard az alap, ahhoz nincs).
const WEAPON_NOTES := {
	"spear": "Lándzsa: messzebbre ér és szúr. Átütés: a szúrást nem lehet kikerülni, és erősen hátralök.",
	"axe": "Balta: nagyon széles ívben suhint, kicsit lassabb, erősen hátralök.",
	"dagger": "Tőr: rövid, de nagyon gyors; nagy kritikus szorzó.",
	"mace": "Buzogány: lassú, de nagyot üt és messzire löki az ellenséget.",
	"bow": "Íj: nyilat lő a kurzor felé; a Távolsági sebzés erősíti, a Hatótáv a nyíl repülési távolsága.",
	"wand": "Varázspálca: a választott varázslatokat szórja (bal és jobb egérgomb); az Elemi sebzés erősíti.",
	"crossbow": "Számszeríj: lassabban tölt, de nagyot üt; legfeljebb 3 vesszőt lő, szűk, egyenes sorban.",
	"sword": "Kard: egyenesen előre döfi; a Hatótáv azt adja meg, milyen messzire.",
}
## Melyik tárgy képe jelzi halványan az üres felszerelés-helyet.
const SLOT_ICON_ITEMS := {
	"weapon": "sword_knight", "helmet": "helmet_knight", "chest": "chest_plate", "pants": "pants_cloth",
	"boots": "boots_worn", "ring": "ring_silver", "amulet": "amulet_bone",
	"gloves": "gloves_wool", "trinket": "trinket_paw",
}

## Stat neve a leírásokban, és hogy százalékos-e / tizedes-e.
const STAT_LABELS := {
	"damage": "közelharci sebzés",
	"ranged_damage": "távolsági sebzés",
	"elemental_damage": "elemi sebzés",
	"multishot": "nyíl lövésenként (többlövés)",
	"damage_percent": "sebzés",
	"max_health": "max élet",
	"health_regen": "élet / mp",
	"dodge": "kikerülés",
	"move_speed": "sebesség",
	"attack_speed": "ütési sebesség",
	"crit_chance": "kritikus esély",
	"attack_range": "hatótáv",
	"defense": "védelem",
	"accuracy": "találati esély",
	"lifesteal": "életlopás esély (+1 élet találatkor)",
	"thorns": "tüskesebzés a támadóidnak",
	"gold_find": "több arany",
	"xp_bonus": "több tapasztalat",
}
const PERCENT_STATS: Array[String] = ["damage_percent", "defense", "lifesteal", "gold_find", "xp_bonus", "dodge", "move_speed", "attack_speed", "crit_chance", "attack_range", "accuracy"]

## id -> definíció. "stats": stat -> [min, max] (negatív = hátrány).
## "region": a kép a 0x72 sprite-lapról (a kardoknál ez a kézben látszó kép is);
## enélkül az ikon az assets/items/<id>.png. "shop": false = a boltban nem kapható.
const DEFINITIONS := {
	# Fegyverek (Brotato-szerűen): "base" = alapsebzés [min, max], "scaling" = a Közelharci
	# sebzés hányszorosa adódik hozzá, "crit" = kritikus szorzó. A "stats" további bónuszok.
	# Kardok (a felszerelt kard látszik suhintáskor)
	"sword_rusty": {"name": "Rozsdás kard", "slot": "weapon", "rarity": "common", "shop": false,
		"region": Rect2(307, 10, 10, 21), "base": [1, 1], "scaling": 1.0, "crit": 1.5, "stats": {},
		"description": "Kicsorbult, rozsdás penge. Jobb a semminél."},
	"sword_knight": {"name": "Lovagkard", "slot": "weapon", "rarity": "common",
		"region": Rect2(339, 98, 10, 29), "base": [2, 2], "scaling": 0.8, "crit": 1.5,
		"stats": {"attack_speed": [5, 10], "attack_range": [3, 6]}},
	"sword_lavish": {"name": "Díszkard", "slot": "weapon", "rarity": "rare",
		"region": Rect2(307, 129, 10, 30), "base": [2, 3], "scaling": 0.9, "crit": 1.5,
		"stats": {"attack_speed": [10, 18], "crit_chance": [2, 4], "attack_range": [6, 10]}},
	"sword_ruby": {"name": "Rubinpenge", "slot": "weapon", "rarity": "epic",
		"region": Rect2(339, 10, 10, 21), "base": [3, 4], "scaling": 1.0, "crit": 1.6,
		"stats": {"attack_speed": [15, 25], "crit_chance": [4, 7], "attack_range": [8, 14], "damage_percent": [3, 6]}},
	"sword_golden": {"name": "Aranypenge", "slot": "weapon", "rarity": "legendary",
		"region": Rect2(291, 137, 10, 22), "base": [4, 5], "scaling": 1.2, "crit": 1.75,
		"stats": {"attack_speed": [20, 35], "crit_chance": [8, 12], "attack_range": [15, 25], "damage_percent": [6, 10]}},
	# Lándzsák: alapból messzebbre érnek, szúrnak (nem suhintanak), a szúrást
	# nem lehet kikerülni és erősen hátralök; cserébe lassabbak, kisebb a skálázásuk,
	# de nagy a kritikus szorzójuk.
	"spear_hunter": {"name": "Vadászlándzsa", "slot": "weapon", "rarity": "common", "weapon_type": "spear",
		"base": [1, 2], "scaling": 0.6, "crit": 1.75, "stats": {"attack_range": [5, 10]}},
	"spear_tassel": {"name": "Bojtos hadilándzsa", "slot": "weapon", "rarity": "rare", "weapon_type": "spear",
		"base": [2, 3], "scaling": 0.7, "crit": 1.75, "stats": {"attack_range": [8, 14], "crit_chance": [2, 4]}},
	"spear_azure": {"name": "Égkék szigony", "slot": "weapon", "rarity": "epic", "weapon_type": "spear",
		"base": [3, 4], "scaling": 0.8, "crit": 2.0,
		"stats": {"attack_range": [12, 18], "attack_speed": [5, 10], "crit_chance": [3, 6]}},
	"spear_crimson": {"name": "Vörös végzet", "slot": "weapon", "rarity": "legendary", "weapon_type": "spear",
		"base": [4, 6], "scaling": 1.0, "crit": 2.25,
		"stats": {"attack_range": [18, 26], "attack_speed": [8, 15], "crit_chance": [8, 12], "damage_percent": [5, 8]}},
	# Íjak: nyilat lőnek a kurzor felé, a Távolsági sebzés erősíti őket (az íjász bónuszt kap rájuk).
	"bow_old": {"name": "Régi íj", "slot": "weapon", "rarity": "common", "weapon_type": "bow", "shop": false,
		"base": [1, 1], "scaling": 1.0, "crit": 1.5, "stats": {},
		"description": "Kopott, de még feszül a húrja. Az íjász első íja."},
	"bow_hunter": {"name": "Vadászíj", "slot": "weapon", "rarity": "common", "weapon_type": "bow",
		"base": [2, 2], "scaling": 0.8, "crit": 1.5, "stats": {"attack_range": [5, 10], "accuracy": [2, 4]}},
	"bow_long": {"name": "Hosszúíj", "slot": "weapon", "rarity": "rare", "weapon_type": "bow",
		"base": [2, 3], "scaling": 0.9, "crit": 1.6, "stats": {"attack_range": [15, 25], "crit_chance": [2, 4], "accuracy": [4, 6]}},
	"bow_flame": {"name": "Lángíj", "slot": "weapon", "rarity": "epic", "weapon_type": "bow",
		"base": [3, 4], "scaling": 1.0, "crit": 1.75,
		"stats": {"ranged_damage": [1, 2], "attack_speed": [8, 12], "damage_percent": [3, 6]}},
	"bow_star": {"name": "Csillagíj", "slot": "weapon", "rarity": "legendary", "weapon_type": "bow",
		"base": [4, 5], "scaling": 1.2, "crit": 2.0,
		"stats": {"multishot": [1, 1], "ranged_damage": [2, 3], "attack_range": [15, 25], "crit_chance": [8, 12], "damage_percent": [6, 10], "accuracy": [6, 10]}},
	# Lőrinc fix varázspálcája (csak ő használhatja, és ő mást nem): a varázslatai ezzel szólnak.
	"wand_lorinc": {"name": "Lőrinc pálcája", "slot": "weapon", "rarity": "epic", "weapon_type": "wand",
		"unique": true, "shop": false, "region": Rect2(324, 129, 8, 30),
		"base": [3, 3], "scaling": 1.0, "crit": 1.6, "stats": {},
		"description": "Régi, vörös kristályos pálca. A gazdája hangjára felizzik."},
	# Számszeríjak (íjászoknak): lassabbak, de nagyobbat ütnek, mint az íjak; legfeljebb 3 vesszőt
	# lőnek egyszerre, szűk sorban. Ugyanannyi van belőlük, mint íjból (ritkaságonként is).
	"crossbow_light": {"name": "Könnyű számszeríj", "slot": "weapon", "rarity": "common", "weapon_type": "crossbow",
		"base": [2, 3], "scaling": 1.0, "crit": 1.6, "stats": {}},
	"crossbow_hunter": {"name": "Vadász-számszeríj", "slot": "weapon", "rarity": "common", "weapon_type": "crossbow",
		"base": [3, 4], "scaling": 0.9, "crit": 1.6, "stats": {"accuracy": [2, 4]}},
	"crossbow_steel": {"name": "Acél számszeríj", "slot": "weapon", "rarity": "rare", "weapon_type": "crossbow",
		"base": [4, 5], "scaling": 1.0, "crit": 1.7, "stats": {"attack_range": [10, 16], "crit_chance": [2, 4]}},
	"crossbow_repeater": {"name": "Ismétlő számszeríj", "slot": "weapon", "rarity": "rare", "weapon_type": "crossbow",
		"base": [3, 4], "scaling": 0.9, "crit": 1.6, "stats": {"attack_speed": [10, 15], "accuracy": [2, 4]}},
	"crossbow_hunting": {"name": "Medvevadász", "slot": "weapon", "rarity": "rare", "weapon_type": "crossbow",
		"base": [4, 5], "scaling": 1.05, "crit": 1.8, "stats": {"damage_percent": [3, 5]}},
	"crossbow_arbalest": {"name": "Arbalest", "slot": "weapon", "rarity": "epic", "weapon_type": "crossbow",
		"base": [5, 7], "scaling": 1.15, "crit": 1.9, "stats": {"ranged_damage": [1, 2], "attack_speed": [-8, -5], "attack_range": [12, 18]}},
	"crossbow_dragon": {"name": "Sárkányfog", "slot": "weapon", "rarity": "epic", "weapon_type": "crossbow",
		"base": [5, 6], "scaling": 1.1, "crit": 2.0, "stats": {"crit_chance": [5, 8], "damage_percent": [4, 6]}},
	"crossbow_flame": {"name": "Parázsvető", "slot": "weapon", "rarity": "epic", "weapon_type": "crossbow",
		"base": [5, 6], "scaling": 1.1, "crit": 1.9, "stats": {"ranged_damage": [1, 2], "damage_percent": [3, 6]}},
	"crossbow_void": {"name": "Ürességvető", "slot": "weapon", "rarity": "legendary", "weapon_type": "crossbow",
		"base": [7, 8], "scaling": 1.3, "crit": 2.2,
		"stats": {"multishot": [1, 1], "ranged_damage": [2, 3], "crit_chance": [8, 12], "damage_percent": [8, 12], "accuracy": [6, 10]}},
	# Sisakok
	"helmet_leather": {"name": "Bőrsapka", "slot": "helmet", "rarity": "common",
		"stats": {"max_health": [2, 4], "crit_chance": [1, 2], "accuracy": [2, 3]}},
	"helmet_knight": {"name": "Lovagsisak", "slot": "helmet", "rarity": "rare",
		"stats": {"max_health": [5, 8], "move_speed": [-4, -2]}},
	"helmet_great": {"name": "Aranyszegélyes nagysisak", "slot": "helmet", "rarity": "epic",
		"stats": {"max_health": [6, 9], "damage": [1, 2]}},
	"helmet_shadow": {"name": "Árnyékmágus kalapja", "slot": "helmet", "rarity": "legendary",
		"stats": {"crit_chance": [8, 12], "damage": [2, 3], "max_health": [-3, -2], "accuracy": [4, 6]}},
	# Mellvértek
	"chest_padded": {"name": "Párnázott zeke", "slot": "chest", "rarity": "common",
		"stats": {"max_health": [3, 5], "health_regen": [0.1, 0.2]}},
	"chest_plate": {"name": "Acél mellvért", "slot": "chest", "rarity": "rare",
		"stats": {"max_health": [7, 10], "dodge": [-3, -2]}},
	"chest_gold": {"name": "Aranypáncél", "slot": "chest", "rarity": "epic",
		"stats": {"max_health": [8, 12], "health_regen": [0.3, 0.5]}},
	"chest_dragon": {"name": "Sárkánypikkely vért", "slot": "chest", "rarity": "legendary",
		"stats": {"max_health": [12, 16], "health_regen": [0.6, 1.0], "damage": [1, 1]}},
	# Nadrágok
	"pants_cloth": {"name": "Vászonnadrág", "slot": "pants", "rarity": "common",
		"stats": {"move_speed": [6, 10], "dodge": [1, 2]}},
	"pants_ranger": {"name": "Erdőjáró nadrág", "slot": "pants", "rarity": "rare",
		"stats": {"dodge": [4, 6], "move_speed": [5, 8]}},
	"pants_shadow": {"name": "Árnyéklépő nadrág", "slot": "pants", "rarity": "epic",
		"stats": {"dodge": [8, 12], "crit_chance": [3, 5], "max_health": [-2, -1]}},
	"pants_knight": {"name": "Lovagi lábvért", "slot": "pants", "rarity": "legendary",
		"stats": {"max_health": [8, 12], "dodge": [4, 6], "damage": [1, 1]}},
	# Cipők
	"boots_worn": {"name": "Kopott csizma", "slot": "boots", "rarity": "common",
		"stats": {"move_speed": [8, 12]}},
	"boots_courier": {"name": "Futárcsizma", "slot": "boots", "rarity": "rare",
		"stats": {"move_speed": [14, 20], "dodge": [2, 4]}},
	"boots_iron": {"name": "Páncélos vascsizma", "slot": "boots", "rarity": "epic",
		"stats": {"move_speed": [10, 14], "max_health": [4, 6], "dodge": [3, 5]}},
	"boots_wind": {"name": "Szélcsizma", "slot": "boots", "rarity": "legendary",
		"stats": {"move_speed": [22, 30], "attack_speed": [12, 20]}},
	# Gyűrűk
	"ring_silver": {"name": "Ezüstgyűrű", "slot": "ring", "rarity": "common",
		"stats": {"health_regen": [0.2, 0.4], "crit_chance": [1, 2]}},
	"ring_ruby": {"name": "Rubingyűrű", "slot": "ring", "rarity": "rare",
		"stats": {"damage_percent": [3, 5], "crit_chance": [3, 5], "max_health": [-2, -1]}},
	"ring_sapphire": {"name": "Hideg zafírgyűrű", "slot": "ring", "rarity": "epic",
		"stats": {"damage": [2, 3], "crit_chance": [5, 8], "health_regen": [-0.2, -0.1]}},
	"ring_emerald": {"name": "Smaragd végzetgyűrű", "slot": "ring", "rarity": "legendary",
		"stats": {"crit_chance": [12, 18], "damage": [1, 2], "damage_percent": [5, 8]}},
	# Amulettek
	"amulet_bone": {"name": "Csontamulett", "slot": "amulet", "rarity": "common",
		"stats": {"dodge": [2, 4], "crit_chance": [1, 2]}},
	"amulet_heart": {"name": "Zafírszív", "slot": "amulet", "rarity": "rare",
		"stats": {"health_regen": [0.5, 0.8], "max_health": [3, 5]}},
	"amulet_blood": {"name": "Vérkő medál", "slot": "amulet", "rarity": "epic",
		"stats": {"damage_percent": [6, 10], "attack_speed": [8, 12], "health_regen": [-0.2, -0.1]}},
	"amulet_sun": {"name": "Napkereszt", "slot": "amulet", "rarity": "legendary",
		"stats": {"attack_speed": [25, 40], "dodge": [4, 6], "crit_chance": [4, 6], "max_health": [-3, -2]}},

	# --- Új fegyverfajták (ikonok: "496 pixel art icons", CC0) ---
	# Balták: széles suhintás, lassabbak, erős hátralökés.
	"axe_wood": {"name": "Favágó fejsze", "slot": "weapon", "rarity": "common", "weapon_type": "axe",
		"base": [2, 3], "scaling": 0.9, "crit": 1.5, "stats": {"max_health": [1, 2]}},
	"axe_battle": {"name": "Csatabárd", "slot": "weapon", "rarity": "rare", "weapon_type": "axe",
		"base": [3, 4], "scaling": 1.0, "crit": 1.6, "stats": {"attack_range": [4, 8], "defense": [1, 2]}},
	"axe_crimson": {"name": "Vérszomjas bárd", "slot": "weapon", "rarity": "epic", "weapon_type": "axe",
		"base": [4, 5], "scaling": 1.15, "crit": 1.75, "stats": {"lifesteal": [5, 8], "damage_percent": [3, 6]}},
	"axe_emerald": {"name": "Smaragdkirály bárdja", "slot": "weapon", "rarity": "legendary", "weapon_type": "axe",
		"base": [5, 7], "scaling": 1.3, "crit": 1.8, "stats": {"damage_percent": [6, 10], "max_health": [4, 6], "attack_range": [8, 12]}},
	# Tőrök: nagyon gyorsak és rövidek, kicsi alapsebzés, nagy kritikus szorzó.
	"dagger_iron": {"name": "Vastőr", "slot": "weapon", "rarity": "common", "weapon_type": "dagger",
		"base": [1, 1], "scaling": 0.7, "crit": 2.0, "stats": {"crit_chance": [3, 5]}},
	"dagger_curved": {"name": "Görbe kés", "slot": "weapon", "rarity": "rare", "weapon_type": "dagger",
		"base": [1, 2], "scaling": 0.8, "crit": 2.0, "stats": {"crit_chance": [5, 8], "move_speed": [4, 6]}},
	"dagger_frost": {"name": "Fagytüske", "slot": "weapon", "rarity": "epic", "weapon_type": "dagger",
		"base": [2, 3], "scaling": 0.9, "crit": 2.25, "stats": {"crit_chance": [8, 12], "dodge": [3, 5]}},
	"dagger_shadow": {"name": "Árnyékpenge", "slot": "weapon", "rarity": "legendary", "weapon_type": "dagger",
		"base": [3, 4], "scaling": 1.0, "crit": 2.5, "stats": {"crit_chance": [12, 16], "dodge": [5, 7], "lifesteal": [4, 6]}},
	# Buzogányok: lassúak, de nagyot ütnek és messzire lökik az ellenséget.
	"mace_club": {"name": "Bunkó", "slot": "weapon", "rarity": "common", "weapon_type": "mace",
		"base": [3, 4], "scaling": 1.0, "crit": 1.5, "stats": {}},
	"mace_morning": {"name": "Hajnalcsillag", "slot": "weapon", "rarity": "rare", "weapon_type": "mace",
		"base": [4, 5], "scaling": 1.1, "crit": 1.5, "stats": {"thorns": [1, 1], "max_health": [2, 3]}},
	"mace_flail": {"name": "Láncos buzogány", "slot": "weapon", "rarity": "epic", "weapon_type": "mace",
		"base": [5, 7], "scaling": 1.2, "crit": 1.6, "stats": {"attack_range": [10, 16], "max_health": [3, 5]}},
	"mace_sun": {"name": "Napbuzogány", "slot": "weapon", "rarity": "legendary", "weapon_type": "mace",
		"base": [7, 9], "scaling": 1.4, "crit": 1.75, "stats": {"defense": [5, 8], "health_regen": [0.3, 0.5], "damage_percent": [5, 8]}},

	# --- Kesztyűk (új hely) ---
	"gloves_wool": {"name": "Gyapjúkesztyű", "slot": "gloves", "rarity": "common",
		"stats": {"attack_speed": [4, 7], "defense": [1, 2], "accuracy": [2, 3]}},
	"gloves_spiked": {"name": "Tüskés ököl", "slot": "gloves", "rarity": "rare",
		"stats": {"damage": [1, 1], "thorns": [1, 2], "attack_speed": [5, 8]}},
	"gloves_steel": {"name": "Acél páncélkesztyű", "slot": "gloves", "rarity": "epic",
		"stats": {"defense": [5, 7], "attack_speed": [8, 12], "damage": [1, 2], "accuracy": [3, 5]}},
	"gloves_titan": {"name": "Titánmarkolat", "slot": "gloves", "rarity": "legendary",
		"stats": {"damage": [2, 3], "defense": [6, 9], "attack_speed": [12, 18], "thorns": [2, 3]}},

	# --- Talizmánok (új hely): különleges képességek ---
	"trinket_paw": {"name": "Nyúlláb", "slot": "trinket", "rarity": "common",
		"stats": {"dodge": [3, 5], "gold_find": [5, 10]}},
	"trinket_clover": {"name": "Négylevelű lóhere", "slot": "trinket", "rarity": "rare",
		"stats": {"gold_find": [20, 30], "crit_chance": [2, 3]}},
	"trinket_crystal": {"name": "Fagykristály", "slot": "trinket", "rarity": "rare",
		"stats": {"defense": [4, 6], "thorns": [1, 2]}},
	"trinket_eye": {"name": "A tudós szeme", "slot": "trinket", "rarity": "epic",
		"stats": {"xp_bonus": [25, 35], "crit_chance": [3, 5]}},
	"trinket_fang": {"name": "Vámpírfog", "slot": "trinket", "rarity": "epic",
		"stats": {"lifesteal": [8, 12], "damage_percent": [4, 6]}},
	# Főnixtoll: legendás; a többlövést csak legendás tárgy növelheti.
	"trinket_phoenix": {"name": "Főnixtoll", "slot": "trinket", "rarity": "legendary",
		"stats": {"multishot": [1, 1], "ranged_damage": [1, 2], "attack_speed": [5, 10]}},
	"trinket_clock": {"name": "Megállított óra", "slot": "trinket", "rarity": "legendary",
		"stats": {"attack_speed": [15, 22], "move_speed": [8, 12], "xp_bonus": [10, 15]}},

	# --- Új páncélok, sisakok, csizmák, ékszerek ---
	"chest_tunic": {"name": "Vászoning", "slot": "chest", "rarity": "common",
		"stats": {"dodge": [2, 4], "move_speed": [3, 6]}},
	"chest_iron": {"name": "Vaspáncél", "slot": "chest", "rarity": "rare",
		"stats": {"defense": [5, 7], "max_health": [3, 5], "move_speed": [-3, -1]}},
	"chest_flame": {"name": "Lángvért", "slot": "chest", "rarity": "legendary",
		"stats": {"defense": [9, 12], "thorns": [3, 4], "max_health": [8, 10], "damage_percent": [4, 6]}},
	"helmet_bronze": {"name": "Bronzsisak", "slot": "helmet", "rarity": "common",
		"stats": {"defense": [2, 3], "max_health": [1, 2]}},
	"helmet_paladin": {"name": "Paladinsisak", "slot": "helmet", "rarity": "epic",
		"stats": {"defense": [6, 8], "max_health": [5, 7], "health_regen": [0.2, 0.3]}},
	"hat_witch": {"name": "Boszorkánykalap", "slot": "helmet", "rarity": "rare",
		"stats": {"crit_chance": [3, 5], "xp_bonus": [10, 15], "max_health": [-2, -1]}},
	"boots_hunter": {"name": "Vadászcsizma", "slot": "boots", "rarity": "rare",
		"stats": {"move_speed": [10, 14], "dodge": [3, 4], "gold_find": [5, 10]}},
	"boots_plate": {"name": "Lemezcsizma", "slot": "boots", "rarity": "epic",
		"stats": {"defense": [5, 7], "max_health": [4, 6], "move_speed": [-4, -2]}},
	"amulet_tooth": {"name": "Fognyaklánc", "slot": "amulet", "rarity": "common",
		"stats": {"damage": [1, 1], "lifesteal": [3, 5]}},
	"amulet_cross": {"name": "Szent kereszt", "slot": "amulet", "rarity": "rare",
		"stats": {"health_regen": [0.3, 0.5], "defense": [3, 4]}},
	"ring_iron": {"name": "Vasgyűrű", "slot": "ring", "rarity": "common",
		"stats": {"defense": [2, 3], "max_health": [1, 3]}},
	"ring_moon": {"name": "Holdkő gyűrű", "slot": "ring", "rarity": "rare",
		"stats": {"dodge": [3, 5], "crit_chance": [2, 3], "xp_bonus": [5, 8]}},

	# --- Típusonként +2 tárgy (ikonok: "496 pixel art icons" és 0x72, CC0; néhány átszínezve) ---
	# Kardok (0x72 lap: a kézben is ez látszik)
	"sword_saw": {"name": "Fűrészpenge", "slot": "weapon", "rarity": "rare",
		"region": Rect2(307, 70, 10, 25), "base": [2, 3], "scaling": 0.95, "crit": 1.6,
		"stats": {"lifesteal": [3, 5], "attack_range": [4, 8]}},
	# Egyedi jutalom Gáspártól (nem esik, nem kapható): a királyi őrség kapitányának kardja.
	# A kép nagy felbontású ("swords cc0", SnoopethDuckDuck, CC0), a kézben 0.6x.
	"sword_royal": {"name": "Gáspár királyi kardja", "slot": "weapon", "rarity": "legendary", "shop": false, "unique": true,
		"base": [9, 10], "scaling": 1.6, "crit": 2.5, "hand_scale": 0.6,
		"stats": {"damage_percent": [25, 25], "attack_speed": [30, 30], "crit_chance": [15, 15], "lifesteal": [10, 10],
			"max_health": [15, 15], "defense": [8, 8], "accuracy": [10, 10]},
		"description": "Gáspár, a királyi őrség egykori kapitányának kardja. Aranyozott penge, rubinos markolat: "
			+ "a király adta neki a Mélységbe indulás előtt. Most a tiéd."},
	"sword_katana": {"name": "Holdfény katana", "slot": "weapon", "rarity": "epic",
		"region": Rect2(293, 66, 6, 29), "base": [3, 4], "scaling": 1.05, "crit": 2.0,
		"stats": {"attack_speed": [18, 26], "crit_chance": [6, 9], "accuracy": [4, 6]}},
	# Lándzsák
	"spear_crystal": {"name": "Kristályhegyű dárda", "slot": "weapon", "rarity": "common", "weapon_type": "spear",
		"base": [1, 2], "scaling": 0.65, "crit": 1.8, "stats": {"attack_range": [6, 10], "accuracy": [2, 3]}},
	"spear_halberd": {"name": "Alabárd", "slot": "weapon", "rarity": "epic", "weapon_type": "spear",
		"base": [4, 5], "scaling": 0.85, "crit": 1.9, "stats": {"attack_range": [16, 22], "defense": [2, 4], "attack_speed": [-6, -3]}},
	# Íjak
	"bow_feather": {"name": "Tollíj", "slot": "weapon", "rarity": "rare", "weapon_type": "bow",
		"base": [2, 3], "scaling": 0.9, "crit": 1.6, "stats": {"attack_speed": [8, 12], "move_speed": [4, 6]}},
	"bow_shadow": {"name": "Árnyíj", "slot": "weapon", "rarity": "epic", "weapon_type": "bow",
		"base": [3, 4], "scaling": 1.05, "crit": 1.9, "stats": {"crit_chance": [6, 9], "ranged_damage": [1, 2], "dodge": [3, 5]}},
	# Balták
	"axe_cleaver": {"name": "Hentesbárd", "slot": "weapon", "rarity": "common", "weapon_type": "axe",
		"base": [2, 3], "scaling": 0.9, "crit": 1.6, "stats": {"damage_percent": [2, 4]}},
	"axe_moon": {"name": "Holdsarló bárd", "slot": "weapon", "rarity": "legendary", "weapon_type": "axe",
		"base": [6, 7], "scaling": 1.3, "crit": 1.9, "stats": {"crit_chance": [6, 9], "lifesteal": [4, 6], "attack_speed": [8, 12]}},
	# Tőrök
	"dagger_viper": {"name": "Viperafog", "slot": "weapon", "rarity": "rare", "weapon_type": "dagger",
		"base": [1, 2], "scaling": 0.8, "crit": 2.1, "stats": {"crit_chance": [5, 7], "lifesteal": [2, 4]}},
	"dagger_sun": {"name": "Napkés", "slot": "weapon", "rarity": "legendary", "weapon_type": "dagger",
		"base": [3, 4], "scaling": 1.05, "crit": 2.5, "stats": {"crit_chance": [12, 16], "attack_speed": [15, 22], "accuracy": [5, 8]}},
	# Buzogányok
	"mace_bone": {"name": "Csontbuzogány", "slot": "weapon", "rarity": "common", "weapon_type": "mace",
		"base": [3, 4], "scaling": 1.0, "crit": 1.5, "stats": {"max_health": [1, 2]}},
	"mace_scepter": {"name": "Égi jogar", "slot": "weapon", "rarity": "epic", "weapon_type": "mace",
		"base": [5, 6], "scaling": 1.2, "crit": 1.6, "stats": {"health_regen": [0.3, 0.5], "xp_bonus": [10, 15]}},
	# Sisakok
	"hat_apprentice": {"name": "Mágustanonc süvege", "slot": "helmet", "rarity": "common",
		"stats": {"xp_bonus": [5, 8], "crit_chance": [1, 2]}},
	"helmet_dark": {"name": "Éjfekete sisak", "slot": "helmet", "rarity": "epic",
		"stats": {"defense": [5, 7], "max_health": [4, 6], "thorns": [1, 2]}},
	# Mellvértek
	"chest_leather": {"name": "Bőrvért", "slot": "chest", "rarity": "common",
		"stats": {"defense": [2, 3], "dodge": [1, 2]}},
	"chest_night": {"name": "Éjacél vért", "slot": "chest", "rarity": "epic",
		"stats": {"defense": [7, 9], "max_health": [6, 9], "dodge": [-2, -1]}},
	# Nadrágok
	"pants_leather": {"name": "Vörös bőrnadrág", "slot": "pants", "rarity": "common",
		"stats": {"defense": [1, 2], "move_speed": [4, 6]}},
	"pants_frost": {"name": "Fagyacél lábvért", "slot": "pants", "rarity": "epic",
		"stats": {"defense": [5, 7], "max_health": [5, 7], "move_speed": [-3, -1]}},
	# Cipők
	"boots_leather": {"name": "Bőrbakancs", "slot": "boots", "rarity": "common",
		"stats": {"move_speed": [6, 9], "defense": [1, 2]}},
	"boots_ember": {"name": "Parázsjáró csizma", "slot": "boots", "rarity": "epic",
		"stats": {"move_speed": [14, 18], "damage_percent": [3, 5], "thorns": [1, 2]}},
	# Kesztyűk
	"gloves_velvet": {"name": "Bársonykesztyű", "slot": "gloves", "rarity": "rare",
		"stats": {"crit_chance": [3, 5], "accuracy": [3, 5]}},
	"gloves_ember": {"name": "Parázskesztyű", "slot": "gloves", "rarity": "epic",
		"stats": {"damage": [1, 2], "attack_speed": [10, 14], "damage_percent": [3, 5]}},
	# Gyűrűk
	"ring_gold": {"name": "Aranygyűrű", "slot": "ring", "rarity": "rare",
		"stats": {"gold_find": [15, 25], "max_health": [2, 3]}},
	"ring_onyx": {"name": "Ónix pecsétgyűrű", "slot": "ring", "rarity": "legendary",
		"stats": {"damage": [2, 3], "lifesteal": [5, 8], "crit_chance": [5, 8]}},
	# Amulettek
	"amulet_wolf": {"name": "Gyógyfőzetes nyaklánc", "slot": "amulet", "rarity": "rare",
		"stats": {"health_regen": [0.4, 0.6], "dodge": [2, 3]}},
	"amulet_royal": {"name": "Királyi zafír", "slot": "amulet", "rarity": "epic",
		"stats": {"max_health": [6, 8], "damage_percent": [4, 6], "defense": [2, 3]}},
	# Talizmánok
	"trinket_fur": {"name": "Farkasprém", "slot": "trinket", "rarity": "common",
		"stats": {"defense": [2, 3], "move_speed": [3, 5]}},
	"trinket_mirror": {"name": "Igazmondó tükör", "slot": "trinket", "rarity": "epic",
		"stats": {"accuracy": [6, 9], "crit_chance": [4, 6], "xp_bonus": [8, 12]}},

	# --- Típusonként még +2 tárgy (ikonok: "496 pixel art icons", Dungeon Crawl, "swords cc0"; mind CC0) ---
	# Kardok (álló, nagy felbontású kép: a kézben 0.6x)
	"sword_venom": {"name": "Méregtüske", "slot": "weapon", "rarity": "rare", "hand_scale": 0.6,
		"base": [2, 3], "scaling": 0.9, "crit": 1.6, "stats": {"lifesteal": [2, 4], "crit_chance": [2, 4]}},
	"sword_dawn": {"name": "Hajnalpenge", "slot": "weapon", "rarity": "legendary", "hand_scale": 0.6,
		"base": [4, 5], "scaling": 1.25, "crit": 1.75,
		"stats": {"attack_speed": [20, 30], "damage_percent": [8, 12], "health_regen": [0.3, 0.5]}},
	# Lándzsák
	"spear_barbed": {"name": "Tüskés szigony", "slot": "weapon", "rarity": "common", "weapon_type": "spear",
		"base": [1, 2], "scaling": 0.65, "crit": 1.75, "stats": {"attack_range": [5, 8], "thorns": [1, 1]}},
	"spear_siege": {"name": "Ostromlándzsa", "slot": "weapon", "rarity": "legendary", "weapon_type": "spear",
		"base": [5, 6], "scaling": 1.0, "crit": 2.25, "stats": {"attack_range": [20, 28], "defense": [4, 6], "damage_percent": [6, 9]}},
	# Íjak
	"bow_serpent": {"name": "Kígyóíj", "slot": "weapon", "rarity": "rare", "weapon_type": "bow",
		"base": [2, 3], "scaling": 0.9, "crit": 1.6, "stats": {"crit_chance": [3, 5], "accuracy": [3, 5]}},
	"bow_frost": {"name": "Fagyíj", "slot": "weapon", "rarity": "epic", "weapon_type": "bow",
		"base": [3, 4], "scaling": 1.0, "crit": 1.8, "stats": {"ranged_damage": [1, 2], "attack_range": [10, 16], "dodge": [2, 4]}},
	# Balták
	"axe_headsman": {"name": "Hóhérbárd", "slot": "weapon", "rarity": "rare", "weapon_type": "axe",
		"base": [3, 4], "scaling": 1.0, "crit": 1.7, "stats": {"crit_chance": [3, 5], "damage_percent": [2, 4]}},
	"axe_double": {"name": "Kétélű csatabárd", "slot": "weapon", "rarity": "legendary", "weapon_type": "axe",
		"base": [6, 8], "scaling": 1.35, "crit": 1.8, "stats": {"damage_percent": [8, 12], "attack_range": [10, 14], "max_health": [5, 7]}},
	# Tőrök
	"dagger_bone": {"name": "Csontkés", "slot": "weapon", "rarity": "common", "weapon_type": "dagger",
		"base": [1, 1], "scaling": 0.7, "crit": 2.0, "stats": {"crit_chance": [3, 5], "lifesteal": [1, 2]}},
	"dagger_ember": {"name": "Parázskés", "slot": "weapon", "rarity": "epic", "weapon_type": "dagger",
		"base": [2, 3], "scaling": 0.95, "crit": 2.25, "stats": {"crit_chance": [8, 11], "attack_speed": [10, 15]}},
	# Buzogányok
	"mace_warhammer": {"name": "Hadikalapács", "slot": "weapon", "rarity": "rare", "weapon_type": "mace",
		"base": [4, 5], "scaling": 1.1, "crit": 1.5, "stats": {"defense": [2, 3], "max_health": [2, 3]}},
	"mace_star": {"name": "Csillagbuzogány", "slot": "weapon", "rarity": "legendary", "weapon_type": "mace",
		"base": [7, 9], "scaling": 1.4, "crit": 1.75, "stats": {"damage_percent": [6, 9], "thorns": [2, 3], "max_health": [5, 7]}},
	# Sisakok
	"helmet_etched": {"name": "Vésett sisak", "slot": "helmet", "rarity": "rare",
		"stats": {"defense": [3, 4], "max_health": [3, 5]}},
	"helmet_plumed": {"name": "Tollas lovagsisak", "slot": "helmet", "rarity": "epic",
		"stats": {"max_health": [6, 8], "crit_chance": [3, 5], "accuracy": [3, 4]}},
	# Mellvértek
	"chest_chain": {"name": "Láncing", "slot": "chest", "rarity": "rare",
		"stats": {"defense": [4, 6], "max_health": [3, 5]}},
	"chest_elven": {"name": "Tündepikkely vért", "slot": "chest", "rarity": "legendary",
		"stats": {"dodge": [8, 12], "defense": [6, 8], "move_speed": [6, 10]}},
	# Nadrágok
	"pants_blue": {"name": "Kék posztónadrág", "slot": "pants", "rarity": "common",
		"stats": {"move_speed": [4, 7], "max_health": [1, 2]}},
	"pants_emerald": {"name": "Smaragd lábvért", "slot": "pants", "rarity": "epic",
		"stats": {"defense": [4, 6], "dodge": [4, 6], "health_regen": [0.2, 0.3]}},
	# Cipők
	"boots_stripe": {"name": "Csíkos vándorcsizma", "slot": "boots", "rarity": "common",
		"stats": {"move_speed": [7, 10], "dodge": [1, 2]}},
	"boots_forest": {"name": "Erdőjáró csizma", "slot": "boots", "rarity": "epic",
		"stats": {"move_speed": [12, 16], "dodge": [4, 6], "gold_find": [5, 10]}},
	# Kesztyűk
	"gloves_fencer": {"name": "Vívókesztyű", "slot": "gloves", "rarity": "rare",
		"stats": {"attack_speed": [6, 9], "crit_chance": [2, 3], "accuracy": [2, 4]}},
	"gloves_mithril": {"name": "Mithril kesztyű", "slot": "gloves", "rarity": "legendary",
		"stats": {"defense": [6, 9], "attack_speed": [12, 18], "damage": [2, 3]}},
	# Gyűrűk
	"ring_emerald_cut": {"name": "Smaragdköves gyűrű", "slot": "ring", "rarity": "rare",
		"stats": {"max_health": [3, 4], "health_regen": [0.2, 0.3]}},
	"ring_bloodruby": {"name": "Vérrubin gyűrű", "slot": "ring", "rarity": "epic",
		"stats": {"damage_percent": [5, 7], "lifesteal": [3, 5]}},
	# Amulettek
	"amulet_eye": {"name": "Látó szem medál", "slot": "amulet", "rarity": "epic",
		"stats": {"crit_chance": [4, 6], "xp_bonus": [8, 12], "accuracy": [3, 5]}},
	"amulet_sunking": {"name": "A Napkirály medálja", "slot": "amulet", "rarity": "legendary",
		"stats": {"max_health": [8, 12], "damage_percent": [6, 9], "gold_find": [10, 15]}},
	# Talizmánok
	"trinket_lantern": {"name": "Koponyalámpás", "slot": "trinket", "rarity": "rare",
		"stats": {"xp_bonus": [10, 15], "dodge": [2, 3]}},
	"trinket_orb": {"name": "Vérgömb", "slot": "trinket", "rarity": "legendary",
		"stats": {"damage_percent": [8, 12], "crit_chance": [5, 8], "lifesteal": [4, 6]}},
}


## Ritkasági változatok: minden tárgynak mind a 4 ritkaságra van stat-változata. Az alap a
## definícióban megadott (mostani) ritkaság; a többit szabály számolja (RARITY_POWER szorzók,
## magasabb ritkaságon lépcsőnként +1, a tárgy jellegéhez illő extra stat: VARIANT_BONUS), és
## tárgyanként felülírható ("variants": {ritkaság: {"stats": {...}, "base": [...]}}).
## Elérhető (eshet, kapható) egyelőre csak a definíció saját ritkasága (available_rarities).
const RARITY_POWER := {"common": 0.65, "rare": 0.85, "epic": 1.0, "legendary": 1.3}
## Az extra stat helyenként (fegyvernél fajtánként) az epikus szintre méretezve.
const VARIANT_BONUS := {
	"sword": {"attack_speed": [6, 9]}, "spear": {"attack_range": [6, 9]}, "axe": {"damage_percent": [4, 6]},
	"dagger": {"crit_chance": [3, 5]}, "mace": {"defense": [2, 4]}, "bow": {"ranged_damage": [1, 2]},
	"crossbow": {"crit_chance": [3, 5]},
	"helmet": {"max_health": [3, 5]}, "chest": {"defense": [3, 5]}, "pants": {"dodge": [2, 4]},
	"boots": {"move_speed": [5, 8]}, "gloves": {"attack_speed": [5, 8]}, "ring": {"crit_chance": [2, 4]},
	"amulet": {"health_regen": [0.2, 0.4]}, "trinket": {"xp_bonus": [6, 10]},
}
## Ezek a statok nem skálázódnak (a többlövés csak legendás tárgyon lehet).
const UNSCALED_STATS: Array[String] = ["multishot"]


## A tárgy megadott ritkaságú változata (definíció-másolat); üres ritkaság = a saját ritkasága.
static func variant(id: String, rarity := "") -> Dictionary:
	var base: Dictionary = DEFINITIONS[id]
	var base_rarity: String = base["rarity"]
	if rarity.is_empty() or rarity == base_rarity or base.get("unique", false):
		return base
	var result := base.duplicate(true)
	result["rarity"] = rarity
	var scale: float = RARITY_POWER[rarity] / RARITY_POWER[base_rarity]
	var stats := {}
	for stat: String in base["stats"]:
		var pair: Array = base["stats"][stat]
		if stat in UNSCALED_STATS:
			if rarity == "legendary":
				stats[stat] = pair
			continue
		# A hátrány (negatív) alacsonyabb ritkaságon nagyobb, magasabbon kisebb.
		var factor := scale if pair[1] > 0 else 1.0 / scale
		stats[stat] = _scaled_pair(stat, pair, factor)
	# Magasabb ritkaságon lépcsőnként egy, a tárgyhoz illő extra stat (ha még nincs ilyen).
	var steps := RARITY_ORDER.find(rarity) - RARITY_ORDER.find(base_rarity)
	if steps > 0:
		var kind: String = base.get("weapon_type", "sword") if base["slot"] == "weapon" else base["slot"]
		var bonus: Dictionary = VARIANT_BONUS[kind]
		for stat: String in bonus:
			var factor: float = RARITY_POWER[rarity] / RARITY_POWER["epic"] * (0.6 + 0.2 * steps)
			var extra := _scaled_pair(stat, bonus[stat], factor)
			if stats.has(stat):
				var have: Array = stats[stat]
				stats[stat] = [have[0] + extra[0], have[1] + extra[1]]
			else:
				stats[stat] = extra
	result["stats"] = stats
	if base.has("base"):
		var damage: Array = base["base"]
		result["base"] = _scaled_pair("damage", damage, scale)
		result["scaling"] = snappedf(float(base["scaling"]) * sqrt(scale), 0.05)
	# Kézi igazítás: a tárgy saját felülírásai erre a ritkaságra.
	var all_overrides: Dictionary = base.get("variants", {})
	var overrides: Dictionary = all_overrides.get(rarity, {})
	for key: String in overrides:
		if key == "stats":
			for stat: String in overrides["stats"]:
				result["stats"][stat] = overrides["stats"][stat]
		else:
			result[key] = overrides[key]
	return result


## Mind a 4 ritkasági változat: ritkaság -> definíció.
static func variants(id: String) -> Dictionary:
	var all := {}
	for rarity in RARITY_ORDER:
		all[rarity] = variant(id, rarity)
	return all


## Milyen ritkaságban eshet / kapható a tárgy (egyelőre csak a saját ritkaságában).
static func available_rarities(id: String) -> Array[String]:
	var list: Array[String] = [DEFINITIONS[id]["rarity"]]
	return list


static func _scaled_pair(stat: String, pair: Array, factor: float) -> Array:
	if stat == "health_regen":
		var low := snappedf(float(pair[0]) * factor, 0.1)
		var high := snappedf(float(pair[1]) * factor, 0.1)
		if pair[1] > 0:
			low = maxf(low, 0.1)
			high = maxf(high, low)
		else:
			high = minf(high, -0.1)
			low = minf(low, high)
		return [low, high]
	var low_i := roundi(float(pair[0]) * factor)
	var high_i := roundi(float(pair[1]) * factor)
	if pair[1] > 0:
		low_i = maxi(low_i, 1)
		high_i = maxi(high_i, low_i)
	else:
		high_i = mini(high_i, -1)
		low_i = mini(low_i, high_i)
	return [low_i, high_i]


## Egy új példány véletlen statokkal és árral (`rarity`: melyik változat; üres = a sajátja).
static func create(id: String, rarity := "") -> Dictionary:
	var definition := variant(id, rarity)
	var stats := {}
	var quality := 0.0
	for stat: String in definition["stats"]:
		var range_pair: Array = definition["stats"][stat]
		var value: float
		if stat == "health_regen":
			value = snappedf(randf_range(range_pair[0], range_pair[1]), 0.1)
		else:
			value = randi_range(range_pair[0], range_pair[1])
		stats[stat] = value
		# Mindegyik statnál a nagyobb érték a jobb (a hátrányoknál a kisebb mínusz).
		quality += 0.5 if is_equal_approx(range_pair[0], range_pair[1]) \
			else inverse_lerp(range_pair[0], range_pair[1], value)
	var rolls: int = definition["stats"].size()
	# Fegyver: az alapsebzés is dobott érték (ez is számít az árba).
	var base_damage := 0
	if definition.has("base"):
		var base_range: Array = definition["base"]
		base_damage = randi_range(base_range[0], base_range[1])
		quality += 0.5 if base_range[0] == base_range[1] else inverse_lerp(base_range[0], base_range[1], base_damage)
		rolls += 1
	quality = quality / rolls if rolls > 0 else 0.0
	var price_range: Array = RARITIES[definition["rarity"]]["price"]
	var price := roundi(lerpf(price_range[0], price_range[1], quality) * randf_range(0.9, 1.1))
	var item := {
		"id": id,
		"name": definition["name"],
		"slot": definition["slot"],
		"rarity": definition["rarity"],
		"stats": stats,
		"price": price,
	}
	if definition.has("region"):
		item["region"] = definition["region"]
	else:
		item["icon_path"] = "res://assets/items/%s.png" % id
	if definition.has("description"):
		item["description"] = definition["description"]
	if definition.has("weapon_type"):
		item["weapon_type"] = definition["weapon_type"]
	if definition.has("hand_scale"):
		item["hand_scale"] = definition["hand_scale"]
	if definition.has("base"):
		item["base_damage"] = base_damage
		item["scaling"] = definition["scaling"]
		item["crit_multiplier"] = definition["crit"]
	return item


## Véletlen tárgy a ritkaságok súlyozásával (a legendás a legritkább).
## `max_rarity`: ennél ritkább nem lehet (pl. a ládákban legfeljebb "rare");
## `min_rarity`: ennél gyakoribb nem lehet (pl. a főellenség legalább "epic"-et dob).
static func random_item(max_rarity := "legendary", min_rarity := "common") -> Dictionary:
	var allowed := RARITY_ORDER.slice(RARITY_ORDER.find(min_rarity), RARITY_ORDER.find(max_rarity) + 1)
	var total := 0
	for rarity in allowed:
		total += RARITIES[rarity]["weight"]
	var ticket := randi_range(1, total)
	var chosen := "common"
	for rarity in allowed:
		ticket -= RARITIES[rarity]["weight"]
		if ticket <= 0:
			chosen = rarity
			break
	# Csak azok a tárgyak, amelyeknek ez a ritkasága elérhető (egyelőre a sajátjuk).
	var ids: Array = DEFINITIONS.keys().filter(func(id: String) -> bool:
		return chosen in available_rarities(id) and DEFINITIONS[id].get("shop", true))
	return create(ids.pick_random(), chosen)


## Távolsági fegyver-e (íj vagy számszeríj): a Távolsági sebzés erősíti, csak íjász használhatja.
static func is_ranged(item: Variant) -> bool:
	return item is Dictionary and item.get("weapon_type", "") in RANGED_TYPES


## Ennyit fizet érte a boltos (a vételár SELL_RATIO része, legalább 1).
static func sell_price(item: Dictionary) -> int:
	return maxi(1, roundi(item.get("price", 0) * SELL_RATIO))


static func rarity_name(item: Dictionary) -> String:
	return RARITIES[item.get("rarity", "common")]["name"]


static func rarity_color(item: Dictionary) -> Color:
	return RARITIES[item.get("rarity", "common")]["color"]


## A ritkaság színe szövegnek, a világos pergamen háttéren is olvashatóan.
static func rarity_ink(item: Dictionary) -> Color:
	return RARITIES[item.get("rarity", "common")]["ink"]


## Egy stat szövegesen, pl. "+3% kikerülés", "-1 max élet", "+0.3 élet / mp".
static func format_stat(stat: String, value: float) -> String:
	var prefix := "+" if value >= 0 else "-"
	var amount := absf(value)
	var number := ("%.1f" % amount) if stat == "health_regen" else str(roundi(amount))
	if stat in PERCENT_STATS:
		number += "%"
	return "%s%s %s" % [prefix, number, STAT_LABELS[stat]]


## BBCode leírás a tooltipekhez: ritkaság, statok (zöld = előny, piros = hátrány).
static func describe_bbcode(item: Dictionary) -> String:
	var lines: Array[String] = []
	# Küldetéstárgy (pl. a tolvaj levele): nem vehető fel, csak a leírása.
	if item.get("quest", false):
		return "[color=#%s]Küldetéstárgy[/color]\n%s" % [SLOT_NOTE_INK.to_html(false), item.get("description", "")]
	if item.has("rarity"):
		lines.append("[color=#%s]%s[/color]" % [rarity_ink(item).to_html(false), rarity_name(item)])
	if item.has("slot"):
		var kind := slot_name(item)
		# Fegyvernél a fajtája is: pl. "Fegyver (Tőr)".
		if item["slot"] == "weapon":
			kind += " (%s)" % WEAPON_KIND_NAMES.get(item.get("weapon_type", "sword"), "Kard")
		lines.append("[color=#%s]Típus: %s  →  %s helyre tehető[/color]"
			% [SLOT_NOTE_INK.to_html(false), kind, slot_name(item)])
	if item.has("base_damage"):
		var scaling_stat := "elemi" if item.get("weapon_type", "") == "wand" \
			else ("távolsági" if is_ranged(item) else "közelharci")
		lines.append("[color=#%s]Alapsebzés: %d  ·  +%d%% %s sebzés\nKritikus szorzó: ×%s[/color]" % [
			WEAPON_NOTE_INK.to_html(false), item["base_damage"], roundi(item["scaling"] * 100.0), scaling_stat,
			str(item["crit_multiplier"])])
	for stat: String in item.get("stats", {}):
		var value: float = item["stats"][stat]
		var color := "3c8a32" if value >= 0 else "b0302a"
		# A különleges képességek (életlopás, tüskék, aranykereső, XP) lilával.
		if stat in Stats.SPECIAL:
			color = "7a3aa8"
		lines.append("[color=#%s]%s[/color]" % [color, format_stat(stat, value)])
	var weapon_note: String = WEAPON_NOTES.get(item.get("weapon_type", ""), "")
	if not weapon_note.is_empty():
		lines.append("[color=#%s]%s[/color]" % [SPEAR_NOTE_INK.to_html(false), weapon_note])
	# Ki használhatja (pirossal, ha a mostani karakter nem).
	var restriction := Characters.weapon_restriction_text(item)
	if not restriction.is_empty():
		var usable := Characters.can_use(item)
		lines.append("[color=#%s]%s%s[/color]" % ["3c6a32" if usable else "b0302a", restriction,
			"" if usable else " (a mostani karaktered nem veheti fel)"])
	if item.has("description"):
		lines.append(item["description"])
	return "\n".join(lines)


## Összehasonlítás: a FELVETT tárgy statjai, mindegyik után zárójelben, hogy mennyivel ad
## többet (+, zöld) vagy kevesebbet (−, piros) a vizsgált (új) tárgyhoz képest. Pl. ha a
## felvett gyűrű 2 védelmet ad, a vizsgált 3-at: "+2% védelem (-1)". Amit csak az új tárgy
## ad, az 0-val szerepel. Fegyvernél az alapsebzés, a skálázás és a kritikus szorzó is.
static func compare_bbcode(new_item: Dictionary, equipped: Dictionary) -> String:
	var lines: Array[String] = []
	if new_item.has("base_damage") and equipped.has("base_damage"):
		var base := float(equipped["base_damage"])
		lines.append("Alapsebzés: %d %s" % [roundi(base), _diff_text(base - float(new_item["base_damage"]), "%+d")])
		var scaling := float(equipped["scaling"]) * 100.0
		lines.append("Skálázás: %d%% %s" % [roundi(scaling),
			_diff_text(scaling - float(new_item["scaling"]) * 100.0, "%+d%%")])
		var crit := float(equipped["crit_multiplier"])
		lines.append("Kritikus szorzó: ×%s %s" % [str(crit),
			_diff_text(crit - float(new_item["crit_multiplier"]), "%+.2f")])
	# Előbb a felvett tárgy statjai, aztán amit csak az új tárgy ad.
	var stats: Array[String] = []
	for stat: String in equipped.get("stats", {}):
		stats.append(stat)
	for stat: String in new_item.get("stats", {}):
		if not stats.has(stat):
			stats.append(stat)
	for stat in stats:
		var old_value := float(equipped.get("stats", {}).get(stat, 0.0))
		var new_value := float(new_item.get("stats", {}).get(stat, 0.0))
		var number_format := "%+.1f" if stat == "health_regen" else "%+d"
		if stat in PERCENT_STATS:
			number_format += "%%"
		lines.append("%s %s" % [format_stat(stat, old_value), _diff_text(old_value - new_value, number_format)])
	if lines.is_empty():
		lines.append("(nincs statja)")
	return "[color=#%s]A felvett tárgy: %s[/color]\n%s" % [
		SLOT_NOTE_INK.to_html(false), equipped["name"], "\n".join(lines)]


## A különbség zárójelben: zöld, ha a felvett tárgy ad többet, piros, ha kevesebbet.
static func _diff_text(diff: float, number_format: String) -> String:
	if is_zero_approx(diff):
		return "[color=#8a7a60](=)[/color]"
	var color := "3c8a32" if diff > 0 else "b0302a"
	var value: Variant = roundi(diff) if number_format.contains("d") else diff
	return "[color=#%s](%s)[/color]" % [color, number_format % value]


## A tárgy helyének (típusának) neve, pl. "Gyűrű", "Amulett".
static func slot_name(item: Dictionary) -> String:
	return Inventory.SLOT_NAMES.get(item.get("slot", ""), "")


## Egy felszerelés-hely jelképe (az üres helyen halványan látszik, hogy mi kerül oda).
static func slot_icon(slot: String) -> Texture2D:
	var id: String = SLOT_ICON_ITEMS.get(slot, "")
	if id.is_empty():
		return null
	var definition: Dictionary = DEFINITIONS[id]
	if definition.has("region"):
		return SpriteSheet.region(definition["region"])
	return load("res://assets/items/%s.png" % id)


static func icon(item: Dictionary) -> Texture2D:
	if item.has("icon_path"):
		return load(item["icon_path"])
	return SpriteSheet.region(item["region"])
