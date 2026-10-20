class_name Inventory
extends Node
## A játékos tárgyai: táska (BAG_SIZE hely) és felszerelés-helyek.
## Egy tárgy egy Dictionary (lásd Items.create): name, slot, rarity, stats, icon...
## A felvett tárgyak statjai bónuszként érvényesülnek (equipment_bonuses()).

signal changed

const BAG_SIZE := 24
const EQUIPMENT_SLOTS: Array[String] = ["helmet", "chest", "pants", "boots", "weapon", "ring", "amulet", "gloves", "trinket"]
const SLOT_NAMES := {
	"helmet": "Sisak",
	"chest": "Mellvért",
	"pants": "Nadrág",
	"boots": "Cipő",
	"weapon": "Fegyver",
	"ring": "Gyűrű",
	"amulet": "Amulett",
	"gloves": "Kesztyű",
	"trinket": "Talizmán",
}
const STARTING_WEAPON_ID := "sword_rusty"

## A táska helyei; üres helyen null.
var bag: Array = []
## Felszerelés-hely -> tárgy (vagy null).
var equipment := {}


func _ready() -> void:
	reset_to_start(false)


## Kezdő felszerelés: üres táska, csak a karakter kezdőfegyvere (lovag: rozsdás kard,
## íjász: régi íj).
func reset_to_start(notify := true) -> void:
	bag.clear()
	bag.resize(BAG_SIZE)
	for slot in EQUIPMENT_SLOTS:
		equipment[slot] = null
	Progress.load_game()
	equipment["weapon"] = Items.create(Characters.data(Progress.character).get("start_weapon", STARTING_WEAPON_ID))
	if notify:
		changed.emit()


## Az első üres helyre teszi; hamisat ad, ha tele a táska.
func add_item(item: Dictionary) -> bool:
	var index := bag.find(null)
	if index == -1:
		return false
	bag[index] = item
	changed.emit()
	return true


## Kiveszi a táskából (pl. eladáskor) és visszaadja.
func take_from_bag(index: int) -> Variant:
	var item = bag[index]
	bag[index] = null
	changed.emit()
	return item


func is_bag_full() -> bool:
	return bag.find(null) == -1


## A táska adott helyén lévő tárgyat felveszi a helyére; ami ott volt, a táskába kerül.
func equip_from_bag(index: int) -> void:
	var item = bag[index]
	if item == null or not equipment.has(item["slot"]) or not Characters.can_use(item):
		return
	bag[index] = equipment[item["slot"]]
	equipment[item["slot"]] = item
	changed.emit()


## Leveszi a tárgyat a táskába. A fegyvert nem lehet levenni (mindig kell egy).
func unequip(slot: String) -> bool:
	if slot == "weapon" or equipment[slot] == null or is_bag_full():
		return false
	add_item(equipment[slot])
	equipment[slot] = null
	changed.emit()
	return true


## Áthelyezés húzással. Egy hely: kind = "bag" (key = index) vagy "equip"
## (key = hely neve). Ha a célhelyen van tárgy, a kettő helyet cserél.
## Felszerelés-helyre csak oda illő tárgy kerülhet, és a fegyverhely nem maradhat üres.
func can_move(from_kind: String, from_key: Variant, to_kind: String, to_key: Variant) -> bool:
	if from_kind == to_kind and from_key == to_key:
		return false
	var moving = _item_at(from_kind, from_key)
	var target = _item_at(to_kind, to_key)
	if moving == null:
		return false
	# Ami a "from" helyre kerülne (a cserélt tárgy), annak is oda kell illenie.
	return _fits(moving, to_kind, to_key) and _fits(target, from_kind, from_key)


func move(from_kind: String, from_key: Variant, to_kind: String, to_key: Variant) -> bool:
	if not can_move(from_kind, from_key, to_kind, to_key):
		return false
	var moving = _item_at(from_kind, from_key)
	var target = _item_at(to_kind, to_key)
	_set_item_at(to_kind, to_key, moving)
	_set_item_at(from_kind, from_key, target)
	changed.emit()
	return true


func _fits(item: Variant, kind: String, key: Variant) -> bool:
	if kind == "bag":
		return true
	if item == null:
		return key != "weapon"
	# A lovag nem vehet fel íjat, az íjász csak íjat (lásd Characters.can_use).
	return item["slot"] == key and Characters.can_use(item)


func _item_at(kind: String, key: Variant) -> Variant:
	return bag[key] if kind == "bag" else equipment[key]


func _set_item_at(kind: String, key: Variant, item: Variant) -> void:
	if kind == "bag":
		bag[key] = item
	else:
		equipment[key] = item


## A felvett tárgyak statjainak összege (stat -> érték).
func equipment_bonuses() -> Dictionary:
	var total := {}
	for slot in EQUIPMENT_SLOTS:
		var item = equipment[slot]
		if item == null:
			continue
		for stat: String in item.get("stats", {}):
			total[stat] = total.get(stat, 0.0) + item["stats"][stat]
	return total


func save_data() -> Dictionary:
	return {"bag": bag.duplicate(true), "equipment": equipment.duplicate(true)}


func load_data(data: Dictionary) -> void:
	bag = data["bag"].duplicate(true)
	for slot in EQUIPMENT_SLOTS:
		equipment[slot] = data["equipment"].get(slot)
	changed.emit()
