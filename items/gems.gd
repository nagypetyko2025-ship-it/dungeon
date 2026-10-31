class_name Gems
## Drágakövek: a kripta rituáléjához kellenek (`Crypt`, `RitualPanel`). A tábori vagyonhoz tartoznak
## (`Progress.gems`, azonnal mentődik, a halál sem viszi el). Honnan: főellenség (biztosan 1, a nagy
## főellenség 3), ládák a `CHEST_DEPTH`-től (`CHEST_CHANCE`). A gyakorló pályán és a próbatételben nincs.
## A rituálé: a következő futásra áldás (`Progress.blessing` → a futás elején `GameState.blessing`).

const STAR := "star"
## id -> név, ikon, szín, az áldás neve, statjai (Stats nevek) és leírása. A Csillagkő minden rituáléhoz kell.
const LIST := {
	"ruby": {"name": "Vérrubin", "icon": "res://assets/items/gem_ruby.png", "color": Color(1, 0.35, 0.35),
		"blessing": "A vér áldása", "bonuses": {"damage_percent": 30.0}, "text": "+30% sebzés"},
	"moonstone": {"name": "Holdkő", "icon": "res://assets/items/gem_moonstone.png", "color": Color(0.88, 0.9, 0.95),
		"blessing": "A hold áldása", "bonuses": {"max_health": 30.0, "health_regen": 1.0},
		"text": "+30 max. élet, +1 életerő-visszatöltés"},
	"sapphire": {"name": "Viharzafír", "icon": "res://assets/items/gem_sapphire.png", "color": Color(0.45, 0.6, 1),
		"blessing": "A vihar áldása", "bonuses": {"move_speed": 15.0, "attack_speed": 20.0},
		"text": "+15% mozgás, +20% támadási sebesség"},
	"amethyst": {"name": "Árnyékametiszt", "icon": "res://assets/items/gem_amethyst.png", "color": Color(0.8, 0.45, 1),
		"blessing": "Az árnyék áldása", "bonuses": {"crit_chance": 12.0, "dodge": 8.0},
		"text": "+12% kritikus esély, +8% kitérés"},
	STAR: {"name": "Csillagkő", "icon": "res://assets/items/gem_star.png", "color": Color(0.85, 0.95, 1),
		"blessing": "", "bonuses": {}, "text": "minden rituáléhoz kell"},
}
## A rituálé ára: ennyi kő a választott fajtából + 1 Csillagkő + tábori arany.
const RITUAL_GEMS := 2
const RITUAL_STARS := 1
const RITUAL_GOLD := 1500
## A főellenség köve: ekkora eséllyel Csillagkő (a nagy főellenség mindig ad egyet a 2 másik mellé).
const BOSS_STAR_CHANCE := 0.15
const CHEST_DEPTH := 21
const CHEST_CHANCE := 0.06


static func gem_name(id: String) -> String:
	return String(LIST[id]["name"])


static func icon(id: String) -> Texture2D:
	return ResourceWarmer.fetch(String(LIST[id]["icon"])) as Texture2D


static func count(id: String) -> int:
	return int(Progress.gems.get(id, 0))


static func add(id: String, amount: int) -> void:
	Progress.gems[id] = maxi(count(id) + amount, 0)
	Progress.save_game()


## Kaphat-e itt követ (a gyakorló pályán, a próbatételben és csalt futásban nem; a történet-futás számít).
static func can_drop() -> bool:
	if GameState.tutorial or GameState.cheated:
		return false
	return GameState.challenge.is_empty() or GameState.challenge.has("story")


static func _random_normal() -> String:
	var ids: Array[String] = ["ruby", "moonstone", "sapphire", "amethyst"]
	return ids[randi() % ids.size()]


## A főellenség után: a kövek egyből a tábori vagyonba kerülnek, felirattal.
static func boss_drop(parent: Node, at: Vector2, lord: bool) -> void:
	if not can_drop():
		return
	var found: Array[String] = []
	if lord:
		found = [STAR, _random_normal(), _random_normal()]
	else:
		found = [STAR if randf() < BOSS_STAR_CHANCE else _random_normal()]
	_give(parent, at, found)


## Láda (a CHEST_DEPTH-től): kis eséllyel egy (nem Csillag-) kő.
static func chest_drop(parent: Node, at: Vector2, depth: int) -> void:
	if depth < CHEST_DEPTH or not can_drop() or randf() >= CHEST_CHANCE:
		return
	_give(parent, at, [_random_normal()])


static func _give(parent: Node, at: Vector2, found: Array[String]) -> void:
	for i in found.size():
		var id := found[i]
		Progress.gems[id] = count(id) + 1
		FloatingText.spawn(parent, at + Vector2(0, -40 - i * 22), "+1 %s" % gem_name(id), LIST[id]["color"], 20)
	Progress.save_game()
	Audio.play("level_up", -8.0)


## Elvégezhető-e most a rituálé ezzel a kővel: "" = igen, különben az ok.
static func ritual_problem(id: String) -> String:
	if not Progress.blessing.is_empty():
		return "Már vár rád egy áldás a következő futásra."
	if count(id) < RITUAL_GEMS:
		return "Kevés a %s (%d kell)." % [gem_name(id), RITUAL_GEMS]
	if count(STAR) < RITUAL_STARS:
		return "Nincs Csillagköved."
	if Progress.camp_gold < RITUAL_GOLD:
		return "Nincs elég tábori arany (%d kell)." % RITUAL_GOLD
	return ""


## A rituálé: elveszi az árat, és a következő futásra áldást ad.
static func perform(id: String) -> bool:
	if not ritual_problem(id).is_empty():
		return false
	# (Az add_camp_gold újratölti a mentést: előbb az, aztán a kövek.)
	Progress.add_camp_gold(-RITUAL_GOLD)
	Progress.gems[id] = count(id) - RITUAL_GEMS
	Progress.gems[STAR] = count(STAR) - RITUAL_STARS
	Progress.blessing = id
	Progress.save_game()
	return true


## A futás elején (Camp): a várakozó áldás erre a futásra szól, a mentésből elfogy.
static func start_run() -> void:
	GameState.blessing = Progress.blessing
	if not Progress.blessing.is_empty():
		Progress.blessing = ""
		Progress.save_game()


## Az áldás statjai ebben a futásban (a Player adja a többi bónuszhoz).
static func run_bonuses() -> Dictionary:
	if GameState.blessing.is_empty() or not LIST.has(GameState.blessing) or GameState.tutorial:
		return {}
	return LIST[GameState.blessing]["bonuses"]
