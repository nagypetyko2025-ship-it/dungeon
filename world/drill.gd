class_name Drill
## Hadgyakorlat (Vas Szilárd hadnagy, a barakkban: Lieutenant.options "drill"): túlélős aréna. Egyetlen terem
## (a próbatétel szabályaival, "story": "drill", 1 emelet: Dungeon a kezdőszoba mellé arénát rak, room.lord
## "drill"), benne végtelen hullám szörny, egyre mélyebb emeletekről (wave_depth), egyre többen (wave_count).
## Az 1. szintről indulsz, a saját felszereléseddel; az a táborból NEM fogy el (Camp._enter_dungeon_now), így
## kidőlve sem veszik el, de amit a gyakorlaton szerzel, az sem jön fel. Kidőlve (DeathScreen) a túlélt hullámok
## után tábori arany (gold_for), a legjobb eredmény BEST_FLAG-ben. A MAX_WAVES. hullám után kinyílik a terem
## lépcsője: azon kilépve győzelem (Dungeon._challenge_won): legendás tárgy (reward) + az arany; vagy maradsz, és a
## hullámok mennek tovább (a lépcső nyitva marad). Kidőlve csak az arany jár, a legendás nem.

const MAX_WAVES := 15
## A legjobb eredmény (túlélt hullámok) a Progress.npc_quests-ben, szövegként.
const BEST_FLAG := "drill_best"
## A w. túlélt hullám aranya: GOLD_BASE + GOLD_STEP × w (lassan nő; a felhasználó kérésére, a régi 25 × w túl gyorsan
## nőtt). Összesen: 15 hullám 690, 30 hullám 1830, 50 hullám 4050 arany.
const GOLD_BASE := 30
const GOLD_STEP := 2
## Két hullám közti szünet (mp); a MAX_WAVES. után hosszabb, hogy eldönthesd: kilépsz vagy maradsz.
## Belépéskor ennyi idő a felkészülésre, aztán jön az első hullám (a többi a kar meghúzására, lásd Room._wave_done).
const START_DELAY := 1.5
## A kilépő lépcső helye a MAX_WAVES. után (a pálya jobb részén, DrillArena).
const EXIT_TILE := Vector2i(11, 0)
## Hullámonként a futásba kapott arany (lent a boltban elkölthető, fel nem hozható): WAVE_GOLD_BASE + STEP × hullám.
const WAVE_GOLD_BASE := 20
const WAVE_GOLD_STEP := 10
## A hullámok szörnyei legfeljebb erről az emeletről jönnek.
const MAX_DEPTH := 99


static func run_challenge() -> Dictionary:
	return {"seed": 0, "floors": 1, "boons": [], "banes": [], "score": 0.0, "level": 2,
		"difficulty": "Gyakorlat", "reward": "legendary", "mythic_chance": 0.0, "story": "drill",
		"title": "Hadgyakorlat",
		"intro": "„Az aréna a barakk mögött van. A hullámok egyre keményebbek, és nem érnek véget. %d után kiléphetsz, ha akarsz. Az első szintről indulsz, " % MAX_WAVES
			+ "a saját felszereléseddel: ami nálad van, az nem vész el, ha kidőlsz — itt nem a halál a tét, hanem a becsület.”",
		"reward_text": "Túlélt hullámonként arany (minél tovább bírod, annál több). A %d. hullám után a lépcsőn kilépve legendás tárgy is jár; ha maradsz és kidőlsz, csak az arany. " % MAX_WAVES
			+ "Eddigi legjobbad: %s." % best_text(),
		"start_label": "Indulok!"}


## A hullám szörnyeinek emelete: 1, 3, 5 ... (a 15. hullám a 29. emeleté).
static func wave_depth(wave: int) -> int:
	return mini(wave * 2 - 1, MAX_DEPTH)


static func wave_count(wave: int) -> int:
	return mini(3 + wave, 14)


static func wave_gold(wave: int) -> int:
	return WAVE_GOLD_BASE + WAVE_GOLD_STEP * wave


static func gold_for(waves_cleared: int) -> int:
	return GOLD_BASE * waves_cleared + GOLD_STEP * waves_cleared * (waves_cleared + 1) / 2


static func best() -> int:
	return int(Progress.npc_quest_state(BEST_FLAG))


static func best_text() -> String:
	var value := best()
	return "még nincs" if value <= 0 else "%d hullám" % value


## A futás vége (kidőlés vagy győzelem): a legjobb eredmény frissül; az arany a táborba. Visszaadja az aranyat.
static func finish(waves_cleared: int) -> int:
	if GameState.cheated:
		return 0
	if waves_cleared > best():
		Progress.set_npc_quest(BEST_FLAG, str(waves_cleared))
	var gold := gold_for(waves_cleared)
	if gold > 0:
		Progress.add_camp_gold(gold)
	return gold


## Kilépés a lépcsőn (győzelem): legendás tárgy (a Dungeon._challenge_won teszi a ládába) és a túlélt hullámok aranya.
static func reward() -> Dictionary:
	finish(waves_cleared())
	return Items.random_item("legendary", "legendary", wave_depth(MAX_WAVES))


static func waves_cleared() -> int:
	return int(GameState.challenge.get("waves_cleared", 0))


const START_TEXT := "Hadgyakorlat: a hullámok nem érnek véget, a %d. után kiléphetsz. Vas Szilárd figyel — mutasd meg, mit tudsz!"
const WON_TEXT := "%d hullám ledöntve! A lépcsőn kiléphetsz a jutalommal — vagy maradj, jön a következő..."


static func wave_text(wave: int) -> String:
	if wave > MAX_WAVES:
		return "%d. hullám — a lépcsőn kiléphetsz a jutalommal" % wave
	return "%d. / %d hullám%s" % [wave, MAX_WAVES, " — utána kiléphetsz" if wave == MAX_WAVES else ""]
