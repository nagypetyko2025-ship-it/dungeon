class_name ResourceWarmer
## Képek (és más erőforrások) gyorsítótára és háttérbetöltése, hogy ne akadjon a játék, amikor valami először
## (vagy egy ablak újranyitásakor újra) megjelenik: a tárgyikonok a csalómenüben, a könyvekben és a táskában,
## a Szörnyek könyve képei, a szörnyek lapjai az első harcnál.
##   - `fetch(path)`: a betöltött erőforrás; egyszer töltődik be, és bent marad (a load() magától kidobná,
##     amint semmi sem használja, és a következő megnyitáskor újra lemezről olvasná).
##   - `warm(paths)`: háttérszálon előre betölti őket (ResourceLoader.load_threaded_request); képkockánként
##     átveszi, ami elkészült. Ha közben valami már kéri, a `fetch` megvárja / betölti.

static var _cache := {}
static var _pending: Array[String] = []
static var _polling := false


static func fetch(path: String) -> Resource:
	var cached: Resource = _cache.get(path)
	if cached != null:
		return cached
	var resource: Resource
	if _pending.has(path):
		resource = ResourceLoader.load_threaded_get(path)
		_pending.erase(path)
	else:
		resource = load(path)
	if resource != null:
		_cache[path] = resource
	return resource


static func warm(paths: Array) -> void:
	for path: String in paths:
		if path.is_empty() or _cache.has(path) or _pending.has(path) or not ResourceLoader.exists(path):
			continue
		if ResourceLoader.load_threaded_request(path) == OK:
			_pending.append(path)
	if not _pending.is_empty() and not _polling:
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null:
			_polling = true
			tree.process_frame.connect(ResourceWarmer._poll)


## Képkockánként: ami a háttérben elkészült, bekerül a gyorsítótárba (egyszerre legfeljebb néhány, hogy
## az átvétel se akasszon).
static func _poll() -> void:
	var taken := 0
	for path in _pending.duplicate():
		if taken >= 8:
			break
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		_pending.erase(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var resource := ResourceLoader.load_threaded_get(path)
			if resource != null:
				_cache[path] = resource
			taken += 1
	if _pending.is_empty():
		_polling = false
		(Engine.get_main_loop() as SceneTree).process_frame.disconnect(ResourceWarmer._poll)
