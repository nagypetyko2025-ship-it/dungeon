class_name NetSession
## A többjátékos mód közös beállításai és segédei (a váró maga: NetLobby).
##
## Felállás: gazda–vendég (ENet). A gazda készít egy várót (6 jegyű kód azonosítja), és a helyi
## hálózaton (LAN) másodpercenként bejelenti a kódját és a nevét (UDP üzenetszórás). A csatlakozó
## ezeket figyelve listázza a várókat, és a kiválasztotthoz csatlakozik (kódot nem kell beírni).
## Így csak ugyanazon a hálózaton lehet csatlakozni (internethez szerver kellene).
##
## A tervezett lépések:
##   1. Váró: kód, játékosok (legfeljebb 4), "készen állok", indítás – kész (NetLobby).
##   2. Közös tábor: mindenki a saját táborába kerül, és látja a többieket – kész (NetAvatars).
##   3. Közös kazamata: a gazda pályája (közös mag), a szörnyek és a sebzés a gazdánál dől el.
##   4. Zsákmány: a tárgyak és az arany a felvevőé.

const ENABLED := true
const GAME_PORT := 24565
## Ezen a porton jelentik be magukat a várók a helyi hálózaton.
const BEACON_PORT := 24566
const MAX_PLAYERS := 4
const CODE_DIGITS := 6
const NAME_MAX_LENGTH := 16
const PLAYER_PATH := "user://player.cfg"


## A beállításokban megadott fix név ("" ha nincs: ilyenkor a váró előtt rákérdez).
static func fixed_name() -> String:
	var config := ConfigFile.new()
	if config.load(PLAYER_PATH) != OK:
		return ""
	return clean_name(str(config.get_value("player", "name", "")))


static func set_fixed_name(value: String) -> void:
	var config := ConfigFile.new()
	config.load(PLAYER_PATH)
	config.set_value("player", "name", clean_name(value))
	config.save(PLAYER_PATH)


static func clean_name(value: String) -> String:
	return value.strip_edges().left(NAME_MAX_LENGTH)


## Véletlen 6 jegyű kód, ami nem egyezik egyik `taken` kóddal sem (a most hirdetett várókéval).
static func new_code(taken: Array) -> String:
	var code := ""
	while code.is_empty() or taken.has(code):
		code = str(randi_range(10 ** (CODE_DIGITS - 1), 10 ** CODE_DIGITS - 1))
	return code


static func is_valid_code(value: String) -> bool:
	return value.length() == CODE_DIGITS and value.is_valid_int()
