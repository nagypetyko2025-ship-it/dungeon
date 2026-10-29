class_name Achievements
## Eredmények könyve (a táborban, a harmadik állványon; ablak: ui/achievement_book.gd): teljesítmények, amelyek a
## mentett táborból számolódnak (Progress: kills, deepest, quests_done, seen_items), és egy-egy kis jutalmat adnak
## (arany a tábori kincsbe, por a kovácshoz). Az átvett jutalmak: `Progress.rewards_claimed` ("ach_<id>").
## Itt van a könyvjutalmak közös kiosztója is (grant / reward_text), a Tárgyak könyve is ezt használja.

const DEMONS := ["hell_hound", "hell_beast", "nightmare", "hell_demon"]

## id, név, leírás, fajta (lásd progress()), cél, jutalom ({"gold": n, "dust": {ritkaság: n}}); a "boss"
## fajtánál a "target" a főellenség neve (ahogy a Progress.kills-ben áll).
const LIST: Array[Dictionary] = [
	{"id": "kills_100", "name": "Első vér", "text": "Ölj meg 100 szörnyet.", "kind": "kills", "goal": 100,
		"reward": {"gold": 100}},
	{"id": "kills_1000", "name": "Szörnyirtó", "text": "Ölj meg 1000 szörnyet.", "kind": "kills", "goal": 1000,
		"reward": {"gold": 250}},
	{"id": "kills_5000", "name": "A kazamata réme", "text": "Ölj meg 5000 szörnyet.", "kind": "kills", "goal": 5000,
		"reward": {"gold": 500, "dust": {"epic": 1}}},
	{"id": "kills_20000", "name": "Élő legenda", "text": "Ölj meg 20 000 szörnyet.", "kind": "kills", "goal": 20000,
		"reward": {"gold": 1000, "dust": {"legendary": 1}}},
	{"id": "deep_10", "name": "Lépcsőről lépcsőre", "text": "Juss le a 10. emeletre.", "kind": "deepest", "goal": 10,
		"reward": {"gold": 100}},
	{"id": "deep_20", "name": "A sötétség szélén", "text": "Juss le a 20. emeletre.", "kind": "deepest", "goal": 20,
		"reward": {"gold": 200}},
	{"id": "deep_40", "name": "A Káoszkő mélyén", "text": "Juss le a 40. emeletre.", "kind": "deepest", "goal": 40,
		"reward": {"gold": 400}},
	{"id": "deep_60", "name": "Jégbe zárva", "text": "Juss le a 60. emeletre.", "kind": "deepest", "goal": 60,
		"reward": {"gold": 600, "dust": {"epic": 1}}},
	{"id": "deep_81", "name": "A pokol kapujában", "text": "Juss le a 81. emeletre, a Vérkőbe.", "kind": "deepest",
		"goal": 81, "reward": {"gold": 800, "dust": {"epic": 1}}},
	{"id": "deep_100", "name": "A mélység alja", "text": "Juss le a 100. emeletre.", "kind": "deepest", "goal": 100,
		"reward": {"gold": 1200, "dust": {"legendary": 1}}},
	{"id": "quests_10", "name": "Szavahihető", "text": "Teljesíts 10 küldetést.", "kind": "quests", "goal": 10,
		"reward": {"gold": 150}},
	{"id": "quests_30", "name": "A kocsma kedvence", "text": "Teljesíts 30 küldetést.", "kind": "quests", "goal": 30,
		"reward": {"gold": 300}},
	{"id": "quests_60", "name": "Mindenki hőse", "text": "Teljesíts 60 küldetést.", "kind": "quests", "goal": 60,
		"reward": {"gold": 600, "dust": {"epic": 1}}},
	{"id": "quests_100", "name": "Nincs több hirdetmény", "text": "Teljesíts 100 küldetést.", "kind": "quests",
		"goal": 100, "reward": {"gold": 1000, "dust": {"legendary": 1}}},
	{"id": "kinds_25", "name": "Kíváncsi vadász", "text": "Ölj meg 25 különféle szörnyet.", "kind": "kinds", "goal": 25,
		"reward": {"gold": 150}},
	{"id": "kinds_60", "name": "Szörnytudós", "text": "Ölj meg 60 különféle szörnyet.", "kind": "kinds", "goal": 60,
		"reward": {"gold": 400}},
	{"id": "kinds_100", "name": "A Szörnyek könyve szerzője", "text": "Ölj meg 100 különféle szörnyet.",
		"kind": "kinds", "goal": 100, "reward": {"gold": 800, "dust": {"epic": 1}}},
	{"id": "items_30", "name": "Gyűjtögető", "text": "Szerezz 30 különféle tárgyat.", "kind": "items", "goal": 30,
		"reward": {"gold": 150}},
	{"id": "items_80", "name": "Kincsvadász", "text": "Szerezz 80 különféle tárgyat.", "kind": "items", "goal": 80,
		"reward": {"gold": 400}},
	{"id": "items_140", "name": "Múzeumigazgató", "text": "Szerezz 140 különféle tárgyat.", "kind": "items",
		"goal": 140, "reward": {"gold": 800, "dust": {"epic": 1}}},
	{"id": "demons_50", "name": "Démonűző", "text": "Ölj meg 50 démont a Vérkőben (pokolkutya, pokolfajzat, "
		+ "lidércló, pokolúr).", "kind": "demons", "goal": 50, "reward": {"gold": 600}},
	{"id": "demons_300", "name": "A pokol ostora", "text": "Ölj meg 300 démont a Vérkőben.", "kind": "demons",
		"goal": 300, "reward": {"gold": 1200, "dust": {"legendary": 1}}},
	{"id": "boss_lord", "name": "A Mélység Ura", "text": "Győzd le a Vérfarkast, a Mélység Urát.", "kind": "boss",
		"target": Bestiary.LORD, "goal": 1, "reward": {"gold": 400}},
	{"id": "boss_scorpion", "name": "Méregfogó", "text": "Győzd le a Skorpiókirályt.", "kind": "boss",
		"target": "Skorpiókirály", "goal": 1, "reward": {"gold": 400}},
	{"id": "boss_frost", "name": "Olvadás", "text": "Győzd le a Jégkirálynőt.", "kind": "boss",
		"target": "Jégkirálynő", "goal": 1, "reward": {"gold": 600, "dust": {"epic": 1}}},
	{"id": "boss_chaos", "name": "Az üresség vége", "text": "Győzd le Ürességfalót, a Káosz Urát.", "kind": "boss",
		"target": Bestiary.CHAOS_LORD, "goal": 1, "reward": {"gold": 1000, "dust": {"legendary": 1}}},
	{"id": "boss_engine", "name": "Óramű-leállás", "text": "Állítsd le az Ősgépezetet a 60. emeleten.", "kind": "boss",
		"target": Bestiary.ENGINE, "goal": 1, "reward": {"gold": 1500, "dust": {"legendary": 1}}},
	{"id": "boss_knocker", "name": "Csend a tárnákban", "text": "Győzd le a Kopogót a bánya mélyén.", "kind": "boss",
		"target": "A Kopogó", "goal": 1, "reward": {"gold": 300}},
	{"id": "boss_lake", "name": "A tó nyugalma", "text": "Győzd le a Tófenék Urát az elárasztott kriptában.",
		"kind": "boss", "target": "A Tófenék Ura", "goal": 1, "reward": {"gold": 300}},
	{"id": "boss_ogre", "name": "Óriásölő", "text": "Győzd le az Ogrekirályt.", "kind": "boss",
		"target": "Ogrekirály", "goal": 1, "reward": {"gold": 100}},
	{"id": "boss_necro", "name": "Nyugodjanak békében", "text": "Győzd le a Nekromanta-főpapot.", "kind": "boss",
		"target": "Nekromanta-főpap", "goal": 1, "reward": {"gold": 200}},
	{"id": "boss_pirate", "name": "Kalózvér", "text": "Győzd le a Kalózkirályt.", "kind": "boss",
		"target": "Kalózkirály", "goal": 1, "reward": {"gold": 250}},
	{"id": "boss_golem", "name": "Kihunyt láng", "text": "Győzd le a Lánggólemet.", "kind": "boss",
		"target": "Lánggólem", "goal": 1, "reward": {"gold": 250}},
	{"id": "boss_eye", "name": "Szemtől szemben", "text": "Győzd le A Mélység Szemét.", "kind": "boss",
		"target": "A Mélység Szeme", "goal": 1, "reward": {"gold": 300}},
	{"id": "boss_slime", "name": "Ragacsos győzelem", "text": "Győzd le a Nyálkakirályt.", "kind": "boss",
		"target": "Nyálkakirály", "goal": 1, "reward": {"gold": 300}},
	{"id": "kings_all", "name": "Királyok veszte", "text": "Győzd le mind a hét régi királyt (Ogrekirály, Orkhadúr, "
		+ "Gyíkkirály, Démonúr, Nekromanta-főpap, Jégóriás, Zombikirály).", "kind": "kings", "goal": 7,
		"reward": {"gold": 700, "dust": {"epic": 1}}},
	{"id": "undead_500", "name": "Sírásó segédje", "text": "Ölj meg 500 élőholtat.", "kind": "category",
		"target": "Élőholtak", "goal": 500, "reward": {"gold": 200}},
	{"id": "greenskins_500", "name": "Goblinvadász", "text": "Ölj meg 500 zöldbőrűt.", "kind": "category",
		"target": "Zöldbőrűek", "goal": 500, "reward": {"gold": 200}},
	{"id": "bugs_300", "name": "Rovarirtó", "text": "Ölj meg 300 bogarat.", "kind": "category",
		"target": "Bogarak", "goal": 300, "reward": {"gold": 200}},
	{"id": "pirates_200", "name": "Fedélzetsöprő", "text": "Ölj meg 200 kalózt.", "kind": "category",
		"target": "Kalózok", "goal": 200, "reward": {"gold": 200}},
	{"id": "dragons_50", "name": "Sárkányölő", "text": "Ölj meg 50 sárkányt.", "kind": "category",
		"target": "Sárkányok", "goal": 50, "reward": {"gold": 400}},
	{"id": "chaos_300", "name": "Rendteremtő", "text": "Ölj meg 300 káoszlényt.", "kind": "category",
		"target": "Káosz", "goal": 300, "reward": {"gold": 400}},
	{"id": "frost_300", "name": "Jégtörő", "text": "Ölj meg 300 fagyott lényt a Fagykőben.", "kind": "category",
		"target": "Fagyott lények", "goal": 300, "reward": {"gold": 500}},
	{"id": "category_full", "name": "Teljes fejezet", "text": "Töltsd ki a Szörnyek könyvének egy teljes fülét "
		+ "(minden szörnyét öld meg legalább egyszer).", "kind": "full_category", "goal": 1, "reward": {"gold": 300}},
	{"id": "rare_items_20", "name": "Kék fény", "text": "Szerezz 20 különféle ritka tárgyat.", "kind": "rarity",
		"target": "rare", "goal": 20, "reward": {"gold": 150}},
	{"id": "epic_items_15", "name": "Bíbor kincs", "text": "Szerezz 15 különféle epikus tárgyat.", "kind": "rarity",
		"target": "epic", "goal": 15, "reward": {"gold": 300}},
	{"id": "legendary_items_10", "name": "Legendák nyomában", "text": "Szerezz 10 különféle legendás tárgyat.",
		"kind": "rarity", "target": "legendary", "goal": 10, "reward": {"gold": 600}},
	{"id": "mythic_items_3", "name": "Mítoszok őrzője", "text": "Szerezz 3 különféle mítikus tárgyat.",
		"kind": "rarity", "target": "mythic", "goal": 3, "reward": {"gold": 800, "dust": {"legendary": 1}}},
	{"id": "upgrades_5", "name": "Tábori ezermester", "text": "Vásárolj összesen 5 szint tábori fejlesztést.",
		"kind": "upgrades", "goal": 5, "reward": {"gold": 150}},
	{"id": "upgrades_20", "name": "A tábor építője", "text": "Vásárolj összesen 20 szint tábori fejlesztést.",
		"kind": "upgrades", "goal": 20, "reward": {"gold": 500}},
]


