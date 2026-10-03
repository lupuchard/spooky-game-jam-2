#extends Node2D
#
#@onready var predators_node = $Predators
#
#const MINIMUM_TIME = 2.0
#const WEIBULL_SHAPE = 2.0
#const WEIBULL_SCALE = 2.0
#
#var predators: Array[Predator] = []
#
#var day: int = 0
#var time_of_day: Enums.TimeOfDay = Enums.TimeOfDay.Day
#var upcoming_predator: Predator = null
#var when_predator: float = 0.0
#var time := 0.0
#var enabled := false
#
#func _ready():
	#for predator in predators_node.get_children():
		#if predator is Predator:
			#predators.push_back(predator)
#
#func _process(delta: float):
	#if enabled:
		#time += delta
	#else:
		#time -= delta
	#
#func enter(for_day: int, for_time: Enums.TimeOfDay):
	#day = for_day
	#time_of_day = for_time
	#enabled = true
#
#func reset():
	#var possible_predators: Array[Predator] = []
	#for predator in predators:
		#if predator.time_of_day == time_of_day && predator.min_day >= day && predator.max_day <= day:
			#possible_predators.push_back(predator)
	#
	#upcoming_predator = possible_predators.pick_random()
	#when_predator = weibull_ppf(randf()) + MINIMUM_TIME
#
#static func weibull_ppf(x: float):
	#return WEIBULL_SCALE * pow(-log(1 - x), 1 / WEIBULL_SHAPE)
