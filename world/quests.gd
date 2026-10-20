class_name Quests
## Küldetések a kocsmárostól (a városban, a Mélységi kocsmában). Egyszerre egy lehet
## felvéve; a haladás csak a kazamatában számít (a gyakorló pályán nem), futásokon át
## összeadódik, és mentődik (Progress). Ha kész, a kocsmárosnál leadod a jutalomért:
## arany (a táborba) vagy tárgy (a tábori ládába). Minden küldetés egyszer teljesíthető.
##
## kind:   kill (target: szörnytípusok, üres = bármilyen), floor (elért emelet),
##         level (elért karakterszint), chest (kinyitott láda), gold (felszedett arany),
##         room (kitisztított szoba), boss (legyőzött főellenség)
## goal:   ennyi kell; "floor"/"level"-nél a legnagyobb elért érték számít
## reward: {"gold": n} vagy {"item": ritkaság}

const ALL := {
	"rat_catcher": {"name": "Kártevőirtás", "kind": "kill", "goal": 15, "target": [],
		"text": "Ölj meg 15 szörnyet a kazamatában.", "reward": {"gold": 60}},
	"bone_dust": {"name": "Csontok porrá", "kind": "kill", "goal": 6, "target": ["skelet"],
		"text": "Ölj meg 6 csontvázat.", "reward": {"item": "rare"}},
	"goblin_hunter": {"name": "Goblinvadász", "kind": "kill", "goal": 8, "target": ["goblin"],
		"text": "Ölj meg 8 goblint.", "reward": {"gold": 50}},
	"zombie_plague": {"name": "Zombijárvány", "kind": "kill", "goal": 6, "target": ["tiny_zombie", "zombie"],
		"text": "Ölj meg 6 zombit (kis zombi is számít).", "reward": {"gold": 55}},
	"into_the_deep": {"name": "Le a mélybe", "kind": "floor", "goal": 3,
		"text": "Juss le a 3. emeletre.", "reward": {"item": "rare"}},
	"seasoned": {"name": "Tapasztalt kalandor", "kind": "level", "goal": 5,
		"text": "Érd el az 5. karakterszintet egy futásban.", "reward": {"gold": 80}},
	"treasure_hunter": {"name": "Kincskereső", "kind": "chest", "goal": 4,
		"text": "Nyiss ki 4 ládát.", "reward": {"gold": 70}},
	"pocket_money": {"name": "Zsebpénz", "kind": "gold", "goal": 100,
		"text": "Szedj fel összesen 100 aranyat.", "reward": {"item": "rare"}},
	"cleaner": {"name": "Nagytakarítás", "kind": "room", "goal": 8,
		"text": "Tisztíts ki 8 szobát.", "reward": {"gold": 60}},
	"first_king": {"name": "Az első király", "kind": "boss", "goal": 1,
		"text": "Győzz le egy főellenséget (a 3. emeleten vár).", "reward": {"item": "epic"}},
}


## Esemény a kazamatából: a felvett küldetés haladása (ha illik rá).
## `value`: kill-nél a szörnytípus neve, gold-nál az összeg, floor/level-nél az érték.
static func notify(kind: String, value: Variant = 1) -> void:
	if GameState.tutorial or Progress.quest.is_empty():
		return
	var definition: Dictionary = ALL.get(Progress.quest["id"], {})
	if definition.is_empty() or definition["kind"] != kind or is_complete():
		return
	var progress := int(Progress.quest.get("progress", 0))
	match kind:
		"kill":
			var targets: Array = definition.get("target", [])
			if not targets.is_empty() and not targets.has(str(value)):
				return
			progress += 1
		"gold":
			progress += int(value)
		"floor", "level":
			progress = maxi(progress, int(value))
		_:
			progress += 1
	Progress.quest["progress"] = mini(progress, int(definition["goal"]))
	Progress.save_game()


static func active() -> Dictionary:
	return ALL.get(Progress.quest.get("id", ""), {})


static func is_complete() -> bool:
	var definition := active()
	return not definition.is_empty() and int(Progress.quest.get("progress", 0)) >= int(definition["goal"])


## Rövid szöveg a kijelzőnek, pl. "Goblinvadász: 3 / 8" ("" ha nincs küldetés).
static func tracker_text() -> String:
	var definition := active()
	if definition.is_empty():
		return ""
	if is_complete():
		return "%s — kész! Add le a kocsmárosnál." % definition["name"]
	return "%s: %d / %d" % [definition["name"], int(Progress.quest.get("progress", 0)), definition["goal"]]


static func reward_text(id: String) -> String:
	var reward: Dictionary = ALL[id]["reward"]
	if reward.has("gold"):
		return "%d tábori arany" % reward["gold"]
	return "%s tárgy (a tábori ládába)" % Items.RARITIES[reward["item"]]["name"].to_lower()


static func accept(id: String) -> bool:
	if not Progress.quest.is_empty() or Progress.quests_done.has(id):
		return false
	Progress.quest = {"id": id, "progress": 0}
	Progress.save_game()
	return true


static func abandon() -> void:
	Progress.quest = {}
	Progress.save_game()


## Leadás: jutalom, a küldetés teljesítettnek számít. Visszaadja a jutalom leírását ("" ha nem kész).
static func turn_in() -> String:
	if not is_complete():
		return ""
	var id: String = Progress.quest["id"]
	var reward: Dictionary = ALL[id]["reward"]
	var text := ""
	if reward.has("gold"):
		Progress.camp_gold += int(reward["gold"])
		text = "+%d tábori arany" % reward["gold"]
	else:
		var item := Items.random_item(reward["item"], reward["item"])
		Progress.stash.append(item)
		text = "%s (a tábori ládába került)" % item["name"]
	Progress.quests_done.append(id)
	Progress.quest = {}
	Progress.save_game()
	return text
