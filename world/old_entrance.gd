class_name OldEntrance
## A legrégebbi bejárat: Lőrinc kút alatti műhelyében a rácsos lépcső (WellCave.GRATE_TILE). Lőrinc küldetése
## (QUEST, J könyv "Idegen a kútban" fül: a rácsot ő nyitja ki) után a lépcsőn le lehet menni: RUN_FLOORS emeletes
## történet-futás a próbatétel szabályaival (Challenge, "story": "entrance"); az utolsó emelet aréna, benne az Őrző
## (BOSS): I. Aurél páncélos kapuőre, aki háromszáz éve olajozza a rács lakatját. Jutalom: Az Őrző kulcsa,
## Lőrincnél arany és 3 új történet (Stranger.ENTRANCE_STORIES).

## "" → active (a rács nyitva) → slain (az Őrző legyőzve) → done (Lőrincnek jelentve).
const QUEST := "well_entrance"
const RUN_FLOORS := 5
const GOLD := 800
const REWARD_ID := "trinket_keeper_key"
## Az Őrző: a 0x72 elesett lovagja nagyban, sötét acélkékre árnyalva; csontvázakat hív a sírjából.
const BOSS := {"name": "Az Őrző", "rect": Rect2(128, 68, 16, 28), "scale": 4.0, "tint": Color(0.55, 0.7, 1.0),
	"health": 105, "damage": 5, "speed": 70.0, "xp": 100,
	"attacks": ["charge", "slam", "blink", "summon"], "minion": "skelet"}


static func run_challenge() -> Dictionary:
	return {"seed": 0, "floors": RUN_FLOORS, "boons": [], "banes": [], "score": 0.0, "level": 3,
		"difficulty": "Nehéz", "reward": "legendary", "mythic_chance": 0.0, "story": "entrance",
		"title": "A legrégebbi bejárat",
		"intro": "Lőrinc kulcsa csikorogva fordul a lakatban. A lépcső régebbi, mint a tábor, régebbi, mint a falu: "
			+ "%d emelet lefelé, és a legalján valaki, aki háromszáz éve őrzi." % RUN_FLOORS,
		"reward_text": "Jutalom, ha legyőzöd: Az Őrző kulcsa (egyedi legendás talizmán) és a lent szerzett aranyad.",
		"start_label": "Lemegyek"}


## Győzelem (a Dungeon hívja a LakeCrypt.story_reward-on át): a küldetés lépése és a jutalom.
static func reward() -> Dictionary:
	if Progress.npc_quest_state(QUEST) == "active":
		Progress.set_npc_quest(QUEST, "slain")
	return Items.mark_story(Items.create(REWARD_ID))


static func cleared() -> bool:
	return Progress.npc_quest_state(QUEST) in ["slain", "done"]


## Lőrinc kérhet-e már: kimentve, a műhely felrobbantva.
static func available() -> bool:
	return Stranger.is_rescued() and Blaster.well_open()


const START_TEXT := "A legrégebbi bejárat: %d emelet lefelé. A lépcsőn friss olajfolt."
const FLOOR_TEXT := "A legrégebbi bejárat — %d. / %d emelet%s"
const NEAR_TEXT := " — alulról kalapácsolás hallatszik..."
const WON_TEXT := "Az Őrző térdre rogyott! A lépcső szabad: fel a műhelybe."
