extends Node
class_name Predator

enum PredatorType {
	Beast,
	Bird,
	Weasel
}

@export var type: PredatorType = PredatorType.Beast
@export var warning_time: float = 1.0
@export var speed: float = 1.0
@export var icon: Texture2D
@export var sprite: Texture2D
@export var min_day: int = 0
@export var max_day: int = 9_999_999
@export var time_of_day: Enums.TimeOfDay = Enums.TimeOfDay.Day
