class_name Audio
extends Node
## Hangok és zene. Egyetlen példány él a SceneTree gyökerén (jelenetváltáskor
## sem tűnik el, így a zene sem szakad meg). Használat:
##   Audio.play("hit")            # effekt (több változatból véletlenül választ)
##   Audio.music("town")          # zene, áttűnéssel: egy helyszín lejátszási listája (PLACE_TRACKS), vagy egy
##                                # szám (MUSIC_TRACKS: "menu", "boss"); "epic": az utoljára kért helyszín listája
## A hangerők és a teljes képernyő a user://settings.cfg-be mentődnek.

const SFX_DIR := "res://assets/audio/sfx/"
## Effekt -> hány változata van (név_1 ... név_N); 0 = egyetlen fájl, szám nélkül.
const VARIANTS := {
	"swing": 2, "thrust": 3, "hit": 3, "crit": 2, "hurt": 2, "enemy_die": 3, "dodge": 2,
	"coin": 2, "xp": 2, "footstep": 3,
	"chest_open": 0, "chest_latch": 0, "door_lock": 0, "door_unlock": 0, "trap": 0,
	"arrow": 0, "magic": 0, "item_pickup": 0, "equip": 0, "buy": 0, "sell": 0, "stairs": 0,
	"ui_click": 0, "ui_hover": 0, "ui_open": 0, "ui_close": 0, "ui_error": 0,
	"boss_slam": 0, "boss_roar": 0, "level_up": 0, "boss_defeated": 0, "death": 0,
	"anvil": 3, "bell": 0,
	# A Vérkő démonjai (EnemyTypes "voice")
	"hound_growl": 2, "hound_die": 0, "beast_growl": 2, "beast_die": 0,
	"horse_growl": 2, "horse_die": 0, "lord_growl": 2, "lord_die": 0,
	# Az Ősgépezet (a 60. emelet nagy főellensége)
	"engine_steam": 2, "engine_stomp": 2, "engine_zap": 2, "engine_gears": 0, "engine_magnet": 0,
	"engine_wake": 0, "engine_die": 0, "engine_beep": 0,
	# A Pokolkapu Őre (a 80. emelet nagy főellensége)
	"gate_bark": 2, "gate_chain": 2, "gate_spit": 2, "gate_howl": 0, "gate_die": 0,
	"gate_fire": 0, "gate_lava": 0, "gate_shadow": 0,
	# Azazel, a Halálangyal és Démonkirály (a pokolban, a 100. emelet kapuja mögött)
	"lucifer_laugh": 0, "lucifer_roar": 2, "lucifer_die": 0, "lucifer_cast": 0, "lucifer_meteor": 2,
	"lucifer_souls": 0, "lucifer_abyss": 0, "lucifer_portal": 0,
}
## Néhány effekt alap-hangereje (dB); a többi 0.
const VOLUMES := {
	"footstep": -16.0, "xp": -10.0, "coin": -6.0, "ui_hover": -14.0, "swing": -4.0,
	"thrust": -4.0, "dodge": -6.0, "magic": -6.0, "anvil": -8.0,
}
const MUSIC_TRACKS := {
	"menu": "res://assets/audio/music/menu_ambience.ogg",
	"dungeon": "res://assets/audio/music/dungeon_ambience.ogg",
	"boss": "res://assets/audio/music/boss_battle.wav",
	# Csak az Ősgépezet elleni harcban szól (a zeneválasztóban sincs ott, lásd ONLY_IN_FIGHT).
	"engine": "res://assets/audio/music/epic_boss_battle.wav",
	# Csak a Pokolkapu Őre elleni harcban szól.
	"gate": "res://assets/audio/music/heavy_boss_battle.ogg",
	# Csak a Azazel elleni harcban szól.
	"lucifer": "res://assets/audio/music/demon_king_battle.mp3",
	# A befejező kisfilmek zenéi (Azazel után, karakterenként, lásd ui/ending_story.gd).
	"end_knight": "res://assets/audio/music/end_knight.mp3",
	"end_archer": "res://assets/audio/music/end_archer.mp3",
	"end_veteran": "res://assets/audio/music/end_veteran.ogg",
	"end_wizard": "res://assets/audio/music/end_wizard.mp3",
	"end_gravedigger": "res://assets/audio/music/end_gravedigger.ogg",
	"end_thief": "res://assets/audio/music/end_thief.ogg",
}
## A zeneválasztóban külön kategória: "Befejezések".
const ENDING_TRACKS := ["end_knight", "end_archer", "end_veteran", "end_wizard", "end_gravedigger", "end_thief"]
## A tábor és a kazamata zenéje helyszínenként: a hely saját számai (PLACE_TRACKS) és a mindenhol szólók
## (GENERAL_TRACKS) egymás után (ha az egyik véget ér, jön a következő; a sorrend keverve, ugyanaz nem jön kétszer
## egymás után). Helyváltáskor a szóló szám marad, ha az új helyen is szólhat; különben áttűnik az új hely zenéjére.
## Mind CC0, lásd assets/audio/LICENSE.txt. "epic": az utoljára kért helyszín (pl. a feléledés után).
## Ezek a számok csak a saját harcukban szólnak (nincsenek a zeneválasztóban).
const ONLY_IN_FIGHT := ["engine", "gate", "lucifer"]
const PLAYLIST := "epic"
const GENERAL_TRACKS: Array[String] = [
	"res://assets/audio/music/jrpg_theme.ogg", "res://assets/audio/music/rising_moon.mp3", "res://assets/audio/music/lament_of_the_war.mp3",
]
## Helyszín -> saját számok. camp: a tábor, a nyugati tisztás, a bolt; town: a város, a vár és a házak; cave: a bánya
## és a kút alja; dungeon: az 1-20. emelet; depths: a 21-40. (Vérkő); abyss: a 41.-től (Káoszkő); trial: a próbatétel.
const PLACE_TRACKS := {
	"camp": ["res://assets/audio/music/medieval_exploration.mp3", "res://assets/audio/music/sirens_in_darkness.mp3"],
	"town": ["res://assets/audio/music/fantasy_orchestral_theme.mp3", "res://assets/audio/music/medieval_exploration.mp3"],
	"cave": ["res://assets/audio/music/cave_theme.ogg", "res://assets/audio/music/ancient_mysteries.ogg"],
	"dungeon": ["res://assets/audio/music/great_labyrinth.ogg", "res://assets/audio/music/medieval_battle.mp3", "res://assets/audio/music/battle_theme_a.mp3", "res://assets/audio/music/cave_theme.ogg"],
	"depths": ["res://assets/audio/music/dark_forest_theme.mp3", "res://assets/audio/music/the_final_battle.ogg", "res://assets/audio/music/great_labyrinth.ogg", "res://assets/audio/music/ancient_mysteries.ogg"],
	"abyss": ["res://assets/audio/music/evil_awaits.mp3", "res://assets/audio/music/dark_forest_theme.mp3", "res://assets/audio/music/the_final_battle.ogg", "res://assets/audio/music/ancient_mysteries.ogg"],
	"trial": ["res://assets/audio/music/battle_theme_a.mp3", "res://assets/audio/music/ancient_mysteries.ogg", "res://assets/audio/music/the_final_battle.ogg", "res://assets/audio/music/medieval_battle.mp3"],
}
## Szám -> hangerő-igazítás (dB): mind kb. -20 dBFS átlagra (mérve), hogy ne ugráljon a hangerő; a
## főellenség zenéje (-17.5) kicsit hangosabb marad.
const PLAYLIST_TRACKS := {
	"res://assets/audio/music/lament_of_the_war.mp3": -5.7,
	"res://assets/audio/music/medieval_exploration.mp3": 3.0,
	"res://assets/audio/music/medieval_battle.mp3": -3.6,
	"res://assets/audio/music/rising_moon.mp3": -3.7,
	"res://assets/audio/music/jrpg_theme.ogg": -7.9,
	"res://assets/audio/music/battle_theme_a.mp3": -6.9,
	"res://assets/audio/music/fantasy_orchestral_theme.mp3": -2.8,
	"res://assets/audio/music/cave_theme.ogg": -5.2,
	"res://assets/audio/music/ancient_mysteries.ogg": -6.8,
	"res://assets/audio/music/great_labyrinth.ogg": -4.1,
	"res://assets/audio/music/sirens_in_darkness.mp3": 1.2,
	"res://assets/audio/music/dark_forest_theme.mp3": -2.1,
	"res://assets/audio/music/the_final_battle.ogg": -1.9,
	"res://assets/audio/music/evil_awaits.mp3": -2.8,
}
## A játék közbeni zenék címe és szerzője: a bal alsó sarokban kiírja, mi szól éppen (lásd _show_now_playing;
## a főmenü zenéjénél nem, ott a Tutorial gomb van).
const MUSIC_TITLES := {
	"res://assets/audio/music/boss_battle.wav": "Boss Battle #2 — nene",
	"res://assets/audio/music/epic_boss_battle.wav": "Epic Boss Battle — Juhani Junkala",
	"res://assets/audio/music/heavy_boss_battle.ogg": "Heavy Boss Battle 1 — MintoDog",
	"res://assets/audio/music/demon_king_battle.mp3": "Battle RPG Theme — Cleyton Kauffman",
	"res://assets/audio/music/end_knight.mp3": "It Takes a Hero — Zane Little (a Lovag befejezése)",
	"res://assets/audio/music/end_archer.mp3": "Peaceful Forest — samza (az Íjász befejezése)",
	"res://assets/audio/music/end_veteran.ogg": "Memories — HothXcc (Gáspár befejezése)",
	"res://assets/audio/music/end_wizard.mp3": "Mirror Lake — Joth (Lőrinc befejezése)",
	"res://assets/audio/music/end_gravedigger.ogg": "Moonlit Lullaby for the Lost — Tsorthan Grove (Vendel befejezése)",
	"res://assets/audio/music/end_thief.ogg": "Night Prowler — Section 31 (Bence befejezése)",
	"res://assets/audio/music/lament_of_the_war.mp3": "Laments of the War — Cethiel",
	"res://assets/audio/music/medieval_exploration.mp3": "Medieval: Exploration — RandomMind",
	"res://assets/audio/music/medieval_battle.mp3": "Medieval: Battle — RandomMind",
	"res://assets/audio/music/rising_moon.mp3": "Fantasy: Rising Moon — RandomMind",
	"res://assets/audio/music/jrpg_theme.ogg": "JRPG Theme — Juhani Junkala",
	"res://assets/audio/music/battle_theme_a.mp3": "Battle Theme A — cynicmusic",
	"res://assets/audio/music/fantasy_orchestral_theme.mp3": "Fantasy Orchestral Theme — Joth",
	"res://assets/audio/music/cave_theme.ogg": "Cave Theme — Brandon75689",
	"res://assets/audio/music/ancient_mysteries.ogg": "Ancient Mysteries — sperrylion",
	"res://assets/audio/music/great_labyrinth.ogg": "Great Labyrinth — MintoDog",
	"res://assets/audio/music/sirens_in_darkness.mp3": "Sirens in Darkness — cynicmusic",
	"res://assets/audio/music/dark_forest_theme.mp3": "Dark Forest Theme — cynicmusic",
	"res://assets/audio/music/the_final_battle.ogg": "The Final Battle — skrjablin",
	"res://assets/audio/music/evil_awaits.mp3": "Evil Awaits — bosslevelaudio",
}
## Új szám után ennyi ideig élénk a felirat, utána halványabb.
const NOW_PLAYING_BRIGHT := 6.0
const MUSIC_FADE := 1.2
const VOICES := 16
const SETTINGS_PATH := "user://settings.cfg"

