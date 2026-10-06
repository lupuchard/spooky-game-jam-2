extends Control

const FATIGUE_PER_DAY = 1.0
const HUNGER_PER_DAY = 2.0
const UNHEALTH_PER_DAY = 0.5
const MINUTES_PER_DAY = 1440.0
const BASE_SPEED = 2.0 # 2 minutes per second
const ACTIVITY_SPEED = 120.0 # 2 hours per second
const DIG_REQUIRED = 0.5
const RITUAL_REQUIRED = 0.1
const HUNGER_WARNING_THRESH = 0.8
const FATIGUE_WARNING_THRESH = 0.8

@export var rabbit: RabbitSprite

#@onready var east_grass_position: Vector2i = get_viewport().size / 4
@onready var burrow_position: Vector2i = (get_viewport().size / 4) * Vector2i(-1, 1)
@onready var underburrow_position: Vector2i = (get_viewport().size / 4) * Vector2i(-1, 3)
@onready var camera := get_viewport().get_camera_2d()
@onready var spooky_shader := %SpookyShader
@onready var main_menu := %MainMenu
@onready var death_popup := %DeathPopup
@onready var survive_popup := %SurvivePopup
@onready var darkness := %Darkness
@onready var jumpscare := %Jumpscare
@onready var gameplay_root := $Root

#@onready var forest_ambience := %ForestAmbience
@onready var spook_ambience := %SpookAmbience
@onready var outside_ambience: int
@onready var digging_sound1 := %DiggingSound1
@onready var digging_sound2 := %DiggingSound2
@onready var beast_approach_sound := %BeastApproachSound
@onready var weasel_approach_sound := %WeaselApproachSound
@onready var finish_dig_sound := %FinishDigSound
@onready var enter_sound := %EnterSound

@onready var rain := %RainShader
@onready var predator_warning := %PredatorWarning
@onready var predator_warning_label := %PredatorWarning/Label
@onready var time_until_predator_label := %TimeUntilPredatorLabel
@onready var beast := %Beast
@onready var bird_silhouette := %BirdSilhouette

@onready var field1 = %Field1
@onready var burrow: Burrow = %Burrow
@onready var entrances: Array[Entrance] = []
@onready var exits: Array[Exit] = []
@onready var fields: Array[Field] = []
@onready var ritual_info := %RitualInfo
@onready var hand_center := %HandCenter
@onready var warning_panel := %WarningPanel
@onready var warning_label := %WarningLabel
@onready var notification_text := %NotificationText

@onready var status_bars_container := %StatusBarsContainer
@onready var fatigue_bar := %FatigueBar
@onready var hunger_bar := %HungerBar
@onready var health_bar := %HealthBar

@onready var dig_button := %DigButton
@onready var dig_progress_bar := %DigProgress
@onready var sleep_button := %SleepButton

var forages: Array[Forage]
var rabbit_over_forage: Array[Forage] = []
#var rabbit_over_entrance: Entrance = null

var location: Field
var location_change_tween: Tween

var time_until_predator: float = 100.0
var predators: Array[PredatorInfo] = []
var predator: PredatorInfo = null
var predator_active: bool = false
var time_until_attack: float = 0.0
var bird_will_attack: bool = false

var digging := false
var sleeping := false
var doing_ritual := false
var dead := false
var paused := false

var tutorial_state := 0
var time_passed  := 0.0
var fatigue      := 0.4
var hunger       := 0.6
var unhealth     := 0.5
var dig_progress := 0.0
var burrow_state: int = 1#0
var game_win := false

var ritual_items_acquired: Array[Forage] = []

var starting_save_state: Dictionary

func _ready() -> void:
	#camera.global_position = east_grass_position
	
	entrances.assign(get_tree().get_nodes_in_group("entrance"))
	for entrance in entrances:
		entrance.entered.connect(func(): enter_burrow(entrance))
	
	exits.assign(get_tree().get_nodes_in_group("exit"))
	for exit in exits:
		if exit.entrance != null:
			exit.exited.connect(func(): exit_burrow(exit))
		else:
			exit.exited.connect(into_the_underburrow)
	
	update_entrances()
	
	forages.assign(get_tree().get_nodes_in_group("forage"))
	for forage in forages:
		forage.rabbit_entered.connect(func(): on_enter_forage(forage))
		forage.rabbit_exited.connect(func(): on_exit_forage(forage))
	
	predators.assign(get_tree().get_nodes_in_group("predator_info"))
	
	fields.assign(get_tree().get_nodes_in_group("field"))
	for field in fields:
		field.grass.ate.connect(on_ate)
	change_location(field1)
	
	dig_button.button_down.connect(start_digging)
	dig_button.button_up.connect(stop_digging)
	sleep_button.button_down.connect(start_sleeping)
	sleep_button.button_up.connect(stop_sleeping)
	ritual_info.ritual_button_pressed.connect(start_ritual)
	ritual_info.ritual_button_released.connect(stop_ritual)
	
	spooky_shader.show()
	
	predator_warning.hide()
	beast.gottem.connect(beast_gottem)
	death_popup.restart_pressed.connect(restart)
	survive_popup.continue_pressed.connect(resume)
	
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
	)
	
	burrow.set_burrow_state(burrow_state)
	
	starting_save_state = get_save_state()
	notification_text.show_text("Left click to eat grass.", 100.0)
	
	pause()
	main_menu.play_pressed.connect(func(): 
		main_menu.hide()
		resume()
	)