## Hol tart a teljesítmény (a cél fölé is mehet).
static func progress(entry: Dictionary) -> int:
	match str(entry["kind"]):
		"kills":
			var total := 0
			for count: Variant in Progress.kills.values():
				total += int(count)
			return total
		"deepest":
			return Progress.deepest
		"quests":
			return Progress.quests_done.size()
		"kinds":
			return Progress.kills.size()
		"items":
			return Progress.seen_items.size()
		"demons":
			var total := 0
			for demon: String in DEMONS:
				total += Bestiary.kills(demon)
			return total
		"boss":
			return Bestiary.kills(str(entry["target"]))
		"kings":
			var beaten := 0
			for king: String in Bestiary.KINGS:
				if Bestiary.kills(king) > 0:
					beaten += 1
			return beaten
		"category":
			var total := 0
			for category: Array in Bestiary.CATEGORIES:
				if category[0] == entry["target"]:
					for monster: String in category[1]:
						total += Bestiary.kills(monster)
			return total
		"full_category":
			for i in Bestiary.CATEGORIES.size():
				if Bestiary.discovered(i).size() == Bestiary.CATEGORIES[i][1].size():
					return 1
			return 0
		"rarity":
			var count := 0
			for id: String in Progress.seen_items:
				if Items.DEFINITIONS.has(id) and Items.DEFINITIONS[id]["rarity"] == entry["target"]:
					count += 1
			return count
		"upgrades":
			var levels := 0
			for level: Variant in Progress.upgrades.values():
				levels += int(level)
			return levels
	return 0


