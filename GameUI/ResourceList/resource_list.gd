extends Control

@export_dir var resources_path
@onready var inventory_node : BaseUnit = %Inventory

# Called when the node enters the scene tree for the first time.
func _ready():
	var dir = DirAccess.open(resources_path)
	dir.list_dir_begin()
	var next_file = dir.get_next()
	print(dir)
	while next_file:
		if next_file.ends_with(".tres"):
			var new_res = load(resources_path + "/" + next_file)
			if new_res is GameRes:
				print("Loaded " + new_res.game_res_name)
				new_res = new_res.duplicate()
				if new_res.price >= 0:
					add_res_to_list(new_res)
		next_file = dir.get_next()
	%ShowButton.toggled.connect(_on_showbutton_toggled)
	%ShowButton.button_pressed = true
	GAME.res_bought.connect(_on_res_bought)
	inventory_node.res_changed.connect(_on_inventory_changed)
	inventory_node.changed.connect(_on_inventory_changed)
	
func _on_inventory_changed():
	var comp : GameRes = inventory_node.parent_component
	if is_instance_valid(comp):
		var coins = comp.get_components_with_name("Coin")
		var qty = 0
		for coin in coins : qty += coin.quantity
		%MoneyAmount.text = str(qty)

func add_res_to_list(res : GameRes):
	var control = res.get_control()
	var shop_element = preload("res://GameUI/ResourceList/shop_element.tscn").instantiate()
	control.set_theme_type_variation("ShopPanel")
	var shop_control = HBoxContainer.new()
#	control.alignment = BoxContainer.ALIGNMENT_CENTER
	control.size_flags_horizontal = Control.SIZE_EXPAND
#	control.size_flags_vertical = Control.SIZE_EXPAND
	%ShopList.add_child(HSeparator.new())
	shop_element.add_child(control)
	shop_element.price = res.price
	shop_element.button_pressed.connect(_on_buy_pressed.bind(res))
	shop_control.add_child(shop_element)
	res.quantity = 1
	shop_control.scale = Vector2(0.5,0.5)
	control.is_enabled = false
	control.can_be_dragged = false
	%ShopList.add_child(shop_control)
#	%List.add_child(HSeparator.new())

func _on_buy_pressed(res : GameRes):
	var coins = inventory_node.parent_component.get_components_with_name("Coin")
	var total_coins = 0
	var price_to_pay = res.price * res.quantity
	for c in coins:
		total_coins += c.quantity
	if total_coins < price_to_pay:
		return
	for c in coins:
		var chg = c.add_quantity(-price_to_pay)
		price_to_pay += chg
		print(chg)
		print(price_to_pay)
	if price_to_pay > 0:
		return
	GAME.res_bought.emit(res.duplicate(true))

func _on_showbutton_toggled(toggle):
	if toggle:
		position.x += %ListContainer.size.x
		%ShowButton.text = "<"
	else:
		position.x-= %ListContainer.size.x
		%ShowButton.text = ">"
		
func _on_res_bought(res : GameRes):
	inventory_node.parent_component.add_component_at(0, res, true)
	_on_inventory_changed()
#	res.set_parent_game_res($ListContainer/TabContainer/Inventory.parent_component)
