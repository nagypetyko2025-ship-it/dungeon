class_name Doctor
## Kálmán doktor a kalandorok kórházában (lásd Hospital): pestisdoktor-maszkos orvos. Kérdezgetni
## lehet, és küldetéseket ad (a J könyv "Doktor" fülén, ami az első kérésével jelenik meg).
## 1. Vérgömb: egy legendás talizmán, a vérmágiájával a hordágyon hozott sebesültet menti meg.

const ID := "doctor"
const NAME := "Kálmán doktor"
const FIGURE := Rect2(368, 345, 16, 23)
const ORB_QUEST := "doctor_orb"
const ORB_ID := "trinket_orb"
const ORB_GOLD := 350

const GREETING := "[i]A pestisdoktor-maszk mögül tompa, fáradt hang szól.[/i]\n\n" \
	+ "Csak óvatosan, ne lépj a vödörbe. Ha nem vérzel, ülj le valahova. Ha vérzel... akkor is ülj le, és várj."

const QUESTS := {
	ORB_QUEST: {"name": "A Vérgömb",
		"text": "Kálmán doktor szerint a hordágyon hozott sebesült nem éli túl a hetet, hacsak nem kap vért, "
			+ "amit egy ember nem adhat. Hozz neki egy [b]Vérgömböt[/b] (legendás talizmán, a táskádban legyen): "
			+ "a vérmágiájával talán még megmentheti.",
		"reward": "%d tábori arany (és egy megmentett élet)" % ORB_GOLD,
		"doing": "vigyél a doktornak egy Vérgömböt", "done": "a sebesült túlélte"},
}

const SMALL_TALK: Array[Dictionary] = [
	{"id": "who", "text": "Ki vagy te?", "trust": 4,
		"answer": "Kálmán. A tábor doktora, mióta az előző... nos, mióta ő is lement. Régen a pestises falvakat " \
			+ "jártam, onnan a maszk. A Mélység szaga sem sokkal jobb, úgyhogy rajtam maradt.\n\n" \
			+ "Rozi nővér segít. Nélküle a fele már a temetőben feküdne, Vendel nagy örömére."},
	{"id": "stretcher", "text": "Mi lett azzal, akit a katonák hoztak?", "trust": 3,
		"answer": "[i]Az ablak melletti ágy felé biccent.[/i]\n\n" \
			+ "Ott fekszik. A kilencedik emeleten egy bukott lovag kardja találta el, a katonák a lépcső aljáról " \
			+ "hozták fel. Sok vért vesztett, de él. Ha a láz lemegy, talán reggel már a nevét is megmondja.\n\n" \
			+ "Azt motyogta, hogy odalent a szörnyek egyre okosabbak. Kerülgetik az oszlopokat. Nem tetszik ez nekem."},
	{"id": "advice", "text": "Van valami tanácsod?", "trust": 2,
		"answer": "Három dolog. Egy: a vörös bájital nem cukorka, de ne is spórold, ha baj van.\n" \
			+ "Kettő: a mérget nem lehet kiizzadni. Ha zöldül a szél a szemed előtt, menekülj, és várd ki.\n" \
			+ "Három: ha a kiképzősátorban edzel, ritkábban látlak itt. Az nekem is jó."},
	{"id": "busy", "text": "Miért van itt ennyi sebesült?", "trust": 3,
		"answer": "Mert egyre többen mennek le. A király aranyat ígér, a kocsmáros küldetéseket ad, a fiatalok " \
			+ "hősök akarnak lenni.\n\n[i]Felsóhajt, a maszk csőre megbillen.[/i]\n\n" \
			+ "A hősökből lesznek a betegeim. A szerencsésebbekből."},
]


## A beszélgetés opciói: a négy kérdés, ötödiknek a küldetés (kérés / átadás / köszönet).
static func options(inventory: Inventory) -> Array[Dictionary]:
	var list: Array[Dictionary] = SMALL_TALK.duplicate()
	match Progress.npc_quest_state(ORB_QUEST):
		"":
			list.append({"id": "help", "text": "Kell segíteni valamiben?",
				"on_choose": func() -> String: return _give_orb_quest()})
		"active":
			if has_orb(inventory):
				list.append({"id": "orb", "text": "Hoztam egy Vérgömböt.",
					"on_choose": func() -> String: return _give_orb(inventory)})
		"done":
			list.append({"id": "patient", "text": "Hogy van a sebesült?",
				"on_choose": func() -> String: return "[i]A doktor az ablak melletti ágy felé int. A sebesült ül, " \
					+ "és egy tál levest kanalaz, kicsit remegő kézzel.[/i]\n\n" \
					+ "Látod? Ma reggel megmondta a nevét: Tamás. Holnap talán már járni is tud. A gömböt elzártam: " \
					+ "ilyen erő nem való egy kórház polcára."})
	return list


static func _give_orb_quest() -> String:
	Progress.set_npc_quest(ORB_QUEST, "active")
	Progress.mark_asked(ID, "help")
	Progress.save_game()
	Audio.play("ui_open")
	return "[i]A doktor sokáig hallgat, a maszk csőre a padló felé fordul.[/i]\n\n" \
		+ "Segíteni? Talán. A hordágyas fiú... nem éli túl a hetet. Túl sok vért vesztett, és amit én adhatok, " \
		+ "az kevés. Ember nem adhat annyit.\n\n" \
		+ "Hallottál már a [b]Vérgömbről[/b]? Legendás talizmán, a Mélység legmélyén terem. Azt mondják, a vér " \
		+ "dobog benne, mint egy szív. Ha valaha rátalálsz, hozd el nekem. A vérmágiájával talán még " \
		+ "visszahozhatom a fiút.\n\n" \
		+ "[color=#7a4a10](Új fül a küldetések könyvében: Doktor  [J])[/color]"


static func is_orb(item: Variant) -> bool:
	return item is Dictionary and item.get("id", "") == ORB_ID


static func has_orb(inventory: Inventory) -> bool:
	for item: Variant in inventory.bag:
		if is_orb(item):
			return true
	return false


static func _give_orb(inventory: Inventory) -> String:
	for i in inventory.bag.size():
		if not is_orb(inventory.bag[i]):
			continue
		inventory.take_from_bag(i)
		Progress.set_npc_quest(ORB_QUEST, "done")
		Progress.add_camp_gold(ORB_GOLD)
		Progress.change_trust(ID, 30)
		Progress.save_game()
		Audio.play("level_up")
		return "[i]A doktor kesztyűs kézzel, óvatosan veszi át a gömböt. Vörösen lüktet a tenyerében, mintha " \
			+ "élne. Az ablak melletti ágyhoz siet, és a sebesült mellkasára fekteti.[/i]\n\n" \
			+ "[i]Hosszú csend. Aztán a fiú köhög egyet, és kinyitja a szemét.[/i]\n\n" \
			+ "Él. Él! Rozi, hozz vizet!\n\n[i]Feléd fordul, a maszk mögül alig hallani a hangját.[/i]\n\n" \
			+ "Köszönöm, kalandor. Nem sokan hoznak ide életet; a legtöbben csak sebeket. " \
			+ "[color=#7a4a10](+%d tábori arany)[/color]" % ORB_GOLD
	return "Hm? Nem látom nálad a Vérgömböt."


static func portrait() -> AtlasTexture:
	return SpriteSheet.region(FIGURE)
