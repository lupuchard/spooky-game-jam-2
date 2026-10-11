class_name Food
extends Forage

@export var restore_health: float = 0.0
@export var reduce_hunger: float = 0.0


@export var initial_spawn_time_minutes: float = 0.0
@export var respawn_time_minutes: float = 1.0

var respawn_time_left := 0.0

func _ready():
	super()
	respawn_time_left = initial_spawn_time_minutes
	
	if respawn_time_left == 0.0:
		spawn()

func pass_time(minutes: float):
	super(minutes)
	if !available:
		respawn_time_left -= minutes
		if respawn_time_left < 0.0:
			spawn()

func remove():
	super()
	respawn_time_left = randf_range(0.0, respawn_time_minutes)

func get_save_state() -> Dictionary:
	var state = super()
	state.respawn_time_left = respawn_time_left
	return state

func load_save_state(state: Dictionary):
	super(state)
	respawn_time_left = state.respawn_time_left
