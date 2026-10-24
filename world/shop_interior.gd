class_name ShopInterior
extends Node2D
## A bolt belseje: egy külön, mindig ugyanúgy berendezett szoba, messze a pályától.
## A padlót és a falakat a Dungeon rajzolja ki (RECT + EXIT_RECT); ez a node
## a berendezést teszi bele: polcos fal, pult mögötte a gyanús boltossal,
## két oldalt az árus pultok a megvehető tárgyakkal, hordók és ládák.
## A déli kijáraton át vissza lehet menni a pályára.

signal exited

const TILE := 32
## A bolt padlója csempe-koordinátákban.
const RECT := Rect2i(-7, 300, 15, 9)
## Kijárat: rövid folyosócsonk a déli fal közepén.
const EXIT_RECT := Rect2i(-1, 309, 3, 2)
## Itt jelenik meg a játékos belépéskor (a szoba alja közepén).
const ENTRANCE_TILE := Vector2i(0, 307)

const INDOOR: Texture2D = preload("res://assets/shop/kenney_indoor.png")
const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
const CONTAINERS: Texture2D = preload("res://assets/shop/barrels_and_boxes.png")
const POTTERY: Texture2D = preload("res://assets/shop/pottery.png")

# Képrészletek
const BARREL := Rect2(0, 0, 16, 16)
const BIG_CRATE := Rect2(16, 0, 16, 16)
const SMALL_CRATE := Rect2(32, 0, 16, 16)
## A boltos: a 0x72 csomag fekete köpenyes, csőrös maszkos "doktora".
const SHOPKEEPER := Rect2(368, 345, 16, 23)
## Üres piaci pult-darabok (Kenney RPG lap): ezekre kerülnek az áruk.
const MARKET_COUNTERS: Array[Rect2] = [
	Rect2(10 * 17, 4 * 17, 16, 16), Rect2(10 * 17, 5 * 17, 16, 16), Rect2(10 * 17, 6 * 17, 16, 16),
]
## A Kenney-bútorok világosabbak a dungeonnál; ennyire tompítjuk őket.
const FURNITURE_TINT := Color(0.8, 0.74, 0.7)
## Ennyivel kerül feljebb a következő hordó, ha egymásra rakjuk őket.
const STACK_STEP := 13.0
const GREETINGS: Array[String] = [
	"Hehe... üdv, idegen.",
	"Nézz csak körül... semmi sem lopott.",
	"Az áruk ott vannak oldalt... hehe.",
	"Van eladnivalód? Megveszem... jó áron.",
]
const GREETING_COOLDOWN := 4.0
const SOLD_LINES: Array[String] = ["Jó vásár... hehe.", "Viseld egészséggel.", "Nem kérdezem, minek kell."]
## A tárgyak az árus pult felett lebegnek.
const ITEM_FLOAT := Vector2(0, -10)
## Minden ennyiedik pult-darabra kerül áru (2 = egy üres hely közöttük).
const ITEM_SPACING := 2
## Ennyire kell közel állni egy áru elé, hogy kijelölődjön.
const FOCUS_RANGE := 44.0
const FOCUS_SCALE := 1.3
const GLOW_ENERGY := 0.7
## "Új áruk" kar (0x72 lap) és az ára: alap + ennyivel drágább minden alkalommal.
const RESTOCK_LEVER := Rect2(80, 208, 16, 16)
const RESTOCK_BASE := 25
const RESTOCK_STEP := 20
## HP bájital a boltostól: ára és hány darab van belőle boltonként.
const POTION_PRICE := 60
const POTIONS_PER_SHOP := 2
const POTION_ICON: Texture2D = preload("res://assets/ui/potion_hp.png")

