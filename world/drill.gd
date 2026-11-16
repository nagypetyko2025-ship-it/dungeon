class_name Drill
## Hadgyakorlat (Vas Szilárd hadnagy, a barakkban: Lieutenant.options "drill"): túlélős aréna. Egyetlen terem
## (a próbatétel szabályaival, "story": "drill", 1 emelet: Dungeon a kezdőszoba mellé arénát rak, room.lord
## "drill"), benne MAX_WAVES hullám szörny, egyre mélyebb emeletekről (wave_depth), egyre többen (wave_count).
## Az 1. szintről indulsz, a saját felszereléseddel; az a táborból NEM fogy el (Camp._enter_dungeon_now), így
## kidőlve sem veszik el, de amit a gyakorlaton szerzel, az sem jön fel. Kidőlve (DeathScreen) a túlélt hullámok
## után tábori arany (gold_for), a legjobb eredmény BEST_FLAG-ben; mind a MAX_WAVES után a terem lépcsője a
## győzelem (Dungeon._challenge_won): legendás tárgy (reward) + az arany.

const MAX_WAVES := 15
## A legjobb eredmény (túlélt hullámok) a Progress.npc_quests-ben, szövegként.
const BEST_FLAG := "drill_best"
## Hullámonként ennyi arany (összeadódik: a 10. túlélt hullám után 25 × (1 + ... + 10)).
const GOLD_PER_WAVE := 25
## Két hullám közti szünet (mp).
const BREAK_SECONDS := 4.0


static func run_challenge() -> Dictionary:
	return {"seed": 0, "floors": 1, "boons": [], "banes": [], "score": 0.0, "level": 2,
		"difficulty": "Gyakorlat", "reward": "legendary", "mythic_chance": 0.0, "story": "drill",
		"title": "Hadgyakorlat",
		"intro": "„Az aréna a barakk mögött van. %d hullám, egyre keményebbek. Az első szintről indulsz, " % MAX_WAVES
			+ "a saját felszereléseddel: ami nálad van, az nem vész el, ha kidőlsz — itt nem a halál a tét, hanem a becsület.”",
		"reward_text": "Kidőlve túlélt hullámonként arany (minél tovább bírod, annál több). Mind a %d után: legendás tárgy. " % MAX_WAVES
			+ "Eddigi legjobbad: %s." % best_text(),
		"start_label": "Indulok!"}


## A hullám szörnyeinek emelete: 1, 3, 5 ... (a 15. hullám a 29. emeleté).
static func wave_depth(wave: int) -> int:
	return wave * 2 - 1


static func wave_count(wave: int) -> int:
	return mini(3 + wave, 14)


static func gold_for(waves_cleared: int) -> int:
	return GOLD_PER_WAVE * waves_cleared * (waves_cleared + 1) / 2


static func best() -> int:
	return int(Progress.npc_quest_state(BEST_FLAG))


static func best_text() -> String:
	var value := best()
	return "még nincs" if value <= 0 else ("mind a %d hullám" % MAX_WAVES if value >= MAX_WAVES else "%d hullám" % value)


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


## Győzelem: legendás tárgy (a Dungeon._challenge_won teszi a ládába) és a hullámok aranya.
static func reward() -> Dictionary:
	finish(MAX_WAVES)
	return Items.random_item("legendary", "legendary", wave_depth(MAX_WAVES))


static func waves_cleared() -> int:
	return int(GameState.challenge.get("waves_cleared", 0))


const START_TEXT := "Hadgyakorlat: %d hullám. Vas Szilárd figyel — mutasd meg, mit tudsz!"
const WON_TEXT := "Mind a %d hullám ledöntve! Vas Szilárd bólint. A lépcső vissza a barakkba visz."


static func wave_text(wave: int) -> String:
	return "%d. / %d hullám%s" % [wave, MAX_WAVES, " — az utolsó!" if wave >= MAX_WAVES else ""]
