extends SceneTree
## Egyensúly-robot: a játék saját függvényeivel (emelet-generálás, EnemyTypes.pick/roll, Upgrades.roll, Items)
## végigszámolja a játékot, és kiírja, mi lóg ki. Nem játszik, hanem mér:
##   1. Szintgörbe: emeletenként mennyi XP jön (a valódi, legenerált emeletek szobáiból), és hányadik szinten
##      jár egy átlagos játékos (XP-bónusz nélkül); ebből: melyik szintes / emeletes küldetés mikor teljesül.
##   2. Kártyák: a sorsolás gyakorisága ritkaságonként, és ritkaságon belül a túl erős / túl gyenge lapok.
##   3. Tárgyak: ritkaság szerint a túl erős / túl gyenge tárgyak (a statok súlyozott összege).
##   4. Szörnyek: a velük egy mélységben járókhoz képest túl szívós / túl veszélyes / túl sok XP-t adó szörnyek.
## Futtatás (a mentéseket nem bántja: a 9-es tesztprofilt használja, a végén törli):
##   Godot --path . --headless --script res://tools/balance_robot.gd
## Eredmény: res://tools/balance_report.md

const OUT := "res://tools/balance_report.md"
const Boss := preload("res://enemies/boss.gd")
const MAX_DEPTH := 99
const XP_SAMPLES := 300
const CARD_ROLLS := 4000
const ITEM_SAMPLES := 40
## Valós kalibráció (a felhasználó tapasztalata): ügyes játékkal a 15. emeleten a 30. szint körül jársz. Ebből jön,
## a teljes (minden szoba, minden gömb) XP hányad részét szerzi meg egy valódi futás; a "valós" oszlop ezzel számol.
const CALIBRATION_FLOOR := 15
const CALIBRATION_LEVEL := 30
## Ennyiszeres eltérés a csoport mediánjától számít kilógónak.
const OUTLIER := 1.6

var _lines: PackedStringArray = []


