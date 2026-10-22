class_name Profiles
## Mentési profilok (a főmenü jobb alsó sarkában): Profil 1-3, mindegyiknek saját tábori mentése
## és eredménytáblája. Az 1. profil a régi mentés (user://save.cfg, user://records.cfg), így a
## meglévő haladás megmarad. Hogy melyik profil az aktív, a user://profile.cfg tárolja; a hang és
## a teljes képernyő beállításai közösek (Audio).

const COUNT := 3
const SETTINGS_PATH := "user://profile.cfg"

static var _current := 0


## Az aktív profil száma (1..COUNT).
static func current() -> int:
	if _current == 0:
		var config := ConfigFile.new()
		_current = int(config.get_value("profile", "current", 1)) if config.load(SETTINGS_PATH) == OK else 1
		_current = clampi(_current, 1, COUNT)
	return _current


## A profil tábori mentése (0 = az aktív profilé).
static func save_path(profile := 0) -> String:
	var number := current() if profile == 0 else profile
	return "user://save.cfg" if number == 1 else "user://save_%d.cfg" % number


## A profil eredménytáblája (0 = az aktív profilé).
static func records_path(profile := 0) -> String:
	var number := current() if profile == 0 else profile
	return "user://records.cfg" if number == 1 else "user://records_%d.cfg" % number


## Profilváltás: elmenti a választást, és betölti az új profil mentését.
static func select(profile: int) -> void:
	_current = clampi(profile, 1, COUNT)
	var config := ConfigFile.new()
	config.set_value("profile", "current", _current)
	config.save(SETTINGS_PATH)
	Progress.load_game(true)


## Rövid összefoglaló a gombra: "üres", vagy pl. "Lovag · 350 arany".
static func summary(profile: int) -> String:
	var config := ConfigFile.new()
	if config.load(save_path(profile)) != OK:
		return "üres"
	var character := str(config.get_value("camp", "character", Characters.DEFAULT))
	return "%s · %d arany" % [Characters.data(character)["name"], int(config.get_value("camp", "gold", 0))]
