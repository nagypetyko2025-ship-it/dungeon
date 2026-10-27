class_name Quests
## Küldetések a kocsmárostól (a városban, a Mélységi kocsmában). Mind egyszerre fut, nem
## kell felvenni; a haladás csak a kazamatában számít (a gyakorló pályán nem), futásokon át
## összeadódik, és mentődik (Progress). Ha kész, a kocsmárosnál átveszed a jutalmat:
## arany (a táborba) vagy tárgy (a tábori ládába). Minden küldetés egyszer teljesíthető.
##
## kind:   kill (target: szörnytípusok, üres = bármilyen), floor (elért emelet),
##         level (elért karakterszint), chest (kinyitott láda), gold (felszedett arany),
##         room (kitisztított szoba), boss (legyőzött főellenség)
## goal:   ennyi kell; "floor"/"level"-nél a legnagyobb elért érték számít
## reward: {"gold": n} vagy {"item": ritkaság}
## tier:   nehézség, "easy" (könnyű: 40-100 arany vagy ritka tárgy), "medium" (közepes:
##         150-300 arany vagy epikus tárgy) vagy "hard" (nehéz: 400-800 arany vagy legendás tárgy),
##         lásd TIERS

const TIERS := {
	"easy": {"name": "Könnyű", "color": Color(0.24, 0.5, 0.2)},
	"medium": {"name": "Közepes", "color": Color(0.72, 0.4, 0.05)},
	"hard": {"name": "Nehéz", "color": Color(0.7, 0.14, 0.12)},
}