func _initialize() -> void:
	Profiles._current = 9
	Progress.load_game(true)
	_line("# Egyensúly-jelentés")
	_line("")
	_line("Készült: %s (tools/balance_robot.gd). Minden szám becslés, XP-bónusz és csalás nélkül." % Time.get_datetime_string_from_system(false, true))
	_line("")
	await _level_curve()
	_cards()
	_items()
	_enemies()
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	file.store_string("\n".join(_lines) + "\n")
	file.close()
	print("KÉSZ: ", ProjectSettings.globalize_path(OUT))
	for name in ["save_9.cfg", "records_9.cfg", "run_9.cfg"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://" + name))
	quit()


func _line(text: String) -> void:
	_lines.append(text)
	print(text)


# ---------------------------------------------------------------- 1. szintgörbe

func _level_curve() -> void:
	_line("## 1. Szintgörbe (a valódi emelet-generálással)")
	_line("")
	_line("| Emelet | Összes XP (minden szoba, minden gömb) | Szint (elméleti maximum) | Szint (valós becslés) |")
	_line("|---|---|---|---|")
	var total := 0
	var level := 1
	var level_at := {}
	var totals := {}
	var boss_xp := 0.0
	for boss: Dictionary in Boss.BOSSES:
		boss_xp += float(boss["xp"])
	boss_xp /= Boss.BOSSES.size()
	for depth in range(1, MAX_DEPTH + 1):
		var count := await _enemies_on_floor(depth)
		var xp := 0.0
		for i in XP_SAMPLES:
			xp += EnemyTypes.roll(EnemyTypes.pick(depth), depth)["xp"]
		xp = xp / XP_SAMPLES * count
		if depth % Boss.BOSS_EVERY == 0:
			xp += boss_xp * (1.0 + 0.2 * (depth - 1)) * Boss.TOUGHNESS_XP
		total += roundi(xp)
		while total >= _xp_to_reach(level + 1):
			level += 1
		level_at[depth] = level
		totals[depth] = total
	# A valós arány a kalibrációból, és vele a valós szintgörbe.
	var share := float(_xp_to_reach(CALIBRATION_LEVEL)) / float(totals[CALIBRATION_FLOOR])
	var half_at := {}
	var real_level := 1
	for depth in range(1, MAX_DEPTH + 1):
		while float(totals[depth]) * share >= _xp_to_reach(real_level + 1):
			real_level += 1
		half_at[depth] = real_level
	for depth in range(1, MAX_DEPTH + 1):
		if depth <= 5 or depth % 5 == 0:
			_line("| %d | %d | %d | %d |" % [depth, totals[depth], level_at[depth], half_at[depth]])
	_line("")
	_line("Valós arány: a teljes XP %.0f%%-a (kalibráció: %d. emelet = %d. szint)." % [share * 100.0, CALIBRATION_FLOOR, CALIBRATION_LEVEL])
	_line("")
	_line("### Szintes és emeletes küldetések: hol teljesülnek")
	_line("")
	_line("| Küldetés | Megbízó | Fokozat | Cél | Becslés |")
	_line("|---|---|---|---|---|")
	for id: String in Quests.ALL:
		var quest: Dictionary = Quests.ALL[id]
		var goal := int(quest["goal"])
		var estimate := ""
		match quest["kind"]:
			"level":
				var full := _first_floor(level_at, goal)
				var half := _first_floor(half_at, goal)
				estimate = "valósan a %s (legkorábban a %s)" % [_floor_text(half), _floor_text(full)]
				# Figyelmeztetés: a fokozatához képest (valósan) túl korán megvan.
				if half > 0 and _too_easy(quest.get("tier", "easy"), half):
					estimate += " ⚠ túl könnyű a fokozatához"
			"floor":
				estimate = "valósan a %d. szint körül" % half_at[mini(goal, MAX_DEPTH)]
			_:
				continue
		_line("| %s | %s | %s | %s %d | %s |" % [quest["name"], Quests.giver_of(id), quest.get("tier", "easy"), quest["kind"], goal, estimate])
	_line("")


## Az első emelet, ahol a szint eléri a célt (-1: 99 emelet alatt sem).
func _first_floor(levels: Dictionary, goal: int) -> int:
	for depth in range(1, MAX_DEPTH + 1):
		if int(levels[depth]) >= goal:
			return depth
	return -1


func _floor_text(depth: int) -> String:
	return "%d. emeleten" % depth if depth > 0 else "99 emelet alatt sem"


## Ennyi összes XP kell az adott szint eléréséhez.
func _xp_to_reach(target_level: int) -> int:
	var sum := 0
	for l in range(1, target_level):
		sum += Experience.xp_for_level(l)
	return sum


## A fokozat szerint ennél korábbi emeleten "túl könnyű" a szintes küldetés.
func _too_easy(tier: String, floor_needed: int) -> bool:
	match tier:
		"elite": return floor_needed < 45
		"hard": return floor_needed < 20
		"medium": return floor_needed < 6
	return false


## A valódi emelet-generálással: hány szörny van az emeleten (a főellenség nélkül).
func _enemies_on_floor(depth: int) -> int:
	GameState.reset()
	GameState.depth = depth
	change_scene_to_file("res://world/dungeon.tscn")
	for f in 4:
		await process_frame
	var count := 0
	var rooms := current_scene.get_node_or_null("Entities/Rooms") if current_scene != null else null
	if rooms != null:
		for room in rooms.get_children():
			if room is Room:
				count += maxi(0, int(room.get("enemy_count")))
	return count


# ---------------------------------------------------------------- 2. kártyák

func _cards() -> void:
	_line("## 2. Kártyák")
	_line("")
	var stats := Stats.new()
	root.add_child(stats)
	var by_rarity := {}
	var seen := {}
	for i in CARD_ROLLS:
		for card in Upgrades.roll(stats, 3, i % 2 == 0, 20):
			by_rarity[card["rarity"]] = int(by_rarity.get(card["rarity"], 0)) + 1
			seen[card.get("id", "")] = true
	var shown := CARD_ROLLS * 3
	_line("Sorsolás (%d szintlépés, 20. szint felett): " % CARD_ROLLS + ", ".join(
		["common", "rare", "epic", "legendary", "mythic"].map(func(r: String) -> String:
			return "%s %.1f%%" % [r, 100.0 * int(by_rarity.get(r, 0)) / shown])))
	_line("")
	var never: Array[String] = []
	for card in Upgrades.cards():
		if not seen.has(card.get("id", "")):
			never.append(str(card.get("title", card.get("id", ""))))
	if not never.is_empty():
		_line("Soha nem jött fel (lehet, hogy karakterhez / íjhoz kötött): " + ", ".join(never))
		_line("")
	# Erősség: a stat-értékek a saját statjuk mediánjához mérve (nyereség +, költség -).
	var medians := _stat_medians(Upgrades.cards().map(func(c: Dictionary) -> Dictionary: return c["gain"]))
	var scored := []
	for card in Upgrades.cards():
		var score := 0.0
		for stat: String in card["gain"]:
			score += absf(float(card["gain"][stat])) / medians.get(stat, 1.0)
		for stat: String in card.get("cost", {}):
			score -= absf(float(card["cost"][stat])) / medians.get(stat, 1.0) * 0.8
		scored.append([str(card.get("title", "")), str(card["rarity"]), score])
	_outliers("Kártya", scored)
	stats.free()


# ---------------------------------------------------------------- 3. tárgyak

func _items() -> void:
	_line("## 3. Tárgyak (fegyverek nélkül: azok ereje az alapsebzésük)")
	_line("")
	var ranges: Array = []
	for id: String in Items.DEFINITIONS:
		var def: Dictionary = Items.DEFINITIONS[id]
		var mids := {}
		for stat: String in def.get("stats", {}):
			var pair: Array = def["stats"][stat]
			mids[stat] = (float(pair[0]) + float(pair[1])) / 2.0
		ranges.append(mids)
	var medians := _stat_medians(ranges)
	var scored := []
	for id: String in Items.DEFINITIONS:
		var def: Dictionary = Items.DEFINITIONS[id]
		# A fegyverek ereje főleg az alapsebzésük (nem stat): azokat nem mérjük össze a többivel.
		if not def.has("rarity") or def.get("slot", "") == "weapon":
			continue
		var score := 0.0
		for stat: String in def.get("stats", {}):
			var pair: Array = def["stats"][stat]
			var mid := (float(pair[0]) + float(pair[1])) / 2.0
			score += mid / medians.get(stat, 1.0) * (1.0 if mid >= 0 else 0.8)
		scored.append(["%s (%s)" % [def.get("name", id), def.get("slot", "")], str(def["rarity"]), score])
	_outliers("Tárgy", scored)


# ---------------------------------------------------------------- 4. szörnyek

func _enemies() -> void:
	_line("## 4. Szörnyek (a saját legkisebb mélységükön, az ott járó többiekhez mérve)")
	_line("")
	_line("Szívósság = élet / (1 - kikerülés); veszély = sebzés × sebesség. Csak az XP / szívósság arány (megéri-e")
	_line("megölni) és a kiugró veszély számít: a nagy testű szörnyek szándékosan szívósabbak.")
	_line("")
	var rows := []
	for type: Dictionary in EnemyTypes.TYPES:
		var depth := int(type["min_depth"])
		var ehp := 0.0
		var threat := 0.0
		var xp := 0.0
		for i in ITEM_SAMPLES:
			var stats := EnemyTypes.roll(type, depth)
			ehp += float(stats["health"]) / maxf(0.2, 1.0 - float(stats["dodge"]) / 100.0)
			threat += float(stats["damage"]) * float(stats["speed"])
			xp += float(stats["xp"])
		rows.append([str(type["name"]), depth, ehp / ITEM_SAMPLES, threat / ITEM_SAMPLES, xp / ITEM_SAMPLES])
	var flagged := 0
	_line("| Szörny | Mélység | Mi lóg ki |")
	_line("|---|---|---|")
	for row: Array in rows:
		# A társai: akiknek a legkisebb mélysége ±3-on belül van.
		var peers := rows.filter(func(r: Array) -> bool: return absi(int(r[1]) - int(row[1])) <= 3)
		if peers.size() < 3:
			continue
		var notes: Array[String] = []
		var ehp_median := _median(peers.map(func(r: Array) -> float: return r[2]))
		var threat_median := _median(peers.map(func(r: Array) -> float: return r[3]))
		var ratio_median := _median(peers.map(func(r: Array) -> float: return r[4] / maxf(1.0, r[2])))
		var ratio := float(row[4]) / maxf(1.0, row[2])
		# (A nagy testű szörnyek szándékosan szívósabbak: csak az számít, ha az XP nem arányos vele.)
		if row[3] > threat_median * 3.0:
			notes.append("kiugróan veszélyes (sebzés × sebesség %.0f, a társaié %.0f)" % [row[3], threat_median])
		if ratio > ratio_median * OUTLIER * 1.5:
			notes.append("sok XP a szívósságához (%.2f, a társaié %.2f)" % [ratio, ratio_median])
		elif ratio < ratio_median / (OUTLIER * 1.5):
			notes.append("kevés XP a szívósságához (%.2f, a társaié %.2f)" % [ratio, ratio_median])
		if not notes.is_empty():
			flagged += 1
			_line("| %s | %d | %s |" % [_monster_name(row[0]), row[1], "; ".join(notes)])
	if flagged == 0:
		_line("| — | — | nincs kilógó |")
	_line("")


func _monster_name(id: String) -> String:
	var entry: Variant = Bestiary.ENTRIES.get(id)
	return "%s (%s)" % [entry[0], id] if entry is Array else id


# ---------------------------------------------------------------- segédek

## Statonként az értékek mediánja (abszolút értékben) egy szótár-listából.
func _stat_medians(dicts: Array) -> Dictionary:
	var values := {}
	for dict: Dictionary in dicts:
		for stat: String in dict:
			if not values.has(stat):
				values[stat] = []
			(values[stat] as Array).append(absf(float(dict[stat])))
	var result := {}
	for stat: String in values:
		result[stat] = maxf(0.01, _median(values[stat]))
	return result


func _median(list: Array) -> float:
	if list.is_empty():
		return 0.0
	var sorted := list.duplicate()
	sorted.sort()
	return float(sorted[sorted.size() / 2])


## [név, ritkaság, pontszám] sorok: ritkaságonként a medián és a kilógók.
func _outliers(label: String, scored: Array) -> void:
	_line("| Ritkaság | Darab | Medián erősség | Túl erős | Túl gyenge |")
	_line("|---|---|---|---|---|")
	for rarity in ["common", "rare", "epic", "legendary", "mythic"]:
		var group := scored.filter(func(s: Array) -> bool: return s[1] == rarity)
		if group.is_empty():
			continue
		var median := _median(group.map(func(s: Array) -> float: return s[2]))
		var strong: Array[String] = []
		var weak: Array[String] = []
		for s: Array in group:
			if s[2] > median * OUTLIER:
				strong.append("%s (%.1f)" % [s[0], s[2]])
			elif s[2] < median / OUTLIER:
				weak.append("%s (%.1f)" % [s[0], s[2]])
		_line("| %s | %d | %.1f | %s | %s |" % [rarity, group.size(), median, ", ".join(strong) if not strong.is_empty() else "—",
			", ".join(weak) if not weak.is_empty() else "—"])
	_line("")
	# Ritkaságok sorrendje: a mediánoknak nőniük kell.
	var last := -1.0
	for rarity in ["common", "rare", "epic", "legendary", "mythic"]:
		var group := scored.filter(func(s: Array) -> bool: return s[1] == rarity)
		if group.is_empty():
			continue
		var median := _median(group.map(func(s: Array) -> float: return s[2]))
		if median < last:
			_line("⚠ %s: a(z) %s medián erőssége kisebb, mint az eggyel közönségesebbé." % [label, rarity])
		last = median
	_line("")
