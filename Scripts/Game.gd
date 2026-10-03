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
const HUNGER_WARNING_THRESH = 0.8

var location = Location.EAST_FIELD
var location_change_tween: Tween

@export var rabbit: RabbitSprite

@onready var east_grass_position: Vector2i = get_viewport().size / 4
@onready var burrow_position: Vector2i = (get_viewport().size / 4) * Vector2i(-1, 1)
@onready var camera := get_viewport().get_camera_2d()
@onready var spooky_shader := %SpookyShader
@onready var death_popup := %DeathPopup
@onready var gameplay_root := $Root

@onready var grass := %Grass
@onready var predator_warning := %PredatorWarning
@onready var predator_warning_label := %PredatorWarning/Label
@onready var time_until_predator_label := %TimeUntilPredatorLabel
@onready var beast := %Beast
@onready var beast_spawn := %BeastSpawn

@onready var burrow: Burrow = %Burrow
@onready var hand_center := %HandCenter
@onready var too_hungry_panel := %TooHungryPanel

@onready var fatigue_bar := %FatigueBar
@onready var hunger_bar := %HungerBar
@onready var health_bar := %HealthBar

@onready var dig_button := %DigButton
@onready var dig_progress_bar := %DigProgress
@onready var sleep_button := %SleepButton

var forages: Array[Forage]
var rabbit_over_forage: Array[Forage] = []
#var rabbit_over_entrance: Entrance = null

var time_until_predator: float = 5.0
var predators: Array[PredatorInfo] = []
var predator: PredatorInfo = null
var predator_active: bool = false
var time_until_attack: float = 0.0

var digging := false
var sleeping := false
var dead := false

var time_passed  := 0.0
var fatigue      := 0.0
var hunger       := 0.5
var unhealth     := 0.5
var dig_progress := 0.0

func _ready() -> void:
	camera.global_position = east_grass_position
	
	var entrances = get_tree().get_nodes_in_group("entrance")
	for entrance in entrances:
		if entrance is not Entrance: continue
		entrance.entered.connect(func(): enter_burrow(entrance))
	
	var exits = get_tree().get_nodes_in_group("exit")
	for exit in exits:
		if exit is not Exit: continue
		exit.exited.connect(func(): exit_burrow(exit.entrance))
	
	forages.assign(get_tree().get_nodes_in_group("forage"))
	for forage in forages:
		forage.rabbit_entered.connect(func(): on_enter_forage(forage))
		forage.rabbit_exited.connect(func(): on_exit_forage(forage))
	
	predators.assign(get_tree().get_nodes_in_group("predator_info"))
	
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
	
	spooky_shader.show()
	
	predator_warning.hide()

func on_enter_forage(forage: Forage) -> void:
	if rabbit_over_forage.size() > 0:
		rabbit_over_forage.back().set_glow(false)
	rabbit_over_forage.push_back(forage)
	forage.set_glow(true)

func on_exit_forage(forage: Forage) -> void:
	rabbit_over_forage.erase(forage)
	if rabbit_over_forage.size() > 0:
		rabbit_over_forage.back().set_glow(true)
	forage.set_glow(false)

func _process(delta: float) -> void:
	if dead:
		return
	
	if (sleeping || digging) && hunger > HUNGER_WARNING_THRESH:
		sleeping = false
		digging = false
		update_state()
	sleep_button.disabled = hunger > HUNGER_WARNING_THRESH
	dig_button.disabled = hunger > HUNGER_WARNING_THRESH
	too_hungry_panel.visible = hunger > HUNGER_WARNING_THRESH
	
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
	
	if unhealth >= 1.0:
		gameplay_root.set_process(false)
		if fatigue >= 1.0:
			death_popup.show_death("You have died of sleep deprivation.")
		else:
			death_popup.show_death("You have died of poor health.")
	if hunger >= 1.0:
		gameplay_root.set_process(false)
		death_popup.show_death("You have died of gastrointestinal stasis.")
	
	fatigue_bar.value = 1.0 - fatigue
	hunger_bar.value = 1.0 - hunger
	health_bar.value = 1.0 - unhealth
	dig_progress_bar.value = dig_progress
	
	grass.can_eat = hunger > 0.05
	
	if location == Location.BURROW:
		if predator != null:
			time_until_attack += delta / 2.0
			predator_warning.value = 1.0 - (time_until_attack / predator.warning_time)
			if time_until_attack >= predator.warning_time:
				predator_active = false
				predator = null
				beast.remove()
	elif predator == null:
		time_until_predator -= delta
		if time_until_predator < 0.0:
			predator = random_predator()
			if predator != null:
				time_until_attack = predator.warning_time
				predator_warning.show()
				predator_warning_label.text = predator.entry_text
			else:
				time_until_predator = random_time_until_predator()
	elif predator != null and !predator_active:
		time_until_attack -= delta
		predator_warning.value = 1.0 - (time_until_attack / predator.warning_time)
		if time_until_attack < 0.0:
			spawn_predator()
			
	time_until_predator_label.text = "%.01f" % time_until_predator

func spawn_predator() -> void:
	match predator.type:
		PredatorInfo.Type.Beast:
			beast.set_predator(predator)
			beast.global_position = Util.random_position_in_area(beast_spawn)
		_: push_error("Predator type not implemented yet %s" % predator.type)
	predator_active = true

func update_state() -> void:
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
	beast.set_process(false)
	
	if predator != null:
		predator_warning_label.text = predator.exit_text

func exit_burrow(to: Entrance) -> void:
	if location != Location.BURROW: return
	rabbit.position = to.position
	change_location(Location.EAST_FIELD)
	rabbit.set_process(true)
	beast.set_process(true)
	time_until_predator = random_time_until_predator()
	
	if predator != null:
		predator_warning_label.text = predator.entry_text

func change_location(new_location: Location) -> void:
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

func pass_time(minutes: float) -> void:
	time_passed += minutes / MINUTES_PER_DAY
	
	fatigue += minutes * FATIGUE_PER_DAY / MINUTES_PER_DAY
	if fatigue > 1.0:
		fatigue = 1.0
		# Unhealth grows fast when no sleep
		unhealth += minutes * UNHEALTH_PER_DAY / MINUTES_PER_DAY * 5.0
	else:
		unhealth += minutes * UNHEALTH_PER_DAY / MINUTES_PER_DAY
		
	hunger += minutes * HUNGER_PER_DAY / MINUTES_PER_DAY
	
	
	for forage in forages:
		forage.pass_time(minutes)
	
	hand_center.rotation = time_passed * TAU

func on_ate() -> void:
	hunger -= 0.1
	if hunger < 0.0:
		hunger = 0.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if rabbit_over_forage.size() > 0:
			var current_forage: Forage = rabbit_over_forage.back()
			on_exit_forage(current_forage)
			current_forage.remove()
			hunger -= current_forage.reduce_hunger
			if hunger < 0.0: hunger = 0.0
			unhealth -= current_forage.restore_health
			if unhealth < 0.0: unhealth = 0.0

func random_time_until_predator() -> float:
	var time = randf_range(max(5.0 - time_passed, 0.5), 10.0)
	while randi_range(0, 3) == 3:
		time *= 2.0
	return time

func random_predator() -> PredatorInfo:
	var possible_predators = predators.filter(func(pred):
		return pred.min_day <= time_passed && pred.max_day >= time_passed
	)
	if possible_predators.size() == 0:
		push_error("No possible predators to spawn!")
		return null
	return possible_predators.pick_random()
