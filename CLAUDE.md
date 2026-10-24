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
- `world/dungeon.gd` emelet-generálás (boss minden 3. emeleten, 20. emelet: Vérfarkas + győzelem), `world/camp.gd` tábor
  (város keletre: `world/town.gd`, 68 csempe széles, a keleti fele (OLD_END_X-től) üres rét, kovács: `world/smithy.gd`, veterán + sáros ösvény nyugatra, a végén a romos ház:
  `world/ruin.gd`, benne a tolvaj rejtekszobája: `world/thief.gd`), `world/shop_interior.gd` bolt.
- Állapot: `world/game_state.gd` (futás; `reset()`), `world/progress.gd` (mentett tábor: arany, láda, fejlesztések, küldetések).
- Ellenségek útkeresése: `Dungeon.nav_path` (AStarGrid2D a padlón, oszlopok szilárdak), `Enemy._chase_direction`.
- Ellenségek: `enemies/enemy_types.gd` (statok, 10. emeleti ugrás; a kikerülés a végén ×0.25, `DODGE_FACTOR`), `enemy.gd`, `boss.gd`, `werewolf_boss.gd`;
  képességek: `enemies/enemy_abilities.gd` (méreg/fagy/fosztogatás a `Player.apply_poison/apply_slow/lose_gold`-on át).
- Tárgyak: `items/items.gd` (DEFINITIONS; a bolti áru emeletenként erősebb: `Items.for_depth`); statok: `components/stats.gd`; szintlépés-kártyák: `components/upgrades.gd`.
- UI: minden ablak CanvasLayer `open()/close()`-zal, a `ui/menus.gd` kezeli (KEYS: I, Tab, M, J). Stílus: `UiStyle`, `MenuStyle`.
- Nyugati tisztás: romos ház + tolvaj (`world/ruin.gd`, `world/thief.gd`), kút + Lőrinc (`world/stranger.gd`), a kút alja: `world/well_cave.gd`.
- A város keleti rétjén tó (`world/lake.gd`: sziget, móló), a partján az öreg horgász (`world/fisherman.gd`, sétál és horgászik; E: 3 történet, küldetése még nincs).
- Temető a kocsma alatt: `world/graveyard.gd`; mellette (keletre) a régi kápolna: `world/chapel.gd` (létra a harangtoronyba, kötél: harang, `bell.wav`). A sírásó (Vendel):
  `world/gravedigger.gd` (küldetései: 50 csontváz → Szent kereszt → 20 zombi → legendás talizmán, köztük 2-2 történet; utána
  a kocsmába költözik, játszható "gravedigger" karakter; J könyv: "Csontváz sírásó" fül).
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
  után; Ctrl: íjász suhanás, Gáspár hadi kiáltás, Bence árnyéklépés a `player.gd`-ben; Lőrinc/"wizard" varázsló a küldetései után ("lorinc_tavern"): `player/spells.gd`; Vendel/"gravedigger" (ásó, Ctrl: csontváz-idézés, `player/skeleton_minion.gd`), választó: `ui/spell_picker.gd`). Kocsmai székek: `world/town.gd`.
- Csalómenü: [0], kód nélkül (`ui/cheat_menu.gd`): teleport a 20. emeletre (`cheat_teleport` a Dungeon/Camp jeleneten),
  halhatatlanság (`GameState.god_mode`), karakterváltás a táborban (zároltakra is; `cheat_select_character` a Camp-en →
  `Town.cheat_switch_to`), tárgylap (bármelyik tárgy bármelyik ritkaságban a táskába). Teszteléshez is hasznos.
- Lift: a táborban a lépcső mellett (`world/camp_lift.gd`, "Lefelé utazás"); a 10. emeleten kék liftszoba (`world/lift_room.gd`,
  `Room.has_lift_room`) Bertalan mérnökkel (`world/engineer.gd`): 500 kazamatai aranyért megjavítja (J könyv "Mérnök" fül), felmegy a lifttel, és a táborban a lift mellett áll (2 új történet); a lift a 10. emeletre is visz.
