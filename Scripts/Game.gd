extends Control

enum Location {
	EAST_FIELD,
	BURROW
}

const FATIGUE_PER_DAY = 1.0
const HUNGER_PER_DAY = 2.0
const UNHEALTH_PER_DAY = 0.5
const MINUTES_PER_DAY = 1440.0
const ACTIVITY_SPEED = 120.0 # 2 hours per second
const DIG_REQUIRED = 0.5
const HUNGER_WARNING_THRESH = 0.8
const FATIGUE_WARNING_THRESH = 0.8

var location = Location.EAST_FIELD
var location_change_tween: Tween

@export var rabbit: RabbitSprite

@onready var east_grass_position: Vector2i = get_viewport().size / 4
@onready var burrow_position: Vector2i = (get_viewport().size / 4) * Vector2i(-1, 1)
@onready var camera := get_viewport().get_camera_2d()
@onready var spooky_shader := %SpookyShader
@onready var death_popup := %DeathPopup
@onready var darkness := %Darkness
@onready var gameplay_root := $Root

#@onready var forest_ambience := %ForestAmbience
@onready var spook_ambience := %SpookAmbience
@onready var outside_ambience: int
@onready var digging_sound1 := %DiggingSound1
@onready var digging_sound2 := %DiggingSound2
@onready var beast_approach_sound := %BeastApproachSound
@onready var finish_dig_sound := %FinishDigSound

@onready var grass := %Grass
@onready var predator_warning := %PredatorWarning
@onready var predator_warning_label := %PredatorWarning/Label
@onready var time_until_predator_label := %TimeUntilPredatorLabel
@onready var beast := %Beast
@onready var beast_spawn := %BeastSpawn
@onready var bird_silhouette := %BirdSilhouette

@onready var burrow: Burrow = %Burrow
@onready var entrances: Array[Entrance] = []
@onready var exits: Array[Exit] = []
@onready var hand_center := %HandCenter
@onready var warning_panel := %WarningPanel
@onready var warning_label := %WarningLabel

@onready var fatigue_bar := %FatigueBar
@onready var hunger_bar := %HungerBar
@onready var health_bar := %HealthBar

@onready var dig_button := %DigButton
@onready var dig_progress_bar := %DigProgress
@onready var sleep_button := %SleepButton

var forages: Array[Forage]
var rabbit_over_forage: Array[Forage] = []
#var rabbit_over_entrance: Entrance = null

var time_until_predator: float = 100.0
var predators: Array[PredatorInfo] = []
var predator: PredatorInfo = null
var predator_active: bool = false
var time_until_attack: float = 0.0
var burrow_state: int = 0
var bird_will_attack: bool = false

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
	
	entrances.assign(get_tree().get_nodes_in_group("entrance"))
	for entrance in entrances:
		entrance.entered.connect(func(): enter_burrow(entrance))
	
	exits.assign(get_tree().get_nodes_in_group("exit"))
	for exit in exits:
		exit.exited.connect(func(): exit_burrow(exit.entrance))
	
	forages.assign(get_tree().get_nodes_in_group("forage"))
	for forage in forages:
		forage.rabbit_entered.connect(func(): on_enter_forage(forage))
		forage.rabbit_exited.connect(func(): on_exit_forage(forage))
	
	predators.assign(get_tree().get_nodes_in_group("predator_info"))
	
	grass.ate.connect(on_ate)
	
	dig_button.button_down.connect(start_digging)
	dig_button.button_up.connect(stop_digging)
	sleep_button.button_down.connect(start_sleeping)
	sleep_button.button_up.connect(stop_sleeping)
	
	spooky_shader.show()
	
	predator_warning.hide()
	beast.gottem.connect(func(): rabbit_died("You have been killed."))
	
	digging_sound1.finished.connect(func():
		if digging:
			digging_sound1.play()
	)
	digging_sound2.finished.connect(func():
		if digging:
			digging_sound2.play()
	)
	
	outside_ambience = AudioServer.get_bus_index("OutsideAmbience")
	spook_ambience.volume_db = -20.0
	
	bird_silhouette.flyby_finished.connect(func():
		if bird_will_attack or !rabbit.standing:
			spawn_beast()
		else:
			predator_begone()
			time_until_predator = random_time_until_predator()
	)

func start_digging():
	digging = true
	update_state()
	digging_sound1.play()
	await get_tree().create_timer(0.4).timeout
	if digging:
		digging_sound2.play()

func stop_digging():
	digging = false
	update_state()

func start_sleeping():
	sleeping = true
	update_state()
	spook_ambience.volume_db = -10.0
	