var _greeting_left := 0.0
var _greeting_index := 0
var _shopkeeper: AnimatedSprite2D
var _dialogue: DialoguePanel
## A 10. emeleti boltos történetei (a tolvaj levelének átadása után bármikor megkérdezhetők).
const SHOPKEEPER_STORIES: Array[Dictionary] = [
	{"id": "how_here", "text": "Hogy kerültél ide le, a tizedik emeletre?", "trust": 3,
		"answer": "[i]Megsimogatja a pultot, mintha egy hű kutya volna.[/i]\n\n" \
			+ "Lejöttem, ahogy mindenki: karddal, bátorsággal, és egy egész csapat barommal. Ők a harmadik " \
			+ "emeleten maradtak, én meg rájöttem, hogy a halottaknak nincs szükségük a felszerelésükre.\n\n" \
			+ "Azóta itt vagyok. A szörnyek nem bántják a boltost. Szerintem tudják, hogy nélkülem a " \
			+ "kalandorok fele már az ötödiken elhullana. És akkor kit ennének? Hehe."},
	{"id": "bence", "text": "Honnan ismered Bencét?", "trust": 4,
		"answer": "[i]Elmosolyodik, ezúttal szinte kedvesen.[/i]\n\n" \
			+ "Tizenkét éves volt, amikor először lejött ide, egyedül, egy konyhakéssel. Ellopott tőlem egy " \
			+ "kenyeret, én meg elkaptam. Ahelyett, hogy kidobtam volna, munkát adtam neki: ő hozta, amit " \
			+ "odalent talált, én eladtam.\n\nAztán egyszer túl sokat hozott fel... a király kincstárából. " \
			+ "Azóta bujkál. De ha bajba kerül, tudja, hol vagyok."},
	{"id": "goods", "text": "Honnan szerzed ezt a sok árut?", "trust": 2,
		"answer": "[i]Gyanakodva körülnéz, aztán lehalkítja a hangját.[/i]\n\n" \
			+ "Ami odalent elhullik, az előbb-utóbb ide kerül. Kalandorok, szörnyek, néha egy-egy ostoba " \
			+ "kereskedő. Én csak... összeszedem és rendbe teszem.\n\nMinél mélyebbre jutsz, annál jobb holmi " \
			+ "kerül a pultomra. A mélység drága, de nagyvonalú. Kérdés nincs, garancia sincs. Hehe."},
]
## Az árus pult helyei: {item, tile, nodes} vagy null, ha már elkelt.
var _stock: Array = []
## Melyik áru előtt áll a játékos (-1 = egyik előtt sem).
var _focused := -1
var _tooltip: ShopTooltip
## A boltos pultja előtt áll-e a játékos (ott lehet eladni).
var _at_counter := false
var _sell_prompt: Label
## Az árus pultok helyei: [pult csempe, ahol állni kell, irány] (az új áruk ide kerülnek).
var _stalls: Array = []
## Hányszor kértél új árut ebben a boltban (minden alkalommal drágább).
var _restocks := 0
var _lever_position := Vector2.ZERO
var _lever_prompt: Label
var _potions_left := POTIONS_PER_SHOP
var _potion_nodes: Array[Sprite2D] = []


static func entrance_position() -> Vector2:
	return Room.tile_center(ENTRANCE_TILE)


## Egy Kenney-lap csempéje (16 px + 1 px hézag).
static func kenney(col: int, row: int) -> Rect2:
	return Rect2(col * 17, row * 17, 16, 16)


func _ready() -> void:
	y_sort_enabled = true
	_build_back_wall_shelves()
	_build_counter()
	_build_market_counters()
	_build_barrels()
	_build_exit()
	_build_restock_lever()
	_add_light(Vector2i(0, 302), 0.55, 2.0)
	_add_light(Vector2i(5, 305), 0.3, 1.5)
	_add_light(Vector2i(-5, 305), 0.3, 1.5)
	_build_dialogue()


func _process(delta: float) -> void:
	_greeting_left -= delta
	_update_focus()
	if _lever_prompt:
		_lever_prompt.visible = _near_lever()
		_lever_prompt.text = "[E] Új áruk: %d arany" % restock_cost()
	if _sell_prompt.visible:
		_sell_prompt.text = "[E] Eladás   ·   [F] HP bájital: %d arany (%s)" % [POTION_PRICE,
			("%d db" % _potions_left) if _potions_left > 0 else "elfogyott"]
		# A tolvaj levele (a 10. emeleten, ha nálad van): G-vel adod át.
		if _letter_here():
			_sell_prompt.text += "   ·   [G] Levél átadása"
		elif _can_talk():
			_sell_prompt.text += "   ·   [G] Beszélgetés"


