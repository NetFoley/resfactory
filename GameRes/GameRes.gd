extends Resource
class_name GameRes
		
@export var max_quantity : int = 10:
	set(value):
		max_quantity = value
		emit_changed()

@export var quantity : int = 1:
	set(value):
		quantity = value
		if quantity <= 0:
			set_parent_game_res(null)
		elif quantity > max_quantity:
			quantity = max_quantity
		emit_changed()

@export var game_res_name : String :
	set(value):
		game_res_name = value
		emit_changed()
		
@export var icon_text : Texture2D:
	set(value):
		icon_text = value
		emit_changed()
#@export_file("*.tscn") var control_node

var parent_game_res : GameRes:
	set(value):
		parent_game_res = value
		emit_changed()
		
@export var components : Array[GameRes]:
	set(value):
		components = value
		emit_changed()
		
var components_control : ComponentControl = preload("res://GameRes/ComponentControl2.tscn").instantiate()

@export var tooltip = "":
	set(value):
		tooltip = value
		if is_instance_valid(components_control) and tooltip is String:
			components_control.tooltip_text = tooltip
			
@export var transformations : Array[Transformation]

var can_process = true

func _init():
	GAME.dragged_changed.connect(func(value): can_process = !value)

func get_control() -> Control:
	if is_instance_valid(components_control):
		components_control.game_res = self
			
	return components_control

func get_energy_qty():
	var energy_comp = get_energy_comp()
	if !is_instance_valid(energy_comp):
		return 0
		
	return energy_comp.quantity
	
func get_energy_comp() -> GameRes:
	var energy_comp = get_component_at(components.size()-1)
	if  !is_instance_valid(energy_comp) or energy_comp.game_res_name != "Energy":
		return null
		
	return energy_comp
	

var buffered_time = 0.0
func _process(delta):
	if Engine.is_editor_hint():
		return
	if !can_process:
		return
	_process_transform(delta)
		
func _process_transform(delta : float):
	var comp = get_component_with_relative_pos(-1)
	var comp_name = "null"
	if is_instance_valid(comp):
		comp_name = comp.game_res_name
		
	var current_transformation : Transformation
	var output_res : GameRes
	for t in transformations:
		if !is_instance_valid(t.input_res):
			comp = null
			output_res = t.output_res.duplicate(true)
			current_transformation = t
			break
		
			
		elif t.input_res.game_res_name == "Anything" or t.input_res.game_res_name == comp_name:
			output_res = t.output_res.duplicate(true)
			current_transformation = t
			break
			
	if !is_instance_valid(output_res):
		buffered_time = 0.0
		return
			
	if get_energy_qty() < current_transformation.energy_needed:
		buffered_time = 0.0
		return
	
			
	buffered_time += delta * quantity / current_transformation.duration
	
	var transformed_qty = int(buffered_time)
		
	if transformed_qty >= 1:
		var qty_chg = 0
		
		var next_comp : GameRes = get_component_with_relative_pos(1)
		if output_res.game_res_name == "MoveOutside":
			if !is_instance_valid(comp) or comp.components.size() > 0:
				return
			output_res = comp.duplicate(true)
			output_res.parent_game_res = null
			output_res.quantity = 1
			qty_chg= parent_game_res.add_component_to_relative_pos(1, output_res, true)
			
		elif output_res.game_res_name == "MoveInside":
			if !is_instance_valid(comp) or comp.components.size() > 0:
				return
			output_res = comp.duplicate(true)
			output_res.parent_game_res = null
			output_res.quantity = 1
			if is_instance_valid(next_comp):
				qty_chg=get_component_with_relative_pos(1).add_component_at(0, output_res, true)
			
		else:
			if is_instance_valid(output_res.parent_game_res):
				output_res.parent_game_res = null
			output_res.quantity = transformed_qty * max(1,current_transformation.ratio)
			if !is_instance_valid(next_comp) or next_comp.game_res_name == output_res.game_res_name and next_comp.is_full():
				qty_chg = add_component_to_relative_pos(1, output_res, true)
			
		if qty_chg < transformed_qty:
			buffered_time = 0.0
		if is_instance_valid(comp):
			comp.quantity -= qty_chg/ current_transformation.ratio
		buffered_time -= qty_chg/ max(1,current_transformation.ratio)
		var energy_comp = get_energy_comp()
		if is_instance_valid(energy_comp):
			energy_comp.quantity -= qty_chg * current_transformation.energy_needed

