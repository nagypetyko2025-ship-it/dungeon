class_name FloatingText
extends Label
## Felfelé úszó, elhalványuló szöveg (sebzésszám, "Kikerülve!" stb.).
## Nagyobb betűmérettel (pl. kritikus találatnál) kicsit "kiugrik" is.

const BOX_SIZE := Vector2(100, 20)
const DEFAULT_FONT_SIZE := 14

var _font_size := DEFAULT_FONT_SIZE


static func spawn(parent: Node, at: Vector2, message: String, color: Color, font_size := DEFAULT_FONT_SIZE) -> void:
	var label := FloatingText.new()
	label._font_size = font_size
	label.text = message
	label.modulate = color
	label.z_index = 10
	label.size = Vector2(BOX_SIZE.x, font_size + 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 4 if font_size <= DEFAULT_FONT_SIZE else 6)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	parent.add_child(label)
	label.global_position = at + Vector2(-BOX_SIZE.x / 2.0, -32 - (font_size - DEFAULT_FONT_SIZE))


func _ready() -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", -24.0, 0.6).as_relative()
	tween.tween_property(self, "modulate:a", 0.0, 0.6).set_delay(0.2)
	if _font_size > DEFAULT_FONT_SIZE:
		# Nagyobb szöveg: rövid "pukkanás".
		pivot_offset = size / 2.0
		scale = Vector2(1.5, 1.5)
		tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(queue_free)