func stop_sleeping():
	sleeping = false
	update_state()
	spook_ambience.volume_db = 0.0

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
	
	if digging && fatigue > FATIGUE_WARNING_THRESH:
		stop_digging()
	if (sleeping || digging) && hunger > HUNGER_WARNING_THRESH:
		stop_sleeping()
		stop_digging()
	sleep_button.disabled = hunger > HUNGER_WARNING_THRESH
	dig_button.disabled = hunger > HUNGER_WARNING_THRESH || fatigue > FATIGUE_WARNING_THRESH
	
	if hunger > HUNGER_WARNING_THRESH:
		warning_panel.show()
		warning_label.text = "Too hungry to sleep or dig"
	elif fatigue > FATIGUE_WARNING_THRESH:
		warning_panel.show()
		warning_label.text = "Too sleepy to dig"
	else:
		warning_panel.hide()
	
	if digging:
		pass_time(delta * ACTIVITY_SPEED)
		dig_progress += (delta * ACTIVITY_SPEED / MINUTES_PER_DAY) / DIG_REQUIRED
		if dig_progress >= 1.0:
			complete_dig()
		grass.rate_mod = ACTIVITY_SPEED
	elif sleeping:
		fatigue = clamp(fatigue - FATIGUE_PER_DAY * 3.0 * delta * ACTIVITY_SPEED / MINUTES_PER_DAY, 0.0, 1.0)
		if fatigue <= 0.0:
			stop_sleeping()
		pass_time(delta * ACTIVITY_SPEED)
		grass.rate_mod = ACTIVITY_SPEED
	else:
		pass_time(delta)        # Minute per second
		grass.rate_mod = 1.0
	
	if unhealth >= 1.0:
		if fatigue >= 1.0:
			rabbit_died("You have died of sleep deprivation.")
		else:
			rabbit_died("You have died of poor health.")
	if hunger >= 1.0:
		rabbit_died("You have died of gastrointestinal stasis.")
	
	fatigue_bar.value = 1.0 - fatigue
	hunger_bar.value = 1.0 - hunger
	health_bar.value = 1.0 - unhealth
	dig_progress_bar.value = dig_progress
	
	grass.can_eat = hunger > 0.05
	
	if location == Location.BURROW:
		if predator != null:
			modify_time_until_attack(delta / 2.0 if predator_active else delta)
			if time_until_attack >= predator.warning_time * 0.9:
				predator_begone()
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
	elif predator != null:
		modify_time_until_attack(-delta)
		if predator.type == PredatorInfo.Type.Beast and time_until_attack <= 1.0 and !beast_approach_sound.playing:
			beast_approach_sound.play()
		
		if time_until_attack < 0.0 and !predator_active:
			spawn_predator()
			bird_will_attack = !rabbit.standing
			if predator.type == PredatorInfo.Type.Bird and bird_will_attack:
				beast_approach_sound.play()
			
	time_until_predator_label.text = "%.01f" % time_until_predator

func predator_begone():
	modify_time_until_attack(predator.warning_time)
	predator_active = false
	predator = null
	beast.remove()
	predator_warning.hide()

func complete_dig():
	dig_progress = 0
	if burrow_state < 5:
		burrow_state += 1
		burrow.set_burrow_state(burrow_state)
	stop_digging()
	finish_dig_sound.play()
	
	for entrance in entrances:
		var unlocked = entrance.unlock_state <= burrow_state
		entrance.visible = unlocked
		entrance.process_mode = Node.PROCESS_MODE_INHERIT if unlocked else Node.PROCESS_MODE_DISABLED
	for exit in exits:
		var unlocked = exit.entrance.unlock_state <= burrow_state
		exit.visible = unlocked
		exit.process_mode = Node.PROCESS_MODE_INHERIT if unlocked else Node.PROCESS_MODE_DISABLED

func modify_time_until_attack(amount: float):
	time_until_attack += amount
	var value = clamp(1.0 - (time_until_attack / predator.warning_time), 0.0, 2.0)
	predator_warning.value = value
	
	value = pow(value, 2)
	var shader: ShaderMaterial = spooky_shader.material
	shader.set_shader_parameter("noise_strength", lerp(0.1, 0.2, value))
	shader.set_shader_parameter("dither_strength", lerp(0.1, 0.2, value))
	shader.set_shader_parameter("vintage_strength", lerp(0.8, 1.0, value))

func spawn_predator() -> void:
	match predator.type:
		PredatorInfo.Type.Beast:
			spawn_beast()
		PredatorInfo.Type.Bird:
			bird_silhouette.do_flyby()
		_: push_error("Predator type not implemented yet %s" % predator.type)
	predator_active = true

func spawn_beast():
	beast.set_predator(predator)
	beast.global_position = Util.random_position_in_area(beast_spawn)

func rabbit_died(text: String):
	call_deferred("pause")
	death_popup.show_death(text)
	dead = true
	darkness.color = Color.DARK_SLATE_GRAY

func pause():
	gameplay_root.process_mode = Node.PROCESS_MODE_DISABLED

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
	rabbit.process_mode = Node.PROCESS_MODE_DISABLED
	beast.process_mode = Node.PROCESS_MODE_DISABLED
	
	if predator != null:
		if time_until_attack < 0.0:
			time_until_attack = 0.0
		predator_warning_label.text = predator.exit_text
	
	#forest_ambience.volume_db = -15.0
	AudioServer.set_bus_volume_db(outside_ambience, -15.0)
	spook_ambience.volume_db = 0.0
	beast_approach_sound.stop()

func exit_burrow(to: Entrance) -> void:
	if location != Location.BURROW: return
	rabbit.position = to.position
	change_location(Location.EAST_FIELD)
	rabbit.process_mode = Node.PROCESS_MODE_INHERIT
	beast.process_mode = Node.PROCESS_MODE_INHERIT
	time_until_predator = random_time_until_predator()
	
	if predator != null:
		predator_warning_label.text = predator.entry_text
	
	#forest_ambience.volume_db = -5.0
	AudioServer.set_bus_volume_db(outside_ambience, -5.0)
	spook_ambience.volume_db = -10.0

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
	darkness.set_time(time_passed)
	
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
	rabbit.eat_sound.play()

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
			rabbit.eat_sound.play()

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
