extends PanelContainer

func _ready():
	GAME.dragged_changed.connect(_on_dragged_changed)
	GAME.res_dragged.connect(_on_res_dragged)
	_on_dragged_changed(false)
	
func _on_dragged_changed(value):
	if !value:
		visible = false
	else:
		update_visual()
	
func _drop_data(_at_position, data):
	var price = data.price * data.quantity
	if price > 0:
		data.set_parent_game_res(null)
		var coins_gave = 0
		while coins_gave < price:
			var coin_res = load("res://GameRes/Resources/coin.tres").duplicate()
			var current_coins = min(coin_res.max_quantity, price-coins_gave)
			coins_gave += current_coins
			coin_res.quantity = current_coins
			GAME.res_bought.emit(coin_res)
		
func _can_drop_data(_at_position, data):
	return data is GameRes
	
func _on_res_dragged(_res: GameRes):
	update_visual()
		
func update_visual():
	var res = GAME.last_dragged_res
	if !res is GameRes or res.price <= 0:
		visible = false
		return false
	%PriceLabel.text = str(res.price * res.quantity)
	visible = true
	return true
	
