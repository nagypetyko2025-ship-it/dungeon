class_name NetSession
## A többjátékos mód hálózati alapja (előkészítés; a játékmenet még nem használja, a menüben
## "hamarosan"). ENet, gazda–vendég felállás: az egyik játékos a gazda (host), ő futtatja a
## kazamatát (a szörnyek, a sebzés és a zsákmány nála dől el), a többiek csatlakoznak hozzá.
##
## A terv (lépésenként):
##   1. Kapcsolat: host() / join() / leave(), a játékosok listája (név, karakter) – ez a fájl.
##   2. Váró: a menüben a gazda látja a csatlakozókat, és ő indítja a futást (a kazamata magja
##      közös: GameState-ben, hogy minden gépen ugyanaz az emelet generálódjon).
##   3. Játékosok a pályán: minden csatlakozónak saját Player (MultiplayerSpawner), a mozgás és
##      az animáció MultiplayerSynchronizerrel; a saját karakterét mindenki maga irányítja.
##   4. Szörnyek és sebzés: csak a gazdán futnak, a vendégek a helyzetüket és az életüket kapják.
##   5. Zsákmány: a tárgyak és az arany a felvevőé (minden játékos a saját táskájába gyűjt).
## A tábor (NPC-k, küldetések, mentés) mindenkinél a saját gépén marad, egyjátékos.

## Amíg nincs kész, a menü nem engedi elindítani.
const ENABLED := false
const DEFAULT_PORT := 24565
const MAX_PLAYERS := 4
const DEFAULT_ADDRESS := "127.0.0.1"

## A csatlakozott játékosok: peer id -> {"name": String, "character": String}.
static var players := {}
static var _tree: SceneTree


## Gazdaként indul: várja a csatlakozókat. OK, vagy a hibakód (pl. foglalt a port).
static func host(tree: SceneTree, player_name: String, port := DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, MAX_PLAYERS - 1)
	if error != OK:
		return error
	_attach(tree, peer)
	players = {1: _info(player_name)}
	return OK


## Csatlakozás egy gazdához (IP-cím és port). A kapcsolat létrejöttét a tree.get_multiplayer()
## connected_to_server / connection_failed jelzése mondja meg.
static func join(tree: SceneTree, player_name: String, address := DEFAULT_ADDRESS, port := DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error != OK:
		return error
	_attach(tree, peer)
	players = {}
	tree.get_multiplayer().connected_to_server.connect(func() -> void:
		players[tree.get_multiplayer().get_unique_id()] = _info(player_name), CONNECT_ONE_SHOT)
	return OK


## Kilépés a többjátékos módból (vissza egyjátékosba).
static func leave() -> void:
	if _tree != null:
		var multiplayer := _tree.get_multiplayer()
		if multiplayer.multiplayer_peer != null:
			multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players = {}


static func is_online() -> bool:
	return _tree != null and not (_tree.get_multiplayer().multiplayer_peer is OfflineMultiplayerPeer) \
		and _tree.get_multiplayer().multiplayer_peer != null


## Ő a gazda-e (egyjátékosban mindig igaz: ott minden a saját gépen dől el).
static func is_host() -> bool:
	return not is_online() or _tree.get_multiplayer().is_server()


static func _attach(tree: SceneTree, peer: ENetMultiplayerPeer) -> void:
	_tree = tree
	var multiplayer := tree.get_multiplayer()
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_disconnected.connect(func(id: int) -> void: players.erase(id))


static func _info(player_name: String) -> Dictionary:
	return {"name": player_name, "character": Progress.character}
