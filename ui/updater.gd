class_name Updater
extends CanvasLayer
## Automatikus frissítés a GitHubról (a főmenü teszi be, indításonként egyszer néz). Megkérdezi a
## GitHubot (compare API), van-e újabb változat a main ágon, mint ami a mappában van; ha igen, felül
## megmutatja az újdonságokat, és AUTO_DELAY másodperc múlva magától frissít ("Később": most kihagyja).
##   - git-tel klónozott mappában: git pull --ff-only (a helyi munkát nem írja felül; ha a mappában
##     nem mentett (commitolatlan) változás van, nem frissít magától, csak gombra)
##   - git nélkül (a GitHubról ZIP-ben letöltött mappa): letölti a main ág ZIP-jét, és felülírja vele
##     a fájlokat; a .update_version / .update_manifest fájl mondja meg, mi volt az előző változat
## Utána újraimportálja az eszközöket (Godot --headless --import), és újraindítja a játékot.
## Exportált játékban és ablak nélkül (tesztek) nem fut; ha a helyi mappa előrébb jár (fel nem
## töltött commitok, pl. fejlesztés közben), nem ajánl frissítést.

const REPO := "nagypetyko2025-ship-it/dungeon"
const BRANCH := "main"
const API := "https://api.github.com/repos/" + REPO
const ZIP_URL := "https://codeload.github.com/" + REPO + "/zip/refs/heads/" + BRANCH
const HEADERS: PackedStringArray = ["User-Agent: dungeon-updater", "Accept: application/vnd.github+json"]
const VERSION_FILE := ".update_version"
const MANIFEST_FILE := ".update_manifest"
const ZIP_PATH := "user://update.zip"
## Ennyi másodperc múlva frissít magától.
const AUTO_DELAY := 6
## Legfeljebb ennyi újdonságot sorolunk fel.
const MAX_LISTED := 6

## Egy indítás alatt csak egyszer nézünk (a főmenübe visszatérve nem újra).
static var _checked := false

var _dir := ""
var _git := ""
var _local_sha := ""
var _remote_sha := ""
var _busy := false
var _auto_left := -1.0
var _panel: PanelContainer
var _title: Label
var _list: Label
var _status: Label
var _update_button: Button
var _later_button: Button


## A helyi változat rövid azonosítója (a főmenü sarkába); "" ha nem tudni.
static func current_version() -> String:
	return _read_local_sha().left(7)


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _checked or OS.has_feature("template") or DisplayServer.get_name() == "headless":
		return
	_checked = true
	_dir = ProjectSettings.globalize_path("res://")
	_check()


func _process(delta: float) -> void:
	if _auto_left < 0.0 or _busy:
		return
	_auto_left -= delta
	_status.text = "Frissítés %d mp múlva... (Később: most kihagyod)" % ceili(maxf(_auto_left, 0.0))
	if _auto_left <= 0.0:
		_auto_left = -1.0
		_start_update()


# ---------------------------------------------------------------- ellenőrzés

func _check() -> void:
	var git_dir := _dir.path_join(".git")
	if FileAccess.file_exists(git_dir):
		return  # git worktree / almodul: ehhez nem nyúlunk
	if DirAccess.dir_exists_absolute(git_dir):
		_git = _find_git()
	_local_sha = _read_local_sha()
	# Git-es mappa, de nem a main ágon (vagy nincs git): nem frissítünk.
	if DirAccess.dir_exists_absolute(git_dir) and (_local_sha.is_empty() or _git.is_empty()):
		return
	var commits: Array = []
	if _local_sha.is_empty():
		# ZIP-ből kicsomagolt mappa, de nem tudjuk, melyik változat: a legutolsót ajánljuk.
		var latest: Variant = await _get_json(API + "/commits/" + BRANCH)
		if not latest is Dictionary:
			return
		commits = [latest]
	else:
		var compare: Variant = await _get_json(API + "/compare/%s...%s" % [_local_sha, BRANCH])
		# (404: a helyi commit nincs a GitHubon, azaz itt fejlesztenek: nem ajánlunk semmit.)
		if not compare is Dictionary:
			return
		var status := str(compare.get("status", ""))
		if status == "diverged":
			_build_panel()
			_title.text = "Új változat van a GitHubon"
			_list.text = "De ebben a mappában fel nem töltött saját változtatások is vannak,\n" \
				+ "ezért nem frissítek magamtól: frissíts kézzel (git pull)."
			_update_button.visible = false
			_later_button.text = "Rendben"
			return
		if status != "ahead":
			return
		commits = compare.get("commits", [])
	if commits.is_empty():
		return
	_remote_sha = str((commits.back() as Dictionary).get("sha", ""))
	_offer(commits)