- Bejátszás az első visszatéréskor a kazamatából: `world/stretcher_scene.gd` (hordágyas katonák, `GameState.visited_dungeon`).
- Többjátékos: `network/` — `net_session.gd` (beállítások, fix név: user://player.cfg, kód), `net_lobby.gd` (/root/NetLobby:
  váró, LAN-bejelentés a kóddal UDP-n, ENet, RPC-k, indítás → mindenki a táborba), `net_avatars.gd` (a többiek a táborban
  és a kazamata ugyanazon emeletén; menü alatt is küld). Közös kazamata: a gazda magot sorsol (`GameState.net_seed`), a
  táborban lévők együtt mennek le (`request_descent`), a lépcső mindenkit visz (`request_floor`). Szörnyek:
  `network/net_enemies.gd` — a gazdánál élnek (a legközelebbi játékost üldözik, menü alatt is mennek), a vendégeknél
  bábok (`net_puppet` az enemy.gd-ben, `Room.add_puppet`); a vendég ütését a gazda vonja le; ha a gazda nincs az
  emeleten, a vendég önálló lesz (local_mode). Szintén a NetEnemies-ben (net_event): a felvehetőket a gazda dobja
  (XP-t a felvételkor mindenki megkapja), közös arany (`Player.add_gold`), ládák (a helyükkel azonosítva), a szörnyek
  lövései; halál után néző mód (`Player.become_spectator`, `GameState.net_dead`), amíg valaki él; a lépcsőn mindenki
  bevárja a többieket (`start_waiting`, a pózban "r"). A terem és a tereptárgyak a közös magból, a bolt áruja saját.
  Szinkron részletei: a póz (20 Hz, 1-es csatorna) és a szörny-pillanatkép (20 Hz, tömör PackedFloat32Array, 2-es csatorna)
  sebességet is visz, a fogadó `network/net_smooth.gd`-vel előre számol; az ENet-fojtás ki van kapcsolva (`_no_throttle`).
  Felvehető: a vendég a gazdától kéri ("claim"), a gazda dönti el, ki kapja ("taken") — kettős felvétel nincs. A közös arany
  összegét a gazda vezeti (NetLobby "közös arany", sorszámozott változások). A más emeletre szóló üzeneteket a NetLobby
  megőrzi (`_pending`), amíg az emelet be nem töltődik. A támadások látszata (fegyver, lövedék) a társaknál is lejátszódik
  (`Player.share_effect` → `NetAvatars._on_effect`; ott nem sebez). Közös játékban a szobák ajtajai nem záródnak be
  (`Room._set_doors_locked`). Élesztés: az elesett társ a halála helyén fekszik (pózban "g" = `Player.net_death_at`);
  mellette 3 mp-ig nyomva tartott E → `NetLobby.send_revive` → az ő gépén `Player.revive_from_net` (fél HP).
  Közös játékban a szintlépés nem nyílik fel magától: alul gomb / L (`ui/level_up.gd`, `GameState.pending_level_ups`);
  a szörnyek kijöhetnek a szobájukból (a főellenség nem); a láda üres-e: a közös magból és a helyéből (mindenkinél ugyanaz).
  Emeletváltáskor (`Dungeon.go_to_floor`) a nyitott ablak bezárul és a szünet feloldódik (menü alatt is jöhet a lépcső).
  Akadás ellen: a szoba szörnyei képkockánként 3-asával kerülnek pályára (`Room._spawn_queue`, a vendég bábjai is), az
  útkereső háló betöltés után épül (`_prebuild_nav`), elfogyott útnál 0,15 mp-enként tervez újra (`Enemy.PATH_RETRY`),
  a pillanatkép 32 szörnyenként külön csomag (`SNAPSHOT_MAX_ENEMIES`, a darabolt csomag wifin könnyen elveszik).
  Teszt: két példány (_host.gd / _client.gd, közös _mp_common.gd). Közös játék alatt `Profiles.multiplayer`: külön mentés profilonként (user://save_mp_<profil>.cfg),
  a gazda a váróban "új kezdés"-t is választhat.
  Menü: `ui/multiplayer_panel.gd`. Teszt: két példány (_host.gd / _client.gd) egyszerre fut.
- Gyakorló pálya: `ui/tutorial_guide.gd` (lépések), kézikönyv: `ui/tutorial_manual.gd` (az irányítás szövege a Beállítások fülön is).