## Polcok a hátsó fal előtt: két csempe magasak, tele áruval.
func _build_back_wall_shelves() -> void:
	var y := RECT.position.y
	var variants := [43, 44, 45, 46, 47, 48, 49, 50]
	for x in range(RECT.position.x + 1, RECT.end.x - 1):
		var col: int = variants[(x - RECT.position.x) % variants.size()]
		_sprite(RPG, kenney(col, 14), Vector2i(x, y))
		_sprite(RPG, kenney(col, 12), Vector2i(x, y), -1.0)
	_solid(Rect2i(RECT.position.x + 1, y, RECT.size.x - 2, 1))


## A pult, mögötte a boltos.
func _build_counter() -> void:
	var y := RECT.position.y + 3
	var pieces := [kenney(4, 7), kenney(5, 7), kenney(6, 7), kenney(5, 7), kenney(6, 7), kenney(5, 7), kenney(7, 7)]
	for i in pieces.size():
		_sprite(INDOOR, pieces[i], Vector2i(-3 + i, y))
	_solid(Rect2i(-3, y, pieces.size(), 1))
	# Néhány tárgy a pulton.
	_sprite(POTTERY, Rect2(48, 32, 16, 16), Vector2i(-2, y), -0.45, 0.8)
	# HP bájitalok a pulton a boltos mellett (személyesen tőle lehet venni, F-fel).
	for i in POTIONS_PER_SHOP:
		var potion := Sprite2D.new()
		potion.texture = POTION_ICON
		potion.scale = Vector2(0.75, 0.75)
		potion.position = Room.tile_center(Vector2i(1, y)) + Vector2(-6 + i * 16, -20)
		potion.z_index = 1
		add_child(potion)
		_potion_nodes.append(potion)

	_shopkeeper = AnimatedSprite2D.new()
	_shopkeeper.sprite_frames = SpriteSheet.character_frames(SHOPKEEPER, true)
	_shopkeeper.scale = Vector2(2, 2)
	_shopkeeper.offset.y = -SHOPKEEPER.size.y / 2.0
	_shopkeeper.position = Room.tile_center(Vector2i(0, y - 1)) + Vector2(0, 14)
	_shopkeeper.flip_h = true
	_shopkeeper.play("idle")
	add_child(_shopkeeper)

	# A pult előtt állva megszólal.
	var area := _area(Rect2i(-3, y + 1, pieces.size(), 2))
	area.body_entered.connect(_on_counter_approached)
	area.body_exited.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			_at_counter = false
			_sell_prompt.visible = false)

	# "[E] Eladás · [F] HP bájital" felirat a pult fölött, amikor a játékos előtte áll.
	_sell_prompt = UiStyle.label("[E] Eladás", 15, Color(1, 0.9, 0.6), true)
	_sell_prompt.size = Vector2(420, 20)
	_sell_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sell_prompt.position = Room.tile_center(Vector2i(0, y)) + Vector2(-210, -64)
	_sell_prompt.z_index = 10
	_sell_prompt.visible = false
	add_child(_sell_prompt)


## Két árus pult (a keleti és a nyugati fal mentén), mindegyiken minden második
## helyen egy áru, hogy jól elkülönüljenek. A tárgyakat majd ide teszi ki a boltos.
func _build_market_counters() -> void:
	var used_ids := {}
	var east := RECT.end.x - 2
	var west := RECT.position.x + 1
	_build_counter_column(east, RECT.position.y + 2, RECT.end.y - 2, -1, used_ids)
	_build_counter_column(west, RECT.position.y + 3, RECT.end.y - 2, 1, used_ids)
	_tooltip = ShopTooltip.new()
	add_child(_tooltip)


