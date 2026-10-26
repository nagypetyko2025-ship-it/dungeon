class_name Audio
extends Node
## Hangok és zene. Egyetlen példány él a SceneTree gyökerén (jelenetváltáskor
## sem tűnik el, így a zene sem szakad meg). Használat:
##   Audio.play("hit")            # effekt (több változatból véletlenül választ)
##   Audio.music("epic")          # zene, áttűnéssel ("epic": a tábor és a kazamata lejátszási listája)
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
}
## A tábor és a kazamata zenéje: epikus számok egymás után (ha az egyik véget ér, jön a következő; a sorrend
## keverve, ugyanaz nem jön kétszer egymás után). Mind CC0, lásd assets/audio/LICENSE.txt.
## Szám -> hangerő-igazítás (dB): mind kb. -20 dBFS átlagra (mérve), hogy ne ugráljon a hangerő; a
## főellenség zenéje (-17.5) kicsit hangosabb marad.
const PLAYLIST := "epic"
const PLAYLIST_TRACKS := {
	"res://assets/audio/music/lament_of_the_war.mp3": -5.7,
	"res://assets/audio/music/medieval_exploration.mp3": 3.0,
	"res://assets/audio/music/medieval_battle.mp3": -3.6,
	"res://assets/audio/music/rising_moon.mp3": -3.7,
	"res://assets/audio/music/jrpg_theme.ogg": -7.9,
}
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
## A lejátszási lista hátralévő számai (elfogyáskor újrakeverve) és az utoljára indított szám.
var _queue: Array[String] = []
var _last_song := ""


## Effekt lejátszása. `volume_db` hozzáadódik az alap-hangerőhöz.
static func play(effect: String, volume_db := 0.0, pitch_variation := 0.08) -> void:
	_node().call_deferred("_play", effect, volume_db, pitch_variation)


## Zene váltása áttűnéssel (ha már ez szól, nem csinál semmit). Üres név: elhalkul.
static func music(track: String) -> void:
	_node().call_deferred("_switch_music", track)


static func settings() -> Audio:
	return _node()


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
	if track == _current_track:
		return
	_current_track = track
	var old := _music_players[_active_music]
	_active_music = 1 - _active_music
	var new_player := _music_players[_active_music]
	var fade := create_tween().set_parallel()
	fade.tween_property(old, "volume_db", -80.0, MUSIC_FADE)
	fade.chain().tween_callback(old.stop)
	if track.is_empty():
		return
	var stream: AudioStream
	var target_db := 0.0
	if track == PLAYLIST:
		stream = _next_song()
		target_db = PLAYLIST_TRACKS[_last_song]
	else:
		stream = _load(MUSIC_TRACKS[track])
		_set_loop(stream, true)
	new_player.stream = stream
	new_player.volume_db = -40.0
	new_player.play()
	var fade_in := create_tween()
	fade_in.tween_property(new_player, "volume_db", target_db, MUSIC_FADE)


## A lejátszási lista következő száma (nem ismétlődik: a lista végén újrakeveri).
func _next_song() -> AudioStream:
	if _queue.is_empty():
		_queue.assign(PLAYLIST_TRACKS.keys())
		_queue.shuffle()
		# Ugyanaz ne jöjjön kétszer egymás után (a keverés határán sem).
		if _queue.size() > 1 and _queue[0] == _last_song:
			_queue.append(_queue.pop_front())
	_last_song = _queue.pop_front()
	var stream := _load(_last_song)
	_set_loop(stream, false)
	return stream


## Egy szám véget ért: ha a lejátszási lista szól, jön a következő (ugyanazon a lejátszón).
func _on_music_finished(player: AudioStreamPlayer) -> void:
	if _current_track != PLAYLIST or player != _music_players[_active_music]:
		return
	player.stream = _next_song()
	player.volume_db = PLAYLIST_TRACKS[_last_song]
	player.play()


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
