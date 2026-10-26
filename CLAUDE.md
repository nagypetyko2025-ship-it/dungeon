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
- Ellenségek útkeresése: `Dungeon.nav_path` (AStarGrid2D a padlón, oszlopok szilárdak), `Enemy._chase_direction`.
- Ellenségek: `enemies/enemy_types.gd` (statok, 10. emeleti ugrás; a kikerülés a végén ×0.25, `DODGE_FACTOR`; Káosz kategória: chaos_spawn 16.-tól,
  chaos_hound 26.-tól), `enemy.gd`, `boss.gd`, `werewolf_boss.gd`, `chaos_lord_boss.gd`;
  képességek: `enemies/enemy_abilities.gd` (méreg/fagy/fosztogatás a `Player.apply_poison/apply_slow/lose_gold`-on át).
  Főellenségek: az első 3 (3., 6., 9. emelet) változatlan; a 12.-től `Boss.LATER_BOSS_GROWTH` (×1.3 élet) és
  `LATER_BOSS_DAMAGE_STEP` (+6% sebzés) főellenségenként (30. emelet: ~110 000, 39.: ~180 000 élet). Vérfarkas:
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
- HP bájital: `ui/potion_badge.gd` (`PotionBadge`, Q gomb; a kazamatában a HP-csík mellett, a táborban bal fent). Gyorstár nincs.
- UI: minden ablak CanvasLayer `open()/close()`-zal, a `ui/menus.gd` kezeli (KEYS: I, Tab, M, J). Stílus: `UiStyle`, `MenuStyle`.
  Bezáró X: a Menus minden megnyíló ablakra kitesz egy `CloseButton`-t (`ui/close_button.gd`), az ablak jobb felső
  sarkába (a legnagyobb nem teljes képernyős panelhez igazodik; egy ablak `close_anchor()`-ral megadhatja, pl. a
  Szörnyek könyve és a szünet menü).
- Kovács (a tábor jobb alsó sarkában, `world/smithy.gd`): előtte E-re `ui/smith_panel.gd` (SmithPanel). Szabályok:
  `items/smithing.gd` — fejlesztés a következő ritkaságba 4 porért abból a ritkaságból, 65% eséllyel (ha nem sikerül,
  a por elvész; `Smithing.upgraded` a statokat a tartományukban ugyanott tartja), szétszedés: 1 (30%: 2) por a tárgy
  ritkaságából (a rajtad lévő tárgyat nem lehet beolvasztani, csak fejleszteni). Porok: `Progress.dust` (ritkaság -> db,
  mentődik; mindig a `Smithing.dust_of / add_dust`-on át, mert a gyakorló pályán külön porok vannak). Tárgycsere a
  helyén: `Inventory.replace`. A főellenség utáni pihenőnél (BossReturnPanel) is csak a táskából lehet felküldeni.
  Megállítás: `GamePause.set_paused(tree, on)` / `GamePause.active(tree)` (`ui/game_pause.gd`) a `get_tree().paused` helyett —
  egyjátékosban a fa áll meg, közös játékban semmi (szintlépés, halál, Esc-menü alatt sem), csak a karakter nem irányítható és a világ nem fogad E-t.
- Nyugati tisztás: romos ház + tolvaj (`world/ruin.gd`, `world/thief.gd`), kút + Lőrinc (`world/stranger.gd`), a kút alja: `world/well_cave.gd`.
- A tábor jobb felső sarkából rejtett ösvény északra: `world/hidden_grave.gd` (tisztás: Borbás Márton sírja, elhalt fa
  Ilona kitűzött levelével, egyszer nyitható láda: 150 tábori arany, Görbe kés, Ismétlő számszeríj; jelző: hidden_grave_chest).
- A város keleti rétjén tó (`world/lake.gd`: sziget lezárt, rácsos lépcsővel, móló), a partján az öreg horgász (`world/fisherman.gd`, sétál és horgászik; E: 3 történet, küldetés: a táska leggyengébb tárgya, döntetlennél "hozz kevesebbet" (fisherman_item), utána +3 történet).
- Temető a kocsma alatt: `world/graveyard.gd`; mellette (keletre) a régi kápolna: `world/chapel.gd` (létra a harangtoronyba, kötél: harang, `bell.wav`). A sírásó (Vendel):
  `world/gravedigger.gd` (küldetései: 50 csontváz → Szent kereszt → 20 zombi → legendás talizmán, köztük 2-2 történet; utána
  a kocsmába költözik, játszható "gravedigger" karakter; J könyv: "Csontváz sírásó" fül).
- A kórháztól jobbra a poros raktár: `world/warehouse.gd` (belül ládák, hordók, polcok, por, asztal székekkel; a széken alszik Kormos Gyula, a bányász: közel érve felriad, felveszi a csákányát, 3 történet).
- A kocsmától jobbra a kalandorok kórháza: `world/hospital.gd` (betegágyak, Kálmán doktor, Rozi nővér; a régi lakóház helyén).
  A doktor kérdései és küldetései: `world/doctor.gd` (J könyv "Doktor" fül; 1.: Vérgömb, 2.: A tudós szeme, 3.: Fűrészpenge, utána 3 történet).
- Város északi része: `world/castle.gd` ( út, királyi vár, őrök, trónterem; király: `world/king.gd`; a
  "Király" fül a J könyvben az első látogatás után; engedély: `deep_30` jelző, a 30. emelet után a táborban "done").
- Szörnyek könyve: állvány a táborban (`BESTIARY_TILE`), adatok: `world/bestiary.gd`, ablak: `ui/bestiary_book.gd`;
  a megölt szörnyek száma `Progress.kills` (a `room.gd` írja, főellenség a saját nevével).
- Általános küldetések nehézséggel (`Quests.TIERS`: easy / medium).
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
  a játékos nem halhat meg (`Health.cannot_die`); a végén lapozható összefoglaló. Szövegek: `ui/tutorial_manual.gd`
  (CHAPTERS a főmenüben, FINISH_PAGES a pálya végén, az irányítás a Beállítások fülön is). A karakterek történetét nem
  árulja el. Teszt: robot, ami minden karakterrel végigjátssza (lépésenként elvégzi a feladatot).
- Automatikus frissítés: `ui/updater.gd` (a főmenü teszi be, indításonként egyszer; headless és exportált játékban nem fut).
  GitHub compare API a helyi main-fej és az origin main között; ha a helyi mögötte van: felül az újdonságok, 6 mp múlva
  magától frissít (git-es mappában `git pull --ff-only`, de commitolatlan változásnál csak gombra; git nélküli mappában
  a main ZIP-je, `.update_version` / `.update_manifest`), utána `--headless --import`, és újraindul. Ha a helyi előrébb
  jár (fel nem töltött commit) vagy más ágon van, nem nyúl semmihez. A főmenü jobb alsó sarkában a commit rövid azonosítója.
