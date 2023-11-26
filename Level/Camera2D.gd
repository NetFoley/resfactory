extends Camera2D

var max_zoom :Vector2 = Vector2(1.0,1.0)
var min_zoom : Vector2 = Vector2(1.0,1.0)
var target_zoom : Vector2 = zoom

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position = lerp(position, get_global_mouse_position(), 0.1)
	position = clamp(position, Vector2(limit_left, limit_top), Vector2(limit_right, limit_bottom))
	var maximum = 1.0
	var minimum = min(float(get_viewport().get_visible_rect().size.x)/float(limit_right - limit_left), float(get_viewport().get_visible_rect().size.y)/float(limit_bottom - limit_top))
	min_zoom = Vector2(minimum, minimum)
	max_zoom = Vector2(maximum, maximum)
	print(get_viewport().get_visible_rect().size.x)
	print((limit_right - limit_left))
	print(minimum)
	target_zoom = Vector2(clamp(target_zoom.x, min_zoom.x, max_zoom.x), clamp(target_zoom.y, min_zoom.y, max_zoom.y))
	zoom = lerp(zoom, target_zoom, 0.1)

func _input(event):
	if event.is_action_pressed("unzoom"):
		target_zoom *= 0.9
	elif event.is_action_pressed("zoom"):
		target_zoom *= 1.11
	elif event.is_action_pressed("reset_zoom"):
		target_zoom = Vector2(1,1)
		