func is_full():
	return quantity < max_quantity
	
		
func is_inside(game_res):
	if !is_instance_valid(game_res) or !is_instance_valid(parent_game_res):
		return false
		
	if parent_game_res == game_res or parent_game_res.is_inside(game_res):
		return true
#	for c in game_res.components:
#		if  c == self or is_inside(c):
#			return true
			
	return false

func set_parent_game_res(new_parent_gr: GameRes, pos = -1):
	if is_instance_valid(parent_game_res):
		parent_game_res.components.erase(self)
		parent_game_res.emit_changed()
	
	if is_instance_valid(new_parent_gr):
		if pos < 0 or pos >= new_parent_gr.components.size():
			new_parent_gr.components.append(self)
		else:
			new_parent_gr.components.insert(pos, self)
		new_parent_gr.emit_changed()
			
	parent_game_res = new_parent_gr
	if !is_instance_valid(parent_game_res):
		if is_instance_valid(components_control):
			components_control.play_leave_anim()
	else:
		components_control.play_spawn_anim()

func get_component_at(pos : int) -> GameRes:
	if pos < 0 or components.size() <= pos or !is_instance_valid(components[pos]):
		return null
	
	return components[pos]
	
func add_component_at(pos : int, component : GameRes, mix = false) -> int:
	var qty_change = 0
	var current_pos = components.find(component)
#	var next_pos = pos
	if current_pos > -1:
		if current_pos < pos:
			pos -= 1
#		elif current_pos == pos:
#			next_pos += 1
	
	if mix:
		var next_comp = get_component_at(pos)
		var previous_comp = get_component_at(pos-1)
		if next_comp != component and is_instance_valid(next_comp):
			qty_change += mix_components(component,  next_comp)
		if next_comp != component and (is_instance_valid(previous_comp)):
			qty_change += mix_components(component,  previous_comp)
			
	if (component.quantity > 0):
		component.set_parent_game_res(self, pos)
#		qty_change += component.quantity
	
	return qty_change
		
func mix_components(component: GameRes, new_comp : GameRes):
	var qty_change = 0
	if !is_instance_valid(component) or !is_instance_valid(new_comp):
		return qty_change
	if new_comp.game_res_name == component.game_res_name:
		qty_change = new_comp.add_quantity(component.quantity)
		component.add_quantity(-qty_change)
#		if component.quantity > 0:
#			component.set_parent_game_res(self, pos)
#	else:
#		if component.quantity > 0:
#			component.set_parent_game_res(self, pos)
#			qty_change = component.quantity
		
	return qty_change
		
func add_quantity(value) -> float:
	var old_qty = quantity
	quantity += value
	var qty_change = quantity - old_qty
	return qty_change

func get_component_with_relative_pos(relative_pos : int):
	if !is_instance_valid(parent_game_res):
		return null
	
	var self_pos = parent_game_res.components.find(self)
	var true_pos = self_pos + relative_pos
	
	return parent_game_res.get_component_at(true_pos)

func add_component_to_relative_pos(relative_pos : int, comp : GameRes, mix = false) -> int:
	if !is_instance_valid(parent_game_res):
		return 0
	
	var self_pos = parent_game_res.components.find(self)
	var true_pos = self_pos + relative_pos
		
	return parent_game_res.add_component_at(true_pos, comp, mix)
