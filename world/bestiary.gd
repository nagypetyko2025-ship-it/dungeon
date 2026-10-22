class_name Bestiary
## A Szörnyek könyve (a táborban, a lépcsőhöz vezető ösvény mellett, egy állványon): minden
## szörny, amiből legalább egyet megöltél (Progress.kills), kategóriánként, névvel, rövid
## leírással és azzal, hányat öltél meg belőle. A főellenségek a saját nevükkel szerepelnek
## (Boss.BOSSES, a vérfarkas), a többiek az EnemyTypes nevével.

const BOSS_SCRIPT := preload("res://enemies/boss.gd")
const WEREWOLF_SCRIPT := preload("res://enemies/werewolf_boss.gd")

## A hét szörnykirály (a 3. emelettől minden 3. emeleten), és a Mélység Ura.
const KINGS := ["Ogrekirály", "Orkhadúr", "Gyíkkirály", "Démonúr", "Nekromanta-főpap", "Jégóriás", "Zombikirály"]
const LORD := "Vérfarkas, a Mélység Ura"
## A 21. emelet utáni új főellenségek (24., 27., 30., 33. emelet).
const DEEP_BOSSES := ["Kalózkirály", "Lánggólem", "A Mélység Szeme", "Nyálkakirály"]
## Kategóriák sorrendben: [cím, szörnyek].
const CATEGORIES := [
	["Élőholtak", ["tiny_zombie", "zombie", "ice_zombie", "big_zombie", "skelet", "skeleton_legionary",
		"giant_skeleton", "necromancer", "lich"]],
	["Zöldbőrűek", ["goblin", "club_goblin", "archer_goblin", "spear_goblin", "kamikaze_goblin", "orc_warrior", "masked_orc", "orc_shaman", "orc_mage", "ogre"]],
	["Démonok", ["imp", "wogol", "chort", "big_demon", "armored_demon", "red_demon", "purple_demon"]],
	["Nyálkák", ["tiny_slug", "slug", "green_slime", "frost_slime", "muddy", "swampy"]],
	["Népek", ["archer", "huntress", "dark_mage", "fire_witch", "fallen_knight", "dwarf", "dwarf_berserker",
		"plague_doctor", "lizard", "lizard_scout"]],
	["Kalózok", ["pirate_grunt", "pirate_gunner", "pirate_captain"]],
	["Fenevadak", ["minotaur", "yeti", "wendigo", "mammoth", "giant_crab"]],
	["Sárkányok", ["fire_dragon", "frost_dragon", "gold_dragon", "shadow_dragon"]],
	["Különös lények", ["mimic", "pumpkin_dude", "angel"]],
	["Főellenségek", KINGS + [LORD] + DEEP_BOSSES],
]
## A képességek neve a könyvben (EnemyAbilities, és a típus "dash" / "ranged" jelzője).
const ABILITY_NAMES := {
	"zigzag": "cikázás", "teleport": "teleport", "summon": "idézés", "heal": "gyógyítás",
	"war_cry": "harci kiáltás", "berserk": "dühöngés", "death_burst": "halálrobbanás",
	"regenerate": "regeneráció", "poison": "méreg", "frost": "fagy", "plunder": "fosztogatás",
	"shield": "pajzs", "explode": "kamikaze robbanás", "dash": "roham", "ranged": "távolsági",
}

