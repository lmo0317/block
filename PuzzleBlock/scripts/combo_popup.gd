class_name ComboPopup
extends Node2D
# Clear feedback in the style of Block Blast: a praise word, "Combo N" and the points,
# stacked where the lines cleared and popping in one after another.

const HOLD: float = 0.8
const RISE: float = 60.0

# rows: [{text, size, fill, outline}] from top to bottom
func setup(rows: Array) -> void:
	z_index = 120
	var total_h := 0.0
	for r in rows:
		total_h += r["size"] * 1.12
	var y := -total_h * 0.5
	for i in range(rows.size()):
		var r: Dictionary = rows[i]
		var size: int = r["size"]
		var ls := LabelSettings.new()
		ls.font = UIKit.FONT
		ls.font_size = size
		ls.font_color = r["fill"]
		ls.outline_size = maxi(8, size / 4)
		ls.outline_color = r["outline"]
		ls.shadow_size = 6
		ls.shadow_color = Color(0, 0, 0, 0.55)
		ls.shadow_offset = Vector2(0, 5)
		var l := Label.new()
		l.text = r["text"]
		l.label_settings = ls
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.size = Vector2(640, size * 1.3)
		l.position = Vector2(-320, y - size * 0.09)
		l.pivot_offset = l.size * 0.5
		l.scale = Vector2.ZERO
		l.rotation = deg_to_rad(-7.0 if i % 2 == 0 else 7.0)
		add_child(l)
		y += size * 1.12
		var delay := i * 0.08
		var tw := l.create_tween().set_parallel(true)
		tw.tween_property(l, "scale", Vector2.ONE, 0.3).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(l, "rotation", 0.0, 0.3).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var out := create_tween()
	out.tween_interval(HOLD + rows.size() * 0.08)
	out.tween_property(self, "position:y", position.y - RISE, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	out.parallel().tween_property(self, "modulate:a", 0.0, 0.35)
	out.tween_callback(queue_free)
