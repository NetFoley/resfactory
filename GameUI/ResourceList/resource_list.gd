extends Control

@export_dir var resources_path
@onready var inventory_node : BaseUnit = %Inventory
var shop_anim_timer = Timer.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	var dir = DirAccess.open(resources_path)
	dir.list_dir_begin()
	var next_file = dir.get_next()
	next_file = next_file.trim_suffix('.remap')
	print(dir)
	print(next_file)
	var resources : Array[GameRes] = []
	while next_file:
		print(next_file)
		if next_file.ends_with(".tres"):
			var new_res = load(resources_path + "/" + next_file)
			if new_res is GameRes:
				print("Loaded " + new_res.game_res_name)
				new_res = new_res.duplicate()
				if new_res.price >= 0:
					resources.append(new_res)
		next_file = dir.get_next()
		next_file = next_file.trim_suffix('.remap')
	
	resources.sort_custom(func(a,b): return a.price < b.price)
	
	for r in resources:
		add_res_to_list(r)
	
	%ShowButton.toggled.connect(_on_showbutton_toggled)
	%ShowButton.button_pressed = true
	GAME.res_bought.connect(_on_res_bought)
	inventory_node.res_changed.connect(_on_inventory_changed)
	inventory_node.changed.connect(_on_inventory_changed)
	add_child(shop_anim_timer)
	shop_anim_timer.timeout.connect(_on_shop_anim_timeout)
	
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
	if shop_anim_timer.is_stopped():
		shop_anim_timer.start(0.05)
	for _i in pow(res.quantity, 0.3):
		if icons_to_anim.size() < 100:
			icons_to_anim.append(res.icon_text)
	inventory_node.parent_component.add_component_at(0, res, true)
	_on_inventory_changed()
#	res.set_parent_game_res($ListContainer/TabContainer/Inventory.parent_component)

func _on_shop_anim_timeout():
	anim_text_to_inventory(icons_to_anim.pop_back())
	shop_anim_timer.start(0.02 + randf() * 0.02)
#	await get_tree().create_timer().timeout

var icons_to_anim = []
func anim_text_to_inventory(text : Texture2D):
	if !is_instance_valid(text):
		return
	var t = create_tween()
	var spr = TextureRect.new()
	spr.texture = text
	spr.top_level = true
	spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spr.size = Vector2(50,50)* (randf()*0.5 + 0.5)
	add_child(spr)
	var inv_rect = %TabContainer.get_tab_control(0).get_global_rect()
	inv_rect.size.y -= %Shop.get_global_rect().size.y
	var price_rect = %PriceCont.get_global_rect()
	t.tween_property(spr, "global_position", inv_rect.position + inv_rect.size/2, 1).from(price_rect.position + price_rect.size * randf()).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(func(): spr.queue_free())
	%TabContainer.get_child(0, true).pivot_offset = %TabContainer.get_child(0, true).size/2
	t.tween_property(%TabContainer.get_child(0, true), "scale", Vector2(1.05,1.05), 0.03)
	t.tween_property(%TabContainer.get_child(0, true), "scale", Vector2(1,1), 0.03)