## Egy függőleges pult; `facing`: merre van a szoba belseje (-1 = balra, 1 = jobbra),
## onnan lehet odaállni az áruhoz.
func _build_counter_column(x: int, top: int, bottom: int, facing: int, used_ids: Dictionary) -> void:
	for y in range(top, bottom + 1):
		_sprite(RPG, MARKET_COUNTERS[(y - top) % MARKET_COUNTERS.size()], Vector2i(x, y))
	_solid(Rect2i(x, top, 1, bottom - top + 1))
	for y in range(top, bottom + 1, ITEM_SPACING):
		var item := Items.random_shop_item(GameState.depth)
		for attempt in 10:
			if not used_ids.has(item["id"]):
				break
			item = Items.random_shop_item(GameState.depth)
		used_ids[item["id"]] = true
		_stalls.append([Vector2i(x, y), Vector2i(x + facing, y), facing])
		_add_stock(item, Vector2i(x, y), Vector2i(x + facing, y), facing)


func _add_stock(item: Dictionary, tile: Vector2i, stand_tile: Vector2i, facing: int) -> void:
	var nodes: Array[Node] = []
	var icon := Sprite2D.new()
	icon.texture = Items.icon(item)
	icon.position = Room.tile_center(tile) + ITEM_FLOAT
	icon.z_index = 2
	add_child(icon)
	var bob := icon.create_tween().set_loops()
	bob.tween_property(icon, "position:y", icon.position.y - 4, 0.8).set_trans(Tween.TRANS_SINE)
	bob.tween_property(icon, "position:y", icon.position.y, 0.8).set_trans(Tween.TRANS_SINE)
	nodes.append(icon)

	var glow := PointLight2D.new()
	glow.texture = _glow_texture()
	glow.color = Items.rarity_color(item)
	glow.energy = GLOW_ENERGY
	glow.texture_scale = 0.35
	glow.position = icon.position
	add_child(glow)
	nodes.append(glow)

	# Az ár a szoba belseje felőli oldalon.
	var price := UiStyle.label("%d" % item["price"], 13, UiStyle.TEXT_GOLD, true)
	price.size = Vector2(30, 16)
	price.position = Room.tile_center(tile) + Vector2(-50 if facing < 0 else 20, -2)
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if facing < 0 else HORIZONTAL_ALIGNMENT_LEFT
	price.z_index = 5
	add_child(price)
	nodes.append(price)

	_stock.append({"item": item, "tile": tile, "stand": Room.tile_center(stand_tile),
		"nodes": nodes, "icon": icon, "glow": glow})


## A játékoshoz legközelebbi áru (FOCUS_RANGE-en belül) a kijelölt:
## kicsit megnő és jobban világít, a leírása megjelenik.
func _update_focus() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var best := -1
	var best_distance := FOCUS_RANGE
	for i in _stock.size():
		if _stock[i] == null:
			continue
		var distance := player.global_position.distance_to(_stock[i]["stand"])
		if distance < best_distance:
			best = i
			best_distance = distance
	if best == _focused:
		return
	if _focused != -1 and _stock[_focused] != null:
		_set_highlight(_stock[_focused], false)
	_focused = best
	if _focused != -1:
		_set_highlight(_stock[_focused], true)
	_update_tooltip()


func _set_highlight(entry: Dictionary, on: bool) -> void:
	entry["icon"].scale = Vector2.ONE * (FOCUS_SCALE if on else 1.0)
	entry["glow"].energy = GLOW_ENERGY * (2.0 if on else 1.0)

func _update_tooltip() -> void:
	if _focused == -1 or _stock[_focused] == null:
		_tooltip.hide_tooltip()
		return
	var player := get_tree().get_first_node_in_group("player")
	var item: Dictionary = _stock[_focused]["item"]
	var gold: int = player.get("gold")
	var hint := "[E] Megvétel"
	var can_buy := true
	if gold < item["price"]:
		hint = "Nincs elég aranyad (még %d kell)" % (item["price"] - gold)
		can_buy = false
	elif player.get_node("Inventory").is_bag_full():
		hint = "Tele a táskád"
		can_buy = false
	_tooltip.show_item(item, hint, can_buy)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if _at_counter and key != null and key.pressed and not key.echo and key.physical_keycode == KEY_F:
		_buy_potion()
		get_viewport().set_input_as_handled()
		return
	if _at_counter and key != null and key.pressed and not key.echo and key.physical_keycode == KEY_G and _can_talk():
		Audio.play("ui_open")
		get_tree().current_scene.get_node("Menus").call("open_menu", _dialogue)
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed("interact"):
		return
	if _near_lever():
		_restock()
		get_viewport().set_input_as_handled()
	elif _focused != -1:
		_buy(_focused)
		get_viewport().set_input_as_handled()
	elif _at_counter:
		get_tree().current_scene.get_node("Menus").call("open_sell")
		get_viewport().set_input_as_handled()


