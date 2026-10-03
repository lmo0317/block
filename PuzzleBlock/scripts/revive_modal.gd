class_name ReviveModal
extends ColorRect

signal revive_accepted
signal revive_declined

@onready var card: Panel = $Card
@onready var countdown_label: Label = $Card/CountdownLabel
@onready var progress_bar: ProgressBar = $Card/ProgressBar
@onready var btn_revive: Button = $Card/BtnRevive
@onready var btn_skip: Button = $Card/BtnSkip

var remaining_time: float = 5.0
const TOTAL_TIME: float = 5.0
var is_active: bool = false

func _ready() -> void:
	visible = false
	UIKit.style_modal_backdrop(self)
	UIKit.style_modal(card, $Card/Title, $Card/Subtitle)
	UIKit.style_button(btn_revive, "primary", 24, 18)
	UIKit.style_button(btn_skip, "ghost", 20, 18)
	progress_bar.add_theme_stylebox_override("background", UIKit.box(UIKit.SURFACE_HI, Color.TRANSPARENT, 6))
	progress_bar.add_theme_stylebox_override("fill", UIKit.box(UIKit.CYAN, Color.TRANSPARENT, 6))
	btn_revive.pressed.connect(_on_revive_pressed)
	btn_skip.pressed.connect(_on_skip_pressed)

func open() -> void:
	visible = true
	is_active = true
	remaining_time = TOTAL_TIME
	_update_ui()
	
	card.scale = Vector2.ONE * 0.7
	card.modulate.a = 0.0
	var tw = create_tween().set_parallel(true)
	tw.tween_property(card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate:a", 1.0, 0.15)
	
	SoundManager.play("invalid", 1.2, 2.0)

func close() -> void:
	is_active = false
	var tw = create_tween().set_parallel(true)
	tw.tween_property(card, "scale", Vector2.ONE * 0.8, 0.15)
	tw.tween_property(card, "modulate:a", 0.0, 0.15)
	tw.chain().tween_callback(func(): visible = false)

func _process(delta: float) -> void:
	if not is_active:
		return
		
	remaining_time -= delta
	_update_ui()
	
	if remaining_time <= 0.0:
		is_active = false
		revive_declined.emit()
		close()

func _update_ui() -> void:
	var sec_int = int(ceil(max(0.0, remaining_time)))
	countdown_label.text = str(sec_int)
	progress_bar.value = (remaining_time / TOTAL_TIME) * 100.0

func _on_revive_pressed() -> void:
	if not is_active:
		return
	is_active = false
	SoundManager.play_click()
	revive_accepted.emit()
	close()

func _on_skip_pressed() -> void:
	if not is_active:
		return
	is_active = false
	SoundManager.play_click()
	revive_declined.emit()
	close()
