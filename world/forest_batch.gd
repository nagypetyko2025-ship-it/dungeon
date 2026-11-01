class_name ForestBatch
extends Node2D
## A tábor (és a rejtett ösvény) díszerdeje egyben kirajzolva: egy fa nem külön Node2D + 1-2 Sprite2D
## (több ezer fánál ez volt a belépés legnagyobb akadása), hanem egy csempesor 16 csempés darabja egy
## node, ami _draw-ban rajzolja a fáit. A node a sor alján áll, így az Entities y-rendezésében ugyanúgy
## takar, mint a különálló fák. Használat: `ForestBatch.plant(entities, pos, tiles, color)`.

const RPG: Texture2D = preload("res://assets/shop/kenney_rpg.png")
## Egy darab szélessége (px): ennyi csempe egy node.
const CHUNK := 16 * 32

## [helyi középpont, Kenney RPG csempe (koordináta), szín]
var _tiles: Array = []


## Egy fa (vagy más kellék) a `parent`-ben (y-rendezett Entities): `at` a fa alja (mint a régi holder),
## `tiles`: [[Kenney RPG koordináta, eltolás az aljától], ...], 2× nagyítva, középre igazítva.
static func plant(parent: Node2D, at: Vector2, tiles: Array, color: Color) -> void:
	# A fák alja a csempesoron belül kicsit szóródik (±6 px): a sor a csempe közepe alapján.
	var row := floori((at.y - 8.0) / 32.0)
	var chunk := floori(at.x / CHUNK)
	var key := "ForestBatch_%d_%d" % [row, chunk]
	var batch := parent.get_node_or_null(key) as ForestBatch
	if batch == null:
		batch = ForestBatch.new()
		batch.name = key
		batch.position = Vector2(chunk * CHUNK, row * 32.0 + 28.0)
		parent.add_child(batch)
	for tile: Array in tiles:
		batch._tiles.append([at - batch.position + (tile[1] as Vector2), tile[0], color])
	batch.queue_redraw()


func _draw() -> void:
	for tile: Array in _tiles:
		var coords: Vector2i = tile[1]
		draw_texture_rect_region(RPG, Rect2((tile[0] as Vector2) - Vector2(16, 16), Vector2(32, 32)),
			Rect2(Vector2(coords) * 17.0, Vector2(16, 16)), tile[2])
