class_name GameCursor
## Saját egérkurzor: páncélkesztyű (a Kenney Cursor Pack CC0 kéz-sziluettjeiből
## pixelesre rajzolva). Mutatáskor kinyújtott ujj, tárgy húzásakor ökölbe szorul.

const POINT: Texture2D = preload("res://assets/cursor/gauntlet_point.png")
const GRAB: Texture2D = preload("res://assets/cursor/gauntlet_grab.png")
## A kurzor "hegye" (ahova kattint) a képen belül.
const POINT_HOTSPOT := Vector2(14, 10)
const GRAB_HOTSPOT := Vector2(18, 16)


static func apply() -> void:
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_IBEAM, Input.CURSOR_HELP]:
		Input.set_custom_mouse_cursor(POINT, shape, POINT_HOTSPOT)
	for shape in [Input.CURSOR_DRAG, Input.CURSOR_CAN_DROP, Input.CURSOR_FORBIDDEN, Input.CURSOR_MOVE]:
		Input.set_custom_mouse_cursor(GRAB, shape, GRAB_HOTSPOT)
