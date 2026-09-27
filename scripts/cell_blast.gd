class_name CellBlast
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var particles: CPUParticles2D = $CPUParticles2D

func start_blast(block_texture: Texture2D) -> void:
	if not is_node_ready():
		await ready
	
	sprite.texture = block_texture
	# Flash white
	sprite.modulate = Color(2.5, 2.5, 2.5, 1.0)
	
	particles.emitting = true
	
	var tw = create_tween().set_parallel(true)
	# Pulse up then shrink down
	tw.tween_property(sprite, "scale", Vector2.ONE * 1.25, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(sprite, "scale", Vector2.ZERO, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.3)
	
	var cleanup = create_tween()
	cleanup.tween_interval(0.5)
	cleanup.tween_callback(queue_free)
