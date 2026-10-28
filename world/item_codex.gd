class_name ItemCodex
## Tárgyak könyve (a táborban, a Szörnyek könyve melletti állványon; ablak: ui/item_book.gd): minden tárgy
## (Items.DEFINITIONS) fülenként; amit már megszereztél (táska, felszerelés, tábori láda), az látszik, a többi
## sötét árnyék. A felfedezett tárgyak: `Progress.seen_items` (az Inventory jelzi, lásd note()).

## Fülek: név, és melyik tárgyak tartoznak bele (hely, illetve a fegyvereknél közel / távol).
const TABS: Array[Array] = [
	["Közelharci fegyverek", "melee"], ["Távolsági fegyverek", "ranged"], ["Sisakok", "helmet"],
	["Mellvértek", "chest"], ["Nadrágok", "pants"], ["Cipők", "boots"], ["Kesztyűk", "gloves"],
	["Gyűrűk", "ring"], ["Amulettek", "amulet"], ["Talizmánok", "trinket"],
]

## Fülenkénti jutalmak (szerény): a fül tárgyainak ennyi százaléka után -> jutalom (Achievements.grant).
## Átvéve: `Progress.rewards_claimed` ("codex_<fül>_<százalék>").
const MILESTONES: Array[Array] = [
	[25, {"gold": 100, "dust": {"rare": 1}}],
	[50, {"gold": 200, "dust": {"epic": 1}}],
	[100, {"gold": 400, "dust": {"legendary": 1}}],
]


## Egy tárgy megszerzése (a könyvbe kerül). A küldetéstárgyak (pl. levél) nem számítanak.
static func note(item: Dictionary) -> void:
	var id := str(item.get("id", ""))
	if id.is_empty() or item.get("quest", false) or not Items.DEFINITIONS.has(id) or Progress.seen_items.has(id):
		return
	Progress.seen_items[id] = true


## A régebben szerzett, még be nem jegyzett tárgyak (a tábori ládában és minden karakter mentett
## felszerelésében) — a könyv megnyitásakor.
static func note_stored() -> void:
	for item: Variant in Progress.stash:
		if item is Dictionary:
			note(item)
	for inventory: Variant in Progress._all_inventories.values():
		if not inventory is Dictionary:
			continue
		var data: Dictionary = inventory
		var items: Array = []
		items.append_array(data.get("bag", []))
		var equipment: Variant = data.get("equipment", {})
		if equipment is Dictionary:
			items.append_array((equipment as Dictionary).values())
		for item: Variant in items:
			if item is Dictionary:
				note(item)


static func seen(id: String) -> bool:
	return Progress.seen_items.has(id)


## A fül tárgyai ritkaság, azon belül név szerint.
static func ids(tab: int) -> Array[String]:
	var kind: String = TABS[tab][1]
	var list: Array[String] = []
	for id: String in Items.DEFINITIONS:
		var definition: Dictionary = Items.DEFINITIONS[id]
		var slot: String = definition["slot"]
		if slot == "weapon":
			if kind != ("ranged" if Items.is_ranged(definition) else "melee"):
				continue
		elif slot != kind:
			continue
		list.append(id)
	list.sort_custom(func(a: String, b: String) -> bool:
		var ra := Items.RARITY_ORDER.find(Items.DEFINITIONS[a]["rarity"])
		var rb := Items.RARITY_ORDER.find(Items.DEFINITIONS[b]["rarity"])
		return ra < rb if ra != rb else str(Items.DEFINITIONS[a]["name"]) < str(Items.DEFINITIONS[b]["name"]))
	return list


static func seen_count(list: Array[String]) -> int:
	var count := 0
	for id in list:
		if seen(id):
			count += 1
	return count


## A tárgy statjai a saját ritkaságában, tartományként (pl. "+3 – +5% kikerülés"), fegyvernél az alapsebzéssel.
static func stats_text(id: String) -> String:
	var definition: Dictionary = Items.DEFINITIONS[id]
	var lines: Array[String] = []
	if definition.has("base"):
		var base: Array = definition["base"]
		lines.append("Alapsebzés: %d – %d" % [base[0], base[1]] if base[0] != base[1] else "Alapsebzés: %d" % base[0])
	var stats: Dictionary = definition["stats"]
	for stat: String in stats:
		var pair: Array = stats[stat]
		if is_equal_approx(float(pair[0]), float(pair[1])):
			lines.append(Items.format_stat(stat, pair[0]))
		else:
			lines.append("%s … %s" % [Items.format_stat(stat, pair[0]), Items.format_stat(stat, pair[1])])
	return "\n".join(lines)


## A fül jutalmának kulcsa, és hogy elérte-e / átvette-e.
static func _milestone_key(tab: int, percent: int) -> String:
	return "codex_%s_%d" % [TABS[tab][1], percent]


static func milestone_reached(tab: int, percent: int) -> bool:
	var list := ids(tab)
	return not list.is_empty() and seen_count(list) * 100 >= percent * list.size()


static func milestone_claimed(tab: int, percent: int) -> bool:
	return Progress.rewards_claimed.has(_milestone_key(tab, percent))


## A fül elért, de még át nem vett jutalmai: átveszi mindet, és visszaadja, mit kapott ("" ha semmit).
static func claim(tab: int) -> String:
	var got: Array[String] = []
	for milestone: Array in MILESTONES:
		var percent: int = milestone[0]
		if milestone_reached(tab, percent) and not milestone_claimed(tab, percent):
			Progress.rewards_claimed[_milestone_key(tab, percent)] = true
			Achievements.grant(milestone[1])
			got.append(Achievements.reward_text(milestone[1]))
	return ", ".join(got)


## A fül következő (még át nem vett) jutalma: [százalék, jutalom], vagy [] ha mind megvan.
static func next_milestone(tab: int) -> Array:
	for milestone: Array in MILESTONES:
		if not milestone_claimed(tab, milestone[0]):
			return milestone
	return []
