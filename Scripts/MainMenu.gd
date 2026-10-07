extends Control

signal play_pressed

@onready var title: Label = $Title
@onready var play_button: Button = %PlayButton
@onready var settings_button: Button = %SettingsButton
@onready var credits_button: Button = %CreditsButton

@onready var settings_panel := %SettingsPanel
@onready var credits_panel := %CreditsPanel

@onready var volume_slider := %VolumeSlider
@onready var jumpscares_on_button: Button = %JumpscaresOnButton
@onready var jumpscares_off_button: Button = %JumpscaresOffButton

@onready var menu_ambience := %MenuAmbience

@onready var master_volume_index := AudioServer.get_bus_index("Master")

var starting_y: float
var time: float = 0.0
var title_characters: Array[Label] = []

func _ready() -> void:
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
		menu_ambience.stop()
		save_settings()
	)
	
	settings_panel.hide()
	credits_panel.hide()
	
	settings_button.toggled.connect(func(on): 
		settings_panel.visible = on
		if !on:
			save_settings()
	)
	credits_button.toggled.connect(func(on): credits_panel.visible = on)
	
	volume_slider.value = 1.0
	volume_slider.value_changed.connect(func(_value): update_volume())
	
	load_settings()
	
	show()

func show_menu() -> void:
	menu_ambience.play()
	show()

func _process(delta: float) -> void:
	if !visible:
		return
	
	time += delta
	for i in range(0, title_characters.size()):
		title_characters[i].position.y = starting_y + sin(time * 5.0 + i) * 2

func save_settings() -> void:
	var settings = {
		volume = volume_slider.value,
		jumpscares = jumpscares_on_button.button_pressed
	}
	
	var save_file = FileAccess.open("user://settings.save", FileAccess.WRITE)
	var json_string = JSON.stringify(settings)
	save_file.store_line(json_string)

func load_settings() -> void:
	if !FileAccess.file_exists("user://settings.save"):
		return
	
	var save_file = FileAccess.open("user://settings.save", FileAccess.READ)
	var json_string = save_file.get_line()
	var json = JSON.new()
	json.parse(json_string)
	
	volume_slider.value = json.data.volume
	jumpscares_on_button.button_pressed = json.data.jumpscares
	update_volume()

func jumpscares_on() -> bool:
	return jumpscares_on_button.button_pressed

func update_volume() -> void:
	AudioServer.set_bus_volume_linear(master_volume_index, pow(volume_slider.value, 2))