const ALL := {
	# ---- Könnyű
	"rat_catcher": {"name": "Kártevőirtás", "kind": "kill", "goal": 15, "target": [], "tier": "easy",
		"text": "Ölj meg 15 szörnyet a kazamatában.", "reward": {"gold": 60}},
	"bone_dust": {"name": "Csontok porrá", "kind": "kill", "goal": 6, "target": ["skelet"], "tier": "easy",
		"text": "Ölj meg 6 csontvázat.", "reward": {"item": "rare"}},
	"goblin_hunter": {"name": "Goblinvadász", "kind": "kill", "goal": 8, "target": ["goblin"], "tier": "easy",
		"text": "Ölj meg 8 goblint.", "reward": {"gold": 50}},
	"zombie_plague": {"name": "Zombijárvány", "kind": "kill", "goal": 6, "target": ["tiny_zombie", "zombie"], "tier": "easy",
		"text": "Ölj meg 6 zombit (kis zombi is számít).", "reward": {"gold": 55}},
	"into_the_deep": {"name": "Le a mélybe", "kind": "floor", "goal": 3, "tier": "easy",
		"text": "Juss le a 3. emeletre.", "reward": {"item": "rare"}},
	"seasoned": {"name": "Tapasztalt kalandor", "kind": "level", "goal": 5, "tier": "easy",
		"text": "Érd el az 5. karakterszintet egy futásban.", "reward": {"gold": 80}},
	"treasure_hunter": {"name": "Kincskereső", "kind": "chest", "goal": 4, "tier": "easy",
		"text": "Nyiss ki 4 ládát.", "reward": {"gold": 70}},
	"pocket_money": {"name": "Zsebpénz", "kind": "gold", "goal": 100, "tier": "easy",
		"text": "Szedj fel összesen 100 aranyat.", "reward": {"item": "rare"}},
	"cleaner": {"name": "Nagytakarítás", "kind": "room", "goal": 8, "tier": "easy",
		"text": "Tisztíts ki 8 szobát.", "reward": {"gold": 60}},
	"first_steps": {"name": "Első lépcső", "kind": "floor", "goal": 2, "tier": "easy",
		"text": "Juss le a 2. emeletre.", "reward": {"gold": 40}},
	"greenhorn": {"name": "Zöldfülű", "kind": "level", "goal": 3, "tier": "easy",
		"text": "Érd el a 3. karakterszintet egy futásban.", "reward": {"gold": 40}},
	"slime_work": {"name": "Nyálkás munka", "kind": "kill", "goal": 8, "tier": "easy",
		"target": ["tiny_slug", "slug", "muddy", "swampy"],
		"text": "Ölj meg 8 nyálkalényt (csiga, sárlény, mocsárlény).", "reward": {"gold": 45}},
	"imp_trouble": {"name": "Ördögfiókák", "kind": "kill", "goal": 5, "target": ["imp"], "tier": "easy",
		"text": "Ölj meg 5 kisördögöt.", "reward": {"gold": 50}},
	"archer_duel": {"name": "Íjászpárbaj", "kind": "kill", "goal": 5, "target": ["archer"], "tier": "easy",
		"text": "Ölj meg 5 erdei íjászt.", "reward": {"gold": 55}},
	"orc_menace": {"name": "Orkveszedelem", "kind": "kill", "goal": 6, "target": ["orc_warrior", "masked_orc"], "tier": "easy",
		"text": "Ölj meg 6 orkot (harcos vagy álarcos).", "reward": {"gold": 60}},
	"pumpkin_patch": {"name": "Tökfejek", "kind": "kill", "goal": 4, "target": ["pumpkin_dude"], "tier": "easy",
		"text": "Ölj meg 4 töklámpást.", "reward": {"item": "rare"}},
	"chest_trap": {"name": "Ládacsapda", "kind": "kill", "goal": 2, "target": ["mimic"], "tier": "easy",
		"text": "Ölj meg 2 mimikét (a ládának álcázott szörnyet).", "reward": {"gold": 70}},
	"graveyard_keeper": {"name": "Temetőőr", "kind": "kill", "goal": 20, "tier": "easy",
		"target": ["tiny_zombie", "zombie", "skelet"],
		"text": "Ölj meg 20 élőhalottat (zombi, csontváz).", "reward": {"gold": 70}},
	"lizard_hunt": {"name": "Gyíkvadászat", "kind": "kill", "goal": 5, "target": ["lizard", "lizard_scout"], "tier": "easy",
		"text": "Ölj meg 5 gyíkembert.", "reward": {"gold": 65}},
	"little_devils": {"name": "Kis patások", "kind": "kill", "goal": 5, "target": ["wogol", "chort"], "tier": "easy",
		"text": "Ölj meg 5 wogolt vagy csortot.", "reward": {"gold": 60}},
	"plague_doctors": {"name": "Pestisdoktorok", "kind": "kill", "goal": 4, "target": ["plague_doctor"], "tier": "easy",
		"text": "Ölj meg 4 pestisdoktort.", "reward": {"item": "rare"}},
	"goblin_hunter_2": {"name": "Goblinirtó", "kind": "kill", "goal": 20, "target": ["goblin"], "tier": "easy",
		"text": "Ölj meg 20 goblint.", "reward": {"gold": 70}},
	"monster_hunter": {"name": "Szörnyvadász", "kind": "kill", "goal": 40, "target": [], "tier": "easy",
		"text": "Ölj meg összesen 40 szörnyet.", "reward": {"gold": 80}},
	"butcher": {"name": "Mészáros", "kind": "kill", "goal": 80, "target": [], "tier": "easy",
		"text": "Ölj meg összesen 80 szörnyet.", "reward": {"gold": 100}},
	"fifth_floor": {"name": "Az ötödik emelet", "kind": "floor", "goal": 5, "tier": "easy",
		"text": "Juss le az 5. emeletre.", "reward": {"item": "rare"}},
	"hardened": {"name": "Edzett harcos", "kind": "level", "goal": 8, "tier": "easy",
		"text": "Érd el a 8. karakterszintet egy futásban.", "reward": {"gold": 90}},
	"lockpicker": {"name": "Ládafeltörő", "kind": "chest", "goal": 8, "tier": "easy",
		"text": "Nyiss ki 8 ládát.", "reward": {"gold": 75}},
	"full_purse": {"name": "Teli erszény", "kind": "gold", "goal": 250, "tier": "easy",
		"text": "Szedj fel összesen 250 aranyat.", "reward": {"gold": 70}},
	"room_by_room": {"name": "Szobáról szobára", "kind": "room", "goal": 15, "tier": "easy",
		"text": "Tisztíts ki 15 szobát.", "reward": {"gold": 80}},
	# ---- Könnyű (második adag)
	"fly_swatter": {"name": "Légycsapó", "kind": "kill", "goal": 10, "target": ["fly"], "tier": "easy",
		"text": "Ölj meg 10 legyet.", "reward": {"gold": 45}},
	"short_fuse": {"name": "Rövid kanóc", "kind": "kill", "goal": 5, "target": ["kamikaze_goblin"], "tier": "easy",
		"text": "Ölj meg 5 robbanó goblint, mielőtt odaérnek hozzád.", "reward": {"item": "rare"}},
	"goblin_army": {"name": "Goblinsereg", "kind": "kill", "goal": 10, "tier": "easy",
		"target": ["spear_goblin", "club_goblin", "archer_goblin"],
		"text": "Ölj meg 10 felfegyverzett goblint (lándzsás, bunkós vagy íjász).", "reward": {"gold": 60}},
	"pirate_raid": {"name": "Kalózvadászat", "kind": "kill", "goal": 6, "target": ["pirate_grunt", "pirate_gunner"], "tier": "easy",
		"text": "Ölj meg 6 kalózt (matróz vagy puskás).", "reward": {"gold": 60}},
	"sticky_business": {"name": "Ragacsos ügy", "kind": "kill", "goal": 8, "target": ["green_slime", "frost_slime"], "tier": "easy",
		"text": "Ölj meg 8 zselét (zöld vagy fagyos).", "reward": {"gold": 55}},
	"hunter_hunted": {"name": "Vadászok vadásza", "kind": "kill", "goal": 4, "target": ["huntress"], "tier": "easy",
		"text": "Ölj meg 4 vadásznőt.", "reward": {"item": "rare"}},
	"ice_cold": {"name": "Jéghideg", "kind": "kill", "goal": 4, "target": ["ice_zombie"], "tier": "easy",
		"text": "Ölj meg 4 jégzombit (vigyázz, megfagyasztanak!).", "reward": {"gold": 60}},
	"fourth_floor": {"name": "A negyedik emelet", "kind": "floor", "goal": 4, "tier": "easy",
		"text": "Juss le a 4. emeletre.", "reward": {"gold": 50}},
	"chest_hunter": {"name": "Ládavadász", "kind": "chest", "goal": 12, "tier": "easy",
		"text": "Nyiss ki 12 ládát.", "reward": {"gold": 90}},
	"gold_fever": {"name": "Aranyláz", "kind": "gold", "goal": 400, "tier": "easy",
		"text": "Szedj fel összesen 400 aranyat.", "reward": {"item": "rare"}},
	# ---- Könnyű (harmadik adag)
	"rat_plague": {"name": "Patkányjárás", "kind": "kill", "goal": 12, "target": ["rat"], "tier": "easy",
		"text": "Ölj meg 12 patkányt.", "reward": {"gold": 45}},
	"spider_webs": {"name": "Pókhálók", "kind": "kill", "goal": 10, "target": ["spider"], "tier": "easy",
		"text": "Ölj meg 10 kazamatapókot.", "reward": {"gold": 50}},
	"bat_swarm": {"name": "Denevérraj", "kind": "kill", "goal": 10, "target": ["cave_bat"], "tier": "easy",
		"text": "Ölj meg 10 barlangi denevért.", "reward": {"item": "rare"}},
	"harvest_thieves": {"name": "Termésrablók", "kind": "kill", "goal": 8, "target": ["farmer_goblin"], "tier": "easy",
		"text": "Ölj meg 8 gyűjtögető goblint.", "reward": {"gold": 50}},
	"mushroom_picking": {"name": "Gombaszedés", "kind": "kill", "goal": 6, "target": ["toadstool"], "tier": "easy",
		"text": "Ölj meg 6 mérges gombaszörnyet (vigyázz a spórafelhőre!).", "reward": {"gold": 60}},
	"orc_raiders": {"name": "Martalócok", "kind": "kill", "goal": 6, "target": ["orc_raider"], "tier": "easy",
		"text": "Ölj meg 6 ork martalócot.", "reward": {"gold": 70}},
	"bug_hunt": {"name": "Bogárvadászat", "kind": "kill", "goal": 20, "target": ["fly", "spider", "rat"], "tier": "easy",
		"text": "Ölj meg 20 kártevőt (légy, pók vagy patkány).", "reward": {"gold": 60}},
	"monster_slayer": {"name": "Szörnyölő", "kind": "kill", "goal": 150, "target": [], "tier": "easy",
		"text": "Ölj meg összesen 150 szörnyet.", "reward": {"gold": 110}},
	"seventh_floor": {"name": "A hetedik emelet", "kind": "floor", "goal": 7, "tier": "easy",
		"text": "Juss le a 7. emeletre.", "reward": {"item": "rare"}},
	"chest_collector": {"name": "Ládagyűjtő", "kind": "chest", "goal": 20, "tier": "easy",
		"text": "Nyiss ki 20 ládát.", "reward": {"gold": 90}},
	"silver_purse": {"name": "Ezüsterszény", "kind": "gold", "goal": 600, "tier": "easy",
		"text": "Szedj fel összesen 600 aranyat.", "reward": {"item": "rare"}},
	"deep_cleaning": {"name": "Mélytakarítás", "kind": "room", "goal": 30, "tier": "easy",
		"text": "Tisztíts ki 30 szobát.", "reward": {"gold": 90}},
	# ---- Közepes
	"first_king": {"name": "Az első király", "kind": "boss", "goal": 1, "tier": "medium",
		"text": "Győzz le egy főellenséget (a 3. emeleten vár).", "reward": {"item": "epic"}},
	"necro_hunter": {"name": "Halottidéző-vadász", "kind": "kill", "goal": 5, "target": ["necromancer"], "tier": "medium",
		"text": "Ölj meg 5 nekromantát.", "reward": {"gold": 200}},
	"giant_slayer": {"name": "Óriásölő", "kind": "kill", "goal": 5, "target": ["big_zombie", "ogre"], "tier": "medium",
		"text": "Ölj meg 5 óriást (óriászombi vagy ogre).", "reward": {"item": "epic"}},
	"mage_hunter": {"name": "Mágusvadász", "kind": "kill", "goal": 8, "target": ["dark_mage", "fire_witch"], "tier": "medium",
		"text": "Ölj meg 8 varázslót (sötét mágus vagy tűzboszorkány).", "reward": {"gold": 220}},
	"dwarf_rage": {"name": "Törpeharag", "kind": "kill", "goal": 6, "target": ["dwarf", "dwarf_berserker"], "tier": "medium",
		"text": "Ölj meg 6 törpét (harcos vagy berzerker).", "reward": {"gold": 200}},
	"tenth_floor": {"name": "A tizedik emelet", "kind": "floor", "goal": 10, "tier": "medium",
		"text": "Juss le a 10. emeletre.", "reward": {"item": "epic"}},
	"veteran_adventurer": {"name": "Veterán kalandor", "kind": "level", "goal": 15, "tier": "medium",
		"text": "Érd el a 15. karakterszintet egy futásban.", "reward": {"gold": 250}},
	"king_slayer": {"name": "Királygyilkos", "kind": "boss", "goal": 3, "tier": "medium",
		"text": "Győzz le összesen 3 főellenséget.", "reward": {"item": "epic"}},
	"massacre": {"name": "Mészárlás", "kind": "kill", "goal": 250, "target": [], "tier": "medium",
		"text": "Ölj meg összesen 250 szörnyet.", "reward": {"gold": 250}},
	"treasury": {"name": "Kincstár", "kind": "gold", "goal": 1000, "tier": "medium",
		"text": "Szedj fel összesen 1000 aranyat.", "reward": {"gold": 200}},
	"dungeon_sweeper": {"name": "Kazamata-takarító", "kind": "room", "goal": 50, "tier": "medium",
		"text": "Tisztíts ki 50 szobát.", "reward": {"gold": 300}},
	# ---- Közepes (második adag)
	"shaman_hunt": {"name": "Sámánvadászat", "kind": "kill", "goal": 6, "target": ["orc_shaman", "orc_mage"], "tier": "medium",
		"text": "Ölj meg 6 ork varázslót (sámán vagy mágus). Ők gyógyítják és védik a többit.", "reward": {"gold": 200}},
	"fallen_order": {"name": "A bukott rend", "kind": "kill", "goal": 6, "target": ["fallen_knight"], "tier": "medium",
		"text": "Ölj meg 6 bukott lovagot.", "reward": {"item": "epic"}},
	"broken_wings": {"name": "Tört szárnyak", "kind": "kill", "goal": 4, "target": ["angel"], "tier": "medium",
		"text": "Ölj meg 4 angyalt (a többi szörnyet gyógyítják).", "reward": {"gold": 220}},
	"big_demons": {"name": "Nagy démonok", "kind": "kill", "goal": 5, "target": ["big_demon"], "tier": "medium",
		"text": "Ölj meg 5 nagy démont.", "reward": {"item": "epic"}},
	"maze_lord": {"name": "A labirintus ura", "kind": "kill", "goal": 4, "target": ["minotaur"], "tier": "medium",
		"text": "Ölj meg 4 minotauruszt.", "reward": {"gold": 250}},
	"legion": {"name": "Csontlégió", "kind": "kill", "goal": 8, "target": ["skeleton_legionary"], "tier": "medium",
		"text": "Ölj meg 8 csontlégióst.", "reward": {"gold": 230}},
	"fifteenth_floor": {"name": "A tizenötödik emelet", "kind": "floor", "goal": 15, "tier": "medium",
		"text": "Juss le a 15. emeletre.", "reward": {"item": "epic"}},
	"boss_hunter": {"name": "Főellenség-vadász", "kind": "boss", "goal": 5, "tier": "medium",
		"text": "Győzz le összesen 5 főellenséget.", "reward": {"gold": 300}},
	"deep_pockets": {"name": "Mély zsebek", "kind": "gold", "goal": 2500, "tier": "medium",
		"text": "Szedj fel összesen 2500 aranyat.", "reward": {"gold": 250}},
	"bloodbath": {"name": "Vérfürdő", "kind": "kill", "goal": 500, "target": [], "tier": "medium",
		"text": "Ölj meg összesen 500 szörnyet.", "reward": {"gold": 300}},
	# ---- Közepes (harmadik adag)
	"barbarian_brawl": {"name": "Barbárpárbaj", "kind": "kill", "goal": 5, "target": ["barbarian"], "tier": "medium",
		"text": "Ölj meg 5 barbárt.", "reward": {"gold": 180}},
	"captain_hunt": {"name": "Kapitányvadászat", "kind": "kill", "goal": 3, "target": ["pirate_captain"], "tier": "medium",
		"text": "Ölj meg 3 kalózkapitányt (előbb a pajzsát kell letörnöd).", "reward": {"item": "epic"}},
	"wraith_hunt": {"name": "Lidércűzés", "kind": "kill", "goal": 6, "target": ["blood_wraith"], "tier": "medium",
		"text": "Ölj meg 6 vérszellemet.", "reward": {"gold": 200}},
	"fire_clan": {"name": "A tűzklán", "kind": "kill", "goal": 5, "target": ["fire_ninja"], "tier": "medium",
		"text": "Ölj meg 5 lángnindzsát.", "reward": {"item": "epic"}},
	"renegades": {"name": "Hitehagyottak", "kind": "kill", "goal": 5, "target": ["renegade_monk"], "tier": "medium",
		"text": "Ölj meg 5 hitehagyott szerzetest (a társaikat gyógyítják: velük kezdd!).", "reward": {"gold": 220}},
	"chaos_spawns": {"name": "Káoszivadékok", "kind": "kill", "goal": 10, "target": ["chaos_spawn"], "tier": "medium",
		"text": "Ölj meg 10 káoszivadékot (a 16. emelet alatt törnek fel).", "reward": {"item": "epic"}},
	"level_twelve": {"name": "Tizenkettes szint", "kind": "level", "goal": 12, "tier": "medium",
		"text": "Érd el a 12. karakterszintet egy futásban.", "reward": {"gold": 160}},
	"chest_master": {"name": "Ládamester", "kind": "chest", "goal": 40, "tier": "medium",
		"text": "Nyiss ki 40 ládát.", "reward": {"gold": 250}},
	"gold_hoard": {"name": "Aranyhegy", "kind": "gold", "goal": 5000, "tier": "medium",
		"text": "Szedj fel összesen 5000 aranyat.", "reward": {"item": "epic"}},
	"room_conqueror": {"name": "Kazamata-hódító", "kind": "room", "goal": 100, "tier": "medium",
		"text": "Tisztíts ki 100 szobát.", "reward": {"gold": 250}},
	"boss_collector": {"name": "Főellenség-gyűjtő", "kind": "boss", "goal": 7, "tier": "medium",
		"text": "Győzz le összesen 7 főellenséget.", "reward": {"gold": 300}},
	# ---- Nehéz
	"dragon_slayer": {"name": "Sárkányölő", "kind": "kill", "goal": 3, "tier": "hard",
		"target": ["fire_dragon", "frost_dragon", "shadow_dragon", "gold_dragon"],
		"text": "Ölj meg 3 sárkányt (tűz-, jég-, árnyék- vagy aranysárkányt).", "reward": {"item": "legendary"}},
	"lich_bane": {"name": "Lichvész", "kind": "kill", "goal": 3, "target": ["lich"], "tier": "hard",
		"text": "Ölj meg 3 lichet. Vendel hálás lesz érte.", "reward": {"gold": 500}},
	"demon_lords": {"name": "Démonurak", "kind": "kill", "goal": 6, "tier": "hard",
		"target": ["purple_demon", "red_demon", "armored_demon"],
		"text": "Ölj meg 6 nagyúri démont (lila, vörös vagy páncélos).", "reward": {"item": "legendary"}},
	"frozen_giants": {"name": "Fagyott óriások", "kind": "kill", "goal": 5, "target": ["yeti", "mammoth", "wendigo"], "tier": "hard",
		"text": "Ölj meg 5 fagyos óriást (jeti, mamut vagy wendigo).", "reward": {"gold": 450}},
	"crab_feast": {"name": "Rákpörkölt", "kind": "kill", "goal": 3, "target": ["giant_crab"], "tier": "hard",
		"text": "Ölj meg 3 óriásrákot.", "reward": {"gold": 400}},
	"bone_colossus": {"name": "Csontkolosszus", "kind": "kill", "goal": 3, "target": ["giant_skeleton"], "tier": "hard",
		"text": "Ölj meg 3 óriás csontvázat.", "reward": {"item": "legendary"}},
	"twentieth_floor": {"name": "A huszadik emelet", "kind": "floor", "goal": 20, "tier": "hard",
		"text": "Juss le a 20. emeletre, a Mélység Urához.", "reward": {"item": "legendary"}},
	"thirtieth_floor": {"name": "A harmincadik emelet", "kind": "floor", "goal": 30, "tier": "hard",
		"text": "Juss le a 30. emeletre.", "reward": {"gold": 800}},
	"legend": {"name": "Élő legenda", "kind": "level", "goal": 25, "tier": "hard",
		"text": "Érd el a 25. karakterszintet egy futásban.", "reward": {"gold": 600}},
	"king_terror": {"name": "A királyok réme", "kind": "boss", "goal": 10, "tier": "hard",
		"text": "Győzz le összesen 10 főellenséget.", "reward": {"item": "legendary"}},
	# ---- Nehéz (második adag)
	"hound_pack": {"name": "Kopófalka", "kind": "kill", "goal": 8, "target": ["chaos_hound"], "tier": "hard",
		"text": "Ölj meg 8 káoszkopót.", "reward": {"item": "legendary"}},
	"chaos_triad": {"name": "Káoszhármas", "kind": "kill", "goal": 12, "tier": "hard",
		"target": ["chaos_maw", "chaos_shard", "chaos_weaver"],
		"text": "Ölj meg 12 mély káoszlényt (káosztorok, hasadékszilánk vagy káoszszövő; a 25. emelet alatt).",
		"reward": {"gold": 800}},
	"twenty_fifth_floor": {"name": "A huszonötödik emelet", "kind": "floor", "goal": 25, "tier": "hard",
		"text": "Juss le a 25. emeletre.", "reward": {"gold": 550}},
	"fortieth_floor": {"name": "A negyvenedik emelet", "kind": "floor", "goal": 40, "tier": "hard",
		"text": "Juss le a 40. emeletre, a Káosz Urának termébe.", "reward": {"item": "legendary"}},
	"abyss_hero": {"name": "A Mélység hőse", "kind": "level", "goal": 20, "tier": "hard",
		"text": "Érd el a 20. karakterszintet egy futásban.", "reward": {"gold": 500}},
	"doomsday": {"name": "Végítélet", "kind": "kill", "goal": 2000, "target": [], "tier": "hard",
		"text": "Ölj meg összesen 2000 szörnyet.", "reward": {"gold": 800}},
	"abyss_executioner": {"name": "A Mélység hóhéra", "kind": "boss", "goal": 20, "tier": "hard",
		"text": "Győzz le összesen 20 főellenséget.", "reward": {"item": "legendary"}},
}


