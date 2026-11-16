extends SceneTree
## Minden .gd betöltése (a --import nem mutatja a parse hibákat). Kiírja: "checked N, bad: M".


func _initialize() -> void:
	var files: Array[String] = []
	_collect("res://", files)
	var bad := 0
	for path in files:
		var script := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
		if script == null or not script.can_instantiate():
			bad += 1
			print("BAD ", path)
	print("checked %d, bad: %d" % [files.size(), bad])
	quit()


func _collect(dir_path: String, files: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for name in dir.get_directories():
		if not name.begins_with("."):
			_collect(dir_path.path_join(name), files)
	for name in dir.get_files():
		if name.ends_with(".gd") and not name.begins_with("_chk") and name != "check_all.gd":
			files.append(dir_path.path_join(name))
