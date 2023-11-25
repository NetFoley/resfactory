extends Control
class_name BaseUnit

@export var process_components = true
@export var parent_component : GameRes:
	set(value):
		parent_component = value
		parent_component.changed.connect(update_control)
#		_on_parent_component_changed.call_deferred()
		
@export var parent_control : Control
@onready var last_control = %LastControl

signal changed()
signal res_changed()

func _ready():
	parent_control.child_order_changed.connect(_on_child_order_changed)

func _on_child_order_changed():
	parent_control.call_deferred("move_child", last_control,-1)

func _enter_tree():
	for c in parent_component.components:
		if is_instance_valid(c):
			c.parent_game_res = parent_component
		else:
			parent_component.components.erase(c)
	update_control()

func update_control():
	#Add components control
	for component in parent_component.components:
		if !is_instance_valid(component):
			continue
		var control = component.get_control()
		control.is_enabled = process_components
		if !is_instance_valid(control):
			printerr("Returned control of component is invalid")
			parent_component.components.erase(component)
			continue
		if is_instance_valid(control.get_parent()):
			if !control.get_parent() == parent_control:
				control.get_parent().remove_child(control)
				parent_control.add_child(control)
			else:
				var new_pos = parent_component.components.find(component)
				if new_pos >= GAME.preview_control_child_index:
					new_pos += 1
				if new_pos >= 0:
					parent_control.move_child(control,new_pos)
		else:
			var new_pos = parent_component.components.find(component)
			if new_pos >= GAME.preview_control_child_index:
				new_pos += 1
			parent_control.add_child(control)
			parent_control.move_child(control, new_pos)
	changed.emit()

#	update_control()

#func _process(delta):
#	preview_control_drop.visible = false

#func _on_parent_component_changed():
#	for c in parent_component.components:
#		if is_instance_valid(c) and !c.is_connected("changed", _on_res_changed):
#			c.changed.connect(_on_res_changed)
#	res_changed.emit()
#
#func _on_res_changed():
#	res_changed.emit()
	
# Called when the node enters the scene tree for the first time.
func _can_drop_data(at_position : Vector2, data):
	if !data is GameRes:
		return false
	var closest_pos = GAME.get_closest_child_index_at_pos(parent_control, at_position)
	GAME.can_drop_started.emit(parent_control, closest_pos)
	return true

func _drop_data(at_position, data):
	if data is GameRes:
		data.get_control().is_enabled = process_components
	parent_component.add_component_at(GAME.preview_control_child_index, data)
	GAME.can_drop_started.emit(null)
#	data.get_control().position = at_position
	update_control.call_deferred()
