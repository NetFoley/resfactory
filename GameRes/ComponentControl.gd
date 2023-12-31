extends Control
class_name ComponentControl

var game_res : GameRes:
	set(value):
		game_res = value
		update_controls()
		if !game_res.changed.is_connected(_on_game_res_changed):
			game_res.changed.connect(_on_game_res_changed)

@onready var components_control = %Components

func update_controls():
	if !is_instance_valid(game_res) or !is_inside_tree():
		return
	%IconText.texture = game_res.icon_text
	%NameLabel.text = game_res.game_res_name
	var t = create_tween()
	t.tween_property(%QuantityBar, "value", game_res.quantity, 0.2).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN_OUT)
#	%QuantityBar.value = game_res.quantity
	%QuantityBar.max_value = game_res.max_quantity
	%QuantityBar/Label.text = str(round(game_res.quantity)) + "/" + str(round(game_res.max_quantity))
	%BufferBar.value = game_res.buffered_time

	#Add components control
	for component in game_res.components:
		if !is_instance_valid(component):
			continue
		var control = component.get_control()
		if !is_instance_valid(control):
			printerr("Returned control of component is invalid")
			game_res.components.erase(component)
			continue
		if is_instance_valid(control.get_parent()):
			if !control.get_parent() == components_control:
				control.get_parent().remove_child(control)
				components_control.add_child(control)
			else:
				var new_pos = game_res.components.find(component)
				if new_pos >= GAME.preview_control_child_index:
					new_pos += 1
				if new_pos >= 0:
					components_control.move_child(control,new_pos)
		else:
			components_control.add_child(control)

@onready var last_control = %LastControl
var is_enabled = true
			
var can_be_dragged = true:
	set(value):
		can_be_dragged = value
		if value:
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		else:
			mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
	

func _on_child_order_changed():
	if is_instance_valid(components_control):
		components_control.call_deferred("move_child", last_control,-1)
	
func _ready():
	components_control.child_order_changed.connect(_on_child_order_changed)
	%InfoButton.toggled.connect(_on_info_toggled)
	update_infos()
	mouse_exited.connect(func():modulate = Color(1,1,1))
	play_spawn_anim()
	update_controls()
	%ComponentPanel.theme_type_variation = theme_type_variation

#func _enter_tree():
#	$AnimationPlayer.stop()
#	$AnimationPlayer.play("Spawning")

func _on_info_toggled(value):
	%Infos.visible = value
	update_infos()

func update_infos():
	if !is_instance_valid(game_res):
		return
	%InfoButton.visible = !game_res.transformations.is_empty()
	for c in %Infos.get_children():
		c.queue_free()
		
	for t in game_res.transformations:
		var transfo = HBoxContainer.new()
		transfo.alignment = BoxContainer.ALIGNMENT_CENTER
		var input_labels = VBoxContainer.new()
		for input in t.input_res:
			var cont = HBoxContainer.new()
			cont.mouse_default_cursor_shape = Control.CURSOR_HELP
			cont.tooltip_text = input.game_res.game_res_name
			var label = Label.new()
			var icon_text = TextureRect.new()
			icon_text.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon_text.texture = input.game_res.icon_text
			label.text = str(input.ratio)
			cont.add_child(label)
			cont.add_child(icon_text)
			input_labels.add_child(cont)
		transfo.add_child(input_labels)
		
		var arrow_label = Label.new()
		arrow_label.text += " > " 
		transfo.add_child(arrow_label)
		
		var output_cont = VBoxContainer.new()
		if is_instance_valid(t.output_res):
			var cont = HBoxContainer.new()
			cont.size_flags_vertical = SIZE_SHRINK_CENTER
			cont.tooltip_text = t.output_res.game_res_name
			cont.mouse_default_cursor_shape = Control.CURSOR_HELP
			var label = Label.new()
			var icon_text = TextureRect.new()
			icon_text.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon_text.texture = t.output_res.icon_text
			label.text = str(t.ratio)
			cont.add_child(label)
			cont.add_child(icon_text)
			output_cont.add_child(cont)
		transfo.add_child(output_cont)
		
		%Infos.add_child(transfo)

func _on_game_res_changed():
	update_controls()

func add_control_to_my_info(control : Control):
	%MyInfo.add_child(control)

func _get_drag_data(_at_position):
	if !can_be_dragged:
		return null
	GAME.res_dragged.emit(game_res)
	var preview = Control.new()
	var self_preview = duplicate(0)
#	self_preview.scale *= 0.5
	preview.add_child(self_preview)
	preview.modulate.a *= 0.35
	set_drag_preview(preview)
#	self_preview.position = get_global_mouse_position() - preview.global_position - at_position * self_preview.scale.x
	self_preview.position = get_global_mouse_position() - preview.global_position  * self_preview.scale.x
	return game_res

func _drop_data(at_position, data):
	if data is GameRes:
		if GAME.should_mix:
			game_res.mix_components(data, game_res)
#			game_res.parent_game_res.add_component_at(game_res.parent_game_res.components.find(game_res), data, true)
		else:
			game_res.add_component_at(GAME.preview_control_child_index, data)
#		data.set_parent_game_res(game_res)
	GAME.can_drop_started.emit(null)
	update_controls()


func _can_drop_data(at_position, data):
	if !can_be_dragged:
		return false
	if data != game_res and !game_res.is_inside(data):
		var closest_pos = GAME.get_closest_child_index_at_pos(components_control, at_position)
		if at_position.y > min(get_rect().size.y/2, get_rect().size.y - %Components.get_rect().size.y):
			GAME.can_drop_started.emit(components_control, closest_pos)
			GAME.should_mix = false
		else:
			GAME.can_drop_started.emit(null)
			GAME.should_mix = true
		if GAME.should_mix:
			modulate = Color(1.4,1.4,1.4)
		else:
			modulate = Color(1,1,1)
			
		return true
	return false

var anim_size_factor = 1.0
func _process(delta):
	%SizeController.custom_minimum_size = %ComponentControl.size * (anim_size_factor)
	%SizeController.pivot_offset = %SizeController.size/2
#	pivot_offset = size/2
	if !is_instance_valid(game_res):
		if !Engine.is_editor_hint():
			queue_free()
		return
		
	if !is_enabled:
		return

	game_res._process(delta)
	%BufferBar.value = game_res.buffered_time

var tIn : Tween
func play_spawn_anim():
	if is_inside_tree():
		if is_instance_valid(tOut):
			tOut.kill()
		tIn = get_tree().create_tween()
		tIn.set_parallel()
		tIn.tween_property(self, "anim_size_factor", 1.0, 0.2).from(0.0).set_trans(Tween.TRANS_QUAD)
#		t.tween_property(self, "custom_minimum_size", start_size, 0.3).from(Vector2(0,0)).set_trans(Tween.TRANS_QUAD)
		
var tOut : Tween
func play_leave_anim():
	if is_inside_tree():
		if is_instance_valid(tIn):
			tIn.kill()
		tOut = get_tree().create_tween()
		tOut.set_parallel()
		tOut.tween_property(self, "anim_size_factor", 0.0, 0.2).set_trans(Tween.TRANS_QUAD)
#		t.tween_property(self, "custom_minimum_size", Vector2(0,0), 0.3).set_trans(Tween.TRANS_QUAD)
		tOut.set_parallel(false)
		tOut.tween_callback(func():queue_free())