func beast_gottem():
	if (1.0 - unhealth) > predator.damage + 0.05:
		jumpscare.survive_scare()
		unhealth += predator.damage
		health_bar.value = 1.0 - unhealth
		var text = "You managed to fight it off, but was injured (lost %s health)."
		survive_popup.show_survive(text % int(predator.damage * 100))
		predator_begone()
		call_deferred("pause")
	else:
		jumpscare.death_scare()
		rabbit_died("You have been killed.")

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

func start_ritual():
	doing_ritual = true
	burrow.get_ritual_pile().hide()
	burrow.get_ritual_pile().hide_everything()
	update_state()
	burrow_state = 5
	burrow.set_burrow_state(burrow_state)

func stop_ritual():
	doing_ritual = false
	update_state()

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
	if dead or game_win or paused:
		return
	
	if (digging || doing_ritual) && fatigue > FATIGUE_WARNING_THRESH:
		stop_digging()
		stop_ritual()
	if (sleeping || digging || doing_ritual) && hunger > HUNGER_WARNING_THRESH:
		stop_sleeping()
		stop_digging()
		stop_ritual()
	sleep_button.disabled = hunger > HUNGER_WARNING_THRESH
	dig_button.visible = burrow_state < 4
	dig_button.disabled = hunger > HUNGER_WARNING_THRESH || fatigue > FATIGUE_WARNING_THRESH
	
	if hunger > HUNGER_WARNING_THRESH:
		warning_panel.show()
		warning_label.text = "Too hungry to sleep or dig"
	elif fatigue > FATIGUE_WARNING_THRESH:
		warning_panel.show()
		warning_label.text = "Too sleepy to dig"
	else:
		warning_panel.hide()
	
	var time_speedup = BASE_SPEED
	if digging:
		time_speedup = ACTIVITY_SPEED
		dig_progress += (delta * time_speedup / MINUTES_PER_DAY) / DIG_REQUIRED
		if dig_progress >= 1.0:
			complete_dig()
	elif sleeping:
		time_speedup = ACTIVITY_SPEED
		fatigue = clamp(fatigue - FATIGUE_PER_DAY * 3.0 * delta * time_speedup / MINUTES_PER_DAY, 0.0, 1.0)
		if fatigue <= 0.0:
			stop_sleeping()
	elif doing_ritual:
		time_speedup = ACTIVITY_SPEED / 4.0
		dig_progress += (delta * time_speedup / MINUTES_PER_DAY) / RITUAL_REQUIRED
		ritual_info.update_progress(dig_progress)
		if dig_progress >= 1.0:
			complete_dig()
			complete_ritual()
	
	pass_time(time_speedup * delta)
	if location != null:
		location.grass.rate_mod = time_speedup
		location.grass.can_eat = hunger > 0.05
	
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
	
	if location == null:
		if predator != null && (beast.path == null || beast.exiting_burrow):
			modify_time_until_attack((delta / 2.0 if predator_active else delta) * time_speedup / 2.0)
			if time_until_attack >= predator.warning_time * 0.95:
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
		
		if predator.type == PredatorInfo.Type.Weasel and time_until_attack <= 0.5 and !weasel_approach_sound.playing:
			weasel_approach_sound.play()
		
		if time_until_attack < 0.0 and !predator_active:
			spawn_predator()
			bird_will_attack = !rabbit.standing
			if predator.type == PredatorInfo.Type.Bird and bird_will_attack:
				beast_approach_sound.play()
			
	time_until_predator_label.text = "%.01f" % time_until_predator
	
	if tutorial_state <= 1 && rabbit.foraging >= 0.8:
		tutorial_state = 2
		notification_text.show_text("Eat forage to restore health.", 100.0)

func predator_begone():
	modify_time_until_attack(predator.warning_time)
	predator_active = false
	predator = null
	beast.remove()
	predator_warning.hide()
	time_until_predator = random_time_until_predator()
	beast_approach_sound.stop()
	weasel_approach_sound.stop()

