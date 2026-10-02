class_name DragScroll
extends Node
# Drag-to-scroll for a ScrollContainer full of buttons (touch or mouse).
# Buttons grab the press, so the container never sees the drag. This watches input before the GUI:
# once the pointer moves past THRESHOLD it scrolls, cancels the pressed button with a release
# outside the screen, and swallows the rest of the gesture so no click fires.
# Usage: DragScroll.attach(scroll_container)

const THRESHOLD: float = 12.0
const OFFSCREEN: Vector2 = Vector2(-10000, -10000)

var scroll: ScrollContainer
var tracking: bool = false
var dragging: bool = false
var start_pos: Vector2
var start_scroll: int

static func attach(target: ScrollContainer) -> DragScroll:
	var d := DragScroll.new()
	d.scroll = target
	target.add_child(d)
	return d

func _input(event: InputEvent) -> void:
	if scroll == null or not scroll.is_visible_in_tree():
		tracking = false
		dragging = false
		return

	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.position.x < OFFSCREEN.x * 0.5:
		return # our own cancel events from _cancel_pressed_button()
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			tracking = scroll.get_global_rect().has_point(event.position)
			dragging = false
			start_pos = event.position
			start_scroll = scroll.scroll_vertical
		elif tracking:
			tracking = false
			if dragging:
				dragging = false
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and tracking:
		var dy: float = event.position.y - start_pos.y
		if not dragging and absf(dy) > THRESHOLD:
			dragging = true
			_cancel_pressed_button()
		if dragging:
			scroll.scroll_vertical = start_scroll - int(dy)
			get_viewport().set_input_as_handled()

func _cancel_pressed_button() -> void:
	# The button decides "clicked" from where it last saw the pointer, so first move the pointer
	# off-screen (the button now thinks it left), then release there: the press ends without a click
	var away := InputEventMouseMotion.new()
	away.position = OFFSCREEN
	away.global_position = OFFSCREEN
	away.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(away)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = OFFSCREEN
	up.global_position = OFFSCREEN
	get_viewport().push_input(up)