## Esemény a kazamatából: minden még futó, illő küldetés haladása.
## `value`: kill-nél a szörnytípus neve, gold-nál az összeg, floor/level-nél az érték.
static func notify(kind: String, value: Variant = 1) -> void:
	# Gyakorláskor és csalt futásban a küldetések nem haladnak.
	if GameState.tutorial or GameState.cheated:
		return
	var changed := false
	for id: String in ALL:
		var definition: Dictionary = ALL[id]
		if definition["kind"] != kind or Progress.quests_done.has(id) or is_complete(id):
			continue
		var amount := progress(id)
		match kind:
			"kill":
				var targets: Array = definition.get("target", [])
				if not targets.is_empty() and not targets.has(str(value)):
					continue
				amount += 1
			"gold":
				amount += int(value)
			"floor", "level":
				amount = maxi(amount, int(value))
			_:
				amount += 1
		Progress.quest_progress[id] = mini(amount, int(definition["goal"]))
		changed = true
	if changed:
		Progress.save_game()


static func progress(id: String) -> int:
	if Progress.quests_done.has(id):
		return int(ALL[id]["goal"])
	var amount := int(Progress.quest_progress.get(id, 0))
	# Emeletes küldetés: ha már jártál ilyen mélyen (akár a küldetés előtt is), az is számít.
	if ALL[id]["kind"] == "floor":
		amount = mini(maxi(amount, Progress.deepest), int(ALL[id]["goal"]))
	return amount