func complete_dig():
	dig_progress = 0
	burrow_state += 1
	burrow.set_burrow_state(burrow_state)
	stop_digging()
	finish_dig_sound.play()
	update_entrances()
	
	ritual_info.update(ritual_items_acquired, burrow_state)
	burrow.update_ritual_pile(ritual_items_acquired)

func complete_ritual():
	stop_ritual()
	%Clock.hide()
	ritual_info.hide()
	%RitualExplosion.emitting = true
	%RitualExplosion2.emitting = true
	%ExplosionSound.play()
	status_bars_container.show()
	game_win = true
	
	for exit in exits:
		exit.hide()
	%Exit5.enable()

func update_entrances():
	for entrance in entrances:
		if entrance.unlock_state <= burrow_state:
			entrance.enable()
		else:
			entrance.disable()
	for exit in exits:
		if exit.entrance.unlock_state <= burrow_state if exit.entrance != null else false:
			exit.enable()
		else:
			exit.disable()

func modify_time_until_attack(amount: float):
	time_until_attack += amount
	var value = clamp(1.0 - (time_until_attack / predator.warning_time), 0.0, 2.0)
	predator_warning.value = value
	
	if predator.type == PredatorInfo.Type.Beast or (
		predator.type == PredatorInfo.Type.Bird && bird_will_attack
	):
		value = pow(value, 2)
	else:
		value = 0.0
	
	var shader: ShaderMaterial = spooky_shader.material
	shader.set_shader_parameter("noise_strength", lerp(0.1, 0.2, value))
	shader.set_shader_parameter("dither_strength", lerp(0.1, 0.2, value))
	shader.set_shader_parameter("vintage_strength", lerp(0.8, 1.0, value))

func spawn_predator() -> void:
	match predator.type:
		PredatorInfo.Type.Beast:
			spawn_beast()
		PredatorInfo.Type.Bird:
			if location != null:
				bird_silhouette.do_flyby(location)
			else:
				predator_begone()
		PredatorInfo.Type.Weasel:
			if location != null:
				spawn_beast()
			else:
				beast.set_predator(predator)
	predator_active = true

func spawn_beast():
	if location != null:
		beast.set_predator(predator)
		beast.global_position = Util.random_position_in_area(location.beast_spawn)
	else:
		predator_begone()

func rabbit_died(text: String):
	call_deferred("pause")
	death_popup.show_death(text)
	dead = true
	darkness.color = Color.DARK_SLATE_GRAY

func pause():
	gameplay_root.process_mode = Node.PROCESS_MODE_DISABLED
	paused = true

func resume():
	gameplay_root.process_mode = Node.PROCESS_MODE_INHERIT
	paused = false

func update_state() -> void:
	if digging:
		burrow.set_rabbit_state(Burrow.State.Digging)
	elif sleeping:
		burrow.set_rabbit_state(Burrow.State.Sleeping)
	else:
		burrow.set_rabbit_state(Burrow.State.Sitting)

func enter_burrow(from: Entrance) -> void:
	if location == null || from.dangerous: return
	
	rabbit.hide()
	change_location(null)
	rabbit.process_mode = Node.PROCESS_MODE_DISABLED
	
	ritual_info.update(ritual_items_acquired, burrow_state)
	burrow.update_ritual_pile(ritual_items_acquired)
	
	for exit in exits:
		exit.set_dangerous(false)
	
	if predator != null:
		if predator.type == PredatorInfo.Type.Weasel and !beast.exiting_burrow:
			if beast.predator == null:
				spawn_predator()
			if !weasel_approach_sound.playing:
				weasel_approach_sound.play()
			beast.follow_into_burrow(from.exit)
			from.exit.set_dangerous(true)
			time_until_attack = 0.0
			predator_warning.value = 1.0
		else:
			if time_until_attack < 0.0:
				time_until_attack = 0.0
			predator_warning_label.text = predator.exit_text
			beast.process_mode = Node.PROCESS_MODE_DISABLED
			weasel_approach_sound.stop()
	
	AudioServer.set_bus_volume_db(outside_ambience, -15.0)
	spook_ambience.volume_db = -5.0
	beast_approach_sound.stop()
	enter_sound.play()
	
	if tutorial_state <= 3:
		tutorial_state = 4
		notification_text.hide_text()