func _offer(commits: Array) -> void:
	_build_panel()
	_title.text = "Új változat érhető el! (%d új változás)" % commits.size()
	var lines: Array[String] = []
	for i in range(commits.size() - 1, maxi(commits.size() - 1 - MAX_LISTED, -1), -1):
		var commit: Dictionary = (commits[i] as Dictionary).get("commit", {})
		var message := str(commit.get("message", "")).get_slice("\n", 0).strip_edges()
		var author := str((commit.get("author", {}) as Dictionary).get("name", ""))
		lines.append("•  %s%s" % [message.left(90) + ("…" if message.length() > 90 else ""),
			"  (%s)" % author if not author.is_empty() else ""])
	if commits.size() > MAX_LISTED:
		lines.append("…és még %d változás" % (commits.size() - MAX_LISTED))
	_list.text = "\n".join(lines)
	if _can_auto_update():
		_auto_left = AUTO_DELAY
	else:
		_status.text = "A mappában nem mentett változtatások vannak: csak gombra frissítek (a munkád megmarad)."


## Magától csak akkor frissít, ha a git-es mappában nincs commitolatlan változás (ZIP-esnél mindig).
func _can_auto_update() -> bool:
	if _git.is_empty():
		return true
	var output: Array = []
	if OS.execute(_git, ["-C", _dir, "status", "--porcelain", "--untracked-files=no"], output, true) != 0:
		return false
	return "".join(output).strip_edges().is_empty()


func _get_json(url: String) -> Variant:
	var http := HTTPRequest.new()
	http.timeout = 10.0
	add_child(http)
	if http.request(url, HEADERS) != OK:
		http.queue_free()
		return null
	var result: Array = await http.request_completed
	http.queue_free()
	if int(result[0]) != HTTPRequest.RESULT_SUCCESS or int(result[1]) != 200:
		return null
	return JSON.parse_string((result[3] as PackedByteArray).get_string_from_utf8())


## A helyi változat (commit) teljes azonosítója: git-es mappában a main ág feje (más ágon ""),
## ZIP-esben a .update_version tartalma.
static func _read_local_sha() -> String:
	var dir := ProjectSettings.globalize_path("res://")
	var git := dir.path_join(".git")
	if DirAccess.dir_exists_absolute(git):
		var head := _read_text(git.path_join("HEAD"))
		if not head.begins_with("ref: "):
			return head
		var ref := head.substr(5)
		if ref != "refs/heads/" + BRANCH:
			return ""
		var sha := _read_text(git.path_join(ref))
		if not sha.is_empty():
			return sha
		for line in _read_text(git.path_join("packed-refs")).split("\n"):
			if line.strip_edges().ends_with(" " + ref):
				return line.get_slice(" ", 0)
		return ""
	return _read_text(dir.path_join(VERSION_FILE))


static func _read_text(path: String) -> String:
	return FileAccess.get_file_as_string(path).strip_edges() if FileAccess.file_exists(path) else ""


## A git: a PATH-on, vagy a szokásos helyeken (Git for Windows, GitHub Desktop).
static func _find_git() -> String:
	var output: Array = []
	if OS.execute("git", ["--version"], output, true) == 0:
		return "git"
	var local := OS.get_environment("LOCALAPPDATA")
	var candidates: Array[String] = ["C:/Program Files/Git/cmd/git.exe", "C:/Program Files (x86)/Git/cmd/git.exe",
		local.path_join("Programs/Git/cmd/git.exe")]
	var desktop := local.path_join("GitHubDesktop")
	if DirAccess.dir_exists_absolute(desktop):
		for app in DirAccess.get_directories_at(desktop):
			if app.begins_with("app-"):
				candidates.append(desktop.path_join(app).path_join("resources/app/git/cmd/git.exe"))
	for candidate in candidates:
		if FileAccess.file_exists(candidate):
			return candidate
	return ""


# ---------------------------------------------------------------- frissítés

func _start_update() -> void:
	if _busy:
		return
	_busy = true
	_auto_left = -1.0
	_update_button.visible = false
	_later_button.visible = false
	var result: Dictionary
	if not _git.is_empty():
		_status.text = "Letöltés (git pull)..."
		result = await _threaded(_git_pull)
	else:
		_status.text = "Letöltés a GitHubról..."
		result = await _download_zip()
		if result["ok"]:
			_status.text = "Kicsomagolás..."
			result = await _threaded(_extract_zip)
	if not result["ok"]:
		_busy = false
		_status.text = "Nem sikerült frissíteni: %s" % str(result["text"]).strip_edges().left(220)
		_later_button.text = "Bezárás"
		_later_button.visible = true
		return
	_status.text = "Az új fájlok előkészítése (importálás) — ez fél percig is eltarthat..."
	await _threaded(_import)
	_status.text = "Kész! A játék újraindul..."
	await get_tree().create_timer(0.8).timeout
	OS.create_process(OS.get_executable_path(), OS.get_cmdline_args())
	get_tree().quit()


