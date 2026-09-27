class_name FloatingText
extends Node2D

@onready var label: Label = $Label

func setup(text: String, text_color: Color = Color.WHITE, scale_mult: float = 1.0) -> void:
	if not is_node_ready():
		await ready
	
	label.text = text
	label.modulate = text_color
	scale = Vector2.ONE * 0.4
	modulate.a = 0.0
	
	var tw = create_tween().set_parallel(true)
	# Scale punch
	tw.tween_property(self, "scale", Vector2.ONE * (1.1 * scale_mult), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.12)
	# Float upward
	tw.tween_property(self, "position:y", position.y - 70.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Fade out near the end
	var tw_fade = create_tween()
	tw_fade.tween_interval(0.45)
	tw_fade.tween_property(self, "modulate:a", 0.0, 0.3)
	tw_fade.tween_callback(queue_free)
