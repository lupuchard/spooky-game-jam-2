extends Control

signal play_pressed

@onready var title: Label = $Title
@onready var play_button: Button = %PlayButton
@onready var credits_button: Button = %CreditsButton

var starting_y: float
var time: float = 0.0
var title_characters: Array[Label] = []

func _ready():
	starting_y = title.position.y
	for i in range(0, title.text.length()):
		var bounds = title.get_character_bounds(i)
		var title_character = title.duplicate()
		add_child(title_character)
		title_character.text = title.text[i]
		title_character.position = title.position + bounds.position
		title_characters.push_back(title_character)
		
	title.hide()
	
	play_button.pressed.connect(func():
		play_button.text = "Resume"
		credits_button.hide()
		play_pressed.emit()
	)

func _process(delta: float):
	if !visible:
		return
	
	time += delta
	for i in range(0, title_characters.size()):
		title_characters[i].position.y = starting_y + sin(time * 5.0 + i) * 2
