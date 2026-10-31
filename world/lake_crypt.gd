class_name LakeCrypt
## A tó titka (Öreg Ábel küldetéssora, lásd Fisherman): a sziget rácsos lépcsője alatt az elárasztott kripta.
## A rácson két zár van: Ábel nagy, rozsdás kulcsa (a halból) és egy kis zár, amihez a kalózoktól kell kulcs
## (KEY_QUEST: kalózokat kell legyőzni). Utána Ábel csónakkal átvisz a szigetre (a móló végén), és a lépcsőn le
## lehet menni: RUN_FLOORS emeletes történet-futás a próbatétel szabályaival (Challenge, "story": "crypt"), a
## Fagykő kék kövével; az utolsó emelet aréna, benne a Tófenék Ura (BOSS). Jutalom: A tófenék gyöngye.
## Ez a fájl a futás adatait és a történet-futások közös elosztóját (story_boss / story_reward) adja.

const RUN_FLOORS := 4
const REWARD_ID := "trinket_lake_pearl"
## A Tófenék Ura: óriási, jégkék páncélú rák, a kripta aljának őre (a "giant_crab" képe, nagyban, árnyalva).
const BOSS := {"name": "A Tófenék Ura", "sheet": "res://assets/enemies/giant_crab.png", "rect": Rect2(0, 0, 16, 16),
	"scale": 5.0, "tint": Color(0.65, 0.95, 1.3), "health": 110, "damage": 5, "speed": 60.0, "xp": 100,
	"attacks": ["charge", "slam", "pools", "summon"], "minion": "giant_crab", "abilities": ["frost"]}


## Az elárasztott kripta: a próbatétel szabályaival, RUN_FLOORS emelet, a végén a Tófenék Ura.
static func run_challenge() -> Dictionary:
	return {"seed": 0, "floors": RUN_FLOORS, "boons": [], "banes": [], "score": 0.0, "level": 3,
		"difficulty": "Nehéz", "reward": "legendary", "mythic_chance": 0.0, "story": "crypt",
		"title": "Az elárasztott kripta",
		"intro": "A rács kinyílik, a lépcső nedves, jeges sötétbe vezet. Lent a kripta: %d emelet lefelé, " % RUN_FLOORS
			+ "és a legalján az, ami a tó fényeit gyújtja.",
		"reward_text": "Jutalom, ha legyőzöd: A tófenék gyöngye (egyedi legendás talizmán) és a lent szerzett aranyad.",
		"start_label": "Lemegyek"}


## Győzelem a kriptában (a Dungeon hívja): a küldetés lépése és a jutalom.
static func reward() -> Dictionary:
	if Progress.npc_quest_state(Fisherman.CRYPT_QUEST) == "active":
		Progress.set_npc_quest(Fisherman.CRYPT_QUEST, "slain")
	return Items.mark_story(Items.create(REWARD_ID))


# ---------------------------------------------------------------- történet-futások (közös)

## A történet-futás utolsó emeletének főellensége ("knocker": a régi tárnák, "crypt": a kripta).
static func story_boss(story: String) -> Dictionary:
	match story:
		"knocker": return Knocking.BOSS
		"crypt": return BOSS
		"entrance": return OldEntrance.BOSS
	return {}


static func is_story_lord(lord: String) -> bool:
	return not story_boss(lord).is_empty()


## A történet-futás jutalma győzelemkor.
static func story_reward(story: String) -> Dictionary:
	if story == "entrance":
		return OldEntrance.reward()
	return Knocking.reward() if story == "knocker" else reward()


## Feliratok: a futás eleje, az emeletek, és a főellenség legyőzése.
static func story_start_text(story: String, floors: int) -> String:
	if story == "crypt":
		return "Az elárasztott kripta: %d emelet lefelé. A víz jéghideg, a fáklyák kéken égnek." % floors
	if story == "entrance":
		return OldEntrance.START_TEXT % floors
	return "A régi tárnák: %d emelet lefelé. Az utolsó alján vár, ami kopog." % floors


static func story_floor_text(story: String, depth: int, floors: int) -> String:
	if story == "entrance":
		return OldEntrance.FLOOR_TEXT % [depth, floors, OldEntrance.NEAR_TEXT if depth >= floors else ""]
	if story == "crypt":
		return "Az elárasztott kripta — %d. / %d emelet%s" % [depth, floors,
			" — a mélyből páncél csikorog..." if depth >= floors else ""]
	return "A régi tárnák — %d. / %d emelet%s" % [depth, floors,
		" — keletről kopogás hallatszik..." if depth >= floors else ""]


static func story_won_text(story: String) -> String:
	if story == "crypt":
		return "A Tófenék Ura elesett! A lépcső szabad: fel a szigetre."
	if story == "entrance":
		return OldEntrance.WON_TEXT
	return "A Kopogó elhallgatott! A lépcső szabad: fel a kötélen."
