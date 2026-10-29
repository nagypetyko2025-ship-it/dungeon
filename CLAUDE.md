# Dungeon (Godot 4.7.2) — munkajegyzet Claude-nak

Rövid, hogy ne kelljen minden munkamenetben újra kinyomozni. A felhasználóval **magyarul** beszélünk.

## Eszközök (Windows)
- Godot: `C:\Users\Peti\Desktop\Godot_v4.7.2-stable_win64.exe` (nincs a PATH-on)
- Git: `C:\Program Files\Git\cmd\git.exe` (PowerShellben nincs a PATH-on; Bash-ben is ezt hívd)
- Python + PIL elérhető (képek kivágása, átszínezése). ogg-kódoló nincs: hangot .wav-ban tegyél be (az Audio kezeli).
- Pythonból GDScript-et szerkesztve a `\n` és a `\` + sortörés heredocban könnyen valódi sortöréssé válik: a Python-szkriptet
  fájlba írd (Write), és azt futtasd.
- Bash heredocban a `\` + sortörés és a hosszú, idézőjeles szövegek elromlanak: GDScript-et **Edit/Write** eszközzel szerkessz, ne Pythonnal a shellből.

## Szokások (a felhasználó kérései)
- Kész munka után **azonnal commit + push** a GitHubra (`main`). Commit üzenet fájlból: `git commit -F <fájl>`.
- Grafika kell → **CC0** letöltés (opengameart / Kenney), és a mappa `LICENSE.txt`-jébe beírni a forrást.
  Már letöltött, újrahasználható CC0 csomagok: 0x72 DungeonTileset II (`assets/0x72_dungeon`, lista: `tile_list.txt`),
  Kenney RPG (`assets/shop/kenney_rpg.png`, 16 px + 1 px hézag → régió = `Vector2(coords) * 17`),
  "496 pixel art icons" (tárgyikonok, 34×34), MiniWorld Sprites (szörnyek, 16×16).
- A kód és a megjegyzések magyarul, statikus típusokkal (a figyelmeztetések hibának számítanak: nincs Variant-következtetés).

## Tesztelés
1. Import/fordítás ellenőrzés: `Godot --headless --path . --import` (stderr üres = jó).
2. Funkcióteszt: ideiglenes `_shot.gd` a projekt gyökerében (`extends SceneTree`, `_initialize`-ban jelenetváltás,
   `await process_frame`, képernyőkép: `root.get_texture().get_image().save_png(...)` a scratchpadbe), futtatás:
   `Godot --path . --script res://_shot.gd` (nem headless, hogy legyen kép). Utána `_shot.gd*` törlése.
3. **Mindig** mentsd el és állítsd vissza a mentést: `Progress.path()` (profilonként: save.cfg, save_2.cfg, save_3.cfg; lásd `world/profiles.gd`) tartalmát a teszt elején
   olvasd be, a végén írd vissza, és ellenőrizd ("mentés változatlan: true").
   **Ezen felül shellből is**: futtatás előtt `cp "$APPDATA/Godot/app_userdata/dungeon/save.cfg" <scratchpad>/save_backup.cfg`,
   utána *feltétel nélkül* vissza (ha a szkript elszáll, a GDScript-es visszaállítás nem fut le — egyszer már így
   íródott felül a felhasználó mentése). A tesztben ne írj a felhasználó táskájának foglalt helyére.
4. A végén a "2 RID allocations ... leaked" és a RenderingServer hibák ártalmatlanok.
- Képernyő: 1280×720 alap (canvas_items, expand); az ablakoknak ebbe bele kell férniük.

## Felépítés (fő fájlok)
- `world/dungeon.gd` emelet-generálás (boss minden 3. emeleten, 20. emelet: Vérfarkas + győzelem; 40. emelet (`CHAOS_DEPTH`): ugyanígy
  aréna, benne a Káosz Ura — `enemies/chaos_lord_boss.gd`, 1 000 000 HP, hasadékok/káoszörvény/káoszalak, `Room.lord` = "werewolf" / "chaos"), `world/camp.gd` tábor
  (város keletre: `world/town.gd`, 68 csempe széles, a keleti fele (OLD_END_X-től) üres rét, kovács: `world/smithy.gd`, veterán + sáros ösvény nyugatra, a végén a romos ház:
  `world/ruin.gd`, benne a tolvaj rejtekszobája: `world/thief.gd`), `world/shop_interior.gd` bolt.
