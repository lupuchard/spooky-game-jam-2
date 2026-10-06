extends PanelContainer

signal continue_pressed

@onready var survive_text := %SurviveText
@onready var continue_button := %ContinueButton

func _ready():
	hide()
	continue_button.pressed.connect(func(): 
		hide()
		continue_pressed.emit()
	)

func show_survive(text: String):
	survive_text.text = text
	show()