func _buy(index: int) -> void:
	var entry = _stock[index]
	if entry == null:
		return
	var player := get_tree().get_first_node_in_group("player")
	var inventory: Inventory = player.get_node("Inventory")
	var item: Dictionary = entry["item"]
	if inventory.is_bag_full() or not player.call("spend_gold", item["price"]):
		Audio.play("ui_error")
		_update_tooltip()
		return
	inventory.add_item(item)
	Audio.play("buy")
	for node: Node in entry["nodes"]:
		node.queue_free()
	_stock[index] = null
	_focused = -1
	_tooltip.hide_tooltip()
	FloatingText.spawn(self, Room.tile_center(entry["tile"]) + Vector2(-20, -10), "Megvetted!", Items.rarity_color(item))
	FloatingText.spawn(self, _shopkeeper.global_position + Vector2(0, -36), SOLD_LINES.pick_random(), Color(0.85, 0.75, 1))


## HP bájital a boltostól (a pultnál F-fel): POTION_PRICE arany, boltonként POTIONS_PER_SHOP darab.
func _letter_here() -> bool:
	if Progress.npc_quest_state(Thief.LETTER_QUEST) != "active" or GameState.depth != Thief.LETTER_FLOOR:
		return false
	var player := get_tree().get_first_node_in_group("player")
	return player != null and Thief.has_letter(player.get_node("Inventory"))


## A boltos beszélgetőablaka (a tolvaj levelénél: a pultnál G-vel), hogy a válasza végig olvasható legyen.
func _build_dialogue() -> void:
	_dialogue = DialoguePanel.new()
	_dialogue.name = "ShopkeeperDialogue"
	_dialogue.npc_id = "shopkeeper"
	_dialogue.npc_name = "A gyanús boltos"
	_dialogue.greeting = "[i]A boltos áthajol a pulton, és gyanakodva méreget.[/i]\n\nNa? Vásárolni jöttél, " \
		+ "vagy csak bámészkodni? Hehe."
	_dialogue.portrait = SpriteSheet.region(SHOPKEEPER)
	_dialogue.options_provider = _dialogue_options
	get_tree().current_scene.add_child.call_deferred(_dialogue)


func _dialogue_options() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	if _letter_here():
		list.append({"id": "letter", "text": "Hoztam neked egy levelet Bencétől.", "on_choose": _give_letter})
	elif Progress.npc_quest_state(Thief.LETTER_QUEST) in ["delivered", "done"]:
		list.append({"id": "letter_news", "text": "Mit írt Bence?", "trust": 2,
			"answer": Thief.SHOPKEEPER_NEWS})
	# A levél után a 10. emeleti boltos bármikor mesél (három történet).
	if Progress.npc_quest_state(Thief.LETTER_QUEST) in ["delivered", "done"]:
		list.append_array(SHOPKEEPER_STORIES)
	return list


## Csak a 10. emeleti boltossal lehet beszélgetni (a tolvaj levelével, és utána bármikor).
func _can_talk() -> bool:
	if GameState.depth != Thief.LETTER_FLOOR:
		return false
	return _letter_here() or Progress.npc_quest_state(Thief.LETTER_QUEST) in ["delivered", "done"]