static var _instance: Audio

var music_volume := 0.6
var sfx_volume := 0.8

var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _music_players: Array[AudioStreamPlayer] = []
var _active_music := 0
var _current_track := ""
var _cache := {}
## Helyszínenként a lejátszási lista hátralévő számai (elfogyáskor újrakeverve), a szóló helyszín és az
## utoljára indított szám.
var _queues := {}
var _place := "camp"
var _last_song := ""
## Lejátszónként a futó áttűnés: újrahasználat előtt le kell állítani (különben egy korábbi elhalkítás
## a végén leállítaná az új számot is, pl. ha gyorsan lépsz vissza a főmenüből a játékba).
var _fades: Array[Tween] = [null, null]
var _now_label: Label
var _now_tween: Tween


## Effekt lejátszása. `volume_db` hozzáadódik az alap-hangerőhöz.
static func play(effect: String, volume_db := 0.0, pitch_variation := 0.08) -> void:
	_node().call_deferred("_play", effect, volume_db, pitch_variation)


## Zene váltása áttűnéssel (ha már ez szól, nem csinál semmit). Üres név: elhalkul.
static func music(track: String) -> void:
	_node().call_deferred("_switch_music", track)


static func settings() -> Audio:
	return _node()


## A zeneválasztó (szünet menü, MusicPanel) kategóriái: [cím, [számok]] — elöl a mindenhol szólók,
## aztán a helyszínek saját számai, a végén az egyéb zenék (főmenü, főellenség...).
const PLACE_NAMES := {
	"camp": "Tábor", "town": "Város", "cave": "Bánya és kút", "dungeon": "Kazamata (1–20. emelet)",
	"depths": "Mélység (21–40. emelet)", "abyss": "Káosz (41. emelettől)", "trial": "Próbatétel",
}


