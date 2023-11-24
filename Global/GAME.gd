extends Node

signal can_drop_started(node : Control, position:int)

signal dragged_changed(value : bool)
signal target_parent_changed(value : Control)

var target_parent : Control:
	set(value):
		target_parent = value
		target_parent_changed.emit(value)
		
var should_mix = false
var preview_control_drop : Control
var preview_control_child_index = 0
var is_dragging = false:
	set(value):
		is_dragging = value
		dragged_changed.emit(value)

func _ready():
	can_drop_started.connect(_on_can_drop_started)
	
func _on_can_drop_started(node, pos = -1):
	set_new_preview_parent(node, pos)

func set_new_preview_parent(parent : Control, pos : int):
	if !is_instance_valid(preview_control_drop):
		preview_control_drop = preload("res://baseunit/Previewdrop.tscn").instantiate()
	if parent == target_parent and pos == preview_control_child_index:
		return
#
#	if pos < 0 or !is_instance_valid(parent):
#		preview_control_drop.play_leave_anim()
##		if is_instance_valid(preview_control_drop.get_parent()):
##			preview_control_drop.get_parent().remove_child(preview_control_drop)
#		return
		
	print(parent, pos)
	
#	if is_instance_valid(preview_control_drop.get_parent()):
#		preview_control_drop.play_leave_anim()
#		parent.add_child(preview_control_drop)
##		preview_control_drop.reparent(parent)
#	else:
#		parent.add_child(preview_control_drop)
#	parent.move_child(preview_control_drop, pos)
#	preview_control_drop.play_spawn_anim()
	preview_control_child_index = pos
	target_parent = parent
	
func get_closest_child_index_at_pos(control : Control, at_position):
	var offset_pos = Vector2.ZERO
	var closest_pos = 0
	var shortest_dist = 9999999999
	var index_offset = 0
#	print(control.get_children())
	for i in control.get_child_count():
		var c : Control = control.get_child(i)
		if c is PreviewDrop:
			index_offset-=1
#			offset_pos += c.size*1.5
			continue
		var control_pos = c.global_position- offset_pos
#		var at_global_position : Vector2 = at_position
		var at_global_position : Vector2 = at_position + control.global_position
		if shortest_dist > at_global_position.distance_to(control_pos):
			closest_pos = i + index_offset
#			if offset_pos != Vector2.ZERO:
#				closest_pos -= 1
			shortest_dist = at_global_position.distance_to(control_pos)
	return closest_pos

func _notification(notification):
	if notification == NOTIFICATION_DRAG_BEGIN:
		is_dragging = true
	elif notification == NOTIFICATION_DRAG_END:
		is_dragging = false
		_on_can_drop_started(null)