## A tolvaj levele a boltosnak (G a pultnál, csak a 10. emeleten): arany a jutalom (a beszélgetőablakban).
func _give_letter() -> String:
	var player := get_tree().get_first_node_in_group("player")
	var answer := Thief.deliver_to_shopkeeper(player) if player else ""
	if answer.is_empty():
		Audio.play("ui_error")
		return "Levél? Milyen levél? Ha levelet hoztál, a táskádban legyen... és a tizedik emeleten keress."
	Audio.play("coin")
	FloatingText.spawn(self, player.global_position + Vector2(0, -60), "+%d arany" % Thief.LETTER_GOLD,
		Color(1, 0.85, 0.3), 20)
	return answer


func _buy_potion() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var say_at := _shopkeeper.global_position + Vector2(0, -36)
	if _potions_left <= 0:
		Audio.play("ui_error")
		FloatingText.spawn(self, say_at, "Elfogyott... hehe.", Color(0.85, 0.75, 1))
		return
	if not player.call("spend_gold", POTION_PRICE):
		Audio.play("ui_error")
		FloatingText.spawn(self, say_at, "Ez %d arany... nincs annyid." % POTION_PRICE, Color(0.85, 0.75, 1))
		return
	_potions_left -= 1
	GameState.potions += 1
	if not _potion_nodes.is_empty():
		_potion_nodes.pop_back().queue_free()
	Audio.play("buy")
	FloatingText.spawn(self, say_at, "Gyógyít... többnyire. Hehe.", Color(0.85, 0.75, 1))
	FloatingText.spawn(self, player.global_position + Vector2(-60, -64), "+1 HP bájital (%d)" % GameState.potions, Color(1, 0.45, 0.5))


## "Új áruk" kar a szoba közepén: E-re a boltos minden árut lecserél újakra, aranyért.
func _build_restock_lever() -> void:
	var tile := Vector2i(0, RECT.position.y + 5)
	_sprite(SpriteSheet.TEXTURE, RESTOCK_LEVER, tile, -0.2)
	_solid(Rect2i(tile.x, tile.y, 1, 1))
	_lever_position = Room.tile_center(tile + Vector2i(0, 1))
	var sign_label := UiStyle.label("Új áruk", 13, UiStyle.TEXT_GOLD, true)
	sign_label.size = Vector2(80, 18)
	sign_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign_label.position = Room.tile_center(tile) + Vector2(-40, -40)
	sign_label.z_index = 10
	add_child(sign_label)
	_lever_prompt = UiStyle.label("", 15, Color(1, 0.9, 0.6), true)
	_lever_prompt.size = Vector2(220, 20)
	_lever_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lever_prompt.position = Room.tile_center(tile) + Vector2(-110, -64)
	_lever_prompt.z_index = 10
	_lever_prompt.visible = false
	add_child(_lever_prompt)


func _near_lever() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	return player != null and player.global_position.distance_to(_lever_position) < 40.0


## Az új áruk ára: RESTOCK_BASE, és minden további alkalommal RESTOCK_STEP-pel több.
func restock_cost() -> int:
	return RESTOCK_BASE + RESTOCK_STEP * _restocks


## Minden áru lecserélődik (a már megvettek helyére is kerül új).
func _restock() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player.call("spend_gold", restock_cost()):
		Audio.play("ui_error")
		FloatingText.spawn(self, _lever_position + Vector2(-30, -60), "Nincs elég aranyad", Color(1, 0.5, 0.4))
		return
	_restocks += 1
	Audio.play("door_unlock")
	Audio.play("coin")
	for entry in _stock:
		if entry != null:
			for node: Node in entry["nodes"]:
				node.queue_free()
	_stock.clear()
	_focused = -1
	_tooltip.hide_tooltip()
	var used_ids := {}
	for stall: Array in _stalls:
		var item := Items.random_shop_item(GameState.depth)
		for attempt in 10:
			if not used_ids.has(item["id"]):
				break
			item = Items.random_shop_item(GameState.depth)
		used_ids[item["id"]] = true
		_add_stock(item, stall[0], stall[1], stall[2])
	FloatingText.spawn(self, _shopkeeper.global_position + Vector2(0, -36), "Friss áru... hehe.", Color(0.85, 0.75, 1))


func _glow_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	return texture


