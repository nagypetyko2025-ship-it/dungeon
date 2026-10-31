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


## Lőrinc nincs a kútnál (a kocsmába költözött, vagy épp vele játszol): ilyenkor a műhely asztalán hagyott
## levele adja a kulcsot (desk_letter), és oda kell visszatenni a legyőzött Őrző után.
static func lorinc_away() -> bool:
	return Stranger.moved_to_tavern() or Progress.character == "wizard"


## A műhely asztala (WellCave "desk"): Lőrinc jegyzetei, és ha ő nincs a kútnál, a levele a rácsról.
## A levél elolvasása elindítja a küldetést; a legyőzött Őrző után a kulcs visszatétele teljesíti (arany).
static func desk_letter() -> String:
	if not available() or not lorinc_away():
		return ""
	match Progress.npc_quest_state(QUEST):
		"":
			Progress.set_npc_quest(QUEST, "active")
			Progress.save_game()
			Audio.play("ui_open")
			return LETTER_KEY
		"active":
			return LETTER_KEY
		"slain":
			# Az add_camp_gold újratölti a mentést: előbb az arany, aztán a többi változás.
			Progress.add_camp_gold(GOLD)
			Progress.set_npc_quest(QUEST, "done")
			Progress.save_game()
			Audio.play("level_up")
			return LETTER_DONE + "\n\n[color=#7a4a10](+%d tábori arany)[/color]" % GOLD
		"done":
			return LETTER_DONE
	return ""


const LETTER_KEY := "[i]Az asztalon, a tintatartó alá csúsztatva, egy frissebb levél. Mellette egy kis, rézből reszelt " \
	+ "kulcs.[/i]\n\n„Kedves barátom!\n\nHa ezt olvasod, Döme kinyitotta a járatot, én meg már a kocsmában ülök, és " \
	+ "Tóbiás borát iszom. Nem bírtam tovább a kút hidegét.\n\nA rács mögötti lépcső a Mélység legrégebbi bejárata. " \
	+ "Háromszáz éves vas, de a lakatja olajos, és éjjelente kalapácsolás hallatszik alulról. A királyi levéltár szerint " \
	+ "I. Aurél őrt állított a legelső kapuhoz, \"aki nem alszik és nem felejt\". Szerintem még mindig ott van.\n\n" \
	+ "Az iránytűm megmutatta a lakat belsejét, ezt a kulcsot reszeltem hozzá. Én nem merek lemenni. Te igen.\n\n" \
	+ "Ha legyőzted, ami lent van, tedd vissza a kulcsot az asztalra. A céh jutalmát a fiókban hagyom.\n\n— L.”\n\n" \
	+ "[color=#7a4a10](A rács mostantól nyitható: %d emelet lefelé. A J könyvben, Lőrinc fülén.)[/color]" % RUN_FLOORS
const LETTER_DONE := "[i]Visszateszed a rézkulcsot az asztalra. A fiókban egy erszény és egy cetli.[/i]\n\n" \
	+ "„Gellért volt az, ugye? Aurél fegyvernöke. A krónikában olvastam róla: megesküdött, hogy senki sem megy át a " \
	+ "kapun a király engedélye nélkül. A király meghalt, az eskü nem.\n\nKöszönöm, hogy leváltottad az őrségből. " \
	+ "Ha erre jársz a kocsmában, meghívlak egy pohárra, és mindent elmesélsz. — L.”"


const START_TEXT := "A legrégebbi bejárat: %d emelet lefelé. A lépcsőn friss olajfolt."
const FLOOR_TEXT := "A legrégebbi bejárat — %d. / %d emelet%s"
const NEAR_TEXT := " — alulról kalapácsolás hallatszik..."
const WON_TEXT := "Az Őrző térdre rogyott! A lépcső szabad: fel a műhelybe."