static func music_categories() -> Array:
	var categories: Array = [["Bárhol szól", GENERAL_TRACKS.duplicate()]]
	for place: String in PLACE_TRACKS:
		var own: Array = []
		for song: String in PLACE_TRACKS[place]:
			if not GENERAL_TRACKS.has(song):
				own.append(song)
		categories.append([PLACE_NAMES.get(place, place), own])
	var other: Array = []
	for track: String in MUSIC_TRACKS:
		if not ONLY_IN_FIGHT.has(track) and not ENDING_TRACKS.has(track):
			other.append(MUSIC_TRACKS[track])
	categories.append(["Egyéb", other])
	var endings: Array = []
	for track: String in ENDING_TRACKS:
		endings.append(MUSIC_TRACKS[track])
	categories.append(["Befejezések", endings])
	return categories


## Egy szám címe (szerző); ha nincs, a fájl neve.
static func song_title(path: String) -> String:
	return str(MUSIC_TITLES.get(path, path.get_file().get_basename().replace("_", " ").capitalize()))


## A most szóló szám (útvonal), vagy "".
static func current_song() -> String:
	var node := _node()
	if node._music_players[node._active_music].playing:
		return str(node._music_players[node._active_music].stream.resource_path)
	return ""


## Egy kiválasztott szám azonnali lejátszása (áttűnéssel); ha véget ér, a helyszín lejátszási listája folytatódik.
static func play_song(path: String) -> void:
	_node().call_deferred("_play_song", path)


