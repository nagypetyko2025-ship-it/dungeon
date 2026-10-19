class_name SpriteSheet
## Képek kivágása a 0x72 DungeonTileset II lapból (assets/0x72_dungeon).
## A koordináták a csomag tile_list.txt fájljából valók.

const TEXTURE: Texture2D = preload("res://assets/0x72_dungeon/0x72_DungeonTilesetII_v1.7.png")
const FRAME_COUNT := 4
const ANIM_FPS := 8.0

static var _frames_cache := {}


static func region(rect: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = TEXTURE
	texture.region = rect
	return texture


## Karakteranimációk. `first_idle` az idle első képkockája; a csomagban
## a run közvetlenül utána jön 4 kockával, a hit (ha van) a run után.
## Ha `has_run` hamis, a karakternek csak egy animációja van (idle = run).
static func character_frames(first_idle: Rect2, has_run := true, has_hit := false) -> SpriteFrames:
	var key := [first_idle, has_run, has_hit]
	if _frames_cache.has(key):
		return _frames_cache[key]
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_animation(frames, "idle", first_idle, 0, FRAME_COUNT)
	_add_animation(frames, "run", first_idle, FRAME_COUNT if has_run else 0, FRAME_COUNT)
	if has_hit:
		_add_animation(frames, "hit", first_idle, FRAME_COUNT * 2, 1)
	_frames_cache[key] = frames
	return frames


static func _add_animation(frames: SpriteFrames, anim: String, first: Rect2, skip: int, count: int) -> void:
	frames.add_animation(anim)
	frames.set_animation_speed(anim, ANIM_FPS)
	for i in count:
		var rect := first
		rect.position.x += (skip + i) * first.size.x
		frames.add_frame(anim, region(rect))