## Kész, de a jutalom még nincs átvéve?
static func is_complete(id: String) -> bool:
	return not Progress.quests_done.has(id) and progress(id) >= int(ALL[id]["goal"])


## A kész, átvehető jutalmú küldetések.
static func ready_ids() -> Array[String]:
	var ids: Array[String] = []
	for id: String in ALL:
		if is_complete(id):
			ids.append(id)
	return ids


## Rövid szöveg a kijelzőnek: ha van átvehető jutalom, az; különben a teljesítéshez
## legközelebb álló futó küldetés, pl. "Goblinvadász: 3 / 8" ("" ha minden kész).
static func tracker_text() -> String:
	var ready := ready_ids().size()
	if ready > 0:
		return ("Küldetés kész! Jutalom a kocsmárosnál." if ready == 1
			else "%d küldetés kész! Jutalmak a kocsmárosnál." % ready)
	var best := ""
	var best_ratio := -1.0
	for id: String in ALL:
		if Progress.quests_done.has(id):
			continue
		var ratio := progress(id) / float(ALL[id]["goal"])
		if ratio > best_ratio:
			best_ratio = ratio
			best = id
	if best.is_empty():
		return ""
	return "%s: %d / %d   [J]" % [ALL[best]["name"], progress(best), ALL[best]["goal"]]


static func reward_text(id: String) -> String:
	var reward: Dictionary = ALL[id]["reward"]
	if reward.has("gold"):
		return "%d tábori arany" % reward["gold"]
	return "%s tárgy (a tábori ládába)" % Items.RARITIES[reward["item"]]["name"].to_lower()


## Jutalom átvétele: a küldetés teljesítettnek számít. Visszaadja a jutalom leírását ("" ha nem kész).
static func turn_in(id: String) -> String:
	if not is_complete(id):
		return ""
	var reward: Dictionary = ALL[id]["reward"]
	var text := ""
	if reward.has("gold"):
		Progress.camp_gold += int(reward["gold"])
		text = "+%d tábori arany" % reward["gold"]
	else:
		var item := Items.random_item(reward["item"], reward["item"])
		Progress.stash.append(item)
		text = "%s (a tábori ládába került)" % item["name"]
	Progress.quests_done.append(id)
	Progress.quest_progress.erase(id)
	Progress.save_game()
	return text