func _play_song(path: String) -> void:
	var old_index := _active_music
	_active_music = 1 - _active_music
	var new_player := _music_players[_active_music]
	_fade(old_index, -80.0, true)
	var stream := _load(path)
	_set_loop(stream, false)
	_last_song = path
	# A végén a lejátszási lista jön (a főmenüben / főellenségnél is az utolsó helyszíné).
	_current_track = _place
	new_player.stream = stream
	new_player.volume_db = -40.0
	new_player.play()
	_fade(_active_music, float(PLAYLIST_TRACKS.get(path, 0.0)), false)
	_show_now_playing(path)


static func _node() -> Audio:
	if _instance == null or not is_instance_valid(_instance):
		_instance = Audio.new()
		var tree := Engine.get_main_loop() as SceneTree
		tree.root.add_child.call_deferred(_instance)
	return _instance


func _init() -> void:
	name = "Audio"
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	for i in VOICES:
		var voice := AudioStreamPlayer.new()
		voice.bus = "SFX"
		add_child(voice)
		_voices.append(voice)
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = "Music"
		player.volume_db = -80.0
		player.finished.connect(_on_music_finished.bind(player))
		add_child(player)
		_music_players.append(player)
	_build_now_playing()
	_load_settings()


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")


func _play(effect: String, volume_db: float, pitch_variation: float) -> void:
	if not VARIANTS.has(effect):
		push_warning("Ismeretlen hang: " + effect)
		return
	var count: int = VARIANTS[effect]
	var file := effect if count == 0 else "%s_%d" % [effect, randi_range(1, count)]
	var stream := _load(SFX_DIR + file + ".ogg")
	if stream == null:
		# Néhány effekt (pl. az üllő) .wav-ban van.
		stream = _load(SFX_DIR + file + ".wav")
	if stream == null:
		return
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	voice.stream = stream
	voice.volume_db = VOLUMES.get(effect, 0.0) + volume_db
	voice.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	voice.play()


func _switch_music(track: String) -> void:
	if track == PLAYLIST:
		track = _place
	if PLACE_TRACKS.has(track):
		_place = track
		# Másik helyszín, de a szóló szám ott is szólhat: nem vált, csak a következő szám jön már az új listából.
		if PLACE_TRACKS.has(_current_track) and place_songs(track).has(_last_song):
			_current_track = track
			return
	if track == _current_track:
		return
	_current_track = track
	var old_index := _active_music
	_active_music = 1 - _active_music
	var new_player := _music_players[_active_music]
	_fade(old_index, -80.0, true)
	if track.is_empty():
		_show_now_playing("")
		return
	var stream: AudioStream
	var target_db := 0.0
	if PLACE_TRACKS.has(track):
		stream = _next_song(track)
		target_db = PLAYLIST_TRACKS[_last_song]
	else:
		stream = _load(MUSIC_TRACKS[track])
		_set_loop(stream, true)
	new_player.stream = stream
	new_player.volume_db = -40.0
	new_player.play()
	_fade(_active_music, target_db, false)
	_show_now_playing(stream.resource_path)


