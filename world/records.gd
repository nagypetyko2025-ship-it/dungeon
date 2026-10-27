class_name Records
## Eredménytábla: a futások végén (halál vagy feladás) elmenti, meddig jutottál,
## mennyi aranyad volt és hány szörnyet öltél meg. Az 5 legjobbat tartja meg, rangsorolva:
## előbb a mélység, aztán az arany, aztán a megölt szörnyek száma dönt.

## Az eredménytábla helye az aktív profiltól függ (lásd Profiles).
static func path() -> String:
	return Profiles.records_path()
const MAX_ENTRIES := 5


## Az eddigi legjobb futások, a legjobbtól kezdve. Minden elem:
## {character, depth, gold, kills, level, time, date, exits} (a régieknél nincs "character": lovag)
static func top() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var config := ConfigFile.new()
	if config.load(path()) != OK:
		return result
	var saved: Variant = config.get_value("records", "entries", [])
	if saved is Array:
		for entry: Variant in saved:
			if entry is Dictionary:
				result.append(entry)
	result.sort_custom(_better)
	return result


## Elmenti a futást; visszaadja, hányadik helyre került (1–5), vagy 0-t, ha nem fért be.
static func submit(depth: int, gold: int, kills: int, level: int, time: float, exits := 0) -> int:
	var entry := {
		"character": Progress.character,
		"depth": depth, "gold": gold, "kills": kills, "level": level,
		"time": int(time), "date": Time.get_date_string_from_system(), "exits": exits,
	}
	var entries := top()
	entries.append(entry)
	entries.sort_custom(_better)
	var rank := entries.find(entry) + 1
	entries.resize(mini(entries.size(), MAX_ENTRIES))
	var config := ConfigFile.new()
	config.set_value("records", "entries", entries)
	config.save(path())
	return rank if rank <= MAX_ENTRIES else 0


## A futás végének rögzítése a játékos aktuális állapotából (csak egyszer futásonként).
static func submit_run(player: Node) -> int:
	if GameState.run_recorded or player == null:
		return 0
	GameState.run_recorded = true
	# A próbatétel nem kerül az eredmények közé.
	if Challenge.active():
		return 0
	# Csalt futás nem kerül az eredmények közé.
	if GameState.cheated:
		return 0
	var experience: Experience = player.get_node("Experience")
	var gold := int(player.get("gold")) + GameState.break_gold_left
	return submit(GameState.depth, gold, GameState.kills, experience.level, GameState.run_time, GameState.exits)


static func _better(a: Dictionary, b: Dictionary) -> bool:
	for key: String in ["depth", "gold", "kills"]:
		if int(a[key]) != int(b[key]):
			return int(a[key]) > int(b[key])
	return false