## Hordók (néhol egymásra rakva) és ládák a sarkokban.
func _build_barrels() -> void:
	var left := RECT.position.x + 1
	var right := RECT.end.x - 3
	var top := RECT.position.y + 1
	var bottom := RECT.end.y - 1
	_barrel_stack(Vector2i(left, top + 1), 2)
	_barrel_stack(Vector2i(left + 1, top + 1), 1)
	_barrel_stack(Vector2i(RECT.end.x - 2, top), 3)
	_crate(Vector2i(left, bottom), BIG_CRATE)
	_barrel_stack(Vector2i(left + 1, bottom), 2)
	_crate(Vector2i(left + 2, bottom), SMALL_CRATE)
	# A pult két végénél, hogy ne lehessen a boltos mögé menni.
	_barrel_stack(Vector2i(-4, top + 1), 2)
	_barrel_stack(Vector2i(-4, top + 2), 1)
	_crate(Vector2i(4, top + 1), BIG_CRATE)
	_barrel_stack(Vector2i(4, top + 2), 2)
	_barrel_stack(Vector2i(right, bottom), 1)


func _barrel_stack(tile: Vector2i, count: int) -> void:
	for i in count:
		var barrel := _sprite(CONTAINERS, BARREL, tile)
		barrel.offset.y = -i * STACK_STEP / 2.0
		# A felsőbb hordók kerüljenek előre.
		barrel.z_index = i
	_solid(Rect2i(tile, Vector2i.ONE))


func _crate(tile: Vector2i, region: Rect2) -> void:
	_sprite(CONTAINERS, region, tile)
	_solid(Rect2i(tile, Vector2i.ONE))


## A kijárat: a folyosócsonk alján egy terület, ami visszavisz a pályára.
func _build_exit() -> void:
	var area := _area(Rect2i(EXIT_RECT.position.x, EXIT_RECT.end.y - 1, EXIT_RECT.size.x, 1))
	area.body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			exited.emit())
	var label := UiStyle.label("▼ Kijárat", 14, Color(1, 0.9, 0.65), true)
	label.position = Room.tile_center(Vector2i(0, EXIT_RECT.position.y)) + Vector2(-34, -12)
	label.z_index = 5
	add_child(label)


func _on_counter_approached(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_at_counter = true
	_sell_prompt.visible = true
	if _greeting_left > 0.0:
		return
	_greeting_left = GREETING_COOLDOWN
	FloatingText.spawn(self, _shopkeeper.global_position + Vector2(0, -36), GREETINGS[_greeting_index], Color(0.85, 0.75, 1))
	_greeting_index = (_greeting_index + 1) % GREETINGS.size()


## Sprite egy csempe közepén; `lift` csempényivel feljebb rajzolja (de a
## rendezés továbbra is a csempe szerint történik).
func _sprite(texture: Texture2D, region: Rect2, tile: Vector2i, lift := 0.0, sprite_scale := 1.0) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.scale = Vector2(2, 2) * sprite_scale
	sprite.position = Room.tile_center(tile)
	sprite.offset.y = lift * 16.0 / sprite_scale
	if texture == INDOOR or texture == RPG:
		sprite.modulate = FURNITURE_TINT
	add_child(sprite)
	return sprite


func _solid(tiles: Rect2i) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(tiles.size) * TILE
	shape.shape = rectangle
	body.position = (Vector2(tiles.position) + Vector2(tiles.size) / 2.0) * TILE
	body.add_child(shape)
	add_child(body)


func _area(tiles: Rect2i) -> Area2D:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitorable = false
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(tiles.size) * TILE
	shape.shape = rectangle
	area.position = (Vector2(tiles.position) + Vector2(tiles.size) / 2.0) * TILE
	area.add_child(shape)
	add_child(area)
	return area


func _add_light(tile: Vector2i, energy: float, light_scale: float) -> void:
	var light := PointLight2D.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 0.8, 0.5))
	gradient.set_color(1, Color(0, 0, 0, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	light.texture = texture
	light.energy = energy
	light.texture_scale = light_scale
	light.position = Room.tile_center(tile)
	add_child(light)