## Áttűnés egy lejátszón (az előző, még futó áttűnését leállítja); `stop_after`: a végén elhallgat.
func _fade(index: int, to_db: float, stop_after: bool) -> void:
	if _fades[index] != null and _fades[index].is_valid():
		_fades[index].kill()
	var player := _music_players[index]
	var tween := create_tween()
	tween.tween_property(player, "volume_db", to_db, MUSIC_FADE)
	if stop_after:
		tween.tween_callback(player.stop)
	_fades[index] = tween


## Egy helyszín összes száma: a sajátjai és a mindenhol szólók.
static func place_songs(place: String) -> Array[String]:
	var songs: Array[String] = []
	songs.assign(PLACE_TRACKS[place])
	for song in GENERAL_TRACKS:
		if not songs.has(song):
			songs.append(song)
	return songs


## A helyszín lejátszási listájának következő száma (nem ismétlődik: a lista végén újrakeveri).
func _next_song(place: String) -> AudioStream:
	var queue: Array[String] = []
	queue.assign(_queues.get(place, []))
	if queue.is_empty():
		queue = place_songs(place)
		queue.shuffle()
	# Ugyanaz ne jöjjön kétszer egymás után (a keverés határán és helyváltáskor sem).
	if queue.size() > 1 and queue[0] == _last_song:
		queue.append(queue.pop_front())
	_last_song = queue.pop_front()
	_queues[place] = queue
	var stream := _load(_last_song)
	_set_loop(stream, false)
	return stream


## Egy szám véget ért: ha a lejátszási lista szól, jön a következő (ugyanazon a lejátszón).
func _on_music_finished(player: AudioStreamPlayer) -> void:
	if not PLACE_TRACKS.has(_current_track) or player != _music_players[_active_music]:
		return
	player.stream = _next_song(_current_track)
	player.volume_db = PLAYLIST_TRACKS[_last_song]
	player.play()
	_show_now_playing(_last_song)


## A bal alsó sarokban: mi szól éppen (a HUD fölött, az ablakok alatt; minden jelenetben, mert az Audio megmarad).
func _build_now_playing() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	_now_label = UiStyle.label("", 15, Color(0.95, 0.88, 0.7), true)
	_now_label.anchor_top = 1.0
	_now_label.anchor_bottom = 1.0
	_now_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_now_label.offset_left = 16.0
	# A kazamatában alul a teljes szélességű XP-sáv van: fölötte.
	_now_label.offset_bottom = -42.0
	_now_label.visible = false
	layer.add_child(_now_label)


## Új szám: a címe élénken megjelenik, pár mp múlva elhalványul (de kint marad). Üres: eltűnik.
func _show_now_playing(path: String) -> void:
	if _now_tween != null and _now_tween.is_valid():
		_now_tween.kill()
	_now_label.visible = MUSIC_TITLES.has(path)
	if not _now_label.visible:
		return
	_now_label.text = "♪ " + str(MUSIC_TITLES[path])
	_now_label.modulate.a = 1.0
	_now_tween = create_tween()
	_now_tween.tween_interval(NOW_PLAYING_BRIGHT)
	_now_tween.tween_property(_now_label, "modulate:a", 0.5, 1.5)


func _set_loop(stream: AudioStream, on: bool) -> void:
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = on
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if on else AudioStreamWAV.LOOP_DISABLED
		stream.loop_begin = 0
		stream.loop_end = int(stream.get_length() * stream.mix_rate)


func _load(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]


# --- Beállítások -------------------------------------------------------------

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_volumes()
	save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_volumes()
	save_settings()


func _apply_volumes() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(music_volume, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(sfx_volume, 0.0001)))


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("display", "fullscreen", is_fullscreen())
	config.save(SETTINGS_PATH)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		music_volume = config.get_value("audio", "music", music_volume)
		sfx_volume = config.get_value("audio", "sfx", sfx_volume)
	_apply_volumes()


## A mentett teljes képernyő beállítás (alapból be).
static func saved_fullscreen() -> bool:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		return config.get_value("display", "fullscreen", true)
	return true


static func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() in [
		DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]


static func toggle_fullscreen() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_WINDOWED if is_fullscreen() else DisplayServer.WINDOW_MODE_FULLSCREEN)
	_node().save_settings()
