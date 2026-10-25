class_name GamePause
## Az ablakok (menük, szintlépés, halál...) alatti megállás.
## Egyjátékosban az egész játék megáll (SceneTree.paused). Közös játékban semmi sem áll meg (a szörnyek,
## a társak, a lövedékek és a saját karaktered is élnek tovább), csak a karaktered nem fogad irányítást,
## és a világ sem reagál (E, súgók): ezt mutatja az `active()`, a `get_tree().paused` helyett.

## Közös játékban nyitva van egy ablak (a fa ilyenkor nem áll meg).
static var _soft := false


static func set_paused(tree: SceneTree, on: bool) -> void:
	_soft = on and NetLobby.is_playing(tree)
	tree.paused = on and not _soft


## Nyitva van-e olyan ablak, ami alatt a játékos nem irányít (egyjátékosban ilyenkor a játék is áll).
static func active(tree: SceneTree) -> bool:
	return tree.paused or (_soft and NetLobby.is_playing(tree))
