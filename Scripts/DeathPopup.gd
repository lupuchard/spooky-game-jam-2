extends PanelContainer

signal restart_pressed

@onready var death_text := %DeathText
@onready var restart_button := %RestartButton

func _ready():
	hide()
	restart_button.pressed.connect(func(): restart_pressed.emit())

func show_death(text: String):
	death_text.text = text
	show()
