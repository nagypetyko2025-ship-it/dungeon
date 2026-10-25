class_name RunSave
## A félbehagyott futás mentése: ha a főellenség utáni pihenő alatt (a táborban, lásd
## BossReturnPanel / Camp._setup_break) lépsz ki, a futás teljes állapota (emelet, statok, szint, XP,
## arany, a nálad lévő tárgyak, varázslatok, bájitalok, a vándorárus kínálata...) ide mentődik, és a
## főmenü "Folytatás" gombjával onnan folytathatod, ahol abbahagytad (a pihenő-táborban, a kék
## portállal vissza a főellenség termébe). Profilonként külön fájl; közös (többjátékos) játékban nincs.
## Ha visszamész a kazamatába, vagy a futás véget ér (feladod, új játék), a mentés törlődik.

## A futás állapota (a GameState mentett mezői) szótárként.
static func _state() -> Dictionary:
	return {"depth": GameState.depth, "saved_stats": GameState.saved_stats, "saved_health": GameState.saved_health,
		"saved_level": GameState.saved_level, "saved_xp": GameState.saved_xp, "saved_gold": GameState.saved_gold,
		"saved_inventory": GameState.saved_inventory, "kills": GameState.kills,
		"chests_opened": GameState.chests_opened, "spells": GameState.spells, "spell_levels": GameState.spell_levels,
		"run_time": GameState.run_time, "lift_used_floor": GameState.lift_used_floor,
		"break_gold_left": GameState.break_gold_left, "break_floor": GameState.break_floor, "exits": GameState.exits,
		"merchant_stock": GameState.merchant_stock, "rerolls": GameState.rerolls, "potions": GameState.potions,
		"cheated": GameState.cheated}


static func _apply(state: Dictionary) -> void:
	GameState.depth = int(state.get("depth", 1))
	GameState.saved_stats = state.get("saved_stats", {})
	GameState.saved_health = int(state.get("saved_health", -1))
	GameState.saved_level = int(state.get("saved_level", 1))
	GameState.saved_xp = int(state.get("saved_xp", 0))
	GameState.saved_gold = int(state.get("saved_gold", 0))
	GameState.saved_inventory = state.get("saved_inventory", {})
	GameState.kills = int(state.get("kills", 0))
	GameState.chests_opened = int(state.get("chests_opened", 0))
	GameState.spells = state.get("spells", [])
	GameState.spell_levels = state.get("spell_levels", {})
	GameState.run_time = float(state.get("run_time", 0.0))
	GameState.lift_used_floor = int(state.get("lift_used_floor", 0))
	GameState.break_gold_left = int(state.get("break_gold_left", 0))
	GameState.break_floor = state.get("break_floor", {})
	GameState.exits = int(state.get("exits", 0))
	GameState.merchant_stock = state.get("merchant_stock", [])
	GameState.rerolls = int(state.get("rerolls", 0))
	GameState.potions = int(state.get("potions", 0))
	GameState.cheated = bool(state.get("cheated", false))


static func path(profile := 0) -> String:
	var number := Profiles.current() if profile == 0 else profile
	return "user://run.cfg" if number == 1 else "user://run_%d.cfg" % number


## Van-e félbehagyott (pihenőnél abbahagyott) futás ezen a profilon.
static func exists() -> bool:
	return not Profiles.multiplayer and FileAccess.file_exists(path())


## A futás állapotának mentése (a pihenő-táborban; a játékos állapotát előbb a GameState-be írja).
static func save(player: Node) -> void:
	if Profiles.multiplayer or GameState.tutorial or not GameState.on_break:
		return
	if is_instance_valid(player) and player.has_method("save_state"):
		player.call("save_state")
	var config := ConfigFile.new()
	config.set_value("run", "state", _state())
	config.save(path())


## A mentett futás visszatöltése a GameState-be (pihenőként: a tábor a kék portállal indul).
static func restore() -> bool:
	var config := ConfigFile.new()
	if config.load(path()) != OK:
		return false
	var state: Variant = config.get_value("run", "state", {})
	if not state is Dictionary:
		return false
	GameState.reset()
	_apply(state)
	GameState.on_break = true
	return true


static func clear() -> void:
	if FileAccess.file_exists(path()):
		DirAccess.remove_absolute(path())


## Rövid leírás a főmenühöz, pl. "pihenő a 9. emelet után".
static func summary() -> String:
	var config := ConfigFile.new()
	if config.load(path()) != OK:
		return ""
	var state: Variant = config.get_value("run", "state", {})
	return "pihenő a %d. emelet után" % int(state.get("depth", 1)) if state is Dictionary else ""
