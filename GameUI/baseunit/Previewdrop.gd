extends PanelContainer
class_name PreviewDrop

var start_size = custom_minimum_size
var is_animating = false

func _init():
	GAME.target_parent_changed.connect(_on_target_parent_changed)
	
func _on_tIn_finished():
	is_animating = false
	_update_anim()
	
func _on_tOut_finished():
	if is_instance_valid(get_parent()):
		get_parent().remove_child(self)
	is_animating = false
	_update_anim()
	
func _on_target_parent_changed(_c):
	_update_anim()
	
func _update_anim():
	if is_animating:
		return
	if GAME.preview_control_child_index == get_index() and get_parent() == GAME.target_parent:
		return
	if is_instance_valid(get_parent()):
		play_leave_anim()
		return
	if !is_instance_valid(GAME.target_parent):
		play_leave_anim()
		return
	GAME.target_parent.add_child(self)
	GAME.target_parent.move_child(self, GAME.preview_control_child_index)
	play_spawn_anim()
		
var anim_dur = 0.05
func play_spawn_anim():
	if is_inside_tree():
		is_animating = true
		var tIn = get_tree().create_tween()
		tIn.finished.connect(_on_tIn_finished)
		tIn.set_parallel()
		tIn.tween_property(self, "scale", Vector2(1,1), anim_dur).from(Vector2(0,0)).set_trans(Tween.TRANS_QUAD)
		tIn.tween_property(self, "custom_minimum_size", start_size, anim_dur).from(Vector2(0,0)).set_trans(Tween.TRANS_QUAD)
	
func play_leave_anim():
	if is_inside_tree():
		is_animating = true
		var tOut = get_tree().create_tween()
		tOut.finished.connect(_on_tOut_finished)
		tOut.set_parallel()
		tOut.tween_property(self, "scale", Vector2(0,0), anim_dur).set_trans(Tween.TRANS_QUAD)
		tOut.tween_property(self, "custom_minimum_size", Vector2(0,0), anim_dur).set_trans(Tween.TRANS_QUAD)
