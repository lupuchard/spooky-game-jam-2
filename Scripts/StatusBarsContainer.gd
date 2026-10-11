extends PanelContainer

@onready var fatigue_bar := %FatigueBar
@onready var hunger_bar := %HungerBar
@onready var health_bar := %HealthBar

@onready var fatigue_icon := %FatigueIcon
@onready var hunger_icon := %HungerIcon
@onready var health_icon := %HealthIcon

@onready var heart1 := %LivesList/Heart1
@onready var heart2 := %LivesList/Heart2
@onready var heart3 := %LivesList/Heart3

@onready var health_texture: Texture2D = preload("res://Assets/icons/health_icon.png")
@onready var health_down_texture: Texture2D = preload("res://Assets/icons/health_icon_down.png")

@onready var heart_texture1: Texture2D = preload("res://Assets/icons/heart1.png")
@onready var heart_texture2: Texture2D = preload("res://Assets/icons/heart2.png")
@onready var heart_texture3: Texture2D = preload("res://Assets/icons/heart3.png")
@onready var heart_texture_empty: Texture2D = preload("res://Assets/icons/heart_empty.png")

func _ready():
	%LivesList.hide()

func update(fatigue: float, hunger: float, unhealth: float):
	fatigue_bar.value = 1.0 - fatigue
	hunger_bar.value = 1.0 - hunger
	health_bar.value = 1.0 - unhealth
	
	if fatigue <= 0.0:
		fatigue_icon.modulate = Color.RED
		health_icon.texture = health_down_texture
	else:
		fatigue_icon.modulate = Color.WHITE
		health_icon.texture = health_texture

func update_lives(lives: int, hard_mode: bool):
	heart3.visible = !hard_mode
	%LivesList.visible = !(lives >= 3 || (hard_mode && lives >= 2))
	
	if lives >= 3:
		heart1.texture = heart_texture1
		heart2.texture = heart_texture1
		heart3.texture = heart_texture1
	elif lives == 2:
		heart1.texture = heart_texture1
		heart2.texture = heart_texture2
		heart3.texture = heart_texture_empty
	elif lives == 1:
		heart1.texture = heart_texture3
		heart2.texture = heart_texture_empty
		heart3.texture = heart_texture_empty
	elif lives <= 0:
		heart1.texture = heart_texture_empty
		heart2.texture = heart_texture_empty
		heart3.texture = heart_texture_empty