## szörny -> [név, rövid leírás]
const ENTRIES := {
	"tiny_zombie": ["Kis zombi", "Lassú, de sosem fárad el. Csapatostul jön, és a nyakadba liheg."],
	"zombie": ["Zombi", "Rothadó test, ami újra összeforr: ha nem végzel vele gyorsan, visszagyógyul."],
	"ice_zombie": ["Jégzombi", "A mélység hidegében fagyott meg. Halálakor jégszilánkokká robban."],
	"big_zombie": ["Óriászombi", "Egy hústorony, amit alig lehet hátralökni. Lassan, de folyton gyógyul."],
	"skelet": ["Csontváz", "Régi kalandorok maradványa. Gyenge, de mindig van belőle még egy."],
	"club_goblin": ["Bunkós goblin", "Egy nagy bottal rohan feléd, és ha megsebzed, csak még dühösebb lesz."],
	"archer_goblin": ["Íjász goblin", "Cikázva lő, és a nyilai valahogy mindig az erszényedet találják el."],
	"orc_mage": ["Orkmágus", "Varázslövedékeket szór, pajzsot von maga köré, és gyógyítja a társait."],
	"red_demon": ["Vörös démon", "Lángoló bőrű démon: a semmiből terem melletted, és halálakor szétrobban."],
	"gold_dragon": ["Aranysárkány", "Kincseken alszik; ha eltalál, a te aranyadat is a halmára gyűjti."],
	"giant_skeleton": ["Óriás csontváz", "Egy ősi óriás csontjai, amiket valami újra összerakott. Lassú, de alig lehet kidönteni; csontvázakat hív maga mellé, és ha elesik, a csontjai szétrepülnek."],
	"skeleton_legionary": ["Csontlégiós", "Egy elesett hadsereg katonája; halála után is sorban menetel."],
	"necromancer": ["Nekromanta", "Halottakat idéz maga mellé. Őt öld meg először, különben sosem fogy el a sereg."],
	"lich": ["Lich", "Halhatatlanságot keresett, és megtalálta. Hideg varázslövedékeket szór legyezőben."],
	"goblin": ["Goblin", "Fürge kis tolvaj, cikázva rohan feléd. Sosem jár egyedül."],
	"orc_warrior": ["Orkharcos", "Ha megsebzed, csak dühösebb lesz: sérülten gyorsabban és erősebben üt."],
	"masked_orc": ["Álarcos ork", "Az orkok elit harcosa. A maszk mögött nincs félelem, csak düh."],
	"orc_shaman": ["Orksámán", "Csatakiáltásával feltüzeli a körülötte állókat."],
	"ogre": ["Ogre", "Hatalmas és buta, de egy ütése egy fát is kidönt. Üvöltése erőt ad társainak."],
	"imp": ["Kisördög", "Pimasz ördögfióka, aki a semmiből tűnik fel melletted."],
	"wogol": ["Wogol", "Patás kis démon, aki kiszámíthatatlanul cikázik a teremben."],
	"chort": ["Csort", "Teleportál és cikázik: mire odacsapnál, már máshol van."],
	"big_demon": ["Nagy démon", "Lángoló izomhegy. Halálakor szétrobban, ne állj túl közel."],
	"armored_demon": ["Páncélos démon", "Fekete vértbe zárt démon, ami tűzgömböket lő."],
	"purple_demon": ["Bíbor démon", "A mélység mélyéről jött; a levegő is szikrázik körülötte."],
	"tiny_slug": ["Kis csiga", "Ártalmatlannak tűnik, de nyálkás nyomot hagy maga után."],
	"slug": ["Csiga", "Nagy, nyálkás csiga. Ha szétvágod, kisebb csigákra esik szét."],
	"muddy": ["Sárlény", "Élő sárkupac. A sebei gyorsan begyógyulnak."],
	"swampy": ["Mocsárlény", "A mocsár mélyéről mászott elő; szívós és makacs, folyton gyógyul."],
	"archer": ["Erdei íjász", "Távolról lő, és igyekszik távol is maradni tőled."],
	"huntress": ["Vadásznő", "Egyszerre több nyilat lő legyezőben. Mozgásban maradj!"],
	"dark_mage": ["Sötét mágus", "Varázslövedékeket szór, amik átsuhannak a termen."],
	"fire_witch": ["Tűzboszorkány", "Egyszerre öt tűzgolyót lő legyezőben."],
	"fallen_knight": ["Elesett lovag", "Egykor a király szolgálatában állt. Most villámgyorsan rohan rád."],
	"dwarf": ["Törpe harcos", "Alacsony, de szikla szilárd. Sérülten feldühödik."],
	"dwarf_berserker": ["Törpe berzerker", "Csatabárdos őrült; minél több sebet kap, annál vadabb."],
	"plague_doctor": ["Pestisdoktor", "Csőrös maszkja mögül halálos ködöt fúj, amikor elesik."],
	"lizard": ["Gyíkharcos", "Rövid felvillanás után villámgyorsan nekiront a prédájának."],
	"lizard_scout": ["Gyíkfelderítő", "A gyíknép kémje: gyors és kiszámíthatatlan."],
	"minotaur": ["Minotaurusz", "Bikafejű óriás, aki a kazamata útvesztőit őrzi."],
	"yeti": ["Jeti", "A fagyos mélység bundás óriása. Ritkán látni, és ritkán élik túl."],
	"wendigo": ["Vendigó", "Csontsovány, éhes szellemlény. Az éhsége sosem csillapodik."],
	"mammoth": ["Mamut", "Ősi agyaras óriás, ami eltaposhat, ha elé állsz."],
	"giant_crab": ["Óriásrák", "Páncélja alig enged, az ollói egy kardot is kettétörnek."],
	"fire_dragon": ["Tűzsárkány", "A mélység ura alatti szintek réme. Tűzzáport lövell."],
	"frost_dragon": ["Jégsárkány", "Jeges lehelete lelassít. Ha eltalál, alig tudsz elmenekülni előle."],
	"shadow_dragon": ["Éjsárkány", "A legmélyebb termek ura: mérgező lángot köp, és pajzsot von maga köré."],
	"green_slime": ["Zöld nyálka", "Ugráló, savas kocsonya. Ha hozzád ér, megmérgez."],
	"frost_slime": ["Jégnyálka", "Hideg, kékes nyálka. Az érintése lelassít, és a sebei lassan begyógyulnak."],
	"spear_goblin": ["Lándzsás goblin", "Mérgezett hegyű lándzsával ront rád. Ne hagyd, hogy nekifusson."],
	"kamikaze_goblin": ["Kamikaze goblin", "Hordónyi puskaporral rohan feléd. Ha közel ér, felrobban."],
	"pirate_grunt": ["Kalózmatróz", "Egy elsüllyedt hajó legénységéből. Minden ütésével aranyat lop."],
	"pirate_gunner": ["Kalóz puskás", "Távolról lő, és a golyója az erszényedet is megcsapolja."],
	"pirate_captain": ["Kalózkapitány", "A legénység feje: pajzsot von maga köré, és rohamra hívja az embereit."],
	"mimic": ["Mimik", "Ládának álcázza magát. Ha közel mész, kitátja a fogas száját."],
	"pumpkin_dude": ["Töklámpás", "Vigyorgó tökfej, ami halálakor szétrobban."],
	"angel": ["Bukott angyal", "A többi szörnyet gyógyítja. Vele kezdd!"],
	"Ogrekirály": ["Ogrekirály", "Az első emeletek ura: egy hatalmas ogre, aki trónját senkinek sem adja át."],
	"Orkhadúr": ["Orkhadúr", "A zöldbőrű hordák vezére; csatakiáltására az egész terem megremeg."],
	"Gyíkkirály": ["Gyíkkirály", "A gyíknép uralkodója. Fürgébb, mint amilyennek látszik."],
	"Démonúr": ["Démonúr", "A pokoli seregek parancsnoka, lángoló haraggal."],
	"Nekromanta-főpap": ["Nekromanta-főpap", "A halottidézők főpapja: holtak hada kíséri."],
	"Jégóriás": ["Jégóriás", "Hideg és könyörtelen óriás a fagyott mélységből."],
	"Zombikirály": ["Zombikirály", "A rothadás koronás ura; a halál nem tudja megállítani."],
	"Vérfarkas, a Mélység Ura": ["Vérfarkas, a Mélység Ura", "A 20. emelet ura, aki Gáspár embereit legyilkolta. " \
		+ "Ha elesik, fel is kel."],
	"Kalózkirály": ["Kalózkirály", "Egy földalatti tengeren elsüllyedt flotta ura. Ágyútüzet zúdít rád, " \
		+ "és minden ütésével kifosztja az erszényed."],
	"Lánggólem": ["Lánggólem", "Élő láva és izzó kő. Ahová lép, kitör alóla a föld."],
	"A Mélység Szeme": ["A Mélység Szeme", "Lebegő, pislogás nélküli szem. Jeges tekintete lelassít, " \
		+ "és egy pillanat alatt melletted terem."],
	"Nyálkakirály": ["Nyálkakirály", "Hatalmas, remegő kocsonya. Mérgező tócsákat hagy maga után, " \
		+ "és kisebb nyálkákat szül."],
}