static func reached(entry: Dictionary) -> bool:
	return progress(entry) >= int(entry["goal"])


static func claimed(entry: Dictionary) -> bool:
	return Progress.rewards_claimed.has("ach_" + str(entry["id"]))


## Átveszi a jutalmat (ha már elérte, és még nem vette át).
static func claim(entry: Dictionary) -> bool:
	if claimed(entry) or not reached(entry):
		return false
	Progress.rewards_claimed["ach_" + str(entry["id"])] = true
	grant(entry["reward"])
	return true


static func done_count() -> int:
	var count := 0
	for entry in LIST:
		if reached(entry):
			count += 1
	return count


## Ennyi elért, de még át nem vett jutalom vár.
static func waiting() -> int:
	var count := 0
	for entry in LIST:
		if reached(entry) and not claimed(entry):
			count += 1
	return count


## Egy könyvjutalom kiosztása: arany a tábori kincsbe, por a kovácshoz; utána mentés.
static func grant(reward: Dictionary) -> void:
	var gold := int(reward.get("gold", 0))
	if gold > 0:
		Progress.add_camp_gold(gold)
	var dust: Dictionary = reward.get("dust", {})
	for rarity: String in dust:
		Progress.add_dust(rarity, int(dust[rarity]))
	Progress.save_game()


## A jutalom olvashatóan, pl. "250 arany, 2 ritka por".
static func reward_text(reward: Dictionary) -> String:
	var parts: Array[String] = []
	var gold := int(reward.get("gold", 0))
	if gold > 0:
		parts.append("%d arany" % gold)
	var dust: Dictionary = reward.get("dust", {})
	for rarity: String in dust:
		parts.append("%d %s por" % [int(dust[rarity]), str(Items.RARITIES[rarity]["name"]).to_lower()])
	return ", ".join(parts)
