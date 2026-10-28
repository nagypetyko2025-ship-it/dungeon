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
		"reward": {"gold": 250, "dust": {"rare": 2}}},
	{"id": "kills_5000", "name": "A kazamata réme", "text": "Ölj meg 5000 szörnyet.", "kind": "kills", "goal": 5000,
		"reward": {"gold": 500, "dust": {"epic": 2}}},
	{"id": "kills_20000", "name": "Élő legenda", "text": "Ölj meg 20 000 szörnyet.", "kind": "kills", "goal": 20000,
		"reward": {"gold": 1000, "dust": {"legendary": 2}}},
	{"id": "deep_10", "name": "Lépcsőről lépcsőre", "text": "Juss le a 10. emeletre.", "kind": "deepest", "goal": 10,
		"reward": {"gold": 100}},
	{"id": "deep_20", "name": "A sötétség szélén", "text": "Juss le a 20. emeletre.", "kind": "deepest", "goal": 20,
		"reward": {"gold": 200, "dust": {"rare": 2}}},
	{"id": "deep_40", "name": "A Káoszkő mélyén", "text": "Juss le a 40. emeletre.", "kind": "deepest", "goal": 40,
		"reward": {"gold": 400, "dust": {"epic": 2}}},
	{"id": "deep_60", "name": "Jégbe zárva", "text": "Juss le a 60. emeletre.", "kind": "deepest", "goal": 60,
		"reward": {"gold": 600, "dust": {"epic": 3}}},
	{"id": "deep_81", "name": "A pokol kapujában", "text": "Juss le a 81. emeletre, a Vérkőbe.", "kind": "deepest",
		"goal": 81, "reward": {"gold": 800, "dust": {"legendary": 2}}},
	{"id": "deep_100", "name": "A mélység alja", "text": "Juss le a 100. emeletre.", "kind": "deepest", "goal": 100,
		"reward": {"gold": 1200, "dust": {"legendary": 3}}},
	{"id": "quests_10", "name": "Szavahihető", "text": "Teljesíts 10 küldetést.", "kind": "quests", "goal": 10,
		"reward": {"gold": 150}},
	{"id": "quests_30", "name": "A kocsma kedvence", "text": "Teljesíts 30 küldetést.", "kind": "quests", "goal": 30,
		"reward": {"gold": 300, "dust": {"rare": 2}}},
	{"id": "quests_60", "name": "Mindenki hőse", "text": "Teljesíts 60 küldetést.", "kind": "quests", "goal": 60,
		"reward": {"gold": 600, "dust": {"epic": 2}}},
	{"id": "quests_100", "name": "Nincs több hirdetmény", "text": "Teljesíts 100 küldetést.", "kind": "quests",
		"goal": 100, "reward": {"gold": 1000, "dust": {"legendary": 2}}},
	{"id": "kinds_25", "name": "Kíváncsi vadász", "text": "Ölj meg 25 különféle szörnyet.", "kind": "kinds", "goal": 25,
		"reward": {"gold": 150}},
	{"id": "kinds_60", "name": "Szörnytudós", "text": "Ölj meg 60 különféle szörnyet.", "kind": "kinds", "goal": 60,
		"reward": {"gold": 400, "dust": {"epic": 2}}},
	{"id": "kinds_100", "name": "A Szörnyek könyve szerzője", "text": "Ölj meg 100 különféle szörnyet.",
		"kind": "kinds", "goal": 100, "reward": {"gold": 800, "dust": {"legendary": 2}}},
	{"id": "items_30", "name": "Gyűjtögető", "text": "Szerezz 30 különféle tárgyat.", "kind": "items", "goal": 30,
		"reward": {"gold": 150}},
	{"id": "items_80", "name": "Kincsvadász", "text": "Szerezz 80 különféle tárgyat.", "kind": "items", "goal": 80,
		"reward": {"gold": 400, "dust": {"epic": 2}}},
	{"id": "items_140", "name": "Múzeumigazgató", "text": "Szerezz 140 különféle tárgyat.", "kind": "items",
		"goal": 140, "reward": {"gold": 800, "dust": {"legendary": 2}}},
	{"id": "demons_50", "name": "Démonűző", "text": "Ölj meg 50 démont a Vérkőben (pokolkutya, pokolfajzat, "
		+ "lidércló, pokolúr).", "kind": "demons", "goal": 50, "reward": {"gold": 600, "dust": {"epic": 3}}},
	{"id": "demons_300", "name": "A pokol ostora", "text": "Ölj meg 300 démont a Vérkőben.", "kind": "demons",
		"goal": 300, "reward": {"gold": 1200, "dust": {"legendary": 3}}},
	{"id": "boss_lord", "name": "A Mélység Ura", "text": "Győzd le a Vérfarkast, a Mélység Urát.", "kind": "boss",
		"target": Bestiary.LORD, "goal": 1, "reward": {"gold": 400, "dust": {"epic": 2}}},
	{"id": "boss_scorpion", "name": "Méregfogó", "text": "Győzd le a Skorpiókirályt.", "kind": "boss",
		"target": "Skorpiókirály", "goal": 1, "reward": {"gold": 400, "dust": {"epic": 2}}},
	{"id": "boss_frost", "name": "Olvadás", "text": "Győzd le a Jégkirálynőt.", "kind": "boss",
		"target": "Jégkirálynő", "goal": 1, "reward": {"gold": 600, "dust": {"legendary": 1}}},
	{"id": "boss_chaos", "name": "Az üresség vége", "text": "Győzd le Ürességfalót, a Káosz Urát.", "kind": "boss",
		"target": Bestiary.CHAOS_LORD, "goal": 1, "reward": {"gold": 1000, "dust": {"legendary": 2}}},
	{"id": "boss_knocker", "name": "Csend a tárnákban", "text": "Győzd le a Kopogót a bánya mélyén.", "kind": "boss",
		"target": "A Kopogó", "goal": 1, "reward": {"gold": 300, "dust": {"epic": 1}}},
	{"id": "boss_lake", "name": "A tó nyugalma", "text": "Győzd le a Tófenék Urát az elárasztott kriptában.",
		"kind": "boss", "target": "A Tófenék Ura", "goal": 1, "reward": {"gold": 300, "dust": {"epic": 1}}},
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
