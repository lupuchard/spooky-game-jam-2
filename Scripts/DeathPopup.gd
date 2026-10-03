extends PanelContainer

@onready var death_text := %DeathText
@onready var restart_button := %RestartButton

func _ready():
	hide()

func show_death(text: String):
	death_text.text = text
	show()
