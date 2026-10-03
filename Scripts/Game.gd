extends Control

enum Location {
	EAST_FIELD,
	BURROW
}

const FATIGUE_PER_DAY = 1.0
const HUNGER_PER_DAY = 2.0
const UNHEALTH_PER_DAY = 0.5
const MINUTES_PER_DAY = 1440.0
const DIG_REQUIRED = 0.5

var location = Location.EAST_FIELD
var location_change_tween: Tween

@export var rabbit: RabbitSprite

@onready var east_grass_position: Vector2i = get_viewport().size / 4
@onready var burrow_position: Vector2i = (get_viewport().size / 4) * Vector2i(-1, 1)
@onready var camera := get_viewport().get_camera_2d()
@onready var hand_center := %HandCenter

@onready var grass := %Grass
@onready var burrow: Burrow = %Burrow

@onready var fatigue_bar := %FatigueBar
@onready var hunger_bar := %HungerBar
@onready var health_bar := %HealthBar

@onready var dig_button := %DigButton
@onready var dig_progress_bar := %DigProgress
@onready var sleep_button := %SleepButton

var digging := false
var sleeping := false

var time_of_day  := 0.0
var fatigue      := 0.0
var hunger       := 0.5
var unhealth     := 0.5
var dig_progress := 0.0

func _ready() -> void:
	camera.global_position = east_grass_position
	
	var entrances = get_tree().get_nodes_in_group("entrance")
	for entrance in entrances:
		if entrance is Entrance:
			entrance.entered.connect(func(): enter_burrow(entrance))
	
	var exits = get_tree().get_nodes_in_group("exit")
	for exit in exits:
		if exit is Exit:
			exit.exited.connect(func(): exit_burrow(exit.entrance))
	
	grass.ate.connect(on_ate)
	
	dig_button.button_down.connect(func():
		digging = true
		update_state()
	)
	dig_button.button_up.connect(func():
		digging = false
		update_state()
	)
	
	sleep_button.button_down.connect(func():
		sleeping = true
		update_state()
	)
	sleep_button.button_up.connect(func():
		sleeping = false
		update_state()
	)

func _process(delta: float) -> void:
	if digging:
		pass_time(delta * 60.0) # Hour per second
		dig_progress += (delta * 60.0 / MINUTES_PER_DAY) / DIG_REQUIRED
		if dig_progress >= 1.0:
			pass # thing happen
		grass.rate_mod = 60.0
	elif sleeping:
		fatigue = clamp(fatigue - FATIGUE_PER_DAY * 3.0 * delta * 60.0 / MINUTES_PER_DAY, 0.0, 1.0)
		pass_time(delta * 60.0)
		grass.rate_mod = 60.0
	else:
		pass_time(delta)        # Minute per second
		grass.rate_mod = 1.0
	
	fatigue_bar.value = 1.0 - fatigue
	hunger_bar.value = 1.0 - hunger
	health_bar.value = 1.0 - unhealth
	dig_progress_bar.value = dig_progress
	
	grass.can_eat = hunger > 0.05

func update_state():
	if digging:
		burrow.set_rabbit_state(Burrow.State.Digging)
	elif sleeping:
		burrow.set_rabbit_state(Burrow.State.Sleeping)
	else:
		burrow.set_rabbit_state(Burrow.State.Sitting)

func enter_burrow(_from: Entrance) -> void:
	if location == Location.BURROW: return
	change_location(Location.BURROW)
	rabbit.set_process(false)

func exit_burrow(to: Entrance) -> void:
	if location != Location.BURROW: return
	rabbit.position = to.position
	change_location(Location.EAST_FIELD)
	rabbit.set_process(true)

func change_location(new_location: Location):
	location = new_location
	if location_change_tween != null:
		location_change_tween.kill()
	location_change_tween = create_tween()
	location_change_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	location_change_tween.tween_property(camera, "global_position", get_location_position(), 0.5)

func get_location_position() -> Vector2:
	match location:
		Location.EAST_FIELD: return east_grass_position
		Location.BURROW: return burrow_position
		_: return Vector2(0, 0)

func pass_time(minutes: float):
	time_of_day += minutes / MINUTES_PER_DAY
	fatigue += minutes * FATIGUE_PER_DAY / MINUTES_PER_DAY
	hunger += minutes * HUNGER_PER_DAY / MINUTES_PER_DAY
	unhealth += minutes * UNHEALTH_PER_DAY / MINUTES_PER_DAY
	
	hand_center.rotation = time_of_day * TAU

func on_ate():
	hunger -= 0.1
	if hunger < 0.0:
		hunger = 0.0