func exit_burrow(exit: Exit) -> void:
	if location != null || exit.dangerous: return
	
	rabbit.global_position = exit.entrance.global_position
	rabbit.show()
	change_location(exit.entrance.get_parent())
	rabbit.process_mode = Node.PROCESS_MODE_INHERIT
	beast.process_mode = Node.PROCESS_MODE_INHERIT
	
	for entrance in entrances:
		entrance.set_dangerous(false)
	
	if predator != null:
		if predator.type == PredatorInfo.Type.Weasel && !beast.exiting_burrow:
			beast.follow_out_of_burrow(exit)
			exit.entrance.set_dangerous(true)
			beast_approach_sound.play()
		else:
			predator_warning_label.text = predator.entry_text
			beast_approach_sound.play()
	else:
		time_until_predator = random_time_until_predator()
	
	AudioServer.set_bus_volume_db(outside_ambience, -5.0)
	spook_ambience.volume_db = -15.0
	enter_sound.play()

func into_the_underburrow() -> void:
	tween_camera(underburrow_position)

func change_location(new_location: Field) -> void:
	location = new_location
	tween_camera(get_location_position())
	if new_location != null:
		rain.position = new_location.position
		for field in fields:
			if field != new_location:
				field.hide()

func tween_camera(destination: Vector2):
	if location_change_tween != null:
		location_change_tween.kill()
	location_change_tween = create_tween()
	location_change_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	location_change_tween.tween_property(camera, "global_position", destination, 0.5)

func get_location_position() -> Vector2:
	if location == null:
		return burrow_position
	else:
		return location.global_position + get_viewport().size / 4.0

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
	
	if tutorial_state == 0:
		tutorial_state = 1
		notification_text.show_text("Hold right click to search for forage.", 100.0)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause()
		main_menu.show()
	if event.is_action_pressed("click") and rabbit_over_forage.size() > 0:
		var current_forage: Forage = rabbit_over_forage.back()
		on_exit_forage(current_forage)
		current_forage.remove()
		
		if current_forage.type == Forage.Type.Food:
			hunger -= current_forage.reduce_hunger
			if hunger < 0.0: hunger = 0.0
			unhealth -= current_forage.restore_health
			if unhealth < 0.0: unhealth = 0.0
			rabbit.eat_sound.play()
			
			if tutorial_state <= 2:
				tutorial_state = 3
				notification_text.show_text("Enter your burrow to evade predators.", 100.0)
				time_until_predator = 5.0
		else:
			ritual_items_acquired.push_back(current_forage)
			current_forage.acquired = true
			for forage in forages:
				if forage.type != Forage.Type.Food && !forage.acquired:
					forage.spawn()
			match current_forage.type:
				Forage.Type.RitualPaper:
					notification_text.show_text("Found ritual papers.", 3.0)
				Forage.Type.RitualSacrifice:
					notification_text.show_text("Found ritual sacrifice.", 3.0)
				Forage.Type.RitualTinder:
					notification_text.show_text("Found ritual tinder.", 3.0)
		
		if current_forage.sound != null:
			current_forage.sound.play()

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
	
	var total_weight := 0.0
	for possible_predator in possible_predators:
		total_weight += possible_predator.spawn_weight
	var choice = randf_range(0.0, total_weight)
	var cumulative_weight := 0.0
	for i in range(0, possible_predators.size() - 1):
		cumulative_weight += possible_predators[i].spawn_weight
		if choice < cumulative_weight:
			return possible_predators[i]
	return possible_predators.back()

func get_save_state() -> Dictionary:
	return {
		"time_passed": time_passed,
		"fatigue": fatigue,
		"hunger": hunger,
		"unhealth": unhealth,
		"dig_progress": dig_progress,
		"burrow_state": burrow_state,
		"forages": forages.map(func(forage: Forage): return forage.get_save_state()),
		"tutorial_state": tutorial_state
	}

func load_save_state(state: Dictionary):
	time_passed = state.time_passed
	fatigue = state.fatigue
	hunger = state.hunger
	unhealth = state.unhealth
	dig_progress = state.dig_progress
	burrow_state = state.burrow_state
	tutorial_state = state.tutorial_state
	predator_begone()
	change_location(null)
	digging = false
	sleeping = false
	
	ritual_items_acquired = []
	for forage_info in state.forages:
		var forage_idx = forages.find_custom(func(x): return x.item_id == forage_info.id)
		if forage_idx == -1: continue
		var forage = forages[forage_idx]
		forage.load_save_state(forage_info)
		if forage.type != Forage.Type.Food && forage.acquired:
			ritual_items_acquired.push_back(forage)
	ritual_info.update(ritual_items_acquired, burrow_state)
	burrow.update_ritual_pile(ritual_items_acquired)

func restart():
	dead = false
	death_popup.hide()
	load_save_state(starting_save_state)
	change_location(field1)
	rabbit.position = Vector2(300, 150)
	call_deferred("resume")
	time_until_predator = random_time_until_predator()
	tutorial_state = 5
	notification_text.hide_text()
