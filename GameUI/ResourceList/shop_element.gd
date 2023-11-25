extends HBoxContainer

signal button_pressed()

var price = 1:
	set(value):
		price = value
		%Button.text = str(value)

func _ready():
	%Button.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	button_pressed.emit()
