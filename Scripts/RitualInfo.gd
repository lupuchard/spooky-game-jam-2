class_name RitualInfo
extends VBoxContainer

signal ritual_button_pressed
signal ritual_button_released

@export var stone_sound: AudioStreamPlayer2D
@export var tinder_sound: AudioStreamPlayer2D
@export var sacrifice_sound: AudioStreamPlayer2D
@export var fire_sound: AudioStreamPlayer2D

@onready var dig_req_label: RitualRequirementLabel = $RitualDigReqLabel
@onready var stone_req_label: RitualRequirementLabel = $RitualStoneReqLabel
@onready var tinder_req_label: RitualRequirementLabel = $RitualTinderReqLabel
@onready var sacrifice_req_label: RitualRequirementLabel = $RitualSacrificeReqLabel
@onready var ritual_button := $RitualButton
@onready var ritual_progress = $RitualButton/RitualProgress

@onready var ritual_sprites: Array[Node2D] = [
	$Stone4,
	$Stone3,
	$Stone2,
	$Stone1,
	$Stone5,
	$Tinder,
	$Sacrifice,
	$Fire
]

@onready var ritual_sounds: Array[AudioStreamPlayer2D] = [
	stone_sound,
	stone_sound,
	stone_sound,
	stone_sound,
	stone_sound,
	tinder_sound,
	sacrifice_sound,
	fire_sound
]

func _ready():
	hide()
	hide_ritual_items()
	ritual_progress.value = 0.0
	
	ritual_button.button_down.connect(func(): ritual_button_pressed.emit())
	ritual_button.button_up.connect(func(): ritual_button_released.emit())

var current_progress: float = 0.0
var ritual_enabled := true
var num_papers := 0
var num_stones := 0
var num_tinder := 0
var num_sacrifice := 0
var burrow_state := 0

func hide_ritual_items():
	for item in ritual_sprites:
		item.hide()

func update(ritual_items_acquired: Array[Forage], new_burrow_state: int):
	num_papers = count_ritual_items(ritual_items_acquired, Forage.Type.RitualPaper)
	if num_papers == 0:
		hide()
		return
	show()
	
	burrow_state = new_burrow_state
	dig_req_label.set_quantity(burrow_state - 2, 2)
	
	num_stones = count_ritual_items(ritual_items_acquired, Forage.Type.RitualStone)
	stone_req_label.set_quantity(num_stones, 5)
	
	num_tinder = count_ritual_items(ritual_items_acquired, Forage.Type.RitualTinder)
	tinder_req_label.set_quantity(num_tinder, 1)
	
	num_sacrifice = count_ritual_items(ritual_items_acquired, Forage.Type.RitualSacrifice)
	sacrifice_req_label.set_quantity(num_sacrifice, 1)
	
	update_ritual_button()

func count_ritual_items(ritual_items_acquired: Array[Forage], type: Forage.Type) -> int:
	return ritual_items_acquired.filter(func(x: Forage): return x.type == type).size()

func update_progress(progress: float):
	var x = 0.0
	var i = 0
	while x < progress && i < ritual_sprites.size():
		if !ritual_sprites[i].visible:
			ritual_sprites[i].show()
			ritual_sounds[i].play()
		x += 1.0 / ritual_sprites.size()
		i += 1
	while i < ritual_sprites.size():
		ritual_sprites[i].hide()
		i += 1
	ritual_progress.value = progress

func set_ritual_enabled(enabled: bool):
	ritual_enabled = enabled
	update_ritual_button()

func update_ritual_button():
	ritual_button.disabled = (
		!ritual_enabled || 
		num_stones < 5 ||
		num_tinder < 1 || 
		num_sacrifice < 1 || 
		burrow_state < 4
	)