## A hosszú, blokkoló munka (git, kicsomagolás, importálás) külön szálon, hogy a kép ne álljon meg.
func _threaded(work: Callable) -> Dictionary:
	var thread := Thread.new()
	thread.start(work)
	while thread.is_alive():
		await get_tree().process_frame
	var result: Variant = thread.wait_to_finish()
	return result if result is Dictionary else {"ok": false, "text": "ismeretlen hiba"}


func _git_pull() -> Dictionary:
	# Ne kérjen jelszót (a tároló nyilvános): ha mégis kérne, inkább hibázzon.
	OS.set_environment("GIT_TERMINAL_PROMPT", "0")
	OS.set_environment("GCM_INTERACTIVE", "never")
	var output: Array = []
	var code := OS.execute(_git, ["-C", _dir, "pull", "--ff-only", "origin", BRANCH], output, true)
	return {"ok": code == 0, "text": "".join(output)}


func _download_zip() -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = 180.0
	http.download_file = ZIP_PATH
	add_child(http)
	if http.request(ZIP_URL, HEADERS) != OK:
		http.queue_free()
		return {"ok": false, "text": "a letöltés nem indult el"}
	var result: Array = await http.request_completed
	http.queue_free()
	if int(result[0]) != HTTPRequest.RESULT_SUCCESS or int(result[1]) != 200:
		return {"ok": false, "text": "letöltési hiba (%d / %d)" % [int(result[0]), int(result[1])]}
	return {"ok": true, "text": ""}


## A ZIP fájljai a mappába (a gyökérmappa nélkül); ami az előző ZIP-ben még benne volt, de már
## nincs, azt töröljük (csak a mi fájljainkat, a manifest szerint). Végül a változat beírása.
func _extract_zip() -> Dictionary:
	var reader := ZIPReader.new()
	if reader.open(ZIP_PATH) != OK:
		return {"ok": false, "text": "a letöltött ZIP nem nyitható meg"}
	var written := {}
	for entry in reader.get_files():
		var slash := entry.find("/")
		var rel := entry.substr(slash + 1) if slash >= 0 else ""
		if rel.is_empty() or rel.ends_with("/") or rel.contains(".."):
			continue
		var target := _dir.path_join(rel)
		DirAccess.make_dir_recursive_absolute(target.get_base_dir())
		var file := FileAccess.open(target, FileAccess.WRITE)
		if file == null:
			reader.close()
			return {"ok": false, "text": "nem írható: " + rel}
		file.store_buffer(reader.read_file(entry))
		file.close()
		written[rel] = true
	reader.close()
	for rel in _read_text(_dir.path_join(MANIFEST_FILE)).split("\n", false):
		if not written.has(rel) and not rel.contains(".."):
			DirAccess.remove_absolute(_dir.path_join(rel))
	var manifest := FileAccess.open(_dir.path_join(MANIFEST_FILE), FileAccess.WRITE)
	if manifest != null:
		manifest.store_string("\n".join(PackedStringArray(written.keys())))
		manifest.close()
	var version := FileAccess.open(_dir.path_join(VERSION_FILE), FileAccess.WRITE)
	if version != null:
		version.store_string(_remote_sha)
		version.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ZIP_PATH))
	return {"ok": true, "text": ""}


func _import() -> Dictionary:
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", _dir, "--import"], output, true)
	return {"ok": code == 0, "text": "".join(output)}


# ---------------------------------------------------------------- ablak

func _build_panel() -> void:
	if _panel != null:
		return
	# Sötét háttér a díszkeret alatt (a keret közepe átlátszó, a főmenü címe átlátszana rajta).
	_panel = PanelContainer.new()
	var backdrop := StyleBoxFlat.new()
	backdrop.bg_color = Color(0.07, 0.045, 0.04, 0.95)
	_panel.add_theme_stylebox_override("panel", backdrop)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_panel.offset_left = -430
	_panel.offset_right = 430
	_panel.offset_top = 16
	add_child(_panel)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", MenuStyle.box(MenuStyle.MENU_PANEL, 18, 22))
	_panel.add_child(frame)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	frame.add_child(box)
	_title = MenuStyle.title_label("", 36, MenuStyle.GOLD)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_list = _label(16, MenuStyle.PARCHMENT)
	box.add_child(_list)
	_status = _label(16, Color(1, 0.85, 0.5))
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	_update_button = MenuStyle.button("Frissítés most")
	_update_button.custom_minimum_size = Vector2(260, 50)
	_update_button.pressed.connect(_start_update)
	row.add_child(_update_button)
	_later_button = MenuStyle.button("Később")
	_later_button.custom_minimum_size = Vector2(200, 50)
	_later_button.pressed.connect(func() -> void:
		_auto_left = -1.0
		_panel.visible = false)
	row.add_child(_later_button)


func _label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 800
	label.add_theme_font_override("font", MenuStyle.BUTTON_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
