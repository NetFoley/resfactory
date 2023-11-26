extends Control

#func _ready():
#	resized.connect(_on_resized)
	
func _physics_process(delta):
	if GAME.is_dragging:
		return
	var rect = $BaseUnit.get_rect()
	get_viewport().get_camera_2d().limit_left = rect.position.x
	get_viewport().get_camera_2d().limit_right = rect.position.x + rect.size.x
	get_viewport().get_camera_2d().limit_top = rect.position.y
	get_viewport().get_camera_2d().limit_bottom = rect.position.y+ rect.size.y