static func kills(monster: String) -> int:
	return int(Progress.kills.get(monster, 0))


## A kategória szörnyei, amelyekből már legalább egyet megöltél.
static func discovered(category: int) -> Array[String]:
	var result: Array[String] = []
	for monster: String in CATEGORIES[category][1]:
		if kills(monster) > 0:
			result.append(monster)
	return result


## A szörny képességei olvashatóan (pl. "méreg, pajzs"); "" ha nincs (vagy főellenség).
static func abilities_text(monster: String) -> String:
	var type := EnemyTypes.by_name(monster)
	if type["name"] != monster:
		return ""
	var names: Array[String] = []
	for ability: String in type.get("abilities", []):
		names.append(ABILITY_NAMES.get(ability, ability))
	for flag: String in ["dash", "ranged"]:
		if type.get(flag, false):
			names.append(ABILITY_NAMES[flag])
	return ", ".join(names)


## A szörny képe (az álló animáció első kockája) és a színezése.
static func icon(monster: String) -> Array:
	var type := EnemyTypes.by_name(monster)
	if type["name"] != monster:
		for boss: Dictionary in BOSS_SCRIPT.BOSSES:
			if boss["name"] == monster:
				if boss.has("sheet"):
					var own := AtlasTexture.new()
					own.atlas = load(boss["sheet"])
					own.region = boss["rect"]
					return [own, boss.get("tint", Color.WHITE)]
				return [SpriteSheet.region(boss["rect"]), boss.get("tint", Color.WHITE)]
		var sheet := AtlasTexture.new()
		sheet.atlas = load(WEREWOLF_SCRIPT.SHEET)
		sheet.region = WEREWOLF_SCRIPT.WEREWOLF["rect"]
		return [sheet, Color.WHITE]
	if type.has("sheet"):
		var texture := AtlasTexture.new()
		texture.atlas = load(type["sheet"])
		texture.region = type["rect"]
		return [texture, type.get("tint", Color.WHITE)]
	return [SpriteSheet.region(type["rect"]), type.get("tint", Color.WHITE)]