- Félbehagyott futás: `world/run_save.gd` (a főellenség utáni pihenőnél kilépve a futás profilonként user://run*.cfg-be mentődik; a főmenü Folytatás gombja onnan indít; a kazamatába visszatéréskor / feladáskor / új játéknál törlődik; multiban nincs).
- Állapot: `world/game_state.gd` (futás; `reset()`), `world/progress.gd` (mentett tábor: arany, láda, fejlesztések, küldetések; `deepest` = a valaha elért legmélyebb emelet, az emeletes küldetések ezt is nézik).
- A mélység kinézete: `world/dungeon_theme.gd` (`DungeonTheme`, `RANGES`): 1-20. a régi kő; 21-40. "Káoszkő"
  (`abyss_sheet.png`), 41-80. "Fagykő" (`frost_sheet.png`, jégkék, hulló hó), 81.-től "Vérkő" (`depths_sheet.png`):
  a 0x72 lap bal felső 128x128-as része átszínezve (falak, padló izzó repedésekkel, zászlók, kutak, oszlop). `band()` a
  kinézet indexe (0 régi, 1 Vérkő, 2 Káoszkő, 3 Fagykő), sávonként CanvasModulate (a sávon belül emeletről emeletre sötétebb),
  háttérszín, fáklyaláng és -fény, szálló részecskék (`add_motes`), izzó repedések a padlón (`add_rift`, RoomDecor),
  több csont és vér. A zene a mélység szerint megy (`Dungeon._music_place`), nem a kinézet szerint.
- Ellenségek útkeresése: `Dungeon.nav_path` (AStarGrid2D a padlón, oszlopok szilárdak), `Enemy._chase_direction`.
- Ellenségek: `enemies/enemy_types.gd` (statok, 10. emeleti ugrás; a kikerülés a végén ×0.25, `DODGE_FACTOR`; Káosz kategória: chaos_spawn 16.-tól,
  chaos_hound 26.-tól, és a 25. emelet utáni saját rajzúak: chaos_maw (Káosztorok, lő) 26.-tól, chaos_shard
  (Hasadékszilánk, pajzs + gyógyulás) 27.-től, chaos_weaver (Káoszszövő, káoszivadékot idéz a típus "summon" kulcsával)
  28.-tól; a rajzoló szkript nincs a repóban, a lapok: 8 kocka, 4 álló + 4 futás; Bogarak: fire_ant (1.-től), blue_beetle (3.),
  soldier_ant (6.), hornet (10.), scorpion (13.), CC0 képekből), `enemy.gd`, `boss.gd`, `werewolf_boss.gd`, `chaos_lord_boss.gd`;
  képességek: `enemies/enemy_abilities.gd` (méreg/fagy/fosztogatás a `Player.apply_poison/apply_slow/lose_gold`-on át).
  Főellenségek: az első 3 (3., 6., 9. emelet) változatlan; a 12.-től `Boss.LATER_BOSS_GROWTH` (×1.3 élet) és
  `LATER_BOSS_DAMAGE_STEP` (+6% sebzés) főellenségenként (30. emelet: ~110 000, 39.: ~180 000 élet). A sor (`Boss.BOSSES`)
  a 36. emeleten a Skorpiókirállyal zárul (bogár-főellenség, `scorpion_king.png`), utána elölről (39.: Ogrekirály). Vérfarkas:
  `LORD_HEALTH` ×40 = 128 000 (+ feltámadás), `LORD_DAMAGE` ×2 = 32; Káosz Ura: 1 000 000 élet, 120 sebzés.
  Mellé / kikerülés: a szörny `_on_hurt`-ja `hitbox.missed = true`-t állít, a Hurtbox ilyenkor nem hívja az `on_hit`-et,
  a lövedék továbbrepül (az átütést sem fogyasztja; ugyanazt a célt a `skips` miatt nem találja el újra).
- Tárgyak: `items/items.gd` (DEFINITIONS; a bolti áru emeletenként erősebb: `Items.for_depth`); statok: `components/stats.gd`; szintlépés-kártyák: `components/upgrades.gd`.
  Ritkaságok: common → rare → epic → legendary → mythic (Mítikus, piros: 17 saját tárgy, fegyverfajtánként / helyenként
  egy, a DEFINITIONS végén). Mítikus csak két helyről jön: a nagy főellenség (Vérfarkas, Káosz Ura) fő dobása
  `MYTHIC_LORD_CHANCE` (1%) eséllyel, és a bolt a `MYTHIC_SHOP_DEPTH` (21.) emelettől, áruhelyenként `MYTHIC_SHOP_CHANCE`
  (1.5%) eséllyel, legalább `MYTHIC_SHOP_PRICE` (1000) aranyért; a `random_item` alapból legfeljebb legendásat dob. Minden tárgynak minden ritkaságra van változata (`Items.variant`), de esni / a boltban
  jönni csak a saját ritkaságában tud (`available_rarities`); a többi változat a csalómenü tárgylapján. `Items.random_item(max, min, depth, style)`: mélyebben
  több a ritkább (`rarity_weight`, RARITIES "per_floor"); a boltban (`random_shop_item`) a fegyverek közül a karakter
  harcmódjához illők gyakoribbak (`weapon_style`, `STYLE_MATCH` / `STYLE_MISMATCH`), a szörnyek és ládák dobásában nem. Íjfajták: bow, shortbow (gyors,
  rövid), warbow (lassú, átütő nyíl: `PlayerArrow.pierce`, a Hurtbox `skips`-szel kérdezi), crossbow (`Player.WEAPON_TYPES`).
  Átütés stat (`Stats.pierce`, max `MAX_PIERCE` = 1): csak a legendás "Átütés" szintlépési kártya adja (íjjal, a
  Nyílzápornál 3× ritkább: `Upgrades.LEGENDARY` "weight"), a fegyver saját átütéséhez adódik.
- Zene: `audio/audio.gd` (`Audio.music`): főmenü "menu" (halk ambient), főellenség "boss"; a tábor és a kazamata
  helyszínenként saját listát játszik (`PLACE_TRACKS`: camp, town, cave, dungeon (1-20.), depths (21-40.), abyss (41.-től),
  trial), mindegyikben ott vannak a mindenhol szólók is (`GENERAL_TRACKS`); keverve egymás után, ismétlés nélkül.
  Helyváltáskor a szóló szám marad, ha az új helyen is szólhat. A táborban a helyet `Camp.music_place(pozíció)` adja
  (fél mp-enként), a kazamatában `Dungeon._music_place()`; "epic" = az utoljára kért hely. `PLAYLIST_TRACKS`: 14 CC0
  szám hangereje (dB-igazítás kb. -20 dBFS-re, mérve). Hangerő: Beállítások "Zene" csúszka (Music busz). Új szám: mérd meg a hangosságát.
  Zeneválasztó: a szünet menüben jobb oldalt "♪ Zene" (`ui/music_panel.gd`, `Audio.music_categories / play_song / current_song`): kategóriánként (bárhol szól, helyszínek, egyéb) bármelyik szám lejátszható; a végén a hely listája folytatódik.
  Bal alul (az XP-sáv fölött) kiírja, mi szól (`MUSIC_TITLES`, a főmenüben nem). Áttűnés lejátszónként (`_fade`): a
  régit le kell állítani újrahasználat előtt, különben egy elhalkítás vége az új számot is leállítja.
- HP bájital: `ui/potion_badge.gd` (`PotionBadge`, Q gomb; a kazamatában a HP-csík mellett, a táborban bal fent). Gyorstár nincs.
- UI: minden ablak CanvasLayer `open()/close()`-zal, a `ui/menus.gd` kezeli (KEYS: I, Tab, M, J). Stílus: `UiStyle`, `MenuStyle`.
  Bezáró X: a Menus minden megnyíló ablakra kitesz egy `CloseButton`-t (`ui/close_button.gd`), az ablak jobb felső
  sarkába (a legnagyobb nem teljes képernyős panelhez igazodik; egy ablak `close_anchor()`-ral megadhatja, pl. a
  Szörnyek könyve és a szünet menü).
- Kovács (a tábor jobb alsó sarkában, `world/smithy.gd`): előtte E-re `ui/smith_panel.gd` (SmithPanel). Szabályok:
  `items/smithing.gd` — fejlesztés a következő ritkaságba 4 porért abból a ritkaságból, 65% eséllyel (ha nem sikerül,
  a por elvész; `Smithing.upgraded` a statokat a tartományukban ugyanott tartja), szétszedés: 1 (30%: 2) por a tárgy
  ritkaságából (a rajtad lévő tárgyat nem lehet beolvasztani, csak fejleszteni). Mítikus tárgy: nem lép feljebb, hanem
  `MYTHIC_UPGRADE_COST` (3) mítikus porért legfeljebb 5-ször fejleszthető (`Smithing.improved`): fejlesztésenként az eredeti
  statok 10%-ával nő ("unupgraded" kulcs), a név mögé kerül: "(kétszer fejlesztett)" ("upgrades", "base_name"). Porok: `Progress.dust` (ritkaság -> db,
  mentődik; mindig a `Smithing.dust_of / add_dust`-on át, mert a gyakorló pályán külön porok vannak). Tárgycsere a
  helyén: `Inventory.replace`. A főellenség utáni pihenőnél (BossReturnPanel) is csak a táskából lehet felküldeni.
  Megállítás: `GamePause.set_paused(tree, on)` / `GamePause.active(tree)` (`ui/game_pause.gd`) a `get_tree().paused` helyett —
  egyjátékosban a fa áll meg, közös játékban semmi (szintlépés, halál, Esc-menü alatt sem), csak a karakter nem irányítható és a világ nem fogad E-t.
- Nyugati tisztás: romos ház + tolvaj (`world/ruin.gd`, `world/thief.gd`), kút + Lőrinc (`world/stranger.gd`), a kút alja: `world/well_cave.gd`.
- A tábor jobb felső sarkából rejtett ösvény északra: `world/hidden_grave.gd` (tisztás: Borbás Márton sírja, elhalt fa
  Ilona kitűzött levelével, egyszer nyitható láda: 150 tábori arany, Görbe kés, Ismétlő számszeríj; jelző: hidden_grave_chest).
- A tó titka: `world/lake_crypt.gd` (`LakeCrypt`). Ábel (`Fisherman`): az átlagos tárgy után KEY_QUEST (8 kalóz a küldetés óta,
  `Progress.kills` bázissal), utána CRYPT_QUEST: a tó déli részén, a móló mellett Ábel csónakja (`Lake`, `rowboat.png`;
  a mólón a `BOARD_CELL`-nél E: beszáll, a csónak a `ROUTE` mentén átevez (`Lake._row`, a játékos fizikája közben ki van
  kapcsolva), kiszáll az `ISLAND_LANDING`-re; vissza ugyanígy), a rácsos lépcsőnél E: történet-futás ("story": "crypt", 4 emelet, Fagykő-kinézet,
  a végén aréna a Tófenék Urával: `LakeCrypt.BOSS`); jutalom `trinket_lake_pearl`, Ábelnél +300 arany és 3 történet.
  A történet-futások közös elosztója: `LakeCrypt.story_boss / story_reward / story_*_text` (a Dungeon, a Room és a
  ChallengePanel már nem csak a "knocker"-t ismeri; új történetnél ide kell felvenni).
- A Fagykő lakói (41-80.): frost_wraith, ice_spider, snow_golem, frozen_knight (`"max_depth"` az EnemyTypes-ban: eddig az
  emeletig jön); a 60. emeleten `Boss.FROST_QUEEN` (Jégkirálynő) a sor helyett.
- A Vérkő lakói (81.-től): hell_hound, hell_beast, nightmare, hell_demon (Gothicvania CC0, nagy súllyal: a sor ~45%-a;
  a régi gyenge démonok is jönnek még). Tervben: nagy főellenség a 60. és a 80. emeleten, a 100.-on portál a pokolba, ott a Démonkirály, az utolsó
  főellenség, ami lezárja a történetet. Hangjuk: a típus "voice" kulcsa ("hound" stb.) → Enemy._growl 5–10 mp-enként
  "<voice>_growl", haláskor "<voice>_die" (Audio.VARIANTS).
- A tábor könyvei egy földfolton (`Camp.BOOKS_PATCH`): Szörnyek, Tárgyak (`ItemCodex.MILESTONES`: fülenként 25/50/100%
  jutalom) és Eredmények könyve (`world/achievements.gd` LIST, ablak `ui/achievement_book.gd`; `Achievements.grant`
  a közös jutalomkiosztó). Az átvett jutalmak: `Progress.rewards_claimed`.
- A város keleti rétjén tó (`world/lake.gd`: sziget lezárt, rácsos lépcsővel, móló), a partján az öreg horgász (`world/fisherman.gd`, sétál és horgászik; E: 3 történet, küldetés: a táska leggyengébb tárgya, döntetlennél "hozz kevesebbet" (fisherman_item), utána +3 történet).
- Temető a kocsma alatt: `world/graveyard.gd`; mellette (keletre) a régi kápolna: `world/chapel.gd` (létra a harangtoronyba, kötél: harang, `bell.wav`). A sírásó (Vendel):
  `world/gravedigger.gd` (küldetései: 50 csontváz → Szent kereszt → 20 zombi → legendás talizmán, köztük 2-2 történet; utána
  a kocsmába költözik, játszható "gravedigger" karakter; J könyv: "Csontváz sírásó" fül).
- A kórháztól jobbra a poros raktár: `world/warehouse.gd` (belül ládák, hordók, polcok, por, asztal székekkel; a széken alszik Kormos Gyula, a bányász: közel érve felriad, felveszi a csákányát, 3 történet + "Ki az a robbantómester?": Puskás Döme, a kocsma hátsó szobáiban lakik).
- A kocsmától jobbra a kalandorok kórháza: `world/hospital.gd` (betegágyak, Kálmán doktor, Rozi nővér; a régi lakóház helyén).
- Utak a városban: minden ház ajtajához földút vezet (a `path_tiles()` statikus függvényekből a tábor rajzolja ki);
  az egyajtós házakhoz (kórház, raktár) és a mólóhoz keskeny, 1 csempés ösvény (`Camp.NARROW`: vége, közepe,
  torkolat), a kápolnához a keleti oldala mellett le, a déli ajtajáig. Útjelző táblák (`Camp._branch_sign`):
  "Királyi palota" a vár útján, "Bánya" és "Tó" a leágazásoknál, "Város" a tábor keleti szélén.
- Bánya: `world/mine.gd` — a raktár és a tó között félúton (2 oszlop) földút fel északra, az erdőn át egy tisztásig;
  ott hegy (`assets/props/mountain.png`: három füves sziklaterasz, havas csúcs, ácsolt bányabejárat sínnel). A tisztáson
  a kamera feljebb néz (`Mine.LOOK_UP`), különben a nagyítás miatt nem látszana a csúcs. A bejáratnál E-re be lehet menni
  (belső tér: `Mine.BOUNDS`, x 598-tól): alagút (sín, érces kocsi, támfák fáklyával), barlangterem, keresztben szakadék,
  a deszkahíd közepe leszakadt (a déli csonkra ráállhatsz, E: lenézel; a túlparton tovább megy a járat, egyelőre
  elérhetetlen, Döme robbantásáig). Csempék: `assets/props/mine_tiles.png` (16 px; a föld és a fal az Adventure Awaits csomagból).
  A doktor kérdései és küldetései: `world/doctor.gd` (J könyv "Doktor" fül; 1.: Vérgömb, 2.: A tudós szeme, 3.: Fűrészpenge, utána 3 történet;
  4.: A fekete csőrök (11 pestisdoktor a küldetés óta, `BEAKS_BASE`), utána 2 történet; 5.: Rozi köhögése (Főnixtoll), utána 2 történet).
- Kocsma (`world/town.gd`): a kocsmáros (Tóbiás) E-re beszélget (`BARKEEP_STORIES`: 3 történet + a szobák; a "munka"
  opció nyitja a küldetések ablakát). A hátsó fal jobb sarkában ajtó (`BACK_DOOR`) a szobák folyosójára (`CORRIDOR`,
  y 30-tól): fent 5 ajtó (`ROOMS`: kopogásra szöveg; 2: Puskás Döme, a robbantómester; 4: kiadó).
  A négyes kibérelhető a kocsmárostól (`ROOM_PRICE` 500 tábori arany, egyszer; `ROOM_FLAG`): belül (`MY_ROOM`, y 40-től)
  ágy (alvás → `RESTED_FLAG`, a következő futás elején +1 HP-bájital: `Town.take_rest_bonus`, a Camp `_enter_dungeon_now`-ja),
  láda (a tábori láda ablaka), trófeafal (`Town.trophies()`: 14 főellenség, a le nem győzöttek sötét árnyékként).
- Próbatétel (random kazamata): `world/challenge.gd` (`Challenge`). A bánya túlpartján a régi tárna (`Mine.DEEP_DOOR`,
  csak a híd után) → lyukas terem (`Mine.DEEP_ROOM`, x 640-től), a lépcsőnél E: `ui/challenge_panel.gd` (ajánlat / eredmény).
  1-20 emelet, 1-3 könnyítés (`BOONS`, 15) és 1-3 nehezítés (`BANES`, 15), ütköző hatás nem jön együtt, a súlyok
  különbsége ≤ `MAX_IMBALANCE`; a nehézség (score → `DIFFICULTIES`, 6 fokozat) adja a jutalmat és a mítikus esélyt. Valós
  időben 10 percenként (és győzelem után) újrasorsolódik (`Progress.npc_quests` challenge_seed / challenge_until);
  csalómenü: "Új random kazamata". Futás közben `GameState.challenge`; a hatások `Challenge.mult/add/flag`-gel
  vannak bekötve (EnemyTypes.roll, Boss, dungeon szobák, Player arany/regen, bolt, bájital, ejtés). Szabályok: nincs
  tárgylift és pihenő-portál, a levitt és lent szerzett tárgyak lent maradnak, arany csak győzelemkor (100%), az
  eredménytáblába és az emelet-küldetésekbe nem számít; győzelem = az utolsó emelet lépcsője (`Dungeon._challenge_won`).
- A kopogás titka: `world/knocking.gd` (`Knocking`, J könyv "Bányász" fül; Döme hídja után Kormos Gyulától).
  1. A lyuk hangja: a lyukas teremben a lyuk keleti szélén fülelni (`Mine.DEEP_LISTEN`), a brigád jele szól.
  2. Pókselyem kötél: 12 kazamatapók a küldetés óta. 3. A Kopogó: a lyuk nyugati szélén a kötél (`Mine.DEEP_ROPE`),
  a régi tárnák = 5 emeletes próbatétel (`GameState.challenge` "story": "knocker", `Challenge.story()`), az utolsó
  emelet aréna (`room.lord` "knocker"), a főellenség `Knocking.BOSS` (`Boss.setup_boss(depth, special)`, kép:
  `assets/enemies/knocker.png`). Jutalom: A huszonhét lámpása (`trinket_miners_lamp`, egyedi). Utána Gyula a bányában
  áll (`Knocking.moved()`), a raktárból eltűnik. A történet a 100. emeletig fog tartani (a 40. után nincs ünnepség).
- Főmenü "Újdonságok" (jobb oldalt): `ui/news.gd` (`News.ENTRIES`, a legújabb felül). Minden változtatásnál írj
  bele egy rövid, játékosnak szóló sort a mai dátum alá.
- Puskás Döme, a robbantómester: `world/blaster.gd` (J könyv "Robbantómester" fül). Első kopogásra kijön, a kettes ajtó
  előtt áll; küldetései: Goblinpor (8 robbanó goblin), Lassú kanóc (5 kalózpuskás), Híd a szakadék fölött (a bányába megy,
  ott E: robbantás, `Mine._blast`: a szikla beékelődik, deszka rá; `Blaster.bridge_fixed()` után a túlpart járható).
  A híd és Lőrinc megmentése után a bányában: `WELL_QUEST` (6 tűzhangya a küldetés óta) → "ready": Döme a kút alján vár
  (`Blaster.at_well()`, `away()` = nincs a folyosón), ott "Robbants!" → `WellCave._blast` → "done" (`well_open()`):
  `WellCave.TUNNEL` + `WORKSHOP` (Lőrinc régi műhelye: jegyzetek, láda `CHEST_FLAG`: `trinket_lorinc_compass` + 250 arany,
  lezárt rácsos lépcső `GRATE_TILE` — a későbbi folytatásnak), `OPEN_BOUNDS`; Lőrincnél `Stranger.WELL_STORIES`.
- Város északi része: `world/castle.gd` ( út, királyi vár, őrök, trónterem; király: `world/king.gd`; a
  "Király" fül a J könyvben az első látogatás után; engedély: `deep_30` jelző, a 30. emelet után a táborban "done").
  A hét király jelentése után: "Mi lesz most, felség?" → új küldetés, a Káosz kapuja (`King.CHAOS_QUEST`: győzd le
  a Káosz Urát a 40. emeleten, a Szörnyek könyve szerint; 3000 tábori arany), és 4 új történet (`King.STORIES`).
- Szörnyek könyve: állvány a táborban (`BESTIARY_TILE`), adatok: `world/bestiary.gd`, ablak: `ui/bestiary_book.gd`;
  a megölt szörnyek száma `Progress.kills` (a `room.gd` írja, főellenség a saját nevével).
- Tárgyak könyve: második állvány mellette (`Camp.ITEM_BOOK_TILE`), adatok: `world/item_codex.gd` (`ItemCodex.TABS`:
  közelharci / távolsági fegyver + helyenként), ablak: `ui/item_book.gd` (ikonrács, a meg nem szerzett sötét árnyék;
  jobb lap: statok a saját ritkaságban + leírás). Felfedezett: `Progress.seen_items` (az `Inventory.changed` jegyzi be a
  táskát és a felszerelést; megnyitáskor a tábori láda és a mentett felszerelések is: `note_stored`).
- Általános küldetések (a kocsmárostól, `world/quests.gd`): 100 db nehézséggel (`Quests.TIERS`: easy / medium / hard).
  A J könyv általános fülén szűrők (állapot, nehézség); ha van leadható, azzal a szűréssel nyílik.
- NPC-beszélgetés: `ui/dialogue_panel.gd` (bizalom -100..+100, oldalanként 5 opció, lapozható ← →, 1-5 gomb), szövegek: `world/dialogues.gd`;
  bizalom és feltett kérdések: `Progress.trust` / `Progress.asked` (mentve).
- Karakterek: `world/characters.gd` (lovag, íjász, Bence/"thief" a levél-küldetés után, Gáspár/"veteran" — utóbbi az "unlock" jelzővel, a 30. emelet
  után; Ctrl: íjász suhanás, Gáspár hadi kiáltás, Bence árnyéklépés a `player.gd`-ben; Lőrinc/"wizard" varázsló a küldetései után ("lorinc_tavern"): `player/spells.gd`; Vendel/"gravedigger" (ásó magától üt; bal klikk: csontváz-idézés, `player/skeleton_minion.gd`; 5 szintenként a stat-kártyák helyett
  idézés-fejlesztés: `player/necromancy.gd` (4 véletlen kártya) — +1 csontváz (max 12, MINDEN fajta együtt számít), +2 mp élet (max 60),
  +1 sebzés, csontváz-erősítés, gyors idézés, jobb klikkre a másodlagos idézés: 3 íjász VAGY óriás csontváz (kizárják egymást); idézéskor szabad helyre kelnek (`_free_spawn_spot`); a csontvázak statjai és a töltési idők a
  szinttel / Vendel statjaival NEM nőnek; a szörnyek (a főellenség nem) a közelebbi csontvázra is rátámadnak, a csontváz `hits`
  találatot bír ki (saját Hurtbox); `GameState.necromancy`; Tab-ban "Idézés" oldal), választó: `ui/spell_picker.gd`). Kocsmai székek: `world/town.gd`.
- Csalómenü: [0], kód nélkül (`ui/cheat_menu.gd`): teleport a 10. / 20. vagy a beírt emeletre (1–99; `cheat_teleport` a Dungeon/Camp jeleneten),
  halhatatlanság (`GameState.god_mode`), karakterváltás a táborban (zároltakra is; `cheat_select_character` a Camp-en →
  `Town.cheat_switch_to`), tárgylap (bármelyik tárgy bármelyik ritkaságban a táskába). Teszteléshez is hasznos.
- Lift: a táborban a lépcső mellett (`world/camp_lift.gd`, "Lefelé utazás"); a 10. emeleten kék liftszoba (`world/lift_room.gd`,
  `Room.has_lift_room`) Bertalan mérnökkel (`world/engineer.gd`): 500 kazamatai aranyért megjavítja (J könyv "Mérnök" fül), felmegy a lifttel, és a táborban a lift mellett áll (2 új történet); a lift a 10. emeletre is visz.
  Mindkét helyen ugyanaz a lift: `LiftRoom.LiftRig` (pixelrácsra rajzolt bakállvány, láncon lógó ketrec, a gerenda végén
  forgó fogaskerék: `assets/props/lift_gear.png`, 8 kocka); lent a szoba közepén, a táborban a kőpadló mellett egy akna fölött (`CampLift.Shaft`).
- Pihenő a főellenség után (`ui/boss_return_panel.gd`): a kék portál a táborból ugyanoda hoz vissza — `GameState.break_floor`
  (`Dungeon.break_snapshot`: mag (`_floor_seed`, egyjátékosban is rögzítve), kitisztított/bejárt szobák, zárt ládák, hely),
  visszatéréskor `Room.restore_cleared`; a RunSave is menti. Új portál nem nyílik újra (egy pihenő főellenségenként).
- Bejátszás az első visszatéréskor a kazamatából: `world/stretcher_scene.gd` (hordágyas katonák, `GameState.visited_dungeon`).
- Többjátékos: `network/` — `net_session.gd` (beállítások, fix név: user://player.cfg, kód), `net_lobby.gd` (/root/NetLobby:
  váró, LAN-bejelentés UDP-n (kód + a gazda neve); a csatlakozó listázza a várókat (`browse` → `games`, `join_game`),
  kódot nem kell beírni; ENet, RPC-k, indítás → mindenki a táborba), `net_avatars.gd` (a többiek a táborban
  és a kazamata ugyanazon emeletén; menü alatt is küld). Közös kazamata: a gazda magot sorsol (`GameState.net_seed`), a
  táborban lévők együtt mennek le (`request_descent`), a lépcső mindenkit visz (`request_floor`). Szörnyek:
  `network/net_enemies.gd` — a gazdánál élnek (a legközelebbi játékost üldözik, menü alatt is mennek), a vendégeknél
  bábok (`net_puppet` az enemy.gd-ben, `Room.add_puppet`); a vendég ütését a gazda vonja le; ha a gazda nincs az
  emeleten, a vendég önálló lesz (local_mode). Szintén a NetEnemies-ben (net_event): a felvehetőket a gazda dobja
  (XP-t a felvételkor mindenki megkapja), közös arany (`Player.add_gold`), ládák (a helyükkel azonosítva), a szörnyek
  lövései; halál után néző mód (`Player.become_spectator`, `GameState.net_dead`), amíg valaki él; a lépcsőn mindenki
  bevárja a többieket (`start_waiting`, a pózban "r"; mozgásgombra lelép: `stop_waiting` — a rálépéskor nyomva tartott gomb nem számít,
  csak egy új lenyomás; aki lelépett, de a lépcsőn megállt, újra vár: `Player.wants_to_wait_again`, Stairs). A terem és a tereptárgyak a közös magból, a bolt áruja saját.
  Szinkron részletei: a póz (20 Hz, 1-es csatorna) és a szörny-pillanatkép (20 Hz, tömör PackedFloat32Array, 2-es csatorna)
  sebességet is visz, a fogadó `network/net_smooth.gd`-vel előre számol; az ENet-fojtás ki van kapcsolva (`_no_throttle`).
  Felvehető: a vendég a gazdától kéri ("claim"), a gazda dönti el, ki kapja ("taken") — kettős felvétel nincs. A közös arany
  összegét a gazda vezeti (NetLobby "közös arany", sorszámozott változások). A más emeletre szóló üzeneteket a NetLobby
  megőrzi (`_pending`), amíg az emelet be nem töltődik. A támadások látszata (fegyver, lövedék) a társaknál is lejátszódik
  (`Player.share_effect` → `NetAvatars._on_effect`; ott nem sebez). A lövedék mása nem a szörnyekbe csapódva tűnik el,
  hanem ahol a lövőnél eltűnt (`PlayerArrow.net_id`, "shot_end"; falat és távot magától tudja). Közös játékban a szobák ajtajai nem záródnak be
  (`Room._set_doors_locked`). Élesztés: az elesett társ a halála helyén fekszik (pózban "g" = `Player.net_death_at`);
  mellette 3 mp-ig nyomva tartott E → `NetLobby.send_revive` → az ő gépén `Player.revive_from_net` (fél HP).
  Tárgyátadás: a táska ablakban a táska tárgyát egy társ nevére húzva (`ui/give_slot.gd`, `InventoryScreen._give_from_bag`)
  → `NetLobby.send_item` → nála `NetAvatars._on_item_received` a táskába; ha tele, visszajön (`item_returned`; ha a
  küldőnél sincs hely / épp jelenetet vált, a tábori ládába). A küldő azonnal kiveszi, így nem kettőződik.
  Közös játékban a szintlépés nem nyílik fel magától: alul gomb / L (`ui/level_up.gd`, `GameState.pending_level_ups`);
  a szörnyek kijöhetnek a szobájukból (a főellenség nem); a láda üres-e: a közös magból és a helyéből (mindenkinél ugyanaz).
  Emeletváltáskor (`Dungeon.go_to_floor`) a nyitott ablak bezárul és a szünet feloldódik (menü alatt is jöhet a lépcső).
  Akadás ellen: a szoba szörnyei képkockánként 3-asával kerülnek pályára (`Room._spawn_queue`, a vendég bábjai is), az
  útkereső háló betöltés után épül (`_prebuild_nav`), elfogyott útnál 0,15 mp-enként tervez újra (`Enemy.PATH_RETRY`),
  a pillanatkép 32 szörnyenként külön csomag (`SNAPSHOT_MAX_ENEMIES`, a darabolt csomag wifin könnyen elveszik).
  Teszt: két példány (_host.gd / _client.gd, közös _mp_common.gd). Közös játék alatt `Profiles.multiplayer`: külön mentés profilonként (user://save_mp_<profil>.cfg),
  a gazda a váróban "új kezdés"-t is választhat.
  Menü: `ui/multiplayer_panel.gd`. Teszt: két példány (_host.gd / _client.gd) egyszerre fut.
- Gyakorló pálya (GameState.tutorial): 7 szoba egy sorban (`Dungeon.TUTORIAL_CELLS` / `TUTORIAL_ROOMS`: kezdő, harc + láda,
  csapdák + képesség, bolt + tárgylift, gyakorló üllő (`world/tutorial_anvil.gd`, SmithPanel gyakorló porokkal:
  `GameState.tutorial_dust`, a fejlesztés mindig sikerül), különleges szörnyek, főellenség (gyenge:
  `Room.TUTORIAL_BOSS_HEALTH`)). A vezető: `ui/tutorial_guide.gd` — feladat- és Enteres magyarázó lépések, a következő
  szoba ajtaja zárva, amíg a lecke nincs kész (`Room.set_gate`), sárga nyíl a célra, villogó keret a HUD-on, H = átugrás,
  a játékos nem halhat meg (`Health.cannot_die`). A pálya lépcsője a valódi TÁBORBA visz (GameState.tutorial marad):
  ott a vezető (`setup_camp`, a tábor hozza létre) végigvisz a tábor dolgain (arany, kiképzősátor + vásárlás, láda +
  kivétel, halál és biztonság, kovács, Szörnyek könyve, küldetések, vándorárus, lakók, út a városba, lépcső), a végén
  rövid "kész" ablak (`TutorialManual.FINISH_TEXT`). Nyitott ablak idején a fenti pergamen alatta van: a képernyő
  alján, az ablakok fölött egy sáv mutatja a teendőt röviden (lépésenként "short", ha a lépés saját ablaka ("window")
  van nyitva; különben "csukd be ezt az ablakot"). Homokozó: a gyakorlás tiszta lappal indul (`Progress.begin_tutorial`:
  mint egy új játék, csak a memóriában; a mentés arany/fejlesztés/tárgy/küldetés stb. nem látszik), közben
  `Progress.save_game` nem ír, és a főmenübe lépve (`Progress.discard_tutorial_changes`) visszatöltődik a mentés. Szövegek:
  `ui/tutorial_manual.gd` (CHAPTERS a főmenüben, az irányítás a Beállítások fülön is). A karakterek történetét nem
  árulja el. Teszt: robot, ami minden karakterrel végigjátssza a pályát és a tábort (lépésenként elvégzi a feladatot).
- Automatikus frissítés: `ui/updater.gd` (a főmenü teszi be, indításonként egyszer; headless és exportált játékban nem fut).
  GitHub compare API a helyi main-fej és az origin main között; ha a helyi mögötte van: felül az újdonságok, 6 mp múlva
  magától frissít (git-es mappában `git pull --ff-only`, de commitolatlan változásnál csak gombra; git nélküli mappában
  a main ZIP-je, `.update_version` / `.update_manifest`), utána `--headless --import`, és újraindul. Ha a helyi előrébb
  jár (fel nem töltött commit) vagy más ágon van, nem nyúl semmihez. A főmenü jobb alsó sarkában a commit rövid azonosítója.
