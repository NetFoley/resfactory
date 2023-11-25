extends BaseUnit

# Called when the node enters the scene tree for the first time.
func update_control():
	super.update_control()
	set_deferred("name", "Inventory (" + str(parent_component.components.size()) + ")")
